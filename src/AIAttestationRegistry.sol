// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AIAttestationRegistry is Ownable {
    struct Attestation { bytes32 assetId; bytes32 decisionHash; string modelVersion; string riskGrade; uint256 valuation; uint256 timestamp; address attestor; }
    mapping(bytes32 => Attestation) public attestations;
    mapping(address => bool) public authorizedAttesters;

    error UnauthorizedAttester();
    event AssetAttested(bytes32 indexed assetId, bytes32 decisionHash, string modelVersion, string riskGrade, uint256 valuation, uint256 timestamp, address indexed attestor);

    constructor() Ownable(msg.sender) { authorizedAttesters[msg.sender] = true; }
    modifier onlyAuthorizedAttester() { if (!authorizedAttesters[msg.sender]) revert UnauthorizedAttester(); _; }
    function setAuthorizedAttester(address account, bool allowed) external onlyOwner { authorizedAttesters[account] = allowed; }
    function attest(bytes32 assetId, bytes32 decisionHash, string calldata modelVersion, string calldata riskGrade, uint256 valuation) external onlyAuthorizedAttester returns (bytes32 attestationId) {
        attestationId = keccak256(abi.encodePacked(assetId, decisionHash, msg.sender, block.timestamp));
        attestations[assetId] = Attestation(assetId, decisionHash, modelVersion, riskGrade, valuation, block.timestamp, msg.sender);
        emit AssetAttested(assetId, decisionHash, modelVersion, riskGrade, valuation, block.timestamp, msg.sender);
    }
    function getAttestation(bytes32 assetId) external view returns (bool, bytes32) { Attestation memory a = attestations[assetId]; return (a.attestor != address(0), a.decisionHash); }
    function isAttested(bytes32 assetId, bytes32 decisionHash) external view returns (bool, address) { Attestation memory a = attestations[assetId]; return (a.attestor != address(0) && a.decisionHash == decisionHash, a.attestor); }
}
