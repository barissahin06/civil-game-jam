# Civil Game Jam MCP kurulumu

Upstream [godot-aseprite-toolkit](https://github.com/barissahin06/godot-aseprite-toolkit).
`mcp-update.json` kurulu commit ve dosya hash'lerini kaydeder. Kaynak paketleri
`aseprite-mcp/` ve `pixelspark-art-mcp/` altındadır; ikinci paketin eski modül adı uyumluluk için korunur.

Repo kökünden, Python 3.13, uv, Node.js, Aseprite ve Godot 4.6.3 kurulu iken:

```powershell
python tools/mcp/toolkit.py setup --repo . --project our-game --aseprite C:/Tools/Aseprite/aseprite.exe --godot C:/Tools/Godot/godot_console.exe
python tools/mcp/toolkit.py doctor --repo .
```

Kurulum paketlerin kilitli ortamlarını hazırlar; `.codex/config.toml` içindeki
`aseprite`, `aseprite-godot-art`, `godot` ve devre dışı `pixelspark-art` tablolarını yönetir.
`ART_REPO` bu repo, `ART_PROJECT` bu reponun `our-game/` klasörüdür.
Başka projelerin ayarları ve kimlik bilgileri değişmez. Codex proje güvenini ve MCP yeniden bağlantısını gerektirir.
Bkz. [resmi Codex MCP belgesi](https://learn.chatgpt.com/docs/extend/mcp?surface=cli).

Bu makinenin eski genel `pixelspark_art` kaydı da yeni projenin yerel ayarında devre dışıdır;
doğru köke bağlı tek art köprüsü `aseprite-godot-art` olur. Takım arkadaşının aynı eski kaydı varsa
yerel config'ine aşağıdaki tabloyu eklemesi yeterlidir; yeniden setup bu ek tabloyu korur:

```toml
[mcp_servers.pixelspark_art]
command = "uv"
args = ["--directory", "tools/mcp/pixelspark-art-mcp", "run", "--frozen", "--no-dev", "-m", "pixelspark_art_mcp"]
enabled = false
```

Araçlar native sprite/katman/cel/palette/çizim/export işlemlerini ve Godot rig,
frame animation, FX, UI atlas, environment build/motion/review işlemlerini sağlar.
Detaylı sözleşmeler paketlerin README dosyalarındadır.

## Güncelleme ve test

Temiz ve doğrulanmış upstream toolkit checkout'undan:

```powershell
python toolkit.py update --repo "C:/path/to/civil-game-jam" --target tools/mcp
```

Update yalnız MCP kaynakları/testleri ve kurulum scriptini alır; artwork, benchmark ve örnekleri almaz.
Yerel değişiklikte durur; tekrar çağrı değişiklik üretmez. Tüketici içindeki `toolkit.py update`
komutunu kaynak olarak kullanmayın; upstream checkout'undan çalıştırın.

Ardından bu repo kökünden ortamları güncelleyin:

```powershell
uv sync --project tools/mcp/aseprite-mcp --frozen
uv sync --project tools/mcp/pixelspark-art-mcp --frozen
```

Sağlayıcı testleri oyun türünden bağımsız araç kontrolleridir; normal oyun CI'ında çalışmaz.
Toolkit sürümünü doğrulamak istediğinizde isteğe bağlı çalıştırabilirsiniz:

```powershell
uv run --project tools/mcp/pixelspark-art-mcp --frozen python -m unittest discover -s tools/mcp/pixelspark-art-mcp/tests
```

Paket içindeki `integration_native.py`, dağıtım dışında tutulan upstream `examples/` fixture'larını
gerektirir. Tam native kabulü upstream checkout'unda çalıştırın; yeni oyuna örnek artwork kopyalamayın.
Kaynak değişikliğinden sonra MCP sunucularını yeniden bağlayın.
