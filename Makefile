.PHONY: build test deploy-sepolia verify-sepolia

build:
	forge build

test:
	forge test -vv

deploy-sepolia:
	forge script script/Deploy.s.sol:DeployScript --rpc-url $(ARBITRUM_SEPOLIA_RPC_URL) --broadcast --verify

verify-sepolia:
	forge script script/VerifyPublicly.s.sol:VerifyPubliclyScript --rpc-url $(ARBITRUM_SEPOLIA_RPC_URL)
