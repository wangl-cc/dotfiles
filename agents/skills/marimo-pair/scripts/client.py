"""HTTP client for the managed marimo server; no local marimo install needed."""

import argparse
import json
import math
import os
import posixpath
import sys
from datetime import datetime, timezone
from http.client import HTTPException
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.parse import parse_qs, urlsplit, urlunsplit
from urllib.request import HTTPRedirectHandler, Request, build_opener

DEFAULT_URL = "https://marimo.ws.loongw.cc"


class ClientError(Exception):
    pass


class NoRedirect(HTTPRedirectHandler):
    # Do not resend code or credentials to a redirect destination.
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def target(url, file=None):
    parsed = urlsplit(url)
    if parsed.scheme not in ("http", "https") or not parsed.hostname:
        raise ClientError("Use an absolute http:// or https:// server URL.")
    if parsed.username is not None or parsed.password is not None:
        raise ClientError("URL credentials are unsupported; use MARIMO_TOKEN.")
    # Validate malformed ports before sending a request.
    _ = parsed.port
    query = parse_qs(parsed.query, keep_blank_values=True)
    if "access_token" in query or "token" in query:
        raise ClientError("Remove the URL token and use MARIMO_TOKEN instead.")
    files = query.get("file", [])
    if len(files) > 1 or (files and not files[0]):
        raise ClientError("The notebook URL must contain one nonempty file key.")
    if file is not None and files and file != files[0]:
        raise ClientError("--file conflicts with the notebook URL's file key.")
    base = urlunsplit((parsed.scheme, parsed.netloc, parsed.path.rstrip("/"), "", ""))
    return base, file if file is not None else (files[0] if files else None)


class Client:
    def __init__(self, base, token):
        self.base = base
        self.headers = {"Authorization": f"Bearer {token}"} if token else {}
        self.opener = build_opener(NoRedirect())

    def request(self, endpoint, *, code=None, session=None, timeout=10):
        headers = dict(self.headers)
        data = None
        if code is not None:
            data = json.dumps({"code": code}).encode()
            headers.update(
                {
                    "Content-Type": "application/json",
                    "Accept": "text/event-stream",
                    "Marimo-Session-Id": session,
                }
            )
        return self.opener.open(
            Request(self.base + endpoint, data=data, headers=headers), timeout=timeout
        )

    def sessions(self):
        with self.request("/api/sessions") as response:
            sessions = json.load(response)
        if not isinstance(sessions, dict) or not all(
            isinstance(key, str)
            and isinstance(info, dict)
            and any(name in info for name in ("path", "filename"))
            for key, info in sessions.items()
        ):
            raise ClientError("The server returned an invalid session listing.")
        return sessions

    def discover(self):
        with self.request("/api/version") as response:
            version = response.read().decode().strip()
        return [{"url": self.base, "version": version, "sessions": self.sessions()}]

    def execute(self, code, session, timeout):
        try:
            with self.request(
                "/api/kernel/execute", code=code, session=session, timeout=timeout
            ) as response:
                if response.headers.get_content_type() != "text/event-stream":
                    raise ClientError("Expected an execution event stream from marimo.")
                for event, payload in events(response):
                    if event in ("stdout", "stderr"):
                        stream = sys.stdout if event == "stdout" else sys.stderr
                        stream.write(str(payload.get("data", "")))
                        stream.flush()
                    elif event == "done":
                        success = payload.get("success")
                        if not isinstance(success, bool):
                            raise ClientError(
                                "Execution result has no boolean success field."
                            )
                        if not success:
                            error = payload.get("error")
                            message = (
                                error.get("msg") if isinstance(error, dict) else error
                            )
                            print(
                                message
                                or "Notebook execution failed; see stderr above.",
                                file=sys.stderr,
                            )
                            return 1
                        output = payload.get("output")
                        if isinstance(output, dict) and output.get("data") is not None:
                            print(output["data"])
                        return 0
                    elif event == "error":
                        raise ClientError("The execution stream reported an error.")
                raise ClientError("Execution ended without a done event.")
        except (OSError, HTTPException, ValueError, ClientError) as exc:
            raise ClientError(
                f"{error_text(exc)} Code may already have executed; inspect the notebook before retrying."
            ) from exc


