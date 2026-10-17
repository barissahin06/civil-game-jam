# Rewrite it — ana menü splash art

`night_operations.aseprite`, 1920×1080 native tuval ve tek frame içerir.
Gece koordinasyon odası; Türkiye panosu, şehir ışıkları, telsiz, konsollar ve masa lambası.
Sol taraf canlı menü metni ve düğmeleri için sakin bırakılır; yazılar resme gömülmez.

11 ayrı katman; oda/zemin, pencere/şehir, Türkiye panosu, raf/saat, masa, konsollar,
telsiz, kâğıtlar, lamba, sandalye ve kenar gölgelerini ayrı ayrı düzenlemeyi sağlar.
Türkiye silüeti mevcut `../p0/map-general.aseprite` kaynağından salt okunur alınmıştır.
Bu bir oynanabilir harita katmanı değildir.

İlk kaynak Aseprite'ın native API'siyle `author_splash.lua` kullanılarak oluşturuldu.
Bu script mevcut kaynağın üzerine yazmayı reddeder. Sonraki değişikliklerden önce
checkpoint alın; kaynak katmanlarını Aseprite'ta düzenleyin. Runtime PNG'ye doğrudan çizmeyin.

```powershell
$repoPath = (Get-Location).Path
aseprite --batch --script-param "repo=$repoPath" --script art/production/ui/main_menu/export.lua
```

Export, kaynağı değiştirmeden `our-game/ui_preview/assets/main_menu_splash.png` üretir
ve tuval/frame/katman sözleşmesini doğrular. Görseli Godot'ta 1920×1080 menü içinde inceleyin;
isim, düğme, kayıt bilgisi ve uyarılar canlı UI olarak kalır.
