extends GdUnitTestSuite


func _fixture() -> Simulation:
	var sim := Simulation.new()
	assert_bool(sim.setup()).is_true()
	sim.advance_to(CalendarClock.date_to_day("1951-04-08"))
	sim.acknowledge()
	# Dispatch feedback is tested independently of monthly capacity wear.
	for area: ServiceArea in sim.areas.values():
		area.condition = 100.0
	return sim


func test_feedback_distinguishes_field_timely_and_late_shipments() -> void:
	var sim := _fixture()
	var crisis: Dictionary = sim.crises.active.front()
	assert_bool(sim.dispatch(31, crisis.id, "team", 1).ok).is_true()
	assert_bool(sim.dispatch(1, crisis.id, "team", 1).ok).is_true()
	var feedback := sim.crisis_feedback(crisis.id)
	assert_int(feedback.teams.field).is_equal(1)
	assert_int(feedback.teams.on_time).is_equal(1)
	assert_int(feedback.teams.missing).is_equal(0)
	assert_int(feedback.stock.missing).is_equal(30)
	assert_float(feedback.support).is_equal_approx(30.0, 0.00001)
	# The same outbound quantity stops covering the response need after the cutoff.
	sim.logistics.shipments.back().arrival = int(crisis.start) + int(crisis.window) + 1
	feedback = sim.crisis_feedback(crisis.id)
	assert_int(feedback.teams.on_time).is_equal(0)
	assert_int(feedback.teams.late).is_equal(1)
	assert_int(feedback.teams.missing).is_equal(1)


func test_outbound_coverage_is_isolated_by_crisis_and_resource() -> void:
	var sim := _fixture()
	var crisis: Dictionary = sim.crises.active.front()
	var other := crisis.duplicate(true)
	other.id = "parallel-test"
	sim.crises.active.append(other)
	assert_bool(sim.dispatch(1, other.id, "team", 1).ok).is_true()
	assert_bool(sim.dispatch(6, crisis.id, "stock", 10).ok).is_true()
	var feedback := sim.crisis_feedback(crisis.id)
	assert_int(feedback.teams.missing).is_equal(2)
	assert_int(feedback.teams.on_time).is_equal(0)
	assert_int(feedback.stock.missing).is_equal(20)
	assert_int(feedback.stock.on_time).is_equal(10)


func test_last_day_arrival_counts_before_the_response_report() -> void:
	var sim := _fixture()
	var crisis: Dictionary = sim.crises.active.front()
	var deadline := int(crisis.start) + int(crisis.window)
	sim.advance_to(deadline - 1)
	var quote := sim.dispatch_preview(1, crisis.id, "team", 1)
	assert_int(quote.arrival).is_equal(deadline)
	assert_bool(quote.late).is_false()
	assert_bool(sim.quick_dispatch(1, crisis.id, "team").ok).is_true()
	assert_int(sim.crisis_feedback(crisis.id).teams.on_time).is_equal(1)
	sim.advance_to(deadline)
	assert_dict(sim.crisis_feedback(crisis.id)).is_empty()
	assert_float(sim.report_for().quality).is_greater(0.0)


func test_late_shortcut_is_blocked_but_manual_dispatch_remains_available() -> void:
	var sim := _fixture()
	var crisis: Dictionary = sim.crises.active.front()
	sim.advance_to(int(crisis.start) + int(crisis.window) - 1)
	var source := 34
	var preview := sim.dispatch_preview(source, crisis.id, "team", 1)
	assert_bool(preview.late).is_true()
	assert_bool(preview.ok).is_true()
	assert_int(sim.missing_dispatch_amount(source, crisis.id, "team")).is_equal(0)
	assert_bool(sim.quick_dispatch(source, crisis.id, "team").ok).is_false()
	assert_bool(sim.dispatch(source, crisis.id, "team", 1).ok).is_true()
	assert_int(sim.crisis_feedback(crisis.id).teams.missing).is_equal(2)


func test_source_options_are_stable_and_quote_the_full_shortcut_amount() -> void:
	var sim := _fixture()
	var crisis: Dictionary = sim.crises.active.front()
	# Equal distances/fees exercise the stable source-id tiebreaker.
	for area: ServiceArea in sim.areas.values():
		area.longitude = 0.0
		area.latitude = 0.0
	var options := sim.dispatch_options(crisis.id, "stock")
	assert_int(options.size()).is_equal(30)
	assert_int(options.front().source).is_equal(31)
	for index: int in range(1, options.size()):
		var option: Dictionary = options[index]
		var quote := sim.logistics.quote(int(option.source), 31, "stock", 10)
		assert_int(option.amount).is_equal(10)
		assert_int(option.fee).is_equal(quote.fee)
		assert_int(option.days).is_equal(1)
		if index > 1:
			assert_int(option.source).is_greater(int(options[index - 1].source))
	sim.areas[34].completed_measures.append("firebreak")
	options = sim.dispatch_options(crisis.id, "stock")
	assert_int(options[1].source).is_equal(34)
	# Days outrank price even for a very efficient distant source.
	sim.projects.definitions["firebreak"].effects.logistics_efficiency = 100.0
	sim.areas[34].longitude = 100.0
	options = sim.dispatch_options(crisis.id, "stock")
	assert_int(options.back().source).is_equal(34)
	assert_int(options.back().fee).is_less(int(options[1].fee))


