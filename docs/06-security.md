# Security Notes

## Trust boundaries

- AI attestations are accepted only from addresses authorized by the registry owner.
- The factory rejects a registry address different from its immutable configured registry.
- Tokenization requires a matching `(assetId, decisionHash)` attestation.
- Tokenization is one-shot through `isTokenized`.
- The token supply invariant is checked after minting.

## Operational rules

- Never commit `.env`, private keys, RPC credentials, or explorer API keys.
- Use a dedicated deployment wallet for testnet and production operations.
- Verify deployed bytecode and constructor arguments on Arbiscan.
- Treat the demo valuation and asset metadata as illustrative until connected to an approved data source.

## Isolation

This Arbitrum line must not mutate the XRPL source or the Base/Ethereum repository. Cross-chain adaptations are separate deployment artifacts.


## Current implementation limits (must remain visible in technical reviews)

- The registry stores one current attestation per `assetId`; a later attestation overwrites the prior mapping entry. The emitted event is historical evidence, but the contract does not provide an on-chain versioned query interface.
- The registry has no revocation, expiry, or model-governance lifecycle in this version.
- `modelVersion`, `riskGrade`, and `valuation` are recorded metadata. The contract does not independently verify model execution, model weights, data provenance, or valuation correctness.
- The owner controls the authorized-attester allowlist. Production governance therefore requires a documented key-management and owner-control design.
- The token contract has no pause/emergency control in this version.
- The invariant test currently checks that supply does not exceed the registered surface-derived bound; it does not establish legal ownership, title validity, valuation, or regulatory compliance.

These are explicit hardening items, not capabilities to imply in a product demonstration.

## CI

The repository includes a Foundry workflow that installs pinned OpenZeppelin Contracts and forge-std versions, compiles the Solidity contracts, and runs unit and invariant tests. The workflow result must be checked on the pull-request head before describing the current branch as validated.
