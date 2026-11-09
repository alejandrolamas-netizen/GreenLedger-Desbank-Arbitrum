# Arbitrum Observability Stack — GreenLedger

**Status:** design specification / not yet implemented  
**Initial network:** Arbitrum Sepolia (chain ID 421614)  
**Production target:** Arbitrum One (chain ID 42161), subject to separate release approval  
**Scope:** monitoring, event indexing, explorer verification, analytics, alerting and operational evidence.

> This document describes a proposed observability architecture. It does not assert that contracts are deployed, verified, audited, indexed, or monitored in either network. Record actual addresses, transaction hashes, block numbers, provider details and dashboard links only after independently checking them.

## 1. Objectives

1. Make contract activity independently inspectable.
2. Detect operational anomalies and failed transactions.
3. Preserve an auditable trail of attestation and tokenization events.
4. Provide reproducible network-specific dashboards.
5. Keep testnet and mainnet data, credentials and release procedures isolated.

Observability is not a substitute for contract security review, a smart-contract audit, legal title verification, or proof that an AI decision is correct.

## 2. Network configuration

| Network | Chain ID | Explorer | Intended use |
|---|---:|---|---|
| Arbitrum Sepolia | 421614 | https://sepolia.arbiscan.io/ | Development, integration and test evidence |
| Arbitrum One | 42161 | https://arbiscan.io/ | Production only after release gates |
| Arbitrum Nova | 42170 | https://nova.arbiscan.io/ | Out of initial scope |

The application must validate the configured chain ID at startup and before signing or submitting transactions. A mismatch must fail closed.

Suggested environment variables (names only; never commit values):

- `ARB_CHAIN_ID`
- `ARB_RPC_URL`
- `ARB_WS_URL` (optional, if the provider supports WebSocket subscriptions)
- `ARBISCAN_API_KEY` (only if required by the selected verification/API workflow)

Use separate credentials and wallets for Sepolia and Arbitrum One. Do not reuse deployment keys across environments. Store secrets in an approved secret manager; never place private keys, seed phrases, API tokens or RPC credentials in Git, logs, dashboards or issue reports.

## 3. Data sources and responsibilities

### Block explorers

