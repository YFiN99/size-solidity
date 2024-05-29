// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Errors} from "@src/libraries/Errors.sol";

import {RESERVED_ID} from "@src/libraries/fixed/LoanLibrary.sol";
import {BaseTest} from "@test/BaseTest.sol";
import {Vars} from "@test/BaseTestGeneral.sol";

import {PERCENT} from "@src/libraries/Math.sol";
import {
    CREDIT_POSITION_ID_START, CreditPosition, DebtPosition, LoanStatus
} from "@src/libraries/fixed/LoanLibrary.sol";
import {LoanOffer, OfferLibrary} from "@src/libraries/fixed/OfferLibrary.sol";
import {SellCreditMarketParams} from "@src/libraries/fixed/actions/SellCreditMarket.sol";
import {YieldCurveHelper} from "@test/helpers/libraries/YieldCurveHelper.sol";

import {Math} from "@src/libraries/Math.sol";

contract SellCreditMarketTest is BaseTest {
    using OfferLibrary for LoanOffer;

    uint256 private constant MAX_RATE = 2e18;
    uint256 private constant MAX_TENOR = 365 days * 2;
    uint256 private constant MAX_AMOUNT_USDC = 100e6;
    uint256 private constant MAX_AMOUNT_WETH = 2e18;

    function test_SellCreditMarket_sellCreditMarket_used_to_borrow() public {
        _deposit(alice, usdc, 200e6);
        _deposit(bob, weth, 100e18);
        _buyCreditLimit(alice, block.timestamp + 365 days, YieldCurveHelper.pointCurve(365 days, 0.03e18));

        Vars memory _before = _state();

        uint256 amount = 100e6;
        uint256 tenor = 365 days;

        uint256 futureValue = Math.mulDivUp(amount, (PERCENT + 0.03e18), PERCENT);
        uint256 debtPositionId = _sellCreditMarket(bob, alice, RESERVED_ID, amount, tenor, false);

        uint256 futureValueOpening = Math.mulDivUp(futureValue, size.riskConfig().crOpening, PERCENT);
        uint256 minimumCollateral = size.debtTokenAmountToCollateralTokenAmount(futureValueOpening);
        uint256 swapFee = size.getSwapFee(amount, tenor);

        Vars memory _after = _state();

        assertGt(_before.bob.collateralTokenBalance, minimumCollateral);
        assertEq(_after.alice.borrowATokenBalance, _before.alice.borrowATokenBalance - amount - swapFee);
        assertEq(_after.bob.borrowATokenBalance, _before.bob.borrowATokenBalance + amount);
        assertEq(_after.variablePool.collateralTokenBalance, _before.variablePool.collateralTokenBalance);
        assertEq(_after.bob.debtBalance, size.getDebtPosition(debtPositionId).futureValue);
    }

    function testFuzz_SellCreditMarket_sellCreditMarket_used_to_borrow(uint256 amount, uint256 apr, uint256 tenor)
        public
    {
        _updateConfig("minimumTenor", 1);
        amount = bound(amount, MAX_AMOUNT_USDC / 20, MAX_AMOUNT_USDC / 10); // arbitrary divisor so that user does not get unhealthy
        apr = bound(apr, 0, MAX_RATE);
        tenor = bound(tenor, 1, MAX_TENOR - 1);

        _deposit(alice, weth, MAX_AMOUNT_WETH);
        _deposit(alice, usdc, MAX_AMOUNT_USDC);
        _deposit(bob, weth, MAX_AMOUNT_WETH);
        _deposit(bob, usdc, MAX_AMOUNT_USDC);

        _buyCreditLimit(alice, block.timestamp + tenor, YieldCurveHelper.pointCurve(tenor, int256(apr)));

        Vars memory _before = _state();

        uint256 rate = uint256(Math.aprToRatePerTenor(apr, tenor));
        uint256 debt = Math.mulDivUp(amount, (PERCENT + rate), PERCENT);

        uint256 debtPositionId = _sellCreditMarket(bob, alice, RESERVED_ID, amount, tenor, false);
        uint256 debtOpening = Math.mulDivUp(debt, size.riskConfig().crOpening, PERCENT);
        uint256 minimumCollateral = size.debtTokenAmountToCollateralTokenAmount(debtOpening);
        Vars memory _after = _state();

        assertGt(_before.bob.collateralTokenBalance, minimumCollateral);
        assertEq(
            _after.alice.borrowATokenBalance,
            _before.alice.borrowATokenBalance - amount - size.getSwapFee(amount, tenor)
        );
        assertEq(_after.bob.borrowATokenBalance, _before.bob.borrowATokenBalance + amount);
        assertEq(_after.variablePool.collateralTokenBalance, _before.variablePool.collateralTokenBalance);
        assertEq(_after.bob.debtBalance, size.getDebtPosition(debtPositionId).futureValue);
    }

    function test_SellCreditMarket_sellCreditMarket_fragmentation() public {
        _deposit(alice, weth, 100e18);
        _deposit(alice, usdc, 100e6 + size.feeConfig().fragmentationFee);
        _deposit(bob, weth, 100e18);
        _deposit(bob, usdc, 100e6);
        _deposit(candy, weth, 100e18);
        _deposit(candy, usdc, 100e6);
        uint256 amount = 30e6;
        _buyCreditLimit(alice, block.timestamp + 12 days, YieldCurveHelper.pointCurve(12 days, 0.03e18));
        _buyCreditLimit(candy, block.timestamp + 12 days, YieldCurveHelper.pointCurve(12 days, 0.03e18));
        uint256 debtPositionId = _sellCreditMarket(bob, alice, RESERVED_ID, 60e6, 12 days, false);
        uint256 creditPositionId = size.getCreditPositionIdsByDebtPositionId(debtPositionId)[1];

        Vars memory _before = _state();

        _sellCreditMarket(alice, candy, creditPositionId, amount, 12 days, true);

        Vars memory _after = _state();

        assertLt(_after.candy.borrowATokenBalance, _before.candy.borrowATokenBalance);
        assertGt(_after.alice.borrowATokenBalance, _before.alice.borrowATokenBalance);
        assertGt(
            _after.feeRecipient.borrowATokenBalance,
            _before.feeRecipient.borrowATokenBalance + size.feeConfig().fragmentationFee
        );
        assertEq(_after.variablePool.collateralTokenBalance, _before.variablePool.collateralTokenBalance);
        assertEq(_after.alice.debtBalance, _before.alice.debtBalance);
        assertEq(_after.bob, _before.bob);
    }

    function testFuzz_SellCreditMarket_sellCreditMarket_exit_full(uint256 amount, uint256 rate, uint256 tenor) public {
        _updateConfig("minimumTenor", 1);
        amount = bound(amount, MAX_AMOUNT_USDC / 10, 2 * MAX_AMOUNT_USDC / 10); // arbitrary divisor so that user does not get unhealthy
        rate = bound(rate, 0, MAX_RATE);
        tenor = bound(tenor, 1, MAX_TENOR - 1);

        _deposit(alice, weth, MAX_AMOUNT_WETH);
        _deposit(alice, usdc, MAX_AMOUNT_USDC + size.feeConfig().fragmentationFee);
        _deposit(bob, weth, MAX_AMOUNT_WETH);
        _deposit(bob, usdc, MAX_AMOUNT_USDC);
        _deposit(candy, weth, MAX_AMOUNT_WETH);
        _deposit(candy, usdc, MAX_AMOUNT_USDC);

        _buyCreditLimit(
            alice, block.timestamp + MAX_TENOR, [int256(rate), int256(rate)], [uint256(tenor), uint256(tenor) * 2]
        );
        _buyCreditLimit(
            candy, block.timestamp + MAX_TENOR, [int256(rate), int256(rate)], [uint256(tenor), uint256(tenor) * 2]
        );
        uint256 debtPositionId = _sellCreditMarket(bob, alice, RESERVED_ID, amount, tenor, false);
        (uint256 debtPositionsCountBefore,) = size.getPositionsCount();

        Vars memory _before = _state();

        uint256 creditPositionId = size.getCreditPositionIdsByDebtPositionId(debtPositionId)[1];
        _sellCreditMarket(alice, candy, creditPositionId, tenor);

        Vars memory _after = _state();
        (uint256 debtPositionsCountAfter,) = size.getPositionsCount();

        assertLt(_after.candy.borrowATokenBalance, _before.candy.borrowATokenBalance);
        assertGt(_after.alice.borrowATokenBalance, _before.alice.borrowATokenBalance);
        assertGt(_after.feeRecipient.borrowATokenBalance, _before.feeRecipient.borrowATokenBalance);
        assertEq(_after.variablePool.collateralTokenBalance, _before.variablePool.collateralTokenBalance);
        assertEq(_after.alice.debtBalance, _before.alice.debtBalance);
        assertEq(_after.bob, _before.bob);
        assertEq(debtPositionsCountAfter, debtPositionsCountBefore);
    }

    function test_SellCreditMarket_sellCreditMarket_exit_properties() public {
        _deposit(alice, weth, 100e18);
        _deposit(alice, usdc, 100e6);
        _deposit(bob, weth, 100e18);
        _deposit(bob, usdc, 100e6);
        _deposit(candy, weth, 100e18);
        _deposit(candy, usdc, 100e6);
        _buyCreditLimit(alice, block.timestamp + 12 days, YieldCurveHelper.pointCurve(12 days, 0.03e18));
        _buyCreditLimit(candy, block.timestamp + 12 days, YieldCurveHelper.pointCurve(12 days, 0.03e18));
        uint256 debtPositionId = _sellCreditMarket(bob, alice, RESERVED_ID, 60e6, 12 days, false);

        Vars memory _before = _state();
        (uint256 debtPositionsCountBefore,) = size.getPositionsCount();

        uint256 creditPositionId = size.getCreditPositionIdsByDebtPositionId(debtPositionId)[1];
        _sellCreditMarket(alice, candy, creditPositionId, 30e6, 12 days);

        Vars memory _after = _state();
        (uint256 debtPositionsCountAfter,) = size.getPositionsCount();

        assertLt(_after.candy.borrowATokenBalance, _before.candy.borrowATokenBalance);
        assertGe(_after.alice.borrowATokenBalance, _before.alice.borrowATokenBalance);
        assertEq(_after.variablePool.collateralTokenBalance, _before.variablePool.collateralTokenBalance);
        assertEq(_after.alice.debtBalance, _before.alice.debtBalance);
        assertEq(_after.bob, _before.bob);
        assertEq(debtPositionsCountAfter, debtPositionsCountBefore);
    }

    function test_SellCreditMarket_sellCreditMarket_reverts_if_below_borrowing_opening_limit() public {
        _deposit(alice, weth, 100e18);
        _deposit(alice, usdc, 120e6);
        _buyCreditLimit(alice, block.timestamp + 12 days, YieldCurveHelper.pointCurve(12 days, 0.03e18));
        uint256 amount = 100e6;
        uint256 tenor = 12 days;
        vm.startPrank(bob);
        uint256 apr = size.getLoanOfferAPR(alice, tenor);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.CR_BELOW_OPENING_LIMIT_BORROW_CR.selector, bob, 0, size.riskConfig().crOpening
            )
        );
        size.sellCreditMarket(
            SellCreditMarketParams({
                lender: alice,
                creditPositionId: RESERVED_ID,
                amount: amount,
                tenor: tenor,
                deadline: block.timestamp,
                maxAPR: apr,
                exactAmountIn: false
            })
        );
    }

    function test_SellCreditMarket_sellCreditMarket_reverts_if_lender_cannot_transfer_underlyingBorrowToken() public {
        _deposit(alice, usdc, 1000e6);
        _deposit(bob, weth, 1e18);
        _buyCreditLimit(alice, block.timestamp + 12 days, YieldCurveHelper.pointCurve(12 days, 0.03e18));

        _withdraw(alice, usdc, 999e6);

        uint256 amount = 10e6;
        uint256 tenor = 12 days;

        vm.startPrank(bob);
        vm.expectRevert();
        size.sellCreditMarket(
            SellCreditMarketParams({
                lender: alice,
                creditPositionId: RESERVED_ID,
                amount: amount,
                tenor: tenor,
                deadline: block.timestamp,
                maxAPR: type(uint256).max,
                exactAmountIn: false
            })
        );
    }

    function test_SellCreditMarket_sellCreditMarket_does_not_create_new_CreditPosition_if_lender_tries_to_exit_fully_exited_CreditPosition(
    ) public {
        _setPrice(1e18);

        _deposit(alice, weth, 200e18);
        _deposit(alice, usdc, 200e6);
        _deposit(bob, weth, 200e18);
        _deposit(candy, usdc, 200e6);
        _deposit(james, usdc, 200e6);
        _deposit(liquidator, usdc, 10_000e6);

        assertEq(size.collateralRatio(bob), type(uint256).max);

        _buyCreditLimit(alice, block.timestamp + 365 days, YieldCurveHelper.pointCurve(365 days, 0.03e18));
        _buyCreditLimit(candy, block.timestamp + 365 days, YieldCurveHelper.pointCurve(365 days, 0.03e18));
        _buyCreditLimit(james, block.timestamp + 365 days, YieldCurveHelper.pointCurve(365 days, 0.03e18));
        uint256 debtPositionId = _sellCreditMarket(bob, alice, RESERVED_ID, 100e6, 365 days, false);
        uint256 creditPositionId = size.getCreditPositionIdsByDebtPositionId(debtPositionId)[1];
        _sellCreditMarket(alice, candy, creditPositionId, 365 days);

        uint256 credit = size.getCreditPosition(creditPositionId).credit;
        vm.expectRevert();
        _sellCreditMarket(alice, james, creditPositionId, credit, 365 days, true);
    }

    function test_SellCreditMarket_sellCreditMarket_CreditPosition_of_CreditPosition_creates_with_correct_debtPositionId(
    ) public {
        _setPrice(1e18);

        _deposit(alice, weth, 150e18);
        _deposit(alice, usdc, 100e6 + size.feeConfig().fragmentationFee);
        _deposit(bob, weth, 160e18);
        _deposit(bob, usdc, 100e6);
        _deposit(candy, weth, 150e18);
        _deposit(candy, usdc, 100e6 + size.feeConfig().fragmentationFee);
        _deposit(james, usdc, 200e6);
        _deposit(liquidator, usdc, 10_000e6);
        _buyCreditLimit(alice, block.timestamp + 12 days, YieldCurveHelper.pointCurve(12 days, 0));
        _buyCreditLimit(bob, block.timestamp + 12 days, YieldCurveHelper.pointCurve(12 days, 0));
        _buyCreditLimit(candy, block.timestamp + 12 days, YieldCurveHelper.pointCurve(12 days, 0));
        _buyCreditLimit(james, block.timestamp + 12 days, YieldCurveHelper.pointCurve(12 days, 0));
        uint256 debtPositionId = _sellCreditMarket(bob, alice, RESERVED_ID, 100e6, 12 days, false);
        uint256 creditPositionId = size.getCreditPositionIdsByDebtPositionId(debtPositionId)[1];
        _sellCreditMarket(alice, candy, creditPositionId, 49e6, 12 days);
        uint256 creditPositionId2 = size.getCreditPositionIdsByDebtPositionId(debtPositionId)[2];
        _sellCreditMarket(candy, bob, creditPositionId2, 42e6, 12 days);

        assertEq(size.getCreditPosition(creditPositionId).debtPositionId, debtPositionId);
        assertEq(size.getCreditPosition(creditPositionId2).debtPositionId, debtPositionId);
    }

    function test_SellCreditMarket_sellCreditMarket_CreditPosition_credit_is_decreased_after_exit() public {
        _setPrice(1e18);

        _deposit(alice, weth, 1500e18);
        _deposit(alice, usdc, 1000e6 + size.feeConfig().fragmentationFee);
        _deposit(bob, weth, 1600e18);
        _deposit(bob, usdc, 1000e6);
        _deposit(candy, usdc, 1000e6);
        _deposit(james, usdc, 2000e6);
        _buyCreditLimit(alice, block.timestamp + 12 days, YieldCurveHelper.pointCurve(12 days, 0));
        _buyCreditLimit(bob, block.timestamp + 12 days, YieldCurveHelper.pointCurve(12 days, 0));
        _buyCreditLimit(candy, block.timestamp + 12 days, YieldCurveHelper.pointCurve(12 days, 0));
        _buyCreditLimit(james, block.timestamp + 12 days, YieldCurveHelper.pointCurve(12 days, 0));
        uint256 debtPositionId = _sellCreditMarket(bob, alice, RESERVED_ID, 1000e6, 12 days, false);
        uint256 creditPositionId = size.getCreditPositionIdsByDebtPositionId(debtPositionId)[1];
        _sellCreditMarket(alice, candy, creditPositionId, 490e6, 12 days, false);
        uint256 creditPositionId2 = size.getCreditPositionIdsByDebtPositionId(debtPositionId)[2];

        CreditPosition memory creditBefore1 = size.getCreditPosition(creditPositionId);
        CreditPosition memory creditBefore2 = size.getCreditPosition(creditPositionId2);

        _sellCreditMarket(candy, bob, creditPositionId2, 400e6, 12 days, false);

        CreditPosition memory creditAfter1 = size.getCreditPosition(creditPositionId);
        CreditPosition memory creditAfter2 = size.getCreditPosition(creditPositionId2);

        assertEq(creditAfter1.credit, creditBefore1.credit);
        assertLt(creditAfter2.credit, creditBefore2.credit);
    }

    function test_SellCreditMarket_sellCreditMarket_does_not_create_loans_if_dust_amount() public {
        _deposit(alice, weth, 100e18);
        _deposit(alice, usdc, 100e6);
        _deposit(bob, weth, 100e18);
        _deposit(bob, usdc, 100e6);
        _buyCreditLimit(alice, block.timestamp + 12 days, YieldCurveHelper.pointCurve(12 days, 0.1e18));

        Vars memory _before = _state();

        uint256 amount = 1;
        uint256 tenor = 12 days;

        vm.startPrank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.CREDIT_LOWER_THAN_MINIMUM_CREDIT.selector, amount, size.riskConfig().minimumCreditBorrowAToken
            )
        );
        size.sellCreditMarket(
            SellCreditMarketParams({
                lender: alice,
                creditPositionId: RESERVED_ID,
                amount: amount,
                tenor: tenor,
                deadline: block.timestamp,
                maxAPR: type(uint256).max,
                exactAmountIn: false
            })
        );

        Vars memory _after = _state();

        assertEq(_after.alice, _before.alice);
        assertEq(_after.bob, _before.bob);
        assertEq(_after.bob.debtBalance, 0);
        assertEq(_after.variablePool.collateralTokenBalance, _before.variablePool.collateralTokenBalance);
        (uint256 debtPositions,) = size.getPositionsCount();
        assertEq(debtPositions, 0);
    }
}
