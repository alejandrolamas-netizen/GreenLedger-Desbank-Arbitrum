#!/usr/bin/env python3
"""Read-only, reorg-aware JSON-RPC event indexer for GreenLedger."""
from __future__ import annotations

import json
import logging
import os
import sqlite3
import sys
import time
import urllib.error
import urllib.request
from dataclasses import dataclass
from typing import Any

from eth_hash.auto import keccak

LOG = logging.getLogger("greenledger.indexer")
EVENT_SIGNATURES = {
    "AssetAttested": "AssetAttested(bytes32,bytes32,string,string,uint256,uint256,address)",
    "AssetTokenCreated": "AssetTokenCreated(bytes32,address,address)",
    "AssetTokenized": "AssetTokenized(bytes32,uint256,address)",
}


class IndexerError(RuntimeError):
    pass


@dataclass(frozen=True)
class Config:
    rpc_url: str
    chain_id: int
    start_block: int
    confirmations: int
    chunk_size: int
    database: str
    addresses: tuple[str, ...]
    poll_seconds: int

    @classmethod
    def from_env(cls) -> "Config":
        rpc = os.environ.get("ARB_RPC_URL", "").strip()
        if not rpc:
            raise IndexerError("ARB_RPC_URL is required")
        raw_addresses = os.environ.get("ARB_CONTRACT_ADDRESSES", "")
        addresses = tuple(sorted({a.strip().lower() for a in raw_addresses.split(",") if a.strip()}))
        if not addresses:
            raise IndexerError("ARB_CONTRACT_ADDRESSES must contain at least one deployed contract address")
        for address in addresses:
            if len(address) != 42 or not address.startswith("0x"):
                raise IndexerError(f"Invalid EVM address: {address}")
            try:
                int(address[2:], 16)
            except ValueError as exc:
                raise IndexerError(f"Invalid EVM address: {address}") from exc
        cfg = cls(
            rpc_url=rpc,
            chain_id=int(os.environ.get("ARB_CHAIN_ID", "421614")),
            start_block=int(os.environ.get("ARB_START_BLOCK", "0")),
            confirmations=int(os.environ.get("ARB_CONFIRMATIONS", "12")),
            chunk_size=int(os.environ.get("ARB_CHUNK_SIZE", "500")),
            database=os.environ.get("ARB_INDEXER_DB", "data/arbitrum-events.sqlite3"),
            addresses=addresses,
            poll_seconds=int(os.environ.get("ARB_POLL_SECONDS", "15")),
        )
        if cfg.start_block < 0 or cfg.confirmations < 0 or cfg.chunk_size < 1 or cfg.poll_seconds < 1:
            raise IndexerError("Block, confirmation, chunk and polling settings must be non-negative/positive")
        return cfg


class RpcClient:
    def __init__(self, url: str, timeout: int = 20):
        self.url, self.timeout, self.request_id = url, timeout, 0

    def call(self, method: str, params: list[Any]) -> Any:
        self.request_id += 1
        payload = json.dumps({"jsonrpc": "2.0", "id": self.request_id, "method": method, "params": params}).encode()
        request = urllib.request.Request(self.url, data=payload, headers={"Content-Type": "application/json"})
        try:
            with urllib.request.urlopen(request, timeout=self.timeout) as response:
                body = json.loads(response.read())
        except (urllib.error.URLError, TimeoutError, json.JSONDecodeError) as exc:
            raise IndexerError(f"RPC transport failure for {method}: {exc}") from exc
        if body.get("error"):
            raise IndexerError(f"RPC error for {method}: {body['error']}")
        if "result" not in body:
            raise IndexerError(f"Malformed JSON-RPC response for {method}")
        return body["result"]


