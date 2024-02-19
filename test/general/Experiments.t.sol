// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {ConversionLibrary} from "@src/libraries/ConversionLibrary.sol";
import {YieldCurve} from "@src/libraries/fixed/YieldCurveLibrary.sol";
import {BaseTest} from "@test/BaseTest.sol";
import {YieldCurveHelper} from "@test/helpers/libraries/YieldCurveHelper.sol";

import {Math} from "@src/libraries/Math.sol";

import {LoanOffer, OfferLibrary} from "@src/libraries/fixed/OfferLibrary.sol";
import {Test} from "forge-std/Test.sol";
import {console2 as console} from "forge-std/console2.sol";

import {PERCENT} from "@src/libraries/Math.sol";
import {CreditPosition, DebtPosition, LoanLibrary, LoanStatus} from "@src/libraries/fixed/LoanLibrary.sol";

contract ExperimentsTest is Test, BaseTest {
    using LoanLibrary for DebtPosition;
    using OfferLibrary for LoanOffer;

    function setUp() public override {
        vm.warp(0);
        super.setUp();
        _setPrice(100e18);
        _setKeeperRole(liquidator);
    }

    function test_Experiments_test1() public {
        _deposit(alice, usdc, 100e6 + size.config().earlyLenderExitFee);
        assertEq(_state().alice.borrowAmount, 100e6 + size.config().earlyLenderExitFee);
        _lendAsLimitOrder(alice, 10, 0.03e18, 12);
        _deposit(james, weth, 50e18);
        assertEq(_state().james.collateralAmount, 50e18);

        uint256 debtPositionId = _borrowAsMarketOrder(james, alice, 100e6, 6);
        (uint256 debtPositions,) = size.getPositionsCount();
        assertEq(debtPositionId, 0, "debt positions start at 0");
        assertGt(debtPositions, 0);
        DebtPosition memory debtPosition = size.getDebtPosition(0);
        CreditPosition memory creditPosition = size.getCreditPositions(size.getCreditPositionIdsByDebtPositionId(0))[0];
        assertEq(debtPosition.faceValue(), 100e6 * 1.03e18 / 1e18);
        assertEq(creditPosition.credit, debtPosition.faceValue());

        _deposit(bob, usdc, 100e6);
        assertEq(_state().bob.borrowAmount, 100e6);
        _lendAsLimitOrder(bob, 10, 0.02e18, 12);
        console.log("alice borrows form bob using virtual collateral");
        console.log("(do not use full CreditPosition credit)");
        uint256 creditPositionId = size.getCreditPositionIdsByDebtPositionId(0)[0];
        _borrowAsMarketOrder(alice, bob, 50e6, 6, [creditPositionId]);

        console.log("should not be able to claim");
        vm.expectRevert();
        _claim(alice, creditPositionId);

        _deposit(james, usdc, debtPosition.faceValue());
        console.log("loan is repaid");
        _repay(james, 0);
        assertEq(size.getDebt(0), 0);

        console.log("should be able to claim");
        _claim(alice, creditPositionId);

        console.log("should not be able to claim anymore since it was claimed already");
        vm.expectRevert();
        _claim(alice, creditPositionId);
    }

    function test_Experiments_test3() public {
        _deposit(bob, usdc, 100e6);
        assertEq(_state().bob.borrowAmount, 100e6);
        _lendAsLimitOrder(bob, 10, 0.03e18, 12);
        _deposit(alice, weth, 2e18);
        _borrowAsMarketOrder(alice, bob, 100e6, 6);
        assertGe(size.collateralRatio(alice), size.config().crOpening);
        assertTrue(!size.isUserLiquidatable(alice), "borrower should not be liquidatable");
        vm.warp(block.timestamp + 1);
        _setPrice(60e18);

        assertTrue(size.isUserLiquidatable(alice), "borrower should be liquidatable");
        assertTrue(size.isDebtPositionLiquidatable(0), "loan should be liquidatable");

        _deposit(liquidator, usdc, 10_000e6);
        console.log("loan should be liquidated");
        _liquidate(liquidator, 0);
    }

    function test_Experiments_testBasicExit1() public {
        uint256 amountToExitPercent = 1e18;
        // Deposit by bob in USDC
        _deposit(bob, usdc, 100e6 + size.config().earlyLenderExitFee);
        assertEq(_state().bob.borrowAmount, 100e6 + size.config().earlyLenderExitFee);

        // Bob lending as limit order
        _lendAsLimitOrder(bob, 10, 0.03e18, 12);

        // Deposit by candy in USDC
        _deposit(candy, usdc, 100e6);
        assertEq(_state().candy.borrowAmount, 100e6);

        // Candy lending as limit order
        _lendAsLimitOrder(candy, 10, 0.05e18, 12);

        // Deposit by alice in WETH
        _deposit(alice, weth, 50e18);

        // Alice borrowing as market order
        uint256 dueDate = 6;
        _borrowAsMarketOrder(alice, bob, 50e6, dueDate);

        // Assertions and operations for loans
        (uint256 debtPositions,) = size.getPositionsCount();
        assertEq(debtPositions, 1, "Expected one active loan");
        DebtPosition memory fol = size.getDebtPosition(0);
        assertTrue(size.isDebtPositionId(0), "The first loan should be DebtPosition");

        // Calculate amount to exit
        uint256 amountToExit = Math.mulDivDown(fol.faceValue(), amountToExitPercent, PERCENT);

        // Lender exiting using borrow as market order
        _borrowAsMarketOrder(
            bob,
            candy,
            amountToExit,
            dueDate,
            block.timestamp,
            type(uint256).max,
            true,
            size.getCreditPositionIdsByDebtPositionId(0)
        );

        (, uint256 creditPositionsCount) = size.getPositionsCount();

        assertEq(creditPositionsCount, 2, "Expected two active loans after lender exit");
        uint256[] memory creditPositionIds = size.getCreditPositionIdsByDebtPositionId(0);
        assertTrue(!size.isDebtPositionId(creditPositionIds[1]), "The second loan should be CreditPosition");
        assertEq(size.getCreditPosition(creditPositionIds[1]).credit, amountToExit, "Amount to Exit should match");
        assertEq(
            size.getCreditPosition(creditPositionIds[0]).credit,
            fol.faceValue() - amountToExit,
            "Should be able to exit the full amount"
        );
    }

    function test_Experiments_testBorrowWithExit1() public {
        // Bob deposits in USDC
        _deposit(bob, usdc, 100e6 + size.config().earlyLenderExitFee);
        assertEq(_state().bob.borrowAmount, 100e6 + size.config().earlyLenderExitFee);

        // Bob lends as limit order
        _lendAsLimitOrder(bob, 10, [int256(0.03e18), int256(0.03e18)], [uint256(3), uint256(8)]);

        // James deposits in USDC
        _deposit(james, usdc, 100e6);
        assertEq(_state().james.borrowAmount, 100e6);

        // James lends as limit order
        _lendAsLimitOrder(james, 12, 0.05e18, 12);

        // Alice deposits in ETH and USDC
        _deposit(alice, weth, 50e18);

        // Alice borrows from Bob using real collateral
        _borrowAsMarketOrder(alice, bob, 70e6, 5);

        // Check conditions after Alice borrows from Bob
        assertEq(
            _state().bob.borrowAmount,
            100e6 - 70e6 + size.config().earlyLenderExitFee,
            "Bob should have 30e6 left to borrow"
        );
        (uint256 debtPositionsCount, uint256 creditPositionsCount) = size.getPositionsCount();
        assertEq(debtPositionsCount, 1, "Expected one active loan");
        assertEq(creditPositionsCount, 1, "Expected one active loan");
        DebtPosition memory loan_Bob_Alice = size.getDebtPosition(0);
        assertTrue(loan_Bob_Alice.lender == bob, "Bob should be the lender");
        assertTrue(loan_Bob_Alice.borrower == alice, "Alice should be the borrower");
        LoanOffer memory loanOffer = size.getUserView(bob).user.loanOffer;
        uint256 rate = loanOffer.getRate(marketBorrowRateFeed.getMarketBorrowRate(), 5);
        assertEq(loan_Bob_Alice.faceValue(), Math.mulDivUp(70e6, (PERCENT + rate), PERCENT), "Check loan faceValue");
        assertEq(size.getDebtPosition(0).dueDate, 5, "Check loan due date");

        // Bob borrows using the loan as virtual collateral
        _borrowAsMarketOrder(bob, james, 35e6, 10, size.getCreditPositionIdsByDebtPositionId(0));

        // Check conditions after Bob borrows
        (uint256 debtPositionsCountAfter, uint256 creditPositionsCountAfter) = size.getPositionsCount();
        assertEq(_state().bob.borrowAmount, 100e6 - 70e6 + 35e6, "Bob should have borrowed 35e6");
        assertEq(debtPositionsCountAfter, 1, "Expected 1 debt position");
        assertEq(creditPositionsCountAfter, 2, "Expected two active loans");
        CreditPosition memory loan_James_Bob = size.getCreditPositions(size.getCreditPositionIdsByDebtPositionId(0))[1];
        assertEq(loan_James_Bob.lender, james, "James should be the lender");
        assertEq(loan_James_Bob.borrower, bob, "Bob should be the borrower");
        LoanOffer memory loanOffer2 = size.getUserView(james).user.loanOffer;
        uint256 rate2 = loanOffer2.getRate(marketBorrowRateFeed.getMarketBorrowRate(), size.getDebtPosition(0).dueDate);
        assertEq(loan_James_Bob.credit, Math.mulDivUp(35e6, PERCENT + rate2, PERCENT), "Check loan faceValue");
    }

    function test_Experiments_testLoanMove1() public {
        // Bob deposits in USDC
        _deposit(bob, usdc, 100e6);
        assertEq(_state().bob.borrowAmount, 100e6);

        // Bob lends as limit order
        _lendAsLimitOrder(bob, 10, [int256(0.03e18), int256(0.03e18)], [uint256(3), uint256(8)]);

        // Alice deposits in WETH
        _deposit(alice, weth, 50e18);

        // Alice borrows as market order from Bob
        _borrowAsMarketOrder(alice, bob, 70e6, 5);

        // Move forward the clock as the loan is overdue
        vm.warp(block.timestamp + 6);

        // Assert loan conditions
        DebtPosition memory fol = size.getDebtPosition(0);
        assertEq(size.getLoanStatus(0), LoanStatus.OVERDUE, "Loan should be overdue");
        (uint256 debtPositionsCount, uint256 creditPositionsCount) = size.getPositionsCount();
        assertEq(debtPositionsCount, 1, "Expect one active loan");
        assertEq(creditPositionsCount, 1, "Expect one active loan");

        assertGt(size.getDebt(0), 0, "Loan should not be repaid before moving to the variable pool");
        uint256 aliceCollateralBefore = _state().alice.collateralAmount;
        assertEq(aliceCollateralBefore, 50e18, "Alice should have no locked ETH initially");

        // add funds to the VP
        _depositVariable(liquidator, address(usdc), 1_000e6);

        // Move to variable pool
        _liquidate(liquidator, 0);

        fol = size.getDebtPosition(0);
        uint256 aliceCollateralAfter = _state().alice.collateralAmount;

        // Assert post-move conditions
        assertEq(size.getDebt(0), 0, "Loan should be repaid by moving into the variable pool");
        // assertEq(size.activeVariableLoans(), 1, "Expect one active loan in variable pool");
        assertEq(aliceCollateralAfter, 0, "Alice should have locked ETH after moving to variable pool");
    }

    function test_Experiments_testSL1() public {
        // Bob deposits in USDC
        _deposit(bob, usdc, 100e6);
        assertEq(_state().bob.borrowAmount, 100e6);

        // Bob lends as limit order
        _lendAsLimitOrder(bob, 10, 0.03e18, 12);

        // Alice deposits in WETH
        _deposit(alice, weth, 2e18);

        // Alice borrows as market order from Bob
        _borrowAsMarketOrder(alice, bob, 100e6, 6);

        // Assert conditions for Alice's borrowing
        assertGe(size.collateralRatio(alice), size.config().crOpening);
        assertTrue(!size.isUserLiquidatable(alice), "Borrower should not be liquidatable");

        vm.warp(block.timestamp + 1);
        _setPrice(30e18);

        // Assert conditions for liquidation
        assertTrue(size.isUserLiquidatable(alice), "Borrower should be liquidatable");
        assertTrue(size.isDebtPositionLiquidatable(0), "Loan should be liquidatable");

        // Perform self liquidation
        assertGt(size.getDebt(0), 0, "Loan should be greater than 0");
        assertEq(_state().bob.collateralAmount, 0, "Bob should have no free ETH initially");

        _selfLiquidate(bob, size.getCreditPositionIdsByDebtPositionId(0)[0]);

        // Assert post-liquidation conditions
        assertGt(_state().bob.collateralAmount, 0, "Bob should have free ETH after self liquidation");
        assertEq(size.getDebt(0), 0, "Loan should be 0 after self liquidation");
    }

    function test_Experiments_testLendAsLimitOrder1() public {
        // Alice deposits in WETH
        _deposit(alice, weth, 2e18);

        // Alice places a borrow limit order
        _borrowAsLimitOrder(alice, 0.03e18, 12);

        // Bob deposits in USDC
        _deposit(bob, usdc, 100e6);
        assertEq(_state().bob.borrowAmount, 100e6);

        // Assert there are no active loans initially
        (uint256 debtPositionsCount, uint256 creditPositionsCount) = size.getPositionsCount();
        assertEq(debtPositionsCount, 0, "There should be no active loans initially");

        // Bob lends to Alice's offer in the market order
        _lendAsMarketOrder(bob, alice, 70e6, 5);

        // Assert a loan is active after lending
        (debtPositionsCount, creditPositionsCount) = size.getPositionsCount();
        assertEq(debtPositionsCount, 1, "There should be one active loan after lending");
        assertEq(creditPositionsCount, 1, "There should be one active loan after lending");
    }

    function test_Experiments_testBorrowerExit1() public {
        // Bob deposits in USDC
        _deposit(bob, usdc, 100e6);
        assertEq(_state().bob.borrowAmount, 100e6);

        // Bob lends as limit order
        _lendAsLimitOrder(bob, 10, [int256(0.03e18), int256(0.03e18)], [uint256(3), uint256(8)]);

        // Candy deposits in WETH
        _deposit(candy, weth, 2e18);

        // Candy places a borrow limit order
        _borrowAsLimitOrder(candy, 0.03e18, 12);

        // Alice deposits in WETH and USDC
        _deposit(alice, weth, 50e18);
        _deposit(alice, usdc, 200e6);
        assertEq(_state().alice.borrowAmount, 200e6);

        // Alice borrows from Bob's offer
        _borrowAsMarketOrder(alice, bob, 70e6, 5);

        // Borrower (Alice) exits the loan to the offer made by Candy
        _borrowerExit(alice, 0, candy);
    }

    function test_Experiments_testLiquidationWithReplacement() public {
        // Bob deposits in USDC
        _deposit(bob, usdc, 100e6);
        assertEq(_state().bob.borrowAmount, 100e6);

        // Bob lends as limit order
        _lendAsLimitOrder(bob, 10, 0.03e18, 12);

        // Alice deposits in WETH
        _deposit(alice, weth, 2e18);

        // Alice borrows as market order from Bob
        _borrowAsMarketOrder(alice, bob, 100e6, 6);

        // Assert conditions for Alice's borrowing
        assertGe(size.collateralRatio(alice), size.config().crOpening, "Alice should be above CR opening");
        assertTrue(!size.isUserLiquidatable(alice), "Borrower should not be liquidatable");

        // Candy places a borrow limit order (candy needs more collateral so that she can be replaced later)
        _deposit(candy, weth, 200e18);
        assertEq(_state().candy.collateralAmount, 200e18);
        _borrowAsLimitOrder(candy, 0.03e18, 12);

        // Update the context (time and price)
        vm.warp(block.timestamp + 1);
        _setPrice(60e18);

        // Assert conditions for liquidation
        assertTrue(size.isUserLiquidatable(alice), "Borrower should be liquidatable");
        assertTrue(size.isDebtPositionLiquidatable(0), "Loan should be liquidatable");

        DebtPosition memory fol = size.getDebtPosition(0);
        uint256 repayFee = size.repayFee(0);
        assertEq(fol.borrower, alice, "Alice should be the borrower");
        assertEq(_state().alice.debtAmount, fol.faceValue() + repayFee, "Alice should have the debt");

        assertEq(_state().candy.debtAmount, 0, "Candy should have no debt");
        // Perform the liquidation with replacement
        _deposit(liquidator, usdc, 10_000e6);
        _liquidateWithReplacement(liquidator, 0, candy);
        assertEq(_state().alice.debtAmount, 0, "Alice should have no debt after");
        assertEq(_state().candy.debtAmount, fol.faceValue() + repayFee, "Candy should have the debt after");
    }

    function test_Experiments_testBasicCompensate1() public {
        // Bob deposits in USDC
        _deposit(bob, usdc, 100e6);
        assertEq(_state().bob.borrowAmount, 100e6, "Bob's borrow amount should be 100e6");

        // Bob lends as limit order
        _lendAsLimitOrder(bob, 10, 0.03e18, 12);

        // Candy deposits in USDC
        _deposit(candy, usdc, 100e6);
        assertEq(_state().candy.borrowAmount, 100e6, "Candy's borrow amount should be 100e6");

        // Candy lends as limit order
        _lendAsLimitOrder(candy, 10, 0.05e18, 12);

        // Alice deposits in WETH
        _deposit(alice, weth, 50e18);
        uint256 dueDate = 6;

        // Alice borrows as market order from Bob
        uint256 debtPositionId = _borrowAsMarketOrder(alice, bob, 50e6, dueDate);
        (uint256 debtPositionsCount, uint256 creditPositionsCount) = size.getPositionsCount();
        assertEq(debtPositionsCount, 1, "There should be one active loan");
        assertEq(creditPositionsCount, 1, "There should be one active loan");
        assertTrue(size.isDebtPositionId(debtPositionId), "The first loan should be DebtPosition");

        DebtPosition memory fol = size.getDebtPosition(debtPositionId);

        // Calculate amount to borrow
        uint256 amountToBorrow = fol.faceValue() / 10;

        // Bob deposits in WETH
        _deposit(bob, weth, 50e18);

        // Bob borrows as market order from Candy
        uint256 bobDebtBefore = _state().bob.debtAmount;
        uint256 loanId2 = _borrowAsMarketOrder(bob, candy, amountToBorrow, dueDate);
        uint256 bobDebtAfter = _state().bob.debtAmount;
        assertGt(bobDebtAfter, bobDebtBefore, "Bob's debt should increase");

        // Bob compensates
        uint256 debtPositionToRepayId = loanId2;
        uint256 creditPositionToCompensateId = size.getCreditPositionIdsByDebtPositionId(debtPositionId)[0];
        _compensate(bob, debtPositionToRepayId, creditPositionToCompensateId, type(uint256).max);

        assertEq(
            _state().bob.debtAmount,
            bobDebtBefore,
            "Bob's total debt covered by real collateral should revert to previous state"
        );
    }

    function test_Experiments_repayFeeAPR_simple() public {
        _setPrice(1e18);
        _deposit(bob, weth, 180e18);
        _deposit(alice, usdc, 100e6);
        YieldCurve memory curve = YieldCurveHelper.customCurve(0, 0, 365 days, 0.1e18);
        _lendAsLimitOrder(alice, block.timestamp + 365 days, curve);
        uint256 debtPositionId = _borrowAsMarketOrder(bob, alice, 100e6, 365 days);
        uint256 repayFee = size.repayFee(debtPositionId);
        // Borrower B1 submits a borror market order for
        // Loan1
        // - Lender=L
        // - Borrower=B1
        // - IV=100
        // - DD=1Y
        // - Rate=10%/Y so
        // - FV=110
        // - InitiTime=0

        vm.warp(block.timestamp + 365 days);

        _deposit(bob, usdc, 10e6);
        _repay(bob, debtPositionId);

        uint256 repayFeeWad = ConversionLibrary.amountToWad(repayFee, usdc.decimals());
        uint256 repayFeeCollateral = Math.mulDivUp(repayFeeWad, 10 ** priceFeed.decimals(), priceFeed.getPrice());

        // If the loan completes its lifecycle, we have
        // protocolFee = 100 * (0.005 * 1) --> 0.5
        assertEq(size.getUserView(feeRecipient).collateralAmount, repayFeeCollateral);
    }

    function test_Experiments_repayFeeAPR_change_fee_after_borrow() public {
        _setPrice(1e18);
        _updateConfig("repayFeeAPR", 0.05e18);
        _deposit(candy, weth, 180e18);
        _deposit(bob, weth, 180e18);
        _deposit(alice, usdc, 200e6);
        YieldCurve memory curve = YieldCurveHelper.customCurve(0, 0, 365 days, 0);
        _lendAsLimitOrder(alice, block.timestamp + 365 days, curve);
        uint256 debtPositionId = _borrowAsMarketOrder(bob, alice, 100e6, 365 days);

        // admin changes repayFeeAPR
        _updateConfig("repayFeeAPR", 0.1e18);

        uint256 loanId2 = _borrowAsMarketOrder(candy, alice, 100e6, 365 days);

        uint256 repayFee = size.repayFee(debtPositionId);
        uint256 repayFee2 = size.repayFee(loanId2);

        vm.warp(block.timestamp + 365 days);

        _repay(bob, debtPositionId);

        uint256 repayFeeWad = ConversionLibrary.amountToWad(repayFee, usdc.decimals());
        uint256 repayFeeCollateral = Math.mulDivUp(repayFeeWad, 10 ** priceFeed.decimals(), priceFeed.getPrice());
        assertEq(size.getUserView(feeRecipient).collateralAmount, repayFeeCollateral);

        _repay(candy, loanId2);

        uint256 repayFeeWad2 = ConversionLibrary.amountToWad(repayFee2, usdc.decimals());
        uint256 repayFeeCollateral2 = Math.mulDivUp(repayFeeWad2, 10 ** priceFeed.decimals(), priceFeed.getPrice());

        assertEq(size.getUserView(feeRecipient).collateralAmount, repayFeeCollateral + repayFeeCollateral2);
        assertGt(_state().bob.collateralAmount, _state().candy.collateralAmount);
        assertEq(_state().bob.collateralAmount, 180e18 - repayFeeCollateral);
        assertEq(_state().candy.collateralAmount, 180e18 - repayFeeCollateral2);
    }

    function test_Experiments_repayFeeAPR_compensate() public {
        // OK so let's make an example of the approach here
        _setPrice(1e18);
        _updateConfig("collateralTokenCap", type(uint256).max);
        address[] memory users = new address[](4);
        users[0] = alice;
        users[1] = bob;
        users[2] = candy;
        users[3] = james;
        for (uint256 i = 0; i < 4; i++) {
            _deposit(users[i], weth, 500e18);
            _deposit(users[i], usdc, 500e6);
        }
        YieldCurve memory curve = YieldCurveHelper.customCurve(0, 0, 365 days, 0.1e18);
        YieldCurve memory curve2 = YieldCurveHelper.customCurve(0, 0, 365 days, 0);
        _lendAsLimitOrder(alice, block.timestamp + 365 days, curve);
        _lendAsLimitOrder(bob, block.timestamp + 365 days, curve2);
        _lendAsLimitOrder(candy, block.timestamp + 365 days, curve2);
        _lendAsLimitOrder(james, block.timestamp + 365 days, curve2);
        uint256 debtPositionId = _borrowAsMarketOrder(bob, alice, 100e6, 365 days);
        uint256 loanId2 = _borrowAsMarketOrder(candy, james, 200e6, 365 days);
        uint256 creditId2 = size.getCreditPositionIdsByDebtPositionId(loanId2)[0];
        _borrowAsMarketOrder(james, bob, 120e6, 365 days, [creditId2]);
        uint256 creditPositionId = size.getCreditPositionIdsByDebtPositionId(loanId2)[1];
        // DebtPosition1
        // DebtPosition.Borrower = B1
        // DebtPosition.IV = 100
        // DebtPosition.FullLenderRate = 10%
        // DebtPosition.startTime = 1 Jan 2023
        // DebtPosition.dueDate = 31 Dec 2023 (months)
        // DebtPosition.lastRepaymentTime=0

        // Computable
        // DebtPosition.FV() = DebtPosition.IV * DebtPosition.FullLenderRate
        // Also tracked
        // fol.credit = DebtPosition.FV() --> 110
        assertEq(size.getDebtPosition(debtPositionId).faceValue(), 110e6);
        assertEq(size.getDebtPosition(debtPositionId).issuanceValue, 100e6);
        assertEq(size.getCreditPositionsByDebtPositionId(debtPositionId)[0].credit, 110e6);
        assertEq(size.repayFee(debtPositionId), 0.5e6);

        // At t=7 borrower compensates for an amount A=20
        // Let's say this amount comes from a CreditPosition CreditPosition1 the borrower owns, so something like
        // CreditPosition1
        // CreditPosition.lender = B1
        // CreditPosition1.credit = 120
        // CreditPosition1.DebtPosition().DueDate = 30 Dec 2023
        assertEq(size.getCreditPosition(creditPositionId).credit, 120e6);

        _compensate(bob, debtPositionId, creditPositionId, 20e6);

        // then the update is
        // CreditPosition1.credit -= 20 --> 100
        assertEq(size.getCreditPosition(creditPositionId).credit, 100e6);

        // Now Borrower has A=20 to compensate his debt on DebtPosition1 which results in
        // DebtPosition1.protocolFees(t=7) = 100 * 0.005  --> 0.29
        assertEq(size.getDebtPosition(debtPositionId).issuanceValue, 100e6 - uint256(20e6 * 1e18) / 1.1e18, 81.818182e6);
        assertEq(
            size.repayFee(debtPositionId), ((100e6 - uint256(20e6 * 1e18) / 1.1e18) * 0.005e18 / 1e18) + 1, 0.409091e6
        );

        // At this point, we need to take 0.29 USDC in fees and we have 2 ways to do it

        // 2) Taking from collateral
        // In this case, we do the same as the above with
        // NetA = A

        // and no CreditPosition_For_Repayment is emitted
        // and to take the fees instead, we do
        // collateral[borrower] -= DebtPosition1.protocolFees(t=7) / Oracle.CurrentPrice
        assertEq(_state().bob.collateralAmount, 500e18 - (0.5e6 - (0.409091e6 - 1)) * 1e12);
    }
}
