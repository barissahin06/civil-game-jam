extends Control

signal screen_requested(screen: String)
signal project_requested(definition_id: String, area_id: int)
signal close_requested

const UI := preload("res://ui_preview/shared/ui_kit.gd")

var selected_area_id: int = 0
var selected_tab: int = 0
var _shell: Control
var _city_title: Label
var _city_region: Label
var _city_body: Control
var _city_tabs: Array[Button] = []
var _investment_page: int = 0


func setup(shell: Control) -> void:
	_shell = shell


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.panel(self, Rect2(16, 174, 400, 846))
	_city_title = UI.text(self, "", Rect2(36, 194, 310, 48), 36)
	var close_button := UI.button(self, "×", Rect2(358, 198, 38, 38), close_requested.emit)
	close_button.tooltip_text = "ŞEHİR PANELİNİ KAPAT / ESC"
	_city_region = UI.text(self, "", Rect2(36, 244, 364, 26), 18, UI.MUTED)
	for index: int in range(3):
		_city_tabs.append(
			UI.button(
				self,
				["ÖZET", "YATIRIM", "LOJİSTİK"][index],
				Rect2(36 + index * 122, 282, 114, 34),
				select_tab.bind(index),
				index == 0
			)
		)
	_city_body = Control.new()
	_city_body.position = Vector2(36, 334)
	_city_body.size = Vector2(360, 660)
	add_child(_city_body)
	hide()


func select_area(id: int) -> bool:
	var sim: Simulation = _shell.sim
	if not sim.areas.has(id):
		return false
	if selected_area_id != id:
		_investment_page = 0
	selected_area_id = id
	var area: ServiceArea = sim.areas[id]
	_city_title.text = area.name.to_upper()
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
	UI.clear(_city_body)
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
	UI.text(_city_body, "ALAN GELİRİ", Rect2(0, 42, 180, 26), 18, UI.MUTED)
	UI.text(
		_city_body, _shell.fmt_money(area.income()) + "/AY", Rect2(174, 42, 186, 26), 18, UI.TEAL
	)
	var resilience := sim.projects.infrastructure(area.id)
	UI.text(_city_body, "ALTYAPI DİRENCİ", Rect2(0, 104, 250, 26), 18, UI.MUTED)
	UI.text(_city_body, "%d/100" % roundi(resilience), Rect2(276, 104, 84, 26))
	UI.bar(_city_body, Vector2(0, 142), 360, resilience, UI.TEAL)
	UI.text(_city_body, "AFET HAZIRLIĞI", Rect2(0, 180, 360, 26), 18, UI.MUTED)
	for index: int in range(5):
		var kind: String = ["earthquake", "flood", "fire", "avalanche", "landslide"][index]
		var value := sim.projects.preparedness(area.id, kind)
		UI.text(
			_city_body,
			["DEPREM", "SEL", "YANGIN", "ÇIĞ", "HEYELAN"][index],
			Rect2(0, 222 + index * 34, 132, 26)
		)
		UI.bar(
			_city_body,
			Vector2(136, 232 + index * 34),
			158,
			value,
			UI.GOLD if value < 60 else UI.TEAL
		)
		UI.text(_city_body, "%d" % roundi(value), Rect2(312, 222 + index * 34, 48, 26))
	UI.panel(_city_body, Rect2(0, 422, 174, 88), true)
	UI.panel(_city_body, Rect2(186, 422, 174, 88), true)
	UI.icon(_city_body, 4, Vector2(10, 432), UI.TEAL)
	UI.icon(_city_body, 5, Vector2(196, 432), UI.GOLD)
	UI.text(_city_body, "%d EKİP" % area.teams, Rect2(50, 434, 122, 26))
	UI.text(_city_body, "%d YARDIM" % area.stock, Rect2(234, 434, 124, 26))
	UI.text(_city_body, "%d TOPLAM" % area.total_teams, Rect2(14, 474, 148, 22), 18, UI.MUTED)
	UI.text(_city_body, "HAZIR", Rect2(200, 474, 144, 22), 18, UI.MUTED)
	UI.text(
		_city_body,
		"AKTİF PROJE: %d/1" % sim.projects.active_count("local", area.id),
		Rect2(0, 546, 360, 26),
		18,
		UI.MUTED
	)
	UI.button(_city_body, "YATIRIMLARI GÖR", Rect2(0, 598, 360, 48), select_tab.bind(1))


