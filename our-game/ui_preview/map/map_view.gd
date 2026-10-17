extends Control

signal area_selected(area_id: int)

const UI := preload("res://ui_preview/shared/ui_kit.gd")
const MAPS: Array[Texture2D] = [
	preload("res://ui_preview/assets/map-general.png"),
	preload("res://ui_preview/assets/map-preparedness.png"),
	preload("res://ui_preview/assets/map-logistics.png"),
	preload("res://ui_preview/assets/map-damage.png"),
]
const HITMASK := preload("res://ui_preview/assets/map-hitmask.png")
const NATIVE_SIZE := Vector2i(3072, 1728)
const DEFAULT_ORIGIN := Vector2(-624, -300)
const FEEDBACK_SECONDS := 0.30
const SHAKE_OFFSETS: Array[Vector2] = [
	Vector2(-3, 2),
	Vector2(3, -2),
	Vector2(-2, -1),
	Vector2(2, 1),
	Vector2(-1, 0),
	Vector2(1, 0),
	Vector2.ZERO
]

var selected_overlay: int = 0
var _map_clip: Control
var _map_legend: Label
var _hint_panel: PanelContainer
var _hint_label: Label
var _map_image: TextureRect
var _selection: TextureRect
var _hit_image: Image
var _drag_start: Vector2
var _map_origin: Vector2
var _dragging: bool = false
var _zoom: int = 1
var _layer_buttons: Array[Button] = []
var _shell: Control
var _heatmap: TextureRect
var _markers: Control
var _palette: ImageTexture
var _crisis_flash: TextureRect
var _feedback_elapsed: float = FEEDBACK_SECONDS
var _shake_enabled: bool = true


func setup(shell: Control) -> void:
	_shell = shell


