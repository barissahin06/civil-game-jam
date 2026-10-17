extends RefCounted
## Native P0 widgets shared by the feature views.

const FONT := preload("res://ui_preview/assets/afet_pixel.fnt")
const CONTROLS := preload("res://ui_preview/assets/controls.png")
const ICONS := preload("res://ui_preview/assets/icons.png")
const SIGNALS := preload("res://ui_preview/assets/signals.png")
const INK := Color("e7e6d8")
const MUTED := Color("91a7b3")
const GOLD := Color("d3b782")
const TEAL := Color("7eaea0")


static func atlas(texture: Texture2D, region: Rect2) -> AtlasTexture:
	var result := AtlasTexture.new()
	result.atlas = texture
	result.region = region
	return result


static func style(region: Rect2) -> StyleBoxTexture:
	var result := StyleBoxTexture.new()
	result.texture = atlas(CONTROLS, region)
	result.texture_margin_left = 6
	result.texture_margin_top = 6
	result.texture_margin_right = 6
	result.texture_margin_bottom = 6
	return result


static func panel(parent: Control, box: Rect2, raised: bool = false) -> Panel:
	var result := Panel.new()
	result.position = box.position
	result.size = box.size
	result.add_theme_stylebox_override("panel", style(Rect2(56 if raised else 0, 0, 48, 48)))
	parent.add_child(result)
	return result


static func text(
	parent: Control, content: String, box: Rect2, font_size: int = 18, ink: Color = INK
) -> Label:
	var result := Label.new()
	result.clip_text = true
	result.text = content
	result.position = box.position
	result.size = box.size
	result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result.add_theme_font_override("font", FONT)
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", ink)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.set_meta("p0_text_size", box.size)
	parent.add_child(result)
	return result


static func button(
	parent: Control, title: String, box: Rect2, action: Callable, active: bool = false
) -> Button:
	var result := Button.new()
	result.set_meta("p0_text_size", box.size)
	result.text = title
	result.position = box.position
	result.size = box.size
	result.add_theme_font_override("font", FONT)
	result.add_theme_font_size_override("font_size", 18)
	result.add_theme_color_override("font_color", INK)
	result.add_theme_stylebox_override("normal", style(Rect2(112 if active else 0, 56, 48, 32)))
	result.add_theme_stylebox_override("hover", style(Rect2(56, 56, 48, 32)))
	result.add_theme_stylebox_override("pressed", style(Rect2(112, 56, 48, 32)))
	result.add_theme_stylebox_override("disabled", style(Rect2(168, 56, 48, 32)))
	result.add_theme_color_override("font_disabled_color", MUTED)
	result.add_theme_stylebox_override("focus", style(Rect2(56, 56, 48, 32)))
	result.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if action.is_valid():
		result.pressed.connect(action)
	parent.add_child(result)
	return result


static func icon(
	parent: Control, index: int, position: Vector2, tint: Color = INK, texture: Texture2D = ICONS
) -> void:
	var result := TextureRect.new()
	result.texture = atlas(texture, Rect2(index * 32, 0, 32, 32))
	result.position = position
	result.modulate = tint
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(result)


static func bar(
	parent: Control, position: Vector2, bar_width: float, value: int, tint: Color
) -> void:
	var background := TextureRect.new()
	background.texture = atlas(CONTROLS, Rect2(248, 136, 1, 1))
	background.position = position
	background.size = Vector2(bar_width, 8)
	background.modulate = Color("101e2b")
	parent.add_child(background)
	var fill := TextureRect.new()
	fill.texture = background.texture
	fill.position = position
	fill.size = Vector2(bar_width * clampf(value / 100.0, 0.0, 1.0), 8)
	fill.modulate = tint
	parent.add_child(fill)


static func clear(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()
