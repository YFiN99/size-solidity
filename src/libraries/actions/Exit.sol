// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {SizeStorage} from "@src/SizeStorage.sol";
import {User} from "@src/libraries/UserLibrary.sol";
import {Loan} from "@src/libraries/LoanLibrary.sol";
import {OfferLibrary, LoanOffer} from "@src/libraries/OfferLibrary.sol";
import {LoanLibrary, Loan, LoanStatus} from "@src/libraries/LoanLibrary.sol";
import {RealCollateralLibrary, RealCollateral} from "@src/libraries/RealCollateralLibrary.sol";
import {PERCENT} from "@src/libraries/MathLibrary.sol";

import {FixedPointMathLib} from "@solmate/utils/FixedPointMathLib.sol";

import {ISize} from "@src/interfaces/ISize.sol";

import {State} from "@src/SizeStorage.sol";

import {Error} from "@src/libraries/Error.sol";

struct ExitParams {
    address exiter;
    uint256 loanId;
    uint256 amount;
    uint256 dueDate;
    address[] lendersToExitTo;
}

library Exit {
    using OfferLibrary for LoanOffer;
    using RealCollateralLibrary for RealCollateral;
    using LoanLibrary for Loan;
    using LoanLibrary for Loan[];

    function validateExit(State storage state, ExitParams memory params) external view {
        Loan memory loan = state.loans[params.loanId];
        // validate exiter
        if (loan.lender != params.exiter) {
            revert Error.EXITER_IS_NOT_LENDER(params.exiter, loan.lender);
        }

        // validate loanId
        if (loan.getLoanStatus(state.loans) != LoanStatus.ACTIVE) {
            revert Error.INVALID_LOAN_STATUS(params.loanId, loan.getLoanStatus(state.loans), LoanStatus.ACTIVE);
        }

        // validate amount
        if (params.amount == 0) {
            revert Error.NULL_AMOUNT();
        }
        if (params.amount > loan.getCredit()) {
            revert Error.AMOUNT_GREATER_THAN_LOAN_CREDIT(params.amount, loan.getCredit());
        }

        // validate dueDate
        if (params.dueDate < block.timestamp) {
            revert Error.PAST_DUE_DATE(params.dueDate);
        }
        // REVIEW
        // if (params.dueDate < loan.getDueDate()) {
        //     revert Error.DUE_DATE_GREATER_THAN_LOAN_DUE_DATE(params.dueDate, loan.getDueDate());
        // }

        // validate lendersToExitTo
        for (uint256 i; i < params.lendersToExitTo.length; ++i) {
            address lender = params.lendersToExitTo[i];
            User memory lenderUser = state.users[lender];

            if (lender == address(0)) {
                revert Error.NULL_ADDRESS();
            }
            if (lenderUser.loanOffer.isNull()) {
                revert Error.INVALID_LOAN_OFFER(lender);
            }
            // @audit should we prevent exit to self?
            // if (lender == params.exiter) {
            //     revert Error.INVALID_LENDER(lender);
            // }
        }
    }

    // NOTE: The exit is equivalent to a spot swap for exact amount in wheres
    // - the exiting lender is the taker
    // - the other lenders are the makers
    // The swap traverses the `loanOfferIds` as they if they were ticks with liquidity in an orderbook
    function executeExit(State storage state, ExitParams memory params) external returns (uint256 amountInLeft) {
        User storage exiterUser = state.users[params.exiter];

        amountInLeft = params.amount;
        for (uint256 i = 0; i < params.lendersToExitTo.length; ++i) {
            if (amountInLeft == 0) {
                // No more amountIn to swap
                break;
            }

            address lender = params.lendersToExitTo[i];
            User storage lenderUser = state.users[lender];
            LoanOffer storage loanOffer = lenderUser.loanOffer;

            uint256 r = PERCENT + loanOffer.getRate(params.dueDate);
            uint256 deltaAmountIn;
            uint256 deltaAmountOut;
            // @audit check rounding direction
            if (amountInLeft > loanOffer.maxAmount) {
                deltaAmountIn = FixedPointMathLib.mulDivUp(r, loanOffer.maxAmount, PERCENT);
                deltaAmountOut = loanOffer.maxAmount;
            } else {
                deltaAmountIn = amountInLeft;
                deltaAmountOut = FixedPointMathLib.mulDivUp(deltaAmountIn, PERCENT, r);
            }

            state.loans.createSOL(params.loanId, lender, params.exiter, deltaAmountIn);
            lenderUser.cash.transfer(exiterUser.cash, deltaAmountOut);
            loanOffer.maxAmount -= deltaAmountOut;
            amountInLeft -= deltaAmountIn;
        }
    }
}
