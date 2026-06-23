import http.server
import urllib.parse
import httpx
import os
import threading
from dotenv import load_dotenv

load_dotenv()

CLIENT_ID = os.getenv("LINKEDIN_CLIENT_ID")
CLIENT_SECRET = os.getenv("LINKEDIN_CLIENT_SECRET")
REDIRECT_URI = os.getenv("LINKEDIN_REDIRECT_URI", "http://localhost:8000")

token_received = threading.Event()

class CallbackHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        params = urllib.parse.parse_qs(urllib.parse.urlparse(self.path).query)
        code = params.get("code", [None])[0]
        error = params.get("error", [None])[0]

        if error:
            self.send_response(200)
            self.end_headers()
            self.wfile.write(f"Error: {error}".encode())
            print(f"\n❌ LinkedIn returned error: {error}")
            token_received.set()
            return

        if code:
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"<h2>Authorization successful! You can close this tab.</h2>")
            print(f"\n✅ Got authorization code, exchanging for token...")
            exchange_token(code)
            token_received.set()

    def log_message(self, format, *args):
        pass  # suppress request logs

def exchange_token(code):
    resp = httpx.post("https://www.linkedin.com/oauth/v2/accessToken", data={
        "grant_type": "authorization_code",
        "code": code,
        "redirect_uri": REDIRECT_URI,
        "client_id": CLIENT_ID,
        "client_secret": CLIENT_SECRET,
    })
    if resp.status_code == 200:
        token = resp.json().get("access_token")
        expires = resp.json().get("expires_in")
        env_path = ".env"
        lines = open(env_path).readlines() if os.path.exists(env_path) else []
        with open(env_path, "w") as f:
            found = False
            for line in lines:
                if line.startswith("LINKEDIN_ACCESS_TOKEN"):
                    f.write(f"LINKEDIN_ACCESS_TOKEN={token}\n")
                    found = True
                else:
                    f.write(line)
            if not found:
                f.write(f"LINKEDIN_ACCESS_TOKEN={token}\n")
        print(f"✅ Access token saved to .env (expires in {expires} seconds ~{expires//3600}h)")
    else:
        print(f"❌ Token exchange failed: {resp.text}")

if __name__ == "__main__":
    port = 8000
    server = http.server.HTTPServer(("0.0.0.0", port), CallbackHandler)
    print(f"Waiting for LinkedIn OAuth callback on port {port}...")
    t = threading.Thread(target=server.serve_forever)
    t.daemon = True
    t.start()
    token_received.wait(timeout=300)
    server.shutdown()
    print("Done.")