func select_area(id: int) -> void:
	_selection.texture = load("res://ui_preview/assets/selection-%02d.png" % id) if id > 0 else null
	if _selection.texture != null:
		assert(_selection.texture.get_size() == Vector2(NATIVE_SIZE))


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hit_image = HITMASK.get_image()
	assert(_hit_image.get_size() == NATIVE_SIZE)
	for texture in MAPS:
		assert(texture.get_size() == Vector2(NATIVE_SIZE))
	_map_clip = Control.new()
	_map_clip.size = Vector2(1920, 1080)
	_map_clip.clip_contents = true
	_map_clip.mouse_default_cursor_shape = Control.CURSOR_MOVE
	_map_clip.gui_input.connect(_on_map_input)
	_map_clip.set_drag_forwarding(Callable(), _can_map_drop, _map_drop)
	add_child(_map_clip)
	_map_image = TextureRect.new()
	_map_image.texture = MAPS[0]
	_map_image.size = Vector2(NATIVE_SIZE)
	_map_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_clip.add_child(_map_image)
	_heatmap = TextureRect.new()
	_heatmap.texture = HITMASK
	_heatmap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; uniform sampler2D palette: filter_nearest; void fragment(){ float id = floor(texture(TEXTURE, UV).r * 255.0 + 0.5); COLOR = texture(palette, vec2((id + 0.5) / 82.0, 0.5)); }"
	var material := ShaderMaterial.new()
	material.shader = shader
	_heatmap.material = material
	_map_image.add_child(_heatmap)
	_selection = TextureRect.new()
	_selection.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_image.add_child(_selection)
	var labels := TextureRect.new()
	labels.texture = preload("res://ui_preview/assets/map-labels.png")
	assert(labels.texture.get_size() == Vector2(NATIVE_SIZE))
	labels.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_image.add_child(labels)
	_markers = Control.new()
	_markers.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_image.add_child(_markers)
	_crisis_flash = TextureRect.new()
	_crisis_flash.texture = UI.atlas(UI.CONTROLS, Rect2(248, 136, 1, 1))
	_crisis_flash.size = Vector2(1920, 1080)
	_crisis_flash.modulate = Color(0.95, 0.12, 0.08, 0.0)
	_crisis_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_crisis_flash)
	reset_map()
	UI.panel(self, Rect2(1638, 930, 254, 34))
	_map_legend = UI.text(self, "BÖLGE RENKLERİ", Rect2(1650, 934, 230, 26), 18, UI.MUTED)
	_map_legend.mouse_filter = Control.MOUSE_FILTER_PASS
	_map_legend.tooltip_text = "Haritadaki renklerin şu an neyi gösterdiği. Alttaki düğmelerle değiştirilir."
	UI.panel(self, Rect2(440, 966, 246, 48))
	UI.panel(self, Rect2(1068, 966, 824, 48))
	UI.button(self, "SIFIRLA", Rect2(452, 974, 124, 32), reset_map).tooltip_text = ("Haritayı ilk görünümüne döndürür.")
	UI.button(self, "+", Rect2(584, 974, 42, 32), _zoom_map.bind(1, Vector2(960, 540))).tooltip_text = ("Yakınlaştır")
	UI.button(self, "-", Rect2(634, 974, 42, 32), _zoom_map.bind(-1, Vector2(960, 540))).tooltip_text = ("Uzaklaştır")
	for index in range(4):
		var title: String = ["GENEL", "HAZIRLIK", "LOJİSTİK", "HASAR/ONARIM"][index]
		_layer_buttons.append(
			UI.button(
				self,
				title,
				Rect2(1080 + index * 200, 974, 190, 32),
				select_overlay.bind(index),
				index == 0
			)
		)
		_layer_buttons[index].tooltip_text = [
			"Bölgeleri yönetim alanlarına göre renklendirir. Kırmızı bölgede afet sürüyor.",
			"Afete hazırlık düzeyi: turkuaz hazırlıklı, kırmızı zayıf. Tamamlanan tedbirler hazırlığı artırır.",
			"Yardım stoğu: turkuaz dolu, kırmızı az. Stok, krizde sevk edilen yardımdır.",
			"Hasar düzeyi: turkuaz sağlam, kırmızı hasarlı. Hasarlı bölgede gelir düşer, onarım gerekir.",
		][index]
	UI.wrap_tooltips(self)
	_build_hints_above()
	refresh()


func _build_hints_above() -> void:
	# Bottom controls sit at the screen edge, where the native tooltip opens over them.
	_hint_panel = PanelContainer.new()
	_hint_panel.add_theme_stylebox_override("panel", UI.style(Rect2(0, 0, 48, 48)))
	_hint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint_panel.z_index = 10
	_hint_panel.hide()
	_hint_label = Label.new()
	_hint_label.add_theme_font_override("font", UI.FONT)
	_hint_label.add_theme_font_size_override("font_size", 18)
	_hint_label.add_theme_color_override("font_color", UI.INK)
	_hint_panel.add_child(_hint_label)
	for child: Node in get_children():
		var control := child as Control
		if control != null and not control.tooltip_text.is_empty():
			control.set_meta("hint", control.tooltip_text)
			control.tooltip_text = ""
			control.mouse_entered.connect(_show_hint_above.bind(control))
			control.mouse_exited.connect(_hint_panel.hide)
	add_child(_hint_panel)


func _show_hint_above(control: Control) -> void:
	_hint_label.text = control.get_meta("hint")
	_hint_panel.show()
	_hint_panel.reset_size()
	var width := get_viewport_rect().size.x
	_hint_panel.position = Vector2(
		clampf(control.position.x, 8.0, width - _hint_panel.size.x - 8.0),
		control.position.y - _hint_panel.size.y - 8.0
	)


func play_crisis_feedback() -> void:
	_feedback_elapsed = 0.0
	_update_crisis_feedback()


func set_shake_enabled(enabled: bool) -> void:
	_shake_enabled = enabled
	if is_instance_valid(_map_clip) and not enabled:
		_map_clip.position = Vector2.ZERO


