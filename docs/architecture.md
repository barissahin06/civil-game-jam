# Klasörler ve mimari

Godot kökü `our-game/`, giriş sahnesi `core/scenes/main.tscn`.
Logo ve afet hafızası ekranının süresi ve kaynakları [açılış rehberindedir](opening.md).
Onaylanan mantıksal viewport 1920×1080'dir; çalışan ayarların kaynağı
`our-game/project.godot` dosyasıdır. Harita ve UI native Aseprite pixel art olarak üretilir.
Oyun kuralları, P0/P1/P2 sınırları ve sınıf sahipleri [oyun tasarımında](game-design.md) tanımlıdır.

| Yol                           | Sorumluluk                                                             |
| ----------------------------- | ---------------------------------------------------------------------- |
| `our-game/core/`              | Başlangıç ve gerçekten oyun genelinde olan durum/servis sahipleri      |
| `our-game/<feature>/scenes/`  | İlgili özelliğin sahneleri                                             |
| `our-game/<feature>/scripts/` | Koordinatörler; gerektiğinde `domain/`, `ui/`, `presentation/`         |
| `our-game/<feature>/data/`    | Özelliğin authored gameplay JSON verileri                              |
| `our-game/shared/`            | Birden fazla gerçek tüketicisi olan ortak kod                          |
| `our-game/assets/`            | Oyuna kurulmuş, onaylı runtime varlıkları                              |
| `our-game/tests/unit/`        | GdUnit4 ile saf mantık testleri                                        |
| `our-game/tests/integration/` | Gerçek sahne ve runtime entegrasyon kontrolleri                        |
| `our-game/ui_preview/`        | Onaylı P0 görünümünü koruyan canlı UI; kurallar `Simulation` üzerinden |
| `our-game/simulation/`        | Tek takvim üzerinde modüllerin komut ve işlem sırası                   |
| `our-game/campaign/domain/`   | UTC gün takvimi, güven ve sürümlü güvenli kayıt                        |
| `our-game/economy/domain/`    | Hazine, gelir, bakım ödemesi ve verim oranı                            |
| `our-game/regions/`           | 21 merkez ve 81 ilin tek sorumluluk alanı sahipliği                    |
| `our-game/management/`        | Tedbir tanımları, araştırma/projeler, taksit, slot ve etkiler          |
| `our-game/events/`            | Doğrulanan tarihsel katalog; karar olayları henüz sağlanmadı           |
| `our-game/crisis/domain/`     | Afet türü modelleri, paralel müdahale ve karşılaştırmalı rapor         |
| `our-game/logistics/domain/`  | Rezervasyon, sevk bedeli, varış, görev ve dönüş                        |
| `art/production/`             | Kullanılan üretim araçlarının düzenlenebilir kaynak dosyaları          |
| `art/catalogs/`               | Kaynak/runtime eşlemeleri ve onay metadata'sı                          |
| `art/preview/`                | Oyuna kurmadan önce gerçek boyutta görsel incelemeler                  |
| `tools/assets/`               | Asset üretim/kurulum araçları                                          |
| `tools/checks/`               | Kurulum, şema ve regresyon denetimleri                                 |
| `tools/mcp/`                  | Sabit sürümlü Aseprite ve Godot MCP sağlayıcıları                      |
| `schemas/`                    | Gameplay JSON şemaları                                                 |
| `generated/`                  | Git dışında kalan raporlar, yakalamalar ve build çıktıları             |

Dosyaları türüne göre kökte tek bir `scripts/` veya `scenes/` yığınına toplamayın.
Yeni özellik klasörünü ilk gerçek dosyasıyla açın; oyun tasarımı belli olmadan özellik iskeletleri kurmayın.
Tek tüketicili yardımcı o özelliğin yanında kalır. UI aksiyon talep eder, domain/model kuralı uygular,
sunum sonucu gösterir; aynı kural bir panelde tekrar hesaplanmaz.

Kayıt sahibi `campaign/domain/save_store.gd`: otomatik `user://campaign_v1.json`,
manuel `user://manual_1_v1.json`–`manual_3_v1.json`; içerik sürümü 1.
Geçersiz kayıt ve değişmiş içerik kataloğu reddedilir; mevcut dosya korunur.
Slot özetleri aynı doğrulamadan geçer; bozuk ve boş kayıtlar yüklenemez.
`slot_directory` I/O sınırıdır; testler yalnız kendilerine ait izole dizini kullanır.
Oyunun adı Rewrite it'tir. Windows veri dizini eski `Godot/app_userdata/Civil Game Jam`
konumuna sabitlenmiştir; marka değişimi kayıtları taşımayı gerektirmez.

