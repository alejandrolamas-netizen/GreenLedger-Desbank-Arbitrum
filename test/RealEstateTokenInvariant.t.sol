// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/AIAttestationRegistry.sol";
import "../src/RealEstateToken.sol";

/// @notice Stateful handler used by Foundry's invariant runner.
contract TokenizationInvariantHandler {
    RealEstateToken public immutable token;

    constructor(
        address registry,
        bytes32 assetId,
        bytes32 titleHash,
        bytes32 decisionHash,
        uint256 surfaceSqFt
    ) {
        // The handler becomes token owner so invariant actions exercise the
        // actual onlyOwner tokenization path rather than bypassing access control.
        token = new RealEstateToken(
            "Invariant Asset",
            "INV",
            assetId,
            titleHash,
            decisionHash,
            surfaceSqFt,
            registry
        );
    }

    function attemptTokenization(address recipient) external {
        // Invalid recipients and repeated calls are expected to revert.
        // Catching them lets the invariant runner continue exploring inputs.
        try token.executeTokenization(recipient) {
        } catch {
        }
    }
}

contract RealEstateTokenInvariantTest is Test {
    AIAttestationRegistry internal registry;
    TokenizationInvariantHandler internal handler;
    RealEstateToken internal token;

    bytes32 internal constant ASSET_ID = keccak256("greenledger-invariant-asset");
    bytes32 internal constant TITLE_HASH = keccak256("greenledger-invariant-title");
    bytes32 internal constant DECISION_HASH = keccak256("greenledger-invariant-decision");
    uint256 internal constant SURFACE_SQ_FT = 50_000;

    function setUp() public {
        registry = new AIAttestationRegistry();
        registry.attest(ASSET_ID, DECISION_HASH, "model-v1", "A", 1);

        handler = new TokenizationInvariantHandler(
            address(registry),
            ASSET_ID,
            TITLE_HASH,
            DECISION_HASH,
            SURFACE_SQ_FT
        );
        token = handler.token();

        // Restrict invariant-generated calls to the explicit stateful handler.
        targetContract(address(handler));
    }

    /// @dev Supply can never exceed the one-time surface-area-based mint cap.
    function invariant_totalSupplyCannotExceedRegisteredSurface() public view {
        assertLe(token.totalSupply(), token.registeredSurfaceSqFt() * 1e18);
    }

    /// @dev Tokenization state and supply must remain consistent across fuzzed calls.
    function invariant_tokenizedFlagMatchesSupply() public view {
        assertEq(token.isTokenized(), token.totalSupply() != 0);
    }

    function test_RevertWhen_MintingWithoutAttestation() public {
        bytes32 unattestedAssetId = keccak256("unattested-asset");
        RealEstateToken unattestedToken = new RealEstateToken(
            "Unattested Asset",
            "NOATT",
            unattestedAssetId,
            TITLE_HASH,
            DECISION_HASH,
            SURFACE_SQ_FT,
            address(registry)
        );

        vm.expectRevert(RealEstateToken.AttestationNotFound.selector);
        unattestedToken.executeTokenization(address(this));
    }

    function test_TokenizationMintsExactSurfaceBasedSupply() public {
        handler.attemptTokenization(address(this));

        assertEq(token.totalSupply(), SURFACE_SQ_FT * 1e18);
        assertEq(token.totalSupply() / 1e18, token.registeredSurfaceSqFt());
        assertTrue(token.isTokenized());
    }
}