func test_missing_selection_uses_exact_rounded_quote_and_available_capacity() -> void:
	var sim := _fixture()
	var crisis: Dictionary = sim.crises.active.front()
	sim.projects.global_completed.append("national_radio")
	sim.projects.global_completed.append("research_depots")
	sim.treasury.money = int(sim.logistics.quote(1, 31, "stock", 7).fee)
	assert_int(sim.missing_dispatch_amount(1, crisis.id, "stock")).is_equal(7)
	sim.treasury.money -= 1
	assert_int(sim.missing_dispatch_amount(1, crisis.id, "stock")).is_equal(6)
	sim.treasury.money = 10000000
	sim.areas[1].stock = 3
	assert_int(sim.missing_dispatch_amount(1, crisis.id, "stock")).is_equal(3)
	sim.areas[1].stock = 80
	assert_int(sim.missing_dispatch_amount(1, crisis.id, "stock")).is_equal(30)


func test_zero_budget_blocks_paid_transport_but_not_free_local_dispatch() -> void:
	var sim := _fixture()
	var crisis: Dictionary = sim.crises.active.front()
	sim.treasury.money = 0
	assert_bool(sim.dispatch_preview(1, crisis.id, "team", 1).ok).is_false()
	assert_int(sim.missing_dispatch_amount(1, crisis.id, "stock")).is_equal(0)
	assert_bool(sim.quick_dispatch(1, crisis.id, "team").ok).is_false()
	assert_bool(sim.quick_dispatch(31, crisis.id, "team").ok).is_true()
	assert_bool(sim.quick_dispatch(31, crisis.id, "team").ok).is_false()
	assert_int(sim.treasury.money).is_equal(0)


func test_repeated_shortcuts_recheck_pending_need_without_overfilling() -> void:
	var sim := _fixture()
	var crisis: Dictionary = sim.crises.active.front()
	sim.areas[1].teams = 3
	assert_bool(sim.quick_dispatch(1, crisis.id, "team").ok).is_true()
	assert_bool(sim.quick_dispatch(1, crisis.id, "team").ok).is_true()
	var cash := sim.treasury.money
	assert_bool(sim.quick_dispatch(1, crisis.id, "team").ok).is_false()
	assert_int(sim.areas[1].teams).is_equal(1)
	assert_int(sim.treasury.money).is_equal(cash)
	assert_int(sim.logistics.shipments.size()).is_equal(2)
	assert_int(sim.crisis_feedback(crisis.id).teams.missing).is_equal(0)
	# The standard form still permits an intentional excess shipment.
	assert_bool(sim.dispatch(1, crisis.id, "team", 1).ok).is_true()


func test_partial_help_need_uses_selection_instead_of_ten_unit_shortcut() -> void:
	var sim := _fixture()
	var crisis: Dictionary = sim.crises.active.front()
	assert_bool(sim.dispatch(31, crisis.id, "stock", 25).ok).is_true()
	assert_bool(sim.quick_dispatch(1, crisis.id, "stock").ok).is_false()
	assert_int(sim.missing_dispatch_amount(1, crisis.id, "stock")).is_equal(5)
	assert_bool(sim.dispatch(1, crisis.id, "stock", 5).ok).is_true()
	assert_int(sim.crisis_feedback(crisis.id).stock.missing).is_equal(0)


func test_queries_leave_state_unchanged_and_same_day_notices_do_not_repeat() -> void:
	var sim := _fixture()
	var crisis: Dictionary = sim.crises.active.front()
	assert_bool(sim.dispatch(1, crisis.id, "team", 1).ok).is_true()
	var convoy: Dictionary = sim.logistics.shipments.back()
	assert_float(sim.shipment_progress(convoy)).is_equal(0.0)
	sim.set_paused(false)
	sim.update(0.75)
	assert_float(sim.shipment_progress(convoy)).is_equal_approx(0.5, 0.00001)
	sim.set_paused(true)
	sim.update(0.25)
	assert_float(sim.shipment_progress(convoy)).is_equal_approx(0.5, 0.00001)
	assert_bool(sim.dispatch(31, crisis.id, "team", 1).ok).is_true()
	assert_str(sim.ticker.back()).contains("1 ekip göreve başladı")
	var before := JSON.stringify(sim.to_dict())
	sim.crisis_feedback(crisis.id)
	sim.dispatch_options(crisis.id, "stock")
	sim.dispatch_preview(1, crisis.id, "team", 1)
	sim.quick_dispatch_preview(1, crisis.id, "team")
	sim.missing_dispatch_amount(1, crisis.id, "stock")
	assert_str(JSON.stringify(sim.to_dict())).is_equal(before)
	assert_array(sim.logistics.tick_day(sim.clock.day, sim.crises.active, sim.crises)).is_empty()
	assert_str(JSON.stringify(sim.to_dict())).is_equal(before)


