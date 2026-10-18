extends Control
## A presentation of campaign progress; every exercise uses the normal game commands.
const UI := preload("res://ui_preview/shared/ui_kit.gd")
const CARD_SIZE := Vector2(624, 330)
const COPY := {
	"finish":
	[
		"OYUNU BİTİR VE HİKÂYENİ OKU",
		"ESC > Oyunu Bitir onay ister; otomatik ve üç manuel kayıt kalıcı silinir. Gazete afetleri, önlemleri, kurtarılanları, önlenen kayıp/hasar tahminlerini ve yarım işleri özetler. Bu ders için bitirmen gerekmez."
	],
	"intro":
	[
		"ULUSAL AFET KOORDİNATÖRÜ",
		"Hazırlan, müdahale et, sonuçlardan öğren. Bütçe ortak hazinendir; gelirden bakım ve proje taksitleri ödenir. Güven sıfıra inerse oyun biter. Bilinç puanı ayrı harcanır. Büyük ekip sayısı hazır, altındaki sayı toplam ekiptir."
	],
	"city":
	[
		"BİR YÖNETİM MERKEZİ SEÇ",
		"Haritadaki seçilebilir illerden birine tıkla. Şehir paneli merkeze bağlı çevre illeri de kapsar. Gelir, altyapı dayanıklılığı ve beş afet türündeki hazırlığı incele."
	],
	"zoom":
	[
		"HARİTAYI YAKINDAN TANI",
		"Fare tekerleğiyle veya alttaki + düğmesiyle yakınlaş. Basılı tutup sürükleyerek haritayı taşıyabilirsin. Görünümü Sıfırla bütün ülkeyi yeniden gösterir."
	],
	"overlay":
	[
		"HAZIRLIĞI HARİTADAN OKU",
		"Harita Görünümü'nü açıp başka bir görünüm seç. Bölgeler coğrafyayı; diğer görünümler hazırlık, yardım stoğu veya altyapı hasarını gösterir. İl üzerine gelerek gerçek değeri oku."
	],
	"investment":
	[
		"İLK KORUYUCU YATIRIMIN",
		"Şehrin Yatırım sekmesinden bir koruyucu proje başlat. Aylık taksitini, süresini ve tamamlanınca etkisini karşılaştır. Her merkezde bir yerel slot vardır; tamamlanmamış önlem henüz koruma sağlamaz."
	],
	"research":
	[
		"BİR TEKNİK ARAŞTIRMA BAŞLAT",
		"Yatırım ve Araştırma > Araştırmalar'ı aç. Dönem ve önkoşulları uygun bir teknik araştırma seç. Teknik araştırmalar ve bilinç geliştirmeleri ortak araştırma slotlarını kullanır."
	],
	"teams":
	[
		"YENİ BİR EKİP HAZIRLA",
		"Ekip ve Yardım Hazırla'dan Ekip Kur'u seç, sonra bir merkeze tıkla. İş, yerel slot doluysa sıraya girer. Ekip kurmanın taksiti ve tamamlandıktan sonra bakım gideri vardır."
	],
	"stock":
	[
		"YARDIM MALZEMESİ HAZIRLA",
		"Aynı panelde Yardım Hazırla'yı seçip bir merkeze tıkla. Farklı merkezler ortak hazineden paralel çalışabilir. Bekleyen emir henüz ödeme yapmaz; başlayan iş aylık taksitle ilerler."
	],
	"time":
	[
		"ZAMANI SEN YÖNET",
		"Zamanı Başlat'a bas. Sakin dönemde aylar, müdahalede günler ilerler. Okurken duraklatabilirsin. Rehber yeni ders açınca durur; tekrar başlatma kararı sana aittir."
	],
	"speed":
	[
		"OYUN HIZINI DENE",
		"Üstteki 1×, 2× veya 4× düğmelerinden birini seç. Hız takvimin akışını değiştirir; duraklatmayı kaldırmaz. Rehber seçtiğin hızı değiştirmez."
	],
	"projects":
	[
		"ÖDEMELERİ VE İLERLEMEYİ İZLE",
		"Yatırım ve Araştırma > Projeler'i aç. İlerleme, bakım ve taksitleri incele. Bütçe yetmezse işler bekler; proje başlatabilmek bütün taksitlerin karşılanacağı anlamına gelmez."
	],
	"completion":
	[
		"İLK PROJEN TAMAMLANDI",
		"Başlattığın bir proje tamamlandı. Projeler'den durumunu, ilgili merkezin hazırlık veya kaynak değişimini incele. Koruyucu yatırımların yararı gerçek afetin sonuçlarında görülecek."
	],
	"bubble":
	[
		"BİLİNÇ PUANI TOPLA",
		"Haritadaki +5 Bilinç Puanı baloncuğuna tıkla. Sakin dönemde oluşurlar; en fazla üçü bekler ve kaybolmazlar. Krizde veya duraklatılmışken yeni baloncuk oluşmaz."
	],
	"awareness":
	[
		"BİLİNCİ HAZIRLIĞA DÖNÜŞTÜR",
		"Araştırmalar'ın Bilinç kategorisinden uygun bir geliştirme başlat. Bilinç puanı peşin harcanır; bu geliştirmeler de teknik araştırmalarla ortak kapasiteyi kullanır."
	],
	"newspaper":
	[
		"İLK AFET HABERİ",
		"Afetin gerçek yerini ve tarihini oku. Takvim otomatik durdu. Haberi Okudum ile müdahaleye geç; önceki alıştırmana krizden sonra döneceğiz."
	],
	"dispatch_teams":
	[
		"ARAMA KURTARMA EKİBİ GÖNDER",
		"Ekip seç; kaynak, hedef ve varış gününü incele. İhtiyaca Göre Ayarla miktarı hazırlar, Gönderimi Onayla gerçek sevki yapar. Haritaya sürüklemek ve hızlı sevk de aynı işlemdir."
	],
	"dispatch_stock":
	[
		"YARDIM MALZEMESİ GÖNDER",
		"Malzeme seçip ihtiyacı, bedeli ve varışı kontrol et. Yoldaki kaynak henüz sahada değildir. Ekipler görevden sonra döner; yardım malzemesi sahada tüketilir. Günlük ikmali takip et."
	],
	"report":
	[
		"MÜDAHALENİN SONUCUNU OKU",
		"Hazırlık, müdahale ve toparlanma ayrı değerlendirilir. Kurtarılanlar etkilenenlerin bir alt kümesidir; sayıları toplama. Karşılaştırmalar simülasyon tahminidir. Raporu okuyup devam et."
	],
	"repair":
	[
		"HASARLI MERKEZİ TOPARLA",
		"Hasarlı merkezde onarımı inceleyip başlat. Hasar geliri azaltır ve zamanla güven kaybettirir. Onarım yerel slotu kullanır, taksitler ödendikçe hasarı azaltır. Kondisyon yenilemesi ayrı bir iştir."
	],
	"national":
	[
		"ULUSAL ÖNLEMLER",
		"Bu önlemler bütün merkezleri etkiler ve ayrı ulusal uygulama slotunu kullanır. Dönem, araştırma koşulu ve aylık taksiti incele. Bu ders için bir önlem satın alman gerekmiyor."
	],
	"project_controls":
	[
		"PROJELERİNİ YÖNET",
		"Öncelik ödeme sırasını değiştirir. Duraklatma ilerlemeyi koruyup slotu açar; yeniden başlatırken kapasite kontrol edilir. İptalde ödenen taksitler dönmez. Denemek için proje iptal etmen gerekmiyor."
	],
	"supply":
	[
		"GÜNLÜK İKMALİ TAKİP ET",
		"Yardım her müdahale gününde tüketilir. Sahadaki stok, yoldaki destek ve ilk eksik gününü birlikte oku. İkmalin varışı geç kalıyorsa daha yakın kaynağı değerlendir; karşılanmış ihtiyaca boşuna sevk yapma."
	],
	"fund":
	[
		"ACİL BÜTÇE DESTEĞİ",
		"Acil fon müdahale verimini ve sonraki onarımı sınırlı destekler. Ekip ve malzemenin yerine geçmez. Bedel ortak hazineden çıkar; bu ders için para aktarman gerekmiyor."
	],
	"transfer":
	[
		"MERKEZLER ARASI TAŞIMA",
		"Kaynak ve hedef seçerek ekip veya yardım malzemesini afet başlamadan başka merkeze taşıyabilirsin. Bedel ve yolculuğu onaydan önce incele. Bu ders taşıma yapmanı gerektirmez."
	],
	"stationing":
	[
		"GEÇİCİ KONUŞLANDIRMA",
		"Başka merkezdeki ekip asıl üssüne bağlı kalır. Hazır, yolda, görevde ve dönüşte sayılarını ayır. Asıl Merkeze Çağır geri dönüşü başlatır; ders için ekip hareketi gerekmiyor."
	],
	"decision":
	[
		"AFET SONRASI KARAR",
		"Kararların maliyeti, koruması ve taahhütleri farklıdır. Kabul edilen program da slot ve taksit ister. Taahhüdün gerçek ilerlemesini izle. Anladım yalnız bu açıklamayı kapatır; senin yerine karar vermez."
	],
	"renewal":
	[
		"KONDİSYON VE YENİLEME",
		"Ekipler ve fiziksel tesisler yaşlanır; düşük kondisyon verimi azaltır. Merkez yenilemesi bakım ve afet hasarı onarımından ayrıdır. Bedeli ve yerel slotu incele; bu ders için başlatman gerekmez."
	],
}

