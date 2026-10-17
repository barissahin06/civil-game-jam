extends SceneTree
## Real viewport input; persistence uses only the isolated test-slot directory.

const SHELL := preload("res://ui_preview/main_preview.gd")
const TEST_SAVE_DIR := "user://test-revert-ui-slots"
var capture_screens: bool = false
var _shell: SHELL
var _main: Node
var _capture_count: int = 0


class RejectingSave:
	extends SaveStore
	var attempts: int = 0

	func save(_simulation: Simulation, _path: String = PATH) -> bool:
		attempts += 1
		error = "Test kaydı reddedildi."
		return false


func _initialize() -> void:
	set_meta("simulation_test", true)
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	root.content_scale_size = root.size
	_main = load("res://core/scenes/main.tscn").instantiate()
	root.add_child(_main)
	await process_frame
	_shell = _main.get_node("MainPreview")
	_shell.auto_save_enabled = false
	_shell.saves.slot_directory = TEST_SAVE_DIR
	await _main.get_node("TitleSplash").tree_exited
	_clear_test_slots()
	assert(
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TEST_SAVE_DIR)) == OK
	)
	_shell.return_to_main_menu()
	assert(_shell.open_screen == "menu" and _shell.in_frontend and not _shell.auto_save_enabled)
	await _capture("main-menu")
	await _press_button("AYARLAR")
	await _capture("settings")
	await _press_button("HARİTA SARSINTISI: AÇIK")
	assert(not _shell.map_shake_enabled)
	await _press_button("HARİTA SARSINTISI: KAPALI")
	await _press_button("GERİ")
	await _press_button("YÜKLE")
	await _capture("load-empty")
	assert(_find_button(_shell._modal, "OTOMATİK YÜKLE").disabled)
	assert(_find_button(_shell._modal, "MANUEL 1 YÜKLE").disabled)
	await _press_button("GERİ")
	await _press_button("YENİ OYUN")
	assert(_shell.open_screen == "newgame")
	_shell.campaign.start_year = 1989
	_shell.refresh_screen()
	await _press_button("+")
	assert(_shell.campaign.start_year == 1990)
	await _capture("newgame-1990")
	await _open_campaign_from_form(1990)
	await _capture("intro-first-page")
	await _press_button("REHBERİ ATLA")
	assert(_shell.open_screen.is_empty() and not _shell.sim.tutorial_enabled and _shell.sim.paused)
	assert(not _shell.in_frontend)
	await _press_button("MENÜ")
	assert(_shell.open_screen == "pause")
	assert(_find_button(_shell._modal, "YENİ OYUN") == null)
	assert(_find_button(_shell._modal, "KAMPANYAYI AÇ") == null)
	var selected_campaign := _shell.sim
	_shell.show_screen("newgame")
	_shell.show_screen("menu")
	assert(_shell.open_screen == "pause" and _shell.sim == selected_campaign)
	await _capture("pause")
	await _check_save_load_flow()
	selected_campaign = _shell.sim
	var real_saves := _shell.saves
	var rejecting_save := RejectingSave.new()
	_shell.saves = rejecting_save
	_shell.auto_save_enabled = true
	await _press_button("ANA MENÜYE DÖN")
	assert(rejecting_save.attempts == 1)
	assert(not _shell.in_frontend and _shell.open_screen == "pause")
	assert(_shell.sim == selected_campaign and _shell.sim.paused)
	_shell.auto_save_enabled = false
	_shell.saves = real_saves
	await _press_button("ANA MENÜYE DÖN")
	assert(_shell.open_screen == "menu" and not _shell.auto_save_enabled)
	await _press_button("KAYITTAN DEVAM ET")
	assert(not _shell.in_frontend and _shell.sim.clock.year == 1990)
	await _press_button("MENÜ")
	await _press_button("ANA MENÜYE DÖN")
	await _press_button("YENİ OYUN")
	_shell.campaign.start_year = 1951
	_shell.refresh_screen()
	await _press_button("-")
	assert(_shell.campaign.start_year == 1950)
	await _open_campaign_from_form(1950)
	assert(_shell.saves.slot_summaries()[1].start_year == 1990)
	assert(_shell.saves.slot_summaries()[2].start_year == 1990)
	for step in range(1, 4):
		await _press_button("İLERİ")
		assert(_shell.campaign.tutorial_step == step)
	await _press_button("HARİTAYA GEÇ")
	assert(_shell.open_screen.is_empty() and _shell.sim.paused)
	await _capture("startup")
	assert(not _shell.city_panel.visible)
	assert(_shell._guide.visible and _shell._guide.text.begins_with("REHBER 1/4"))
	var hit: Image = _shell.map_view._hit_image
	var points: Dictionary = {}
	for y in range(300, 1400, 3):
		for x in range(800, 2500, 3):
			var id := roundi(hit.get_pixel(x, y).r * 255.0)
			if id > 0 and not points.has(id):
				var point := Vector2(x, y) + _shell.map_view._map_image.position
				if Rect2(440, 230, 1450, 680).has_point(point):
					points[id] = point
	assert(points.size() == 21)
	for id: int in points:
		await _click(points[id])
		assert(_shell.selected_area_id == id)
		await _press_button("×")
		assert(not _shell.city_panel.visible)
	await _click(points[31])
	await _capture("city-summary")
	assert(_shell._guide.text.begins_with("REHBER 2/4"))
	await _press_button("YATIRIM")
	await _capture("city-investments")
	await _press_button("İNCELE")
	assert(_shell.open_screen == "project")
	await _capture("local-project")
	await _press_button("BAŞLAT")
	assert(_shell.sim.projects.active_count("local", 31) == 1)
	assert(_shell._guide.text.begins_with("REHBER 3/4"))
	await _press_button("KAPAT")
	await _press_button("ARAŞTIRMA 0/2")
	await _capture("research-protection")
	await _press_button("İNCELE")
	await _press_button("BAŞLAT")
	assert(_shell.sim.projects.active_count("research") == 1)
	assert(_shell._guide.text.begins_with("REHBER 4/4"))
	await _press_button("KAPAT")
	_shell.show_screen("research")
	for tab in range(1, 4):
		_shell.research.select_tab(tab)
		await _capture("research-tab-%d" % tab)
	_shell.close_screen()
	_shell.show_screen("projects")
	await _capture("projects")
	_shell.close_screen()
	_shell.show_screen("national")
	await _capture("national")
	_shell.close_screen()
	await _press_button("DEVAM")
	_shell.sim.update(300.0)
	await process_frame
	await process_frame
	assert(CalendarClock.day_to_iso(_shell.sim.clock.day) == "1951-04-08")
	assert(_shell.open_screen == "newspaper")
	assert(_shell.sim.projects.is_completed("river_zoning", 31))
	await _capture("first-newspaper")
	await _press_button("KRİZ MERKEZİNE GEÇ")
	assert(_shell.open_screen == "crisis")
	await _capture("crisis")
	var target: Dictionary = _shell.sim.crises.active.front()
	var source_id: int = _shell.sim.areas.keys()[_shell.crisis.source_index]
	var quote := _shell.sim.logistics.quote(source_id, 31, "team", 1)
	var before := _shell.sim.treasury.money
	await _press_button("SEVK ET")
	assert(_shell.sim.areas[source_id].teams == 0)
	assert(_shell.sim.treasury.money == before - int(quote.fee))
	assert(not _shell._guide_plate.visible and _shell.sim.tutorial_completed.size() == 4)
	await _press_button("ACİL BÜTÇE")
	await _capture("emergency-fund")
	await _press_button("₺1,0 M AKTAR")
	assert(int(target.funds) == 1000000)
	await _press_button("KRİZE DÖN")
	await _press_button("KAPAT")
	# Same dispatch command through a native GUI drag from the city onto its target province.
	_shell.select_area(1)
	_shell.city_panel.select_tab(2)
	await process_frame
	await _capture("city-logistics")
	var drag: Button = _find_button(_main, "1 EKİP SÜRÜKLE")
	await _drag(drag.get_global_rect().get_center(), points[31])
	assert(_shell.sim.areas[1].teams == 0, "Map drop must reserve the team")
	await _capture("shipments")
	_shell.sim.advance_to(int(target.start) + int(target.window))
	await process_frame
	await process_frame
	assert(_shell.open_screen == "report")
	await _capture("report")
	await _press_button("AYRINTILAR")
	await _capture("report-details")
	await _press_button("ONARIMI İNCELE")
	await _capture("repair-project")
	await _press_button("BAŞLAT")
	assert(_shell.sim.projects.active_count("local", 31) == 1)
	_shell.close_screen()
	for layer in range(4):
		_shell.map_view.select_overlay(layer)
		await _capture("map-layer-%d" % layer)
	_shell.show_screen("ending")
	await _capture("ending")
	_shell.close_screen()
	_shell.show_screen("defeat")
	await _capture("defeat")
	_shell.close_screen()
	await _press_button("MENÜ")
	await _press_button("KISA REHBER")
	assert(_shell.campaign.tutorial_step == 0)
	await _capture("tutorial")
	_shell.close_screen()
	await _press_button("MENÜ")
	await _press_button("ANA MENÜYE DÖN")
	await _capture("menu")
	if capture_screens:
		var key := InputEventKey.new()
		key.pressed = true
		key.keycode = KEY_F11
		_shell._unhandled_key_input(key)
		await process_frame
		assert(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
		_shell._unhandled_key_input(key)
		await process_frame
		assert(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED)
	_main.queue_free()
	await process_frame
	_clear_test_slots()
	print(
		"GAMEPLAY_UI_PASS: 21 cities, real projects, research, first disaster, dispatch form + native map drop, report, repair; captures=",
		_capture_count
	)
	quit()


func _clear_test_slots() -> void:
	var store := SaveStore.new()
	store.slot_directory = TEST_SAVE_DIR
	for slot in range(4):
		for path: String in [store.slot_path(slot), store.slot_path(slot) + ".tmp"]:
			if FileAccess.file_exists(path):
				assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK)
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(TEST_SAVE_DIR)):
		assert(DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_DIR)) == OK)


