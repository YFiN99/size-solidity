// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {BaseTest} from "@test/BaseTest.sol";
import {Vars} from "@test/BaseTestGeneral.sol";

import {Errors} from "@src/libraries/Errors.sol";
import {FixedLoan} from "@src/libraries/fixed/FixedLoanLibrary.sol";
import {BorrowOffer} from "@src/libraries/fixed/OfferLibrary.sol";
import {BorrowerExitParams} from "@src/libraries/fixed/actions/BorrowerExit.sol";

contract BorrowerExitTest is BaseTest {
    function test_BorrowerExit_borrowerExit_transfer_cash_from_sender_to_borrowOffer_properties() public {
        _deposit(alice, weth, 100e18);
        _deposit(alice, usdc, 100e6);
        _deposit(bob, weth, 100e18);
        _deposit(bob, usdc, 100e6);
        _deposit(candy, weth, 100e18);
        _deposit(candy, usdc, 100e6);
        _lendAsLimitOrder(alice, 100e6, 12, 0.03e18, 12);
        uint256 loanId = _borrowAsMarketOrder(bob, alice, 100e6, 12);
        _borrowAsLimitOrder(candy, 100e6, 0.03e18, 12);

        Vars memory _before = _state();

        BorrowOffer memory borrowOfferBefore = size.getUserView(candy).user.borrowOffer;
        FixedLoan memory loanBefore = size.getFixedLoan(loanId);
        uint256 loansBefore = size.activeFixedLoans();

        _borrowerExit(bob, loanId, candy);

        BorrowOffer memory borrowOfferAfter = size.getUserView(candy).user.borrowOffer;
        FixedLoan memory loanAfter = size.getFixedLoan(loanId);
        uint256 loansAfter = size.activeFixedLoans();

        Vars memory _after = _state();

        assertGt(_after.candy.borrowAmount, _before.candy.borrowAmount);
        assertLt(_after.bob.borrowAmount, _before.bob.borrowAmount);
        assertGt(_after.candy.debtAmount, _before.candy.debtAmount);
        assertLt(_after.bob.debtAmount, _before.bob.debtAmount);
        assertLt(borrowOfferAfter.maxAmount, borrowOfferBefore.maxAmount);
        assertEq(loanAfter.faceValueExited, loanBefore.faceValueExited);
        assertEq(loanBefore.borrower, bob);
        assertEq(loanAfter.borrower, candy);
        assertEq(_before.alice, _after.alice);
        assertEq(loansAfter, loansBefore);
    }

    // @audit exit to self should not change anything except for maxAmount
    function test_BorrowerExit_borrowerExit_to_self_is_possible_properties() public {
        _deposit(alice, weth, 100e18);
        _deposit(alice, usdc, 100e6);
        _deposit(bob, weth, 100e18);
        _deposit(bob, usdc, 100e6);
        _lendAsLimitOrder(alice, 100e6, 12, 0.03e18, 12);
        uint256 loanId = _borrowAsMarketOrder(bob, alice, 100e6, 12);
        _borrowAsLimitOrder(bob, 100e6, 0.03e18, 12);

        Vars memory _before = _state();

        address borrowerToExitTo = bob;

        BorrowOffer memory borrowOfferBefore = size.getUserView(bob).user.borrowOffer;
        FixedLoan memory loanBefore = size.getFixedLoan(loanId);
        uint256 loansBefore = size.activeFixedLoans();

        _borrowerExit(bob, loanId, borrowerToExitTo);

        BorrowOffer memory borrowOfferAfter = size.getUserView(bob).user.borrowOffer;
        FixedLoan memory loanAfter = size.getFixedLoan(loanId);
        uint256 loansAfter = size.activeFixedLoans();

        Vars memory _after = _state();

        assertLt(borrowOfferAfter.maxAmount, borrowOfferBefore.maxAmount);
        assertEq(loanAfter.faceValueExited, loanBefore.faceValueExited);
        assertEq(_before.alice, _after.alice);
        assertEq(_before.bob, _after.bob);
        assertEq(loansAfter, loansBefore);
    }

    function test_BorrowerExit_borrowerExit_cannot_leave_borrower_liquidatable() public {
        _setPrice(1e18);
        _deposit(alice, usdc, 100e6);
        _deposit(bob, weth, 2 * 150e18);
        _deposit(bob, usdc, 100e6);
        _deposit(candy, weth, 150e18);
        _lendAsLimitOrder(alice, 100e6, 12, 1e18, 12);
        uint256 loanId = _borrowAsMarketOrder(bob, alice, 100e6, 12);
        _borrowAsLimitOrder(candy, 200e6, 0, 12);

        vm.startPrank(bob);
        vm.expectRevert(abi.encodeWithSelector(Errors.USER_IS_LIQUIDATABLE.selector, candy, 1.5e18 / 2));
        size.borrowerExit(BorrowerExitParams({loanId: loanId, borrowerToExitTo: candy}));
    }
}
