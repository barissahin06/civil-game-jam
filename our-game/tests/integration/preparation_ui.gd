extends "res://tests/integration/gameplay_ui.gd"
## Real map input, isolated simulation and no player save I/O.


func _run() -> void:
	capture_screens = "--capture" in OS.get_cmdline_user_args()
	root.size = Vector2i(1920, 1080)
	root.content_scale_size = root.size
	_main = load("res://ui_preview/scenes/main_preview.tscn").instantiate()
	root.add_child(_main)
	await process_frame
	_shell = _main
	_shell.auto_save_enabled = false
	_shell.sim.tutorial_enabled = false
	assert(_shell.sim.start_project("river_zoning", 31).ok)
	await _press_button("EKİP VE YARDIM HAZIRLA")
	var panel: Control = _shell.preparation_panel
	assert(panel.visible and panel.action_id.is_empty())
	assert(not _shell.city_panel.visible and _shell.open_screen.is_empty())
	var points := _map_points()
	await _click(points[1])
	assert(_shell.sim.projects.projects.size() == 1, "Choose an action before stamping")
	await _press_button("EKİP KUR")
	await _click(Vector2(1050, 250))
	assert(_shell.sim.projects.projects.size() == 1, "Passive map/sea must not enqueue")
	var money := _shell.sim.treasury.money
	for id: int in [1, 6, 31, 1]:
		await _click(points[id])
	assert(_shell.sim.projects.active_count("local", 1) == 1)
	assert(_shell.sim.projects.active_count("local", 6) == 1)
	assert(_shell.sim.preparation_plan().summary.queued_count == 2)
	assert(panel.action_id == "rescue_team" and not _shell.city_panel.visible)
	assert(_shell.sim.treasury.money == money, "Map orders use existing monthly billing")
	await _capture("preparation-team-orders")
	await _press_button("YARDIM HAZIRLA")
	var marker: Button = _shell.map_view._marker_nodes["plan:1"]
	await _click(marker.get_global_rect().get_center())
	assert(_shell.sim.preparation_plan().summary.queued_count == 3)
	var row: Dictionary = panel._rows[1]
	await _click(row.undo.get_global_rect().get_center())
	assert(_shell.sim.preparation_plan().summary.queued_count == 2)
	assert(_shell.sim.projects.projects.back().status == "cancelled")
	assert(panel.action_id == "aid_stock")
	var row_id: int = row.title.get_instance_id()
	panel._scroll.scroll_vertical = 1600
	var focus: Button = panel._actions.aid_stock
	focus.grab_focus()
	var scroll: int = panel._scroll.scroll_vertical
	_shell.sim.changed.emit()
	await process_frame
	await process_frame
	assert(panel._rows[1].title.get_instance_id() == row_id)
	assert(panel._scroll.scroll_vertical == scroll and root.gui_get_focus_owner() == focus)
	assert(_shell.map_view._marker_nodes["plan:1"] == marker)
	await _capture("preparation-scrolled")
	panel._scroll.scroll_vertical = 0
	var before: int = _shell.sim.projects.projects.size()
	var origin: Vector2 = _shell.map_view._map_image.position
	await _pan(points[6], points[6] + Vector2(40, 20))
	assert(_shell.map_view._map_image.position != origin)
	assert(not _shell.map_view._map_image.has_node("TerrainDetails"))
	assert(_shell.sim.projects.projects.size() == before, "Panning must not enqueue")
	await _check_map_toolbar()
	await _key(KEY_ESCAPE)
	assert(not panel.visible and panel.action_id.is_empty())
	assert(_shell.open_screen == "pause")
	await _key(KEY_ESCAPE)
	assert(_shell.open_screen.is_empty())
	await _capture("plain-map-overview")
	await _click(points[31])
	assert(_shell.city_panel.visible and _shell.selected_area_id == 31)
	await _press_button("EKİP VE YARDIM HAZIRLA")
	assert(panel.visible and panel.action_id.is_empty() and not _shell.city_panel.visible)
	await _press_button("YARDIM HAZIRLA")
	await _press_button("YATIRIM VE ARAŞTIRMA")
	assert(not panel.visible and panel.action_id.is_empty())
	await _capture("preparation-project-tracker")
	var paused := _find_button(_shell._modal, "DURAKLAT")
	assert(paused != null)
	var queued_count := 0
	for project_row: Control in _shell._screen_content.get_node("ProjectList/Rows").get_children():
		var project: ActiveProject = _shell.sim.projects.get_project(
			String(project_row.name).trim_prefix("Project").to_int()
		)
		assert(project_row.get_node("Pause").disabled == (project.status == "queued"))
		if project.status == "queued":
			queued_count += 1
	assert(queued_count > 0, "Queued orders remain visible in the scroll list")
	await _capture("preparation-queued-projects")
	_shell.close_screen()
	await _press_button("EKİP VE YARDIM HAZIRLA")
	await _press_button("YARDIM HAZIRLA")
	# A pending newspaper exits stamping before another click can create an order.
	_shell.sim.advance_to(CalendarClock.date_to_day("1951-04-08"))
	await process_frame
	await process_frame
	assert(_shell.open_screen == "newspaper" and not panel.visible)
	before = _shell.sim.projects.projects.size()
	await _click(points[6])
	assert(_shell.sim.projects.projects.size() == before)
	_shell.acknowledge_news()
	_shell.close_screen()
	await process_frame
	await _check_map_legend()
	await _shell.audio.shutdown()
	_main.queue_free()
	await process_frame
	print(
		"PREPARATION_UI_PASS: palette, repeat/parallel/busy orders, undo, persistent focus/scroll/markers, plain map toolbar/modes/legends/hover/pan/zoom, escape and modal exit"
	)
	quit()


