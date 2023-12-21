// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {FixedPointMathLib} from "@solmate/utils/FixedPointMathLib.sol";

import {Loan} from "@src/libraries/LoanLibrary.sol";
import {Loan, LoanLibrary, LoanStatus} from "@src/libraries/LoanLibrary.sol";
import {PERCENT} from "@src/libraries/MathLibrary.sol";
import {Common} from "@src/libraries/actions/Common.sol";

import {State} from "@src/SizeStorage.sol";

import {Errors} from "@src/libraries/Errors.sol";
import {Events} from "@src/libraries/Events.sol";

struct LiquidateLoanParams {
    uint256 loanId;
}

library LiquidateLoan {
    using LoanLibrary for Loan;
    using Common for State;

    function getAssignedCollateral(State storage state, Loan memory loan) public view returns (uint256) {
        uint256 debt = state.debtToken.balanceOf(loan.borrower);
        uint256 collateral = state.collateralToken.balanceOf(loan.borrower);
        if (debt > 0) {
            return FixedPointMathLib.mulDivDown(collateral, loan.faceValue, debt);
        } else {
            return 0;
        }
    }

    function collateralRatio(State storage state, address account) public view returns (uint256) {
        uint256 collateral = state.collateralToken.balanceOf(account);
        uint256 debt = state.debtToken.balanceOf(account);
        uint256 price = state.priceFeed.getPrice();

        if (debt > 0) {
            return FixedPointMathLib.mulDivDown(collateral, price, debt);
        } else {
            return type(uint256).max;
        }
    }

    function isLiquidatable(State storage state, address account) public view returns (bool) {
        return collateralRatio(state, account) < state.crLiquidation;
    }

    function validateUserIsNotLiquidatable(State storage state, address account) external view {
        if (isLiquidatable(state, account)) {
            revert Errors.USER_IS_LIQUIDATABLE(account, collateralRatio(state, account));
        }
    }

    function validateLiquidateLoan(State storage state, LiquidateLoanParams calldata params) external view {
        Loan memory loan = state.loans[params.loanId];
        uint256 assignedCollateral = getAssignedCollateral(state, loan);
        uint256 debtCollateral =
            FixedPointMathLib.mulDivDown(loan.getDebt(), 10 ** state.priceFeed.decimals(), state.priceFeed.getPrice());

        // validate msg.sender

        // validate loanId
        if (!isLiquidatable(state, loan.borrower)) {
            revert Errors.LOAN_NOT_LIQUIDATABLE_CR(params.loanId, collateralRatio(state, loan.borrower));
        }
        if (!loan.isFOL()) {
            revert Errors.ONLY_FOL_CAN_BE_LIQUIDATED(params.loanId);
        }
        // @audit is this reachable?
        if (!state.either(loan, [LoanStatus.ACTIVE, LoanStatus.OVERDUE])) {
            revert Errors.LOAN_NOT_LIQUIDATABLE_STATUS(params.loanId, state.getLoanStatus(loan));
        }
        if (assignedCollateral < debtCollateral) {
            revert Errors.LIQUIDATION_AT_LOSS(params.loanId);
        }
    }

    function executeLiquidateLoan(State storage state, LiquidateLoanParams calldata params)
        external
        returns (uint256)
    {
        emit Events.LiquidateLoan(params.loanId);

        Loan storage fol = state.loans[params.loanId];

        uint256 assignedCollateral = getAssignedCollateral(state, fol);
        uint256 debtBorrowAsset = fol.getDebt();
        uint256 debtCollateral =
            FixedPointMathLib.mulDivDown(debtBorrowAsset, 10 ** state.priceFeed.decimals(), state.priceFeed.getPrice());
        uint256 collateralRemainder = assignedCollateral - debtCollateral;

        uint256 collateralRemainderToLiquidator =
            FixedPointMathLib.mulDivDown(collateralRemainder, state.collateralPercentagePremiumToLiquidator, PERCENT);
        uint256 collateralRemainderToBorrower =
            FixedPointMathLib.mulDivDown(collateralRemainder, state.collateralPercentagePremiumToBorrower, PERCENT);
        uint256 collateralRemainderToProtocol =
            collateralRemainder - collateralRemainderToLiquidator - collateralRemainderToBorrower;

        uint256 liquidatorProfitCollateral = debtCollateral + collateralRemainderToLiquidator;

        state.collateralToken.transferFrom(fol.borrower, state.feeRecipient, collateralRemainderToProtocol);
        state.collateralToken.transferFrom(fol.borrower, msg.sender, liquidatorProfitCollateral);
        state.borrowToken.transferFrom(msg.sender, state.protocolVault, debtBorrowAsset);
        state.debtToken.burn(fol.borrower, debtBorrowAsset);
        fol.repaid = true;

        return liquidatorProfitCollateral;
    }
}
