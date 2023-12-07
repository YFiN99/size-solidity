// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {SizeStorage} from "@src/SizeStorage.sol";
import {User} from "@src/libraries/UserLibrary.sol";
import {Loan} from "@src/libraries/LoanLibrary.sol";
import {OfferLibrary, BorrowOffer} from "@src/libraries/OfferLibrary.sol";
import {LoanLibrary, LoanStatus, Loan} from "@src/libraries/LoanLibrary.sol";
import {VaultLibrary, Vault} from "@src/libraries/VaultLibrary.sol";
import {SizeView} from "@src/SizeView.sol";
import {PERCENT} from "@src/libraries/MathLibrary.sol";
import {YieldCurve} from "@src/libraries/YieldCurveLibrary.sol";

import {FixedPointMathLib} from "@solmate/utils/FixedPointMathLib.sol";

import {ISize} from "@src/interfaces/ISize.sol";

import {State} from "@src/SizeStorage.sol";

import {Errors} from "@src/libraries/Errors.sol";
import {Events} from "@src/libraries/Events.sol";

struct ClaimParams {
    uint256 loanId;
    address lender;
    address protocol;
}

library Claim {
    using LoanLibrary for Loan;
    using VaultLibrary for Vault;

    function validateClaim(State storage state, ClaimParams memory params) external view {
        Loan memory loan = state.loans[params.loanId];

        // validate loanId
        // NOTE: Both ACTIVE and OVERDUE loans can't be claimed because the money is not in the protocol yet
        // NOTE: The CLAIMED can't be claimed either because its credit has already been consumed entirely either by a previous claim or by exiting before
        if (loan.getLoanStatus(state.loans) != LoanStatus.REPAID) {
            revert Errors.LOAN_NOT_REPAID(params.loanId);
        }

        // validate lender
        if (params.lender != loan.lender) {
            revert Errors.CLAIMER_IS_NOT_LENDER(params.lender, loan.lender);
        }

        // validate protocol
    }

    function executeClaim(State storage state, ClaimParams memory params) external {
        Loan storage loan = state.loans[params.loanId];
        User storage protocolUser = state.users[params.protocol];
        User storage lenderUser = state.users[loan.lender];

        // @audit amountFVExited can increase if SOLs are created, what if claim/exit happen in different times?
        protocolUser.borrowAsset.transfer(lenderUser.borrowAsset, loan.getCredit());
        loan.amountFVExited = loan.FV;

        emit Events.Claim(params.loanId, params.lender);
    }
}
