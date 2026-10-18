extends "res://tests/integration/gameplay_ui.gd"
## Compact navigation and detail returns use the real viewport, isolated from player files.


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	root.content_scale_size = root.size
	_main = load("res://ui_preview/scenes/main_preview.tscn").instantiate()
	root.add_child(_main)
	await process_frame
	_shell = _main
	_shell.auto_save_enabled = false
	_shell.sim.tutorial_enabled = false
	var navigation: Array[String] = []
	for child in _shell.hud.get_children():
		if child is Button and child.position.y == 130:
			navigation.append(child.text)
	assert(navigation.size() == 6)
	for title: String in [
		"EKİPLER VE YARDIM",
		"AFET MÜDAHALESİ 0",
		"EKİP VE YARDIM HAZIRLA",
		"YATIRIM VE ARAŞTIRMA",
		"HABERLER VE RAPORLAR",
		"MENÜ"
	]:
		assert(title in navigation)
	await _capture("compact-overview")
	await _press_button("HABERLER VE RAPORLAR")
	await _capture("compact-events-menu")
	await _key(KEY_TAB)
	assert(root.gui_get_focus_owner().text == "SON AFET RAPORU")
	await _key(KEY_TAB)
	assert(root.gui_get_focus_owner().text == "SON HABER", "Popup focus must stay in its choices")
	await _key(KEY_DOWN)
	assert(root.gui_get_focus_owner().text == "SON AFET RAPORU")
	await _key(KEY_ESCAPE)
	assert(_shell.open_screen.is_empty() and not _main.get_node("EventsMenu").visible)
	await _press_button("HABERLER VE RAPORLAR")
	var selection: int = _shell.selected_area_id
	await _click(Vector2(1100, 180))
	assert(not _main.get_node("EventsMenu").visible and _shell.selected_area_id == selection)
	await _press_button("HABERLER VE RAPORLAR")
	await _press_button("SON AFET RAPORU")
	assert(_label("HENÜZ TAMAMLANMIŞ MÜDAHALE YOK.") != null)
	await _capture("compact-empty-report")
	await _press_button("KAPAT")
	await _press_button("YATIRIM VE ARAŞTIRMA")
	assert(_shell.open_screen == "projects")
	await _capture("compact-empty-projects")
	for index in range(9):
		assert(_shell.sim.enqueue_preparation("rescue_team", _shell.sim.areas.keys()[index]).ok)
	assert(_shell.sim.enqueue_preparation("aid_stock", _shell.sim.areas.keys()[0]).ok)
	await process_frame
	await process_frame
	var list: ScrollContainer = _shell._screen_content.get_node("ProjectList")
	assert(_visible_rows(list) >= 2, "Explained project rows must fit without smaller fonts")
	await _capture("compact-projects")
	var first: ActiveProject = _shell.sim.projects.projects.front()
	var first_row: Control = list.get_node("Rows").get_child(0)
	await _click(first_row.get_node("Priority").get_global_rect().get_center())
	assert(first.priority)
	first_row = _shell._screen_content.get_node("ProjectList/Rows").get_child(0)
	await _click(first_row.get_node("Pause").get_global_rect().get_center())
	assert(first.status == "paused")
	first_row = _shell._screen_content.get_node("ProjectList/Rows").get_child(0)
	await _click(first_row.get_node("Pause").get_global_rect().get_center())
	assert(first.status == "active")
	list = _shell._screen_content.get_node("ProjectList")
	list.scroll_vertical = int(list.get_v_scroll_bar().max_value)
	await process_frame
	var row: Control = list.get_node("Rows").get_child(-1)
	var inspect: Button = row.get_node("Inspect")
	inspect.grab_focus()
	var scroll: int = list.scroll_vertical
	_shell.sim.changed.emit()
	await process_frame
	await process_frame
	list = _shell._screen_content.get_node("ProjectList")
	assert(list.scroll_vertical == scroll)
	assert(root.gui_get_focus_owner() == list.get_node("Rows").get_child(-1).get_node("Inspect"))
	await _click(root.gui_get_focus_owner().get_global_rect().get_center())
	assert(_shell.open_screen == "project")
	assert(
		_find_button(_shell._modal, "BAŞLAT") == null,
		"Preparation details must not introduce a second production entry"
	)
	await _press_button("GERİ")
	assert(_shell.open_screen == "projects")
	list = _shell._screen_content.get_node("ProjectList")
	assert(list.scroll_vertical == scroll)
	var queued: ActiveProject = _shell.sim.projects.projects.back()
	var money: int = _shell.sim.treasury.money
	row = list.get_node("Rows").get_child(-1)
	await _click(row.get_node("Cancel").get_global_rect().get_center())
	assert(queued.status == "queued", "First cancel click only requests confirmation")
	await _capture("project-cancel-confirmation")
	row = _shell._screen_content.get_node("ProjectList/Rows").get_child(-1)
	await _click(row.get_node("Cancel").get_global_rect().get_center())
	assert(queued.status == "cancelled" and _shell.sim.treasury.money == money)
	await _press_button("ÖNLEMLER")
	await _capture("compact-national")
	await _press_button("İNCELE")
	await _press_button("GERİ")
	assert(_shell.open_screen == "national")
	await _press_button("ARAŞTIRMALAR 0/2")
	await _press_button("LOJİSTİK VE MÜDAHALE")
	var research_focus: String = _find_button(_shell._modal, "İNCELE").name
	await _press_button("İNCELE")
	await _press_button("GERİ")
	assert(_shell.open_screen == "research" and _shell.research.selected_tab == 2)
	assert(root.gui_get_focus_owner() != null and root.gui_get_focus_owner().name == research_focus)
	await _capture("compact-research")
	await _key(KEY_ESCAPE)
	await _key(KEY_ESCAPE)
	assert(_shell.open_screen == "research" and _shell.research.selected_tab == 2)
	await _press_button("KAPAT")
	await _press_button("YATIRIM VE ARAŞTIRMA")
	assert(_shell.open_screen == "research", "Reopening Gelişim remembers its tab")
	await _press_button("KAPAT")
	_shell.select_area(31)
	await _press_button("YATIRIM")
	var investments: ScrollContainer = _shell.city_panel.find_child("InvestmentList", true, false)
	assert(investments != null and _visible_rows(investments) >= 2)
	for investment_row: Control in investments.get_child(0).get_children():
		var inspect_button: Button = investment_row.get_node("Inspect")
		assert(
			Rect2(Vector2.ZERO, investment_row.size).encloses(inspect_button.get_rect()),
			"Investment action must fit its row at native font size"
		)
	assert(_find_button(_shell.city_panel, "EKİP KUR") == null)
	assert(investments.find_child("rescue_team", true, false) == null)
	assert(investments.find_child("aid_stock", true, false) == null)
	await _capture("compact-city-investments")
	investments.scroll_vertical = int(investments.get_v_scroll_bar().max_value)
	await process_frame
	scroll = investments.scroll_vertical
	_shell.sim.changed.emit()
	await process_frame
	await process_frame
	assert(investments.scroll_vertical == scroll)
	var last_row: Control = investments.get_child(0).get_child(-1)
	inspect = last_row.get_node("Inspect")
	await _click(inspect.get_global_rect().get_center())
	await _press_button("GERİ")
	assert(_shell.city_panel.selected_tab == 1 and investments.scroll_vertical == scroll)
	assert(root.gui_get_focus_owner() == inspect)
	await _press_button("GÖNDERİM")
	assert(_find_button(_shell.city_panel, "EKİP KUR") == null)
	assert(_find_button(_shell.city_panel, "STOK HAZIRLA") == null)
	assert(_find_button(_shell.city_panel, "AFET MÜDAHALESİ") == null)
	assert(_find_button(_shell.city_panel, "GÖNDERİM HAZIRLA") != null)
	await _capture("compact-city-logistics")
	await _shell.audio.shutdown()
	_main.queue_free()
	await process_frame
	print(
		"COMPACTION_UI_PASS: six entries, event popup, compact lists, detail return, focus/scroll, unique preparation entry"
	)
	quit()


func _visible_rows(scroll: ScrollContainer) -> int:
	var count := 0
	for row: Control in scroll.get_child(0).get_children():
		if scroll.get_global_rect().encloses(row.get_global_rect()):
			count += 1
	return count


func _key(key: Key) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = key
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
	await process_frame
	await process_frame


func _label(content: String) -> Label:
	for node in _shell._screen_content.find_children("*", "Label", true, false):
		if node.text == content:
			return node
	return null
