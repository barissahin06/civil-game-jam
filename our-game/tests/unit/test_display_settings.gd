extends GdUnitTestSuite
const SETTINGS := preload("res://ui_preview/campaign/display_settings.gd")
const TEST_PATH := "user://test-display-settings-isolated.cfg"


func after_test() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))


func test_default_and_invalid_preferences_use_fullscreen() -> void:
	var settings := SETTINGS.new()
	assert_str(settings.mode).is_equal("fullscreen")
	settings.load_preferences(TEST_PATH)
	assert_str(settings.mode).is_equal("fullscreen")
	var config := ConfigFile.new()
	config.set_value("display", "mode", 4)
	assert_int(config.save(TEST_PATH)).is_equal(OK)
	settings.load_preferences(TEST_PATH)
	assert_str(settings.mode).is_equal("fullscreen")
	config.set_value("display", "mode", "invalid")
	assert_int(config.save(TEST_PATH)).is_equal(OK)
	settings.load_preferences(TEST_PATH)
	assert_str(settings.mode).is_equal("fullscreen")
	assert_bool(settings.select_mode("invalid")).is_false()
	assert_str(settings.mode).is_equal("fullscreen")


func test_mode_roundtrip_preserves_other_preferences() -> void:
	var config := ConfigFile.new()
	config.set_value("visual", "map_shake", false)
	assert_int(config.save(TEST_PATH)).is_equal(OK)
	var settings := SETTINGS.new()
	for id: String in SETTINGS.MODES:
		assert_bool(settings.select_mode(id)).is_true()
		assert_bool(settings.save_preferences(TEST_PATH)).is_true()
		var restored := SETTINGS.new()
		restored.load_preferences(TEST_PATH)
		assert_str(restored.mode).is_equal(id)
		assert_int(config.load(TEST_PATH)).is_equal(OK)
		assert_bool(config.get_value("visual", "map_shake")).is_false()


func test_f11_returns_to_chosen_fullscreen_variant() -> void:
	var settings := SETTINGS.new()
	for id: String in ["fullscreen", "borderless"]:
		settings.select_mode(id)
		settings.toggle_fullscreen()
		assert_str(settings.mode).is_equal("windowed")
		assert_bool(settings.save_preferences(TEST_PATH)).is_true()
		var restored := SETTINGS.new()
		restored.load_preferences(TEST_PATH)
		restored.toggle_fullscreen()
		assert_str(restored.mode).is_equal(id)
		settings.toggle_fullscreen()
		assert_str(settings.mode).is_equal(id)
