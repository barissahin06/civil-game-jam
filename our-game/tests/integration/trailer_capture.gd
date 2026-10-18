extends "res://tests/integration/gameplay_ui.gd"
## Trailer footage driver: plays a real 1950 campaign with glided mouse input for Movie Maker.
## Not part of verify. Run (no --headless):
##   Godot --path our-game --resolution 1920x1080 --write-movie <abs.avi> --fixed-fps 60 \
##     --script res://tests/integration/trailer_capture.gd -- --marks <abs.json>

const CURSOR_ARROW := preload("res://ui_preview/assets/cursor_arrow.png")
const CURSOR_POINT := preload("res://ui_preview/assets/cursor_pointing.png")
const CURSOR_MOVE := preload("res://ui_preview/assets/cursor_move.png")
const FPS := 60.0

var _pointer: Vector2 = Vector2(1500, 900)
var _cursor: Sprite2D
var _marks: Dictionary = {}
var _marks_path: String = ""


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var at := args.find("--marks")
	if at >= 0 and at + 1 < args.size():
		_marks_path = args[at + 1]
	root.size = Vector2i(1920, 1080)
	root.content_scale_size = root.size
	_main = load("res://ui_preview/scenes/main_preview.tscn").instantiate()
	root.add_child(_main)
	await process_frame
	_shell = _main
	_shell.auto_save_enabled = false
	_shell.saves.slot_directory = _test_save_dir
	# The edit uses its own music; keep the game's effects only. Never write the player's prefs.
	_shell.audio.preferences_path = ""
	if _shell.audio.music_enabled:
		_shell.audio.toggle_music_enabled()
	_make_cursor()
	_shell.return_to_main_menu()
	await _wait(0.4)
	await _scene_menu()
	var points := _province_points()
	await _scene_city(points)
	await _scene_research()
	await _scene_prepare(points)
	await _scene_time_to_crisis()
	await _scene_dispatch(points)
	await _scene_report()
	await _scene_parallel()
	await _scene_decision()
	_mark("end")
	_write_marks()
	await _shell.audio.shutdown()
	_main.queue_free()
	await process_frame
	print("TRAILER_CAPTURE_PASS: ", _marks)
	quit()


func _make_cursor() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 128
	root.add_child(layer)
	_cursor = Sprite2D.new()
	_cursor.centered = false
	_cursor.texture = CURSOR_ARROW
	layer.add_child(_cursor)
	_place_cursor()


func _place_cursor() -> void:
	var hovered: Control = (
		root.gui_get_hovered_control() if root.has_method("gui_get_hovered_control") else null
	)
	if root.gui_is_dragging():
		_cursor.texture = CURSOR_MOVE
		_cursor.position = _pointer - Vector2(15, 15)
	elif hovered is BaseButton and not (hovered as BaseButton).disabled:
		_cursor.texture = CURSOR_POINT
		_cursor.position = _pointer - Vector2(12, 3)
	else:
		_cursor.texture = CURSOR_ARROW
		_cursor.position = _pointer - Vector2(3, 3)


func _mark(label: String) -> void:
	_marks[label] = snappedf(Engine.get_frames_drawn() / FPS, 0.001)
	print("TRAILER_MARK ", label, " ", _marks[label])


func _write_marks() -> void:
	if _marks_path.is_empty():
		return
	var file := FileAccess.open(_marks_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(_marks, "\t"))
	file.close()


func _wait(seconds: float) -> void:
	for _frame in range(maxi(1, roundi(seconds * FPS))):
		await process_frame
		_place_cursor()


func _motion(point: Vector2, mask: int) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point
	event.global_position = point
	event.relative = point - _pointer
	event.button_mask = mask
	root.warp_mouse(point)
	_pointer = point
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _glide(to: Vector2, seconds: float, mask: int = 0) -> void:
	var from := _pointer
	var steps := maxi(1, roundi(seconds * FPS))
	for step in range(1, steps + 1):
		var t := float(step) / steps
		_motion(from.lerp(to, t * t * (3.0 - 2.0 * t)), mask)
		await process_frame
		_place_cursor()


func _tap(point: Vector2) -> void:
	await _glide(point, 0.55)
	_mouse(point, true)
	await _wait(0.1)
	_mouse(point, false)
	await _wait(0.3)


