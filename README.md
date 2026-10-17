# Rewrite it

Godot 4.6.3 oyun projesi. Godot Project Manager'a `our-game/project.godot` dosyasını ekleyin.
F5, splash art içeren ayrı ana menüyü açar. Yeni Oyun'dan 1950–1990 başlangıç yılı seçin.
1920×1080 tarihsel afet stratejisinde şehir panelinden yatırım,
üst menüden araştırma ve ulusal tedbir başlatın; DEVAM ile takvimi ilerletin.
Afet haberi oyunu durdurur. Ekip/yardımı haritaya sürükleyerek veya kriz formundan sevk edin.
F11 tam ekranı; boşluk duraklatmayı değiştirir. 1×/2×/4× hız kullanılabilir.
Harita, HUD ve panellerin arkasında ekranı kaplar; yakın çevre ülkeleri soluk sınır ve adlarıyla gösterir.
1950–1990 arasında başlayıp 2026 sonuna ulaşın. Bütçe, tek ulusal güven, bilinç puanı,
aylık taksit/bakım, araştırmalar, paralel krizler, gidiş/görev/dönüş ve onarım birbirine bağlıdır.
Bir otomatik ve üç manuel kayıt yuvası vardır. Ana menüden yükleyin veya oyun içi menüden
kaydedin/yükleyin. Üzerine yazma ve oyun içi yükleme onay ister. Sandbox kilitlidir.
Maliyetler ve sonuç hesabı ilk oyun dengesi değerleridir; tarihsel istatistik iddiası taşımaz.

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
- [Üç kişilik paralel çalışma](docs/team-workflow.md)
- [Oyun kararları ve uygulama sırası](docs/game-design.md)
- [P0 native kaynaklar ve önizleme](art/production/ui/p0/README.md)
- [Kod ve veri standardı](docs/code-style.md)
- [Geliştirme ve doğrulama](docs/development.md)
- [Bağımlılık sahipliği](docs/dependencies.md)
- [Aseprite / Godot araçları](tools/mcp/README.md)
- [Art üretim kuralları](art/production/AGENTS.md)

MCP kaynakları `godot-aseprite-toolkit` deposunun sabitlenmiş sürümüdür;
ilgili MIT lisansları paketlerin içindedir.
