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
	assert_int(settlement.income).is_equal(4675000)
	assert_int(settlement.upkeep).is_equal(1360000)
	assert_int(settlement.net).is_equal(3315000)
	system.tick_month(1950, settlement.can_pay_budget)
	assert_int(system.treasury.money).is_equal(22315000)
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
	system.global_completed.append("research_radio")
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
	system.treasury.money = int(system.calculate_upkeep() / 2)
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
	assert_int(system.calculate_upkeep()).is_equal(1400000)
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


func test_effect_preview_is_read_only_and_matches_local_completion() -> void:
	var system := _fixture()
	system.treasury.maintenance_ratio = 0.5
	system.areas[34].damage = 35.0
	system.areas[34].completed_measures.append("assembly_areas")
	system.repair_support[34] = 1000000
	system.start("strengthening", 6, 1950)
	var before := _preview_state(system)
	var area_before: ServiceArea = system.areas[34]
	var preview := system.effect_preview("river_zoning", 34)
	assert_str(_preview_state(system)).is_equal(before)
	assert_bool(system.areas[34] == area_before).is_true()
	assert_bool(preview.global).is_false()
	assert_float(preview.maintenance_ratio).is_equal(0.5)
	assert_int(preview.rows.size()).is_equal(3)
	var flood := _effect_row(preview, "protection_flood")
	assert_float(flood.before).is_equal(system.preparedness(34, "flood"))
	assert_bool(is_equal_approx(flood.delta, 18.6)).is_true()
	assert_str(flood.unit).is_equal("points")
	assert_bool(flood.bounded and flood.higher_is_better).is_true()
	assert_bool(system.start("river_zoning", 34, 1950).ok).is_true()
	for month: int in range(6):
		system.tick_month(1950)
	assert_float(flood.after).is_equal(system.preparedness(34, "flood"))
	assert_float(_effect_row(preview, "resilience").after).is_equal(system.infrastructure(34))
	assert_str(system.projects[0].status).is_equal("active")
	for row: Dictionary in system.effect_preview("river_zoning", 34).rows:
		assert_float(row.delta).is_equal(0.0)


func test_global_effect_preview_averages_actual_centers_and_maintenance() -> void:
	var system := _fixture()
	system.treasury.maintenance_ratio = 0.5
	for area: ServiceArea in system.areas.values():
		area.resilience = 100.0
	system.areas[34].completed_measures.append("strengthening")
	var definition := system.definition_for("research_structural")
	definition.effects.protection_earthquake = 80.0
	definition.months = 1
	var preview := system.effect_preview(definition.id)
	assert_bool(preview.global).is_true()
	var row := _effect_row(preview, "protection_earthquake")
	assert_float(row.before).is_equal(_mean_preparedness(system, "earthquake"))
	assert_bool(system.start(definition.id, 0, 1950).ok).is_true()
	system.tick_month(1950)
	assert_float(row.after).is_equal(_mean_preparedness(system, "earthquake"))
	assert_float(row.after).is_equal(100.0)
	var radio := system.effect_preview("national_radio")
	assert_float(_effect_row(radio, "rescue_efficiency").delta).is_equal(1.5)
	assert_float(radio.maintenance_ratio).is_equal(0.5)


func test_effect_preview_respects_consumer_caps_and_capacity() -> void:
	var system := _fixture()
	system.definition_for("research_response").effects.repair_efficiency = 0.4
	system.definition_for("community_preparedness").effects.trust_decay_reduction = 1.0
	var repair := _effect_row(system.effect_preview("research_response"), "repair_efficiency")
	var trust_row := _effect_row(
		system.effect_preview("community_preparedness"), "trust_decay_reduction"
	)
	assert_float(repair.after).is_equal(15.0)
	assert_float(repair.maximum).is_equal(15.0)
	assert_float(trust_row.after).is_equal(85.0)
	assert_float(trust_row.maximum).is_equal(85.0)
	assert_bool(repair.bounded and trust_row.bounded).is_true()
	system.initialize_era(1990)
	var capacity := _effect_row(system.effect_preview("research_capacity"), "research_capacity")
	assert_float(capacity.before).is_equal(2.0)
	assert_float(capacity.after).is_equal(3.0)
	assert_bool(capacity.bounded).is_true()
	system.definition_for("research_capacity").months = 1
	assert_bool(system.start("research_capacity", 0, 1990).ok).is_true()
	system.tick_month(1990)
	assert_float(capacity.after).is_equal(float(system.research_capacity))
	(
		assert_float(
			_effect_row(system.effect_preview("research_capacity"), "research_capacity").delta
		)
		. is_equal(0.0)
	)


