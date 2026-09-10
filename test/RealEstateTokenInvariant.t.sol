// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../src/RealEstateToken.sol";

contract RealEstateTokenInvariantTest is Test {
    RealEstateToken token;
    function setUp() public { token = new RealEstateToken("Invariant", "INV", keccak256("asset"), bytes32(0), keccak256("decision"), 1, address(0)); }
    function invariant_totalSupplyCannotExceedRegisteredSurface() public view {
        assertLe(token.totalSupply(), token.registeredSurfaceSqFt() * 1e18);
    }
}
