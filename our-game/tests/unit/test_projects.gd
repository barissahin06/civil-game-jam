extends GdUnitTestSuite


func _fixture() -> ProjectSystem:
	var catalog := Catalog.new()
	var system := ProjectSystem.new()
	system.setup(catalog.load_definitions(), catalog.load_areas(), Treasury.new(), TrustState.new())
	return system


func test_initial_month_pays_maintenance_before_installments() -> void:
	var system := _fixture()
	var started := system.start("river_zoning", 34, 1950)
	assert_bool(started.ok).is_true()
	var settlement := system.treasury.collect_and_maintain(system.areas, system)
	assert_int(settlement.income).is_equal(6000000)
	assert_int(settlement.upkeep).is_equal(1000000)
	assert_int(settlement.net).is_equal(5000000)
	system.tick_month(1950, settlement.can_pay_budget)
	assert_int(system.treasury.money).is_equal(24000000)
	assert_int(system.get_project(started.uid).progress_months).is_equal(1)
	assert_float(system.get_effect(34, "protection_flood")).is_equal(0.0)


func test_integer_installments_finish_exactly_once() -> void:
	var system := _fixture()
	var definition := system.definition_for("river_zoning")
	definition.cost_budget = 10
	definition.months = 3
	var uid: int = system.start(definition.id, 34, 1950).uid
	var before := system.treasury.money
	for month: int in range(3):
		system.tick_month(1950)
	assert_int(system.get_project(uid).paid).is_equal(10)
	assert_int(before - system.treasury.money).is_equal(10)
	assert_float(system.get_effect(34, "protection_flood")).is_equal(18.0)
	assert_float(system.get_effect(34, "protection_earthquake")).is_equal(5.0)
	assert_int(system.tick_month(1950).size()).is_equal(0)
	assert_bool(system.start(definition.id, 34, 1950).ok).is_false()
	assert_int(system.areas[34].completed_measures.size()).is_equal(1)


func test_shared_research_slots_pause_resume_and_awareness_payment() -> void:
	var system := _fixture()
	system.treasury.awareness_points = 30
	var technical := system.start("research_structural", 0, 1950)
	var awareness := system.start("community_preparedness", 0, 1950)
	assert_bool(technical.ok and awareness.ok).is_true()
	assert_int(system.treasury.awareness_points).is_equal(15)
	assert_int(system.active_count("research")).is_equal(2)
	assert_bool(system.start("research_meteorology", 0, 1950).ok).is_false()
	system.tick_month(1950)
	assert_bool(system.pause(awareness.uid).ok).is_true()
	var third := system.start("research_meteorology", 0, 1950)
	assert_bool(third.ok).is_true()
	assert_bool(system.resume(awareness.uid).ok).is_false()
	assert_bool(system.cancel(third.uid).ok).is_true()
	assert_bool(system.resume(awareness.uid).ok).is_true()
	assert_int(system.get_project(awareness.uid).progress_months).is_equal(1)
	assert_int(system.treasury.awareness_points).is_equal(15)


func test_local_and_national_slots_are_independent() -> void:
	var system := _fixture()
	var local := system.start("river_zoning", 34, 1950)
	assert_bool(local.ok).is_true()
	assert_bool(system.start("strengthening", 34, 1950).ok).is_false()
	assert_bool(system.start("river_zoning", 6, 1950).ok).is_true()
	assert_bool(system.start("national_radio", 0, 1950).ok).is_true()
	assert_bool(system.start("research_structural", 0, 1950).ok).is_true()
	assert_bool(system.pause(local.uid).ok).is_true()
	assert_bool(system.start("strengthening", 34, 1950).ok).is_true()
	assert_bool(system.resume(local.uid).ok).is_false()


func test_priority_then_oldest_is_paid_without_debt() -> void:
	var system := _fixture()
	var first := system.start("river_zoning", 34, 1950)
	var second := system.start("river_zoning", 6, 1950)
	system.treasury.money = 1000000
	system.set_priority(second.uid, true)
	system.tick_month(1950)
	assert_int(system.get_project(first.uid).progress_months).is_equal(0)
	assert_str(system.get_project(first.uid).status).is_equal("waiting")
	assert_int(system.get_project(second.uid).progress_months).is_equal(1)
	assert_int(system.treasury.money).is_equal(0)
	system.treasury.money = 1000000
	system.set_priority(second.uid, false)
	system.tick_month(1950)
	assert_int(system.get_project(first.uid).progress_months).is_equal(1)
	assert_int(system.get_project(second.uid).progress_months).is_equal(1)
	assert_bool(system.treasury.spend(-1)).is_false()