func _process(delta: float) -> void:
	if _feedback_elapsed < FEEDBACK_SECONDS:
		_feedback_elapsed = minf(FEEDBACK_SECONDS, _feedback_elapsed + maxf(0.0, delta))
		_update_crisis_feedback()


func _update_crisis_feedback() -> void:
	if not is_instance_valid(_crisis_flash):
		return
	var intensity := 1.0 - _feedback_elapsed / FEEDBACK_SECONDS
	_crisis_flash.modulate.a = intensity * 0.18
	# Only the map viewport moves; persistent camera coordinates and fixed controls stay put.
	var index := mini(SHAKE_OFFSETS.size() - 1, int(_feedback_elapsed / 0.04))
	_map_clip.position = (
		SHAKE_OFFSETS[index] if _shake_enabled and intensity > 0.0 else Vector2.ZERO
	)


func select_overlay(index: int) -> void:
	selected_overlay = index
	_map_legend.text = ["BÖLGE RENKLERİ", "HAZIRLIK DÜZEYİ", "YARDIM STOĞU", "HASAR DÜZEYİ"][index]
	_map_image.texture = MAPS[0]
	for button_index in range(_layer_buttons.size()):
		_layer_buttons[button_index].add_theme_stylebox_override(
			"normal", UI.style(Rect2(112 if button_index == index else 0, 56, 48, 32))
		)
	refresh()


func refresh() -> void:
	if not is_instance_valid(_markers) or _shell == null:
		return
	UI.clear(_markers)
	var sim: Simulation = _shell.sim
	var palette := Image.create(82, 1, false, Image.FORMAT_RGBA8)
	palette.fill(Color.TRANSPARENT)
	for area: ServiceArea in sim.areas.values():
		var value := 0.0
		match selected_overlay:
			1:
				for kind: String in ["earthquake", "flood", "fire", "avalanche", "landslide"]:
					value += sim.projects.preparedness(area.id, kind) / 500.0
			2:
				value = clampf(area.stock / 160.0, 0.0, 1.0)
			3:
				value = 1.0 - area.damage / 100.0
		if selected_overlay > 0:
			var tint := Color("ac6158").lerp(UI.TEAL, value)
			tint.a = 0.68
			palette.set_pixel(area.id, 0, tint)
	for target: Dictionary in sim.crises.active:
		var area: ServiceArea = sim.areas[int(target.area_id)]
		palette.set_pixel(area.id, 0, Color(0.85, 0.22, 0.15, 0.7))
		var marker: Button = UI.button(
			_markers,
			"!",
			Rect2(_native_point(area) + Vector2(-14, -44), Vector2(28, 34)),
			_open_crisis.bind(target.id)
		)
		marker.tooltip_text = area.name + ": " + target.name
		marker.set_drag_forwarding(
			Callable(), _can_marker_drop.bind(target.id), _marker_drop.bind(target.id)
		)
	for id: int in sim.bubbles:
		var bubble: Button = UI.button(
			_markers,
			"+5",
			Rect2(_native_point(sim.areas[id]) + Vector2(18, -42), Vector2(54, 34)),
			sim.collect_bubble.bind(id)
		)
		bubble.tooltip_text = "Tıkla: +5 bilinç puanı. Sakin dönemlerde çıkar, en fazla 3 tane birikir."
	UI.wrap_tooltips(_markers)
	for shipment: Dictionary in sim.logistics.shipments:
		if shipment.state in ["outbound", "returning"]:
			var a: Vector2 = _native_point(sim.areas[int(shipment.source)])
			var b: Vector2 = _native_point(sim.areas[int(shipment.target)])
			if shipment.state == "returning":
				var swap := a
				a = b
				b = swap
			var line := Line2D.new()
			line.add_point(a)
			line.add_point(b)
			line.width = 2.0
			line.default_color = UI.GOLD
			_markers.add_child(line)
			var progress := (
				1.0
				- clampf(
					float(int(shipment.arrival) - sim.clock.day) / maxi(1, int(shipment.days)),
					0.0,
					1.0
				)
			)
			UI.icon(_markers, 3, a.lerp(b, progress), UI.GOLD)
	if _palette == null:
		_palette = ImageTexture.create_from_image(palette)
	else:
		_palette.update(palette)
	(_heatmap.material as ShaderMaterial).set_shader_parameter("palette", _palette)


