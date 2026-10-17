extends SceneTree
## Real viewport input; persistence uses only the isolated test-slot directory.

const SHELL := preload("res://ui_preview/main_preview.gd")
const UI := preload("res://ui_preview/shared/ui_kit.gd")
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
	capture_screens = "--capture" in OS.get_cmdline_user_args()
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
	print("UI_CHECKPOINT: opening complete")
	_clear_test_slots()
	assert(
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TEST_SAVE_DIR)) == OK
	)
	_shell.return_to_main_menu()
	assert(_shell.open_screen == "menu" and _shell.in_frontend and not _shell.auto_save_enabled)
	await _capture("main-menu")
	_check_button_tone("ÇIKIŞ", UI.ButtonTone.DANGER)
	_check_button_tone("YENİ OYUN", UI.ButtonTone.NEUTRAL)
	await _press_button("AYARLAR")
	await _capture("settings")
	await _press_button("AFET SARSINTISI: AÇIK")
	assert(not _shell.map_shake_enabled)
	await _press_button("AFET SARSINTISI: KAPALI")
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
	_check_button_tone("+", UI.ButtonTone.NEUTRAL)
	_check_button_tone("-", UI.ButtonTone.NEUTRAL)
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
	await _check_project_effects()
	_check_button_tone("BAŞLAT", UI.ButtonTone.CONFIRM)
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
	_check_button_tone("SEVK ET", UI.ButtonTone.CONFIRM)
	_check_button_tone("ACİL BÜTÇE", UI.ButtonTone.CAUTION)
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
	_check_button_tone("₺1,0 M AKTAR", UI.ButtonTone.CAUTION)
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
	assert(_shell.open_screen == "pause", "Help returns to its parent pause menu")
	await _press_button("ANA MENÜYE DÖN")
	await _capture("menu")
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
	_check_button_tone("MANUEL 1 KAYDET", UI.ButtonTone.CONFIRM)
	assert(_find_button(_shell._modal, "OTOMATİK").disabled)
	await _press_button("MANUEL 1 KAYDET")
	assert(_shell.saves.slot_summaries()[1].game_date == "1990-01-01")
	_shell.sim.advance_to(CalendarClock.date_to_day("1990-02-01"))
	await process_frame
	await _press_button("MANUEL 2 KAYDET")
	assert(_shell.saves.slot_summaries()[2].game_date == "1990-02-01")
	await _press_button("MANUEL 1 KAYDET")
	await _capture("save-confirm-overwrite")
	_check_button_tone("ÜZERİNE YAZ", UI.ButtonTone.DANGER)
	_check_button_tone("VAZGEÇ", UI.ButtonTone.NEUTRAL)
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
	_check_button_tone("ONAYLA: YÜKLE", UI.ButtonTone.DANGER)
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
	_check_button_tone("KAMPANYAYI AÇ", UI.ButtonTone.CONFIRM)
	await _press_button("KAMPANYAYI AÇ")
	if _shell.open_screen == "newgame":
		_check_button_tone("ONAYLA: YENİ KAMPANYA", UI.ButtonTone.DANGER)
		await _capture("newgame-confirm-replace")
		await _press_button("ONAYLA: YENİ KAMPANYA")
	assert(_shell.open_screen == "tutorial" and _shell.campaign.tutorial_step == 0)
	assert(not _shell.in_frontend)
	assert(_shell.sim.start_year == year and _shell.sim.paused)
	assert(CalendarClock.day_to_iso(_shell.sim.clock.day) == "%d-01-01" % year)
	assert(_shell.sim.tutorial_enabled and not _shell.auto_save_enabled)


