extends "res://tests/integration/gameplay_ui.gd"
## Isolated authored first-crisis walkthrough. --review exposes A/B controls only here.

var _review: bool = false


func _run() -> void:
	_review = "--review" in OS.get_cmdline_user_args()
	capture_screens = "--capture" in OS.get_cmdline_user_args()
	var motion := "--motion" in OS.get_cmdline_user_args()
	root.size = Vector2i(1920, 1080)
	root.content_scale_size = root.size
	root.gui_embed_subwindows = true
	# Opening is covered by startup/gameplay_ui; this fixture starts at the decision surface.
	_main = load("res://ui_preview/scenes/main_preview.tscn").instantiate()
	root.add_child(_main)
	await process_frame
	_shell = _main
	_shell.auto_save_enabled = false
	_seed()
	if motion:
		await _motion()
		return
	if _review:
		_review_controls()
		return
	await _check_crisis_map_feedback()
	await _capture("pilot-a-waiting")
	_check_dispatch_header()
	var panel: Control = _shell.crisis._panel
	var panel_id := panel.get_instance_id()
	panel._send.grab_focus()
	_shell.sim.changed.emit()
	await process_frame
	await process_frame
	assert(panel.get_instance_id() == panel_id and root.gui_get_focus_owner() == panel._send)
	_shell.crisis.operation_scene_enabled = true
	_shell.refresh_screen()
	await _capture("pilot-b-waiting")
	# Actual city shortcut opens the same source, then direct quick dispatch reserves once.
	_shell.close_screen()
	_shell.select_area(1)
	_shell.city_panel.select_tab(2)
	await _press_button("BU MERKEZDEN GÖNDER")
	assert(_shell.crisis.source_id == 1)
	var target: Dictionary = _shell.crisis.selected()
	var before := _shell.sim.treasury.money
	var quote := _shell.sim.dispatch_preview(1, target.id, "team", 1)
	await _press_button("1 EKİP GÖNDER")
	assert(_shell.sim.areas[1].teams == 0)
	assert(_shell.sim.treasury.money == before - int(quote.fee))
	assert(_shell.crisis._panel._quick_team.disabled)
	assert(_shell.sim.crisis_feedback(target.id).teams.on_time == 1)
	await _capture("pilot-outbound")
	_shell.close_screen()
	_shell.select_area(31)
	_shell.city_panel.select_tab(2)
	await _press_button("BU MERKEZDEN GÖNDER")
	await _press_button("1 EKİP GÖNDER")
	assert(_shell.sim.crisis_feedback(target.id).teams.missing == 0)
	await _capture("pilot-b-rescue")
	await _press_button("10 YARDIM GÖNDER")
	await _capture("pilot-b-aid")
	await _press_button("YARDIM SEÇ")
	var shipment_count := _shell.sim.logistics.shipments.size()
	await _press_button("EKSİK KADAR SEÇ")
	assert(_shell.crisis.amount == 30)
	assert(_shell.sim.logistics.shipments.size() == shipment_count, "Fill must not spend")
	await _press_button("SEVK ET")
	assert(_shell.sim.crisis_feedback(target.id).stock.missing == 0)
	assert(_shell.crisis._panel._quick_stock.disabled)
	# Refresh does not replay arrivals, replace nodes, or lose the chosen source.
	var ticker_count := _shell.sim.ticker.size()
	panel = _shell.crisis._panel
	panel_id = panel.get_instance_id()
	for index in range(3):
		_shell.refresh_screen()
	assert(_shell.crisis._panel.get_instance_id() == panel_id)
	assert(_shell.crisis.source_id == 31 and _shell.sim.ticker.size() == ticker_count)
	var phase: float = panel._operation._phase
	var convoy_position: Vector2 = _shell.map_view._shipment_nodes[1].icon.position
	await create_timer(0.1).timeout
	assert(panel._operation._phase == phase, "Paused work poses must freeze")
	for speed in [1, 2, 4]:
		_shell.sim.set_speed(speed)
		_shell.sim.set_paused(false)
		await create_timer(0.12).timeout
		_shell.sim.set_paused(true)
		assert(panel._operation._phase > phase)
		assert(
			_shell.map_view._shipment_nodes[1].icon.position != convoy_position,
			"Travel must move within a response day"
		)
		convoy_position = _shell.map_view._shipment_nodes[1].icon.position
		phase = panel._operation._phase
	var marker: Node = _shell.map_view._marker_nodes["crisis:" + target.id]
	_shell.sim.advance_to(int(target.start) + 1)
	await process_frame
	await process_frame
	assert(_shell.map_view._marker_nodes["crisis:" + target.id] == marker)
	assert(_shell.sim.crisis_feedback(target.id).teams.field == 2)
	var deployed: Dictionary = _shell.map_view._shipment_nodes[1]
	assert(deployed.icon.position == deployed.target, "Paused arrival must show the target")
	assert(
		_shell.sim.ticker.any(
			func(item: String) -> bool: return item.contains("eksik: 0 ekip, 0 yardım")
		)
	)
	await _capture("pilot-arrival")
	_shell.sim.advance_to(int(target.start) + int(target.window))
	await process_frame
	await process_frame
	assert(_shell.open_screen == "report")
	_check_resolved_palette(int(target.area_id))
	await _capture("pilot-report")
	await _press_button("ONARIMI İNCELE")
	await _press_button("BAŞLAT")
	_shell.close_screen()
	_shell.show_screen("crisis")
	assert(_shell.crisis._panel._fund.disabled, "Resolved crises must not offer budget support")
	await _capture("pilot-b-recovery")
	_shell.sim.advance_to(CalendarClock.date_to_day("1951-10-01"))
	await process_frame
	await process_frame
	assert(_shell.sim.areas[31].damage == 0.0)
	assert(_shell.map_view._recovery_notices.has(31))
	await _capture("pilot-b-restored")
	# Parallel targets require an explicit choice and retain the city's source.
	_seed()
	_shell.sim.crises.begin(_shell.sim.historical.events[1])
	_shell.show_dispatch(6)
	assert(_shell.crisis.require_target_selection)
	assert(_shell.crisis._panel._send.disabled)
	assert(_shell.crisis._panel._fund.disabled, "Budget support needs an explicit crisis target")
	var picker: OptionButton = _shell.crisis._panel._target
	await _click(picker.get_global_rect().get_center())
	assert(picker.get_popup().visible, "Target popup must open from real mouse input")
	await _key(KEY_UP, picker.get_popup())
	await _key(KEY_ENTER, picker.get_popup())
	assert(not _shell.crisis.require_target_selection and _shell.crisis.source_id == 6)
	var source_picker: OptionButton = _shell.crisis._panel._source
	await _click(source_picker.get_global_rect().get_center())
	assert(source_picker.get_popup().visible)
	await _key(KEY_UP, source_picker.get_popup())
	await _key(KEY_ENTER, source_picker.get_popup())
	var chosen_source: int = _shell.crisis.source_id
	assert(chosen_source != 6, "Source popup must accept real input")
	_shell.sim.changed.emit()
	await process_frame
	await process_frame
	assert(_shell.crisis.source_id == chosen_source)
	var chosen_target: String = _shell.crisis.selected().id
	_check_dispatch_header()
	await _press_button("ACİL BÜTÇE")
	assert(_shell.open_screen == "fund", "Budget button must open support, not close the panel")
	await _capture("pilot-emergency-budget")
	await _press_button("KRİZE DÖN")
	assert(_shell.open_screen == "crisis")
	assert(
		_shell.crisis.selected().id == chosen_target and _shell.crisis.source_id == chosen_source
	)
	_check_dispatch_header()
	var other: Dictionary = _shell.sim.crises.active.front()
	assert(_shell.crisis.selected().id != other.id)
	var other_marker: Button = _shell.map_view._marker_nodes["crisis:" + other.id]
	await _click(other_marker.get_global_rect().get_center())
	assert(_shell.crisis.selected().id == other.id and _shell.crisis.source_id == chosen_source)
	await _capture("pilot-parallel")
	_main.queue_free()
	await process_frame
	print(
		"CRISIS_PILOT_PASS: red active-crisis palette and restoration, synchronized HUD/map shake, aligned budget header, fund navigation, quick dispatch, fill, source context, parallel targets, persistent focus/markers, A/B poses, 1/2/4x, report, repair"
	)
	quit()