## Görünüm ve model sınırları

`ui_preview/main_preview.gd` yalnız birleştirme ve ekran yönlendirmesidir.
`map/` harita inputunu; `campaign/` HUD, menü ve kampanya ekranlarını;
`management/` şehir, proje ve araştırmayı; `crisis/` sevk, gazete ve raporları;
`logistics/` merkezler arasındaki birlik durumunun görünümünü sahiplenir.
`shared/` native UI bileşenleri ve ortak ekran çizimini içerir.
Ortak `UI.FONT`, `art/production/ui/p0/afet_pixel.aseprite` ve `.fnt` kaynağından
üretilen 126 glifli bitmap fonttur. Türkçe büyük/küçük harfler, `i/İ`–`ı/I` ayrımı,
düz/kıvrımlı kesme ve tırnak işaretleri aynı native atlasta bulunur; harf ilerlemesi 12 px'tir.
`UI.button()` eylem rengini açık `ButtonTone` parametresinden alır; başlık metninden tahmin etmez.
Başlatma, sevk ve güvenli onay yeşil; bütçe aktarımı ve proje duraklatma altın;
iptal, çıkış ve kayıt değiştiren son onay kırmızıdır. Gezinme, kapatma, miktar ve yıl
seçimi nötr mavidir.
Hover ve basılı durumlar eylem rengini korur; klavye odağı çerçeveyle görünür.
Devre dışı düğmeler bütün eylemlerde aynı soluk nötr görünümü kullanır.
HUD üst şeridinde bütçe, güven, bilinç, toplam birlik ve yardım stoğu solda;
takvim ve zaman kontrolleri sağda gösterilir.
Bütün HUD bilgileri tek ortak zemin kullanır; bilgi gruplarında ayrı dolgu veya çerçeve bulunmaz.
Birlik sayısı hazır, yolda, görevde ve dönüşteki ekipleri kapsar; yardım sayısı tüm merkezlerde
sevke hazır malzemeyi gösterir. Sayılar mevcut `Simulation.unit_overview()` özetinden alınır;
sevk edilmiş yardım merkez stoğuna dahil değildir. Tam değer ve ekip durumları tooltip'te korunur.
HUD'daki bütçe, güven ve bilinç ikonları mevcut 32×32 atlas hücrelerini 2× ölçekte,
aynı düşey hizada gösterir.
Takvim ve zaman kontrolleri sağda tek kompakt gruptadır. Tarih 36 px yazıyla,
üç harfli ay adıyla gösterilir; tam tarih tooltip'tedir. Normal/aylık ve müdahale/günlük
ayrımı, duraklatma durumu ve seçili hız görünür kalır. Bilinç değeri mor vurgulu puan alanındadır.
`TrustState.feedback()` güvenin 0–100 sınırını ve geçmişe gerçekten uygulanmış son değişimi
salt okunur sunar. HUD güveni iki, son değişimi üç ondalıkla gösterir; dönemsel değişim varsaymaz.
Sıfır güvenin kampanyayı bitirdiği ve son değişimin nedeni tooltip'tedir.
Hız düğmelerinin basılı durumu seçili hızı korur; ayrı metin çalışan hızı veya duraklatılmışken
seçili hızı belirtir. Bu alanlar simülasyon yenilemesinde yerinde güncellenir.
`shared/ui_kit.gd`, açılışta native Aseprite imleçlerini donanım imleci olarak yükler;
normal ok, düğme, harita taşıma ve sürükle-bırak durumları ortak paleti kullanır.
Kaynak ve hotspot sözleşmesi [imleç rehberindedir](../art/production/ui/cursors/README.md).
Her modül kendi görünüm durumunu tutar; diğer modülün özel alanına erişmez.
Harita/HUD/şehir sinyalleri ana dosyada bağlanır; modal ekranlar ana dosyanın dar gezinme API'sini kullanır.
Ana menü ve kampanya seçimi ayrı tam ekran akışıdır. `in_frontend` açıkken ortak oyun görünümü gizlenir;
oyun içi menü yalnız duraklatma/ayarları sunar. Yeni kampanyaya oyun içinden doğrudan yönlendirme yoktur.
Ana menüye dönüş kaydı tamamlar; başarısız kayıtta mevcut oyun ekranı korunur.
`campaign/save_screens.gd` yuva seçimini, onay ve uyarıları sunar; dosya doğrulaması
`SaveStore`'da, aktif simülasyonu değiştirme kararı ana koordinatörde kalır.
`campaign/display_settings.gd` görüntü modunun tek sahibidir: tam ekran (exclusive),
kenarlıksız tam ekran ve kenarlı pencere. Proje varsayılanı tam ekrandır; geçerli son seçim
`user://preferences.cfg` içindeki `display/mode` alanından uygulanır. Pencere modu
tam ekrandan kalan borderless bayrağını temizler. F11 seçili tam ekran türü ile pencereyi değiştirir;
bu tür `display/fullscreen_mode` alanıyla pencere modunda kaydedilse de korunur.
Esc oyun içi duraklatma menüsünü açar; menü kapanınca önceki ekran ve takvimin çalışma durumu
geri gelir. Haber/rapor/sonuç menünün altında bekler, kabul edilmiş sayılmaz.
Bu menü ve alt ekranları açıkken simülasyon yenilemesi zorunlu haber ekranını öne taşımaz.
Ana menü splash art'ı `art/production/ui/main_menu/night_operations.aseprite` kaynağından
export edilir; canlı başlık ve düğmeler resme gömülmez.
Harita 3072×1728 native tuvali 1920×1080 viewport'un arka planında gösterir; bir panel çerçevesine sığdırılmaz.
`art/production/ui/p0/map-general.aseprite` içindeki arazi katmanları, aynı native boyutta
şeffaf `ui_preview/assets/map-terrain.png` olarak ayrı export edilir. `map_view.gd` bu görseli
harita resminin kalıcı `TerrainDetails` çocuğunda, veri rengi üstünde ve seçim/etiket/işaretçi
altında gösterir. Katman aynı nearest filtreyi ve 1×–3× kamera pan/zoom dönüşümünü miras alır;
input yakalamaz. Yalnız Bölgeler modunda görünür; sayısal modların renk ve lejantını etkilemez.
Arazi ayrıntıları görseldir; kaynak, yolculuk, afet veya kayıt modeline yeni kural eklemez.
Ana dosya haritayı HUD ve şehir panelinden önce ekler. Harita, maskeler ve etiketler aynı kamera dönüşümünü
paylaşır; 1× ölçekte pan ve 1–3× yakınlaştırma kullanılır. Ülke katmanları yalnız görseldir.
Harita araçları sol altta kalıcı, başlangıçta kapalı bir çubuktadır. Seçili görünümü belirten
düğme çubuğu sağa açar; sıfırlama ve yakınlaştırma her zaman erişilebilirdir. Açıldığında
dört görünüm düğmesi sağa, açıklama ve renk lejantı da bu düğmelerin üstüne yerleşir.
Şehir/hazırlık ve kriz/birlik panelleriyle çakışmaz. Açık/kapalı durum, mod, kamera ve odak
simülasyon yenilemesinde korunur; oyuncu kayıtlarına yeni alan eklenmez.
Bildirim şeridi kalan sağ alanı kullanır; dar alanda metin kısalır, tamamı tooltip'te korunur.
Yakınlık etiketi geçerli ölçeği gösterir; 1×–3× sınırlarında ilgili yakınlaştırma düğmesi kapanır.
Mod adları gösterilen veriyi belirtir: Bölgeler, Hazırlık, Yardım Stoğu ve Hasar.
Bölgeler lejantı native haritanın yedi rengini tam bölge adlarıyla eşler; renklerin risk göstermediğini belirtir.
Sayısal modlarda aynı mavi–turkuaz–altın ölçek düşük değerden yüksek değere gider;
lejantta birimler ve örnek değerler, merkezin üzerine gelince gerçek değer görünür.
`Simulation.map_overlay()` beş afet hazırlığının ortalamasını, merkez stoğunu veya altyapı hasarını
salt okunur sunar. Stok için 160 yalnız renk doygunluğu eşiğidir, envanter kapasitesi değildir.
Veri rengi opaktır; alttaki bölge rengiyle karışmaz. Shader seçilebilir il kenarını korur,
diğer 60 pasif ilin native çizimi değişmez. Aktif kriz bölgesi bütün modlarda kırmızı
gösterilir; `!` işareti ve kırmızı lejant anahtarı bu vurguyu açıklar. Sayısal modun
gerçek değeri hover bilgisinde korunur. Son aktif kriz bitince ilin bölge/veri rengi geri gelir.
Yeni afetin kısa kırmızı uyarısı ve 0,30 saniyelik sarsıntısı olay başına bir kez oynar.
Harita aynı ofseti sinyalle HUD'a iletir; kamera koordinatları ve modal paneller sabit kalır.
Afet sarsıntısı kapatıldığında harita/HUD anında yerine döner; kırmızı bölge ve kısa uyarı sürer.
Yenileme ve kayıt yükleme başlangıç efektini tekrar oynatmaz. Kayıt veya oyun dengesi değişmez.
Üst gezintide Birlikler/Kriz Merkezi/Hazırlık Planla, geliştirme ve kayıt/haber erişimlerinden önce birlikte yer alır.

