// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {State} from "@src/SizeStorage.sol";
import {Errors} from "@src/libraries/Errors.sol";
import {Events} from "@src/libraries/Events.sol";
import {Initialize} from "@src/libraries/general/actions/Initialize.sol";

struct UpdateConfigParams {
    bytes32 key;
    uint256 value;
}

library UpdateConfig {
    using Initialize for State;

    function validateUpdateConfig(State storage, UpdateConfigParams memory params) external pure {
        // validation is done at execution
    }

    function executeUpdateConfig(State storage state, UpdateConfigParams memory params) external {
        // TODO validate params
        if (params.key == "minimumCreditBorrowAsset") {
            state._fixed.minimumCreditBorrowAsset = params.value;
        } else if (params.key == "collateralTokenCap") {
            state._fixed.collateralTokenCap = params.value;
        } else if (params.key == "borrowATokenCap") {
            state._fixed.borrowATokenCap = params.value;
        } else if (params.key == "debtTokenCap") {
            state._fixed.debtTokenCap = params.value;
        } else if (params.key == "repayFeeAPR") {
            state._fixed.repayFeeAPR = params.value;
        } else {
            revert Errors.INVALID_KEY(params.key);
        }

        emit Events.UpdateConfig(params.key, params.value);
    }
}
