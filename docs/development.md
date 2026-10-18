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

Günlük ikmal ve geçici konuşlandırma, `verify` ve `test:ui` içindeki
`micromanagement_ui.gd` sürücüsüyle kontrol edilir. Gerçek renderer görüntülerini üretmek için:

```powershell
& $env:GODOT_PATH --path our-game --script res://tests/integration/micromanagement_ui.gd -- --capture
```

Görüntüler `generated/micromanagement-ui/` altına yazılır; gerçek boyutta ayrıca incelenir.
Oyuncu kaydına dokunmayan sekiz politika denemesi için:

```powershell
& $env:GODOT_PATH --headless --path our-game --script res://tests/integration/balance_probe.gd
```

`BALANCE_V3_PASS` ve `generated/reports/checks/balance-v3.json`, 1950/1990 için
aksiyonsuz, yalnız ekip, hazırlık/ikmal ve aşırı taahhüt politikalarının tanısıdır.
Bu rapor insan oynanış testi veya başarı oranı değildir.

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
atlama; 1950 seçimi ve 12 rehber bölümünü bitirme. Yıl seçimi yapılana kadar otomatik kayıt kapalıdır.
Ana menü ve kampanya seçiminde harita/HUD gizlidir; oyun içi menüde kampanya seçimi yoktur.
Oyun ekranından doğrudan `menu`/`newgame` yönlendirmesi de engellenir. Ana menüye dönüş, ayrı bir aksiyondur.
Sonra şehir → yatırım → araştırma → ilk afet sevkiyatı adımları, bağlamsal rehberin ilerleyip kapanması
ve menüden rehberi yeniden açma gerçek input ile doğrulanır.
Oyun Rehberi metinleri `ui_preview/campaign/tutorial_copy.gd` içinde tutulur; bölüm seçimi,
geri/ileri gezinme ve ana menü/duraklatma menüsüne dönüş `campaign_screens.gd` sahibindedir.
Rehber; amaç ve zaman, harita, ekonomi, yerel projeler, araştırma/ulusal önlemler,
ekip/yardım hazırlığı, merkezler arası taşıma, afet sevki, günlük ikmal, onarım/yenileme,
kalıcı kararlar/güven ve kayıt/kontrolleri kapsar. Haritadaki dört eylemli bağlamsal rehber
ayrı kalır. `gameplay_ui.gd`, tüm bölümlerde metin taşmasını, ilk bölümde geri sınırını,
geri/ileri ve gerçek açılır liste girdisini, okuma sırasında modelin değişmemesini ve üç
giriş akışını denetler. Aynı sürücüyü `--capture` ile gerçek renderer'da çalıştırıp
`generated/gameplay-ui/guide-*.png` görüntülerini 1920×1080'de inceleyin.
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

## Afet sonrası kararlar

`test_decisions.gd`, Gediz/Samsun/Marmara pilotlarını, bütün 21 kartın 63 alternatifini,
kalıcı ret/iptali, yerel/ulusal slot sırasını, taksit/tamamlama etkilerini ve kayıt
devamlılığını denetler. Sürüm 1 geçişi yalnız bilinen eski katalog hash'iyle yapılır.
`test_decision_catalog.gd` ve Python katalog testleri referans, kapsam, etki ve kaynak
aksiyonlarının eşlemesini doğrular. Bu kontroller insan oynanış dengesi kanıtı değildir.

`verify` ve `test:ui`, `decision_ui.gd` ile rapor sonrası gerçek seçim/onay girdisini,
Esc menüsünden dönüşü, bekleyen kararın bellekte yüklenmesini ve bütün kartların
native fontla çizilmesini kontrol eder. 63 alternatifin özetleri en fazla dört satırda,
kaydırma veya taşma olmadan gösterilir; artı/eksi işaretleri, etki renkleri, dolu slot
ve sıfır kazanım/güven sınırı da denetlenir. Oyuncunun kayıtları ve tercihleri kullanılmaz.

```powershell
& $env:GODOT_PATH --path our-game --script res://tests/integration/decision_ui.gd -- --capture
```

1920×1080 görüntüler `generated/gameplay-ui/decision-*.png` altındadır.

## Gazete fotoğrafları

