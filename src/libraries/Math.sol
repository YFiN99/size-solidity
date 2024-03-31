// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";

uint256 constant PERCENT = 1e18;

// @audit-info The protocol does not support tokens with more than 18 decimals
// @audit Check rounding direction of all `FixedPointMath.mulDiv{Up,Down}`

/// @title Math
library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return FixedPointMathLib.min(a, b);
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return FixedPointMathLib.max(a, b);
    }

    function min(uint256 a, uint256 b, uint256 c) internal pure returns (uint256) {
        return FixedPointMathLib.min(FixedPointMathLib.min(a, b), c);
    }

    function mulDivUp(uint256 x, uint256 y, uint256 z) internal pure returns (uint256) {
        return FixedPointMathLib.mulDivUp(x, y, z);
    }

    function mulDivDown(uint256 x, uint256 y, uint256 z) internal pure returns (uint256) {
        return FixedPointMathLib.mulDiv(x, y, z);
    }

    function amountToWad(uint256 amount, uint8 decimals) internal pure returns (uint256) {
        return amount * 10 ** (18 - decimals);
    }

    function ratePerMaturityToAPR(uint256 ratePerMaturity, uint256 maturity) internal pure returns (uint256) {
        return mulDivDown(ratePerMaturity, 365 days, maturity);
    }

    function aprToRatePerMaturity(uint256 apr, uint256 maturity) internal pure returns (uint256) {
        return mulDivDown(apr, maturity, 365 days);
    }

    function binarySearch(uint256[] memory array, uint256 value) internal pure returns (uint256 low, uint256 high) {
        low = 0;
        high = array.length - 1;
        if (value < array[low] || value > array[high]) {
            // @audit-info Covered in test_Math_binarySearch_not_found
            return (type(uint256).max, type(uint256).max);
        }
        while (low <= high) {
            uint256 mid = (low + high) / 2;
            if (array[mid] == value) {
                return (mid, mid);
            } else if (array[mid] < value) {
                low = mid + 1;
            } else {
                high = mid - 1;
            }
        }
        return (high, low);
    }
}
