// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "forge-std/StdInvariant.sol";
import "../src/AIAttestationRegistry.sol";
import "../src/GreenLedgerFactory.sol";
import "../src/RealEstateToken.sol";

contract GreenLedgerFuzzTest is Test {
    function testFuzzTokenizationMintsExactlyRegisteredSurface(
        uint256 surfaceSqFt,
        address recipient
    ) public {
        surfaceSqFt = bound(surfaceSqFt, 1, type(uint256).max / 1e18);
        vm.assume(recipient != address(0));

        AIAttestationRegistry registry = new AIAttestationRegistry();
        bytes32 assetId = keccak256("GL-FUZZ-ASSET");
        bytes32 decisionHash = keccak256("GL-FUZZ-DECISION");
        registry.attest(assetId, decisionHash, "QAIzero-RWA-v1", "A", 1);

        RealEstateToken token = new RealEstateToken(
            "GreenLedger Fuzz", "GLF", assetId, keccak256("title"),
            decisionHash, surfaceSqFt, address(registry)
        );

        token.executeTokenization(recipient);

        uint256 expectedSupply = surfaceSqFt * 1e18;
        assertEq(token.totalSupply(), expectedSupply);
        assertEq(token.balanceOf(recipient), expectedSupply);
        assertTrue(token.isTokenized());
    }

    function testFuzzUnauthorizedAttesterCannotWrite(address caller) public {
        vm.assume(caller != address(this));
        AIAttestationRegistry registry = new AIAttestationRegistry();

        vm.expectRevert(AIAttestationRegistry.UnauthorizedAttester.selector);
        vm.prank(caller);
        registry.attest(bytes32(uint256(1)), bytes32(uint256(2)), "model", "A", 1);
    }

    function testFuzzTokenizationRejectsNonMatchingDecision(bytes32 wrongDecisionHash) public {
        bytes32 assetId = keccak256("GL-MISMATCH-ASSET");
        bytes32 validDecisionHash = keccak256("GL-VALID-DECISION");
        vm.assume(wrongDecisionHash != validDecisionHash && wrongDecisionHash != bytes32(0));

        AIAttestationRegistry registry = new AIAttestationRegistry();
        registry.attest(assetId, validDecisionHash, "QAIzero-RWA-v1", "A", 1);

        RealEstateToken token = new RealEstateToken(
            "GreenLedger Mismatch", "GLM", assetId, keccak256("title"),
            wrongDecisionHash, 100, address(registry)
        );

        vm.expectRevert(RealEstateToken.AttestationNotFound.selector);
        token.executeTokenization(address(this));
    }

    function testFactoryRejectsDifferentRegistry() public {
        AIAttestationRegistry registry = new AIAttestationRegistry();
        GreenLedgerFactory factory = new GreenLedgerFactory(address(registry));

        vm.expectRevert(GreenLedgerFactory.InvalidRegistry.selector);
        factory.deployAssetToken(
            "Invalid", "INV", keccak256("asset"), keccak256("title"),
            keccak256("decision"), 10, address(0xBEEF)
        );
    }

    function testFactoryRejectsDuplicateAssetId() public {
        AIAttestationRegistry registry = new AIAttestationRegistry();
        GreenLedgerFactory factory = new GreenLedgerFactory(address(registry));
        bytes32 assetId = keccak256("unique-asset");
        bytes32 decisionHash = keccak256("unique-decision");
        registry.attest(assetId, decisionHash, "model-v1", "A", 1);

        factory.deployAssetToken("First", "ONE", assetId, keccak256("title"), decisionHash, 1, address(registry));
        vm.expectRevert(abi.encodeWithSelector(GreenLedgerFactory.AssetAlreadyDeployed.selector, assetId, factory.assetTokenById(assetId)));
        factory.deployAssetToken("Second", "TWO", assetId, keccak256("title-2"), decisionHash, 1, address(registry));
    }
}

contract GreenLedgerInvariantHandler {
    RealEstateToken public immutable token;

    constructor(RealEstateToken token_) {
        token = token_;
    }

    function tokenize() external {
        if (!token.isTokenized()) token.executeTokenization(address(this));
    }

    function transfer(uint96 rawAmount, address recipient) external {
        if (!token.isTokenized()) return;
        if (recipient == address(0)) recipient = address(0xBEEF);
        uint256 balance = token.balanceOf(address(this));
        if (balance == 0) return;
        uint256 amount = uint256(rawAmount) % (balance + 1);
        token.transfer(recipient, amount);
    }
}

contract GreenLedgerInvariantTest is StdInvariant, Test {
    RealEstateToken internal token;
    GreenLedgerInvariantHandler internal handler;
    uint256 internal constant SURFACE_SQ_FT = 50_000;
    uint256 internal constant EXPECTED_SUPPLY = SURFACE_SQ_FT * 1e18;

    function setUp() public {
        AIAttestationRegistry registry = new AIAttestationRegistry();
        bytes32 assetId = keccak256("GL-INVARIANT-ASSET");
        bytes32 decisionHash = keccak256("GL-INVARIANT-DECISION");
        registry.attest(assetId, decisionHash, "QAIzero-RWA-v1", "A", 1);

        token = new RealEstateToken(
            "GreenLedger Invariant", "GLI", assetId, keccak256("title"),
            decisionHash, SURFACE_SQ_FT, address(registry)
        );

        handler = new GreenLedgerInvariantHandler(token);
        token.transferOwnership(address(handler));
        targetContract(address(handler));
    }

    function invariantSupplyNeverExceedsRegisteredSurface() public view {
        assertLe(token.totalSupply(), EXPECTED_SUPPLY);
    }

    function invariantTokenizedSupplyEqualsRegisteredSurface() public view {
        if (token.isTokenized()) assertEq(token.totalSupply(), EXPECTED_SUPPLY);
        else assertEq(token.totalSupply(), 0);
    }
}
