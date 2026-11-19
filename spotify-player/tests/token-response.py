#!/usr/bin/env python3
"""Exercise the real token helper against a loopback HTTP counterpart in a VM."""
import argparse
from contextlib import contextmanager
import hashlib
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import os
from pathlib import Path
import subprocess
import threading


@contextmanager
def counterpart():
    class Handler(BaseHTTPRequestHandler):
        def do_POST(self):
            self.server.requests.append(self.rfile.read(int(self.headers['Content-Length'])).decode())
            self.send_response(self.server.status)
            self.end_headers()
            self.wfile.write(self.server.body.encode())

        def log_message(self, *args):
            pass

    server = ThreadingHTTPServer(('127.0.0.1', 0), Handler)
    server.requests = []
    thread = threading.Thread(target=server.serve_forever)
    thread.start()
    try:
        yield server
    finally:
        server.shutdown()
        thread.join()
        server.server_close()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--work', type=Path, required=True)
    args = parser.parse_args()
    work = args.work.resolve()
    work.mkdir(exist_ok=False)
    (work / 'tmp').mkdir()
    original = (Path(__file__).resolve().parents[1] / 'Auth.js').read_text()
    endpoint = 'https://accounts.spotify.com/api/token'
    assert original.count(endpoint) == 1
    cases = [('null', 'null', 200, False), ('array', '[]', 200, False),
             ('scalar', '1', 200, False), ('empty', '{}', 200, False),
             ('malformed', '{', 200, False), ('missing-expiry', '{"access_token":"fixture"}', 200, False),
             ('http-error', '{"access_token":"fixture","expires_in":3600}', 400, False),
             ('valid', '{"access_token":"fixture","refresh_token":"refresh","expires_in":3600}', 200, True)]
    rows = []
    with counterpart() as server:
        (work / 'Auth.js').write_text(original.replace(endpoint, 'http://127.0.0.1:' + str(server.server_port) + '/token'))
        for name, body, status, accepted in cases:
            server.body, server.status = body, status
            fixture = '''import QtQml
import "Auth.js" as Auth
QtObject {
  id: root
  property int callbacks: 0
  property var settle: Timer {
    interval: 50
    onTriggered: {
      if (root.callbacks !== 1) { console.error("TOKEN_ASSERT: duplicate callback"); Qt.exit(2); }
      else { console.log("TOKEN_RESPONSE: PASS"); Qt.quit(); }
    }
  }
  property var watchdog: Timer { interval: 2000; running: true; onTriggered: { console.error("TOKEN_ASSERT: callback missing"); Qt.exit(2); } }
  Component.onCompleted: Auth.requestToken("fixture", {grant_type: "authorization_code", code: "test code"}, function(token, error) {
    root.callbacks++;
    if (ACCEPTED ? (!token || token.accessToken !== "fixture" || token.refreshToken !== "refresh" || token.tokenExpiresAt <= Date.now() || error !== null) : (token !== null || error !== "token-response")) {
      console.error("TOKEN_ASSERT: response contract"); Qt.exit(2); return;
    }
    settle.start();
  })
}
'''.replace('ACCEPTED', 'true' if accepted else 'false')
            path = work / (name + '.qml')
            path.write_text(fixture)
            result = subprocess.run(['/usr/lib/qt6/bin/qml', '-a', 'core', str(path)],
                env=dict(os.environ, TMPDIR=str(work / 'tmp'), LC_ALL='C.UTF-8', QT_FORCE_STDERR_LOGGING='1'),
                capture_output=True, text=True, timeout=10)
            log = result.stdout + result.stderr
            (work / (name + '.log')).write_text(log)
            rows.append(dict(case=name, exit=result.returncode, passed=result.returncode == 0 and 'TOKEN_RESPONSE: PASS' in log))
    assert server.requests == ['grant_type=authorization_code&code=test%20code'] * len(cases)
    proof = dict(status='PASS' if all(row['passed'] for row in rows) else 'FAIL', cases=rows,
                 sourceSha256=hashlib.sha256(original.encode()).hexdigest(), counterpart='loopback URL only')
    (work / 'result.json').write_text(json.dumps(proof, indent=2) + '\n')
    print(json.dumps(proof), flush=True)
    assert proof['status'] == 'PASS'


if __name__ == '__main__':
    main()
