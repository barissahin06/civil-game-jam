extends GdUnitTestSuite


func _fixture() -> Simulation:
	var simulation := Simulation.new()
	assert_bool(simulation.setup()).is_true()
	return simulation


func test_finish_explanation_follows_basics_before_optional_lessons_and_roundtrips() -> void:
	var simulation := _fixture()
	for id: String in CampaignGuide.BASE_STEPS:
		if id != "finish":
			simulation.guide.record(id)
	assert_str(simulation.guide.select_step(simulation, "projects")).is_equal("finish")
	assert_bool(simulation.outcome.is_empty()).is_true()
	var restored := SaveStore.new().restore(simulation.to_dict())
	assert_object(restored).is_not_null()
	assert_str(restored.guide.select_step(restored, "projects")).is_equal("finish")
	restored.guide.acknowledge()
	assert_bool(restored.guide.done("finish")).is_true()
	assert_str(restored.guide.select_step(restored, "projects")).is_equal("project_controls")
	assert_str(simulation.outcome).is_empty()


func test_national_construction_does_not_complete_research_step() -> void:
	var simulation := _fixture()
	simulation.projects.global_completed.append("research_radio")
	assert_bool(simulation.start_project("national_radio").ok).is_true()
	assert_bool("research" in simulation.tutorial_completed).is_false()
	assert_bool("investment" in simulation.tutorial_completed).is_false()
	assert_bool(simulation.guide.done("research")).is_false()
	assert_bool(simulation.guide.done("investment")).is_false()


func test_technical_research_uses_definition_scope_not_area_argument() -> void:
	var simulation := _fixture()
	assert_bool(simulation.start_project("research_structural", 34).ok).is_true()
	assert_bool("research" in simulation.tutorial_completed).is_true()
	assert_bool("investment" in simulation.tutorial_completed).is_false()
	assert_bool(simulation.guide.done("research")).is_true()
	assert_bool(simulation.guide.done("investment")).is_false()


func test_awareness_research_completes_research_step_after_real_point_collection() -> void:
	var simulation := _fixture()
	simulation.advance_to(CalendarClock.date_to_day("1950-03-01"))
	assert_int(simulation.bubbles.size()).is_equal(1)
	simulation.collect_bubble(simulation.bubbles.front())
	assert_bool(simulation.start_project("community_preparedness").ok).is_true()
	assert_bool("research" in simulation.tutorial_completed).is_true()
	assert_bool("investment" in simulation.tutorial_completed).is_false()
	assert_bool(simulation.guide.done("bubble")).is_true()
	assert_bool(simulation.guide.done("awareness")).is_true()
	assert_bool(simulation.guide.done("research")).is_false()


func test_failed_commands_do_not_advance_guide_and_local_start_marks_investment() -> void:
	var simulation := _fixture()
	assert_bool(simulation.start_project("community_preparedness").ok).is_false()
	assert_bool(simulation.start_project("unknown_project").ok).is_false()
	assert_int(simulation.tutorial_completed.size()).is_equal(0)
	assert_bool(simulation.start_project("river_zoning", 31).ok).is_true()
	assert_bool("investment" in simulation.tutorial_completed).is_true()
	assert_bool("research" in simulation.tutorial_completed).is_false()
	assert_bool(simulation.start_project("strengthening", 31).ok).is_false()
	assert_int(simulation.tutorial_completed.size()).is_equal(1)
	assert_bool(simulation.guide.done("investment")).is_true()
	assert_bool(simulation.guide.done("research")).is_false()
	assert_bool(simulation.guide.done("awareness")).is_false()


func test_all_start_years_get_a_paused_intro_and_do_not_wait_for_unavailable_events() -> void:
	for year in range(1950, 1991):
		var simulation := Simulation.new()
		assert_bool(simulation.setup(year)).is_true()
		assert_str(simulation.guide.select_step(simulation, "")).is_equal("intro")
		assert_bool(simulation.paused).is_true()
		for id: String in CampaignGuide.BASE_STEPS:
			simulation.guide.record(id)
		assert_str(simulation.guide.select_step(simulation, "")).is_empty()
		assert_bool(simulation.guide.done("completion")).is_false()
		assert_bool(simulation.guide.done("bubble")).is_false()