var _shell: Control
var _card: Panel
var _title: Label
var _body: Label
var _suggestion: Label
var _next: Button
var _shown_step: String = ""
var _target: Rect2
var _bound_sim: Simulation
var _candidate: Dictionary = {}
var _cache_key: String = ""
var _schedule_dirty: bool = true
var _context_key: String = ""
var _step: String = ""


func setup(shell: Control) -> void:
	_shell = shell


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 20
	_card = UI.panel(self, Rect2(Vector2(432, 184), CARD_SIZE), true)
	_card.name = "GuideCard"
	_title = UI.text(_card, "", Rect2(16, 10, 592, 28), 18, UI.GOLD)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body = UI.text(_card, "", Rect2(16, 46, 592, 158))
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_suggestion = UI.text(_card, "", Rect2(16, 206, 592, 72), 18, UI.TEAL)
	_suggestion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_suggestion.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_next = UI.button(_card, "", Rect2(16, 286, 184, 32), _next_pressed)
	UI.button(_card, "BU ADIMI ATLA", Rect2(210, 286, 194, 32), _skip)
	UI.button(_card, "REHBERİ KAPAT", Rect2(414, 286, 194, 32), _close)
	hide()


func reset() -> void:
	if _bound_sim != null and _bound_sim.changed.is_connected(_invalidate):
		_bound_sim.changed.disconnect(_invalidate)
	_shown_step = ""
	_bound_sim = null
	_cache_key = ""
	_schedule_dirty = true
	_context_key = ""


