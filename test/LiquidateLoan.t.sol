// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {BaseTest, Vars} from "./BaseTest.sol";

import {FixedPointMathLib} from "@solmate/utils/FixedPointMathLib.sol";
import {LoanStatus} from "@src/libraries/LoanLibrary.sol";
import {PERCENT} from "@src/libraries/MathLibrary.sol";

contract LiquidateLoanTest is BaseTest {
    function test_LiquidateLoan_liquidateLoan_seizes_borrower_collateral() public {
        _setPrice(1e18);

        _deposit(alice, 100e18, 100e18);
        _deposit(bob, 100e18, 100e18);
        _deposit(liquidator, 100e18, 100e18);

        assertEq(size.collateralRatio(bob), type(uint256).max);

        _lendAsLimitOrder(alice, 100e18, 12, 0.03e18, 12);
        uint256 amount = 15e18;
        uint256 loanId = _borrowAsMarketOrder(bob, alice, amount, 12);
        uint256 debt = FixedPointMathLib.mulDivUp(amount, (PERCENT + 0.03e18), PERCENT);
        uint256 debtOpening = FixedPointMathLib.mulDivUp(debt, size.crOpening(), PERCENT);
        uint256 lock = FixedPointMathLib.mulDivUp(debtOpening, 10 ** priceFeed.decimals(), priceFeed.getPrice());
        // nothing is locked anymore on v2
        lock = 0;
        uint256 assigned = 100e18 - lock;

        assertEq(size.getAssignedCollateral(loanId), assigned);
        assertEq(size.getDebt(loanId), debt);
        assertEq(size.collateralRatio(bob), FixedPointMathLib.mulDivDown(assigned, PERCENT, (debt * 1)));
        assertTrue(!size.isLiquidatable(bob));
        assertTrue(!size.isLiquidatable(loanId));

        _setPrice(0.2e18);

        assertEq(size.getAssignedCollateral(loanId), assigned);
        assertEq(size.getDebt(loanId), debt);
        assertEq(size.collateralRatio(bob), FixedPointMathLib.mulDivDown(assigned, PERCENT, (debt * 5)));
        assertTrue(size.isLiquidatable(bob));
        assertTrue(size.isLiquidatable(loanId));

        Vars memory _before = _state();

        uint256 liquidatorProfit = _liquidateLoan(liquidator, loanId);

        uint256 collateralRemainder = assigned - (debt * 5);

        Vars memory _after = _state();

        assertEq(_after.liquidator.borrowAmount, _before.liquidator.borrowAmount - debt);
        assertEq(_after.protocolBorrowAmount, _before.protocolBorrowAmount + debt);
        assertEq(
            _after.feeRecipientCollateralAmount,
            _before.feeRecipientCollateralAmount
                + FixedPointMathLib.mulDivDown(collateralRemainder, size.collateralPercentagePremiumToProtocol(), PERCENT)
        );
        assertEq(
            _after.bob.collateralAmount,
            _before.bob.collateralAmount - (debt * 5)
                - FixedPointMathLib.mulDivDown(
                    collateralRemainder,
                    (size.collateralPercentagePremiumToProtocol() + size.collateralPercentagePremiumToLiquidator()),
                    PERCENT
                ),
            _before.bob.collateralAmount - (debt * 5) - collateralRemainder
                + FixedPointMathLib.mulDivDown(collateralRemainder, size.collateralPercentagePremiumToBorrower(), PERCENT)
        );
        uint256 liquidatorProfitAmount = (debt * 5)
            + FixedPointMathLib.mulDivDown(collateralRemainder, size.collateralPercentagePremiumToLiquidator(), PERCENT);
        assertEq(_after.liquidator.collateralAmount, _before.liquidator.collateralAmount + liquidatorProfitAmount);
        assertEq(liquidatorProfit, liquidatorProfitAmount);
    }

    function test_LiquidateLoan_liquidateLoan_repays_loan() public {
        _setPrice(1e18);

        _deposit(alice, 100e18, 100e18);
        _deposit(bob, 100e18, 100e18);
        _deposit(liquidator, 100e18, 100e18);

        _lendAsLimitOrder(alice, 100e18, 12, 0.03e18, 12);
        uint256 loanId = _borrowAsMarketOrder(bob, alice, 15e18, 12);

        _setPrice(0.2e18);

        assertTrue(size.isLiquidatable(loanId));
        assertEq(size.getLoanStatus(loanId), LoanStatus.ACTIVE);

        _liquidateLoan(liquidator, loanId);

        assertEq(size.getLoanStatus(loanId), LoanStatus.REPAID);
    }

    function test_LiquidateLoan_liquidateLoan_reduces_borrower_debt() public {
        _setPrice(1e18);

        _deposit(alice, 100e18, 100e18);
        _deposit(bob, 100e18, 100e18);
        _deposit(liquidator, 100e18, 100e18);

        _lendAsLimitOrder(alice, 100e18, 12, 0.03e18, 12);
        uint256 amount = 15e18;
        uint256 loanId = _borrowAsMarketOrder(bob, alice, amount, 12);
        uint256 debt = FixedPointMathLib.mulDivUp(amount, (PERCENT + 0.03e18), PERCENT);

        _setPrice(0.2e18);

        assertTrue(size.isLiquidatable(loanId));

        Vars memory _before = _state();

        _liquidateLoan(liquidator, loanId);

        Vars memory _after = _state();

        assertEq(_after.bob.debtAmount, _before.bob.debtAmount - debt, 0);
    }

    function test_LiquidateLoan_liquidateLoan_can_be_called_unprofitably() public {
        _setPrice(1e18);

        _deposit(alice, 100e18, 100e18);
        _deposit(bob, 100e18, 100e18);
        _deposit(liquidator, 1000e18, 1000e18);

        _lendAsLimitOrder(alice, 100e18, 12, 0.03e18, 12);
        uint256 amount = 15e18;
        uint256 loanId = _borrowAsMarketOrder(bob, alice, amount, 12);

        _setPrice(0.1e18);

        assertTrue(size.isLiquidatable(loanId));
        uint256 assignedCollateral = size.getAssignedCollateral(loanId);
        uint256 debtCollateral =
            FixedPointMathLib.mulDivDown(size.getDebt(loanId), 10 ** priceFeed.decimals(), priceFeed.getPrice());

        uint256 liquidatorProfit = _liquidateLoan(liquidator, loanId, 0);

        assertLt(liquidatorProfit, debtCollateral);
        assertEq(liquidatorProfit, assignedCollateral);
        assertEq(size.getAssignedCollateral(loanId), 0);
        assertEq(size.getUserView(bob).collateralAmount, 0);
    }
}
