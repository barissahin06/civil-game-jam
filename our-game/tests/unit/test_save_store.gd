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


func _previous_windows_fixture(year: int = 1950) -> Simulation:
	var sim := Simulation.new()
	assert_bool(sim.setup(year)).is_true()
	sim.content_fingerprint = SaveStore.PRE_EXTENSION_CATALOG
	for event: Dictionary in sim.historical.events:
		event.response_window_days -= SaveStore.RESPONSE_WINDOW_EXTENSION_DAYS
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


func test_previous_windows_extend_new_and_active_campaigns_without_changing_input() -> void:
	var store := SaveStore.new()
	var sim := _previous_windows_fixture()
	var data := sim.to_dict().duplicate(true)
	var restored := store.restore(data)
	assert_object(restored).is_not_null()
	if restored == null:
		return
	assert_str(restored.content_fingerprint).is_equal(_fixture().content_fingerprint)
	assert_str(restored.content_fingerprint).is_equal(SaveStore.EXTENDED_CATALOG)
	assert_int(int(restored.historical.events.front().response_window_days)).is_equal(9)
	_round_trip(restored)
	sim.advance_to(CalendarClock.date_to_day("1951-04-08"))
	sim.acknowledge()
	var crisis: Dictionary = sim.crises.active.front()
	assert_bool(sim.dispatch(31, crisis.id, "team", 1).ok).is_true()
	assert_bool(sim.dispatch(31, crisis.id, "stock", 30).ok).is_true()
	sim.advance_to(sim.clock.day + 2)
	data = sim.to_dict().duplicate(true)
	var previous := _canonical(data)
	restored = store.restore(data)
	assert_object(restored).is_not_null()
	if restored == null:
		return
	assert_str(_canonical(data)).is_equal(previous)
	var migrated: Dictionary = restored.crises.active.front()
	assert_int(int(migrated.window)).is_equal(int(crisis.window) + 2)
	assert_int(int(migrated.elapsed)).is_equal(int(crisis.elapsed))
	assert_int(int(migrated.consumed_stock)).is_equal(int(crisis.consumed_stock))
	_round_trip(restored)
	restored.advance_to(int(crisis.start) + int(crisis.window))
	assert_int(restored.crises.active.size()).is_equal(1)
	restored.advance_to(int(crisis.start) + int(crisis.window) + 2)
	assert_int(restored.crises.active.size()).is_equal(0)
	assert_int(int(restored.crises.reports.front().day)).is_equal(int(crisis.start) + 9)
	_round_trip(restored)


func test_previous_completed_reports_keep_dates_outcomes_and_resave_with_current_catalog() -> void:
	var sim := _previous_windows_fixture()
	sim.advance_to(CalendarClock.date_to_day("1951-04-08"))
	sim.acknowledge()
	var crisis: Dictionary = sim.crises.active.front()
	assert_bool(sim.dispatch(6, crisis.id, "team", 1).ok).is_true()
	assert_bool(sim.dispatch(31, crisis.id, "stock", 30).ok).is_true()
	sim.advance_to(int(crisis.start) + int(crisis.window))
	var report: Dictionary = sim.crises.reports.front().duplicate(true)
	var store := SaveStore.new()
	var restored := store.restore(sim.to_dict())
	assert_object(restored).is_not_null()
	if restored == null:
		return
	assert_str(_canonical(restored.crises.reports.front())).is_equal(_canonical(report))
	assert_int(int(restored.event_for(report.event_id).response_window_days)).is_equal(7)
	assert_int(int(restored.historical.events[1].response_window_days)).is_equal(9)
	assert_bool(store.save(restored, TEST_PATH)).is_true()
	var resaved := store.load_campaign(TEST_PATH)
	assert_object(resaved).is_not_null()
	if resaved != null:
		assert_str(resaved.content_fingerprint).is_equal(_fixture().content_fingerprint)
		assert_str(_canonical(resaved.crises.reports.front())).is_equal(_canonical(report))
		_round_trip(resaved)


func test_previous_windows_reject_wrong_lengths_and_expired_active_records() -> void:
	var sim := _previous_windows_fixture()
	sim.advance_to(CalendarClock.date_to_day("1951-04-08"))
	sim.acknowledge()
	var store := SaveStore.new()
	var bad := sim.to_dict().duplicate(true)
	bad.active[0].window += 1
	assert_object(store.restore(bad)).is_null()
	bad = sim.to_dict().duplicate(true)
	bad.active[0].window = "7"
	assert_object(store.restore(bad)).is_null()
	bad = sim.to_dict().duplicate(true)
	bad.active[0].elapsed = 7
	bad.day += 7
	assert_object(store.restore(bad)).is_null()
	bad = sim.to_dict().duplicate(true)
	bad.catalog = "unrelated-catalog"
	assert_object(store.restore(bad)).is_null()
	var crisis: Dictionary = sim.crises.active.front()
	sim.advance_to(int(crisis.start) + int(crisis.window))
	bad = sim.to_dict().duplicate(true)
	bad.reports[0].day += 1
	assert_object(store.restore(bad)).is_null()


