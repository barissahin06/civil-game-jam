extends GdUnitTestSuite


func _fixture(year: int = 1950) -> Simulation:
	var sim := Simulation.new()
	assert_bool(sim.setup(year)).is_true()
	return sim


func _first_crisis(sim: Simulation) -> Dictionary:
	sim.advance_to(CalendarClock.date_to_day("1951-04-08"))
	sim.acknowledge()
	return sim.crises.active.front()


func test_paused_speed_first_event_and_monthly_settlement() -> void:
	var sim := _fixture()
	var initial := sim.clock.day
	sim.update(100.0)
	assert_int(sim.clock.day).is_equal(initial)
	var project := sim.start_project("river_zoning", 31)
	sim.start_project("research_structural")
	sim.set_speed(4)
	sim.set_paused(false)
	sim.update(300.0)
	assert_str(CalendarClock.day_to_iso(sim.clock.day)).is_equal("1951-01-01")
	assert_bool(sim.paused).is_true()
	assert_dict(sim.news_queue.front()).is_equal(
		{"kind": "research_done", "id": "research_structural"}
	)
	sim.acknowledge()
	sim.set_paused(false)
	sim.update(300.0)
	assert_str(CalendarClock.day_to_iso(sim.clock.day)).is_equal("1951-04-08")
	assert_bool(sim.paused).is_true()
	assert_int(sim.crises.active.size()).is_equal(1)
	assert_int(sim.news_queue.size()).is_equal(1)
	assert_str(sim.projects.get_project(project.uid).status).is_equal("completed")
	assert_bool(sim.projects.is_completed("research_structural")).is_true()
	assert_int(sim.treasury.money).is_equal(77000000)
	sim.update(100.0)
	assert_str(CalendarClock.day_to_iso(sim.clock.day)).is_equal("1951-04-08")


func test_newspaper_archive_reveals_started_events_and_survives_restore() -> void:
	var sim := _fixture()
	assert_dict(sim.latest_event()).is_empty()
	sim.advance_to(CalendarClock.date_to_day("1951-04-08"))
	var first: Dictionary = sim.latest_event()
	assert_str(first.date).is_equal("1951-04-08")
	assert_str(first.id).is_equal(sim.news_queue.front().id)
	sim.acknowledge()
	assert_dict(sim.latest_event()).is_equal(first)
	var restored := SaveStore.new().restore(JSON.parse_string(JSON.stringify(sim.to_dict())))
	assert_object(restored).is_not_null()
	assert_dict(restored.latest_event()).is_equal(first)


func test_reservation_arrival_return_and_double_dispatch_rejection() -> void:
	var sim := _fixture()
	var target := _first_crisis(sim)
	var quote := sim.logistics.quote(1, int(target.area_id), "team", 1)
	assert_int(quote.days).is_equal(1)
	var cash := sim.treasury.money
	assert_bool(sim.dispatch(1, target.id, "team", 1).ok).is_true()
	assert_bool(sim.dispatch(1, target.id, "team", 1).ok).is_false()
	assert_int(sim.areas[1].teams).is_equal(0)
	assert_int(sim.treasury.money).is_equal(cash - int(quote.fee))
	sim.advance_to(sim.clock.day + 1)
	assert_int(target.teams).is_equal(1)
	sim.advance_to(int(target.start) + int(target.window))
	assert_int(sim.crises.reports.size()).is_equal(1)
	assert_int(sim.areas[1].teams).is_equal(0)
	sim.acknowledge()
	sim.advance_to(sim.clock.day + 1)
	assert_int(sim.areas[1].teams).is_equal(1)
	assert_int(sim.treasury.money).is_equal(cash - int(quote.fee))


func test_stock_consumption_funding_cap_and_report_subset() -> void:
	var sim := _fixture()
	var target := _first_crisis(sim)
	assert_bool(sim.dispatch(31, target.id, "stock", 20).ok).is_true()
	assert_int(sim.areas[31].stock).is_equal(20)
	assert_int(target.stock).is_equal(20)
	assert_bool(sim.fund(target.id, 5000000).ok).is_true()
	assert_bool(sim.fund(target.id, 1).ok).is_false()
	sim.advance_to(int(target.start) + int(target.window))
	var report: Dictionary = sim.crises.reports.front()
	assert_int(report.affected + report.safe).is_equal(report.exposed)
	assert_bool(report.rescued <= report.affected).is_true()
	assert_int(sim.areas[31].stock).is_equal(20)
	assert_int(sim.projects.repair_support[31]).is_equal(5000000)


