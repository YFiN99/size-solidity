// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Logger} from "@script/Logger.sol";
import {Size} from "@src/core/Size.sol";
import {LiquidateParams} from "@src/core/libraries/fixed/actions/Liquidate.sol";
import {Script} from "forge-std/Script.sol";
import {console2 as console} from "forge-std/console2.sol";

contract LiquidateScript is Script, Logger {
    function run() external {
        console.log("Liquidating...");

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address sizeContractAddress = vm.envAddress("SIZE_CONTRACT_ADDRESS");

        Size size = Size(payable(sizeContractAddress));

        LiquidateParams memory params = LiquidateParams({debtPositionId: 0, minimumCollateralProfit: 0});

        vm.startBroadcast(deployerPrivateKey);
        size.liquidate(params);
        vm.stopBroadcast();
    }
}