func test_migrated_parallel_reports_require_one_shared_response_window() -> void:
	var sim := _previous_windows_fixture(1963)
	sim.advance_to(CalendarClock.date_to_day("1963-09-18"))
	assert_int(sim.crises.active.size()).is_greater(1)
	var crisis: Dictionary = sim.crises.active.front()
	sim.acknowledge()
	sim.advance_to(int(crisis.start) + int(crisis.window))
	var store := SaveStore.new()
	var restored := store.restore(sim.to_dict())
	assert_object(restored).is_not_null()
	if restored == null:
		return
	_round_trip(restored)
	var bad := restored.to_dict().duplicate(true)
	bad.reports[0].day += 2
	bad.day += 2
	assert_object(store.restore(bad)).is_null()


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
		while not sim.news_queue.is_empty():
			if sim.news_queue.front().kind == "decision":
				assert_bool(sim.choose_decision(sim.news_queue.front().id, "decline").ok).is_true()
			else:
				sim.acknowledge()
		sim.trust.value = 100.0
		sim.advance_to(ending)
		if sim.crises.active.size() > 1 and not checked_parallel:
			_round_trip(sim)
			checked_parallel = true
		safety += 1
	assert_bool(checked_parallel).is_true()
	assert_str(sim.outcome).is_equal("ending")
	_round_trip(sim)


func test_slot_paths_use_v4_and_reject_out_of_range_ids() -> void:
	var store := SaveStore.new()
	assert_str(store.slot_path(0)).is_equal(SaveStore.PATH)
	for slot in range(1, 4):
		assert_str(store.slot_path(slot)).is_equal("user://manual_%d_v4.json" % slot)
	for slot: int in [-100, -1, 4, 100]:
		assert_str(store.slot_path(slot)).is_empty()
	store.slot_directory = TEST_SLOT_DIRECTORY
	assert_str(store.slot_path(0)).is_equal(TEST_SLOT_DIRECTORY + "/campaign_v4.json")
	assert_str(store.slot_path(3)).is_equal(TEST_SLOT_DIRECTORY + "/manual_3_v4.json")


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


func test_transfer_stationing_guest_mission_and_recall_round_trip() -> void:
	var sim := _fixture()
	assert_bool(sim.transfer_resources(6, 31, "team", 1).ok).is_true()
	assert_bool(sim.transfer_resources(1, 31, "stock", 10).ok).is_true()
	_round_trip(sim)
	sim.advance_to(sim.clock.day + 3)
	assert_int(sim.logistics.available_teams(31, 6)).is_equal(1)
	_round_trip(sim)
	sim.advance_to(CalendarClock.date_to_day("1951-04-08"))
	sim.acknowledge()
	var crisis: Dictionary = sim.crises.active.front()
	assert_bool(sim.dispatch(31, crisis.id, "team", 1, 6).ok).is_true()
	assert_bool(sim.dispatch(31, crisis.id, "stock", 20).ok).is_true()
	_round_trip(sim)
	sim.set_paused(false)
	sim.advance_to(sim.clock.day + 1)
	assert_int(crisis.consumed_stock).is_greater(0)
	assert_bool(crisis.supply_alerted).is_true()
	_round_trip(sim)
	sim.advance_to(int(crisis.start) + int(crisis.window))
	assert_str(sim.logistics.shipments[2].state).is_equal("returning")
	_round_trip(sim)
	sim.acknowledge()
	sim.advance_to(sim.clock.day + 3)
	assert_int(sim.areas[6].teams).is_equal(1)
	_round_trip(sim)
	assert_bool(sim.transfer_resources(6, 31, "team", 1).ok).is_true()
	sim.advance_to(sim.clock.day + 3)
	assert_bool(sim.recall_teams(31, 6, 1).ok).is_true()
	_round_trip(sim)


