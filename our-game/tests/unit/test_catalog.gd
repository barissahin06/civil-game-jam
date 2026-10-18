extends GdUnitTestSuite


func test_all_centers_and_every_province_have_one_owner() -> void:
	var catalog := Catalog.new()
	var areas := catalog.load_areas()
	assert_int(areas.size()).is_equal(30)
	var provinces: Array[int] = []
	var total_income := 0
	for area: ServiceArea in areas.values():
		assert_bool(area.id in area.province_ids).is_true()
		provinces.append_array(area.province_ids)
		total_income += area.income()
	provinces.sort()
	assert_int(provinces.size()).is_equal(81)
	for index: int in range(81):
		assert_int(provinces[index]).is_equal(index + 1)
	assert_int(total_income).is_equal(4675000)
	assert_int(catalog.validation_errors.size()).is_equal(0)


func test_added_centers_keep_regional_population_and_upkeep_with_proportional_income() -> void:
	var areas := Catalog.new().load_areas()
	var expected := {
		"Marmara": [4400000, 886647, 30354],
		"Ege": [3000000, 604526, 20688],
		"İç Anadolu": [3800000, 765732, 26206],
		"Akdeniz": [3200000, 644826, 22068],
		"Karadeniz": [2600000, 523921, 17929],
		"Doğu Anadolu": [3000000, 604523, 20688],
		"Güneydoğu Anadolu": [3200000, 644825, 22067],
	}
	for region: String in expected:
		var totals: Array[int] = [0, 0, 0]
		for area: ServiceArea in areas.values():
			if area.region == region:
				totals[0] += area.population
				totals[1] += area.base_income
				totals[2] += area.base_upkeep
		assert_array(totals).is_equal(expected[region])
	for id: int in [3, 10, 17, 24, 33, 36, 37, 46, 58]:
		assert_bool(areas.has(id)).is_true()
		assert_int(areas[id].teams).is_equal(1)
		assert_int(areas[id].total_teams).is_equal(1)
		assert_int(areas[id].stock).is_equal(40)
	assert_str(areas[48].name).is_equal("Muğla")


func test_monthly_budget_keeps_headroom_for_two_projects_and_overcommitment_uses_reserve() -> void:
	var catalog := Catalog.new()
	var areas := catalog.load_areas(1950)
	var treasury := Treasury.new()
	var projects := ProjectSystem.new()
	projects.setup(catalog.load_definitions(), areas, treasury, TrustState.new())
	treasury.refresh_forecast(areas, projects)
	assert_int(treasury.money).is_equal(20000000)
	assert_int(treasury.last_income).is_equal(4675000)
	assert_int(treasury.last_upkeep).is_equal(1360000)
	assert_int(treasury.last_net).is_equal(3315000)
	assert_int(projects.monthly_cost_for("river_zoning", 34)).is_equal(1000000)
	for area_id: int in [34, 31]:
		assert_bool(projects.start("river_zoning", area_id, 1950).ok).is_true()
	var settlement := treasury.collect_and_maintain(areas, projects)
	projects.tick_month(1950, bool(settlement.can_pay_budget))
	assert_int(treasury.money).is_equal(21315000)
	for area_id: int in [1, 6]:
		assert_bool(projects.start("river_zoning", area_id, 1950).ok).is_true()
	for month: int in range(2):
		settlement = treasury.collect_and_maintain(areas, projects)
		projects.tick_month(1950, bool(settlement.can_pay_budget))
	assert_int(treasury.money).is_equal(19945000)
	assert_float(treasury.maintenance_ratio).is_equal(1.0)


func test_every_start_year_keeps_the_previous_catalog_investment_headroom() -> void:
	var catalog := Catalog.new()
	for year: int in range(1950, 1991):
		var areas := catalog.load_areas(year)
		var elapsed := year - 1950
		var previous_income := roundi(4000000 * (1.0 + elapsed * 0.015))
		var previous_teams := 21 * (1 + int(elapsed / 20))
		var previous_net := previous_income - 160000 - previous_teams * ProjectSystem.TEAM_UPKEEP
		var treasury := Treasury.new()
		var projects := ProjectSystem.new()
		projects.setup(catalog.load_definitions(), areas, treasury, TrustState.new())
		treasury.refresh_forecast(areas, projects)
		assert_bool(treasury.last_net >= previous_net).is_true()


func test_linked_research_groups_and_cross_benefits() -> void:
	var catalog := Catalog.new()
	var definitions := catalog.load_definitions()
	var counts: Array[int] = [0, 0, 0, 0]
	for definition: MeasureDefinition in definitions.values():
		if definition.is_research():
			counts[definition.tab] += 1
		for requirement: String in definition.prerequisites:
			assert_bool(definitions.has(requirement)).is_true()
	for index: int in range(4):
		assert_int(counts[index]).is_equal(10)
	var river: MeasureDefinition = definitions.river_zoning
	assert_bool(river.effects.has("protection_flood")).is_true()
	assert_bool(river.effects.has("protection_earthquake")).is_true()
	assert_int(definitions.community_preparedness.months).is_less(
		definitions.research_structural.months
	)


func test_later_start_has_period_profile_and_round_trip() -> void:
	var catalog := Catalog.new()
	var early := catalog.load_areas(1950)
	var later := catalog.load_areas(1990)
	assert_bool(later[34].population > early[34].population).is_true()
	assert_bool(later[34].base_income > early[34].base_income).is_true()
	assert_bool(later[34].total_teams > early[34].total_teams).is_true()
	var restored := ServiceArea.from_dict(later[34].to_dict())
	assert_object(restored).is_not_null()
	assert_int(restored.id).is_equal(34)
	assert_array(restored.province_ids).is_equal(later[34].province_ids)


func test_invalid_model_data_is_rejected() -> void:
	var catalog := Catalog.new()
	var area: ServiceArea = catalog.load_areas()[34]
	var invalid := area.to_dict()
	invalid.teams = 2
	invalid.total_teams = 1
	assert_object(ServiceArea.from_dict(invalid)).is_null()
	invalid = area.to_dict()
	invalid.province_ids = [34, 34]
	assert_object(ServiceArea.from_dict(invalid)).is_null()
	var definitions := catalog.load_definitions()
	var bad_effects: Dictionary = {"id": "bad"}
	assert_object(MeasureDefinition.from_dict(bad_effects)).is_null()
	assert_int(definitions.size()).is_greater(20)