def events(response):
    """Read SSE records, including CRLF and multi-line data fields."""
    event = "message"
    data = []
    for raw in response:
        line = raw.decode("utf-8").rstrip("\r\n")
        if not line:
            if data:
                payload = json.loads("\n".join(data))
                if not isinstance(payload, dict):
                    raise ClientError("Invalid execution event payload.")
                yield event, payload
            event, data = "message", []
        elif not line.startswith(":"):
            field, separator, value = line.partition(":")
            if separator and value.startswith(" "):
                value = value[1:]
            if field == "event":
                event = value
            elif field == "data":
                data.append(value)
    # An unterminated record does not establish successful completion.


def choose_session(sessions, file):
    if not sessions:
        raise ClientError(
            "No active sessions. Open the notebook in the shared server's browser UI."
        )
    candidates = sessions
    if file is not None:
        key = posixpath.normpath(file)

        def matches(info):
            for name in ("path", "filename"):
                path = info.get(name)
                if not isinstance(path, str):
                    continue
                path = posixpath.normpath(path)
                if path == key or (
                    not key.startswith("/") and path.endswith("/" + key)
                ):
                    return True
            return False

        candidates = {sid: info for sid, info in sessions.items() if matches(info)}
    if len(candidates) != 1:
        listing = "\n".join(
            f"  {sid}  {info.get('path') or info.get('filename')}"
            for sid, info in sessions.items()
        )
        reason = (
            "No session matches the notebook"
            if not candidates
            else "Multiple sessions match"
        )
        raise ClientError(
            f"{reason}. Select --file or an exact --session; available sessions:\n{listing}"
        )
    return next(iter(candidates))


def positive_timeout(value):
    number = float(value)
    if not math.isfinite(number) or number <= 0:
        raise argparse.ArgumentTypeError("timeout must be a positive number")
    return number


def error_text(exc):
    if isinstance(exc, HTTPError):
        return f"HTTP {exc.code}: {exc.reason}. Check the server URL, authentication, and session."
    if isinstance(exc, URLError):
        return f"Could not reach marimo: {exc.reason}"
    return str(exc)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("discover", "execute"))
    address = parser.add_mutually_exclusive_group()
    address.add_argument(
        "--url", help="server or notebook browser URL; overrides MARIMO_URL"
    )
    address.add_argument(
        "--port", type=int, help="explicit Pod-local port on 127.0.0.1"
    )
    parser.add_argument("--token", default=os.environ.get("MARIMO_TOKEN", ""))
    selection = parser.add_mutually_exclusive_group()
    selection.add_argument(
        "--file", help="notebook path or unique relative path suffix"
    )
    selection.add_argument("--session", help="exact active session ID")
    parser.add_argument(
        "--timeout",
        type=positive_timeout,
        default=300,
        help="execution socket timeout in seconds (default: 300)",
    )
    parser.add_argument("-c", dest="code", help="inline scratchpad code")
    parser.add_argument(
        "code_file", nargs="?", help="scratchpad code file, or - for stdin"
    )
    args = parser.parse_args()
    if args.port is not None and not 1 <= args.port <= 65535:
        parser.error("--port must be between 1 and 65535")
    if args.code is not None and args.code_file is not None:
        parser.error("choose either -c or a code file")
    try:
        url = args.url or (
            f"http://127.0.0.1:{args.port}"
            if args.port is not None
            else os.environ.get("MARIMO_URL", DEFAULT_URL)
        )
        base, file = target(url, args.file)
        if args.session is not None and file is not None:
            raise ClientError(
                "--session cannot be combined with a notebook file selector."
            )
        client = Client(base, args.token)
        if args.action == "discover":
            print(json.dumps(client.discover(), indent=2))
            return 0
        if args.code is not None:
            code = args.code
        elif args.code_file and args.code_file != "-":
            code = Path(args.code_file).read_text()
        elif not sys.stdin.isatty():
            code = sys.stdin.read()
        else:
            parser.error("provide code using -c, a code file, or stdin")
        if not code.strip():
            raise ClientError("No code supplied.")
        session = (
            args.session
            if args.session is not None
            else choose_session(client.sessions(), file)
        )
        if log := os.environ.get("EXECUTE_CODE_LOG"):
            with open(log, "a") as handle:
                handle.write(datetime.now(timezone.utc).isoformat() + "\n")
        return client.execute(code, session, args.timeout)
    except (OSError, HTTPException, ValueError, ClientError) as exc:
        print(error_text(exc), file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
