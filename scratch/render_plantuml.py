import zlib
import urllib.request
from pathlib import Path

puml_path = Path("diagram/project-erd.puml")
if not puml_path.exists():
    raise FileNotFoundError(puml_path)

text = puml_path.read_bytes()
compressed = zlib.compress(text)[2:-4]
alphabet = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-_"
encoded = []
for i in range(0, len(compressed), 3):
    chunk = compressed[i : i + 3]
    b = 0
    for j, v in enumerate(chunk):
        b |= v << (16 - 8 * j)
    if len(chunk) == 3:
        encoded.extend(
            [
                alphabet[(b >> 18) & 0x3F],
                alphabet[(b >> 12) & 0x3F],
                alphabet[(b >> 6) & 0x3F],
                alphabet[b & 0x3F],
            ]
        )
    elif len(chunk) == 2:
        encoded.extend(
            [
                alphabet[(b >> 18) & 0x3F],
                alphabet[(b >> 12) & 0x3F],
                alphabet[(b >> 6) & 0x3F],
            ]
        )
    elif len(chunk) == 1:
        encoded.extend(
            [
                alphabet[(b >> 18) & 0x3F],
                alphabet[(b >> 12) & 0x3F],
            ]
        )
encoded_str = "".join(encoded)
url = f"https://www.plantuml.com/plantuml/png/{encoded_str}"
req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
with urllib.request.urlopen(req, timeout=30) as resp:
    data = resp.read()
    output = Path("diagram/project-erd.png")
    output.write_bytes(data)
    print(f"wrote {output} ({len(data)} bytes)")
