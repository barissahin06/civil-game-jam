extends Control

signal screen_requested(screen: String)
signal project_requested(definition_id: String, area_id: int)
signal close_requested
signal dispatch_requested(source: int)

const UI := preload("res://ui_preview/shared/ui_kit.gd")
const Copy := preload("res://ui_preview/management/measure_copy.gd")

var selected_area_id: int = 0
var selected_tab: int = 0
var _shell: Control
var _city_title: Label
var _city_region: Label
var _city_body: Control
var _city_tabs: Array[Button] = []
var _rendered_tab: int = -1
var _rendered_area_id: int = 0
var _investment_scroll: ScrollContainer
var _investment_capacity: Label
var _investment_rows: Dictionary = {}
var _investment_position: int = 0
var _investment_focus: String = ""


func setup(shell: Control) -> void:
	_shell = shell


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.panel(self, Rect2(16, 174, 400, 846))
	_city_title = UI.text(self, "", Rect2(36, 194, 310, 88), 36)
	_city_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var close_button := UI.button(self, "×", Rect2(358, 198, 38, 38), close_requested.emit)
	close_button.tooltip_text = "ŞEHİR PANELİNİ KAPAT / ESC"
	_city_region = UI.text(self, "", Rect2(36, 286, 364, 26), 18, UI.MUTED)
	var totals := UI.text(
		self, "DEĞERLER, MERKEZE BAĞLI İLLERİN TOPLAMIDIR.", Rect2(36, 316, 364, 44), 18, UI.MUTED
	)
	totals.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for index: int in range(3):
		_city_tabs.append(
			UI.button(
				self,
				["ÖZET", "YATIRIM", "GÖNDERİM"][index],
				Rect2(36 + index * 122, 362, 114, 34),
				select_tab.bind(index),
				index == 0
			)
		)
		_city_tabs.back().set_meta("guide_target", "city_tab_%d" % index)
	_city_body = Control.new()
	_city_body.position = Vector2(36, 408)
	_city_body.size = Vector2(360, 588)
	add_child(_city_body)
	hide()


func select_area(id: int) -> bool:
	var sim: Simulation = _shell.sim
	if not sim.areas.has(id):
		return false
	if selected_area_id != id:
		_investment_position = 0
		_investment_focus = ""
		_rendered_area_id = 0
	selected_area_id = id
	var area: ServiceArea = sim.areas[id]
	_city_title.add_theme_font_size_override("font_size", 32 if area.name.length() > 12 else 36)
	_city_title.text = area.name.to_upper() + " VE ÇEVRESİ"
	_city_region.text = area.region.to_upper()
	_render_city(area)
	show()
	return true


func clear_selection() -> void:
	selected_area_id = 0
	hide()


func refresh() -> void:
	if selected_area_id != 0:
		select_area(selected_area_id)


func select_tab(index: int) -> void:
	selected_tab = clampi(index, 0, 2)
	for button_index: int in range(_city_tabs.size()):
		_city_tabs[button_index].add_theme_stylebox_override(
			"normal", UI.style(Rect2(112 if button_index == selected_tab else 0, 56, 48, 32))
		)
	refresh()


func _render_city(area: ServiceArea) -> void:
	if selected_tab == 1 and _rendered_tab == 1 and _rendered_area_id == area.id:
		_refresh_investments(area)
		return
	if _rendered_tab == 1 and is_instance_valid(_investment_scroll):
		if _rendered_area_id == area.id:
			_investment_position = _investment_scroll.scroll_vertical
	_investment_rows.clear()
	UI.clear(_city_body)
	_rendered_tab = selected_tab
	_rendered_area_id = area.id
	match selected_tab:
		0:
			_summary(area)
		1:
			_investments(area)
		2:
			_logistics(area)


