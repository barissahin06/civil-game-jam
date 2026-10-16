# Kod ve veri standardı

- BOM'suz UTF-8, LF ve dosya sonunda newline. `.editorconfig` ve `.gitattributes` tek kaynaktır.
- GDScript: tab, 100 karakter hedefi, gdformat güvenlik kontrolleri açık. Script/fonksiyon/değişken/sinyal `snake_case`, sınıf/node/enum `PascalCase`, sabitler `CONSTANT_CASE`.
- Parametre ve dönüş tiplerini belirtin; açık değerlerde `:=` kullanılabilir. JSON gibi dinamik sınırlarda `Variant` veriyi doğruladıktan sonra modele dönüştürün. Cast ile doğrulamayı atlamayın.
- JSON/YAML/Markdown: Prettier, iki boşluk, 100 karakter hedefi. Python: dört boşluk.
- Yalnız değişen dosyaları formatlayın. Geniş `npm run format` / `format:gd` komutlarını ayrı stil işlerinde kullanın.
- Üçüncü taraf addonları, hash ile izlenen MCP kaynaklarını ve art çıktısını formatlamayın. Godot sahne/UID/import dosyalarını motor yönetir.
- Tekrar ve gereksiz dalları inceleyin; sırf puan için soyutlama eklemeyin. `gdradon` tanı aracıdır, Godot tip kontrolünün veya testlerin yerini almaz.

Gameplay verisi `our-game/<feature>/data/<name>.json` için şema
`schemas/<feature>/<name>.schema.json` olur; `data/` altındaki daha derin yollar korunur.
`npm run check:data` tüm özellik verilerini bulur ve eksik şemada başarısız olur.
Şema zorunlu alan ve tipleri doğrular; ID ilişkileri, denge ve kayıt uyumluluğu domain testleriyle kontrol edilir.

```powershell
uv run --project tools gdformat --check our-game/path/to/changed_script.gd
npx --no-install prettier --check docs/changed-file.md
```
