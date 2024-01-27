// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {FixedLoanOffer} from "@src/libraries/fixed/OfferLibrary.sol";
import {YieldCurve, YieldCurveLibrary} from "@src/libraries/fixed/YieldCurveLibrary.sol";
import {VariableLibrary} from "@src/libraries/variable/VariableLibrary.sol";

import {State} from "@src/SizeStorage.sol";

import {Errors} from "@src/libraries/Errors.sol";
import {Events} from "@src/libraries/Events.sol";

struct LendAsLimitOrderParams {
    uint256 maxAmount; // in decimals (e.g. 1_000e6 for 1000 USDC)
    uint256 maxDueDate;
    YieldCurve curveRelativeTime;
}

library LendAsLimitOrder {
    using VariableLibrary for State;

    function validateLendAsLimitOrder(State storage state, LendAsLimitOrderParams calldata params) external view {
        // validate msg.sender

        // validate params.maxAmount
        if (params.maxAmount == 0) {
            revert Errors.NULL_AMOUNT();
        }
        if (params.maxAmount > state.borrowATokenBalanceOf(msg.sender)) {
            revert Errors.NOT_ENOUGH_FREE_CASH(state.borrowATokenBalanceOf(msg.sender), params.maxAmount);
        }

        // validate maxDueDate
        if (params.maxDueDate == 0) {
            revert Errors.NULL_MAX_DUE_DATE();
        }
        if (params.maxDueDate < block.timestamp) {
            revert Errors.PAST_MAX_DUE_DATE(params.maxDueDate);
        }

        // validate params.curveRelativeTime
        YieldCurveLibrary.validateYieldCurve(params.curveRelativeTime);
    }

    function executeLendAsLimitOrder(State storage state, LendAsLimitOrderParams calldata params) external {
        state._fixed.users[msg.sender].loanOffer = FixedLoanOffer({
            maxAmount: params.maxAmount,
            maxDueDate: params.maxDueDate,
            curveRelativeTime: params.curveRelativeTime
        });
        emit Events.LendAsLimitOrder(params.maxAmount, params.maxDueDate, params.curveRelativeTime);
    }
}
