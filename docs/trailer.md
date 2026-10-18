# Tanıtım videosu (trailer)

Yaklaşık 58 saniyelik Türkçe tanıtım videosu bu depodaki araçlarla yeniden üretilir.
MP4, ham çekimler ve ses dosyaları Git dışındaki `generated/trailer/` altında kalır.

| Parça                                       | Sahibi                                               |
| ------------------------------------------- | ---------------------------------------------------- |
| Gerçek oyun çekimi (1950 kampanyası, 1080p) | `our-game/tests/integration/trailer_capture.gd`      |
| Alt yazı katmanı (oyunun bitmap fontu)      | `trailer_cards.gd` + `tools/trailer/cards.json`      |
| ElevenLabs ses, müzik ve efekt üretimi      | `tools/trailer/eleven.py` (anahtar `.env`, Git dışı) |
| Montaj, ses miksi ve çıktı                  | `tools/trailer/build.py`                             |
| PixelSpark / Rewrite it logoları            | `our-game/assets/branding/` (açılıştakiyle aynı)     |

Çekim sürücüsü `--verify` zincirinde değildir. Oyunu gerçek fare girdisiyle oynar, geçici
imleci kendisi çizer ve oyun müziğini kapatır; oyuncu kaydına ve tercihine dokunmaz.
Paralel kriz ve karar kartı sahneleri `crisis_pilot.gd` / `decision_ui.gd` ile aynı
ön hazırlığı kullanır. Movie Maker için yerel, Git dışı bir `our-game/override.cfg`
(`window_width_override=1920`, `window_height_override=1080`, `mode=0`) gerekir;
yoksa kayıt proje varsayılanı olan 1600×900 olur.

```powershell
$g = 'C:/Tools/Godot/Godot_v4.6.3-stable_win64.exe'
& $g --path our-game --write-movie <abs>/raw/run.avi --fixed-fps 60 --script res://tests/integration/trailer_capture.gd -- --marks <abs>/raw/run.json
& $g --path our-game --write-movie <abs>/raw/cards.avi --fixed-fps 60 --script res://tests/integration/trailer_cards.gd -- --cards tools/trailer/cards.json
python tools/trailer/build.py run daniel   # ses: daniel | adam | brian
```

`build.py` ham çekimi sahne işaretlerine göre keser; ffmpeg, Gemini kancası
(`gemini/hook1.mp4`) ve `voice/`, `music/` dosyaları `generated/trailer/` altında beklenir.
Anlatım metni ve zamanlama `build.py` içindeki `VO_START` ile `tools/trailer/voiceover.txt` dosyasındadır.
Açılış istatistikleri (170 afet, 26 milyon etkilenen, 89 bin can kaybı) [açılış rehberindeki](opening.md)
EM-DAT toplamlarıdır; kaynak notu videoda da yazar.
