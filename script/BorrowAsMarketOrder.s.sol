// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../src/Size.sol";
import "../src/libraries/fixed/YieldCurveLibrary.sol";

import "./TimestampHelper.sol";
import "forge-std/Script.sol";

contract BorrowMarketOrder is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address sizeContractAddress = vm.envAddress("SIZE_CONTRACT_ADDRESS");

        address LenderTest = 0xD20baecCd9F77fAA9E2C2B185F33483D7911f9C8;
        address BorrowerTest = 0x979Af411D048b453E3334C95F392012B3BbD6215;

        console.log("LenderTest", LenderTest);
        console.log("BorrowerTest", BorrowerTest);

        TimestampHelper helper = new TimestampHelper();
        uint256 currentTimestamp = helper.getCurrentTimestamp();
        uint256 dueDate = currentTimestamp + 60 * 60 * 24 * 4; // 4 days from now

        Size sizeContract = Size(sizeContractAddress);

        BorrowAsMarketOrderParams memory params = BorrowAsMarketOrderParams({
            lender: BorrowerTest,
            amount: 5e6,
            dueDate: dueDate,
            exactAmountIn: false,
            receivableLoanIds: new uint256[](0)
        });
        console.log("borrower USDC", sizeContract.getUserView(BorrowerTest).borrowAmount);
        vm.startBroadcast(deployerPrivateKey);
        sizeContract.borrowAsMarketOrder(params);
        vm.stopBroadcast();
    }
}