class EventIndexer:
    def __init__(self, config: Config, rpc: Any, db: sqlite3.Connection | None = None):
        self.config, self.rpc = config, rpc
        if db is None:
            os.makedirs(os.path.dirname(config.database) or ".", exist_ok=True)
            db = sqlite3.connect(config.database)
        self.db = db
        self.db.row_factory = sqlite3.Row
        self._init_db()
        self.topics = { "0x" + keccak(text=sig).hex(): name for name, sig in EVENT_SIGNATURES.items() }

    def _init_db(self) -> None:
        self.db.executescript("""
        PRAGMA journal_mode=WAL;
        PRAGMA foreign_keys=ON;
        CREATE TABLE IF NOT EXISTS blocks (
          chain_id INTEGER NOT NULL, block_number INTEGER NOT NULL, block_hash TEXT NOT NULL,
          parent_hash TEXT NOT NULL, timestamp INTEGER NOT NULL,
          PRIMARY KEY(chain_id, block_number)
        );
        CREATE TABLE IF NOT EXISTS events (
          chain_id INTEGER NOT NULL, contract_address TEXT NOT NULL, event_name TEXT NOT NULL,
          block_number INTEGER NOT NULL, block_hash TEXT NOT NULL, transaction_hash TEXT NOT NULL,
          transaction_index INTEGER NOT NULL, log_index INTEGER NOT NULL, timestamp INTEGER NOT NULL,
          topics_json TEXT NOT NULL, data TEXT NOT NULL, removed INTEGER NOT NULL DEFAULT 0,
          PRIMARY KEY(chain_id, transaction_hash, log_index)
        );
        CREATE INDEX IF NOT EXISTS events_asset_lookup ON events(chain_id, event_name, block_number);
        CREATE TABLE IF NOT EXISTS indexer_state (
          chain_id INTEGER PRIMARY KEY, last_block INTEGER NOT NULL
        );
        """)
        self.db.commit()

    @staticmethod
    def _hex_int(value: str) -> int:
        return int(value, 16)

    def validate_chain(self) -> None:
        actual = self._hex_int(self.rpc.call("eth_chainId", []))
        if actual != self.config.chain_id:
            raise IndexerError(f"Chain mismatch: configured {self.config.chain_id}, RPC returned {actual}")

    def _header(self, number: int) -> dict[str, Any]:
        result = self.rpc.call("eth_getBlockByNumber", [hex(number), False])
        if not result or not result.get("hash") or not result.get("parentHash"):
            raise IndexerError(f"Missing block header at {number}")
        return result

    def _cursor(self) -> int:
        row = self.db.execute("SELECT last_block FROM indexer_state WHERE chain_id=?", (self.config.chain_id,)).fetchone()
        return int(row["last_block"]) if row else self.config.start_block - 1

    def _recover_reorg(self, cursor: int) -> int:
        if cursor < self.config.start_block:
            return cursor
        row = self.db.execute(
            "SELECT block_hash FROM blocks WHERE chain_id=? AND block_number=?",
            (self.config.chain_id, cursor),
        ).fetchone()
        if not row:
            raise IndexerError("Indexer cursor has no matching stored block checkpoint; manual recovery required")
        canonical = self._header(cursor)["hash"].lower()
        if canonical == row["block_hash"].lower():
            return cursor
        LOG.warning("Reorganization detected at or before indexed block %s", cursor)
        ancestor = cursor - 1
        while ancestor >= self.config.start_block:
            stored = self.db.execute(
                "SELECT block_hash FROM blocks WHERE chain_id=? AND block_number=?",
                (self.config.chain_id, ancestor),
            ).fetchone()
            if stored and self._header(ancestor)["hash"].lower() == stored["block_hash"].lower():
                break
            ancestor -= 1
        if ancestor < self.config.start_block:
            raise IndexerError("No common ancestor found within indexed range; manual re-index required")
        with self.db:
            self.db.execute("DELETE FROM events WHERE chain_id=? AND block_number>?", (self.config.chain_id, ancestor))
            self.db.execute("DELETE FROM blocks WHERE chain_id=? AND block_number>?", (self.config.chain_id, ancestor))
            self.db.execute(
                "INSERT INTO indexer_state(chain_id,last_block) VALUES(?,?) "
                "ON CONFLICT(chain_id) DO UPDATE SET last_block=excluded.last_block",
                (self.config.chain_id, ancestor),
            )
        LOG.warning("Rolled index back to common ancestor %s", ancestor)
        return ancestor

    def _store_range(self, start: int, end: int) -> int:
        logs = self.rpc.call("eth_getLogs", [{
            "fromBlock": hex(start), "toBlock": hex(end),
            "address": list(self.config.addresses),
            "topics": [list(self.topics.keys())],
        }])
        headers = {}
        for number in range(start, end + 1):
            header = self._header(number)
            if number > start and header["parentHash"].lower() != headers[number - 1]["hash"].lower():
                raise IndexerError(f"Non-contiguous canonical headers at block {number}; retry the range")
            headers[number] = header
        if start > self.config.start_block:
            previous = self.db.execute(
                "SELECT block_hash FROM blocks WHERE chain_id=? AND block_number=?",
                (self.config.chain_id, start - 1),
            ).fetchone()
            if previous and headers[start]["parentHash"].lower() != previous["block_hash"].lower():
                raise IndexerError(f"Parent hash mismatch at block {start}; reorg recovery is required")
        with self.db:
            for number, header in headers.items():
                self.db.execute(
                    "INSERT OR REPLACE INTO blocks(chain_id,block_number,block_hash,parent_hash,timestamp) VALUES(?,?,?,?,?)",
                    (self.config.chain_id, number, header["hash"].lower(), header["parentHash"].lower(), self._hex_int(header["timestamp"])),
                )
            for log in logs:
                number = self._hex_int(log["blockNumber"])
                if number not in headers:
                    raise IndexerError("RPC returned a log outside the requested block range")
                header = headers[number]
                if log.get("blockHash", "").lower() != header["hash"].lower():
                    raise IndexerError(f"Log/header block hash mismatch at block {number}; retry the range")
                topics = log.get("topics", [])
                if not topics:
                    continue
                event_name = self.topics.get(topics[0].lower(), "Unknown")
                self.db.execute(
                    """INSERT OR IGNORE INTO events
                    (chain_id,contract_address,event_name,block_number,block_hash,transaction_hash,
                     transaction_index,log_index,timestamp,topics_json,data)
                    VALUES(?,?,?,?,?,?,?,?,?,?,?)""",
                    (self.config.chain_id, log["address"].lower(), event_name, number,
                     header["hash"].lower(), log["transactionHash"].lower(),
                     self._hex_int(log["transactionIndex"]), self._hex_int(log["logIndex"]),
                     self._hex_int(header["timestamp"]), json.dumps(topics), log.get("data", "0x")),
                )
            self.db.execute(
                "INSERT INTO indexer_state(chain_id,last_block) VALUES(?,?) "
                "ON CONFLICT(chain_id) DO UPDATE SET last_block=excluded.last_block",
                (self.config.chain_id, end),
            )
        return len(logs)

    def run_once(self) -> dict[str, int]:
        self.validate_chain()
        latest = self._hex_int(self.rpc.call("eth_blockNumber", []))
        safe_head = latest - self.config.confirmations
        cursor = self._recover_reorg(self._cursor())
        if safe_head <= cursor:
            return {"latest": latest, "safe_head": safe_head, "indexed_to": cursor, "logs_seen": 0}
        total = 0
        start = max(cursor + 1, self.config.start_block)
        while start <= safe_head:
            end = min(start + self.config.chunk_size - 1, safe_head)
            total += self._store_range(start, end)
            start = end + 1
        return {"latest": latest, "safe_head": safe_head, "indexed_to": self._cursor(), "logs_seen": total}


def main() -> int:
    logging.basicConfig(level=os.environ.get("LOG_LEVEL", "INFO"), format="%(asctime)s %(levelname)s %(message)s")
    try:
        cfg = Config.from_env()
        rpc = RpcClient(cfg.rpc_url)
        indexer = EventIndexer(cfg, rpc)
        while True:
            try:
                LOG.info("Indexer cycle: %s", indexer.run_once())
            except IndexerError:
                LOG.exception("Indexer cycle failed; cursor retained for safe retry")
            time.sleep(cfg.poll_seconds)
    except (IndexerError, ValueError) as exc:
        LOG.error("%s", exc)
        return 2


if __name__ == "__main__":
    sys.exit(main())