func _check_map_toolbar() -> void:
	var map: Control = _shell.map_view
	var before: int = _shell.sim.projects.projects.size()
	var toolbar: Panel = map.get_node("MapToolbar")
	var first: Button = map._layer_buttons[0]
	assert(toolbar.position == Vector2(16, 1030) and toolbar.size == Vector2(640, 42))
	assert(not map.tools_expanded and not first.is_visible_in_tree())
	assert(not map._legend_panel.is_visible_in_tree())
	assert(not toolbar.get_global_rect().intersects(_shell.preparation_panel.get_global_rect()))
	await _capture("map-controls-collapsed")
	var notice: String = _shell._status.text
	var notice_tooltip: String = _shell._status.get_meta("hint", "")
	await _click(map._tools_toggle.get_global_rect().get_center())
	assert(map.tools_expanded and toolbar.size == Vector2(1478, 42))
	assert(first.is_visible_in_tree() and map._legend_panel.is_visible_in_tree())
	assert(not toolbar.get_global_rect().intersects(_shell._status_panel.get_global_rect()))
	assert(
		not map._legend_panel.get_global_rect().intersects(
			_shell.preparation_panel.get_global_rect()
		)
	)
	assert(_shell._status.text == notice and _shell._status.get_meta("hint", "") == notice_tooltip)
	await _capture("map-controls-expanded")
	assert(not map._map_image.has_node("TerrainDetails"))
	assert(map._heatmap.get_index() < map._selection.get_index())
	await _press_button("GÖRÜNÜMÜ SIFIRLA")
	assert(map._zoom == 1 and map._zoom_out.disabled and not map._zoom_in.disabled)
	assert(map._zoom_label.text == "1×")
	await _click(map._zoom_out.get_global_rect().get_center())
	assert(map._zoom == 1)
	for index in range(4):
		await _click(map._layer_buttons[index].get_global_rect().get_center())
		assert(map.selected_overlay == index)
		assert(not map._map_image.has_node("TerrainDetails"))
		for selected in range(4):
			assert(map._layer_buttons[selected].button_pressed == (selected == index))
		# Clicking the active mode again must leave one mode selected.
		await _click(map._layer_buttons[index].get_global_rect().get_center())
		assert(map._layer_buttons[index].button_pressed)
		await _capture("map-toolbar-mode-%d" % index)
	await _click(toolbar.global_position + Vector2(624, 22))
	await _click(map._legend_panel.global_position + Vector2(4, 4))
	var camera_before: Vector2 = map._map_image.position
	var gutter: Vector2 = toolbar.global_position + Vector2(624, 22)
	await _pan(gutter, gutter + Vector2(30, 0))
	assert(map._map_image.position == camera_before, "Dragging map controls must not pan the map")
	for zoom in [2, 3]:
		await _click(map._zoom_in.get_global_rect().get_center())
		assert(map._zoom == zoom and map._zoom_label.text == "%d×" % zoom)
	assert(map._zoom_in.disabled and not map._zoom_out.disabled)
	await _click(map._zoom_in.get_global_rect().get_center())
	assert(map._zoom == 3)
	await _capture("map-toolbar-zoom-max")
	await _click(map._zoom_out.get_global_rect().get_center())
	assert(map._zoom == 2 and not map._zoom_in.disabled)
	await _press_button("GÖRÜNÜMÜ SIFIRLA")
	assert(map._map_image.position == map.DEFAULT_ORIGIN and map._zoom_out.disabled)
	for zoom in [2, 3, 3]:
		await _wheel(Vector2(1100, 600), MOUSE_BUTTON_WHEEL_UP)
		assert(map._zoom == zoom and map._zoom_label.text == "%d×" % zoom)
	await _wheel(Vector2(1100, 600), MOUSE_BUTTON_WHEEL_DOWN)
	assert(map._zoom == 2 and not map._zoom_in.disabled)
	await _press_button("GÖRÜNÜMÜ SIFIRLA")
	await _wheel(Vector2(1100, 600), MOUSE_BUTTON_WHEEL_DOWN)
	assert(map._zoom == 1 and map._zoom_out.disabled)
	assert(_shell.sim.projects.projects.size() == before, "Toolbar/wheel must not enqueue")
	_shell.sim.changed.emit()
	await process_frame
	assert(map.get_node("MapToolbar") == toolbar and map._layer_buttons[0] == first)
	assert(not map._map_image.has_node("TerrainDetails"))
	assert(map.selected_overlay == 3 and map._layer_buttons[3].button_pressed)
	await _click(map._tools_toggle.get_global_rect().get_center())
	assert(not map.tools_expanded and not first.is_visible_in_tree())
	assert(map._tools_toggle.text == "HARİTA GÖRÜNÜMÜ" and map.selected_overlay == 3)
	assert(not toolbar.get_global_rect().intersects(_shell._status_panel.get_global_rect()))
	assert(_shell._status_panel.position.x == 672)
	_shell.sim.changed.emit()
	await process_frame
	assert(not map.tools_expanded and map._tools_toggle.has_focus())
	await _click(map._tools_toggle.get_global_rect().get_center())
	assert(map.tools_expanded and map._layer_buttons[3].button_pressed)
	await _press_button("BÖLGELER")
	await _capture("map-toolbar-reset")
	await _capture("plain-map-general-native")
	for zoom in [2, 3]:
		await _wheel(Vector2(1100, 600), MOUSE_BUTTON_WHEEL_UP)
		assert(not map._map_image.has_node("TerrainDetails") and map._zoom == zoom)
		assert(map._map_image.get_global_transform().get_scale() == Vector2.ONE * zoom)
		await _capture("plain-map-zoom-%d" % zoom)
	await _press_button("GÖRÜNÜMÜ SIFIRLA")
	await _click(map._tools_toggle.get_global_rect().get_center())
	assert(not map.tools_expanded and map.selected_overlay == 0 and map._zoom == 1)


