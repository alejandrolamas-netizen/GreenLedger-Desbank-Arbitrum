// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/AIAttestationRegistry.sol";
import "../src/GreenLedgerFactory.sol";
import "../src/RealEstateToken.sol";

contract RealEstateTokenTest is Test {
    AIAttestationRegistry registry;
    GreenLedgerFactory factory;
    RealEstateToken token;
    address deployer = address(this);

    bytes32 assetId = keccak256("GL-BUE-001");
    bytes32 decisionHash = keccak256("decision-001");

    function setUp() public {
        registry = new AIAttestationRegistry();
        factory = new GreenLedgerFactory(address(registry));
        registry.attest(assetId, decisionHash, "QAIzero-RWA-v1.0", "A", 48_500_000 * 1e18);
        address tokenAddress = factory.deployAssetToken("GreenLedger Buenos Aires", "GL-SF", assetId, keccak256("title"), decisionHash, 50_000, address(registry));
        token = RealEstateToken(tokenAddress);
    }

    function testCannotTokenizeWithoutMatchingAttestation() public {
        AIAttestationRegistry other = new AIAttestationRegistry();
        RealEstateToken unverified = new RealEstateToken("Unverified", "UNV", assetId, bytes32(0), keccak256("wrong"), 50_000, address(other));
        vm.expectRevert(RealEstateToken.AttestationNotFound.selector);
        unverified.executeTokenization(address(this));
    }

    function testTokenizationMatchesSurfaceInvariant() public {
        token.executeTokenization(deployer);
        assertEq(token.totalSupply(), 50_000 * 1e18);
        assertEq(token.balanceOf(deployer), 50_000 * 1e18);
        assertTrue(token.isTokenized());
    }

    function testCannotTokenizeTwice() public {
        token.executeTokenization(deployer);
        vm.expectRevert(RealEstateToken.AlreadyTokenized.selector);
        token.executeTokenization(deployer);
    }
}
