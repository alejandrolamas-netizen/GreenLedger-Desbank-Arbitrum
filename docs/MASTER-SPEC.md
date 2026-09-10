# GreenLedger / Desbank — Arbitrum Master Specification

## Purpose

This repository is the Arbitrum implementation line of GreenLedger / Desbank. It is intentionally isolated from the XRPL original and the Base/Ethereum implementation.

## Network targets

| Network | Chain ID | Role |
|---|---:|---|
| Arbitrum One | 42161 | production target |
| Arbitrum Sepolia | 421614 | test/development target |

## On-chain flow

1. `AIAttestationRegistry` records the AI decision hash and metadata.
2. `GreenLedgerFactory` accepts only its configured attestation registry.
3. The factory deploys `RealEstateToken` and transfers ownership to the caller.
4. `RealEstateToken.executeTokenization()` requires a matching attestation.
5. Supply is `registeredSurfaceSqFt × 10^18`.

## Canonical decision hash

The demo uses the Solidity canonical encoding:

`keccak256(abi.encodePacked(assetId, modelVersion, riskGrade, valuation, block.timestamp))`

Any off-chain verifier must reproduce the exact byte encoding and valuation units used by the deployed transaction. JSON serialization must not be substituted silently.

## Demo asset

- Asset ID: `GL-BUE-001`
- Surface: `50,000 sqft`
- Valuation: `48,500,000 USD`, represented with 18-decimal accounting in the attestation
- Model: `QAIzero-RWA-v1.0`
- Risk grade: `A`

## Deployment status

Addresses and transaction hashes are deliberately not hardcoded until an actual Arbitrum deployment is performed and independently verifiable on Arbiscan.