func _check_save_load_flow() -> void:
	await _press_button("KAYDET")
	await _capture("save-empty")
	assert(_find_button(_shell._modal, "OTOMATİK").disabled)
	await _press_button("MANUEL 1 KAYDET")
	assert(_shell.saves.slot_summaries()[1].game_date == "1990-01-01")
	_shell.sim.advance_to(CalendarClock.date_to_day("1990-02-01"))
	await process_frame
	await _press_button("MANUEL 2 KAYDET")
	assert(_shell.saves.slot_summaries()[2].game_date == "1990-02-01")
	await _press_button("MANUEL 1 KAYDET")
	await _capture("save-confirm-overwrite")
	assert(_shell.save_slots.pending_slot == 1)
	await _press_button("VAZGEÇ")
	assert(_shell.saves.slot_summaries()[1].game_date == "1990-01-01")
	assert(_shell._save())
	var corrupt := FileAccess.open(_shell.saves.slot_path(3), FileAccess.WRITE)
	corrupt.store_string("invalid test slot")
	corrupt.close()
	await _press_button("GERİ")
	await _press_button("YÜKLE")
	await _capture("load-slots")
	assert(_find_button(_shell._modal, "MANUEL 3 YÜKLE").disabled)
	await _press_button("MANUEL 1 YÜKLE")
	await _capture("load-confirm")
	assert(_shell.save_slots.pending_slot == 1 and _shell.sim.clock.month == 2)
	await _press_button("VAZGEÇ")
	assert(_shell.sim.clock.month == 2)
	await _press_button("MANUEL 1 YÜKLE")
	await _press_button("ONAYLA: YÜKLE")
	assert(_shell.open_screen.is_empty() and _shell.sim.clock.month == 1 and _shell.sim.paused)
	await _press_button("MENÜ")
	await _press_button("YÜKLE")
	await _press_button("MANUEL 2 YÜKLE")
	await _press_button("ONAYLA: YÜKLE")
	assert(_shell.sim.clock.month == 2)
	await _press_button("MENÜ")
	await _press_button("KAYDET")
	await _press_button("MANUEL 1 KAYDET")
	await _press_button("ÜZERİNE YAZ")
	assert(_shell.saves.slot_summaries()[1].game_date == "1990-02-01")
	await _press_button("GERİ")
	assert(_shell.open_screen == "pause")


