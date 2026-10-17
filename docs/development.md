# Geliştirme ve doğrulama

Repo kökünde Python 3.13, uv ve Node.js 18+ kullanın. Motor Godot 4.6.3'tür.

```powershell
uv sync --project tools --frozen
npm ci --ignore-scripts
npm run setup:godot
```

| Komut                                   | Kapsam                                                   |
| --------------------------------------- | -------------------------------------------------------- |
| `npm run format:check` / `format`       | Prettier kontrolü / yazma                                |
| `npm run format:gd:check` / `format:gd` | Oyun ve art preview GDScript kontrolü / yazma            |
| `npm run complexity`                    | Tanısal GDScript karmaşıklık raporu                      |
| `npm run check:data`                    | Özellik JSON verilerini yerel şemalarla doğrulama        |
| `npm run setup:godot`                   | SHA-256 sabitlenmiş GdUnit4 kurulumu                     |
| `npm run test:unit`                     | Godot importu ve GdUnit4 testleri                        |
| `npm run test:tools`                    | Şema, log başarısızlığı ve addon koruma sınır testleri   |
| `npm run verify`                        | Godot importu, unit, başlangıç ve oynanış input kontrolü |
| `npm run test:ui`                       | İlk yatırım, araştırma, afet, sevk ve onarım input akışı |
| `npm run build:windows`                 | Doğrulanmış Godot şablonuyla Windows x64 EXE/PCK ve ZIP  |

Godot PATH'te değilse `$env:GODOT_PATH = 'C:/Tools/Godot/godot_console.exe'` tanımlayın
veya `uv run --project tools python tools/checks/verify.py --godot <path>` kullanın.
Loglar `generated/reports/checks/`, GdUnit raporları `generated/reports/gdunit/` altındadır.
`ERROR:`, `CHECK FAILED`, eksik tamamlanma işareti ve zaman aşımı başarısızlıktır.

Godot'u `our-game/project.godot` ile açın; F6 mevcut sahneyi, F5 başlangıç sahnesini çalıştırır.
UI/input/animasyon değişimlerini projenin kendi viewport ayarlarında ve normal hızda ayrıca inceleyin.
Headless testler görsel kabul kanıtı değildir.

## Taşınabilir Windows demosu

`npm run build:windows`, standart Godot 4.6.3 ile release EXE ve ayrı PCK üretir.
Mono sürümü kullanılmaz. Gerekirse `GODOT_PATH` tanımlayın veya
`uv run --project tools python tools/checks/build_windows.py --godot <path>` kullanın.
İlk çalıştırmada resmi export şablon arşivi (yaklaşık 1,2 GB) indirilip SHA-256 ile doğrulanır;
yalnız Windows x64 şablonları `generated/tools/` altına çıkarılır. Sonraki çalıştırmalar önbelleği kullanır.

Çıktı `generated/builds/RewriteIt-Windows-x64.zip` dosyasıdır.
ZIP'i tamamen çıkartıp `RewriteIt.exe` dosyasını çalıştırın; PCK aynı klasörde kalmalıdır.
Paket, aktif gameplay JSON'larını ve `licenses/` altındaki motor lisans bildirimlerini içerir;
testler, addonlar ve özgün tarihsel arşiv dışarıda tutulur.
Import/export logları `generated/reports/checks/windows-*.log`, dosya hash'leri
`generated/builds/windows-x64-manifest.json` içindedir. Paketleme tek başına runtime kabulü değildir.

Çıkartılmış paketi, repo kaynakları yerine kendi PCK'sından okuyarak standart Godot 4.6.3 ile
kontrol etmek için:

```powershell
$smokeScript = (Resolve-Path 'our-game/tests/integration/package_smoke.gd').Path
& $env:GODOT_PATH --headless --main-pack '<çıkartılan klasör>/RewriteIt.pck' --script $smokeScript
```

Başarı işareti `PACKAGED_GAMEPLAY_PASS` olmalıdır; hata logu, eksik işaret veya zaman aşımı başarısızlıktır.
Bu harici sürücü paketlenmiş bytecode/veriler üzerinde açık kontroller çalıştırır. Oyuncunun kayıt ve tercih dosyalarına
dokunmadan açılış, 21 alan/99 afet kataloğu, yatırım, araştırma, ilk kriz, sevk, rapor ve bellekte kayıt
doğrulamasını kapsar. Gerçek renderer görüntüsü için sona `-- --capture <mutlak PNG yolu>` eklenir;
bu çalıştırmada `--headless` kaldırılır.

Standart release EXE, `--script` ve `--main-pack` parametrelerini desteklemez; bu nedenle yukarıdaki
kontrol için editör binary'si kullanılır. EXE açılışı ayrıca `--headless --quit-after 5` ile denenir.
Gerçek release renderer çıktısı için `--windowed --resolution 1920x1080 --write-movie <mutlak PNG yolu>
--quit-after 5` kullanılır; bu kısa açılış testi yeni kampanya veya kayıt aksiyonu vermez.

İlk beş dakika kontrolü `test:ui` içinde ana menüden iki başlangıcı da açar: 1990 seçimi ve rehberi
atlama; 1950 seçimi ve dört rehber sayfasını bitirme. Yıl seçimi yapılana kadar otomatik kayıt kapalıdır.
Ana menü ve kampanya seçiminde harita/HUD gizlidir; oyun içi menüde kampanya seçimi yoktur.
Oyun ekranından doğrudan `menu`/`newgame` yönlendirmesi de engellenir. Ana menüye dönüş, ayrı bir aksiyondur.
Sonra şehir → yatırım → araştırma → ilk afet sevkiyatı adımları, bağlamsal rehberin ilerleyip kapanması
ve menüden rehberi yeniden açma gerçek input ile doğrulanır.
Bu otomatik kabul, oyuncunun okuma/karar süresini içeren beş dakikalık insan testi yerine geçmez.

Kayıt/yükleme kabulünde sürücü yalnız `user://test-revert-ui-slots` altındaki bilinen dört dosyayı
kullanır ve temizler. Boş/bozuk yuva, iki manuel kaydın bağımsızlığı, üzerine yazma onayı/iptali,
oyun içi yükleme onayı/iptali, otomatik kayıttan devam ve yeni kampanyada manuel kayıtların korunması
gerçek input ile kontrol edilir. Oyuncunun kayıtları bu testlere katılmaz.
Splash kaynağı ve export komutu [ana menü art rehberindedir](../art/production/ui/main_menu/README.md).

`complexity` yalnız kendi kodumuzun dizinlerini tarar; yeni özellik eklendiğinde `package.json`
komutuna onun dizinini de ekleyin. İndirilen addonları rapora dahil etmeyin.

CI Windows üzerinde aynı kilitli araçları, format/şema kontrollerini, Python sınır testlerini
ve Godot import/unit/startup kontrollerini çalıştırır.
MCP sağlayıcı testleri oyun CI'ının parçası değildir; toolkit güncellenirken isteğe bağlı çalıştırılır.
MCP native görsel testleri lisanslı yerel Aseprite gerektirir.
Yerel başarı remote CI sonucu sayılmaz.

MCP kurulumu ve sürüm güncellemesi için [toolkit rehberini](../tools/mcp/README.md) kullanın.
Kimlik bilgilerini ve makine yollarını yerel dosyalarda tutun; genel Codex yapılandırmasını kopyalamayın.
