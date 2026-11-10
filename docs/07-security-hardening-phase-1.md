# GreenLedger Security Hardening — Phase 1

**Status:** engineering plan; no contract behavior changed by this document.  
**Target branch:** `security/hardening-phase-1`  
**Baseline:** `main`  
**Deployment policy:** no production deployment, no key handling, and no merge without explicit review and authorization.

## Scope and goals

This phase addresses the trust boundaries identified in the current Solidity contracts. The goal is to make attestation lifecycle, asset uniqueness, emergency controls, and validation explicit and testable before any production-network consideration.

The current contracts are a prototype. An attestation is not proof of legal title, a valuation is not independently verified, and an AI decision is not proof that a model executed as claimed. Tokenization must not be represented as legal ownership or a regulated financial product.

## Work packages

### GL-SEC-01 — Versioned attestation history (P0)

- Replace the single mutable per-asset record as the sole source of truth with append-only attestation records.
- Assign a stable, queryable attestation identifier and emit it in the event.
- Preserve a current-attestation pointer per asset while retaining prior records.
- Bind each record to the asset identifier, decision hash, attestor, model/version metadata, timestamp, and lifecycle status.
- Tests: first attestation, subsequent version, historical lookup, current pointer, unauthorized writer rejection, event contents.

### GL-SEC-02 — Revocation and expiry (P0)

- Add explicit validity/expiry semantics and a revocation state for each attestation.
- Define who may revoke and whether revocation requires the original attestor, registry owner, or a designated governance role.
- Ensure tokenization rejects revoked, expired, superseded (if policy requires), or otherwise inactive attestations.
- Tests: valid, expired, revoked, superseded, boundary timestamp, and unauthorized revocation.

**Policy decision required:** whether an already-tokenized asset is frozen or remains transferable after its attestation is revoked. Do not silently assume either behavior.

### GL-SEC-03 — Attestor governance (P0)

- Separate operational attestor administration from general ownership where practical.
- Emit auditable events for authorization changes.
- Specify role separation, ownership transfer, and recovery procedures.
- Document that multisig/timelock governance is an operational deployment requirement unless implemented and tested on-chain.
- Tests: grant, revoke, unauthorized administration, ownership transfer, and role invariants.

### GL-SEC-04 — Emergency pause (P0)

- Add a narrowly scoped emergency pause to the relevant state-changing operations.
- Specify whether pause blocks attestation writes, new token creation, tokenization, and/or transfers.
- Ensure unpause authority and emergency governance are explicit.
- Tests: paused and unpaused behavior for every affected operation; unauthorized pause/unpause.

**Policy decision required:** define the minimum emergency authority and the exact set of operations frozen during an incident.

### GL-SEC-05 — Asset uniqueness (P1)

- Prevent the factory from creating multiple token contracts for the same asset identifier.
- Record the deployed token address by asset identifier and expose a read method.
- Emit a deterministic creation event and reject duplicate creation.
- Tests: first deployment succeeds, duplicate deployment reverts, independent assets succeed.

### GL-SEC-06 — Constructor and parameter validation (P1)

- Reject zero registry addresses and addresses without contract code where a contract is required.
- Reject zero asset identifiers, invalid title hashes where required by policy, and zero registered surface.
- Validate recipients and other critical parameters at the earliest safe boundary.
- Document surface units and the supply conversion formula; define a maximum bound to prevent nonsensical configurations.
- Tests: zero values, EOA registry, boundary values, overflow behavior, and valid deployment.

### GL-SEC-07 — Security and invariant tests (P1)

- Add focused unit tests for every work package.
- Add invariant/fuzz tests for supply bounds, one-token-per-asset, attestation lifecycle, and authorization.
- Run the full Foundry suite and record exact toolchain versions and command output.
- Do not report CI as passing until checks have actually completed on the proposed branch.

## Suggested implementation order

1. Agree the policy decisions in SEC-02 and SEC-04.
2. Implement versioned attestation records and lifecycle checks.
3. Implement attestor governance and emergency controls.
4. Implement factory uniqueness and parameter validation.
5. Add unit, fuzz, and invariant tests.
6. Run `forge fmt --check`, `forge build --sizes`, and `forge test -vvv`.
7. Obtain an independent Solidity security review before any mainnet deployment.

## Review and release gates

- [ ] Policy decisions documented and approved.
- [ ] All new and existing tests pass on the branch.
- [ ] No secrets, private keys, RPC credentials, or deployment artifacts committed.
- [ ] CI result observed on the exact proposed head commit.
- [ ] Independent review completed; findings triaged.
- [ ] Deployment configuration and governance reviewed separately.
- [ ] Explicit authorization obtained before merge or deployment.

## Known limitations not solved by these changes alone

- An on-chain hash does not prove legal title or the truth of off-chain documents.
- Model/version strings and risk grades are metadata unless independently attested and verifiable.
- A smart contract cannot establish regulatory compliance by itself.
- Event logs can support off-chain audit trails but do not replace a properly designed on-chain record and retention policy.
- A testnet deployment or passing unit tests is not a security audit.
