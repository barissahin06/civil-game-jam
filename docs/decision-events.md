# Afet sonrası kararlar

21 kart, kaynaklı 20 doğal afet kaydındaki 25 aksiyonu oynanışa bağlar. İliç maden kazası kapsam
dışındadır. Marmara'nın yapı denetimi, tıbbi kurtarma ve ulusal koordinasyon aksiyonları ayrı
kartlardır; Marmara ve Düzce'nin ortak yapı denetimi aynı karttır ve ikinci kez seçilemez.

## İçerik ve sahiplik

- [decisions.json](../our-game/events/data/decisions.json): kart metni, kaynak afet kimlikleri,
  yönetim alanı ve üç alternatif. `full`, `focused` ve `decline` kimlikleri sabittir.
- [measures.json](../our-game/management/data/measures.json): 42 ayrı `decision_` projesinin
  maliyet, süre, bakım ve tamamlanma etkileri. Kartlarda bu sayılar kopyalanmaz.
- [aftermath.json](../our-game/events/data/historical/aftermath.json): kaynak bağlantılarıyla
  tarihsel aksiyon arşivi. Kartın tarihsel notu bu açıklamaları korur; arşiv değiştirilmemiştir.
- [preventive_actions.json](../our-game/management/data/preventive_actions.json): içerik fikirleri
  arşivi. Maden dışındaki 14 fikir, kartların taşıma, yapı/okul güvenliği, dere/bent/köprü,
  yangın, eğitim, tıbbi kurtarma ve koordinasyon alternatiflerinde temsil edilir.

Tarihsel açıklama, alternatiflerin veya sayısal kazançların tarihte gerçekleştiği iddiası değildir.
Alternatifler, TL tutarları ve süreler oyun tasarımı ve ilk denge adaylarıdır. Örneğin 4708 sayılı
Kanun 2001'e, AFAD kuruluşu 2009'a aittir; 1999 deprem günü kurulmuş olarak sunulmaz. UMKE de
deprem sonrası reform süreci olarak anlatılır. Oyun, oyuncunun alternatif programını ilgili afetin
raporundan sonra başlatır.

## Kesinleşme ve uygulama

İlgili afetin bütün yönetim alanlarındaki müdahaleleri bittiğinde ve bütün raporları okunduğunda
`Gelecek Afetler İçin Önlem Seç` başlıklı ekran bir kez açılır. Takvim seçim yapılana kadar durur.
Önce alternatif seçilir,
ardından `SEÇİMİ ONAYLA` ile kesinleşir. Menü/Esc karar vermiş sayılmaz.

Her alternatifin etkileri 3–4 satırlık özette karşılaştırılır: kazanımlar yeşil `+`,
bedel ve kayıplar kırmızı `-` ile gösterilir. Sınıra ulaşmış sıfır kazanımlar nötrdür.
Proje seçeneklerinin fayda satırı, etkilerin ne zaman geleceğini `Proje bitince kazanım` ile belirtir.
Toplam bedel, aylık taksit/bakım, süre ve yerel/ulusal slot sırası görünür; seçenek
başlığının üzerine gelince programın açıklaması okunabilir. Sayılar mevcut proje önizlemesinden gelir.
Ret seçeneğinin özeti `Bu iki projeyi bu oyunda bir daha başlatamazsın.` cümlesini görünür tutar.

Her kartın kapsamlı ve odaklı seçenekleri anlık güven değişimi 0 olan iki ayrı projedir.
`İki projeyi de reddet` yeni gelir, koruma veya proje üretmez; güveni doğrudan değiştirmez ve kartın iki
programını kampanya boyunca kapatır. Tamamlama güven puanı vermez; hazırlığın sahadaki sonuçları
değerlendirilir. Kabul edilen proje halka taahhüttür: kesin iptal bir kez −0,5 güven; son gerçek
ilerlemeden sonra 6 tam takvim ayında uyarı, 12 aydan itibaren ayda −0,1 güven doğurur.
Sıradaki projede süre seçimden başlar; ödeme ve gerçek ilerleme süreyi yeniler. Duraklat/sürdür
ve kayıt/yükleme süreyi sıfırlamaz. Güven 0–100 sınırındadır.
Tüm seçeneklerin görünen başlıkları `DecisionSystem` tarafından önizleme, güven değişiminin
nedeni ve sonuç bildiriminde aynı adla sunulur. Ret ve sınırlı seçeneklerin açıklamaları da
çalışma anındaki önizlemede sadeleştirilir; kapsamlı seçeneklerin teknik ayrıntıları katalogdaki
açıklamalarında aynen korunur. Katalog JSON'u ve içerik parmak izi değişmez. Sınırlı seçenekler
`Önce…` yerine kapsamı ve eylemi doğrudan anlatır; daha sonra kapsamlı programa geçiş vaat etmez.
Samsun'un ekip seçeneği `Bir arama kurtarma ekibi kur` olarak gösterilir.

