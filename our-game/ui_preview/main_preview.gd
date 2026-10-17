extends Control
## Composition only: views issue commands to the shared simulation.
const UI := preload("res://ui_preview/shared/ui_kit.gd")
const MAP_VIEW := preload("res://ui_preview/map/map_view.gd")
const CITY_PANEL := preload("res://ui_preview/management/city_panel.gd")
const HUD := preload("res://ui_preview/campaign/hud.gd")
const MENU_SPLASH := preload("res://ui_preview/assets/main_menu_splash.png")
var sim: Simulation
var saves := SaveStore.new()
var map_view: MAP_VIEW
var city_panel: CITY_PANEL
var hud: HUD
var campaign := preload("res://ui_preview/campaign/campaign_screens.gd").new()
var save_slots := preload("res://ui_preview/campaign/save_screens.gd").new()
var research := preload("res://ui_preview/management/research_screen.gd").new()
var projects := preload("res://ui_preview/management/project_screens.gd").new()
var crisis := preload("res://ui_preview/crisis/crisis_screen.gd").new()
var news_reports := preload("res://ui_preview/crisis/news_reports.gd").new()
var selected_area_id: int = 0
var open_screen: String = ""
var auto_save_enabled: bool = false
var in_frontend: bool = false
var map_shake_enabled: bool = true
var _gameplay: Control
var _modal: Control
var _screen_content: Control
var _status: Label
var _guide: Label
var _guide_plate: Panel
var _dirty: bool = true
var _save_dirty: bool = false
var _save_timer: float = 0.0
var _presented_outcome: String = ""
var _ticker_cursor: int = 0
var _ticker_elapsed: float = 0.0
var _last_ticker_message: String = ""
var _feedback_event_ids: Array[String] = []


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	UI.install_cursors()
	theme = Theme.new()
	theme.default_font = UI.FONT
	theme.default_font_size = 18
	theme.set_stylebox("panel", "TooltipPanel", UI.style(Rect2(0, 0, 48, 48)))
	theme.set_color("font_color", "TooltipLabel", UI.INK)
	sim = Simulation.new()
	if not sim.setup():
		push_error("Kampanya verileri yüklenemedi; oyun başlatılamadı.")
		set_process(false)
		get_tree().quit(1)
		return
	_load_visual_preferences()
	_bind_simulation()
	for view in [campaign, save_slots, research, projects, crisis, news_reports]:
		view.setup(self)
	map_view = MAP_VIEW.new()
	map_view.setup(self)
	city_panel = CITY_PANEL.new()
	city_panel.setup(self)
	hud = HUD.new()
	hud.setup(self)
	hud.screen_requested.connect(show_screen)
	map_view.area_selected.connect(select_area)
	city_panel.screen_requested.connect(show_screen)
	city_panel.project_requested.connect(show_project)
	city_panel.close_requested.connect(close_city_panel)
	_gameplay = Control.new()
	_gameplay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_gameplay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_gameplay)
	_gameplay.add_child(map_view)
	map_view.set_shake_enabled(map_shake_enabled)
	_gameplay.add_child(hud)
	_gameplay.add_child(city_panel)
	UI.panel(_gameplay, Rect2(16, 1030, 1888, 42))
	_status = UI.text(_gameplay, "", Rect2(32, 1040, 1856, 26), 18, UI.MUTED)
	_status.mouse_filter = Control.MOUSE_FILTER_PASS
	_guide_plate = UI.panel(_gameplay, Rect2(432, 174, 1010, 36))
	_guide = UI.text(_gameplay, "", Rect2(446, 178, 982, 28), 18, UI.GOLD)
	if not _testing():
		return_to_main_menu()
	_refresh_views()


func _exit_tree() -> void:
	UI.reset_cursors()


func return_to_main_menu() -> void:
	sim.set_paused(true)
	if auto_save_enabled and not _save():
		return
	auto_save_enabled = false
	in_frontend = true
	close_city_panel()
	_gameplay.hide()
	show_screen("menu")


func _bind_simulation(resuming: bool = false) -> void:
	sim.changed.connect(_mark_dirty)
	sim.notification_requested.connect(_mark_dirty)
	sim.notification_requested.connect(_play_new_crisis_feedback)
	_feedback_event_ids.clear()
	for event: Dictionary in sim.historical.events:
		if int(event.day) < sim.clock.day or (resuming and int(event.day) == sim.clock.day):
			_feedback_event_ids.append(event.id)


func _play_new_crisis_feedback() -> void:
	if not is_instance_valid(map_view):
		return
	for item: Dictionary in sim.news_queue:
		if item.kind == "newspaper" and not item.id in _feedback_event_ids:
			_feedback_event_ids.append(item.id)
			map_view.play_crisis_feedback()


func _load_visual_preferences() -> void:
	if _testing():
		return
	var preferences := ConfigFile.new()
	if preferences.load("user://preferences.cfg") == OK:
		var enabled: Variant = preferences.get_value("visual", "map_shake", true)
		if enabled is bool:
			map_shake_enabled = enabled


