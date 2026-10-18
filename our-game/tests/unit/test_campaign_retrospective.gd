extends GdUnitTestSuite

const RETROSPECTIVE := preload("res://campaign/domain/campaign_retrospective.gd")


func _fixture(year: int = 1950) -> Simulation:
	var sim := Simulation.new()
	assert_bool(sim.setup(year)).is_true()
	return sim


func _canonical(data: Dictionary) -> String:
	return JSON.stringify(JSON.parse_string(JSON.stringify(data)))


func _report(event: Dictionary, rescued: int, losses: int) -> Dictionary:
	return {
		"event_id": str(event.id),
		"rescued": rescued,
		"protected": rescued * 2,
		"prevented_losses": rescued * 3,
		"prevented_damage": rescued * 1000,
		"losses": losses,
		"quality": 40.0,
	}


func _project(sim: Simulation, id: String, area_id: int, status: String) -> void:
	var project := ActiveProject.new()
	project.definition_id = id
	project.area_id = area_id
	project.status = status
	sim.projects.projects.append(project)


func test_new_campaign_has_no_player_achievements_or_events() -> void:
	var sim := _fixture(1990)
	assert_bool(sim.projects.global_completed.is_empty()).is_false()
	var summary := RETROSPECTIVE.build(sim, "voluntary")
	assert_str(summary.reason).is_equal("voluntary")
	assert_str(summary.start_date).is_equal("1990-01-01")
	assert_str(summary.end_date).is_equal("1990-01-01")
	assert_int(summary.event_count).is_equal(0)
	assert_int(summary.completed_event_count).is_equal(0)
	assert_int(summary.active_event_count).is_equal(0)
	assert_array(summary.events).is_empty()
	assert_array(summary.completed_projects).is_empty()
	assert_array(summary.unfinished_projects).is_empty()
	assert_bool(summary.photo_event.is_empty()).is_true()
	for value: int in summary.totals.values():
		assert_int(value).is_equal(0)
	assert_float(summary.trust).is_equal(sim.trust.value)
	assert_dict(summary.scores).is_equal(sim.scores())


func test_reports_from_multiple_centers_count_one_event_and_sum_actual_results() -> void:
	var sim := _fixture()
	var first: Dictionary = sim.historical.events[0]
	var second: Dictionary = sim.historical.events[1]
	sim.crises.reports.append(_report(second, 7, 4))
	sim.crises.reports.append(_report(first, 10, 2))
	sim.crises.reports.append(_report(first, 20, 3))
	var summary := RETROSPECTIVE.build(sim, "ending")
	assert_int(summary.event_count).is_equal(2)
	assert_int(summary.completed_event_count).is_equal(2)
	assert_int(summary.active_event_count).is_equal(0)
	assert_str(summary.events[0].id).is_equal(str(first.id))
	assert_str(summary.events[1].id).is_equal(str(second.id))
	assert_int(summary.events[0].reports_count).is_equal(2)
	assert_int(summary.events[0].rescued).is_equal(30)
	assert_int(summary.totals.rescued).is_equal(37)
	assert_int(summary.totals.protected).is_equal(74)
	assert_int(summary.totals.prevented_losses).is_equal(111)
	assert_int(summary.totals.prevented_damage).is_equal(37000)
	assert_int(summary.totals.losses).is_equal(9)
	assert_str(summary.photo_event.id).is_equal(str(second.id))


func test_ongoing_centers_do_not_finish_an_event_or_contribute_unfinished_results() -> void:
	var sim := _fixture()
	var first: Dictionary = sim.historical.events[0]
	var second: Dictionary = sim.historical.events[1]
	var third: Dictionary = sim.historical.events[2]
	sim.crises.reports.append(_report(first, 10, 2))
	sim.crises.reports.append(_report(second, 20, 3))
	for event: Dictionary in [second, second, third]:
		sim.crises.active.append({"event_id": event.id, "rescued": 999, "losses": 999})
	var summary := RETROSPECTIVE.build(sim, "defeat")
	assert_int(summary.event_count).is_equal(3)
	assert_int(summary.completed_event_count).is_equal(1)
	assert_int(summary.active_event_count).is_equal(2)
	assert_bool(summary.events[0].active).is_false()
	assert_bool(summary.events[1].active).is_true()
	assert_bool(summary.events[2].active).is_true()
	assert_int(summary.events[2].reports_count).is_equal(0)
	assert_int(summary.events[2].rescued).is_equal(0)
	assert_int(summary.totals.rescued).is_equal(30)
	assert_int(summary.totals.losses).is_equal(5)
	assert_str(summary.photo_event.id).is_equal(str(first.id))


