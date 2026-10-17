# Gameplay veri şemaları

`our-game/<feature>/data/<name>.json` karşılığı `schemas/<feature>/<name>.schema.json`.
Alt klasörler korunur. `npm run check:data` eksik şema veya geçersiz veride başarısız olur;
kataloglar arasındaki bilinmeyen ve tekrarlanan kimlikleri de reddeder.

| Veri                                      | Sahibi ve amacı                                                         |
| ----------------------------------------- | ----------------------------------------------------------------------- |
| `events/data/historical/events.json`      | 99 afetin kararlı kimlikleri ve çalışan simülasyon değerleri            |
| `events/data/historical/aftermath.json`   | `event_id` ile bağlanan kaynaklı tarihsel kararlar ve araştırma notları |
| `management/data/preventive_actions.json` | Kimlik, başlık ve açıklama içeren tedbir önerileri                      |
| `management/data/measures.json`           | Runtime tedbirlerinin maliyet, etki ve açılma koşulları                 |
| `regions/data/service_areas.json`         | Sorumluluk alanları ve il kimlikleri                                    |

Afet sonrası katalog, afetin adını, tarihini veya kayıp verisini kopyalamaz. `entries` yalnızca
kaynaklı bir eylemi veya özel araştırma notu bulunan olayları içerir. Diğer olaylarda katalogdaki
`default_research_note` geçerlidir. Boş veya eksik bir eylem listesi, tarihte hiç önlem alınmadığının
kanıtı değildir. Kaynak taraması 17 Ekim 2026 itibarıyladır; eski afet verilerinin tümünün
doğrulandığı anlamına gelmez. İliç kaydı maden kazası bağlamındadır.

`actions` içindeki `type`, karar (`decision`), önlem (`measure`) veya yapılanma (`organization`)
olabilir. Her eylemin açıklaması ve en az bir HTTPS kaynağı zorunludur. `research_sources` varsa
`research_note` da gerekir. Kararın açıklanması, uygulamanın tamamlanması anlamına gelmez.
Yardım, tazminat, genel konut yapımı ve somut koruyucu önleme dönüşmemiş toplantılar bu seçkide yoktur.

Tarihsel kararlar ile tedbir önerileri içerik kataloglarıdır; kendiliğinden seçenekli olay,
araştırma veya oyun etkisi oluşturmaz. Oynanabilir tedbirlerin tek sahibi `measures.json` olarak kalır.
`events/historical/events.json` eski kaynak arşividir; runtime okumaz.
