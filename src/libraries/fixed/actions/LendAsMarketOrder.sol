// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {PERCENT} from "@src/libraries/Math.sol";

import {AccountingLibrary} from "@src/libraries/fixed/AccountingLibrary.sol";

import {CreditPosition, DebtPosition, LoanLibrary} from "@src/libraries/fixed/LoanLibrary.sol";
import {BorrowOffer, OfferLibrary} from "@src/libraries/fixed/OfferLibrary.sol";

import {Math} from "@src/libraries/Math.sol";

import {State} from "@src/SizeStorage.sol";

import {Errors} from "@src/libraries/Errors.sol";
import {Events} from "@src/libraries/Events.sol";

struct LendAsMarketOrderParams {
    address borrower;
    uint256 dueDate;
    uint256 amount;
    uint256 deadline;
    uint256 minAPR;
    bool exactAmountIn;
}

library LendAsMarketOrder {
    using OfferLibrary for BorrowOffer;
    using AccountingLibrary for State;
    using LoanLibrary for State;
    using LoanLibrary for DebtPosition;
    using LoanLibrary for CreditPosition;

    function validateLendAsMarketOrder(State storage state, LendAsMarketOrderParams calldata params) external view {
        BorrowOffer memory borrowOffer = state.data.users[params.borrower].borrowOffer;

        // validate msg.sender
        // N/A

        // validate borrower
        if (borrowOffer.isNull()) {
            revert Errors.INVALID_BORROW_OFFER(params.borrower);
        }

        // validate dueDate
        if (params.dueDate < block.timestamp + state.riskConfig.minimumMaturity) {
            revert Errors.PAST_DUE_DATE(params.dueDate);
        }
        if (params.dueDate > block.timestamp + state.riskConfig.maximumMaturity) {
            revert Errors.DUE_DATE_GREATER_THAN_MAX_DUE_DATE(
                params.dueDate, block.timestamp + state.riskConfig.maximumMaturity
            );
        }

        // validate amount
        if (params.amount < state.riskConfig.minimumCreditBorrowAToken) {
            revert Errors.CREDIT_LOWER_THAN_MINIMUM_CREDIT(params.amount, state.riskConfig.minimumCreditBorrowAToken);
        }

        // validate deadline
        if (params.deadline < block.timestamp) {
            revert Errors.PAST_DEADLINE(params.deadline);
        }

        // validate minAPR
        uint256 apr = borrowOffer.getAPRByDueDate(state.oracle.variablePoolBorrowRateFeed, params.dueDate);
        if (apr < params.minAPR) {
            revert Errors.APR_LOWER_THAN_MIN_APR(apr, params.minAPR);
        }

        // validate exactAmountIn
        // N/A
    }

    function executeLendAsMarketOrder(State storage state, LendAsMarketOrderParams calldata params)
        external
        returns (uint256 cashAmountIn)
    {
        emit Events.LendAsMarketOrder(params.borrower, params.dueDate, params.amount, params.exactAmountIn);

        uint256 ratePerMaturity = state.data.users[params.borrower].borrowOffer.getRatePerMaturityByDueDate(
            state.oracle.variablePoolBorrowRateFeed, params.dueDate
        );

        uint256 creditAmountOut;
        uint256 fees;

        if (params.exactAmountIn) {
            cashAmountIn = params.amount;
            (creditAmountOut, fees) = state.getCreditAmountOut({
                cashAmountIn: cashAmountIn,
                maxCredit: Math.mulDivDown(cashAmountIn, PERCENT + ratePerMaturity, PERCENT),
                ratePerMaturity: ratePerMaturity,
                dueDate: params.dueDate
            });
        } else {
            creditAmountOut = params.amount;
            (cashAmountIn, fees) = state.getCashAmountIn({
                creditAmountOut: creditAmountOut,
                maxCredit: creditAmountOut,
                ratePerMaturity: ratePerMaturity,
                dueDate: params.dueDate
            });
        }

        // slither-disable-next-line unused-return
        state.createDebtAndCreditPositions({
            lender: msg.sender,
            borrower: params.borrower,
            faceValue: creditAmountOut,
            dueDate: params.dueDate
        });
        state.data.borrowAToken.transferFrom(msg.sender, params.borrower, cashAmountIn - fees);
        state.data.borrowAToken.transferFrom(msg.sender, state.feeConfig.feeRecipient, fees);
    }
}
