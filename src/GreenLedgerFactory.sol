// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./RealEstateToken.sol";

contract GreenLedgerFactory {
    address public immutable attestationRegistry;
    mapping(bytes32 => address) public assetTokenById;

    error InvalidRegistry();
    error InvalidAssetId();
    error AssetAlreadyDeployed(bytes32 assetId, address existingToken);
    error InvalidTokenParameters();

    event AssetTokenCreated(bytes32 indexed assetId, address indexed tokenAddress, address indexed creator);

    constructor(address _attestationRegistry) {
        if (_attestationRegistry == address(0) || _attestationRegistry.code.length == 0) {
            revert InvalidRegistry();
        }
        attestationRegistry = _attestationRegistry;
    }

    function deployAssetToken(
        string calldata name,
        string calldata symbol,
        bytes32 assetId,
        bytes32 titleHash,
        bytes32 decisionHash,
        uint256 surfaceSqFt,
        address registry
    ) external returns (address tokenAddress) {
        if (registry != attestationRegistry) revert InvalidRegistry();
        if (assetId == bytes32(0)) revert InvalidAssetId();
        address existing = assetTokenById[assetId];
        if (existing != address(0)) revert AssetAlreadyDeployed(assetId, existing);
        if (
            bytes(name).length == 0 ||
            bytes(symbol).length == 0 ||
            titleHash == bytes32(0) ||
            decisionHash == bytes32(0) ||
            surfaceSqFt == 0
        ) revert InvalidTokenParameters();

        RealEstateToken token = new RealEstateToken(
            name,
            symbol,
            assetId,
            titleHash,
            decisionHash,
            surfaceSqFt,
            registry
        );
        token.transferOwnership(msg.sender);
        tokenAddress = address(token);
        assetTokenById[assetId] = tokenAddress;
        emit AssetTokenCreated(assetId, tokenAddress, msg.sender);
    }
}
