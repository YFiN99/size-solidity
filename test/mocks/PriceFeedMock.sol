// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "../../src/oracle/IPriceFeed.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PriceFeedMock is IPriceFeed, Ownable {
    uint256 public price;
    uint8 public decimals = 18;

    event PriceUpdated(uint256 oldPrice, uint256 newPrice);

    constructor(address owner_) Ownable(owner_) {}

    function setPrice(uint256 newPrice) public onlyOwner {
        uint256 oldPrice = price;
        price = newPrice;
        emit PriceUpdated(oldPrice, newPrice);
    }

    function getPrice() public view returns (uint256) {
        return price;
    }
}
