// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {MulticallUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";

import {
    Initialize, InitializeFixedParams, InitializeGeneralParams
} from "@src/libraries/general/actions/Initialize.sol";
import {UpdateConfig, UpdateConfigParams} from "@src/libraries/general/actions/UpdateConfig.sol";

import {BorrowAsLimitOrder, BorrowAsLimitOrderParams} from "@src/libraries/fixed/actions/BorrowAsLimitOrder.sol";
import {BorrowAsMarketOrder, BorrowAsMarketOrderParams} from "@src/libraries/fixed/actions/BorrowAsMarketOrder.sol";

import {BorrowerExit, BorrowerExitParams} from "@src/libraries/fixed/actions/BorrowerExit.sol";
import {Claim, ClaimParams} from "@src/libraries/fixed/actions/Claim.sol";
import {Deposit, DepositParams} from "@src/libraries/fixed/actions/Deposit.sol";

import {LendAsLimitOrder, LendAsLimitOrderParams} from "@src/libraries/fixed/actions/LendAsLimitOrder.sol";
import {LendAsMarketOrder, LendAsMarketOrderParams} from "@src/libraries/fixed/actions/LendAsMarketOrder.sol";
import {LiquidateFixedLoan, LiquidateFixedLoanParams} from "@src/libraries/fixed/actions/LiquidateFixedLoan.sol";
import {MoveToVariablePool, MoveToVariablePoolParams} from "@src/libraries/fixed/actions/MoveToVariablePool.sol";

import {FixedLibrary} from "@src/libraries/fixed/FixedLibrary.sol";

import {Compensate, CompensateParams} from "@src/libraries/fixed/actions/Compensate.sol";
import {
    LiquidateFixedLoanWithReplacement,
    LiquidateFixedLoanWithReplacementParams
} from "@src/libraries/fixed/actions/LiquidateFixedLoanWithReplacement.sol";
import {Repay, RepayParams} from "@src/libraries/fixed/actions/Repay.sol";
import {
    SelfLiquidateFixedLoan,
    SelfLiquidateFixedLoanParams
} from "@src/libraries/fixed/actions/SelfLiquidateFixedLoan.sol";
import {Withdraw, WithdrawParams} from "@src/libraries/fixed/actions/Withdraw.sol";

import {SizeStorage, State} from "@src/SizeStorage.sol";

import {FixedLibrary} from "@src/libraries/fixed/FixedLibrary.sol";

import {SizeView} from "@src/SizeView.sol";

import {State} from "@src/SizeStorage.sol";

import {ISize} from "@src/interfaces/ISize.sol";

contract Size is ISize, SizeView, Initializable, Ownable2StepUpgradeable, MulticallUpgradeable, UUPSUpgradeable {
    using Initialize for State;
    using UpdateConfig for State;
    using Deposit for State;
    using Withdraw for State;
    using BorrowAsMarketOrder for State;
    using BorrowAsLimitOrder for State;
    using LendAsMarketOrder for State;
    using LendAsLimitOrder for State;
    using BorrowerExit for State;
    using Repay for State;
    using Claim for State;
    using LiquidateFixedLoan for State;
    using SelfLiquidateFixedLoan for State;
    using LiquidateFixedLoanWithReplacement for State;
    using MoveToVariablePool for State;
    using Compensate for State;
    using FixedLibrary for State;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(InitializeGeneralParams calldata g, InitializeFixedParams calldata f) external initializer {
        state.validateInitialize(g, f);

        __Ownable_init(g.owner);
        __Ownable2Step_init();
        __Multicall_init();
        __UUPSUpgradeable_init();

        state.executeInitialize(g, f);
    }

    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function updateConfig(UpdateConfigParams calldata params) external onlyOwner {
        state.validateUpdateConfig(params);
        state.executeUpdateConfig(params);
    }

    /// @inheritdoc ISize
    function deposit(DepositParams calldata params) external override(ISize) {
        state.validateDeposit(params);
        state.executeDeposit(params);
    }

    /// @inheritdoc ISize
    function withdraw(WithdrawParams calldata params) external override(ISize) {
        state.validateWithdraw(params);
        state.executeWithdraw(params);
        state.validateUserIsNotLiquidatable(msg.sender);
    }

    /// @inheritdoc ISize
    function lendAsLimitOrder(LendAsLimitOrderParams calldata params) external override(ISize) {
        state.validateLendAsLimitOrder(params);
        state.executeLendAsLimitOrder(params);
    }

    /// @inheritdoc ISize
    function borrowAsLimitOrder(BorrowAsLimitOrderParams calldata params) external override(ISize) {
        state.validateBorrowAsLimitOrder(params);
        state.executeBorrowAsLimitOrder(params);
    }

    /// @inheritdoc ISize
    function lendAsMarketOrder(LendAsMarketOrderParams calldata params) external override(ISize) {
        state.validateLendAsMarketOrder(params);
        state.executeLendAsMarketOrder(params);
        state.validateUserIsNotLiquidatable(params.borrower);
    }

    /// @inheritdoc ISize
    function borrowAsMarketOrder(BorrowAsMarketOrderParams memory params) external override(ISize) {
        state.validateBorrowAsMarketOrder(params);
        state.executeBorrowAsMarketOrder(params);
        state.validateUserIsNotLiquidatable(msg.sender);
    }

    /// @inheritdoc ISize
    function borrowerExit(BorrowerExitParams calldata params) external override(ISize) {
        state.validateBorrowerExit(params);
        state.executeBorrowerExit(params);
        state.validateUserIsNotLiquidatable(params.borrowerToExitTo);
    }

    /// @inheritdoc ISize
    function repay(RepayParams calldata params) external override(ISize) {
        state.validateRepay(params);
        state.executeRepay(params);
    }

    /// @inheritdoc ISize
    function claim(ClaimParams calldata params) external override(ISize) {
        state.validateClaim(params);
        state.executeClaim(params);
    }

    /// @inheritdoc ISize
    function liquidateFixedLoan(LiquidateFixedLoanParams calldata params)
        external
        override(ISize)
        returns (uint256 liquidatorProfitCollateralAsset)
    {
        state.validateLiquidateFixedLoan(params);
        liquidatorProfitCollateralAsset = state.executeLiquidateFixedLoan(params);
    }

    /// @inheritdoc ISize
    function selfLiquidateFixedLoan(SelfLiquidateFixedLoanParams calldata params) external override(ISize) {
        state.validateSelfLiquidateFixedLoan(params);
        state.executeSelfLiquidateFixedLoan(params);
    }

    /// @inheritdoc ISize
    function liquidateFixedLoanWithReplacement(LiquidateFixedLoanWithReplacementParams calldata params)
        external
        override(ISize)
        returns (uint256 liquidatorProfitCollateralAsset, uint256 liquidatorProfitBorrowAsset)
    {
        state.validateLiquidateFixedLoanWithReplacement(params);
        (liquidatorProfitCollateralAsset, liquidatorProfitBorrowAsset) =
            state.executeLiquidateFixedLoanWithReplacement(params);
        state.validateUserIsNotLiquidatable(params.borrower);
    }

    /// @inheritdoc ISize
    function moveToVariablePool(MoveToVariablePoolParams calldata params) external override(ISize) {
        state.validateMoveToVariablePool(params);
        state.executeMoveToVariablePool(params);
    }

    /// @inheritdoc ISize
    function compensate(CompensateParams calldata params) external override(ISize) {
        state.validateCompensate(params);
        state.executeCompensate(params);
    }
}