func _invalidate() -> void:
	_schedule_dirty = true


func refresh() -> void:
	if not is_node_ready():
		return
	var sim: Simulation = _shell.sim
	if _bound_sim != sim:
		reset()
		_bound_sim = sim
		sim.changed.connect(_invalidate)
	if _shell.in_frontend:
		hide()
		return
	var context: Dictionary = _shell.projects.guide_context()
	var context_key := (
		"%s:%d:%s" % [_shell.open_screen, _shell.selected_area_id, context.definition_id]
	)
	if _schedule_dirty or context_key != _context_key:
		_schedule_dirty = false
		_context_key = context_key
		_cache_key = ""
		_step = sim.guide.select_step(
			sim, _shell.open_screen, _shell.selected_area_id, str(context.definition_id)
		)
	var step := _step
	visible = not step.is_empty()
	if not visible:
		return
	if step != _shown_step:
		_shown_step = step
		_cache_key = ""
		sim.set_paused(true)
	var key := (
		"%s:%s:%d:%d:%d:%d"
		% [
			step,
			_shell.open_screen,
			_shell.selected_area_id,
			sim.clock.day,
			sim.projects.projects.size(),
			sim.treasury.awareness_points
		]
	)
	if key != _cache_key:
		_cache_key = key
		_candidate = _recommend(step)
	var copy: Array = COPY[step]
	_title.text = "REHBER / " + str(copy[0])
	_body.text = str(copy[1])
	_suggestion.text = str(_candidate.get("message", "İstediğin zaman atlayabilirsin."))
	_next.text = "ANLADIM" if step in CampaignGuide.INFO_STEPS else "HEDEFİ GÖSTER"
	_target = _target_rect(step)
	_place_card()
	queue_redraw()


