// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/GreenLedgerFactory.sol";
import "../src/AIAttestationRegistry.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        console.log("Deployer:", deployer);
        console.log("Chain ID:", block.chainid);
        vm.startBroadcast(deployerPrivateKey);
        AIAttestationRegistry attestation = new AIAttestationRegistry();
        console.log("AIAttestationRegistry deployed at:", address(attestation));
        GreenLedgerFactory factory = new GreenLedgerFactory(address(attestation));
        console.log("GreenLedgerFactory deployed at:", address(factory));
        vm.stopBroadcast();
        console.log("ATTESTATION_ADDRESS=", vm.toString(address(attestation)));
        console.log("FACTORY_ADDRESS=", vm.toString(address(factory)));
    }
}
