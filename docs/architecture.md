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
| `our-game/events/`            | Tarihsel afet kataloğu ve 21 kalıcı afet sonrası karar                 |
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

Kayıt sahibi `campaign/domain/save_store.gd`: otomatik `user://campaign_v4.json`,
manuel `user://manual_1_v4.json`–`manual_3_v4.json`; içerik sürümü 4.
Kondisyon, afet hasarı partileri ve taahhüt takibi yeni kampanya gerektirir; sürüm 1/2/3 kayıtları taşınmaz.
Eski kayıt dosyaları değiştirilmez. Karar kartı/proje durumu yeni kayıtta korunur.
`ServiceArea.condition` merkezdeki ekip ve fiziksel tesislerin ortak kondisyonudur;
`ProjectSystem` yaşlanmayı, yenileme bedelini ve etkilerini hesaplar. Ekipler başka merkezde
konuşlanırken kondisyon sahipliği asıl üslerinde kalır. `TrustState.damage_records`, her afetin
gerçek hasarını, altı aylık süresini ve uygulanmış ihmal kaybından geri alınabilecek payı saklar.
`DecisionSystem` taahhüdün son gerçek ilerlemesini ve son aylık denetimini saklar.
Geçersiz kayıt ve değişmiş içerik kataloğu reddedilir; mevcut dosya korunur.
İki günlük müdahale uzatmasından hemen önceki bilinen sürüm 4 katalog hash'i ayrıca tanınır.
Önce eski sürelerle bütün kayıt doğrulanır; ardından aktif ve gelecek krizlere iki gün eklenir.
Bitmiş raporların günleri ve sonuçları korunur; bu geçmiş pencereler yeniden kayıtta da doğrulanır.
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
HUD üst şeridinde bütçe, Halkın Güveni, Bilinç Puanı, hazır ekip ve Yardım Malzemesi solda;
takvim ve zaman kontrolleri sağda gösterilir.
Bütün HUD bilgileri tek ortak zemin kullanır; bilgi gruplarında ayrı dolgu veya çerçeve bulunmaz.
Büyük ekip sayısı yalnız hazır ekipleri gösterir; alt satırdaki toplam, yolda, görevde ve dönüşteki ekipleri de kapsar. Yardım sayısı tüm merkezlerde
sevke hazır malzemeyi gösterir. Sayılar mevcut `Simulation.unit_overview()` özetinden alınır;
sevk edilmiş yardım merkez stoğuna dahil değildir. Tam değer ve ekip durumları tooltip'te korunur.
HUD'daki bütçe, güven ve bilinç ikonları mevcut 32×32 atlas hücrelerini 1,5× ölçekte,
aynı düşey hizada gösterir. Üst şerit 112 px yüksekliğindedir; 18 px başlıklar,
30 px ana değerler ve 18 px açıklamalar arasında en az 6 px boşluk bırakılır.
Net gelir ve toplam ekip açıklamaları tek satırdır; gelir hesabının ayrıntısı tooltip'tedir.
Takvim ve zaman kontrolleri sağda tek kompakt gruptadır. Tarih 30 px yazıyla,
üç harfli ay adıyla gösterilir; tam tarih tooltip'tedir. Normal/aylık ve müdahale/günlük
ayrımı, duraklatma durumu ve seçili hız görünür kalır. Bilinç değeri mor vurgulu puan alanındadır.
`TrustState.feedback()` güvenin 0–100 sınırını ve geçmişe gerçekten uygulanmış son değişimi
salt okunur sunar. HUD güveni iki, son değişimi üç ondalıkla gösterir; dönemsel değişim varsaymaz.
Sıfır güvenin oyunu bitirdiği görünürdür; son değişimin nedeni tooltip'tedir.
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
`core/audio/game_audio.gd` müzik/efekt oynatımının ve ses tercihlerinin tek sahibidir.
`eren/sounds` kaynaklı altı WAV `assets/sounds/` altında import metadata'sıyla korunur.
58 saniyelik ana müzik açılış tamamlanınca başlar, ileri yönde döngüye girer ve menü/kampanya
geçişlerinde kesilmez. Simülasyonu duraklatmak müziği durdurmaz. Ayarlarda müzik aç/kapat,
bulunduğu yerde duraklat/sürdür ve ayrı müzik/efekt yüzde slider'ları bulunur.
Kapatılan müzik yeniden açılınca baştan başlar; duraklatma geçicidir.
Müzik açık/kapalı tercihi ve iki ses düzeyi `preferences.cfg` içindeki `audio` bölümünde,
mevcut görüntü/görsel tercihler korunarak saklanır; kampanya kaydına eklenmez.
Pencereyi veya ÇIKIŞ düğmesini kullanarak kapatma, bekleyen ses tercihini kaydeder ve ses
iş parçacığının oynatımı bırakması için `audio.shutdown()` tamamlandıktan sonra çıkar.
Ortak UI düğmeleri tıklama, `command_result` başarılı/başarısız işlemler için onay/ret sesi çalar.
Yeni afet sesi mevcut olay-ID defterini kullanır; yenileme/yükleme eski uyarıyı tekrarlamaz.
`Simulation.reward_earned` proje/araştırma/onarım tamamlanmasında ve bilinç toplamada yayımlanır;
sunum bu sinyali tamamlanma sesine bağlar. Oyun modeli ses dosyalarını bilmez.
Esc oyun içi duraklatma menüsünü açar; menü kapanınca önceki ekran ve takvimin çalışma durumu
geri gelir. Haber/rapor/sonuç menünün altında bekler, kabul edilmiş sayılmaz.
Bu menü ve alt ekranları açıkken simülasyon yenilemesi zorunlu haber ekranını öne taşımaz.
Ana menü splash art'ı `art/production/ui/main_menu/night_operations.aseprite` kaynağından
export edilir; canlı başlık ve düğmeler resme gömülmez.
Harita 3072×1728 native tuvali 1920×1080 viewport'un arka planında gösterir; bir panel çerçevesine sığdırılmaz.
Harita dağ, orman/bozkır ve kıyı dokusu gibi dekoratif arazi ayrıntıları göstermez.
`art/production/ui/p0/map-general.aseprite` içindeki arazi katmanları ve ayrı
`ui_preview/assets/map-terrain.png` export'u düzenlenebilir kaynaklar olarak korunur;
`map_view.gd` bu görseli yüklemez. Bu görsel değişiklik kaynak, yolculuk, afet veya kayıt
modelini etkilemez.
Ana dosya haritayı HUD ve şehir panelinden önce ekler. Harita, maskeler ve etiketler aynı kamera dönüşümünü
paylaşır; 1× ölçekte pan ve 1–3× yakınlaştırma kullanılır. Ülke katmanları yalnız görseldir.
Harita araçları sol altta kalıcı, başlangıçta kapalı bir çubuktadır. Seçili görünümü belirten
düğme çubuğu sağa açar; sıfırlama ve yakınlaştırma her zaman erişilebilirdir. Açıldığında
dört görünüm düğmesi sağa, açıklama ve renk lejantı da bu düğmelerin üstüne yerleşir.
Şehir/hazırlık ve kriz/birlik panelleriyle çakışmaz. Açık/kapalı durum, mod, kamera ve odak
simülasyon yenilemesinde korunur; oyuncu kayıtlarına yeni alan eklenmez.
Bildirim şeridi kalan sağ alanı kullanır; dar alanda metin kısalır, tamamı tooltip'te korunur.
Yakınlık etiketi geçerli ölçeği gösterir; 1×–3× sınırlarında ilgili yakınlaştırma düğmesi kapanır.
Mod adları gösterilen veriyi belirtir: Bölgeler, Afet Hazırlığı, Yardım Malzemesi ve Altyapı Hasarı.
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
Üst gezinti altı girişten oluşur: Ekipler ve Yardım, Afet Müdahalesi, Ekip ve Yardım Hazırla, Yatırım ve Araştırma, Olaylar ve Menü.
Afet Müdahalesi aktif kriz sayısını gösterir. Yatırım ve Araştırma, Projeler/Önlemler/Araştırma
sekmelerini aynı pencere altında toplar; oturum içinde son sekme ve liste kaydırması korunur.
Araştırmanın kategori ve önkoşul ağacı ile kapasite sayacı kendi sekmesindedir.
Araştırma ağacı dört kategoride 1950/1970/1990/2005/2020 sütunlarını kullanır; her
kategori/dönemde iki araştırma vardır. Oklar gerçek önkoşulları gösterir; kategori dışı
bağlantı doğru karta gider. `ProjectSystem.requirement_status()` tarih ve bütün araştırma
koşullarını ayrı sunar; `unlocks_for()` doğrudan açılan içerikleri aynı katalogdan türetir.
Ulusal önlemler dönem başlıkları altında listelenir. Araştırma bağlantıları, ayrıntı ve geri
dönüş kategori, odak ve kaydırmayı oturum içinde korur. Kısa ve uzun açıklamalar
`MeasureCopy` sunum kaynağındadır; bedel, etki ve bağımlılık verisi gameplay kataloğunda kalır.
Haberler ve Raporlar, son haber/afet raporu ekranlarını açan küçük bir menüdür; dış tıklama veya Esc yalnız bu
menüyü kapatır. Otomatik haber/rapor kuyruğunun onay ve duraklatma davranışı korunur.
Şehir yatırımları, ulusal tedbirler ve proje takibi kaydırılabilir özet satırlar kullanır;
ayrıntıdan geri dönüş geldiği sekmeyi veya şehir yatırım listesini, odak ve kaydırmayı korur.
Ekip/yardım üretiminin tek UI girişi Ekip ve Yardım Hazırla'dır; şehirdeki yatırım ve lojistik
görünümlerinde bu üretim düğmeleri yoktur. Şehir lojistiği kaynak merkezini koruyan
Gönderim Hazırla eylemini ve haritaya sürükleyerek sevki sunar.