func _investments(area: ServiceArea) -> void:
	var sim: Simulation = _shell.sim
	var definitions: Array[MeasureDefinition] = []
	for definition: MeasureDefinition in sim.projects.definitions.values():
		if definition.is_local():
			definitions.append(definition)
	var last_page := maxi(0, int((definitions.size() - 1) / 3))
	_investment_page = clampi(_investment_page, 0, last_page)
	UI.text(_city_body, "YEREL YATIRIMLAR", Rect2(0, 0, 360, 28), 18, UI.GOLD)
	UI.text(
		_city_body,
		"AKTİF PROJE: %d/1" % sim.projects.active_count("local", area.id),
		Rect2(0, 40, 360, 26),
		18,
		UI.MUTED
	)
	for row: int in range(3):
		var index := _investment_page * 3 + row
		if index >= definitions.size():
			break
		var definition := definitions[index]
		var y := 92 + row * 160
		UI.panel(_city_body, Rect2(0, y, 360, 144), true)
		var title := UI.text(_city_body, definition.title.to_upper(), Rect2(12, y + 12, 336, 48))
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title.size = Vector2(336, 48)
		title.tooltip_text = definition.title
		UI.text(
			_city_body,
			(
				"%s / %d AY"
				% [
					_shell.fmt_money(sim.projects.cost_for(definition.id, area.id)),
					definition.months
				]
			),
			Rect2(12, y + 62, 336, 26),
			18,
			UI.MUTED
		)
		var availability := sim.projects.availability(definition.id, area.id, sim.clock.year)
		var inspect := UI.button(
			_city_body,
			"TAMAMLANDI" if sim.projects.is_completed(definition.id, area.id) else "İNCELE",
			Rect2(12, y + 96, 336, 36),
			project_requested.emit.bind(definition.id, area.id)
		)
		inspect.tooltip_text = availability.message
	UI.button(_city_body, "GERİ", Rect2(0, 580, 84, 34), _change_page.bind(-1)).disabled = (
		_investment_page == 0
	)
	UI.text(
		_city_body,
		"%d / %d" % [_investment_page + 1, last_page + 1],
		Rect2(94, 584, 172, 26),
		18,
		UI.MUTED
	)
	UI.button(_city_body, "İLERİ", Rect2(276, 580, 84, 34), _change_page.bind(1)).disabled = (
		_investment_page == last_page
	)
	UI.button(
		_city_body, "PROJE TAKİBİ", Rect2(0, 630, 360, 30), screen_requested.emit.bind("projects")
	)


func _change_page(offset: int) -> void:
	_investment_page += offset
	refresh()


func _logistics(area: ServiceArea) -> void:
	UI.text(_city_body, "MERKEZ LOJİSTİĞİ", Rect2(0, 0, 360, 28), 18, UI.GOLD)
	UI.text(
		_city_body,
		"HAZIR / TOPLAM EKİP: %d / %d" % [area.teams, area.total_teams],
		Rect2(0, 60, 360, 28)
	)
	UI.text(_city_body, "YARDIM STOĞU: %d" % area.stock, Rect2(0, 110, 360, 28))
	var team := UI.button(_city_body, "1 EKİP SÜRÜKLE", Rect2(0, 174, 360, 42), Callable())
	team.disabled = area.teams < 1
	team.set_drag_forwarding(_drag.bind("team", team), Callable(), Callable())
	var stock := UI.button(_city_body, "10 YARDIM SÜRÜKLE", Rect2(0, 230, 360, 42), Callable())
	stock.disabled = area.stock < 10
	stock.set_drag_forwarding(_drag.bind("stock", stock), Callable(), Callable())
	UI.button(
		_city_body,
		"EKİP KUR",
		Rect2(0, 306, 174, 44),
		project_requested.emit.bind("rescue_team", area.id)
	)
	UI.button(
		_city_body,
		"STOK HAZIRLA",
		Rect2(186, 306, 174, 44),
		project_requested.emit.bind("aid_stock", area.id)
	)
	UI.button(
		_city_body, "KRİZ MERKEZİ", Rect2(0, 384, 360, 48), screen_requested.emit.bind("crisis")
	)
	UI.text(_city_body, "HEDEF ALANA BIRAKARAK SEVK ET", Rect2(0, 466, 360, 28), 18, UI.MUTED)
	UI.text(_city_body, "YAKIN 1 / ORTA 2 / UZAK 3 GÜN", Rect2(0, 562, 360, 50), 18, UI.MUTED)


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
		"%s / %d %s" % [area.name.to_upper(), amount, "EKİP" if kind == "team" else "YARDIM"]
	)
	preview.add_theme_font_override("font", UI.FONT)
	preview.add_theme_font_size_override("font_size", 18)
	token.set_drag_preview(preview)
	return {"tag": "dispatch", "source": area.id, "kind": kind, "amount": amount}
