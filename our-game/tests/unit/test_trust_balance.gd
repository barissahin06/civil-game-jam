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


func test_natural_decay_remains_small_at_every_trust_level() -> void:
	var trust := TrustState.new()
	for level: float in [1.0, 50.0, 100.0]:
		trust.value = level
		trust.decay_month()
		assert_float(level - trust.value).is_equal_approx(0.01, 0.000001)


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
	assert_float(sim.trust.value).is_equal_approx(50.0, 0.000001)


func test_response_report_shows_actual_clamped_trust_change() -> void:
	var trust := TrustState.new()
	trust.value = 100.0
	assert_float(trust.assess_response(1.0, 1.0, 1.0, 1.0, "Başarı")).is_equal(0.0)
	trust.value = 0.5
	assert_float(trust.assess_response(0.0, 0.0, 0.0, 0.0, "Eksik müdahale")).is_equal(-0.5)
	assert_float(trust.value).is_equal(0.0)


func test_feedback_identifies_initial_bounds_without_an_invented_change() -> void:
	var trust := TrustState.new()
	var result := trust.feedback()
	assert_float(result.value).is_equal(70.0)
	assert_float(result.minimum).is_equal(0.0)
	assert_float(result.maximum).is_equal(100.0)
	assert_bool(result.has_change).is_false()
	assert_float(result.latest_amount).is_equal(0.0)
	assert_str(result.latest_reason).is_equal("Henüz değişim yok")


func test_feedback_keeps_the_last_actual_change_at_both_bounds() -> void:
	var trust := TrustState.new()
	trust.value = 99.5
	trust.change(2.0, "Hazırlık")
	assert_float(trust.feedback().latest_amount).is_equal(0.5)
	trust.change(1.0, "Üst sınırda")
	assert_str(trust.feedback().latest_reason).is_equal("Hazırlık")
	trust.change(-150.0, "Eksik müdahale")
	assert_float(trust.feedback().value).is_equal(0.0)
	assert_float(trust.feedback().latest_amount).is_equal(-100.0)
	trust.change(-1.0, "Alt sınırda")
	assert_str(trust.feedback().latest_reason).is_equal("Eksik müdahale")


func test_feedback_preserves_small_changes_and_cannot_modify_trust() -> void:
	var trust := TrustState.new()
	trust.decay_month()
	var result := trust.feedback()
	assert_float(result.latest_amount).is_equal_approx(-0.01, 0.000001)
	assert_bool(result.has_change).is_true()
	assert_str(result.latest_reason).is_equal("Aylık güven aşınması")
	result.value = 0.0
	result.latest_amount = -90.0
	result.latest_reason = "Değiştirilmiş"
	assert_float(trust.value).is_equal_approx(69.99, 0.000001)
	assert_float(trust.feedback().latest_amount).is_equal_approx(-0.01, 0.000001)
	assert_str(trust.feedback().latest_reason).is_equal("Aylık güven aşınması")


func test_response_recovers_slowly_and_large_event_scaling_stays_bounded() -> void:
	var trust := TrustState.new()
	assert_float(trust.assess_response(1.0, 0.95, 1.0, 1.0, "Başarı")).is_equal_approx(
		0.8, 0.000001
	)
	assert_float(trust.assess_response(1.0, 0.95, 1.0, 1.0, "Büyük başarı", 10.0)).is_equal_approx(
		1.2, 0.000001
	)
	assert_float(trust.assess_response(0.0, 0.0, 0.0, 0.0, "Başarısızlık", 10.0)).is_equal_approx(
		-3.0, 0.000001
	)
