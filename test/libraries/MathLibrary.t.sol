// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Math} from "@src/libraries/MathLibrary.sol";
import {Test} from "forge-std/Test.sol";

contract MathTest is Test {
    function test_Math_amountToWad_18_decimals() public {
        uint256 amount = 1e18;
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

    // @audit TODO test Math_wadToAmount
    function test_Math_wadToAmount_18_decimals() public {
        uint256 amount = 1e18;
        uint8 decimals = 18;

        uint256 wad = Math.wadToAmount(amount, decimals);
        assertEq(wad, amount);
    }

    function testFuzz_Math_wadToAmount_18_decimals(uint256 amount) public {
        uint8 decimals = 18;

        uint256 wad = Math.wadToAmount(amount, decimals);
        assertEq(wad, amount);
    }

    function test_Math_wadToAmount_lt_18() public {
        uint256 amount = 1e18;
        uint8 decimals = 6;

        uint256 wad = Math.wadToAmount(amount, decimals);
        assertEq(wad, 1e6);
    }

    function testFuzz_Math_wadToAmount_lt_18(uint256 amount) public {
        uint8 decimals = 6;

        uint256 wad = Math.wadToAmount(amount, decimals);
        assertEq(wad, amount / 1e12);
    }

    function test_Math_wadToAmount_gt_18() public {
        uint256 amount = 1e24;
        uint8 decimals = 24;

        vm.expectRevert();
        Math.wadToAmount(amount, decimals);
    }

    function testFuzz_Math_wadToAmount_gt_18(uint256 amount) public {
        uint8 decimals = 24;

        vm.expectRevert();
        Math.wadToAmount(amount, decimals);
    }

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
}