func _check_crisis_map_feedback() -> void:
	var map := _shell.map_view
	map.set_process(false)
	var camera := map._map_image.position
	var toolbar := map._toolbar.global_position
	var panel := _shell.crisis._panel.global_position
	map._process(0.04)
	assert(map._map_clip.position != Vector2.ZERO)
	assert(_shell.hud.position == map._map_clip.position)
	assert(map._map_image.position == camera)
	assert(map._toolbar.global_position == toolbar)
	assert(_shell.crisis._panel.global_position == panel)
	await _capture("pilot-crisis-hud-shake")
	map._process(map.FEEDBACK_SECONDS)
	assert(_shell.hud.position == Vector2.ZERO and map._map_clip.position == Vector2.ZERO)
	assert(map._crisis_flash.modulate.a == 0.0)
	if DisplayServer.get_name() == "headless":
		print("UI_CHECKPOINT: palette texture readback requires native rendering")
	var original: Array[Dictionary] = _shell.sim.crises.active.duplicate()
	var target: Dictionary = original.front()
	for mode: int in range(4):
		map.select_overlay(mode)
		_check_palette(int(target.area_id), map.CRISIS_COLOR)
		await _capture("pilot-crisis-red-" + ["regions", "preparedness", "stock", "damage"][mode])
	# Independent in-memory targets exercise overlapping crises without advancing the campaign.
	var same_area := target.duplicate(true)
	same_area.id += "-overlap"
	same_area.event_id += "-overlap"
	var parallel := target.duplicate(true)
	parallel.id += "-parallel"
	parallel.event_id += "-parallel"
	parallel.area_id = 1
	_shell.sim.crises.active.append(same_area)
	_shell.sim.crises.active.append(parallel)
	_shell.sim.crises.active.erase(target)
	map.refresh()
	_check_palette(int(target.area_id), map.CRISIS_COLOR)
	_check_palette(1, map.CRISIS_COLOR)
	_shell.sim.crises.active.erase(same_area)
	for mode: int in range(4):
		map.select_overlay(mode)
		_check_area_base_color(int(target.area_id))
		_check_palette(1, map.CRISIS_COLOR)
	_shell.sim.crises.active.clear()
	_check_resolved_palette(1)
	_shell.sim.crises.active = original
	map.select_overlay(0)
	assert(map._feedback_elapsed == map.FEEDBACK_SECONDS, "Palette refresh must not replay shake")
	await _capture("pilot-crisis-settled")
	map.set_process(true)


