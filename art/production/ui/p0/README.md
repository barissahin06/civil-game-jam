# P0 ana ekran kaynakları

Durum: P0 ekranları 17 Ekim 2026'da kullanıcı tarafından uygun bulundu.
İl paneli isteğe bağlı açılır; 81 ilin sınırı görünür, yalnız 30 yönetim merkezi seçilebilir.
Harita, HUD ve panellerin altında ekranı kaplayan kesintisiz arka plandır.
Türkiye odaktadır; Balkanlar, Ege, Kafkasya ve yakın Orta Doğu soluk ülke sınırları/adlarıyla görünür.
Bu bir UI prototipidir. Gerçek ekonomi, takvim, afet sonucu ve kayıt entegrasyonu içermez.
Kod, üç kişinin paralel çalışabilmesi için özellik modüllerine ayrılmıştır;
dosya paylaşımı ve modül sözleşmeleri [çalışma rehberindedir](../../../../docs/team-workflow.md).

| Native kaynak                            | İçerik / runtime çıktısı                                                            |
| ---------------------------------------- | ----------------------------------------------------------------------------------- |
| `controls.aseprite`                      | 256×160 panel, düğme ve durum atlası → `controls.png`                               |
| `icons.aseprite`                         | 12 adet 32×32 simge → `icons.png`                                                   |
| `signals.aseprite`                       | 16 adet 32×32 afet, durum ve navigasyon simgesi → `signals.png`                     |
| `paper.aseprite`                         | 64×64 native gazete kâğıdı çerçevesi → `paper.png`                                  |
| `afet_pixel.aseprite` + `afet_pixel.fnt` | 126 glif, Türkçe ve noktalama; 18 px bitmap font → aynı adlı PNG/FNT                |
| `map-general.aseprite`                   | 3072×1728 bölgesel harita → `map-general.png`; üç arazi katmanı → `map-terrain.png` |
| `map-preparedness.aseprite`              | Hazırlık örnek katmanı → aynı adlı PNG                                              |
| `map-logistics.aseprite`                 | Lojistik örnek katmanı → aynı adlı PNG                                              |
| `map-damage.aseprite`                    | Hasar/toparlanma örnek katmanı → aynı adlı PNG                                      |
| `map-selection.aseprite`                 | 30 ayrı il seçim sınırı; her katman `SELECT / TR-XX`                                |

`controls.aseprite` → `controls.png` atlasındaki mevcut 48×24 durum hücreleri düğme
eylemlerinde de kullanılır: `(168,96)` yeşil onay/başlatma, `(112,96)` kırmızı iptal/riskli
son onay, `(56,96)` altın bütçe/proje duraklatma. `UI.button()` bunları 6 px kenarlarla ölçekler;
hover/basılı durumlarda aynı hücrenin parlaklığı değişir. Nötr ve devre dışı düğmeler
48×32 hücreleri kullanmayı sürdürür. Native kaynak veya export değişmez.