func _recommend(step: String) -> Dictionary:
	var sim: Simulation = _shell.sim
	if step == "finish":
		return {
			"message":
			"ANLADIM ile oynamaya devam et. Bitirişten sonra gazete üzerinden ana menüye dönersin."
		}
	if step in ["investment", "research", "awareness", "repair"]:
		var kinds: Array = {
			"investment": ["policy", "local"],
			"research": ["research"],
			"awareness": ["awareness"],
			"repair": ["repair"]
		}[step]
		var ids: Array = sim.areas.keys()
		if _shell.selected_area_id in ids:
			ids.erase(_shell.selected_area_id)
			ids.push_front(_shell.selected_area_id)
		var reason := "Uygun seçenek yok. Dönem, önkoşul ve boş slotu kontrol et; bekleyebilir veya adımı atlayabilirsin."
		var best: Dictionary = {}
		for area_id: int in ids:
			for definition: MeasureDefinition in sim.projects.definitions.values():
				if not definition.kind in kinds or definition.id.begins_with("decision_"):
					continue
				var owner := area_id if definition.is_local() else 0
				var available := sim.projects.availability(definition.id, owner, sim.clock.year)
				if not available.ok:
					reason = str(available.message)
					continue
				var monthly := sim.projects.monthly_cost_for(definition.id, owner)
				if best.is_empty() or monthly < int(best.monthly):
					best = {
						"id": definition.id,
						"area_id": owner,
						"monthly": monthly,
						"tab": definition.tab
					}
					best.message = (
						"Öneri: %s. %s"
						% [
							definition.title,
							(
								"%d bilinç puanı." % definition.cost_awareness
								if definition.kind == "awareness"
								else (
									"%s/ay taksit; sonraki ödemeler bütçene bağlı."
									% _shell.fmt_money(monthly)
								)
							)
						]
					)
			if not best.is_empty():
				return best
		return {"message": reason}
	if step in ["teams", "stock"]:
		var id := "rescue_team" if step == "teams" else "aid_stock"
		for action: Dictionary in sim.preparation_plan().actions:
			if action.id == id:
				return {
					"id": id,
					"message":
					(
						"%s/ay / %d ay. %s"
						% [
							_shell.fmt_money(action.monthly_cost),
							action.months,
							(
								"Merkezde proje varsa sıraya girer."
								if action.ok
								else str(action.message)
							)
						]
					)
				}
	if step in ["dispatch_teams", "dispatch_stock"]:
		var kind := "team" if step == "dispatch_teams" else "stock"
		var id: String = sim.guide.crisis_id
		var options := sim.dispatch_options(id, kind)
		for source: Dictionary in options:
			var amount := sim.missing_dispatch_amount(
				int(source.source), id, kind, int(source.home)
			)
			var quote := sim.dispatch_preview(
				int(source.source), id, kind, amount, int(source.home)
			)
			if amount > 0 and quote.ok and not quote.late:
				return {
					"message":
					(
						"Öneri: %s, %d birim / %s. Varış: %s."
						% [
							sim.areas[int(source.source)].name,
							amount,
							_shell.fmt_money(int(quote.fee)),
							CalendarClock.day_to_iso(int(quote.arrival))
						]
					)
				}
		return {
			"message":
			"Uygun kaynak yok. Kaynakları ve varış gününü kontrol et; bu adımı atlayabilirsin."
		}
	return {}


