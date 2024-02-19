// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {BaseTest} from "@test/BaseTest.sol";

import {BorrowerExitParams} from "@src/libraries/fixed/actions/BorrowerExit.sol";

import {Errors} from "@src/libraries/Errors.sol";

contract BorrowerExitValidationTest is BaseTest {
    function test_BorrowerExit_validation() public {
        _setPrice(1e18);
        _updateConfig("repayFeeAPR", 0);

        _deposit(alice, usdc, 100e6);
        _deposit(bob, weth, 2 * 150e18);
        _deposit(candy, usdc, 100e6);
        _deposit(candy, weth, 150e18);
        _deposit(james, usdc, 100e6);
        _deposit(james, weth, 150e18);
        _lendAsLimitOrder(alice, 12, 1e18, 12);
        _lendAsLimitOrder(candy, 12, 1e18, 12);
        _lendAsLimitOrder(james, 12, 1e18, 12);
        uint256 debtPositionId = _borrowAsMarketOrder(bob, alice, 100e6, 12);
        _borrowAsLimitOrder(candy, 0, 12);
        uint256 loanId2 = _borrowAsMarketOrder(candy, james, 50e6, 12);
        uint256 creditId2 = size.getCreditPositionIdsByDebtPositionId(loanId2)[0];
        _borrowAsMarketOrder(james, candy, 10e6, 12, [creditId2]);

        address borrowerToExitTo = candy;

        vm.expectRevert(abi.encodeWithSelector(Errors.EXITER_IS_NOT_BORROWER.selector, address(this), bob));
        size.borrowerExit(
            BorrowerExitParams({
                debtPositionId: debtPositionId,
                deadline: block.timestamp,
                minRate: 0,
                borrowerToExitTo: borrowerToExitTo
            })
        );

        vm.startPrank(bob);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.NOT_ENOUGH_BORROW_ATOKEN_BALANCE.selector, 100e6, 200e6 + size.config().earlyBorrowerExitFee
            )
        );
        size.borrowerExit(
            BorrowerExitParams({
                debtPositionId: debtPositionId,
                deadline: block.timestamp,
                minRate: 0,
                borrowerToExitTo: borrowerToExitTo
            })
        );
        vm.stopPrank();

        vm.startPrank(james);
        vm.expectRevert(abi.encodeWithSelector(Errors.INVALID_DEBT_POSITION_ID.selector, creditId2));
        size.borrowerExit(
            BorrowerExitParams({
                debtPositionId: creditId2,
                deadline: block.timestamp,
                minRate: 0,
                borrowerToExitTo: borrowerToExitTo
            })
        );

        vm.startPrank(bob);
        vm.expectRevert();
        size.borrowerExit(
            BorrowerExitParams({
                debtPositionId: debtPositionId,
                deadline: block.timestamp,
                minRate: 0,
                borrowerToExitTo: address(0)
            })
        );
        vm.stopPrank();

        _deposit(bob, usdc, 200e6);
        _borrowAsLimitOrder(bob, 2, 12);
        _borrowAsLimitOrder(candy, 2, 12);

        vm.startPrank(bob);

        vm.expectRevert(abi.encodeWithSelector(Errors.RATE_LOWER_THAN_MIN_RATE.selector, 2, 3));
        size.borrowerExit(
            BorrowerExitParams({
                debtPositionId: debtPositionId,
                deadline: block.timestamp,
                minRate: 3,
                borrowerToExitTo: bob
            })
        );

        vm.expectRevert(abi.encodeWithSelector(Errors.PAST_DEADLINE.selector, block.timestamp - 1));
        size.borrowerExit(
            BorrowerExitParams({
                debtPositionId: debtPositionId,
                deadline: block.timestamp - 1,
                minRate: 0,
                borrowerToExitTo: bob
            })
        );

        vm.warp(block.timestamp + 12);
        vm.expectRevert(abi.encodeWithSelector(Errors.PAST_DUE_DATE.selector, 12));
        size.borrowerExit(
            BorrowerExitParams({
                debtPositionId: debtPositionId,
                deadline: block.timestamp,
                minRate: 0,
                borrowerToExitTo: borrowerToExitTo
            })
        );
    }
}
