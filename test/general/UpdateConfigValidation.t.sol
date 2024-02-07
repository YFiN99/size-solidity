// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {BaseTest} from "@test/BaseTest.sol";

import {Errors} from "@src/libraries/Errors.sol";
import {UpdateConfigParams} from "@src/libraries/general/actions/UpdateConfig.sol";

contract UpdateConfigValidationTest is BaseTest {
    function test_UpdateConfig_validation() public {
        vm.expectRevert(abi.encodeWithSelector(Errors.INVALID_KEY.selector, bytes32("invalid")));
        size.updateConfig(UpdateConfigParams({key: "invalid", value: 1e18}));
    }
}
