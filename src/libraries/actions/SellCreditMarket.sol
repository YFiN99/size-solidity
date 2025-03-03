// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {CreditPosition, DebtPosition, LoanLibrary, RESERVED_ID} from "@src/libraries/LoanLibrary.sol";
import {Math, PERCENT} from "@src/libraries/Math.sol";
import {LimitOrder, OfferLibrary} from "@src/libraries/OfferLibrary.sol";
import {VariablePoolBorrowRateParams} from "@src/libraries/YieldCurveLibrary.sol";

import {State} from "@src/SizeStorage.sol";

import {AccountingLibrary} from "@src/libraries/AccountingLibrary.sol";
import {RiskLibrary} from "@src/libraries/RiskLibrary.sol";

import {Errors} from "@src/libraries/Errors.sol";
import {Events} from "@src/libraries/Events.sol";

struct SellCreditMarketParams {
    // The lender
    address lender;
    // The credit position ID to sell
    // If RESERVED_ID, a new credit position will be created
    uint256 creditPositionId;
    // The amount of credit to sell
    uint256 amount;
    // The tenor of the loan
    // If creditPositionId is not RESERVED_ID, this value is ignored and the tenor of the existing loan is used
    uint256 tenor;
    // The deadline for the transaction
    uint256 deadline;
    // The maximum APR for the loan
    uint256 maxAPR;
    // Whether amount means credit or cash
    bool exactAmountIn;
}