func _check_map_legend() -> void:
	var map: Control = _shell.map_view
	assert(not map.tools_expanded)
	await _click(map._tools_toggle.get_global_rect().get_center())
	assert(map.tools_expanded)
	var points := _map_points()
	var toolbar: Panel = map.get_node("MapToolbar")
	var description: Label = map._legend_description
	var readout: Label = map._legend_readout
	# Dummy headless rendering does not upload ImageTexture.update() changes.
	var native_palette := DisplayServer.get_name() != "headless"
	assert(map._region_labels.size() == 7 and map._region_swatches.size() == 7)
	assert(map._legend_values.size() == 3 and map._legend_swatches.size() == 3)
	assert(map._crisis_key.text == "! KIRMIZI / AKTİF AFET")
	_check_palette_color(map._crisis_swatch.color, map.CRISIS_COLOR)
	for mode in range(4):
		await _click(map._layer_buttons[mode].get_global_rect().get_center())
		if native_palette:
			var mode_palette: Image = map._palette.get_image()
			for crisis: Dictionary in _shell.sim.crises.active:
				_check_palette_color(
					mode_palette.get_pixel(int(crisis.area_id), 0), map.CRISIS_COLOR
				)
			for id: int in [1, 6]:
				if mode == 0:
					assert(mode_palette.get_pixel(id, 0).a == 0.0)
				else:
					_check_palette_color(
						mode_palette.get_pixel(id, 0),
						map._data_color(map._overlay_data.areas[id].ratio)
					)
		assert(description.is_visible_in_tree() == (mode > 0))
		if mode > 0:
			assert(not description.text.is_empty())
		for index in range(7):
			assert(map._region_labels[index].is_visible_in_tree() == (mode == 0))
			assert(map._region_swatches[index].is_visible_in_tree() == (mode == 0))
		for index in range(3):
			assert(map._legend_values[index].is_visible_in_tree() == (mode > 0))
			assert(map._legend_swatches[index].is_visible_in_tree() == (mode > 0))
			if mode > 0:
				assert(not map._legend_values[index].text.is_empty())
				assert(
					(
						map._legend_swatches[index].color.to_rgba32()
						== map._data_color(float(index) / 2.0).to_rgba32()
					)
				)
		if mode == 0:
			for area: ServiceArea in _shell.sim.areas.values():
				var found := false
				for label: Label in map._region_labels:
					found = found or label.text == area.region.to_upper()
				assert(found, "Every geographic region needs a named color key: " + area.region)
		await _capture("map-legend-mode-%d" % mode)
	# These values are confined to the final fixture section; no later gameplay uses them.
	_shell.sim.areas[1].stock = 0
	_shell.sim.areas[6].stock = 80
	_shell.sim.areas[31].stock = 240
	await _press_button("YARDIM MALZEMESİ")
	_shell.sim.changed.emit()
	await process_frame
	await process_frame
	var palette: Image = map._palette.get_image()
	for index in range(2) if native_palette else []:
		var id: int = [1, 6][index]
		_check_palette_color(palette.get_pixel(id, 0), map._legend_swatches[index].color)
	if native_palette:
		_check_palette_color(palette.get_pixel(31, 0), map.CRISIS_COLOR)
	assert(map._legend_values[2].text.contains("160+"))
	var focus: Button = map._layer_buttons[2]
	focus.grab_focus()
	var hint: String = readout.text
	await _hover(points[31])
	assert(readout.text.contains(_shell.sim.areas[31].name.to_upper()))
	assert(readout.text.contains("240"), "Saturated stock colors must retain the actual inventory")
	assert(root.gui_get_focus_owner() == focus)
	var selected: int = _shell.selected_area_id
	_shell.sim.changed.emit()
	await process_frame
	assert(map._legend_description == description and map._legend_readout == readout)
	assert(readout.text.contains("240") and root.gui_get_focus_owner() == focus)
	await _capture("map-legend-stock-hover")
	await _hover(toolbar.global_position + Vector2(240, 22))
	assert(readout.text == hint and _shell.selected_area_id == selected)
	assert(root.gui_get_focus_owner() == focus)
	_shell.sim.areas[1].stock = 80
	_shell.sim.changed.emit()
	await process_frame
	palette = map._palette.get_image()
	assert(_shell.sim.areas[1].region != _shell.sim.areas[6].region)
	if native_palette:
		assert(palette.get_pixel(1, 0) == palette.get_pixel(6, 0))
	_shell.sim.areas[1].damage = 0.0
	_shell.sim.areas[6].damage = 100.0
	_shell.sim.areas[31].damage = 100.0
	await _press_button("ALTYAPI HASARI")
	_shell.sim.changed.emit()
	await process_frame
	await process_frame
	palette = map._palette.get_image()
	if native_palette:
		_check_palette_color(palette.get_pixel(1, 0), map._legend_swatches[0].color)
		_check_palette_color(palette.get_pixel(6, 0), map._legend_swatches[2].color)
		_check_palette_color(palette.get_pixel(31, 0), map.CRISIS_COLOR)
	var crisis: Dictionary = _shell.sim.crises.active.front()
	var marker: Button = map._marker_nodes["crisis:" + crisis.id]
	assert(marker.is_visible_in_tree() and marker.text == "!")
	assert(map._crisis_key.is_visible_in_tree() and map._crisis_swatch.is_visible_in_tree())
	await _hover(points[31])
	assert(
		readout.text.contains(_shell.sim.areas[31].name.to_upper()) and readout.text.contains("100")
	)
	await _capture("map-legend-damage-crisis")


