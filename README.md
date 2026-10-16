# Civil Game Jam

Godot 4.6.3 oyun projesi. Godot Project Manager'a `our-game/project.godot` dosyasını ekleyin.
Başlangıç sahnesi yalnız bir başlık gösterir; oyun mekanikleri henüz eklenmedi.

## Başlangıç

Python 3.13, uv, Node.js 18+ ve Godot 4.6.3 kurulu olmalı. Repo kökünden:

```powershell
uv sync --project tools --frozen
npm ci --ignore-scripts
npm run setup:godot
npm run verify
```

Godot PATH'te değilse `GODOT_PATH` tanımlayın. MCP kurulumu için ayrıca lisanslı Aseprite gerekir:

```powershell
python tools/mcp/toolkit.py setup --repo . --project our-game --aseprite C:/Tools/Aseprite/aseprite.exe --godot C:/Tools/Godot/godot_console.exe
python tools/mcp/toolkit.py doctor --repo .
```

Codex'te bu depoyu açın, proje güvenini onaylayın ve MCP sunucularını yeniden bağlayın.
Makineye özel `.codex/config.toml` Git dışındadır. Kurulum genel Codex ayarlarını değiştirmez.

## Rehberler

- [Çalışma kuralları](AGENTS.md)
- [Klasörler ve mimari](docs/architecture.md)
- [Kod ve veri standardı](docs/code-style.md)
- [Geliştirme ve doğrulama](docs/development.md)
- [Bağımlılık sahipliği](docs/dependencies.md)
- [Aseprite / Godot araçları](tools/mcp/README.md)
- [Art üretim kuralları](art/production/AGENTS.md)

MCP kaynakları `godot-aseprite-toolkit` deposunun sabitlenmiş sürümüdür;
ilgili MIT lisansları paketlerin içindedir.
