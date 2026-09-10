# Public Judge Verification — Arbitrum

A reviewer should verify the implementation in this order:

1. Confirm the deployed chain is Arbitrum One (`42161`) or Arbitrum Sepolia (`421614`).
2. Inspect `AIAttestationRegistry` and confirm the asset's stored `decisionHash`.
3. Reproduce the hash using the exact Solidity `abi.encodePacked` inputs and units.
4. Inspect `GreenLedgerFactory` and confirm `AssetTokenCreated` points to the expected token.
5. Inspect `RealEstateToken` immutable metadata: `assetId`, `titleHash`, `decisionHash`, `registeredSurfaceSqFt`, and registry address.
6. Confirm `isAttested(assetId, decisionHash)` returns true.
7. Confirm `totalSupply == registeredSurfaceSqFt × 10^18`.
8. Run the Foundry tests locally with `forge test -vv`.

## Evidence standard

A repository, source code, or deployment script is not itself proof of a live deployment. Record the actual contract addresses, transaction hashes, block numbers and Arbiscan verification URLs after deployment.
