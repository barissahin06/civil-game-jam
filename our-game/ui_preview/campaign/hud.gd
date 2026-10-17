extends Control
signal screen_requested(screen: String)
const UI := preload("res://ui_preview/shared/ui_kit.gd")
const VIOLET := Color("b38aed")
var _shell: Control
var _date_label: Label
var _date_state: Label
var _budget: Label
var _income: Label
var _trust: Label
var _trust_limits: Label
var _trust_delta: Label
var _awareness: Label
var _total_teams: Label
var _total_stock: Label
var _speed_state: Label
var _pause_button: Button
var _research_button: Button
var _crisis_button: Button
var _speed_buttons: Array[Button] = []


func setup(shell: Control) -> void:
	_shell = shell


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.panel(self, Rect2(12, 12, 1896, 100))
	var icons: Array[TextureRect] = [
		UI.icon(self, 0, Vector2(32, 32), UI.GOLD),
		UI.icon(self, 1, Vector2(376, 32), UI.TEAL),
		UI.icon(self, 2, Vector2(666, 32), VIOLET),
	]
	for index in range(icons.size()):
		icons[index].name = ["BudgetIcon", "TrustIcon", "AwarenessIcon"][index]
		icons[index].scale = Vector2(2, 2)
	UI.text(self, "BÜTÇE", Rect2(112, 18, 248, 22), 18, UI.MUTED)
	_budget = UI.text(self, "", Rect2(112, 40, 248, 44), 36, UI.GOLD)
	_income = UI.text(self, "", Rect2(112, 84, 248, 22), 18, UI.TEAL)
	_income.tooltip_text = "Son ay: gelir eksi bakım; proje taksitleri hariç"
	_income.mouse_filter = Control.MOUSE_FILTER_PASS
	_trust_limits = UI.text(self, "", Rect2(456, 18, 192, 22), 18, UI.MUTED)
	_trust = UI.text(self, "", Rect2(456, 40, 192, 44), 36)
	_trust.mouse_filter = Control.MOUSE_FILTER_PASS
	_trust_delta = UI.text(self, "", Rect2(456, 84, 192, 22), 18, UI.MUTED)
	_trust_delta.mouse_filter = Control.MOUSE_FILTER_PASS
	UI.text(self, "BİLİNÇ", Rect2(744, 18, 120, 22), 18, VIOLET)
	_awareness = UI.text(self, "", Rect2(744, 40, 120, 44), 36, VIOLET)
	_awareness.mouse_filter = Control.MOUSE_FILTER_PASS
	UI.text(self, "PUAN", Rect2(744, 84, 120, 22), 18, VIOLET)
	UI.text(self, "BİRLİK", Rect2(900, 18, 156, 22), 18, UI.TEAL)
	_total_teams = UI.text(self, "", Rect2(900, 40, 156, 44), 36, UI.TEAL)
	_total_teams.mouse_filter = Control.MOUSE_FILTER_PASS
	_total_teams.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	UI.text(self, "TOPLAM EKİP", Rect2(900, 84, 156, 22), 18, UI.MUTED)
	UI.text(self, "YARDIM", Rect2(1092, 18, 164, 22), 18, UI.GOLD)
	_total_stock = UI.text(self, "", Rect2(1092, 40, 164, 44), 36, UI.GOLD)
	_total_stock.mouse_filter = Control.MOUSE_FILTER_PASS
	_total_stock.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	UI.text(self, "TOPLAM STOK", Rect2(1092, 84, 164, 22), 18, UI.MUTED)
	UI.text(self, "TAKVİM", Rect2(1292, 18, 304, 22), 18, UI.GOLD)
	_date_label = UI.text(self, "", Rect2(1292, 40, 304, 44), 36)
	_date_label.mouse_filter = Control.MOUSE_FILTER_PASS
	_date_state = UI.text(self, "", Rect2(1292, 84, 304, 22), 18, UI.GOLD)
	UI.text(self, "ZAMAN", Rect2(1612, 18, 272, 22), 18, UI.MUTED)
	_pause_button = UI.button(self, "DEVAM", Rect2(1612, 40, 108, 38), _toggle_time)
	for index in range(3):
		_speed_buttons.append(
			UI.button(
				self,
				["1×", "2×", "4×"][index],
				Rect2(1724 + index * 56, 40, 48, 38),
				_set_speed.bind([1, 2, 4][index])
			)
		)
		_speed_buttons[index].toggle_mode = true
		_speed_buttons[index].add_theme_stylebox_override(
			"hover_pressed", UI.style(Rect2(112, 56, 48, 32))
		)
	_speed_state = UI.text(self, "", Rect2(1612, 84, 272, 22), 18, UI.GOLD)
	UI.button(self, "MENÜ", Rect2(1752, 116, 144, 42), screen_requested.emit.bind("pause"))
	UI.button(self, "BİRLİKLER", Rect2(32, 116, 180, 42), screen_requested.emit.bind("units"))
	_crisis_button = UI.button(
		self, "", Rect2(224, 116, 218, 42), screen_requested.emit.bind("crisis")
	)
	UI.button(
		self, "HAZIRLIK PLANLA", Rect2(454, 116, 198, 42), screen_requested.emit.bind("preparation")
	)
	UI.button(self, "PROJELER", Rect2(676, 116, 140, 42), screen_requested.emit.bind("projects"))
	UI.button(self, "ULUSAL PLAN", Rect2(828, 116, 180, 42), screen_requested.emit.bind("national"))
	_research_button = UI.button(
		self, "", Rect2(1020, 116, 236, 42), screen_requested.emit.bind("research")
	)
	UI.button(self, "GAZETE", Rect2(1280, 116, 140, 42), screen_requested.emit.bind("newspaper"))
	UI.button(self, "RAPOR", Rect2(1432, 116, 130, 42), screen_requested.emit.bind("report"))
	refresh()


