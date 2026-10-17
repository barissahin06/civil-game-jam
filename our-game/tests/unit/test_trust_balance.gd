extends GdUnitTestSuite


func test_team_only_response_cannot_replace_aid_and_preparation() -> void:
	var response_only := TrustState.new()
	var prepared := TrustState.new()
	response_only.value = 50.0
	prepared.value = 50.0
	assert_float(response_only.assess_response(0.09, 0.63, 1.0, 0.0, "Ekip ağırlıklı")).is_less(0.0)
	assert_float(prepared.assess_response(0.60, 0.85, 1.0, 1.0, "Hazırlıklı müdahale")).is_greater(
		0.0
	)
	(
		assert_float(
			response_only.assess_response(0.09, 0.95, 1.0, 0.0, "Ekip ve bütçe, yardım yok")
		)
		. is_less(0.0)
	)


func test_damage_pressure_ends_as_damage_is_repaired() -> void:
	var trust := TrustState.new()
	trust.value = 50.0
	trust.decay_month(0.0, 60.0)
	assert_float(trust.value).is_equal_approx(49.895, 0.000001)
	var before := trust.value
	trust.decay_month(0.0, 0.0)
	assert_float(before - trust.value).is_equal_approx(0.015, 0.000001)
	assert_str(trust.history[1].reason).is_equal("Onarılmayan altyapının güven etkisi")


func test_repeatable_logistics_projects_do_not_farm_trust() -> void:
	var sim := Simulation.new()
	assert_bool(sim.setup()).is_true()
	sim.trust.value = 50.0
	for repetition: int in range(3):
		assert_bool(sim.projects.start("aid_stock", 34, 1950).ok).is_true()
		for month: int in range(2):
			sim.projects.tick_month(1950)
	assert_float(sim.trust.value).is_equal(50.0)
	assert_bool(sim.projects.start("river_zoning", 34, 1950).ok).is_true()
	for month: int in range(6):
		sim.projects.tick_month(1950)
	assert_float(sim.trust.value).is_equal_approx(50.6, 0.000001)


func test_response_report_shows_actual_clamped_trust_change() -> void:
	var trust := TrustState.new()
	assert_float(trust.assess_response(1.0, 1.0, 1.0, 1.0, "Başarı")).is_equal(0.0)
	trust.value = 0.5
	assert_float(trust.assess_response(0.0, 0.0, 0.0, 0.0, "Eksik müdahale")).is_equal(-0.5)
	assert_float(trust.value).is_equal(0.0)
