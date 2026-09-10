// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IAIAttestation { function isAttested(bytes32 assetId, bytes32 decisionHash) external view returns (bool, address); }

contract RealEstateToken is ERC20, Ownable {
    bytes32 public immutable assetId;
    bytes32 public immutable titleHash;
    bytes32 public immutable decisionHash;
    uint256 public immutable registeredSurfaceSqFt;
    IAIAttestation public immutable attestationRegistry;
    bool public isTokenized;

    error AttestationNotFound();
    error InvariantViolation(uint256 expected, uint256 actual);
    error AlreadyTokenized();
    event AssetTokenized(bytes32 indexed assetId, uint256 totalSupply, address indexed attester);

    constructor(string memory name, string memory symbol, bytes32 _assetId, bytes32 _titleHash, bytes32 _decisionHash, uint256 _surfaceSqFt, address _attestationRegistry)
        ERC20(name, symbol) Ownable(msg.sender) {
        assetId = _assetId; titleHash = _titleHash; decisionHash = _decisionHash;
        registeredSurfaceSqFt = _surfaceSqFt; attestationRegistry = IAIAttestation(_attestationRegistry);
    }

    function executeTokenization(address recipient) external onlyOwner {
        if (isTokenized) revert AlreadyTokenized();
        (bool valid, address attester) = attestationRegistry.isAttested(assetId, decisionHash);
        if (!valid) revert AttestationNotFound();
        uint256 targetSupply = registeredSurfaceSqFt * (10 ** decimals());
        _mint(recipient, targetSupply);
        if (totalSupply() != targetSupply) revert InvariantViolation(targetSupply, totalSupply());
        isTokenized = true;
        emit AssetTokenized(assetId, totalSupply(), attester);
    }
}