- [Arbiscan Sepolia](https://sepolia.arbiscan.io/): inspect testnet transactions, addresses, logs and contract source verification.
- [Arbiscan One](https://arbiscan.io/): inspect mainnet activity after a production deployment.
- [Arbitrum documentation](https://docs.arbitrum.io/): confirm current network parameters, RPC guidance and operational caveats.

Explorer pages are an independent inspection surface. A verified source match improves transparency but is not an audit or security certification.

### RPC and event ingestion

Use a documented RPC provider with an explicit availability/rate-limit policy. The indexer should:

1. Verify chain ID before processing.
2. Start from a configured deployment block for each contract.
3. Fetch logs in bounded block ranges.
4. Persist chain ID, contract address, block number, block hash, transaction hash, transaction index, log index and decoded event fields.
5. Make ingestion idempotent using the composite key `chain_id + tx_hash + log_index`.
6. Track the last processed block and support safe backfill.
7. Reconcile stored block hashes with canonical chain data and roll back/replay affected records after a reorganization.
8. Distinguish pending observations from confirmed/finalized observations according to the provider and current Arbitrum guidance. Do not hardcode an assumed finality interval without validating it.

Do not treat a single RPC response as sufficient evidence for a high-impact administrative action. Where practical, cross-check critical records with the explorer or a second independent provider.

### Dune Analytics

[Dune](https://dune.com/) can provide SQL-based historical analysis once the relevant chain data and contract events are available in its datasets. Create dashboards only after confirming the correct chain, contract addresses and event ABI. Dune is an analytics layer, not a real-time alerting guarantee or source of contract correctness.

### Optional indexing

[Chainbase](https://chainbase.com/) may be evaluated if custom indexing or API access materially reduces operational effort. It is optional; do not introduce a paid dependency until rate limits, coverage, data retention, pricing and exit strategy have been reviewed.

## 4. GreenLedger event inventory

The current repository source includes these event signatures:

| Contract | Event | Monitoring purpose |
|---|---|---|
| `AIAttestationRegistry` | `AssetAttested` | New or updated attestation for an asset |
| `GreenLedgerFactory` | `AssetTokenCreated` | Token contract created for an asset |
| `RealEstateToken` | `AssetTokenized` | Tokenization executed and supply minted |

The registry also exposes `setAuthorizedAttester(address,bool)` as a state-changing function, but the current source does not emit a dedicated authorization-change event. This limits event-only monitoring of attestor governance. Add a dedicated event in a separately reviewed contract change before relying on event-based alerts for this operation.

### Current-source limitations relevant to observability

- The registry stores one current attestation per `assetId`; a later attestation overwrites the prior mapping value. Historical `AssetAttested` logs may be indexed, but the contract does not expose a versioned on-chain history.
- `attest()` computes and returns an `attestationId`, but the current event does not emit that identifier and the mapping is keyed by `assetId`.
- The factory does not currently expose an on-chain registry of all deployed token addresses or enforce global uniqueness of `assetId` across created token contracts.
- The current event set is insufficient by itself to monitor every administrative or security-relevant state transition.

These are source-code observations, not claims about any deployed instance. Reassess against the exact commit and verified bytecode used for any future deployment.

## 5. Minimum indexed data model

### contracts
- chain_id
- contract_address
- contract_type
- deployment_tx_hash
- deployment_block
- source_commit
- compiler_version
- verification_url
- environment (testnet/mainnet)

### events
- chain_id
- contract_address
- event_name
- block_number
- block_hash
- transaction_hash
- transaction_index
- log_index
- timestamp
- decoded_payload
- confirmation_status

### assets
- asset_id
- title_hash
- registered_surface_sq_ft
- registry_address
- token_address
- decision_hash
- first_seen_at
- latest_attestation_block
- tokenization_tx_hash
- data_status

Store raw event payloads alongside decoded fields so that decoding can be repeated after ABI changes. Do not store sensitive personal, financial or title documents in public analytics tables.

## 6. Dashboard specification

Build separate Sepolia and One dashboards. Never mix environments in the same default view.

### Network and contract health
- Current indexed block and indexing lag
- Last successful RPC poll
- RPC errors, rate-limit responses and retry count
- Contract addresses and deployment blocks
- Explorer verification status, with link to the exact contract page

### Protocol activity
- Attestations by day and asset
- Token contracts created by day
- Tokenization executions by day
- Successful and reverted transactions, where reliable transaction/receipt data is available
- Unique assets observed and duplicate token creations requiring investigation

### Governance and security
- Attestor authorization changes (only after contract events or another reliable state-diff mechanism are implemented)
- Ownership/admin changes where observable
- Unexpected contract interactions
- Pauses/unpauses if pause functionality is implemented in a future contract version
- Changes in implementation/source version across deployments

### Data quality
- Events with decoding failures
- Missing deployment metadata
- Duplicate or conflicting asset identifiers
- Gaps in indexed block ranges
- Reorgs detected and records replayed

Every chart must show its chain, contract address, time range and data freshness.

## 7. Alerting policy

Start with operational alerts that are explainable and actionable:

| Alert | Trigger | Initial response |
|---|---|---|
| Chain mismatch | Configured chain ID differs from connected RPC | Stop transaction submission; investigate configuration |
| Indexer stalled | No forward progress beyond the agreed service threshold | Check RPC/provider health, then resume from last confirmed cursor |
| Ingestion gap | Missing block range or failed backfill | Pause dashboard freshness claims; backfill and reconcile |
| Decode failure | Event cannot be decoded with the registered ABI | Quarantine record; verify ABI and deployed bytecode |
| Unexpected token creation | New token contract not associated with an approved asset workflow | Investigate transaction, creator and asset ID |
| Unexpected attestation | Attestation from an unrecognized attestor | Verify authorization state and transaction context |
| Admin/permission change | Ownership or attestor permissions change | Notify designated maintainers and verify authorization |
| Reorg detected | Stored block hash no longer canonical | Roll back affected derived records and replay |

Thresholds, recipients, escalation windows and on-call ownership must be configured before production use. Do not label an alert as proof of fraud or compromise; it is a signal for investigation.

## 8. Security and operational controls

- Read-only monitoring credentials wherever possible.
- Least-privilege access to dashboards, indexer infrastructure and secret stores.
- Separate Sepolia and One databases, credentials, alert channels and deployment records.
- Rate limiting, bounded retries with backoff, and dead-letter/quarantine handling.
- Immutable retention of raw event observations where operationally appropriate.
- Documented backup, restore and re-index procedures.
- No secret values in telemetry, exception messages or exported dashboards.
- Review provider terms, data retention, regional availability and costs before production selection.
- Treat third-party indexer output as data to reconcile, not as an authority for contract state.

## 9. Acceptance criteria

### Sepolia pilot
- [ ] Correct chain ID (421614) is validated at startup.
- [ ] Deployment addresses and deployment transaction hashes are recorded from actual receipts.
- [ ] Each deployed contract is linked to its Arbiscan Sepolia page.
- [ ] Source verification status is recorded accurately; no claim is made before checking it.
- [ ] Indexer backfills from the documented deployment block.
- [ ] The three current protocol events are decoded and stored with transaction/log identity.
- [ ] Re-running the same block range does not create duplicate records.
- [ ] A simulated RPC outage is recovered without silently skipping blocks.
- [ ] Reorg reconciliation is tested in a controlled environment.
- [ ] Dashboard labels show Sepolia and expose data freshness.
- [ ] Alerts are tested and have an assigned responder.

### Arbitrum One release gate
- [ ] Separate production deployment approval and documented threat model.
- [ ] Independent contract security review completed for the exact release commit.
- [ ] Governance and emergency-operation policies defined and implemented.
- [ ] Mainnet deployment and verified bytecode independently checked.
- [ ] Production RPC/indexer service levels, alert routing, backups and recovery tested.
- [ ] Legal, asset-data and operational approvals completed by the responsible parties.

## 10. Implementation sequence

1. **Inventory:** record actual deployed addresses, source commit, compiler settings and deployment blocks. If no deployment exists, keep the inventory explicitly marked pending.
2. **Indexer prototype:** implement read-only log ingestion for Sepolia with checkpointing, idempotency and reorg reconciliation.
3. **Event coverage:** document ABI versions and identify missing governance/security events; handle contract changes in separate reviewed PRs.
4. **Analytics:** create a Dune dashboard using confirmed addresses and decoded events.
5. **Alerting:** add RPC/indexer health and protocol-event alerts with tested runbooks.
6. **Operational review:** test recovery and data quality before considering mainnet.

## 11. Reference links

- [Arbitrum documentation](https://docs.arbitrum.io/)
- [Arbiscan — Arbitrum One](https://arbiscan.io/)
- [Arbiscan — Arbitrum Sepolia](https://sepolia.arbiscan.io/)
- [Arbiscan — Arbitrum Nova](https://nova.arbiscan.io/)
- [Dune](https://dune.com/)
- [Chainbase](https://chainbase.com/)

---

**Implementation status:** documentation only. No indexer, dashboard, alerting service, RPC provider integration, contract change, deployment, verification or audit is delivered by this specification.
