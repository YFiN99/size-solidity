// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {Math} from "@src/libraries/Math.sol";

import {IPriceFeed} from "./IPriceFeed.sol";
import {Errors} from "@src/libraries/Errors.sol";

/// @title PriceFeed
/// @notice A contract that provides the price of a `base` asset in terms of a `quote` asset, using an intermediate asset, scaled to 18 decimals
/// @dev The price is calculated as `base / quote`. Example configuration:
///      _base: ETH/USD feed
///      _quote: USDC/USD feed
///      _baseStalePriceInterval: 3600 seconds (https://data.chain.link/ethereum/mainnet/crypto-usd/eth-usd)
///      _quoteStalePriceInterval: 86400 seconds (https://data.chain.link/ethereum/mainnet/stablecoins/usdc-usd)
///      answer: ETH/USDC in 1e18
///      Note: _base and _quote must have the same number of decimals
///      Note: _base and _quote must have the same intermediate asset (in this example, USD)
contract PriceFeed is IPriceFeed {
    /* solhint-disable */
    uint256 public constant decimals = 18;
    AggregatorV3Interface public immutable base;
    AggregatorV3Interface public immutable quote;
    uint256 public immutable baseStalePriceInterval;
    uint256 public immutable quoteStalePriceInterval;
    /* solhint-enable */

    constructor(address _base, address _quote, uint256 _baseStalePriceInterval, uint256 _quoteStalePriceInterval) {
        if (_base == address(0) || _quote == address(0)) {
            revert Errors.NULL_ADDRESS();
        }

        if (_baseStalePriceInterval == 0 || _quoteStalePriceInterval == 0) {
            revert Errors.NULL_STALE_PRICE();
        }

        base = AggregatorV3Interface(_base);
        quote = AggregatorV3Interface(_quote);
        baseStalePriceInterval = _baseStalePriceInterval;
        quoteStalePriceInterval = _quoteStalePriceInterval;

        if (base.decimals() != quote.decimals()) {
            revert Errors.INVALID_DECIMALS(quote.decimals());
        }
    }

    function getPrice() external view returns (uint256) {
        return Math.mulDivDown(
            _getPrice(base, baseStalePriceInterval), 10 ** decimals, _getPrice(quote, quoteStalePriceInterval)
        );
    }

    function _getPrice(AggregatorV3Interface aggregator, uint256 stalePriceInterval) internal view returns (uint256) {
        // slither-disable-next-line unused-return
        (, int256 price,, uint256 updatedAt,) = aggregator.latestRoundData();

        if (price <= 0) revert Errors.INVALID_PRICE(address(aggregator), price);
        if (block.timestamp - updatedAt > stalePriceInterval) {
            revert Errors.STALE_PRICE(address(aggregator), updatedAt);
        }

        return SafeCast.toUint256(price);
    }
}