func _summary(area: ServiceArea) -> void:
	var sim: Simulation = _shell.sim
	UI.text(_city_body, "YÖNETİLEN NÜFUS", Rect2(0, 0, 240, 26), 18, UI.MUTED)
	UI.text(_city_body, _shell.fmt_count(area.population), Rect2(252, 0, 108, 26))
	UI.text(_city_body, "AYLIK GELİR", Rect2(0, 42, 180, 26), 18, UI.MUTED)
	UI.text(
		_city_body, _shell.fmt_money(area.income()) + "/AY", Rect2(174, 42, 186, 26), 18, UI.TEAL
	)
	var resilience := sim.projects.infrastructure(area.id)
	UI.text(_city_body, "ALTYAPI DAYANIKLILIĞI", Rect2(0, 92, 264, 26), 18, UI.MUTED)
	UI.text(_city_body, "%d/100" % roundi(resilience), Rect2(276, 92, 84, 26))
	UI.bar(_city_body, Vector2(0, 130), 360, resilience, UI.TEAL)
	UI.text(_city_body, "AFET HAZIRLIĞI", Rect2(0, 160, 360, 26), 18, UI.MUTED)
	for index: int in range(5):
		var kind: String = ["earthquake", "flood", "fire", "avalanche", "landslide"][index]
		var value := sim.projects.preparedness(area.id, kind)
		UI.text(
			_city_body,
			["DEPREM", "SEL", "YANGIN", "ÇIĞ", "HEYELAN"][index],
			Rect2(0, 200 + index * 32, 132, 26)
		)
		UI.bar(
			_city_body,
			Vector2(136, 210 + index * 32),
			158,
			value,
			UI.GOLD if value < 60 else UI.TEAL
		)
		UI.text(_city_body, "%d" % roundi(value), Rect2(312, 200 + index * 32, 48, 26))
	UI.panel(_city_body, Rect2(0, 380, 360, 100), true)
	UI.text(_city_body, "KENDİ HAZIR EKİBİ", Rect2(12, 386, 240, 26), 18, UI.MUTED)
	UI.text(_city_body, str(area.teams), Rect2(264, 386, 84, 26))
	UI.text(_city_body, "KENDİ TOPLAM EKİBİ", Rect2(12, 416, 240, 26), 18, UI.MUTED)
	UI.text(_city_body, str(area.total_teams), Rect2(264, 416, 84, 26))
	UI.text(_city_body, "YARDIM MALZEMESİ", Rect2(12, 446, 240, 26), 18, UI.MUTED)
	UI.text(_city_body, str(area.stock), Rect2(264, 446, 84, 26))
	UI.text(
		_city_body,
		(
			"KONDİSYON: %%%d / VERİM: %%%d"
			% [roundi(area.condition), roundi(area.capacity_efficiency() * 100.0)]
		),
		Rect2(0, 494, 360, 26),
		18,
		UI.GOLD if area.condition <= ProjectSystem.RENEWAL_WARNING else UI.MUTED
	)
	UI.button(_city_body, "YATIRIMLARI GÖR", Rect2(0, 536, 360, 48), select_tab.bind(1))


func _investments(area: ServiceArea) -> void:
	var sim: Simulation = _shell.sim
	var definitions: Array[MeasureDefinition] = []
	for definition: MeasureDefinition in sim.projects.definitions.values():
		if (
			definition.is_local()
			and not definition.id in ["rescue_team", "aid_stock"]
			and not definition.id.begins_with("decision_")
		):
			definitions.append(definition)
	UI.text(_city_body, "YEREL YATIRIMLAR", Rect2(0, 0, 360, 28), 18, UI.GOLD)
	_investment_capacity = UI.text(_city_body, "", Rect2(0, 36, 360, 26), 18, UI.MUTED)
	_investment_scroll = ScrollContainer.new()
	_investment_scroll.name = "InvestmentList"
	_investment_scroll.position = Vector2(0, 74)
	_investment_scroll.size = Vector2(360, 514)
	_investment_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_city_body.add_child(_investment_scroll)
	var list := Control.new()
	list.name = "Rows"
	list.custom_minimum_size = Vector2(336, definitions.size() * 256)
	_investment_scroll.add_child(list)
	for index: int in range(definitions.size()):
		var definition := definitions[index]
		var row := UI.panel(list, Rect2(0, index * 256, 336, 248), true)
		row.name = definition.id
		var title := UI.text(row, definition.title.to_upper(), Rect2(10, 2, 316, 44), 18)
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title.size = Vector2(316, 44)
		title.tooltip_text = definition.title
		var explanation := UI.text(
			row,
			Copy.explanation_for(definition.id).to_upper(),
			Rect2(10, 48, 316, 66),
			18,
			UI.MUTED
		)
		explanation.name = "Explanation"
		explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var status := UI.text(row, "", Rect2(10, 142, 316, 66), 18, UI.MUTED)
		status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_investment_rows[definition.id] = {
			"cost": UI.text(row, "", Rect2(10, 116, 316, 24), 18, UI.MUTED),
			"status": status,
			"inspect":
			UI.button(
				row,
				"İNCELE",
				Rect2(214, 210, 112, 34),
				_inspect_investment.bind(definition.id, area.id)
			),
		}
		_investment_rows[definition.id].inspect.name = "Inspect"
		_investment_rows[definition.id].inspect.set_meta("guide_target", "inspect_" + definition.id)
	_refresh_investments(area)
	_investment_scroll.set_deferred("scroll_vertical", _investment_position)


