// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {Test} from "forge-std/Test.sol";

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {UpdateConfigParams} from "@src/libraries/general/actions/UpdateConfig.sol";

import {UserView} from "@src/SizeView.sol";

import {Deploy} from "./Deploy.sol";

struct Vars {
    UserView alice;
    UserView bob;
    UserView candy;
    UserView james;
    UserView liquidator;
    UserView variablePool;
    UserView size;
    UserView feeRecipient;
}

abstract contract BaseTestGeneral is Test, Deploy {
    address internal alice = address(0x10000);
    address internal bob = address(0x20000);
    address internal candy = address(0x30000);
    address internal james = address(0x40000);
    address internal liquidator = address(0x50000);
    address internal feeRecipient = address(0x70000);

    function setUp() public virtual {
        vm.label(alice, "alice");
        vm.label(bob, "bob");
        vm.label(candy, "candy");
        vm.label(james, "james");
        vm.label(liquidator, "liquidator");
        vm.label(feeRecipient, "feeRecipient");

        setup(address(this), feeRecipient);
    }

    function _mint(address token, address user, uint256 amount) internal {
        deal(token, user, amount);
    }

    function _approve(address user, address token, address spender, uint256 amount) internal {
        vm.prank(user);
        IERC20Metadata(token).approve(spender, amount);
    }

    function _state() internal view returns (Vars memory vars) {
        vars.alice = size.getUserView(alice);
        vars.bob = size.getUserView(bob);
        vars.candy = size.getUserView(candy);
        vars.james = size.getUserView(james);
        vars.liquidator = size.getUserView(liquidator);
        vars.variablePool = size.getUserView(address(variablePool));
        vars.size = size.getUserView(address(size));
        vars.feeRecipient = size.getUserView(feeRecipient);
    }

    function _setPrice(uint256 price) internal {
        vm.prank(address(this));
        priceFeed.setPrice(price);
    }

    function _updateConfig(bytes32 key, uint256 value) internal {
        vm.prank(address(this));
        size.updateConfig(UpdateConfigParams({key: key, value: value}));
    }

    function _setKeeperRole(address user) internal {
        vm.prank(address(this));
        size.grantRole(size.KEEPER_ROLE(), user);
    }
}