`LogisticsSystem.unit_overview()` hazır ekipleri kaynak merkez envanterinden, yol/görev/dönüş
sayılarını aynı merkeze ait ekip sevkiyatlarından, toplam yardım stoğunu merkez envanterlerinden
salt okunur toplar. Tamamlanmış ve yardım türü
sevkiyatlar ekip durumuna eklenmez. `Simulation.unit_overview()` sevk formuna geçiş uygunluğunu ekler;
yeni kayıt alanı veya sevk komutu yoktur. `logistics/units_panel.gd` bu sorguyla 21 merkezi gösterir,
yenilemede satırları, odak ve kaydırmayı korur. Merkez erişimi şehir lojistiğini açar;
Gönderim Hazırla mevcut kaynak seçimli kriz formuna gider, birden fazla krizde hedefi oyuncu seçer.

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
Yükleme sırasında sıra çalıştırılmaz. Karar projeleri de aynı yerel/ulusal slotu ve
`sequence` sırasını kullanır. Sürüm 2 karar kayıtlarını eski binary açamaz.

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
oyun gününü açıkça belirten `response_window_days` kullanılır.
`events/data/decisions.json`, 20 kaynak afete bağlı 21 karar kartını tanımlar.
`DecisionCatalog` referansları doğrular; `DecisionSystem` teklif, seçim ve bağlı proje
kayıtlarını sahiplenir. Maliyet, süre ve kalıcı etkiler `management/data/measures.json`
ve `ProjectSystem` üzerinden uygulanır. Son alan raporu okunduğunda kararlar sıraya
eklenir; seçim yapılmadan takvim ilerlemez. Seçim kalıcıdır; iptal ve farklı bir ekran
kararı yeniden açmaz. Marmara/Düzce denetimi ortak karardır; İliç maden kararı kapsam dışıdır.
Kart listesi ve ilk denge değerleri [karar rehberindedir](decision-events.md).

