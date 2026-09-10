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
