extends GdUnitTestSuite

const SHELL := preload("res://ui_preview/main_preview.gd")
var _had_test_meta: bool
var _previous_test_meta: Variant


func before_test() -> void:
	_had_test_meta = get_tree().has_meta("simulation_test")
	_previous_test_meta = get_tree().get_meta("simulation_test") if _had_test_meta else null
	get_tree().set_meta("simulation_test", true)


func after_test() -> void:
	if _had_test_meta:
		get_tree().set_meta("simulation_test", _previous_test_meta)
	else:
		get_tree().remove_meta("simulation_test")


func _fixture() -> Node:
	var main := load("res://core/scenes/main.tscn").instantiate() as Node
	add_child(main)
	var shell: SHELL = main.get_node("MainPreview")
	shell.set_process(false)
	shell.map_view.set_process(false)
	return main


func test_shake_moves_only_map_and_restores_camera_exactly() -> void:
	var main := _fixture()
	var shell: SHELL = main.get_node("MainPreview")
	shell.select_area(31)
	var map := shell.map_view
	map._zoom_map(1, Vector2(960, 540))
	var camera := map._map_image.position
	var zoom := map._map_image.scale
	var hud := shell.hud.global_position
	var panel := shell.city_panel.global_position
	var layer := map._layer_buttons[0].global_position
	map.play_crisis_feedback()
	map._process(0.04)
	assert_bool(map._map_clip.position != Vector2.ZERO).is_true()
	assert_float(map._crisis_flash.modulate.a).is_greater(0.0)
	assert_vector(map._map_image.position).is_equal(camera)
	assert_vector(map._map_image.scale).is_equal(zoom)
	assert_vector(shell.hud.global_position).is_equal(hud)
	assert_vector(shell.city_panel.global_position).is_equal(panel)
	assert_vector(map._layer_buttons[0].global_position).is_equal(layer)
	map._process(0.5)
	assert_vector(map._map_clip.position).is_equal(Vector2.ZERO)
	assert_float(map._crisis_flash.modulate.a).is_equal(0.0)
	assert_vector(map._map_image.position).is_equal(camera)
	main.free()


func test_disabling_shake_preserves_red_flash_and_in_memory_preference() -> void:
	var main := _fixture()
	var shell: SHELL = main.get_node("MainPreview")
	assert_bool(shell._testing()).is_true()
	shell.map_view.play_crisis_feedback()
	shell.toggle_map_shake()
	assert_bool(shell.map_shake_enabled).is_false()
	shell.map_view._process(0.1)
	assert_vector(shell.map_view._map_clip.position).is_equal(Vector2.ZERO)
	assert_float(shell.map_view._crisis_flash.modulate.a).is_greater(0.0)
	shell.map_view._process(0.3)
	assert_float(shell.map_view._crisis_flash.modulate.a).is_equal(0.0)
	shell.toggle_map_shake()
	assert_bool(shell.map_shake_enabled).is_true()
	main.free()


func test_historical_event_pauses_and_feedback_does_not_replay_on_refresh() -> void:
	var main := _fixture()
	var shell: SHELL = main.get_node("MainPreview")
	shell.sim.advance_to(CalendarClock.date_to_day("1951-04-08"))
	assert_bool(shell.sim.paused).is_true()
	assert_float(shell.map_view._feedback_elapsed).is_equal(0.0)
	shell.map_view._process(0.08)
	shell._refresh_views()
	shell.sim.notification_requested.emit()
	assert_float(shell.map_view._feedback_elapsed).is_equal(0.08)
	assert_str(shell.open_screen).is_equal("newspaper")
	main.free()


func test_multi_area_event_is_deduplicated_by_historical_event_id() -> void:
	var main := _fixture()
	var shell: SHELL = main.get_node("MainPreview")
	var event: Dictionary
	for item: Dictionary in shell.sim.historical.events:
		if item.date == "2023-02-06":
			event = item
			break
	# The notification fixture isolates feedback from the decades of simulation before this event.
	shell.sim.crises.begin(event)
	assert_bool(shell.sim.crises.active.size() > 1).is_true()
	shell.sim.news_queue.append({"kind": "newspaper", "id": event.id})
	shell.sim.notification_requested.emit()
	shell.map_view._process(0.12)
	for _target: Dictionary in shell.sim.crises.active:
		shell.sim.notification_requested.emit()
	assert_float(shell.map_view._feedback_elapsed).is_equal(0.12)
	assert_int(shell._feedback_event_ids.count(event.id)).is_equal(1)
	main.free()


func test_resuming_seeds_seen_events_without_replaying_existing_news() -> void:
	var main := _fixture()
	var shell: SHELL = main.get_node("MainPreview")
	var restored := Simulation.new()
	assert_bool(restored.setup()).is_true()
	restored.advance_to(CalendarClock.date_to_day("1951-04-08"))
	shell.sim = restored
	shell._bind_simulation(true)
	shell._refresh_views()
	assert_float(shell.map_view._feedback_elapsed).is_equal(shell.map_view.FEEDBACK_SECONDS)
	shell.start_campaign(1950)
	shell.sim.advance_to(CalendarClock.date_to_day("1951-04-08"))
	assert_float(shell.map_view._feedback_elapsed).is_equal(0.0)
	main.free()
