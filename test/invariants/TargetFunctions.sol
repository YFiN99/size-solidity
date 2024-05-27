// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Helper} from "./Helper.sol";
import {Properties} from "./Properties.sol";
import {BaseTargetFunctions} from "@chimera/BaseTargetFunctions.sol";

import "@crytic/properties/contracts/util/Hevm.sol";

import {Math, PERCENT} from "@src/libraries/Math.sol";

import {WadRayMath} from "@aave/protocol/libraries/math/WadRayMath.sol";
import {PoolMock} from "@test/mocks/PoolMock.sol";

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Deploy} from "@script/Deploy.sol";
import {PriceFeedMock} from "@test/mocks/PriceFeedMock.sol";

import {YieldCurve} from "@src/libraries/fixed/YieldCurveLibrary.sol";

import {LoanStatus} from "@src/libraries/fixed/LoanLibrary.sol";
import {SellCreditLimitParams} from "@src/libraries/fixed/actions/SellCreditLimit.sol";
import {SellCreditMarketParams} from "@src/libraries/fixed/actions/SellCreditMarket.sol";

import {ClaimParams} from "@src/libraries/fixed/actions/Claim.sol";

import {CompensateParams} from "@src/libraries/fixed/actions/Compensate.sol";

import {BuyCreditLimitParams} from "@src/libraries/fixed/actions/BuyCreditLimit.sol";
import {BuyCreditMarketParams} from "@src/libraries/fixed/actions/BuyCreditMarket.sol";
import {LiquidateParams} from "@src/libraries/fixed/actions/Liquidate.sol";
import {DepositParams} from "@src/libraries/general/actions/Deposit.sol";

import {LiquidateWithReplacementParams} from "@src/libraries/fixed/actions/LiquidateWithReplacement.sol";
import {RepayParams} from "@src/libraries/fixed/actions/Repay.sol";
import {SelfLiquidateParams} from "@src/libraries/fixed/actions/SelfLiquidate.sol";
import {WithdrawParams} from "@src/libraries/general/actions/Withdraw.sol";

import {SetUserConfigurationParams} from "@src/libraries/fixed/actions/SetUserConfiguration.sol";

import {KEEPER_ROLE} from "@src/Size.sol";

// import {console2 as console} from "forge-std/console2.sol";

import {Errors} from "@src/libraries/Errors.sol";
import {ExpectedErrors} from "@test/invariants/ExpectedErrors.sol";

import {CREDIT_POSITION_ID_START, DEBT_POSITION_ID_START, RESERVED_ID} from "@src/libraries/fixed/LoanLibrary.sol";

