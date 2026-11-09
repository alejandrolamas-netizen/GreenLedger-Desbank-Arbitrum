# GreenLedger-Desbank-Arbitrum

**EmergentSoft · RWA Tokenization · Arbitrum Track**

## Status

**Network-specific implementation track.**

This repository contains the Arbitrum adaptation of the GreenLedger / Desbank asset-tokenization stack.

## Implemented scope

- Arbitrum One / Arbitrum Sepolia deployment tooling
- AI-attestation-gated ERC-20 asset tokenization
- Surface-area / supply invariant enforcement
- Verification tooling
- Automated tests

## Architecture

`AIAttestationRegistry → GreenLedgerFactory → RealEstateToken`

The factory uses its configured attestation registry. Tokenization requires a matching `(assetId, decisionHash)` attestation and enforces the configured surface/supply invariant.

## Evidence policy

The repository contains implementation, deployment and verification tooling but **does not claim a live Arbitrum deployment until real contract addresses, transaction hashes and explorer verification are recorded**.

Source code does not by itself establish a regulated financial service, securities offering, investment product or legal ownership interest.

## Separation rule

This repository is independent from the XRPL original and the Base/Ethereum implementation. Changes to one network track should not be represented as changes to another.

## Production hardening

Before production financial use, validate:

- attestation history/versioning and revocation;
- model and decision provenance;
- authorized attestors and two-step registry ownership transfer;
- upgrade/admin controls;
- token supply invariants and global asset-ID uniqueness;
- emergency pause for new tokenization (existing transfers remain enabled);
- deployment verification and independent security review;
- legal and regulatory requirements for the intended jurisdiction and asset.

## Commercial role

This network track supports technical RWA tokenization workflows where Arbitrum is the selected settlement environment.

## Security & IP

See `SECURITY.md` and `LICENSE`.

## Owner

Alejandro Lamas — Founder & CEO, EmergentSoft


## Current hardening implementation

The repository now includes versioned attestations, revocation and expiry controls, Foundry fuzz/invariant tests, a read-only Arbitrum Sepolia event indexer, two-step registry ownership transfer, an emergency pause for new tokenization, factory-level asset-ID uniqueness and input validation. These controls are source-code and CI milestones; they are not evidence of a live deployment, an independent audit or regulatory approval. See [governance and asset-integrity controls](docs/10-governance-emergency-asset-integrity.md) and [Arbitrum observability](docs/08-arbitrum-observability.md).
