// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {BaseTest} from "./BaseTest.sol";
import {YieldCurveLibrary} from "@src/libraries/YieldCurveLibrary.sol";
import {User} from "@src/libraries/UserLibrary.sol";
import {PERCENT} from "@src/libraries/MathLibrary.sol";
import {LoanOffer} from "@src/libraries/OfferLibrary.sol";
import {Loan, LoanStatus} from "@src/libraries/LoanLibrary.sol";

import {FixedPointMathLib} from "@solmate/utils/FixedPointMathLib.sol";

contract ClaimTest is BaseTest {
    function test_Claim_claim_gets_loan_FV_back() public {
        _deposit(alice, 100e18, 100e18);
        _deposit(bob, 100e18, 100e18);
        _lendAsLimitOrder(alice, 100e18, 12, 0.05e4, 12);
        uint256 amountLoanId1 = 10e18;
        uint256 loanId = _borrowAsMarketOrder(bob, alice, amountLoanId1, 12);
        _repay(bob, loanId);

        uint256 FV = FixedPointMathLib.mulDivUp(PERCENT + 0.05e4, amountLoanId1, PERCENT);

        Vars memory _before = _state();

        assertEq(size.getLoanStatus(loanId), LoanStatus.REPAID);
        _claim(alice, loanId);

        Vars memory _after = _state();

        assertEq(_after.alice.borrowAsset.free, _before.alice.borrowAsset.free + FV);
        assertEq(size.getLoanStatus(loanId), LoanStatus.CLAIMED);
    }

    function test_Claim_claim_of_exited_loan_gets_credit_back() public {
        _deposit(alice, 100e18, 100e18);
        _deposit(bob, 100e18, 100e18);
        _deposit(candy, 100e18, 100e18);
        _lendAsLimitOrder(alice, 100e18, 12, 0.03e4, 12);
        uint256 loanId = _borrowAsMarketOrder(bob, alice, 100e18, 12);
        _lendAsLimitOrder(candy, 100e18, 12, 0.03e4, 12);

        address[] memory lendersToExitTo = new address[](1);
        lendersToExitTo[0] = candy;

        uint256 amountFVExited = 10e18;
        _exit(alice, loanId, amountFVExited, 12, lendersToExitTo);
        _repay(bob, loanId);

        Vars memory _before = _state();

        assertEq(size.getLoanStatus(loanId), LoanStatus.REPAID);
        _claim(alice, loanId);

        Vars memory _after = _state();

        uint256 FV = FixedPointMathLib.mulDivUp(PERCENT + 0.03e4, 100e18, PERCENT);
        uint256 credit = FV - amountFVExited;
        assertEq(_after.alice.borrowAsset.free, _before.alice.borrowAsset.free + credit);
        assertEq(size.getLoanStatus(loanId), LoanStatus.CLAIMED);
    }
}