func test_actions_record_out_of_order_and_while_closed_without_reopening() -> void:
	var simulation := _fixture()
	var guide := simulation.guide
	guide.close()
	guide.record("city")
	guide.record("city")
	guide.record("unknown")
	assert_bool(simulation.enqueue_preparation("rescue_team", 34).ok).is_true()
	assert_bool(simulation.enqueue_preparation("aid_stock", 34).ok).is_true()
	assert_bool(simulation.enqueue_preparation("unknown", 34).ok).is_false()
	assert_bool(guide.done("teams")).is_true()
	assert_bool(guide.done("stock")).is_true()
	assert_bool(guide.done("investment")).is_false()
	assert_bool(guide.enabled).is_false()
	assert_int(guide.completed.count("city")).is_equal(1)
	assert_str(guide.select_step(simulation, "")).is_empty()
	guide.resume()
	assert_str(guide.select_step(simulation, "")).is_equal("intro")


func test_single_skip_close_resume_and_information_acknowledgement() -> void:
	var simulation := _fixture()
	var guide := simulation.guide
	assert_str(guide.select_step(simulation, "")).is_equal("intro")
	guide.acknowledge()
	assert_str(guide.select_step(simulation, "")).is_equal("city")
	guide.acknowledge()
	assert_bool(guide.done("city")).is_false()
	guide.skip()
	assert_bool("city" in guide.skipped).is_true()
	assert_str(guide.select_step(simulation, "")).is_equal("zoom")
	guide.close()
	guide.resume()
	assert_str(guide.select_step(simulation, "")).is_equal("zoom")
	guide.record("city")
	assert_bool("city" in guide.skipped).is_false()
	assert_bool("city" in guide.completed).is_true()


func test_crisis_interrupts_and_returns_to_incomplete_base_after_real_actions() -> void:
	var simulation := _fixture()
	var guide := simulation.guide
	guide.record("intro")
	assert_str(guide.select_step(simulation, "")).is_equal("city")
	simulation.advance_to(CalendarClock.date_to_day("1951-04-08"))
	assert_str(guide.select_step(simulation, "newspaper")).is_equal("newspaper")
	assert_str(guide.return_step).is_equal("city")
	simulation.acknowledge()
	assert_bool(guide.done("newspaper")).is_true()
	assert_str(guide.select_step(simulation, "crisis")).is_equal("dispatch_teams")
	assert_bool(simulation.dispatch(31, guide.crisis_id, "team", 1).ok).is_true()
	assert_str(guide.select_step(simulation, "crisis")).is_equal("dispatch_stock")
	assert_bool(simulation.dispatch(31, guide.crisis_id, "stock", 10).ok).is_true()
	assert_bool(guide.done("dispatch_teams")).is_true()
	assert_bool(guide.done("dispatch_stock")).is_true()
	assert_bool(simulation.dispatch(31, "unknown", "stock", 10).ok).is_false()
	simulation.advance_to(
		int(simulation.crises.active.front().start) + int(simulation.crises.active.front().window)
	)
	assert_str(guide.select_step(simulation, "report")).is_equal("report")
	simulation.acknowledge()
	assert_bool(guide.done("report")).is_true()
	assert_str(guide.select_step(simulation, "")).is_equal("city")


func test_early_disaster_and_unavailable_resources_do_not_lock_base_lessons() -> void:
	var simulation := Simulation.new()
	assert_bool(simulation.setup(1952)).is_true()
	simulation.guide.record("intro")
	simulation.advance_to(CalendarClock.date_to_day("1952-01-03"))
	assert_str(simulation.guide.select_step(simulation, "newspaper")).is_equal("newspaper")
	simulation.acknowledge()
	for area: ServiceArea in simulation.areas.values():
		area.teams = 0
		area.stock = 0
	assert_str(simulation.guide.select_step(simulation, "crisis")).is_equal("city")
	assert_bool(simulation.guide.done("dispatch_teams")).is_false()
	assert_bool(simulation.guide.done("dispatch_stock")).is_false()


func test_finished_dispatch_waits_for_report_before_returning_to_base_lessons() -> void:
	var simulation := _fixture()
	var guide := simulation.guide
	guide.record("intro")
	assert_str(guide.select_step(simulation, "")).is_equal("city")
	assert_bool(simulation.start_project("aid_stock", 34).ok).is_true()
	simulation.advance_to(CalendarClock.date_to_day("1951-04-08"))
	assert_str(guide.select_step(simulation, "newspaper")).is_equal("newspaper")
	simulation.acknowledge()
	guide.record("dispatch_teams")
	guide.record("dispatch_stock")
	assert_str(guide.select_step(simulation, "crisis")).is_equal("completion")
	guide.acknowledge()
	assert_str(guide.select_step(simulation, "crisis")).is_empty()
	assert_str(guide.return_step).is_equal("city")
	simulation.advance_to(
		int(simulation.crises.active.front().start) + int(simulation.crises.active.front().window)
	)
	assert_str(guide.select_step(simulation, "report")).is_equal("report")
	simulation.acknowledge()
	assert_str(guide.select_step(simulation, "")).is_equal("city")


