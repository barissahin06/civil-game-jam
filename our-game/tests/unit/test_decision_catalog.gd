extends GdUnitTestSuite

const TEST_PATH := "user://test-decision-catalog.json"


func after_test() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(TEST_PATH)


func test_authored_catalog_loads_with_unique_projects_and_shared_reform() -> void:
	var definitions := Catalog.new().load_definitions()
	var events := HistoricalCatalog.new()
	assert_bool(events.load_events()).is_true()
	var catalog := DecisionCatalog.new()
	(
		assert_bool(catalog.load_cards(definitions, events.events, Catalog.new().load_areas()))
		. is_true()
	)
	assert_int(catalog.cards.size()).is_equal(21)
	assert_str(catalog.fingerprint).is_not_empty()
	var reforms := 0
	for card: Dictionary in catalog.cards:
		if card.id == "gediz_relocation":
			assert_int(int(card.area_id)).is_equal(3)
		if card.id == "bozkurt_flood":
			assert_int(int(card.area_id)).is_equal(37)
		if card.id == "construction_inspection":
			reforms += 1
			assert_array(card.event_ids).contains_exactly(["historical-040", "historical-041"])
	assert_int(reforms).is_equal(1)
	assert_int(definitions.decision_gediz_relocation_full.cost_budget).is_equal(18000000)
	assert_int(definitions.decision_samsun_flood_focused.months).is_equal(4)
	assert_bool(definitions.decision_samsun_flood_focused.repeatable).is_false()
	assert_int(definitions.decision_construction_inspection_full.months).is_equal(18)
	definitions.decision_gediz_relocation_full.effects.unknown_effect = 1
	(
		assert_bool(catalog.load_cards(definitions, events.events, Catalog.new().load_areas()))
		. is_false()
	)
	assert_array(catalog.cards).is_empty()


func test_catalog_rejects_bad_references_without_partial_results() -> void:
	var original: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string(DecisionCatalog.PATH)
	)
	var definitions := Catalog.new().load_definitions()
	var events := HistoricalCatalog.new()
	events.load_events()
	var areas := Catalog.new().load_areas()
	var malformed: Array[Dictionary] = []
	var value: Dictionary = original.duplicate(true)
	value.cards[1].id = value.cards[0].id
	malformed.append(value)
	value = original.duplicate(true)
	value.cards[1].event_ids = ["historical-999"]
	malformed.append(value)
	value = original.duplicate(true)
	value.cards[0].area_id = 34
	malformed.append(value)
	value = original.duplicate(true)
	value.cards[1].options[0].project_id = value.cards[0].options[0].project_id
	malformed.append(value)
	value = original.duplicate(true)
	value.cards[0].options[1].project_id = ""
	malformed.append(value)
	value = original.duplicate(true)
	value.cards[0].options[2].trust_delta = "-0.5"
	malformed.append(value)
	value = original.duplicate(true)
	value.cards[0].options[0].id = "decline"
	malformed.append(value)
	value = original.duplicate(true)
	value.cards[0].options[0].project_id = "decision_construction_inspection_full"
	malformed.append(value)
	var catalog := DecisionCatalog.new()
	for data: Dictionary in malformed:
		assert_bool(catalog.load_cards(definitions, events.events, areas)).is_true()
		var file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
		file.store_string(JSON.stringify(data))
		file.close()
		assert_bool(catalog.load_cards(definitions, events.events, areas, TEST_PATH)).is_false()
		assert_array(catalog.cards).is_empty()
		assert_str(catalog.fingerprint).is_empty()
