// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/AIAttestationRegistry.sol";
import "../src/RealEstateToken.sol";

contract RealEstateTokenInvariantTest is Test {
    RealEstateToken token;

    function setUp() public {
        AIAttestationRegistry registry = new AIAttestationRegistry();
        bytes32 assetId = keccak256("invariant-asset");
        bytes32 decisionHash = keccak256("invariant-decision");
        registry.attest(assetId, decisionHash, "model-v1", "A", 1);
        token = new RealEstateToken(
            "Invariant", "INV", assetId, keccak256("title"),
            decisionHash, 1, address(registry)
        );
    }

    function invariant_totalSupplyCannotExceedRegisteredSurface() public view {
        assertLe(token.totalSupply(), token.registeredSurfaceSqFt() * 1e18);
    }
}