func _check_button_tone(title: String, tone: UI.ButtonTone) -> void:
	var button: Button = _find_button(_shell._modal, title)
	assert(button != null, "Missing action button: " + title)
	var normal: StyleBoxTexture = button.get_theme_stylebox("normal")
	var region: Rect2 = normal.texture.region
	if tone == UI.ButtonTone.NEUTRAL:
		assert(region == Rect2(0, 56, 48, 32), title + " must remain neutral")
	else:
		var x: int = {
			UI.ButtonTone.CONFIRM: 168, UI.ButtonTone.CAUTION: 56, UI.ButtonTone.DANGER: 112
		}[tone]
		assert(region == Rect2(x, 96, 48, 24), "Wrong action color: " + title)
		for state: String in ["hover", "pressed", "hover_pressed"]:
			var surface: StyleBoxTexture = button.get_theme_stylebox(state)
			assert(surface.texture.region == region, "Action loses its color: " + title)
		var hover: StyleBoxTexture = button.get_theme_stylebox("hover")
		var pressed: StyleBoxTexture = button.get_theme_stylebox("pressed")
		assert(hover.modulate_color.r > normal.modulate_color.r)
		assert(pressed.modulate_color.r < normal.modulate_color.r)
	var disabled: StyleBoxTexture = button.get_theme_stylebox("disabled")
	assert(disabled.texture.region == Rect2(168, 56, 48, 32))
	var focus: StyleBoxTexture = button.get_theme_stylebox("focus")
	assert(not focus.draw_center, "Focus must preserve the action color: " + title)


func _check_project_effects() -> void:
	var before := JSON.stringify(_shell.sim.to_dict())
	var map_position: Vector2 = _shell.map_view._map_image.position
	var preview := _shell.sim.projects.effect_preview("river_zoning", 31)
	var scroll: ScrollContainer = _shell.projects._content.get_node("ProjectEffects")
	assert(preview.rows.size() == 3)
	_check_effect_rows(scroll, preview)
	var track: Control = scroll.get_child(0).get_child(0).get_child(4)
	var from := track.get_global_rect().get_center()
	_mouse(from, true)
	var motion := InputEventMouseMotion.new()
	motion.position = from + Vector2(120, 0)
	motion.global_position = motion.position
	motion.relative = Vector2(120, 0)
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(motion)
	Input.flush_buffered_events()
	await process_frame
	assert(not root.gui_is_dragging(), "Effect bars are read-only comparisons")
	_mouse(motion.position, false)
	await process_frame
	assert(_shell.map_view._map_image.position == map_position)
	assert(JSON.stringify(_shell.sim.to_dict()) == before)
	_shell.projects.show_project("assembly_areas", 31)
	await process_frame
	await process_frame
	scroll = _shell.projects._content.get_node("ProjectEffects")
	preview = _shell.sim.projects.effect_preview("assembly_areas", 31)
	assert(preview.rows.size() == 6)
	_check_effect_rows(scroll, preview)
	for step: int in range(10):
		await _effect_wheel(scroll.get_global_rect().get_center())
	assert(scroll.scroll_vertical > 0, "Mouse wheel must expose effects below the first three")
	var last: Control = scroll.get_child(0).get_child(5)
	assert(scroll.get_global_rect().encloses(last.get_global_rect()))
	await _capture("project-effects-scrolled")
	_shell.projects.show_project("national_radio")
	await process_frame
	scroll = _shell.projects._content.get_node("ProjectEffects")
	preview = _shell.sim.projects.effect_preview("national_radio")
	_check_effect_rows(scroll, preview)
	assert(preview.global and preview.rows[0].unit == "percent")
	assert(String(scroll.get_child(0).get_child(0).get_child(1).text).contains("%"))
	var has_global_note := false
	for child: Node in _shell.projects._content.get_children():
		if child is Label and child.text.begins_with("ULUSAL ORTALAMA"):
			has_global_note = true
	assert(has_global_note)
	await _capture("project-effects-national")
	_shell.projects.show_project("research_capacity")
	await process_frame
	scroll = _shell.projects._content.get_node("ProjectEffects")
	_check_effect_rows(scroll, _shell.sim.projects.effect_preview("research_capacity"))
	assert(scroll.get_child(0).get_child(0).get_child(1).text == "2 / 3 (+1)")
	await _capture("project-effects-capacity")
	var area: ServiceArea = _shell.sim.areas[31]
	var damage := area.damage
	var income := area.base_income
	area.damage = 60.0
	_shell.projects.show_project("repair", 31)
	await process_frame
	scroll = _shell.projects._content.get_node("ProjectEffects")
	_check_effect_rows(scroll, _shell.sim.projects.effect_preview("repair", 31))
	var damage_row: Control = scroll.get_child(0).get_node("damage")
	assert(damage_row.get_child(1).text == "60 / 0 (-60)")
	assert(damage_row.get_child(1).get_theme_color("font_color") == UI.TEAL)
	await _capture("project-effects-repair")
	area.base_income = 0
	_shell.projects.show_project("repair", 31)
	await process_frame
	scroll = _shell.projects._content.get_node("ProjectEffects")
	_check_effect_rows(scroll, _shell.sim.projects.effect_preview("repair", 31))
	var income_track: Control = scroll.get_child(0).get_node("income").get_child(4)
	assert(income_track.get_child(3).position.x == -1.0)
	area.damage = damage
	area.base_income = income
	var host := Control.new()
	root.add_child(host)
	var view := preload("res://ui_preview/management/project_screens.gd").new()
	view.setup(_shell)
	view._content = host
	var adverse := {
		"global": false,
		"maintenance_ratio": 1.0,
		"rows":
		[
			{
				"key": "resilience",
				"before": 40.0,
				"after": 20.0,
				"delta": -20.0,
				"minimum": 0.0,
				"maximum": 100.0,
				"unit": "points",
				"bounded": true,
				"higher_is_better": true
			}
		]
	}
	view._project_effects(adverse)
	await process_frame
	var adverse_scroll: ScrollContainer = host.get_node("ProjectEffects")
	_check_effect_rows(adverse_scroll, adverse)
	assert(adverse_scroll.get_child(0).get_child(0).get_child(1).text == "40 / 20 (-20)")
	host.queue_free()
	await process_frame
	assert(
		JSON.stringify(_shell.sim.to_dict()) == before, "Preview navigation must not alter gameplay"
	)
	_shell.projects.show_project("river_zoning", 31)
	await _capture("project-effects-local")


