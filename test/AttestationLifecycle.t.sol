// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/AIAttestationRegistry.sol";
import "../src/RealEstateToken.sol";

contract AttestationLifecycleTest is Test {
    AIAttestationRegistry internal registry;
    bytes32 internal constant ASSET = keccak256("GL-LIFECYCLE-ASSET");
    bytes32 internal constant DECISION_A = keccak256("GL-DECISION-A");
    bytes32 internal constant DECISION_B = keccak256("GL-DECISION-B");

    function setUp() public { registry = new AIAttestationRegistry(); }

    function _attest(bytes32 decisionHash) internal returns (bytes32) {
        return registry.attest(ASSET, decisionHash, "QAIzero-RWA-v1", "A", 100);
    }

    function testAttestationHistoryIsAppendOnlyAndCurrentPointerAdvances() public {
        bytes32 first = _attest(DECISION_A);
        bytes32 second = _attest(DECISION_B);
        assertEq(registry.getAttestationHistoryLength(ASSET), 2);
        assertEq(registry.getAttestationHistoryAt(ASSET, 0), first);
        assertEq(registry.getAttestationHistoryAt(ASSET, 1), second);
        assertEq(registry.currentAttestationId(ASSET), second);
        assertFalse(registry.isAttestationValid(first));
        assertTrue(registry.isAttestationValid(second));
    }

    function testRevokedAttestationCannotAuthorizeTokenization() public {
        bytes32 id = _attest(DECISION_A);
        registry.revokeAttestation(id, keccak256("evidence withdrawn"));
        RealEstateToken token = new RealEstateToken(
            "GreenLedger Lifecycle", "GLL", ASSET, keccak256("title"),
            DECISION_A, 100, address(registry)
        );
        vm.expectRevert(RealEstateToken.AttestationNotFound.selector);
        token.executeTokenization(address(this));
    }

    function testExpiredAttestationCannotAuthorizeTokenization() public {
        uint256 expiry = block.timestamp + 1 days;
        registry.attestWithExpiry(ASSET, DECISION_A, "QAIzero-RWA-v1", "A", 100, expiry);
        vm.warp(expiry);
        RealEstateToken token = new RealEstateToken(
            "GreenLedger Expiry", "GLE", ASSET, keccak256("title"),
            DECISION_A, 100, address(registry)
        );
        vm.expectRevert(RealEstateToken.AttestationNotFound.selector);
        token.executeTokenization(address(this));
    }

    function testOnlyOwnerOrOriginalAttestorCanRevoke() public {
        bytes32 id = _attest(DECISION_A);
        vm.expectRevert(AIAttestationRegistry.UnauthorizedAttester.selector);
        vm.prank(address(0xBEEF));
        registry.revokeAttestation(id, keccak256("unauthorized"));
        registry.revokeAttestation(id, keccak256("owner approved"));
        assertFalse(registry.isAttestationValid(id));
    }

    function testOriginalAttestorCanRevokeOwnAttestation() public {
        address attestor = address(0xA77E57);
        registry.setAuthorizedAttester(attestor, true);
        vm.prank(attestor);
        bytes32 id = registry.attest(ASSET, DECISION_A, "model-v1", "A", 100);
        vm.prank(attestor);
        registry.revokeAttestation(id, keccak256("attestor correction"));
        assertFalse(registry.isAttestationValid(id));
    }

    function testRevocationDoesNotFreezeAlreadyTokenizedAsset() public {
        bytes32 id = _attest(DECISION_A);
        RealEstateToken token = new RealEstateToken(
            "GreenLedger Existing", "GLX", ASSET, keccak256("title"),
            DECISION_A, 100, address(registry)
        );
        token.executeTokenization(address(this));
        uint256 supplyBefore = token.totalSupply();
        registry.revokeAttestation(id, keccak256("post-tokenization review"));
        assertTrue(token.isTokenized());
        assertEq(token.totalSupply(), supplyBefore);
        token.transfer(address(0xBEEF), 1 ether);
        assertEq(token.balanceOf(address(0xBEEF)), 1 ether);
    }

    function testAttestorAuthorizationChangeIsEnforced() public {
        address attestor = address(0xA77E57);
        registry.setAuthorizedAttester(attestor, true);
        vm.prank(attestor);
        registry.attest(ASSET, DECISION_A, "model-v1", "A", 100);
        registry.setAuthorizedAttester(attestor, false);
        vm.expectRevert(AIAttestationRegistry.UnauthorizedAttester.selector);
        vm.prank(attestor);
        registry.attest(ASSET, DECISION_B, "model-v2", "B", 200);
    }

    function testEmergencyPauseBlocksTokenizationButNotTransfersOfExistingTokens() public {
        bytes32 id = _attest(DECISION_A);
        RealEstateToken token = new RealEstateToken(
            "GreenLedger Pausable", "GLP", ASSET, keccak256("title"),
            DECISION_A, 100, address(registry)
        );
        token.executeTokenization(address(this));
        RealEstateToken pendingToken = new RealEstateToken(
            "GreenLedger Pending", "GLN", ASSET, keccak256("title-pending"),
            DECISION_A, 100, address(registry)
        );
        registry.setTokenizationPaused(true);
        vm.expectRevert(RealEstateToken.TokenizationPaused.selector);
        pendingToken.executeTokenization(address(0xBEEF));
        token.transfer(address(0xBEEF), 1 ether);
        assertEq(token.balanceOf(address(0xBEEF)), 1 ether);
        assertTrue(registry.isAttestationValid(id));
    }

    function testRegistryOwnershipTransferRequiresAcceptance() public {
        address nextOwner = address(0xCAFE);
        registry.transferOwnership(nextOwner);
        assertEq(registry.owner(), address(this));
        vm.prank(nextOwner);
        registry.acceptOwnership();
        assertEq(registry.owner(), nextOwner);
    }

    function testInvalidAttestationDataIsRejected() public {
        vm.expectRevert(AIAttestationRegistry.InvalidAttestationData.selector);
        registry.attest(bytes32(0), DECISION_A, "model-v1", "A", 100);
        vm.expectRevert(AIAttestationRegistry.InvalidAttestationData.selector);
        registry.attest(ASSET, bytes32(0), "model-v1", "A", 100);
        vm.expectRevert(AIAttestationRegistry.InvalidAttestationData.selector);
        registry.attest(ASSET, DECISION_A, "", "A", 100);
    }
}