func test_inadequate_maintenance_reduces_physical_effects_and_waits() -> void:
	var system := _fixture()
	var strengthening := system.definition_for("strengthening")
	strengthening.months = 1
	system.start(strengthening.id, 34, 1950)
	system.tick_month(1950)
	system.start("river_zoning", 34, 1950)
	for area: ServiceArea in system.areas.values():
		area.base_income = 0
	system.treasury.money = 540000
	var settlement := system.treasury.collect_and_maintain(system.areas, system)
	assert_float(settlement.maintenance_ratio).is_equal(0.5)
	assert_float(system.get_effect(34, "protection_earthquake")).is_equal(11.0)
	system.tick_month(1950, settlement.can_pay_budget)
	assert_int(system.projects[1].progress_months).is_equal(0)
	assert_int(system.treasury.money).is_equal(0)


func test_repair_restores_income_gradually_and_repeatable_teams_add_upkeep() -> void:
	var system := _fixture()
	system.areas[34].damage = 60.0
	var income_before: int = system.areas[34].income()
	var repair := system.start("repair", 34, 1950)
	assert_int(system.get_project(repair.uid).cost_budget).is_equal(7200000)
	system.tick_month(1950)
	assert_float(system.areas[34].damage).is_equal(50.0)
	assert_bool(system.areas[34].income() > income_before).is_true()
	for month: int in range(5):
		system.tick_month(1950)
	assert_float(system.areas[34].damage).is_equal(0.0)
	var team := system.definition_for("rescue_team")
	team.months = 1
	system.start(team.id, 34, 1950)
	system.tick_month(1950)
	assert_int(system.areas[34].teams).is_equal(2)
	assert_int(system.calculate_upkeep()).is_equal(1040000)
	assert_bool(system.start(team.id, 34, 1950).ok).is_true()


func test_era_prerequisites_and_one_capacity_expansion() -> void:
	var system := _fixture()
	assert_bool(system.start("research_ground", 0, 1950).ok).is_false()
	assert_bool(system.start("gas_cutoff", 34, 1970).ok).is_false()
	system.initialize_era(1990)
	assert_bool(system.is_completed("research_structural")).is_true()
	assert_bool(system.is_completed("research_depots")).is_true()
	assert_bool(system.is_completed("research_isolation")).is_false()
	var capacity := system.definition_for("research_capacity")
	capacity.months = 1
	system.start(capacity.id, 0, 1990)
	system.tick_month(1990)
	assert_int(system.research_capacity).is_equal(3)
	assert_bool(system.start(capacity.id, 0, 1990).ok).is_false()


func test_saved_projects_restore_without_double_charge_and_bad_progress_is_rejected() -> void:
	var system := _fixture()
	var started := system.start("river_zoning", 34, 1950)
	system.tick_month(1950)
	var saved := system.to_dict()
	var restored := _fixture()
	assert_bool(restored.restore(saved)).is_true()
	assert_int(restored.get_project(started.uid).paid).is_equal(1000000)
	var before := restored.treasury.money
	restored.tick_month(1950)
	assert_int(before - restored.treasury.money).is_equal(1000000)
	var invalid := saved.duplicate(true)
	invalid.projects[0].progress_months = 99
	assert_bool(restored.restore(invalid)).is_false()
	assert_int(restored.get_project(started.uid).progress_months).is_equal(2)


func test_repair_fund_discount_is_capped_saved_and_consumed_once() -> void:
	var system := _fixture()
	system.areas[34].damage = 100.0
	system.repair_support[34] = 5000000
	assert_int(system.cost_for("repair", 34)).is_equal(9600000)
	var started := system.start("repair", 34, 1950)
	assert_int(system.get_project(started.uid).repair_support_used).is_equal(5000000)
	var restored := _fixture()
	assert_bool(restored.restore(JSON.parse_string(JSON.stringify(system.to_dict())))).is_true()
	assert_int(restored.repair_support[34]).is_equal(5000000)
	for month: int in range(6):
		system.tick_month(1950)
	assert_int(system.repair_support[34]).is_equal(0)
	system.areas[34].damage = 100.0
	assert_int(system.cost_for("repair", 34)).is_equal(12000000)
	var invalid := restored.to_dict()
	invalid.repair_support[34] = -1
	assert_bool(restored.restore(invalid)).is_false()
