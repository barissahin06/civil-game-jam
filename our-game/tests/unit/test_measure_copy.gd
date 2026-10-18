extends GdUnitTestSuite

const Copy := preload("res://ui_preview/management/measure_copy.gd")


func test_every_catalog_measure_has_a_short_explanation_and_no_orphan_copy() -> void:
	var definitions := Catalog.new().load_definitions()
	for id: String in definitions:
		var explanation := Copy.explanation_for(id)
		assert_bool(explanation.length() >= 20 and explanation.length() <= 90).is_true()
		assert_bool(explanation == definitions[id].title).is_false()
	for id: String in Copy.EXPLANATIONS:
		assert_bool(definitions.has(id)).is_true()
	assert_str(Copy.explanation_for("unknown_measure")).is_empty()


func test_project_states_name_the_actual_waiting_reason() -> void:
	assert_str(Copy.status_for("active")).is_equal("DEVAM EDİYOR")
	assert_str(Copy.status_for("waiting")).is_equal("BÜTÇE BEKLİYOR")
	assert_str(Copy.status_for("paused")).is_equal("DURAKLATILDI")
	assert_str(Copy.status_for("queued")).is_equal("SIRADA / HENÜZ ÖDEME YOK")


func test_research_and_national_copy_explains_the_method_and_actual_benefit() -> void:
	var definitions := Catalog.new().load_definitions()
	var detailed_count := 0
	for definition: MeasureDefinition in definitions.values():
		if definition.id.begins_with("decision_"):
			continue
		if not definition.is_research() and definition.kind != "national":
			continue
		detailed_count += 1
		var description := Copy.description_for(definition.id)
		assert_bool(description.length() > Copy.explanation_for(definition.id).length()).is_true()
		assert_bool(description.count(".") >= 2).is_true()
		(
			assert_bool(
				(
					description.to_lower().contains("ülke genelinde")
					or definition.id == "research_capacity"
				)
			)
			. is_true()
		)
	assert_int(detailed_count).is_equal(55)
	for id: String in Copy.DESCRIPTIONS:
		assert_bool(definitions.has(id)).is_true()
	assert_str(Copy.description_for("river_zoning")).is_equal(Copy.explanation_for("river_zoning"))
	assert_str(Copy.description_for("unknown_measure")).is_empty()
