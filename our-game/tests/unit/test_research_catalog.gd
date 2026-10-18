extends GdUnitTestSuite

const ERAS := [1950, 1970, 1990, 2005, 2020]


class FixtureCatalog:
	extends Catalog
	var payload: Dictionary = {}

	func _load_json(_path: String) -> Variant:
		return payload


func _fixture(year: int = 1950) -> ProjectSystem:
	var catalog := Catalog.new()
	var system := ProjectSystem.new()
	system.setup(
		catalog.load_definitions(), catalog.load_areas(year), Treasury.new(), TrustState.new()
	)
	return system


func test_catalog_has_two_research_per_category_and_era_and_three_national_per_era() -> void:
	var system := _fixture()
	var cells: Dictionary = {}
	var national_counts: Dictionary = {}
	var research_count := 0
	var national_count := 0
	for definition: MeasureDefinition in system.definitions.values():
		if definition.is_research():
			research_count += 1
			var key := "%d:%d" % [definition.tab, definition.year]
			cells[key] = int(cells.get(key, 0)) + 1
			assert_int(definition.upkeep).is_equal(0)
		elif definition.kind == "national" and not definition.id.begins_with("decision_"):
			national_count += 1
			national_counts[definition.year] = int(national_counts.get(definition.year, 0)) + 1
		for requirement: String in definition.prerequisites:
			assert_bool(system.definition_for(requirement).year <= definition.year).is_true()
	assert_int(research_count).is_equal(40)
	assert_int(national_count).is_equal(15)
	assert_int(cells.size()).is_equal(20)
	for tab: int in range(4):
		for year: int in ERAS:
			assert_int(cells.get("%d:%d" % [tab, year], 0)).is_equal(2)
	for year: int in ERAS:
		assert_int(national_counts.get(year, 0)).is_equal(3)
	assert_int(system.definition_for("gas_cutoff").year).is_equal(1990)


func test_catalog_cost_and_duration_tiers_match_each_era() -> void:
	var system := _fixture()
	for definition: MeasureDefinition in system.definitions.values():
		if definition.id.begins_with("decision_") or definition.is_local():
			continue
		var era := ERAS.find(definition.year)
		assert_bool(era >= 0).is_true()
		if definition.kind == "awareness":
			assert_int(definition.cost_budget).is_equal(0)
			assert_int(definition.cost_awareness).is_equal([15, 20, 25, 30, 35][era])
			assert_int(definition.months).is_equal([3, 3, 4, 4, 6][era])
		elif definition.kind == "research":
			assert_int(definition.cost_budget).is_equal(
				[12000000, 16000000, 20000000, 24000000, 30000000][era]
			)
			assert_int(definition.cost_awareness).is_equal(0)
			assert_int(definition.months).is_equal([12, 12, 15, 18, 18][era])
		else:
			assert_int(definition.cost_budget).is_equal(
				[24000000, 36000000, 48000000, 60000000, 72000000][era]
			)
			assert_int(definition.months).is_equal([12, 12, 15, 18, 18][era])
			assert_int(definition.upkeep).is_equal([60000, 80000, 100000, 120000, 150000][era])


func test_requirements_expose_date_and_every_prerequisite_as_an_and_condition() -> void:
	var system := _fixture()
	var status := system.requirement_status("research_capacity", 0, 1989)
	assert_int(status.year).is_equal(1990)
	assert_bool(status.year_locked).is_true()
	assert_bool(status.ready).is_false()
	assert_int(status.prerequisites.size()).is_equal(2)
	system.global_completed.append("research_coordination")
	status = system.requirement_status("research_capacity", 0, 1990)
	assert_bool(status.year_locked).is_false()
	assert_bool(status.prerequisites[0].completed).is_true()
	assert_bool(status.prerequisites[1].completed).is_false()
	assert_bool(system.start("research_capacity", 0, 1990).ok).is_false()
	system.global_completed.append("research_depots")
	assert_bool(system.requirement_status("research_capacity", 0, 1989).ready).is_false()
	assert_bool(system.start("research_capacity", 0, 1989).ok).is_false()
	assert_bool(system.requirement_status("research_capacity", 0, 1990).ready).is_true()
	assert_bool(system.start("research_capacity", 0, 1990).ok).is_true()
	assert_bool(system.requirement_status("missing", 0, 2026).ready).is_false()
	assert_int(system.requirement_status("missing", 0, 2026).year).is_equal(0)
	assert_bool(system.requirement_status("gas_cutoff", 999, 2026).ready).is_false()


