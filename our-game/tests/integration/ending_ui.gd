extends "res://tests/integration/gameplay_ui.gd"
## Destructive-flow tests use only a per-process test directory.


class RejectingClear:
	extends SaveStore

	func clear_campaign_slots() -> bool:
		error = "Test: bazı kayıtlar silinemedi. Silme kısmen gerçekleşmiş olabilir. Yeniden dene."
		return false


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	root.content_scale_size = root.size
	_test_save_dir = "user://test-ending-%d" % OS.get_process_id()
	_main = load("res://ui_preview/scenes/main_preview.tscn").instantiate()
	root.add_child(_main)
	await process_frame
	_shell = _main
	_shell.saves.slot_directory = _test_save_dir
	assert(
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_test_save_dir)) == OK
	)
	_shell.start_campaign(1950)
	_shell.sim.guide.close()
	assert(_shell.sim.start_project("river_zoning", 31).ok)
	_shell.sim.advance_to(CalendarClock.date_to_day("1951-04-08"))
	await process_frame
	var queue := _shell.sim.news_queue.duplicate(true)
	var before: Array[String] = []
	for slot in range(4):
		assert(_shell.saves.save(_shell.sim, _shell.saves.slot_path(slot)))
		before.append(FileAccess.get_file_as_string(_shell.saves.slot_path(slot)))
	await _key(KEY_ESCAPE)
	await _press_button("OYUNU BİTİR")
	assert(_shell.open_screen == "finish_confirm")
	var focused := root.gui_get_focus_owner() as Button
	assert(focused != null and focused.text == "VAZGEÇ")
	_check_button_tone("KAYITLARI SİL VE BİTİR", UI.ButtonTone.DANGER)
	await _capture("ending-confirm")
	await _key(KEY_ESCAPE)
	assert(_shell.open_screen == "pause" and _shell.sim.news_queue == queue)
	for slot in range(4):
		assert(FileAccess.get_file_as_string(_shell.saves.slot_path(slot)) == before[slot])
	var real_store := _shell.saves
	var rejecting := RejectingClear.new()
	rejecting.slot_directory = _test_save_dir
	_shell.saves = rejecting
	_shell.auto_save_enabled = true
	await _press_button("OYUNU BİTİR")
	await _press_button("KAYITLARI SİL VE BİTİR")
	assert(_shell.open_screen == "finish_confirm" and not _shell.campaign_finished)
	assert(not _shell.auto_save_enabled and not _shell._save())
	assert(_shell.ending.notice.contains("kısmen"))
	await _press_button("VAZGEÇ")
	assert(_shell.auto_save_enabled and _shell.open_screen == "pause")
	_shell.auto_save_enabled = false
	_shell.saves = real_store
	await _press_button("OYUNU BİTİR")
	await _press_button("KAYITLARI SİL VE BİTİR")
	assert(_shell.open_screen == "retrospective" and _shell.campaign_finished)
	assert(_shell.sim.paused and _shell.sim.news_queue == queue)
	assert(not _shell.tour.visible)
	await _capture("ending-front")
	await _press_button("AFETLER")
	await _capture("ending-events")
	await _press_button("BIRAKILAN MİRAS")
	await _capture("ending-legacy")
	await _key(KEY_ESCAPE)
	_shell.show_screen("save")
	assert(_shell.open_screen == "retrospective")
	assert(not _shell.save_campaign_slot(1).ok and not _shell._save())
	_shell._mark_dirty()
	_shell._process(11.0)
	_assert_empty_slots()
	await _press_button("ANA MENÜYE DÖN")
	assert(_shell.in_frontend and _find_button(_shell._modal, "KAYITTAN DEVAM ET").disabled)
	_assert_empty_slots()
	await _check_natural_endings()
	await _check_completed_newspaper()
	await _check_empty_and_long_newspapers()
	_shell.auto_save_enabled = false
	await _shell.audio.shutdown()
	_main.queue_free()
	await process_frame
	_clear_test_slots()
	print(
		"ENDING_UI_PASS: confirm/cancel/failure, four slots, frozen ending, natural endings, empty/long newspaper; captures=",
		_capture_count
	)
	quit()


