// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {State} from "@src/SizeStorage.sol";

import {ConversionLibrary} from "@src/libraries/ConversionLibrary.sol";
import {Errors} from "@src/libraries/Errors.sol";
import {Math, PERCENT} from "@src/libraries/Math.sol";
import {AccountingLibrary} from "@src/libraries/fixed/AccountingLibrary.sol";

uint256 constant DEBT_POSITION_ID_START = 0;
uint256 constant CREDIT_POSITION_ID_START = type(uint256).max / 2;
uint256 constant RESERVED_ID = type(uint256).max;

struct DebtPosition {
    address lender;
    address borrower;
    uint256 issuanceValue; // updated on repayment
    uint256 rate;
    uint256 repayFeeAPR;
    uint256 startDate; // updated opon borrower replacement
    uint256 dueDate;
    uint256 liquidityIndexAtRepayment; // set on repayment
}

struct CreditPosition {
    address lender;
    address borrower;
    uint256 credit;
    uint256 debtPositionId;
}

// When the loan is created, it is in ACTIVE status
// When maturity is reached, it is in OVERDUE status
// If the loan is not repaid and the CR is sufficient, it is moved to the Variable Pool,
//   otherwise it is eligible for liquidation but if the CR < 100% then it will remain in
//   the overdue state until the CR is > 100% or the lenders perform self liquidation
// When the loan is repaid either by the borrower or by the liquidator, it is in REPAID status
enum LoanStatus {
    ACTIVE, // not yet due
    OVERDUE, // eligible to liquidation
    REPAID // by borrower or liquidator

}

