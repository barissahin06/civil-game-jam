extends RefCounted
## Presentation copy stays outside the gameplay catalog and its save fingerprint.

const EXPLANATIONS := {
	"river_zoning": "Sel ve depreme hazırlığı, altyapı dayanıklılığını artırır.",
	"strengthening": "Binaları deprem ve yangına hazırlar; altyapıyı güçlendirir.",
	"firebreak": "Yangın ve sel hazırlığını, malzeme taşıma verimini artırır.",
	"assembly_areas": "Her afet türüne hazırlığı ve güvenli tahliyeyi artırır.",
	"gas_cutoff": "Deprem ve yangına hazırlığı artırır.",
	"slope_control": "Heyelan ve çığ hazırlığını, altyapı dayanıklılığını artırır.",
	"rescue_team": "Bu merkezde gönderime hazır bir arama kurtarma ekibi kurar.",
	"aid_stock": "Bu merkeze gönderime hazır yardım malzemesi ekler.",
	"repair": "Ödenen her ay bu merkezin altyapı hasarını azaltır.",
	"center_renewal": "Ekip ve tesis kondisyonunu yeniler.",
	"national_radio":
	"Ortak telsiz altyapısı, kurtarma ve malzeme taşıma koordinasyonunu güçlendirir.",
	"early_warning":
	"Yağış ve havza bilgisiyle çalışan radar ağı, sel ve tahliye hazırlığını artırır.",
	"satellite_network":
	"Uydu üzerinden ortak bilgi akışı, kurtarma ve yardım koordinasyonunu destekler.",
	"research_structural": "Taşıyıcı sistem bilgisi, yapıların deprem hazırlığını artırır.",
	"research_ground":
	"Zemin davranışını tanımak, deprem ve heyelana uygun yapı kararlarını destekler.",
	"research_automation":
	"Düzenli kontrol yöntemleri, altyapının güvenilir çalışmasını destekler.",
	"research_isolation":
	"Zemin hareketinin yapıya aktarımını azaltan yöntemlerle deprem hazırlığı artar.",
	"research_meteorology": "Yağış ve sıcaklık tahminleri, sel ve çığa hazırlığı destekler.",
	"research_radar": "Yağışın konumunu izleyen yöntemler, sel hazırlığını güçlendirir.",
	"research_satellite":
	"Yerel haberleşmeye alternatif yöntemler, kurtarma koordinasyonunu destekler.",
	"research_sensor":
	"Uzak ölçüm yöntemleri, heyelan ve yangın tehlikesinin tanınmasını kolaylaştırır.",
	"research_coordination":
	"Ortak görev tanımları, mevcut kurtarma ekiplerinin birlikte çalışmasını iyileştirir.",
	"research_depots":
	"Tutarlı stok kayıtları ve yerleşim planları, malzeme taşıma verimini artırır.",
	"research_capacity": "Ortak çalışma düzeni, eş zamanlı araştırma kapasitesini artırır.",
	"research_response":
	"Kurtarma ve onarımın görev devrini düzenlemek, iki çalışmanın verimini artırır.",
	"community_preparedness":
	"Temel hazırlık bilgisi, tahliyeyi destekler ve güvenin aşınmasını yavaşlatır.",
	"household_planning":
	"Ailelerin buluşma ve çıkış planları, güvenli tahliye hazırlığını güçlendirir.",
	"evacuation_drills":
	"Birlikte uygulanan planlar, tahliye hazırlığını ve kurtarma uyumunu artırır.",
	"volunteer_network":
	"Gönüllülerin görev sınırlarını bilmesi, kurtarma çalışmalarının uyumunu artırır.",
	"public_communication":
	"Tutarlı ve anlaşılır bilgilendirme, halkın güveninin zamanla aşınmasını yavaşlatır.",
	"community_coordination":
	"Yerel dayanışma düzeni, yardım kullanımını iyileştirir ve güven aşınmasını azaltır.",
	"decision_gediz_relocation_full":
	"Merkezin deprem hazırlığını ve altyapı dayanıklılığını artırır.",
	"decision_gediz_relocation_focused":
	"Merkezin deprem hazırlığını ve altyapı dayanıklılığını artırır.",
	"decision_samsun_flood_full": "Merkezin sel hazırlığını ve altyapı dayanıklılığını artırır.",
	"decision_samsun_flood_focused": "Bu merkezde bir arama kurtarma ekibi kurar.",
	"decision_construction_inspection_full":
	"Ülke genelinde deprem hazırlığını ve altyapı dayanıklılığını artırır.",
	"decision_construction_inspection_focused":
	"Ülke genelinde deprem hazırlığını ve altyapı dayanıklılığını artırır.",
	"decision_kursunlu_relocation_full":
	"Merkezin deprem hazırlığını ve altyapı dayanıklılığını artırır.",
	"decision_kursunlu_relocation_focused":
	"Merkezin deprem hazırlığını ve altyapı dayanıklılığını artırır.",
	"decision_hazard_zoning_full":
	"Deprem, heyelan ve çığ hazırlığını; altyapı dayanıklılığını artırır.",
	"decision_hazard_zoning_focused": "Ülke genelinde deprem, heyelan ve çığ hazırlığını artırır.",
	"decision_catak_relocation_full":
	"Merkezin heyelan hazırlığını ve altyapı dayanıklılığını artırır.",
	"decision_catak_relocation_focused":
	"Merkezin heyelan hazırlığını ve altyapı dayanıklılığını artırır.",
	"decision_senirkent_flood_full": "Merkezin sel hazırlığını ve altyapı dayanıklılığını artırır.",
	"decision_senirkent_flood_focused":
	"Merkezin sel hazırlığını ve altyapı dayanıklılığını artırır.",
	"decision_medical_rescue_full": "Ülke genelinde kurtarma ve malzeme taşıma verimini artırır.",
	"decision_medical_rescue_focused": "Ülke genelinde kurtarma çalışmalarının verimini artırır.",
	"decision_national_coordination_full":
	"Ülke genelinde kurtarma, malzeme taşıma ve onarım verimini artırır.",
	"decision_national_coordination_focused":
	"Ülke genelinde kurtarma ve malzeme taşıma verimini artırır.",
	"decision_istanbul_streambeds_full":
	"Merkezin sel hazırlığını ve altyapı dayanıklılığını artırır.",
	"decision_istanbul_streambeds_focused": "Merkezin sel ve güvenli tahliye hazırlığını artırır.",
	"decision_silivri_school_safety_full":
	"Deprem ve tahliye hazırlığını, altyapı dayanıklılığını artırır.",
	"decision_silivri_school_safety_focused":
	"Merkezin deprem ve güvenli tahliye hazırlığını artırır.",
	"decision_dereli_flood_full": "Merkezin sel hazırlığını ve altyapı dayanıklılığını artırır.",
	"decision_dereli_flood_focused": "Merkezin sel hazırlığını ve altyapı dayanıklılığını artırır.",
	"decision_izmir_risk_planning_full":
	"Deprem hazırlığını, altyapı dayanıklılığını ve kurtarma verimini artırır.",
	"decision_izmir_risk_planning_focused":
	"Merkezin deprem hazırlığını ve altyapı dayanıklılığını artırır.",
	"decision_bozkurt_flood_full": "Merkezin sel hazırlığını ve altyapı dayanıklılığını artırır.",
	"decision_bozkurt_flood_focused":
	"Merkezin sel hazırlığını ve altyapı dayanıklılığını artırır.",
	"decision_urban_transformation_full":
	"Deprem hazırlığını, altyapı dayanıklılığını ve onarım verimini artırır.",
	"decision_urban_transformation_focused":
	"Ülke genelinde deprem hazırlığını ve altyapı dayanıklılığını artırır.",
	"decision_yesilyurt_training_full":
	"Merkezin tahliye hazırlığını ve kurtarma verimini artırır.",
	"decision_yesilyurt_training_focused": "Merkezin güvenli tahliye hazırlığını artırır.",
	"decision_sanliurfa_flood_full": "Merkezin sel hazırlığını ve altyapı dayanıklılığını artırır.",
	"decision_sanliurfa_flood_focused":
	"Merkezin sel hazırlığını ve altyapı dayanıklılığını artırır.",
	"decision_silivri_awareness_full": "Merkezin tahliye hazırlığını ve kurtarma verimini artırır.",
	"decision_silivri_awareness_focused": "Merkezin güvenli tahliye hazırlığını artırır.",
	"decision_uzengili_relocation_full":
	"Merkezin çığ hazırlığını ve altyapı dayanıklılığını artırır.",
	"decision_uzengili_relocation_focused":
	"Merkezin çığ hazırlığını ve altyapı dayanıklılığını artırır.",
	"decision_tasagil_firebreaks_full":
	"Merkezin yangın hazırlığını ve altyapı dayanıklılığını artırır.",
	"decision_tasagil_firebreaks_focused":
	"Merkezin yangın hazırlığını ve altyapı dayanıklılığını artırır.",
	"decision_hatay_fire_response_full":
	"Merkezin yangın hazırlığını ve kurtarma verimini artırır.",
	"decision_hatay_fire_response_focused":
	"Merkezin yangın hazırlığını ve kurtarma verimini artırır.",
	"research_materials":
	"Malzemelerin ısı ve yük davranışını inceleyerek altyapıyı dayanıklı kılar.",
	"research_slope_snow": "Eğim ve kar yükü bilgisi, heyelan ve çığ hazırlığını artırır.",
	"research_fire_models":
	"Yangının yayılma yollarını incelemek, koruyucu planlamayı güçlendirir.",
	"research_redundancy":
	"Tek noktaya bağımlılığı azaltan tasarımlar, altyapı dayanıklılığını artırır.",
	"research_multihazard":
	"Deprem, yangın ve seli birlikte ele alan tasarım, hazırlığı dengeli artırır.",
	"research_condition_monitoring":
	"İzleme verileri, altyapıdaki zayıflıkların tanınmasını ve hazırlığı destekler.",
	"research_radio":
	"Ortak telsiz usulleri, kurtarma ekiplerinin aynı bilgiyle çalışmasını sağlar.",
	"research_basin": "Yağışın akışa dönüşümünü modellemek, taşkına hazırlığı artırır.",
	"research_terrain": "Eğim ve akış haritaları, heyelan ve sel hazırlığını iyileştirir.",
	"research_data_standards":
	"Ortak veri dili, ekiplerin kurtarma ve malzeme planlarını uyumlu kılar.",
	"research_hazard_analysis":
	"Birleşik ölçüm ve saha verileri, sel, heyelan ve yangın hazırlığını artırır.",
	"research_warning_design":
	"Açık eylem bilgisi taşıyan uyarılar, güvenli tahliye hazırlığını artırır.",
	"research_equipment": "Uyumlu yükleme ve paketleme kuralları, malzeme taşıma verimini artırır.",
	"research_field_planning":
	"Görev ile kaynak ihtiyacını eşleştirmek, kurtarma çalışmalarını verimli kılar.",
	"research_repair_planning":
	"Malzeme ve iş sırasını birlikte planlamak, onarım maliyetini azaltır.",
	"research_supply": "İhtiyaca uygun yük bileşimi, taşınan yardımın verimini artırır.",
	"research_damage": "Ortak saha değerlendirmesi, kurtarma ve onarım önceliklerini netleştirir.",
	"research_scenarios":
	"Önceden çalışılan görev senaryoları, kurtarma ve yardım kullanımını iyileştirir.",
	"school_safety": "Okulda öğrenilen güvenli çıkış davranışları, tahliye hazırlığını artırır.",
	"accessible_preparedness":
	"Farklı ihtiyaçlara uygun hazırlık bilgisi, güvenli tahliyeyi destekler.",
	"information_verification":
	"Kaynağı doğrulama alışkanlığı, belirsizlikte güvenin aşınmasını yavaşlatır.",
	"inclusive_response":
	"Destek ihtiyacını gözeten mahalle planları, tahliye ve kurtarma uyumunu artırır.",
	"national_equipment": "Sabitlenen ekipman, deprem ve yangına karşı tesis hazırlığını artırır.",
	"national_depots":
	"Düzenli aktarma noktaları, yardım yüklerinin verimli kullanılmasını destekler.",
	"national_mountain": "Şev ve kar gözlemleri, heyelan ve çığ hazırlığını güçlendirir.",
	"national_equipment_standard":
	"Uyumlu saha ekipmanı, kurtarma ve yardım kullanımını verimli kılar.",
	"national_fire_watch":
	"Arazi ve yayılım bilgisine dayanan gözetleme, yangın hazırlığını artırır.",
	"national_repair_supply":
	"Uyumlu onarım malzemeleri, onarım ve malzeme taşıma maliyet verimini artırır.",
	"national_backup_power": "Yedek enerji düzeni, kritik altyapının dayanıklılığını artırır.",
	"national_sensor_stations":
	"Sürekli ve ortak biçimli ölçümler, dört afet türünde hazırlığı artırır.",
	"national_dispatch":
	"Ortak ihtiyaç ve yük planı, yardım taşıma ile kurtarmanın uyumunu artırır.",
	"national_preventive_maintenance":
	"İzleme bilgisine dayalı bakım, altyapıyı yangın ve sele karşı güçlendirir.",
	"national_multichannel_warning":
	"Tutarlı uyarıların farklı kanallardan paylaşılması, güvenli hazırlığı artırır.",
	"national_damage_assessment":
	"Ortak saha raporları, kurtarma ve onarım kaynaklarının uygun kullanımını destekler.",
}

