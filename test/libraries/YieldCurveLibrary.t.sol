// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {Errors} from "@src/libraries/Errors.sol";

import {Math} from "@src/libraries/Math.sol";
import {YieldCurve, YieldCurveLibrary} from "@src/libraries/fixed/YieldCurveLibrary.sol";

import {IMarketBorrowRateFeed} from "@src/oracle/IMarketBorrowRateFeed.sol";

import {AssertsHelper} from "@test/helpers/AssertsHelper.sol";
import {YieldCurveHelper} from "@test/helpers/libraries/YieldCurveHelper.sol";
import {MarketBorrowRateFeedMock} from "@test/mocks/MarketBorrowRateFeedMock.sol";
import {Test} from "forge-std/Test.sol";

contract YieldCurveTest is Test, AssertsHelper {
    MarketBorrowRateFeedMock marketBorrowRateFeed;

    function setUp() public {
        marketBorrowRateFeed = new MarketBorrowRateFeedMock(address(this));
        marketBorrowRateFeed.setMarketBorrowRate(0);
    }

    function test_YieldCurve_getRate_below_timestamp() public {
        YieldCurve memory curve = YieldCurveHelper.normalCurve();
        vm.expectRevert(abi.encodeWithSelector(Errors.PAST_DUE_DATE.selector, 0));
        YieldCurveLibrary.getRate(curve, marketBorrowRateFeed, 0);
    }

    function test_YieldCurve_getRate_below_bounds() public {
        YieldCurve memory curve = YieldCurveHelper.normalCurve();
        uint256 interval = curve.maturities[0] - 1;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.DUE_DATE_OUT_OF_RANGE.selector,
                interval,
                curve.maturities[0],
                curve.maturities[curve.maturities.length - 1]
            )
        );
        YieldCurveLibrary.getRate(curve, marketBorrowRateFeed, block.timestamp + interval);
    }

    function test_YieldCurve_getRate_after_bounds() public {
        YieldCurve memory curve = YieldCurveHelper.normalCurve();
        uint256 interval = curve.maturities[curve.maturities.length - 1] + 1;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.DUE_DATE_OUT_OF_RANGE.selector,
                interval,
                curve.maturities[0],
                curve.maturities[curve.maturities.length - 1]
            )
        );
        YieldCurveLibrary.getRate(curve, marketBorrowRateFeed, block.timestamp + interval);
    }

    function test_YieldCurve_getRate_first_point() public {
        YieldCurve memory curve = YieldCurveHelper.normalCurve();
        uint256 interval = curve.maturities[0];
        uint256 rate = YieldCurveLibrary.getRate(curve, marketBorrowRateFeed, block.timestamp + interval);
        assertEq(rate, SafeCast.toUint256(curve.rates[0]));
    }

    function test_YieldCurve_getRate_last_point() public {
        YieldCurve memory curve = YieldCurveHelper.normalCurve();
        uint256 interval = curve.maturities[curve.maturities.length - 1];
        uint256 rate = YieldCurveLibrary.getRate(curve, marketBorrowRateFeed, block.timestamp + interval);
        assertEq(rate, SafeCast.toUint256(curve.rates[curve.rates.length - 1]));
    }

    function test_YieldCurve_getRate_middle_point() public {
        YieldCurve memory curve = YieldCurveHelper.normalCurve();
        uint256 interval = curve.maturities[2];
        uint256 rate = YieldCurveLibrary.getRate(curve, marketBorrowRateFeed, block.timestamp + interval);
        assertEq(rate, SafeCast.toUint256(curve.rates[2]));
    }

    function test_YieldCurve_getRate_point_2_out_of_5() public {
        YieldCurve memory curve = YieldCurveHelper.normalCurve();
        uint256 interval = curve.maturities[1];
        uint256 rate = YieldCurveLibrary.getRate(curve, marketBorrowRateFeed, block.timestamp + interval);
        assertEq(rate, SafeCast.toUint256(curve.rates[1]));
    }

    function test_YieldCurve_getRate_point_4_out_of_5() public {
        YieldCurve memory curve = YieldCurveHelper.normalCurve();
        uint256 interval = curve.maturities[3];
        uint256 rate = YieldCurveLibrary.getRate(curve, marketBorrowRateFeed, block.timestamp + interval);
        assertEq(rate, SafeCast.toUint256(curve.rates[3]));
    }

    function test_YieldCurve_getRate_point_interpolated_slope_eq_0(
        uint256 p0,
        uint256 p1,
        uint256 ip,
        uint256 q0,
        uint256 q1,
        uint256 iq
    ) public {
        YieldCurve memory curve = YieldCurveHelper.flatCurve();
        p0 = bound(p0, 0, curve.maturities.length - 1);
        p1 = bound(p1, p0, curve.maturities.length - 1);
        ip = bound(ip, curve.maturities[p0], curve.maturities[p1]);
        uint256 rate0 = YieldCurveLibrary.getRate(curve, marketBorrowRateFeed, block.timestamp + ip);

        q0 = bound(q0, 0, curve.maturities.length - 1);
        q1 = bound(q1, q0, curve.maturities.length - 1);
        iq = bound(ip, curve.maturities[q0], curve.maturities[q1]);
        uint256 rate1 = YieldCurveLibrary.getRate(curve, marketBorrowRateFeed, block.timestamp + iq);
        assertEq(rate1, rate0);
        assertEq(rate0, SafeCast.toUint256(curve.rates[0]));
    }

    function test_YieldCurve_getRate_point_interpolated_slope_lt_0(
        uint256 p0,
        uint256 p1,
        uint256 ip,
        uint256 q0,
        uint256 q1,
        uint256 iq
    ) public {
        YieldCurve memory curve = YieldCurveHelper.negativeCurve();
        p0 = bound(p0, 0, curve.maturities.length - 1);
        p1 = bound(p1, p0, curve.maturities.length - 1);
        ip = bound(ip, curve.maturities[p0], curve.maturities[p1]);
        uint256 rate0 = YieldCurveLibrary.getRate(curve, marketBorrowRateFeed, block.timestamp + ip);

        q0 = bound(q0, p1, curve.maturities.length - 1);
        q1 = bound(q1, q0, curve.maturities.length - 1);
        iq = bound(ip, curve.maturities[q0], curve.maturities[q1]);
        uint256 rate1 = YieldCurveLibrary.getRate(curve, marketBorrowRateFeed, block.timestamp + iq);
        assertLe(rate1, rate0);
    }

    function test_YieldCurve_getRate_point_interpolated_slope_gt_0(
        uint256 p0,
        uint256 p1,
        uint256 ip,
        uint256 q0,
        uint256 q1,
        uint256 iq
    ) public {
        YieldCurve memory curve = YieldCurveHelper.normalCurve();
        p0 = bound(p0, 0, curve.maturities.length - 1);
        p1 = bound(p1, p0, curve.maturities.length - 1);
        ip = bound(ip, curve.maturities[p0], curve.maturities[p1]);
        uint256 rate0 = YieldCurveLibrary.getRate(curve, marketBorrowRateFeed, block.timestamp + ip);

        q0 = bound(q0, p1, curve.maturities.length - 1);
        q1 = bound(q1, q0, curve.maturities.length - 1);
        iq = bound(ip, curve.maturities[q0], curve.maturities[q1]);
        uint256 rate1 = YieldCurveLibrary.getRate(curve, marketBorrowRateFeed, block.timestamp + iq);
        assertGe(rate1, rate0);
    }

    function testFuzz_YieldCurve_getRate_full_random_does_not_revert(
        uint256 seed,
        uint256 p0,
        uint256 p1,
        uint256 interval
    ) public {
        YieldCurve memory curve = YieldCurveHelper.getRandomYieldCurve(seed);
        p0 = bound(p0, 0, curve.maturities.length - 1);
        p1 = bound(p1, p0, curve.maturities.length - 1);
        interval = bound(interval, curve.maturities[p0], curve.maturities[p1]);
        uint256 min = type(uint256).max;
        uint256 max = 0;
        for (uint256 i = 0; i < curve.rates.length; i++) {
            uint256 rate = SafeCast.toUint256(curve.rates[i]);
            if (rate < min) {
                min = rate;
            }
            if (rate > max) {
                max = rate;
            }
        }
        uint256 r = YieldCurveLibrary.getRate(curve, marketBorrowRateFeed, block.timestamp + interval);
        assertGe(r, min);
        assertLe(r, max);
    }

    function test_YieldCurve_getRate_with_non_null_marketBorrowRate() public {
        YieldCurve memory curve = YieldCurveHelper.marketCurve();
        marketBorrowRateFeed.setMarketBorrowRate(0.31415e18);
        uint256 linearRate = Math.compoundRateToLinearRate(0.31415e18, 60 days);

        assertEq(
            YieldCurveLibrary.getRate(curve, marketBorrowRateFeed, block.timestamp + 60 days), linearRate + 0.02e18
        );
    }

    function test_YieldCurve_getRate_with_non_null_marketBorrowRate_negative_multiplier() public {
        YieldCurve memory curve = YieldCurveHelper.negativeMarketCurve();
        marketBorrowRateFeed.setMarketBorrowRate(0.01337e18);
        uint256 linearRate = Math.compoundRateToLinearRate(0.01337e18, 60 days);

        assertEq(
            YieldCurveLibrary.getRate(curve, marketBorrowRateFeed, block.timestamp + 60 days), 0.04e18 - linearRate
        );
    }

    function test_YieldCurve_getRate_with_negative_rate() public {
        marketBorrowRateFeed.setMarketBorrowRate(0.07e18);
        uint256 linearRate = Math.compoundRateToLinearRate(0.07e18, 30 days);
        YieldCurve memory curve = YieldCurveHelper.customCurve(20 days, -0.001e18, 40 days, -0.002e18);
        curve.marketRateMultipliers[0] = 1e18;
        curve.marketRateMultipliers[1] = 1e18;

        assertEqApprox(
            YieldCurveLibrary.getRate(curve, marketBorrowRateFeed, block.timestamp + 30 days),
            uint256(linearRate - 0.0015e18),
            1e13
        );
    }

    function test_YieldCurve_getRate_with_negative_rate_double_multiplier() public {
        marketBorrowRateFeed.setMarketBorrowRate(0.07e18);
        uint256 linearRate = Math.compoundRateToLinearRate(0.07e18, 30 days);
        YieldCurve memory curve = YieldCurveHelper.customCurve(20 days, -0.001e18, 40 days, -0.002e18);
        curve.marketRateMultipliers[0] = 2e18;
        curve.marketRateMultipliers[1] = 2e18;

        assertEqApprox(
            YieldCurveLibrary.getRate(curve, marketBorrowRateFeed, block.timestamp + 30 days),
            uint256(2 * linearRate - 0.0015e18),
            1e13
        );
    }

    function test_YieldCurve_getRate_null_multiplier_does_not_fetch_oracle() public {
        YieldCurve memory curve = YieldCurveHelper.customCurve(30 days, 0.01e18, 60 days, 0.02e18);
        assertEq(
            YieldCurveLibrary.getRate(curve, IMarketBorrowRateFeed(address(0)), block.timestamp + 45 days), 0.015e18
        );
    }
}
