extends "res://ui_preview/shared/screen_view.gd"

const TABS := ["ALTYAPI VE KORUMA", "UYARI VE HABERLEŞME", "LOJİSTİK VE MÜDAHALE", "BİLİNÇ"]
const ERAS := [1950, 1970, 1990, 2005, 2020]
const CARD_SIZE := Vector2(460, 304)
const COLUMN_WIDTH := 560
const ROW_HEIGHT := 336
const Copy := preload("res://ui_preview/management/measure_copy.gd")

var selected_tab: int = 0
var _scroll_positions: Dictionary = {}
var _pending_focus: String = ""
var _back_actions: Array[Callable] = []
var _restoring_scroll: bool = false
var _hovered_id: String = ""
var capacity: int:
	get:
		var sim: Simulation = _shell.sim
		return sim.projects.research_capacity


class ResearchConnection:
	extends Control
	var points: PackedVector2Array
	var source_id: String
	var target_id: String
	var completed: bool
	var ink: Color

	func _draw() -> void:
		draw_polyline(points, ink, 3.0, false)
		var end := points[-1]
		draw_colored_polygon(
			PackedVector2Array([end, end + Vector2(-12, -7), end + Vector2(-12, 7)]), ink
		)


func render(content: Control, screen: String) -> void:
	super.render(content, screen)
	if screen == "research":
		_research()


func _research() -> void:
	_hovered_id = ""
	var sim: Simulation = _shell.sim
	_title(
		"ARAŞTIRMALAR",
		(
			"ARAŞTIRMA: %d/%d / ÖNKOŞUL: + TAMAM, - EKSİK. HEPSİ GEREKLİDİR."
			% [sim.projects.active_count("research"), capacity]
		)
	)
	if not _back_actions.is_empty():
		UI.button(_content, "BAĞLANTIYA GERİ", Rect2(1080, 0, 264, 38), _go_back).name = "ResearchBack"
	for index: int in range(TABS.size()):
		var tab := UI.button(
			_content,
			TABS[index],
			Rect2(index * 336, 108, 324, 44),
			select_tab.bind(index),
			index == selected_tab
		)
		tab.name = "Category%d" % index
		tab.set_meta("guide_target", "research_tab_%d" % index)
	var nodes: Array[MeasureDefinition] = []
	for definition: MeasureDefinition in sim.projects.definitions.values():
		if definition.is_research() and definition.tab == selected_tab:
			nodes.append(definition)
	var scroll := ScrollContainer.new()
	scroll.name = "ResearchList"
	scroll.position = Vector2(0, 164)
	scroll.size = Vector2(1344, 504)
	scroll.follow_focus = false
	_content.add_child(scroll)
	var tree := Control.new()
	tree.name = "ResearchTree"
	tree.custom_minimum_size = Vector2(ERAS.size() * COLUMN_WIDTH, 752)
	scroll.add_child(tree)
	_restoring_scroll = true
	var tab_index := selected_tab
	scroll.get_h_scroll_bar().value_changed.connect(
		func(_value: float) -> void: _remember_scroll(scroll, tab_index)
	)
	scroll.get_v_scroll_bar().value_changed.connect(
		func(_value: float) -> void: _remember_scroll(scroll, tab_index)
	)
	var positions: Dictionary = {}
	for era_index: int in range(ERAS.size()):
		var year: int = ERAS[era_index]
		var band := ColorRect.new()
		band.name = "Era%d" % year
		band.position = Vector2(era_index * COLUMN_WIDTH, 0)
		band.size = Vector2(COLUMN_WIDTH - 12, 736)
		band.color = Color("182735") if year > sim.clock.year else Color("203743")
		band.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tree.add_child(band)
		UI.text(tree, "%d / %s" % [year, "DÖNEM KİLİTLİ" if year > sim.clock.year else "DÖNEM AÇIK"], Rect2(era_index * COLUMN_WIDTH + 20, 8, 500, 34), 24, UI.MUTED if year > sim.clock.year else UI.GOLD).name = (
			"EraTitle%d" % year
		)
		var row := 0
		for definition: MeasureDefinition in nodes:
			if definition.year == year:
				positions[definition.id] = Vector2(
					era_index * COLUMN_WIDTH + 20, 64 + row * ROW_HEIGHT
				)
				row += 1
	var edge_index := 0
	for definition: MeasureDefinition in nodes:
		for requirement: String in definition.prerequisites:
			if positions.has(requirement):
				_connection(
					requirement,
					definition.id,
					positions[requirement],
					positions[definition.id],
					sim.projects.is_completed(requirement),
					tree,
					edge_index
				)
				edge_index += 1
	for definition: MeasureDefinition in nodes:
		_card(tree, definition, positions[definition.id])
	_restore_scroll.call_deferred(scroll, tab_index)


