// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {Math} from "@src/libraries/Math.sol";

import {AssertsHelper} from "@test/helpers/AssertsHelper.sol";
import {Test} from "forge-std/Test.sol";

contract MathTest is Test, AssertsHelper {
    function test_Math_min() public {
        assertEq(Math.min(4, 5, 6), 4);
        assertEq(Math.min(4, 6, 5), 4);
        assertEq(Math.min(5, 4, 6), 4);
        assertEq(Math.min(5, 6, 4), 4);
        assertEq(Math.min(6, 4, 5), 4);
        assertEq(Math.min(6, 5, 4), 4);
    }

    function test_Math_mulDivUp() public {
        assertEq(Math.mulDivUp(3, 5, 4), 4);
        assertEq(Math.mulDivUp(4, 5, 4), 5);
    }

    function test_Math_mulDivDown() public {
        assertEq(Math.mulDivDown(3, 5, 4), 3);
        assertEq(Math.mulDivDown(4, 5, 4), 5);
    }

    function test_Math_binarySearch_two() public {
        uint256[] memory array = new uint256[](2);
        array[0] = 86400;
        array[1] = 259200;
        uint256 needle = 172800;
        uint256 low;
        uint256 high;
        (low, high) = Math.binarySearch(array, needle);
        assertEq(low, 0);
        assertEq(high, 1);
    }

    function test_Math_binarySearch_found() public {
        uint256[] memory array = new uint256[](5);
        array[0] = 10;
        array[1] = 20;
        array[2] = 30;
        array[3] = 40;
        array[4] = 50;
        uint256 low;
        uint256 high;
        for (uint256 i = 0; i < array.length; i++) {
            (low, high) = Math.binarySearch(array, array[i]);
            assertEq(low, i);
            assertEq(high, i);
        }
    }

    function test_Math_binarySearch_not_found() public {
        uint256[] memory array = new uint256[](5);
        array[0] = 10;
        array[1] = 20;
        array[2] = 30;
        array[3] = 40;
        array[4] = 50;
        uint256 low;
        uint256 high;
        (low, high) = Math.binarySearch(array, 0);
        assertEq(low, type(uint256).max);
        assertEq(high, type(uint256).max);
        (low, high) = Math.binarySearch(array, 13);
        assertEq(low, 0);
        assertEq(high, 1);
        (low, high) = Math.binarySearch(array, 17);
        assertEq(low, 0);
        assertEq(high, 1);
        (low, high) = Math.binarySearch(array, 21);
        assertEq(low, 1);
        assertEq(high, 2);
        (low, high) = Math.binarySearch(array, 29);
        assertEq(low, 1);
        assertEq(high, 2);
        (low, high) = Math.binarySearch(array, 32);
        assertEq(low, 2);
        assertEq(high, 3);
        (low, high) = Math.binarySearch(array, 37);
        assertEq(low, 2);
        assertEq(high, 3);
        (low, high) = Math.binarySearch(array, 42);
        assertEq(low, 3);
        assertEq(high, 4);
        (low, high) = Math.binarySearch(array, 45);
        assertEq(low, 3);
        assertEq(high, 4);
        (low, high) = Math.binarySearch(array, 51);
        assertEq(low, type(uint256).max);
        assertEq(high, type(uint256).max);
    }

    function test_Math_powWadWad() public {
        uint256 toleranceWAD = 20;
        assertEq(Math.powWadWad(2e18, 0), 1e18);
        assertEq(Math.powWadWad(3e18, 0), 1e18);
        assertEqApprox(Math.powWadWad(2e18, 3), 1e18, toleranceWAD);
        assertEqApprox(Math.powWadWad(3e18, 2), 1e18, toleranceWAD);
        assertEqApprox(Math.powWadWad(2e18, 3e18), 8e18, toleranceWAD);
        assertEqApprox(Math.powWadWad(3e18, 2e18), 9e18, toleranceWAD);
    }

    function test_Math_linearAPRToRatePerMaturity() public {
        uint256 toleranceWAD = 1;
        // 1% APY (linear interest) is 0.082% over the period of 30 days
        assertEqApprox(
            SafeCast.toUint256(Math.linearAPRToRatePerMaturity(0.01e18, 30 days)), 0.000821917808219178e18, toleranceWAD
        );
    }

    function test_Math_compoundAPRToRatePerMaturity() public {
        uint256 toleranceWAD = 1_000;
        // 7% APY (compound interest) is 0.5576% (linear interest) over the period of 30 days
        assertEqApprox(Math.compoundAPRToRatePerMaturity(0.07e18, 30 days), 0.0055764757837924e18, toleranceWAD);
    }

    function test_Math_amountToWad_18_decimals() public {
        uint256 amount = 1e6;
        uint8 decimals = 18;

        uint256 wad = Math.amountToWad(amount, decimals);
        assertEq(wad, amount);
    }

    function testFuzz_Math_amountToWad_18_decimals(uint256 amount) public {
        uint8 decimals = 18;

        uint256 wad = Math.amountToWad(amount, decimals);
        assertEq(wad, amount);
    }

    function test_Math_amountToWad_lt_18() public {
        uint256 amount = 1e6;
        uint8 decimals = 6;

        uint256 wad = Math.amountToWad(amount, decimals);
        assertEq(wad, 1e18);
    }

    function testFuzz_Math_amountToWad_lt_18(uint256 amount) public {
        amount = bound(amount, 0, type(uint256).max / 1e18);
        uint8 decimals = 6;

        uint256 wad = Math.amountToWad(amount, decimals);
        assertEq(wad, amount * 1e12);
    }

    function test_Math_amountToWad_gt_18() public {
        uint256 amount = 1e24;
        uint8 decimals = 24;

        vm.expectRevert();
        Math.amountToWad(amount, decimals);
    }

    function testFuzz_Math_amountToWad_gt_18(uint256 amount) public {
        uint8 decimals = 24;

        vm.expectRevert();
        Math.amountToWad(amount, decimals);
    }
}