func _check_resolved_palette(area_id: int) -> void:
	for mode: int in range(4):
		_shell.map_view.select_overlay(mode)
		_check_area_base_color(area_id)
	_shell.map_view.select_overlay(0)


func _check_area_base_color(area_id: int) -> void:
	var map := _shell.map_view
	var expected := Color.TRANSPARENT
	if map.selected_overlay > 0:
		expected = map._data_color(float(map._overlay_data.areas[area_id].ratio))
	_check_palette(area_id, expected)


func _check_palette(area_id: int, expected: Color) -> void:
	# Dummy rendering does not retain ImageTexture.update pixels; native runs verify the palette.
	if DisplayServer.get_name() == "headless":
		return
	var actual := _shell.map_view._palette.get_image().get_pixel(area_id, 0)
	# RGBA8 texture storage quantizes interpolated colors by up to one channel step.
	for channel in range(4):
		assert(
			absf(actual[channel] - expected[channel]) <= 1.0 / 255.0 + 0.00001,
			(
				"Map palette area %d / mode %d: %s != %s"
				% [area_id, _shell.map_view.selected_overlay, actual, expected]
			)
		)


func _check_dispatch_header() -> void:
	var panel: Control = _shell.crisis._panel
	var heading: Rect2 = panel._labels.heading.get_global_rect()
	var budget: Rect2 = panel._fund.get_global_rect()
	var close: Rect2 = _find_button(_shell._modal, "KAPAT").get_global_rect()
	for box: Rect2 in [heading, budget, close]:
		assert(
			box.position.y == heading.position.y and box.size.y == 34,
			"Crisis header must align: heading=%s, budget=%s, close=%s" % [heading, budget, close]
		)
		assert(panel.get_global_rect().encloses(box), "Crisis header must fit its panel")
	assert(not heading.intersects(budget) and not heading.intersects(close))
	assert(not budget.intersects(close), "Budget and close must have separate mouse targets")
	assert(panel._target.get_global_rect().position.y >= budget.end.y)


