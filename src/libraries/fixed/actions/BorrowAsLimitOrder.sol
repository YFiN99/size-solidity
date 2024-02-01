// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {State} from "@src/SizeStorage.sol";
import {BorrowOffer} from "@src/libraries/fixed/OfferLibrary.sol";
import {YieldCurve, YieldCurveLibrary} from "@src/libraries/fixed/YieldCurveLibrary.sol";

import {Events} from "@src/libraries/Events.sol";

struct BorrowAsLimitOrderParams {
    YieldCurve curveRelativeTime;
}

library BorrowAsLimitOrder {
    function validateBorrowAsLimitOrder(State storage, BorrowAsLimitOrderParams calldata params) external pure {
        // validate msg.sender

        // validate curveRelativeTime
        YieldCurveLibrary.validateYieldCurve(params.curveRelativeTime);
    }

    function executeBorrowAsLimitOrder(State storage state, BorrowAsLimitOrderParams calldata params) external {
        state._fixed.users[msg.sender].borrowOffer = BorrowOffer({curveRelativeTime: params.curveRelativeTime});
        emit Events.BorrowAsLimitOrder(params.curveRelativeTime);
    }
}