func test_unlocks_are_direct_derived_and_stably_sorted_including_cross_category() -> void:
	var system := _fixture()
	var ids: Array[String] = []
	for definition: MeasureDefinition in system.unlocks_for("research_structural"):
		ids.append(definition.id)
	assert_array(ids).is_equal(["national_equipment", "research_ground", "research_automation"])
	ids.clear()
	for definition: MeasureDefinition in system.unlocks_for("research_ground"):
		ids.append(definition.id)
	assert_array(ids).is_equal(["national_mountain", "research_terrain", "research_isolation"])
	system.definition_for("decision_gediz_relocation_full").prerequisites.append("research_ground")
	assert_int(system.unlocks_for("research_ground").size()).is_equal(3)
	assert_int(system.unlocks_for("missing").size()).is_equal(0)


func test_later_start_is_order_independent_skips_awareness_and_does_not_reward() -> void:
	var normal := _fixture(1990)
	var reversed := _fixture(1990)
	var definitions: Dictionary = {}
	var keys: Array = reversed.definitions.keys()
	keys.reverse()
	for id: String in keys:
		definitions[id] = reversed.definitions[id]
	reversed.definitions = definitions
	normal.trust.value = 50.0
	reversed.trust.value = 50.0
	normal.initialize_era(1990)
	reversed.initialize_era(1990)
	normal.global_completed.sort()
	reversed.global_completed.sort()
	assert_array(normal.global_completed).is_equal(reversed.global_completed)
	assert_int(normal.global_completed.size()).is_equal(12)
	assert_bool(normal.is_completed("research_equipment")).is_true()
	assert_bool(normal.is_completed("research_capacity")).is_false()
	assert_bool(normal.is_completed("community_preparedness")).is_false()
	assert_float(normal.trust.value).is_equal(50.0)
	assert_float(reversed.trust.value).is_equal(50.0)
	assert_int(normal.trust.history.size()).is_equal(0)


func test_research_and_national_completion_has_no_direct_trust_reward_and_applies_once() -> void:
	var system := _fixture()
	system.treasury.money = 3000000000
	system.treasury.awareness_points = 10000
	system.trust.value = 50.0
	var remaining: Array[String] = []
	var total_cost := 0
	for definition: MeasureDefinition in system.definitions.values():
		if definition.id.begins_with("decision_") or definition.is_local():
			continue
		remaining.append(definition.id)
		total_cost += definition.cost_budget
		definition.months = 1
	while not remaining.is_empty():
		var before := remaining.size()
		for id: String in remaining.duplicate():
			if system.start(id, 0, 2026).ok:
				remaining.erase(id)
		system.tick_month(2026)
		assert_bool(before > remaining.size()).is_true()
		if before == remaining.size():
			return
	assert_int(system.global_completed.size()).is_equal(55)
	assert_float(system.trust.value).is_equal(50.0)
	assert_int(system.trust.history.size()).is_equal(0)
	assert_int(3000000000 - system.treasury.money).is_equal(total_cost)
	assert_int(system.research_capacity).is_equal(3)
	var trust_before := system.trust.value
	var funds_before := system.treasury.money
	for id: String in system.global_completed:
		assert_bool(system.start(id, 0, 2026).ok).is_false()
	assert_int(system.tick_month(2026).size()).is_equal(0)
	assert_float(system.trust.value).is_equal(trust_before)
	assert_int(system.treasury.money).is_equal(funds_before)