abstract contract TargetFunctions is Deploy, Helper, ExpectedErrors, BaseTargetFunctions {
    function setup() internal override {
        setupLocal(address(this), address(this));
        size.grantRole(KEEPER_ROLE, USER2);

        address[] memory users = new address[](3);
        users[0] = USER1;
        users[1] = USER2;
        users[2] = USER3;
        usdc.mint(address(this), MAX_AMOUNT_USDC);
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            usdc.mint(user, MAX_AMOUNT_USDC / 3);

            hevm.deal(address(this), MAX_AMOUNT_WETH / 3);
            weth.deposit{value: MAX_AMOUNT_WETH / 3}();
            weth.transfer(user, MAX_AMOUNT_WETH / 3);
        }
    }

    function deposit(address token, uint256 amount) public getSender checkExpectedErrors(DEPOSIT_ERRORS) {
        token = uint160(token) % 2 == 0 ? address(weth) : address(usdc);
        uint256 maxAmount = token == address(weth) ? MAX_AMOUNT_WETH / 3 : MAX_AMOUNT_USDC / 3;
        amount = between(amount, maxAmount / 2, maxAmount);

        __before();

        hevm.prank(sender);
        IERC20Metadata(token).approve(address(size), amount);

        hevm.prank(sender);
        (success, returnData) =
            address(size).call(abi.encodeCall(size.deposit, DepositParams({token: token, amount: amount, to: sender})));
        if (success) {
            __after();

            if (token == address(weth)) {
                eq(_after.sender.collateralTokenBalance, _before.sender.collateralTokenBalance + amount, DEPOSIT_01);
                eq(_after.senderCollateralAmount, _before.senderCollateralAmount - amount, DEPOSIT_01);
            } else {
                if (variablePool.getReserveNormalizedIncome(address(usdc)) == WadRayMath.RAY) {
                    eq(_after.sender.borrowATokenBalance, _before.sender.borrowATokenBalance + amount, DEPOSIT_01);
                }
                eq(_after.senderBorrowAmount, _before.senderBorrowAmount - amount, DEPOSIT_01);
            }
        }
    }

    function withdraw(address token, uint256 amount) public getSender checkExpectedErrors(WITHDRAW_ERRORS) {
        token = uint160(token) % 2 == 0 ? address(weth) : address(usdc);

        __before();

        uint256 maxAmount = token == address(weth) ? MAX_AMOUNT_WETH : MAX_AMOUNT_USDC;
        amount = between(amount, 0, maxAmount);

        hevm.prank(sender);
        (success, returnData) = address(size).call(
            abi.encodeCall(size.withdraw, WithdrawParams({token: token, amount: amount, to: sender}))
        );
        if (success) {
            __after();
            uint256 withdrawnAmount;

            if (token == address(weth)) {
                withdrawnAmount = Math.min(amount, _before.sender.collateralTokenBalance);
                eq(
                    _after.sender.collateralTokenBalance,
                    _before.sender.collateralTokenBalance - withdrawnAmount,
                    WITHDRAW_01
                );
                eq(_after.senderCollateralAmount, _before.senderCollateralAmount + withdrawnAmount, WITHDRAW_01);
            } else {
                withdrawnAmount = Math.min(amount, _before.sender.borrowATokenBalance);
                if (variablePool.getReserveNormalizedIncome(address(usdc)) == WadRayMath.RAY) {
                    eq(
                        _after.sender.borrowATokenBalance,
                        _before.sender.borrowATokenBalance - withdrawnAmount,
                        WITHDRAW_01
                    );
                }
                eq(_after.senderBorrowAmount, _before.senderBorrowAmount + withdrawnAmount, WITHDRAW_01);
            }
        }
    }

    function sellCreditMarket(
        address lender,
        uint256 creditPositionId,
        uint256 amount,
        uint256 dueDate,
        bool exactAmountIn
    ) public getSender checkExpectedErrors(SELL_CREDIT_MARKET_ERRORS) {
        __before();

        lender = _getRandomUser(lender);
        amount = between(amount, 0, MAX_AMOUNT_USDC / 100);
        dueDate = between(dueDate, block.timestamp, block.timestamp + MAX_DURATION);

        hevm.prank(sender);
        (success, returnData) = address(size).call(
            abi.encodeCall(
                size.sellCreditMarket,
                SellCreditMarketParams({
                    lender: lender,
                    creditPositionId: creditPositionId,
                    amount: amount,
                    dueDate: dueDate,
                    deadline: block.timestamp,
                    maxAPR: type(uint256).max,
                    exactAmountIn: exactAmountIn
                })
            )
        );

        if (success) {
            __after();

            if (lender != sender) {
                gt(_after.sender.borrowATokenBalance, _before.sender.borrowATokenBalance, BORROW_01);
            }
        }
    }

    function sellCreditLimitOrder(uint256 yieldCurveSeed)
        public
        getSender
        checkExpectedErrors(BORROW_AS_LIMIT_ORDER_ERRORS)
    {
        __before();

        YieldCurve memory curveRelativeTime = _getRandomYieldCurve(yieldCurveSeed);

        hevm.prank(sender);
        (success, returnData) = address(size).call(
            abi.encodeCall(size.sellCreditLimitOrder, SellCreditLimitParams({curveRelativeTime: curveRelativeTime}))
        );
        if (success) {
            __after();
        }
    }

    function buyCreditMarket(address borrower, uint256 dueDate, uint256 amount, bool exactAmountIn) public getSender {
        __before();

        borrower = _getRandomUser(borrower);
        dueDate = between(dueDate, block.timestamp, block.timestamp + MAX_DURATION);
        amount = between(amount, 0, _before.sender.borrowATokenBalance / 10);

        hevm.prank(sender);
        size.buyCreditMarket(
            BuyCreditMarketParams({
                borrower: borrower,
                creditPositionId: RESERVED_ID,
                dueDate: dueDate,
                amount: amount,
                deadline: block.timestamp,
                minAPR: 0,
                exactAmountIn: exactAmountIn
            })
        );
        if (success) {
            __after();

            if (sender != borrower) {
                lt(_after.sender.borrowATokenBalance, _before.sender.borrowATokenBalance, BORROW_01);
            }
            eq(_after.debtPositionsCount, _before.debtPositionsCount + 1, BORROW_02);
        }
    }

    function buyCreditLimitOrder(uint256 maxDueDate, uint256 yieldCurveSeed)
        public
        getSender
        checkExpectedErrors(LEND_AS_LIMIT_ORDER_ERRORS)
    {
        __before();

        maxDueDate = between(maxDueDate, block.timestamp, block.timestamp + MAX_DURATION);
        YieldCurve memory curveRelativeTime = _getRandomYieldCurve(yieldCurveSeed);

        hevm.prank(sender);
        (success, returnData) = address(size).call(
            abi.encodeCall(
                size.buyCreditLimitOrder,
                BuyCreditLimitParams({maxDueDate: maxDueDate, curveRelativeTime: curveRelativeTime})
            )
        );
        if (success) {
            __after();
        }
    }

    function repay(uint256 debtPositionId) public getSender hasLoans checkExpectedErrors(REPAY_ERRORS) {
        debtPositionId =
            between(debtPositionId, DEBT_POSITION_ID_START, DEBT_POSITION_ID_START + _before.debtPositionsCount - 1);
        __before(debtPositionId);

        hevm.prank(sender);
        (success, returnData) =
            address(size).call(abi.encodeCall(size.repay, RepayParams({debtPositionId: debtPositionId})));
        if (success) {
            __after(debtPositionId);

            lte(_after.sender.borrowATokenBalance, _before.sender.borrowATokenBalance, REPAY_01);
            gte(_after.variablePoolBorrowAmount, _before.variablePoolBorrowAmount, REPAY_01);
            lt(_after.borrower.debtBalance, _before.borrower.debtBalance, REPAY_02);
        }
    }

    function claim(uint256 creditPositionId) public getSender hasLoans checkExpectedErrors(CLAIM_ERRORS) {
        creditPositionId = between(
            creditPositionId, CREDIT_POSITION_ID_START, CREDIT_POSITION_ID_START + _before.creditPositionsCount - 1
        );
        __before(creditPositionId);

        hevm.prank(sender);
        (success, returnData) =
            address(size).call(abi.encodeCall(size.claim, ClaimParams({creditPositionId: creditPositionId})));
        if (success) {
            __after(creditPositionId);

            gte(_after.sender.borrowATokenBalance, _before.sender.borrowATokenBalance, BORROW_01);
            t(size.isCreditPositionId(creditPositionId), CLAIM_02);
        }
    }

    function liquidate(uint256 debtPositionId, uint256 minimumCollateralProfit)
        public
        getSender
        hasLoans
        checkExpectedErrors(LIQUIDATE_ERRORS)
    {
        debtPositionId =
            between(debtPositionId, DEBT_POSITION_ID_START, DEBT_POSITION_ID_START + _before.debtPositionsCount - 1);
        __before(debtPositionId);

        minimumCollateralProfit = between(minimumCollateralProfit, 0, MAX_AMOUNT_WETH);

        hevm.prank(sender);
        (success, returnData) = address(size).call(
            abi.encodeCall(
                size.liquidate,
                LiquidateParams({debtPositionId: debtPositionId, minimumCollateralProfit: minimumCollateralProfit})
            )
        );
        if (success) {
            __after(debtPositionId);

            uint256 liquidatorProfitCollateralToken = abi.decode(returnData, (uint256));

            if (sender != _before.borrower.account) {
                gte(
                    _after.sender.collateralTokenBalance,
                    _before.sender.collateralTokenBalance + liquidatorProfitCollateralToken,
                    LIQUIDATE_01
                );
            }
            if (_before.loanStatus != LoanStatus.OVERDUE) {
                lt(_after.sender.borrowATokenBalance, _before.sender.borrowATokenBalance, LIQUIDATE_02);
            }
            lt(_after.borrower.debtBalance, _before.borrower.debtBalance, LIQUIDATE_02);
            t(_before.isBorrowerLiquidatable || _before.loanStatus == LoanStatus.OVERDUE, LIQUIDATE_03);
        }
    }

    function selfLiquidate(uint256 creditPositionId)
        public
        getSender
        hasLoans
        checkExpectedErrors(SELF_LIQUIDATE_ERRORS)
    {
        creditPositionId = between(
            creditPositionId, CREDIT_POSITION_ID_START, CREDIT_POSITION_ID_START + _before.creditPositionsCount - 1
        );
        __before(creditPositionId);

        hevm.prank(sender);
        (success, returnData) = address(size).call(
            abi.encodeCall(size.selfLiquidate, SelfLiquidateParams({creditPositionId: creditPositionId}))
        );
        if (success) {
            __after(creditPositionId);

            if (sender != _before.borrower.account) {
                gte(_after.sender.collateralTokenBalance, _before.sender.collateralTokenBalance, SELF_LIQUIDATE_01);
            }
            lte(_after.borrower.debtBalance, _before.borrower.debtBalance, SELF_LIQUIDATE_02);
        }
    }

    function liquidateWithReplacement(uint256 debtPositionId, uint256 minimumCollateralProfit, address borrower)
        public
        getSender
        hasLoans
        checkExpectedErrors(LIQUIDATE_WITH_REPLACEMENT_ERRORS)
    {
        debtPositionId =
            between(debtPositionId, DEBT_POSITION_ID_START, DEBT_POSITION_ID_START + _before.debtPositionsCount - 1);
        __before(debtPositionId);

        minimumCollateralProfit = between(minimumCollateralProfit, 0, MAX_AMOUNT_WETH);

        borrower = _getRandomUser(borrower);

        hevm.prank(sender);
        (success, returnData) = address(size).call(
            abi.encodeCall(
                size.liquidateWithReplacement,
                LiquidateWithReplacementParams({
                    debtPositionId: debtPositionId,
                    minAPR: 0,
                    deadline: block.timestamp,
                    borrower: borrower,
                    minimumCollateralProfit: minimumCollateralProfit
                })
            )
        );
        if (success) {
            __after(debtPositionId);
            (uint256 liquidatorProfitCollateralToken,) = abi.decode(returnData, (uint256, uint256));

            gte(
                _after.sender.collateralTokenBalance,
                _before.sender.collateralTokenBalance + liquidatorProfitCollateralToken,
                LIQUIDATE_01
            );
            lt(_after.borrower.debtBalance, _before.borrower.debtBalance, LIQUIDATE_02);
        }
    }

    function compensate(uint256 creditPositionWithDebtToRepayId, uint256 creditPositionToCompensateId, uint256 amount)
        public
        getSender
        hasLoans
        checkExpectedErrors(COMPENSATE_ERRORS)
    {
        creditPositionWithDebtToRepayId = between(
            creditPositionWithDebtToRepayId,
            CREDIT_POSITION_ID_START,
            CREDIT_POSITION_ID_START + _before.creditPositionsCount - 1
        );
        creditPositionToCompensateId = between(
            creditPositionToCompensateId,
            CREDIT_POSITION_ID_START,
            CREDIT_POSITION_ID_START + _before.creditPositionsCount - 1
        );

        __before(creditPositionWithDebtToRepayId);

        hevm.prank(sender);
        (success, returnData) = address(size).call(
            abi.encodeCall(
                size.compensate,
                CompensateParams({
                    creditPositionWithDebtToRepayId: creditPositionWithDebtToRepayId,
                    creditPositionToCompensateId: creditPositionToCompensateId,
                    amount: amount
                })
            )
        );
        if (success) {
            __after(creditPositionWithDebtToRepayId);

            lt(_after.borrower.debtBalance, _before.borrower.debtBalance, COMPENSATE_01);
        }
    }

    function setUserConfiguration(uint256 openingLimitBorrowCR, bool allCreditPositionsForSaleDisabled)
        public
        getSender
        checkExpectedErrors(SET_USER_CONFIGURATION_ERRORS)
    {
        __before();

        hevm.prank(sender);
        (success, returnData) = address(size).call(
            abi.encodeCall(
                size.setUserConfiguration,
                SetUserConfigurationParams({
                    openingLimitBorrowCR: openingLimitBorrowCR,
                    allCreditPositionsForSaleDisabled: allCreditPositionsForSaleDisabled,
                    creditPositionIdsForSale: false,
                    creditPositionIds: new uint256[](0)
                })
            )
        );
        if (success) {
            __after();
        }
    }

    function setPrice(uint256 price) public {
        price = between(price, MIN_PRICE, MAX_PRICE);
        PriceFeedMock(address(priceFeed)).setPrice(price);
    }

    function setLiquidityIndex(uint256 liquidityIndex, uint256 supplyAmount) public {
        uint256 currentLiquidityIndex = variablePool.getReserveNormalizedIncome(address(usdc));
        liquidityIndex =
            (between(liquidityIndex, PERCENT, MAX_LIQUIDITY_INDEX_INCREASE_PERCENT)) * currentLiquidityIndex / PERCENT;
        PoolMock(address(variablePool)).setLiquidityIndex(address(usdc), liquidityIndex);

        supplyAmount = between(supplyAmount, 0, MAX_AMOUNT_USDC);
        if (supplyAmount > 0) {
            usdc.approve(address(variablePool), supplyAmount);
            variablePool.supply(address(usdc), supplyAmount, address(this), 0);
        }
    }
}