func _open_campaign_from_form(year: int) -> void:
	await _press_button("KAMPANYAYI AÇ")
	if _shell.open_screen == "newgame":
		await _press_button("ONAYLA: YENİ KAMPANYA")
	assert(_shell.open_screen == "tutorial" and _shell.campaign.tutorial_step == 0)
	assert(not _shell.in_frontend)
	assert(_shell.sim.start_year == year and _shell.sim.paused)
	assert(CalendarClock.day_to_iso(_shell.sim.clock.day) == "%d-01-01" % year)
	assert(_shell.sim.tutorial_enabled and not _shell.auto_save_enabled)


func _capture(label: String) -> void:
	await process_frame
	await process_frame
	_check_text(_main)
	assert(_shell.hud.is_visible_in_tree() == (not _shell.in_frontend), "HUD visibility: " + label)
	assert(
		_shell.map_view.is_visible_in_tree() == (not _shell.in_frontend), "Map visibility: " + label
	)
	if capture_screens:
		var output := ProjectSettings.globalize_path("res://../generated/gameplay-ui")
		DirAccess.make_dir_recursive_absolute(output)
		RenderingServer.force_draw(false)
		var picture := root.get_texture().get_image()
		assert(picture.get_size() == Vector2i(1920, 1080))
		assert(picture.save_png(output.path_join(label + ".png")) == OK)
		_capture_count += 1


