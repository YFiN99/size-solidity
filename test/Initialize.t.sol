// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {Size} from "@src/Size.sol";
import {PriceFeedMock} from "./mocks/PriceFeedMock.sol";
import {WETH} from "./mocks/WETH.sol";
import {USDC} from "./mocks/USDC.sol";

contract InitializeTest is Test {
    Size public implementation;
    ERC1967Proxy public proxy;
    PriceFeedMock public priceFeed;
    WETH public weth;
    USDC public usdc;

    function setUp() public {
        priceFeed = new PriceFeedMock(address(this));
        weth = new WETH();
        usdc = new USDC();
    }

    function test_SizeInitialize_implementation_cannot_be_initialized() public {
        implementation = new Size();
        vm.expectRevert();
        implementation.initialize(
            address(this), address(priceFeed), address(weth), address(usdc), 1.5e4, 1.3e4, 0.3e4, 0.1e4
        );

        assertEq(implementation.CRLiquidation(), 0);
    }

    function test_SizeInitialize_proxy_can_be_initialized() public {
        implementation = new Size();
        proxy = new ERC1967Proxy(
            address(implementation),
            abi.encodeWithSelector(
                Size.initialize.selector,
                address(this),
                address(priceFeed),
                address(weth),
                address(usdc),
                1.5e4,
                1.3e4,
                0.3e4,
                0.1e4
            )
        );

        assertEq(Size(address(proxy)).CRLiquidation(), 1.3e4);
    }
}