Yerel projeler ilgili yönetim merkezinin slotunu, ulusal projeler ortak ulusal slotu kullanır.
Slot doluysa FIFO sırasına girer. Sıradayken ödeme, ilerleme, bakım veya koruma yoktur.
Proje başlayınca aylık taksitlerle ilerler; o ayın taksiti karşılanmazsa ilerlemez. Başlangıçta
ayrı peşinat alınmaz. Kalıcı etki ve bakım tamamlanınca başlar; kapanmış raporların sonucu değişmez.
Önizleme bugünkü sınırları ve koşulları kullanarak gerçekten kazanılacak farkı gösterir.

Karar, duraklatma veya iptalden sonra da kalıcıdır. İptalde ödenen taksit geri verilmez,
tamamlanma etkisi ve ödülü verilmez, karşı seçenek açılmaz. `decision_` projeleri normal yatırım,
araştırma ve komut ekranından başlatılamaz. Diğer tedbirler kullanılabilir.

Yerel coğrafya, 81 ilin 30 merkeze bağlandığı mevcut alan modeliyle uygulanır. Örneğin Gediz
(Kütahya) Afyonkarahisar, Bozkurt Kastamonu merkezine; Çatak ve Üzengili Trabzon merkezine bağlıdır. Kart metni gerçek
yerleşimi anlatır, sayısal koruma ilgili yönetim alanını etkiler.

## İlk sayısal katalog

Aşağıdaki tutarlar oyun TL'sidir. Koruma/direnç ve yüzdeyle sunulan verim/tahliye değerleri
eklenen puanlardır; doğrudan can kaybı yüzdesi değildir. Sınırlar nedeniyle canlı kazanım daha
düşük olabilir. Her kartın üçüncü seçeneği yukarıdaki kalıcı ret kuralını kullanır.
Tablodaki seçenek başlıkları kaynak katalogdaki adlardır; oyuncuya görünen başlıklar yukarıdaki
sunum kuralıyla sadeleştirilir.

