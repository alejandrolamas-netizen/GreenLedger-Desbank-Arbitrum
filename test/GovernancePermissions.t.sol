// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/AIAttestationRegistry.sol";
import "../src/GreenLedgerFactory.sol";
import "../src/RealEstateToken.sol";

contract GovernancePermissionsTest is Test {
    AIAttestationRegistry internal registry;
    GreenLedgerFactory internal factory;

    address internal constant OUTSIDER = address(0xB0B);
    address internal constant ATTESTER = address(0xA77E57);
    address internal constant BENEFICIARY = address(0xCAFE);

    bytes32 internal constant ASSET = keccak256("GL-GOVERNANCE-ASSET");
    bytes32 internal constant DECISION = keccak256("GL-GOVERNANCE-DECISION");

    function setUp() public {
        registry = new AIAttestationRegistry();
        factory = new GreenLedgerFactory(address(registry));
    }

    function testOnlyRegistryOwnerCanAuthorizeAttesters() public {
        vm.prank(OUTSIDER);
        vm.expectRevert();
        registry.setAuthorizedAttester(ATTESTER, true);

        assertFalse(registry.authorizedAttesters(ATTESTER));
        registry.setAuthorizedAttester(ATTESTER, true);
        assertTrue(registry.authorizedAttesters(ATTESTER));
    }

    function testOnlyRegistryOwnerCanPauseTokenization() public {
        vm.prank(OUTSIDER);
        vm.expectRevert();
        registry.setTokenizationPaused(true);

        assertFalse(registry.tokenizationPaused());
        registry.setTokenizationPaused(true);
        assertTrue(registry.tokenizationPaused());
    }

    function testAuthorizedAttesterCannotExerciseOwnerAdministration() public {
        registry.setAuthorizedAttester(ATTESTER, true);

        vm.prank(ATTESTER);
        vm.expectRevert();
        registry.setAuthorizedAttester(OUTSIDER, true);

        vm.prank(ATTESTER);
        vm.expectRevert();
        registry.setTokenizationPaused(true);

        assertFalse(registry.authorizedAttesters(OUTSIDER));
        assertFalse(registry.tokenizationPaused());
    }

    function testRemovingAttesterBlocksFutureAttestations() public {
        registry.setAuthorizedAttester(ATTESTER, true);

        vm.prank(ATTESTER);
        registry.attest(ASSET, DECISION, "model-v1", "A", 100);

        registry.setAuthorizedAttester(ATTESTER, false);
        assertFalse(registry.authorizedAttesters(ATTESTER));

        vm.prank(ATTESTER);
        vm.expectRevert(AIAttestationRegistry.UnauthorizedAttester.selector);
        registry.attest(ASSET, keccak256("NEXT-DECISION"), "model-v2", "A", 100);
    }

    function testPermissionlessFactoryDeploymentAssignsTokenOwnershipToCaller() public {
        registry.attest(ASSET, DECISION, "model-v1", "A", 100);

        vm.prank(OUTSIDER);
        address tokenAddress = factory.deployAssetToken(
            "Governance Test Asset",
            "GLGT",
            ASSET,
            keccak256("GL-GOVERNANCE-TITLE"),
            DECISION,
            250,
            address(registry)
        );

        RealEstateToken token = RealEstateToken(tokenAddress);
        assertEq(token.owner(), OUTSIDER);
        assertEq(factory.assetTokenById(ASSET), tokenAddress);

        vm.prank(OUTSIDER);
        token.executeTokenization(BENEFICIARY);

        assertTrue(token.isTokenized());
        assertEq(token.balanceOf(BENEFICIARY), 250 * 1e18);
    }

    function testFactoryDeploymentDoesNotRequireExistingAttestation() public {
        bytes32 unattestedAsset = keccak256("GL-UNATTESTED-DEPLOYMENT");

        vm.prank(OUTSIDER);
        address tokenAddress = factory.deployAssetToken(
            "Unattested Deployment",
            "GLUD",
            unattestedAsset,
            keccak256("GL-UNATTESTED-TITLE"),
            keccak256("GL-UNATTESTED-DECISION"),
            10,
            address(registry)
        );

        RealEstateToken token = RealEstateToken(tokenAddress);
        assertEq(token.owner(), OUTSIDER);
        vm.prank(OUTSIDER);
        vm.expectRevert(RealEstateToken.AttestationNotFound.selector);
        token.executeTokenization(BENEFICIARY);
    }

    function testNonOwnerCannotTokenizeCallerOwnedToken() public {
        registry.attest(ASSET, DECISION, "model-v1", "A", 100);

        vm.prank(OUTSIDER);
        address tokenAddress = factory.deployAssetToken(
            "Caller Owned Asset",
            "GLO",
            ASSET,
            keccak256("GL-CALLER-OWNED-TITLE"),
            DECISION,
            10,
            address(registry)
        );

        RealEstateToken token = RealEstateToken(tokenAddress);
        vm.expectRevert();
        token.executeTokenization(BENEFICIARY);
        assertFalse(token.isTokenized());
    }
}
