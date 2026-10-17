# Kriz operasyon sahnesi

`operations.aseprite`, 480×270 native pixel art kaynağıdır. Zemin, bina/hasar,
ekipman ve çizilmiş çalışma pozları ayrı katmanlardadır. Beş tag, ikişer 350 ms
kare içerir: `waiting`, `rescue`, `aid`, `recovery`, `restored`.

Runtime eşlemesi: `our-game/ui_preview/assets/operations.png`, yatay 4800×270
sheet; `operation_view.gd` durumu simülasyondan seçer. Kaynak varışı animasyon
tarafından üretilmez. Duraklatmada poz ilerlemez; hız 1×/2×/4× takvime uyar.
Sahne belirli bir tarihsel sokağın canlandırılması değildir.

`create.lua` ilk native kaynağın çizim reçetesidir; mevcut dosyayı ezmeyi reddeder.
Sonraki düzenlemelerde Aseprite kaynağını checkpoint/staged akışıyla düzenleyin.
Kaynağı değiştirmeden runtime sheet'i yeniden üretmek için:

```powershell
$repoPath = (Get-Location).Path
Start-Process -FilePath C:/Tools/Aseprite/aseprite.exe -Wait -WindowStyle Hidden -ArgumentList @('--batch', '--script-param', "repo=`"$repoPath`"", '--script', 'art/production/ui/crisis_pilot/export.lua')
```

`OPERATION_EXPORT_PASS` işaretini denetleyin. A/B kontrolleri yalnız
`tests/integration/crisis_pilot.gd -- --review` sürücüsündedir; normal kampanyada
harita/panel görünümü A kullanılır. GPU yakalamaları `generated/gameplay-ui/pilot-*.png`
altında tutulur. Görsel kabul native boyutta ve normal hızda kullanıcıyla yapılır.