| Kart / yönetim alanı                | Seçenek                          | Toplam TL | Ay  | Tamamlanma etkisi                                                                                | Bakım TL/ay |
| ----------------------------------- | -------------------------------- | --------- | --- | ------------------------------------------------------------------------------------------------ | ----------- |
| `gediz_relocation` / Afyonkarahisar | Planlı yeniden yerleşim          | 18 milyon | 12  | deprem koruması +18 puan; altyapı direnci +4 puan                                                | 0           |
| `gediz_relocation` / Afyonkarahisar | Öncelikli kesimleri taşı         | 6 milyon  | 6   | deprem koruması +8 puan; altyapı direnci +1 puan                                                 | 0           |
| `samsun_flood` / Samsun             | Yerleşim ve dere ıslahı          | 18 milyon | 12  | sel koruması +22 puan; altyapı direnci +4 puan                                                   | 80 bin      |
| `samsun_flood` / Samsun             | Önce müdahale kapasitesi         | 4 milyon  | 4   | ekip +1                                                                                          | 40 bin      |
| `construction_inspection` / Ulusal  | Yaygın yapı denetimi             | 36 milyon | 18  | deprem koruması +10 puan; altyapı direnci +2 puan                                                | 0           |
| `construction_inspection` / Ulusal  | Yüksek riskli yapıları denetle   | 12 milyon | 6   | deprem koruması +4 puan; altyapı direnci +1 puan                                                 | 0           |
| `kursunlu_relocation` / Ankara      | İki köyü planlı taşı             | 18 milyon | 12  | deprem koruması +18 puan; altyapı direnci +4 puan                                                | 0           |
| `kursunlu_relocation` / Ankara      | Önce riskli konutları taşı       | 6 milyon  | 6   | deprem koruması +8 puan; altyapı direnci +1 puan                                                 | 0           |
| `hazard_zoning` / Ulusal            | Ulusal tehlikeli alan düzeni     | 36 milyon | 18  | deprem koruması +7 puan; heyelan koruması +5 puan; çığ koruması +5 puan; altyapı direnci +2 puan | 0           |
| `hazard_zoning` / Ulusal            | Önce yüksek riskli alanlar       | 12 milyon | 6   | deprem koruması +3 puan; heyelan koruması +2 puan; çığ koruması +2 puan                          | 0           |
| `catak_relocation` / Trabzon        | Konutları güvenli alana taşı     | 18 milyon | 12  | heyelan koruması +22 puan; altyapı direnci +4 puan                                               | 0           |
| `catak_relocation` / Trabzon        | Önce acil riskli konutlar        | 6 milyon  | 6   | heyelan koruması +10 puan; altyapı direnci +1 puan                                               | 0           |
| `senirkent_flood` / Antalya         | Havza ve bent programı           | 18 milyon | 12  | sel koruması +22 puan; altyapı direnci +4 puan                                                   | 80 bin      |
| `senirkent_flood` / Antalya         | Öncelikli bentleri kur           | 6 milyon  | 6   | sel koruması +10 puan; altyapı direnci +1 puan                                                   | 20 bin      |
| `medical_rescue` / Ulusal           | Ulusal tıbbi kurtarma ağı        | 36 milyon | 18  | kurtarma verimi +15 puan; lojistik verimi +5 puan                                                | 120 bin     |
| `medical_rescue` / Ulusal           | Önce ortak eğitim düzeni         | 12 milyon | 6   | kurtarma verimi +6 puan                                                                          | 40 bin      |
| `national_coordination` / Ulusal    | Bütünleşik görev ve iletişim     | 36 milyon | 18  | kurtarma verimi +10 puan; lojistik verimi +10 puan; onarım verimi +5 puan                        | 120 bin     |
| `national_coordination` / Ulusal    | Ortak müdahale protokolü         | 12 milyon | 6   | kurtarma verimi +4 puan; lojistik verimi +4 puan                                                 | 40 bin      |
| `istanbul_streambeds` / İstanbul    | Tespit ve dere yatağı düzeni     | 18 milyon | 12  | sel koruması +18 puan; altyapı direnci +3 puan                                                   | 40 bin      |
| `istanbul_streambeds` / İstanbul    | Önce risk envanteri              | 6 milyon  | 6   | sel koruması +6 puan; tahliye +2 puan                                                            | 0           |
| `silivri_school_safety` / İstanbul  | Güvenli okul ve eğitim programı  | 18 milyon | 12  | deprem koruması +14 puan; altyapı direnci +3 puan; tahliye +4 puan                               | 40 bin      |
| `silivri_school_safety` / İstanbul  | Önce yüksek riskli okullar       | 6 milyon  | 6   | deprem koruması +6 puan; tahliye +2 puan                                                         | 0           |
| `dereli_flood` / Trabzon            | Dere yatağı ve köprüleri düzenle | 18 milyon | 12  | sel koruması +22 puan; altyapı direnci +4 puan                                                   | 80 bin      |
| `dereli_flood` / Trabzon            | Önce kritik köprüler             | 6 milyon  | 6   | sel koruması +10 puan; altyapı direnci +1 puan                                                   | 20 bin      |
| `izmir_risk_planning` / İzmir       | Envanter ve ortak risk platformu | 18 milyon | 12  | deprem koruması +12 puan; altyapı direnci +2 puan; kurtarma verimi +5 puan                       | 40 bin      |
| `izmir_risk_planning` / İzmir       | Önce öncelikli yapı envanteri    | 6 milyon  | 6   | deprem koruması +5 puan; altyapı direnci +1 puan                                                 | 0           |
| `bozkurt_flood` / Kastamonu         | Dere, duvar ve köprü programı    | 18 milyon | 12  | sel koruması +22 puan; altyapı direnci +4 puan                                                   | 80 bin      |
| `bozkurt_flood` / Kastamonu         | Önce kritik taşkın kesimleri     | 6 milyon  | 6   | sel koruması +10 puan; altyapı direnci +1 puan                                                   | 20 bin      |
| `urban_transformation` / Ulusal     | Ulusal güvenli dönüşüm programı  | 36 milyon | 18  | deprem koruması +10 puan; altyapı direnci +4 puan; onarım verimi +5 puan                         | 0           |
| `urban_transformation` / Ulusal     | Önce yüksek riskli yapı grupları | 12 milyon | 6   | deprem koruması +4 puan; altyapı direnci +1 puan                                                 | 0           |
| `yesilyurt_training` / Malatya      | Yerel uyarı ve tatbikat ağı      | 6 milyon  | 6   | tahliye +8 puan; kurtarma verimi +4 puan                                                         | 20 bin      |
| `yesilyurt_training` / Malatya      | Önce hasarlı yapı uyarıları      | 2 milyon  | 3   | tahliye +3 puan                                                                                  | 0           |
| `sanliurfa_flood` / Şanlıurfa       | Üç derede koruma programı        | 18 milyon | 12  | sel koruması +22 puan; altyapı direnci +4 puan                                                   | 80 bin      |
| `sanliurfa_flood` / Şanlıurfa       | Önce yüksek riskli kesimler      | 6 milyon  | 6   | sel koruması +10 puan; altyapı direnci +1 puan                                                   | 20 bin      |
| `silivri_awareness` / İstanbul      | Okul ve mahalle tatbikatları     | 6 milyon  | 6   | tahliye +8 puan; kurtarma verimi +4 puan                                                         | 20 bin      |
| `silivri_awareness` / İstanbul      | Önce farkındalık dersleri        | 2 milyon  | 3   | tahliye +3 puan                                                                                  | 0           |
| `uzengili_relocation` / Trabzon     | Güvenli yeniden yerleşim         | 18 milyon | 12  | çığ koruması +22 puan; altyapı direnci +4 puan                                                   | 0           |
| `uzengili_relocation` / Trabzon     | Önce yüksek riskli haneler       | 6 milyon  | 6   | çığ koruması +10 puan; altyapı direnci +1 puan                                                   | 0           |
| `tasagil_firebreaks` / Antalya      | Yangın kuşağı ve dirençli orman  | 18 milyon | 12  | yangın koruması +22 puan; altyapı direnci +4 puan                                                | 80 bin      |
| `tasagil_firebreaks` / Antalya      | Önce yerleşim çevresi kuşaklar   | 6 milyon  | 6   | yangın koruması +10 puan; altyapı direnci +1 puan                                                | 20 bin      |
| `hatay_fire_response` / Hatay       | Yerel ekip ve su ikmal ağı       | 6 milyon  | 6   | yangın koruması +12 puan; kurtarma verimi +6 puan                                                | 40 bin      |
| `hatay_fire_response` / Hatay       | Önce tanker ve ekipman hazırlığı | 2 milyon  | 3   | yangın koruması +5 puan; kurtarma verimi +2 puan                                                 | 20 bin      |