func _card(tree: Control, definition: MeasureDefinition, position: Vector2) -> void:
	var sim: Simulation = _shell.sim
	var gates := sim.projects.requirement_status(definition.id, 0, sim.clock.year)
	var card := UI.panel(tree, Rect2(position, CARD_SIZE), true)
	card.name = definition.id
	card.mouse_entered.connect(_set_hover.bind(definition.id))
	card.mouse_exited.connect(_set_hover.bind(""))
	var title := UI.text(card, definition.title.to_upper(), Rect2(14, 8, 432, 44), 18, UI.GOLD)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var explanation := UI.text(
		card, Copy.explanation_for(definition.id).to_upper(), Rect2(14, 52, 432, 66), 18, UI.MUTED
	)
	explanation.name = "Explanation"
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var price: String = (
		"%d BİLİNÇ" % definition.cost_awareness
		if definition.kind == "awareness"
		else _shell.fmt_money(definition.cost_budget)
	)
	UI.text(
		card,
		"%d / %s / %d AY" % [definition.year, price, definition.months],
		Rect2(14, 122, 432, 22)
	)
	var status := UI.text(
		card,
		_state(definition, gates),
		Rect2(14, 146, 432, 22),
		18,
		UI.TEAL if sim.projects.is_completed(definition.id) else UI.MUTED
	)
	status.name = "State"
	status.tooltip_text = sim.projects.availability(definition.id, 0, sim.clock.year).message
	UI.text(
		card,
		(
			"TÜM ÖNKOŞULLAR GEREKLİ"
			if gates.prerequisites.size() > 1
			else "ÖNKOŞUL" if not gates.prerequisites.is_empty() else "ÖNKOŞUL YOK"
		),
		Rect2(14, 170, 432, 22),
		18,
		UI.MUTED
	)
	for index: int in range(gates.prerequisites.size()):
		var requirement: Dictionary = gates.prerequisites[index]
		var parent := sim.projects.definition_for(requirement.id)
		var prefix := "+ " if requirement.completed else "- "
		if parent.tab != selected_tab:
			prefix += ["ALTYAPI", "UYARI", "LOJİSTİK", "BİLİNÇ"][parent.tab] + ": "
		var requirement_title: String = (
			"Zemin-Yapı Etkileşimi" if requirement.id == "research_ground" else requirement.title
		)
		var link := UI.button(
			card,
			prefix + requirement_title.to_upper(),
			Rect2(14, 192 + index * 34, 432, 30),
			open_research.bind(requirement.id)
		)
		link.name = "Requirement_" + requirement.id
		link.clip_text = true
		link.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		link.tooltip_text = (
			"%s / %s / %s"
			% [
				TABS[parent.tab],
				requirement.title,
				"Tamamlandı" if requirement.completed else "Henüz tamamlanmadı"
			]
		)
		link.add_theme_color_override("font_color", UI.TEAL if requirement.completed else UI.MUTED)
		link.focus_entered.connect(_refresh_highlight)
		link.focus_exited.connect(func() -> void: _refresh_highlight.call_deferred())
	var inspect := UI.button(
		card, "İNCELE", Rect2(14, 264, 432, 30), _shell.show_project.bind(definition.id, 0)
	)
	inspect.name = "Inspect_" + definition.id
	inspect.set_meta("guide_target", "inspect_" + definition.id)
	inspect.focus_entered.connect(_refresh_highlight)
	inspect.focus_exited.connect(func() -> void: _refresh_highlight.call_deferred())


func _state(definition: MeasureDefinition, gates: Dictionary) -> String:
	var sim: Simulation = _shell.sim
	if sim.projects.is_completed(definition.id):
		return "TAMAMLANDI"
	for project: ActiveProject in sim.projects.projects:
		if (
			project.definition_id == definition.id
			and project.status in ["active", "waiting", "paused", "queued"]
		):
			return (
				"%s / %d/%d AY"
				% [Copy.status_for(project.status), project.progress_months, definition.months]
			)
	if gates.year_locked:
		return "%d YILINDA AÇILIR" % gates.year
	if not gates.ready:
		return "EKSİK ÖNKOŞUL VAR"
	return String(sim.projects.availability(definition.id, 0, sim.clock.year).message).to_upper()