`verify` ve `test:ui`, `newspaper_ui.gd` ile boş arşivi, ilk afet haberini, gerçek fare
girdisiyle kriz merkezine geçişi ve HUD'dan son haberin tekrar açılmasını kontrol eder.
99 haberin tamamında 1440×840 gazetenin ortalanması, eşit iki sütun, sabit 640×360
fotoğraf alanı, kırpmadan sığdırma, metinle çakışmama ve taşmama denetlenir. Olaya özel
59 görsel ile türüne göre kullanılan
40 temsili görsel ayrılır; temsili fotoğrafların açıklaması bunu açıkça belirtir.
Sürücü oyuncu kayıtlarına veya tercihlerine dokunmaz; katalog ve kampanya parmak izi değişmez.

Gerçek 1920×1080 renderer incelemesi için:

```powershell
& $env:GODOT_PATH --path our-game --script res://tests/integration/newspaper_ui.gd -- --capture
```

Görüntüler `generated/gameplay-ui/newspaper-*.png` altındadır; deprem, sel, yangın,
çığ ve heyelan, farklı fotoğraf oranları ve en uzun başlık/açıklama bu incelemeye dahildir.
Gerçek renderer'da aynı fotoğraf materyaline verilen gri rampa yedi sıcak baskı tonu
üretmelidir; headless çalışma bu GPU piksel kontrolünü atlar. Ortak `newsprint.gdshader`
filtreyi bütün fotoğraflara uygular; JPEG kaynakları ve olay verisi değişmez.

`test_font_coverage.gd`, Türkçe alfabenin büyük/küçük harflerini, yazdırılabilir ASCII,
şapkalı harfler ve tipografik noktalamanın font kaydını ve gerçek alfa piksellerini denetler.
Boşluk dışındaki glifler boş veya `?` hücresinin kopyası olamaz; `i/İ` ve `ı/I` ayrımı korunur.
`newspaper_ui.gd`, `historical-081` haberindeki `Hatip Çayı'nın` metnini ayrıca kontrol eder.
Native `newspaper-font-coverage.png` bütün karakterleri; `newspaper-historical-081.png` gerçek
gazete yerleşimini gösterir. Kaynak/export ve yeniden import sözleşmesi
[P0 art rehberindedir](../art/production/ui/p0/README.md).

## Kriz etkisi ve kolay sevk pilotu

`verify` ve `test:ui`, mevcut input akışının ardından `crisis_pilot.gd` kontrolünü de
çalıştırır. İzole sürücü ilk tarihsel afeti hazırlık, sevk, rapor ve altı aylık
onarım boyunca izler; bu fixture'da sonraki afetlerin otomatik başlangıcı kapatılır.
Oyuncu kayıtları ve tercihlerine dokunmaz. Hızlı sevk, popup/harita girdisi,
kaynak bağlamı, paralel hedefler, odağın ve düğümlerin korunması kontrol edilir.

Standart Godot 4.6.3 ile A/B incelemesi:

```powershell
& $env:GODOT_PATH --path our-game --script res://tests/integration/crisis_pilot.gd -- --review
```

Üstte yalnız bu sürücüde görünen A/B düğmeleri sahneyi açıp kapatır; Yeniden Dene
aynı başlangıcı kurar. Ekran görüntülü otomatik kabul için `--review` yerine
`--capture` kullanın; `--headless` vermeyin. Çıktı `generated/gameplay-ui/pilot-*.png`.
Bu kontrol insanın karar etkisini anlamasını veya devam etme isteğini kanıtlamaz.

`test_crisis_feedback.gd`, afet başlangıcındaki ortak harita/HUD sarsıntısını, kamera ve
panellerin sabit kalmasını, ayar kapatılınca hareketin hemen durmasını ve yenileme/yüklemede
efektin tekrarlanmamasını denetler. Pilot, kırmızı ilin dört modda görünmesini, aynı ildeki son
kriz bitince görünüm renginin geri dönmesini ve paralel krizlerin bağımsızlığını kontrol eder.
Palette doku okuması gerçek renderer gerektirir; headless kabul bunu atlar. Native `--capture`
çıktılarında `pilot-crisis-hud-shake.png`, `pilot-crisis-red-*.png` ve
`pilot-crisis-settled.png` incelenir. Normal hızdaki hareketi kaydetmek için:

