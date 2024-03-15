// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {IAToken} from "@aave/interfaces/IAToken.sol";
import {IPool} from "@aave/interfaces/IPool.sol";
import {VariableDebtToken} from "@aave/protocol/tokenization/VariableDebtToken.sol";

import {DataTypes} from "@aave/protocol/libraries/types/DataTypes.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {State} from "@src/SizeStorage.sol";
import {Errors} from "@src/libraries/Errors.sol";
import {CollateralLibrary} from "@src/libraries/fixed/CollateralLibrary.sol";

import {CreditPosition, DebtPosition, LoanLibrary} from "@src/libraries/fixed/LoanLibrary.sol";

import {UserLibrary} from "@src/libraries/fixed/UserLibrary.sol";
import {Vault} from "@src/proxy/Vault.sol";

/// @title VariableLibrary
/// @dev Contains functions for interacting with the Size Variable Pool (Aave v3 fork)
library VariableLibrary {
    using SafeERC20 for IERC20Metadata;
    using CollateralLibrary for State;
    using LoanLibrary for State;
    using LoanLibrary for DebtPosition;
    using LoanLibrary for CreditPosition;
    using UserLibrary for State;

    /// @notice Deposit underlyin tokens into the variable pool
    /// @dev Assumes `from` has approved to `address(this)` the `amount` of `underlyingToken`
    ///      The deposit is made to the vault of `to`
    ///      Note: Only the underlying collateral token should be set as collateral
    ///      Note: `setUseReserveAsCollateral` can later be optimized so that it is called only once per vault
    /// @param state The state struct
    /// @param underlyingToken The underlying token
    /// @param from The address of the depositor
    /// @param to The address of the recipient
    /// @param amount The amount of tokens to deposit
    /// @param variable Whether to deposit on the vault for variable or fixed-rate lending
    /// @param setUseReserveAsCollateral Whether to set the collateral as collateral.
    function depositUnderlyingTokenToVariablePool(
        State storage state,
        IERC20Metadata underlyingToken,
        address from,
        address to,
        uint256 amount,
        bool variable,
        bool setUseReserveAsCollateral
    ) external {
        underlyingToken.safeTransferFrom(from, address(this), amount);

        Vault vaultTo = variable ? state.getVaultVariable(to) : state.getVaultFixed(to);

        underlyingToken.forceApprove(address(state.data.variablePool), amount);
        state.data.variablePool.supply(address(underlyingToken), amount, address(vaultTo), 0);

        // set underlyingToken as collateral
        if (setUseReserveAsCollateral) {
            // slither-disable-next-line unused-return
            vaultTo.proxy(
                address(state.data.variablePool),
                abi.encodeCall(IPool.setUserUseReserveAsCollateral, (address(underlyingToken), true))
            );
        }
    }

    /// @notice Withdraw underlying tokens from the variable pool
    /// @dev Assumes `from` has enough aTokens to withdraw
    ///      The withdraw is made from the vault of `from`
    /// @param state The state struct
    /// @param aToken The aToken
    /// @param from The address of the withdrawer
    /// @param to The address of the recipient
    /// @param amount The amount of tokens to withdraw
    /// @param variable Whether to withdrawm from the vault for variable or fixed-rate lending
    function withdrawUnderlyingTokenFromVariablePool(
        State storage state,
        IAToken aToken,
        address from,
        address to,
        uint256 amount,
        bool variable
    ) external {
        if (aTokenBalanceOf(state, aToken, from, variable) < amount) {
            revert Errors.NOT_ENOUGH_ATOKEN_BALANCE(
                address(aToken), from, variable, aTokenBalanceOf(state, aToken, from, variable), amount
            );
        }

        address underlyingToken = aToken.UNDERLYING_ASSET_ADDRESS();

        Vault vaultFrom = variable ? state.getVaultVariable(from) : state.getVaultFixed(from);

        // slither-disable-next-line unused-return
        vaultFrom.proxy(address(state.data.variablePool), abi.encodeCall(IPool.withdraw, (underlyingToken, amount, to)));
    }

    /// @notice Borrow a variable loan from the variable pool
    /// @param state The state struct
    /// @param from The address of the borrower
    /// @param to The address of the recipient
    /// @param amount The amount of tokens to borrow
    function borrowVariableLoan(State storage state, address from, address to, uint256 amount) external {
        IERC20Metadata underlyingBorrowToken = IERC20Metadata(state.data.underlyingBorrowToken);

        Vault vaultFrom = state.getVaultVariable(from);
        Vault vaultTo = state.getVaultVariable(to);

        address[] memory targets = new address[](2);
        bytes[] memory data = new bytes[](2);

        // borrow
        targets[0] = address(state.data.variablePool);
        data[0] = abi.encodeCall(
            IPool.borrow,
            (
                address(underlyingBorrowToken),
                amount,
                uint256(DataTypes.InterestRateMode.VARIABLE),
                0,
                address(vaultFrom)
            )
        );

        // transfer to `address(this)`
        targets[1] = address(state.data.underlyingBorrowToken);
        data[1] = abi.encodeCall(IERC20.transfer, (address(this), amount));

        // slither-disable-next-line unused-return
        vaultFrom.proxy(targets, data);

        // supply to `to`
        underlyingBorrowToken.forceApprove(address(state.data.variablePool), amount);
        state.data.variablePool.supply(address(underlyingBorrowToken), amount, address(vaultTo), 0);
    }

    /// @notice Repay a variable loan from the variable pool
    /// @param state The state struct
    /// @param from The address of the repayer
    /// @param amount The amount of tokens to repay
    function repayVariableLoan(State storage state, address from, uint256 amount) external {
        // @audit Validate if we can use `repayWithATokens` without reaching any caps
        Vault vaultFrom = state.getVaultVariable(from);

        // slither-disable-next-line unused-return
        vaultFrom.proxy(
            address(state.data.variablePool),
            abi.encodeCall(
                IPool.repayWithATokens,
                (address(state.data.underlyingBorrowToken), amount, uint256(DataTypes.InterestRateMode.VARIABLE))
            )
        );
    }

    /// @notice Liquidate a variable loan from the variable pool
    /// @dev    The caller must have underlying collateral tokens on their vault
    /// @param state The state struct
    /// @param from The address of the liquidator
    /// @param borrower The address of the liquidated borrower
    /// @param amount The amount of debt to cover
    function liquidateVariableLoan(State storage state, address from, address borrower, uint256 amount) external {
        // @audit Validate if we can use `liquidationCall` without reaching any caps
        Vault vaultFrom = state.getVaultVariable(from);
        Vault vaultTo = state.getVaultVariable(borrower);

        address[] memory targets = new address[](3);
        bytes[] memory data = new bytes[](3);

        // unwrap borrow aTokens (e.g. aszUSDC) to underlying borrow tokens (e.g. USDC)
        targets[0] = address(state.data.variablePool);
        data[0] =
            abi.encodeCall(IPool.withdraw, (address(state.data.underlyingBorrowToken), amount, address(vaultFrom)));

        // approve underlying borrow tokens
        targets[1] = address(state.data.underlyingBorrowToken);
        data[1] = abi.encodeCall(IERC20.approve, (address(state.data.variablePool), amount));

        // liquidate
        targets[2] = address(state.data.variablePool);
        data[2] = abi.encodeCall(
            IPool.liquidationCall,
            (
                address(state.data.underlyingCollateralToken),
                address(state.data.underlyingBorrowToken),
                address(vaultTo),
                amount,
                true
            )
        );

        // slither-disable-next-line unused-return
        vaultFrom.proxy(targets, data);
    }

    /// @notice Transfer aTokens from one user to another, from the vault destined to fixed-rate loans
    /// @dev Assumes `from` has enough aTokens to transfer
    ///      The transfer is made from the vault of `from` to the vault of `to`
    /// @param state The state struct
    /// @param from The address of the sender
    /// @param to The address of the recipient
    /// @param amount The amount of aTokens to transfer
    function transferBorrowATokenFixed(State storage state, address from, address to, uint256 amount) public {
        IAToken borrowAToken = state.data.borrowAToken;
        if (aTokenBalanceOf(state, borrowAToken, from, false) < amount) {
            revert Errors.NOT_ENOUGH_ATOKEN_BALANCE(
                address(borrowAToken), from, false, aTokenBalanceOf(state, borrowAToken, from, false), amount
            );
        }

        Vault vaultFrom = state.getVaultFixed(from);
        Vault vaultTo = state.getVaultFixed(to);

        // slither-disable-next-line unused-return
        vaultFrom.proxy(address(borrowAToken), abi.encodeCall(IERC20.transfer, (address(vaultTo), amount)));
    }

    /// @notice Get the balance of borrow aTokens for a user on the Variable Pool
    /// @param state The state struct
    /// @param account The user's address
    /// @param variable Whether to get the balance for the variable or fixed-rate vault
    /// @return The balance of aTokens
    function aTokenBalanceOf(State storage state, IAToken aToken, address account, bool variable)
        public
        view
        returns (uint256)
    {
        Vault vault = variable ? state.data.users[account].vaultVariable : state.data.users[account].vaultFixed;
        return aToken.balanceOf(address(vault));
    }

    /// @notice Get the balance of variable debt for a user on the Variable Pool
    /// @param state The state struct
    /// @param account The user's address
    function variableDebtTokenBalanceOf(State storage state, address account) public view returns (uint256) {
        VariableDebtToken token = VariableDebtToken(
            state.data.variablePool.getReserveData(address(state.data.underlyingBorrowToken)).variableDebtTokenAddress
        );
        Vault vault = state.data.users[account].vaultVariable;
        return token.balanceOf(address(vault));
    }

    /// @notice Get the liquidity index of Size Variable Pool (Aave v3 fork)
    /// @param state The state struct
    /// @return The liquidity index
    function borrowATokenLiquidityIndex(State storage state) public view returns (uint256) {
        return state.data.variablePool.getReserveNormalizedIncome(address(state.data.underlyingBorrowToken));
    }

    /// @notice Move a fixed-rate DebtPosition to the variable pool by supplying the assigned collateral and paying the liquidator with the move fee
    ///        Try borrowing underlying borrow tokens from the variable pool by first supplying collateral
    ///        The borrow is made on behalf of the variable-rate vault of the `from` user and the supply is made to the fixed-rate vault of the `to` user, so that it later can be claimed
    ///        After moving the loan to the Variable Pool, we check the vault's health factor and revert if it is below the liquidation threshold. See https://docs.aave.com/risk/asset-risk/risk-parameters#health-factor
    /// @dev Assumes `from` has enough collateral to borrow `amount`
    ///      We use a memory copy of the DebtPosition as it might have already changed in storage as a result of the liquidation process
    ///      This function may revert due to Variable Pool health checks or liquidity conditions
    /// @param state The state struct
    /// @param debtPositionCopy The DebtPosition to move
    /// @return liquidatorProfitCollateralToken The amount of collateral tokens paid to the liquidator
    function moveDebtPositionToVariablePool(State storage state, DebtPosition memory debtPositionCopy)
        external
        returns (uint256 liquidatorProfitCollateralToken)
    {
        uint256 assignedCollateral = state.getDebtPositionAssignedCollateral(debtPositionCopy);

        // take overdue transfer fee from collateral
        liquidatorProfitCollateralToken = state.feeConfig.collateralOverdueTransferFee;
        state.data.collateralToken.transferFrom(debtPositionCopy.borrower, msg.sender, liquidatorProfitCollateralToken);

        address from = debtPositionCopy.borrower;
        address to = address(this);
        uint256 collateralBalance = assignedCollateral - liquidatorProfitCollateralToken;
        uint256 borrowATokenBalance = debtPositionCopy.faceValue;

        // begin move to variable pool
        Vault vaultFrom = state.getVaultVariable(from);
        Vault vaultTo = state.getVaultFixed(to);

        // unwrap collateralToken (e.g. szETH) to underlyingCollateralToken (e.g. WETH) from `from` to `address(this)`
        state.withdrawUnderlyingCollateralToken(from, address(this), collateralBalance);

        // supply underlying collateral token
        state.data.underlyingCollateralToken.forceApprove(address(state.data.variablePool), collateralBalance);
        state.data.variablePool.supply(
            address(state.data.underlyingCollateralToken), collateralBalance, address(vaultFrom), 0
        );

        address[] memory targets = new address[](3);
        bytes[] memory data = new bytes[](3);

        // set underlyingCollateralToken as collateral
        targets[0] = address(state.data.variablePool);
        data[0] =
            abi.encodeCall(IPool.setUserUseReserveAsCollateral, (address(state.data.underlyingCollateralToken), true));

        // borrow
        targets[1] = address(state.data.variablePool);
        data[1] = abi.encodeCall(
            IPool.borrow,
            (
                address(state.data.underlyingBorrowToken),
                borrowATokenBalance,
                uint256(DataTypes.InterestRateMode.VARIABLE),
                0,
                address(vaultFrom)
            )
        );

        // transfer underlying borrow tokens to `address(this)`
        targets[2] = address(state.data.underlyingBorrowToken);
        data[2] = abi.encodeCall(IERC20.transfer, (address(this), borrowATokenBalance));

        // slither-disable-next-line unused-return
        vaultFrom.proxy(targets, data);

        // supply to `to`
        state.data.underlyingBorrowToken.forceApprove(address(state.data.variablePool), borrowATokenBalance);
        state.data.variablePool.supply(
            address(state.data.underlyingBorrowToken), borrowATokenBalance, address(vaultTo), 0
        );

        // check if the user HF is greater than the threshold
        (,,,,, uint256 healthFactor) = state.data.variablePool.getUserAccountData(address(vaultFrom));
        if (healthFactor < state.riskConfig.moveToVariablePoolHFThreshold) {
            revert Errors.HEALTH_FACTOR_BELOW_MOVE_TO_VARIABLE_POOL_HF_THRESHOLD(
                address(vaultFrom), healthFactor, state.riskConfig.moveToVariablePoolHFThreshold
            );
        }
    }
}
