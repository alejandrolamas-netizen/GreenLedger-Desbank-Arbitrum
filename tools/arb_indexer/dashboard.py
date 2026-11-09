#!/usr/bin/env python3
"""Local, read-only dashboard for the GreenLedger SQLite event indexer."""
from __future__ import annotations
import html
import os
import sqlite3
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

def _utc(timestamp: int) -> str:
    return datetime.fromtimestamp(timestamp, tz=timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")

def _page(status: str, detail: str, event_count: int, latest_block: int, events: list[dict]) -> str:
    rows = "".join(
        "<tr>"
        f"<td>{html.escape(str(e['block']))}</td>"
        f"<td>{html.escape(str(e['name']))}</td>"
        f"<td><code>{html.escape(str(e['address']))}</code></td>"
        f"<td><code>{html.escape(str(e['tx']))}</code></td>"
        f"<td>{html.escape(str(e['log_index']))}</td>"
        f"<td>{html.escape(str(e['time']))}</td>"
        "</tr>" for e in events
    ) or '<tr><td colspan="6">No indexed events yet.</td></tr>'
    return f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>GreenLedger · Local Event Monitor</title>
<style>
:root {{ color-scheme: dark; font-family: Inter, system-ui, sans-serif; }}
body {{ margin: 0; padding: 2rem; background: #0b1220; color: #e6edf7; }}
main {{ max-width: 1200px; margin: auto; }}
p, small {{ color: #9aabc2; }}
.cards {{ display: flex; gap: 1rem; flex-wrap: wrap; margin: 1.5rem 0; }}
.card {{ background: #131e30; border: 1px solid #2a3a52; border-radius: 12px; padding: 1rem; min-width: 180px; }}
.value {{ font-size: 1.6rem; font-weight: 700; }}
.status {{ border-left: 3px solid #3b82f6; padding: .5rem 1rem; background: #111d30; }}
.table-wrap {{ overflow-x: auto; border: 1px solid #2a3a52; border-radius: 12px; }}
table {{ width: 100%; border-collapse: collapse; font-size: .88rem; }}
th, td {{ text-align: left; padding: .75rem; border-bottom: 1px solid #26364c; }}
th {{ color: #9aabc2; background: #131e30; }}
code {{ font-size: .8rem; overflow-wrap: anywhere; }}
footer {{ margin-top: 1.5rem; color: #8091a9; font-size: .8rem; }}
</style></head><body><main>
<h1>GreenLedger</h1><p>Local, read-only Arbitrum event monitor</p>
<div class="status"><strong>{html.escape(status)}</strong><br>{html.escape(detail)}</div>
<section class="cards">
<div class="card"><small>Indexed events</small><div class="value">{event_count}</div></div>
<div class="card"><small>Latest stored block</small><div class="value">{latest_block}</div></div>
<div class="card"><small>Mode</small><div class="value">Read-only</div></div>
</section><h2>Recent events</h2>
<div class="table-wrap"><table><thead><tr><th>Block</th><th>Event</th><th>Contract</th><th>Transaction</th><th>Log index</th><th>Timestamp</th></tr></thead>
<tbody>{rows}</tbody></table></div>
<footer>Local prototype. Raw event metadata only; no ABI decoding, legal-title verification, alert delivery or hosted-service guarantee.</footer>
</main></body></html>"""

def build_dashboard_html(database: str) -> str:
    path = Path(database)
    if not path.exists():
        return _page("Database not created", "Start the indexer and refresh this page.", 0, 0, [])
    try:
        with sqlite3.connect(path.resolve().as_uri() + "?mode=ro", uri=True, timeout=2) as db:
            state = db.execute("SELECT chain_id, last_block FROM indexer_state ORDER BY chain_id LIMIT 1").fetchone()
            count = db.execute("SELECT COUNT(*) FROM events").fetchone()[0]
            latest = db.execute("SELECT COALESCE(MAX(block_number), 0) FROM blocks").fetchone()[0]
            result = db.execute("""SELECT event_name, contract_address, block_number, transaction_hash,
                log_index, timestamp FROM events
                ORDER BY block_number DESC, transaction_index DESC, log_index DESC LIMIT 50""").fetchall()
    except sqlite3.Error as exc:
        return _page("Database unavailable", f"SQLite read failed: {exc}", 0, 0, [])
    chain_id, cursor = state if state else (0, 0)
    events = [{"name": r[0], "address": r[1], "block": r[2], "tx": r[3],
               "log_index": r[4], "time": _utc(r[5])} for r in result]
    return _page(f"Chain ID {chain_id}" if chain_id else "Waiting for indexer",
                 f"Latest stored block: {latest}; indexer cursor: {cursor}",
                 int(count), int(latest), events)

class DashboardHandler(BaseHTTPRequestHandler):
    database = "data/arbitrum-events.sqlite3"
    def do_GET(self) -> None:
        if self.path != "/":
            self.send_error(404)
            return
        body = build_dashboard_html(self.database).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)
    def log_message(self, fmt: str, *args: object) -> None:
        print("dashboard:", fmt % args)

def main() -> None:
    host = os.environ.get("DASHBOARD_HOST", "127.0.0.1")
    if host != "127.0.0.1":
        raise SystemExit("For safety, the dashboard only binds to 127.0.0.1")
    port = int(os.environ.get("DASHBOARD_PORT", "8080"))
    DashboardHandler.database = os.environ.get("ARB_INDEXER_DB", "data/arbitrum-events.sqlite3")
    server = ThreadingHTTPServer((host, port), DashboardHandler)
    print(f"GreenLedger local dashboard: http://{host}:{port}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("Stopping dashboard")
    finally:
        server.server_close()

if __name__ == "__main__":
    main()
