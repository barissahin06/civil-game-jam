extends Control
signal screen_requested(screen: String)
const UI := preload("res://ui_preview/shared/ui_kit.gd")
var _shell: Control
var _date_label: Label
var _date_state: Label
var _budget: Label
var _income: Label
var _trust: Label
var _awareness: Label
var _trust_hint: Control
var _awareness_hint: Control
var _pause_button: Button
var _research_button: Button
var _crisis_button: Button
var _speed_buttons: Array[Button] = []


func setup(shell: Control) -> void:
	_shell = shell


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.panel(self, Rect2(12, 12, 1896, 92))
	UI.icon(self, 11, Vector2(32, 40), UI.GOLD)
	UI.text(self, "REWRITE IT", Rect2(82, 44, 300, 28))
	UI.icon(self, 0, Vector2(406, 28), UI.GOLD)
	UI.text(self, "BÜTÇE", Rect2(450, 24, 190, 24), 18, UI.MUTED)
	_budget = UI.text(self, "", Rect2(450, 44, 196, 42), 36, UI.GOLD)
	_income = UI.text(self, "", Rect2(650, 58, 180, 26), 18, UI.TEAL)
	_income.tooltip_text = "Son ayın net sonucu: bölge gelirleri eksi bakım giderleri. Proje taksitleri bu rakama dahil değil."
	_income.mouse_filter = Control.MOUSE_FILTER_PASS
	_hint(
		Rect2(400, 20, 248, 72),
		"Hazinedeki para. Proje taksitleri, ekip ve sevkiyat bedelleri buradan ödenir. Para yetmezse projeler bekler."
	)
	UI.icon(self, 1, Vector2(848, 32), UI.TEAL)
	UI.text(self, "GÜVEN", Rect2(890, 24, 120, 24), 18, UI.MUTED)
	_trust = UI.text(self, "", Rect2(890, 48, 100, 40), 36)
	_trust_hint = _hint(Rect2(840, 20, 170, 72), "")
	UI.icon(self, 2, Vector2(1036, 32), UI.GOLD)
	UI.text(self, "BİLİNÇ", Rect2(1078, 24, 110, 24), 18, UI.MUTED)
	_awareness = UI.text(self, "", Rect2(1078, 48, 100, 40), 36)
	_awareness_hint = _hint(Rect2(1028, 20, 170, 72), "")
	_date_label = UI.text(self, "", Rect2(1234, 26, 220, 26))
	_date_state = UI.text(self, "", Rect2(1234, 62, 220, 24), 18, UI.GOLD)
	_hint(
		Rect2(1226, 20, 236, 72),
		"Oyun tarihi. Normal dönemde zaman ay ay, kriz sırasında gün gün ilerler. Haber veya rapor açıkken zaman durur."
	)
	_pause_button = UI.button(self, "DEVAM", Rect2(1470, 34, 142, 42), _toggle_time)
	_pause_button.tooltip_text = "Zamanı başlatır veya durdurur. Duraklatılmışken de proje başlatabilir, sevkiyat yapabilirsin."
	for index in range(3):
		_speed_buttons.append(
			UI.button(
				self,
				["1×", "2×", "4×"][index],
				Rect2(1624 + index * 68, 34, 60, 42),
				_set_speed.bind([1, 2, 4][index])
			)
		)
		_speed_buttons[index].tooltip_text = (
			"Oyun hızı: zaman %d kat hızlı akar." % [1, 2, 4][index]
		)
	UI.button(self, "MENÜ", Rect2(1834, 34, 62, 42), screen_requested.emit.bind("pause")).tooltip_text = ("Kaydet, yükle, ayarlar ve ana menü.")
	UI.button(self, "PROJELER", Rect2(32, 116, 350, 42), screen_requested.emit.bind("projects")).tooltip_text = ("Başlattığın bütün projeler: ilerleme, aylık taksit, öncelik, duraklatma ve iptal.")
	UI.button(self, "ULUSAL PLAN", Rect2(432, 116, 206, 42), screen_requested.emit.bind("national")).tooltip_text = ("Bütün ülkeyi kapsayan tedbirler. Tamamlanınca her bölgeye koruma sağlar. Aynı anda bir ulusal proje yürür.")
	_research_button = UI.button(
		self, "", Rect2(650, 116, 236, 42), screen_requested.emit.bind("research")
	)
	_research_button.tooltip_text = "Araştırma ağacı. Sayaç: yürüyen araştırma / araştırma kapasitesi. Araştırmalar korumayı artırır ve yeni tedbirlerin kilidini açar."
	_crisis_button = UI.button(
		self, "", Rect2(898, 116, 218, 42), screen_requested.emit.bind("crisis")
	)
	_crisis_button.tooltip_text = "Devam eden afetler ve sayısı. Buradan bölgelere ekip ve yardım stoğu sevk edilir."
	UI.button(self, "GAZETE", Rect2(1128, 116, 140, 42), screen_requested.emit.bind("newspaper")).tooltip_text = ("Son afet haberi ve tarihsel afet arşivi.")
	UI.button(self, "RAPOR", Rect2(1280, 116, 130, 42), screen_requested.emit.bind("report")).tooltip_text = ("Son krizin sonuç raporu: etkilenen kişi, hasar ve tedbirlerin önlediği kayıp.")
	refresh()


