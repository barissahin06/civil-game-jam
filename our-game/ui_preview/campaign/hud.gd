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
	_income.tooltip_text = "Son ay: gelir eksi bakım; proje taksitleri hariç"
	UI.icon(self, 1, Vector2(848, 32), UI.TEAL)
	UI.text(self, "GÜVEN", Rect2(890, 24, 120, 24), 18, UI.MUTED)
	_trust = UI.text(self, "", Rect2(890, 48, 100, 40), 36)
	_trust.mouse_filter = Control.MOUSE_FILTER_PASS
	UI.icon(self, 2, Vector2(1036, 32), UI.GOLD)
	UI.text(self, "BİLİNÇ", Rect2(1078, 24, 110, 24), 18, UI.MUTED)
	_awareness = UI.text(self, "", Rect2(1078, 48, 100, 40), 36)
	_awareness.mouse_filter = Control.MOUSE_FILTER_PASS
	_date_label = UI.text(self, "", Rect2(1234, 26, 220, 26))
	_date_state = UI.text(self, "", Rect2(1234, 62, 220, 24), 18, UI.GOLD)
	_pause_button = UI.button(self, "DEVAM", Rect2(1470, 34, 142, 42), _toggle_time)
	for index in range(3):
		_speed_buttons.append(
			UI.button(
				self,
				["1×", "2×", "4×"][index],
				Rect2(1624 + index * 68, 34, 60, 42),
				_set_speed.bind([1, 2, 4][index])
			)
		)
	UI.button(self, "MENÜ", Rect2(1834, 34, 62, 42), screen_requested.emit.bind("pause"))
	UI.button(self, "PROJELER", Rect2(32, 116, 350, 42), screen_requested.emit.bind("projects"))
	UI.button(self, "ULUSAL PLAN", Rect2(432, 116, 206, 42), screen_requested.emit.bind("national"))
	_research_button = UI.button(
		self, "", Rect2(650, 116, 236, 42), screen_requested.emit.bind("research")
	)
	_crisis_button = UI.button(
		self, "", Rect2(898, 116, 218, 42), screen_requested.emit.bind("crisis")
	)
	UI.button(self, "GAZETE", Rect2(1128, 116, 140, 42), screen_requested.emit.bind("newspaper"))
	UI.button(self, "RAPOR", Rect2(1280, 116, 130, 42), screen_requested.emit.bind("report"))
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
	_trust.tooltip_text = "Ulusal güven / son değişimler\n" + "\n".join(changes)
	_awareness.text = str(sim.treasury.awareness_points)
	_awareness.tooltip_text = (
		"Bilinç geliştirmeleri tamamlandı. Yeni baloncuk üretimi durdu."
		if sim.projects.awareness_complete()
		else "Ulusal bilinç geliştirmelerinde harcanır."
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


func _toggle_time() -> void:
	_shell.sim.set_paused(not _shell.sim.paused)


func _set_speed(speed: int) -> void:
	_shell.sim.set_speed(speed)
