// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {BaseTest} from "@test/BaseTest.sol";

import {BorrowOffer, OfferLibrary} from "@src/libraries/fixed/OfferLibrary.sol";
import {YieldCurve} from "@src/libraries/fixed/YieldCurveLibrary.sol";

import {BorrowAsLimitOrderParams} from "@src/libraries/fixed/actions/BorrowAsLimitOrder.sol";

import {Errors} from "@src/libraries/Errors.sol";

contract BorrowAsLimitOrderValidationTest is BaseTest {
    using OfferLibrary for BorrowOffer;

    function test_BorrowAsLimitOrder_validation() public {
        _deposit(alice, weth, 100e18);
        uint256[] memory maturities = new uint256[](2);
        int256[] memory marketRateMultipliers = new int256[](2);
        maturities[0] = 1 days;
        maturities[1] = 2 days;
        int256[] memory rates1 = new int256[](1);
        rates1[0] = 1.01e18;

        vm.expectRevert(abi.encodeWithSelector(Errors.ARRAY_LENGTHS_MISMATCH.selector));
        size.borrowAsLimitOrder(
            BorrowAsLimitOrderParams({
                openingLimitBorrowCR: 0,
                curveRelativeTime: YieldCurve({
                    maturities: maturities,
                    marketRateMultipliers: marketRateMultipliers,
                    rates: rates1
                })
            })
        );

        int256[] memory empty;

        vm.expectRevert(abi.encodeWithSelector(Errors.NULL_ARRAY.selector));
        size.borrowAsLimitOrder(
            BorrowAsLimitOrderParams({
                openingLimitBorrowCR: 0,
                curveRelativeTime: YieldCurve({
                    maturities: maturities,
                    marketRateMultipliers: marketRateMultipliers,
                    rates: empty
                })
            })
        );

        int256[] memory rates = new int256[](2);
        rates[0] = 1.01e18;
        rates[1] = 1.02e18;

        maturities[0] = 2 days;
        maturities[1] = 1 days;
        vm.expectRevert(abi.encodeWithSelector(Errors.MATURITIES_NOT_STRICTLY_INCREASING.selector));
        size.borrowAsLimitOrder(
            BorrowAsLimitOrderParams({
                openingLimitBorrowCR: 0,
                curveRelativeTime: YieldCurve({
                    maturities: maturities,
                    marketRateMultipliers: marketRateMultipliers,
                    rates: rates
                })
            })
        );
    }
}
