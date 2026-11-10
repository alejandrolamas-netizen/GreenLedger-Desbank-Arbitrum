#!/usr/bin/env python3
"""Read-only Arbitrum Sepolia JSON-RPC smoke checks.

This checks observable RPC behavior; it does not identify or attest the node
implementation/version behind an RPC endpoint.
"""
from __future__ import annotations

import argparse
import json
import os
import sys
from urllib.parse import urlsplit
from urllib.request import Request, urlopen
from urllib.error import HTTPError, URLError


class RpcError(RuntimeError):
    pass


def rpc_call(endpoint: str, method: str, params: list, request_id: int):
    payload = json.dumps({
        "jsonrpc": "2.0",
        "id": request_id,
        "method": method,
        "params": params,
    }).encode("utf-8")
    request = Request(
        endpoint,
        data=payload,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urlopen(request, timeout=20) as response:
            body = response.read()
    except HTTPError as exc:
        raise RpcError(f"{method}: HTTP {exc.code}") from exc
    except URLError as exc:
        raise RpcError(f"{method}: transport error ({exc.reason})") from exc

    try:
        decoded = json.loads(body)
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise RpcError(f"{method}: endpoint returned invalid JSON") from exc

    if decoded.get("error") is not None:
        error = decoded["error"]
        raise RpcError(
            f"{method}: JSON-RPC error {error.get('code')}: "
            f"{error.get('message', 'unspecified error')}"
        )
    if "result" not in decoded:
        raise RpcError(f"{method}: JSON-RPC response has no result")
    return decoded["result"]


def quantity(value: str, field: str) -> int:
    if not isinstance(value, str) or not value.startswith("0x"):
        raise RpcError(f"{field}: expected a hex quantity")
    try:
        return int(value, 16)
    except ValueError as exc:
        raise RpcError(f"{field}: invalid hex quantity") from exc


def validate_fee_history(result: dict, block_count: int) -> None:
    if not isinstance(result, dict):
        raise RpcError("eth_feeHistory: result must be an object")
    quantity(result.get("oldestBlock"), "oldestBlock")
    base_fees = result.get("baseFeePerGas")
    gas_ratios = result.get("gasUsedRatio")
    if not isinstance(base_fees, list) or len(base_fees) != block_count + 1:
        raise RpcError("eth_feeHistory: unexpected baseFeePerGas length")
    if not isinstance(gas_ratios, list) or len(gas_ratios) != block_count:
        raise RpcError("eth_feeHistory: unexpected gasUsedRatio length")
    for value in base_fees:
        quantity(value, "baseFeePerGas[]")
    if any(not isinstance(value, (int, float)) or not 0 <= value <= 1
           for value in gas_ratios):
        raise RpcError("eth_feeHistory: gasUsedRatio values must be between 0 and 1")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--rpc-url",
        default=os.environ.get("ARBITRUM_SEPOLIA_RPC_URL"),
        help="RPC endpoint; defaults to ARBITRUM_SEPOLIA_RPC_URL",
    )
    parser.add_argument(
        "--expected-chain-id",
        type=lambda value: int(value, 0),
        default=421614,
        help="Expected chain ID (default: 421614 / Arbitrum Sepolia)",
    )
    args = parser.parse_args()

    if not args.rpc_url:
        parser.error("provide --rpc-url or set ARBITRUM_SEPOLIA_RPC_URL")
    parsed = urlsplit(args.rpc_url)
    if parsed.scheme not in ("http", "https") or not parsed.hostname:
        parser.error("RPC URL must be an http(s) URL")

    try:
        chain_id = quantity(
            rpc_call(args.rpc_url, "eth_chainId", [], 1), "eth_chainId"
        )
        if chain_id != args.expected_chain_id:
            raise RpcError(
                f"chain mismatch: expected {args.expected_chain_id}, received {chain_id}"
            )

        latest_block = quantity(
            rpc_call(args.rpc_url, "eth_blockNumber", [], 2), "eth_blockNumber"
        )

        block_count = 5
        fee_history = rpc_call(
            args.rpc_url,
            "eth_feeHistory",
            [hex(block_count), "latest", [25, 50, 75]],
            3,
        )
        validate_fee_history(fee_history, block_count)

        # Nitro v3.11.4 release notes state that reward percentiles > 100
        # are rejected. This checks the observable RPC validation behavior.
        try:
            rpc_call(
                args.rpc_url,
                "eth_feeHistory",
                [hex(block_count), "latest", [101]],
                4,
            )
        except RpcError:
            percentile_guard = "PASS: percentile 101 rejected"
        else:
            raise RpcError(
                "eth_feeHistory accepted reward percentile 101; "
                "expected an RPC validation error"
            )

        print(json.dumps({
            "status": "PASS",
            "endpoint_host": parsed.hostname,
            "chain_id": chain_id,
            "latest_block": latest_block,
            "fee_history": "PASS",
            "fee_history_percentile_guard": percentile_guard,
            "scope": (
                "RPC behavior only; does not prove the endpoint runs "
                "Arbitrum Nitro v3.11.4"
            ),
        }, indent=2))
        return 0
    except RpcError as exc:
        print(json.dumps({"status": "FAIL", "reason": str(exc)}, indent=2), file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
