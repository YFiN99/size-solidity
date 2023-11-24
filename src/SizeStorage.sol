// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IPriceFeed} from "./oracle/IPriceFeed.sol";
import {Loan} from "./libraries/LoanLibrary.sol";
import {LoanOffer, BorrowOffer} from "@src/libraries/OfferLibrary.sol";
import {User} from "@src/libraries/UserLibrary.sol";

abstract contract SizeStorage {
    mapping(address => User) public users;
    Loan[] public loans;
    IPriceFeed public priceFeed;
    uint256 public maxTime;
    uint256 public CROpening;
    uint256 public CRLiquidation;
    uint256 public collateralPercentagePremiumToLiquidator;
    uint256 public collateralPercentagePremiumToBorrower;
}
