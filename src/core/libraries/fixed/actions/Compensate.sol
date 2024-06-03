// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {State} from "@src/core/SizeStorage.sol";

import {Math} from "@src/core/libraries/Math.sol";

import {AccountingLibrary} from "@src/core/libraries/fixed/AccountingLibrary.sol";

import {Errors} from "@src/core/libraries/Errors.sol";
import {Events} from "@src/core/libraries/Events.sol";
import {
    CreditPosition,
    DebtPosition,
    LoanLibrary,
    LoanStatus,
    RESERVED_ID
} from "@src/core/libraries/fixed/LoanLibrary.sol";

import {RiskLibrary} from "@src/core/libraries/fixed/RiskLibrary.sol";

struct CompensateParams {
    uint256 creditPositionWithDebtToRepayId;
    uint256 creditPositionToCompensateId;
    uint256 amount;
}

library Compensate {
    using AccountingLibrary for State;
    using LoanLibrary for State;
    using LoanLibrary for DebtPosition;
    using LoanLibrary for CreditPosition;

    using RiskLibrary for State;

    function validateCompensate(State storage state, CompensateParams calldata params) external view {
        CreditPosition storage creditPositionWithDebtToRepay =
            state.getCreditPosition(params.creditPositionWithDebtToRepayId);
        DebtPosition storage debtPositionToRepay =
            state.getDebtPositionByCreditPositionId(params.creditPositionWithDebtToRepayId);

        uint256 amountToCompensate = Math.min(params.amount, creditPositionWithDebtToRepay.credit);

        // validate creditPositionWithDebtToRepayId
        if (state.getLoanStatus(params.creditPositionWithDebtToRepayId) != LoanStatus.ACTIVE) {
            revert Errors.LOAN_NOT_ACTIVE(params.creditPositionWithDebtToRepayId);
        }

        // validate creditPositionToCompensateId
        if (params.creditPositionToCompensateId == RESERVED_ID) {
            uint256 tenor = debtPositionToRepay.dueDate - block.timestamp;

            // validate tenor
            if (tenor < state.riskConfig.minTenor || tenor > state.riskConfig.maxTenor) {
                revert Errors.TENOR_OUT_OF_RANGE(tenor, state.riskConfig.minTenor, state.riskConfig.maxTenor);
            }
        } else {
            CreditPosition storage creditPositionToCompensate =
                state.getCreditPosition(params.creditPositionToCompensateId);
            DebtPosition storage debtPositionToCompensate =
                state.getDebtPositionByCreditPositionId(params.creditPositionToCompensateId);
            if (!state.isCreditPositionTransferrable(params.creditPositionToCompensateId)) {
                revert Errors.CREDIT_POSITION_NOT_TRANSFERRABLE(
                    params.creditPositionToCompensateId,
                    state.getLoanStatus(params.creditPositionToCompensateId),
                    state.collateralRatio(debtPositionToCompensate.borrower)
                );
            }
            if (
                debtPositionToRepay.dueDate
                    < state.getDebtPositionByCreditPositionId(params.creditPositionToCompensateId).dueDate
            ) {
                revert Errors.DUE_DATE_NOT_COMPATIBLE(
                    params.creditPositionWithDebtToRepayId, params.creditPositionToCompensateId
                );
            }
            if (creditPositionToCompensate.lender != debtPositionToRepay.borrower) {
                revert Errors.INVALID_LENDER(creditPositionToCompensate.lender);
            }
            if (params.creditPositionToCompensateId == params.creditPositionWithDebtToRepayId) {
                revert Errors.INVALID_CREDIT_POSITION_ID(params.creditPositionToCompensateId);
            }
            amountToCompensate = Math.min(amountToCompensate, creditPositionToCompensate.credit);
        }

        // validate msg.sender
        if (msg.sender != debtPositionToRepay.borrower) {
            revert Errors.COMPENSATOR_IS_NOT_BORROWER(msg.sender, debtPositionToRepay.borrower);
        }

        // validate amount
        if (amountToCompensate == 0) {
            revert Errors.NULL_AMOUNT();
        }
    }

    function executeCompensate(State storage state, CompensateParams calldata params) external {
        emit Events.Compensate(
            params.creditPositionWithDebtToRepayId, params.creditPositionToCompensateId, params.amount
        );

        CreditPosition storage creditPositionWithDebtToRepay =
            state.getCreditPosition(params.creditPositionWithDebtToRepayId);
        DebtPosition storage debtPositionToRepay =
            state.getDebtPositionByCreditPositionId(params.creditPositionWithDebtToRepayId);

        uint256 amountToCompensate = Math.min(params.amount, creditPositionWithDebtToRepay.credit);

        CreditPosition memory creditPositionToCompensate;
        if (params.creditPositionToCompensateId == RESERVED_ID) {
            creditPositionToCompensate = state.createDebtAndCreditPositions({
                lender: msg.sender,
                borrower: msg.sender,
                futureValue: amountToCompensate,
                dueDate: debtPositionToRepay.dueDate
            });
        } else {
            creditPositionToCompensate = state.getCreditPosition(params.creditPositionToCompensateId);
            amountToCompensate = Math.min(amountToCompensate, creditPositionToCompensate.credit);
        }

        // debt reduction
        state.repayDebt(creditPositionWithDebtToRepay.debtPositionId, amountToCompensate, false);

        // credit reduction
        // slither-disable-next-line unused-return
        state.reduceCredit(params.creditPositionWithDebtToRepayId, amountToCompensate);

        uint256 exiterCreditRemaining = creditPositionToCompensate.credit - amountToCompensate;

        // credit emission
        state.createCreditPosition({
            exitCreditPositionId: params.creditPositionToCompensateId == RESERVED_ID
                ? state.data.nextCreditPositionId - 1
                : params.creditPositionToCompensateId,
            lender: creditPositionWithDebtToRepay.lender,
            credit: amountToCompensate
        });
        if (exiterCreditRemaining > 0) {
            // charge the fragmentation fee in collateral tokens, capped by the user balance
            uint256 fragmentationFeeInCollateral = Math.min(
                state.debtTokenAmountToCollateralTokenAmount(state.feeConfig.fragmentationFee),
                state.data.collateralToken.balanceOf(msg.sender)
            );
            state.data.collateralToken.transferFrom(
                msg.sender, state.feeConfig.feeRecipient, fragmentationFeeInCollateral
            );
        }
    }
}