func test_deterministic_response_and_delay_cost() -> void:
	var early := _fixture()
	var delayed := _fixture()
	var repeat := _fixture()
	for sim: Simulation in [early, delayed, repeat]:
		var target := _first_crisis(sim)
		if sim == delayed:
			sim.advance_to(sim.clock.day + 3)
		sim.dispatch(31, target.id, "team", 1)
		sim.dispatch(31, target.id, "stock", 40)
		sim.advance_to(int(target.start) + int(target.window))
	assert_dict(early.report_for()).is_equal(repeat.report_for())
	assert_bool(early.report_for().rescued > delayed.report_for().rescued).is_true()
	assert_bool(early.report_for().losses <= delayed.report_for().losses).is_true()


func test_parallel_catalog_events_share_calendar_without_losing_news() -> void:
	var sim := _fixture(1990)
	# Jump only in this bounded catalog fixture to exercise an actual multi-area event.
	var event: Dictionary
	for item: Dictionary in sim.historical.events:
		if item.date == "2023-02-06":
			event = item
			break
	sim.clock.set_day(int(event.day))
	sim.crises.begin(event)
	assert_bool(sim.crises.active.size() > 1).is_true()
	var reserved: int = sim.areas[6].teams
	for target: Dictionary in sim.crises.active:
		sim.dispatch(6, target.id, "team", 1)
	assert_int(sim.areas[6].teams).is_equal(0)
	assert_int(sim.logistics.shipments.size()).is_equal(reserved)
	var finished := sim.crises.tick_day(
		sim.clock.day + int(event.response_window_days), sim.logistics
	)
	# Daily response windows must actually be simulated, not finished by a clock comparison.
	assert_int(finished.size()).is_equal(0)


func test_awareness_bubbles_are_bounded_persistent_and_collectable() -> void:
	var sim := _fixture()
	sim.advance_to(CalendarClock.date_to_day("1950-09-01"))
	assert_int(sim.bubbles.size()).is_equal(3)
	var before := sim.treasury.awareness_points
	var id: int = sim.bubbles.front()
	sim.collect_bubble(id)
	sim.collect_bubble(id)
	assert_int(sim.treasury.awareness_points).is_equal(before + 5)
	sim.update(100.0)
	assert_int(sim.bubbles.size()).is_equal(2)


func test_save_round_trip_mid_crisis_and_corruption_rejected() -> void:
	var sim := _fixture()
	var target := _first_crisis(sim)
	sim.dispatch(6, target.id, "team", 1)
	var store := SaveStore.new()
	var restored := store.restore(JSON.parse_string(JSON.stringify(sim.to_dict())))
	assert_object(restored).is_not_null()
	assert_str(_canonical_json(restored.to_dict())).is_equal(_canonical_json(sim.to_dict()))
	assert_bool(restored.paused).is_true()
	var corrupted: Dictionary = sim.to_dict().duplicate(true)
	corrupted.shipments[0].amount = 100
	assert_object(store.restore(corrupted)).is_null()
	corrupted = sim.to_dict().duplicate(true)
	corrupted.version = 99
	assert_object(store.restore(corrupted)).is_null()
	corrupted = sim.to_dict().duplicate(true)
	corrupted.active[0].start += 1
	assert_object(store.restore(corrupted)).is_null()


func test_actual_campaign_reaches_2026_boundary_and_trust_zero_ends_early() -> void:
	var sim := _fixture(1990)
	var safety := 0
	while sim.outcome.is_empty() and safety < 1000:
		sim.news_queue.clear()
		sim.trust.value = 100.0
		sim.advance_to(CalendarClock.date_to_day(Simulation.END_DATE))
		safety += 1
	assert_str(sim.outcome).is_equal("ending")
	assert_str(CalendarClock.day_to_iso(sim.clock.day)).is_equal("2026-12-31")
	assert_int(sim._event_index).is_equal(99)
	var failed := _fixture()
	failed.trust.value = 0.0
	failed.advance_to(failed.clock.day + 1)
	assert_str(failed.outcome).is_equal("defeat")


func _canonical_json(data: Dictionary) -> String:
	return JSON.stringify(JSON.parse_string(JSON.stringify(data)))


func test_all_start_years_show_a_historical_disaster_within_five_active_minutes() -> void:
	for year: int in range(1950, 1991):
		var sim := _fixture(year)
		sim.set_paused(false)
		sim.update(300.0)
		assert_bool(not sim.crises.active.is_empty()).is_true()
		assert_bool(not sim.news_queue.is_empty()).is_true()
		assert_bool(sim.paused).is_true()


