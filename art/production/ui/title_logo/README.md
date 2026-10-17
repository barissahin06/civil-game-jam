# Rewrite it — başlık logosu

`rewrite_it.aseprite`, 1152×432 şeffaf tuval ve tek frame içerir. Özel çizilmiş iri
slab-serif **REWRITE**, kırmızı italik küçük **it** ve sola dönen kısa revizyon çizgisi;
3×3 native piksel ızgarası kullanılır. Ciddi gazete/koordinasyon merkezi tonu korunur.

Altı ayrı katman gölge, kontur, fildişi harfler, ışık/mürekkep izleri, kırmızı `it` ve
revizyon çizgisini bağımsız düzenlemeyi sağlar. Ana renkler fildişi `#eadfbc`, açık
krem `#fff0cf`, koyu lacivert `#081b25`, petrol gölgesi `#153b47` ve kırmızı
`#bc4b43`'tür. Kenarlarda yumuşatma ve yarı şeffaf piksel bulunmaz.

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
