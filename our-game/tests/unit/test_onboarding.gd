extends GdUnitTestSuite


func _fixture() -> Simulation:
	var simulation := Simulation.new()
	assert_bool(simulation.setup()).is_true()
	return simulation


func test_national_construction_does_not_complete_research_step() -> void:
	var simulation := _fixture()
	assert_bool(simulation.start_project("national_radio").ok).is_true()
	assert_bool("research" in simulation.tutorial_completed).is_false()
	assert_bool("investment" in simulation.tutorial_completed).is_false()


func test_technical_research_uses_definition_scope_not_area_argument() -> void:
	var simulation := _fixture()
	assert_bool(simulation.start_project("research_structural", 34).ok).is_true()
	assert_bool("research" in simulation.tutorial_completed).is_true()
	assert_bool("investment" in simulation.tutorial_completed).is_false()


func test_awareness_research_completes_research_step_after_real_point_collection() -> void:
	var simulation := _fixture()
	simulation.advance_to(CalendarClock.date_to_day("1950-03-01"))
	assert_int(simulation.bubbles.size()).is_equal(1)
	simulation.collect_bubble(simulation.bubbles.front())
	assert_bool(simulation.start_project("community_preparedness").ok).is_true()
	assert_bool("research" in simulation.tutorial_completed).is_true()
	assert_bool("investment" in simulation.tutorial_completed).is_false()


func test_failed_commands_do_not_advance_guide_and_local_start_marks_investment() -> void:
	var simulation := _fixture()
	assert_bool(simulation.start_project("community_preparedness").ok).is_false()
	assert_bool(simulation.start_project("unknown_project").ok).is_false()
	assert_int(simulation.tutorial_completed.size()).is_equal(0)
	assert_bool(simulation.start_project("river_zoning", 31).ok).is_true()
	assert_bool("investment" in simulation.tutorial_completed).is_true()
	assert_bool("research" in simulation.tutorial_completed).is_false()
	assert_bool(simulation.start_project("strengthening", 31).ok).is_false()
	assert_int(simulation.tutorial_completed.size()).is_equal(1)
