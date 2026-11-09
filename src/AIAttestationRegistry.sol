// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable2Step.sol";

/// @notice Append-only attestation history with an explicit current-record pointer.
/// @dev An attestation is evidence metadata; it is not proof of legal title or valuation.
contract AIAttestationRegistry is Ownable2Step {
    struct Attestation {
        bytes32 assetId;
        bytes32 decisionHash;
        string modelVersion;
        string riskGrade;
        uint256 valuation;
        uint256 timestamp;
        address attestor;
        uint256 expiresAt; // 0 means no expiry
        bool revoked;
    }

    mapping(bytes32 => Attestation) public attestationById;
    mapping(bytes32 => bytes32[]) private _attestationHistory;
    mapping(bytes32 => bytes32) public currentAttestationId;
    mapping(address => bool) public authorizedAttesters;
    mapping(bytes32 => uint256) private _assetNonce;

    bool public tokenizationPaused;

    error UnauthorizedAttester();
    error AttestationNotFound();
    error AttestationAlreadyRevoked();
    error InvalidExpiry();
    error InvalidAddress();
    error InvalidAttestationData();

    event AttestorAuthorizationChanged(address indexed account, bool allowed);
    event TokenizationPauseChanged(bool paused, address indexed operator);
    event AssetAttested(
        bytes32 indexed assetId,
        bytes32 indexed attestationId,
        bytes32 decisionHash,
        string modelVersion,
        string riskGrade,
        uint256 valuation,
        uint256 timestamp,
        uint256 expiresAt,
        address indexed attestor
    );
    event AttestationRevoked(
        bytes32 indexed assetId,
        bytes32 indexed attestationId,
        address indexed revoker,
        bytes32 reasonHash,
        uint256 timestamp
    );

    constructor() Ownable(msg.sender) {
        authorizedAttesters[msg.sender] = true;
        emit AttestorAuthorizationChanged(msg.sender, true);
    }

    modifier onlyAuthorizedAttester() {
        if (!authorizedAttesters[msg.sender]) revert UnauthorizedAttester();
        _;
    }

    function setAuthorizedAttester(address account, bool allowed) external onlyOwner {
        if (account == address(0)) revert InvalidAddress();
        authorizedAttesters[account] = allowed;
        emit AttestorAuthorizationChanged(account, allowed);
    }

    /// @notice Emergency control for new tokenizations; existing ERC-20 transfers remain enabled.
    function setTokenizationPaused(bool paused) external onlyOwner {
        tokenizationPaused = paused;
        emit TokenizationPauseChanged(paused, msg.sender);
    }

    /// @notice Backward-compatible attestation entry point with no expiry.
    function attest(
        bytes32 assetId,
        bytes32 decisionHash,
        string calldata modelVersion,
        string calldata riskGrade,
        uint256 valuation
    ) external onlyAuthorizedAttester returns (bytes32) {
        return _attest(assetId, decisionHash, modelVersion, riskGrade, valuation, 0);
    }

    /// @notice Creates an attestation that expires at a specified future timestamp.
    function attestWithExpiry(
        bytes32 assetId,
        bytes32 decisionHash,
        string calldata modelVersion,
        string calldata riskGrade,
        uint256 valuation,
        uint256 expiresAt
    ) external onlyAuthorizedAttester returns (bytes32) {
        if (expiresAt <= block.timestamp) revert InvalidExpiry();
        return _attest(assetId, decisionHash, modelVersion, riskGrade, valuation, expiresAt);
    }

    function _attest(
        bytes32 assetId,
        bytes32 decisionHash,
        string calldata modelVersion,
        string calldata riskGrade,
        uint256 valuation,
        uint256 expiresAt
    ) internal returns (bytes32 attestationId) {
        if (
            assetId == bytes32(0) ||
            decisionHash == bytes32(0) ||
            bytes(modelVersion).length == 0 ||
            bytes(riskGrade).length == 0 ||
            valuation == 0
        ) revert InvalidAttestationData();

        uint256 nonce = ++_assetNonce[assetId];
        attestationId = keccak256(
            abi.encode(assetId, decisionHash, msg.sender, block.chainid, block.timestamp, nonce)
        );

        attestationById[attestationId] = Attestation({
            assetId: assetId,
            decisionHash: decisionHash,
            modelVersion: modelVersion,
            riskGrade: riskGrade,
            valuation: valuation,
            timestamp: block.timestamp,
            attestor: msg.sender,
            expiresAt: expiresAt,
            revoked: false
        });
        _attestationHistory[assetId].push(attestationId);
        currentAttestationId[assetId] = attestationId;

        emit AssetAttested(
            assetId,
            attestationId,
            decisionHash,
            modelVersion,
            riskGrade,
            valuation,
            block.timestamp,
            expiresAt,
            msg.sender
        );
    }

    /// @notice The original attestor or registry owner may revoke a record.
    /// @dev Revocation blocks future tokenization; it does not alter existing token balances/transfers.
    function revokeAttestation(bytes32 attestationId, bytes32 reasonHash) external {
        Attestation storage a = attestationById[attestationId];
        if (a.attestor == address(0)) revert AttestationNotFound();
        if (msg.sender != owner() && msg.sender != a.attestor) revert UnauthorizedAttester();
        if (a.revoked) revert AttestationAlreadyRevoked();

        a.revoked = true;
        emit AttestationRevoked(a.assetId, attestationId, msg.sender, reasonHash, block.timestamp);
    }

    function isAttestationValid(bytes32 attestationId) public view returns (bool) {
        Attestation storage a = attestationById[attestationId];
        if (a.attestor == address(0) || a.revoked) return false;
        if (a.expiresAt != 0 && block.timestamp >= a.expiresAt) return false;
        if (currentAttestationId[a.assetId] != attestationId) return false;
        return true;
    }

    function getAttestationHistoryLength(bytes32 assetId) external view returns (uint256) {
        return _attestationHistory[assetId].length;
    }

    function getAttestationHistoryAt(bytes32 assetId, uint256 index) external view returns (bytes32) {
        return _attestationHistory[assetId][index];
    }

    function getAttestation(bytes32 assetId) external view returns (bool, bytes32) {
        bytes32 id = currentAttestationId[assetId];
        Attestation storage a = attestationById[id];
        return (id != bytes32(0) && isAttestationValid(id), a.decisionHash);
    }

    function isAttested(bytes32 assetId, bytes32 decisionHash) external view returns (bool, address) {
        bytes32 id = currentAttestationId[assetId];
        Attestation storage a = attestationById[id];
        bool valid = id != bytes32(0) && isAttestationValid(id) && a.decisionHash == decisionHash;
        return (valid, a.attestor);
    }
}
