// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {VariableLibrary} from "@src/libraries/variable/VariableLibrary.sol";

import {PERCENT} from "@src/libraries/Math.sol";

import {AccountingLibrary} from "@src/libraries/fixed/AccountingLibrary.sol";

import {DebtPosition, LoanLibrary} from "@src/libraries/fixed/LoanLibrary.sol";
import {BorrowOffer, OfferLibrary} from "@src/libraries/fixed/OfferLibrary.sol";

import {Math} from "@src/libraries/Math.sol";

import {State} from "@src/SizeStorage.sol";

import {Errors} from "@src/libraries/Errors.sol";
import {Events} from "@src/libraries/Events.sol";

struct BorrowerExitParams {
    uint256 debtPositionId;
    address borrowerToExitTo;
    uint256 deadline;
    uint256 minAPR;
}

library BorrowerExit {
    using OfferLibrary for BorrowOffer;
    using LoanLibrary for DebtPosition;
    using LoanLibrary for State;
    using VariableLibrary for State;
    using AccountingLibrary for State;

    function validateBorrowerExit(State storage state, BorrowerExitParams calldata params) external view {
        BorrowOffer memory borrowOffer = state.data.users[params.borrowerToExitTo].borrowOffer;
        DebtPosition memory debtPosition = state.getDebtPosition(params.debtPositionId);

        // validate debtPositionId
        uint256 dueDate = debtPosition.dueDate;
        if (dueDate < block.timestamp) {
            revert Errors.PAST_DUE_DATE(debtPosition.dueDate);
        }
        uint256 maturity = dueDate - block.timestamp;
        if (maturity < state.riskConfig.minimumMaturity) {
            revert Errors.MATURITY_BELOW_MINIMUM_MATURITY(maturity, state.riskConfig.minimumMaturity);
        }

        uint256 ratePerMaturity = borrowOffer.getRatePerMaturityByDueDate(state.oracle.marketBorrowRateFeed, dueDate);
        uint256 issuanceValue = Math.mulDivUp(debtPosition.faceValue, PERCENT, PERCENT + ratePerMaturity);

        // validate msg.sender
        if (msg.sender != debtPosition.borrower) {
            revert Errors.EXITER_IS_NOT_BORROWER(msg.sender, debtPosition.borrower);
        }
        if (
            state.aTokenBalanceOf(state.data.borrowAToken, msg.sender, false)
                < issuanceValue + state.feeConfig.earlyBorrowerExitFee
        ) {
            revert Errors.NOT_ENOUGH_ATOKEN_BALANCE(
                address(state.data.borrowAToken),
                msg.sender,
                false,
                state.aTokenBalanceOf(state.data.borrowAToken, msg.sender, false),
                issuanceValue + state.feeConfig.earlyBorrowerExitFee
            );
        }

        // validate deadline
        if (params.deadline < block.timestamp) {
            revert Errors.PAST_DEADLINE(params.deadline);
        }

        // validate minAPR
        if (Math.ratePerMaturityToLinearAPR(ratePerMaturity, maturity) < params.minAPR) {
            revert Errors.APR_LOWER_THAN_MIN_APR(
                Math.ratePerMaturityToLinearAPR(ratePerMaturity, maturity), params.minAPR
            );
        }

        // validate borrowerToExitTo
        // N/A
    }

    function executeBorrowerExit(State storage state, BorrowerExitParams calldata params) external {
        emit Events.BorrowerExit(params.debtPositionId, params.borrowerToExitTo);

        BorrowOffer storage borrowOffer = state.data.users[params.borrowerToExitTo].borrowOffer;
        DebtPosition storage debtPosition = state.data.debtPositions[params.debtPositionId];

        uint256 ratePerMaturity =
            borrowOffer.getRatePerMaturityByDueDate(state.oracle.marketBorrowRateFeed, debtPosition.dueDate);

        uint256 faceValue = debtPosition.faceValue;
        uint256 issuanceValue = Math.mulDivUp(faceValue, PERCENT, PERCENT + ratePerMaturity);

        uint256 repayFee = state.chargeEarlyRepayFeeInCollateral(debtPosition);
        debtPosition.updateRepayFee(faceValue, repayFee);
        state.transferBorrowATokenFixed(msg.sender, state.feeConfig.feeRecipient, state.feeConfig.earlyBorrowerExitFee);
        state.transferBorrowATokenFixed(msg.sender, params.borrowerToExitTo, issuanceValue);
        state.data.debtToken.burn(msg.sender, faceValue);

        debtPosition.borrower = params.borrowerToExitTo;
        debtPosition.startDate = block.timestamp;
        debtPosition.issuanceValue = issuanceValue;
        debtPosition.faceValue = faceValue;
        debtPosition.repayFee =
            LoanLibrary.repayFee(issuanceValue, block.timestamp, debtPosition.dueDate, state.feeConfig.repayFeeAPR);

        state.data.debtToken.mint(params.borrowerToExitTo, debtPosition.getDebt());
    }
}
