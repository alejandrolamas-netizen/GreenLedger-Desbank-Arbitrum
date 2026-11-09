import sqlite3
import tempfile
import unittest
from pathlib import Path
from dashboard import build_dashboard_html

class DashboardTests(unittest.TestCase):
    def test_missing_database_returns_setup_message(self):
        with tempfile.TemporaryDirectory() as tmp:
            page = build_dashboard_html(str(Path(tmp) / "missing.sqlite3"))
        self.assertIn("Database not created", page)
        self.assertIn("Start the indexer", page)

    def test_dashboard_reads_database_and_escapes_values(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "events.sqlite3"
            with sqlite3.connect(path) as db:
                db.executescript("""
                    CREATE TABLE indexer_state(chain_id INTEGER PRIMARY KEY, last_block INTEGER NOT NULL);
                    CREATE TABLE blocks(chain_id INTEGER, block_number INTEGER, block_hash TEXT,
                        parent_hash TEXT, timestamp INTEGER, PRIMARY KEY(chain_id, block_number));
                    CREATE TABLE events(chain_id INTEGER, contract_address TEXT, event_name TEXT,
                        block_number INTEGER, block_hash TEXT, transaction_hash TEXT,
                        transaction_index INTEGER, log_index INTEGER, timestamp INTEGER,
                        topics_json TEXT, data TEXT, removed INTEGER DEFAULT 0,
                        PRIMARY KEY(chain_id, transaction_hash, log_index));
                    INSERT INTO indexer_state VALUES(421614, 123);
                    INSERT INTO blocks VALUES(421614, 123, '0xhash', '0xparent', 1700000000);
                    INSERT INTO events VALUES(421614, '0xabc', '<script>alert(1)</script>',
                        123, '0xhash', '0xtx', 0, 1, 1700000000, '[]', '0x', 0);
                """)
            page = build_dashboard_html(str(path))
        self.assertIn("Chain ID 421614", page)
        self.assertIn("Indexed events", page)
        self.assertIn("&lt;script&gt;", page)
        self.assertNotIn("<script>alert(1)</script>", page)
        self.assertIn("0xtx", page)

if __name__ == "__main__":
    unittest.main()
