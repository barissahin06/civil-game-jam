extends "res://tests/integration/gameplay_ui.gd"
## Fleet navigation and dispatch use real input without player save I/O.


func _run() -> void:
	capture_screens = "--capture" in OS.get_cmdline_user_args()
	root.size = Vector2i(1920, 1080)
	root.content_scale_size = root.size
	root.gui_embed_subwindows = true
	_main = load("res://ui_preview/scenes/main_preview.tscn").instantiate()
	root.add_child(_main)
	await process_frame
	_shell = _main
	_shell.auto_save_enabled = false
	_shell.sim.tutorial_enabled = false
	await _press_button("BİRLİKLER")
	assert(_shell.open_screen == "units" and _shell.units_panel._rows.size() == 21)
	var panel: Control = _shell.units_panel
	for row: Dictionary in panel._rows.values():
		assert(row.dispatch.disabled and row.dispatch.tooltip_text.contains("aktif kriz"))
	_check_toolbar_clear()
	assert(not _shell.map_view.tools_expanded)
	await _click(_shell.map_view._tools_toggle.get_global_rect().get_center())
	assert(_shell.map_view.tools_expanded)
	_check_toolbar_clear()
	await _click(_shell.map_view._layer_buttons[2].get_global_rect().get_center())
	assert(_shell.map_view.selected_overlay == 2, "Units panel must leave map tools accessible")
	await _capture("units-overview")
	await _row_click(31, "center")
	assert(_shell.open_screen.is_empty() and _shell.city_panel.visible)
	assert(_shell.selected_area_id == 31 and _shell.city_panel.selected_tab == 2)
	_shell.sim.advance_to(CalendarClock.date_to_day("1951-04-08"))
	await process_frame
	await process_frame
	assert(_shell.open_screen == "newspaper")
	await _press_button("KRİZ MERKEZİNE GEÇ")
	assert(_shell.sim.news_queue.is_empty())
	_shell.close_screen()
	await _press_button("BİRLİKLER")
	await _row_click(31, "dispatch")
	assert(_shell.open_screen == "crisis" and _shell.crisis.source_id == 31)
	await _press_button("1 EKİP GÖNDER")
	assert(_shell.sim.areas[31].teams == 0)
	_shell.close_screen()
	await _press_button("BİRLİKLER")
	await _row_click(1, "dispatch")
	assert(_shell.crisis.source_id == 1)
	await _press_button("1 EKİP GÖNDER")
	await _press_button("10 YARDIM GÖNDER")
	_shell.close_screen()
	await _press_button("BİRLİKLER")
	panel = _shell.units_panel
	assert(panel._summary.text == "HAZIR / TOPLAM EKİP: 19 / 21")
	assert(panel._movements.text == "YOLDA 1 / GÖREVDE 1 / DÖNÜŞ 0")
	assert(panel._rows[1].ready.text == "HAZIR 0 / TOPLAM 1")
	assert(panel._rows[31].movement.text == "YOLDA 0 / GÖREVDE 1 / DÖNÜŞ 0")
	assert(panel._rows[1].stock.text == "YARDIM STOĞU: 30")
	await _focus_row(31, "center")
	var title_id: int = panel._rows[31].title.get_instance_id()
	var scroll: int = panel._scroll.scroll_vertical
	var focus: Button = panel._rows[31].center
	_shell.sim.changed.emit()
	await process_frame
	await process_frame
	assert(_shell.units_panel == panel and panel._rows[31].title.get_instance_id() == title_id)
	assert(scroll > 0 and panel._scroll.scroll_vertical == scroll)
	assert(root.gui_get_focus_owner() == focus)
	_check_toolbar_clear()
	await _capture("units-mobilized")
	await _key(KEY_ESCAPE)
	assert(_shell.open_screen == "pause")
	await _key(KEY_ESCAPE)
	assert(_shell.open_screen == "units")
	# A second target must be chosen explicitly while retaining the clicked center.
	_shell.sim.crises.begin(_shell.sim.historical.events[1])
	_shell.sim.changed.emit()
	await process_frame
	await _row_click(6, "dispatch")
	assert(_shell.crisis.source_id == 6 and _shell.crisis.require_target_selection)
	assert(_shell.crisis._panel._send.disabled and _shell.crisis._panel._quick_team.disabled)
	var picker: OptionButton = _shell.crisis._panel._target
	await _click(picker.get_global_rect().get_center())
	assert(picker.get_popup().visible)
	await _key(KEY_UP, picker.get_popup())
	await _key(KEY_ENTER, picker.get_popup())
	assert(not _shell.crisis.require_target_selection and _shell.crisis.source_id == 6)
	var selected: String = _shell.crisis.selected().id
	_shell.sim.changed.emit()
	await process_frame
	await process_frame
	assert(_shell.crisis.source_id == 6 and _shell.crisis.selected().id == selected)
	await _capture("units-parallel-dispatch")
	_main.queue_free()
	await process_frame
	print(
		"UNITS_UI_PASS: direct fleet access, source centers, quick dispatch, live counts, stable scroll/focus, map tools, parallel target and Escape"
	)
	quit()


func _check_toolbar_clear() -> void:
	var toolbar: Control = _shell.map_view.get_node("MapToolbar")
	var frame: Control = _shell._modal.get_child(0)
	assert(not toolbar.get_global_rect().intersects(frame.get_global_rect()))
	assert(toolbar.is_visible_in_tree())
	if _shell.map_view.tools_expanded:
		assert(
			not _shell.map_view._legend_panel.get_global_rect().intersects(frame.get_global_rect())
		)
	assert(not toolbar.get_global_rect().intersects(_shell._status_panel.get_global_rect()))


func _focus_row(id: int, action: String) -> void:
	var panel: Control = _shell.units_panel
	var button: Button = panel._rows[id][action]
	panel._scroll.ensure_control_visible(button.get_parent() as Control)
	await process_frame
	await process_frame
	button.grab_focus()
	assert(panel._scroll.get_global_rect().encloses(button.get_global_rect()))


func _row_click(id: int, action: String) -> void:
	await _focus_row(id, action)
	var button: Button = _shell.units_panel._rows[id][action]
	assert(not button.disabled)
	await _click(button.get_global_rect().get_center())


func _key(code: Key, window: Window = null) -> void:
	if window == null:
		window = root
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		event.window_id = window.get_window_id()
		Input.parse_input_event(event)
		Input.flush_buffered_events()
	await process_frame
	await process_frame
