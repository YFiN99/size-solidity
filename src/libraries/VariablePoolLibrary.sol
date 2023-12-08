// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Loan} from "@src/libraries/LoanLibrary.sol";

struct VariablePool {
    uint256 reserveBorrowAsset;
    uint256 reserveCollateralAsset;
    Loan[] activeLoans;
}
