extends GdUnitTestSuite


func _day(iso: String) -> int:
	return CalendarClock.date_to_day(iso)


func _area(id: int = 31) -> ServiceArea:
	var area := ServiceArea.new()
	area.id = id
	area.population = 1000
	return area


func _damage(trust: TrustState, area: ServiceArea, event: String, amount: float, day: int) -> void:
	var previous := area.damage
	area.damage = minf(100.0, area.damage + amount)
	trust.record_damage(event, area.id, area.damage - previous, day)


func test_six_complete_calendar_months_and_new_disaster_keep_separate_grace() -> void:
	var trust := TrustState.new()
	var area := _area()
	var areas := {area.id: area}
	_damage(trust, area, "old", 20.0, _day("1950-01-15"))
	_damage(trust, area, "new", 20.0, _day("1950-07-01"))
	assert_float(trust.review_recovery(_day("1950-07-01"), areas)).is_equal(0.0)
	assert_float(trust.review_recovery(_day("1950-08-01"), areas)).is_equal_approx(-0.03, 0.000001)
	assert_float(trust.damage_records[0].recoverable_loss).is_equal_approx(0.015, 0.000001)
	assert_float(trust.damage_records[1].recoverable_loss).is_equal(0.0)
	assert_float(trust.review_recovery(_day("1950-08-01"), areas)).is_equal(0.0)
	assert_int(TrustState.elapsed_months(_day("1952-08-31"), _day("1953-02-28"))).is_equal(6)
	assert_int(TrustState.elapsed_months(_day("1950-01-15"), _day("1950-07-14"))).is_equal(5)


func test_real_partial_repair_refunds_at_most_half_the_applied_neglect_loss() -> void:
	var trust := TrustState.new()
	var area := _area()
	var areas := {area.id: area}
	_damage(trust, area, "old", 40.0, _day("1950-01-01"))
	trust.review_recovery(_day("1950-07-01"), areas)
	assert_float(trust.value).is_equal_approx(69.94, 0.000001)
	area.damage -= 10.0
	assert_float(trust.repair_damage(area.id, 10.0)).is_equal_approx(0.0075, 0.000001)
	assert_float(trust.damage_records[0].remaining_damage).is_equal(30.0)
	area.damage = 0.0
	assert_float(trust.repair_damage(area.id, 30.0)).is_equal_approx(0.0225, 0.000001)
	assert_float(trust.value).is_equal_approx(69.97, 0.000001)
	assert_array(trust.damage_records).is_empty()
	assert_float(trust.repair_damage(area.id, 40.0)).is_equal(0.0)
	_damage(trust, area, "new", 40.0, _day("1950-08-01"))
	area.damage = 0.0
	assert_float(trust.repair_damage(area.id, 40.0)).is_equal(0.0)


func test_clamped_losses_cannot_be_refunded_as_if_they_were_applied() -> void:
	var trust := TrustState.new()
	var area := _area()
	_damage(trust, area, "old", 100.0, _day("1950-01-01"))
	trust.value = 0.01
	assert_float(trust.review_recovery(_day("1950-07-01"), {area.id: area})).is_equal(-0.01)
	assert_float(trust.review_recovery(_day("1950-08-01"), {area.id: area})).is_equal(0.0)
	area.damage = 0.0
	assert_float(trust.repair_damage(area.id, 100.0)).is_equal_approx(0.005, 0.000001)


func test_recovery_round_trip_preserves_review_and_rejects_bad_ledgers() -> void:
	var trust := TrustState.new()
	var area := _area()
	var areas := {area.id: area}
	_damage(trust, area, "old", 40.0, _day("1950-01-01"))
	var day := _day("1950-07-01")
	trust.review_recovery(day, areas)
	var data: Variant = JSON.parse_string(JSON.stringify(trust.damage_records))
	var restored := TrustState.new()
	restored.value = trust.value
	assert_bool(restored.restore_recovery(data, areas, day)).is_true()
	assert_float(restored.review_recovery(day, areas)).is_equal(0.0)
	var bad: Array = data.duplicate(true)
	bad[0].recoverable_loss = 10.0
	assert_bool(restored.restore_recovery(bad, areas, day)).is_false()
	bad = data.duplicate(true)
	bad[0].remaining_damage = 39.0
	assert_bool(restored.restore_recovery(bad, areas, day)).is_false()
	bad = data.duplicate(true)
	bad[0].last_review_month = TrustState.month_index(day) + 1
	assert_bool(restored.restore_recovery(bad, areas, day)).is_false()
	bad = data.duplicate(true)
	bad.append(bad[0].duplicate(true))
	assert_bool(restored.restore_recovery(bad, areas, day)).is_false()
	bad = data.duplicate(true)
	bad[0].remaining_damage = NAN
	assert_bool(restored.restore_recovery(bad, areas, day)).is_false()
	assert_float(restored.damage_records[0].remaining_damage).is_equal(40.0)


