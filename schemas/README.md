# Gameplay veri şemaları

`our-game/<feature>/data/<name>.json` karşılığı `schemas/<feature>/<name>.schema.json`.
Örnek: `our-game/farming/data/crops.json` → `schemas/farming/crops.schema.json`.
Alt klasörler korunur. `npm run check:data` eksik şema veya geçersiz veride başarısız olur.
Henüz gameplay JSON'u yoktur; komut sıfır veri doğrulandığını açıkça bildirir.

Tarihsel afet kataloğu `our-game/events/historical/events.json` yalnızca afetlerin temel kayıtlarını
tutar; afet sonrası kararlar bu dosyada bulunmaz. Katalog,
`schemas/events/historical/events.schema.json` ile doğrulanır. `data/` dışında olduğundan `check:data`
taramasına dahil değildir; ayrıca kontrol edilir:

```powershell
uv run --project tools python -m check_jsonschema --schemafile schemas/events/historical/events.schema.json our-game/events/historical/events.json
```

`our-game/events/historical/r_events.json`, aynı afetlerin sonrasında alınan kararların kısa kataloğudur.
Afetlerin sırası ve temel alanları korunur. Yapı denetimi, tehlikeli alanlardan taşınma, taşkın koruma
tesisleri, afet eğitimi ve kurumsal yapılanmalar gibi seçili kararlar kısa açıklama ve kaynaklarıyla
yazılır. Bir maddede hem koruyucu önlem hem yardım veya yeniden yapım varsa yalnızca koruyucu kısmı
aktarılır.

Yardım dağıtımı, geçici barınma, genel konut yapımı, tazminat, sigorta, afet sonrası hasar raporu ve
somut önleme dönüşmemiş toplantılar bu kopyaya alınmaz. Bir kuruma yer verilmesi, o kurumun her
faaliyetinin koruyucu olduğu anlamına gelmez. Uygun eylemi bulunmayan afet de boş `actions` ve açıklayıcı
notuyla korunur; boş liste tarihsel olarak hiç önlem alınmadığının kanıtı değildir.

Her eylem yalnızca `type`, kısa bir `description` ve `sources` içerir. Varsayımsal etki değerlendirmesi
eklenmez. Kararın açıklanması ile uygulamanın tamamlanması birbirinin yerine kullanılmaz.

Bu dosyadaki `aftermath.actions`, kararları (`decision`), önlemleri (`measure`) ve kurulan yapılanmaları
(`organization`) tutar. `research_note` belirsizlikleri, `research_sources` bu notun kaynaklarını
gösterir. Kaynak taraması 17 Ekim 2026 itibarıyladır; afetlerin eski tarih, can kaybı ve süre alanlarının
tamamının doğrulandığı anlamına gelmez. İliç kaydı maden kazası bağlamındadır.

Karar kataloğu ortak olay şemasını kullanır ve `aftermath` alanını zorunlu tutar:

```powershell
uv run --project tools python -m check_jsonschema --schemafile schemas/events/historical/r_events.schema.json our-game/events/historical/r_events.json
```

`our-game/events/historical/preventive_actions.json`, oyun için yazılmış önlemleri ek alan içermeyen
bir metin dizisinde tutar. Eylem adı ve kısa açıklaması aynı metindedir; karşılığı
`schemas/events/historical/preventive_actions.schema.json` dosyasıdır:

```powershell
uv run --project tools python -m check_jsonschema --schemafile schemas/events/historical/preventive_actions.schema.json our-game/events/historical/preventive_actions.json
```
