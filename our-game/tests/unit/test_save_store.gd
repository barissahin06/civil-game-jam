extends GdUnitTestSuite

const TEST_PATH := "user://test-save-store-isolated.json"
const TEST_SLOT_DIRECTORY := "user://test-save-slots-isolated"


func after_test() -> void:
	for suffix: String in ["", ".tmp"]:
		_remove_test_path(TEST_PATH + suffix)
	var store := SaveStore.new()
	store.slot_directory = TEST_SLOT_DIRECTORY
	for slot in range(4):
		for suffix: String in ["", ".tmp"]:
			_remove_test_path(store.slot_path(slot) + suffix)
	_remove_test_path(TEST_SLOT_DIRECTORY)


func _remove_test_path(path: String) -> void:
	if (
		FileAccess.file_exists(path)
		or DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(path))
	):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _slot_store() -> SaveStore:
	var store := SaveStore.new()
	store.slot_directory = TEST_SLOT_DIRECTORY
	(
		assert_int(
			DirAccess.make_dir_recursive_absolute(
				ProjectSettings.globalize_path(TEST_SLOT_DIRECTORY)
			)
		)
		. is_equal(OK)
	)
	return store


func _fixture() -> Simulation:
	var sim := Simulation.new()
	assert_bool(sim.setup()).is_true()
	return sim


func _crisis_fixture() -> Simulation:
	var sim := _fixture()
	sim.advance_to(CalendarClock.date_to_day("1951-04-08"))
	sim.acknowledge()
	return sim


func _canonical(data: Dictionary) -> String:
	return JSON.stringify(JSON.parse_string(JSON.stringify(data)))


func _round_trip(sim: Simulation) -> void:
	var store := SaveStore.new()
	var restored := store.restore(JSON.parse_string(JSON.stringify(sim.to_dict())))
	assert_object(restored).is_not_null()
	if restored != null:
		assert_str(_canonical(restored.to_dict())).is_equal(_canonical(sim.to_dict()))
		assert_bool(restored.paused).is_true()


func test_negative_epoch_new_campaign_and_active_projects_round_trip() -> void:
	var sim := _fixture()
	assert_bool(sim.clock.day < 0).is_true()
	assert_bool(sim.start_project("river_zoning", 34).ok).is_true()
	sim.advance_to(CalendarClock.date_to_day("1950-04-01"))
	sim.projects.pause(sim.projects.projects.front().uid)
	_round_trip(sim)


func test_outbound_deployed_local_and_returning_resources_round_trip() -> void:
	var sim := _crisis_fixture()
	var crisis: Dictionary = sim.crises.active.front()
	assert_bool(sim.dispatch(6, crisis.id, "team", 1).ok).is_true()
	assert_bool(sim.dispatch(31, crisis.id, "team", 1).ok).is_true()
	assert_bool(sim.dispatch(31, crisis.id, "stock", 10).ok).is_true()
	_round_trip(sim)
	sim.advance_to(sim.clock.day + 2)
	_round_trip(sim)
	sim.advance_to(int(crisis.start) + int(crisis.window))
	assert_int(sim.crises.reports.size()).is_equal(1)
	_round_trip(sim)
	sim.acknowledge()
	sim.advance_to(sim.clock.day + 3)
	_round_trip(sim)


func test_shipment_arriving_after_window_and_local_zero_day_return_round_trip() -> void:
	var sim := _crisis_fixture()
	var crisis: Dictionary = sim.crises.active.front()
	sim.dispatch(31, crisis.id, "team", 1)
	sim.advance_to(int(crisis.start) + int(crisis.window) - 1)
	sim.dispatch(34, crisis.id, "team", 1)
	sim.advance_to(sim.clock.day + 1)
	assert_str(sim.logistics.shipments[0].state).is_equal("done")
	assert_int(sim.areas[31].teams).is_equal(1)
	_round_trip(sim)
	sim.acknowledge()
	sim.advance_to(sim.clock.day + 2)
	_round_trip(sim)


func test_bad_event_area_names_reports_and_missing_records_are_rejected() -> void:
	var sim := _crisis_fixture()
	var store := SaveStore.new()
	var bad := sim.to_dict().duplicate(true)
	bad.active[0].area_id = 6
	bad.active[0].id = String(bad.active[0].event_id) + "-6"
	assert_object(store.restore(bad)).is_null()
	bad = sim.to_dict().duplicate(true)
	bad.active[0].name = "Uydurma olay"
	assert_object(store.restore(bad)).is_null()
	bad = sim.to_dict().duplicate(true)
	bad.active.clear()
	assert_object(store.restore(bad)).is_null()
	var crisis: Dictionary = sim.crises.active.front()
	sim.advance_to(int(crisis.start) + int(crisis.window))
	bad = sim.to_dict().duplicate(true)
	bad.reports[0].id = "unknown-31"
	assert_object(store.restore(bad)).is_null()
	bad = sim.to_dict().duplicate(true)
	bad.reports[0].name = "Yanlış ad"
	assert_object(store.restore(bad)).is_null()
	bad = sim.to_dict().duplicate(true)
	bad.reports[0].day += 1
	assert_object(store.restore(bad)).is_null()


