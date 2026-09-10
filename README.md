# GreenLedger-Desbank-Arbitrum

Arbitrum adaptation of the GreenLedger / Desbank asset-tokenization stack.

- Arbitrum One: `42161`
- Arbitrum Sepolia: `421614`
- Arbiscan verification supported
- AI-attestation-gated ERC-20 asset tokenization
- Invariant: **1 token = 1 registered sqft** with 18 decimals

## Architecture

`AIAttestationRegistry` → `GreenLedgerFactory` → `RealEstateToken`

The factory accepts only its configured registry and transfers ownership of each newly created token to the caller. Tokenization requires a matching `(assetId, decisionHash)` attestation and enforces the surface/supply invariant.

## Demo asset

`GL-BUE-001` — 50,000 sqft — 48,500,000 USD — `QAIzero-RWA-v1.0` — risk grade `A`.

The repository contains deployment and verification tooling but **does not claim a live Arbitrum deployment until real contract addresses, transaction hashes and explorer verification are recorded**.

## Quick start

```bash
cp .env.example .env
forge install OpenZeppelin/openzeppelin-contracts --no-commit
forge install foundry-rs/forge-std --no-commit
forge build
forge test -vv
```

For Arbitrum Sepolia configure the environment and run `make deploy-sepolia`.

## Separation rule

This repository is independent from the XRPL original and the Base/Ethereum implementation. Do not modify those source lines from the Arbitrum workstream.
