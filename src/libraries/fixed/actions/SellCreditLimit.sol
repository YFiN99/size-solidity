// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {State} from "@src/SizeStorage.sol";
import {BorrowOffer, OfferLibrary} from "@src/libraries/fixed/OfferLibrary.sol";
import {YieldCurve, YieldCurveLibrary} from "@src/libraries/fixed/YieldCurveLibrary.sol";

import {Events} from "@src/libraries/Events.sol";

struct SellCreditLimitParams {
    YieldCurve curveRelativeTime;
}

library SellCreditLimit {
    using OfferLibrary for BorrowOffer;

    function validateSellCreditLimit(State storage state, SellCreditLimitParams calldata params) external view {
        BorrowOffer memory borrowOffer = BorrowOffer({curveRelativeTime: params.curveRelativeTime});

        // a null offer mean clearing their limit orders
        if (!borrowOffer.isNull()) {
            // validate msg.sender
            // N/A

            // validate openingLimitBorrowCR
            // N/A

            // validate curveRelativeTime
            YieldCurveLibrary.validateYieldCurve(
                params.curveRelativeTime, state.riskConfig.minimumTenor, state.riskConfig.maximumTenor
            );
        }
    }

    function executeSellCreditLimit(State storage state, SellCreditLimitParams calldata params) external {
        state.data.users[msg.sender].borrowOffer = BorrowOffer({curveRelativeTime: params.curveRelativeTime});
        emit Events.SellCreditLimit(
            params.curveRelativeTime.maturities,
            params.curveRelativeTime.aprs,
            params.curveRelativeTime.marketRateMultipliers
        );
    }
}