func _connection(
	source_id: String,
	target_id: String,
	parent: Vector2,
	child: Vector2,
	completed: bool,
	tree: Control,
	index: int
) -> void:
	var edge := ResearchConnection.new()
	edge.name = "Edge_" + source_id + "__" + target_id
	edge.source_id = source_id
	edge.target_id = target_id
	edge.completed = completed
	edge.ink = UI.TEAL if completed else UI.MUTED
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var from := parent + Vector2(CARD_SIZE.x, CARD_SIZE.y / 2.0)
	var to := child + Vector2(0, CARD_SIZE.y / 2.0)
	var exit_x := from.x + 16 + (index % 5) * 5
	var entry_x := to.x - 18 - (index % 5) * 5
	var lane_y := parent.y + CARD_SIZE.y + 8 + (index % 5) * 4
	edge.points = PackedVector2Array(
		[
			from,
			Vector2(exit_x, from.y),
			Vector2(exit_x, lane_y),
			Vector2(entry_x, lane_y),
			Vector2(entry_x, to.y),
			to
		]
	)
	tree.add_child(edge)


func _set_hover(id: String) -> void:
	_hovered_id = id
	_refresh_highlight()


func _refresh_highlight() -> void:
	if not is_instance_valid(_content):
		return
	var tree := _content.get_node_or_null("ResearchList/ResearchTree")
	if tree == null:
		return
	var id := _hovered_id
	if id.is_empty():
		var focused: Node = _shell.get_viewport().gui_get_focus_owner()
		while focused != null and focused.get_parent() != tree:
			focused = focused.get_parent()
		if focused != null:
			id = String(focused.name)
	for child: Node in tree.get_children():
		if child is ResearchConnection:
			child.ink = (
				UI.GOLD
				if id in [child.source_id, child.target_id]
				else UI.TEAL if child.completed else UI.MUTED
			)
			child.queue_redraw()


func _remember_scroll(scroll: ScrollContainer, tab: int) -> void:
	if not _restoring_scroll:
		_scroll_positions[tab] = Vector2i(scroll.scroll_horizontal, scroll.scroll_vertical)


func _restore_scroll(scroll: ScrollContainer, tab: int) -> void:
	await _shell.get_tree().process_frame
	if not is_instance_valid(scroll) or not scroll.is_inside_tree():
		return
	var saved: Vector2i = _scroll_positions.get(tab, Vector2i.ZERO)
	scroll.scroll_horizontal = saved.x
	scroll.scroll_vertical = saved.y
	if not _pending_focus.is_empty():
		var card := scroll.get_node_or_null("ResearchTree/" + _pending_focus) as Control
		if card != null:
			scroll.scroll_horizontal = maxi(0, int(card.position.x) - 20)
			scroll.scroll_vertical = maxi(0, int(card.position.y) - 64)
			card.get_node("Inspect_" + _pending_focus).grab_focus()
		_pending_focus = ""
	_restoring_scroll = false
	_remember_scroll(scroll, tab)
	scroll.follow_focus = true


func open_research(id: String, back_action: Callable = Callable()) -> void:
	var sim: Simulation = _shell.sim
	var definition := sim.projects.definition_for(id)
	if definition == null or not definition.is_research():
		return
	if _shell.open_screen == "research":
		var scroll: ScrollContainer = _content.get_node("ResearchList")
		var position := Vector2i(scroll.scroll_horizontal, scroll.scroll_vertical)
		_back_actions.append(_restore_tab.bind(selected_tab, _shell.screen_focus_path(), position))
	elif back_action.is_valid():
		_back_actions.append(back_action)
	selected_tab = definition.tab
	_pending_focus = id
	_shell.show_screen("research")


func _restore_tab(tab: int, focus: NodePath, position: Vector2i) -> void:
	selected_tab = tab
	_scroll_positions[tab] = position
	_shell.show_screen("research")
	_shell.restore_screen_focus(focus)


func _go_back() -> void:
	if not _back_actions.is_empty():
		var action: Callable = _back_actions.pop_back()
		action.call()


func reset_navigation() -> void:
	_back_actions.clear()


func select_tab(index: int) -> void:
	selected_tab = clampi(index, 0, TABS.size() - 1)
	_shell.refresh_screen()
