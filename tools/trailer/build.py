"""Rewrite it trailer montajı: ham oyun çekimi + Gemini kancası + ElevenLabs ses/müzik -> MP4.

Önkoşullar (hepsi Git dışı generated/trailer/ altında):
  ffmpeg.exe, raw/<run>.avi + .json (our-game/tests/integration/trailer_capture.gd),
  cards.avi (trailer_cards.gd), gemini/hook1.mp4, voice/<ses>_s1..s8.mp3, music/*.mp3.

Kullanım: python tools/trailer/build.py <run_adı> <ses: daniel|adam|brian> [çıktı.mp4]
"""

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
T = ROOT / "generated" / "trailer"
FF = str(T / "ffmpeg.exe")
BRAND = ROOT / "our-game" / "assets" / "branding"
TOTAL = 58.0
VO_START = [4.3, 13.6, 19.7, 25.3, 30.6, 36.6, 43.0, 50.0]  # s1..s8 başlangıçları (sn)


def run(*args: str) -> None:
    subprocess.run([FF, "-v", "error", "-y", *args], check=True)


def segments(m: dict) -> list[dict]:
    """(ad, kaynak, başlangıç, bitiş, hedef süre). Hız = kaynak süresi / hedef süre."""
    raw = "raw"
    return [
        {"n": "hook", "src": "gemini", "a": 0.8, "b": 9.3, "d": 8.5},
        {"n": "menu", "src": raw, "a": m["menu"] + 0.7, "b": m["map"] - 2.2, "d": 6.5},
        {"n": "city", "src": raw, "a": m["map"] + 1.2, "b": m["project"] + 0.6, "d": 2.6},
        {"n": "research", "src": raw, "a": m["research"] + 0.5, "b": m["prepare"] - 3.0, "d": 3.4},
        {"n": "quake", "src": raw, "a": m["newspaper"] - 2.0, "b": m["newspaper"] + 3.2, "d": 5.2},
        {"n": "send", "src": raw, "a": m["dispatch"] + 1.0, "b": m["convoy"] + 4.0, "d": 6.4},
        {"n": "parallel", "src": raw, "a": m["parallel"] + 0.2, "b": m["parallel"] + 3.6, "d": 3.4},
        {"n": "report", "src": raw, "a": m["report"] + 0.2, "b": m["report"] + 3.8, "d": 3.6},
        {"n": "layers", "src": raw, "a": m["parallel"] + 3.8, "b": m["decision"] - 0.2, "d": 2.8},
        {"n": "decision", "src": raw, "a": m["decision"] + 0.6, "b": m["decision_end"] - 0.1, "d": 3.1, "fade": 0.4},
    ]


def atempo(speed: float) -> str:
    chain = []
    while speed > 2.0:
        chain.append("atempo=2.0")
        speed /= 2.0
    while speed < 0.5:
        chain.append("atempo=0.5")
        speed /= 0.5
    chain.append(f"atempo={speed:.5f}")
    return ",".join(chain)


def cut(run_name: str, seg: dict, index: int) -> tuple[Path, Path]:
    src = T / "gemini" / "hook1.mp4" if seg["src"] == "gemini" else T / "raw" / f"{run_name}.avi"
    speed = (seg["b"] - seg["a"]) / seg["d"]
    assert 0.6 <= speed <= 4.0, (seg["n"], speed)
    video, audio = T / "parts" / f"s{index:02d}.mp4", T / "parts" / f"s{index:02d}.wav"
    scale = "scale=1920:1080:flags=lanczos,fps=60,format=yuv420p"
    if seg.get("fade"):
        scale += f",fade=t=out:st={seg['d'] - seg['fade']:.3f}:d={seg['fade']}"
    run(
        "-ss", f"{seg['a']:.3f}", "-t", f"{seg['b'] - seg['a']:.3f}", "-i", str(src), "-an",
        "-vf", f"setpts=PTS/{speed:.5f},{scale}", "-t", f"{seg['d']:.3f}",
        "-c:v", "libx264", "-crf", "15", "-preset", "fast", str(video),
    )
    if seg["src"] == "gemini":
        run("-f", "lavfi", "-i", "anullsrc=r=48000:cl=stereo", "-t", f"{seg['d']:.3f}", str(audio))
    else:
        run(
            "-ss", f"{seg['a']:.3f}", "-t", f"{seg['b'] - seg['a']:.3f}", "-i", str(src), "-vn",
            "-af", f"{atempo(speed)},aresample=48000", "-ac", "2", "-t", f"{seg['d']:.3f}", str(audio),
        )
    return video, audio


