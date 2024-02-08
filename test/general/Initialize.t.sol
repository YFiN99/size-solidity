// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {BaseTest} from "@test/BaseTest.sol";

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {Size} from "@src/Size.sol";

contract InitializeTest is BaseTest {
    function test_Initialize_implementation_cannot_be_initialized() public {
        address owner = address(this);
        Size implementation = new Size();
        vm.expectRevert();
        implementation.initialize(owner, c, o, d);

        assertEq(implementation.config().crLiquidation, 0);
    }

    function test_Initialize_proxy_can_be_initialized() public {
        address owner = address(this);
        Size implementation = new Size();
        ERC1967Proxy proxy =
            new ERC1967Proxy(address(implementation), abi.encodeWithSelector(Size.initialize.selector, owner, c, o, d));

        assertEq(Size(address(proxy)).config().crLiquidation, 1.3e18);
    }

    function test_Initialize_wrong_initialization_reverts() public {
        Size implementation = new Size();

        vm.expectRevert();
        new ERC1967Proxy(address(implementation), abi.encodeWithSelector(Size.initialize.selector, c, o, d));
    }
}