```powershell
$motionPath = Join-Path (Get-Location) 'generated/gameplay-ui/crisis-feedback.avi'
& $env:GODOT_PATH --path our-game --windowed --write-movie $motionPath --fixed-fps 60 --script res://tests/integration/crisis_pilot.gd -- --motion
```

Tamamlanma işareti `CRISIS_PILOT_MOTION_PASS` olmalıdır. Kayıtta ilk 0,30 saniyenin sarsıntısı,
kısa kırmızı uyarı ve ardından sabit HUD/harita ayrıca gözle incelenir.
Movie Maker başlangıç penceresinin 1600×900 ölçüsünü kullanır; `--capture` PNG kabul
görüntüleri 1920×1080'dir.

## Haritada hazırlık emirleri

`verify` ve `test:ui`, `preparation_ui.gd` gerçek input kontrolünü de çalıştırır:
eylem paleti, farklı/aynı merkeze emir, meşgul merkezde sıra, son bekleyen emri kaldırma,
odak/kaydırma/işaretçi sürekliliği, pan/zoom, Esc ve haber ekranına geçiş.
Sol alttaki kalıcı harita araç çubuğunun kapalı başlaması, sağa açılıp kapanması,
şehir/hazırlık ve kriz/birlik panellerinden ayrı kalması; kapatıldığında mod, kamera ve odağın
korunması kontrol edilir. Bildirim metni ve tam tooltip, çubuk alan değiştirirken korunur.
Araçların üstünde sürükleme haritayı kaydırmaz. Dört modun gerçek tıklamayla seçimi, tek basılı mod,
1×–3× yakınlaştırma sınırları, düğme/tekerlek/sıfırlama eşleşmesi ve araç çubuğuna
tıklamanın haritada hazırlık emri oluşturmaması da kontrol edilir.
Mod açıklaması ve lejant aynı kalıcı çubukta gösterilir: Bölgeler görünümünde yedi bölge adı,
sayısal modlarda birim ve üç örnek değer bulunur. `preparation_ui.gd`, gerçek fare hareketiyle
merkez değerini okumayı ve haritadan çıkınca ipucunun geri gelmesini; yenilemede odak, seçim ve
lejant düğümlerinin korunmasını kontrol eder. Yardım stoğunda 0/80/240 değerlerinin lejantla aynı
renk ölçeğini kullanması, 160+ renk doygunluğunda gerçek 240 stoğunun okunması ve farklı
bölgelerde eşit stokların aynı renkle gösterilmesi denetlenir. Hasar ölçeği 0→100 yönündedir;
aktif kriz kırmızı dolgu ve ayrı `!` işaretiyle bütün modlarda görünür; hover sayısı gerçek
hazırlık/stok/hasar değerini korur. Kriz bitince ilin görünüm rengi geri dönmelidir.
`test_map_overlay.gd`, salt okunur sorgunun
stok, hasar, beş afet hazırlığının ortalaması ve kampanya durumundan bağımsız dönüş değerini doğrular.
`test_preparation_queue.gd`, FIFO/aylık taksit/bütçe/iptal/duraklatma ve kayıt doğrulamasını kapsar.
Native arazi kaynağı `art/production/ui/p0/map-general.aseprite`, ayrı runtime çıktısı
`our-game/ui_preview/assets/map-terrain.png` dosyasıdır; export sözleşmesi
[P0 art rehberindedir](../art/production/ui/p0/README.md). `preparation_ui.gd` bu 3072×1728
katmanın yalnız Bölgeler modunda görünmesini, veri rengi ile seçim/etiket katmanları arasındaki
sırasını, yenilemede düğüm kimliğini ve pan/1×–3× zoom dönüşümünü kontrol eder.
Gerçek tıklama, hazırlık emri ve harita taşıma akışı bu katmanın inputu engellemediğini de denetler.
Arazi görseldir; simülasyon hesabı veya kayıt biçimi değiştirmez.
Gerçek renderer'da aynı 1920×1080 kontrolü için:

```powershell
& $env:GODOT_PATH --path our-game --script res://tests/integration/preparation_ui.gd -- --capture
```

