import sqlite3
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from indexer import Config, EventIndexer, IndexerError, EVENT_SIGNATURES
from eth_hash.auto import keccak


class FakeRpc:
    def __init__(self, chain_id=421614, latest=4):
        self.chain_id = chain_id
        self.latest = latest
        self.hashes = {n: f"0x{n:064x}" for n in range(0, 20)}
        self.logs = []

    def call(self, method, params):
        if method == "eth_chainId":
            return hex(self.chain_id)
        if method == "eth_blockNumber":
            return hex(self.latest)
        if method == "eth_getBlockByNumber":
            n = int(params[0], 16)
            return {"number": hex(n), "hash": self.hashes[n],
                    "parentHash": self.hashes.get(n - 1, "0x" + "00" * 32),
                    "timestamp": hex(1_700_000_000 + n)}
        if method == "eth_getLogs":
            f = int(params[0]["fromBlock"], 16)
            t = int(params[0]["toBlock"], 16)
            return [x for x in self.logs if f <= int(x["blockNumber"], 16) <= t]
        raise AssertionError(method)


def make_config():
    return Config("http://rpc.invalid", 421614, 1, 0, 2, ":memory:",
                  ("0x" + "11" * 20,), 1)


def make_log(rpc, block=2, event_name="AssetTokenCreated", log_index=0):
    topic = "0x" + keccak(EVENT_SIGNATURES[event_name].encode("utf-8")).hex()
    return {
        "address": "0x" + "11" * 20,
        "blockNumber": hex(block), "blockHash": rpc.hashes[block],
        "transactionHash": "0x" + f"{log_index + 171:064x}",
        "transactionIndex": "0x0", "logIndex": hex(log_index),
        "topics": [topic], "data": "0x",
    }


class IndexerTests(unittest.TestCase):
    def setUp(self):
        self.rpc = FakeRpc()
        self.db = sqlite3.connect(":memory:")
        self.indexer = EventIndexer(make_config(), self.rpc, self.db)

    def test_chain_mismatch_fails_closed(self):
        self.rpc.chain_id = 42161
        with self.assertRaises(IndexerError):
            self.indexer.run_once()

    def test_indexes_and_repeated_cycle_is_idempotent(self):
        self.rpc.logs = [make_log(self.rpc)]
        first = self.indexer.run_once()
        self.assertEqual(first["indexed_to"], 4)
        count1 = self.db.execute("SELECT COUNT(*) FROM events").fetchone()[0]
        second = self.indexer.run_once()
        count2 = self.db.execute("SELECT COUNT(*) FROM events").fetchone()[0]
        self.assertEqual(count1, 1)
        self.assertEqual(count2, 1)
        self.assertEqual(second["logs_seen"], 0)

    def test_indexes_registry_governance_events(self):
        event_names = [
            "AttestorAuthorizationChanged",
            "AttestationRevoked",
            "TokenizationPauseChanged",
        ]
        self.rpc.logs = [
            make_log(self.rpc, event_name=name, log_index=index)
            for index, name in enumerate(event_names)
        ]
        result = self.indexer.run_once()
        self.assertEqual(result["logs_seen"], 3)
        stored = {
            row[0] for row in self.db.execute("SELECT event_name FROM events").fetchall()
        }
        self.assertEqual(stored, set(event_names))

    def test_reorg_rolls_back_to_common_ancestor(self):
        self.rpc.logs = [make_log(self.rpc)]
        self.indexer.run_once()
        old_hash = self.rpc.hashes[4]
        self.rpc.hashes[4] = "0x" + "ff" * 32
        self.rpc.hashes[3] = "0x" + "ee" * 32
        self.rpc.hashes[2] = "0x" + "dd" * 32
        self.rpc.latest = 4
        self.rpc.logs = []
        result = self.indexer.run_once()
        self.assertEqual(result["indexed_to"], 4)
        self.assertNotEqual(old_hash, self.rpc.hashes[4])
        self.assertEqual(self.db.execute("SELECT COUNT(*) FROM events").fetchone()[0], 0)

    def test_provider_error_does_not_advance_cursor(self):
        class Broken(FakeRpc):
            def call(self, method, params):
                if method == "eth_getLogs":
                    raise IndexerError("provider unavailable")
                return super().call(method, params)
        broken = Broken()
        indexer = EventIndexer(make_config(), broken, sqlite3.connect(":memory:"))
        with self.assertRaises(IndexerError):
            indexer.run_once()
        self.assertEqual(indexer._cursor(), 0)


if __name__ == "__main__":
    unittest.main()
