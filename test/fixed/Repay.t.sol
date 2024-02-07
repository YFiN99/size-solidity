// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {BaseTest} from "@test/BaseTest.sol";
import {Vars} from "@test/BaseTestGeneral.sol";

import {Errors} from "@src/libraries/Errors.sol";

import {PERCENT} from "@src/libraries/Math.sol";
import {FixedLoanStatus} from "@src/libraries/fixed/FixedLoanLibrary.sol";
import {RepayParams} from "@src/libraries/fixed/actions/Repay.sol";

import {Math} from "@src/libraries/Math.sol";

contract RepayTest is BaseTest {
    function test_Repay_repay_full_FOL() public {
        _deposit(alice, weth, 100e18);
        _deposit(alice, usdc, 100e6);
        _deposit(bob, weth, 100e18);
        _deposit(bob, usdc, 100e6);
        _deposit(candy, weth, 100e18);
        _deposit(candy, usdc, 100e6);
        _lendAsLimitOrder(alice, 12, 0.05e18, 12);
        uint256 amountFixedLoanId1 = 10e6;
        uint256 loanId = _borrowAsMarketOrder(bob, alice, amountFixedLoanId1, 12);
        uint256 faceValue = Math.mulDivUp(amountFixedLoanId1, PERCENT + 0.05e18, PERCENT);
        uint256 repayFee = size.maximumRepayFee(loanId);

        Vars memory _before = _state();

        _repay(bob, loanId);

        Vars memory _after = _state();

        assertEq(_after.bob.debtAmount, _before.bob.debtAmount - faceValue - repayFee);
        assertEq(_after.bob.borrowAmount, _before.bob.borrowAmount - faceValue);
        assertEq(_after.alice.borrowAmount, _before.alice.borrowAmount);
        assertEq(_after.size.borrowAmount, _before.size.borrowAmount + faceValue);
        assertEq(_after.variablePool.borrowAmount, _before.variablePool.borrowAmount);
        assertEq(size.getDebt(loanId), 0);
    }

    function test_Repay_repay_partial_FOL() internal {}

    function test_Repay_overdue_does_not_increase_debt() public {
        _deposit(alice, weth, 100e18);
        _deposit(alice, usdc, 100e6);
        _deposit(bob, weth, 100e18);
        _deposit(bob, usdc, 100e6);
        _deposit(candy, weth, 100e18);
        _deposit(candy, usdc, 100e6);
        _lendAsLimitOrder(alice, 12, 0.05e18, 12);
        uint256 amountFixedLoanId1 = 10e6;
        uint256 loanId = _borrowAsMarketOrder(bob, alice, amountFixedLoanId1, 12);
        uint256 faceValue = Math.mulDivUp(amountFixedLoanId1, PERCENT + 0.05e18, PERCENT);
        uint256 repayFee = size.maximumRepayFee(loanId);

        Vars memory _before = _state();
        assertEq(size.getFixedLoanStatus(loanId), FixedLoanStatus.ACTIVE);

        vm.warp(365 days);

        Vars memory _overdue = _state();

        assertEq(_overdue.bob.debtAmount, _before.bob.debtAmount);
        assertEq(_overdue.bob.borrowAmount, _before.bob.borrowAmount);
        assertEq(_overdue.variablePool.borrowAmount, _before.variablePool.borrowAmount);
        assertGt(size.getDebt(loanId), 0);
        assertEq(size.getFixedLoanStatus(loanId), FixedLoanStatus.OVERDUE);

        _repay(bob, loanId);

        Vars memory _after = _state();

        assertEq(_after.bob.debtAmount, _before.bob.debtAmount - faceValue - repayFee);
        assertEq(_after.bob.borrowAmount, _before.bob.borrowAmount - faceValue);
        assertEq(_after.variablePool.borrowAmount, _before.variablePool.borrowAmount);
        assertEq(_after.alice.borrowAmount, _before.alice.borrowAmount);
        assertEq(_after.size.borrowAmount, _before.size.borrowAmount + faceValue);
        assertEq(size.getDebt(loanId), 0);
        assertEq(size.getFixedLoanStatus(loanId), FixedLoanStatus.REPAID);
    }

    function test_Repay_repay_claimed_should_revert() public {
        _deposit(alice, weth, 100e18);
        _deposit(alice, usdc, 100e6);
        _deposit(bob, weth, 100e18);
        _deposit(bob, usdc, 200e6);
        _deposit(candy, weth, 100e18);
        _deposit(candy, usdc, 100e6);
        _lendAsLimitOrder(alice, 12, 1e18, 12);
        _lendAsLimitOrder(candy, 12, 1e18, 12);
        uint256 loanId = _borrowAsMarketOrder(bob, alice, 100e6, 12);
        _borrowAsMarketOrder(bob, candy, 100e6, 12);

        Vars memory _before = _state();

        _repay(bob, loanId);
        _claim(bob, loanId);

        Vars memory _after = _state();

        assertEq(_after.alice.borrowAmount, _before.alice.borrowAmount + 200e6);
        assertEq(_after.bob.borrowAmount, _before.bob.borrowAmount - 200e6);
        assertEq(_after.variablePool.borrowAmount, _before.variablePool.borrowAmount);
        assertEq(_after.size.borrowAmount, _before.size.borrowAmount, 0);

        vm.expectRevert(abi.encodeWithSelector(Errors.LOAN_ALREADY_REPAID.selector, loanId));
        _repay(bob, loanId);
    }

    function test_Repay_repay_partial_cannot_leave_loan_below_minimumCreditBorrowAsset() internal {}

    function testFuzz_Repay_repay_partial_cannot_leave_loan_below_minimumCreditBorrowAsset(
        uint256 borrowAmount,
        uint256 repayAmount
    ) public {
        borrowAmount = bound(borrowAmount, size.fixedConfig().minimumCreditBorrowAsset, 100e6);
        repayAmount = bound(repayAmount, 0, borrowAmount);

        _setPrice(1e18);
        _deposit(alice, usdc, 100e6);
        _deposit(bob, weth, 160e18);
        _lendAsLimitOrder(alice, 12, 0, 12);
        uint256 loanId = _borrowAsMarketOrder(bob, alice, borrowAmount, 12);

        vm.prank(bob);
        try size.repay(RepayParams({loanId: loanId})) {} catch {}
        assertGe(size.getCredit(loanId), size.fixedConfig().minimumCreditBorrowAsset);
    }

    function test_Repay_repay_pays_repayFeeAPR() private {}

    function test_Repay_repay_pays_repayFeeAPR_at_different_times_different_amounts() private {}
}
