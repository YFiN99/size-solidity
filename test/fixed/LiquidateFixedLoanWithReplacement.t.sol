// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {BaseTest} from "@test/BaseTest.sol";
import {Vars} from "@test/BaseTestGeneral.sol";

import {Math} from "@src/libraries/Math.sol";
import {PERCENT} from "@src/libraries/Math.sol";
import {FixedLoan, FixedLoanStatus} from "@src/libraries/fixed/FixedLoanLibrary.sol";
import {BorrowOffer} from "@src/libraries/fixed/OfferLibrary.sol";

import {LiquidateFixedLoanWithReplacementParams} from
    "@src/libraries/fixed/actions/LiquidateFixedLoanWithReplacement.sol";

import {Errors} from "@src/libraries/Errors.sol";

contract LiquidateFixedLoanWithReplacementTest is BaseTest {
    function setUp() public override {
        super.setUp();
        _setKeeperRole(liquidator);
    }

    function test_LiquidateFixedLoanWithReplacement_liquidateFixedLoanWithReplacement_updates_new_borrower_borrowOffer_same_rate(
    ) public {
        _setPrice(1e18);
        _deposit(alice, weth, 100e18);
        _deposit(alice, usdc, 100e6);
        _deposit(bob, weth, 100e18);
        _deposit(bob, usdc, 100e6);
        _deposit(candy, weth, 400e18);
        _deposit(candy, usdc, 100e6);
        _deposit(liquidator, weth, 100e18);
        _deposit(liquidator, usdc, 100e6);
        _lendAsLimitOrder(alice, 12, 0.03e18, 12);
        _borrowAsLimitOrder(candy, 0.03e18, 12);
        uint256 amount = 15e6;
        uint256 loanId = _borrowAsMarketOrder(bob, alice, amount, 12);
        uint256 debt = Math.mulDivUp(amount, (PERCENT + 0.03e18), PERCENT);
        uint256 delta = debt - amount;

        _setPrice(0.2e18);

        BorrowOffer memory borrowOfferBefore = size.getUserView(candy).user.borrowOffer;
        FixedLoan memory loanBefore = size.getFixedLoan(loanId);
        Vars memory _before = _state();

        assertEq(loanBefore.borrower, bob);
        assertEq(loanBefore.repaid, false);
        assertEq(size.getFixedLoanStatus(loanId), FixedLoanStatus.ACTIVE);

        _liquidateFixedLoanWithReplacement(liquidator, loanId, candy);

        BorrowOffer memory borrowOfferAfter = size.getUserView(candy).user.borrowOffer;
        FixedLoan memory loanAfter = size.getFixedLoan(loanId);
        Vars memory _after = _state();

        assertEq(_after.alice, _before.alice);
        assertEq(_after.candy.debtAmount, _before.candy.debtAmount + debt);
        assertEq(_after.candy.borrowAmount, _before.candy.borrowAmount + amount);
        // assertEq(_after.variablePool.borrowAmount, _before.variablePool.borrowAmount, 0);
        assertEq(_after.feeRecipient.borrowAmount, _before.feeRecipient.borrowAmount + delta);
        assertEq(loanAfter.borrower, candy);
        assertEq(loanAfter.repaid, false);
        assertEq(size.getFixedLoanStatus(loanId), FixedLoanStatus.ACTIVE);
    }

    function test_LiquidateFixedLoanWithReplacement_liquidateFixedLoanWithReplacement_updates_new_borrower_borrowOffer_different_rate(
    ) public {
        _setPrice(1e18);
        _deposit(alice, weth, 100e18);
        _deposit(alice, usdc, 100e6);
        _deposit(bob, weth, 100e18);
        _deposit(bob, usdc, 100e6);
        _deposit(candy, weth, 400e18);
        _deposit(candy, usdc, 100e6);
        _deposit(liquidator, weth, 100e18);
        _deposit(liquidator, usdc, 100e6);
        _lendAsLimitOrder(alice, 12, 0.03e18, 12);
        _borrowAsLimitOrder(candy, 0.01e18, 12);
        uint256 amount = 15e6;
        uint256 loanId = _borrowAsMarketOrder(bob, alice, amount, 12);
        uint256 debt = Math.mulDivUp(amount, (PERCENT + 0.03e18), PERCENT);
        uint256 newAmount = Math.mulDivDown(debt, PERCENT, (PERCENT + 0.01e18));
        uint256 delta = debt - newAmount;

        _setPrice(0.2e18);

        BorrowOffer memory borrowOfferBefore = size.getUserView(candy).user.borrowOffer;
        FixedLoan memory loanBefore = size.getFixedLoan(loanId);
        Vars memory _before = _state();

        assertEq(loanBefore.borrower, bob);
        assertEq(loanBefore.repaid, false);
        assertEq(size.getFixedLoanStatus(loanId), FixedLoanStatus.ACTIVE);

        _liquidateFixedLoanWithReplacement(liquidator, loanId, candy);

        BorrowOffer memory borrowOfferAfter = size.getUserView(candy).user.borrowOffer;
        FixedLoan memory loanAfter = size.getFixedLoan(loanId);
        Vars memory _after = _state();

        assertEq(_after.alice, _before.alice);
        assertEq(_after.candy.debtAmount, _before.candy.debtAmount + debt);
        assertEq(_after.candy.borrowAmount, _before.candy.borrowAmount + newAmount);
        assertEq(_before.variablePool.borrowAmount, 0);
        assertEq(_after.variablePool.borrowAmount, _before.variablePool.borrowAmount);
        assertEq(_after.feeRecipient.borrowAmount, _before.feeRecipient.borrowAmount + delta);
        assertEq(loanAfter.borrower, candy);
        assertEq(loanAfter.repaid, false);
        assertEq(size.getFixedLoanStatus(loanId), FixedLoanStatus.ACTIVE);
    }

    function test_LiquidateFixedLoanWithReplacement_liquidateFixedLoanWithReplacement_cannot_leave_new_borrower_liquidatable(
    ) public {
        _setPrice(1e18);
        _deposit(alice, weth, 100e18);
        _deposit(alice, usdc, 100e6);
        _deposit(bob, weth, 100e18);
        _deposit(bob, usdc, 100e6);
        _deposit(liquidator, weth, 100e18);
        _deposit(liquidator, usdc, 100e6);
        _lendAsLimitOrder(alice, 12, 0.03e18, 12);
        _borrowAsLimitOrder(candy, 0.03e18, 12);
        uint256 loanId = _borrowAsMarketOrder(bob, alice, 15e6, 12);

        _setPrice(0.2e18);

        vm.startPrank(liquidator);

        vm.expectRevert(abi.encodeWithSelector(Errors.USER_IS_LIQUIDATABLE.selector, candy, 0));
        size.liquidateFixedLoanWithReplacement(
            LiquidateFixedLoanWithReplacementParams({loanId: loanId, borrower: candy, minimumCollateralRatio: 1e18})
        );
    }

    function test_LiquidateFixedLoanWithReplacement_liquidateFixedLoanWithReplacement_cannot_be_executed_if_loan_is_overdue(
    ) public {
        _setPrice(1e18);
        _deposit(alice, weth, 100e18);
        _deposit(alice, usdc, 100e6);
        _deposit(bob, weth, 100e18);
        _deposit(bob, usdc, 100e6);
        _deposit(candy, weth, 100e18);
        _deposit(candy, usdc, 100e6);
        _deposit(liquidator, weth, 100e18);
        _deposit(liquidator, usdc, 100e6);
        _lendAsLimitOrder(alice, 12, 0.03e18, 12);
        _borrowAsLimitOrder(candy, 0.03e18, 12);
        uint256 loanId = _borrowAsMarketOrder(bob, alice, 15e6, 12);

        _setPrice(0.2e18);

        assertTrue(size.isLoanLiquidatable(loanId));

        vm.startPrank(liquidator);

        vm.warp(block.timestamp + 12);

        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.INVALID_LOAN_STATUS.selector, loanId, FixedLoanStatus.OVERDUE, FixedLoanStatus.ACTIVE
            )
        );
        size.liquidateFixedLoanWithReplacement(
            LiquidateFixedLoanWithReplacementParams({loanId: loanId, borrower: candy, minimumCollateralRatio: 1e18})
        );
    }
}
