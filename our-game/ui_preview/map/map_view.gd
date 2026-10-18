extends Control

signal area_selected(area_id: int)
signal tools_toggled(expanded: bool)
signal crisis_shake_changed(offset: Vector2)

const UI := preload("res://ui_preview/shared/ui_kit.gd")
const MAPS: Array[Texture2D] = [
	preload("res://ui_preview/assets/map-general.png"),
	preload("res://ui_preview/assets/map-preparedness.png"),
	preload("res://ui_preview/assets/map-logistics.png"),
	preload("res://ui_preview/assets/map-damage.png"),
]
const HITMASK := preload("res://ui_preview/assets/map-hitmask.png")
const TERRAIN := preload("res://ui_preview/assets/map-terrain.png")
const NATIVE_SIZE := Vector2i(3072, 1728)
const DEFAULT_ORIGIN := Vector2(-624, -300)
const FEEDBACK_SECONDS := 0.30
const CRISIS_COLOR := Color("b55655")
const DATA_LOW := Color("385c78")
const DATA_MIDDLE := Color("7eaea0")
const DATA_HIGH := Color("d3b782")
# Interior colors of the seven regions in the native map-general export.
const REGION_COLORS := {
	"Marmara": Color("648b9e"),
	"Ege": Color("6d9a89"),
	"Akdeniz": Color("a47f6e"),
	"İç Anadolu": Color("a59b7c"),
	"Karadeniz": Color("67968e"),
	"Doğu Anadolu": Color("8b86a3"),
	"Güneydoğu Anadolu": Color("aa9569"),
}
# Dense neighboring labels need separate badge positions at the native camera scale.
const PREPARATION_OFFSETS := {31: Vector2(-20, -44), 35: Vector2(60, -26)}
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
var tools_expanded: bool = false
var _toolbar: Panel
var _tools_drawer: Control
var _legend_panel: Panel
var _tools_toggle: Button
var _map_clip: Control
var _map_legend: Label
var _legend_description: Label
var _legend_values: Array[Label] = []
var _legend_swatches: Array[ColorRect] = []
var _region_labels: Array[Label] = []
var _region_swatches: Array[ColorRect] = []
var _legend_readout: Label
var _region_note: Label
var _crisis_key: Label
var _crisis_swatch: ColorRect
var _overlay_data: Dictionary = {}
var _hovered_area: int = 0
var _map_image: TextureRect
var _terrain: TextureRect
var _selection: TextureRect
var _hit_image: Image
var _drag_start: Vector2
var _map_origin: Vector2
var _dragging: bool = false
var _zoom: int = 1
var _zoom_in: Button
var _zoom_out: Button
var _zoom_label: Label
var _layer_buttons: Array[Button] = []
var _shell: Control
var _heatmap: TextureRect
var _markers: Control
var _palette: ImageTexture
var _crisis_flash: TextureRect
var _feedback_elapsed: float = FEEDBACK_SECONDS
var _shake_enabled: bool = true
var _bound_sim: Simulation
var _marker_nodes: Dictionary = {}
var _shipment_nodes: Dictionary = {}
var _previous_damage: Dictionary = {}
var _recovery_notices: Dictionary = {}


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
	_map_clip.mouse_exited.connect(_clear_readout)
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
	shader.code = """
shader_type canvas_item;
uniform sampler2D palette: filter_nearest;
void fragment() {
	float id = floor(texture(TEXTURE, UV).r * 255.0 + 0.5);
	vec4 tint = texture(palette, vec2((id + 0.5) / 82.0, 0.5));
	vec2 pixel = TEXTURE_PIXEL_SIZE;
	bool edge = texture(TEXTURE, UV + vec2(pixel.x, 0.0)).r != texture(TEXTURE, UV).r
		|| texture(TEXTURE, UV + vec2(0.0, pixel.y)).r != texture(TEXTURE, UV).r;
	COLOR = vec4(edge ? tint.rgb * 0.65 : tint.rgb, tint.a);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	_heatmap.material = material
	_map_image.add_child(_heatmap)
	_terrain = TextureRect.new()
	_terrain.name = "TerrainDetails"
	_terrain.texture = TERRAIN
	assert(_terrain.texture.get_size() == Vector2(NATIVE_SIZE))
	_terrain.size = Vector2(NATIVE_SIZE)
	_terrain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map_image.add_child(_terrain)
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
	_toolbar = UI.panel(self, Rect2(16, 1030, 640, 42))
	_toolbar.name = "MapToolbar"
	_tools_toggle = UI.button(_toolbar, "", Rect2(8, 4, 214, 34), _toggle_tools)
	_tools_toggle.name = "MapToolsToggle"
	_tools_toggle.toggle_mode = true
	UI.hint_above(
		UI.button(_toolbar, "GÖRÜNÜMÜ SIFIRLA", Rect2(228, 4, 214, 34), reset_map),
		"Haritayı ilk yakınlığına ve konumuna döndürür."
	)
	_zoom_out = UI.button(
		_toolbar, "-", Rect2(448, 4, 34, 34), _zoom_map.bind(-1, Vector2(960, 540))
	)
	_zoom_label = UI.text(_toolbar, "", Rect2(488, 4, 72, 34))
	_zoom_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.hint_above(_zoom_label, "Harita yakınlığı: 1× - 3×. Fare tekerleğiyle de değiştirilebilir.")
	_zoom_label.mouse_filter = Control.MOUSE_FILTER_PASS
	_zoom_in = UI.button(_toolbar, "+", Rect2(568, 4, 34, 34), _zoom_map.bind(1, Vector2(960, 540)))
	UI.hint_above(_zoom_out, "Uzaklaştır")
	UI.hint_above(_zoom_in, "Yakınlaştır")
	_tools_drawer = Control.new()
	_tools_drawer.position = Vector2(640, 0)
	_tools_drawer.size = Vector2(838, 42)
	_tools_drawer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toolbar.add_child(_tools_drawer)
	_legend_panel = UI.panel(_toolbar, Rect2(416, -122, 838, 112))
	_map_legend = UI.text(_legend_panel, "", Rect2(12, 8, 454, 22), 18, UI.GOLD)
	_legend_description = UI.text(_legend_panel, "", Rect2(12, 34, 454, 22), 18, UI.MUTED)
	_region_note = UI.text(_legend_panel, "21 MERKEZ", Rect2(264, 34, 190, 22), 18, UI.MUTED)
	_crisis_swatch = _swatch(_legend_panel, Rect2(462, 10, 18, 18), CRISIS_COLOR)
	_crisis_key = UI.text(
		_legend_panel, "! KIRMIZI / AKTİF AFET", Rect2(482, 8, 344, 22), 18, UI.INK
	)
	for index: int in range(3):
		_legend_swatches.append(
			_swatch(_legend_panel, Rect2(12 + index * 268, 62, 18, 18), _data_color(index / 2.0))
		)
		_legend_values.append(UI.text(_legend_panel, "", Rect2(38 + index * 268, 60, 240, 22)))
	var region_names := REGION_COLORS.keys()
	for index: int in range(region_names.size()):
		var column := (index - 1) % 3 if index > 0 else 0
		var row := 60 + int((index - 1) / 3) * 24 if index > 0 else 34
		var x := 12 + column * 268
		var region: String = region_names[index]
		_region_swatches.append(
			_swatch(_legend_panel, Rect2(x, row + 2, 18, 18), REGION_COLORS[region])
		)
		_region_labels.append(
			UI.text(_legend_panel, region.to_upper(), Rect2(x + 26, row, 240, 22))
		)
	_legend_readout = UI.text(_legend_panel, "", Rect2(12, 84, 814, 22), 18, UI.INK)
	for index in range(4):
		var title: String = ["BÖLGELER", "AFET HAZIRLIĞI", "YARDIM MALZEMESİ", "ALTYAPI HASARI"][index]
		var button := UI.button(
			_tools_drawer,
			title,
			Rect2([12, 160, 376, 608][index], 4, [136, 204, 220, 216][index], 34),
			select_overlay.bind(index)
		)
		button.toggle_mode = true
		button.add_theme_color_override("font_pressed_color", UI.GOLD)
		(
			UI
			. hint_above(
				button,
				[
					"Merkezleri coğrafi bölgelerine göre renklendirir.",
					"Merkezleri afete hazırlık düzeyine göre renklendirir. Tamamlanan önlemler hazırlığı artırır.",
					"Merkezleri gönderime hazır yardım malzemesine göre renklendirir.",
					"Merkezleri altyapı hasarına göre renklendirir. Hasar geliri düşürür, onarım gerekir.",
				][index],
				_legend_panel
			)
		)
		_layer_buttons.append(button)
	reset_map()
	select_overlay(selected_overlay)


func _toggle_tools() -> void:
	tools_expanded = not tools_expanded
	_sync_tools()
	tools_toggled.emit(tools_expanded)


func _sync_tools() -> void:
	_toolbar.size.x = 1478 if tools_expanded else 640
	_tools_drawer.visible = tools_expanded
	_legend_panel.visible = tools_expanded
	_tools_toggle.set_pressed_no_signal(tools_expanded)
	_tools_toggle.text = "HARİTA GÖRÜNÜMÜ"
	UI.hint_above(
		_tools_toggle,
		(
			("Harita görünümlerini kapat. " if tools_expanded else "Harita görünümlerini sağa aç. ")
			+ "Seçili: "
			+ ["Bölgeler", "Afet Hazırlığı", "Yardım Malzemesi", "Altyapı Hasarı"][selected_overlay]
		),
		_legend_panel
	)


func play_crisis_feedback() -> void:
	_feedback_elapsed = 0.0
	_update_crisis_feedback()


func reset_crisis_feedback() -> void:
	_feedback_elapsed = FEEDBACK_SECONDS
	_update_crisis_feedback()


func set_shake_enabled(enabled: bool) -> void:
	_shake_enabled = enabled
	_update_crisis_feedback()


func _process(delta: float) -> void:
	_update_shipments(delta)
	if _feedback_elapsed < FEEDBACK_SECONDS:
		_feedback_elapsed = minf(FEEDBACK_SECONDS, _feedback_elapsed + maxf(0.0, delta))
		_update_crisis_feedback()


func _update_crisis_feedback() -> void:
	if not is_instance_valid(_crisis_flash):
		return
	var intensity := 1.0 - _feedback_elapsed / FEEDBACK_SECONDS
	_crisis_flash.modulate.a = intensity * 0.18
	# Map and HUD share the feedback offset without moving persistent camera coordinates.
	var index := mini(SHAKE_OFFSETS.size() - 1, int(_feedback_elapsed / 0.04))
	_map_clip.position = (
		SHAKE_OFFSETS[index] if _shake_enabled and intensity > 0.0 else Vector2.ZERO
	)
	crisis_shake_changed.emit(_map_clip.position)


func select_overlay(index: int) -> void:
	selected_overlay = clampi(index, 0, 3)
	_sync_tools()
	_map_image.texture = MAPS[0]
	_terrain.visible = selected_overlay == 0
	for button_index in range(_layer_buttons.size()):
		var button := _layer_buttons[button_index]
		button.set_pressed_no_signal(button_index == selected_overlay)
		var ink := UI.GOLD if button_index == selected_overlay else UI.INK
		button.add_theme_color_override("font_color", ink)
		button.add_theme_color_override("font_hover_color", ink)
	refresh()


func refresh() -> void:
	if not is_instance_valid(_markers) or _shell == null:
		return
	var sim: Simulation = _shell.sim
	_overlay_data = sim.map_overlay(selected_overlay)
	_update_legend()
	if _bound_sim != sim:
		UI.clear(_markers)
		_marker_nodes.clear()
		_shipment_nodes.clear()
		_previous_damage.clear()
		_recovery_notices.clear()
		_bound_sim = sim
	var palette := Image.create(82, 1, false, Image.FORMAT_RGBA8)
	palette.fill(Color.TRANSPARENT)
	for area: ServiceArea in sim.areas.values():
		if selected_overlay > 0:
			palette.set_pixel(area.id, 0, _data_color(float(_overlay_data.areas[area.id].ratio)))
		if (
			not is_zero_approx(float(_previous_damage.get(area.id, area.damage)))
			and is_zero_approx(area.damage)
		):
			var notice := UI.text(
				_markers,
				"ONARILDI",
				Rect2(_native_point(area) + Vector2(-48, -70), Vector2(144, 26)),
				18,
				UI.TEAL
			)
			_recovery_notices[area.id] = {"node": notice, "time": 3.0}
		_previous_damage[area.id] = area.damage
	var wanted: Array[String] = []
	for target: Dictionary in sim.crises.active:
		var area: ServiceArea = sim.areas[int(target.area_id)]
		palette.set_pixel(area.id, 0, CRISIS_COLOR)
		var key: String = "crisis:" + target.id
		wanted.append(key)
		if not _marker_nodes.has(key):
			var marker := UI.button(
				_markers,
				"!",
				Rect2(_native_point(area) + Vector2(-14, -44), Vector2(28, 34)),
				_open_crisis.bind(target.id)
			)
			marker.tooltip_text = area.name + ": " + target.name
			marker.set_drag_forwarding(
				Callable(), _can_marker_drop.bind(target.id), _marker_drop.bind(target.id)
			)
			_marker_nodes[key] = marker
		var feedback := sim.crisis_feedback(target.id)
		_marker_nodes[key].tooltip_text = (
			"%s: %s\nSahada %d ekip / %d yardım\nYolda %d ekip / %d yardım"
			% [
				area.name,
				target.name,
				feedback.teams.field,
				feedback.stock.field,
				feedback.teams.on_time,
				feedback.stock.on_time
			]
		)
		_marker_nodes[key].modulate = UI.TEAL if int(target.teams) > 0 else Color.WHITE
		_marker_nodes[key].add_theme_color_override("font_color", UI.GOLD)
	var planning: bool = (
		is_instance_valid(_shell.preparation_panel) and _shell.preparation_panel.visible
	)
	_map_clip.mouse_default_cursor_shape = (
		Control.CURSOR_POINTING_HAND if planning else Control.CURSOR_MOVE
	)
	if planning:
		for area: Dictionary in sim.preparation_plan().areas:
			var key := "plan:%d" % int(area.area_id)
			wanted.append(key)
			if not _marker_nodes.has(key):
				_marker_nodes[key] = UI.button(
					_markers,
					"+",
					Rect2(
						(
							_native_point(sim.areas[int(area.area_id)])
							+ Vector2(PREPARATION_OFFSETS.get(int(area.area_id), Vector2(26, -54)))
						),
						Vector2(42, 34)
					),
					area_selected.emit.bind(int(area.area_id))
				)
			var marker: Button = _marker_nodes[key]
			marker.text = str(area.planned_count) if int(area.planned_count) > 0 else "+"
			marker.modulate = (
				UI.GOLD if int(area.queued_count) > 0 else UI.MUTED if area.busy else UI.TEAL
			)
			marker.tooltip_text = (
				"%s\nStok: %d ekip / %d yardım\nSırada: %d ekip / %d malzeme işi\nSayı: aktif + sıradaki hazırlık işleri.\nSeçili eylemi eklemek için tıkla."
				% [area.name, area.teams, area.stock, area.queued_teams, area.queued_stock]
			)
	for id: int in [] if planning else sim.bubbles:
		var key := "bubble:%d" % id
		wanted.append(key)
		if not _marker_nodes.has(key):
			var bubble := UI.button(
				_markers,
				"+5 BİLİNÇ PUANI",
				Rect2(_native_point(sim.areas[id]) + Vector2(18, -42), Vector2(198, 34)),
				sim.collect_bubble.bind(id)
			)
			bubble.tooltip_text = "Bilinç puanı topla"
			_marker_nodes[key] = bubble
	for key: String in _marker_nodes.keys():
		if not key in wanted:
			_markers.remove_child(_marker_nodes[key])
			_marker_nodes[key].queue_free()
			_marker_nodes.erase(key)
	_sync_shipments()
	if _palette == null:
		_palette = ImageTexture.create_from_image(palette)
	else:
		_palette.update(palette)
	(_heatmap.material as ShaderMaterial).set_shader_parameter("palette", _palette)
	_update_readout()


static func _data_color(ratio: float) -> Color:
	return (
		DATA_LOW.lerp(DATA_MIDDLE, ratio * 2.0)
		if ratio <= 0.5
		else DATA_MIDDLE.lerp(DATA_HIGH, (ratio - 0.5) * 2.0)
	)


func _swatch(parent: Control, box: Rect2, color: Color) -> ColorRect:
	var result := ColorRect.new()
	result.position = box.position
	result.size = box.size
	result.color = color
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(result)
	return result


func _update_legend() -> void:
	var maximum: int = int(_overlay_data.maximum)
	_map_legend.text = [
		"BÖLGELER / RİSK GÖSTERMEZ",
		"ORTALAMA AFET HAZIRLIĞI",
		"MERKEZDEKİ YARDIM MALZEMESİ",
		"ALTYAPIDAKİ HASAR"
	][selected_overlay]
	_legend_description.text = [
		"",
		"BEŞ AFET TÜRÜNÜN ORTALAMASI / 0-100",
		"%d+ RENK TAVANI / KAPASİTE DEĞİL" % maximum,
		"0-100 YÜZDE / YÜKSEK = DAHA HASARLI"
	][selected_overlay]
	var captions: Array = [
		[],
		["0 / DÜŞÜK", "50 / ORTA", "100 / YÜKSEK"],
		["0 / BOŞ", "%d BİRİM" % (maximum / 2), "%d+ BİRİM" % maximum],
		["0% / HASAR YOK", "50% HASAR", "100% / AĞIR HASAR"]
	]
	for index: int in range(3):
		_legend_values[index].visible = selected_overlay > 0
		_legend_swatches[index].visible = selected_overlay > 0
		if selected_overlay > 0:
			_legend_values[index].text = captions[selected_overlay][index]
	for index: int in range(_region_labels.size()):
		_region_labels[index].visible = selected_overlay == 0
		_region_swatches[index].visible = selected_overlay == 0
	_legend_description.visible = selected_overlay > 0
	_region_note.visible = selected_overlay == 0
	_legend_readout.visible = selected_overlay > 0


func _clear_readout() -> void:
	_hovered_area = 0
	_update_readout()


func _update_readout() -> void:
	if not is_instance_valid(_legend_readout):
		return
	_legend_readout.text = "MERKEZ İLİN ÜZERİNE GEL: ALANIN DEĞERİNİ GÖR"
	if selected_overlay == 0 or not _overlay_data.get("areas", {}).has(_hovered_area):
		return
	var area: Dictionary = _overlay_data.areas[_hovered_area]
	var value := (
		str(int(area.value))
		if selected_overlay == 2
		else ("%.1f/100" % area.value).replace(".", ",")
	)
	_legend_readout.text = (
		"%s / %s: %s"
		% [
			String(area.name).to_upper(),
			["", "HAZIRLIK", "YARDIM", "HASAR"][selected_overlay],
			value
		]
	)


func _sync_shipments() -> void:
	var wanted: Array[int] = []
	for shipment: Dictionary in _shell.sim.logistics.shipments:
		if not shipment.state in ["outbound", "returning", "deployed"]:
			continue
		var id: int = shipment.id
		wanted.append(id)
		var returning: bool = shipment.state == "returning"
		var origin := int(shipment.target) if returning else int(shipment.source)
		var destination := int(shipment.home) if returning else int(shipment.target)
		var a: Vector2 = _native_point(_shell.sim.areas[origin])
		var b: Vector2 = _native_point(_shell.sim.areas[destination])
		if not _shipment_nodes.has(id):
			var group := Control.new()
			group.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_markers.add_child(group)
			var line := Line2D.new()
			line.width = 2.0
			group.add_child(line)
			var icon := TextureRect.new()
			icon.texture = UI.atlas(UI.ICONS, Rect2(96, 0, 32, 32))
			icon.mouse_filter = Control.MOUSE_FILTER_PASS
			group.add_child(icon)
			var label := UI.text(group, "", Rect2(a + Vector2(-36, 28), Vector2(196, 26)), 18)
			label.hide()
			icon.mouse_entered.connect(label.show)
			icon.mouse_exited.connect(label.hide)
			_shipment_nodes[id] = {
				"group": group, "line": line, "icon": icon, "label": label, "target": a
			}
			icon.position = a
		var view: Dictionary = _shipment_nodes[id]
		view.shipment = shipment
		view.origin = a
		view.destination = b
		view.line.points = PackedVector2Array([a, b])
		view.line.visible = shipment.state != "deployed"
		view.icon.visible = shipment.state != "deployed"
		if shipment.state == "deployed":
			view.label.hide()
		var tint := UI.TEAL if shipment.state in ["returning", "deployed"] else UI.GOLD
		view.line.default_color = tint
		view.icon.modulate = tint
		var progress: float = _shell.sim.shipment_progress(shipment)
		view.target = b if shipment.state == "deployed" else a.lerp(b, progress)
		# A loaded/paused view must already show the actual day, not the departure point.
		if _shell.sim.paused or shipment.state == "deployed":
			view.icon.position = view.target
			view.label.position = view.target + Vector2(-36, 28)
		view.label.text = (
			"%s %d %s"
			% [
				(
					"GÖREVDE"
					if shipment.state == "deployed"
					else "DÖNÜŞ" if shipment.state == "returning" else "YOLDA"
				),
				shipment.amount,
				"EKİP" if shipment.kind == "team" else "YARDIM"
			]
		)
		view.label.modulate = tint
		view.icon.tooltip_text = (
			"%s > %s\n%s"
			% [_shell.sim.areas[origin].name, _shell.sim.areas[destination].name, view.label.text]
		)
	for id: int in _shipment_nodes.keys():
		if not id in wanted:
			_markers.remove_child(_shipment_nodes[id].group)
			_shipment_nodes[id].group.queue_free()
			_shipment_nodes.erase(id)


func _update_shipments(delta: float) -> void:
	if _shell == null or _bound_sim != _shell.sim:
		return
	if not _shell.sim.paused:
		for view: Dictionary in _shipment_nodes.values():
			if view.shipment.state != "deployed":
				view.target = view.origin.lerp(
					view.destination, _shell.sim.shipment_progress(view.shipment)
				)
			view.icon.position = view.icon.position.lerp(
				view.target, minf(1.0, delta * 12.0 * _shell.sim.speed)
			)
			view.label.position = view.icon.position + Vector2(-36, 28)
	for id: int in _recovery_notices.keys():
		var notice: Dictionary = _recovery_notices[id]
		notice.time -= delta
		if float(notice.time) <= 0.0:
			_markers.remove_child(notice.node)
			notice.node.queue_free()
			_recovery_notices.erase(id)


func _native_point(area: ServiceArea) -> Vector2:
	return (
		Vector2((area.longitude - 12.0) * 0.777593016455506 * 93.0, (49.0 - area.latitude) * 93.0)
		. round()
	)


func _open_crisis(id: String) -> void:
	_shell.crisis.select_crisis(id)
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
			_shell.sim.dispatch(
				int(data.source),
				id,
				data.kind,
				int(data.get("amount", 1)),
				int(data.get("home", 0))
			)
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
	_update_zoom_controls()


func _zoom_map(direction: int, focus: Vector2) -> void:
	var next_zoom := clampi(_zoom + direction, 1, 3)
	if next_zoom == _zoom:
		return
	var source_point := (focus - _map_image.position) / float(_zoom)
	_zoom = next_zoom
	_map_image.scale = Vector2.ONE * _zoom
	_map_image.position = (focus - source_point * _zoom).round()
	_constrain_map()
	_update_zoom_controls()


func _update_zoom_controls() -> void:
	_zoom_label.text = "%d×" % _zoom
	_zoom_out.disabled = _zoom == 1
	_zoom_in.disabled = _zoom == 3


func _constrain_map() -> void:
	var limit := (_map_clip.size - _map_image.size * _zoom).min(Vector2.ZERO)
	_map_image.position = _map_image.position.clamp(limit, Vector2.ZERO).round()


func _on_map_input(event: InputEvent) -> void:
	if _shell.screen_blocks_map():
		return  # Gaps between the top buttons must not reach the map under an open screen.
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
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		var native: Vector2 = ((event.position - _map_image.position) / float(_zoom)).floor()
		_hovered_area = (
			roundi(_hit_image.get_pixelv(Vector2i(native)).r * 255.0)
			if Rect2(Vector2.ZERO, Vector2(NATIVE_SIZE)).has_point(native)
			else 0
		)
		_update_readout()