func _target_rect(step: String) -> Rect2:
	var id: String = (
		{
			"intro": "metrics",
			"zoom": "zoom",
			"overlay": "overlay",
			"time": "time",
			"speed": "speed",
			"newspaper": "newspaper",
			"report": "report",
			"transfer": "transfer",
			"stationing": "stationing"
		}
		. get(step, "")
	)
	if step == "city":
		return _shell.map_view.guide_area_rect(_shell.sim.areas.keys().front())
	if step == "bubble":
		id = "bubble"
	if step in ["investment", "research", "awareness", "repair"]:
		if _shell.open_screen == "project":
			var context: Dictionary = _shell.projects.guide_context()
			var definition: MeasureDefinition = _shell.sim.projects.definition_for(
				str(context.definition_id)
			)
			var kinds: Array = {
				"investment": ["policy", "local"],
				"research": ["research"],
				"awareness": ["awareness"],
				"repair": ["repair"]
			}[step]
			id = (
				"project_start"
				if definition != null and definition.kind in kinds
				else "development"
			)
		elif step in ["research", "awareness"]:
			if _shell.open_screen != "research":
				id = "research" if _tag_rect("research").has_area() else "development"
			else:
				id = "inspect_" + str(_candidate.get("id", ""))
				if not _tag_rect(id).has_area():
					id = "research_tab_%d" % int(_candidate.get("tab", 0))
		else:
			id = "inspect_" + str(_candidate.get("id", ""))
			if not _tag_rect(id).has_area():
				id = "city_tab_1"
			if not _tag_rect(id).has_area():
				return _shell.map_view.guide_area_rect(
					int(_candidate.get("area_id", _shell.sim.areas.keys().front()))
				)
	if step in ["teams", "stock"]:
		id = "preparation"
		if _shell.preparation_panel.visible:
			id = "prepare_" + step
			if _shell.preparation_panel.action_id == str(_candidate.get("id", "")):
				return _shell.map_view.guide_area_rect(_shell.sim.areas.keys().front())
	if step in ["projects", "completion", "project_controls"]:
		id = "projects" if _tag_rect("projects").has_area() else "development"
	if step in ["dispatch_teams", "dispatch_stock", "supply", "fund"]:
		id = "crisis"
		if _shell.open_screen == "crisis":
			id = "dispatch_teams" if step == "dispatch_teams" else "dispatch_stock"
			var kind := "team" if step == "dispatch_teams" else "stock"
			if _shell.crisis.dispatch_kind == kind:
				id = "dispatch_send"
	if step == "supply":
		id = "supply"
	if step in ["national", "decision", "renewal"]:
		id = "project_start" if step == "renewal" else step
	if step == "fund":
		id = "fund"
	var box := _tag_rect(id)
	if not box.has_area() and step in ["dispatch_teams", "dispatch_stock"]:
		box = _tag_rect("dispatch_source")
	if not box.has_area() and step == "overlay":
		box = _tag_rect("overlay_menu")
	return box


func _tag_rect(id: String) -> Rect2:
	if id.is_empty():
		return Rect2()
	var control := _find_target(_shell, id)
	if control == null:
		return Rect2()
	var box := control.get_global_rect()
	var parent := control.get_parent()
	while parent is Control:
		if parent.clip_contents:
			box = box.intersection(parent.get_global_rect())
		parent = parent.get_parent()
	return box.intersection(Rect2(0, 0, 1920, 1080))


func _find_target(node: Node, id: String) -> Control:
	if node == self or (node is CanvasItem and not node.is_visible_in_tree()):
		return null
	if node is BaseButton and node.disabled:
		return null
	if node is Control and str(node.get_meta("guide_target", "")) == id:
		return node
	for child: Node in node.get_children():
		var found := _find_target(child, id)
		if found != null:
			return found
	return null


func _place_card() -> void:
	if _shell.open_screen in ["newspaper", "decision"]:
		_layout_card(Vector2(224, 828))
		_card.position = Vector2(8, 180)
		return
	if not _shell.open_screen.is_empty() and not _shell.open_screen in ["crisis", "units"]:
		_layout_card(Vector2(400, 560))
		_card.position = Vector2(16, 184)
		return
	_layout_card(CARD_SIZE)
	var candidates: Array[Vector2] = [
		Vector2(432, 184), Vector2(656, 680), Vector2(16, 184), Vector2(1280, 680)
	]
	if not _shell.open_screen.is_empty() and not _shell.open_screen in ["crisis", "units"]:
		candidates = [Vector2(16, 180), Vector2(16, 680), Vector2(656, 184)]
	for point: Vector2 in candidates:
		var box := Rect2(point, CARD_SIZE)
		if box.intersects(_target.grow(12)):
			continue
		if _shell.city_panel.visible and box.intersects(Rect2(16, 174, 400, 846)):
			continue
		if _shell.preparation_panel.visible and box.intersects(Rect2(16, 174, 400, 846)):
			continue
		if _shell.open_screen in ["crisis", "units"] and box.intersects(Rect2(1284, 174, 620, 846)):
			continue
		_card.position = point
		return
	_card.position = Vector2(432, 184)