Gazete fotoğraflarını `ui_preview/crisis/news_photos.gd` sunum eşlemesi seçer: 59 olayın
kararlı ID'si mevcut JPEG'lere bağlanır; diğer 40 haber afet türüne uygun beş temsili
görselden birini kullanır (`fire` → `_fallback_wildfire.jpg`). Eksik olay görselinde de
tür görseline dönülür. Gazete modalinin 1440×840 kâğıdı viewport'un ortasındadır;
`news_reports.gd` eşit iki sütunda haber metnini ve fotoğrafı ayırır. Tüm görseller aynı
640×360 alana oranı korunarak, kırpılmadan sığar; farklı oranlarda kâğıt tonlu boşluk kalır.
`crisis/newsprint.gdshader`, yalnız fotoğrafları parlaklıklarına göre yedi sıcak mürekkep/kâğıt
tonuna posterize eder. Orijinal JPEG'ler korunur; görseller yeniden üretilmez veya kırpılmaz.
Fotoğrafların altında genel açıklama gösterilmez. Özgün arşiv runtime'da okunmaz; aktif olay JSON'u,
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
`quick_dispatch` sabit 1 ekip/10 yardım için ihtiyacı yeniden doğrulayan model komutudur.
UI'da 1 Ekip Seç/10 Yardım Seç yalnız tür ve miktarı, Eksik Kadar Seç yalnız mevcut türün
miktarını doldurur; bu seçimler harcama yapmaz. Tek Sevk Et düğmesi ve drag/drop mevcut
`dispatch` komutunu kullanır. Sevk paneli ihtiyaç, toplam ücret, yol süresi ve işlem hatasını
görünür tutar; uzun yolculuk açıklaması kısa özet ve tooltip olarak sunulur.
Günlük ikmal ve konuşlandırma kayıt sözleşmesi aşağıdadır. Temsili operasyon sahnesi yalnız izole
A/B sürücüsünün B görünümünde açılır; native kaynak/export eşlemesi
[pilot art rehberinde](../art/production/ui/crisis_pilot/README.md) tutulur.