func refresh() -> void:
	var sim: Simulation = _shell.sim
	_budget.text = _shell.fmt_money(sim.treasury.money)
	_income.text = (
		("+" if sim.treasury.last_net >= 0 else "")
		+ _shell.fmt_money(sim.treasury.last_net)
		+ "/AY"
	)
	var trust := sim.trust.feedback()
	_trust_limits.text = "GÜVEN %d-%d" % [trust.minimum, trust.maximum]
	_trust.text = ("%.2f" % trust.value).replace(".", ",")
	_trust_delta.text = (
		("SON %+.3f" % trust.latest_amount).replace(".", ",") if trust.has_change else "DEĞİŞİM YOK"
	)
	_trust_delta.add_theme_color_override(
		"font_color", UI.TEAL if trust.latest_amount > 0.0 else UI.GOLD
	)
	_trust.tooltip_text = (
		"Ulusal güven: %d-%d. %d'a düştüğünde kampanya sona erer.\nSon değişim: %s\n%s"
		% [trust.minimum, trust.maximum, trust.minimum, _trust_delta.text, trust.latest_reason]
	)
	_trust_delta.tooltip_text = _trust.tooltip_text
	_awareness.text = str(sim.treasury.awareness_points)
	_awareness.tooltip_text = (
		"Bilinç geliştirmeleri tamamlandı. Yeni baloncuk üretimi durdu."
		if sim.projects.awareness_complete()
		else "Ulusal bilinç geliştirmelerinde harcanır."
	)
	var resources: Dictionary = sim.unit_overview().summary
	_total_teams.text = _shell.fmt_count(resources.total)
	_total_teams.tooltip_text = (
		"Toplam %d ekip: %d hazır, %d yolda, %d görevde, %d dönüşte."
		% [
			resources.total,
			resources.ready,
			resources.outbound,
			resources.deployed,
			resources.returning
		]
	)
	_total_stock.text = _shell.fmt_count(resources.stock)
	_total_stock.tooltip_text = (
		"Tüm merkezlerde sevke hazır toplam yardım malzemesi: %s." % _total_stock.text
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
		"%02d %s %d" % [sim.clock.day_of_month, months[sim.clock.month].left(3), sim.clock.year]
	)
	_date_label.tooltip_text = (
		"%02d %s %d" % [sim.clock.day_of_month, months[sim.clock.month], sim.clock.year]
	)
	_date_state.text = "MÜDAHALE / GÜNLÜK" if not sim.crises.active.is_empty() else "NORMAL / AYLIK"
	_pause_button.text = "DEVAM" if sim.paused else "DURAKLAT"
	_speed_state.text = (("DURDU / %d× SEÇİLİ" if sim.paused else "AKTİF HIZ: %d×") % sim.speed)
	_research_button.text = (
		"ARAŞTIRMA %d/%d" % [sim.projects.active_count("research"), sim.projects.research_capacity]
	)
	_crisis_button.text = "KRİZ MERKEZİ %d" % sim.crises.active.size()
	for index in range(3):
		var selected: bool = sim.speed == [1, 2, 4][index]
		_speed_buttons[index].set_pressed_no_signal(selected)
		_speed_buttons[index].add_theme_color_override(
			"font_color", UI.GOLD if selected else UI.MUTED
		)
		_speed_buttons[index].add_theme_stylebox_override(
			"normal", UI.style(Rect2(112 if selected else 0, 56, 48, 32))
		)


func _toggle_time() -> void:
	_shell.sim.set_paused(not _shell.sim.paused)


func _set_speed(speed: int) -> void:
	_shell.sim.set_speed(speed)