/// @title SellCreditMarket
/// @custom:security-contact security@size.credit
/// @author Size (https://size.credit/)
/// @notice Contains the logic for selling credit (borrowing) as a market order
library SellCreditMarket {
    using OfferLibrary for LimitOrder;
    using LoanLibrary for DebtPosition;
    using LoanLibrary for CreditPosition;
    using LoanLibrary for State;
    using RiskLibrary for State;
    using AccountingLibrary for State;

    struct SwapDataSellCreditMarket {
        uint256 creditAmountIn;
        uint256 cashAmountOut;
        uint256 swapFee;
        uint256 fragmentationFee;
        uint256 tenor;
    }

    /// @notice Validates the input parameters for selling credit as a market order
    /// @param state The state
    /// @param params The input parameters for selling credit as a market order
    function validateSellCreditMarket(State storage state, SellCreditMarketParams calldata params) external view {
        LimitOrder memory loanOffer = state.data.users[params.lender].loanOffer;
        uint256 tenor;

        // validate msg.sender
        // N/A

        // validate lender
        if (loanOffer.isNull()) {
            revert Errors.INVALID_LOAN_OFFER(params.lender);
        }

        // validate creditPositionId
        if (params.creditPositionId == RESERVED_ID) {
            tenor = params.tenor;

            // validate tenor
            if (tenor < state.riskConfig.minTenor || tenor > state.riskConfig.maxTenor) {
                revert Errors.TENOR_OUT_OF_RANGE(tenor, state.riskConfig.minTenor, state.riskConfig.maxTenor);
            }
        } else {
            CreditPosition storage creditPosition = state.getCreditPosition(params.creditPositionId);
            DebtPosition storage debtPosition = state.getDebtPositionByCreditPositionId(params.creditPositionId);
            if (msg.sender != creditPosition.lender) {
                revert Errors.BORROWER_IS_NOT_LENDER(msg.sender, creditPosition.lender);
            }
            if (!state.isCreditPositionTransferrable(params.creditPositionId)) {
                revert Errors.CREDIT_POSITION_NOT_TRANSFERRABLE(
                    params.creditPositionId,
                    state.getLoanStatus(params.creditPositionId),
                    state.collateralRatio(debtPosition.borrower)
                );
            }
            tenor = debtPosition.dueDate - block.timestamp; // positive since the credit position is transferrable, so the loan must be ACTIVE
        }

        // validate amount
        if (params.amount == 0) {
            revert Errors.NULL_AMOUNT();
        }

        // validate tenor
        if (block.timestamp + tenor > loanOffer.maxDueDate) {
            revert Errors.DUE_DATE_GREATER_THAN_MAX_DUE_DATE(block.timestamp + tenor, loanOffer.maxDueDate);
        }

        // validate deadline
        if (params.deadline < block.timestamp) {
            revert Errors.PAST_DEADLINE(params.deadline);
        }

        // validate maxAPR
        uint256 apr = loanOffer.getAPRByTenor(
            VariablePoolBorrowRateParams({
                variablePoolBorrowRate: state.oracle.variablePoolBorrowRate,
                variablePoolBorrowRateUpdatedAt: state.oracle.variablePoolBorrowRateUpdatedAt,
                variablePoolBorrowRateStaleRateInterval: state.oracle.variablePoolBorrowRateStaleRateInterval
            }),
            tenor
        );
        if (apr > params.maxAPR) {
            revert Errors.APR_GREATER_THAN_MAX_APR(apr, params.maxAPR);
        }

        // validate exactAmountIn
        // N/A
    }

    /// @notice Executes the selling of credit as a market order
    /// @param state The state
    /// @param params The input parameters for selling credit as a market order
    function executeSellCreditMarket(State storage state, SellCreditMarketParams calldata params)
        external
        returns (uint256 cashAmountOut)
    {
        emit Events.SellCreditMarket(
            params.lender, params.creditPositionId, params.tenor, params.amount, params.tenor, params.exactAmountIn
        );

        // slither-disable-next-line uninitialized-local
        SwapDataSellCreditMarket memory swapData;

        // slither-disable-next-line uninitialized-local
        CreditPosition memory creditPosition;
        if (params.creditPositionId == RESERVED_ID) {
            swapData.tenor = params.tenor;
        } else {
            DebtPosition storage debtPosition = state.getDebtPositionByCreditPositionId(params.creditPositionId);
            creditPosition = state.getCreditPosition(params.creditPositionId);

            swapData.tenor = debtPosition.dueDate - block.timestamp;
        }

        uint256 ratePerTenor = state.data.users[params.lender].loanOffer.getRatePerTenor(
            VariablePoolBorrowRateParams({
                variablePoolBorrowRate: state.oracle.variablePoolBorrowRate,
                variablePoolBorrowRateUpdatedAt: state.oracle.variablePoolBorrowRateUpdatedAt,
                variablePoolBorrowRateStaleRateInterval: state.oracle.variablePoolBorrowRateStaleRateInterval
            }),
            swapData.tenor
        );

        if (params.exactAmountIn) {
            swapData.creditAmountIn = params.amount;

            (cashAmountOut, swapData.swapFee, swapData.fragmentationFee) = state.getCashAmountOut({
                creditAmountIn: swapData.creditAmountIn,
                maxCredit: params.creditPositionId == RESERVED_ID ? swapData.creditAmountIn : creditPosition.credit,
                ratePerTenor: ratePerTenor,
                tenor: swapData.tenor
            });
        } else {
            cashAmountOut = params.amount;

            (swapData.creditAmountIn, swapData.swapFee, swapData.fragmentationFee) = state.getCreditAmountIn({
                cashAmountOut: cashAmountOut,
                maxCashAmountOut: params.creditPositionId == RESERVED_ID
                    ? cashAmountOut
                    : Math.mulDivDown(
                        creditPosition.credit, PERCENT - state.getSwapFeePercent(swapData.tenor), PERCENT + ratePerTenor
                    ),
                maxCredit: params.creditPositionId == RESERVED_ID
                    ? Math.mulDivUp(cashAmountOut, PERCENT + ratePerTenor, PERCENT - state.getSwapFeePercent(swapData.tenor))
                    : creditPosition.credit,
                ratePerTenor: ratePerTenor,
                tenor: swapData.tenor
            });
        }

        if (params.creditPositionId == RESERVED_ID) {
            // slither-disable-next-line unused-return
            state.createDebtAndCreditPositions({
                lender: msg.sender,
                borrower: msg.sender,
                futureValue: swapData.creditAmountIn,
                dueDate: block.timestamp + swapData.tenor
            });
        }

        uint256 exitCreditPositionId =
            params.creditPositionId == RESERVED_ID ? state.data.nextCreditPositionId - 1 : params.creditPositionId;

        state.createCreditPosition({
            exitCreditPositionId: exitCreditPositionId,
            lender: params.lender,
            credit: swapData.creditAmountIn,
            forSale: true
        });
        state.data.borrowAToken.transferFrom(params.lender, msg.sender, cashAmountOut);
        state.data.borrowAToken.transferFrom(
            params.lender, state.feeConfig.feeRecipient, swapData.swapFee + swapData.fragmentationFee
        );

        emit Events.SwapData(
            exitCreditPositionId,
            msg.sender,
            params.lender,
            swapData.creditAmountIn,
            cashAmountOut + swapData.swapFee + swapData.fragmentationFee,
            cashAmountOut,
            swapData.swapFee,
            swapData.fragmentationFee,
            swapData.tenor
        );
    }
}
