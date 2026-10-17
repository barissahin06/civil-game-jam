extends GdUnitTestSuite


func test_all_centers_and_every_province_have_one_owner() -> void:
	var catalog := Catalog.new()
	var areas := catalog.load_areas()
	assert_int(areas.size()).is_equal(21)
	var provinces: Array[int] = []
	var total_income := 0
	for area: ServiceArea in areas.values():
		provinces.append_array(area.province_ids)
		total_income += area.income()
	provinces.sort()
	assert_int(provinces.size()).is_equal(81)
	for index: int in range(81):
		assert_int(provinces[index]).is_equal(index + 1)
	assert_int(total_income).is_equal(6000000)
	assert_int(catalog.validation_errors.size()).is_equal(0)


func test_linked_research_groups_and_cross_benefits() -> void:
	var catalog := Catalog.new()
	var definitions := catalog.load_definitions()
	var counts: Array[int] = [0, 0, 0, 0]
	for definition: MeasureDefinition in definitions.values():
		if definition.is_research():
			counts[definition.tab] += 1
			assert_str(definition.story_headline).is_not_empty()
			assert_str(definition.story_text).is_not_empty()
		for requirement: String in definition.prerequisites:
			assert_bool(definitions.has(requirement)).is_true()
	for index: int in range(3):
		assert_int(counts[index]).is_equal(4)
	assert_int(counts[3]).is_equal(6)
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
	var bad_story: Dictionary = {
		"id": "bad_story",
		"title": "Bad",
		"kind": "research",
		"tab": 0,
		"year": 1950,
		"prerequisites": [],
		"cost_budget": 0,
		"cost_awareness": 0,
		"months": 1,
		"upkeep": 0,
		"effects": {},
		"repeatable": false,
		"story": {"headline": ""},
	}
	assert_object(MeasureDefinition.from_dict(bad_story)).is_null()
	assert_int(definitions.size()).is_greater(20)
