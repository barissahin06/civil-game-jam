extends GdUnitTestSuite


func _fixture(window: int = 7) -> Dictionary:
	var catalog := Catalog.new()
	var areas := catalog.load_areas(1950)
	var treasury := Treasury.new()
	var trust := TrustState.new()
	trust.value = 50.0
	var projects := ProjectSystem.new()
	projects.setup(catalog.load_definitions(), areas, treasury, trust)
	projects.initialize_era(1950)
	var logistics := LogisticsSystem.new()
	logistics.setup(areas, treasury, projects)
	var crises := CrisisSystem.new()
	crises.setup(areas, projects, trust)
	crises.begin(
		{
			"id": "supply-test",
			"name": "İkmal testi",
			"province_ids": [31],
			"kind": "earthquake",
			"severity": 2,
			"day": 100,
			"response_window_days": window
		}
	)
	return {"areas": areas, "crises": crises, "logistics": logistics, "trust": trust}


func _send(fixture: Dictionary, amount: int, day: int = 100, source: int = 31) -> void:
	var crisis: Dictionary = fixture.crises.active.front()
	(
		assert_bool(fixture.logistics.dispatch(source, 31, crisis.id, "stock", amount, day).ok)
		. is_true()
	)
	fixture.logistics.tick_day(day, fixture.crises.active)


func _pending(crisis: Dictionary, arrival: int, amount: int) -> Dictionary:
	return {
		"purpose": "crisis",
		"state": "outbound",
		"kind": "stock",
		"crisis_id": crisis.id,
		"arrival": arrival,
		"amount": amount
	}


func test_daily_consumption_partial_support_and_stock_conservation() -> void:
	var fixture := _fixture(4)
	var crisis: Dictionary = fixture.crises.active.front()
	var initial: int = fixture.areas[31].stock
	var need: Dictionary = fixture.crises.requirements(crisis)
	assert_int(need.daily_stock).is_equal(10)
	assert_int(need.stock).is_equal(30)
	_send(fixture, 25)
	fixture.crises.tick_day(101, fixture.logistics)
	assert_int(crisis.stock).is_equal(15)
	assert_int(crisis.consumed_stock).is_equal(10)
	assert_float(crisis.aid_coverage_sum).is_equal_approx(1.0, 0.00001)
	var after_first := JSON.stringify(crisis)
	fixture.crises.tick_day(101, fixture.logistics)
	assert_str(JSON.stringify(crisis)).is_equal(after_first)
	fixture.crises.tick_day(102, fixture.logistics)
	fixture.crises.tick_day(103, fixture.logistics)
	assert_int(crisis.stock).is_equal(0)
	assert_int(crisis.consumed_stock).is_equal(25)
	assert_float(crisis.aid_coverage_sum).is_equal_approx(2.5, 0.00001)
	assert_float(crisis.support_sum).is_equal_approx(1.0, 0.00001)
	fixture.crises.tick_day(104, fixture.logistics)
	var report: Dictionary = fixture.crises.reports.front()
	assert_float(report.aid_coverage).is_equal_approx(0.625, 0.00001)
	assert_int(report.consumed_stock + report.returned_stock + fixture.areas[31].stock).is_equal(
		initial
	)


func test_unused_field_stock_returns_to_the_target_depot_once() -> void:
	var fixture := _fixture(2)
	var crisis: Dictionary = fixture.crises.active.front()
	var initial: int = fixture.areas[31].stock
	_send(fixture, 30)
	fixture.crises.tick_day(101, fixture.logistics)
	fixture.crises.tick_day(102, fixture.logistics)
	var report: Dictionary = fixture.crises.reports.front()
	assert_int(report.consumed_stock).is_equal(20)
	assert_int(report.returned_stock).is_equal(10)
	assert_float(report.aid_coverage).is_equal_approx(1.0, 0.00001)
	assert_int(crisis.stock).is_equal(0)
	assert_int(fixture.areas[31].stock).is_equal(initial - 20)
	fixture.crises.tick_day(102, fixture.logistics)
	assert_int(fixture.areas[31].stock).is_equal(initial - 20)
	assert_int(fixture.crises.reports.size()).is_equal(1)


func test_forecast_and_feedback_are_read_only_and_use_arrival_days() -> void:
	var fixture := _fixture()
	var crisis: Dictionary = fixture.crises.active.front()
	_send(fixture, 10)
	fixture.logistics.shipments.append(_pending(crisis, 102, 10))
	var before := JSON.stringify({"crisis": crisis, "shipments": fixture.logistics.shipments})
	var forecast: Dictionary = fixture.crises.supply_forecast(crisis.id, fixture.logistics, 100)
	var feedback: Dictionary = fixture.crises.feedback(crisis.id, fixture.logistics)
	assert_int(forecast.first_shortage_day).is_equal(103)
	assert_int(forecast.on_time).is_equal(10)
	assert_int(forecast.late).is_equal(0)
	assert_float(forecast.supply_days).is_equal_approx(1.0, 0.00001)
	assert_int(feedback.stock.daily).is_equal(10)
	assert_int(feedback.stock.capacity).is_equal(30)
	assert_int(feedback.stock.first_shortage_day).is_equal(103)
	assert_int(feedback.stock.missing).is_equal(10)
	(
		assert_str(JSON.stringify({"crisis": crisis, "shipments": fixture.logistics.shipments}))
		. is_equal(before)
	)


