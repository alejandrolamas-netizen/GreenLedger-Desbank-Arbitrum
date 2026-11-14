# Governance and Permissions Model

## Scope and status

This document describes the permissions implemented in the current Solidity source. It is an implementation review, not an independent security audit, legal opinion, title verification, or production-readiness certification.

The Base and Arbitrum source files reviewed for this document have matching Git blob SHAs for:
- `src/AIAttestationRegistry.sol`
- `src/GreenLedgerFactory.sol`
- `src/RealEstateToken.sol`

Matching source files do not establish deployed-bytecode parity or equivalent runtime state. Deployment addresses, compiler settings, constructor arguments, chain configuration, and on-chain verification must be checked separately.

## Role and permission matrix

| Role / actor | Contract | Permission | Effect and boundary |
|---|---|---|---|
| Registry owner | AIAttestationRegistry | `setAuthorizedAttester(account, allowed)` | Grants or revokes authority to create attestations. Zero address is rejected. |
| Registry owner | AIAttestationRegistry | `setTokenizationPaused(paused)` | Blocks or re-enables new tokenization calls. Does not disable ERC-20 transfers or alter existing balances. |
| Registry owner | AIAttestationRegistry | `revokeAttestation(id, reasonHash)` | Can revoke any existing attestation. Revocation blocks future tokenization when that record is current. |
| Authorized attester | AIAttestationRegistry | `attest(...)`, `attestWithExpiry(...)` | Creates a new attestation for an asset. The new record becomes current and makes the previous record non-current for validity checks. |
| Original attestor | AIAttestationRegistry | `revokeAttestation(id, reasonHash)` | Can revoke its own record, including a historical record. |
| Any external caller | GreenLedgerFactory | `deployAssetToken(...)` | Can deploy one token contract per asset ID, subject to parameter and registry checks. Factory does not require caller authorization or a current attestation at deployment time. |
| Factory caller / token owner | RealEstateToken | `executeTokenization(recipient)` | Can execute the one-time mint if the registry reports the matching attestation valid and tokenization is not paused. |
| Any ERC-20 holder | RealEstateToken | ERC-20 transfer functions | Transfers are not gated by the registry pause or attestation validity. |

## Lifecycle and control semantics

1. Registry deployment sets the deployer as owner and initially authorizes that same address as an attester.
2. The registry owner can add or remove attesters. Removing an attester prevents future attestations from that address; it does not automatically revoke attestations already created by it.
3. Every new attestation is appended to the asset history and becomes `currentAttestationId[assetId]`. Only the current record can pass `isAttestationValid`.
4. An attestation is invalid if it does not exist, is revoked, is expired, or is no longer the current record.
5. The original attestor or registry owner can revoke an attestation. Revoking an older, superseded record does not invalidate a newer current record. Revoking the current record prevents new tokenization against it.
6. Factory deployment is permissionless. The caller becomes the newly created token's owner after the factory transfers ownership.
7. Tokenization is owner-only, one-time, requires a nonzero recipient, checks the global pause flag, and checks the current attestation for the token's asset ID and decision hash.
8. The pause is scoped to new tokenization. It is not a transfer freeze, burn control, or general emergency stop.

## Security and governance observations

- **Concentrated registry authority:** a single registry owner can authorize attesters, pause tokenization, and revoke any attestation. `Ownable2Step` requires the proposed new owner to accept ownership, but it is not a multisig, timelock, or independent approval process.
- **Initial deployer trust:** the registry deployer starts as both owner and authorized attester. Operational deployment should explicitly review whether this is acceptable.
- **Permissionless factory:** anyone can create a token for an asset ID before another caller does. The first successful deployment reserves that ID in the factory. This is a design choice, not an access-control guarantee.
- **Token-owner concentration:** the factory caller becomes token owner and therefore controls the one-time tokenization call. The registry attestation remains a separate prerequisite.
- **No post-tokenization pause on transfers:** pause and attestation revocation do not restrict transfers of already minted ERC-20 balances.
- **Attestation supersession:** creating a new attestation immediately makes the previous one non-current, even if the previous record was not revoked. Off-chain consumers should read the current pointer and validity result rather than infer validity from historical existence.
- **No legal-asset enforcement:** hashes and attestation metadata do not independently establish legal title, valuation, custody, regulatory status, or rights represented by a token.

## Decisions required before production use

These are governance decisions, not changes assumed by this document:

1. Should registry ownership be held by a multisig, and what signer threshold and recovery process should apply?
2. Should sensitive administrative changes use a timelock? If so, which actions should be delayed, and which emergency actions should remain immediate?
3. Should the factory remain permissionless, or should deployment be gated by an allowlist, attestation, or governance approval?
4. Who should own each token after deployment: the caller, a designated issuer, a multisig, or another controlled address?
5. Should a registry-wide pause also block transfers, or is the current tokenization-only pause intentional?
6. What is the operational policy for attestation renewal, supersession, expiry, revocation reasons, and off-chain indexing?
7. Who monitors owner and attester changes, pause events, token creation, and attestation lifecycle events?

## Recommended verification work

- Add tests for unauthorized owner-only calls and unauthorized attestation attempts.
- Test that removing an attester blocks new attestations but does not silently rewrite existing records.
- Test owner and original-attestor revocation rights, including historical versus current records.
- Test that pause blocks new tokenization but does not block ERC-20 transfers.
- Test and document permissionless factory deployment and caller ownership.
- Compare the same tests and source files across Base and Arbitrum; record compiler, optimizer, EVM version, dependency lock, and deployment evidence separately.
- Obtain an independent review of the contracts and deployment configuration before handling real assets or making production claims.

## Evidence boundary

The current automated CI, static-analysis, and invariant-test results are useful engineering evidence. They do not prove absence of vulnerabilities and do not replace an independent smart-contract audit, deployment verification, operational controls, or legal review.
