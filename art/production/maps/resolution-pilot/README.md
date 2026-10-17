# Türkiye haritası çözünürlük pilotu

Durum: B'nin native 1920×1080 çizim ölçeği seçildi. A karşılaştırma kaynağı olarak korunur.
Bu ölçek pilotları henüz oyun runtime'ına kurulmadı; P0 yerleşimi ayrıca hazırlanır.

| Kaynak                       | Native boyut | 1080p gösterim                      |
| ---------------------------- | ------------ | ----------------------------------- |
| `turkiye-960x540.aseprite`   | 960×540      | A: tam 2×, nearest-neighbor büyütme |
| `turkiye-1920x1080.aseprite` | 1920×1080    | B: native 1×                        |

Her iki harita aynı sınır geometrisini, kadrajı, 35 renkli paleti ve yazı boyutunu kullanır.
Çizim, piksel dolgusu, bitmap harfler ve PNG exportları Aseprite içinde üretildi.
Hazır bir raster harita veya AI görüntüsü kullanılmadı.

Her dosyada 26 katman vardır: deniz, kara gölgesi, pasif Türkiye zemini, ayrı ayrı 21 seçili il,
kıyı/ülke sınırı ve il adları. Seçili illerin katman verisinde `TR-XX` kimliği bulunur.
Yedi bölgenin renkleri seçili illerde gösterilir; coğrafi bölge sınırları bu pilotun kapsamında değildir.
Türkçe il adları özgün bitmap harflerle yazıldı.

## Sınır kaynağı

- [Natural Earth Admin 1, 1:10m](https://www.naturalearthdata.com/downloads/10m-cultural-vectors/10m-admin-1-states-provinces/).
- [Geometri dosyası](https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/ne_10m_admin_1_states_provinces.geojson).
- [Natural Earth kullanım koşulları](https://www.naturalearthdata.com/about/terms-of-use/): public domain.
- Alınma tarihi: 2026-10-17. Dosyadaki Türkiye'ye ait 81 ilin geometrisi kullanıldı.
- Alınan global GeoJSON dosyasının SHA-256 değeri:
  `22d0e3ad85eb3e27f17cabf8ba2d50e554fbc27a87796ff891d958185da62fb5`.

Ham indirme, geometri hazırlama ve native çizim scriptleri ile PNG önizlemeleri Git dışındaki
`generated/map-pilots/` altındadır. Native kaynaklar bunlara ihtiyaç duymadan Aseprite'ta açılır.

## Kontrol

Aseprite üzerinden iki PNG'nin de 1920×1080 ve tamamen opak olduğu, A'daki her 2×2 piksel bloğunun
aynı renkten oluştuğu, B'nin native piksel ayrıntısı taşıdığı, iki kaynakta da 21 benzersiz il katmanı
bulunduğu doğrulandı. Poligon rasterleştirmesi için kenar ve iç boşluk assert kontrolleri çalıştırıldı.
İki export görsel olarak incelendi. Godot entegrasyonu ve oyun içi zoom/input kontrolü yapılmadı.
