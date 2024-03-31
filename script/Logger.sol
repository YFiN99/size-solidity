// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {SizeView, UserView} from "@src/SizeView.sol";
import {CreditPosition, DebtPosition, LoanLibrary} from "@src/libraries/fixed/LoanLibrary.sol";
import {BorrowOffer, LoanOffer, OfferLibrary} from "@src/libraries/fixed/OfferLibrary.sol";
import {console2 as console} from "forge-std/console2.sol";

abstract contract Logger {
    using LoanLibrary for DebtPosition;
    using OfferLibrary for LoanOffer;
    using OfferLibrary for BorrowOffer;

    function log(UserView memory userView) internal pure {
        console.log("account", userView.account);
        if (!userView.user.loanOffer.isNull()) {
            console.log("user.loanOffer.maxDueDate", userView.user.loanOffer.maxDueDate);
            for (uint256 i = 0; i < userView.user.loanOffer.curveRelativeTime.aprs.length; i++) {
                console.log(
                    "user.loanOffer.curveRelativeTime.maturities[]",
                    userView.user.loanOffer.curveRelativeTime.maturities[i]
                );
                console.log(
                    "user.loanOffer.curveRelativeTime.aprs[]", userView.user.loanOffer.curveRelativeTime.aprs[i]
                );
                console.log(
                    "user.loanOffer.curveRelativeTime.marketRateMultipliers[]",
                    userView.user.loanOffer.curveRelativeTime.marketRateMultipliers[i]
                );
            }
        }
        if (!userView.user.borrowOffer.isNull()) {
            console.log("user.borrowOffer.openingLimitBorrowCR", userView.user.borrowOffer.openingLimitBorrowCR);
            for (uint256 i = 0; i < userView.user.borrowOffer.curveRelativeTime.aprs.length; i++) {
                console.log(
                    "user.borrowOffer.curveRelativeTime.maturities[]",
                    userView.user.borrowOffer.curveRelativeTime.maturities[i]
                );
                console.log(
                    "user.borrowOffer.curveRelativeTime.aprs[]", userView.user.borrowOffer.curveRelativeTime.aprs[i]
                );
                console.log(
                    "user.borrowOffer.curveRelativeTime.marketRateMultipliers[]",
                    userView.user.borrowOffer.curveRelativeTime.marketRateMultipliers[i]
                );
            }
        }
        console.log("collateralBalance", userView.collateralTokenBalance);
        console.log("borrowATokenBalance", userView.borrowATokenBalance);
        console.log("debtBalance", userView.debtBalance);
    }

    function log(DebtPosition memory debtPosition) internal pure {
        console.log("lender", debtPosition.lender);
        console.log("borrower", debtPosition.borrower);
        console.log("issuanceValue", debtPosition.issuanceValue);
        console.log("faceValue", debtPosition.faceValue);
        console.log("repayFee", debtPosition.repayFee);
        console.log("overdueLiquidatorReward", debtPosition.overdueLiquidatorReward);
        console.log("startDate", debtPosition.startDate);
        console.log("dueDate", debtPosition.dueDate);
        console.log("liquidityIndexAtRepayment", debtPosition.liquidityIndexAtRepayment);
    }
}
