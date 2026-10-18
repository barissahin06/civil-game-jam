extends SceneTree
## Trailer text overlay track: game bitmap font on black, to be screen-blended in the edit.
## Run (no --headless):
##   Godot --path our-game --write-movie <abs.avi> --fixed-fps 60 \
##     --script res://tests/integration/trailer_cards.gd -- --cards <abs.json>
## cards.json: {"duration": 58.0, "items": [{"t", "d", "text", "x", "y", "size", "color", "align"}]}

const UI := preload("res://ui_preview/shared/ui_kit.gd")
const FPS := 60.0
const FADE := 0.35

var _items: Array = []
var _labels: Array[Label] = []
var _duration: float = 0.0


func _initialize() -> void:
	set_meta("simulation_test", true)
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var path: String = args[args.find("--cards") + 1]
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	_duration = float(data.duration)
	_items = data.items
	root.size = Vector2i(1920, 1080)
	root.content_scale_size = root.size
	var back := ColorRect.new()
	back.color = Color.BLACK
	back.size = Vector2(1920, 1080)
	root.add_child(back)
	for item: Dictionary in _items:
		var label := Label.new()
		label.text = String(item.text)
		label.add_theme_font_override("font", UI.FONT)
		label.add_theme_font_size_override("font_size", int(item.size))
		label.add_theme_color_override("font_color", Color(String(item.color)))
		label.horizontal_alignment = (
			HORIZONTAL_ALIGNMENT_CENTER
			if item.get("align", "left") == "center"
			else HORIZONTAL_ALIGNMENT_LEFT
		)
		label.position = Vector2(float(item.x), float(item.y))
		if item.get("align", "left") == "center":
			label.size = Vector2(float(item.w), 200.0)
		label.modulate.a = 0.0
		root.add_child(label)
		_labels.append(label)
	for frame in range(roundi(_duration * FPS)):
		var t := frame / FPS
		for index in range(_items.size()):
			var item: Dictionary = _items[index]
			var start := float(item.t)
			var end := start + float(item.d)
			_labels[index].modulate.a = clampf(minf((t - start) / FADE, (end - t) / FADE), 0.0, 1.0)
		await process_frame
	print("TRAILER_CARDS_PASS: ", _items.size())
	quit()
