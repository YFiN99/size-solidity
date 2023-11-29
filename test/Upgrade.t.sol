// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {Size} from "../src/Size.sol";
import {SizeV2} from "./mocks/SizeV2.sol";
import {PriceFeedMock} from "./mocks/PriceFeedMock.sol";
import {WETH} from "./mocks/WETH.sol";
import {USDC} from "./mocks/USDC.sol";

contract UpgradeTest is Test {
    Size public v1;
    SizeV2 public v2;
    ERC1967Proxy public proxy;
    PriceFeedMock public priceFeed;
    WETH public weth;
    USDC public usdc;

    function setUp() public {
        priceFeed = new PriceFeedMock(address(this));
        weth = new WETH();
        usdc = new USDC();
    }

    function test_SizeUpgrade_proxy_can_be_upgraded_with_uups_casting() public {
        v1 = new Size();
        proxy = new ERC1967Proxy(
            address(v1),
            abi.encodeWithSelector(
                Size.initialize.selector,
                address(this),
                priceFeed,
                address(weth),
                address(usdc),
                1.5e4,
                1.3e4,
                0.3e4,
                0.1e4
            )
        );
        v2 = new SizeV2();

        UUPSUpgradeable(address(proxy)).upgradeToAndCall(address(v2), "");
        assertEq(SizeV2(address(proxy)).version(), 2);
    }

    function test_SizeUpgrade_proxy_can_be_upgraded_directly() public {
        v1 = new Size();
        proxy = new ERC1967Proxy(
            address(v1),
            abi.encodeWithSelector(
                Size.initialize.selector,
                address(this),
                priceFeed,
                address(weth),
                address(usdc),
                1.5e4,
                1.3e4,
                0.3e4,
                0.1e4
            )
        );
        v2 = new SizeV2();

        Size(address(proxy)).upgradeToAndCall(address(v2), "");
        assertEq(SizeV2(address(proxy)).version(), 2);
    }
}