func _assert_empty_slots() -> void:
	for slot in range(4):
		assert(not FileAccess.file_exists(_shell.saves.slot_path(slot)))


func _key(code: Key) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
	await process_frame
	await process_frame


func _check_natural_endings() -> void:
	for reason: String in ["ending", "defeat"]:
		_shell.start_campaign(1990)
		_shell.sim.guide.close()
		if reason == "ending":
			_shell.sim._event_index = _shell.sim.historical.events.size()
			_shell.sim.clock.set_day(CalendarClock.date_to_day("2026-12-31"))
		else:
			_shell.sim.trust.value = 0.0
		_shell.sim._check_ending()
		# A marker file proves natural endings do not invoke save deletion.
		var file := FileAccess.open(_shell.saves.slot_path(1), FileAccess.WRITE)
		file.store_string("natural-ending-marker")
		file.close()
		_shell._refresh_views()
		assert(_shell.open_screen == reason and not _shell.campaign_finished)
		await _key(KEY_ESCAPE)
		assert(_shell.open_screen == reason)
		await _capture("ending-" + reason)
		await _press_button("ANA MENÜYE DÖN")
		assert(FileAccess.get_file_as_string(_shell.saves.slot_path(1)) == "natural-ending-marker")


func _check_empty_and_long_newspapers() -> void:
	_shell.start_campaign(1950)
	_shell.sim.guide.close()
	_shell.request_campaign_finish()
	_shell.confirm_campaign_finish()
	await _capture("ending-empty")
	var snapshot: Dictionary = _shell.ending.summary.duplicate(true)
	for index in range(99):
		snapshot.events.append(
			{
				"date": "2026-12-31",
				"name": "Uzun kampanya / çok merkezli afet değerlendirmesi %d" % index,
				"active": false,
				"rescued": 1234,
				"protected": 5678,
				"prevented_losses": 12,
				"prevented_damage": 2500000,
				"losses": 23
			}
		)
	_shell.ending.open(snapshot)
	_shell.refresh_screen()
	await _press_button("AFETLER")
	var list: ScrollContainer = _shell._screen_content.get_node("EndingList")
	await process_frame
	assert(list.get_v_scroll_bar().max_value > list.size.y)
	for index in range(6):
		await _effect_wheel(list.get_global_rect().get_center())
	assert(list.scroll_vertical > 0)
	var position := list.scroll_vertical
	await _press_button("BIRAKILAN MİRAS")
	await _press_button("AFETLER")
	await process_frame
	list = _shell._screen_content.get_node("EndingList")
	assert(list.scroll_vertical == position)
	await _capture("ending-long-events")


func _check_completed_newspaper() -> void:
	_shell.start_campaign(1950)
	_shell.sim.guide.close()
	assert(_shell.sim.start_project("river_zoning", 31).ok)
	_shell.sim.advance_to(CalendarClock.date_to_day("1951-04-08"))
	_shell.sim.acknowledge()
	var crisis: Dictionary = _shell.sim.crises.active.front()
	assert(_shell.sim.dispatch(31, crisis.id, "team", 1).ok)
	assert(_shell.sim.dispatch(31, crisis.id, "stock", 20).ok)
	_shell.sim.advance_to(int(crisis.start) + int(crisis.window))
	_shell.show_screen("pause")
	_shell.request_campaign_finish()
	_shell.confirm_campaign_finish()
	assert(_shell.ending.summary.completed_event_count == 1)
	assert(not _shell.ending.summary.photo_event.is_empty())
	await _capture("ending-completed")
	var snapshot: Dictionary = _shell.ending.summary.duplicate(true)
	var longest_title := ""
	for definition: MeasureDefinition in _shell.sim.projects.definitions.values():
		if definition.title.length() > longest_title.length():
			longest_title = definition.title
	snapshot.completed_projects[0].title = longest_title
	for key: String in snapshot.totals:
		snapshot.totals[key] = 1000000000000
	_shell.ending.open(snapshot)
	_shell.refresh_screen()
	await _capture("ending-large-values")