func test_resource_reservations_targets_and_arrival_states_are_rejected() -> void:
	var sim := _crisis_fixture()
	var crisis: Dictionary = sim.crises.active.front()
	sim.dispatch(6, crisis.id, "team", 1)
	var store := SaveStore.new()
	var bad := sim.to_dict().duplicate(true)
	bad.shipments[0].target = 34
	assert_object(store.restore(bad)).is_null()
	bad = sim.to_dict().duplicate(true)
	bad.shipments[0].arrival = sim.clock.day
	assert_object(store.restore(bad)).is_null()
	bad = sim.to_dict().duplicate(true)
	bad.shipments[0].state = "deployed"
	assert_object(store.restore(bad)).is_null()
	bad = sim.to_dict().duplicate(true)
	bad.areas[0].teams += 1
	assert_object(store.restore(bad)).is_null()
	sim.advance_to(sim.clock.day + 2)
	bad = sim.to_dict().duplicate(true)
	bad.active[0].teams = 0
	assert_object(store.restore(bad)).is_null()


func test_future_duplicate_news_bad_scalars_and_changed_catalog_are_rejected() -> void:
	var sim := _crisis_fixture()
	var store := SaveStore.new()
	var bad := sim.to_dict().duplicate(true)
	bad.news_queue = [{"kind": "newspaper", "id": sim.historical.events.back().id}]
	assert_object(store.restore(bad)).is_null()
	bad = sim.to_dict().duplicate(true)
	var id: String = sim.historical.events.front().id
	bad.news_queue = [{"kind": "newspaper", "id": id}, {"kind": "newspaper", "id": id}]
	assert_object(SaveStore.new().restore(bad)).is_null()
	bad.news_queue = [{"kind": "research_done", "id": "research_structural"}]
	assert_object(store.restore(bad)).is_null()
	for key: String in ["money", "income", "awareness"]:
		bad = sim.to_dict().duplicate(true)
		bad[key] = "12"
		assert_object(store.restore(bad)).is_null()
	bad = sim.to_dict().duplicate(true)
	bad.catalog = "different-content"
	assert_object(store.restore(bad)).is_null()
	bad = sim.to_dict().duplicate(true)
	bad.day = CalendarClock.INVALID_DAY
	assert_object(store.restore(bad)).is_null()


func test_atomic_overwrite_and_invalid_save_keep_previous_bytes() -> void:
	var store := SaveStore.new()
	var sim := _fixture()
	assert_bool(store.save(sim, TEST_PATH)).is_true()
	assert_object(store.load_campaign(TEST_PATH)).is_not_null()
	sim.advance_to(sim.clock.next_month_day())
	assert_bool(store.save(sim, TEST_PATH)).is_true()
	var previous := FileAccess.get_file_as_bytes(TEST_PATH)
	assert_bool(FileAccess.file_exists(TEST_PATH + ".tmp")).is_false()
	sim.treasury.money = -1
	assert_bool(store.save(sim, TEST_PATH)).is_false()
	assert_bool(FileAccess.get_file_as_bytes(TEST_PATH) == previous).is_true()
	assert_object(store.load_campaign(TEST_PATH)).is_not_null()


func test_failed_temporary_write_keeps_previous_file() -> void:
	var store := SaveStore.new()
	var sim := _fixture()
	assert_bool(store.save(sim, TEST_PATH)).is_true()
	var previous := FileAccess.get_file_as_bytes(TEST_PATH)
	(
		assert_int(DirAccess.make_dir_absolute(ProjectSettings.globalize_path(TEST_PATH + ".tmp")))
		. is_equal(OK)
	)
	sim.advance_to(sim.clock.next_month_day())
	assert_bool(store.save(sim, TEST_PATH)).is_false()
	assert_bool(FileAccess.get_file_as_bytes(TEST_PATH) == previous).is_true()
	assert_object(store.load_campaign(TEST_PATH)).is_not_null()


func test_parallel_multi_area_event_and_2026_ending_round_trip() -> void:
	var sim := Simulation.new()
	assert_bool(sim.setup(1990)).is_true()
	var ending := CalendarClock.date_to_day(Simulation.END_DATE)
	var checked_parallel := false
	var safety := 0
	while sim.outcome.is_empty() and safety < 1000:
		sim.news_queue.clear()
		sim.trust.value = 100.0
		sim.advance_to(ending)
		if sim.crises.active.size() > 1 and not checked_parallel:
			_round_trip(sim)
			checked_parallel = true
		safety += 1
	assert_bool(checked_parallel).is_true()
	assert_str(sim.outcome).is_equal("ending")
	_round_trip(sim)


func test_slot_paths_keep_legacy_autosave_and_reject_out_of_range_ids() -> void:
	var store := SaveStore.new()
	assert_str(store.slot_path(0)).is_equal(SaveStore.PATH)
	for slot in range(1, 4):
		assert_str(store.slot_path(slot)).is_equal("user://manual_%d_v1.json" % slot)
	for slot: int in [-100, -1, 4, 100]:
		assert_str(store.slot_path(slot)).is_empty()
	store.slot_directory = TEST_SLOT_DIRECTORY
	assert_str(store.slot_path(0)).is_equal(TEST_SLOT_DIRECTORY + "/campaign_v1.json")
	assert_str(store.slot_path(3)).is_equal(TEST_SLOT_DIRECTORY + "/manual_3_v1.json")