func test_existing_on_time_support_does_not_require_duplicate_shipments() -> void:
	var simulation := _fixture()
	simulation.advance_to(CalendarClock.date_to_day("1951-04-08"))
	simulation.acknowledge()
	var crisis_id := str(simulation.crises.active.front().id)
	assert_bool(simulation.dispatch(31, crisis_id, "team", 1).ok).is_true()
	assert_bool(simulation.dispatch(1, crisis_id, "team", 1).ok).is_true()
	assert_bool(simulation.dispatch(31, crisis_id, "stock", 30).ok).is_true()
	simulation.guide = CampaignGuide.new()
	var money := simulation.treasury.money
	assert_str(simulation.guide.select_step(simulation, "crisis")).is_empty()
	assert_bool(simulation.guide.done("dispatch_teams")).is_true()
	assert_bool(simulation.guide.done("dispatch_stock")).is_true()
	assert_int(simulation.treasury.money).is_equal(money)


func test_completion_uses_real_project_records_and_contexts_are_optional() -> void:
	var simulation := Simulation.new()
	assert_bool(simulation.setup(1990)).is_true()
	var guide := simulation.guide
	for id: String in CampaignGuide.BASE_STEPS:
		guide.record(id)
	assert_str(guide.select_step(simulation, "")).is_empty()
	assert_str(guide.select_step(simulation, "national")).is_equal("national")
	guide.acknowledge()
	assert_str(guide.select_step(simulation, "units")).is_equal("transfer")
	guide.acknowledge()
	assert_str(guide.select_step(simulation, "units")).is_equal("stationing")
	guide.acknowledge()
	assert_bool(simulation.start_project("aid_stock", 34).ok).is_true()
	simulation.advance_to(CalendarClock.date_to_day("1990-03-01"))
	guide.record("bubble")
	guide.record("awareness")
	assert_str(guide.select_step(simulation, "")).is_equal("completion")
	guide.acknowledge()
	assert_bool(guide.done("completion")).is_true()


func test_menus_and_endgame_suppress_without_mutating_time() -> void:
	var simulation := _fixture()
	var guide := simulation.guide
	guide.select_step(simulation, "")
	for screen: String in CampaignGuide.HIDDEN_SCREENS:
		assert_str(guide.select_step(simulation, screen)).is_empty()
	assert_str(guide.active_step).is_equal("intro")
	simulation.set_paused(false)
	assert_bool(guide.done("time")).is_true()
	guide.select_step(simulation, "")
	assert_bool(simulation.paused).is_false()
	simulation.outcome = "ending"
	assert_str(guide.select_step(simulation, "")).is_empty()


func test_repair_lesson_finds_a_damaged_center_outside_the_map_selection() -> void:
	var simulation := _fixture()
	for id: String in CampaignGuide.BASE_STEPS:
		simulation.guide.record(id)
	for id: String in ["bubble", "awareness", "completion", "report"]:
		simulation.guide.record(id)
	simulation.areas[31].damage = 20.0
	assert_str(simulation.guide.select_step(simulation, "project", 34, "repair")).is_equal("repair")


func test_guide_save_roundtrip_and_missing_optional_key_resumes_disabled() -> void:
	var simulation := _fixture()
	simulation.guide.record("intro")
	simulation.guide.select_step(simulation, "")
	simulation.guide.skip()
	simulation.guide.select_step(simulation, "")
	var store := SaveStore.new()
	var restored := store.restore(simulation.to_dict())
	assert_object(restored).is_not_null()
	assert_str(restored.guide.active_step).is_equal("zoom")
	assert_bool(restored.guide.done("intro")).is_true()
	assert_bool("city" in restored.guide.skipped).is_true()
	var legacy := simulation.to_dict()
	legacy.erase("guide")
	restored = store.restore(legacy)
	assert_object(restored).is_not_null()
	assert_bool(restored.guide.enabled).is_false()
	restored.guide.resume()
	assert_str(restored.guide.select_step(restored, "")).is_equal("intro")


