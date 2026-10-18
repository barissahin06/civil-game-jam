extends "res://tests/integration/gameplay_ui.gd"
## Real input, isolated preferences, and actual players; --capture uses the real renderer.


class RecordingAudio:
	extends "res://core/audio/game_audio.gd"
	var played: Array[String] = []

	func play_effect(id: String) -> void:
		played.append(id)
		super.play_effect(id)


func _run() -> void:
	create_timer(30.0).timeout.connect(
		func() -> void:
			push_error("AUDIO_UI_TIMEOUT")
			quit(1)
	)
	root.size = Vector2i(1920, 1080)
	root.content_scale_size = root.size
	_main = load("res://ui_preview/scenes/main_preview.tscn").instantiate()
	_shell = _main
	var audio := RecordingAudio.new()
	_shell.audio = audio
	root.add_child(_main)
	await process_frame
	_shell.saves.slot_directory = TEST_SAVE_DIR
	_shell.return_to_main_menu()
	assert(audio.preferences_path.is_empty(), "Test must not use player preferences")
	assert(audio._music.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD)
	assert(is_equal_approx(audio._music.stream.get_length(), 58.0))
	assert(audio._music.has_stream_playback())
	await _press_button("AYARLAR")
	assert("ui_click" in audio.played)
	audio._music.seek(10.0)
	await create_timer(0.1).timeout
	await _press_button("MÜZİĞİ DURAKLAT")
	assert(audio.music_paused and audio._music.stream_paused)
	assert(audio._music.has_stream_playback(), "Pause must retain playback")
	var paused_at := audio._music.get_playback_position()
	assert(paused_at >= 10.0)
	await create_timer(0.1).timeout
	# The audio thread may finish its current mix buffer after the pause request.
	assert(absf(audio._music.get_playback_position() - paused_at) < 0.1)
	await _capture("audio-settings-paused")
	await _press_button("MÜZİĞİ SÜRDÜR")
	assert(not audio.music_paused and not audio._music.stream_paused)
	assert(audio._music.get_playback_position() >= paused_at, "Resume must not restart the song")
	audio._music.seek(57.95)
	await create_timer(0.2).timeout
	assert(audio._music.has_stream_playback() and audio._music.get_playback_position() < 1.0)
	await _press_button("MÜZİK: AÇIK")
	assert(not audio.music_enabled and not audio._music.has_stream_playback())
	assert(_find_button(_main, "MÜZİĞİ DURAKLAT").disabled)
	await _capture("audio-settings-off")
	await _press_button("MÜZİK: KAPALI")
	assert(audio.music_enabled and audio._music.has_stream_playback())
	var sliders := _sliders(_shell._modal)
	assert(sliders.size() == 2)
	var music: HSlider = sliders[0]
	var effects: HSlider = sliders[1]
	await _click(music.get_global_rect().get_center())
	assert(audio.music_volume > 0.45 and audio.music_volume < 0.55)
	var before := music.value
	music.grab_focus()
	await _key(KEY_RIGHT)
	assert(music.value == before + 1.0 and is_equal_approx(audio.music_volume, music.value / 100.0))
	assert(is_equal_approx(audio._music.volume_linear, audio.music_volume))
	await _click(effects.get_global_rect().position + Vector2(1, 18))
	assert(is_zero_approx(audio.effects_volume))
	for player: AudioStreamPlayer in audio._effects.values():
		assert(not player.has_stream_playback() and is_zero_approx(player.volume_linear))
	await _click(effects.get_global_rect().get_center())
	assert(audio.effects_volume > 0.45 and audio.effects_volume < 0.55)
	await _capture("audio-settings-menu")
	var music_id := music.get_instance_id()
	audio.set_music_volume(NAN)
	assert(music.get_instance_id() == music_id)
	await _press_button("GERİ")
	_shell.start_campaign(1950)
	_shell.sim.tutorial_enabled = false
	assert(audio._music.has_stream_playback(), "Campaign transition must retain music")
	await _key(KEY_ESCAPE)
	await _press_button("AYARLAR")
	await _capture("audio-settings-game")
	await _key(KEY_ESCAPE)
	await _key(KEY_ESCAPE)
	audio.played.clear()
	_shell.command_result(_shell.sim.start_project("missing-project", 6))
	assert(audio.played == ["error_denied"])
	assert(audio._effects["error_denied"].has_stream_playback())
	_shell.command_result(_shell.sim.start_project("rescue_team", 6))
	assert(audio.played.back() == "action_confirm")
	assert(audio._effects["action_confirm"].has_stream_playback())
	var completed := _shell.sim.projects.get_project(1)
	assert(completed != null)
	completed.progress_months = _shell.sim.projects.definition_for("rescue_team").months - 1
	_shell.sim.advance_to(CalendarClock.date_to_day("1950-02-01"))
	assert(audio.played.back() == "reward_complete")
	assert(audio._effects["reward_complete"].has_stream_playback())
	audio.played.clear()
	_shell.sim.bubbles.append(6)
	_shell.sim.collect_bubble(6)
	assert(audio.played == ["reward_complete"])
	_shell.sim.advance_to(CalendarClock.date_to_day("1951-04-08"))
	await process_frame
	await process_frame
	assert(audio.played.count("crisis_alert") == 1)
	assert(audio._effects["crisis_alert"].has_stream_playback())
	_shell.sim.changed.emit()
	await process_frame
	assert(audio.played.count("crisis_alert") == 1, "Refresh must not replay alerts")
	_shell.sim = Simulation.new()
	assert(_shell.sim.setup())
	_shell.sim.advance_to(CalendarClock.date_to_day("1951-04-08"))
	_shell._bind_simulation(true)
	_shell._play_new_crisis_feedback()
	assert(audio.played.count("crisis_alert") == 1, "Load must not replay past alerts")
	await audio.shutdown()
	assert(not audio._music.has_stream_playback())
	_main.queue_free()
	await process_frame
	print(
		"AUDIO_UI_PASS: music loop/pause/mute, slider mouse/keyboard, effects, completion and alert deduplication"
	)
	quit()


func _sliders(parent: Node) -> Array[HSlider]:
	var result: Array[HSlider] = []
	if parent is HSlider:
		result.append(parent)
	for child in parent.get_children():
		result.append_array(_sliders(child))
	return result


func _key(code: Key) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
	await process_frame
	await process_frame