func test_normal_and_crisis_clock_fit_the_campaign_tempo_budget() -> void:
	var sim := _fixture()
	var active_seconds := 0
	while sim.outcome.is_empty() and active_seconds <= 3000:
		# Isolate calendar tempo from player reading time and defeat balance.
		sim.news_queue.clear()
		sim.trust.value = 100.0
		sim.set_paused(false)
		sim.update(1.0)
		active_seconds += 1
	assert_str(sim.outcome).is_equal("ending")
	assert_bool(active_seconds >= 1800 and active_seconds <= 2700).is_true()
	print("CAMPAIGN_TEMPO_SECONDS: ", active_seconds)


func test_sudden_and_ongoing_models_have_distinct_normalized_time_profiles() -> void:
	var sudden := SuddenDisasterModel.new()
	var ongoing := OngoingDisasterModel.new()
	var sudden_total := 0.0
	var ongoing_total := 0.0
	for day: int in range(7):
		sudden_total += sudden.daily_weight(day, 7)
		ongoing_total += ongoing.daily_weight(day, 7)
	assert_float(sudden_total).is_equal_approx(1.0, 0.000001)
	assert_float(ongoing_total).is_equal_approx(1.0, 0.000001)
	assert_bool(sudden.daily_weight(0, 7) > ongoing.daily_weight(0, 7)).is_true()
	assert_bool(sudden.daily_weight(6, 7) < ongoing.daily_weight(6, 7)).is_true()
	var unprepared := sudden.estimate(1000000, 7, 0.0, 0.0, 0, 7)
	var protected := sudden.estimate(1000000, 7, 60.0, 0.7, 0, 7)
	assert_bool(protected.affected < unprepared.affected).is_true()
	assert_bool(protected.losses < unprepared.losses).is_true()


func test_report_damage_uses_same_model_and_repair_price_without_income_proxy() -> void:
	var low_income := _fixture()
	var high_income := _fixture()
	for sim: Simulation in [low_income, high_income]:
		var target := _first_crisis(sim)
		if sim == high_income:
			sim.areas[31].base_income *= 10
		sim.advance_to(int(target.start) + int(target.window))
	var report := low_income.report_for()
	assert_int(report.prevented_damage).is_equal(high_income.report_for().prevented_damage)
	var model := SuddenDisasterModel.new()
	var difference := model.total_damage(2, 0.0, 7, 0.0) - model.total_damage(2, 9.0, 7, 0.0)
	assert_int(report.prevented_damage).is_equal(low_income.projects.repair_cost(difference))
	assert_int(report.repair_estimate).is_equal(low_income.projects.cost_for("repair", 31))
	var ongoing := OngoingDisasterModel.new()
	assert_float(ongoing.total_damage(5, 0.0, 10, 5.0)).is_equal_approx(22.5, 0.00001)
	assert_float(ongoing.total_damage(5, 60.0, 10, 7.0)).is_equal_approx(11.5, 0.00001)


func test_month_boundary_on_disaster_start_does_not_generate_awareness_bubble() -> void:
	var sim := _fixture()
	var event: Dictionary = sim.historical.events[0]
	event.day = CalendarClock.date_to_day("1950-03-01")
	event.date = "1950-03-01"
	sim.clock.set_day(int(event.day) - 1)
	sim._calm_months = 1
	sim.advance_to(int(event.day))
	assert_int(sim.crises.active.size()).is_equal(1)
	assert_int(sim.bubbles.size()).is_equal(0)
	assert_int(sim._calm_months).is_equal(1)


func test_completed_awareness_tree_stops_new_bubbles_but_preserves_existing_ones() -> void:
	var sim := _fixture()
	sim.advance_to(CalendarClock.date_to_day("1950-03-01"))
	assert_int(sim.bubbles.size()).is_equal(1)
	var existing := sim.bubbles.duplicate()
	var last := ""
	for definition: MeasureDefinition in sim.projects.definitions.values():
		if definition.kind == "awareness":
			last = definition.id
			sim.projects.global_completed.append(definition.id)
	assert_bool(sim.projects.awareness_complete()).is_true()
	sim.advance_to(CalendarClock.date_to_day("1950-05-01"))
	assert_array(sim.bubbles).is_equal(existing)
	sim.collect_bubble(existing[0])
	sim.advance_to(CalendarClock.date_to_day("1950-07-01"))
	assert_int(sim.bubbles.size()).is_equal(0)
	sim.projects.global_completed.erase(last)
	assert_bool(sim.projects.awareness_complete()).is_false()
	sim.advance_to(CalendarClock.date_to_day("1950-09-01"))
	assert_int(sim.bubbles.size()).is_equal(1)
