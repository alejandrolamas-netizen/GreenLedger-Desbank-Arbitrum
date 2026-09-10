# GreenLedger-Desbank-Arbitrum

Arbitrum adaptation of the GreenLedger / Desbank asset-tokenization stack.

## Scope

- **Arbitrum One:** chain ID `42161`
- **Arbitrum Sepolia:** chain ID `421614`
- Explorer: Arbiscan
- ERC-20 real-estate representation with AI attestation gating
- Deterministic supply invariant: **1 token = 1 registered sqft** (18 decimals)
- Public verification flow for attestation, token creation and supply invariant

## Architecture

`AIAttestationRegistry` → `GreenLedgerFactory` → `RealEstateToken`

The factory only accepts the registry it was deployed with. The token can only be tokenized by its owner after a matching AI attestation exists. Ownership is transferred from the factory-created token to the original caller so the caller can execute tokenization.

## Demo asset

`GL-BUE-001` / 50,000 sqft / valuation `48,500,000 USD` represented with 18-decimal accounting.

The demo scripts are deployment tooling; **this repository does not claim that contracts are deployed on Arbitrum until real transaction hashes and verified contract addresses are recorded.**

## Quick start

```bash
cp .env.example .env
forge install OpenZeppelin/openzeppelin-contracts --no-commit
forge install foundry-rs/forge-std --no-commit
forge build
forge test -vv
```

For Arbitrum Sepolia, configure `ARBITRUM_SEPOLIA_RPC_URL`, `PRIVATE_KEY` and `ARBISCAN_API_KEY`, then:

```bash
make deploy-sepolia
```

After deployment, set `ATTESTATION_ADDRESS` and `FACTORY_ADDRESS` and run the seed script as needed.

## Separation rule

This repository is independent from the XRPL original and the Base/Ethereum implementation. Arbitrum changes must not modify those source lines.
