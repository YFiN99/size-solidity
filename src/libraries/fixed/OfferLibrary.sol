// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Errors} from "@src/libraries/Errors.sol";
import {Math} from "@src/libraries/Math.sol";
import {YieldCurve, YieldCurveLibrary} from "@src/libraries/fixed/YieldCurveLibrary.sol";
import {IVariablePoolBorrowRateFeed} from "@src/oracle/IVariablePoolBorrowRateFeed.sol";

struct LoanOffer {
    uint256 maxDueDate;
    YieldCurve curveRelativeTime;
}

struct BorrowOffer {
    YieldCurve curveRelativeTime;
}

/// @title OfferLibrary
library OfferLibrary {
    using YieldCurveLibrary for YieldCurve;

    function isNull(LoanOffer memory self) internal pure returns (bool) {
        return self.maxDueDate == 0 && self.curveRelativeTime.isNull();
    }

    function isNull(BorrowOffer memory self) internal pure returns (bool) {
        return self.curveRelativeTime.isNull();
    }

    function getAPRByDueDate(
        LoanOffer memory self,
        IVariablePoolBorrowRateFeed variablePoolBorrowRateFeed,
        uint256 dueDate
    ) internal view returns (uint256) {
        if (dueDate < block.timestamp) revert Errors.PAST_DUE_DATE(dueDate);
        uint256 tenor = dueDate - block.timestamp;
        return YieldCurveLibrary.getAPR(self.curveRelativeTime, variablePoolBorrowRateFeed, tenor);
    }

    function getRatePerTenorByDueDate(
        LoanOffer memory self,
        IVariablePoolBorrowRateFeed variablePoolBorrowRateFeed,
        uint256 dueDate
    ) internal view returns (uint256) {
        if (dueDate < block.timestamp) revert Errors.PAST_DUE_DATE(dueDate);
        uint256 tenor = dueDate - block.timestamp;
        uint256 apr = YieldCurveLibrary.getAPR(self.curveRelativeTime, variablePoolBorrowRateFeed, tenor);
        return Math.aprToRatePerTenor(apr, tenor);
    }

    function getAPRByDueDate(
        BorrowOffer memory self,
        IVariablePoolBorrowRateFeed variablePoolBorrowRateFeed,
        uint256 dueDate
    ) internal view returns (uint256) {
        if (dueDate < block.timestamp) revert Errors.PAST_DUE_DATE(dueDate);
        uint256 tenor = dueDate - block.timestamp;
        return YieldCurveLibrary.getAPR(self.curveRelativeTime, variablePoolBorrowRateFeed, tenor);
    }

    function getRatePerTenorByDueDate(
        BorrowOffer memory self,
        IVariablePoolBorrowRateFeed variablePoolBorrowRateFeed,
        uint256 dueDate
    ) internal view returns (uint256) {
        if (dueDate < block.timestamp) revert Errors.PAST_DUE_DATE(dueDate);
        uint256 tenor = dueDate - block.timestamp;
        uint256 apr = YieldCurveLibrary.getAPR(self.curveRelativeTime, variablePoolBorrowRateFeed, tenor);
        return Math.aprToRatePerTenor(apr, tenor);
    }
}