func _find_button(parent: Node, title: String) -> Button:
	if parent is CanvasItem and not parent.is_visible_in_tree():
		return null
	if parent is Button and parent.text == title:
		return parent
	for child in parent.get_children():
		var found := _find_button(child, title)
		if found != null:
			return found
	return null


func _press_button(title: String) -> void:
	var button := _find_button(_shell._modal if is_instance_valid(_shell._modal) else _main, title)
	assert(button != null, "Missing button: " + title)
	assert(not button.disabled, "Disabled button: " + title)
	await _click(button.get_global_rect().get_center())


func _mouse(point: Vector2, pressed: bool) -> void:
	root.warp_mouse(point)
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = point
	event.global_position = point
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _click(point: Vector2) -> void:
	_mouse(point, true)
	_mouse(point, false)
	await process_frame
	await process_frame


func _drag(from: Vector2, to: Vector2) -> void:
	var hover := InputEventMouseMotion.new()
	hover.position = from
	hover.global_position = from
	root.warp_mouse(from)
	Input.parse_input_event(hover)
	Input.flush_buffered_events()
	await process_frame
	_mouse(from, true)
	await process_frame
	for point: Vector2 in [from + Vector2(30, 0), from.lerp(to, 0.5), to]:
		root.warp_mouse(point)
		var motion := InputEventMouseMotion.new()
		motion.position = point
		motion.global_position = point
		motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		motion.relative = Vector2(30, 0)
		Input.parse_input_event(motion)
		Input.flush_buffered_events()
		await process_frame
	assert(root.gui_is_dragging(), "Native mouse motion must start the resource drag")
	_mouse(to, false)
	await process_frame
	await process_frame


func _check_text(parent: Node) -> void:
	if parent is CanvasItem and not parent.is_visible_in_tree():
		return
	if parent is Label or parent is Button:
		var control := parent as Control
		var font := control.get_theme_font("font")
		var font_size := control.get_theme_font_size("font_size")
		for character: String in control.text:
			assert(
				character == "\n" or font.has_char(character.unicode_at(0)),
				"Missing font glyph: " + character + " in " + control.text
			)
		var width := font.get_string_size(control.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var authored: Vector2 = control.get_meta("p0_text_size", control.size)
		var available := authored.x
		if parent is Button:
			available -= control.get_theme_stylebox("normal").get_minimum_size().x
		if parent is Label and parent.autowrap_mode != TextServer.AUTOWRAP_OFF:
			assert(
				parent.get_line_count() * parent.get_line_height() <= authored.y,
				"Clipped paragraph: " + control.text
			)
		else:
			assert(width <= available, "Clipped text: " + control.text)
		# Map annotations are clipped by the camera; fixed UI must fit the viewport.
		if not _shell.map_view._markers.is_ancestor_of(parent):
			assert(
				Rect2(0, 0, 1920, 1080).encloses(control.get_global_rect()),
				"Text outside viewport: " + control.text
			)
	for child in parent.get_children():
		_check_text(child)