## Arayüz metinleri ve açıklamalar

Oyuncuya görünen dil gündelik Türkçedir. Üst menü Ekipler ve Yardım, Afet Müdahalesi,
Ekip ve Yardım Hazırla, Yatırım ve Araştırma, Haberler ve Raporlar ve Menü girişlerini kullanır.
Yatırım sekmeleri Projeler, Önlemler ve Araştırmalar'dır. Teknik proje adları korunur;
`ui_preview/management/measure_copy.gd` kısa açıklamaların tek sunum kaynağıdır. Açıklamalar
listelerde ve ayrıntılarda görünür. Satır yüksekliği okunabilir metne göre artabilir.
Bu metinler gameplay kataloğuna eklenmez; içerik parmak izi ve kayıt biçimi değişmez.

Merkez başlığı İstanbul ve Çevresi biçimindedir; nüfus ve gelir bağlı illeri kapsar.
Bütçe altındaki son ay değeri gelir eksi bakımdır; proje taksitleri hariç olduğu görünürdür.
Gönderim Hazırla formu açar; Gönderimi Onayla seçili miktarı gönderir. Sürükleme her zaman
1 ekip veya 10 birim yardım malzemesi gönderir. Varış ve taşıma bedeli ayrı adlandırılır.
Zamanı Başlat / Zamanı Durdur tüm simülasyon zamanını kontrol eder.

## Günlük ikmal ve geçici konuşlandırma

`LogisticsSystem.stationed`, hazır misafir ekipleri `home`, `location`, `amount` ile tutar.
`ServiceArea.teams` yalnız asıl merkezinde hazır ekipleri; `total_teams` merkeze bağlı bütün
ekipleri sayar. Sevkiyattaki `source` çıkış, `home` asıl merkezdir; `purpose` kriz görevi ve
merkez transferini ayırır. Görevden dönüş mesafesi afet alanından asıl merkeze hesaplanır.
Transferde yardım hedef depoya, ekip geçici konuma geçer; geri çağırma ayrı tek yön emridir.
Birlik görünümü hazır ekipleri bulundukları yerde, bağlı toplamları asıl merkezde gösterir.

`CrisisSystem.supply_forecast` bütün varışları gün bazında toplar, kapasiteyi tüketimden önce
kontrol eder ve sonraki günlerin tüketimini yürütür. Sevk önizlemesi, miktar doldurma ve
kritik duruş aynı salt okunur tahmini kullanır. `has_shortage` eksik günün varlığını belirtir;
1970 öncesi gün sayıları negatif olduğu için tarihin işaretiyle yokluk sınanmaz.
Gerçek günlük destek tüketilebilen yardımdan gelir. `consumed_stock` ve `aid_coverage_sum`
tüketimi ve rapor/güvenin günlük ortalamasını saklar; kalan saha stoğu raporda hedef depoya döner.