func test_forecast_adds_same_day_extra_without_consuming_today() -> void:
	var fixture := _fixture()
	var crisis: Dictionary = fixture.crises.active.front()
	var forecast: Dictionary = fixture.crises.supply_forecast(
		crisis.id, fixture.logistics, 100, {"arrival": 100, "amount": 30}
	)
	assert_bool(forecast.capacity_ok).is_true()
	assert_int(forecast.first_shortage_day).is_equal(104)
	assert_int(crisis.stock).is_equal(0)
	forecast = fixture.crises.supply_forecast(
		crisis.id, fixture.logistics, 100, {"arrival": 100, "amount": 31}
	)
	assert_bool(forecast.capacity_ok).is_false()


func test_shortage_on_the_day_before_unix_epoch_is_not_a_missing_date() -> void:
	var fixture := _fixture(3)
	var crisis: Dictionary = fixture.crises.active.front()
	crisis.start = -2
	var forecast: Dictionary = fixture.crises.supply_forecast(crisis.id, fixture.logistics, -2)
	assert_bool(forecast.has_shortage).is_true()
	assert_int(forecast.first_shortage_day).is_equal(-1)
	forecast = fixture.crises.supply_forecast(
		crisis.id, fixture.logistics, -2, {"arrival": -2, "amount": 30}
	)
	assert_bool(forecast.has_shortage).is_false()
	assert_int(forecast.first_shortage_day).is_equal(-1)


func test_forecast_checks_all_simultaneous_arrivals_before_consumption() -> void:
	var fixture := _fixture()
	var crisis: Dictionary = fixture.crises.active.front()
	fixture.logistics.shipments.append(_pending(crisis, 101, 10))
	fixture.logistics.shipments.append(_pending(crisis, 101, 20))
	var forecast: Dictionary = fixture.crises.supply_forecast(crisis.id, fixture.logistics, 100)
	assert_bool(forecast.capacity_ok).is_true()
	forecast = fixture.crises.supply_forecast(
		crisis.id, fixture.logistics, 100, {"arrival": 101, "amount": 1}
	)
	assert_bool(forecast.capacity_ok).is_false()
	assert_int(forecast.on_time).is_equal(31)


func test_forecast_allows_space_freed_before_a_future_arrival() -> void:
	var fixture := _fixture()
	var crisis: Dictionary = fixture.crises.active.front()
	_send(fixture, 10)
	var forecast: Dictionary = fixture.crises.supply_forecast(
		crisis.id, fixture.logistics, 100, {"arrival": 102, "amount": 30}
	)
	assert_bool(forecast.capacity_ok).is_true()
	assert_int(forecast.first_shortage_day).is_equal(105)


func test_forecast_excludes_other_missions_and_late_arrivals_from_field_capacity() -> void:
	var fixture := _fixture(2)
	var crisis: Dictionary = fixture.crises.active.front()
	var transfer := _pending(crisis, 101, 100)
	transfer.purpose = "transfer"
	fixture.logistics.shipments.append(transfer)
	var other := _pending(crisis, 101, 100)
	other.crisis_id = "another-crisis"
	fixture.logistics.shipments.append(other)
	fixture.logistics.shipments.append(_pending(crisis, 103, 100))
	fixture.logistics.shipments.append(_pending(crisis, 99, 100))
	var forecast: Dictionary = fixture.crises.supply_forecast(crisis.id, fixture.logistics, 100)
	assert_bool(forecast.capacity_ok).is_true()
	assert_int(forecast.first_shortage_day).is_equal(101)
	assert_int(forecast.on_time).is_equal(0)
	assert_int(forecast.late).is_equal(100)


func test_last_day_arrival_counts_and_empty_final_stock_has_full_aid_credit() -> void:
	var fixture := _fixture(3)
	var crisis: Dictionary = fixture.crises.active.front()
	_send(fixture, 20)
	fixture.crises.tick_day(101, fixture.logistics)
	fixture.crises.tick_day(102, fixture.logistics)
	_send(fixture, 10, 102, 1)
	assert_int(fixture.logistics.shipments.back().arrival).is_equal(103)
	fixture.logistics.tick_day(103, fixture.crises.active)
	fixture.crises.tick_day(103, fixture.logistics)
	var report: Dictionary = fixture.crises.reports.front()
	assert_int(report.consumed_stock).is_equal(30)
	assert_int(report.returned_stock).is_equal(0)
	assert_float(report.aid_coverage).is_equal_approx(1.0, 0.00001)
	var expected := TrustState.new()
	expected.value = 50.0
	var expected_delta := expected.assess_response(
		float(crisis.protection) / 100.0, float(report.quality) / 100.0, 0.0, 1.0, "test"
	)
	assert_float(report.trust_delta).is_equal_approx(expected_delta, 0.00001)
