// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {Loan} from "@src/libraries/LoanLibrary.sol";

import {Loan, LoanLibrary} from "@src/libraries/LoanLibrary.sol";
import {Math} from "@src/libraries/MathLibrary.sol";
import {NonTransferrableToken} from "@src/token/NonTransferrableToken.sol";

import {State} from "@src/SizeStorage.sol";

import {Errors} from "@src/libraries/Errors.sol";
import {Events} from "@src/libraries/Events.sol";

struct WithdrawParams {
    address token;
    uint256 amount;
}

library Withdraw {
    using LoanLibrary for Loan;
    using SafeERC20 for IERC20Metadata;

    function validateWithdraw(State storage state, WithdrawParams calldata params) external view {
        // validte msg.sender

        // validate token
        if (params.token != address(state.tokens.collateralAsset) && params.token != address(state.tokens.borrowAsset))
        {
            revert Errors.INVALID_TOKEN(params.token);
        }

        // validate amount
        if (params.amount == 0) {
            revert Errors.NULL_AMOUNT();
        }
    }

    function executeWithdraw(State storage state, WithdrawParams calldata params) external {
        NonTransferrableToken nonTransferrableToken = params.token == address(state.tokens.collateralAsset)
            ? NonTransferrableToken(state.tokens.collateralToken)
            : NonTransferrableToken(state.tokens.borrowToken);
        IERC20Metadata token = IERC20Metadata(params.token);
        uint8 decimals = token.decimals();

        uint256 userBalanceWad = nonTransferrableToken.balanceOf(msg.sender);
        uint256 userBalanceAmountDown = Math.wadToAmountDown(userBalanceWad, decimals);

        uint256 withdrawAmountDown = Math.min(params.amount, userBalanceAmountDown);
        uint256 wadDown = Math.amountToWad(withdrawAmountDown, decimals);

        nonTransferrableToken.burn(msg.sender, wadDown);
        token.safeTransfer(msg.sender, withdrawAmountDown);

        emit Events.Withdraw(params.token, wadDown);
    }
}