func _go(title: String, optional: bool = false) -> bool:
	var button := _find_button(_shell._modal if is_instance_valid(_shell._modal) else _main, title)
	if button == null:
		button = _find_button(_main, title)
	if button == null or button.disabled:
		print("TRAILER_MISSING: ", title)
		assert(optional, "Missing trailer button: " + title)
		return false
	var center := button.get_global_rect().get_center()
	await _tap(center)
	# Leave the HUD time buttons so their hover tooltip never covers the top bar.
	if center.y < 130.0 and center.x > 1500.0:
		await _glide(Vector2(960, 640), 0.35)
	return true


func _drag_glide(from: Vector2, to: Vector2) -> void:
	await _glide(from, 0.5)
	_mouse(from, true)
	await _wait(0.08)
	await _glide(from + Vector2(40, -10), 0.15, MOUSE_BUTTON_MASK_LEFT)
	await _glide(to, 1.1, MOUSE_BUTTON_MASK_LEFT)
	await _wait(0.15)
	_mouse(to, false)
	await _wait(0.4)


func _wait_until(done: Callable, max_seconds: float) -> bool:
	for _frame in range(roundi(max_seconds * FPS)):
		if done.call():
			return true
		await process_frame
		_place_cursor()
	return false


func _province_points() -> Dictionary:
	var hit: Image = _shell.map_view._hit_image
	var points: Dictionary = {}
	for y in range(300, 1400, 3):
		for x in range(800, 2500, 3):
			var id := roundi(hit.get_pixel(x, y).r * 255.0)
			if id > 0 and not points.has(id):
				var point := Vector2(x, y) + _shell.map_view._map_image.position
				if Rect2(440, 230, 1450, 680).has_point(point):
					points[id] = point
	return points


func _scene_menu() -> void:
	_mark("menu")
	await _wait(2.2)
	await _go("YENİ OYUN")
	_shell.campaign.start_year = 1950
	_shell.refresh_screen()
	await _wait(1.6)
	await _go("YENİ OYUNU BAŞLAT")
	if _shell.open_screen == "newgame":
		await _go("OTOMATİK KAYDIN YERİNE BAŞLAT")
	await _wait(0.8)
	await _go("REHBERİ ATLA")
	await _wait(0.6)


func _scene_city(points: Dictionary) -> void:
	_mark("map")
	await _wait(1.6)
	await _tap(points[31])
	await _wait(1.0)
	await _go("YATIRIM")
	await _wait(0.8)
	await _go("İNCELE")
	await _wait(2.2)
	_mark("project")
	await _go("BAŞLAT")
	await _wait(0.6)
	await _go("KAPAT")
	await _wait(0.4)


func _scene_research() -> void:
	_mark("research")
	await _go("YATIRIM VE ARAŞTIRMA")
	await _go("ARAŞTIRMALAR 0/2")
	await _wait(1.8)
	await _go("İNCELE")
	await _wait(1.4)
	await _go("BAŞLAT")
	await _wait(0.5)
	await _go("KAPAT")
	await _wait(0.4)


func _scene_prepare(points: Dictionary) -> void:
	_mark("prepare")
	await _go("EKİP VE YARDIM HAZIRLA")
	await _wait(0.6)
	await _go("EKİP KUR")
	for id: int in [1, 6, 21]:
		if points.has(id):
			await _tap(points[id])
	await _go("YARDIM HAZIRLA")
	for id: int in [31, 6]:
		if points.has(id):
			await _tap(points[id])
	await _wait(0.8)
	await _go("×", true)
	await _wait(0.4)


func _scene_time_to_crisis() -> void:
	_mark("time")
	await _go("4×")
	await _go("ZAMANI BAŞLAT")
	var opened := await _wait_until(func() -> bool: return _shell.open_screen == "newspaper", 60.0)
	assert(opened, "The first historical disaster did not open its newspaper")
	_mark("newspaper")
	await _wait(3.2)
	await _go("HABERİ OKUDUM")
	await _wait(1.0)


