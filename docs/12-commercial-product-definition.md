# GreenLedger / Desbank — Commercial Product Definition (v1)

**Status:** product definition for a pre-commercial engineering prototype. This document does not represent a production release, customer deployment, regulated financial service, investment product, custody service, or legal-title system.

## 1. Product thesis

GreenLedger is the asset-evidence and tokenization-control layer. Desbank is the proposed financial-workflow layer that may consume verified GreenLedger asset records in a later, separately governed product.

The initial commercial offer should be enterprise software and implementation services for controlled RWA workflow pilots. It must not promise liquidity, yield, credit, custody, exchange, underwriting, legal ownership, or regulatory compliance.

## 2. Product boundaries

### GreenLedger — current technical scope

The Arbitrum codebase currently provides:

- an owner-governed attestation registry with append-only per-asset record history;
- attestation expiry and revocation;
- authorization controls for attestors;
- a pause that blocks new tokenization;
- a factory that prevents a second token contract for the same non-zero asset ID;
- an ERC-20 tokenization path gated by the current matching attestation;
- a supply invariant derived from registered surface area;
- Foundry unit, fuzz and invariant tests;
- a read-only Arbitrum Sepolia JSON-RPC indexer and local loopback dashboard;
- chain-guarded deployment, synthetic demo-seeding and public-verification scripts.

These are repository capabilities. They are not evidence of a live deployment, independent audit, verified real-world asset, customer usage, or legal ownership.

### Desbank — proposed next layer

Desbank should be treated as a product/workflow layer, not as an active liquidity protocol. Candidate capabilities for discovery and later implementation:

1. asset onboarding case management;
2. evidence/document references and provenance;
3. policy and approval workflow;
4. portfolio and exposure reporting;
5. integration adapters for customer systems;
6. permissioned operational reporting.

Do not implement or market lending, collateralization, yield, deposits, swaps, redemption, custody or liquidity routing until there is a separately reviewed product specification, risk model, legal analysis, security design and explicit go-live approval.

## 3. Target customer and initial use case

Initial discovery segments:

- RWA asset originators and administrators;
- infrastructure providers serving real-estate, energy or industrial asset owners;
- fintech and professional-services teams building controlled digital-asset workflows.

Initial pilot problem: a customer needs a traceable technical record connecting an asset identifier, off-chain evidence references, a reviewed decision, an authorized attestation, and (only where appropriate) a test tokenization event.

Do not assume that the token itself conveys title, a security, a debt claim, beneficial ownership or a right to cash flows. Those consequences depend on the asset, contracts, jurisdiction and legal structure.

## 4. Proposed 60–90 day design-partner pilot

### Phase A — discovery and data mapping (weeks 1–2)
- identify asset class, jurisdiction, customer roles and intended legal effect;
- map source documents and authoritative registries;
- define asset identifiers, evidence hashes, retention and access rules;
- document exclusions and customer acceptance criteria.

### Phase B — controlled technical configuration (weeks 3–5)
- configure a test environment and synthetic or customer-approved non-sensitive test data;
- define attestor roles and approval policy;
- configure metadata schema and event reporting;
- run threat-model review and test suite.

### Phase C — testnet workflow validation (weeks 6–9)
- execute a controlled testnet demonstration only after explicit customer approval;
- validate event indexing, evidence references and exception handling;
- record reproducible test evidence and limitations.

### Phase D — acceptance and next-step decision (weeks 10–12)
- deliver architecture, test evidence, operational runbook and gap register;
- review legal, compliance and security dependencies with qualified customer advisers;
- decide whether to extend, redesign or stop.

Pilot success is measured by workflow traceability, completeness of evidence, test reproducibility, operator usability and closure of agreed defects — not token price, yield or speculative TVL.

## 5. Commercial packaging hypothesis

These are packaging concepts for customer discovery, not approved price quotes:

- **Discovery & Architecture:** paid assessment, asset workflow map, threat model and implementation plan.
- **Design Partner Pilot:** fixed-scope 60–90 day implementation with testnet-only validation.
- **Enterprise Integration:** separately scoped connectors, identity, reporting, deployment and support after security and legal gates.

Every proposal must state supported network, environment, deliverables, exclusions, customer responsibilities, data handling, acceptance tests, support window and change-control process.

## 6. Data and trust model

- Keep personally identifiable information, confidential documents, bank data and legal instruments off-chain.
- Store only opaque identifiers and cryptographic commitments on-chain where justified.
- A hash proves integrity against a known source; it does not prove that the source is true, authoritative or legally sufficient.
- An AI model version, risk grade or valuation field is metadata, not an independent appraisal or legal opinion.
- The current Solidity valuation field has no explicit currency, unit or scale. Do not expose it as a monetary valuation in customer-facing output until a typed valuation schema and migration strategy exist.
- surfaceSqFt is a technical quantity used to calculate token supply. It is not proof of measured area or a legal unit of entitlement.
- Define customer-specific access, retention, deletion, backup, incident and data-residency policies before any real customer data is processed.

## 7. Roles and governance

Before a customer pilot, document at minimum:

- registry owner and succession/recovery process;
- attestor admission, removal and separation of duties;
- who creates, reviews and revokes attestations;
- incident escalation and pause authority;
- key-management design appropriate to the customer;
- change management and release approval.

Ownable2Step is safer ownership transfer mechanics, not a multisig, timelock, independent governance or segregation of duties. The current owner is still a privileged role.

## 8. Commercial acceptance criteria

A pilot is not accepted until all applicable items are evidenced:

- requirements and exclusions signed off;
- test environment and chain ID confirmed;
- contract source and build artifacts pinned to a commit;
- unit, fuzz and invariant suites pass in CI;
- threat model and unresolved risks reviewed;
- synthetic data clearly labelled, or customer data explicitly approved;
- contract deployment and explorer verification recorded if a testnet deployment is authorized;
- indexer and dashboard run against the same verified deployment;
- operator runbook, recovery procedure and known limitations delivered;
- customer acceptance report signed.

## 9. Explicit non-claims

GreenLedger / Desbank must not be described as audited, production-ready, bank-integrated, compliant, liquid, revenue-generating, custody-enabled or legally title-conferring unless the specific claim is supported by independent evidence and approved by the responsible legal/security reviewers.

## 10. Next product increments

1. ABI-aware event decoding and versioned event schemas.
2. Indexer coverage for attestor authorization, revocation and pause events.
3. Reconciliation between registry, factory, token and indexed records.
4. Evidence manifest format with off-chain storage references and content hashes.
5. Role-based operator console and audit export (off-chain, privacy-aware).
6. Formal security review, external audit and customer-specific legal assessment.
7. Ethereum/Base implementation brought to documented security parity before cross-network product claims.
