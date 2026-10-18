extends "res://tests/integration/gameplay_ui.gd"
## Real input, all research eras and descriptions; never reads or writes player saves.

const ERAS := [1950, 1970, 1990, 2005, 2020]


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	root.content_scale_size = root.size
	_main = load("res://ui_preview/scenes/main_preview.tscn").instantiate()
	root.add_child(_main)
	await process_frame
	_shell = _main
	_shell.auto_save_enabled = false
	_shell.sim.tutorial_enabled = false
	_shell.sim.set_paused(true)
	_shell.show_screen("research")
	for tab: int in range(4):
		_shell.research.select_tab(tab)
		await _capture("research-era-tab-%d" % tab)
		_check_tree(tab)
		var scroll: ScrollContainer = _shell._screen_content.get_node("ResearchList")
		scroll.scroll_horizontal = int(scroll.get_h_scroll_bar().max_value)
		scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
		await _capture("research-era-last-%d" % tab)
		var saved := Vector2i(scroll.scroll_horizontal, scroll.scroll_vertical)
		_shell.refresh_screen()
		await process_frame
		await process_frame
		scroll = _shell._screen_content.get_node("ResearchList")
		assert(Vector2i(scroll.scroll_horizontal, scroll.scroll_vertical) == saved)
	await _check_cross_category()
	await _check_national_return()
	await _check_details()
	await _shell.audio.shutdown()
	_main.queue_free()
	await process_frame
	print(
		"RESEARCH_TREE_UI_PASS: 40 research, 5 eras, arrows, cross-category links, national return, 55 descriptions"
	)
	quit()


func _check_tree(tab: int) -> void:
	var sim: Simulation = _shell.sim
	var tree: Control = _shell._screen_content.get_node("ResearchList/ResearchTree")
	var expected_edges := 0
	var cards: Array[Control] = []
	var counts: Dictionary = {}
	for definition: MeasureDefinition in sim.projects.definitions.values():
		if not definition.is_research() or definition.tab != tab:
			continue
		var card: Control = tree.get_node(definition.id)
		cards.append(card)
		counts[definition.year] = int(counts.get(definition.year, 0)) + 1
		assert(int(card.position.x) == ERAS.find(definition.year) * 560 + 20)
		var gates := sim.projects.requirement_status(definition.id, 0, sim.clock.year)
		if gates.year_locked:
			assert(String(card.get_node("State").text).contains(str(definition.year)))
		for requirement: String in definition.prerequisites:
			assert(
				card.has_node("Requirement_" + requirement),
				"Every prerequisite stays visible even behind a date lock"
			)
			if sim.projects.definition_for(requirement).tab == tab:
				expected_edges += 1
				assert(tree.has_node("Edge_" + requirement + "__" + definition.id))
	for year: int in ERAS:
		assert(counts.get(year) == 2)
		assert(tree.has_node("EraTitle%d" % year))
	var edges := 0
	for child: Node in tree.get_children():
		if not String(child.name).begins_with("Edge_"):
			continue
		edges += 1
		var points: PackedVector2Array = child.get("points")
		assert(points[-1].x > points[-2].x, "Arrowhead must point into the target from the left")
		for index: int in range(points.size() - 1):
			for card: Control in cards:
				var interior := card.get_rect().grow(-3)
				var a := points[index]
				var b := points[index + 1]
				if is_equal_approx(a.y, b.y):
					assert(
						not (
							a.y > interior.position.y
							and a.y < interior.end.y
							and maxf(a.x, b.x) > interior.position.x
							and minf(a.x, b.x) < interior.end.x
						),
						"Horizontal dependency line crosses a card"
					)
				else:
					assert(
						not (
							a.x > interior.position.x
							and a.x < interior.end.x
							and maxf(a.y, b.y) > interior.position.y
							and minf(a.y, b.y) < interior.end.y
						),
						"Vertical dependency line crosses a card"
					)
	assert(edges == expected_edges)


