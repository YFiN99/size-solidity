// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {ConversionLibrary} from "@src/libraries/ConversionLibrary.sol";
import {Math, PERCENT} from "@src/libraries/Math.sol";

import {AccountingLibrary} from "@src/libraries/fixed/AccountingLibrary.sol";

import {FixedLoan} from "@src/libraries/fixed/FixedLoanLibrary.sol";
import {FixedLoan, FixedLoanLibrary} from "@src/libraries/fixed/FixedLoanLibrary.sol";
import {RiskLibrary} from "@src/libraries/fixed/RiskLibrary.sol";
import {VariableLibrary} from "@src/libraries/variable/VariableLibrary.sol";

import {State} from "@src/SizeStorage.sol";

import {Errors} from "@src/libraries/Errors.sol";
import {Events} from "@src/libraries/Events.sol";

struct SelfLiquidateFixedLoanParams {
    uint256 loanId;
}

library SelfLiquidateFixedLoan {
    using FixedLoanLibrary for FixedLoan;
    using FixedLoanLibrary for State;
    using VariableLibrary for State;
    using AccountingLibrary for State;
    using RiskLibrary for State;

    function validateSelfLiquidateFixedLoan(State storage state, SelfLiquidateFixedLoanParams calldata params)
        external
        view
    {
        FixedLoan storage loan = state._fixed.loans[params.loanId];
        FixedLoan storage fol = state.getFOL(loan);

        uint256 assignedCollateral = state.getProRataAssignedCollateral(params.loanId);
        uint256 debtWad = ConversionLibrary.amountToWad(state.getDebt(fol), state._general.borrowAsset.decimals());
        uint256 debtCollateral =
            Math.mulDivDown(debtWad, 10 ** state._general.priceFeed.decimals(), state._general.priceFeed.getPrice());

        // validate msg.sender
        if (msg.sender != loan.generic.lender) {
            revert Errors.LIQUIDATOR_IS_NOT_LENDER(msg.sender, loan.generic.lender);
        }

        // validate loanId
        if (!state.isLoanSelfLiquidatable(params.loanId)) {
            revert Errors.LOAN_NOT_SELF_LIQUIDATABLE(
                params.loanId, state.collateralRatio(loan.generic.borrower), state.getFixedLoanStatus(loan)
            );
        }
        if (!(assignedCollateral < debtCollateral)) {
            revert Errors.LIQUIDATION_NOT_AT_LOSS(params.loanId, assignedCollateral, debtCollateral);
        }
    }

    function executeSelfLiquidateFixedLoan(State storage state, SelfLiquidateFixedLoanParams calldata params)
        external
    {
        emit Events.SelfLiquidateFixedLoan(params.loanId);

        FixedLoan storage loan = state._fixed.loans[params.loanId];
        FixedLoan storage fol = state.getFOL(loan);

        uint256 credit = loan.generic.credit;

        uint256 assignedCollateral = state.getProRataAssignedCollateral(params.loanId);
        state._fixed.collateralToken.transferFrom(fol.generic.borrower, msg.sender, assignedCollateral);

        state.reduceLoanCredit(params.loanId, credit);
        state.chargeRepayFee(fol, credit);
        state._fixed.debtToken.burn(fol.generic.borrower, credit);
    }
}
