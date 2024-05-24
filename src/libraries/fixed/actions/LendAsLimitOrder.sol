// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {LoanOffer, OfferLibrary} from "@src/libraries/fixed/OfferLibrary.sol";
import {YieldCurve, YieldCurveLibrary} from "@src/libraries/fixed/YieldCurveLibrary.sol";

import {State} from "@src/SizeStorage.sol";

import {Errors} from "@src/libraries/Errors.sol";
import {Events} from "@src/libraries/Events.sol";

struct LendAsLimitOrderParams {
    uint256 maxDueDate;
    YieldCurve curveRelativeTime;
}

library LendAsLimitOrder {
    using OfferLibrary for LoanOffer;

    function validateLendAsLimitOrder(State storage state, LendAsLimitOrderParams calldata params) external view {
        LoanOffer memory loanOffer =
            LoanOffer({maxDueDate: params.maxDueDate, curveRelativeTime: params.curveRelativeTime});

        // a null offer mean clearing their limit orders
        if (!loanOffer.isNull()) {
            // validate msg.sender
            // N/A

            // validate maxDueDate
            if (params.maxDueDate == 0) {
                revert Errors.NULL_MAX_DUE_DATE();
            }
            if (params.maxDueDate < block.timestamp + state.riskConfig.minimumMaturity) {
                revert Errors.PAST_MAX_DUE_DATE(params.maxDueDate);
            }

            // validate params.curveRelativeTime
            YieldCurveLibrary.validateYieldCurve(
                params.curveRelativeTime, state.riskConfig.minimumMaturity, state.riskConfig.maximumMaturity
            );
        }
    }

    function executeLendAsLimitOrder(State storage state, LendAsLimitOrderParams calldata params) external {
        state.data.users[msg.sender].loanOffer =
            LoanOffer({maxDueDate: params.maxDueDate, curveRelativeTime: params.curveRelativeTime});
        emit Events.LendAsLimitOrder(
            params.maxDueDate,
            params.curveRelativeTime.maturities,
            params.curveRelativeTime.aprs,
            params.curveRelativeTime.marketRateMultipliers
        );
    }
}
