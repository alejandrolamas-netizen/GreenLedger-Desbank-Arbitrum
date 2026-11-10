# Arbitrum Nitro v3.11.4 — RPC compatibility validation

**Status:** validation procedure and read-only smoke-check tool.  
**Target environment:** Arbitrum Sepolia (chain ID 421614).  
**Related release:** [OffchainLabs/nitro v3.11.4](https://github.com/OffchainLabs/nitro/releases/tag/v3.11.4).

## Purpose

This check validates the JSON-RPC behavior that GreenLedger's Arbitrum integration depends on. It is intentionally read-only: it does not deploy contracts, sign transactions, change chain state, or require a private key.

The v3.11.4 release notes describe, among other changes:
- rejection of `eth_feeHistory` reward percentiles greater than 100;
- rejection of `eth_getProof` requests containing more than 1,024 storage keys;
- a fix to batch-poster gas estimation when estimation reverts;
- safer limits for `eth_getProof` memory allocation.

The smoke-check script tests chain identification, latest block access, valid fee-history response shape, and rejection of a reward percentile above 100.

**Important limitation:** a successful RPC test does not prove which client implementation or Nitro version serves the endpoint. Public RPC providers may route requests through gateways, load balancers, or modified clients. Obtain node-version evidence separately from the operator if exact Nitro v3.11.4 provenance is required.

## 1. Run the smoke check

From the repository root:

```bash
python3 tools/arbitrum_rpc_smoke.py
```

The script reads `ARBITRUM_SEPOLIA_RPC_URL` from the environment. Alternatively:

```bash
python3 tools/arbitrum_rpc_smoke.py --rpc-url "$ARBITRUM_SEPOLIA_RPC_URL"
```

Expected chain ID is 421614. To test another explicitly selected network, supply `--expected-chain-id` with its decimal or hexadecimal chain ID. Do not point a testnet deployment workflow at mainnet.

The script performs:
1. `eth_chainId` and fails closed on a mismatch.
2. `eth_blockNumber` to verify latest-block access.
3. `eth_feeHistory` for five blocks and reward percentiles 25, 50 and 75.
4. A negative `eth_feeHistory` probe with percentile 101; an RPC validation error is expected.

The script prints the endpoint hostname, not the full URL, to avoid exposing credentials embedded in provider URLs.

## 2. What this does not test

- It does not prove that the RPC backend is specifically Nitro v3.11.4.
- It does not exercise the 1,024-key `eth_getProof` boundary. Providers can impose independent request-size and rate limits, so that probe must be run against a controlled node with a known client build.
- It does not test batch-poster internals, BoLD validator logs, node memory behavior, or canonical block-header decoding.
- It does not compile contracts, run Foundry tests, deploy contracts, verify source code, or perform a security audit.

## 3. Contract-level Arbitrum Sepolia validation

After the local Foundry suite passes and a testnet deployment is deliberately approved, follow [the Arbitrum Sepolia runbook](11-arbitrum-sepolia-runbook.md). Capture, without inventing or hand-editing:
- chain ID and test timestamp;
- registry, factory and token addresses;
- deployment and tokenization transaction hashes;
- deployment block numbers;
- Arbiscan Sepolia links;
- Foundry build/test output and CI run URL;
- event-indexer output for `AssetAttested`, `AssetTokenCreated` and `AssetTokenized`.

Keep synthetic demonstration assets clearly labelled as synthetic. Do not imply legal title, independent valuation, regulatory approval, production readiness, or non-zero TVL from a testnet demonstration.

## 4. Acceptance record

| Check | Expected result | Evidence |
|---|---|---|
| Chain ID | 421614 | Script output |
| Latest block | RPC returns valid hex quantity | Script output |
| Valid fee history | Five gas ratios and six base-fee entries | Script output |
| Percentile guard | Percentile 101 rejected | Script output |
| Foundry build/tests | Pass | Local output / GitHub Actions |
| Sepolia deployment | Only after explicit approval | Transaction hashes and explorer links |
| Contract event flow | Expected events indexed | Indexer records and transaction links |
| Nitro version provenance | Confirmed by node operator | Operator/build metadata, not public RPC inference |

Record actual outcomes in a dated validation report. Until the checks are run, their status is **not yet tested**.
