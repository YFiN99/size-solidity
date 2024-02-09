// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

/// @title IMarketBorrowRateFeed
interface IMarketBorrowRateFeed {
    /// @notice Returns the market borrow rate
    function getMarketBorrowRate() external view returns (uint256);
}