func test_player_projects_group_repeat_orders_and_keep_unfinished_states_separate() -> void:
	var sim := _fixture()
	_project(sim, "rescue_team", 34, "completed")
	_project(sim, "rescue_team", 34, "completed")
	_project(sim, "rescue_team", 6, "completed")
	_project(sim, "repair", 34, "completed")
	_project(sim, "center_renewal", 34, "completed")
	_project(sim, "research_structural", 0, "completed")
	_project(sim, "aid_stock", 34, "queued")
	_project(sim, "aid_stock", 34, "queued")
	_project(sim, "aid_stock", 34, "active")
	_project(sim, "river_zoning", 34, "waiting")
	_project(sim, "river_zoning", 6, "paused")
	_project(sim, "strengthening", 6, "cancelled")
	var summary := RETROSPECTIVE.build(sim, "voluntary")
	assert_int(summary.completed_projects.size()).is_equal(5)
	assert_int(summary.unfinished_projects.size()).is_equal(4)
	for row: Dictionary in summary.completed_projects:
		assert_bool(row.has("status")).is_false()
		assert_str(row.title).is_equal(sim.projects.definition_for(row.id).title)
		if row.id == "rescue_team" and row.area_id == 34:
			assert_int(row.count).is_equal(2)
			assert_str(row.area_name).is_equal(sim.areas[34].name)
		if row.id == "research_structural":
			assert_str(row.kind).is_equal("research")
			assert_str(row.area_name).is_equal("Türkiye geneli")
	for row: Dictionary in summary.unfinished_projects:
		assert_bool(row.status in ["active", "waiting", "paused", "queued"]).is_true()
		assert_int(row.count).is_equal(2 if row.status == "queued" else 1)


func test_summary_is_deterministic_and_contains_no_mutable_source_references() -> void:
	var sim := _fixture()
	sim.crises.reports.append(_report(sim.historical.events[0], 10, 2))
	_project(sim, "river_zoning", 34, "completed")
	var before := JSON.stringify(sim.to_dict())
	var history_before := JSON.stringify(sim.historical.events)
	var summary := RETROSPECTIVE.build(sim, "voluntary")
	assert_str(JSON.stringify(summary)).is_equal(
		JSON.stringify(RETROSPECTIVE.build(sim, "voluntary"))
	)
	summary.events[0].name = "Changed"
	summary.completed_projects[0].title = "Changed"
	summary.photo_event.province_ids.clear()
	summary.totals.rescued = 0
	assert_str(JSON.stringify(sim.to_dict())).is_equal(before)
	assert_str(JSON.stringify(sim.historical.events)).is_equal(history_before)


func test_loaded_campaign_produces_the_same_summary_without_a_save_format_change() -> void:
	var sim := _fixture()
	assert_bool(sim.start_project("river_zoning", 34).ok).is_true()
	sim.advance_to(CalendarClock.date_to_day("1951-04-08"))
	sim.acknowledge()
	var crisis: Dictionary = sim.crises.active.front()
	sim.advance_to(int(crisis.start) + int(crisis.window))
	assert_int(sim.crises.reports.size()).is_equal(1)
	var restored := SaveStore.new().restore(JSON.parse_string(JSON.stringify(sim.to_dict())))
	assert_object(restored).is_not_null()
	if restored != null:
		assert_str(_canonical(RETROSPECTIVE.build(restored, "voluntary"))).is_equal(
			_canonical(RETROSPECTIVE.build(sim, "voluntary"))
		)