`LogisticsSystem.unit_overview()` hazır ekipleri kaynak merkez envanterinden, yol/görev/dönüş
sayılarını aynı merkeze ait ekip sevkiyatlarından, toplam yardım stoğunu merkez envanterlerinden
salt okunur toplar. Tamamlanmış ve yardım türü
sevkiyatlar ekip durumuna eklenmez. `Simulation.unit_overview()` sevk formuna geçiş uygunluğunu ekler;
yeni kayıt alanı veya sevk komutu yoktur. `logistics/units_panel.gd` bu sorguyla 21 merkezi gösterir,
yenilemede satırları, odak ve kaydırmayı korur. Merkez erişimi şehir lojistiğini açar;
Sevk Aç mevcut kaynak seçimli kriz formuna gider, birden fazla krizde hedefi oyuncu seçer.

Üç geliştirici için dosya paylaşımı, ortak sözleşme ve kabul komutları
[paralel çalışma rehberinde](team-workflow.md) bulunur.

`Simulation` bir `RefCounted` koordinatörüdür; UI düğümlerini veya dosya kaydını bilmez.
Modeller arasında doğrudan bağımlılık yalnız gereken nesnelere verilir; global autoload yoktur.
Bir günün sırası: ay sınırında gelir/bakım/projeler, sevkiyat varışı, günlük müdahale/rapor,
tarihsel afet başlangıçları, güven ve 2026 sınırı. Gazete/rapor kuyruğu takvimi durdurur.
`DisasterModel` iki gerçek alt tipe ayrılır: ani afetlerde ilk günler daha ağır; devam eden
sel/yangında günlük tehlike süre boyunca eşit işlenir. İnsan sonuçları model tahminidir.
Lojistik ekipleri sayılı gruplar olarak rezerve eder; her grubun tek sevkiyat durumu vardır.
UI'daki sürükleme ve sevk formu aynı `Simulation.dispatch` komutunu çağırır.