func test_slot_summaries_are_fixed_and_do_not_create_missing_files() -> void:
	var store := _slot_store()
	store.error = "Previous command error"
	var summaries := store.slot_summaries()
	assert_int(summaries.size()).is_equal(4)
	for slot in range(4):
		var summary: Dictionary = summaries[slot]
		assert_int(summary.slot).is_equal(slot)
		assert_bool(summary.exists).is_false()
		assert_bool(summary.valid).is_false()
		assert_str(summary.game_date).is_empty()
		assert_int(summary.start_year).is_equal(0)
		assert_int(summary.saved_at).is_equal(0)
		assert_str(summary.error).is_empty()
		assert_bool(FileAccess.file_exists(store.slot_path(slot))).is_false()
	assert_str(store.error).is_equal("Previous command error")


func test_slot_summaries_validate_contents_and_preserve_corrupt_bytes() -> void:
	var store := _slot_store()
	var sim := _fixture()
	assert_bool(store.save(sim, store.slot_path(0))).is_true()
	var later := Simulation.new()
	assert_bool(later.setup(1990)).is_true()
	assert_bool(store.save(later, store.slot_path(1))).is_true()
	var corrupt := FileAccess.open(store.slot_path(2), FileAccess.WRITE)
	corrupt.store_string("{ invalid campaign")
	corrupt.close()
	var corrupt_bytes := FileAccess.get_file_as_bytes(store.slot_path(2))
	store.error = "Keep visible command failure"
	var summaries := store.slot_summaries()
	assert_bool(summaries[0].valid).is_true()
	assert_str(summaries[0].game_date).is_equal("1950-01-01")
	assert_int(summaries[0].start_year).is_equal(1950)
	assert_int(summaries[0].saved_at).is_greater(0)
	assert_bool(summaries[1].valid).is_true()
	assert_str(summaries[1].game_date).is_equal("1990-01-01")
	assert_int(summaries[1].start_year).is_equal(1990)
	assert_bool(summaries[2].exists).is_true()
	assert_bool(summaries[2].valid).is_false()
	assert_bool(String(summaries[2].error).is_empty()).is_false()
	assert_bool(summaries[3].exists).is_false()
	assert_bool(FileAccess.get_file_as_bytes(store.slot_path(2)) == corrupt_bytes).is_true()
	assert_str(store.error).is_equal("Keep visible command failure")


func test_manual_slot_overwrite_never_changes_autosave_or_other_slots() -> void:
	var store := _slot_store()
	var sim := _fixture()
	for slot in range(4):
		assert_bool(store.save(sim, store.slot_path(slot))).is_true()
	var originals: Array[PackedByteArray] = []
	for slot in range(4):
		originals.append(FileAccess.get_file_as_bytes(store.slot_path(slot)))
	sim.advance_to(sim.clock.next_month_day())
	assert_bool(store.save(sim, store.slot_path(1))).is_true()
	var restored := store.load_campaign(store.slot_path(1))
	assert_object(restored).is_not_null()
	if restored != null:
		assert_str(_canonical(restored.to_dict())).is_equal(_canonical(sim.to_dict()))
	for slot: int in [0, 2, 3]:
		(
			assert_bool(FileAccess.get_file_as_bytes(store.slot_path(slot)) == originals[slot])
			. is_true()
		)
	assert_bool(FileAccess.file_exists(store.slot_path(1) + ".tmp")).is_false()
	sim.treasury.money = -1
	var previous := FileAccess.get_file_as_bytes(store.slot_path(1))
	assert_bool(store.save(sim, store.slot_path(1))).is_false()
	assert_bool(FileAccess.get_file_as_bytes(store.slot_path(1)) == previous).is_true()
	assert_bool(FileAccess.get_file_as_bytes(store.slot_path(0)) == originals[0]).is_true()


func test_oversized_slot_is_visible_but_never_loadable() -> void:
	var store := _slot_store()
	var file := FileAccess.open(store.slot_path(3), FileAccess.WRITE)
	file.seek(SaveStore.MAX_FILE_BYTES)
	file.store_8(0)
	file.close()
	var summaries := store.slot_summaries()
	assert_bool(summaries[3].exists).is_true()
	assert_bool(summaries[3].valid).is_false()
	assert_bool(String(summaries[3].error).is_empty()).is_false()
	var preserved := FileAccess.open(store.slot_path(3), FileAccess.READ)
	assert_int(preserved.get_length()).is_equal(SaveStore.MAX_FILE_BYTES + 1)
	preserved.close()


func test_completed_research_story_in_news_queue_round_trips() -> void:
	var sim := _fixture()
	sim.projects.global_completed.append("research_structural")
	sim.news_queue.append({"kind": "research_done", "id": "research_structural"})
	_round_trip(sim)
