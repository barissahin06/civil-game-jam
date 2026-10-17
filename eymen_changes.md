# Eymen'in değişiklikleri

Bu belge, Eymen'in iki branch'te yaptığı değişiklikleri dosya dosya özetler. Amaç,
ekipteki herkesin hangi dosyalara ve fonksiyonlara dokunulduğunu bilmesi ve aynı yerlerde
çalışırken çakışma (conflict) yaşamamasıdır. Her bölümde "Dikkat" notları, başka biri o
dosyada çalışırken nelere bakması gerektiğini anlatır.

## Branch durumu

| Branch                      | Durum                                                  | İçerik                                                                          |
| --------------------------- | ------------------------------------------------------ | ------------------------------------------------------------------------------- |
| `eymen/historical-events`   | PR #2, #3 ve #5 ile `main`'e merge edildi              | Tarihsel afet verisi, şehirler, olay görselleri                                 |
| `eymen/arastirma-eklentisi` | `main`'in `b859739` commit'inden ayrıldı, PR henüz yok | Araştırma hikâyeleri, tamamlanma penceresi, HUD açıklamaları ve diğer UI işleri |

`eymen/arastirma-eklentisi` üzerindeki commit'ler (eskiden yeniye):

| Commit    | Başlık                                                          |
| --------- | --------------------------------------------------------------- |
| `54a703d` | Add story text to research measures                             |
| `2502cfa` | Add research completion stories                                 |
| `ff7daa5` | Add HUD tooltips, screen switching, pause layout and intro skip |

## 1. Tarihsel afet verisi

**Dosya:** `our-game/events/historical/events.json`

1950–2026 arasında Türkiye'de yaşanmış doğal afetlerin listesi. Her kayıt şu alanları taşır:

| Alan            | Tür              | Açıklama                                                    |
| --------------- | ---------------- | ----------------------------------------------------------- |
| `name`          | metin            | Olayın adı, örneğin `1999 Marmara Depremi`                  |
| `time`          | `YYYY-MM-DD`     | Olay tarihi                                                 |
| `disaster_type` | metin            | `earthquake`, `flood`, `avalanche`, `wildfire`, `landslide` |
| `description`   | metin            | Tek cümlelik açıklama                                       |
| `casualties`    | sayı             | Can kaybı                                                   |
| `duration`      | sayı (saniye)    | Depremde sarsıntı süresi; sel, çığ ve yangında tahmini süre |
| `regions`       | metin listesi    | Türkiye'nin 7 coğrafi bölgesinden etkilenenler              |
| `city`          | metin listesi    | Etkilenen iller                                             |
| `image`         | `res://` yolu    | Gazete görseli (bkz. bölüm 2)                               |
| `is_active`     | `true` / `false` | Gerçek boolean; `"false"` gibi metin değil                  |

- Depremlerin listesi Türkçe Vikipedi deprem listesinden, sel/heyelan/çığ/yangın kayıtları
  haber ve akademik kaynaklardan derlendi. Bazı ölü sayıları kaynaklar arasında farklıdır;
  en sık geçen ya da resmi rakam kullanıldı.
- `duration` depremlerde büyüklüğe göre tahmin edildi (örneğin M7+ için 40 sn). Sel ve
  yangın süreleri kaba tahmindir; oyun dengesi için değiştirilebilir.

**Dikkat:**

- Bu dosya, oyunun şu an okuduğu katalog **değildir**. Oyun
  `our-game/events/data/historical/events.json` dosyasını okur (`historical_catalog.gd`
  içindeki `PATH`); o dosya farklı bir formattadır (`id`, `date`, `kind`, `province_ids`,
  `severity` gibi alanlar). İki dosya şimdilik birbirine bağlı değil. Görselleri oyuna
  bağlamak isteyen, `image` alanını o kataloğa taşımalıdır.
- `main`'de Barış'ın `e9eab5c` ("Preserve historical records without event images")
  commit'i 1988 Çatak Heyelanı, 2024 İliç Toprak Kayması ve 2025 Silivri Depremi kayıtlarını
  görselsiz geri ekledi. Bu yüzden `main`'deki dosya 99 kayıtlıdır ve bu üç kaydın `image`
  alanı yoktur. Bu dosyada değişiklik yapmadan önce `main`'i çekin.
- `our-game/events/historical/` klasörü `*/data/` altında olmadığı için
  `npm run check:data` bu dosyayı **doğrulamaz**; şeması yoktur.

