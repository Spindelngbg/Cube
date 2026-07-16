import json
import re
import ssl
import urllib.parse
import urllib.request
from http.cookiejar import CookieJar

URL = "https://quaternius.itch.io/universal-base-characters"
OUT = r"C:\Users\Simon\Desktop\assets\downloads\universal-base.zip"

jar = CookieJar()
opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(jar))
headers = {"User-Agent": "Mozilla/5.0"}

html = opener.open(urllib.request.Request(URL, headers=headers), timeout=60).read().decode("utf-8", "replace")
csrf_m = re.search(r'name="csrf_token" value="([^"]+)"', html)
if not csrf_m:
    raise SystemExit("No csrf token")
csrf = csrf_m.group(1)

body = urllib.parse.urlencode({
    "csrf_token": csrf,
    "price": "0",
    "email": "cube@local.dev",
}).encode()
req = urllib.request.Request(
    f"{URL}/purchase",
    data=body,
    headers={**headers, "Content-Type": "application/x-www-form-urlencoded"},
)
try:
    resp = opener.open(req, timeout=60).read().decode("utf-8", "replace")
    print("purchase response:", resp[:1500])
    data = json.loads(resp)
except Exception as exc:
    print("purchase failed:", exc)
    data = {}

download_url = None
if isinstance(data, dict):
    download_url = data.get("url") or data.get("download_url")
    if not download_url and data.get("id"):
        download_url = f"{URL}/file/{data['id']}"

if not download_url:
    for m in re.finditer(r'href="([^"]+/file/\d+[^"]*)"', html):
        download_url = m.group(1)
        if "Standard" in html[max(0, m.start() - 200):m.end() + 200]:
            break

print("download_url:", download_url)
if download_url:
    if download_url.startswith("/"):
        download_url = "https://quaternius.itch.io" + download_url
    content = opener.open(urllib.request.Request(download_url, headers=headers), timeout=300).read()
    with open(OUT, "wb") as f:
        f.write(content)
    print("saved", OUT, len(content))