extends GdUnitTestSuite


func _fixture(active_crisis: bool = false) -> Simulation:
	var sim := Simulation.new()
	assert_bool(sim.setup()).is_true()
	if active_crisis:
		sim.advance_to(CalendarClock.date_to_day("1951-04-08"))
		sim.acknowledge()
	return sim


func _center(overview: Dictionary, id: int) -> Dictionary:
	for center: Dictionary in overview.centers:
		if int(center.area_id) == id:
			return center
	assert(false, "Missing unit center: %d" % id)
	return {}


func test_initial_overview_is_ordered_and_detached_from_campaign_state() -> void:
	var sim := _fixture()
	var before := JSON.stringify(sim.to_dict())
	var overview := sim.unit_overview()
	assert_dict(overview.summary).is_equal(
		{"ready": 30, "total": 30, "stock": 1200, "outbound": 0, "deployed": 0, "returning": 0}
	)
	assert_int(overview.centers.size()).is_equal(30)
	var previous := 0
	for center: Dictionary in overview.centers:
		assert_int(center.area_id).is_greater(previous)
		previous = int(center.area_id)
		assert_int(center.ready).is_equal(1)
		assert_int(center.total).is_equal(1)
		assert_int(center.stock).is_equal(40)
		assert_str(center.name).is_equal(sim.areas[previous].name)
	# A caller may edit its returned display data without changing a live center or shipment.
	overview.summary.ready = 900
	overview.summary.stock = 900
	overview.centers.front().ready = 800
	overview.centers.front().name = "Changed display copy"
	overview.centers.clear()
	assert_str(JSON.stringify(sim.to_dict())).is_equal(before)
	assert_int(sim.unit_overview().summary.ready).is_equal(30)
	assert_int(sim.unit_overview().summary.stock).is_equal(1200)


func test_team_lifecycle_counts_source_centers_and_excludes_aid_and_done_shipments() -> void:
	var sim := _fixture(true)
	var crisis: Dictionary = sim.crises.active.front()
	assert_bool(sim.dispatch(31, crisis.id, "team", 1).ok).is_true()
	assert_bool(sim.dispatch(1, crisis.id, "team", 1).ok).is_true()
	assert_bool(sim.dispatch(6, crisis.id, "stock", 10).ok).is_true()
	var overview := sim.unit_overview()
	assert_dict(overview.summary).is_equal(
		{"ready": 28, "total": 30, "stock": 1190, "outbound": 1, "deployed": 1, "returning": 0}
	)
	assert_int(_center(overview, 31).deployed).is_equal(1)
	assert_int(_center(overview, 1).outbound).is_equal(1)
	assert_int(_center(overview, 6).outbound).is_equal(0)
	assert_int(_center(overview, 6).stock).is_equal(30)
	sim.advance_to(int(crisis.start) + 1)
	overview = sim.unit_overview()
	assert_int(overview.summary.outbound).is_equal(0)
	assert_int(overview.summary.deployed).is_equal(2)
	assert_int(overview.summary.stock).is_equal(1190)
	var deadline := int(crisis.start) + int(crisis.window)
	sim.advance_to(deadline)
	overview = sim.unit_overview()
	assert_dict(overview.summary).is_equal(
		{"ready": 29, "total": 30, "stock": 1190, "outbound": 0, "deployed": 0, "returning": 1}
	)
	assert_int(_center(overview, 31).ready).is_equal(1)
	assert_int(_center(overview, 31).returning).is_equal(0)
	assert_int(_center(overview, 1).returning).is_equal(1)
	sim.advance_to(deadline + 1)
	overview = sim.unit_overview()
	assert_dict(overview.summary).is_equal(
		{"ready": 30, "total": 30, "stock": 1190, "outbound": 0, "deployed": 0, "returning": 0}
	)
	assert_int(sim.logistics.shipments.size()).is_equal(3)
	assert_str(sim.logistics.shipments.front().state).is_equal("done")


func test_dispatch_access_explains_crisis_inventory_and_campaign_gates() -> void:
	var sim := _fixture()
	var center := _center(sim.unit_overview(), 31)
	assert_bool(center.can_dispatch).is_false()
	assert_str(center.dispatch_message).contains("aktif afet")
	sim.advance_to(CalendarClock.date_to_day("1951-04-08"))
	sim.acknowledge()
	assert_bool(_center(sim.unit_overview(), 31).can_dispatch).is_true()
	sim.areas[31].teams = 0
	sim.areas[31].stock = 0
	center = _center(sim.unit_overview(), 31)
	assert_bool(center.can_dispatch).is_false()
	assert_str(center.dispatch_message).contains("hazır ekip veya yardım yok")
	sim.areas[31].stock = 1
	assert_bool(_center(sim.unit_overview(), 31).can_dispatch).is_true()
	sim.outcome = "ending"
	center = _center(sim.unit_overview(), 31)
	assert_bool(center.can_dispatch).is_false()
	assert_str(center.dispatch_message).contains("Oyun tamamlandı")
