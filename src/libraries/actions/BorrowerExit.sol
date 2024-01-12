// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {FixedLoan} from "@src/libraries/FixedLoanLibrary.sol";

import {FixedLoan, FixedLoanLibrary} from "@src/libraries/FixedLoanLibrary.sol";
import {PERCENT} from "@src/libraries/MathLibrary.sol";
import {BorrowOffer, OfferLibrary} from "@src/libraries/OfferLibrary.sol";

import {Math} from "@src/libraries/MathLibrary.sol";

import {State} from "@src/SizeStorage.sol";

import {Errors} from "@src/libraries/Errors.sol";
import {Events} from "@src/libraries/Events.sol";

struct BorrowerExitParams {
    uint256 loanId;
    address borrowerToExitTo;
}

library BorrowerExit {
    using OfferLibrary for BorrowOffer;
    using FixedLoanLibrary for FixedLoan;
    using FixedLoanLibrary for FixedLoan[];

    function validateBorrowerExit(State storage state, BorrowerExitParams calldata params) external view {
        BorrowOffer memory borrowOffer = state.users[params.borrowerToExitTo].borrowOffer;
        FixedLoan memory fol = state.loans[params.loanId];

        uint256 rate = borrowOffer.getRate(fol.dueDate);
        uint256 r = PERCENT + rate;
        uint256 faceValue = fol.faceValue;
        uint256 amountIn = Math.mulDivUp(faceValue, PERCENT, r);

        // validate msg.sender
        if (msg.sender != fol.borrower) {
            revert Errors.EXITER_IS_NOT_BORROWER(msg.sender, fol.borrower);
        }
        if (state.f.borrowToken.balanceOf(msg.sender) < amountIn) {
            revert Errors.NOT_ENOUGH_FREE_CASH(state.f.borrowToken.balanceOf(msg.sender), amountIn);
        }

        // validate loanId
        if (!fol.isFOL()) {
            revert Errors.ONLY_FOL_CAN_BE_EXITED(params.loanId);
        }
        if (fol.dueDate <= block.timestamp) {
            // @audit-info BE-01 This line is not marked on the coverage report due to https://github.com/foundry-rs/foundry/issues/4854
            revert Errors.PAST_DUE_DATE(fol.dueDate);
        }

        // validate borrowerToExitTo
        if (amountIn > borrowOffer.maxAmount) {
            revert Errors.AMOUNT_GREATER_THAN_MAX_AMOUNT(amountIn, borrowOffer.maxAmount);
        }
    }

    function executeBorrowerExit(State storage state, BorrowerExitParams calldata params) external {
        emit Events.BorrowerExit(params.loanId, params.borrowerToExitTo);

        BorrowOffer storage borrowOffer = state.users[params.borrowerToExitTo].borrowOffer;
        FixedLoan storage fol = state.loans[params.loanId];

        uint256 rate = borrowOffer.getRate(fol.dueDate);
        uint256 r = PERCENT + rate;
        uint256 faceValue = fol.faceValue;
        uint256 amountIn = Math.mulDivUp(faceValue, PERCENT, r);

        state.f.borrowToken.transferFrom(msg.sender, params.borrowerToExitTo, amountIn);
        state.f.debtToken.transferFrom(msg.sender, params.borrowerToExitTo, faceValue);
        fol.borrower = params.borrowerToExitTo;
        borrowOffer.maxAmount -= amountIn;
    }
}