## 2. Afet görselleri

**Klasör:** `our-game/assets/events/`

- Her olayın görseli olay adından türetilmiş bir dosya adıyla durur:
  `1999-marmara-depremi.jpg`. `events.json` içindeki yol:
  `"image": "res://assets/events/1999-marmara-depremi.jpg"`.
- Görseli bulunamayan olaylar türlerine göre bir yedek görsel kullanır:
  `_fallback_earthquake.jpg`, `_fallback_flood.jpg`, `_fallback_avalanche.jpg`,
  `_fallback_wildfire.jpg`, `_fallback_landslide.jpg`.
- Hedef boyut 800×450 (16:9), JPG, kalite 80–85. Bazı eski görseller 4:3 orandadır;
  çerçeveye "Keep Aspect Covered" ile yerleştirilmesi önerilir.
- Her görselin yanında Godot'un oluşturduğu `.jpg.import` dosyası vardır; görselle birlikte
  commit edilmelidir.

**Dikkat:**

- Görsellerin çoğu haber sitelerinden alınmış **telifli** fotoğraflardır. Oyun yalnız
  game jam içinde kullanılacağı için kabul edildi. Oyun herkese açık bir yerde (itch.io gibi)
  yayınlanacaksa bu görseller değiştirilmelidir.
- Bir görseli değiştirirken aynı dosya adını kullanın; `events.json` değişmez. Yedek
  görsellerin üzerine yazmayın, onlar birden fazla olayda ortaktır.

## 3. Araştırma hikâyeleri ve tamamlanma penceresi

Araştırma ağacındaki 18 düğümün (12 teknik araştırma + 6 bilinç geliştirmesi) her biri
artık kısa bir önizleme ve tamamlanınca gösterilen uzun bir hikâye taşır.

### Veri

**`our-game/management/data/measures.json`:** `kind` değeri `research` veya `awareness`
olan her kayda isteğe bağlı bir `story` nesnesi eklendi:

```json
"story": {
  "headline": "Ayakta Tutan Hesaptır",
  "preview": "Mühendislik okullarında deprem dersi açılacak, ...",
  "text": "Mühendislik okullarında ilk kez deprem dersi okutuldu. ..."
}
```

- `headline`: tamamlanma penceresindeki büyük başlık.
- `preview`: proje ekranında, araştırma başlamadan önce gösterilen kısa cümle.
- `text`: araştırma bitince açılan pencerede gösterilen uzun hikâye.

**`schemas/management/measures.schema.json`:** `story` alanı eklendi. Alan isteğe bağlıdır;
varsa `headline`, `preview` ve `text` zorunludur ve boş olamaz.

**`our-game/management/domain/measure_definition.gd`:** `story_headline`, `story_preview`
ve `story_text` alanları eklendi. `from_dict()` bozuk bir `story` nesnesini reddeder
(sözlük değilse ya da alanlardan biri boşsa `null` döner).

**Yazı tipi uyarısı:** Oyunun piksel yazı tipi noktalı virgülü (`;`), çift ve tek tırnağı
(`"` `'`) ve `î` harfini ekranda `?` olarak gösteriyor. Hikâye metinlerinde bu karakterler
kullanılmadı. Yeni metin eklerken bunlardan kaçının. `events.json` açıklamalarındaki kesme
işaretleri ("Körfezi'nde" gibi) gazetede de `?` görünebilir.

### Oyun akışı

**`our-game/simulation/simulation.gd`, `_month_boundary()`:** Bir araştırma ya da bilinç
geliştirmesi tamamlanınca ve hikâyesi varsa `news_queue` kuyruğuna
`{"kind": "research_done", "id": <ölçü id>}` eklenir. Kuyruk dolu olduğu için zaman durur
ve pencere açılır.

**`our-game/campaign/domain/save_store.gd`, `restore()`:** Kayıt yüklenirken `news_queue`
artık `research_done` türünü de kabul eder. Bu kayıtların araştırması tamamlanmış olmalı ve
aynı araştırma kuyrukta iki kez olamaz; tarih sırası kontrolü bu tür için uygulanmaz.

**Davranış değişikliği:** Araştırma bitince oyun artık o ayın başında durur. Örneğin
1950'de başlatılan Yapı Güvenliği Bilimi, 1 Ocak 1951'de pencere açar; oyun "TAMAM"a
basılınca devam eder. Testler buna göre güncellendi.

