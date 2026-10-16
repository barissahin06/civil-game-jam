# Varlık kaynakları ve araç güvenliği

- Bu dizinde kullanılan üretim araçlarının düzenlenebilir kaynak dosyalarını tut. Araç, dosya formatı, görsel stil ve animasyon tekniği bu projenin ihtiyaçlarına göre belirlenir.
- Var olan kaynağı değiştirmeden önce yedek/checkpoint al; ilgisiz katman, frame, cel ve animasyonları koru.
- Aseprite MCP kullanırken önce `inspect_workspace` ile doğru depoya bağlı olduğunu doğrula. Mevcut sprite düzenlemelerinde `checkpoint_sources` ve staged düzenleme araçlarını kullan.
- Bir üretim pipeline'ı varsa kaynak ile export çıktısını ayır; çıktıyı yeniden üretmek yerine kaynağı yanlışlıkla ezme.
- Değişiklikleri projenin kendi görüntü ayarlarında incele. Animasyon varsa normal hızda da kontrol et. Yapısal test başarısını görsel kabul sayma.
- Geçici rapor ve yakalamaları `generated/` altında tut. `.art-history` ve `.art-operation.lock` Git dışındadır; kilit silmeden önce kayıtlı PID'yi kontrol et.