const DESCRIPTIONS := {
	"center_renewal":
	"Bu merkezde ekip ve yerel yatırımların zamanla yıpranan kapasitesi yenilenir. Tamamlandığında merkez kondisyonu tam düzeye döner; afet nedeniyle oluşan altyapı hasarı için ayrı onarım gerekir.",
	"research_structural":
	"Yapıların yükü nasıl taşıdığını ve hangi birleşimlerde zayıfladığını araştırır. Bu bilgi, ülke genelinde deprem hazırlığına katkı sağlar ve daha ileri yapı çalışmalarının temelini oluşturur.",
	"research_materials":
	"Yapı malzemelerinin yüksek sıcaklık ve tekrarlanan yükler altındaki davranışını karşılaştırır. Uygun malzeme seçimi ülke genelinde yangın hazırlığını ve altyapı dayanıklılığını artırır.",
	"research_ground":
	"Zemin hareketlerinin temel ve taşıyıcı sistemlere nasıl aktarıldığını inceler. Elde edilen bilgi ülke genelinde deprem ve heyelan hazırlığını artırır; sismik izolasyon ve arazi haritalama çalışmalarına temel sağlar.",
	"research_slope_snow":
	"Şevlerdeki kayma koşullarını ve kar örtüsünün yük altında kararlılığını araştırır. Bu iki riskin birlikte değerlendirilmesi, ülke genelinde heyelan ve çığ hazırlığını artırır.",
	"research_automation":
	"Kritik altyapının çalışma durumunu denetleyen otomatik kontrol yöntemlerini geliştirir. Düzenli kontrol, ülke genelinde altyapı dayanıklılığına katkı sağlar ve otomatik gaz kesme yatırımını mümkün kılar.",
	"research_fire_models":
	"Yanıcı malzeme, rüzgâr ve arazi koşullarının yangının yayılmasına etkisini modeller. Olası yayılma yollarının bilinmesi, ülke genelinde yangın hazırlığını artırır ve gözetleme uygulamasını destekler.",
	"research_isolation":
	"Zemin ile yapı arasındaki hareket aktarımını azaltan izolasyon yöntemlerini araştırır. Uygun tasarım bilgisi, ülke genelinde deprem hazırlığını güçlendirir ve çoklu afet tasarımına temel olur.",
	"research_redundancy":
	"Kritik tesislerin tek enerji veya kontrol noktasına bağımlılığını azaltan tasarımları inceler. Yedeklilik bilgisi ülke genelinde altyapı dayanıklılığı sağlar ve tesislerde yedek enerji uygulamasını açar.",
	"research_multihazard":
	"Bir afet için alınan yapı kararının başka bir afet karşısında yaratabileceği zayıflıkları inceler. Deprem, yangın ve seli birlikte değerlendirmek, ülke genelindeki hazırlığı üç riskte de artırır.",
	"research_condition_monitoring":
	"Otomatik kontrol ile sensör ölçümlerini birleştirerek altyapının durumunu izleme yöntemleri geliştirir. Zayıf noktaların tanınması ülke genelinde altyapı dayanıklılığını ve deprem hazırlığını artırır; mevcut hasarı kendiliğinden onarmaz.",
	"research_meteorology":
	"Yağış, sıcaklık ve kar birikimini izleyerek tehlikeli hava koşullarını öngörme yöntemleri geliştirir. Tahmin bilgisi ülke genelinde sel ve çığ hazırlığını artırır, radar ve havza çalışmalarının temelini oluşturur.",
	"research_radio":
	"Afet sırasında ekipler arasında kısa, anlaşılır ve ortak telsiz mesajları kullanmanın yöntemlerini araştırır. Haberleşme düzeni mevcut kurtarma çalışmalarının ülke genelindeki verimini artırır ve ulusal telsiz uygulamasını açar.",
	"research_radar":
	"Radar yansımalarından yağışın konumunu ve şiddetini yorumlama yöntemlerini geliştirir. Yağış sistemlerini daha iyi tanımak, ülke genelinde sel hazırlığını artırır ve erken uyarı radarlarının kurulmasını destekler.",
	"research_basin":
	"Yağışın havza boyunca yüzey akışına ve taşkına nasıl dönüştüğünü modeller. Suyun birikebileceği alanları belirlemek ülke genelinde sel hazırlığını artırır ve radar verisinin uygulamada yorumlanmasını sağlar.",
	"research_satellite":
	"Yerel haberleşme hatlarından bağımsız uydu bağlantılarının afet koordinasyonunda kullanımını araştırır. Ortak bilgi akışı, ülke genelinde kurtarma verimini artırır ve uydu haberleşme ağının kurulmasına temel sağlar.",
	"research_terrain":
	"Zemin bilgisini sayısal yükseklik ve su akış haritalarıyla birleştirme yöntemlerini geliştirir. Tehlikeli eğim ve akış alanlarının tanınması ülke genelinde heyelan ve sel hazırlığını artırır.",
	"research_sensor":
	"Arazi ölçümlerini haberleşme üzerinden birlikte yorumlayan sensör ağı yöntemleri geliştirir. Bu bilgi ülke genelinde heyelan ve yangın hazırlığını artırır; sürekli ölçüm istasyonları için bilimsel temel sağlar.",
	"research_data_standards":
	"Konum, ihtiyaç ve saha raporlarının aynı biçimde paylaşılması için ortak veri standartları oluşturur. Bilginin birlikte okunabilmesi ülke genelinde kurtarma ve malzeme taşıma verimini artırır.",
	"research_hazard_analysis":
	"Sensör ölçümlerini, arazi bilgisini ve standart saha raporlarını birlikte değerlendirme yöntemleri geliştirir. Tek kaynağın kaçırabileceği işaretleri karşılaştırmak ülke genelinde sel, heyelan ve yangın hazırlığını artırır.",
	"research_warning_design":
	"Uyarı mesajlarında tehlikenin nerede olduğu ve hangi güvenli davranışın beklendiği üzerine çalışır. Radar ve ortak veri bilgisinin anlaşılır mesajlara dönüşmesi, ülke genelinde tahliye hazırlığını artırır.",
	"research_coordination":
	"Kurtarma sahasında görev, sorumluluk ve bilgi devri yöntemlerini araştırır. Aynı hedefe çalışan ekiplerin uyumu ülke genelinde kurtarma verimini artırır; yeni ekip kurmaz.",
	"research_depots":
	"Depolardaki malzemelerin kayıt, gruplama ve yüklemeye hazırlama yöntemlerini geliştirir. Düzenli stok planlaması ülke genelinde malzeme taşıma verimini artırır; sevkiyatın varış süresini değiştirmez.",
	"research_equipment":
	"Yardım malzemelerinin paketleme, işaretleme ve ekipmanla uyumlu yüklenme standartlarını araştırır. Aynı düzenin kullanılması ülke genelinde malzeme taşıma verimini artırır ve ortak saha uygulamasını destekler.",
	"research_field_planning":
	"Sahadaki görevleri mevcut ekip ve ekipman ihtiyacıyla eşleştirme yöntemlerini geliştirir. Kaynakların göreve uygun kullanılması ülke genelinde kurtarma verimini artırır; hazır ekip sayısını değiştirmez.",
	"research_capacity":
	"Koordinasyon ve kaynak planlama bilgisini kalıcı bir araştırma kurumu altında birleştirir. Kurum tamamlandığında teknik araştırma ve bilinç geliştirmelerinin paylaştığı kapasite ikiden üçe çıkar.",
	"research_repair_planning":
	"Hasarlı altyapının onarımında gerekli işlerin ve malzemelerin sırasını planlama yöntemlerini geliştirir. Ülke genelindeki onarım verimi, başlatılacak onarım projelerinin bedelini azaltır; mevcut hasarı otomatik gidermez.",
	"research_response":
	"Kurtarma, saha kaynakları ve onarım hazırlığı arasındaki görev devrini ortak yöntemlerle düzenler. Ülke genelinde kurtarma verimini ve yeni onarım projelerinin maliyet verimini artırır.",
	"research_supply":
	"Yardım yüklerindeki malzeme bileşiminin saha ihtiyaçlarıyla eşleştirilmesini araştırır. Yükün daha uygun hazırlanması ülke genelinde malzeme taşıma verimini artırır; yolculuk süresine etki etmez.",
	"research_damage":
	"Hasarın aynı ölçütlerle kaydedilmesi ve acil görevlerle ilişkilendirilmesi için yöntemler geliştirir. Net öncelikler ülke genelinde kurtarma verimini ve yeni onarımların maliyet verimini artırır.",
	"research_scenarios":
	"Farklı afet ve kaynak koşulları için kurtarma ve ikmal görevlerinin birlikte çalışıldığı senaryolar hazırlar. Ekiplerin ortak yönteme alışması ülke genelinde kurtarma ve malzeme taşıma verimini artırır.",
	"community_preparedness":
	"Afet çantasının amacı, mahalledeki güvenli davranışlar ve hazırlığın paylaşılması üzerine eğitim geliştirir. Tanıdık hazırlık adımları ülke genelinde tahliye hazırlığını artırır ve güvenin zamanla aşınmasını yavaşlatır.",
	"school_safety":
	"Öğrenci ve çalışanların afet sırasında güvenli davranışları ve çıkış düzenini öğrenmesine yönelik eğitim geliştirir. Ortak davranış bilgisi ülke genelinde tahliye hazırlığına katkı sağlar ve mahalle tatbikatlarını destekler.",
	"household_planning":
	"Ailelerin afet öncesinde buluşma noktası, iletişim ve güvenli çıkış adımlarını belirlemesini sağlayan rehberler geliştirir. Önceden paylaşılmış planlar ülke genelinde tahliye hazırlığını artırır.",
	"volunteer_network":
	"Gönüllü desteğinin görevli ekiplerle nasıl koordine edileceğini anlatan eğitimler geliştirir. Görev ve bilgi akışının netleşmesi ülke genelinde kurtarma verimini artırır; yeni kurtarma ekibi üretmez.",
	"evacuation_drills":
	"Okulda ve ailede öğrenilen güvenli davranışların mahalle ölçeğinde birlikte uygulanmasını sağlar. Tekrarlanan görev ve çıkış denemeleri ülke genelinde tahliye hazırlığını ve kurtarma verimini artırır.",
	"public_communication":
	"Kamu açıklamalarında doğrulanmış bilginin, belirsizliğin ve beklenen davranışın açıkça aktarılmasını öğretir. Tutarlı iletişim ülke genelinde güvenin aylık aşınmasını yavaşlatır; afet sonuçlarının güven etkisini kaldırmaz.",
	"community_coordination":
	"Mahallelerin yardım ihtiyaçlarını ortak kayıt ve güvenilir iletişimle paylaşmasını sağlayan dayanışma yöntemleri geliştirir. İhtiyacın anlaşılması ülke genelinde malzeme taşıma verimini artırır ve güven aşınmasını yavaşlatır.",
	"accessible_preparedness":
	"Hareket, görme, işitme veya dil desteği ihtiyacı olan kişilere uygun hazırlık rehberleri geliştirir. Güvenli adımların daha geniş kesimlerce anlaşılması ülke genelinde tahliye hazırlığını artırır.",
	"information_verification":
	"Afet bilgisinin kaynağını, tarihini ve doğrulanabilirliğini değerlendirmeyi öğreten eğitimler geliştirir. Doğru bilgiye erişim alışkanlığı ülke genelinde güvenin zamanla aşınmasını yavaşlatır.",
	"inclusive_response":
	"Dayanışma görevlerini, farklı destek ihtiyaçlarını ve güvenli çıkış planlarını birlikte ele alan eğitim geliştirir. Kimin hangi desteğe ihtiyaç duyduğunun önceden bilinmesi ülke genelinde kurtarma verimini ve tahliye hazırlığını artırır.",
	"national_equipment":
	"Kritik tesislerde devrilebilen ekipman ve bağlantılar uygun sabitleme düzeniyle güvenceye alınır. Yapı ve malzeme bilgisinin sahaya uygulanması ülke genelinde deprem ve yangın hazırlığını artırır.",
	"national_radio":
	"Kurtarma ve yardım birimleri için ortak telsiz altyapısı ve haberleşme usulleri kurulur. Birimler arası bilgi akışı ülke genelinde kurtarma ve malzeme taşıma verimini artırır; yeni ekip oluşturmaz.",
	"national_depots":
	"Yardım malzemelerinin kayıtlı biçimde birleştirildiği ve göreve hazırlandığı aktarma noktaları kurulur. Koordinasyon ve stok bilgisinin uygulanması ülke genelinde malzeme taşıma verimini artırır; varış süresini değiştirmez.",
	"national_mountain":
	"Dağlık alanlarda zemin, şev ve kar örtüsünün düzenli gözlenmesini sağlayan bir ağ kurulur. Gözlemlerin birlikte değerlendirilmesi ülke genelinde heyelan ve çığ hazırlığını artırır.",
	"early_warning":
	"Radar yağış ölçümleri havza ve taşkın bilgisiyle birlikte kullanılarak uyarı altyapısı kurulur. Tehlikeli yağışın anlamlandırılması ülke genelinde sel ve tahliye hazırlığını artırır.",
	"national_equipment_standard":
	"Saha birimlerinin birlikte kullanabileceği ekipman, paketleme ve görev düzeni uygulanır. Birimler arası uyum ülke genelinde kurtarma ve malzeme taşıma verimini artırır.",
	"national_fire_watch":
	"Yangın yayılım modelleri ve sayısal arazi bilgisiyle öncelikli gözetleme noktaları belirlenir. Düzenli gözlem ağı ülke genelinde yangın hazırlığını güçlendirir.",
	"satellite_network":
	"Afet birimlerinin saha ve ihtiyaç bilgilerini paylaşabileceği uydu haberleşme ağı kurulur. Yerel hatlara alternatif bilgi akışı ülke genelinde kurtarma ve malzeme taşıma verimini artırır.",
	"national_repair_supply":
	"Onarım işlerinde kullanılan malzemelerin tedariki ve yük hazırlığı ortak bir düzene alınır. Uyumlu tedarik ülke genelinde malzeme taşıma verimini ve yeni onarımların maliyet verimini artırır; mevcut hasarı kendiliğinden gidermez.",
	"national_backup_power":
	"Kritik tesislere ana enerji kaynağından bağımsız yedek enerji düzeni kurulur. Yedeklilik yönteminin uygulanması ülke genelinde altyapı dayanıklılığını artırır.",
	"national_sensor_stations":
	"Sensör ölçümlerinin ortak veri biçimiyle toplandığı sürekli tehlike ölçüm istasyonları kurulur. Düzenli ölçüm bilgisi ülke genelinde heyelan, sel, yangın ve çığ hazırlığını artırır.",
	"national_dispatch":
	"Kurtarma görevleri ve yardım yüklerinin aynı ihtiyaç bilgisiyle planlandığı ortak ağ kurulur. Ülke genelinde malzeme taşıma ve kurtarma verimi artar; sevkiyatların yolculuk süresi değişmez.",
	"national_preventive_maintenance":
	"Kritik hatlarda durum izleme ve çoklu afet bilgisine dayalı koruyucu bakım düzeni kurulur. Ülke genelinde altyapı dayanıklılığı ile yangın ve sel hazırlığı artar; daha önce oluşmuş hasar için ayrı onarım gerekir.",
	"national_multichannel_warning":
	"Birleştirilmiş tehlike bilgisiyle hazırlanan anlaşılır uyarılar farklı haberleşme kanallarından paylaşılır. Aynı eylem bilgisinin yayılması ülke genelinde tahliye, sel ve yangın hazırlığını artırır.",
	"national_damage_assessment":
	"Hasar değerlendirme yöntemleri ve müdahale senaryolarını kullanan ortak saha raporlama ağı kurulur. Net görev öncelikleri ülke genelinde kurtarma verimini ve yeni onarımların maliyet verimini artırır.",
}


static func explanation_for(id: String) -> String:
	return EXPLANATIONS.get(id, "")


static func description_for(id: String) -> String:
	return DESCRIPTIONS.get(id, explanation_for(id))


static func status_for(status: String) -> String:
	return (
		{
			"active": "DEVAM EDİYOR",
			"waiting": "BÜTÇE BEKLİYOR",
			"paused": "DURAKLATILDI",
			"queued": "SIRADA / HENÜZ ÖDEME YOK",
		}
		. get(status, status)
	)
