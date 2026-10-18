extends GdUnitTestSuite

const AUDIO := preload("res://core/audio/game_audio.gd")
const TEST_PATH := "user://test-audio-settings-isolated.cfg"


func after_test() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))


func test_audio_roundtrip_preserves_other_preferences() -> void:
	var config := ConfigFile.new()
	config.set_value("display", "mode", "windowed")
	config.set_value("visual", "map_shake", false)
	assert_int(config.save(TEST_PATH)).is_equal(OK)
	var audio := AUDIO.new()
	audio.music_enabled = false
	audio.music_volume = 0.25
	audio.effects_volume = 0.0
	assert_bool(audio.save_preferences(TEST_PATH)).is_true()
	var restored := AUDIO.new()
	restored.load_preferences(TEST_PATH)
	assert_bool(restored.music_enabled).is_false()
	assert_float(restored.music_volume).is_equal(0.25)
	assert_float(restored.effects_volume).is_equal(0.0)
	assert_bool(restored.music_paused).is_false()
	assert_int(config.load(TEST_PATH)).is_equal(OK)
	assert_str(config.get_value("display", "mode")).is_equal("windowed")
	assert_bool(config.get_value("visual", "map_shake")).is_false()
	audio.free()
	restored.free()


func test_invalid_preferences_are_validated_and_clamped() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "music_enabled", "false")
	config.set_value("audio", "music_volume", -3.0)
	config.set_value("audio", "effects_volume", 8)
	assert_int(config.save(TEST_PATH)).is_equal(OK)
	var audio := AUDIO.new()
	audio.load_preferences(TEST_PATH)
	assert_bool(audio.music_enabled).is_true()
	assert_float(audio.music_volume).is_equal(0.0)
	assert_float(audio.effects_volume).is_equal(1.0)
	config.set_value("audio", "music_volume", "loud")
	config.set_value("audio", "effects_volume", NAN)
	assert_int(config.save(TEST_PATH)).is_equal(OK)
	var defaults := AUDIO.new()
	defaults.load_preferences(TEST_PATH)
	assert_float(defaults.music_volume).is_equal(0.4)
	assert_float(defaults.effects_volume).is_equal(0.7)
	audio.free()
	defaults.free()


func test_debounced_preferences_and_pending_exit_change_are_saved() -> void:
	var audio := AUDIO.new()
	audio.preferences_path = TEST_PATH
	add_child(audio)
	audio.set_music_volume(0.21)
	await get_tree().create_timer(0.4).timeout
	var restored := AUDIO.new()
	restored.load_preferences(TEST_PATH)
	assert_float(restored.music_volume).is_equal(0.21)
	audio.set_effects_volume(0.17)
	assert_bool(audio._save_timer.is_stopped()).is_false()
	await audio.shutdown()
	restored.load_preferences(TEST_PATH)
	assert_float(restored.effects_volume).is_equal(0.17)
	audio.free()
	restored.free()
