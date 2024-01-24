// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {MulticallUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";

import {
    Initialize,
    InitializeFixedParams,
    InitializeGeneralParams,
    InitializeVariableParams
} from "@src/libraries/general/actions/Initialize.sol";
import {UpdateConfig, UpdateConfigParams} from "@src/libraries/general/actions/UpdateConfig.sol";

import {FixedLibrary} from "@src/libraries/fixed/FixedLibrary.sol";

import {SizeFixed} from "@src/SizeFixed.sol";
import {SizeVariable} from "@src/SizeVariable.sol";
import {SizeView} from "@src/SizeView.sol";

import {State} from "@src/SizeStorage.sol";

import {ISize} from "@src/interfaces/ISize.sol";

contract Size is
    ISize,
    SizeView,
    SizeFixed,
    SizeVariable,
    Initializable,
    Ownable2StepUpgradeable,
    MulticallUpgradeable,
    UUPSUpgradeable
{
    using Initialize for State;
    using UpdateConfig for State;
    using FixedLibrary for State;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        InitializeGeneralParams calldata g,
        InitializeFixedParams calldata f,
        InitializeVariableParams calldata v
    ) external initializer {
        state.validateInitialize(g, f, v);

        __Ownable_init(g.owner);
        __Ownable2Step_init();
        __Multicall_init();
        __UUPSUpgradeable_init();

        state.executeInitialize(g, f, v);
    }

    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function updateConfig(UpdateConfigParams calldata params) external onlyOwner {
        state.validateUpdateConfig(params);
        state.executeUpdateConfig(params);
    }
}
