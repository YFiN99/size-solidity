// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IAToken} from "@aave/interfaces/IAToken.sol";
import {IPool} from "@aave/interfaces/IPool.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {PERCENT} from "@src/libraries/Math.sol";
import {IPriceFeed} from "@src/oracle/IPriceFeed.sol";
import {CollateralToken} from "@src/token/CollateralToken.sol";
import {DebtToken} from "@src/token/DebtToken.sol";

import {UserProxy} from "@src/proxy/UserProxy.sol";

import {State} from "@src/SizeStorage.sol";

import {Errors} from "@src/libraries/Errors.sol";
import {Events} from "@src/libraries/Events.sol";

struct InitializeGeneralParams {
    address owner;
    address priceFeed;
    address collateralAsset;
    address borrowAsset;
    address feeRecipient;
    address variablePool;
}

struct InitializeFixedParams {
    uint256 crOpening;
    uint256 crLiquidation;
    uint256 collateralPremiumToLiquidator;
    uint256 collateralPremiumToProtocol;
    uint256 minimumCreditBorrowAsset;
}

library Initialize {
    function _validateInitializeGeneralParams(InitializeGeneralParams memory g) internal pure {
        // validate owner
        // OwnableUpgradeable already performs this check

        // validate price feed
        if (g.priceFeed == address(0)) {
            revert Errors.NULL_ADDRESS();
        }

        // validate collateral asset
        if (g.collateralAsset == address(0)) {
            revert Errors.NULL_ADDRESS();
        }

        // validate borrow asset
        if (g.borrowAsset == address(0)) {
            revert Errors.NULL_ADDRESS();
        }

        // validate feeRecipient
        if (g.feeRecipient == address(0)) {
            revert Errors.NULL_ADDRESS();
        }
    }

    function _validateInitializeFixedParams(InitializeFixedParams memory f) internal pure {
        // validate crOpening
        if (f.crOpening < PERCENT) {
            revert Errors.INVALID_COLLATERAL_RATIO(f.crOpening);
        }

        // validate crLiquidation
        if (f.crLiquidation < PERCENT) {
            revert Errors.INVALID_COLLATERAL_RATIO(f.crLiquidation);
        }
        if (f.crOpening <= f.crLiquidation) {
            revert Errors.INVALID_LIQUIDATION_COLLATERAL_RATIO(f.crOpening, f.crLiquidation);
        }

        // validate collateralPremiumToLiquidator
        if (f.collateralPremiumToLiquidator > PERCENT) {
            revert Errors.INVALID_COLLATERAL_PERCENTAGE_PREMIUM(f.collateralPremiumToLiquidator);
        }

        // validate collateralPremiumToProtocol
        if (f.collateralPremiumToProtocol > PERCENT) {
            revert Errors.INVALID_COLLATERAL_PERCENTAGE_PREMIUM(f.collateralPremiumToProtocol);
        }
        if (f.collateralPremiumToLiquidator + f.collateralPremiumToProtocol > PERCENT) {
            revert Errors.INVALID_COLLATERAL_PERCENTAGE_PREMIUM_SUM(
                f.collateralPremiumToLiquidator + f.collateralPremiumToProtocol
            );
        }

        // validate minimumCreditBorrowAsset
        if (f.minimumCreditBorrowAsset == 0) {
            revert Errors.NULL_AMOUNT();
        }
    }

    function validateInitialize(State storage, InitializeGeneralParams memory g, InitializeFixedParams memory f)
        external
        pure
    {
        _validateInitializeGeneralParams(g);
        _validateInitializeFixedParams(f);
    }

    function _executeInitializeGeneral(State storage state, InitializeGeneralParams memory g) internal {
        state._general.priceFeed = IPriceFeed(g.priceFeed);
        state._general.collateralAsset = IERC20Metadata(g.collateralAsset);
        state._general.borrowAsset = IERC20Metadata(g.borrowAsset);
        state._general.feeRecipient = g.feeRecipient;
        state._general.variablePool = IPool(g.variablePool);
    }

    function _executeInitializeFixed(State storage state, InitializeFixedParams memory f) internal {
        state._fixed.collateralToken = new CollateralToken(address(this), "Size Fixed ETH", "szETH");
        state._fixed.borrowAToken =
            IAToken(state._general.variablePool.getReserveData(address(state._general.borrowAsset)).aTokenAddress);
        state._fixed.debtToken = new DebtToken(address(this), "Size Debt", "szDebt");

        state._fixed.crOpening = f.crOpening;
        state._fixed.crLiquidation = f.crLiquidation;
        state._fixed.collateralPremiumToLiquidator = f.collateralPremiumToLiquidator;
        state._fixed.collateralPremiumToProtocol = f.collateralPremiumToProtocol;
        state._fixed.minimumCreditBorrowAsset = f.minimumCreditBorrowAsset;
    }

    function _executeInitializeVariable(State storage state) internal {
        state._variable.userProxyImplementation = address(new UserProxy());
    }

    function executeInitialize(State storage state, InitializeGeneralParams memory g, InitializeFixedParams memory f)
        external
    {
        _executeInitializeGeneral(state, g);
        _executeInitializeFixed(state, f);
        _executeInitializeVariable(state);
        emit Events.Initialize(g, f);
    }
}
