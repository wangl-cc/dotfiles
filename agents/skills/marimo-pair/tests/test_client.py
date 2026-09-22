"""Exercise the CLI against an isolated HTTP server; never run notebook code."""

import http.server
import json
import os
import socket
import subprocess
import tempfile
import threading
import time
import unittest
from pathlib import Path

SCRIPTS = Path(__file__).resolve().parents[1] / "scripts"
DONE = b'event: done\ndata: {"success":true,"output":{"data":"42"}}\n\n'
SESSIONS = {
    "alpha": {
        "path": "/home/test/Documents/ecDNA/notebooks/example.py",
        "filename": "example.py",
    },
    "beta": {
        "path": "/home/test/Documents/other/notebooks/example.py",
        "filename": "example.py",
    },
}


class ClientTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        class Handler(http.server.BaseHTTPRequestHandler):
            def log_message(self, *args):
                pass

            def respond(self, status, body, content_type="application/json"):
                self.send_response(status)
                self.send_header("Content-Type", content_type)
                self.send_header("Content-Length", str(len(body)))
                if status == 302:
                    self.send_header("Location", "/redirect-target")
                self.end_headers()
                try:
                    self.wfile.write(body)
                except BrokenPipeError:
                    pass

            def do_GET(self):
                cls.calls.append(("GET", self.path, dict(self.headers), None))
                if self.path.endswith("/api/sessions"):
                    self.respond(cls.get_status, json.dumps(cls.sessions).encode())
                elif self.path.endswith("/api/version"):
                    self.respond(200, b"0.24.0", "text/plain")
                else:
                    self.respond(404, b"{}")

            def do_POST(self):
                body = self.rfile.read(int(self.headers.get("Content-Length", 0)))
                cls.calls.append(
                    ("POST", self.path, dict(self.headers), json.loads(body))
                )
                time.sleep(cls.delay)
                self.respond(cls.post_status, cls.body, cls.content_type)

        cls.server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), Handler)
        cls.thread = threading.Thread(target=cls.server.serve_forever, daemon=True)
        cls.thread.start()
        cls.url = f"http://127.0.0.1:{cls.server.server_port}"

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
        cls.server.server_close()
        cls.thread.join()

    def setUp(self):
        cls = type(self)
        cls.calls = []
        cls.sessions = SESSIONS
        cls.get_status = 200
        cls.post_status = 200
        cls.content_type = "text/event-stream"
        cls.body = DONE
        cls.delay = 0

    def run_client(self, *args, action="execute", code="1 + 1", env=None):
        script = "execute-code.sh" if action == "execute" else "discover-servers.sh"
        environment = dict(
            os.environ, MARIMO_URL=self.url, MARIMO_TOKEN="", EXECUTE_CODE_LOG=""
        )
        environment.update(env or {})
        return subprocess.run(
            ["bash", str(SCRIPTS / script), *args],
            input=code,
            capture_output=True,
            text=True,
            env=environment,
            timeout=5,
            check=False,
        )

    def posts(self):
        return [call for call in self.calls if call[0] == "POST"]

    def test_file_selects_one_kernel_and_preserves_code(self):
        code = "print('quotes $ ` \\ and 中文')\n"
        result = self.run_client("--file", "ecDNA/notebooks/example.py", code=code)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "42\n")
        self.assertEqual(self.posts()[0][2]["Marimo-Session-Id"], "alpha")
        self.assertEqual(self.posts()[0][3], {"code": code})

    def test_browser_url_decodes_file_and_preserves_proxy_prefix(self):
        result = self.run_client(
            "--url", self.url + "/marimo/?file=ecDNA%2Fnotebooks%2Fexample.py#cell"
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            [c[1] for c in self.calls],
            ["/marimo/api/sessions", "/marimo/api/kernel/execute"],
        )

    def test_ambiguous_or_missing_file_never_executes(self):
        for file in (None, "example.py", "missing.py"):
            with self.subTest(file=file):
                result = self.run_client(*(["--file", file] if file else []))
                self.assertNotEqual(result.returncode, 0)
                self.assertFalse(self.posts())

    def test_conflicting_selectors_never_connect(self):
        result = self.run_client(
            "--url", self.url + "/?file=example.py", "--session", "alpha"
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.calls)

    def test_no_active_session_never_executes(self):
        type(self).sessions = {}
        result = self.run_client()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Open the notebook", result.stderr)
        self.assertFalse(self.posts())

    def test_single_session_and_code_file(self):
        type(self).sessions = {"alpha": SESSIONS["alpha"]}
        with tempfile.TemporaryDirectory() as tmp:
            script = Path(tmp) / "code.py"
            script.write_text("print('from file')")
            result = self.run_client(str(script))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.posts()[0][3]["code"], "print('from file')")

    def test_http_and_protocol_failures_never_succeed_or_retry(self):
        for status, mime, body in (
            (404, "application/json", b'{"detail":"Unknown session"}'),
            (200, "text/html", b"<html>Login</html>"),
            (200, "text/event-stream", b'event: stdout\ndata: {"data":"partial"}\n\n'),
            (200, "text/event-stream", b'event: done\ndata: {"success":true}'),
            (200, "text/event-stream", b'event: done\ndata: {"success":"true"}\n\n'),
            (200, "text/event-stream", b"event: done\ndata: nope\n\n"),
        ):
            with self.subTest(status=status, body=body):
                cls = type(self)
                cls.calls, cls.post_status, cls.content_type, cls.body = (
                    [],
                    status,
                    mime,
                    body,
                )
                result = self.run_client("--session", "alpha")
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(len(self.posts()), 1)
                self.assertIn("may already have executed", result.stderr)

    def test_failed_execution_reports_stderr(self):
        type(
            self
        ).body = b'event: stderr\ndata: {"data":"bad code"}\n\nevent: done\ndata: {"success":false}\n\n'
        result = self.run_client("--session", "alpha")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("bad code", result.stderr)

    def test_crlf_multiline_events(self):
        type(
            self
        ).body = b': heartbeat\r\n\r\nevent: stdout\r\ndata: {"data":"hello"}\r\n\r\nevent: done\r\ndata: {"success":true,\r\ndata: "output":{"data":"42"}}\r\n\r\n'
        result = self.run_client("--session", "alpha", "-c", "42")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout, "hello42\n")

    def test_redirect_does_not_forward_code(self):
        type(self).post_status = 302
        result = self.run_client("--session", "alpha")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(len(self.calls), 1)

    def test_auth_and_explicit_url_override(self):
        result = self.run_client(
            "--url",
            self.url,
            "--file",
            SESSIONS["alpha"]["path"],
            env={"MARIMO_URL": "http://127.0.0.1:1", "MARIMO_TOKEN": "fixture-token"},
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(
            all(c[2]["Authorization"] == "Bearer fixture-token" for c in self.calls)
        )

    def test_discovery_leaves_foreign_registry_untouched(self):
        with tempfile.TemporaryDirectory() as tmp:
            registry = Path(tmp) / "marimo/servers/server.json"
            registry.parent.mkdir(parents=True)
            registry.write_text('{"pid":2147483647}')
            result = self.run_client(action="discover", env={"XDG_STATE_HOME": tmp})
            self.assertEqual(registry.read_text(), '{"pid":2147483647}')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout)[0]["sessions"], SESSIONS)
        self.assertFalse(self.posts())

    def test_connection_failure_is_nonzero(self):
        with socket.socket() as sock:
            sock.bind(("127.0.0.1", 0))
            result = self.run_client(
                "--url",
                f"http://127.0.0.1:{sock.getsockname()[1]}",
                "--session",
                "alpha",
            )
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.posts())

    def test_timeout_fails_without_retry(self):
        type(self).delay = 0.15
        result = self.run_client("--session", "alpha", "--timeout", "0.03")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("before retrying", result.stderr)
        self.assertEqual(len(self.posts()), 1)
        time.sleep(0.2)


if __name__ == "__main__":
    unittest.main()
