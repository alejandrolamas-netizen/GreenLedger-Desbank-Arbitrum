// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./RealEstateToken.sol";

contract GreenLedgerFactory {
    address public immutable attestationRegistry;
    event AssetTokenCreated(bytes32 indexed assetId, address indexed tokenAddress, address indexed creator);
    constructor(address _attestationRegistry) { attestationRegistry = _attestationRegistry; }
    function deployAssetToken(string calldata name, string calldata symbol, bytes32 assetId, bytes32 titleHash, bytes32 decisionHash, uint256 surfaceSqFt, address registry) external returns (address tokenAddress) {
        require(registry == attestationRegistry, "Invalid registry");
        RealEstateToken token = new RealEstateToken(name, symbol, assetId, titleHash, decisionHash, surfaceSqFt, registry);
        token.transferOwnership(msg.sender);
        tokenAddress = address(token);
        emit AssetTokenCreated(assetId, tokenAddress, msg.sender);
    }
}