func _check_palette_color(actual: Color, expected: Color) -> void:
	assert(actual.a == 1.0 and expected.a == 1.0)
	# The RGBA8 texture quantizes the swatch's floating point color.
	for channel in range(4):
		assert(absf(actual[channel] - expected[channel]) <= 1.0 / 255.0 + 0.00001)


func _hover(point: Vector2) -> void:
	root.warp_mouse(point)
	var event := InputEventMouseMotion.new()
	event.position = point
	event.global_position = point
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	await process_frame
	await process_frame


func _wheel(point: Vector2, button: MouseButton) -> void:
	root.warp_mouse(point)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = button
		event.position = point
		event.global_position = point
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
	await process_frame
	await process_frame


func _map_points() -> Dictionary:
	var points: Dictionary = {}
	var hit: Image = _shell.map_view._hit_image
	for y in range(300, 1400, 3):
		for x in range(800, 2500, 3):
			var id := roundi(hit.get_pixel(x, y).r * 255.0)
			if id > 0 and not points.has(id):
				var point := Vector2(x, y) + _shell.map_view._map_image.position
				if Rect2(440, 230, 1450, 620).has_point(point):
					points[id] = point
	return points


func _pan(from: Vector2, to: Vector2) -> void:
	_mouse(from, true)
	var motion := InputEventMouseMotion.new()
	motion.position = to
	motion.global_position = to
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	motion.relative = to - from
	Input.parse_input_event(motion)
	Input.flush_buffered_events()
	_mouse(to, false)
	await process_frame
	await process_frame


func _key(code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
	await process_frame
	await process_frame
