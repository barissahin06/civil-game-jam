extends Node
## Playback and preferences live outside campaign saves and simulation time.

signal settings_changed
signal preference_save_failed

const MUSIC := preload("res://assets/sounds/main_game_loop.wav")
const EFFECTS := {
	"ui_click": preload("res://assets/sounds/ui_click.wav"),
	"action_confirm": preload("res://assets/sounds/action_confirm.wav"),
	"error_denied": preload("res://assets/sounds/error_denied.wav"),
	"crisis_alert": preload("res://assets/sounds/crisis_alert.wav"),
	"reward_complete": preload("res://assets/sounds/reward_complete.wav"),
}
var preferences_path: String = "user://preferences.cfg"
var music_enabled: bool = true
var music_paused: bool = false
var music_volume: float = 0.4
var effects_volume: float = 0.7
var _music := AudioStreamPlayer.new()
var _effects: Dictionary[String, AudioStreamPlayer] = {}
var _save_timer := Timer.new()
var _music_started: bool = false


func _init() -> void:
	add_child(_music)
	add_child(_save_timer)


func _ready() -> void:
	add_to_group("game_audio")
	if not preferences_path.is_empty():
		load_preferences(preferences_path)
	_music.stream = MUSIC
	for id: String in EFFECTS:
		var player := AudioStreamPlayer.new()
		player.stream = EFFECTS[id]
		add_child(player)
		_effects[id] = player
	_save_timer.one_shot = true
	_save_timer.wait_time = 0.3
	_save_timer.timeout.connect(_save_pending_preferences)
	_apply_levels()


func _exit_tree() -> void:
	if not _save_timer.is_stopped():
		_save_pending_preferences()


func start_music() -> void:
	_music_started = true
	_apply_music()


func shutdown() -> void:
	if not _save_timer.is_stopped():
		_save_timer.stop()
		_save_pending_preferences()
	_music.stop()
	for player: AudioStreamPlayer in _effects.values():
		player.stop()
	# AudioServer releases fade-out playback references on its audio thread (Godot #76745).
	await get_tree().create_timer(0.1).timeout


func toggle_music_enabled() -> void:
	music_enabled = not music_enabled
	music_paused = false
	_apply_music()
	_settings_updated()


func toggle_music_paused() -> void:
	if not music_enabled:
		return
	music_paused = not music_paused
	_apply_music()
	_settings_updated()


func set_music_volume(value: float) -> void:
	if not is_finite(value):
		return
	music_volume = clampf(value, 0.0, 1.0)
	_apply_levels()
	_settings_updated()


func set_effects_volume(value: float) -> void:
	if not is_finite(value):
		return
	effects_volume = clampf(value, 0.0, 1.0)
	_apply_levels()
	_settings_updated()


func play_effect(id: String) -> void:
	if effects_volume <= 0.0 or not _effects.has(id):
		return
	if id != "ui_click":
		_effects["ui_click"].stop()
	_effects[id].play()


func _apply_music() -> void:
	if not _music_started:
		return
	if not music_enabled:
		_music.stop()
		return
	if not _music.has_stream_playback():
		_music.play()
	_music.stream_paused = music_paused


func _apply_levels() -> void:
	_music.volume_linear = music_volume
	for player: AudioStreamPlayer in _effects.values():
		player.volume_linear = effects_volume
		if effects_volume <= 0.0:
			player.stop()


func _settings_updated() -> void:
	settings_changed.emit()
	if not preferences_path.is_empty():
		_save_timer.start()


func load_preferences(path: String) -> void:
	var preferences := ConfigFile.new()
	if preferences.load(path) != OK:
		return
	var enabled: Variant = preferences.get_value("audio", "music_enabled", true)
	if enabled is bool:
		music_enabled = enabled
	for key: String in ["music_volume", "effects_volume"]:
		var value: Variant = preferences.get_value("audio", key, get(key))
		if (value is float or value is int) and is_finite(float(value)):
			set(key, clampf(float(value), 0.0, 1.0))


func save_preferences(path: String) -> bool:
	var preferences := ConfigFile.new()
	var error := preferences.load(path)
	if error != OK and error != ERR_FILE_NOT_FOUND:
		return false
	preferences.set_value("audio", "music_enabled", music_enabled)
	preferences.set_value("audio", "music_volume", music_volume)
	preferences.set_value("audio", "effects_volume", effects_volume)
	return preferences.save(path) == OK


func _save_pending_preferences() -> void:
	if not save_preferences(preferences_path):
		preference_save_failed.emit()
