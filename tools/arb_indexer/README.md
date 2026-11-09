# GreenLedger Arbitrum Event Indexer

A read-only Python JSON-RPC poller that stores GreenLedger protocol logs in SQLite. It is an initial Sepolia-first operational prototype, not a hosted service or a production monitoring guarantee.

## Setup

Python 3.10+ is recommended.

```bash
python -m venv .venv
. .venv/bin/activate
pip install -r tools/arb_indexer/requirements.txt
cp tools/arb_indexer/.env.example .env
```

Set the environment variables from the deployment record. In particular, replace the example address with the actual verified registry/factory/token addresses and set `ARB_START_BLOCK` to the earliest relevant deployment block. The example address is deliberately non-production placeholder data and must not be used as a deployment claim.

Export the values from a secure environment manager (the script does not parse `.env` files):

```bash
set -a
. ./.env
set +a
python tools/arb_indexer/indexer.py
```

For PowerShell, set the same variables in the process environment before running the script.

## Configuration

| Variable | Meaning | Default |
|---|---|---|
| `ARB_RPC_URL` | HTTP JSON-RPC endpoint | required |
| `ARB_CHAIN_ID` | Expected chain ID | 421614 |
| `ARB_START_BLOCK` | First block to scan | 0 |
| `ARB_CONFIRMATIONS` | Head distance before indexing | 12 |
| `ARB_CHUNK_SIZE` | Maximum blocks per `eth_getLogs` request | 500 |
| `ARB_POLL_SECONDS` | Poll interval | 15 |
| `ARB_INDEXER_DB` | SQLite database path | data/arbitrum-events.sqlite3 |
| `ARB_CONTRACT_ADDRESSES` | Comma-separated contract addresses | required |

Use the network's documented RPC guidance and the provider's rate limits to tune confirmations and chunk size. These defaults are operational starting points, not a guarantee of finality or provider capacity.

## Stored data

- `blocks`: canonical block hashes, parent hashes and timestamps for the indexed range.
- `events`: raw topics and data, event name, contract, transaction/log identity and block metadata.
- `indexer_state`: last committed block per chain.

The primary key on `(chain_id, transaction_hash, log_index)` makes repeated ingestion idempotent. The indexer checks the stored cursor block against the current chain and rolls back to a stored common ancestor if that cursor was reorganized. It retains raw event topics/data rather than claiming full ABI argument decoding.

## Current event signatures

- `AssetAttested(bytes32,bytes32,bytes32,string,string,uint256,uint256,uint256,address)`
- `AssetTokenCreated(bytes32,address,address)`
- `AssetTokenized(bytes32,uint256,address)`

Unknown topics are not queried by the current filter. Governance events are not covered until the contracts emit them and the indexer event inventory is updated.

## Local dashboard

After the indexer has created the SQLite database, start the local read-only dashboard in a second terminal:

~~~bash
python tools/arb_indexer/dashboard.py
~~~

Open http://127.0.0.1:8080. The dashboard binds only to loopback, opens the database in SQLite read-only mode and displays the latest indexed block and recent raw events. It is a local prototype, not a hosted service, ABI decoder or alerting system.

## Safety and limitations

- Chain ID is checked before every indexing cycle.
- This tool never signs, sends transactions, or requires a private key.
- Do not commit RPC credentials, API keys, private keys, seed phrases or production addresses in example files.
- It does not decode ABI parameters, track pending transactions, provide a web dashboard, send alerts, or independently establish legal asset ownership.
- It uses one configured contract-address set and one start block for the selected environment. Run a separate process and database for each network.
- A provider outage leaves the cursor unchanged so the next cycle can retry.
- Reorg recovery is bounded by the locally indexed range; if no common ancestor is found, the process stops advancing and requires operator investigation.
- Confirmations are a configurable operational buffer, not a protocol-level finality assertion.
