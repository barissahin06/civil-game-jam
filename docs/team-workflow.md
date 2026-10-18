# Üç kişilik paralel çalışma

Onaylı UI kodu `our-game/ui_preview/` altında özelliklere ayrılmıştır. Ekranlar artık
`Simulation` durumunu okur; oyun formülleri ilgili özelliklerin `domain/` dizinindedir.
Aşağıdaki paylaşım görev alanı önerisidir; dosya sahibi değiştiğinde ekiple paylaşın.

| Çalışma alanı           | Dosyalar                                               | Sorumluluk                                                    |
| ----------------------- | ------------------------------------------------------ | ------------------------------------------------------------- |
| 1: Harita ve kampanya   | UI `map/`, `campaign/`; model `campaign/`, `regions/`  | Harita, HUD, takvim, dönem başlangıcı, güven, rehber ve kayıt |
| 2: Yönetim ve araştırma | UI `management/`; model `management/`, `economy/`      | Hazine, bakım, projeler, araştırma, çapraz etkiler ve onarım  |
| 3: Kriz ve lojistik     | UI `crisis/`; model `crisis/`, `logistics/`, `events/` | Tarihsel katalog, paralel müdahale, sevkiyat ve rapor         |

`main_preview.gd` yalnız modülleri kurar ve ekran geçişlerini bağlar. Günlük ekran
değişiklikleri için bu dosyaya kod eklemek gerekmez. `shared/ui_kit.gd` birden fazla
ekranın kullandığı native düğme, panel, metin ve atlas yardımcılarının tek sahibidir.
`shared/screen_view.gd` ortak ekran başlığı/paragraf/metrik çizimini sağlar.
`Simulation.areas` şehir paneli ve sevk ekranının tek gerçek envanteridir.
`simulation/simulation.gd` ortak sözleşmedir; işlem sırası veya komut değişikliğini üç alanla paylaşın.

## Modüller arası sözleşme

- Harita `area_selected(area_id)` sinyali üretir. Ana dosya seçimi şehir paneli ve seçim sınırına dağıtır.
- Şehir paneli ve HUD `screen_requested(screen)` sinyali üretir. Şehir paneli ayrıca
  `project_requested(definition_id, area_id)` üretir; başka modülün iç durumunu değiştirmez.
- Modal ekranlar `screen_view.gd` tabanını kullanır. `setup(shell)` bağlantıyı kurar;
  `render(content, screen)` yalnız verilen içerik alanını doldurur. Yenilemeden önce bu alanı ana dosya temizler.
- Modal ekranların ana dosyadan istediği işlemler: `show_screen`, `close_screen`,
  `refresh_screen`, `show_project`, `select_area`, `start_campaign`, `continue_campaign`,
  `acknowledge_news`, `command_result`. Kayıt ekranı `save_campaign_slot` / `load_campaign_slot`
  komutlarını kullanır; dosya yolları ve doğrulama `SaveStore` sahibindedir.
  Ortak sayı/para biçimi `fmt_count` / `fmt_money` kullanılır.
- Gazete arşivi `Simulation.latest_event()` ve `event_for(id)` üzerinden okunur;
  UI özel olay sayacına erişmez. Model değişimleri `changed` sinyaliyle sunuma aktarılır.
- Araştırma sekmesi, proje takip durumu, kampanya yılı ve sevk formu kendi modülünde tutulur.
  Bir ekran diğerinin özel alanını okumaz. Önizleme sürücüleri kabul kontrolü için bu alanları inceleyebilir.
- Renk, bitmap font ve native atlas değişiklikleri `shared/ui_kit.gd` üzerinden yapılır.
  Yeni ekran eklenirse ana dosyanın yönlendirmesi ve görüntü/input sürücüsü birlikte güncellenir.

## Birleştirme düzeni

Her geliştirici kendi branch ve checkout/worktree'sinde çalışsın. Aynı fiziksel checkout'ta
eşzamanlı branch değiştirmeyin. Başlarken `git status --short` ve aktif branch'i kontrol edin;
başka birinin değişikliklerini temizlemeyin veya geri almayın.

Modül içi değişiklikte ilgili klasör ve kabul sürücüsünü değiştirin. Ana dosya, ortak UI,
`Simulation` komutları, veri şemaları, `project.godot`, giriş sahnesi ve native atlaslar ortak dosyalardır;
aynı anda düzenlemek yerine değişikliği ekip içinde koordine edin.
Aseprite dosyaları ikili kaynaktır: aynı `.aseprite` dosyasını iki kişi eşzamanlı düzenlemesin.
Kaynak ile export çıktısını birlikte taşıyın; `.gd.uid` ve import metadata ilgili dosyayla kalsın.

Native art dosyaları için aynı paylaşım kullanılabilir: harita/kampanya sahibi `map-*.aseprite`,
yönetim/araştırma sahibi ortak `controls.aseprite`, `icons.aseprite` ve font,
kriz/lojistik sahibi `paper.aseprite` ve `signals.aseprite` üzerinde çalışır.
Ortak atlası etkileyen değişikliği diğer iki alanla paylaşın; kaynak/runtime yollarını
`art/production/ui/p0/README.md` ve `export.lua` birlikte tanımlar.

Gerçek model kodu [mimarideki](architecture.md) özellik dizinindedir.
UI yalnız modelin sonucunu göstersin; ücret, takvim, stok veya güven formülleri ekranlarda çoğaltılmasın.
Katalog alanı değişirse loader, kayıt doğrulaması, şema ve ilgili model testini birlikte güncelleyin.

## Birleştirmeden önce kontrol

```powershell
uv run --project tools gdformat --check our-game/ui_preview art/preview/p0
npx --no-install prettier --check docs/architecture.md docs/team-workflow.md
npm run verify
godot --headless --path our-game --script ../art/preview/p0/check_preview.gd
godot --path our-game --script ../art/preview/p0/capture_preview.gd
```

Godot PATH'te değilse [geliştirme rehberindeki](development.md) `GODOT_PATH` ayarını kullanın;
doğrudan `godot` çağrılarında da aynı motoru çalıştırın. Grafik yakalama headless çalıştırılmaz.
UI kontrolü `tests/integration/gameplay_ui.gd` ile gerçek tıklama ve native GUI drag/drop kullanır;
36 ekran yakalaması `generated/gameplay-ui/` altında 1920×1080
metin sınırlarını ve F11 geçişini denetler. Görselleri ayrıca gerçek boyutta inceleyin.
Gameplay JSON'u değişirse şeması ve `npm run check:data` da değişikliğin parçasıdır.

`npm run verify` import, saf model/kayıt testleri, açılış ve oynanış input kontrolünü çalıştırır.
`npm run test:ui` yalnız input kontrolüdür. GPU yakalama ayrı çalışır; test ağacı
`simulation_test` işaretiyle gerçek kampanya otomatik kaydını kapatır.

Harita tuvali değişince aynı kaynak sahibi dört harita, etiketler, HIT ve 30 seçim sınırını
birlikte export eder. Kamera/viewport dönüşümü `map/map_view.gd` sahibindedir; HUD ve şehir
paneli haritanın üstünde kalır. İl tıklama sürücüsündeki noktalar kamera dönüşümünden hesaplanır.
