import json
import os
import re
import shutil
import urllib.request
import zipfile

GAME_ID = 3822259
ZIP_OUT = r"C:\Users\Simon\Desktop\assets\downloads\universal-base.zip"
EXTRACT_DIR = r"C:\Users\Simon\Desktop\assets\downloads\universal-base"
DEST_DIR = r"C:\Users\Simon\Cube\assets\models\characters\quaternius-universal"

headers = {"User-Agent": "Mozilla/5.0"}


def try_api_download() -> bool:
    for url in [
        f"https://itch.io/api/1/game/{GAME_ID}/uploads",
        f"https://quaternius.itch.io/api/1/game/{GAME_ID}/uploads",
    ]:
        try:
            raw = urllib.request.urlopen(
                urllib.request.Request(url, headers=headers), timeout=60
            ).read().decode("utf-8", "replace")
            print("api", url, raw[:500])
            data = json.loads(raw)
            uploads = data.get("uploads") or data
            if isinstance(uploads, list):
                for upload in uploads:
                    name = str(upload.get("filename", ""))
                    if "Standard" in name or name.endswith(".zip"):
                        file_id = upload.get("id")
                        if file_id:
                            dl = f"https://quaternius.itch.io/universal-base-characters/file/{file_id}"
                            print("try", dl)
                            content = urllib.request.urlopen(
                                urllib.request.Request(dl, headers=headers), timeout=300
                            ).read()
                            if content[:2] == b"PK":
                                with open(ZIP_OUT, "wb") as f:
                                    f.write(content)
                                print("saved zip", len(content))
                                return True
        except Exception as exc:
            print("api fail", url, exc)
    return False


def find_model_file(root: str):
    preferred = []
    for dirpath, _, files in os.walk(root):
        for fname in files:
            lower = fname.lower()
            if not lower.endswith((".gltf", ".glb", ".fbx")):
                continue
            full = os.path.join(dirpath, fname)
            score = 0
            if "superhero_male_fullbody" in lower:
                score += 20
            elif "regular_male" in lower:
                score += 18
            elif "male" in lower and "fullbody" in lower:
                score += 14
            elif "male" in lower and "eyebrow" not in lower and "hair" not in lower:
                score += 6
            if "godot" in dirpath.lower():
                score += 4
            if lower.endswith(".gltf"):
                score += 2
            preferred.append((score, full))
    if not preferred:
        return None
    preferred.sort(reverse=True)
    return preferred[0][1]


def install_model(src: str) -> None:
    os.makedirs(DEST_DIR, exist_ok=True)
    ext = os.path.splitext(src)[1].lower()
    dest_name = os.path.basename(src)
    dest = os.path.join(DEST_DIR, dest_name)
    shutil.copy2(src, dest)
    base = os.path.splitext(src)[0]
    for suffix in [".bin", "_0.png", ".png", ".jpg", ".jpeg"]:
        extra = base + suffix
        if os.path.isfile(extra):
            shutil.copy2(extra, os.path.join(DEST_DIR, os.path.basename(extra)))
    print("installed", dest)


def main() -> None:
    if not os.path.isfile(ZIP_OUT):
        try_api_download()

    if os.path.isfile(ZIP_OUT):
        if os.path.isdir(EXTRACT_DIR):
            shutil.rmtree(EXTRACT_DIR)
        os.makedirs(EXTRACT_DIR, exist_ok=True)
        with zipfile.ZipFile(ZIP_OUT, "r") as zf:
            zf.extractall(EXTRACT_DIR)
        model = find_model_file(EXTRACT_DIR)
        if model:
            install_model(model)
            return

    raise SystemExit(
        "Universal Base not downloaded. Place Universal Base Characters[Standard].zip at "
        + ZIP_OUT
    )


if __name__ == "__main__":
    main()