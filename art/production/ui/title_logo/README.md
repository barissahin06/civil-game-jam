# Rewrite it — başlık logosu

`rewrite_it.aseprite`, 1152×432 şeffaf tuval ve tek frame içerir. Özel çizilmiş iri
slab-serif **REWRITE**, mor italik küçük **it** ve sola dönen kısa revizyon çizgisi;
3×3 native piksel ızgarası kullanılır. Ciddi gazete/koordinasyon merkezi tonu korunur.

Altı ayrı katman gölge, kontur, fildişi harfler, ışık/mürekkep izleri, mor `it` ve
revizyon çizgisini bağımsız düzenlemeyi sağlar. Ana renkler fildişi `#eadfbc`, açık
krem `#fff0cf`, koyu lacivert `#081b25`, petrol gölgesi `#153b47` ve mor
`#9257e3`'tür. Mor vurgunun ışığı `#b38aed`, gölgesi `#5d3e94`'tür. Kenarlarda yumuşatma ve yarı şeffaf piksel bulunmaz.

Düzenlenebilir üretim kaynağı Aseprite dosyasıdır. `author_title.lua` ilk native
çizimi oluşturur ve mevcut kaynağın üzerine yazmayı reddeder. Sonraki değişiklikten
önce checkpoint alın; kaynak katmanlarını düzenleyin. PNG'ye doğrudan çizmeyin.

```powershell
$repoPath = (Get-Location).Path
aseprite --batch --script-param "repo=$repoPath" --script art/production/ui/title_logo/export.lua
```

Export, kaynağı değiştirmeden `generated/art/title_logo/rewrite_it.png` önizlemesini ve
`our-game/assets/branding/rewrite_it.png` runtime çıktısını üretir.
Tuval/frame/katman sözleşmesi, şeffaf sınır, ikili alpha ve native/export piksel
eşitliği doğrulanır. `REWRITE_TITLE_EXPORT_PASS` tamamlanma işaretidir.
Windows konsolunda çıktı görünmezse aynı işaret `rewrite_it.export-check.txt` içinde bulunur.

Bağımsız Godot önizlemesi gerçek 1920×1080 viewport'ta kontrol edildi;
`generated/art/title_logo/opening-preview-1920x1080.png` bu yerleşimi gösterir.
Logo, açılışta afet hafızası yazısından sonra ve ana menüden önce 3,5 saniye gösterilir.
İlk yarım saniyede belirir, son yarım saniyede ana menüye söner. Süre ve akışın sahibi
`our-game/core/scripts/opening.gd` dosyasıdır.

## HUD uyarlaması

`rewrite_it_hud.aseprite`, HUD için ayrı hazırlanmış 320×80 şeffaf native kaynaktır.
Açılış logosunun altı katmanı korunarak fildişi **REWRITE**, mor italik **it** ve
kısaltılmış revizyon oku yeniden yerleştirilmiştir. `author_hud.lua`, onaylı
`rewrite_it.aseprite` katmanlarından en yakın komşu örneklemeyle ilk uyarlamayı
oluşturur; mevcut HUD kaynağını ezmeyi reddeder. HUD uyarlama işlemi ana başlık kaynağını ve PNG'sini değiştirmez.
Sonraki çizim değişiklikleri checkpoint alınarak HUD Aseprite kaynağında yapılır.

```powershell
$repoPath = (Get-Location).Path
aseprite --batch --script-param "repo=$repoPath" --script art/production/ui/title_logo/export_hud.lua
```

Export, `generated/art/title_logo/rewrite_it_hud.png` önizlemesini ve
`our-game/assets/branding/rewrite_it_hud.png` runtime çıktısını üretir. 320×80 tek
frame, altı katman, şeffaf sınır, ikili alpha ve native/export piksel eşitliği
doğrulanır. Tamamlanma işareti `REWRITE_HUD_EXPORT_PASS`; raporu
`generated/art/title_logo/rewrite_it_hud.export-check.txt` dosyasıdır.

Bu kompakt uyarlama kaynak olarak korunur; HUD'da artık gösterilmez.
Üst şeritteki alan bütçe, güven, bilinç ve takvime ayrılmıştır. HUD yerleşiminin sahibi
`our-game/ui_preview/campaign/hud.gd` dosyasıdır.

`recolor.lua`, önceki kırmızı vurguyu mor palete taşımak için checkpoint alınmış,
`generated/art/title_logo/` altındaki staged native kopyalarda çalışır. Yalnız son
iki katmandaki üç vurgu rengini ve beşinci katmanın adını değiştirir; yeniden
açılan kaynaklarda ilk dört katmanın piksel eşitliğini, tüm alpha değerlerini,
cel konumlarını ve frame geometrisini doğrular. Native doğrulama işareti
`REWRITE_VIOLET_RECOLOR_PASS`'tir. Bu tek seferlik geçişten sonra normal export
komutları kullanılır; `author_title.lua` yeni kaynakları doğrudan mor paletle üretir.