func _layout_card(dimensions: Vector2) -> void:
	_card.size = dimensions
	var narrow := dimensions.x < CARD_SIZE.x
	var title_height := 76.0 if dimensions.x < 300 else 52.0 if narrow else 28.0
	_title.size = Vector2(dimensions.x - 32, title_height)
	_body.position = Vector2(16, title_height + 28)
	var buttons: Array[Button] = [_next]
	for child: Node in _card.get_children():
		if child is Button and child != _next:
			buttons.append(child)
	var footer := 138.0 if narrow else 44.0
	var suggestion_height := 120.0 if narrow else 72.0
	_suggestion.position = Vector2(16, dimensions.y - footer - suggestion_height)
	_suggestion.size = Vector2(dimensions.x - 32, suggestion_height - 8)
	_body.size = Vector2(dimensions.x - 32, _suggestion.position.y - _body.position.y - 8)
	for index: int in range(buttons.size()):
		buttons[index].position = (
			Vector2(16, dimensions.y - footer + index * 42)
			if narrow
			else Vector2(16 + index * 198, dimensions.y - footer)
		)
		buttons[index].size = Vector2(dimensions.x - 32 if narrow else 194, 32)
	for child: Node in _card.get_children():
		if child is Control:
			child.set_meta("p0_text_size", child.size)


func _draw() -> void:
	if not visible or not _target.has_area():
		return
	draw_rect(_target.grow(5), UI.GOLD, false, 3.0)
	var origin := _card.get_rect().get_center()
	var target := _target.get_center()
	var direction := (target - origin).normalized()
	var half := _card.size / 2.0
	var distance := minf(
		half.x / maxf(absf(direction.x), 0.001), half.y / maxf(absf(direction.y), 0.001)
	)
	var edge := origin + direction * (distance + 4)
	if _card.get_rect().has_point(edge):
		return
	draw_line(edge, target, UI.GOLD, 3.0)
	var side := direction.orthogonal() * 7.0
	draw_colored_polygon(
		PackedVector2Array(
			[target, target - direction * 16.0 + side, target - direction * 16.0 - side]
		),
		UI.GOLD
	)


func _next_pressed() -> void:
	if _shown_step in CampaignGuide.INFO_STEPS:
		_shell.sim.guide.acknowledge()
	else:
		focus_target()
	_shell.sim.changed.emit()
	refresh()


func focus_target() -> void:
	if _shown_step in ["research", "awareness"] and _candidate.has("id"):
		_shell.research.open_research(str(_candidate.id))
	elif _shown_step in ["investment", "repair"] and _candidate.has("id"):
		_shell.show_project(str(_candidate.id), int(_candidate.area_id))
	elif _shown_step in ["teams", "stock"]:
		if not _shell.preparation_panel.visible:
			_shell.show_screen("preparation")
	elif _shown_step in ["projects", "completion"]:
		_shell.show_screen("projects")
	elif _shown_step in ["dispatch_teams", "dispatch_stock"]:
		_shell.crisis.select_crisis(_shell.sim.guide.crisis_id)
		_shell.show_screen("crisis")
	elif _shown_step == "overlay":
		_shell.map_view.show_guide_tools()
	elif _shown_step in ["city", "zoom", "bubble"]:
		_shell.close_screen()
		_shell.preparation_panel.close()
		_shell.map_view.reset_map()


func _skip() -> void:
	_shell.sim.guide.skip()
	_shell.sim.changed.emit()
	refresh()


func _close() -> void:
	_shell.sim.guide.close()
	_shell.sim.changed.emit()
	hide()
