// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {UserView} from "@src/SizeView.sol";
import {BaseTest} from "@test/BaseTest.sol";

contract DepositTest is BaseTest {
    function test_Deposit_deposit_increases_user_balance() public {
        _deposit(alice, address(usdc), 1e6);
        UserView memory aliceUser = size.getUserView(alice);
        assertEq(aliceUser.borrowATokenBalance, 1e6);
        assertEq(aliceUser.collateralBalance, 0);
        assertEq(usdc.balanceOf(address(variablePool)), 1e6);

        _deposit(alice, address(weth), 2e18);
        aliceUser = size.getUserView(alice);
        assertEq(aliceUser.borrowATokenBalance, 1e6);
        assertEq(aliceUser.collateralBalance, 2e18);
        assertEq(weth.balanceOf(address(size)), 2e18);
    }

    function testFuzz_Deposit_deposit_increases_user_balance(uint256 x, uint256 y) public {
        _updateConfig("collateralTokenCap", type(uint256).max);
        _updateConfig("borrowATokenCap", type(uint256).max);
        x = bound(x, 1, type(uint128).max);
        y = bound(y, 1, type(uint128).max);

        _deposit(alice, address(usdc), x);
        UserView memory aliceUser = size.getUserView(alice);
        assertEq(aliceUser.borrowATokenBalance, x);
        assertEq(aliceUser.collateralBalance, 0);
        assertEq(usdc.balanceOf(address(variablePool)), x);

        _deposit(alice, address(weth), y);
        aliceUser = size.getUserView(alice);
        assertEq(aliceUser.borrowATokenBalance, x);
        assertEq(aliceUser.collateralBalance, y);
        assertEq(weth.balanceOf(address(size)), y);
    }
}