### Arayüz

**`our-game/ui_preview/management/project_screens.gd`, `_project()`:** "Çapraz etkiler"
listesinin altında `story_preview` metni gösterilir.

**`our-game/ui_preview/crisis/news_reports.gd`:** Yeni `_research_done()` ekranı eklendi.
Gazete kâğıdı görünümünde "ARAŞTIRMA TAMAMLANDI" başlığı, araştırmanın adı, hikâye başlığı
ve uzun metin gösterilir; "TAMAM" düğmesi kuyruktaki pencereyi kapatır.

**`our-game/ui_preview/main_preview.gd`, `refresh_screen()`:** `research_done` ekranı
`news_reports`'a yönlendirildi.

## 4. Üst bar ve harita açıklamaları (tooltip)

**`our-game/ui_preview/campaign/hud.gd`:**

- Üst bardaki her kutu ve düğmeye açıklama eklendi: Bütçe, aylık net, Güven, Bilinç, tarih,
  DEVAM, 1×/2×/4×, MENÜ, PROJELER, ULUSAL PLAN, ARAŞTIRMA, KRİZ MERKEZİ, GAZETE, RAPOR.
- Yeni `_hint(box, tip)` fonksiyonu, etiket kutularının (Bütçe, Güven, Bilinç, tarih)
  üzerine görünmez bir alan koyar. Etiketler fareyi yok saydığı için eskiden bu
  açıklamalar hiç görünmüyordu.
- Güven açıklamasının altında son güven değişimleri listelenir (`refresh()` içinde).

**`our-game/ui_preview/map/map_view.gd`:**

- SIFIRLA, +, −, GENEL, HAZIRLIK, LOJİSTİK, HASAR/ONARIM, BÖLGE RENKLERİ ve haritadaki
  +5 bilinç balonuna açıklama eklendi.
- Alt kenardaki kontrollerin açıklaması, Godot'un kendi tooltip'i yerine kendi panelimizle
  **düğmenin üstünde** açılır: `_build_hints_above()` ve `_show_hint_above()`. Bu
  kontrollerin metni `tooltip_text` yerine `hint` meta verisinde durur.
- `_on_map_input()`: Bir ekran açıkken harita tıklamaları yok sayılır.

**`our-game/ui_preview/shared/ui_kit.gd`:** Yeni `wrap_tooltips(root, width)` fonksiyonu,
uzun açıklamaları yaklaşık 44 karakterlik satırlara böler. Oyunun açıklama kutusu metni
kendi kendine alt satıra geçirmiyordu.

**Dikkat:** HUD'a ya da harita alt kontrollerine yeni bir düğme eklerseniz ona da açıklama
yazın. `gameplay_ui.gd` testi açıklaması olmayan düğmede hata verir.

## 5. Açık ekranlar arasında geçiş

**`our-game/ui_preview/main_preview.gd`, `show_screen()`:**

- İsteğe bağlı bir ekran açıkken (Projeler, Ulusal Plan, Araştırma gibi) üstteki ekran
  düğmeleri tıklanabilir ve doğrudan diğer ekrana geçer. Bunun için modal katman fareyi
  yok sayar; ekran düğmeleri satırı dışındaki alanları iki görünmez engelleyici kapatır
  (`Rect2(0, 0, 1920, 110)` ve `Rect2(0, 166, 1920, 914)`).
- Okunması zorunlu ekranlarda (yeni gazete, kriz raporu, araştırma bitiş penceresi, oyun
  sonu) eski kilit davranışı sürer.
- DEVAM, hız ve MENÜ düğmeleri ekran açıkken kilitli kalır.

**Dikkat:** Üst bardaki düğmelerin yerini değiştirirseniz engelleyici dikdörtgenlerin
koordinatlarını da güncelleyin.

## 6. Duraklatma menüsü

- **`our-game/ui_preview/main_preview.gd`, `show_screen()`:** `pause` ekranı için panel
  artık dar ve ortalı: `Rect2(620, 174, 680, 800)`. KAPAT düğmesi panelin sağ üstünde.
  Diğer ekranlar eski geniş paneli (`Rect2(432, 174, 1472, 846)`) kullanır.
- **`our-game/ui_preview/campaign/campaign_screens.gd`, `_pause()`:** "OYUN DURAKLATILDI"
  başlığı panele sığacak şekilde 560 piksel genişlikte ve ortalı.

