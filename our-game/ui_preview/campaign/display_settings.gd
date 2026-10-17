extends RefCounted
## Window preferences are separate from campaign saves.
const MODES := {
	"fullscreen": DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN,
	"borderless": DisplayServer.WINDOW_MODE_FULLSCREEN,
	"windowed": DisplayServer.WINDOW_MODE_WINDOWED,
}
var mode: String = "fullscreen"
var _fullscreen_mode: String = "fullscreen"


func load_preferences(path: String = "user://preferences.cfg") -> void:
	var preferences := ConfigFile.new()
	mode = "fullscreen"
	_fullscreen_mode = "fullscreen"
	if preferences.load(path) == OK:
		var saved: Variant = preferences.get_value("display", "mode", "fullscreen")
		if saved is String and MODES.has(saved):
			mode = saved
		var fullscreen: Variant = preferences.get_value("display", "fullscreen_mode", "fullscreen")
		if fullscreen is String and fullscreen in ["fullscreen", "borderless"]:
			_fullscreen_mode = fullscreen
	if mode != "windowed":
		_fullscreen_mode = mode


func save_preferences(path: String = "user://preferences.cfg") -> bool:
	var preferences := ConfigFile.new()
	var error := preferences.load(path)
	if error != OK and error != ERR_FILE_NOT_FOUND:
		return false
	preferences.set_value("display", "mode", mode)
	preferences.set_value("display", "fullscreen_mode", _fullscreen_mode)
	return preferences.save(path) == OK


func current_mode() -> String:
	if DisplayServer.get_name() != "headless":
		var actual := DisplayServer.window_get_mode()
		for id: String in MODES:
			if MODES[id] == actual:
				return id
	return mode


func select_mode(id: String) -> bool:
	if not MODES.has(id):
		return false
	mode = id
	if id != "windowed":
		_fullscreen_mode = id
	apply()
	return true


func toggle_fullscreen() -> void:
	var current := current_mode()
	if current != "windowed":
		_fullscreen_mode = current
	select_mode(_fullscreen_mode if current == "windowed" else "windowed")


func apply() -> void:
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_mode(MODES[mode])
	if mode == "windowed":
		# Godot keeps the borderless flag when leaving either fullscreen mode.
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
