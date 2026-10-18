extends "res://tests/integration/gameplay_ui.gd"
## --native-window checks the actual OS window; test preferences never touch player files.
var _native: bool = false


func _run() -> void:
	_native = "--native-window" in OS.get_cmdline_user_args()
	capture_screens = "--capture" in OS.get_cmdline_user_args()
	if not _native:
		root.size = Vector2i(1920, 1080)
	root.content_scale_size = Vector2i(1920, 1080)
	assert(ProjectSettings.get_setting("display/window/size/mode") == 4)
	if _native:
		assert(DisplayServer.get_name() != "headless")
		assert(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	_main = load("res://ui_preview/scenes/main_preview.tscn").instantiate()
	root.add_child(_main)
	await process_frame
	_shell = _main
	_shell.auto_save_enabled = false
	_shell.sim.tutorial_enabled = false
	await _check_hud_feedback()
	_shell.sim.set_paused(false)
	await _key(KEY_ESCAPE)
	assert(_shell.open_screen == "pause" and _shell.sim.paused)
	await _key(KEY_ESCAPE)
	assert(_shell.open_screen.is_empty() and not _shell.sim.paused)
	_shell.sim.set_paused(true)
	_shell.select_area(6)
	await _key(KEY_ESCAPE)
	assert(_shell.open_screen == "pause")
	await _key(KEY_ESCAPE)
	assert(_shell.open_screen.is_empty() and _shell.selected_area_id == 6)
	for screen: String in ["research", "projects", "national", "crisis", "fund"]:
		_shell.show_screen(screen)
		await _key(KEY_ESCAPE)
		assert(_shell.open_screen == "pause")
		await _key(KEY_ESCAPE)
		assert(_shell.open_screen == screen)
	await _key(KEY_ESCAPE)
	await _press_button("OYUN REHBERİ")
	assert(_shell.open_screen == "tutorial")
	await _key(KEY_ESCAPE)
	assert(_shell.open_screen == "pause")
	await _key(KEY_ESCAPE)
	assert(_shell.open_screen == "fund", "Nested help must preserve the original menu return")
	_shell.close_screen()
	_shell.sim.advance_to(CalendarClock.date_to_day("1951-04-08"))
	await process_frame
	await process_frame
	assert(_shell.open_screen == "newspaper")
	var pending := _shell.sim.news_queue.duplicate(true)
	await _key(KEY_ESCAPE)
	_shell.sim.changed.emit()
	await process_frame
	await process_frame
	assert(_shell.open_screen == "pause" and _shell.sim.news_queue == pending)
	await _press_button("OYUN REHBERİ")
	assert(not _find_button(_shell._modal, "KAPAT").disabled)
	await _key(KEY_ESCAPE)
	assert(_shell.open_screen == "pause")
	await _press_button("AYARLAR")
	await _capture("window-settings-fullscreen")
	for mode: String in ["borderless", "fullscreen"]:
		await _press_button("KENARLIKSIZ TAM EKRAN" if mode == "borderless" else "TAM EKRAN")
		await _check_mode(mode)
		await _key(KEY_F11)
		await _check_mode("windowed")
		await _key(KEY_F11)
		await _check_mode(mode)
	await _press_button("PENCERE")
	await _check_mode("windowed")
	await _capture("window-settings-windowed")
	await _press_button("KENARLIKSIZ TAM EKRAN")
	await _check_mode("borderless")
	await _capture("window-settings-borderless")
	await _key(KEY_ESCAPE)
	assert(_shell.open_screen == "pause")
	await _key(KEY_ESCAPE)
	assert(_shell.open_screen == "newspaper" and _shell.sim.news_queue == pending)
	await _press_button("HABERİ OKUDUM")
	assert(_shell.hud._date_state.text == "MÜDAHALE / GÜNLÜK")
	var target: Dictionary = _shell.crisis.selected()
	_shell.sim.advance_to(int(target.start) + int(target.window))
	await process_frame
	await process_frame
	assert(_shell.open_screen == "report")
	pending = _shell.sim.news_queue.duplicate(true)
	await _key(KEY_ESCAPE)
	assert(_shell.open_screen == "pause")
	await _key(KEY_ESCAPE)
	assert(_shell.open_screen == "report" and _shell.sim.news_queue == pending)
	await _shell.audio.shutdown()
	_main.queue_free()
	await process_frame
	print(
		"WINDOW_CONTROLS_PASS: HUD feedback/speed input, Esc pause/return, required news/report preserved, three display modes, F11 roundtrips; native=",
		_native
	)
	quit()


func _check_hud_feedback() -> void:
	var sim := _shell.sim
	var hud := _shell.hud
	var original_day := sim.clock.day
	var original_money := sim.treasury.money
	var original_awareness := sim.treasury.awareness_points
	var original_trust := sim.trust.value
	var original_history: Array[Dictionary] = sim.trust.history.duplicate(true)
	var original_speed := sim.speed
	var original_accumulator := sim._accumulator
	sim.clock.set_day(CalendarClock.date_to_day("1950-06-30"))
	sim.treasury.money = 118000000
	sim.treasury.awareness_points = 9999
	sim.changed.emit()
	await process_frame
	await process_frame
	assert(hud._trust_limits.text == "HALKIN GÜVENİ")
	assert(hud._trust.text == "70,00" and hud._trust_delta.text == "DEĞİŞİM YOK")
	assert("oyun" in hud._trust.tooltip_text.to_lower() and "0" in hud._trust.tooltip_text)
	assert(hud._awareness.text == "9999")
	assert(hud._total_teams.text == "30" and hud._total_stock.text == "1.200")
	var team_label_id := hud._total_teams.get_instance_id()
	var stock_label_id := hud._total_stock.get_instance_id()
	var area: ServiceArea = sim.areas[6]
	area.teams += 2
	area.total_teams += 2
	area.stock += 1234
	sim.changed.emit()
	await process_frame
	await process_frame
	assert(hud._total_teams.text == "32" and hud._total_stock.text == "2.434")
	assert("32" in hud._total_teams.tooltip_text and "2.434" in hud._total_stock.tooltip_text)
	assert(hud._awareness.get_rect().end.x < hud._total_teams.position.x)
	assert(hud._total_teams.get_rect().end.x < hud._total_stock.position.x)
	assert(hud._total_stock.get_rect().end.x < 1280)
	await _capture("hud-resource-totals")
	area.teams -= 2
	area.total_teams -= 2
	area.stock -= 1234
	sim.changed.emit()
	await process_frame
	await process_frame
	assert(hud._total_teams.text == "30" and hud._total_stock.text == "1.200")
	assert(hud._total_teams.get_instance_id() == team_label_id)
	assert(hud._total_stock.get_instance_id() == stock_label_id)
	assert(hud._date_label.text == "30 HAZ 1950")
	assert(hud._date_label.tooltip_text == "30 HAZİRAN 1950")
	assert(hud._date_label.mouse_filter == Control.MOUSE_FILTER_PASS)
	assert(hud._date_label.get_theme_font_size("font_size") == 30)
	assert(hud._date_state.text == "NORMAL / AYLIK")
	assert(hud._trust_limits.get_rect().end.y + 4 <= hud._trust.position.y)
	for pair: Array in [
		[hud._budget, hud._income],
		[hud._trust, hud._trust_delta],
		[hud._total_teams, hud._team_total],
		[hud._date_label, hud._date_state],
	]:
		assert(pair[0].get_rect().end.y + 6 <= pair[1].position.y)
	var clock_bounds := Rect2(1280, 16, 616, 108)
	for control: Control in [
		hud._date_label,
		hud._date_state,
		hud._pause_button,
		hud._speed_state,
	]:
		assert(clock_bounds.encloses(control.get_rect()))
	assert(hud._date_label.get_rect().end.x + 12 <= hud._pause_button.position.x)
	var button_ids: Array[int] = []
	for button: Button in hud._speed_buttons:
		assert(clock_bounds.encloses(button.get_rect()))
		button_ids.append(button.get_instance_id())
	for speed: int in [1, 2, 4]:
		await _press_button("%d×" % speed)
		_assert_hud_speed(speed, true)
		var selected: Button = hud._speed_buttons[[1, 2, 4].find(speed)]
		assert(root.gui_get_focus_owner() == selected)
		sim.changed.emit()
		await process_frame
		await process_frame
		assert(root.gui_get_focus_owner() == selected, "HUD refresh must keep input focus")
		for index: int in range(hud._speed_buttons.size()):
			assert(hud._speed_buttons[index].get_instance_id() == button_ids[index])
		_assert_hud_speed(speed, true)
	sim.trust.change(-0.015, "HUD testindeki gerçek güven aşınması")
	sim.changed.emit()
	await process_frame
	await process_frame
	assert(hud._trust.text in ["69,98", "69,99"])
	assert(hud._trust_delta.text == "SON -0,015")
	assert("HUD testindeki gerçek güven aşınması" in hud._trust_delta.tooltip_text)
	var latest_text := hud._trust_delta.text
	var history_size := sim.trust.history.size()
	var trust_value := sim.trust.value
	sim.changed.emit()
	await process_frame
	await process_frame
	assert(hud._trust_delta.text == latest_text)
	assert(sim.trust.history.size() == history_size and sim.trust.value == trust_value)
	await _capture("hud-paused")
	for speed: int in [1, 2, 4]:
		await _press_button("%d×" % speed)
		sim._accumulator = 0.0
		await _press_button("ZAMANI BAŞLAT")
		_assert_hud_speed(speed, false)
		await _capture("hud-running-%dx" % speed)
		await _press_button("ZAMANI DURDUR")
		_assert_hud_speed(speed, true)
	sim.clock.set_day(original_day)
	sim.treasury.money = original_money
	sim.treasury.awareness_points = original_awareness
	sim.trust.value = original_trust
	sim.trust.history.assign(original_history)
	sim._accumulator = original_accumulator
	sim.set_speed(original_speed)
	sim.changed.emit()
	await process_frame
	await process_frame


func _assert_hud_speed(speed: int, paused: bool) -> void:
	assert(_shell.sim.speed == speed and _shell.sim.paused == paused)
	for index: int in range(_shell.hud._speed_buttons.size()):
		var button: Button = _shell.hud._speed_buttons[index]
		assert(button.toggle_mode)
		assert(button.button_pressed == ([1, 2, 4][index] == speed))
	assert(
		(
			_shell.hud._speed_state.text
			== ("DURDU / %d× SEÇİLİ" if paused else "AKTİF HIZ: %d×") % speed
		)
	)


func _key(code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
	await process_frame
	await process_frame


func _check_mode(mode: String) -> void:
	await create_timer(0.15).timeout
	assert(_shell.display.current_mode() == mode)
	if _native:
		assert(DisplayServer.window_get_mode() == _shell.display.MODES[mode])
		if mode == "windowed":
			assert(not DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_BORDERLESS))
			var usable := DisplayServer.screen_get_usable_rect(
				DisplayServer.window_get_current_screen()
			)
			var client := Rect2i(
				DisplayServer.window_get_position(), DisplayServer.window_get_size()
			)
			assert(usable.encloses(client), "Windowed controls must fit the usable desktop")
		else:
			assert(
				(
					DisplayServer.window_get_size()
					== DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())
				)
			)
		print("NATIVE_MODE: ", mode, " / ", DisplayServer.window_get_size())


func _click(point: Vector2) -> void:
	var physical := root.get_stretch_transform() * point
	_mouse(physical, true)
	_mouse(physical, false)
	await process_frame
	await process_frame


func _capture(label: String) -> void:
	await process_frame
	await process_frame
	_check_text(_main)
	if capture_screens:
		var output := ProjectSettings.globalize_path("res://../generated/gameplay-ui")
		DirAccess.make_dir_recursive_absolute(output)
		RenderingServer.force_draw(false)
		assert(root.get_texture().get_image().save_png(output.path_join(label + ".png")) == OK)
	print("UI_CHECKPOINT: ", label)
