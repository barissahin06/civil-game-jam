extends GdUnitTestSuite


func test_capacity_ages_and_warns_before_critical_without_changing_knowledge() -> void:
	var sim := Simulation.new()
	assert_bool(sim.setup()).is_true()
	var area: ServiceArea = sim.areas[34]
	area.completed_measures.append("strengthening")
	area.completed_measures.append("river_zoning")
	var initial := sim.projects.get_effect(34, "protection_earthquake")
	var notices := 0
	for month: int in range(120):
		notices += sim.projects.age_capacity().size()
	assert_float(area.condition).is_equal(70.0)
	assert_int(notices).is_equal(30)
	assert_float(area.capacity_efficiency()).is_equal(0.85)
	assert_float(sim.projects.get_effect(34, "protection_earthquake")).is_equal(
		initial - 22.0 * 0.15
	)
	area.condition = 0.0
	assert_float(sim.projects.get_effect(34, "protection_earthquake")).is_equal(16.0)


func test_renewal_prices_home_capacity_uses_local_slot_and_restores_on_completion() -> void:
	var sim := Simulation.new()
	assert_bool(sim.setup()).is_true()
	var area: ServiceArea = sim.areas[34]
	area.condition = 70.0
	area.completed_measures.append("strengthening")
	area.completed_measures.append("river_zoning")
	assert_int(sim.projects.cost_for("center_renewal", 34)).is_equal(11000000)
	area.teams = 0
	assert_int(sim.projects.cost_for("center_renewal", 34)).is_equal(11000000)
	var before := sim.treasury.money
	var started := sim.projects.start("center_renewal", 34, 1950)
	assert_bool(started.ok).is_true()
	assert_bool(sim.projects.start("repair", 34, 1950).ok).is_false()
	for month: int in range(5):
		sim.projects.tick_month(1950)
	assert_float(area.condition).is_equal(70.0)
	sim.projects.tick_month(1950)
	assert_float(area.condition).is_equal(100.0)
	assert_int(before - sim.treasury.money).is_equal(11000000)
	assert_float(sim.trust.value).is_equal(70.0)
	assert_bool(sim.projects.availability("center_renewal", 34, 1950).ok).is_false()


func test_renewal_snapshot_and_condition_survive_restore_and_bad_values_are_rejected() -> void:
	var sim := Simulation.new()
	assert_bool(sim.setup()).is_true()
	sim.areas[34].condition = 72.0
	var started := sim.projects.start("center_renewal", 34, 1950)
	assert_bool(started.ok).is_true()
	sim.projects.tick_month(1950)
	sim.areas[34].total_teams += 1
	sim.areas[34].teams += 1
	assert_int(sim.projects.cost_for("center_renewal", 34)).is_equal(4000000)
	var data := JSON.parse_string(JSON.stringify(sim.to_dict())) as Dictionary
	var restored := SaveStore.new().restore(data)
	assert_object(restored).is_not_null()
	if restored != null:
		assert_float(restored.areas[34].condition).is_equal(72.0)
		assert_int(restored.projects.get_project(started.uid).paid).is_equal(333333)
	data.projects.projects[0].cost_budget = 1
	assert_object(SaveStore.new().restore(data)).is_null()
	data = JSON.parse_string(JSON.stringify(sim.to_dict())) as Dictionary
	data.areas[0].condition = 101.0
	assert_object(SaveStore.new().restore(data)).is_null()
