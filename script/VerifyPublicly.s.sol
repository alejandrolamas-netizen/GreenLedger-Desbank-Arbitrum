// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/AIAttestationRegistry.sol";
import "../src/RealEstateToken.sol";

contract VerifyPubliclyScript is Script {
    function run() external view {
        address attestationAddress = vm.envAddress("ATTESTATION_ADDRESS");
        address tokenAddress = vm.envAddress("DEMO_TOKEN_ADDRESS");
        AIAttestationRegistry registry = AIAttestationRegistry(attestationAddress);
        RealEstateToken token = RealEstateToken(tokenAddress);
        (bool exists, bytes32 storedDecisionHash) = registry.getAttestation(token.assetId());
        (bool valid,) = registry.isAttested(token.assetId(), token.decisionHash());
        uint256 expectedSupply = token.registeredSurfaceSqFt() * 1e18;
        console.log("Arbitrum chain ID:", block.chainid);
        console.log("Attestation exists:", exists);
        console.log("Decision hash matches token:", storedDecisionHash == token.decisionHash());
        console.log("Attestation valid:", valid);
        console.log("Total supply:", token.totalSupply());
        console.log("Expected supply:", expectedSupply);
        console.log("Surface invariant:", token.totalSupply() == expectedSupply);
        console.log("VERDICT:", exists && valid && storedDecisionHash == token.decisionHash() && token.totalSupply() == expectedSupply ? "PASS" : "FAIL");
    }
}
