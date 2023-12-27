// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {FixedPointMathLib} from "@solmate/utils/FixedPointMathLib.sol";
import {State} from "@src/SizeStorage.sol";
import {Errors} from "@src/libraries/Errors.sol";
import {Events} from "@src/libraries/Events.sol";
import {Loan, LoanLibrary, LoanStatus, RESERVED_ID, VariableLoan} from "@src/libraries/LoanLibrary.sol";

library Common {
    using LoanLibrary for Loan;

    function validateMinimumCredit(State storage state, uint256 credit) public view {
        if (credit < state.minimumCredit) {
            revert Errors.CREDIT_LOWER_THAN_MINIMUM_CREDIT(credit, state.minimumCredit);
        }
    }

    // solhint-disable-next-line var-name-mixedcase
    function createFOL(State storage state, address lender, address borrower, uint256 faceValue, uint256 dueDate)
        public
    {
        Loan memory fol = Loan({
            faceValue: faceValue,
            faceValueExited: 0,
            lender: lender,
            borrower: borrower,
            dueDate: dueDate,
            repaid: false,
            folId: RESERVED_ID
        });
        validateMinimumCredit(state, fol.getCredit());

        state.loans.push(fol);
        uint256 folId = state.loans.length - 1;

        emit Events.CreateLoan(folId, lender, borrower, RESERVED_ID, RESERVED_ID, faceValue, dueDate);
    }

    // solhint-disable-next-line var-name-mixedcase
    function createSOL(
        State storage state,
        uint256 exiterId,
        uint256 folId,
        address lender,
        address borrower,
        uint256 faceValue
    ) public {
        Loan memory fol = state.loans[folId];

        Loan memory sol = Loan({
            faceValue: faceValue,
            faceValueExited: 0,
            lender: lender,
            borrower: borrower,
            dueDate: fol.dueDate,
            repaid: false,
            folId: folId
        });

        validateMinimumCredit(state, sol.getCredit());
        state.loans.push(sol);
        uint256 solId = state.loans.length - 1;

        Loan storage exiter = state.loans[exiterId];
        exiter.faceValueExited += faceValue;
        uint256 exiterCredit = exiter.getCredit();

        if (exiterCredit > 0) {
            validateMinimumCredit(state, exiterCredit);
        }

        emit Events.CreateLoan(solId, lender, borrower, exiterId, folId, faceValue, fol.dueDate);
    }

    function createVariableLoan(
        State storage state,
        address borrower,
        uint256 amountBorrowAssetLentOut,
        uint256 amountCollateral
    ) public {
        state.variableLoans.push(
            VariableLoan({
                borrower: borrower,
                amountBorrowAssetLentOut: amountBorrowAssetLentOut,
                amountCollateral: amountCollateral,
                startTime: block.timestamp,
                repaid: false
            })
        );
    }

    function _getFOL(State storage state, Loan memory self) internal view returns (Loan memory) {
        return self.isFOL() ? self : state.loans[self.folId];
    }

    function getFOL(State storage state, Loan storage self) public view returns (Loan storage) {
        return self.isFOL() ? self : state.loans[self.folId];
    }

    function getLoanStatus(State storage state, Loan memory self) public view returns (LoanStatus) {
        if (self.faceValueExited == self.faceValue) {
            return LoanStatus.CLAIMED;
        } else if (_getFOL(state, self).repaid) {
            return LoanStatus.REPAID;
        } else if (block.timestamp >= self.dueDate) {
            return LoanStatus.OVERDUE;
        } else {
            return LoanStatus.ACTIVE;
        }
    }

    function either(State storage state, Loan memory self, LoanStatus[2] memory status) public view returns (bool) {
        return getLoanStatus(state, self) == status[0] || getLoanStatus(state, self) == status[1];
    }

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

    function getMinimumCollateralOpening(State storage state, uint256 faceValue) public view returns (uint256) {
        return FixedPointMathLib.mulDivUp(faceValue, state.crOpening, state.priceFeed.getPrice());
    }
}
