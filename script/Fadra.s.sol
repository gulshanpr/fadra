// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {Fadra} from "../src/Fadra.sol";
contract MyScript is Script {
     function run() external {
        // Start broadcasting transactions
        vm.startBroadcast();

        // Constructor arguments
        string memory name = "Fadra";
        string memory symbol = "FDR";
        address lpWallet = 0xAEDb4Aa3aa52953864b3e0813087E332F1Dcee3B;
        address marketingWallet = 0xAEDb4Aa3aa52953864b3e0813087E332F1Dcee3B;

        // Deploy the contract
        Fadra fadra = new Fadra(name, symbol, lpWallet, marketingWallet);

        // Log the deployed contract address
        console.log("Fadra deployed to:", address(fadra));

        // Stop broadcasting
        vm.stopBroadcast();
    }
}
