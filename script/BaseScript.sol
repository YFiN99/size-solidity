//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {Vm} from "forge-std/Vm.sol";

struct Deployment {
    string name;
    address addr;
}

abstract contract BaseScript is Script {
    error InvalidChainId(uint256 chainid);
    error InvalidPrivateKey(string privateKey);

    string root;
    string path;
    Deployment[] public deployments;

    string chainName = "sepolia";

    modifier broadcast() {
        vm.startBroadcast();
        _;
        vm.stopBroadcast();
    }

    function setupLocalhostEnv(uint32 index) internal returns (uint256 localhostPrivateKey) {
        if (block.chainid == 31337) {
            root = vm.projectRoot();
            path = string.concat(root, "/localhost.json");
            string memory mnemonic = "test test test test test test test test test test test junk";
            return vm.deriveKey(mnemonic, index);
        } else {
            return vm.envUint("DEPLOYER_PRIVATE_KEY");
        }
    }

    function exportDeployments() internal {
        // fetch already existing contracts
        root = vm.projectRoot();
        path = string.concat(root, "/deployments/");
        string memory chainIdStr = vm.toString(block.chainid);
        path = string.concat(path, string.concat(chainIdStr, ".json"));

        string memory finalObject;
        string memory deploymentsObject;
        for (uint256 i = 0; i < deployments.length; i++) {
            deploymentsObject = vm.serializeAddress(".deployments", deployments[i].name, deployments[i].addr);
        }
        finalObject = vm.serializeString(".", "deployments", deploymentsObject);

        string memory networkName = getNetworkName();
        finalObject = vm.serializeString(".", "networkName", networkName);

        string memory commit = getCommitHash();
        finalObject = vm.serializeString(".", "commit", commit);

        vm.writeJson(finalObject, path);
    }

    function getChain() public returns (Chain memory) {
        return getChain(block.chainid);
    }

    function getNetworkName() public returns (string memory) {
        try this.getChain() returns (Chain memory chain) {
            return chain.name;
        } catch {
            return findChainName();
        }
    }

    function getCommitHash() public returns (string memory) {
        string[] memory inputs = new string[](4);

        inputs[0] = "git";
        inputs[1] = "rev-parse";
        inputs[2] = "--short";
        inputs[3] = "HEAD";

        bytes memory res = vm.ffi(inputs);
        return string(res);
    }

    function findChainName() public returns (string memory) {
        uint256 thisChainId = block.chainid;
        string[2][] memory allRpcUrls = vm.rpcUrls();
        for (uint256 i = 0; i < allRpcUrls.length; i++) {
            try vm.createSelectFork(allRpcUrls[i][1]) {
                if (block.chainid == thisChainId) {
                    return allRpcUrls[i][0];
                }
            } catch {
                continue;
            }
        }
        revert InvalidChainId(thisChainId);
    }
}
