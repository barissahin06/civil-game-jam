# Geliştirme ve doğrulama

Repo kökünde Python 3.13, uv ve Node.js 18+ kullanın. Motor Godot 4.6.3'tür.

```powershell
uv sync --project tools --frozen
npm ci --ignore-scripts
npm run setup:godot
```

| Komut                                   | Kapsam                                                 |
| --------------------------------------- | ------------------------------------------------------ |
| `npm run format:check` / `format`       | Prettier kontrolü / yazma                              |
| `npm run format:gd:check` / `format:gd` | Oyun ve art preview GDScript kontrolü / yazma          |
| `npm run complexity`                    | Tanısal GDScript karmaşıklık raporu                    |
| `npm run check:data`                    | Özellik JSON verilerini yerel şemalarla doğrulama      |
| `npm run setup:godot`                   | SHA-256 sabitlenmiş GdUnit4 kurulumu                   |
| `npm run test:unit`                     | Godot importu ve GdUnit4 testleri                      |
| `npm run test:tools`                    | Şema, log başarısızlığı ve addon koruma sınır testleri |
| `npm run verify`                        | Godot importu, unit testler ve başlangıç sahnesi       |

Godot PATH'te değilse `$env:GODOT_PATH = 'C:/Tools/Godot/godot_console.exe'` tanımlayın
veya `uv run --project tools python tools/checks/verify.py --godot <path>` kullanın.
Loglar `generated/reports/checks/`, GdUnit raporları `generated/reports/gdunit/` altındadır.
`ERROR:`, `CHECK FAILED`, eksik tamamlanma işareti ve zaman aşımı başarısızlıktır.

Godot'u `our-game/project.godot` ile açın; F6 mevcut sahneyi, F5 başlangıç sahnesini çalıştırır.
UI/input/animasyon değişimlerini projenin kendi viewport ayarlarında ve normal hızda ayrıca inceleyin.
Headless testler görsel kabul kanıtı değildir. Henüz platform export preset'i ve export smoke testi yoktur;
hedef platform seçilince eklenir.

`complexity` yalnız kendi kodumuzun dizinlerini tarar; yeni özellik eklendiğinde `package.json`
komutuna onun dizinini de ekleyin. İndirilen addonları rapora dahil etmeyin.

CI Windows üzerinde aynı kilitli araçları, format/şema kontrollerini, Python sınır testlerini
ve Godot import/unit/startup kontrollerini çalıştırır.
MCP sağlayıcı testleri oyun CI'ının parçası değildir; toolkit güncellenirken isteğe bağlı çalıştırılır.
MCP native görsel testleri lisanslı yerel Aseprite gerektirir.
Yerel başarı remote CI sonucu sayılmaz.

MCP kurulumu ve sürüm güncellemesi için [toolkit rehberini](../tools/mcp/README.md) kullanın.
Kimlik bilgilerini ve makine yollarını yerel dosyalarda tutun; genel Codex yapılandırmasını kopyalamayın.
