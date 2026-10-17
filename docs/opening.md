# Açılış

`core/scenes/main.tscn` önce 1,5 saniyelik Godot logosunu, ardından 3,5 saniyelik
Pixel Spark logosunu gösterir. Motorun sabit açılış resmi yerine siyah yükleme zemini
kullanılır; Godot logosunu da sahne gösterdiği için sönme efekti uygulanabilir.
Ardından siyah fonda beyaz yazılı afet hafızası ekranı 15 saniye, sonrasında **Rewrite it**
başlık logosu 3,5 saniye gösterilir ve ana menü açılır.
Her dört ekran yalnız uygulama başlangıcında gösterilir.
`core/scripts/opening.gd` geçişleri yönetir. Logo ve yazılar ilk yarım saniyede belirir;
her ekranın son yarım saniyesinde sönme olur. Bu efektler toplam sürelere dahildir.
Metin ekranı siyah zemine söner; ardından başlık logosu belirir. Başlık ekranı sönerken
ana menü görünür. Metin ekranında ayrı bir başlık gösterilmez.
Godot görseli [Godot 4.6.3 kaynak deposundan](https://github.com/godotengine/godot/blob/4.6.3-stable/main/splash.png)
alınmıştır; `assets/branding/godot_splash.png` dosyasıdır. Godot MIT lisansı ve logo
[CC BY 4.0](https://godotengine.org/press/) koşulları geçerlidir.

## Yaklaşık dönem toplamları

1950–Ekim 2026 anlatımı, aşağıdaki EM-DAT kaynaklarının 17 Ekim 2026 tarihinde yapılan
birleştirmesine dayanır. 14 Ekim güncellemeli ülke profilinde Türkiye için son kayıt yılı
2025'tir; 2026'da hiç afet olmadığı veya arşivin tüm olayları kapsadığı iddia edilmez.
EM-DAT eşiklerini karşılayan büyük olaylar sayılır; tüm yerel olayların envanteri değildir.
Salgınlar ve teknolojik kazalar bu oyunun doğal afet kapsamına dahil edilmez.

| Dönem     | Olay | Can kaybı | Etkilenme  |
| --------- | ---- | --------- | ---------- |
| 1950–1999 | 78   | 34.442    | 7.943.630  |
| 2000–2025 | 93   | 54.781    | 17.616.610 |
| Toplam    | 171  | 89.223    | 25.560.240 |

Açılışta yaklaşık **170 büyük doğal afet, 26 milyon etkilenen kişi, 89 bin can kaybı**
olarak yuvarlanır. Bilinmeyen etki alanları tahminle doldurulmaz; toplamlar raporlanmış
değerlerdir. Etkilenme sayısı dönem boyunca tekilleştirilmiş kişi sayısı değildir;
aynı kişi farklı olaylarda tekrar sayılabilir. Kaynak notu bunu ekranda açıklar.
EM-DAT can kaybı tanımı ölen ve kayıp kişilerin toplamını kapsar.

### Kaynaklar ve hesap

- 1950–1999: [EM-DAT Archive, sürüm 2026.04](https://doi.org/10.14428/DVN/I0LTPH),
  `260430_emdat_archive.xlsx`, `EM-DAT Data` sayfası.
  `ISO = TUR`, `Disaster Group = Natural`, `Disaster Subgroup != Biological`,
  `1950 <= Start Year < 2000`. Olay sayısı satır adedi;
  diğerleri `Total Deaths` ve `Total Affected` sütunlarının toplamıdır.
- 2000 ve sonrası:
  [HDX EM-DAT Country Profiles](https://data.humdata.org/dataset/emdat-country-profiles),
  `EMDAT-country-profiles_2026_10_14.xlsx`, `EM-DAT (2026-10-14)` sayfası.
  `ISO = TUR`, `Disaster Group = Natural`, `Disaster Subroup != Biological`.
  Son sütun adı kaynak dosyada bu şekilde yazılmıştır.
  `Total Events`, `Total Deaths`, `Total Affected` sütunları toplanır.
  İki kaynak farklı yıllar için kullanılır; olaylar iki kez sayılmaz.
- [EM-DAT tanımlar ve erişim](https://doc.emdat.be/docs/data-accessibility/).
  EM-DAT, CRED / UCLouvain kaynağıdır.

İndirilen araştırma dosyaları `generated/research/` altında Git dışında tutulur.
Tarih aralığı veya sayılar güncellenirken aynı filtrelerle yeniden hesaplanmalıdır.

Logo kullanıcının sağladığı PNG'dir; `assets/branding/pixel_spark.png` doğrudan runtime
kaynağı olarak kullanılır. Yeni bir görsel üretimi veya dönüştürme pipeline'ı yoktur.
Sahnedeki AtlasTexture, görselin görünür `Rect2(541, 226, 203, 263)` bölgesini seçer;
siyah kenar boşlukları hizalamaya katılmaz. Logo 1920×1080 mantıksal viewport'ta
304,5×394,5 boyutuyla, önceki ölçeği korunarak yatayda ortalanır ve merkezden 20 piksel
yukarı yerleştirilir.

Rewrite it başlığının düzenlenebilir kaynağı
`art/production/ui/title_logo/rewrite_it.aseprite` dosyasıdır. Aynı klasördeki `export.lua`,
`assets/branding/rewrite_it.png` runtime çıktısını üretir. Logo 1152×432 native boyutuyla,
nearest filtreyle 1920×1080 viewport'un merkezinde siyah fonda gösterilir.