func test_2020_content_finishes_by_2026_with_earlier_prerequisites_and_enough_resources() -> void:
	var system := _fixture(1990)
	system.treasury.money = 3000000000
	system.treasury.awareness_points = 10000
	var remaining: Array[String] = []
	for definition: MeasureDefinition in system.definitions.values():
		if definition.id.begins_with("decision_") or definition.is_local():
			continue
		if definition.year < 2020:
			system.global_completed.append(definition.id)
		else:
			remaining.append(definition.id)
	system.initialize_era(2020)
	for month: int in range(84):
		var year := 2020 + int(month / 12)
		for id: String in remaining.duplicate():
			if system.start(id, 0, year).ok:
				remaining.erase(id)
		assert_bool(system.active_count("research") <= 3).is_true()
		assert_bool(system.active_count("national") <= 1).is_true()
		system.tick_month(year)
		if (
			remaining.is_empty()
			and system.active_count("research") + system.active_count("national") == 0
		):
			break
	assert_int(remaining.size()).is_equal(0)
	assert_int(system.active_count("research") + system.active_count("national")).is_equal(0)
	for definition: MeasureDefinition in system.definitions.values():
		if definition.year == 2020 and not definition.id.begins_with("decision_"):
			assert_bool(system.is_completed(definition.id)).is_true()


func test_catalog_rejects_missing_cyclic_future_and_non_era_requirements() -> void:
	var source: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://management/data/measures.json")
	)
	var catalog := FixtureCatalog.new()
	catalog.payload = source.duplicate(true)
	catalog.payload.measures[0].prerequisites = ["missing"]
	assert_int(catalog.load_definitions().size()).is_equal(0)
	assert_bool(catalog.validation_errors[0].contains("Bilinmeyen")).is_true()
	catalog.payload = source.duplicate(true)
	catalog.payload.measures[0].prerequisites = ["strengthening"]
	catalog.payload.measures[1].prerequisites = ["river_zoning"]
	assert_int(catalog.load_definitions().size()).is_equal(0)
	assert_bool(catalog.validation_errors[0].contains("döngü")).is_true()
	catalog.payload = source.duplicate(true)
	catalog.payload.measures[0].prerequisites = ["research_sensor"]
	assert_int(catalog.load_definitions().size()).is_equal(0)
	assert_bool(catalog.validation_errors[0].contains("sonraki")).is_true()
	catalog.payload = source.duplicate(true)
	for entry: Dictionary in catalog.payload.measures:
		if entry.id == "research_ground":
			entry.year = 1960
	assert_int(catalog.load_definitions().size()).is_equal(0)
	assert_bool(catalog.validation_errors[0].contains("dönemi")).is_true()


func test_1950_and_1990_monthly_economies_can_fund_the_catalog_before_campaign_end() -> void:
	for start_year: int in [1950, 1990]:
		var system := _fixture(start_year)
		system.initialize_era(start_year)
		system.treasury.awareness_points = 10000
		var remaining: Array[String] = []
		for definition: MeasureDefinition in system.definitions.values():
			if definition.id.begins_with("decision_") or definition.is_local():
				continue
			if not system.is_completed(definition.id):
				remaining.append(definition.id)
		for month: int in range((2027 - start_year) * 12):
			var year := start_year + int(month / 12)
			for id: String in remaining.duplicate():
				if system.start(id, 0, year).ok:
					remaining.erase(id)
			var settlement := system.treasury.collect_and_maintain(system.areas, system)
			system.tick_month(year, bool(settlement.can_pay_budget))
			assert_bool(system.treasury.money >= 0).is_true()
			if (
				remaining.is_empty()
				and system.active_count("research") + system.active_count("national") == 0
			):
				break
		assert_int(remaining.size()).is_equal(0)
		assert_int(system.active_count("research") + system.active_count("national")).is_equal(0)
		assert_int(system.global_completed.size()).is_equal(55)
