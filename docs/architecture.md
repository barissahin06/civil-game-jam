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
Oyunun adı Revert it'tir. Windows veri dizini eski `Godot/app_userdata/Civil Game Jam`
konumuna sabitlenmiştir; marka değişimi kayıtları taşımayı gerektirmez.

## Görünüm ve model sınırları

`ui_preview/main_preview.gd` yalnız birleştirme ve ekran yönlendirmesidir.
`map/` harita inputunu; `campaign/` HUD, menü ve kampanya ekranlarını;
`management/` şehir, proje ve araştırmayı; `crisis/` sevk, gazete ve raporları sahiplenir.
`shared/` native UI bileşenleri ve ortak ekran çizimini içerir.
Her modül kendi görünüm durumunu tutar; diğer modülün özel alanına erişmez.
Harita/HUD/şehir sinyalleri ana dosyada bağlanır; modal ekranlar ana dosyanın dar gezinme API'sini kullanır.
Ana menü ve kampanya seçimi ayrı tam ekran akışıdır. `in_frontend` açıkken ortak oyun görünümü gizlenir;
oyun içi menü yalnız duraklatma/ayarları sunar. Yeni kampanyaya oyun içinden doğrudan yönlendirme yoktur.
Ana menüye dönüş kaydı tamamlar; başarısız kayıtta mevcut oyun ekranı korunur.
`campaign/save_screens.gd` yuva seçimini, onay ve uyarıları sunar; dosya doğrulaması
`SaveStore`'da, aktif simülasyonu değiştirme kararı ana koordinatörde kalır.
Ana menü splash art'ı `art/production/ui/main_menu/night_operations.aseprite` kaynağından
export edilir; canlı başlık ve düğmeler resme gömülmez.
Harita 3072×1728 native tuvali 1920×1080 viewport'un arka planında gösterir; bir panel çerçevesine sığdırılmaz.
Ana dosya haritayı HUD ve şehir panelinden önce ekler. Harita, maskeler ve etiketler aynı kamera dönüşümünü
paylaşır; 1× ölçekte pan ve 1–3× yakınlaştırma kullanılır. Ülke katmanları yalnız görseldir.

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

Aktif kataloglar `regions/data/service_areas.json`, `management/data/measures.json`,
`events/data/historical/events.json` dosyalarıdır. `events/historical/events.json` özgün arşivdir;
runtime okumaz. Tarih/ad/açıklama/kayıp referansı korunur, eski belirsiz `duration` yerine
oyun gününü açıkça belirten `response_window_days` kullanılır. Ayrı karar olayları eklenmedi.

`events/data/historical/aftermath.json`, olayları `event_id` üzerinden kaynaklı afet sonrası
kararlarla ilişkilendirir; temel afet alanlarını tekrarlamaz. Ortak araştırma notu bir kez tutulur,
yalnız özel notu veya eylemi olan olaylar `entries` içine yazılır.
`management/data/preventive_actions.json`, `id`, `title`, `description` alanlarıyla içerik önerilerini
tutar. İki katalog da `check:data` kapsamındadır; tarihsel kararlar ve öneriler runtime tedbiri
veya seçenekli olay değildir. Maliyet ve etki sahibi `management/data/measures.json` olarak kalır.
Bu ek içerikler simülasyonun katalog fingerprint'ine dahil edilmez.