Mantıksal viewport 1920×1080'dir. Native harita tuvali 3072×1728'dir; kamera bu tuvalin
bir bölümünü 1× piksel ölçeğinde gösterir, harita bir UI dikdörtgenine sığdırılmaz.
Başlangıç kamerası Türkiye'ye bakar; panel kapanınca altında kalan coğrafya görünür.
İl ve ülke geometrisi aynı [Natural Earth kaynağından](https://www.naturalearthdata.com/downloads/10m-cultural-vectors/10m-admin-1-states-provinces/)
alınır; komşu ülkelerin idari alt bölgeleri birleştirilerek yalnız ülke sınırları çizilir.
Kaynak hash'i ve [public domain kullanım koşulları](https://www.naturalearthdata.com/about/terms-of-use/)
[çözünürlük pilotunda](../../maps/resolution-pilot/README.md) kayıtlıdır.
Yedi bölge seçili illerin renkleriyle temsil edilir; coğrafi bölge sınırları henüz çizilmedi.
Dört harita kaynağında `03 / Pasif il sınırları` adlı native katman, diğer 51 ilin
sınırlarını soluk çizgilerle gösterir. Bu katman seçili il renkleri, etiketler ve kıyı
çizgisinden ayrıdır. `01a / Çevre ülkeler`, `01b / Ülke sınırları` ve `98 / Ülke adları`
katmanları çevre coğrafyayı oluşturur; yabancı şehir, yönetim düğümü veya etkileşim içermez.
HIT ve 30 seçim maskesi aynı yeni tuval/projeksiyonda birlikte üretilir; seçilebilir il kimlikleri korunur.
Genel harita 43, diğer üç harita 40'ar katman ve tek frame içerir. `sprite.data` projeksiyonu, tuvali
ve başlangıç kamera konumunu kaydeder; oyun kodu `map/map_view.gd` içinde bu kamera konumunu kullanır.
Ekranlardaki miktarlar, maliyetler, dönem kilitleri ve sonuçlar authored UI örnekleridir.
Bu değerler onaylanmış oyun dengesi veya hesaplanmış simülasyon sonucu değildir.
Font büyük harf çizim düzenini korur; Türkçe alfabenin 29 harfinin büyük/küçük kod noktaları,
`ÂÎÛâîû`, bütün yazdırılabilir ASCII işaretleri, `₺`, `×`, `•`, `‘’“”«»`, `–—…` ve bölünmez boşluk
desteklenir. `i/İ` noktalı, `ı/I` noktasız çizilir. Kesme işaretleri soru işareti hücresini kullanmaz.
`author_font.lua`, checkpoint alınmış native kopyada bu karakterleri tamamlar; diğer gliflere,
384×88 tuvale, 12×22 hücrelere ve 12 px ilerlemeye dokunmaz.

## Dekoratif arazi

`map-general.aseprite` içindeki `70 / Arazi - Dağ sıraları`,
`71 / Arazi - Orman ve bozkır` ve `72 / Arazi - Kıyı dokusu` katmanları
dağ siluetlerini, ağaç/ot kümelerini ve kıyı dalgalarını ayrı tutar. Bu çizimler
yaklaşık, dekoratif coğrafyadır; yeni arazi mekaniği veya veri katmanı değildir.
Etiketler ve il sınırları açık bırakılır. Kaynağın önceki 31 katmanı korunur.

`author_terrain.lua`, checkpoint alınmış bir native kopya üzerinde yalnız bu üç
katmanı yeniden üretir. Aseprite önizlemesinde arazi haritayla birlikte görünür.
Export sırasında bu katmanlar şeffaf `map-terrain.png` içinde birleştirilir;
`map-general.png`, hitmask, etiketler ve seçim maskeleri değişmeden üretilir.
Oyun haritası dağ, orman/bozkır ve kıyı dokusu gibi dekoratif arazi ayrıntılarını hiçbir
görünümde göstermez. Native katmanlar ve ayrı export düzenlenebilir kaynaklar olarak korunur;
runtime `map-terrain.png` dosyasını yüklemez.

## Export ve inceleme

Kaynak düzenlemeden önce checkpoint al. Native dosyaları Aseprite'ta düzenle,
runtime PNG'lere doğrudan çizme. Export scripti kaynağı değiştirmeden
`our-game/ui_preview/assets/` çıktılarını yeniden üretir:

```powershell
$repoPath = (Get-Location).Path
aseprite --batch --script-param "repo=$repoPath" --script art/production/ui/p0/export.lua
```

Aseprite MCP ile aynı işlem `P0_ROOT` repo kökü verilerek `export.lua` dosyasını çalıştırır.
Script tek frame, 3072×1728 harita/seçim tuvali, üç arazi katmanı ve keskin alfa kenarları, ülke/pasif sınır katmanları,
30 il ID'si ve 126 glif düzenini doğrular. Grid, katman adı veya il sınırı
değişirse ona bağlı descriptor, seçim sınırı ve hitmask birlikte güncellenmelidir.
Bitmap font sayfası değişince Godot'ta PNG ile birlikte `.fnt` kaynağını da yeniden içe aktar;
yalnız PNG importu eski font önbelleğini koruyabilir.

Godot'ta F5 ana önizlemeyi açar. İl sınırına tıklama, sol panel sekmeleri, dört katman,
tekerlek/+/- ile 1×–3× yakınlaştırma, sürükleme ve Sıfırla çalışır. F11 tam ekranı değiştirir.
Sürükleme 1× ölçekte de çalışır; kamera tuvalin dışına çıkmaz. Sıfırla Türkiye kadrajını geri getirir.
HUD, şehir paneli, modal ve katman düğmeleri haritanın üstündedir; bunlara tıklama haritayı seçmez.
Şehir paneli başlangıçta kapalıdır; 30 merkezden biri seçilince açılır.
Paneldeki × seçimi ve vurguyu temizler. Esc önce açık modalı, sonra şehir panelini kapatır.
Diğer 51 ile, çevre ülkelere veya denize tıklamak şehir seçmez.
Ana menüden 1950–1990 yılı seçilebilir; Sandbox kilitlidir. Dört araştırma sekmesi bağlantılı
ağaç ve detay kartlarına sahiptir. Yerel/ulusal tedbir ayrıntıları, proje takip durumları,
gazete ilk haberi/kararı, iki kriz alanı, acil fon, rapor ayrıntıları, 2026 bitişi, erken yenilgi
ve atlanabilir rehber önizlemeleri bulunur. Proje takibindeki duraklatma, öncelik ve iki adımlı
iptal yalnız örnek görünüm durumunu değiştirir.

Kriz ekranında ekip/yardım kriz kartına sürüklenir veya formdan seçilir; ikisi aynı örnek sevk
planını doldurur. Kaynak miktarı UI fixture'ıyla sınırlıdır. Harita üstündeki gerçek sevkiyat,
rezervasyon, stok tüketimi, varış ve dönüş P2'de bağlanır.
Bu aşamada proje satın alma, zaman, afet, kayıt ve gerçek ekonomi çalıştırılmaz.
Devam et örnek kampanyayı gösterir; gerçek kayıt dosyası okunmaz/yazılmaz.

1920×1080 yakalamalar `generated/ui-p0/captures/` altındadır.
Input kontrolü `art/preview/p0/check_preview.gd` ile yapılır:

```powershell
godot --headless --path our-game --script ../art/preview/p0/check_preview.gd
```

Bu kontrol 30 ilde viewport tıklamalarını, şehir sekmelerini, katmanları, zoom/pan,
yıl sınırlarını, rehberi, gazete kararını, rapor ayrıntılarını, proje durumlarını ve native GUI
sürükle-bırak ile sevk formunu dener. Kaynak sınırı ve hatalı drag payload'ı da kontrol edilir.
Görsel kabul yerine geçmez.

`art/preview/p0/capture_preview.gd` grafik renderer ile 27 adet 1920×1080 PNG üretir ve
metinleri otomatik genişleyen etiket yerine authored kutu ölçüsüne göre kontrol eder.
Yakalamalar panel kapalı başlangıcı, panel açık ana ekranı, batıya sürükleme ve yakınlaştırmayı içerir.
F11 ile tam ekrana girip pencereye dönüşü de doğrular. `--headless` kullanmadan aynı script
çağrısıyla çalıştırılır. Otomatik geometri kontrolüne ek olarak görüntüler native boyutta incelenir.
Yerel .NET Godot importu eksik SDK nedeniyle hata verdiği için bu önizlemenin import/unit/startup
kontrolleri standart Godot 4.6.3 ile çalıştırılmıştır; proje GDScript kullanır.

Kararlar, sınıf ilişkileri ve denge adayları [oyun tasarımında](../../../../docs/game-design.md) bulunur.
