# GreenLedger-Desbank-Arbitrum

**EmergentSoft · RWA Tokenization · Arbitrum Track**

## What it is

Arbitrum adaptation of the GreenLedger / Desbank asset-tokenization stack.

## Business problem

Enterprise RWA systems need network-specific tokenization infrastructure with verifiable issuance rules, AI attestations and reproducible deployment tooling.

## Capabilities

- Arbitrum One / Arbitrum Sepolia support
- AI-attestation-gated ERC-20 asset tokenization
- Surface-area / supply invariant enforcement
- Deployment and verification tooling

## Architecture

`AIAttestationRegistry → GreenLedgerFactory → RealEstateToken`

The factory accepts only its configured registry and transfers ownership of each newly created token to the caller. Tokenization requires a matching `(assetId, decisionHash)` attestation and enforces the surface/supply invariant.

## Evidence policy

The repository contains deployment and verification tooling but **does not claim a live Arbitrum deployment until real contract addresses, transaction hashes and explorer verification are recorded**.

## Commercial role

This network track supports enterprise RWA tokenization and financing workflows where Arbitrum is the selected settlement environment.

## Separation rule

This repository is independent from the XRPL original and the Base/Ethereum implementation. Do not modify those source lines from the Arbitrum workstream.

## Security & IP

See [`SECURITY.md`](SECURITY.md) and [`LICENSE`](LICENSE). Third-party components remain subject to their respective licenses.

## Owner

Alejandro Lamas — Founder & CEO, EmergentSoft