`Simulation.transfer_preview`, `transfer_resources` ve `recall_teams` arayüz sınırıdır.
Sevk komutları isteğe bağlı asıl merkez kimliğiyle misafir grubu seçer. Üç gün içinde açık
gören çalışan takvim gün işlemi sonunda durur ve `supply_warning_requested` üretir.
`supply_alerted` çözülmemiş aynı açığın duruşunu tekrarlamaz; yeterli ikmal sonrası yeniden kurulur.

## Uygulamalı kampanya rehberi

Temel alıştırmaların hemen ardından `finish` bilgi adımı Oyunu Bitir onayını, kapanış
gazetesinin içeriğini ve otomatik/üç manuel kaydın kalıcı silinmesini açıklar. Anladım
yalnız dersi tamamlar; oyun bitirme veya kayıt silme komutu çalıştırmaz.

`campaign/domain/campaign_guide.gd` kampanya başına rehber durumunun tek sahibidir.
Tamamlanan ve atlanan adımlar, etkin ders, kriz kesintisinden dönüş ve ilgili kriz kimliği
burada tutulur. Başarılı domain komutları yatırım, teknik araştırma, bilinç, ekip, yardım,
sevk, gazete/rapor ve baloncuk ilerlemesini kaydeder. Harita ve ekran etkileşimleri yalnız
kendi başarılı seçimlerini bildirir. Scheduler zamanı değiştirmez; UI yeni dersi ilk kez
sunarken duraklatır. Okuma sonrası zamanı başlatmak oyuncunun eylemidir.

`ui_preview/campaign/tour_guide.gd` görev kartı, metin, öneri ve hedef vurgusunu sunar.
Öneriler mevcut `availability`, `preparation_plan` ve sevk önizlemelerine dayanır.
Düğmeler `guide_target` kimliğiyle bulunur; kırpma, kaydırma ve harita dönüşümü güncel
hedef geometrisine uygulanır. Kart dışındaki görsel katman inputu engellemez. Ana
koordinatör yalnız kampanya, ekran ve menü yaşam döngüsünü bağlar. Rehber durumu/modeli
her karede yeniden hesaplanmaz; simülasyon veya gezinme değişince yenilenir.

Sürüm 4 kayıtlarında `guide` isteğe bağlıdır. Bulunursa tipler, bilinen/benzersiz adımlar
ve gerçek aktif afet/rapor referansı doğrulanır; geçersiz veri reddedilir. Alanı olmayan
mevcut v4 kayıtları yüklenir ve yeni tur kapalı kalır; menüden etkinleştirilebilir.
Kayıt yolları, sürüm numarası ve gameplay katalog parmak izi değişmez. Eski dört adımlık
`tutorial` alanları kayıt uyumluluğu için korunur; uygulamalı turu yönetmez.

## Kapanış gazetesi

`CampaignRetrospective.build` kampanya durumunu değiştirmeden olayları `event_id` ile
birleştirir. Sonuçlar yalnız tamamlanan merkez raporlarından gelir; süren afetler ayrı
kalır. Tamamlanan işler gerçek proje kayıtlarından alınır; dönem başlangıcında hazır
gelen araştırmalar oyuncu katkısı sayılmaz. Kişi toplamları olay bazlı simülasyon
tahminidir, benzersiz nüfus sayısı veya tek bir önlemin ayrı etkisi değildir.

`ui_preview/campaign/ending_newspaper.gd` üç sayfalı anlatımı, afet listesini ve
tamamlanan/yarım kalan çalışmaları sunar. Gönüllü bitirişte önce onay alınır, gazete
verisi bellekte hazırlanır, otomatik kayıt durdurulur ve `SaveStore.clear_campaign_slots`
yalnız dört v4 yuvasını ve ilgili `.tmp` dosyalarını siler. Çoklu dosya silme atomik
değildir; hata kısmi silinme olabileceğini belirtir, yeniden deneme güvenlidir.
Silme hatasında oyun bellekte tutulur; vazgeçilirse önceki otomatik kayıt durumu geri gelir.
Başarıdan sonra kayıt, ESC ve çıkış akışı silinen kayıtları yeniden oluşturmaz.
Yeni oyun/yükleme bu geçici oturum durumunu sıfırlar. 2026 ve güven tükenmesi aynı
gazeteyi gösterir; bu doğal bitişler kayıtları silmez. Kayıt biçimi ve katalog hash'i değişmez.
