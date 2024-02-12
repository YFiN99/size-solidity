// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {State} from "@src/SizeStorage.sol";

import {ConversionLibrary} from "@src/libraries/ConversionLibrary.sol";
import {Errors} from "@src/libraries/Errors.sol";

import {Math} from "@src/libraries/Math.sol";
import {Loan, LoanLibrary, LoanStatus} from "@src/libraries/fixed/LoanLibrary.sol";

/// @title RiskLibrary
library RiskLibrary {
    using LoanLibrary for State;
    using LoanLibrary for Loan;
    using LoanLibrary for LoanStatus;

    function validateMinimumCredit(State storage state, uint256 credit) public view {
        if (0 < credit && credit < state.config.minimumCreditBorrowAToken) {
            revert Errors.CREDIT_LOWER_THAN_MINIMUM_CREDIT(credit, state.config.minimumCreditBorrowAToken);
        }
    }

    function validateMinimumCreditOpening(State storage state, uint256 credit) public view {
        if (credit < state.config.minimumCreditBorrowAToken) {
            revert Errors.CREDIT_LOWER_THAN_MINIMUM_CREDIT_OPENING(credit, state.config.minimumCreditBorrowAToken);
        }
    }

    function collateralRatio(State storage state, address account) public view returns (uint256) {
        uint256 collateral = state.data.collateralToken.balanceOf(account);
        uint256 debt = state.data.debtToken.balanceOf(account);
        uint256 debtWad = ConversionLibrary.amountToWad(debt, state.data.underlyingBorrowToken.decimals());
        uint256 price = state.oracle.priceFeed.getPrice();

        if (debt > 0) {
            return Math.mulDivDown(collateral, price, debtWad);
        } else {
            return type(uint256).max;
        }
    }

    function isLoanSelfLiquidatable(State storage state, uint256 loanId) public view returns (bool) {
        Loan storage loan = state.data.loans[loanId];
        LoanStatus status = state.getLoanStatus(loan);
        // both FOLs and SOLs can be self liquidated
        return
            (isUserLiquidatable(state, loan.generic.borrower) && status.either([LoanStatus.ACTIVE, LoanStatus.OVERDUE]));
    }

    function isLoanLiquidatable(State storage state, uint256 loanId) public view returns (bool) {
        Loan storage loan = state.data.loans[loanId];
        LoanStatus status = state.getLoanStatus(loan);
        // only FOLs can be liquidated
        return loan.isFOL()
        // case 1: if the user is liquidatable, only active/overdue FOLs can be liquidated
        && (
            (isUserLiquidatable(state, loan.generic.borrower) && status.either([LoanStatus.ACTIVE, LoanStatus.OVERDUE]))
            // case 2: overdue loans can always be liquidated regardless of the user's CR
            || status == LoanStatus.OVERDUE
        );
    }

    function isUserLiquidatable(State storage state, address account) public view returns (bool) {
        return collateralRatio(state, account) < state.config.crLiquidation;
    }

    function validateUserIsNotLiquidatable(State storage state, address account) external view {
        if (isUserLiquidatable(state, account)) {
            revert Errors.USER_IS_LIQUIDATABLE(account, collateralRatio(state, account));
        }
    }

    function validateUserIsNotBelowopeningLimitBorrowCR(State storage state, address account) external view {
        uint256 openingLimitBorrowCR = Math.max(
            state.config.crOpening,
            state.data.users[account].borrowOffer.openingLimitBorrowCR // 0 by default, or user-defined if BorrowAsLimitOrder has been placed
        );
        if (collateralRatio(state, account) < openingLimitBorrowCR) {
            revert Errors.CR_BELOW_OPENING_LIMIT_BORROW_CR(
                account, collateralRatio(state, account), openingLimitBorrowCR
            );
        }
    }

    function getMinimumCollateralOpening(State storage state, uint256 faceValue) public view returns (uint256) {
        uint256 faceValueWad = ConversionLibrary.amountToWad(faceValue, state.data.underlyingBorrowToken.decimals());
        return Math.mulDivUp(faceValueWad, state.config.crOpening, state.oracle.priceFeed.getPrice());
    }
}
