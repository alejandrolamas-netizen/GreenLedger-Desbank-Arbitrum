# Arbitrum Sepolia deployment and demonstration runbook

## Safety boundary

This runbook is for **Arbitrum Sepolia only**. The deployment, demo-seeding and verification scripts enforce chain ID 421614 and revert on other networks.

The demo seed is synthetic. It does not represent a real property, a legal title, a valuation opinion, an investment product or a claim of ownership. Do not use the demo data for production or mainnet.

Never paste a private key or seed phrase into ChatGPT, GitHub issues, PRs, source files or logs. Keep signing material in a local environment manager or hardware-wallet workflow. The scripts read PRIVATE_KEY from the local process environment.

## 1. Local preflight

From a trusted local clone:

~~~bash
forge build
forge test -vvv
~~~

Create a local environment file and protect it:

~~~bash
cp .env.example .env
~~~

Fill .env locally with an Arbitrum Sepolia RPC endpoint, a test-only deployer key and (if using explorer verification) an Arbiscan API key. The repository ignores .env.

Load variables in a shell without putting secrets in command arguments:

~~~bash
set -a
. ./.env
set +a
~~~

Confirm the RPC network before signing:

~~~bash
cast chain-id --rpc-url "$ARBITRUM_SEPOLIA_RPC_URL"
~~~

Expected result: 421614. Stop if the result differs. Ensure the deployer has only testnet funds.

## 2. Deploy registry and factory

~~~bash
forge script script/Deploy.s.sol:DeployScript \
  --rpc-url "$ARBITRUM_SEPOLIA_RPC_URL" \
  --broadcast
~~~

Record the emitted ATTESTATION_ADDRESS and FACTORY_ADDRESS from the terminal output. Verify both addresses and the deployment transaction on the Arbitrum Sepolia explorer before continuing. Do not infer addresses from a local simulation.

Add the verified addresses to your local .env:

~~~text
ATTESTATION_ADDRESS=0x...
FACTORY_ADDRESS=0x...
~~~

Reload the environment after editing.

## 3. Create one synthetic demo asset

Run this step once per newly deployed factory. The factory enforces global asset-ID uniqueness, so rerunning against the same factory will correctly revert.

~~~bash
forge script script/SeedDemoAsset.s.sol:SeedDemoAssetScript \
  --rpc-url "$ARBITRUM_SEPOLIA_RPC_URL" \
  --broadcast
~~~

Record the attestation ID, token address, decision hash, block number and transaction hash from the output. Verify the transaction and deployed token address on the explorer. Add the token address to local .env as DEMO_TOKEN_ADDRESS.

## 4. Verify protocol invariants

~~~bash
forge script script/VerifyPublicly.s.sol:VerifyPubliclyScript \
  --rpc-url "$ARBITRUM_SEPOLIA_RPC_URL"
~~~

The expected verdict is PASS. Retain the console output and explorer links as evidence. This verifies the on-chain checks in the script; it is not an audit or legal verification of a real-world asset.

## 5. Start the read-only event indexer

Set the verified contract addresses and deployment block in local environment variables:

~~~bash
export ARB_CHAIN_ID=421614
export ARB_CONTRACT_ADDRESSES="$ATTESTATION_ADDRESS,$FACTORY_ADDRESS,$DEMO_TOKEN_ADDRESS"
export ARB_START_BLOCK=<verified-deployment-block>
export ARB_INDEXER_DB=data/arbitrum-sepolia.sqlite3
~~~

Install and run:

~~~bash
python -m venv .venv
. .venv/bin/activate
pip install -r tools/arb_indexer/requirements.txt
python tools/arb_indexer/indexer.py
~~~

The indexer is read-only: it does not sign or send transactions. It stores raw event topics/data and block metadata in SQLite. It requires actual verified contract addresses and the earliest relevant deployment block.

## 6. Start the local dashboard

In a second terminal, load the same ARB_INDEXER_DB value and run:

~~~bash
. .venv/bin/activate
python tools/arb_indexer/dashboard.py
~~~

Open http://127.0.0.1:8080. The dashboard binds only to loopback and reads SQLite in read-only mode. It shows indexed-event counts, the latest stored block and recent raw events. It is a local prototype, not a hosted dashboard or alerting service.

## 7. Evidence checklist

Before describing the demo publicly, retain:
- chain ID and timestamp of each deployment;
- registry, factory and token addresses;
- deployment and seeding transaction hashes;
- verified explorer links and verified source status, if completed;
- Foundry test and CI run links;
- indexer database cursor and sample event records;
- the exact synthetic-demo disclaimer.

## Known limitations

- No deployment has been performed by this runbook or by this PR.
- No contract address or transaction hash is pre-populated.
- The indexer stores raw logs; full ABI decoding and alert delivery are not included.
- The dashboard is local-only and has no authentication because it binds to loopback.
- A passing CI or Sepolia demo is not an independent security audit, regulatory approval or proof of legal title.