func test_stationed_ownership_purpose_and_supply_corruption_is_rejected() -> void:
	var sim := _fixture()
	assert_bool(sim.transfer_resources(6, 31, "team", 1).ok).is_true()
	sim.advance_to(sim.clock.day + 3)
	var store := SaveStore.new()
	var data := sim.to_dict()
	for key: String in ["home", "location", "amount"]:
		var bad := data.duplicate(true)
		bad.stationed[0][key] = "6"
		assert_object(store.restore(bad)).is_null()
	var bad := data.duplicate(true)
	bad.stationed[0].home = 999
	assert_object(store.restore(bad)).is_null()
	bad = data.duplicate(true)
	bad.stationed.append(bad.stationed[0].duplicate(true))
	assert_object(store.restore(bad)).is_null()
	bad = data.duplicate(true)
	bad.shipments[0].delivered = true
	assert_object(store.restore(bad)).is_null()
	bad = data.duplicate(true)
	bad.shipments[0].purpose = "crisis"
	assert_object(store.restore(bad)).is_null()
	sim.advance_to(CalendarClock.date_to_day("1951-04-08"))
	sim.acknowledge()
	var crisis: Dictionary = sim.crises.active.front()
	assert_bool(sim.dispatch(31, crisis.id, "stock", 20).ok).is_true()
	sim.advance_to(sim.clock.day + 1)
	data = sim.to_dict()
	for key: String in ["consumed_stock", "aid_coverage_sum", "supply_alerted"]:
		bad = data.duplicate(true)
		bad.active[0][key] = "1"
		assert_object(store.restore(bad)).is_null()
	bad = data.duplicate(true)
	bad.active[0].consumed_stock += 1
	assert_object(store.restore(bad)).is_null()
	bad = data.duplicate(true)
	bad.active[0].stock = int(crisis.severity) * 15 + 1
	assert_object(store.restore(bad)).is_null()
	bad = data.duplicate(true)
	bad.active[0].aid_coverage_sum = INF
	assert_object(store.restore(bad)).is_null()
	bad = data.duplicate(true)
	bad.shipments[1].delivered = false
	assert_object(store.restore(bad)).is_null()


func test_reports_keep_consumed_and_returned_aid_ledger() -> void:
	var sim := _crisis_fixture()
	var crisis: Dictionary = sim.crises.active.front()
	assert_bool(sim.transfer_resources(1, 31, "stock", 40).ok).is_true()
	assert_bool(sim.dispatch(31, crisis.id, "stock", 30).ok).is_true()
	sim.advance_to(int(crisis.start) + int(crisis.window) - 1)
	assert_bool(sim.dispatch(31, crisis.id, "stock", 20).ok).is_true()
	sim.advance_to(sim.clock.day + 1)
	assert_int(sim.crises.reports[0].returned_stock).is_greater(0)
	_round_trip(sim)
	var bad := sim.to_dict()
	bad.reports[0].consumed_stock += 1
	assert_object(SaveStore.new().restore(bad)).is_null()
	bad = sim.to_dict()
	bad.reports[0].returned_stock += 1
	assert_object(SaveStore.new().restore(bad)).is_null()


func test_clear_campaign_slots_removes_all_v4_slots_and_staging_files_only() -> void:
	var store := _slot_store()
	var sim := _fixture()
	for slot in range(4):
		assert_bool(store.save(sim, store.slot_path(slot))).is_true()
		var staging := FileAccess.open(store.slot_path(slot) + ".tmp", FileAccess.WRITE)
		staging.store_string("unfinished write")
		staging.close()
	var preserved := ["preferences.cfg", "campaign_v3.json", "manual_4_v4.json", "other.json"]
	for filename: String in preserved:
		var file := FileAccess.open(TEST_SLOT_DIRECTORY.path_join(filename), FileAccess.WRITE)
		file.store_string("keep these bytes")
		file.close()
	assert_bool(store.clear_campaign_slots()).is_true()
	assert_str(store.error).is_empty()
	for slot in range(4):
		assert_bool(FileAccess.file_exists(store.slot_path(slot))).is_false()
		assert_bool(FileAccess.file_exists(store.slot_path(slot) + ".tmp")).is_false()
	for summary: Dictionary in store.slot_summaries():
		assert_bool(summary.exists).is_false()
	for filename: String in preserved:
		var path := TEST_SLOT_DIRECTORY.path_join(filename)
		assert_str(FileAccess.get_file_as_string(path)).is_equal("keep these bytes")
		_remove_test_path(path)
	assert_bool(store.clear_campaign_slots()).is_true()


func test_clear_campaign_slots_reports_incomplete_deletion_and_allows_retry() -> void:
	var store := _slot_store()
	(
		assert_int(DirAccess.make_dir_absolute(ProjectSettings.globalize_path(store.slot_path(0))))
		. is_equal(OK)
	)
	assert_bool(store.save(_fixture(), store.slot_path(1))).is_true()
	assert_bool(store.clear_campaign_slots()).is_false()
	assert_bool(store.error.contains("campaign_v4.json")).is_true()
	assert_bool(store.error.contains("Bazı yuvalar silinmiş olabilir")).is_true()
	(
		assert_bool(
			DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(store.slot_path(0)))
		)
		. is_true()
	)
	assert_bool(FileAccess.file_exists(store.slot_path(1))).is_false()
	_remove_test_path(store.slot_path(0))
	assert_bool(store.clear_campaign_slots()).is_true()
	assert_str(store.error).is_empty()
