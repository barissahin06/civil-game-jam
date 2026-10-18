extends RefCounted
## Player-facing guide; rules and values remain owned by the simulation.

const PAGES: Array[Dictionary] = [
	{
		"title": "AMAÇ VE İLK ADIMLAR",
		"sections":
		[
			{
				"heading": "HAZIRLAN > MÜDAHALE ET > TOPARLAN",
				"text":
				"Türkiye'de afetlere hazırlık ve yardım işlerini yönetiyorsun. Merkezleri güçlendir, afetlerde ekip ve malzeme gönder, sonra hasarı onar. Halkın Güveni 0'a düşerse oyun biter. 2026 sonuna ulaşırsan hazırlık, yardım çalışmaları ve onarım için ayrı puan alırsın."
			},
			{
				"heading": "İLK YAPACAKLARIN",
				"text":
				"Haritada bir merkez seç. Yatırım sekmesinden bütçene uygun bir proje başlat. Yatırım ve Araştırma > Araştırmalar'dan başlayabildiğin bir araştırma seç. Ekip ve Yardım Hazırla ile ekip ve malzeme hazırla. Sonra Zamanı Başlat'a bas. İlk afet haberini okuyunca yardım gönder."
			},
			{
				"heading": "ZAMANI SEN YÖNETİRSİN",
				"text":
				"Oyun başladığında zaman durur. Bu sırada proje başlatabilir, ekip ve malzeme gönderebilirsin. Afet yokken aylar, afet sırasında günler geçer. Sağ üstten zamanı başlat, durdur veya hızını değiştir. Haber ve uyarıları kapattıktan sonra zamanın durup durmadığına bak."
			}
		]
	},
	{
		"title": "HARİTAYI VE GÖSTERGELERİ OKU",
		"sections":
		[
			{
				"heading": "BİR MERKEZ, ÇEVRESİNDEKİ İLLERİ DE YÖNETİR",
				"text":
				"Sınırları parlak çizilmiş 21 merkezden birine tıkla. Soldaki bilgiler bu merkezle ona bağlı illeri kapsar. Yatırım sekmesinde proje başlatırsın. Lojistik sekmesinde ekip ve malzemeleri görürsün. Soluk çizilmiş illere ayrı tıklanmaz; onları bağlı oldukları merkezden yönetirsin."
			},
			{
				"heading": "SOL ALTTAKİ HARİTA ARAÇLARINI AÇ",
				"text":
				"Renklerin ve işaretlerin açıklamalarına bak. Bölgeler görünümünde her renk bir bölgeyi gösterir. Afet Hazırlığı beş afet için hazırlık değerlerinin ortalamasıdır. Yardım Malzemesi depodaki miktarı, Altyapı Hasarı hasarı gösterir. Sayılar için merkezin üzerine gel. Kırmızı renk ve ! süren afeti gösterir."
			},
			{
				"heading": "ÜST ŞERİTTE NEYİ İZLEYECEKSİN?",
				"text":
				"Bütçe bütün merkezlerin ortak parasıdır. Halkın Güveni ülke için tek değerdir. Bilinç Puanı'nı bazı araştırmalarda harcarsın. Hazır Ekip hemen gönderebildiklerini sayar; Toplam yolda ve görevdekileri de içerir. Haritayı sürükle; fare tekerleği veya + / - ile yakınlığı değiştir."
			}
		]
	},
	{
		"title": "BÜTÇE, TAKSİT VE BAKIM",
		"sections":
		[
			{
				"heading": "AYLIK GELİRİN BİR KISMI GİDERLERE AYRILIR",
				"text":
				"Ay başında gelir toplanır. Önce bakım giderleri, sonra proje taksitleri ödenir. Bütçe altındaki Son Ay tutarı, gelirden bakım gideri çıkınca kalan paradır. Proje taksitleri bu hesaba dahil değildir. Yatırım ve Araştırma > Projeler'den aylık taksitleri de kontrol et."
			},
			{
				"heading": "BAŞLATMADAN ÖNCE KARŞILAŞTIR",
				"text":
				"Projenin toplam fiyatına, aylık taksitine, kaç ay süreceğine ve bittikten sonraki bakım giderine bak. Kurduğun tesisler ve ekipler her ay para harcar. Ekip ve malzeme göndermek de ücretlidir. Bütün paranı projelere bağlama; afet yardımı için para ayır."
			},
			{
				"heading": "PARA YETMEZSE NE OLUR?",
				"text":
				"Taksit ödenemezse proje o ay ilerlemez. Bakım parası yetmezse ekip ve tesisler daha az etkili çalışır; parayla yürüyen projeler bekler. Projeler'den önce hangi işin ödeneceğini seçebilir veya işi duraklatabilirsin. Bütçe borca girmez; çok iş başlatmak işleri geciktirebilir."
			}
		]
	},
	{
		"title": "ŞEHİR YATIRIMLARI VE PROJELER",
		"sections":
		[
			{
				"heading": "ŞEHİR > YATIRIM > İNCELE > BAŞLAT",
				"text":
				"Şehir özetinde hangi afet türüne hazırlığın düşük olduğuna bak. Yatırım sekmesinden buna uygun bir proje seç. Ayrıntıda bugünkü değerle proje bittiğindeki değeri karşılaştır. Proje bitmeden koruma artmaz. Gösterilen sonuç bugünkü duruma göre hesaplanır."
			},
			{
				"heading": "HER MERKEZDE AYNI ANDA BİR İŞ YÜRÜR",
				"text":
				"Bir merkez aynı anda yatırım, ekip kurma, yardım hazırlama, onarım veya yenileme işlerinden birini yapar. Farklı merkezlerde aynı anda işler yürütebilirsin; hepsi ortak parayı kullanır. Başlatamadığın projenin ayrıntısında neyi beklemen gerektiği yazar."
			},
			{
				"heading": "YATIRIM VE ARAŞTIRMA > PROJELER",
				"text":
				"Başlamış, sırada bekleyen ve duraklatılmış işleri burada izle. Ödeme Önceliği hangi taksitin önce ödeneceğini değiştirir; işlerin başlama sırasını değiştirmez. Duraklatınca yapılan iş korunur, başka işe yer açılır. İptalde paran geri verilmez; halka verdiğin sözden dönersen güven de azalır."
			}
		]
	},
	{
		"title": "ARAŞTIRMA, BİLİNÇ VE ÜLKE GENELİNDE ÖNLEMLER",
		"sections":
		[
			{
				"heading": "ARAŞTIRMAYI BİTİR, YENİ YATIRIMLARI AÇ",
				"text":
				"Araştırmalar'da bir konu seç. Tarihler o araştırmanın hangi yılda açıldığını, oklar önce bitmesi gereken araştırmaları gösterir. Başlatamadığın kartın açıklamasını oku. Araştırma bitince yeni bir yatırım açılabilir; onu ayrıca başlatman gerekir."
			},
			{
				"heading": "BAŞLANGIÇTA AYNI ANDA İKİ ARAŞTIRMA YAPABİLİRSİN",
				"text":
				"Bilinç bölümündeki araştırmalar Bilinç Puanı, diğerleri para ister. Hepsinin bitmesi zaman alır. Başlangıçta toplam iki araştırma aynı anda yürür. Puan kazanmak için haritadaki bilinç baloncuklarına tıkla. Afet sürerken veya zaman durmuşken yeni baloncuk çıkmaz."
			},
			{
				"heading": "ÖNLEMLER BÜTÜN MERKEZLERE FAYDA SAĞLAR",
				"text":
				"Önlemler sekmesinden ülke genelinde bir proje başlatabilirsin. Bu projelerden aynı anda biri yürür; şehirdeki işleri engellemez. Bazıları için belli bir yılın gelmesi veya araştırmanın bitmesi gerekir. Gösterilen etki bütün merkezlerin ortalamasıdır."
			}
		]
	},
	{
		"title": "EKİP KUR VE YARDIM HAZIRLA",
		"sections":
		[
			{
				"heading": "EKİP VE YARDIM HAZIRLA > EYLEM SEÇ > MERKEZE TIKLA",
				"text":
				"Üstten Ekip ve Yardım Hazırla'ya bas. Ekip Kur veya Yardım Hazırla'yı seç, sonra haritadaki bir merkeze tıkla. Her tıklama bir iş ekler. Aynı merkeze tekrar tıklayabilir veya başka merkez seçebilirsin. Yeni ekip ve malzemeler iş tamamlanınca hazır olur."
			},
			{
				"heading": "MERKEZDE BİR İŞ VARSA YENİ İŞ SIRADA BEKLER",
				"text":
				"Merkezde başka iş yoksa verdiğin iş başlar. Varsa sırasını bekler. Sıradaki iş için henüz para ödenmez. Önceki iş bitince sıradaki başlar ve ilk taksiti sonraki ay ödenir. Hazırlık ekranında başlayan ve bekleyen işlerle eldeki ekip ve malzemeleri görebilirsin."
			},
			{
				"heading": "YANLIŞ EMRİ NASIL GERİ ALIRSIN?",
				"text":
				"Merkezin yanındaki - düğmesi son bekleyen işi ücretsiz kaldırır. Başlamış işi Projeler'den duraklat veya iptal et. Duraklatılmış aynı tür iş sırayı engelliyorsa onu sürdür ya da iptal et. Merkezlerin bilgilerine tekrar bakabilmek için hazırlık ekranını × veya Esc ile kapat."
			}
		]
	},
	{
		"title": "MERKEZLER ARASI TAŞIMA VE EKİP DURUMU",
		"sections":
		[
			{
				"heading": "EKİPLER VE YARDIM > MERKEZLER ARASI TAŞIMA",
				"text":
				"Afetten önce başka bir merkeze ekip veya malzeme taşıyabilirsin. Nereden, nereye ve ne kadar göndereceğini seç. Ekip Taşı, ekibi o merkezde hazır bekletir. Depoya Malzeme, yardımı o merkezin deposuna koyar. Süre ve ücrete bakıp Taşımayı Onayla'ya bas."
			},
			{
				"heading": "DEPOYA TAŞIDIĞIN MALZEMEYİ AFETE AYRICA GÖNDER",
				"text":
				"Depoya koyduğun yardım kendiliğinden afet bölgesine gitmez. Afet başlayınca ayrıca göndermen gerekir. Başka merkeze taşıdığın ekip orada geçici olarak kalır. Onu bulunduğu yerden afete gönderebilir veya Asıl Merkeze Çağır ile geri çağırabilirsin."
			},
			{
				"heading": "TOPLAM EKİP HER AN KULLANILABİLEN EKİP DEĞİLDİR",
				"text":
				"Listede ekiplerin hazır mı, yolda mı, görevde mi olduğuna bak. Yoldaki veya görevdeki ekibi tekrar gönderemezsin. Afet görevi bitince ekip asıl merkezine döner; vardığında yeniden hazır olur. Şehirdeki Gönderim Hazırla düğmesi afet yardım ekranını açar."
			}
		]
	},
	{
		"title": "AFET HABERİNDEN İLK GÖNDERİME",
		"sections":
		[
			{
				"heading": "GAZETE > HABERİ OKUDUM > AFET MÜDAHALESİ",
				"text":
				"Afet başlayınca zaman durur ve gazete açılır. Haberi Okudum'a basınca yardım gönderme ekranı açılır. Birden fazla afet varsa üst listeden yardım göndereceğin afeti seç. Bu ekranı Afet Müdahalesi'nden, son haberi ve raporu Haberler ve Raporlar'dan tekrar açabilirsin."
			},
			{
				"heading": "AFETİ SEÇ > EKİP VEYA MALZEME SEÇ > MİKTARI AYARLA",
				"text":
				"Afet bölgesinde neyin eksik olduğuna bak. Ekip veya malzeme seç, hangi merkezden göndereceğini belirle. Miktarı + / - ya da İhtiyaca Göre Ayarla ile seç. Bu seçimler para harcamaz. Süre ve ücrete bakıp Gönderimi Onayla'ya bas. Afet bölgesine sürüklemek 1 ekip veya 10 birim malzeme gönderir."
			},
			{
				"heading": "GÖNDERDİKTEN SONRA ZAMANI BAŞLAT",
				"text":
				"Ekip ve malzeme yoldayken yardım sağlamaz; afet bölgesine ulaşmaları gerekir. Yakın merkezden daha erken varabilirler. Yolculuğun kaç gün süreceğine ve afet için kalan süreye bak. Zamanı Başlat'a basıp günleri ilerlet. Birden çok afette ekip ve malzemeyi aralarında paylaştır."
			}
		]
	},
	{
		"title": "YARDIM MALZEMELERİ VE ACİL BÜTÇE",
		"sections":
		[
			{
				"heading": "YARDIM MALZEMELERİ HER GÜN KULLANILIR",
				"text":
				"Afet ekranında günlük ihtiyaca, kalan malzemeye ve ne zaman biteceğine bak. Bölgede sınırlı miktarda malzeme tutulur; hepsini tek seferde gönderemezsin. İhtiyaca Göre Ayarla, yoldaki yardımı da sayar. Gönderebileceğin miktarı merkezdeki malzemeye ve parana göre seçer."
			},
			{
				"heading": "YARDIM AZALDIĞINDA YENİDEN MALZEME GÖNDER",
				"text":
				"Üç gün içinde malzeme yetersiz kalacaksa oyun zamanı durdurur. Eksik kalmadan yetişebilecek bir merkezden yardım gönder. Gerekirse başka merkez seç. Sonra zamanı yeniden başlat. Uzun süren afette malzeme her gün kullanılır; tekrar göndermen gerekebilir."
			},
			{
				"heading": "ACİL BÜTÇE EKİP VE MALZEMENİN YERİNİ TUTMAZ",
				"text":
				"Afet ekranındaki Acil Bütçe ile o afete para ayırabilirsin. Bu para yardım çalışmalarını ve sonraki onarımı bir miktar destekler. Eksik ekip ve malzemeyi ayrıca göndermelisin. Doğru afeti seçtiğine bak. Para ortak bütçeden çıkar; proje taksitlerini de düşün."
			}
		]
	},
	{
		"title": "RAPOR, ONARIM VE MERKEZ YENİLEMESİ",
		"sections":
		[
			{
				"heading": "RAPORDA KARARLARININ SONUCUNU OKU",
				"text":
				"Yardım süresi bitince rapor açılır. Hazırlığın ve gönderdiğin yardımın etkisine, kalan hasara ve güven değişimine bak. Korunan insan ve önlenen hasar sayıları oyunun yaptığı tahminlerdir. Ayrıntılar ile daha fazla bilgi görürsün. Onarımı İncele ile onarım projesini açabilirsin."
			},
			{
				"heading": "AFET BİTTİĞİNDE HASAR KENDİLİĞİNDEN KAYBOLMAZ",
				"text":
				"Hasar, merkezin gelirini ve dayanıklılığını azaltır. Onarımı sen başlatırsın; merkezde başka iş varsa beklemen gerekir. Taksitler ödendikçe hasar azalır. Afetten altı ay sonra kalan hasar halkın güvenini azaltmaya başlar. Onararak bu kaybın bir kısmını geri kazanabilirsin."
			},
			{
				"heading": "YIPRANAN EKİP VE TESİSLERİ YENİLE",
				"text":
				"Şehirdeki Kondisyon, ekip ve tesislerin ne kadar yıprandığını gösterir. Değer düştükçe daha az etkili çalışırlar. Yatırım'daki Merkez yenilemesi bunu düzeltir. Ne kadar çok ekip ve tesis varsa fiyat o kadar artar. Afet hasarı için ayrıca onarım yapmalısın."
			}
		]
	},
	{
		"title": "AFET SONRASI KARARLAR VE HALKIN GÜVENİ",
		"sections":
		[
			{
				"heading": "BAZI RAPORLARDAN SONRA KALICI KARAR VERİRSİN",
				"text":
				"Bazı afetlerin bütün raporlarını okuyunca seçenekler sunulur. Her seçeneğin fiyatına, süresine, faydasına ve halkın güvenini nasıl değiştirdiğine bak. Seçeneğini onaylayana kadar zaman durur. Kararını sonradan değiştiremezsin; reddettiğin projeyi başka ekrandan başlatamazsın."
			},
			{
				"heading": "PROJEYİ KABUL EDERSEN HALKA SÖZ VERMİŞ OLURSUN",
				"text":
				"Kabul ettiğin proje, şehir veya ülke genelindeki işlerden biri sayılır. Başka iş varsa sırada bekler. Faydasını tamamlanınca görürsün. Altı ay ilerlemezse uyarı alırsın; on iki aydan sonra her ay güven kaybedersin. Sırada beklemek veya duraklatmak bu süreyi durdurmaz."
			},
			{
				"heading": "GÜVENİ YALNIZ AFET ANINDA DEĞİL, HER AY İZLE",
				"text":
				"Güven zamanla azalır. Hazırlığın, yaptığın yardımlar ve bitirdiğin işler güveni etkiler. Halka söz verdiğin projeyi iptal edersen de güven kaybedersin. Üstte güvenin üzerine gelerek son değişimin nedenini oku. Güven düşüyorsa yardımları, ödemeleri ve onarımları kontrol et."
			}
		]
	},
	{
		"title": "KAYIT, KONTROLLER VE SONRAKİ ADIM",
		"sections":
		[
			{
				"heading": "MENÜ > KAYDET / YÜKLE",
				"text":
				"Oyun kendisi kayıt tutar. Ayrıca Menü > Kaydet'ten kullanabileceğin üç kayıt yeri vardır. Önemli kararlardan önce kayıt alabilirsin. Ana menüye dönerken oyun kaydedilir. Yeni oyun yalnız otomatik kaydın yerine geçer. Eski kayıt yüklenince o kayıttaki tarihe dönersin."
			},
			{
				"heading": "ESC, AYARLAR VE REHBERE DÖNÜŞ",
				"text":
				"Esc ile oyunu durdurup menüyü açarsın. Devam Et ile önceki ekrana dönersin. Ayarlar'dan ekranı, müziği, diğer sesleri ve afet sarsıntısını ayarlayabilirsin. F11 ile pencere ve tam ekran arasında geçersin. Oyun Rehberi'ni yeniden açıp üst listeden istediğin bölümü seçebilirsin."
			},
			{
				"heading": "HARİTAYA DÖNDÜĞÜNDE",
				"text":
				"Önce parana ve aylık giderlerine bak. Bir merkezde neyin eksik olduğunu bul ve paran yetecek bir işe başla. Ekip ve malzeme hazırla, sonra zamanı başlat. Afette yardımı zamanında gönder; malzeme azaldıkça yenisini yolla. Sonrasında hasarı onar ve verdiğin sözleri yerine getir."
			}
		]
	}
]