func _scene_dispatch(points: Dictionary) -> void:
	_mark("dispatch")
	_shell.close_screen()
	_shell.select_area(1)
	_shell.city_panel.select_tab(2)
	await _wait(1.0)
	var drag := _find_button(_main, "1 EKİP SÜRÜKLE")
	await _drag_glide(drag.get_global_rect().get_center(), points[31])
	await _wait(0.7)
	drag = _find_button(_main, "10 BİRİM MALZEME SÜRÜKLE")
	await _drag_glide(drag.get_global_rect().get_center(), points[31])
	await _wait(0.7)
	_mark("convoy")
	await _go("1×")
	await _go("ZAMANI BAŞLAT")
	await _wait(4.0)
	_shell.sim.set_paused(true)
	_shell.show_screen("crisis")
	await _wait(0.8)
	for kind in ["EKİP SEÇ", "MALZEME SEÇ"]:
		await _go(kind)
		if kind == "MALZEME SEÇ":
			await _go("İHTİYACA GÖRE AYARLA", true)
		await _go("GÖNDERİMİ ONAYLA", true)
		await _wait(0.6)
	await _go("ACİL BÜTÇE")
	await _wait(0.8)
	await _go("₺1,0 M AKTAR")
	await _wait(0.6)
	await _go("AFET MÜDAHALESİNE DÖN")
	await _wait(1.2)


func _scene_report() -> void:
	_mark("report_run")
	await _go("4×")
	await _go("ZAMANI BAŞLAT", true)
	var limit := Engine.get_frames_drawn() + roundi(100.0 * FPS)
	# Daily-supply stops are part of play: resupply to the need, resume, repeat until the report.
	while _shell.open_screen != "report" and Engine.get_frames_drawn() < limit:
		if _shell.sim.paused and _shell.open_screen in ["", "crisis"]:
			print("TRAILER_NOTE: paused on '", _shell.open_screen, "'; resupplying")
			await _resupply()
			await _go("ZAMANI BAŞLAT", true)
		await _wait(0.25)
	assert(_shell.open_screen == "report", "The first disaster never produced its report")
	_mark("report")
	await _wait(3.0)
	await _go("AYRINTILAR", true)
	await _wait(1.6)
	await _go("ONARIMI İNCELE", true)
	await _wait(1.0)
	await _go("BAŞLAT", true)
	await _wait(0.6)
	_shell.close_screen()
	await _wait(0.4)


func _resupply() -> void:
	_shell.show_screen("crisis")
	await _wait(0.4)
	await _go("MALZEME SEÇ", true)
	await _go("İHTİYACA GÖRE AYARLA", true)
	await _go("GÖNDERİMİ ONAYLA", true)
	await _wait(0.3)


func _scene_parallel() -> void:
	_mark("parallel")
	# Two more archive disasters at once, as in the crisis pilot; the clock stays paused.
	_shell.sim.set_paused(true)
	_shell.sim.crises.begin(_shell.sim.historical.events[1])
	_shell.sim.crises.begin(_shell.sim.historical.events[2])
	_shell.sim.changed.emit()
	_shell.show_screen("crisis")
	await _wait(3.6)
	_shell.close_screen()
	await _go("HARİTA GÖRÜNÜMÜ", true)
	for mode in ["AFET HAZIRLIĞI", "YARDIM MALZEMESİ", "ALTYAPI HASARI"]:
		await _go(mode, true)
		await _wait(1.0)
	_mark("parallel_end")


func _scene_decision() -> void:
	_mark("decision")
	var sim := _seed_decision("samsun_flood")
	_shell.sim = sim
	_shell._bind_simulation(true)
	_shell.show_screen("decision")
	await _wait(2.0)
	var option := _shell._screen_content.get_node("DecisionOption_full") as Button
	await _tap(option.get_global_rect().get_center())
	await _wait(1.8)
	_mark("decision_end")


func _seed_decision(id: String) -> Simulation:
	var sim := Simulation.new()
	assert(sim.setup(1990))
	var card := sim.decisions.card_for(id)
	var event := sim.event_for(card.event_ids[0])
	var end := int(event.day) + int(event.response_window_days) + 2
	for _iteration in range(1000):
		if sim.news_queue.is_empty():
			sim.trust.value = 100.0
			sim.advance_to(end)
		elif sim.news_queue.front().kind == "decision":
			if sim.news_queue.front().id == id:
				return sim
			assert(sim.choose_decision(sim.news_queue.front().id, "decline").ok)
		else:
			sim.acknowledge()
	assert(false, "Decision fixture did not reach " + id)
	return sim
