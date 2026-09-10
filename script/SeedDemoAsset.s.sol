// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/AIAttestationRegistry.sol";
import "../src/GreenLedgerFactory.sol";
import "../src/RealEstateToken.sol";

contract SeedDemoAssetScript is Script {
    bytes32 constant ASSET_ID = keccak256("GL-BUE-001");
    bytes32 constant TITLE_HASH = keccak256("Manhattan Commercial Tower Title Deed");
    string constant MODEL_VERSION = "QAIzero-RWA-v1.0";
    string constant RISK_GRADE = "A";
    uint256 constant VALUATION_USD = 48_500_000 * 1e18;
    uint256 constant SURFACE_SQFT = 50_000;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        address attestationAddress = vm.envAddress("ATTESTATION_ADDRESS");
        address factoryAddress = vm.envAddress("FACTORY_ADDRESS");
        AIAttestationRegistry attestation = AIAttestationRegistry(attestationAddress);
        GreenLedgerFactory factory = GreenLedgerFactory(factoryAddress);

        vm.startBroadcast(deployerPrivateKey);
        bytes32 decisionHash = keccak256(abi.encodePacked(ASSET_ID, MODEL_VERSION, RISK_GRADE, VALUATION_USD, block.timestamp));
        bytes32 attestationId = attestation.attest(ASSET_ID, decisionHash, MODEL_VERSION, RISK_GRADE, VALUATION_USD);
        address tokenAddress = factory.deployAssetToken("GreenLedger Buenos Aires", "GL-SF", ASSET_ID, TITLE_HASH, decisionHash, SURFACE_SQFT, attestationAddress);
        RealEstateToken token = RealEstateToken(tokenAddress);
        token.executeTokenization(deployer);
        vm.stopBroadcast();

        console.log("Attestation ID:", vm.toString(attestationId));
        console.log("Token Contract deployed at:", tokenAddress);
        console.log("Total Supply:", token.totalSupply());
        console.log("Registered Surface:", token.registeredSurfaceSqFt());
        console.log("Invariant Verified:", token.totalSupply() == SURFACE_SQFT * 1e18);
        console.log("DEMO_ASSET_ID=GL-BUE-001");
        console.log("DEMO_DECISION_HASH=", vm.toString(decisionHash));
        console.log("DEMO_TOKEN_ADDRESS=", tokenAddress);
        console.log("DEMO_BLOCK_NUMBER=", block.number);
    }
}
