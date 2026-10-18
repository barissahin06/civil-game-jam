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
var _team_total: Label
var _total_teams: Label
var _total_stock: Label
var _speed_state: Label
var _pause_button: Button
var _crisis_button: Button
var _speed_buttons: Array[Button] = []
var _events_button: Button
var _events_menu: Control


func setup(shell: Control) -> void:
	_shell = shell


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.panel(self, Rect2(12, 12, 1896, 112))
	var icons: Array[TextureRect] = [
		UI.icon(self, 0, Vector2(32, 16), UI.GOLD),
		UI.icon(self, 1, Vector2(376, 32), UI.TEAL),
		UI.icon(self, 2, Vector2(666, 32), VIOLET),
	]
	for index in range(icons.size()):
		icons[index].name = ["BudgetIcon", "TrustIcon", "AwarenessIcon"][index]
		icons[index].scale = Vector2(2, 2)
	UI.text(self, "BÜTÇE", Rect2(112, 18, 248, 22), 18, UI.MUTED)
	_budget = UI.text(self, "", Rect2(112, 38, 248, 42), 36, UI.GOLD)
	_income = UI.text(self, "", Rect2(32, 80, 328, 44), 18, UI.TEAL)
	_income.tooltip_text = "Son ay: gelir eksi bakım; proje taksitleri hariç"
	_income.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_income.mouse_filter = Control.MOUSE_FILTER_PASS
	_trust_limits = UI.text(self, "", Rect2(456, 18, 192, 22), 18, UI.MUTED)
	_trust = UI.text(self, "", Rect2(456, 38, 192, 42), 36)
	_trust.mouse_filter = Control.MOUSE_FILTER_PASS
	_trust_delta = UI.text(self, "", Rect2(456, 80, 192, 22), 18, UI.MUTED)
	_trust_delta.mouse_filter = Control.MOUSE_FILTER_PASS
	UI.text(self, "0: OYUN BİTER", Rect2(456, 102, 192, 22), 18, UI.MUTED)
	UI.text(self, "BİLİNÇ PUANI", Rect2(744, 18, 144, 22), 18, VIOLET)
	_awareness = UI.text(self, "", Rect2(744, 40, 120, 44), 36, VIOLET)
	_awareness.mouse_filter = Control.MOUSE_FILTER_PASS
	UI.text(self, "HARCANABİLİR", Rect2(744, 84, 144, 22), 18, VIOLET)
	UI.text(self, "HAZIR EKİP", Rect2(900, 18, 156, 22), 18, UI.TEAL)
	_total_teams = UI.text(self, "", Rect2(900, 38, 156, 42), 36, UI.TEAL)
	_total_teams.mouse_filter = Control.MOUSE_FILTER_PASS
	_total_teams.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_team_total = UI.text(self, "", Rect2(900, 80, 180, 44), 18, UI.MUTED)
	_team_total.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UI.text(self, "YARDIM MALZEMESİ", Rect2(1092, 18, 192, 22), 18, UI.GOLD)
	_total_stock = UI.text(self, "", Rect2(1092, 40, 164, 44), 36, UI.GOLD)
	_total_stock.mouse_filter = Control.MOUSE_FILTER_PASS
	_total_stock.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	UI.text(self, "GÖNDERİME HAZIR", Rect2(1092, 84, 192, 22), 18, UI.MUTED)
	UI.text(self, "TAKVİM", Rect2(1316, 18, 280, 22), 18, UI.GOLD)
	_date_label = UI.text(self, "", Rect2(1316, 40, 280, 44), 36)
	_date_label.mouse_filter = Control.MOUSE_FILTER_PASS
	_date_state = UI.text(self, "", Rect2(1316, 84, 280, 22), 18, UI.GOLD)
	_speed_state = UI.text(self, "", Rect2(1612, 18, 272, 22), 18, UI.GOLD)
	_pause_button = UI.button(self, "ZAMANI BAŞLAT", Rect2(1612, 40, 272, 38), _toggle_time)
	for index in range(3):
		_speed_buttons.append(
			UI.button(
				self,
				["1×", "2×", "4×"][index],
				Rect2(1612 + index * 92, 82, 88, 26),
				_set_speed.bind([1, 2, 4][index])
			)
		)
		_speed_buttons[index].toggle_mode = true
		_speed_buttons[index].add_theme_stylebox_override(
			"hover_pressed", UI.style(Rect2(112, 56, 48, 32))
		)
	UI.button(self, "MENÜ", Rect2(1752, 130, 144, 42), screen_requested.emit.bind("pause"))
	UI.button(
		self, "EKİPLER VE YARDIM", Rect2(32, 130, 230, 42), screen_requested.emit.bind("units")
	)
	_crisis_button = UI.button(
		self, "", Rect2(274, 130, 250, 42), screen_requested.emit.bind("crisis")
	)
	UI.button(
		self,
		"EKİP VE YARDIM HAZIRLA",
		Rect2(536, 130, 340, 42),
		screen_requested.emit.bind("preparation")
	)
	UI.button(
		self,
		"YATIRIM VE ARAŞTIRMA",
		Rect2(888, 130, 300, 42),
		screen_requested.emit.bind("development")
	)
	_events_button = UI.button(
		self, "HABERLER VE RAPORLAR", Rect2(1200, 130, 290, 42), _toggle_events_menu
	)
	_events_menu = Control.new()
	_events_menu.name = "EventsMenu"
	_events_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_events_menu.gui_input.connect(_events_input)
	_shell.add_child(_events_menu)
	var panel := UI.panel(_events_menu, Rect2(1200, 180, 300, 108), true)
	panel.name = "Choices"
	var newspaper := UI.button(
		panel, "SON HABER", Rect2(8, 8, 284, 42), _open_event.bind("newspaper")
	)
	var report := UI.button(
		panel, "SON AFET RAPORU", Rect2(8, 58, 284, 42), _open_event.bind("report")
	)
	for pair: Array in [[newspaper, report], [report, newspaper]]:
		var button: Button = pair[0]
		var other: Button = pair[1]
		button.focus_next = button.get_path_to(other)
		button.focus_previous = button.get_path_to(other)
		button.focus_neighbor_top = button.get_path_to(other)
		button.focus_neighbor_bottom = button.get_path_to(other)
		button.focus_neighbor_left = button.get_path_to(other)
		button.focus_neighbor_right = button.get_path_to(other)
	_events_menu.hide()
	refresh()


