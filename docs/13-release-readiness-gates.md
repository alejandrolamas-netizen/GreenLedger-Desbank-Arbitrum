# GreenLedger — Release Readiness and Risk Gates

This is a release-control checklist for engineering and commercial pilots. A completed checkbox requires evidence attached to the release record; a source-code change or passing CI alone is insufficient.

## Gate 0 — product and legal perimeter

- [ ] Define asset class, jurisdiction, customer and intended legal effect.
- [ ] Confirm whether a token is only a technical representation or is intended to convey a legal/economic right.
- [ ] Obtain qualified legal review of the specific asset structure, offering, transfer restrictions, AML/KYC and licensing questions.
- [ ] Confirm the pilot is not offering deposits, investment returns, credit, exchange, custody or liquidity services unless separately authorized.
- [ ] Approve privacy/data-protection and records-retention design.

**Stop condition:** unclear legal rights, jurisdiction or regulated activity.

## Gate 1 — source and build integrity

- [ ] Pin repository commit, compiler version, optimizer settings and dependency lock/revision.
- [ ] Reproduce forge build and forge test -vvv from a clean checkout.
- [ ] Preserve CI run URLs and test output.
- [ ] Review storage layout and deployment assumptions.
- [ ] Run static analysis and dependency/vulnerability review.
- [ ] Review deployment scripts and chain-ID guards.

**Current evidence:** Foundry CI and unit/fuzz/invariant tests exist in the Arbitrum track. This does not establish independent review or testnet execution.

## Gate 2 — smart-contract security

- [ ] Independent review of access control, owner privileges and key recovery.
- [ ] Review attestation creation, supersession, expiry and revocation edge cases.
- [ ] Review whether a revoked or superseded attestation can ever authorize a new tokenization.
- [ ] Review emergency pause authority, monitoring and unpause procedure.
- [ ] Review ERC-20 transfer restrictions and whether unrestricted transfers match the intended legal model.
- [ ] Review asset-ID uniqueness scope and cross-factory/network implications.
- [ ] Review surface-to-supply conversion, units, rounding and overflow assumptions.
- [ ] Review valuation semantics, currency, precision and provenance.
- [ ] Review reentrancy/external-call assumptions and dependency versions.
- [ ] Complete external audit and remediate findings before production financial use.

**Stop condition:** unresolved critical/high findings, unclear admin ownership or missing recovery controls.

## Gate 3 — testnet deployment evidence

- [ ] Explicitly approve the target testnet and deployment operator.
- [ ] Verify RPC chain ID immediately before deployment.
- [ ] Use a dedicated test environment and test-only credentials controlled locally by the operator.
- [ ] Record commit, compiler settings, deployer role, contract addresses, transaction hashes and block numbers.
- [ ] Verify source code and constructor parameters on the relevant explorer.
- [ ] Seed only synthetic test assets unless a separately approved test dataset is used.
- [ ] Run public verification script and preserve output.

**Stop condition:** chain ID mismatch, unknown deployment artifact, missing transaction or explorer evidence.

## Gate 4 — indexer and operational observability

- [ ] Run indexer against the exact verified contract addresses and deployment block.
- [ ] Confirm chain ID and RPC endpoint configuration.
- [ ] Decode event arguments using the ABI version associated with the deployed bytecode.
- [ ] Index attestor authorization, revocation and pause events, not only the three initial asset events.
- [ ] Test duplicate ingestion, provider outage, cursor recovery and reorganization rollback.
- [ ] Reconcile indexed event counts and key values against direct RPC reads.
- [ ] Validate dashboard read-only behavior, loopback binding and database permissions.
- [ ] Define backup, restore, monitoring and operator escalation.

**Current limitation:** the existing indexer stores raw topics/data for a limited event set; it is not a complete ABI-aware operational monitoring service.

## Gate 5 — customer pilot acceptance

- [ ] Written scope, responsibilities, exclusions and success metrics.
- [ ] Data processing agreement and security responsibilities where applicable.
- [ ] Customer-approved test data and evidence handling.
- [ ] Named operator and escalation contacts.
- [ ] Reproducible demonstration and acceptance report.
- [ ] Open-defect register and agreed remediation plan.

## Gate 6 — production decision

Production is a separate decision, not an automatic continuation of a testnet pilot. Require independent security sign-off, legal/regulatory sign-off, operational readiness, key-management approval, incident response, support commitments, disaster recovery, monitoring, change management and customer acceptance.

## Current release classification

**Engineering prototype / pre-testnet evidence stage.** Repository code and CI are not evidence of deployment, audit, legal title, regulated permissions, customer adoption or production readiness.
