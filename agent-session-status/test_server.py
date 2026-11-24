import json
import unittest
from http.client import HTTPConnection
from threading import Thread
from unittest.mock import patch

from server import SessionRequestHandler, SessionServer


TOKEN = "test-token"
HEADERS = {"Authorization": f"Bearer {TOKEN}", "X-Agent": "codex"}
RUNNING = {"id": "task-0", "title": "Retained task", "status": "running"}
COMPLETED = {**RUNNING, "title": "Updated task", "status": "completed"}


class ReportSessionTest(unittest.TestCase):
    def setUp(self):
        self.httpd = SessionServer(("127.0.0.1", 0), SessionRequestHandler, TOKEN)
        self.addCleanup(self.httpd.server_close)
        thread = Thread(target=self.httpd.serve_forever, kwargs={"poll_interval": 0.01})
        thread.start()
        self.addCleanup(thread.join)
        self.addCleanup(self.httpd.shutdown)

    def request(self, method, path, headers=None, body=None):
        client = HTTPConnection(*self.httpd.server_address, timeout=5)
        try:
            client.request(method, path, body=body, headers=headers or {})
            response = client.getresponse()
            self.assertEqual(response.status, 200)
            self.assertEqual(response.getheader("Content-Type"), "application/json")
            return json.load(response)
        finally:
            client.close()

    def tool(self, name, arguments, headers=HEADERS):
        return self.request("POST", "/mcp", headers, json.dumps({
            "jsonrpc": "2.0", "id": 1, "method": "tools/call",
            "params": {"name": name, "arguments": arguments},
        }))

    def test_compact_ack_and_read_paths(self):
        store = self.httpd.store
        for i in range(2000):
            store.upsert("codex", {**RUNNING, "id": f"task-{i}"})
        store.upsert("claude", RUNNING)

        with patch.object(store, "snapshot_for_agent", wraps=store.snapshot_for_agent) as snapshot:
            response = self.tool("report_session", COMPLETED)
        self.assertEqual(len(response["result"]["content"][0]["text"]), len("OK"))
        self.assertEqual(response, {"jsonrpc": "2.0", "id": 1, "result": {
            "content": [{"type": "text", "text": "OK"}], "isError": False,
        }})
        snapshot.assert_not_called()

        caller = json.loads(self.tool("list_sessions", {})["result"]["content"][0]["text"])
        desktop = self.request("GET", "/sessions")
        self.assertEqual([group["agent"] for group in caller["agents"]], ["codex"])
        desktop_groups = {group["agent"]: group for group in desktop["agents"]}
        self.assertEqual(set(desktop_groups), {"claude", "codex"})
        self.assertEqual(caller["agents"][0], desktop_groups["codex"])
        sessions = {session["id"]: session for session in desktop_groups["codex"]["sessions"]}
        self.assertEqual(len(sessions), 2000)
        updated = sessions[COMPLETED["id"]]
        self.assertEqual({key: updated[key] for key in COMPLETED}, COMPLETED)

    def test_rejected_reports_leave_sessions_unchanged(self):
        self.httpd.store.upsert("codex", RUNNING)
        before = self.request("GET", "/sessions")["agents"]
        cases = (
            ({**HEADERS, "Authorization": "Bearer wrong"}, COMPLETED, -32001, "Unauthorized"),
            ({"Authorization": HEADERS["Authorization"]}, COMPLETED, -32602, "X-Agent header is required"),
            (HEADERS, {**COMPLETED, "id": ""}, -32602, "session id is required"),
            (HEADERS, {**COMPLETED, "status": "invalid"}, -32602, "status must be running, completed, or blocked"),
        )
        for headers, arguments, code, message in cases:
            with self.subTest(message=message):
                self.assertEqual(self.tool("report_session", arguments, headers), {
                    "jsonrpc": "2.0", "id": 1, "error": {"code": code, "message": message},
                })
                self.assertEqual(self.request("GET", "/sessions")["agents"], before)


if __name__ == "__main__":
    unittest.main()
