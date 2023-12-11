// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {console2 as console} from "forge-std/console2.sol";

import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

import {BaseTest} from "./BaseTest.sol";
import {YieldCurveLibrary} from "@src/libraries/YieldCurveLibrary.sol";
import {User} from "@src/libraries/UserLibrary.sol";
import {PERCENT} from "@src/libraries/MathLibrary.sol";
import {Loan, LoanLibrary} from "@src/libraries/LoanLibrary.sol";
import {LoanOffer, OfferLibrary} from "@src/libraries/OfferLibrary.sol";

import {FixedPointMathLib} from "@solmate/utils/FixedPointMathLib.sol";

import {Errors} from "@src/libraries/Errors.sol";

contract BorrowAsMarketOrderTest is BaseTest {
    using OfferLibrary for LoanOffer;
    using LoanLibrary for Loan;

    uint256 private constant MAX_RATE = 2e4;
    uint256 private constant MAX_DUE_DATE = 12;
    uint256 private constant MAX_AMOUNT = 100e18;

    function test_BorrowAsMarketOrder_borrowAsMarketOrder_with_real_collateral() public {
        _deposit(alice, 100e18, 100e18);
        _deposit(bob, 100e18, 100e18);
        _lendAsLimitOrder(alice, 100e18, 12, 0.03e4, 12);
        LoanOffer memory offerBefore = size.getLoanOffer(alice);

        Vars memory _before = _state();

        uint256 amount = 10e18;
        uint256 dueDate = 12;

        _borrowAsMarketOrder(bob, alice, amount, dueDate);

        uint256 debt = FixedPointMathLib.mulDivUp(amount, (PERCENT + 0.03e4), PERCENT);
        uint256 ethLocked = FixedPointMathLib.mulDivUp(debt, size.crOpening(), priceFeed.getPrice());
        Vars memory _after = _state();
        LoanOffer memory offerAfter = size.getLoanOffer(alice);

        assertEq(_after.alice.borrowAmount, _before.alice.borrowAmount - amount);
        assertEq(_after.bob.borrowAmount, _before.bob.borrowAmount + amount);
        assertEq(_after.protocolCollateralAmount, _before.protocolCollateralAmount + ethLocked);
        assertEq(_after.bob.debtAmount, debt);
        assertEq(offerAfter.maxAmount, offerBefore.maxAmount - amount);
    }

    function test_BorrowAsMarketOrder_borrowAsMarketOrder_with_real_collateral(
        uint256 amount,
        uint256 rate,
        uint256 dueDate
    ) public {
        amount = bound(amount, 1, MAX_AMOUNT / 10); // arbitrary divisor so that user does not get unhealthy
        rate = bound(rate, 0, MAX_RATE);
        dueDate = bound(dueDate, block.timestamp, block.timestamp + MAX_DUE_DATE - 1);

        amount = 10e18;
        rate = 0.03e4;
        dueDate = 12;

        _deposit(alice, MAX_AMOUNT, MAX_AMOUNT);
        _deposit(bob, MAX_AMOUNT, MAX_AMOUNT);

        _lendAsLimitOrder(alice, MAX_AMOUNT, block.timestamp + MAX_DUE_DATE, rate, MAX_DUE_DATE);
        LoanOffer memory offerBefore = size.getLoanOffer(alice);

        Vars memory _before = _state();

        _borrowAsMarketOrder(bob, alice, amount, dueDate);
        uint256 debt = FixedPointMathLib.mulDivUp(amount, (PERCENT + rate), PERCENT);
        uint256 ethLocked = FixedPointMathLib.mulDivUp(debt, size.crOpening(), priceFeed.getPrice());
        Vars memory _after = _state();
        LoanOffer memory offerAfter = size.getLoanOffer(alice);

        assertEq(_after.alice.borrowAmount, _before.alice.borrowAmount - amount);
        assertEq(_after.bob.borrowAmount, _before.bob.borrowAmount + amount);
        assertEq(_after.protocolCollateralAmount, _before.protocolCollateralAmount + ethLocked);
        assertEq(_after.bob.debtAmount, debt);
        assertEq(offerAfter.maxAmount, offerBefore.maxAmount - amount);
    }

    function test_BorrowAsMarketOrder_borrowAsMarketOrder_with_virtual_collateral() public {
        _deposit(alice, 100e18, 100e18);
        _deposit(bob, 100e18, 100e18);
        _deposit(candy, 100e18, 100e18);
        uint256 amount = 30e18;
        _lendAsLimitOrder(alice, 100e18, 12, 0.03e4, 12);
        _lendAsLimitOrder(candy, 100e18, 12, 0.03e4, 12);
        uint256 loanId = _borrowAsMarketOrder(bob, alice, 60e18, 12);
        uint256[] memory virtualCollateralLoanIds = new uint256[](1);
        virtualCollateralLoanIds[0] = loanId;

        Vars memory _before = _state();

        uint256 loanId2 = _borrowAsMarketOrder(alice, candy, amount, 12, virtualCollateralLoanIds);

        Vars memory _after = _state();

        assertEq(_after.candy.borrowAmount, _before.candy.borrowAmount - amount);
        assertEq(_after.alice.borrowAmount, _before.alice.borrowAmount + amount);
        assertEq(_after.protocolCollateralAmount, _before.protocolCollateralAmount);
        assertEq(_after.alice.debtAmount, _before.alice.debtAmount);
        assertEq(_after.bob, _before.bob);
        assertTrue(!size.isFOL(loanId2));
    }

    function test_BorrowAsMarketOrder_borrowAsMarketOrder_with_virtual_collateral(
        uint256 amount,
        uint256 rate,
        uint256 dueDate
    ) public {
        amount = bound(amount, MAX_AMOUNT / 10, 2 * MAX_AMOUNT / 10); // arbitrary divisor so that user does not get unhealthy
        rate = bound(rate, 0, MAX_RATE);
        dueDate = bound(dueDate, block.timestamp, block.timestamp + MAX_DUE_DATE - 1);

        _deposit(alice, MAX_AMOUNT, MAX_AMOUNT);
        _deposit(bob, MAX_AMOUNT, MAX_AMOUNT);
        _deposit(candy, MAX_AMOUNT, MAX_AMOUNT);

        _lendAsLimitOrder(alice, MAX_AMOUNT, block.timestamp + MAX_DUE_DATE, rate, MAX_DUE_DATE);
        _lendAsLimitOrder(candy, MAX_AMOUNT, block.timestamp + MAX_DUE_DATE, rate, MAX_DUE_DATE);
        uint256 loanId = _borrowAsMarketOrder(bob, alice, amount, dueDate);
        uint256[] memory virtualCollateralLoanIds = new uint256[](1);
        virtualCollateralLoanIds[0] = loanId;

        Vars memory _before = _state();

        uint256 loanId2 = _borrowAsMarketOrder(alice, candy, amount, dueDate, virtualCollateralLoanIds);

        Vars memory _after = _state();

        assertEq(_after.candy.borrowAmount, _before.candy.borrowAmount - amount);
        assertEq(_after.alice.borrowAmount, _before.alice.borrowAmount + amount);
        assertEq(_after.protocolCollateralAmount, _before.protocolCollateralAmount);
        assertEq(_after.alice.debtAmount, _before.alice.debtAmount);
        assertEq(_after.bob, _before.bob);
        assertTrue(!size.isFOL(loanId2));
    }

    function test_BorrowAsMarketOrder_borrowAsMarketOrder_with_virtual_collateral_and_real_collateral() public {
        _deposit(alice, 100e18, 100e18);
        _deposit(bob, 100e18, 100e18);
        _deposit(candy, 100e18, 100e18);
        _lendAsLimitOrder(alice, 100e18, 12, 0.05e4, 12);
        _lendAsLimitOrder(candy, 100e18, 12, 0.05e4, 12);
        uint256 amountLoanId1 = 10e18;
        uint256 loanId = _borrowAsMarketOrder(bob, alice, amountLoanId1, 12);
        LoanOffer memory loanOffer = size.getLoanOffer(candy);
        uint256[] memory virtualCollateralLoanIds = new uint256[](1);
        virtualCollateralLoanIds[0] = loanId;

        Vars memory _before = _state();

        uint256 dueDate = 12;
        uint256 amountLoanId2 = 30e18;
        uint256 loanId2 = _borrowAsMarketOrder(alice, candy, amountLoanId2, dueDate, virtualCollateralLoanIds);
        Loan memory loan2 = size.getLoan(loanId2);

        Vars memory _after = _state();

        uint256 r = PERCENT + loanOffer.getRate(dueDate);

        uint256 FV = FixedPointMathLib.mulDivUp(r, (amountLoanId2 - amountLoanId1), PERCENT);
        uint256 maxCollateralToLock = FixedPointMathLib.mulDivUp(FV, size.crOpening(), priceFeed.getPrice());

        assertLt(_after.candy.borrowAmount, _before.candy.borrowAmount);
        assertGt(_after.alice.borrowAmount, _before.alice.borrowAmount);
        assertEq(_after.protocolCollateralAmount, _before.protocolCollateralAmount + maxCollateralToLock);
        assertEq(_after.alice.debtAmount, _before.alice.debtAmount + FV);
        assertEq(_after.bob, _before.bob);
        assertTrue(size.isFOL(loanId2));
        assertEq(loan2.FV, FV);
    }

    function test_BorrowAsMarketOrder_borrowAsMarketOrder_with_virtual_collateral_and_real_collateral(
        uint256 amountLoanId1,
        uint256 amountLoanId2
    ) public {
        amountLoanId1 = bound(amountLoanId1, MAX_AMOUNT / 10, 2 * MAX_AMOUNT / 10); // arbitrary divisor so that user does not get unhealthy
        amountLoanId2 = bound(amountLoanId2, 3 * MAX_AMOUNT / 10, 3 * 2 * MAX_AMOUNT / 10); // arbitrary divisor so that user does not get unhealthy

        _deposit(alice, 100e18, 100e18);
        _deposit(bob, 100e18, 100e18);
        _deposit(candy, 100e18, 100e18);
        _lendAsLimitOrder(alice, 100e18, 12, 0.05e4, 12);
        _lendAsLimitOrder(candy, 100e18, 12, 0.05e4, 12);
        uint256 loanId1 = _borrowAsMarketOrder(bob, alice, amountLoanId1, 12);
        uint256[] memory virtualCollateralLoanIds = new uint256[](1);
        virtualCollateralLoanIds[0] = loanId1;

        uint256 dueDate = 12;
        uint256 r = PERCENT + size.getLoanOffer(candy).getRate(dueDate);
        uint256 deltaAmountOut = (
            FixedPointMathLib.mulDivUp(r, amountLoanId2, PERCENT) > size.getLoan(loanId1).getCredit()
        ) ? FixedPointMathLib.mulDivUp(size.getLoan(loanId1).getCredit(), PERCENT, r) : amountLoanId2;
        uint256 FV = FixedPointMathLib.mulDivUp(r, amountLoanId2 - deltaAmountOut, PERCENT);

        Vars memory _before = _state();

        uint256 loanId2 = _borrowAsMarketOrder(alice, candy, amountLoanId2, dueDate, virtualCollateralLoanIds);

        Vars memory _after = _state();

        uint256 maxCollateralToLock = FixedPointMathLib.mulDivUp(FV, size.crOpening(), priceFeed.getPrice());

        assertLt(_after.candy.borrowAmount, _before.candy.borrowAmount);
        assertGt(_after.alice.borrowAmount, _before.alice.borrowAmount);
        assertGt(_after.protocolCollateralAmount, _before.protocolCollateralAmount);
        assertEq(_after.protocolCollateralAmount, _before.protocolCollateralAmount + maxCollateralToLock);
        assertEq(_after.alice.debtAmount, _before.alice.debtAmount + FV);
        assertEq(_after.bob, _before.bob);
        assertTrue(size.isFOL(loanId2));
        assertEq(size.getLoan(loanId2).FV, FV);
    }

    function test_BorrowAsMarketOrder_borrowAsMarketOrder_with_virtual_collateral_properties() public {
        _deposit(alice, 100e18, 100e18);
        _deposit(bob, 100e18, 100e18);
        _deposit(candy, 100e18, 100e18);
        _lendAsLimitOrder(alice, 100e18, 12, 0.03e4, 12);
        _lendAsLimitOrder(candy, 100e18, 12, 0.03e4, 12);
        uint256 loanId = _borrowAsMarketOrder(bob, alice, 30e18, 12);
        uint256[] memory virtualCollateralLoanIds = new uint256[](1);
        virtualCollateralLoanIds[0] = loanId;

        Vars memory _before = _state();

        uint256 loanId2 = _borrowAsMarketOrder(alice, candy, 30e18, 12, virtualCollateralLoanIds);

        // uint256 FV = FixedPointMathLib.mulDivUp(r, amount, PERCENT);
        // uint256 maxCollateralToLock = FixedPointMathLib.mulDivUp(FV, size.crOpening(), priceFeed.getPrice());

        Vars memory _after = _state();

        assertLt(_after.candy.borrowAmount, _before.candy.borrowAmount);
        assertGt(_after.alice.borrowAmount, _before.alice.borrowAmount);
        assertEq(_after.protocolCollateralAmount, _before.protocolCollateralAmount);
        assertEq(_after.alice.debtAmount, _before.alice.debtAmount);
        assertEq(_after.bob, _before.bob);
        assertTrue(!size.isFOL(loanId2));
    }

    function test_BorrowAsMarketOrder_borrowAsMarketOrder_reverts_if_free_eth_is_lower_than_locked_amount() public {
        _deposit(alice, 100e18, 100e18);
        _lendAsLimitOrder(alice, 100e18, 12, 0.03e4, 12);
        LoanOffer memory loanOffer = size.getLoanOffer(alice);
        uint256 amount = 100e18;
        uint256 dueDate = 12;
        uint256 r = PERCENT + loanOffer.getRate(dueDate);
        uint256 FV = FixedPointMathLib.mulDivUp(r, amount, PERCENT);
        uint256 maxCollateralToLock = FixedPointMathLib.mulDivUp(FV, size.crOpening(), priceFeed.getPrice());
        vm.startPrank(bob);
        uint256[] memory virtualCollateralLoansIds;
        vm.expectRevert(
            abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, bob, 0, maxCollateralToLock)
        );
        size.borrowAsMarketOrder(alice, 100e18, 12, false, virtualCollateralLoansIds);
    }

    function test_BorrowAsMarketOrder_borrowAsMarketOrder_reverts_if_lender_cannot_transfer_borrowAsset() public {
        _deposit(alice, usdc, 1000e6);
        _deposit(bob, weth, 1e18);
        _lendAsLimitOrder(alice, 100e18, 12, 0.03e4, 12);

        _withdraw(alice, usdc, 999e6);

        uint256 amount = 10e18;
        uint256 dueDate = 12;

        vm.startPrank(bob);
        uint256[] memory virtualCollateralLoansIds;
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, alice, 1e18, 10e18));
        size.borrowAsMarketOrder(alice, amount, dueDate, false, virtualCollateralLoansIds);
    }
}
