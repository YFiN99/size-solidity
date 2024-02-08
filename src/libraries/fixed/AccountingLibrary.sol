// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {State} from "@src/SizeStorage.sol";
import {ConversionLibrary} from "@src/libraries/ConversionLibrary.sol";

import {Events} from "@src/libraries/Events.sol";
import {Math, PERCENT} from "@src/libraries/Math.sol";

import {VariableLibrary} from "@src/libraries/variable/VariableLibrary.sol";

import {FOL, GenericLoan, Loan, LoanLibrary, RESERVED_ID, SOL} from "@src/libraries/fixed/LoanLibrary.sol";
import {RiskLibrary} from "@src/libraries/fixed/RiskLibrary.sol";

library AccountingLibrary {
    using RiskLibrary for State;
    using LoanLibrary for Loan;
    using LoanLibrary for State;
    using VariableLibrary for State;

    function reduceLoanCredit(State storage state, uint256 loanId, uint256 amount) public {
        Loan storage loan = state.data.loans[loanId];

        loan.generic.credit -= amount;

        state.validateMinimumCredit(loan.generic.credit);
    }

    function maximumRepayFee(State storage state, uint256 issuanceValue, uint256 startDate, uint256 dueDate)
        internal
        view
        returns (uint256)
    {
        uint256 interval = dueDate - startDate;
        uint256 repayFeePercent = Math.mulDivUp(state.config.repayFeeAPR, interval, 365 days);
        uint256 fee = Math.mulDivUp(issuanceValue, repayFeePercent, PERCENT);
        return fee;
    }

    function maximumRepayFee(State storage state, Loan memory fol) internal view returns (uint256) {
        return maximumRepayFee(state, fol.fol.issuanceValue, fol.fol.startDate, fol.fol.dueDate);
    }

    function partialRepayFee(State storage state, Loan memory fol, uint256 repayAmount)
        internal
        view
        returns (uint256)
    {
        // pending question about calculating parial repay fee
        return Math.mulDivUp(repayAmount, maximumRepayFee(state, fol), fol.faceValue());
    }

    function chargeRepayFee(State storage state, Loan storage fol, uint256 repayAmount) internal {
        uint256 repayFee = partialRepayFee(state, fol, repayAmount);

        uint256 repayFeeWad = ConversionLibrary.amountToWad(repayFee, state.data.underlyingBorrowToken.decimals());
        uint256 repayFeeCollateral =
            Math.mulDivUp(repayFeeWad, 10 ** state.oracle.priceFeed.decimals(), state.oracle.priceFeed.getPrice());

        // due to rounding up, it is possible that repayFeeCollateral is greater than the borrower collateral
        uint256 cappedRepayFeeCollateral =
            Math.min(repayFeeCollateral, state.data.collateralToken.balanceOf(fol.generic.borrower));

        state.data.collateralToken.transferFrom(
            fol.generic.borrower, state.config.feeRecipient, cappedRepayFeeCollateral
        );

        fol.fol.issuanceValue -= Math.mulDivDown(repayAmount, PERCENT, PERCENT + fol.fol.rate);
        state.data.debtToken.burn(fol.generic.borrower, repayFee);
    }

    // solhint-disable-next-line var-name-mixedcase
    function createFOL(
        State storage state,
        address lender,
        address borrower,
        uint256 issuanceValue,
        uint256 rate,
        uint256 dueDate
    ) public returns (Loan memory fol) {
        fol = Loan({
            generic: GenericLoan({lender: lender, borrower: borrower, credit: 0}),
            fol: FOL({
                issuanceValue: issuanceValue,
                rate: rate,
                startDate: block.timestamp,
                dueDate: dueDate,
                liquidityIndexAtRepayment: 0
            }),
            sol: SOL({folId: RESERVED_ID})
        });
        fol.generic.credit = fol.faceValue();
        state.validateMinimumCreditOpening(fol.generic.credit);

        state.data.loans.push(fol);
        uint256 folId = state.data.loans.length - 1;

        emit Events.CreateFOL(folId, lender, borrower, issuanceValue, rate, dueDate);
    }

    // solhint-disable-next-line var-name-mixedcase
    function createSOL(State storage state, uint256 exiterId, address lender, address borrower, uint256 credit)
        public
        returns (Loan memory sol)
    {
        uint256 folId = state.getFOLId(exiterId);

        sol = Loan({
            generic: GenericLoan({lender: lender, borrower: borrower, credit: credit}),
            fol: FOL({issuanceValue: 0, rate: 0, startDate: 0, dueDate: 0, liquidityIndexAtRepayment: 0}),
            sol: SOL({folId: folId})
        });

        state.data.loans.push(sol);
        uint256 solId = state.data.loans.length - 1;

        reduceLoanCredit(state, exiterId, credit);
        state.validateMinimumCreditOpening(sol.generic.credit);

        emit Events.CreateSOL(solId, lender, borrower, exiterId, folId, credit);
    }
}
