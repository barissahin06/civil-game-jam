# Gameplay veri şemaları

`our-game/<feature>/data/<name>.json` karşılığı `schemas/<feature>/<name>.schema.json`.
Alt klasörler korunur. `npm run check:data` eksik şema veya geçersiz veride başarısız olur;
kataloglar arasındaki bilinmeyen ve tekrarlanan kimlikleri de reddeder.

| Veri                                      | Sahibi ve amacı                                                             |
| ----------------------------------------- | --------------------------------------------------------------------------- |
| `events/data/historical/events.json`      | 99 afetin kararlı kimlikleri ve çalışan simülasyon değerleri                |
| `events/data/historical/aftermath.json`   | `event_id` ile bağlanan kaynaklı tarihsel kararlar ve araştırma notları     |
| `events/data/decisions.json`              | 21 oynanabilir kartın afet/alan bağları, alternatifleri ve kalıcı seçimleri |
| `management/data/preventive_actions.json` | Kimlik, başlık ve açıklama içeren tedbir önerileri                          |
| `management/data/measures.json`           | Runtime tedbirlerinin maliyet, etki ve açılma koşulları                     |
| `regions/data/service_areas.json`         | Sorumluluk alanları ve il kimlikleri                                        |

Afet sonrası katalog, afetin adını, tarihini veya kayıp verisini kopyalamaz. `entries` yalnızca
kaynaklı bir eylemi veya özel araştırma notu bulunan olayları içerir. Diğer olaylarda katalogdaki
`default_research_note` geçerlidir. Boş veya eksik bir eylem listesi, tarihte hiç önlem alınmadığının
kanıtı değildir. Kaynak taraması 17 Ekim 2026 itibarıyladır; eski afet verilerinin tümünün
doğrulandığı anlamına gelmez. İliç kaydı maden kazası bağlamındadır.

`actions` içindeki `type`, karar (`decision`), önlem (`measure`) veya yapılanma (`organization`)
olabilir. Her eylemin açıklaması ve en az bir HTTPS kaynağı zorunludur. `research_sources` varsa
`research_note` da gerekir. Kararın açıklanması, uygulamanın tamamlanması anlamına gelmez.
Yardım, tazminat, genel konut yapımı ve somut koruyucu önleme dönüşmemiş toplantılar bu seçkide yoktur.

Tarihsel arşiv ile tedbir önerileri içerik kataloglarıdır. Oynanabilir bağ `decisions.json`
tarafından kurulur: 20 doğal afet kaydındaki 25 kaynaklı aksiyon, 21 kart ve 42 tek uygulamalı
`decision_` projesiyle temsil edilir. İliç maden kararı kapsam dışındadır; Marmara/Düzce yapı
denetimi aynı karttır. Her kartın `full`, `focused`, `decline` alternatifleri ve tek yönetim
alanı vardır; 0 ulusal kapsamdır. Ret proje başlatmaz, güveni 0,5 azaltır; kabulde anlık güven
değişimi 0'dır. Şema alanları/tipleri, `check:data` proje/afet/alan ilişkilerini ve tüketilen
etkileri, runtime `DecisionCatalog` aynı bağları yükleme sırasında doğrular.

Oynanabilir tedbirlerin sayısal tek sahibi `measures.json` olarak kalır. Tarihsel notlar kaynak
arşivinden, alternatifler ve sayısal etkiler oyun tasarımından gelir. Katalogların doğrulanması
denge veya kayıt uyumluluğu kanıtı değildir. Akış, 21 kartın sayısal tablosu ve sürüm 1 kayıt
geçişi [karar rehberindedir](../docs/decision-events.md).
`events/historical/events.json` eski kaynak arşividir; runtime okumaz.