func _check_cross_category() -> void:
	_shell.research.open_research("research_terrain")
	await process_frame
	await process_frame
	assert(_shell.research.selected_tab == 1)
	var scroll: ScrollContainer = _shell._screen_content.get_node("ResearchList")
	var saved := Vector2i(scroll.scroll_horizontal, scroll.scroll_vertical)
	var link: Button = scroll.get_node("ResearchTree/research_terrain/Requirement_research_ground")
	assert(link.text.contains("ALTYAPI"))
	await _click(link.get_global_rect().get_center())
	assert(_shell.research.selected_tab == 0)
	assert(root.gui_get_focus_owner().name == "Inspect_research_ground")
	await _capture("research-cross-category")
	await _press_button("BAĞLANTIYA GERİ")
	assert(_shell.research.selected_tab == 1)
	scroll = _shell._screen_content.get_node("ResearchList")
	assert(
		Vector2i(scroll.scroll_horizontal, scroll.scroll_vertical) == saved,
		(
			"Cross-category return scroll: expected %s, got %s"
			% [saved, Vector2i(scroll.scroll_horizontal, scroll.scroll_vertical)]
		)
	)
	assert(root.gui_get_focus_owner().name == "Requirement_research_ground")
	await _key(KEY_TAB)
	assert(root.gui_get_focus_owner() != null)
	var focus := root.gui_get_focus_owner()
	assert(
		scroll.get_global_rect().encloses(focus.get_global_rect()),
		"Keyboard focus scrolls into view"
	)
	_shell.research.open_research("research_ground")
	await process_frame
	await process_frame
	var tree: Control = _shell._screen_content.get_node("ResearchList/ResearchTree")
	assert(tree.get_node("Edge_research_structural__research_ground").get("ink") == UI.GOLD)


func _check_national_return() -> void:
	_shell.show_screen("national")
	await process_frame
	await process_frame
	var scroll: ScrollContainer = _shell._screen_content.get_node("ProjectList")
	var rows: Control = scroll.get_node("Rows")
	for year: int in ERAS:
		assert(rows.has_node("EraTitle%d" % year))
	var target: Control = rows.get_node("national_multichannel_warning")
	scroll.scroll_vertical = int(target.position.y)
	await _capture("research-national-2020")
	var saved := scroll.scroll_vertical
	var link: Button = target.get_node("Requirement_research_hazard_analysis")
	await _click(link.get_global_rect().get_center())
	assert(_shell.open_screen == "research" and _shell.research.selected_tab == 1)
	assert(root.gui_get_focus_owner().name == "Inspect_research_hazard_analysis")
	await _capture("research-national-link")
	await _press_button("BAĞLANTIYA GERİ")
	assert(_shell.open_screen == "national")
	scroll = _shell._screen_content.get_node("ProjectList")
	assert(scroll.scroll_vertical == saved)
	assert(root.gui_get_focus_owner().name == "Requirement_research_hazard_analysis")
	await _capture("research-national-restored")


func _check_details() -> void:
	_shell.projects.show_project("research_condition_monitoring")
	await _capture("research-detail-top")
	assert(_find_button(_shell._modal, "BAŞLAT").disabled)
	var details: Control = _shell._screen_content.get_node("ProjectBody/Details")
	assert(details.has_node("Requirement_research_automation"))
	assert(details.has_node("Requirement_research_sensor"))
	assert(details.has_node("Unlock_national_preventive_maintenance"))
	assert(String(details.get_node("YearRequirement").text).contains("2020"))
	var body: ScrollContainer = _shell._screen_content.get_node("ProjectBody")
	body.scroll_vertical = int(body.get_v_scroll_bar().max_value)
	await _capture("research-detail-links")
	var count := 0
	for definition: MeasureDefinition in _shell.sim.projects.definitions.values():
		if (
			not definition.is_research()
			and not (definition.kind == "national" and not definition.id.begins_with("decision_"))
		):
			continue
		_shell.projects.show_project(definition.id)
		await process_frame
		await process_frame
		details = _shell._screen_content.get_node("ProjectBody/Details")
		assert(String(details.get_node("Description").text).length() > 90)
		_check_text(_main)
		count += 1
	assert(count == 55)


func _key(code: Key) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
	await process_frame
	await process_frame