func _check_effect_rows(scroll: ScrollContainer, preview: Dictionary) -> void:
	var rows: VBoxContainer = scroll.get_child(0)
	assert(rows.get_child_count() == preview.rows.size())
	for effect: Dictionary in preview.rows:
		var row: Control = rows.get_node(String(effect.key))
		var track: Control = row.get_child(4)
		assert(track.mouse_filter == Control.MOUSE_FILTER_IGNORE)
		var tint: Color = UI.MUTED
		if not is_zero_approx(effect.delta):
			tint = (
				UI.TEAL
				if (effect.delta > 0.0) == bool(effect.higher_is_better)
				else Color("cf9584")
			)
		assert(row.get_child(1).get_theme_color("font_color") == tint)
		var scale: float = maxf(1.0, effect.maximum - effect.minimum)
		var current := clampf((effect.before - effect.minimum) / scale, 0.0, 1.0) * track.size.x
		var future := clampf((effect.after - effect.minimum) / scale, 0.0, 1.0) * track.size.x
		assert(is_equal_approx(track.get_child(4).position.x + 1.0, current))
		assert(is_equal_approx(track.get_child(3).position.x + 1.0, future))
		assert(track.get_child(4).modulate == UI.INK and track.get_child(3).modulate == tint)
		assert(is_equal_approx(track.get_child(2).size.x, absf(future - current)))
		for segment: TextureRect in track.get_children():
			assert(is_finite(segment.position.x) and is_finite(segment.size.x))
			assert(segment.mouse_filter == Control.MOUSE_FILTER_IGNORE)


func _effect_wheel(point: Vector2) -> void:
	root.warp_mouse(point)
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_WHEEL_DOWN
		event.position = point
		event.global_position = point
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
	await process_frame
	await process_frame


func _capture(label: String) -> void:
	await process_frame
	await process_frame
	_check_text(_main)
	print("UI_CHECKPOINT: ", label)
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
		elif not (
			parent is Label and parent.text_overrun_behavior != TextServer.OVERRUN_NO_TRIMMING
		):
			assert(width <= available, "Clipped text: " + control.text)
		# Map annotations and scroll contents have explicit clipping parents.
		var clipped := _shell.map_view._markers.is_ancestor_of(parent)
		var ancestor := parent.get_parent()
		while ancestor != null:
			clipped = clipped or ancestor is ScrollContainer
			ancestor = ancestor.get_parent()
		if not clipped:
			assert(
				Rect2(0, 0, 1920, 1080).encloses(control.get_global_rect()),
				"Text outside viewport: " + control.text
			)
	for child in parent.get_children():
		_check_text(child)
