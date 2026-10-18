extends "res://tests/integration/gameplay_ui.gd"
## Actual input for transfer, guest ownership and the supply warning route.


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	root.content_scale_size = root.size
	root.gui_embed_subwindows = true
	_main = load("res://ui_preview/scenes/main_preview.tscn").instantiate()
	root.add_child(_main)
	await process_frame
	_shell = _main
	_shell.auto_save_enabled = false
	_shell.sim.tutorial_enabled = false
	await _press_button("EKİPLER VE YARDIM")
	var panel: Control = _shell.units_panel
	await _choose_group(panel._source, 6, 6)
	await _choose_center(panel._target, 31)
	var money := _shell.sim.treasury.money
	var quote: Dictionary = _shell.sim.transfer_preview(6, 31, "team", 1, 6)
	assert(
		(
			not panel._transfer.disabled
			and panel._quote.text.contains(_shell.fmt_money(int(quote.fee)))
		)
	)
	assert(_shell.sim.treasury.money == money and _shell.sim.logistics.shipments.is_empty())
	panel._transfer.grab_focus()
	var identity: int = panel._source.get_instance_id()
	_shell.sim.changed.emit()
	await process_frame
	await process_frame
	assert(
		(
			panel._source.get_instance_id() == identity
			and root.gui_get_focus_owner() == panel._transfer
		)
	)
	await _click(panel._transfer.get_global_rect().get_center())
	assert(_shell.sim.areas[6].teams == 0)
	assert(_shell.sim.treasury.money == money - int(quote.fee))
	_shell.sim.advance_to(_shell.sim.clock.day + 3)
	await process_frame
	await process_frame
	await _choose_group(panel._source, 31, 6)
	assert(not panel._recall.disabled and panel._source.text.contains("ÜS ANKARA"))
	assert(_shell.sim.logistics.available_teams(31, 6) == 1)
	await _save_capture("units")
	await _click(panel._recall.get_global_rect().get_center())
	assert(_shell.sim.logistics.available_teams(31, 6) == 0)
	_shell.sim.advance_to(_shell.sim.clock.day + 3)
	await process_frame
	await process_frame
	assert(_shell.sim.areas[6].teams == 1)
	await _choose_group(panel._source, 6, 6)
	await _click(panel._transfer.get_global_rect().get_center())
	_shell.sim.advance_to(_shell.sim.clock.day + 3)
	assert(_shell.sim.transfer_resources(34, 31, "team", 1).ok)
	_shell.sim.advance_to(_shell.sim.clock.day + 3)
	_shell.sim.advance_to(CalendarClock.date_to_day("1951-04-08"))
	await process_frame
	await process_frame
	assert(_shell.open_screen == "newspaper")
	var id: String = _shell.sim.crises.active.front().id
	_shell.sim.supply_warning_requested.emit(id)
	await process_frame
	assert(_shell.open_screen == "newspaper", "A supply warning must wait for required news")
	await _press_button("HABERİ OKUDUM")
	await process_frame
	await process_frame
	assert(_shell.open_screen == "crisis" and _shell.crisis.selected().id == id)
	var dispatch: Control = _shell.crisis._panel
	await _choose_group(dispatch._source, 31, 6)
	assert(_shell.crisis.source_id == 31 and _shell.crisis.source_home == 6)
	await _click(dispatch._send.get_global_rect().get_center())
	assert(_shell.sim.logistics.shipments.back().home == 6)
	assert(_shell.sim.logistics.shipments.back().state == "deployed")
	await _choose_group(dispatch._source, 31, 34)
	var point: Vector2 = (
		_shell.map_view._markers.get_global_transform()
		* _shell.map_view._native_point(_shell.sim.areas[31])
	)
	await _drag(dispatch._team.get_global_rect().get_center(), point)
	var guest_mission: Dictionary = _shell.sim.logistics.shipments.back()
	assert(guest_mission.home == 34 and guest_mission.state == "deployed")
	assert(_shell.sim.areas[31].teams == 1, "Map drop must use the selected guest group")
	await _press_button("MALZEME SEÇ")
	await _choose_group(dispatch._source, 31, 31)
	await _click(dispatch._send.get_global_rect().get_center())
	_shell.sim.set_paused(false)
	_shell.sim.advance_to(_shell.sim.clock.day + 1)
	await process_frame
	await process_frame
	assert(_shell.sim.paused and _shell.open_screen == "crisis")
	assert(_shell.sim.crises.get_crisis(id).supply_alerted)
	assert(_shell.sim.crises.get_crisis(id).consumed_stock == 10)
	assert(_shell.sim.dispatch(6, id, "stock", 10).ok)
	await process_frame
	await process_frame
	dispatch = _shell.crisis._panel
	var feedback := _shell.sim.crisis_feedback(id)
	assert(dispatch._labels.stock.text.contains("%d BİRİM/GÜN" % feedback.stock.daily))
	assert(
		dispatch._labels.stock.text.contains(
			CalendarClock.day_to_iso(int(feedback.stock.first_shortage_day))
		)
	)
	assert(dispatch._labels.stock.tooltip_text.contains("10 birim"))
	assert(_shell.crisis.source_id == 31)
	await _save_capture("crisis")
	var crisis: Dictionary = _shell.sim.crises.get_crisis(id)
	_shell.sim.advance_to(int(crisis.start) + int(crisis.window))
	await process_frame
	await process_frame
	assert(guest_mission.state == "returning")
	var movement: Dictionary = _shell.map_view._shipment_nodes[int(guest_mission.id)]
	assert(movement.destination == _shell.map_view._native_point(_shell.sim.areas[34]))
	assert(movement.origin == _shell.map_view._native_point(_shell.sim.areas[31]))
	await _shell.audio.shutdown()
	_main.queue_free()
	await process_frame
	print(
		"MICROMANAGEMENT_UI_PASS: transfer, guest home, recall, native map drop, home return route, stable focus, daily supply and warning/news priority"
	)
	quit()


func _choose_group(picker: OptionButton, source: int, home: int) -> void:
	for index in range(picker.item_count):
		var group: Dictionary = picker.get_item_metadata(index)
		if int(group.source) == source and int(group.home) == home:
			await _choose_index(picker, index)
			return
	assert(false, "Missing source/home group %d/%d" % [source, home])


func _choose_center(picker: OptionButton, area_id: int) -> void:
	for index in range(picker.item_count):
		if int(picker.get_item_metadata(index)) == area_id:
			await _choose_index(picker, index)
			return
	assert(false, "Missing target center")


func _choose_index(picker: OptionButton, index: int) -> void:
	await _click(picker.get_global_rect().get_center())
	assert(picker.get_popup().visible)
	for step in range(picker.item_count + 1):
		if picker.get_popup().get_focused_item() == index:
			break
		await _key(KEY_DOWN, picker.get_popup())
	assert(picker.get_popup().get_focused_item() == index)
	await _key(KEY_ENTER, picker.get_popup())
	assert(not picker.get_popup().visible and picker.selected == index)


func _key(code: Key, window: Window = null) -> void:
	if window == null:
		window = root
	for pressed: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		event.window_id = window.get_window_id()
		Input.parse_input_event(event)
		Input.flush_buffered_events()
	await process_frame
	await process_frame


func _save_capture(label: String) -> void:
	if not capture_screens:
		return
	await process_frame
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(
		"res://../generated/micromanagement-ui/" + label + ".png"
	)
	assert(DirAccess.make_dir_recursive_absolute(path.get_base_dir()) == OK)
	assert(root.get_texture().get_image().save_png(path) == OK)
