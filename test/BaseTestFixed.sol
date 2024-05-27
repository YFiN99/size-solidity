// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {Size} from "@src/Size.sol";
import {YieldCurve} from "@src/libraries/fixed/YieldCurveLibrary.sol";

import {YieldCurveHelper} from "@test/helpers/libraries/YieldCurveHelper.sol";

import {DepositParams} from "@src/libraries/general/actions/Deposit.sol";
import {WithdrawParams} from "@src/libraries/general/actions/Withdraw.sol";

import {BorrowAsLimitOrderParams} from "@src/libraries/fixed/actions/BorrowAsLimitOrder.sol";
import {SellCreditMarketParams} from "@src/libraries/fixed/actions/SellCreditMarket.sol";

import {CreditPosition, DEBT_POSITION_ID_START, DebtPosition, RESERVED_ID} from "@src/libraries/fixed/LoanLibrary.sol";

import {ClaimParams} from "@src/libraries/fixed/actions/Claim.sol";
import {LendAsLimitOrderParams} from "@src/libraries/fixed/actions/LendAsLimitOrder.sol";
import {LiquidateParams} from "@src/libraries/fixed/actions/Liquidate.sol";

import {CompensateParams} from "@src/libraries/fixed/actions/Compensate.sol";
import {LiquidateWithReplacementParams} from "@src/libraries/fixed/actions/LiquidateWithReplacement.sol";
import {RepayParams} from "@src/libraries/fixed/actions/Repay.sol";
import {SelfLiquidateParams} from "@src/libraries/fixed/actions/SelfLiquidate.sol";

import {BuyCreditMarketParams} from "@src/libraries/fixed/actions/BuyCreditMarket.sol";
import {SetUserConfigurationParams} from "@src/libraries/fixed/actions/SetUserConfiguration.sol";

import {BaseTestGeneral} from "@test/BaseTestGeneral.sol";

