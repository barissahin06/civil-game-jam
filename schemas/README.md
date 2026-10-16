# Gameplay veri şemaları

`our-game/<feature>/data/<name>.json` karşılığı `schemas/<feature>/<name>.schema.json`.
Örnek: `our-game/farming/data/crops.json` → `schemas/farming/crops.schema.json`.
Alt klasörler korunur. `npm run check:data` eksik şema veya geçersiz veride başarısız olur.
Henüz gameplay JSON'u yoktur; komut sıfır veri doğrulandığını açıkça bildirir.
