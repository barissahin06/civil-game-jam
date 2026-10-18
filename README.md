# Rewrite it

**Hazırlan. Müdahale et. Geleceği yeniden yaz.**

Rewrite it, Türkiye'nin yakın tarihinde geçen bir afet yönetimi ve strateji oyunudur.
Ulusal afet koordinatörü olarak ülkenin kaynaklarını yönetir, şehirleri afetlere hazırlar
ve kriz anında ekiplerle yardım malzemelerini ihtiyaç duyulan bölgelere ulaştırırsın.
Bugün yaptığın bir yatırım, yıllar sonra yaşanacak bir afetin sonucunu değiştirebilir.

## Kampanya

1950–1990 arasında bir başlangıç yılı seç ve 31 Aralık 2026'ya kadar ülkenin afet
yönetimini üstlen. Türkiye'nin yedi bölgesindeki **30 yönetim merkezi**, çevrelerindeki
illerle birlikte 81 ili kapsar. Her merkezin hazırlığını, altyapısını, ekiplerini ve
yardım stoklarını tek bir ulusal bütçeyle yönetirsin.

Amaç; can kaybını ve hasarı azaltmak, afetlerden sonra toparlanmak ve halkın güvenini
koruyarak kampanyayı tamamlamak. Halkın Güveni sıfıra düşerse kampanya erken sona erer.

## Oynanış döngüsü

1. **Afet gelmeden hazırlan.** Şehirlerin ihtiyaçlarını incele, koruyucu yatırımlar yap,
   ekip kur ve yardım malzemesi hazırla. Bütçeni yalnız bugünkü harcamalara göre değil,
   projelerin aylık taksitlerine ve tesislerin bakım giderlerine göre de planla.
2. **Kriz sırasında öncelik belirle.** Afet haberi geldiğinde zaman durur. Ekip ve
   malzemeleri haritadan veya sevk panelinden gönder; yol süresini, taşıma bedelini ve
   bölgenin ihtiyacını hesaba kat. Aynı anda birden fazla afetle karşılaşabilirsin.
3. **Sonuçları değerlendir ve toparlan.** Müdahale raporlarını incele, hasarlı altyapıyı
   onar, yardım stoklarını yenile ve ekiplerinin dönüşünü planla. Bazı afetlerin ardından
   açılan seçeneklerin anlık etkilerini ve uzun vadeli proje yükünü değerlendirerek kalıcı kararlar ver.
4. **Bir sonraki afete daha güçlü gir.** Araştırmalarla yeni önlemler aç, bilinç
   puanlarını toplumsal hazırlığa ayır ve zamanla yıpranan merkezlerini yenile.
   Her karar gelecekteki hazırlığını ve halkın sana duyduğu güveni etkiler.

## Tarihsel afetler, değişebilen sonuçlar

Deprem, sel, yangın, çığ ve heyelanlar tarihsel başlangıç tarihlerinde karşına çıkar.
Gazete biçimindeki haberler olayları aktarırken müdahale raporları senin hazırlığının
ve kararlarının sonuçlarını gösterir. Afetin zamanı bellidir; ne kadar hazırlıklı
olduğun ve yardımı ne kadar hızlı ulaştırdığın kampanyanın gidişini değiştirir.

Oyun içindeki maliyetler, müdahale süreleri ve sonuç hesapları oynanış için modellenmiştir;
tarihsel kayıpların birebir yeniden üretimi veya bilimsel bir afet tahmini değildir.

## Oynamaya başla

- Yeni kampanyada uygulamalı rehber, hazırlık ve müdahale adımlarını oyun içinde öğretir.
  Menüdeki **Oyun Rehberi** ile konuları tekrar okuyabilirsin.
- Haritayı sürükleyebilir, yakınlaştırabilir ve hazırlık, yardım stoğu veya altyapı hasarı
  görünümleriyle merkezleri karşılaştırabilirsin.
- **Boşluk** zamanı durdurur veya sürdürür; **1× / 2× / 4×** düğmeleri hızı değiştirir.
  **Esc** oyun içi menüyü açar; **F11** tam ekran ile pencere arasında geçiş yapar.
- Bir otomatik ve üç manuel kayıt yuvasıyla kampanyana daha sonra devam edebilirsin.

Oyun Türkçe arayüz ve pixel art görseller kullanır. Tarihsel kampanya oynanabilir;
Sandbox modu şu an kilitlidir.

## Kaynaktan çalıştırma ve geliştirme

Oyun **Godot 4.6.3** ile geliştirilir. Godot Project Manager'a
`our-game/project.godot` dosyasını ekleyip **F5** ile çalıştırabilirsin.
Ana menüden **Yeni Oyun** seçerek kampanyanı başlat.

Geliştirme ve doğrulama araçları için Python 3.13, uv ve Node.js 18+ gerekir.
Repo kökünde:

```powershell
uv sync --project tools --frozen
npm ci --ignore-scripts
npm run setup:godot
npm run verify
```

Godot PATH'te değilse `GODOT_PATH` tanımla. Diğer komutlar ve Windows paketi oluşturma
adımları [geliştirme rehberinde](docs/development.md), lisanslı Aseprite gerektiren
MCP kurulumu ise [araç rehberinde](tools/mcp/README.md) bulunur.

## Rehberler

- [Çalışma kuralları](AGENTS.md)
- [Klasörler ve mimari](docs/architecture.md)
- [Üç kişilik paralel çalışma](docs/team-workflow.md)
- [Oyun kararları ve uygulama sırası](docs/game-design.md)
- [P0 native kaynaklar ve önizleme](art/production/ui/p0/README.md)
- [Kod ve veri standardı](docs/code-style.md)
- [Geliştirme ve doğrulama](docs/development.md)
- [Bağımlılık sahipliği](docs/dependencies.md)
- [Aseprite / Godot araçları](tools/mcp/README.md)
- [Art üretim kuralları](art/production/AGENTS.md)

MCP kaynakları `godot-aseprite-toolkit` deposunun sabitlenmiş sürümüdür;
ilgili MIT lisansları paketlerin içindedir.