Haritada hazırlık emrinin görünümü `management/preparation_panel.gd` içindedir.
`Simulation.enqueue_preparation` yalnız ekip kurma/yardım stoğu emri kabul eder;
`preparation_plan` ücret, bakım, merkez kapasitesi ve sıra durumunu salt okunur sunar.
UI taksit veya slot formülü hesaplamaz. Panel satırları ve harita işaretçileri yerinde güncellenir.
`ProjectSystem` aynı `ActiveProject` kayıtlarını `queued` durumunda tutar; şehir başına
`sequence` sırası kullanılır. Bekleyen kayıt slot, ödeme, ilerleme veya etki üretmez.
Boş şehirde emir hemen aktiftir; aylık ödeme turu bittikten sonra boşalan slotta sıradaki iş
aktifleşir ve ilk taksitini sonraki ay öder. İptal de boşalan slotun sırasını çalıştırır.
Elle duraklatma anında otomatik sıra çalıştırılmaz; aynı türde duraklatılmış iş sıra başını engeller.
Yükleme sırasında sıra çalıştırılmaz. Kayıt sürümü 1 ve alan yapısı korunur;
eski kayıtlar yüklenir, `queued` içeren yeni kayıtlar bu durumu tanımayan eski binary ile açılamaz.

Proje ayrıntılarında `ProjectSystem.effect_preview()` yalnız seçilen projenin tamamlanmasını
salt okunur bir kopyada uygular. Aynı `preparedness`, `infrastructure`, `get_effect` ve gelir
sorguları şimdiki değerle karşılaştırılır; mevcut bakım verimi ve diğer durumlar sabittir.
Yerel etkiler seçili merkezi, ulusal etkiler merkezlerin ortalamasını gösterir.
Araştırma kapasitesi ortak ulusal slot sayısıdır; ortalama olarak sunulmaz.
Başka bekleyen projeler tamamlanmış sayılmaz. Mevcut model sınırları uygulanır;
sınırsız ekip, stok ve bonuslarda çubuğun gösterim ölçeği kapasite sınırı olarak sunulmaz.
`project_screens.gd` her etkiyi beyaz mevcut değer çizgisi ve renkli tamamlanma çizgisiyle
gösterir. İyileşme yeşil, olumsuz değişim kırmızı; sayısal farkın işareti ayrıca yazılır.
Hasarın azalması da iyileşmedir. Çubuklar salt okunur, uzun etki listeleri kaydırılabilirdir.
Onarımda kalan hasar, direnç ve gelir değişimi aynı sunumu kullanır. Gameplay kataloğu,
etki doğrulaması ve oyuncu kayıt biçimi değişmez.

