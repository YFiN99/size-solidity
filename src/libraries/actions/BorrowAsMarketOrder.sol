// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {User} from "@src/libraries/UserLibrary.sol";
import {Loan} from "@src/libraries/LoanLibrary.sol";
import {OfferLibrary, LoanOffer} from "@src/libraries/OfferLibrary.sol";
import {LoanLibrary, Loan} from "@src/libraries/LoanLibrary.sol";
import {PERCENT} from "@src/libraries/MathLibrary.sol";

import {FixedPointMathLib} from "@solmate/utils/FixedPointMathLib.sol";

import {State} from "@src/SizeStorage.sol";

import {Errors} from "@src/libraries/Errors.sol";
import {Events} from "@src/libraries/Events.sol";

struct BorrowAsMarketOrderParams {
    address lender;
    uint256 amount;
    uint256 dueDate;
    bool exactAmountIn;
    uint256[] virtualCollateralLoanIds;
}

library BorrowAsMarketOrder {
    using OfferLibrary for LoanOffer;
    using LoanLibrary for Loan;
    using LoanLibrary for Loan[];

    function validateBorrowAsMarketOrder(State storage state, BorrowAsMarketOrderParams memory params) external view {
        User memory lenderUser = state.users[params.lender];
        LoanOffer memory loanOffer = lenderUser.loanOffer;

        // validate msg.sender

        // validate params.lender
        if (loanOffer.isNull()) {
            revert Errors.INVALID_LOAN_OFFER(params.lender);
        }

        // validate params.amount
        if (params.amount == 0) {
            revert Errors.NULL_AMOUNT();
        }
        if (params.amount > loanOffer.maxAmount) {
            revert Errors.AMOUNT_GREATER_THAN_MAX_AMOUNT(params.amount, loanOffer.maxAmount);
        }

        // validate params.dueDate
        if (params.dueDate < block.timestamp) {
            revert Errors.PAST_DUE_DATE(params.dueDate);
        }
        if (params.dueDate > loanOffer.maxDueDate) {
            revert Errors.DUE_DATE_GREATER_THAN_MAX_DUE_DATE(params.dueDate, loanOffer.maxDueDate);
        }

        // validate params.exactAmountIn
        // N/A

        // validate params.virtualCollateralLoanIds
        for (uint256 i = 0; i < params.virtualCollateralLoanIds.length; ++i) {
            uint256 loanId = params.virtualCollateralLoanIds[i];
            Loan memory loan = state.loans[loanId];

            if (msg.sender != loan.lender) {
                revert Errors.BORROWER_IS_NOT_LENDER(msg.sender, loan.lender);
            }
            if (params.dueDate < loan.getDueDate(state.loans)) {
                revert Errors.DUE_DATE_LOWER_THAN_LOAN_DUE_DATE(params.dueDate, loan.getDueDate(state.loans));
            }
        }
    }

    function executeBorrowAsMarketOrder(State storage state, BorrowAsMarketOrderParams memory params) external {
        emit Events.BorrowAsMarketOrder(
            msg.sender,
            params.lender,
            params.amount,
            params.dueDate,
            params.exactAmountIn,
            params.virtualCollateralLoanIds
        );

        params.amount = _borrowWithVirtualCollateral(state, params);
        _borrowWithRealCollateral(state, params);
    }

    /**
     * @notice Borrow with virtual collateral, an internal state-modifying function.
     * @dev The `amount` is initialized to `amountOutLeft`, which is decreased as more and more SOLs are created
     */
    function _borrowWithVirtualCollateral(State storage state, BorrowAsMarketOrderParams memory params)
        internal
        returns (uint256 amountOutLeft)
    {
        //  amountIn: Amount of future cashflow to exit
        //  amountOut: Amount of cash to borrow at present time

        User storage lenderUser = state.users[params.lender];

        LoanOffer storage loanOffer = lenderUser.loanOffer;

        uint256 r = PERCENT + loanOffer.getRate(params.dueDate);

        amountOutLeft = params.exactAmountIn ? FixedPointMathLib.mulDivUp(params.amount, PERCENT, r) : params.amount;

        for (uint256 i = 0; i < params.virtualCollateralLoanIds.length; ++i) {
            // Full amount borrowed
            if (amountOutLeft == 0) {
                break;
            }

            uint256 loanId = params.virtualCollateralLoanIds[i];
            Loan memory loan = state.loans[loanId];

            uint256 deltaAmountIn;
            uint256 deltaAmountOut;
            if (FixedPointMathLib.mulDivUp(r, amountOutLeft, PERCENT) > loan.getCredit()) {
                deltaAmountIn = loan.getCredit();
                deltaAmountOut = FixedPointMathLib.mulDivUp(loan.getCredit(), PERCENT, r);
            } else {
                deltaAmountIn = FixedPointMathLib.mulDivUp(r, amountOutLeft, PERCENT);
                deltaAmountOut = amountOutLeft;
            }

            state.loans.createSOL(loanId, params.lender, msg.sender, deltaAmountIn);
            // NOTE: Transfer deltaAmountOut for each SOL created
            state.borrowToken.transferFrom(params.lender, msg.sender, deltaAmountOut);
            loanOffer.maxAmount -= deltaAmountOut;
            amountOutLeft -= deltaAmountOut;
        }
    }

    /**
     * @notice Borrow with real collateral, an internal state-modifying function.
     * @dev Cover the remaining amount with real collateral
     */
    function _borrowWithRealCollateral(State storage state, BorrowAsMarketOrderParams memory params) internal {
        if (params.amount == 0) {
            return;
        }

        User storage lenderUser = state.users[params.lender];

        LoanOffer storage loanOffer = lenderUser.loanOffer;

        loanOffer.maxAmount -= params.amount;

        uint256 r = PERCENT + loanOffer.getRate(params.dueDate);

        // solhint-disable-next-line var-name-mixedcase
        uint256 FV = FixedPointMathLib.mulDivUp(r, params.amount, PERCENT);
        uint256 maxCollateralToLock = FixedPointMathLib.mulDivUp(FV, state.crOpening, state.priceFeed.getPrice());

        state.collateralToken.transferFrom(msg.sender, state.protocolVault, maxCollateralToLock); // lock
        state.debtToken.mint(msg.sender, FV);
        state.loans.createFOL(params.lender, msg.sender, FV, params.dueDate);
        state.borrowToken.transferFrom(params.lender, msg.sender, params.amount);
    }
}
