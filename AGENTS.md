# Civil Game Jam çalışma kuralları

- Oyun kökü `our-game/`; Godot 4.6.3 kullanılır. Başlamadan `git status --short` ve aktif branch'i kontrol et; bağımsız değişiklikleri koru.
- Önce [mimari](docs/architecture.md), [kod/veri standardı](docs/code-style.md) ve [geliştirme komutlarını](docs/development.md) oku. Paket sürümleri için [bağımlılık rehberini](docs/dependencies.md) kullan.
- Başka projelerin çözünürlük, görsel stil, animasyon yöntemi veya gameplay kararlarını bu projeye taşıma. Araç kurulumu bu kararlar için yetki değildir; bu projenin belirtilmiş kararlarını esas al.
- Yeni oyun kodunu mevcut özelliğin altına koy. Kuralların tek domain/model sahibini kullan; UI'da formül kopyalama. Sınır veya veri formatı değişince ilgili belgeyi de güncelle.
- Değişen GDScript'i gdformat, JSON/Markdown/YAML'ı Prettier ile kontrol et. Küçük değişiklikte bütün repoyu formatlama. Yeni kodda tip belirt; dinamik veri sınırlarını doğrula.
- Gameplay JSON'u değişince `schemas/` altındaki karşılığını güncelle ve `npm run check:data` çalıştır. Şema doğrulaması oyun dengesi veya kayıt uyumluluğu kanıtı değildir.
- Saf oyun mantığı için `npm run test:unit`; açılış ve entegrasyon için `npm run verify` kullan. UI/input/animasyon kabulünde gerçek viewport ile görüntülü doğrulama gerekir.
- Logdaki `ERROR:` / `CHECK FAILED`, eksik tamamlanma işareti veya zaman aşımı başarısızlıktır; sıfır çıkış kodu tek başına başarı değildir. Çalıştırmadığın kontrolü geçmiş gibi raporlama.
- `.gd.uid` ve import metadata'yı ilgili kaynakla koru. `generated/`, `.godot/`, `.venv/`, `node_modules/` ve indirilen GdUnit4 kaynaklarını commit etme. Oyuncu kayıtlarına veya kimlik bilgilerine dokunma.
- Art üretiminde [art/production/AGENTS.md](art/production/AGENTS.md) geçerlidir. Native kaynakları düzenle; derived çıktıları pipeline ile yeniden üret.
- MCP paketlerini doğrudan düzenlemek yerine upstream toolkit'te geliştir ve `toolkit.py update` ile al. `tools/mcp/mcp-update.json` sürüm ve hash kaydıdır.

## Codebase Memory

Yapısal kod keşfinde MCP graph araçlarını dosya aramasından önce kullan:
`search_graph` → ilgili yönde `trace_path` → `get_code_snippet`.
Başlangıçta `list_projects` / `index_status` ile doğru proje ve generation'ı doğrula.
Varsayılan Tier 2 doğrulamadır; Scout yalnız geçici pozitif bulgular, Auditor sınırlı kapsamda tam inceleme içindir.
İlgili sayfaları tamamla ve kullanılan her yol için `check_index_coverage` çağır.
Negatif veya kapsamlı iddialarda scope'u da kontrol et. Eksik, eski veya bilinmeyen kapsamda
bildirilen kaynak aralıklarını doğrudan oku/ara; temiz kapsam tek başına tamlık kanıtı değildir.
Metin sabitleri, hata mesajları, yapılandırma, kod dışı dosyalar ve yetersiz graph sonuçları için `rg` kullan.
Yeni depo indeksli değilse `index_repository` ile bu deponun kökünü indeksle.
Alt görev veriliyorsa proje, tier, generation, yollar, kapsam boşlukları ve açık soruları aktar;
alt ajanın MCP erişimi olduğunu varsayma.
