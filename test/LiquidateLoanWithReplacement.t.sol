// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {BaseTest, Vars} from "./BaseTest.sol";

import {Loan, LoanStatus} from "@src/libraries/LoanLibrary.sol";
import {Math} from "@src/libraries/MathLibrary.sol";
import {PERCENT} from "@src/libraries/MathLibrary.sol";
import {BorrowOffer} from "@src/libraries/OfferLibrary.sol";

import {LiquidateLoanWithReplacementParams} from "@src/libraries/actions/LiquidateLoanWithReplacement.sol";

import {Errors} from "@src/libraries/Errors.sol";

contract LiquidateLoanWithReplacementTest is BaseTest {
    function test_LiquidateLoanWithReplacement_liquidateLoanWithReplacement_updates_new_borrower_borrowOffer_same_rate()
        public
    {
        _setPrice(1e18);
        _deposit(alice, 100e18, 100e18);
        _deposit(bob, 100e18, 100e18);
        _deposit(candy, 1000e18, 100e18);
        _deposit(liquidator, 100e18, 100e18);
        _lendAsLimitOrder(alice, 100e18, 12, 0.03e18, 12);
        _borrowAsLimitOrder(candy, 100e18, 0.03e18, 12);
        uint256 amount = 15e18;
        uint256 loanId = _borrowAsMarketOrder(bob, alice, amount, 12);
        uint256 debt = Math.mulDivUp(amount, (PERCENT + 0.03e18), PERCENT);
        uint256 delta = debt - amount;

        _setPrice(0.2e18);

        BorrowOffer memory borrowOfferBefore = size.getUserView(candy).user.borrowOffer;
        Loan memory loanBefore = size.getLoan(loanId);
        Vars memory _before = _state();

        assertEq(loanBefore.borrower, bob);
        assertEq(loanBefore.repaid, false);
        assertEq(size.getLoanStatus(loanId), LoanStatus.ACTIVE);

        _liquidateLoanWithReplacement(liquidator, loanId, candy);

        BorrowOffer memory borrowOfferAfter = size.getUserView(candy).user.borrowOffer;
        Loan memory loanAfter = size.getLoan(loanId);
        Vars memory _after = _state();

        assertEq(_after.alice, _before.alice);
        assertEq(_after.candy.debtAmount, _before.candy.debtAmount + debt);
        assertEq(_after.candy.borrowAmount, _before.candy.borrowAmount + amount);
        assertEq(_after.protocolBorrowAmount, _before.protocolBorrowAmount, 0);
        assertEq(_after.feeRecipientBorrowAmount, _before.feeRecipientBorrowAmount + delta);
        assertEq(loanAfter.borrower, candy);
        assertEq(loanAfter.repaid, false);
        assertEq(size.getLoanStatus(loanId), LoanStatus.ACTIVE);
        assertEq(borrowOfferAfter.maxAmount, borrowOfferBefore.maxAmount - amount);
    }

    function test_LiquidateLoanWithReplacement_liquidateLoanWithReplacement_updates_new_borrower_borrowOffer_different_rate(
    ) public {
        _setPrice(1e18);
        _deposit(alice, 100e18, 100e18);
        _deposit(bob, 100e18, 100e18);
        _deposit(candy, 1000e18, 100e18);
        _deposit(liquidator, 100e18, 100e18);
        _lendAsLimitOrder(alice, 100e18, 12, 0.03e18, 12);
        _borrowAsLimitOrder(candy, 100e18, 0.01e18, 12);
        uint256 amount = 15e18;
        uint256 loanId = _borrowAsMarketOrder(bob, alice, amount, 12);
        uint256 debt = Math.mulDivUp(amount, (PERCENT + 0.03e18), PERCENT);
        uint256 newAmount = Math.mulDivDown(debt, PERCENT, (PERCENT + 0.01e18));
        uint256 delta = debt - newAmount;

        _setPrice(0.2e18);

        BorrowOffer memory borrowOfferBefore = size.getUserView(candy).user.borrowOffer;
        Loan memory loanBefore = size.getLoan(loanId);
        Vars memory _before = _state();

        assertEq(loanBefore.borrower, bob);
        assertEq(loanBefore.repaid, false);
        assertEq(size.getLoanStatus(loanId), LoanStatus.ACTIVE);

        _liquidateLoanWithReplacement(liquidator, loanId, candy);

        BorrowOffer memory borrowOfferAfter = size.getUserView(candy).user.borrowOffer;
        Loan memory loanAfter = size.getLoan(loanId);
        Vars memory _after = _state();

        assertEq(_after.alice, _before.alice);
        assertEq(_after.candy.debtAmount, _before.candy.debtAmount + debt);
        assertEq(_after.candy.borrowAmount, _before.candy.borrowAmount + newAmount);
        assertEq(_after.protocolBorrowAmount, _before.protocolBorrowAmount, 0);
        assertEq(_after.feeRecipientBorrowAmount, _before.feeRecipientBorrowAmount + delta);
        assertEq(loanAfter.borrower, candy);
        assertEq(loanAfter.repaid, false);
        assertEq(size.getLoanStatus(loanId), LoanStatus.ACTIVE);
        assertEq(borrowOfferAfter.maxAmount, borrowOfferBefore.maxAmount - newAmount);
    }

    function test_LiquidateLoanWithReplacement_liquidateLoanWithReplacement_cannot_leave_new_borrower_liquidatable()
        public
    {
        _setPrice(1e18);
        _deposit(alice, 100e18, 100e18);
        _deposit(bob, 100e18, 100e18);
        _deposit(liquidator, 100e18, 100e18);
        _lendAsLimitOrder(alice, 100e18, 12, 0.03e18, 12);
        _borrowAsLimitOrder(candy, 100e18, 0.03e18, 12);
        uint256 loanId = _borrowAsMarketOrder(bob, alice, 15e18, 12);

        _setPrice(0.2e18);

        vm.startPrank(liquidator);

        vm.expectRevert(abi.encodeWithSelector(Errors.USER_IS_LIQUIDATABLE.selector, candy, 0));
        size.liquidateLoanWithReplacement(
            LiquidateLoanWithReplacementParams({loanId: loanId, borrower: candy, minimumCollateralRatio: 1e18})
        );
    }

    function test_LiquidateLoanWithReplacement_liquidateLoanWithReplacement_cannot_be_executed_if_loan_is_overdue()
        public
    {
        _setPrice(1e18);
        _deposit(alice, 100e18, 100e18);
        _deposit(bob, 100e18, 100e18);
        _deposit(candy, 1000e18, 100e18);
        _deposit(liquidator, 100e18, 100e18);
        _lendAsLimitOrder(alice, 100e18, 12, 0.03e18, 12);
        _borrowAsLimitOrder(candy, 100e18, 0.03e18, 12);
        uint256 loanId = _borrowAsMarketOrder(bob, alice, 15e18, 12);

        _setPrice(0.2e18);

        assertTrue(size.isLiquidatable(loanId));

        vm.startPrank(liquidator);

        vm.warp(block.timestamp + 12);

        vm.expectRevert(
            abi.encodeWithSelector(Errors.INVALID_LOAN_STATUS.selector, loanId, LoanStatus.OVERDUE, LoanStatus.ACTIVE)
        );
        size.liquidateLoanWithReplacement(
            LiquidateLoanWithReplacementParams({loanId: loanId, borrower: candy, minimumCollateralRatio: 1e18})
        );
    }
}