## Doğrulama ve kayıt

`DecisionCatalog` her yüklemede afet, alan, alternatif ve proje bağlarını atomik doğrular.
Kimlik tekrarını, bilinmeyen projeyi, alan/ulusal sahiplik uyuşmazlığını ve tüketilmeyen etki
anahtarını reddeder. Karar projeleri 1950 taban yılı, boş önkoşul ve tek uygulama kullanır;
gerçek açılma koşulu ilgili rapor ve kalıcı oyuncu seçimidir.

Kayıt içeriği sürüm 4'tür. Kartın bekleme/seçim durumu, afet ve gün bilgileri ile bağlı proje
kimliği saklanır; yükleme yeniden ödeme veya ödül üretmez. Modern kaydın katalog parmak izi
eşleşmelidir. Yeni ekonomi ve taahhüt takibi eski kampanyalara taşınmaz; sürüm 1/2/3
yüklemesi desteklenmez. Otomatik `campaign_v4.json` ve manuel `manual_%d_v4.json` dosyaları
kullanılır; eski dosyalara dokunulmaz. Bilinmeyen veya bozuk kayıt reddedilir.

`test_catalogs.py`, tam 21 kart/20 afet/42 proje ve 25 kaynaklı aksiyonun tarihsel notlarda birer
kez bulunmasını kontrol eder. `test_decision_catalog.gd` runtime referans, kapsam ve geçersiz
yüklemede boş sonuç sınırını denetler. İlk Gediz, Samsun ve Marmara akışları genişlemeden önce
domain ve gerçek 1920×1080 renderer üzerinden doğrulanmıştır. Bu kontroller uzun kampanya
denge testi veya insanın bütün seçenekleri anlamasının kanıtı değildir.