## 7. Açılış metnini atlama

**`our-game/core/scripts/opening.gd`:**

- Afet hafızası metni ekrandayken sağ altta "ATLAMAK İÇİN ESC BASILI TUT" çubuğu görünür
  (`_build_skip_bar()`, `Intro/SkipBar` düğümü).
- ESC 2 saniye (`SKIP_HOLD_SECONDS`) basılı tutulunca çubuk dolar; metin ve "Rewrite it"
  başlık ekranı atlanıp doğrudan ana menüye geçilir. ESC erken bırakılırsa çubuk sıfırlanır.
- Çubuk açıkken ESC tuşu ana menüye iletilmez (`_input()`).
- Akıştaki tween'ler artık `_tween` değişkeninde tutulur; atlama, metin tween'ini sonuna
  sardırarak (`custom_step`) çalışır.

**`docs/opening.md`:** Atlama davranışı belgeye eklendi.

## 8. Testler

| Dosya                                       | Değişiklik                                                                                                 |
| ------------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| `our-game/tests/unit/test_catalog.gd`       | Her araştırmanın hikâyesi var; bozuk `story` reddediliyor                                                  |
| `our-game/tests/unit/test_simulation.gd`    | Araştırma bitince 1 Ocak 1951'de `research_done` ile durma, sonra ilk afete devam                          |
| `our-game/tests/unit/test_save_store.gd`    | `research_done` kuyruğu kayıtta korunuyor; tamamlanmamış araştırmayla kayıt reddediliyor                   |
| `our-game/tests/integration/gameplay_ui.gd` | Bitiş penceresi, açıklama zorunluluğu, alt açıklamanın konumu, ekranlar arası geçiş, zorunlu gazete kilidi |
| `our-game/tests/integration/startup.gd`     | ESC ile atlama: yarıda bırakınca sıfırlanma ve 2 saniyede ana menüye geçiş                                 |

Bütün değişikliklerden sonra şu komutlar geçti: `npm run check:data`,
`npm run format:gd:check`, `npm run verify` (Godot import, birim testleri, açılış ve oyun
akışı testleri).

## Çakışma riski olan dosyalar

Aşağıdaki dosyalarda aynı anda çalışıyorsanız önce `eymen/arastirma-eklentisi` merge
edilsin ya da değişikliklerinizi bu branch'in üzerine alın.

| Dosya                                               | Dokunulan yer                                                                      | Risk   |
| --------------------------------------------------- | ---------------------------------------------------------------------------------- | ------ |
| `our-game/ui_preview/main_preview.gd`               | `show_screen()`, `refresh_screen()`                                                | Yüksek |
| `our-game/ui_preview/campaign/hud.gd`               | `_ready()`, `refresh()`, yeni `_hint()`                                            | Yüksek |
| `our-game/ui_preview/map/map_view.gd`               | `_ready()` alt kontroller, `refresh()`, `_on_map_input()`, yeni hint fonksiyonları | Yüksek |
| `our-game/management/data/measures.json`            | Araştırma ve bilinç kayıtlarına `story`                                            | Orta   |
| `our-game/simulation/simulation.gd`                 | `_month_boundary()`                                                                | Orta   |
| `our-game/campaign/domain/save_store.gd`            | `restore()` içindeki `news_queue` doğrulaması                                      | Orta   |
| `our-game/core/scripts/opening.gd`                  | `_ready()` akışı, yeni `_process()` ve `_input()`                                  | Orta   |
| `our-game/tests/integration/gameplay_ui.gd`         | Birkaç yere yeni adımlar                                                           | Orta   |
| `our-game/ui_preview/crisis/news_reports.gd`        | `render()`, yeni `_research_done()`                                                | Düşük  |
| `our-game/ui_preview/management/project_screens.gd` | `_project()` içinde etki listesinin altı                                           | Düşük  |
| `our-game/ui_preview/shared/ui_kit.gd`              | Yeni `wrap_tooltips()`                                                             | Düşük  |
| `our-game/ui_preview/campaign/campaign_screens.gd`  | `_pause()` başlığı                                                                 | Düşük  |
| `our-game/management/domain/measure_definition.gd`  | Yeni alanlar ve `from_dict()`                                                      | Düşük  |
| `schemas/management/measures.schema.json`           | `story` alanı                                                                      | Düşük  |
| `docs/opening.md`                                   | Atlama paragrafı                                                                   | Düşük  |
