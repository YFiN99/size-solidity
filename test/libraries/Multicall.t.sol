// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {BaseTest} from "@test/BaseTest.sol";
import {Vars} from "@test/BaseTestGeneral.sol";

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {RESERVED_ID} from "@src/libraries/fixed/LoanLibrary.sol";

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {DebtPosition} from "@src/libraries/fixed/LoanLibrary.sol";
import {RepayParams} from "@src/libraries/fixed/actions/Repay.sol";

import {Errors} from "@src/libraries/Errors.sol";

import {BorrowAsLimitOrderParams} from "@src/libraries/fixed/actions/BorrowAsLimitOrder.sol";
import {LendAsLimitOrderParams} from "@src/libraries/fixed/actions/LendAsLimitOrder.sol";
import {LiquidateParams} from "@src/libraries/fixed/actions/Liquidate.sol";
import {DepositParams} from "@src/libraries/general/actions/Deposit.sol";
import {WithdrawParams} from "@src/libraries/general/actions/Withdraw.sol";

import {YieldCurveHelper} from "@test/helpers/libraries/YieldCurveHelper.sol";

contract MulticallTest is BaseTest {
    function test_Multicall_multicall_can_deposit_and_create_loanOffer() public {
        vm.startPrank(alice);
        uint256 amount = 100e6;
        address token = address(usdc);
        deal(token, alice, amount);
        IERC20Metadata(token).approve(address(size), amount);

        assertEq(size.getUserView(alice).borrowATokenBalance, 0);

        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodeCall(size.deposit, (DepositParams({token: token, amount: amount, to: alice})));
        data[1] = abi.encodeCall(
            size.lendAsLimitOrder,
            LendAsLimitOrderParams({
                maxDueDate: block.timestamp + 1 days,
                curveRelativeTime: YieldCurveHelper.flatCurve()
            })
        );
        bytes[] memory results = size.multicall(data);

        assertEq(results.length, 2);
        assertEq(results[0], bytes(""));
        assertEq(results[1], bytes(""));

        assertEq(size.getUserView(alice).borrowATokenBalance, amount);
    }

    function test_Multicall_multicall_can_deposit_ether_and_create_borrowOffer() public {
        vm.startPrank(alice);
        uint256 amount = 1.23 ether;
        vm.deal(alice, amount);

        assertEq(size.getUserView(alice).collateralTokenBalance, 0);

        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodeCall(size.deposit, (DepositParams({token: address(weth), amount: amount, to: alice})));
        data[1] = abi.encodeCall(
            size.borrowAsLimitOrder, BorrowAsLimitOrderParams({curveRelativeTime: YieldCurveHelper.flatCurve()})
        );
        size.multicall{value: amount}(data);

        assertEq(size.getUserView(alice).collateralTokenBalance, amount);
    }

    function test_Multicall_multicall_cannot_credit_more_ether_due_to_payable() public {
        vm.startPrank(alice);
        uint256 amount = 1 wei;
        vm.deal(alice, amount);

        assertEq(size.getUserView(alice).collateralTokenBalance, 0);

        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodeCall(size.deposit, (DepositParams({token: address(weth), amount: amount, to: alice})));
        data[1] = abi.encodeCall(size.deposit, (DepositParams({token: address(weth), amount: amount, to: alice})));
        size.multicall{value: amount}(data);

        assertEq(size.getUserView(alice).collateralTokenBalance, amount);
    }

    function test_Multicall_multicall_cannot_deposit_twice() public {
        vm.startPrank(alice);
        uint256 amount = 1 wei;
        vm.deal(alice, 2 * amount);

        assertEq(size.getUserView(alice).collateralTokenBalance, 0);

        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodeCall(size.deposit, (DepositParams({token: address(weth), amount: amount, to: alice})));
        data[1] = abi.encodeCall(size.deposit, (DepositParams({token: address(weth), amount: amount, to: alice})));
        vm.expectRevert(abi.encodeWithSelector(Errors.INVALID_MSG_VALUE.selector, 2 * amount));
        size.multicall{value: 2 * amount}(data);
    }

    function test_Multicall_multicall_cannot_execute_unauthorized_actions() public {
        vm.startPrank(alice);
        uint256 amount = 100e6;
        address token = address(usdc);
        deal(token, alice, amount);
        IERC20Metadata(token).approve(address(size), amount);

        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodeCall(size.deposit, (DepositParams({token: token, amount: amount, to: alice})));
        data[1] = abi.encodeCall(size.grantRole, (0x00, alice));
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, alice, 0x00));
        size.multicall(data);
    }

    function test_Multicall_liquidator_can_liquidate_and_withdraw() public {
        _setPrice(1e18);
        _setKeeperRole(liquidator);

        _deposit(alice, weth, 100e18);
        _deposit(alice, usdc, 100e6);
        _deposit(bob, weth, 150e18);

        _lendAsLimitOrder(alice, block.timestamp + 365 days, 1e18);
        uint256 amount = 40e6;
        uint256 debtPositionId = _sellCreditMarket(bob, alice, RESERVED_ID, amount, block.timestamp + 365 days, false);
        DebtPosition memory debtPosition = size.getDebtPosition(debtPositionId);
        uint256 faceValue = debtPosition.faceValue;

        _setPrice(0.6e18);

        assertTrue(size.isDebtPositionLiquidatable(debtPositionId));

        _mint(address(usdc), liquidator, faceValue);
        _approve(liquidator, address(usdc), address(size), faceValue);

        Vars memory _before = _state();
        uint256 beforeLiquidatorUSDC = usdc.balanceOf(liquidator);
        uint256 beforeLiquidatorWETH = weth.balanceOf(liquidator);

        bytes[] memory data = new bytes[](4);
        // deposit only the necessary to cover for the loan's faceValue
        data[0] = abi.encodeCall(size.deposit, DepositParams({token: address(usdc), amount: faceValue, to: liquidator}));
        // liquidate profitably (but does not enforce CR)
        data[1] = abi.encodeCall(
            size.liquidate, LiquidateParams({debtPositionId: debtPositionId, minimumCollateralProfit: 0})
        );
        // withdraw everything
        data[2] = abi.encodeCall(
            size.withdraw, WithdrawParams({token: address(weth), amount: type(uint256).max, to: liquidator})
        );
        data[3] = abi.encodeCall(
            size.withdraw, WithdrawParams({token: address(usdc), amount: type(uint256).max, to: liquidator})
        );
        vm.prank(liquidator);
        size.multicall(data);

        Vars memory _after = _state();
        uint256 afterLiquidatorUSDC = usdc.balanceOf(liquidator);
        uint256 afterLiquidatorWETH = weth.balanceOf(liquidator);

        assertEq(_after.bob.debtBalance, _before.bob.debtBalance - faceValue, 0);
        assertEq(_after.liquidator.borrowATokenBalance, _before.liquidator.borrowATokenBalance, 0);
        assertEq(_after.liquidator.collateralTokenBalance, _before.liquidator.collateralTokenBalance, 0);
        assertGt(
            _after.feeRecipient.collateralTokenBalance,
            _before.feeRecipient.collateralTokenBalance,
            "feeRecipient has liquidation split"
        );
        assertEq(beforeLiquidatorWETH, 0);
        assertGt(afterLiquidatorWETH, beforeLiquidatorWETH);
        assertEq(beforeLiquidatorUSDC, faceValue);
        assertEq(afterLiquidatorUSDC, 0);
    }

    function test_Multicall_multicall_bypasses_cap_if_it_is_to_reduce_debt() public {
        _setPrice(1e18);
        uint256 amount = 100e6;
        uint256 cap = amount + size.getSwapFee(100e6, block.timestamp + 365 days);
        _updateConfig("borrowATokenCap", cap);

        _deposit(alice, usdc, cap);
        _deposit(bob, weth, 200e18);

        _lendAsLimitOrder(alice, block.timestamp + 365 days, 0.1e18);
        uint256 debtPositionId = _sellCreditMarket(bob, alice, RESERVED_ID, amount, block.timestamp + 365 days, false);
        uint256 faceValue = size.getDebtPosition(debtPositionId).faceValue;

        vm.warp(block.timestamp + 365 days);

        assertEq(_state().bob.debtBalance, faceValue);

        uint256 remaining = faceValue - size.getUserView(bob).borrowATokenBalance;
        _mint(address(usdc), bob, remaining);
        _approve(bob, address(usdc), address(size), remaining);

        // attempt to deposit to repay, but it reverts due to cap
        vm.expectRevert(abi.encodeWithSelector(Errors.BORROW_ATOKEN_CAP_EXCEEDED.selector, cap, cap + remaining));
        vm.prank(bob);
        size.deposit(DepositParams({token: address(usdc), amount: remaining, to: bob}));

        assertEq(_state().bob.debtBalance, faceValue);

        // debt reduction is allowed to go over cap
        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodeCall(size.deposit, DepositParams({token: address(usdc), amount: remaining, to: bob}));
        data[1] = abi.encodeCall(size.repay, RepayParams({debtPositionId: debtPositionId}));
        vm.prank(bob);
        size.multicall(data);

        assertEq(_state().bob.debtBalance, 0);
    }
}
