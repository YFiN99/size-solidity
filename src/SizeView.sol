// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {SizeStorage} from "./SizeStorage.sol";
import "./libraries/UserLibrary.sol";
import "./libraries/LoanLibrary.sol";
import "./libraries/OfferLibrary.sol";
import "./libraries/EnumerableMapExtensionsLibrary.sol";

abstract contract SizeView is SizeStorage {
    using UserLibrary for User;
    using OfferLibrary for LoanOffer;
    using LoanLibrary for Loan;
    using EnumerableMapExtensionsLibrary for EnumerableMap.UintToUintMap;

    function getCollateralRatio(address user) public view returns (uint256) {
        return users[user].collateralRatio(priceFeed.getPrice());
    }

    function isLiquidatable(address user) public view returns (bool) {
        return users[user].isLiquidatable(priceFeed.getPrice(), CRLiquidation);
    }

    function isLiquidatable(uint256 loanId) public view returns (bool) {
        Loan memory loan = loans[loanId];
        return users[loan.borrower].isLiquidatable(priceFeed.getPrice(), CRLiquidation);
    }

    function getAssignedCollateral(uint256 loanId) public view returns (uint256) {
        Loan memory loan = loans[loanId];
        User memory borrower = users[loan.borrower];
        if (borrower.totDebtCoveredByRealCollateral == 0) {
            return 0;
        } else {
            return borrower.eth.free * loan.FV / borrower.totDebtCoveredByRealCollateral;
        }
    }

    function getUserCollateral(address user) public view returns (uint256, uint256, uint256, uint256) {
        User memory u = users[user];
        return (u.cash.free, u.cash.locked, u.eth.free, u.eth.locked);
    }

    function activeLoans() public view returns (uint256) {
        return loans.length - 1;
    }

    function isFOL(uint256 loanId) public view returns (bool) {
        return loans[loanId].isFOL();
    }

    function getRate(uint256 offerId, uint256 dueDate) public view returns (uint256) {
        return loanOffers[offerId].getRate(dueDate);
    }

    function getDueDate(uint256 loanId) public view returns (uint256) {
        return loans[loanId].getDueDate(loans);
    }
}
