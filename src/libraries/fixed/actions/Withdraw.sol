// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {State} from "@src/SizeStorage.sol";

import {Math} from "@src/libraries/Math.sol";
import {CollateralLibrary} from "@src/libraries/fixed/CollateralLibrary.sol";
import {VariableLibrary} from "@src/libraries/variable/VariableLibrary.sol";

import {Errors} from "@src/libraries/Errors.sol";
import {Events} from "@src/libraries/Events.sol";

struct WithdrawParams {
    address token;
    uint256 amount;
    address to;
}

library Withdraw {
    using VariableLibrary for State;
    using CollateralLibrary for State;

    function validateWithdraw(State storage state, WithdrawParams calldata params) external view {
        // validte msg.sender

        // validate token
        if (
            params.token != address(state._general.collateralAsset)
                && params.token != address(state._general.borrowAsset)
        ) {
            revert Errors.INVALID_TOKEN(params.token);
        }

        // validate amount
        if (params.amount == 0) {
            revert Errors.NULL_AMOUNT();
        }

        // validate to
        if (params.to == address(0)) {
            revert Errors.NULL_ADDRESS();
        }
    }

    function executeWithdraw(State storage state, WithdrawParams calldata params) public {
        if (params.token == address(state._general.collateralAsset)) {
            uint256 amount = Math.min(params.amount, state._fixed.collateralToken.balanceOf(msg.sender));
            if (amount > 0) {
                state.withdrawCollateralToken(msg.sender, params.to, amount);
            }
        } else {
            uint256 amount = Math.min(params.amount, state.borrowATokenBalanceOf(msg.sender));
            if (amount > 0) {
                state.withdrawBorrowTokenFromVariablePool(msg.sender, params.to, amount);
            }
        }

        emit Events.Withdraw(params.token, params.to, params.amount);
    }
}