func refresh() -> void:
	var sim: Simulation = _shell.sim
	_budget.text = _shell.fmt_money(sim.treasury.money)
	_income.text = (
		("+" if sim.treasury.last_net >= 0 else "")
		+ _shell.fmt_money(sim.treasury.last_net)
		+ "/AY"
	)
	_trust.text = str(roundi(sim.trust.value))
	var changes: Array[String] = []
	for index: int in range(maxi(0, sim.trust.history.size() - 3), sim.trust.history.size()):
		var entry: Dictionary = sim.trust.history[index]
		changes.append("%+.2f / %s" % [entry.amount, entry.reason])
	_trust_hint.tooltip_text = "Halkın devlete güveni (0-100). Her ay biraz azalır, onarılmayan hasar daha da düşürür. Tamamlanan projeler ve başarılı müdahaleler artırır. Sıfıra düşerse oyun kaybedilir."
	if not changes.is_empty():
		_trust_hint.tooltip_text += "\n\nSon değişimler:\n" + "\n".join(changes)
	_awareness.text = str(sim.treasury.awareness_points)
	_awareness_hint.tooltip_text = (
		"Bilinç puanı. Bütün bilinç geliştirmeleri tamamlandığı için yeni +5 balonu çıkmaz."
		if sim.projects.awareness_complete()
		else "Bilinç puanı. Haritadaki +5 balonlarını toplayarak kazanılır, Araştırma ekranının Bilinç sekmesindeki geliştirmelerde harcanır."
	)
	var months := [
		"",
		"OCAK",
		"ŞUBAT",
		"MART",
		"NİSAN",
		"MAYIS",
		"HAZİRAN",
		"TEMMUZ",
		"AĞUSTOS",
		"EYLÜL",
		"EKİM",
		"KASIM",
		"ARALIK"
	]
	_date_label.text = (
		"%02d %s %d" % [sim.clock.day_of_month, months[sim.clock.month], sim.clock.year]
	)
	_date_state.text = (
		"DURAKLATILDI"
		if sim.paused
		else ("MÜDAHALE / GÜNLÜK" if not sim.crises.active.is_empty() else "NORMAL / AYLIK")
	)
	_pause_button.text = "DEVAM" if sim.paused else "DURAKLAT"
	_research_button.text = (
		"ARAŞTIRMA %d/%d" % [sim.projects.active_count("research"), sim.projects.research_capacity]
	)
	_crisis_button.text = "KRİZ MERKEZİ %d" % sim.crises.active.size()
	for index in range(3):
		_speed_buttons[index].add_theme_stylebox_override(
			"normal", UI.style(Rect2(112 if sim.speed == [1, 2, 4][index] else 0, 56, 48, 32))
		)
	UI.wrap_tooltips(self)


func _hint(box: Rect2, tip: String) -> Control:
	# Transparent hover area: labels ignore the mouse, so the whole box carries the tooltip.
	var area := Control.new()
	area.position = box.position
	area.size = box.size
	area.tooltip_text = tip
	add_child(area)
	return area


func _toggle_time() -> void:
	_shell.sim.set_paused(not _shell.sim.paused)


func _set_speed(speed: int) -> void:
	_shell.sim.set_speed(speed)