func test_repair_preview_shows_beneficial_reduction_and_restored_income() -> void:
	var system := _fixture()
	system.areas[34].damage = 60.0
	var before := _preview_state(system)
	var preview := system.effect_preview("repair", 34)
	assert_str(_preview_state(system)).is_equal(before)
	var damage := _effect_row(preview, "damage")
	var income := _effect_row(preview, "income")
	assert_float(damage.before).is_equal(60.0)
	assert_float(damage.after).is_equal(0.0)
	assert_float(damage.delta).is_equal(-60.0)
	assert_bool(damage.higher_is_better).is_false()
	assert_float(income.before).is_equal(float(system.areas[34].income()))
	assert_float(income.after).is_equal(float(system.areas[34].base_income))
	assert_str(income.unit).is_equal("money")
	assert_bool(system.start("repair", 34, 1950).ok).is_true()
	for month: int in range(6):
		system.tick_month(1950)
	assert_float(damage.after).is_equal(system.areas[34].damage)
	assert_float(income.after).is_equal(float(system.areas[34].income()))
	assert_float(_effect_row(preview, "resilience").after).is_equal(system.infrastructure(34))


func test_repeatable_effect_preview_uses_total_teams_and_uncapped_stock() -> void:
	var system := _fixture()
	system.areas[34].total_teams = 8
	system.areas[34].teams = 2
	system.areas[34].stock = 240
	var team := _effect_row(system.effect_preview("rescue_team", 34), "teams")
	var stock := _effect_row(system.effect_preview("aid_stock", 34), "stock")
	assert_float(team.before).is_equal(8.0)
	assert_float(team.after).is_equal(9.0)
	assert_bool(team.bounded).is_false()
	assert_bool(team.maximum >= team.after).is_true()
	assert_float(stock.before).is_equal(240.0)
	assert_float(stock.after).is_equal(280.0)
	assert_bool(stock.bounded).is_false()
	assert_float(stock.maximum).is_equal(280.0)
	system.definition_for("aid_stock").months = 1
	assert_bool(system.start("aid_stock", 34, 1950).ok).is_true()
	system.tick_month(1950)
	assert_float(stock.after).is_equal(float(system.areas[34].stock))
	assert_float(_effect_row(system.effect_preview("aid_stock", 34), "stock").after).is_equal(320.0)
	assert_int(system.effect_preview("missing", 34).rows.size()).is_equal(0)
	assert_int(system.effect_preview("river_zoning", 999).rows.size()).is_equal(0)
	assert_int(system.effect_preview("repair").rows.size()).is_equal(0)


func _effect_row(preview: Dictionary, key: String) -> Dictionary:
	for row: Dictionary in preview.rows:
		if row.key == key:
			return row
	return {}


func _mean_preparedness(system: ProjectSystem, kind: String) -> float:
	var total := 0.0
	for area_id: int in system.areas:
		total += system.preparedness(area_id, kind)
	return total / system.areas.size()


func _preview_state(system: ProjectSystem) -> String:
	var area_records: Array[Dictionary] = []
	for area: ServiceArea in system.areas.values():
		area_records.append(area.to_dict())
	return (
		JSON
		. stringify(
			{
				"project_system": system.to_dict(),
				"capacity": system.research_capacity,
				"areas": area_records,
				"treasury":
				[
					system.treasury.money,
					system.treasury.awareness_points,
					system.treasury.maintenance_ratio,
					system.treasury.last_income,
					system.treasury.last_upkeep,
					system.treasury.last_net
				],
				"trust": system.trust.feedback(),
				"trust_history": system.trust.history,
			}
		)
	)
