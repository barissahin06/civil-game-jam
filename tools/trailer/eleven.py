"""ElevenLabs yardımcısı (yalnız stdlib). Anahtar .env dosyasından okunur ve yazdırılmaz.

.env, repo kökünde ya da üst klasörlerinde aranır (worktree'den ana depoya kadar).

Kullanım:
  python tools/trailer/eleven.py voices [dil]
  python tools/trailer/eleven.py tts <voice_id> <metin_dosyası> <çıktı.mp3> [model]
  python tools/trailer/eleven.py music <istem_dosyası> <çıktı.mp3> <süre_ms>
  python tools/trailer/eleven.py sfx <istem> <çıktı.mp3> <süre_sn>
"""

import json
import sys
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
API = "https://api.elevenlabs.io"


def key() -> str:
    for folder in (ROOT, *ROOT.parents):
        env = folder / ".env"
        if env.is_file():
            for line in env.read_text(encoding="utf-8").splitlines():
                line = line.strip()
                if line.startswith("ELEVENLABS_API_KEY="):
                    return line.split("=", 1)[1].strip().strip('"')
                if line.startswith("sk_"):  # yalnız anahtar yapıştırılmış dosya
                    return line
    raise SystemExit(".env içinde ELEVENLABS_API_KEY yok")


def call(path: str, body: dict | None = None, raw: bool = False):
    request = urllib.request.Request(
        API + path,
        data=None if body is None else json.dumps(body).encode(),
        headers={"xi-api-key": key(), "Content-Type": "application/json"},
    )
    try:
        with urllib.request.urlopen(request, timeout=300) as response:
            data = response.read()
    except urllib.error.HTTPError as error:
        raise SystemExit(f"HTTP {error.code}: {error.read().decode()[:600]}")
    return data if raw else json.loads(data)


def main(argv: list[str]) -> None:
    command = argv[0]
    if command == "voices":
        language = argv[1] if len(argv) > 1 else "tr"
        found = call(
            f"/v1/shared-voices?page_size=30&language={language}&sort=usage_character_count_7d"
        )
        for voice in found["voices"]:
            print(
                voice["voice_id"],
                "|",
                voice["name"],
                "|",
                voice.get("gender"),
                "|",
                voice.get("descriptive") or voice.get("use_case"),
                "|",
                voice.get("age"),
            )
    elif command == "tts":
        voice, text_file, out = argv[1:4]
        model = argv[4] if len(argv) > 4 else "eleven_multilingual_v2"
        body = {
            "text": Path(text_file).read_text(encoding="utf-8").strip(),
            "model_id": model,
            "voice_settings": {"stability": 0.45, "similarity_boost": 0.8, "style": 0.35},
        }
        Path(out).write_bytes(
            call(f"/v1/text-to-speech/{voice}?output_format=mp3_44100_128", body, raw=True)
        )
    elif command == "music":
        prompt_file, out, length = argv[1:4]
        body = {
            "prompt": Path(prompt_file).read_text(encoding="utf-8").strip(),
            "music_length_ms": int(length),
        }
        Path(out).write_bytes(call("/v1/music?output_format=mp3_44100_128", body, raw=True))
    elif command == "sfx":
        prompt, out, seconds = argv[1:4]
        body = {"text": prompt, "duration_seconds": float(seconds)}
        Path(out).write_bytes(call("/v1/sound-generation?output_format=mp3_44100_128", body, raw=True))
    else:
        raise SystemExit(__doc__)


if __name__ == "__main__":
    main(sys.argv[1:])