func _seed() -> void:
	_shell.start_campaign(1950)
	_shell.sim.tutorial_enabled = false
	_shell.crisis.source_id = 0
	_shell.crisis.crisis_index = 0
	_shell.crisis.dispatch_kind = "team"
	_shell.crisis.amount = 1
	_shell.crisis.require_target_selection = false
	_shell.crisis._feedback = ""
	assert(_shell.sim.start_project("river_zoning", 31).ok)
	_shell.sim.advance_to(CalendarClock.date_to_day("1951-04-08"))
	assert(_shell.sim.projects.is_completed("river_zoning", 31))
	# This review fixture follows one authored event through its six-month recovery.
	_shell.sim._event_index = _shell.sim.historical.events.size()
	_shell.sim.acknowledge()
	_shell.show_dispatch(31)
	_shell._refresh_views()


func _review_controls() -> void:
	var ui := preload("res://ui_preview/shared/ui_kit.gd")
	var controls := Control.new()
	_main.add_child(controls)
	ui.panel(controls, Rect2(432, 174, 780, 44), true)
	ui.button(controls, "A / HARİTA", Rect2(442, 180, 180, 32), _variant.bind(false))
	ui.button(controls, "B / SAHA", Rect2(632, 180, 180, 32), _variant.bind(true))
	ui.button(controls, "YENİDEN DENE", Rect2(822, 180, 200, 32), _seed)
	ui.button(controls, "ÇIK", Rect2(1032, 180, 164, 32), quit)
	print("CRISIS_PILOT_REVIEW_READY: isolated, no player saves; A/B controls available")


func _variant(enabled: bool) -> void:
	_shell.crisis.operation_scene_enabled = enabled
	if _shell.open_screen.is_empty():
		_shell.show_screen("crisis")
	_shell.refresh_screen()


func _key(code: Key, window: Window) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		# Popups have a window identity even when embedded in the test viewport.
		event.window_id = window.get_window_id()
		Input.parse_input_event(event)
		Input.flush_buffered_events()
	await process_frame
	await process_frame


func _motion() -> void:
	_shell.crisis.operation_scene_enabled = true
	var id: String = _shell.crisis.selected().id
	_shell.sim.quick_dispatch(1, id, "team")
	_shell.sim.quick_dispatch(31, id, "team")
	_shell.sim.set_speed(1)
	_shell.sim.set_paused(false)
	await create_timer(1.4).timeout
	_shell.sim.quick_dispatch(31, id, "stock")
	await create_timer(2.8).timeout
	_shell.sim.set_paused(true)
	print("CRISIS_PILOT_MOTION_PASS: 1x travel, arrival, rescue and aid poses")
	_main.queue_free()
	await process_frame
	quit()