func test_legacy_guide_adopts_real_actions_without_new_purchases_or_state_changes() -> void:
	var simulation := _fixture()
	simulation.learn("city")
	assert_bool(simulation.start_project("river_zoning", 31).ok).is_true()
	assert_bool(simulation.start_project("research_structural").ok).is_true()
	simulation.advance_to(CalendarClock.date_to_day("1950-03-01"))
	simulation.collect_bubble(simulation.bubbles.front())
	assert_bool(simulation.start_project("community_preparedness").ok).is_true()
	assert_bool(simulation.enqueue_preparation("rescue_team", 34).ok).is_true()
	assert_bool(simulation.enqueue_preparation("aid_stock", 34).ok).is_true()
	simulation.advance_to(CalendarClock.date_to_day("1951-04-08"))
	simulation.acknowledge()
	var crisis_id := str(simulation.crises.active.front().id)
	assert_bool(simulation.dispatch(31, crisis_id, "team", 1).ok).is_true()
	assert_bool(simulation.dispatch(31, crisis_id, "stock", 10).ok).is_true()
	assert_bool(simulation.enqueue_preparation("rescue_team", 34).ok).is_true()
	assert_bool(simulation.enqueue_preparation("aid_stock", 34).ok).is_true()
	var cancelled := simulation.start_project("firebreak", 1)
	assert_bool(cancelled.ok).is_true()
	assert_bool(simulation.cancel_project(int(cancelled.uid)).ok).is_true()
	var legacy := simulation.to_dict()
	legacy.erase("guide")
	var before := JSON.stringify(legacy)
	var restored := SaveStore.new().restore(legacy)
	assert_object(restored).is_not_null()
	assert_bool(restored.guide.enabled).is_false()
	for id: String in [
		"city",
		"investment",
		"research",
		"awareness",
		"teams",
		"stock",
		"dispatch_teams",
		"dispatch_stock"
	]:
		assert_bool(restored.guide.done(id)).is_true()
	assert_int(restored.treasury.money).is_equal(int(legacy.money))
	assert_int(restored.projects.projects.size()).is_equal(simulation.projects.projects.size())
	assert_int(restored.logistics.shipments.size()).is_equal(simulation.logistics.shipments.size())
	assert_str(JSON.stringify(legacy)).is_equal(before)
	restored.guide.resume()
	for id: String in ["intro", "zoom", "overlay", "newspaper", "completion"]:
		restored.guide.record(id)
	restored.advance_to(
		int(restored.crises.active.front().start) + int(restored.crises.active.front().window)
	)
	restored.acknowledge()
	assert_str(restored.guide.select_step(restored, "")).is_equal("time")
	assert_int(restored.projects.projects.size()).is_equal(simulation.projects.projects.size())


func test_legacy_era_research_is_not_mistaken_for_a_player_exercise() -> void:
	var simulation := Simulation.new()
	assert_bool(simulation.setup(1990)).is_true()
	assert_bool(simulation.projects.is_completed("research_structural", 0)).is_true()
	var legacy := simulation.to_dict()
	legacy.erase("guide")
	var restored := SaveStore.new().restore(legacy)
	assert_object(restored).is_not_null()
	assert_bool(restored.guide.enabled).is_false()
	assert_bool(restored.guide.done("research")).is_false()
	assert_int(restored.projects.projects.size()).is_equal(0)


func test_guide_restore_rejects_bad_types_unknown_duplicate_and_stale_crisis_ids() -> void:
	var simulation := _fixture()
	var store := SaveStore.new()
	for guide_data: Variant in [
		[],
		{"enabled": true},
		{
			"enabled": "true",
			"completed": [],
			"skipped": [],
			"active_step": "",
			"return_step": "",
			"crisis_id": ""
		},
		{
			"enabled": true,
			"completed": ["unknown"],
			"skipped": [],
			"active_step": "",
			"return_step": "",
			"crisis_id": ""
		},
		{
			"enabled": true,
			"completed": ["city"],
			"skipped": ["city"],
			"active_step": "",
			"return_step": "",
			"crisis_id": ""
		},
		{
			"enabled": true,
			"completed": [],
			"skipped": [],
			"active_step": "city",
			"return_step": "",
			"crisis_id": "missing-crisis"
		}
	]:
		var data := simulation.to_dict()
		data.guide = guide_data
		assert_object(store.restore(data)).is_null()
