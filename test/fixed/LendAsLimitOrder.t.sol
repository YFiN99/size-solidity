// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {BaseTest} from "@test/BaseTest.sol";

import {Errors} from "@src/libraries/Errors.sol";
import {RESERVED_ID} from "@src/libraries/fixed/LoanLibrary.sol";
import {LoanOffer, OfferLibrary} from "@src/libraries/fixed/OfferLibrary.sol";

import {YieldCurve} from "@src/libraries/fixed/YieldCurveLibrary.sol";

import {BuyCreditLimitParams} from "@src/libraries/fixed/actions/BuyCreditLimit.sol";

import {SellCreditMarketParams} from "@src/libraries/fixed/actions/SellCreditMarket.sol";

contract BuyCreditLimitTest is BaseTest {
    using OfferLibrary for LoanOffer;

    function test_BuyCreditLimit_buyCreditLimitOrder_adds_loanOffer_to_orderbook() public {
        _deposit(alice, weth, 100e18);
        _deposit(alice, usdc, 100e6);
        assertTrue(_state().alice.user.loanOffer.isNull());
        _buyCreditLimitOrder(alice, block.timestamp + 12 days, 1.01e18);
        assertTrue(!_state().alice.user.loanOffer.isNull());
    }

    function test_BuyCreditLimit_buyCreditLimitOrder_clear_limit_order() public {
        _setPrice(1e18);
        _deposit(alice, usdc, 1_000e6);
        _deposit(bob, weth, 300e18);
        _deposit(candy, weth, 300e18);

        uint256 maxDueDate = block.timestamp + 365 days;
        uint256[] memory marketRateMultipliers = new uint256[](2);
        uint256[] memory maturities = new uint256[](2);
        maturities[0] = 30 days;
        maturities[1] = 60 days;
        int256[] memory aprs = new int256[](2);
        aprs[0] = 0.15e18;
        aprs[0] = 0.12e18;

        vm.prank(alice);
        size.buyCreditLimitOrder(
            BuyCreditLimitParams({
                maxDueDate: maxDueDate,
                curveRelativeTime: YieldCurve({
                    maturities: maturities,
                    marketRateMultipliers: marketRateMultipliers,
                    aprs: aprs
                })
            })
        );

        _sellCreditMarket(bob, alice, RESERVED_ID, 100e6, block.timestamp + 45 days, false);

        BuyCreditLimitParams memory empty;
        vm.prank(alice);
        size.buyCreditLimitOrder(empty);

        uint256 amount = 100e6;
        uint256 dueDate = block.timestamp + 45 days;
        vm.prank(candy);
        vm.expectRevert(abi.encodeWithSelector(Errors.INVALID_LOAN_OFFER.selector, alice));
        size.sellCreditMarket(
            SellCreditMarketParams({
                lender: alice,
                creditPositionId: RESERVED_ID,
                amount: amount,
                dueDate: dueDate,
                deadline: block.timestamp,
                maxAPR: type(uint256).max,
                exactAmountIn: false
            })
        );
    }

    function test_BuyCreditLimit_buyCreditLimitOrder_experiment_strategy_speculator() public {
        // The speculator hopes to profit off of interest rate movements, by either:
        // 1. Lending at a high interest rate and exit to other lenders when interest rates drop
        // 2. Borrowing at low interest rate and exit to other borrowers when interest rates rise
        // #### Case 1: Betting on Rates Dropping
        // Lenny the Lender lends 10,000 at 6% interest for 6 months, with a face value of 10,300.
        // Two weeks after Lenny lends, the interest rate to borrow for 5.5 months is 4.5%.
        // Lenny exits to another lender, who pays 10300/(1+0.045*11/24) = 10,091 to Lenny in return for the 10300 from the borrower in 5.5 months.
        // Lenny has now made 91 over the course of 2 weeks. While only around 1%, it’s 26% annualized without compounding, and he may compound his profits by repeating this strategy.

        _setPrice(1e18);
        _updateConfig("swapFeeAPR", 0);

        _deposit(alice, usdc, 10_000e6);
        _buyCreditLimitOrder(alice, block.timestamp + 180 days, 0.06e18);

        _deposit(bob, weth, 20_000e18);
        uint256 debtPositionId = _sellCreditMarket(bob, alice, RESERVED_ID, 10_000e6, block.timestamp + 180 days, false);
        uint256 creditPositionId = size.getCreditPositionIdsByDebtPositionId(debtPositionId)[1];
        uint256 faceValue = size.getDebtPosition(debtPositionId).faceValue;
        assertEqApprox(faceValue, 10_300e6, 100e6);

        vm.warp(block.timestamp + 14 days);
        _deposit(candy, usdc, faceValue);
        _buyCreditLimitOrder(candy, block.timestamp + 180 days - 14 days, 0.045e18);
        _sellCreditMarket(alice, candy, creditPositionId, size.getDebtPosition(debtPositionId).dueDate);

        assertEqApprox(_state().alice.borrowATokenBalance, 10_091e6, 10e6);
        assertEq(_state().alice.debtBalance, 0);
    }
}
