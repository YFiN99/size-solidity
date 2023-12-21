// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {LoanStatus} from "@src/libraries/LoanLibrary.sol";
import {UserView} from "@src/libraries/UserLibrary.sol";
import {Vars} from "@test/BaseTest.sol";
import {Test} from "forge-std/Test.sol";

abstract contract AssertsHelper is Test {
    function assertEq(Vars memory a, Vars memory b) internal {
        assertEq(a.alice, b.alice);
        assertEq(a.bob, b.bob);
        assertEq(a.candy, b.candy);
        assertEq(a.james, b.james);
        assertEq(a.liquidator, b.liquidator);
        assertEq(a.protocolCollateralAmount, b.protocolCollateralAmount, "protocolCollateralAmount");
        assertEq(a.protocolBorrowAmount, b.protocolBorrowAmount, "protocolBorrowAmount");
        assertEq(a.feeRecipientCollateralAmount, b.feeRecipientCollateralAmount, "feeRecipientCollateralAmount");
        assertEq(a.feeRecipientBorrowAmount, b.feeRecipientBorrowAmount, "feeRecipientBorrowAmount");
    }

    function assertEq(UserView memory a, UserView memory b) internal {
        assertEq(a.collateralAmount, b.collateralAmount, "collateralAmount");
        assertEq(a.borrowAmount, b.borrowAmount, "borrowAmount");
        assertEq(a.debtAmount, b.debtAmount, "debtAmount");
    }

    function assertEq(uint256 a, uint256 b, uint256 c) internal {
        string memory reason = string.concat(
            "Expected ", Strings.toString(a), " to be equal to ", Strings.toString(b), " and ", Strings.toString(c)
        );
        assertTrue(a == b && b == c, reason);
    }

    function assertEq(LoanStatus a, LoanStatus b) internal {
        string memory reason = string.concat("Expected ", str(a), " to be equal to ", str(b));
        return assertEq(a, b, reason);
    }

    function assertEq(LoanStatus a, LoanStatus b, string memory reason) internal {
        assertTrue(uint256(a) == uint256(b), reason);
    }

    function str(LoanStatus a) internal pure returns (string memory) {
        if (a == LoanStatus.CLAIMED) {
            return "CLAIMED";
        } else if (a == LoanStatus.REPAID) {
            return "REPAID";
        } else if (a == LoanStatus.OVERDUE) {
            return "OVERDUE";
        } else {
            return "ACTIVE";
        }
    }
}