abstract contract BaseTestFixed is Test, BaseTestGeneral {
    function _deposit(address user, IERC20Metadata token, uint256 amount) internal {
        _deposit(user, address(token), amount, user);
    }

    function _deposit(address user, address token, uint256 amount, address to) internal {
        _mint(token, user, amount);
        _approve(user, token, address(size), amount);
        vm.prank(user);
        size.deposit(DepositParams({token: token, amount: amount, to: to}));
    }

    function _withdraw(address user, IERC20Metadata token, uint256 amount) internal {
        _withdraw(user, address(token), amount, user);
    }

    function _withdraw(address user, address token, uint256 amount, address to) internal {
        vm.prank(user);
        size.withdraw(WithdrawParams({token: token, amount: amount, to: to}));
    }

    function _lendAsLimitOrder(
        address lender,
        uint256 maxDueDate,
        int256[1] memory ratesArray,
        uint256[1] memory maturitiesArray
    ) internal {
        int256[] memory aprs = new int256[](1);
        uint256[] memory maturities = new uint256[](1);
        uint256[] memory marketRateMultipliers = new uint256[](1);
        aprs[0] = ratesArray[0];
        maturities[0] = maturitiesArray[0];
        YieldCurve memory curveRelativeTime =
            YieldCurve({maturities: maturities, marketRateMultipliers: marketRateMultipliers, aprs: aprs});
        return _lendAsLimitOrder(lender, maxDueDate, curveRelativeTime);
    }

    function _lendAsLimitOrder(
        address lender,
        uint256 maxDueDate,
        int256[2] memory ratesArray,
        uint256[2] memory maturitiesArray
    ) internal {
        int256[] memory aprs = new int256[](2);
        uint256[] memory maturities = new uint256[](2);
        uint256[] memory marketRateMultipliers = new uint256[](2);
        aprs[0] = ratesArray[0];
        aprs[1] = ratesArray[1];
        maturities[0] = maturitiesArray[0];
        maturities[1] = maturitiesArray[1];
        YieldCurve memory curveRelativeTime =
            YieldCurve({maturities: maturities, marketRateMultipliers: marketRateMultipliers, aprs: aprs});
        return _lendAsLimitOrder(lender, maxDueDate, curveRelativeTime);
    }

    function _lendAsLimitOrder(address lender, uint256 maxDueDate, int256 rate) internal {
        return _lendAsLimitOrder(lender, maxDueDate, [rate], [maxDueDate - block.timestamp]);
    }

    function _lendAsLimitOrder(address lender, uint256 maxDueDate, YieldCurve memory curveRelativeTime) internal {
        vm.prank(lender);
        size.lendAsLimitOrder(LendAsLimitOrderParams({maxDueDate: maxDueDate, curveRelativeTime: curveRelativeTime}));
    }

    function _sellCreditMarket(
        address borrower,
        address lender,
        uint256 creditPositionId,
        uint256 amount,
        uint256 dueDate,
        bool exactAmountIn
    ) internal returns (uint256) {
        vm.prank(borrower);
        size.sellCreditMarket(
            SellCreditMarketParams({
                lender: lender,
                creditPositionId: creditPositionId,
                amount: amount,
                dueDate: dueDate,
                deadline: block.timestamp,
                maxAPR: type(uint256).max,
                exactAmountIn: exactAmountIn
            })
        );
        (uint256 debtPositionsCount,) = size.getPositionsCount();
        return DEBT_POSITION_ID_START + debtPositionsCount - 1;
    }

    function _sellCreditMarket(
        address borrower,
        address lender,
        uint256 creditPositionId,
        uint256 amount,
        uint256 dueDate
    ) internal returns (uint256) {
        return _sellCreditMarket(borrower, lender, creditPositionId, amount, dueDate, true);
    }

    function _sellCreditMarket(address borrower, address lender, uint256 creditPositionId, uint256 dueDate)
        internal
        returns (uint256)
    {
        uint256 amount = size.getCreditPosition(creditPositionId).credit;
        return _sellCreditMarket(borrower, lender, creditPositionId, amount, dueDate, true);
    }

    function _sellCreditMarket(address borrower, address lender, uint256 amount, uint256 dueDate, bool exactAmountIn)
        internal
        returns (uint256)
    {
        return _sellCreditMarket(borrower, lender, RESERVED_ID, amount, dueDate, exactAmountIn);
    }

    function _borrowAsLimitOrder(address borrower, YieldCurve memory curveRelativeTime) internal {
        vm.prank(borrower);
        size.borrowAsLimitOrder(BorrowAsLimitOrderParams({curveRelativeTime: curveRelativeTime}));
    }

    function _borrowAsLimitOrder(address borrower, int256[1] memory ratesArray, uint256[1] memory maturitiesArray)
        internal
    {
        int256[] memory aprs = new int256[](1);
        uint256[] memory maturities = new uint256[](1);
        uint256[] memory marketRateMultipliers = new uint256[](1);
        aprs[0] = ratesArray[0];
        maturities[0] = maturitiesArray[0];
        YieldCurve memory curveRelativeTime =
            YieldCurve({maturities: maturities, marketRateMultipliers: marketRateMultipliers, aprs: aprs});
        return _borrowAsLimitOrder(borrower, curveRelativeTime);
    }

    function _borrowAsLimitOrder(address borrower, int256[2] memory ratesArray, uint256[2] memory maturitiesArray)
        internal
    {
        int256[] memory aprs = new int256[](2);
        uint256[] memory maturities = new uint256[](2);
        uint256[] memory marketRateMultipliers = new uint256[](2);
        aprs[0] = ratesArray[0];
        aprs[1] = ratesArray[1];
        maturities[0] = maturitiesArray[0];
        maturities[1] = maturitiesArray[1];
        YieldCurve memory curveRelativeTime =
            YieldCurve({maturities: maturities, marketRateMultipliers: marketRateMultipliers, aprs: aprs});
        return _borrowAsLimitOrder(borrower, curveRelativeTime);
    }

    function _borrowAsLimitOrder(address borrower, int256 rate, uint256 dueDate) internal {
        YieldCurve memory curveRelativeTime = YieldCurveHelper.pointCurve(dueDate - block.timestamp, rate);
        return _borrowAsLimitOrder(borrower, curveRelativeTime);
    }

    function _buyCreditMarket(address lender, uint256 creditPositionId, uint256 amount, bool exactAmountIn)
        internal
        returns (uint256)
    {
        CreditPosition memory creditPosition = size.getCreditPosition(creditPositionId);
        DebtPosition memory debtPosition = size.getDebtPosition(creditPosition.debtPositionId);
        address borrower = creditPosition.lender;
        uint256 dueDate = debtPosition.dueDate;
        return _buyCreditMarket(lender, borrower, creditPositionId, amount, dueDate, exactAmountIn);
    }

    function _buyCreditMarket(address lender, address borrower, uint256 amount, uint256 dueDate)
        internal
        returns (uint256)
    {
        return _buyCreditMarket(lender, borrower, RESERVED_ID, amount, dueDate, false);
    }

    function _buyCreditMarket(address lender, address borrower, uint256 amount, uint256 dueDate, bool exactAmountIn)
        internal
        returns (uint256)
    {
        return _buyCreditMarket(lender, borrower, RESERVED_ID, amount, dueDate, exactAmountIn);
    }

    function _buyCreditMarket(
        address user,
        address borrower,
        uint256 creditPositionId,
        uint256 amount,
        uint256 dueDate,
        bool exactAmountIn
    ) internal returns (uint256) {
        vm.prank(user);
        size.buyCreditMarket(
            BuyCreditMarketParams({
                borrower: borrower,
                creditPositionId: creditPositionId,
                dueDate: dueDate,
                amount: amount,
                exactAmountIn: exactAmountIn,
                deadline: block.timestamp,
                minAPR: 0
            })
        );

        (uint256 debtPositionsCount,) = size.getPositionsCount();
        return DEBT_POSITION_ID_START + debtPositionsCount - 1;
    }

    function _repay(address user, uint256 debtPositionId) internal {
        vm.prank(user);
        size.repay(RepayParams({debtPositionId: debtPositionId}));
    }

    function _claim(address user, uint256 creditPositionId) internal {
        vm.prank(user);
        size.claim(ClaimParams({creditPositionId: creditPositionId}));
    }

    function _liquidate(address user, uint256 debtPositionId) internal returns (uint256) {
        return _liquidate(user, debtPositionId, 0);
    }

    function _liquidate(address user, uint256 debtPositionId, uint256 minimumCollateralProfit)
        internal
        returns (uint256)
    {
        vm.prank(user);
        return size.liquidate(
            LiquidateParams({debtPositionId: debtPositionId, minimumCollateralProfit: minimumCollateralProfit})
        );
    }

    function _selfLiquidate(address user, uint256 creditPositionId) internal {
        vm.prank(user);
        return size.selfLiquidate(SelfLiquidateParams({creditPositionId: creditPositionId}));
    }

    function _liquidateWithReplacement(address user, uint256 debtPositionId, address borrower)
        internal
        returns (uint256, uint256)
    {
        return _liquidateWithReplacement(user, debtPositionId, borrower, 1e18);
    }

    function _liquidateWithReplacement(
        address user,
        uint256 debtPositionId,
        address borrower,
        uint256 minimumCollateralProfit
    ) internal returns (uint256, uint256) {
        vm.prank(user);
        return size.liquidateWithReplacement(
            LiquidateWithReplacementParams({
                debtPositionId: debtPositionId,
                borrower: borrower,
                minimumCollateralProfit: minimumCollateralProfit,
                deadline: block.timestamp,
                minAPR: 0
            })
        );
    }

    function _compensate(address user, uint256 creditPositionWithDebtToRepayId, uint256 creditPositionToCompensateId)
        internal
    {
        return _compensate(user, creditPositionWithDebtToRepayId, creditPositionToCompensateId, type(uint256).max);
    }

    function _compensate(
        address user,
        uint256 creditPositionWithDebtToRepayId,
        uint256 creditPositionToCompensateId,
        uint256 amount
    ) internal {
        vm.prank(user);
        size.compensate(
            CompensateParams({
                creditPositionWithDebtToRepayId: creditPositionWithDebtToRepayId,
                creditPositionToCompensateId: creditPositionToCompensateId,
                amount: amount
            })
        );
    }

    function _setUserConfiguration(
        address user,
        uint256 openingLimitBorrowCR,
        bool allCreditPositionsForSaleDisabled,
        bool creditPositionIdsForSale,
        uint256[] memory creditPositionIds
    ) internal {
        vm.prank(user);
        size.setUserConfiguration(
            SetUserConfigurationParams({
                openingLimitBorrowCR: openingLimitBorrowCR,
                allCreditPositionsForSaleDisabled: allCreditPositionsForSaleDisabled,
                creditPositionIdsForSale: creditPositionIdsForSale,
                creditPositionIds: creditPositionIds
            })
        );
    }
}