Görüntüler `generated/gameplay-ui/preparation-*.png`, `map-toolbar-*.png`, `map-legend-*.png` ve
`terrain-*.png` altındadır. `terrain-general-native.png` 1×, `terrain-zoom-2.png` ve
`terrain-zoom-3.png` tamsayı yakınlaştırmadaki araziyi gösterir. Sürücü oyuncu kayıtlarına dokunmaz;
kuyruk kayıt testleri kendi test dizinini kullanır. İnsanla kullanım denemesi ayrıca yapılır.

## Kompakt gezinme ve listeler

`verify` ve `test:ui`, `compaction_ui.gd` ile altı üst girişi, Yatırım ve Araştırma sekmelerini,
Olaylar açılır menüsünü ve boş rapor/proje durumunu gerçek input ile denetler.
Proje takibinde altı, şehir yatırımlarında beş satırın aynı anda görünmesi;
yenileme ve ayrıntıdan dönüşte kaydırma/odak; araştırma kategorisinin ve son Yatırım ve Araştırma
sekmesinin korunması kapsamdadır. Şehirde ekip/yardım üretimi ve yinelenen genel kriz
düğmesi bulunmamalıdır; hazırlık emirleri mevcut `preparation_ui.gd` ile doğrulanır.
`crisis_pilot.gd` ve `units_ui.gd`, miktar seçiminin harcama yapmadığını ve Sevk Et'in
mevcut kaynak/hedef doğrulamalarını kullandığını denetler. Gazete/rapor kuyruğu ve Esc
dönüşü mevcut sürücülerde korunur. Oyuncu kayıtları kullanılmaz.

```powershell
& $env:GODOT_PATH --path our-game --script res://tests/integration/compaction_ui.gd -- --capture
```

Gerçek 1920×1080 görüntüler `generated/gameplay-ui/compact-*.png` altındadır.

## Ekipler ve Yardıme doğrudan erişim

`verify` ve `test:ui`, `units_ui.gd` ile HUD'dan birlik listesine erişimi, aktif kriz
yokken sevk gerekçesini, seçilen merkezden şehir lojistiği/sevk formuna geçişi ve
mevcut hızlı sevk komutlarını gerçek input ile denetler. Hazır/yolda/görevde ekip
sayılarının güncellenmesi, liste kaydırma/odak/düğüm sürekliliği, paralel krizde hedef
seçimi ve Esc ile menüden geri dönüş de kapsamdadır. Sağdaki birlik panelinin harita
araç çubuğunu kapatmadığı kontrol edilir. `test_unit_overview.gd`, ekiplerin sevk,
görev ve dönüş sayımlarını, yardımın ekip sayılmamasını, merkez sırasını ve salt okunur
sorgu sınırını doğrular. Oyuncu kayıtları kullanılmaz.

```powershell
& $env:GODOT_PATH --path our-game --script res://tests/integration/units_ui.gd -- --capture
```

Gerçek 1920×1080 görüntüler `generated/gameplay-ui/units-*.png` altındadır.

## Proje etkilerinin önizlemesi

`test_projects.gd`, salt okunur etki önizlemesini gerçek tamamlanma sonucuyla karşılaştırır:
yerel çapraz hazırlık/direnç, ulusal ortalama, bakım verimi, mevcut etki sınırları,
araştırma slotu, onarım ve tekrarlı ekip/stok. Önizleme parayı, güveni, projeleri veya
merkezleri değiştirmemelidir; tamamlanmış tedbir ikinci kez eklenmemelidir.

`gameplay_ui.gd` gerçek proje ekranında mevcut/tamamlanma çubuklarını, uzun etki listesinin
kaydırılmasını ve salt okunur sürükleme davranışını kontrol eder. Onarımda negatif hasar
farkı yeşil olmalıdır. Olumsuz azalış yalnız testteki sunum verisiyle kırmızı olarak
kontrol edilir; gameplay kataloğuna yeni etki eklenmez. `-- --capture` ile aynı sürücüden
1920×1080 görüntüler alınır. Ulusal ortalama ve bugünkü koşullar açıklaması, miktar/yüzde/
para birimleri, çubuk sınırları ve metin taşması görüntüde ayrıca incelenir.

## Eyleme göre düğme renkleri

