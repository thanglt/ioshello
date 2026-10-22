"""Local test server for verifying web view request headers.

Usage: python3 -I echo_headers.py <log-file> [port]
Point the app's URL temporarily at http://localhost:<port>/test, open it in the
web view, then read <log-file>. Each request is logged as
`path | AL=<Accept-Language> | UA=<User-Agent>`.

The page exercises: fetch, XMLHttpRequest, a same-window link (/next), a fragment
link (#frag, must NOT reload), navigator.language, and the page back button bridge
(window.ReactNativeWebView.postMessage({"command":"back"})).
"""

import http.server
import sys

LOG = sys.argv[1]
PORT = int(sys.argv[2]) if len(sys.argv) > 2 else 8765

PAGE = """<!DOCTYPE html><html lang="ja"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"></head>
<body style="font-size:22px">
<p id="lang"></p>
<p>日本語: 注文履歴 1,200円 <b>ステータス</b></p>
<p><a href="/next">next page</a> | <a href="#frag">fragment</a></p>
<p><button style="font-size:22px" onclick="ReactNativeWebView.postMessage(JSON.stringify({command: 'back'}))">bridge back</button></p>
<script>
document.getElementById('lang').textContent =
  'navigator: ' + navigator.language + ' / ' + navigator.languages.join(',');
fetch('/api/fetch');
const x = new XMLHttpRequest(); x.open('GET', '/api/xhr'); x.send();
</script>
</body></html>"""


class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        with open(LOG, "a") as f:
            f.write(
                f"{self.path} | AL={self.headers.get('Accept-Language')}"
                f" | UA={self.headers.get('User-Agent', '')}\n"
            )
        body = b"{}" if self.path.startswith("/api") else PAGE.encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *args):
        pass


http.server.HTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
