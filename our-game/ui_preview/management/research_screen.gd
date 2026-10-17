extends "res://ui_preview/shared/screen_view.gd"

const TABS := ["ALTYAPI VE KORUMA", "UYARI VE HABERLEŞME", "LOJİSTİK VE MÜDAHALE", "BİLİNÇ"]

var selected_tab: int = 0
var capacity: int:
	get:
		var sim: Simulation = _shell.sim
		return sim.projects.research_capacity


func render(content: Control, screen: String) -> void:
	super.render(content, screen)
	if screen == "research":
		_research()


func _research() -> void:
	var sim: Simulation = _shell.sim
	_title(
		"ULUSAL ARAŞTIRMA",
		"ARAŞTIRMA KAPASİTESİ: %d/%d" % [sim.projects.active_count("research"), capacity]
	)
	for index: int in range(4):
		UI.button(
			_content,
			TABS[index],
			Rect2(index * 344, 108, 330, 44),
			select_tab.bind(index),
			index == selected_tab
		)
	var nodes: Array[MeasureDefinition] = []
	for definition: MeasureDefinition in sim.projects.definitions.values():
		if definition.is_research() and definition.tab == selected_tab:
			nodes.append(definition)
	var positions: Dictionary = {}
	for index: int in range(nodes.size()):
		positions[nodes[index].id] = Vector2((index % 3) * 456, 202 + int(index / 3) * 224)
	for definition: MeasureDefinition in nodes:
		for requirement: String in definition.prerequisites:
			if positions.has(requirement):
				_connection(
					positions[requirement],
					positions[definition.id],
					sim.projects.is_completed(requirement)
				)
	for definition: MeasureDefinition in nodes:
		var position: Vector2 = positions[definition.id]
		var x := position.x
		var y := position.y
		UI.panel(_content, Rect2(x, y, 418, 166), true)
		var title: Label = UI.text(
			_content, definition.title.to_upper(), Rect2(x + 14, y + 12, 390, 44), 18, UI.GOLD
		)
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title.size = Vector2(390, 44)
		var price: String = (
			"%d BİLİNÇ" % definition.cost_awareness
			if definition.kind == "awareness"
			else _shell.fmt_money(definition.cost_budget)
		)
		UI.text(_content, "%s / %d AY" % [price, definition.months], Rect2(x + 14, y + 60, 390, 28))
		var state := _state(definition)
		var state_label: Label = UI.text(
			_content,
			state,
			Rect2(x + 14, y + 94, 390, 24),
			18,
			UI.TEAL if sim.projects.is_completed(definition.id) else UI.MUTED
		)
		state_label.tooltip_text = (
			sim.projects.availability(definition.id, 0, sim.clock.year).message
		)
		UI.button(
			_content,
			"İNCELE",
			Rect2(x + 14, y + 126, 390, 30),
			_shell.show_project.bind(definition.id, 0)
		)


func _state(definition: MeasureDefinition) -> String:
	var sim: Simulation = _shell.sim
	if sim.projects.is_completed(definition.id):
		return "TAMAMLANDI"
	for project: ActiveProject in sim.projects.projects:
		if (
			project.definition_id == definition.id
			and project.status in ["active", "waiting", "paused"]
		):
			return "PROJEDE / %d-%d AY" % [project.progress_months, definition.months]
	if sim.clock.year < definition.year:
		return "%d DÖNEM KİLİDİ" % definition.year
	for requirement: String in definition.prerequisites:
		if not sim.projects.is_completed(requirement):
			return "ÖNKOŞUL BEKLİYOR"
	return "ARAŞTIRILABİLİR"


func _connection(parent: Vector2, child: Vector2, completed: bool) -> void:
	var color := UI.TEAL if completed else UI.MUTED
	if is_equal_approx(parent.y, child.y):
		_line(Rect2(parent.x + 418, parent.y + 82, child.x - parent.x - 418, 3), color)
	else:
		var from := parent + Vector2(207, 166)
		var to := child + Vector2(207, 0)
		var middle := (from.y + to.y) / 2.0
		_line(Rect2(from.x, from.y, 3, middle - from.y), color)
		_line(Rect2(minf(from.x, to.x), middle, absf(to.x - from.x) + 3, 3), color)
		_line(Rect2(to.x, middle, 3, to.y - middle), color)


func select_tab(index: int) -> void:
	selected_tab = clampi(index, 0, 3)
	_shell.refresh_screen()