`gameplay_ui.gd`, gerçek kampanya, yatırım, sevk, bütçe ve kayıt ekranlarında eylem
renklerini denetler. Güvenli başlangıç yeşil, kayıt değiştiren son onay kırmızı;
yılın `+ / −` düğmeleri ve vazgeçme nötr kalmalıdır. Hover/basılı görünüm aynı eylem
rengini korumalı, odak çerçevesi dolguyu örtmemeli ve devre dışı görünüm nötr olmalıdır.
Görsel kontrol için gerçek renderer ile çalıştırın:

```powershell
& $env:GODOT_PATH --path our-game --script res://tests/integration/gameplay_ui.gd -- --capture
```

`generated/gameplay-ui/` içindeki `newgame-1990`, `newgame-confirm-replace`,
`save-confirm-overwrite`, `load-confirm`, `local-project` ve `crisis` görüntülerini
1920×1080'de inceleyin. Renk tek başına açıklama değildir; eylem başlıkları ve mevcut
risk/onay metinleri korunur.

## Pencere ve Esc kontrolleri

`verify` ve `test:ui`, `window_controls.gd` ile Esc menüsü/önceki ekrana dönüşü,
okunmamış gazete/raporun korunmasını, ayarlar ve F11 akışlarını denetler.
HUD kabulü aynı sürücüde gerçek fare girdisiyle 1×/2×/4× seçimini, tek etkin hız düğmesini,
duraklatma/devam metnini ve yenilemede düğüm/odak sürekliliğini kontrol eder. Güvenin 0–100 sınırı,
küçük gerçek değişimi ve gerekçesi; dört basamaklı bilinç, büyük bütçe ve uzun ay adıyla tarih
yerleşimi de denetlenir. Toplam birlik ve yardım stoğunun değişim sinyaliyle güncellenmesi,
binlik ayıracı, tooltip değerleri, yerleşimi ve düğüm sürekliliği de kontrol edilir.
Görüntüler `generated/gameplay-ui/hud-*.png` altındadır.
`test_display_settings.gd` yalnız izole tercih dosyasıyla varsayılan modu, geçersiz veriyi,
tercihlerin korunmasını ve iki tam ekran türüne F11 dönüşünü kontrol eder.
Gerçek Windows penceresinde işletim sistemi modunu ve pencere sınırlarını doğrulamak için:

```powershell
& $env:GODOT_PATH --path our-game --script res://tests/integration/window_controls.gd -- --native-window --capture
```

Bu sürücü oyuncu tercihini okumaz/yazmaz; proje varsayılanının exclusive tam ekran olmasını,
kenarlıksız tam ekranda monitör ölçüsünü ve pencere modunda kenarlık/masaüstüne sığmayı doğrular.
Fare koordinatları gerçek pencere ölçeğine çevrilir. Görüntüler
`generated/gameplay-ui/window-settings-*.png` altındadır. Headless çalışma OS modu kanıtı değildir.
Kriz pilotu ayrıca Acil Bütçe/Kapat başlık hizasını ve fon ekranı gidiş-dönüşünü kontrol eder.

MCP kurulumu ve sürüm güncellemesi için [toolkit rehberini](../tools/mcp/README.md) kullanın.
Kimlik bilgilerini ve makine yollarını yerel dosyalarda tutun; genel Codex yapılandırmasını kopyalamayın.

## Ses ve müzik kontrolleri

`verify` ve `test:ui`, `audio_ui.gd` ile gerçek fare/klavye girdisi üzerinden müzik aç/kapat,
duraklat/sürdür, iki ses slider'ı, menü/kampanya geçişinde süreklilik, işlem onay/ret sesleri,
tamamlanma ve tek seferlik afet uyarısını kontrol eder. Testler oyuncu tercihlerini kullanmaz.
`test_audio_preferences.gd`, yalnız izole CFG ile ses tercihlerini, geçersiz tipleri, sınırları
ve mevcut görüntü/görsel tercihlerin korunmasını, gecikmeli kaydı ve çıkışta son değişikliğin
saklanmasını denetler. Sesli sürücüler kapanırken `audio.shutdown()` beklenir: Godot'un ses
iş parçacığı durdurulan oynatım referanslarını bir sonraki karışımda bırakır.

Gerçek 1920×1080 görüntülü kabul için:

```powershell
& $env:GODOT_PATH --path our-game --script res://tests/integration/audio_ui.gd -- --capture
```