def main(run_name: str, voice: str, out: Path) -> None:
    marks = json.loads((T / "raw" / f"{run_name}.json").read_text())
    segs = segments(marks)
    parts = [cut(run_name, seg, i) for i, seg in enumerate(segs)]
    spark = T / "parts" / "logo_spark.mp4"
    # --- video: logo + gövde, sonra alt yazı katmanı (screen) ve final logosu ---
    listing = T / "parts" / "list.txt"
    listing.write_text(
        "".join(f"file '{p.as_posix()}'\n" for p in [spark, *[v for v, _ in parts]]), encoding="utf-8"
    )
    body = T / "parts" / "body.mp4"
    run("-f", "concat", "-safe", "0", "-i", str(listing), "-c", "copy", str(body))
    logo = BRAND / "rewrite_it.png"
    end_at = 49.5
    # final logosu: siyah zemin + logo, end_at'te solarak belirir
    endcard = T / "parts" / "endcard.mp4"
    run(
        "-f", "lavfi", "-i", f"color=black:s=1920x1080:r=60:d={TOTAL - end_at}", "-loop", "1", "-framerate", "60",
        "-i", str(logo), "-t", f"{TOTAL - end_at}",
        "-filter_complex",
        "[1:v]format=rgba,fade=t=in:st=0:d=0.9:alpha=1[l];[0:v][l]overlay=x=(W-w)/2:y=324:shortest=1,format=yuv420p[v]",
        "-map", "[v]", "-c:v", "libx264", "-crf", "15", str(endcard),
    )
    full = T / "parts" / "full.mp4"
    run(
        "-i", str(body), "-i", str(endcard),
        "-filter_complex", "[0:v][1:v]concat=n=2:v=1:a=0[v]", "-map", "[v]",
        "-c:v", "libx264", "-crf", "15", "-r", "60", str(full),
    )
    graded = T / "parts" / "graded.mp4"
    run(
        "-i", str(full), "-i", str(T / "raw" / "cards.avi"),
        "-filter_complex", "[0:v]format=gbrp[a];[1:v]format=gbrp[b];[a][b]blend=all_mode=screen,format=yuv420p[v]", "-map", "[v]",
        "-shortest", "-c:v", "libx264", "-crf", "15", str(graded),
    )
    # --- ses ---
    gameplay_audio = T / "parts" / "game_sfx.wav"
    alist = T / "parts" / "alist.txt"
    alist.write_text(
        "".join(f"file '{(T / 'parts' / f'silence_logo.wav').as_posix()}'\n" for _ in [0])
        + "".join(f"file '{a.as_posix()}'\n" for _, a in parts),
        encoding="utf-8",
    )
    run("-f", "lavfi", "-i", "anullsrc=r=48000:cl=stereo", "-t", "4", str(T / "parts" / "silence_logo.wav"))
    run("-f", "concat", "-safe", "0", "-i", str(alist), "-ac", "2", str(gameplay_audio))
    inputs = [str(gameplay_audio), str(T / "music" / "music_v1.mp3")]
    for i in range(1, 9):
        inputs.append(str(T / "voice" / f"{voice}_s{i}.mp3"))
    sfx = [("sfx_test.mp3", 0.3, 0.9), ("sfx_riser.mp3", 21.9, 0.7), ("sfx_quake.mp3", 26.9, 0.8),
           ("sfx_title.mp3", 49.4, 0.9)]
    for name, _, _ in sfx:
        inputs.append(str(T / "music" / name))
    args = []
    for item in inputs:
        args += ["-i", item]
    fc = ["[0:a]volume=0.55,apad=whole_dur=%s[g]" % TOTAL]
    fc.append(f"[1:a]volume=0.9,afade=t=in:st=0:d=2,afade=t=out:st={TOTAL - 2.5}:d=2.5,apad=whole_dur={TOTAL}[mus]")
    vo_labels = []
    for i in range(8):
        ms = int(VO_START[i] * 1000)
        fc.append(f"[{2 + i}:a]aresample=48000,volume=1.6,adelay={ms}|{ms},apad=whole_dur={TOTAL}[v{i}]")
        vo_labels.append(f"[v{i}]")
    fc.append("".join(vo_labels) + f"amix=inputs=8:normalize=0,asplit=2[vo][vokey]")
    sfx_labels = []
    for j, (name, at, vol) in enumerate(sfx):
        ms = int(at * 1000)
        fc.append(f"[{10 + j}:a]aresample=48000,volume={vol},adelay={ms}|{ms},apad=whole_dur={TOTAL}[x{j}]")
        sfx_labels.append(f"[x{j}]")
    fc.append("[mus][vokey]sidechaincompress=threshold=0.02:ratio=6:attack=15:release=450[duck]")
    fc.append(
        f"[duck][vo][g]{''.join(sfx_labels)}amix=inputs={3 + len(sfx)}:normalize=0,"
        f"atrim=0:{TOTAL},loudnorm=I=-14:TP=-1.5:LRA=11[a]"
    )
    mixed = T / "parts" / "mix.wav"
    run(*args, "-filter_complex", ";".join(fc), "-map", "[a]", "-ar", "48000", str(mixed))
    run(
        "-i", str(graded), "-i", str(mixed), "-map", "0:v", "-map", "1:a", "-c:v", "copy",
        "-c:a", "aac", "-b:a", "224k", "-shortest", "-movflags", "+faststart", str(out),
    )
    print("OK", out)


if __name__ == "__main__":
    name, voice = sys.argv[1], sys.argv[2]
    main(name, voice, Path(sys.argv[3]) if len(sys.argv) > 3 else T / f"trailer_{voice}.mp4")
