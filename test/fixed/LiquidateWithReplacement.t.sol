// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {BaseTest} from "@test/BaseTest.sol";
import {Vars} from "@test/BaseTestGeneral.sol";

import {Math} from "@src/libraries/Math.sol";
import {PERCENT} from "@src/libraries/Math.sol";
import {LoanStatus} from "@src/libraries/fixed/LoanLibrary.sol";
import {DebtPosition} from "@src/libraries/fixed/LoanLibrary.sol";

import {LiquidateWithReplacementParams} from "@src/libraries/fixed/actions/LiquidateWithReplacement.sol";

import {Errors} from "@src/libraries/Errors.sol";

contract LiquidateWithReplacementTest is BaseTest {
    function setUp() public override {
        super.setUp();
        _setKeeperRole(liquidator);
    }

    function test_LiquidateWithReplacement_liquidateWithReplacement_updates_new_borrower_borrowOffer_same_rate()
        public
    {
        _setPrice(1e18);
        _deposit(alice, weth, 100e18);
        _deposit(alice, usdc, 100e6);
        _deposit(bob, weth, 100e18);
        _deposit(bob, usdc, 100e6);
        _deposit(candy, weth, 400e18);
        _deposit(candy, usdc, 100e6);
        _deposit(liquidator, weth, 100e18);
        _deposit(liquidator, usdc, 100e6);
        _lendAsLimitOrder(alice, block.timestamp + 365 days, 0.03e18);
        _borrowAsLimitOrder(candy, 0.03e18, block.timestamp + 365 days);
        uint256 amount = 15e6;
        uint256 debtPositionId = _borrowAsMarketOrder(bob, alice, amount, block.timestamp + 365 days);
        uint256 faceValue = Math.mulDivUp(amount, (PERCENT + 0.03e18), PERCENT);
        uint256 repayFee = size.getDebtPosition(debtPositionId).repayFee;
        uint256 delta = faceValue - amount;

        _setPrice(0.2e18);

        Vars memory _before = _state();

        assertEq(size.getDebtPosition(debtPositionId).borrower, bob);
        assertGt(size.getOverdueDebt(debtPositionId), 0);
        assertEq(size.getLoanStatus(debtPositionId), LoanStatus.ACTIVE);

        _liquidateWithReplacement(liquidator, debtPositionId, candy);

        Vars memory _after = _state();

        assertEq(_after.alice, _before.alice);
        assertEq(
            _after.candy.debtBalance,
            _before.candy.debtBalance + faceValue + repayFee + size.feeConfig().overdueLiquidatorReward
        );
        assertEq(_after.candy.borrowATokenBalance, _before.candy.borrowATokenBalance + amount);
        assertEq(_after.feeRecipient.borrowATokenBalance, _before.feeRecipient.borrowATokenBalance + delta);
        assertEq(size.getDebtPosition(debtPositionId).borrower, candy);
        assertGt(size.getOverdueDebt(debtPositionId), 0);
        assertEq(size.getLoanStatus(debtPositionId), LoanStatus.ACTIVE);
    }

    function test_LiquidateWithReplacement_liquidateWithReplacement_updates_new_borrower_borrowOffer_different_rate()
        public
    {
        _setPrice(1e18);
        _deposit(alice, weth, 100e18);
        _deposit(alice, usdc, 100e6);
        _deposit(bob, weth, 100e18);
        _deposit(bob, usdc, 100e6);
        _deposit(candy, weth, 400e18);
        _deposit(candy, usdc, 100e6);
        _deposit(liquidator, weth, 100e18);
        _deposit(liquidator, usdc, 100e6);
        _lendAsLimitOrder(alice, block.timestamp + 365 days, 0.03e18);
        _borrowAsLimitOrder(candy, 0.01e18, block.timestamp + 365 days);
        uint256 amount = 15e6;
        uint256 debtPositionId = _borrowAsMarketOrder(bob, alice, amount, block.timestamp + 365 days);
        uint256 faceValue = Math.mulDivUp(amount, (PERCENT + 0.03e18), PERCENT);
        uint256 newAmount = Math.mulDivDown(faceValue, PERCENT, (PERCENT + 0.01e18));
        uint256 repayFee = size.getDebtPosition(debtPositionId).repayFee;
        uint256 delta = faceValue - newAmount;

        _setPrice(0.2e18);

        Vars memory _before = _state();

        assertEq(size.getDebtPosition(debtPositionId).borrower, bob);
        assertGt(size.getOverdueDebt(debtPositionId), 0);
        assertEq(size.getLoanStatus(debtPositionId), LoanStatus.ACTIVE);

        _liquidateWithReplacement(liquidator, debtPositionId, candy);

        Vars memory _after = _state();

        assertEq(_after.alice, _before.alice);
        assertEq(
            _after.candy.debtBalance,
            _before.candy.debtBalance + faceValue + repayFee + size.feeConfig().overdueLiquidatorReward
        );
        assertEq(_after.candy.borrowATokenBalance, _before.candy.borrowATokenBalance + newAmount);
        assertEq(_before.variablePool.borrowATokenBalance, 0);
        assertEq(_after.variablePool.borrowATokenBalance, _before.variablePool.borrowATokenBalance);
        assertEq(_after.feeRecipient.borrowATokenBalance, _before.feeRecipient.borrowATokenBalance + delta);
        assertEq(size.getDebtPosition(debtPositionId).borrower, candy);
        assertGt(size.getOverdueDebt(debtPositionId), 0);
        assertEq(size.getLoanStatus(debtPositionId), LoanStatus.ACTIVE);
    }

    function test_LiquidateWithReplacement_liquidateWithReplacement_cannot_leave_new_borrower_liquidatable() public {
        _setPrice(1e18);
        _deposit(alice, weth, 100e18);
        _deposit(alice, usdc, 100e6);
        _deposit(bob, weth, 100e18);
        _deposit(bob, usdc, 100e6);
        _deposit(liquidator, weth, 100e18);
        _deposit(liquidator, usdc, 100e6);
        _lendAsLimitOrder(alice, block.timestamp + 365 days, 0.03e18);
        _borrowAsLimitOrder(candy, 0.03e18, block.timestamp + 365 days);
        uint256 debtPositionId = _borrowAsMarketOrder(bob, alice, 15e6, block.timestamp + 365 days);

        _setPrice(0.2e18);

        vm.startPrank(liquidator);

        vm.expectRevert(abi.encodeWithSelector(Errors.CR_BELOW_OPENING_LIMIT_BORROW_CR.selector, candy, 0, 1.5e18));
        size.liquidateWithReplacement(
            LiquidateWithReplacementParams({
                debtPositionId: debtPositionId,
                borrower: candy,
                deadline: block.timestamp,
                minAPR: 0,
                minimumCollateralProfit: 0
            })
        );
    }

    function test_LiquidateWithReplacement_liquidateWithReplacement_cannot_be_executed_if_loan_is_overdue() public {
        _updateConfig("minimumMaturity", 1);
        _setPrice(1e18);
        _deposit(alice, weth, 100e18);
        _deposit(alice, usdc, 100e6);
        _deposit(bob, weth, 100e18);
        _deposit(bob, usdc, 100e6);
        _deposit(candy, weth, 100e18);
        _deposit(candy, usdc, 100e6);
        _deposit(liquidator, weth, 100e18);
        _deposit(liquidator, usdc, 100e6);
        _lendAsLimitOrder(alice, block.timestamp + 365 days, 0.03e18);
        _borrowAsLimitOrder(candy, 0.03e18, 30);
        uint256 debtPositionId = _borrowAsMarketOrder(bob, alice, 15e6, block.timestamp + 365 days);

        _setPrice(0.2e18);

        assertTrue(size.isDebtPositionLiquidatable(debtPositionId));

        vm.startPrank(liquidator);

        vm.warp(block.timestamp + 365 days + 1);

        vm.expectRevert(abi.encodeWithSelector(Errors.LOAN_NOT_ACTIVE.selector, debtPositionId));
        size.liquidateWithReplacement(
            LiquidateWithReplacementParams({
                debtPositionId: debtPositionId,
                borrower: candy,
                deadline: block.timestamp,
                minAPR: 0,
                minimumCollateralProfit: 0
            })
        );
    }

    function test_LiquidateWithReplacement_liquidateWithReplacement_experiment() public {
        _setPrice(1e18);
        _updateConfig("collateralTokenCap", type(uint256).max);
        _updateConfig("borrowATokenCap", type(uint256).max);
        // Bob deposits in USDC
        _deposit(bob, usdc, 100e6);
        assertEq(_state().bob.borrowATokenBalance, 100e6);

        // Bob lends as limit order
        _lendAsLimitOrder(
            bob,
            block.timestamp + 365 days,
            [int256(0.03e18), int256(0.03e18)],
            [uint256(365 days), uint256(365 days * 2)]
        );

        // Alice deposits in WETH
        _deposit(alice, weth, 200e18);

        // Alice borrows as market order from Bob
        _borrowAsMarketOrder(alice, bob, 100e6, block.timestamp + 365 days);

        // Assert conditions for Alice's borrowing
        assertGe(size.collateralRatio(alice), size.riskConfig().crOpening, "Alice should be above CR opening");
        assertTrue(!size.isUserUnderwater(alice), "Borrower should not be underwater");

        // Candy places a borrow limit order (candy needs more collateral so that she can be replaced later)
        _deposit(candy, weth, 20000e18);
        assertEq(_state().candy.collateralTokenBalance, 20000e18);
        _borrowAsLimitOrder(candy, [int256(0.03e18), int256(0.03e18)], [uint256(180 days), uint256(365 days * 2)]);

        // Update the context (time and price)
        vm.warp(block.timestamp + 1 days);
        _setPrice(0.6e18);

        // Assert conditions for liquidation
        assertTrue(size.isUserUnderwater(alice), "Borrower should be underwater");
        assertTrue(size.isDebtPositionLiquidatable(0), "Loan should be liquidatable");

        DebtPosition memory loan = size.getDebtPosition(0);
        uint256 repayFee = loan.repayFee;
        assertEq(loan.borrower, alice, "Alice should be the borrower");
        assertEq(
            _state().alice.debtBalance,
            loan.faceValue + repayFee + size.feeConfig().overdueLiquidatorReward,
            "Alice should have the debt"
        );

        assertEq(_state().candy.debtBalance, 0, "Candy should have no debt");
        // Perform the liquidation with replacement
        _deposit(liquidator, usdc, 10_000e6);
        _liquidateWithReplacement(liquidator, 0, candy);
        assertEq(_state().alice.debtBalance, 0, "Alice should have no debt after");
        assertEq(
            _state().candy.debtBalance,
            loan.faceValue + repayFee + size.feeConfig().overdueLiquidatorReward,
            "Candy should have the debt after"
        );
    }
}