/// @title LoanLibrary
library LoanLibrary {
    using AccountingLibrary for State;

    function isDebtPositionId(State storage state, uint256 positionId) internal view returns (bool) {
        return positionId >= DEBT_POSITION_ID_START && positionId < state.data.nextDebtPositionId;
    }

    function isCreditPositionId(State storage state, uint256 positionId) internal view returns (bool) {
        return positionId >= CREDIT_POSITION_ID_START && positionId < state.data.nextCreditPositionId;
    }

    function getDebt(DebtPosition memory self) internal pure returns (uint256) {
        return faceValue(self) + repayFee(self);
    }

    function faceValue(DebtPosition memory self) internal pure returns (uint256) {
        return Math.mulDivUp(self.issuanceValue, PERCENT + self.rate, PERCENT);
    }

    function faceValueInCollateralToken(State storage state, DebtPosition memory self)
        internal
        view
        returns (uint256)
    {
        uint256 debtBorrowTokenWad =
            ConversionLibrary.amountToWad(faceValue(self), state.data.underlyingBorrowToken.decimals());
        uint256 debtInCollateralToken = Math.mulDivDown(
            debtBorrowTokenWad, 10 ** state.oracle.priceFeed.decimals(), state.oracle.priceFeed.getPrice()
        );
        return debtInCollateralToken;
    }

    function getDebtPositionIdByCreditPositionId(State storage state, uint256 creditPositionId)
        public
        view
        returns (uint256)
    {
        return getCreditPosition(state, creditPositionId).debtPositionId;
    }

    function getDebtPosition(State storage state, uint256 debtPositionId) public view returns (DebtPosition storage) {
        if (isDebtPositionId(state, debtPositionId)) {
            return state.data.debtPositions[debtPositionId];
        } else {
            revert Errors.INVALID_DEBT_POSITION_ID(debtPositionId);
        }
    }

    function getCreditPosition(State storage state, uint256 creditPositionId)
        public
        view
        returns (CreditPosition storage)
    {
        if (isCreditPositionId(state, creditPositionId)) {
            return state.data.creditPositions[creditPositionId];
        } else {
            revert Errors.INVALID_CREDIT_POSITION_ID(creditPositionId);
        }
    }

    function getDebtPositionByCreditPositionId(State storage state, uint256 creditPositionId)
        public
        view
        returns (DebtPosition storage)
    {
        CreditPosition memory creditPosition = getCreditPosition(state, creditPositionId);
        return getDebtPosition(state, creditPosition.debtPositionId);
    }

    /// @notice Get the status of a loan
    /// @param state The state struct
    /// @param positionId The positionId (can be either a DebtPosition or a CreditPosition)
    /// @return The status of the loan
    function getLoanStatus(State storage state, uint256 positionId) public view returns (LoanStatus) {
        // assumes `positionId` is a debt position id
        DebtPosition memory debtPosition = state.data.debtPositions[positionId];
        if (isCreditPositionId(state, positionId)) {
            // if `positionId` is in reality a credit position id, updates the memory variable
            debtPosition = getDebtPositionByCreditPositionId(state, positionId);
        } else if (!isDebtPositionId(state, positionId)) {
            // if `positionId` is neither a debt position id nor a credit position id, reverts
            revert Errors.INVALID_POSITION_ID(positionId);
        }

        if (getDebt(debtPosition) == 0) {
            return LoanStatus.REPAID;
        } else if (block.timestamp >= debtPosition.dueDate) {
            return LoanStatus.OVERDUE;
        } else {
            return LoanStatus.ACTIVE;
        }
    }

    /// @notice Get the amount of collateral assigned to a DebtPosition
    /// @dev Takes into account the total debt of the user, which includes the repayment fee
    ///      When used to calculate the amount of collateral on liquidations, the repayment fee must be excluded first from the user debt
    /// @param state The state struct
    /// @param debtPosition The DebtPosition
    /// @return The amount of collateral assigned to the DebtPosition
    function getDebtPositionAssignedCollateral(State storage state, DebtPosition memory debtPosition)
        public
        view
        returns (uint256)
    {
        uint256 debt = state.data.debtToken.balanceOf(debtPosition.borrower);
        uint256 collateral = state.data.collateralToken.balanceOf(debtPosition.borrower);

        if (debt > 0) {
            return Math.mulDivDown(collateral, faceValue(debtPosition), debt);
        } else {
            return 0;
        }
    }

    /// @notice Get the amount of collateral assigned to a CreditPosition, pro-rata to the DebtPosition's faceValue
    /// @dev Takes into account the total debt of the user, which includes the repayment fee
    ///      When used to calculate the amount of collateral on liquidations, the repayment fee must be excluded first from the user debt
    /// @param state The state struct
    /// @param creditPosition The CreditPosition
    /// @return The amount of collateral assigned to the CreditPosition
    function getCreditPositionProRataAssignedCollateral(State storage state, CreditPosition memory creditPosition)
        public
        view
        returns (uint256)
    {
        DebtPosition storage debtPosition = getDebtPosition(state, creditPosition.debtPositionId);

        uint256 creditPositionCredit = creditPosition.credit;
        uint256 debtPositionCollateral = getDebtPositionAssignedCollateral(state, debtPosition);
        uint256 debtPositionFaceValue = faceValue(debtPosition);

        if (debtPositionFaceValue > 0) {
            return Math.mulDivDown(debtPositionCollateral, creditPositionCredit, debtPositionFaceValue);
        } else {
            return 0;
        }
    }

    function repayFee(uint256 issuanceValue, uint256 startDate, uint256 dueDate, uint256 repayFeeAPR)
        internal
        pure
        returns (uint256)
    {
        uint256 interval = dueDate - startDate;
        uint256 repayFeePercent = Math.mulDivUp(repayFeeAPR, interval, 365 days);
        uint256 fee = Math.mulDivUp(issuanceValue, repayFeePercent, PERCENT);
        return fee;
    }

    function repayFee(DebtPosition memory self) internal pure returns (uint256) {
        return repayFee(self.issuanceValue, self.startDate, self.dueDate, self.repayFeeAPR);
    }

    function partialRepayFee(DebtPosition memory self, uint256 repayAmount) internal pure returns (uint256) {
        return Math.mulDivUp(repayAmount, repayFee(self), faceValue(self));
    }
}