func toggle_map_shake() -> void:
	map_shake_enabled = not map_shake_enabled
	map_view.set_shake_enabled(map_shake_enabled)
	if not _testing():
		var preferences := ConfigFile.new()
		preferences.load("user://preferences.cfg")
		preferences.set_value("visual", "map_shake", map_shake_enabled)
		if preferences.save("user://preferences.cfg") != OK:
			preview_notice("Görsel tercih kaydedilemedi; bu oturumda uygulanıyor.")
	if open_screen in ["menu", "pause", "settings"]:
		refresh_screen()


func _testing() -> bool:
	return (
		DisplayServer.get_name() == "headless"
		or bool(get_tree().get_meta("simulation_test", false))
	)


func _process(delta: float) -> void:
	sim.update(delta)
	if _dirty and not get_viewport().gui_is_dragging():
		_refresh_views()
	_save_timer += delta
	if auto_save_enabled and _save_dirty and _save_timer >= 10.0:
		_save()
	_ticker_elapsed += delta
	if _ticker_elapsed >= 4.0 and not sim.ticker.is_empty():
		_ticker_elapsed = 0.0
		_ticker_cursor = wrapi(_ticker_cursor - 1, 0, sim.ticker.size())
		_display_ticker()


func _mark_dirty() -> void:
	_dirty = true
	_save_dirty = true


func _refresh_views() -> void:
	_dirty = false
	if in_frontend:
		return
	_play_new_crisis_feedback()
	hud.refresh()
	city_panel.refresh()
	map_view.refresh()
	if not sim.ticker.is_empty():
		if sim.ticker.back() != _last_ticker_message:
			_last_ticker_message = sim.ticker.back()
			_ticker_cursor = sim.ticker.size() - 1
		_display_ticker()
	var actions: Array[String] = ["city", "investment", "research", "dispatch"]
	var hints: Array[String] = [
		"REHBER 1/4: Bir yönetim merkezi seç.",
		"REHBER 2/4: Şehirde yerel yatırım başlat.",
		"REHBER 3/4: Üst menüden araştırma başlat.",
		"REHBER 4/4: İlk afette ekip veya yardım sevk et."
	]
	_guide.text = ""
	if sim.tutorial_enabled:
		for index in range(actions.size()):
			if not actions[index] in sim.tutorial_completed:
				_guide.text = hints[index]
				break
	_guide_plate.visible = not _guide.text.is_empty()
	_guide.visible = _guide_plate.visible
	if not sim.news_queue.is_empty():
		var route: String = sim.news_queue.front().kind
		if open_screen != route:
			show_screen(route)
		elif is_instance_valid(_screen_content):
			refresh_screen()
	elif not sim.outcome.is_empty() and _presented_outcome != sim.outcome:
		_presented_outcome = sim.outcome
		show_screen(sim.outcome)
	elif not open_screen.is_empty():
		refresh_screen()


func select_area(id: int) -> void:
	if in_frontend:
		return
	if city_panel.select_area(id):
		selected_area_id = id
		map_view.select_area(id)
		sim.learn("city")
		_mark_dirty()


func close_city_panel() -> void:
	selected_area_id = 0
	city_panel.clear_selection()
	map_view.select_area(0)


func show_project(id: String, area_id: int = 0) -> void:
	projects.show_project(id, area_id)


func start_campaign(year: int) -> void:
	var replacement := Simulation.new()
	if not replacement.setup(year):
		preview_notice("Kampanya verileri yüklenemedi")
		return
	sim = replacement
	in_frontend = false
	_gameplay.show()
	_presented_outcome = ""
	_bind_simulation()
	auto_save_enabled = not _testing()
	close_city_panel()
	_remove_modal()
	_mark_dirty()
	if auto_save_enabled:
		_save()


func continue_campaign() -> void:
	var result := load_campaign_slot(0)
	if not result.ok:
		save_slots.open("load")
		save_slots.notice = str(result.message)
		refresh_screen()


func save_campaign_slot(slot: int) -> Dictionary:
	if in_frontend or slot < 1 or slot > 3:
		return {"ok": false, "message": "Manuel kayıt için açık kampanya ve 1-3 arasında yuva seç."}
	if not saves.save(sim, saves.slot_path(slot)):
		return {"ok": false, "message": saves.error}
	return {"ok": true, "message": "Manuel kayıt %d kaydedildi." % slot}


func load_campaign_slot(slot: int) -> Dictionary:
	var path := saves.slot_path(slot)
	if path.is_empty():
		return {"ok": false, "message": "Geçersiz kayıt yuvası."}
	var restored := saves.load_campaign(path)
	if restored == null:
		return {"ok": false, "message": saves.error}
	sim = restored
	in_frontend = false
	_gameplay.show()
	_presented_outcome = ""
	_bind_simulation(true)
	auto_save_enabled = not _testing()
	close_city_panel()
	_remove_modal()
	_mark_dirty()
	return {"ok": true, "message": "Kampanya yüklendi."}