Çıktılar `generated/gameplay-ui/audio-settings-*.png` altındadır. Headless kontrol sesin
duyusal dengesini kanıtlamaz; normal ses çıkışında dinleyerek ayrıca değerlendirin.

## Arayüz metinlerinin kabulü

`npm run verify` yeni adları, kayıt onaylarını, gönderim özetini ve hazır/toplam ekip ayrımını
kontrol eder. Proje açıklamalarının katalog kimlikleriyle eşleşmesi unit testle doğrulanır.
Uzun teknik adlar ve açıklamalar için gerçek 1920×1080 görüntüde `gameplay_ui.gd`,
`compaction_ui.gd`, `preparation_ui.gd` ve `window_controls.gd` sürücülerini `--capture` ile
çalıştırın. Temel metinler kırpılmamalı; açıklama için küçültülen yazı kullanılmamalıdır.
Açıklamalar nedeniyle daha az satır görünmesi kabul edilir; kaydırma ve klavye odağı korunur.
Headless kontroller görsel kabulün yerine geçmez.

## Araştırma ağacı ve ulusal önlemler

Dört kategoride beş dönem × iki seçenek, toplam 40 araştırma ve 15 normal ulusal önlem
vardır. Afet sonrası karar programları bu sayılara dahil değildir. Katalog testleri dönem,
önkoşul, maliyet/süre ve etki dağılımını; eksik/döngülü/gelecek tarihli önkoşulların reddini,
geç başlangıç sırasının bağımsızlığını, tek seferlik etkileri ve kapasiteyi denetler.
Ekonomi denemeleri 1950/1990 için aylık gelir, bakım ve taksitlerle borçsuz ilerlemeyi;
ayrı bir yeterli kaynak senaryosu 2020 içeriğinin 2026 sonundan önce tamamlanmasını sınar.
Bunlar afetli kampanyanın veya insan oynanışının dengeli olduğu anlamına gelmez.

`npm run verify` ve `npm run test:ui`, `research_tree_ui.gd` ile gerçek fare/klavye
girdisi üzerinden beş tarih sütununu, kartları kesmeyen yönlü okları, kategori dışı
önkoşulları, önlemden araştırmaya gidiş/dönüşü ve 55 uzun açıklamanın okunmasını kontrol eder.
Oyuncunun kayıtları ve tercihleri kullanılmaz. Gerçek 1920×1080 renderer incelemesi için:

```powershell
& $env:GODOT_PATH --path our-game --script res://tests/integration/research_tree_ui.gd -- --capture
```

Görüntüler `generated/gameplay-ui/research-*.png` altındadır. Her kategorinin ilk/son dönemi,
kategori geçişi, 2020 ulusal önlemleri ve uzun araştırma açıklaması ayrıca incelenir.

## Kondisyon, yenileme ve taahhüt kabulü

`test_center_renewal.gd`, kapasiteye bağlı bedeli, yerel slotu, taksitleri, kondisyon/verim
kaybını ve yeni kayıt alanlarının doğrulamasını kontrol eder. `test_trust_recovery.gd`, ayrı
hasar partilerinin altı aylık süresini, uygulanmış kaybın sınırlı iadesini ve ortak afet
puanlamasını; `test_decisions.gd`, taahhüdün gerçek ilerleme ve 6/12 ay sınırlarını denetler.

`verify` ve `test:ui` içindeki `renewal_trust_ui.gd`, gerçek fare girdisiyle yenileme bedelini,
başlatmayı, taahhüt uyarısını, proje listesinde durumu ve iki aşamalı iptal bedelini kontrol eder.
Oyuncu kaydı veya tercihi kullanılmaz. Gerçek 1920×1080 görüntülü kabul:

```powershell
& $env:GODOT_PATH --path our-game --script res://tests/integration/renewal_trust_ui.gd -- --capture
```

Görüntüler `generated/balance-ui/` altında oluşur. Uzun kampanya tanısı için
`balance_probe.gd` çalıştırılır; çıktı `generated/reports/checks/balance-v4.json`.
Politikalar oyun kuralları değildir; nakit veya güven sıfırlanmaz. Dikkatli politika normal
bakım ve taksitlere göre 4,5 aylık rezervi hedefler, gelecekteki bakım/yenileme yükünü hesaba katar.
İnsanla uzun kampanya denemesi ayrı kabul aşamasıdır.
