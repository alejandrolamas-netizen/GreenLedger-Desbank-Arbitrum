# Attestation lifecycle policy — Phase 1

**Status:** proposed implementation policy for review; not a legal or regulatory determination.

## Record model

- Attestations are append-only records identified by a unique attestationId.
- Each record retains asset ID, decision hash, model version, risk grade, valuation metadata, attestor, creation timestamp, optional expiry and revocation state.
- A per-asset pointer identifies the current attestation. Creating a newer attestation supersedes the prior record for new tokenization checks; prior records remain queryable.
- expiresAt equal to zero means no automatic expiry. Otherwise, validity ends when the block timestamp is greater than or equal to expiresAt.

## Revocation policy

- The original attestor or registry owner may revoke an attestation. A revocation reason is represented by a hash; sensitive evidence should remain off-chain under an appropriate retention and access policy.
- Revocation makes that attestation invalid for future tokenization.
- Revocation does not burn, freeze, or otherwise alter tokens already minted. It does not itself stop transfers.
- Emergency pause is a separate future control with a separately approved authority model and explicit operation scope.

## Tokenization gate

A token may be tokenized only when the registry reports that the asset's current attestation exists, is not revoked, has not expired, is still the current record for that asset, and matches the token's decision hash.

## Important limitations

- This mechanism does not establish legal title, asset existence, valuation accuracy, model execution, or regulatory compliance.
- The owner is currently a single Ownable authority. Multisig/timelock governance and operational recovery remain separate deployment requirements.
- Existing deployed token contracts will not automatically inherit changes to a registry implementation unless their immutable registry address points to an upgraded compatible contract. No deployment or upgrade is performed by this PR.
- A revocation is an operational evidence-status change, not a legal determination about ownership or investor rights.