func _save() -> bool:
	var saved := saves.save(sim, saves.slot_path(0))
	if not saved:
		preview_notice(saves.error)
	_save_dirty = false
	_save_timer = 0.0
	return saved


func command_result(result: Dictionary) -> void:
	preview_notice(str(result.get("message", "")))
	sim.changed.emit()
	if auto_save_enabled:
		_save_timer = 10.0


func refresh_screen() -> void:
	if not is_instance_valid(_screen_content):
		return
	UI.clear(_screen_content)
	match open_screen:
		"save", "load":
			save_slots.render(_screen_content, open_screen)
		"research":
			research.render(_screen_content, open_screen)
		"project", "projects", "national":
			projects.render(_screen_content, open_screen)
		"crisis", "fund":
			crisis.render(_screen_content, open_screen)
		"newspaper", "report":
			news_reports.render(_screen_content, open_screen)
		"menu", "newgame", "pause", "settings", "tutorial", "ending", "defeat":
			campaign.render(_screen_content, open_screen)


func show_screen(screen: String) -> void:
	if (
		(not in_frontend and screen in ["menu", "newgame"])
		or (in_frontend and screen not in ["menu", "newgame", "load", "settings", "tutorial"])
	):
		return
	_remove_modal()
	sim.set_paused(true)
	open_screen = screen
	_modal = Control.new()
	_modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_modal)
	if in_frontend:
		var background := TextureRect.new()
		background.texture = MENU_SPLASH
		background.size = Vector2(1920, 1080)
		background.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_modal.add_child(background)
		if screen != "menu":
			UI.panel(_modal, Rect2(248, 156, 1424, 824), true)
	else:
		UI.panel(_modal, Rect2(432, 174, 1472, 846), true)
		var close: Button = UI.button(_modal, "KAPAT", Rect2(1738, 216, 116, 38), close_screen)
		close.disabled = not sim.news_queue.is_empty() or not sim.outcome.is_empty()
	_screen_content = Control.new()
	_screen_content.position = (
		Vector2(116, 164)
		if in_frontend and screen == "menu"
		else Vector2(288, 220) if in_frontend else Vector2(474, 270)
	)
	_screen_content.size = Vector2(1376, 690)
	_modal.add_child(_screen_content)
	refresh_screen()


func _remove_modal() -> void:
	if is_instance_valid(_modal):
		remove_child(_modal)
		_modal.queue_free()
	_modal = null
	open_screen = ""


func close_screen() -> void:
	if in_frontend:
		if open_screen != "menu":
			show_screen("menu")
		return
	if open_screen in ["save", "load", "settings"]:
		show_screen("pause")
		return
	if sim.news_queue.is_empty() and sim.outcome.is_empty():
		_remove_modal()


func acknowledge_news() -> void:
	var was_news: bool = (
		not sim.news_queue.is_empty() and sim.news_queue.front().kind == "newspaper"
	)
	sim.acknowledge()
	_remove_modal()
	if sim.news_queue.is_empty() and was_news:
		show_screen("crisis")
	_mark_dirty()


func preview_notice(message: String) -> void:
	if is_instance_valid(_status):
		_status.text = message
		sim.log_message(message)


func _display_ticker() -> void:
	if sim.ticker.is_empty():
		return
	_ticker_cursor = clampi(_ticker_cursor, 0, sim.ticker.size() - 1)
	var message := sim.ticker[_ticker_cursor]
	_status.text = message if message.length() <= 119 else message.left(116) + "..."
	_status.tooltip_text = message


static func fmt_money(value: int) -> String:
	var amount := absf(float(value))
	var suffix := ""
	if amount >= 1000000000:
		amount /= 1000000000.0
		suffix = " MRD"
	elif amount >= 1000000:
		amount /= 1000000.0
		suffix = " M"
	elif amount >= 1000:
		amount /= 1000.0
		suffix = " BİN"
	return (
		("-" if value < 0 else "")
		+ "₺"
		+ (("%.1f" % amount).replace(".", ",") if not suffix.is_empty() else str(absi(value)))
		+ suffix
	)


static func fmt_count(value: int) -> String:
	var digits := str(value)
	var result := ""
	for index in range(digits.length()):
		if index > 0 and (digits.length() - index) % 3 == 0:
			result += "."
		result += digits[index]
	return result


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and auto_save_enabled and sim != null:
		_save()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if not open_screen.is_empty():
				close_screen()
			else:
				close_city_panel()
		elif event.keycode == KEY_SPACE and open_screen.is_empty():
			sim.set_paused(not sim.paused)
		elif event.keycode == KEY_F11:
			toggle_fullscreen()


func toggle_fullscreen() -> void:
	DisplayServer.window_set_mode(
		(
			DisplayServer.WINDOW_MODE_WINDOWED
			if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
			else DisplayServer.WINDOW_MODE_FULLSCREEN
		)
	)
	if open_screen == "settings":
		refresh_screen()