func _crises(provinces: Array[int]) -> Dictionary:
	var catalog := Catalog.new()
	var areas := catalog.load_areas(1950)
	for area: ServiceArea in areas.values():
		area.resilience = 0.0
	var trust := TrustState.new()
	var projects := ProjectSystem.new()
	projects.setup(catalog.load_definitions(), areas, Treasury.new(), trust)
	var logistics := LogisticsSystem.new()
	logistics.setup(areas, projects.treasury, projects)
	var crises := CrisisSystem.new()
	crises.setup(areas, projects, trust, logistics)
	crises.begin(
		{
			"id": "test-event",
			"name": "Test afeti",
			"day": _day("1950-01-01"),
			"province_ids": provinces,
			"kind": "earthquake",
			"severity": 1,
			"response_window_days": 1
		}
	)
	return {
		"crises": crises,
		"trust": trust,
		"logistics": logistics,
		"areas": areas,
		"projects": projects
	}


func test_one_national_assessment_is_independent_of_number_of_identical_centers() -> void:
	var single := _crises([31])
	var multiple := _crises([31, 1])
	var day := _day("1950-01-02")
	single.crises.tick_day(day, single.logistics)
	multiple.crises.tick_day(day, multiple.logistics)
	assert_int(multiple.crises.reports.size()).is_equal(2)
	assert_float(multiple.trust.value).is_equal(single.trust.value)
	assert_int(multiple.trust.history.size()).is_equal(1)
	var carriers := 0
	var delta := 0.0
	for report: Dictionary in multiple.crises.reports:
		assert_bool(report.trust_assessed).is_true()
		assert_str(report.event_id).is_equal("test-event")
		carriers += 1 if report.has("national_trust_delta") else 0
		delta += float(report.trust_delta)
	assert_int(carriers).is_equal(1)
	assert_float(delta).is_equal_approx(float(multiple.trust.value) - 70.0, 0.000001)
	multiple.crises.tick_day(day, multiple.logistics)
	assert_int(multiple.trust.history.size()).is_equal(1)


func test_partial_event_reports_survive_restore_until_the_last_center_finishes() -> void:
	var fixture := _crises([31, 1])
	fixture.crises.active.back().window = 2
	fixture.crises.tick_day(_day("1950-01-02"), fixture.logistics)
	assert_int(fixture.crises.reports.size()).is_equal(1)
	assert_bool(fixture.crises.reports[0].trust_assessed).is_false()
	assert_float(fixture.trust.value).is_equal(70.0)
	var restored := CrisisSystem.new()
	restored.setup(fixture.areas, fixture.projects, fixture.trust, fixture.logistics)
	restored.active.assign(JSON.parse_string(JSON.stringify(fixture.crises.active)))
	restored.reports.assign(JSON.parse_string(JSON.stringify(fixture.crises.reports)))
	restored.tick_day(_day("1950-01-03"), fixture.logistics)
	assert_int(fixture.trust.history.size()).is_equal(1)
	assert_bool(restored.reports.front().trust_assessed).is_true()
	assert_bool(restored.reports.back().trust_assessed).is_true()
	restored.tick_day(_day("1950-01-03"), fixture.logistics)
	assert_int(fixture.trust.history.size()).is_equal(1)


func test_deployed_guest_team_uses_its_home_condition_in_every_support_query() -> void:
	var fixture := _crises([31])
	var crisis: Dictionary = fixture.crises.active.front()
	fixture.logistics.stationed.append({"home": 6, "location": 31, "amount": 1})
	fixture.areas[6].teams -= 1
	fixture.areas[6].condition = 0.0
	(
		assert_bool(
			fixture.logistics.dispatch(31, 31, crisis.id, "team", 1, int(crisis.start), 6).ok
		)
		. is_true()
	)
	fixture.logistics.tick_day(int(crisis.start), fixture.crises.active)
	var feedback: Dictionary = fixture.crises.feedback(crisis.id, fixture.logistics)
	assert_float(feedback.support).is_equal_approx(30.0, 0.000001)
	assert_float(fixture.crises.response_support(crisis).support).is_equal_approx(0.3, 0.000001)
	assert_int(crisis.teams).is_equal(1)
	fixture.areas[6].condition = 100.0
	fixture.areas[31].condition = 0.0
	assert_float(fixture.crises.feedback(crisis.id, fixture.logistics).support).is_equal_approx(
		60.0, 0.000001
	)
	fixture.crises.tick_day(int(crisis.start) + 1, fixture.logistics)
	assert_float(crisis.support_sum).is_equal_approx(0.6, 0.000001)