func _native_point(area: ServiceArea) -> Vector2:
	return (
		Vector2((area.longitude - 12.0) * 0.777593016455506 * 93.0, (49.0 - area.latitude) * 93.0)
		. round()
	)


func _open_crisis(id: String) -> void:
	for index in range(_shell.sim.crises.active.size()):
		if _shell.sim.crises.active[index].id == id:
			_shell.crisis.crisis_index = index
	_shell.show_screen("crisis")


func _can_marker_drop(_point: Vector2, data: Variant, id: String) -> bool:
	return (
		data is Dictionary
		and data.get("tag") == "dispatch"
		and data.get("kind") in ["team", "stock"]
		and _shell.sim.areas.has(int(data.get("source", 0)))
		and not _shell.sim.crises.get_crisis(id).is_empty()
	)


func _marker_drop(point: Vector2, data: Variant, id: String) -> void:
	if _can_marker_drop(point, data, id):
		_shell.command_result(
			_shell.sim.dispatch(int(data.source), id, data.kind, int(data.get("amount", 1)))
		)


func _map_target(point: Vector2) -> String:
	var native := ((point - _map_image.position) / _zoom).floor()
	if not Rect2(Vector2.ZERO, Vector2(NATIVE_SIZE)).has_point(native):
		return ""
	var id := roundi(_hit_image.get_pixelv(Vector2i(native)).r * 255.0)
	for target: Dictionary in _shell.sim.crises.active:
		if int(target.area_id) == id:
			return target.id
	return ""


func _can_map_drop(point: Vector2, data: Variant) -> bool:
	return _can_marker_drop(point, data, _map_target(point))


func _map_drop(point: Vector2, data: Variant) -> void:
	_marker_drop(point, data, _map_target(point))


func reset_map() -> void:
	_zoom = 1
	_map_image.scale = Vector2.ONE
	_map_image.position = DEFAULT_ORIGIN
	_constrain_map()


func _zoom_map(direction: int, focus: Vector2) -> void:
	var next_zoom := clampi(_zoom + direction, 1, 3)
	if next_zoom == _zoom:
		return
	var source_point := (focus - _map_image.position) / float(_zoom)
	_zoom = next_zoom
	_map_image.scale = Vector2.ONE * _zoom
	_map_image.position = (focus - source_point * _zoom).round()
	_constrain_map()


func _constrain_map() -> void:
	var limit := (_map_clip.size - _map_image.size * _zoom).min(Vector2.ZERO)
	_map_image.position = _map_image.position.clamp(limit, Vector2.ZERO).round()


func _on_map_input(event: InputEvent) -> void:
	if not _shell.open_screen.is_empty():
		return  # An open screen owns the input; gaps between top buttons must not reach the map.
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom_map(1, event.position)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom_map(-1, event.position)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_drag_start = event.position
				_map_origin = _map_image.position
				_dragging = true
			else:
				if event.position.distance_to(_drag_start) < 5.0:
					var point: Vector2 = (
						((event.position - _map_image.position) / float(_zoom)).floor()
					)
					if Rect2(Vector2.ZERO, _hit_image.get_size()).has_point(point):
						var id := roundi(_hit_image.get_pixelv(Vector2i(point)).r * 255.0)
						if id > 0:
							area_selected.emit(id)
				_dragging = false
	elif event is InputEventMouseMotion and _dragging:
		_map_image.position = (_map_origin + event.position - _drag_start).round()
		_constrain_map()
