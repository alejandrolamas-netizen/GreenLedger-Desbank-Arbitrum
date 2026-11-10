# GreenLedger / Desbank — Arbitrum

**EmergentSoft · RWA asset-evidence and tokenization-control track**

## Status

**Pre-commercial engineering prototype.** This repository contains the Arbitrum-specific implementation and testnet tooling. It does not establish a live Arbitrum deployment, independent audit, customer deployment, regulated financial service or legal ownership system.

## Implemented source scope

- owner-governed, append-only attestation history with expiry and revocation;
- authorized attestors and two-step registry ownership transfer;
- emergency pause for new tokenization (existing ERC-20 transfers are not frozen);
- factory-level uniqueness for non-zero asset IDs;
- token input validation and attestation-gated ERC-20 tokenization;
- surface-to-supply invariant;
- Foundry unit, fuzz and stateful invariant tests;
- read-only Arbitrum Sepolia event indexer and loopback-only local dashboard;
- chain-guarded deployment, synthetic demo-seeding and verification scripts.

These are repository and CI milestones, not deployment or audit evidence.

## Architecture

Real-world asset evidence → AIAttestationRegistry → GreenLedgerFactory → RealEstateToken → read-only event indexing.

The registry's AI decision metadata is not an independent appraisal, legal opinion or proof of asset title. The title hash is a commitment, not proof that the underlying document is authoritative. The surface-based supply formula is a technical rule, not proof of measured area or entitlement.

## Commercial product definition

The proposed initial offer is enterprise software and implementation services for controlled RWA workflow pilots. Desbank is a proposed workflow/integration layer, not an active liquidity venue.

- [Commercial product definition](docs/12-commercial-product-definition.md)
- [Release readiness and risk gates](docs/13-release-readiness-gates.md)
- [Attestation lifecycle policy](docs/09-attestation-lifecycle-policy.md)
- [Governance and asset-integrity controls](docs/10-governance-emergency-asset-integrity.md)
- [Arbitrum observability](docs/08-arbitrum-observability.md)
- [Arbitrum Sepolia runbook](docs/11-arbitrum-sepolia-runbook.md)

## Known limitations

- no live contract addresses, transaction hashes or explorer verification are recorded here;
- no independent security audit has been completed;
- the indexer stores raw logs for a limited event set; full ABI decoding and complete governance-event coverage are not implemented;
- the dashboard is local-only, not hosted and not an alerting service;
- registry ownership remains a privileged role; Ownable2Step is not a multisig or timelock;
- valuation metadata does not currently encode currency, unit or scale;
- customer-specific legal, privacy, compliance and operational requirements remain to be assessed.

## Network separation

This repository is independent from the Ethereum/Base and XRPL workstreams. A test, deployment or security result on one network is not evidence for another.

## Security & IP

See SECURITY.md and LICENSE. Production financial use requires independent security review and customer-specific legal/regulatory assessment.

## Owner

EmergentSoft
