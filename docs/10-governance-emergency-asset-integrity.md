# Governance, emergency controls and asset integrity

## Scope

This change adds a second security-hardening layer to the Arbitrum implementation:

- two-step registry ownership transfer through OpenZeppelin Ownable2Step;
- explicit attestor authorization events and rejection of the zero address;
- an owner-controlled emergency pause for **new tokenization only**;
- global asset-ID uniqueness in the factory;
- non-zero and non-empty input validation at registry, factory and token boundaries;
- tests for pause behavior, duplicate assets, invalid attestations and ownership acceptance.

## Emergency pause policy

The registry owner may pause or resume new tokenization. Each token checks the registry pause state before minting its initial supply. The pause does not freeze, burn or restrict transfers of tokens that have already been minted. It also does not prevent attestation records from being written or revoked.

The registry owner remains a privileged authority. Two-step ownership transfer reduces accidental transfer risk but is not a substitute for a multisig, timelock, independent governance process or operational key controls. A multisig contract can be designated as owner in a future deployment, subject to deployment and governance review.

## Asset uniqueness

The factory stores one token address per non-zero asset ID and rejects a second deployment for the same ID. The registry and token constructors reject zero identifiers, missing hashes, zero supply surface, missing registry code and invalid required metadata.

The asset ID is an application-level identifier. This contract-level uniqueness rule does not independently prove that two different IDs cannot refer to the same real-world property. That requires a trusted asset registry, due diligence and legal controls.

## Validation

The Foundry suite covers:
- tokenization supply invariants and fuzzed surface values;
- attestation expiry, revocation and authorization;
- emergency pause and transfer continuity;
- duplicate asset-ID rejection;
- invalid input rejection;
- two-step ownership acceptance.

CI results must be checked on the pull request before merge. Passing tests do not constitute an independent security audit.

## Explicit limitations

- No deployed contract is upgraded by this source change.
- Existing deployed tokens do not gain the pause check automatically.
- The owner remains a single configured authority unless a multisig is used as owner at deployment.
- No independent audit, legal title verification, valuation assurance, regulatory approval or production-readiness claim is made.
