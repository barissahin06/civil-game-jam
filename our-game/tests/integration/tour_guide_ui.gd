extends "res://tests/integration/gameplay_ui.gd"


## Real tutorial input; calendar waits are advanced explicitly, saves stay in an isolated directory.
func _run() -> void:
	root.size = Vector2i(1920, 1080)
	root.content_scale_size = root.size
	_test_save_dir = "user://test-tour-guide-%d" % OS.get_process_id()
	_main = load("res://ui_preview/scenes/main_preview.tscn").instantiate()
	root.add_child(_main)
	await process_frame
	_shell = _main
	_shell.auto_save_enabled = false
	_shell.saves.slot_directory = _test_save_dir
	assert(
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_test_save_dir)) == OK
	)
	if capture_screens:
		await create_timer(0.25).timeout
	_shell.start_campaign(1950)
	await _step("intro")
	assert(_shell.sim.paused and not _shell.auto_save_enabled)
	assert(_shell.tour.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	await _capture("tour-intro")
	await _guide_button("ANLADIM")
	await _step("city")
	var before: Rect2 = _shell.tour._target
	await _pan_map(Vector2(1240, 580), Vector2(1280, 604))
	assert(_shell.tour._target != before, "Map highlight must follow native map movement")
	_shell.map_view.reset_map()
	await process_frame
	await _click(_map_point(34))
	assert(_shell.selected_area_id == 34 and _shell.sim.guide.done("city"))
	await _step("zoom")
	await _wheel_map(Vector2(1240, 580))
	assert(_shell.map_view._zoom == 2 and _shell.sim.guide.done("zoom"))
	await _step("overlay")
	await _guide_button("HEDEFİ GÖSTER")
	await _click(_shell.map_view._layer_buttons[1].get_global_rect().get_center())
	assert(_shell.sim.guide.done("overlay"))
	_shell.map_view.reset_map()
	await _step("investment")
	await _capture("tour-map")
	await _guide_button("HEDEFİ GÖSTER")
	assert(_shell.open_screen == "project")
	await _capture("tour-project")
	await _press_button("BAŞLAT")
	assert(_shell.sim.guide.done("investment"))
	await _step("research")
	await _guide_button("HEDEFİ GÖSTER")
	assert(_shell.open_screen == "research")
	var inspect: Rect2 = _shell.tour._target
	var scroll: ScrollContainer = _shell._screen_content.get_node("ResearchList")
	scroll.scroll_horizontal = int(scroll.get_h_scroll_bar().max_value)
	await process_frame
	await process_frame
	assert(_shell.tour._target.has_area() and _shell.tour._target != inspect)
	await _guide_button("HEDEFİ GÖSTER")
	await process_frame
	await _click(_shell.tour._target.get_center())
	assert(_shell.open_screen == "project")
	await _press_button("BAŞLAT")
	assert(_shell.sim.guide.done("research"))
	await _step("teams")
	await _guide_button("HEDEFİ GÖSTER")
	await _press_button("EKİP KUR")
	await _click(_shell.map_view._marker_nodes["plan:34"].get_global_rect().get_center())
	assert(_shell.sim.guide.done("teams"))
	await _step("stock")
	await _press_button("YARDIM HAZIRLA")
	await _click(_shell.map_view._marker_nodes["plan:34"].get_global_rect().get_center())
	assert(_shell.sim.guide.done("stock"))
	await _step("time")
	await _press_button("ZAMANI BAŞLAT")
	await _step("speed")
	assert(_shell.sim.paused, "A new lesson pauses once")
	await _press_button("ZAMANI BAŞLAT")
	for frame in range(4):
		await process_frame
	assert(not _shell.sim.paused, "The current lesson must allow the player to resume time")
	await _press_button("ZAMANI DURDUR")
	await _press_button("2×")
	assert(_shell.sim.guide.done("speed"))
	await _step("projects")
	await _guide_button("HEDEFİ GÖSTER")
	assert(_shell.open_screen == "projects" and _shell.sim.guide.done("projects"))
	await _step("finish")
	assert(_shell.tour._body.text.contains("üç manuel kayıt"))
	assert(_shell.tour._body.text.contains("önlenen kayıp/hasar"))
	await _capture("tour-finish")
	await _guide_button("ANLADIM")
	assert(not _shell.campaign_finished and _shell.sim.outcome.is_empty())
	await _step("project_controls")
	await _guide_button("ANLADIM")
	await _press_button("KAPAT")
	_shell.sim.advance_to(CalendarClock.date_to_day("1950-03-01"))
	await _step("bubble")
	await _click(_shell.tour._target.get_center())
	assert(_shell.sim.guide.done("bubble"))
	await _step("awareness")
	await _guide_button("HEDEFİ GÖSTER")
	await _click(_shell.tour._target.get_center())
	assert(_shell.open_screen == "project")
	await _press_button("BAŞLAT")
	assert(_shell.sim.guide.done("awareness"))
	await _press_button("KAPAT")
	_shell.sim.advance_to(CalendarClock.date_to_day("1951-04-08"))
	await _step("newspaper")
	await _capture("tour-newspaper")
	await _press_button("HABERİ OKUDUM")
	await _step("dispatch_teams")
	await _capture("tour-crisis")
	await _press_button("EKİP SEÇ")
	await _press_button("İHTİYACA GÖRE AYARLA")
	await _press_button("GÖNDERİMİ ONAYLA")
	assert(_shell.sim.guide.done("dispatch_teams"))
	await _step("dispatch_stock")
	await _press_button("MALZEME SEÇ")
	await _press_button("İHTİYACA GÖRE AYARLA")
	await _press_button("GÖNDERİMİ ONAYLA")
	assert(_shell.sim.guide.done("dispatch_stock"))
	await _step("completion")
	await _guide_button("ANLADIM")
	var crisis: Dictionary = _shell.sim.crises.active.front()
	_shell.sim.advance_to(int(crisis.start) + int(crisis.window))
	await _step("report")
	await _capture("tour-report")
	await _press_button("ONARIMI İNCELE")
	assert(_shell.sim.guide.done("report") and _shell.open_screen == "project")
	await _step("repair")
	await _press_button("BAŞLAT")
	assert(_shell.sim.guide.done("repair"))
	await _check_early_interruption_and_restore()
	await _shell.audio.shutdown()
	_main.queue_free()
	await process_frame
	_clear_test_slots()
	print(
		"TOUR_GUIDE_UI_PASS: real exercises, pause once, moving targets, crisis/report/repair, skips and isolated restore; captures=",
		_capture_count
	)
	quit()


func _check_early_interruption_and_restore() -> void:
	_shell.start_campaign(1952)
	await _step("intro")
	await _guide_button("ANLADIM")
	await _step("city")
	await _guide_button("BU ADIMI ATLA")
	await _step("zoom")
	var guide_before_reading := JSON.stringify(_shell.sim.guide.to_dict())
	await _key(KEY_ESCAPE)
	await _press_button("OYUN REHBERİ")
	await _select_guide_topic(8)
	await _capture("tour-reference-guide")
	assert(not _shell.tour.visible)
	await _press_button("GENEL BAKIŞI KAPAT")
	assert(_shell.open_screen == "pause")
	await _key(KEY_ESCAPE)
	await _step("zoom")
	assert(JSON.stringify(_shell.sim.guide.to_dict()) == guide_before_reading)
	await _guide_button("REHBERİ KAPAT")
	assert(not _shell.sim.guide.enabled and not _shell.tour.visible)
	await _key(KEY_ESCAPE)
	await _press_button("OYUN REHBERİ")
	assert(not _shell.tour.visible)
	await _press_button("REHBERE DEVAM ET")
	await _step("zoom")
	assert("city" in _shell.sim.guide.skipped and _shell.sim.paused)
	_shell.sim.advance_to(CalendarClock.date_to_day("1952-01-03"))
	await _step("newspaper")
	assert(_shell.sim.guide.return_step == "zoom")
	await _capture("tour-early-newspaper")
	await _press_button("HABERİ OKUDUM")
	await _step("dispatch_teams")
	await _guide_button("BU ADIMI ATLA")
	await _step("dispatch_stock")
	await _guide_button("BU ADIMI ATLA")
	var crisis: Dictionary = _shell.sim.crises.active.front()
	_shell.sim.advance_to(int(crisis.start) + int(crisis.window))
	await _step("report")
	await _press_button("RAPORU OKUDUM")
	await _step("zoom")
	assert(_shell.save_campaign_slot(1).ok)
	assert(_shell.load_campaign_slot(1).ok)
	await _step("zoom")
	assert("city" in _shell.sim.guide.skipped)
	assert("dispatch_teams" in _shell.sim.guide.skipped)
	assert(_shell.sim.guide.done("report"))


func _step(id: String) -> void:
	await process_frame
	await process_frame
	assert(
		_shell.sim.guide.active_step == id,
		"Expected guide %s, got %s" % [id, _shell.sim.guide.active_step]
	)
	assert(_shell.tour.visible and _shell.tour._shown_step == id)
	if _shell.tour._target.has_area():
		assert(
			not _shell.tour._card.get_global_rect().intersects(_shell.tour._target),
			"Guide must leave the target clickable: " + id
		)


func _capture(label: String) -> void:
	if not capture_screens:
		await super._capture(label)
		return
	await process_frame
	await RenderingServer.frame_post_draw
	_check_text(_main)
	print("UI_CHECKPOINT: ", label)
	var output := ProjectSettings.globalize_path("res://../generated/gameplay-ui")
	DirAccess.make_dir_recursive_absolute(output)
	var picture := root.get_texture().get_image()
	assert(picture.get_size() == Vector2i(1920, 1080))
	assert(picture.save_png(output.path_join(label + ".png")) == OK)
	_capture_count += 1


func _guide_button(title: String) -> void:
	var button := _find_button(_shell.tour, title)
	assert(button != null and not button.disabled, "Missing guide button: " + title)
	await _click(button.get_global_rect().get_center())


func _map_point(id: int) -> Vector2:
	var hit: Image = _shell.map_view._hit_image
	for y in range(300, 1400, 3):
		for x in range(800, 2500, 3):
			if roundi(hit.get_pixel(x, y).r * 255.0) != id:
				continue
			var point: Vector2 = _shell.map_view._map_image.get_global_transform() * Vector2(x, y)
			if (
				Rect2(440, 230, 1450, 620).has_point(point)
				and not _shell.tour._card.get_global_rect().has_point(point)
			):
				return point
	assert(false, "No visible map input point for city %d" % id)
	return Vector2.ZERO


func _pan_map(from: Vector2, to: Vector2) -> void:
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


func _wheel_map(point: Vector2) -> void:
	root.warp_mouse(point)
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_WHEEL_UP
		event.position = point
		event.global_position = point
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
	await process_frame
	await process_frame


func _key(code: Key) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
	await process_frame
	await process_frame
