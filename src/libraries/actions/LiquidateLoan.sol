// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {UserLibrary, User} from "@src/libraries/UserLibrary.sol";
import {Loan} from "@src/libraries/LoanLibrary.sol";
import {LoanLibrary, LoanStatus, Loan} from "@src/libraries/LoanLibrary.sol";
import {VaultLibrary, Vault} from "@src/libraries/VaultLibrary.sol";
import {PERCENT} from "@src/libraries/MathLibrary.sol";

import {State} from "@src/SizeStorage.sol";

import {Errors} from "@src/libraries/Errors.sol";
import {Events} from "@src/libraries/Events.sol";

struct LiquidateLoanParams {
    uint256 loanId;
    address liquidator;
}

library LiquidateLoan {
    using UserLibrary for User;
    using LoanLibrary for Loan;
    using VaultLibrary for Vault;

    function _isLiquidatable(State storage state, address account) internal view returns (bool) {
        return state.users[account].isLiquidatable(state.priceFeed.getPrice(), state.crLiquidation);
    }

    function _getAssignedCollateral(State storage state, Loan memory loan) internal view returns (uint256) {
        return state.users[loan.borrower].getAssignedCollateral(loan.FV);
    }

    function validateUserIsNotLiquidatable(State storage state, address account) external view {
        if (_isLiquidatable(state, account)) {
            revert Errors.USER_IS_LIQUIDATABLE(
                account, state.users[account].collateralRatio(state.priceFeed.getPrice())
            );
        }
    }

    function validateLiquidateLoan(State storage state, LiquidateLoanParams memory params) external view {
        Loan memory loan = state.loans[params.loanId];
        uint256 assignedCollateral = _getAssignedCollateral(state, loan);
        uint256 amountCollateralDebtCoverage = loan.getDebt() * 1e18 / state.priceFeed.getPrice();

        // validate loanId
        if (!_isLiquidatable(state, loan.borrower)) {
            revert Errors.LOAN_NOT_LIQUIDATABLE(params.loanId);
        }
        if (!loan.isFOL()) {
            revert Errors.ONLY_FOL_CAN_BE_LIQUIDATED(params.loanId);
        }
        // @audit is this reachable?
        if (loan.either(state.loans, [LoanStatus.REPAID, LoanStatus.CLAIMED])) {
            revert Errors.LOAN_NOT_LIQUIDATABLE(params.loanId);
        }
        if (assignedCollateral < amountCollateralDebtCoverage) {
            revert Errors.LIQUIDATION_AT_LOSS(params.loanId);
        }

        // validate liquidator

        // validate protocol
    }

    function executeLiquidateLoan(State storage state, LiquidateLoanParams memory params) external returns (uint256) {
        Loan storage loan = state.loans[params.loanId];

        emit Events.LiquidateLoan(params.loanId, params.liquidator);

        uint256 price = state.priceFeed.getPrice();

        uint256 assignedCollateral = _getAssignedCollateral(state, loan);
        uint256 debtBorrowAsset = loan.getDebt();
        uint256 debtCollateral = debtBorrowAsset * 1e18 / price;
        uint256 collateralRemainder = assignedCollateral - debtCollateral;

        uint256 collateralRemainderToLiquidator =
            collateralRemainder * state.collateralPercentagePremiumToLiquidator / PERCENT;
        uint256 collateralRemainderToBorrower =
            collateralRemainder * state.collateralPercentagePremiumToBorrower / PERCENT;
        uint256 collateralRemainderToProtocol =
            collateralRemainder - collateralRemainderToLiquidator - collateralRemainderToBorrower;

        state.users[loan.borrower].collateralAsset.transfer(
            state.protocolCollateralAsset, collateralRemainderToProtocol
        );
        state.users[loan.borrower].collateralAsset.transfer(
            state.users[params.liquidator].collateralAsset, collateralRemainderToLiquidator + debtCollateral
        );
        state.users[params.liquidator].borrowAsset.transfer(state.protocolBorrowAsset, debtBorrowAsset);

        state.liquidationProfitCollateralAsset += collateralRemainderToProtocol;

        return debtCollateral + collateralRemainderToLiquidator;
    }
}