func refresh() -> void:
	var sim: Simulation = _shell.sim
	_budget.text = _shell.fmt_money(sim.treasury.money)
	_income.text = (
		"SON AY: "
		+ ("+" if sim.treasury.last_net >= 0 else "")
		+ _shell.fmt_money(sim.treasury.last_net)
		+ "\nGELİR-BAKIM; TAKSİT HARİÇ"
	)
	var trust := sim.trust.feedback()
	_trust_limits.text = "HALKIN GÜVENİ"
	_trust.text = ("%.2f" % trust.value).replace(".", ",")
	_trust_delta.text = (
		("SON %+.3f" % trust.latest_amount).replace(".", ",") if trust.has_change else "DEĞİŞİM YOK"
	)
	_trust_delta.add_theme_color_override(
		"font_color", UI.TEAL if trust.latest_amount > 0.0 else UI.GOLD
	)
	_trust.tooltip_text = (
		"Halkın güveni: %d-%d. %d'a düştüğünde oyun sona erer.\nSon değişim: %s\n%s"
		% [trust.minimum, trust.maximum, trust.minimum, _trust_delta.text, trust.latest_reason]
	)
	_trust_delta.tooltip_text = _trust.tooltip_text
	_awareness.text = str(sim.treasury.awareness_points)
	_awareness.tooltip_text = (
		"Bilinç geliştirmeleri tamamlandı. Yeni baloncuk üretimi durdu."
		if sim.projects.awareness_complete()
		else "Toplumsal hazırlık geliştirmelerinde harcanır."
	)
	var resources: Dictionary = sim.unit_overview().summary
	_total_teams.text = _shell.fmt_count(resources.ready)
	_team_total.text = "TOPLAM EKİP\n" + _shell.fmt_count(resources.total)
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
		"Tüm merkezlerde gönderime hazır toplam yardım malzemesi: %s." % _total_stock.text
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
	_pause_button.text = "ZAMANI BAŞLAT" if sim.paused else "ZAMANI DURDUR"
	_speed_state.text = (("DURDU / %d× SEÇİLİ" if sim.paused else "AKTİF HIZ: %d×") % sim.speed)
	_crisis_button.text = "AFET MÜDAHALESİ %d" % sim.crises.active.size()
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


func close_events_menu() -> bool:
	if not is_instance_valid(_events_menu) or not _events_menu.visible:
		return false
	_events_menu.hide()
	_events_button.grab_focus()
	return true


func _toggle_events_menu() -> void:
	if close_events_menu():
		return
	if not _shell.sim.news_queue.is_empty() or not _shell.sim.outcome.is_empty():
		return
	_events_menu.get_node("Choices").position = (
		_events_button.get_global_rect().position + Vector2(0, 50)
	)
	_shell.move_child(_events_menu, _shell.get_child_count() - 1)
	_events_menu.show()
	_events_menu.get_node("Choices").get_child(0).grab_focus()


func _events_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		close_events_menu()
		_events_menu.accept_event()


func _open_event(screen: String) -> void:
	close_events_menu()
	screen_requested.emit(screen)
