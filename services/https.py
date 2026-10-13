"""Tiny HTTPS endpoint for LAN tests; no external Python dependencies."""
import http.server
import ssl
import sys

class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        body = (sys.argv[4] + '\n').encode()
        self.send_response(200)
        self.send_header('Content-Type', 'text/plain; charset=utf-8')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

server = http.server.ThreadingHTTPServer((sys.argv[1], 443), Handler)
context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
context.minimum_version = ssl.TLSVersion.TLSv1_2
context.load_cert_chain(sys.argv[2], sys.argv[3])
server.socket = context.wrap_socket(server.socket, server_side=True)
server.serve_forever()
