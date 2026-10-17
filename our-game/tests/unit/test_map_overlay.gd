extends GdUnitTestSuite


func _fixture() -> Simulation:
	var sim := Simulation.new()
	assert_bool(sim.setup()).is_true()
	return sim


func test_stock_scale_saturates_without_hiding_the_actual_inventory() -> void:
	var sim := _fixture()
	for stock: int in [0, 80, 160, 240]:
		sim.areas[1].stock = stock
		var overlay := sim.map_overlay(2)
		var area: Dictionary = overlay.areas[1]
		assert_float(overlay.minimum).is_equal(0.0)
		assert_float(overlay.maximum).is_equal(160.0)
		assert_float(area.value).is_equal(float(stock))
		assert_float(area.ratio).is_equal(minf(float(stock) / 160.0, 1.0))
	assert_int(sim.areas[1].stock).is_equal(240)


func test_damage_scale_runs_from_undamaged_to_fully_damaged() -> void:
	var sim := _fixture()
	for damage: float in [0.0, 50.0, 100.0]:
		sim.areas[1].damage = damage
		var overlay := sim.map_overlay(3)
		assert_float(overlay.minimum).is_equal(0.0)
		assert_float(overlay.maximum).is_equal(100.0)
		assert_float(overlay.areas[1].value).is_equal(damage)
		assert_float(overlay.areas[1].ratio).is_equal(damage / 100.0)


func test_preparedness_is_the_average_of_all_five_existing_disaster_models() -> void:
	var sim := _fixture()
	sim.areas[1].completed_measures.append("slope_control")
	sim.areas[1].completed_measures.append("strengthening")
	sim.areas[1].damage = 25.0
	var expected := 0.0
	for kind: String in ["earthquake", "flood", "fire", "avalanche", "landslide"]:
		expected += sim.projects.preparedness(1, kind) / 5.0
	var overlay := sim.map_overlay(1)
	assert_float(overlay.maximum).is_equal(100.0)
	assert_float(overlay.areas[1].value).is_equal_approx(expected, 0.00001)
	assert_float(overlay.areas[1].ratio).is_equal_approx(expected / 100.0, 0.00001)


func test_every_mode_returns_detached_area_data_without_mutating_the_campaign() -> void:
	var sim := _fixture()
	var before := JSON.stringify(sim.to_dict())
	for mode: int in range(4):
		var overlay := sim.map_overlay(mode)
		assert_int(overlay.mode).is_equal(mode)
		assert_int(overlay.areas.size()).is_equal(sim.areas.size())
		for area: ServiceArea in sim.areas.values():
			assert_str(overlay.areas[area.id].name).is_equal(area.name)
			assert_str(overlay.areas[area.id].region).is_equal(area.region)
			if mode == 0:
				assert_float(overlay.areas[area.id].value).is_equal(0.0)
				assert_float(overlay.areas[area.id].ratio).is_equal(0.0)
		overlay.areas[1].name = "Changed display copy"
		overlay.areas[1].value = 999.0
		overlay.areas.clear()
	assert_str(JSON.stringify(sim.to_dict())).is_equal(before)
	assert_dict(sim.map_overlay(-1)).is_empty()
	assert_dict(sim.map_overlay(4)).is_empty()
