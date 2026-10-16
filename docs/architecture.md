# Klasörler ve mimari

Godot kökü `our-game/`, giriş sahnesi `core/scenes/main.tscn`.
Planlanan oyun çözünürlüğü 960×540'tır; çalışan ayarların kaynağı `our-game/project.godot` dosyasıdır.
Görsel stil, animasyon tekniği ve gameplay yapısı bu araç kurulumuyla belirlenmez.

| Yol                           | Sorumluluk                                                        |
| ----------------------------- | ----------------------------------------------------------------- |
| `our-game/core/`              | Başlangıç ve gerçekten oyun genelinde olan durum/servis sahipleri |
| `our-game/<feature>/scenes/`  | İlgili özelliğin sahneleri                                        |
| `our-game/<feature>/scripts/` | Koordinatörler; gerektiğinde `domain/`, `ui/`, `presentation/`    |
| `our-game/<feature>/data/`    | Özelliğin authored gameplay JSON verileri                         |
| `our-game/shared/`            | Birden fazla gerçek tüketicisi olan ortak kod                     |
| `our-game/assets/`            | Oyuna kurulmuş, onaylı runtime varlıkları                         |
| `our-game/tests/unit/`        | GdUnit4 ile saf mantık testleri                                   |
| `our-game/tests/integration/` | Gerçek sahne ve runtime entegrasyon kontrolleri                   |
| `art/production/`             | Kullanılan üretim araçlarının düzenlenebilir kaynak dosyaları     |
| `art/catalogs/`               | Kaynak/runtime eşlemeleri ve onay metadata'sı                     |
| `art/preview/`                | Oyuna kurmadan önce gerçek boyutta görsel incelemeler             |
| `tools/assets/`               | Asset üretim/kurulum araçları                                     |
| `tools/checks/`               | Kurulum, şema ve regresyon denetimleri                            |
| `tools/mcp/`                  | Sabit sürümlü Aseprite ve Godot MCP sağlayıcıları                 |
| `schemas/`                    | Gameplay JSON şemaları                                            |
| `generated/`                  | Git dışında kalan raporlar, yakalamalar ve build çıktıları        |

Dosyaları türüne göre kökte tek bir `scripts/` veya `scenes/` yığınına toplamayın.
Yeni özellik klasörünü ilk gerçek dosyasıyla açın; oyun tasarımı belli olmadan özellik iskeletleri kurmayın.
Tek tüketicili yardımcı o özelliğin yanında kalır. UI aksiyon talep eder, domain/model kuralı uygular,
sunum sonucu gösterir; aynı kural bir panelde tekrar hesaplanmaz.

Kayıt biçimi eklenirse tek sahibinde sürümlensin ve eski kayıt fixture'larıyla doğrulansın.