func test_support_feedback_is_the_daily_model_input_and_ignores_inbound() -> void:
	var sim := _fixture()
	var crisis: Dictionary = sim.crises.active.front()
	sim.projects.global_completed.append("national_radio")
	sim.treasury.maintenance_ratio = 0.5
	assert_bool(sim.dispatch(31, crisis.id, "team", 1).ok).is_true()
	assert_bool(sim.dispatch(1, crisis.id, "team", 1).ok).is_true()
	assert_bool(sim.fund(crisis.id, 5000000).ok).is_true()
	var feedback := sim.crisis_feedback(crisis.id)
	assert_float(feedback.support).is_equal_approx(19.03125, 0.00001)
	sim.crises.tick_day(sim.clock.day + 1, sim.logistics)
	assert_float(float(crisis.support_sum) * 100.0).is_equal_approx(feedback.support, 0.00001)
	assert_float(crisis.baseline_support_sum).is_equal_approx(0.1875, 0.00001)


func test_invalid_query_inputs_fail_without_changing_the_campaign() -> void:
	var sim := _fixture()
	var crisis: Dictionary = sim.crises.active.front()
	var before := JSON.stringify(sim.to_dict())
	assert_dict(sim.crisis_feedback("missing")).is_empty()
	assert_array(sim.dispatch_options(crisis.id, "invalid")).is_empty()
	assert_bool(sim.dispatch_preview(999, crisis.id, "team", 1).ok).is_false()
	assert_bool(sim.dispatch_preview(1, crisis.id, "team", 0).ok).is_false()
	assert_bool(sim.quick_dispatch(1, "missing", "team").ok).is_false()
	assert_bool(sim.quick_dispatch(1, crisis.id, "invalid").ok).is_false()
	assert_int(sim.missing_dispatch_amount(999, crisis.id, "stock")).is_equal(0)
	assert_str(JSON.stringify(sim.to_dict())).is_equal(before)


func test_report_feedback_uses_model_estimates_and_current_recovery_without_save_fields() -> void:
	var sim := _fixture()
	var crisis: Dictionary = sim.crises.active.front()
	sim.advance_to(int(crisis.start) + int(crisis.window))
	var report := sim.report_for()
	var before := JSON.stringify(sim.to_dict())
	var feedback := sim.report_feedback(report)
	assert_str(feedback.area_name).is_equal(sim.areas[31].name)
	assert_str(feedback.preparation_summary).contains(str(report.protected))
	assert_str(feedback.response_summary).contains(str(report.rescued))
	assert_str(feedback.recovery_summary).contains(str(report.repair_estimate))
	for key: String in ["preparation_summary", "response_summary", "recovery_summary"]:
		assert_int(String(feedback[key]).length()).is_less_equal(100)
	assert_str(JSON.stringify(sim.to_dict())).is_equal(before)
	sim.areas[31].damage = 0.0
	assert_str(String(sim.report_feedback(report).recovery_summary).to_lower()).contains(
		"kalan hasar yok"
	)
	assert_dict(sim.report_feedback({})).is_empty()


func test_repair_completion_is_logged_once_with_the_affected_area() -> void:
	var sim := _fixture()
	var crisis: Dictionary = sim.crises.active.front()
	sim.advance_to(int(crisis.start) + int(crisis.window))
	sim.acknowledge()
	# Isolate repair completion from later newspaper pauses in the historical catalog.
	sim._event_index = sim.historical.events.size()
	assert_bool(sim.start_project("repair", 31).ok).is_true()
	for month: int in range(6):
		sim.advance_to(sim.clock.next_month_day())
	var expected := "%s: onarım tamamlandı." % sim.areas[31].name
	var count := 0
	for message: String in sim.ticker:
		if message.begins_with(expected):
			count += 1
	assert_int(count).is_equal(1)
	assert_str(String(sim.report_feedback(sim.report_for()).recovery_summary).to_lower()).contains(
		"kalan hasar yok"
	)
	sim.advance_to(sim.clock.next_month_day())
	var after := 0
	for message: String in sim.ticker:
		if message.begins_with(expected):
			after += 1
	assert_int(after).is_equal(1)