func _refresh_investments(area: ServiceArea) -> void:
	var sim: Simulation = _shell.sim
	_investment_capacity.text = (
		"AYNI ANDA ÇALIŞAN PROJE: %d/1" % sim.projects.active_count("local", area.id)
	)
	for id: String in _investment_rows:
		var definition: MeasureDefinition = sim.projects.definition_for(id)
		var row: Dictionary = _investment_rows[id]
		row.cost.text = (
			"%s / %d AY" % [_shell.fmt_money(sim.projects.cost_for(id, area.id)), definition.months]
		)
		var availability: Dictionary = sim.projects.availability(id, area.id, sim.clock.year)
		var status: String = String(availability.message).to_upper()
		if sim.projects.is_completed(id, area.id):
			status = "TAMAMLANDI"
		else:
			for project: ActiveProject in sim.projects.projects:
				if project.definition_id == id and project.area_id == area.id:
					if project.status in ["active", "waiting", "paused", "queued"]:
						status = Copy.status_for(project.status)
		row.status.text = status
		row.inspect.tooltip_text = availability.message


func _inspect_investment(id: String, area_id: int) -> void:
	_investment_focus = id
	project_requested.emit(id, area_id)


func restore_investment_focus() -> void:
	if selected_tab == 1 and _investment_rows.has(_investment_focus):
		_investment_rows[_investment_focus].inspect.call_deferred("grab_focus")


func _logistics(area: ServiceArea) -> void:
	UI.text(_city_body, "MERKEZDEN GÖNDERİM", Rect2(0, 0, 360, 28), 18, UI.GOLD)
	UI.text(
		_city_body,
		"KENDİ HAZIR EKİBİ: %d\nKENDİ TOPLAM EKİBİ: %d" % [area.teams, area.total_teams],
		Rect2(0, 60, 360, 44)
	)
	UI.text(_city_body, "YARDIM MALZEMESİ: %d" % area.stock, Rect2(0, 110, 360, 28))
	var team := UI.button(_city_body, "1 EKİP SÜRÜKLE", Rect2(0, 174, 360, 42), Callable())
	team.disabled = area.teams < 1
	team.set_drag_forwarding(_drag.bind("team", team), Callable(), Callable())
	var stock := UI.button(
		_city_body, "10 BİRİM MALZEME SÜRÜKLE", Rect2(0, 230, 360, 42), Callable()
	)
	stock.disabled = area.stock < 10
	stock.set_drag_forwarding(_drag.bind("stock", stock), Callable(), Callable())
	UI.button(
		_city_body,
		"GÖNDERİM HAZIRLA",
		Rect2(0, 306, 360, 42),
		dispatch_requested.emit.bind(area.id)
	)
	UI.text(_city_body, "HEDEF MERKEZE BIRAK.", Rect2(0, 374, 360, 28), 18, UI.MUTED)
	UI.text(_city_body, "YAKIN 1 / ORTA 2 / UZAK 3 GÜN", Rect2(0, 414, 360, 28), 18, UI.MUTED)


func _drag(_position: Vector2, kind: String, token: Control) -> Variant:
	var sim: Simulation = _shell.sim
	if not sim.areas.has(selected_area_id):
		return null
	var area: ServiceArea = sim.areas[selected_area_id]
	var amount := 1 if kind == "team" else 10
	if (kind == "team" and area.teams < amount) or (kind == "stock" and area.stock < amount):
		return null
	var preview := Label.new()
	preview.text = (
		"%s / %d %s"
		% [area.name.to_upper(), amount, "EKİP" if kind == "team" else "BİRİM YARDIM MALZEMESİ"]
	)
	preview.add_theme_font_override("font", UI.FONT)
	preview.add_theme_font_size_override("font_size", 18)
	token.set_drag_preview(preview)
	return {"tag": "dispatch", "source": area.id, "kind": kind, "amount": amount}
