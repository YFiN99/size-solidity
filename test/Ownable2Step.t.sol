// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {BaseTest, Vars} from "./BaseTest.sol";

contract Ownable2StepTest is BaseTest {
    function test_Ownable2Step_has_owner() public {
        assertEq(size.owner(), address(this));
    }

    function test_Ownable2Step_transferOwnership_does_not_change_owner() public {
        size.transferOwnership(address(0x1));
        assertEq(size.owner(), address(this));
    }

    function test_Ownable2Step_transferOwnership_changes_owner_acceptOwnership() public {
        size.transferOwnership(address(0x1));
        assertEq(size.owner(), address(this));
        vm.prank(address(0x1));
        size.acceptOwnership();
        assertEq(size.owner(), address(0x1));
    }
}
