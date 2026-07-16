import re
import urllib.request

for page in [
    "https://quaternius.itch.io/universal-base-characters",
    "https://quaternius.com/packs/universalbasecharacters.html",
]:
    html = urllib.request.urlopen(page, timeout=60).read().decode("utf-8", "replace")
    print("PAGE", page)
    print("DRIVE", sorted(set(re.findall(r"https://drive\\.google\\.com[^\"']+", html))))

for pat in [r'data-upload_id="(\d+)"', r"/file/(\d+)", r"uploads/(\d+)"]:
    print(pat, sorted(set(re.findall(pat, html))))

for name in ["Standard", "glTF", "Regular", "Male", "FBX"]:
    idx = html.find(name)
    if idx >= 0:
        print(name, "...", html[max(0, idx - 80): idx + 120].replace("\n", " "))