Aktif kataloglar `regions/data/service_areas.json`, `management/data/measures.json`,
`events/data/historical/events.json` dosyalarıdır. `events/historical/events.json` özgün arşivdir;
runtime okumaz. Tarih/ad/açıklama/kayıp referansı korunur, eski belirsiz `duration` yerine
oyun gününü açıkça belirten `response_window_days` kullanılır. Ayrı karar olayları eklenmedi.

Gazete fotoğraflarını `ui_preview/crisis/news_photos.gd` sunum eşlemesi seçer: 59 olayın
kararlı ID'si mevcut JPEG'lere bağlanır; diğer 40 haber afet türüne uygun beş temsili
görselden birini kullanır (`fire` → `_fallback_wildfire.jpg`). Eksik olay görselinde de
tür görseline dönülür. Gazete modalinin 1440×840 kâğıdı viewport'un ortasındadır;
`news_reports.gd` eşit iki sütunda haber metnini ve fotoğrafı ayırır. Tüm görseller aynı
640×360 alana oranı korunarak, kırpılmadan sığar; farklı oranlarda kâğıt tonlu boşluk kalır.
`crisis/newsprint.gdshader`, yalnız fotoğrafları parlaklıklarına göre yedi sıcak mürekkep/kâğıt
tonuna posterize eder. Orijinal JPEG'ler korunur; görseller yeniden üretilmez veya kırpılmaz.
Temsili görseller açıkça etiketlenir. Özgün arşiv runtime'da okunmaz; aktif olay JSON'u,
katalog fingerprint'i ve kayıt biçimi bu sunum verisinden etkilenmez. Rapor ekranı kendi
yerleşimini kullanmayı sürdürür; haber kabulü ve Esc menüsünün davranışı değişmez.

`events/data/historical/aftermath.json`, olayları `event_id` üzerinden kaynaklı afet sonrası
kararlarla ilişkilendirir; temel afet alanlarını tekrarlamaz. Ortak araştırma notu bir kez tutulur,
yalnız özel notu veya eylemi olan olaylar `entries` içine yazılır.
`management/data/preventive_actions.json`, `id`, `title`, `description` alanlarıyla içerik önerilerini
tutar. İki katalog da `check:data` kapsamındadır; tarihsel kararlar ve öneriler runtime tedbiri
veya seçenekli olay değildir. Maliyet ve etki sahibi `management/data/measures.json` olarak kalır.
Bu ek içerikler simülasyonun katalog fingerprint'ine dahil edilmez.

Kriz sevk paneli ve harita işaretçileri simülasyon güncellemesinde korunur; alanlar
yerinde güncellenir. Sağdaki kriz paneli haritayı kapatmaz; modal gazete/raporlar
takvimi durdurmaya devam eder. Kriz panelinin Devam/Duraklat eylemi aynı takvimi yönetir.
`Simulation` salt okunur `crisis_feedback`, `dispatch_options`, `dispatch_preview`,
`quick_dispatch_preview`, `missing_dispatch_amount` ve `report_feedback` sorgularını sunar.
`shipment_progress`, kriz gününün mevcut takvim kesrini yalnız yolculuk sunumuna verir.
Eksik ihtiyaç zamanında varacak aynı kriz/türdeki sevkleri içerir; geç varış ayrı kalır.
`quick_dispatch` sabit 1 ekip/10 yardım için ihtiyacı yeniden doğrular ve mevcut
`dispatch` komutuna gider. Standart form ve drag/drop aynı komutta kalır.
Kayıt sürümü ve kayıt alanları değişmez. Temsili operasyon sahnesi yalnız izole
A/B sürücüsünün B görünümünde açılır; native kaynak/export eşlemesi
[pilot art rehberinde](../art/production/ui/crisis_pilot/README.md) tutulur.
