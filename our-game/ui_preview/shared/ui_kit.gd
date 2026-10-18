extends RefCounted
## Native P0 widgets shared by the feature views.

enum ButtonTone { NEUTRAL, CONFIRM, CAUTION, DANGER }

const FONT := preload("res://ui_preview/assets/afet_pixel.fnt")
const CONTROLS := preload("res://ui_preview/assets/controls.png")
const ICONS := preload("res://ui_preview/assets/icons.png")
const SIGNALS := preload("res://ui_preview/assets/signals.png")
const INK := Color("e7e6d8")
const MUTED := Color("91a7b3")
const GOLD := Color("d3b782")
const TEAL := Color("7eaea0")


static func install_cursors() -> void:
	if DisplayServer.get_name() == "headless":
		return
	Input.set_custom_mouse_cursor(
		preload("res://ui_preview/assets/cursor_arrow.png"), Input.CURSOR_ARROW, Vector2(3, 3)
	)
	Input.set_custom_mouse_cursor(
		preload("res://ui_preview/assets/cursor_pointing.png"),
		Input.CURSOR_POINTING_HAND,
		Vector2(12, 3)
	)
	Input.set_custom_mouse_cursor(
		preload("res://ui_preview/assets/cursor_move.png"), Input.CURSOR_MOVE, Vector2(15, 15)
	)
	Input.set_custom_mouse_cursor(
		preload("res://ui_preview/assets/cursor_move.png"), Input.CURSOR_DRAG, Vector2(15, 15)
	)
	Input.set_custom_mouse_cursor(
		preload("res://ui_preview/assets/cursor_can_drop.png"),
		Input.CURSOR_CAN_DROP,
		Vector2(15, 15)
	)
	Input.set_custom_mouse_cursor(
		preload("res://ui_preview/assets/cursor_forbidden.png"),
		Input.CURSOR_FORBIDDEN,
		Vector2(15, 15)
	)


static func reset_cursors() -> void:
	for shape in [
		Input.CURSOR_ARROW,
		Input.CURSOR_POINTING_HAND,
		Input.CURSOR_MOVE,
		Input.CURSOR_DRAG,
		Input.CURSOR_CAN_DROP,
		Input.CURSOR_FORBIDDEN
	]:
		Input.set_custom_mouse_cursor(null, shape)


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
	# Bitmap text boxes use the font line height without extra theme spacing.
	result.add_theme_constant_override("line_spacing", 0)
	result.add_theme_font_override("font", FONT)
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", ink)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.set_meta("p0_text_size", box.size)
	parent.add_child(result)
	return result


static func button(
	parent: Control,
	title: String,
	box: Rect2,
	action: Callable,
	active: bool = false,
	tone: ButtonTone = ButtonTone.NEUTRAL
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
	result.add_theme_stylebox_override("hover_pressed", style(Rect2(112, 56, 48, 32)))
	result.add_theme_stylebox_override("disabled", style(Rect2(168, 56, 48, 32)))
	result.add_theme_color_override("font_disabled_color", MUTED)
	var focus := style(Rect2(56, 56, 48, 32))
	focus.draw_center = false
	result.add_theme_stylebox_override("focus", focus)
	if tone != ButtonTone.NEUTRAL:
		var x: int = {ButtonTone.CONFIRM: 168, ButtonTone.CAUTION: 56, ButtonTone.DANGER: 112}[tone]
		for state: String in ["normal", "hover", "pressed", "hover_pressed"]:
			var surface := style(Rect2(x, 96, 48, 24))
			var brightness: float = 1.18 if state == "hover" else 1.0 if state == "normal" else 0.82
			surface.modulate_color = Color(brightness, brightness, brightness)
			result.add_theme_stylebox_override(state, surface)
	result.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	result.pressed.connect(_play_click.bind(result))
	if action.is_valid():
		result.pressed.connect(action)
	parent.add_child(result)
	return result


static func _play_click(button: Button) -> void:
	if button.is_inside_tree():
		var audio := button.get_tree().get_first_node_in_group("game_audio")
		if audio != null:
			audio.play_effect("ui_click")


static func icon(
	parent: Control, index: int, position: Vector2, tint: Color = INK, texture: Texture2D = ICONS
) -> TextureRect:
	var result := TextureRect.new()
	result.texture = atlas(texture, Rect2(index * 32, 0, 32, 32))
	result.position = position
	result.modulate = tint
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(result)
	return result


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


static func wrap_hint(content: String, width: int = 44) -> String:
	# The pixel tooltip never wraps, so long hints are broken into short lines.
	var lines: Array[String] = []
	for paragraph: String in content.split("\n"):
		var line := ""
		for word: String in paragraph.split(" ", false):
			if not line.is_empty() and line.length() + 1 + word.length() > width:
				lines.append(line)
				line = word
			else:
				line = word if line.is_empty() else line + " " + word
		lines.append(line)
	return "\n".join(lines)


static func wrap_tooltips(root: Node) -> void:
	for node: Node in [root] + root.find_children("*", "Control", true, false):
		var control := node as Control
		if control != null and control.tooltip_text.length() > 44:
			control.tooltip_text = wrap_hint(control.tooltip_text)


static func hint_above(control: Control, hint: String, anchor: Control = null) -> void:
	# Controls on the bottom edge show their hint above themselves; the native tooltip
	# would open over the control. Text lives in the "hint" meta, not tooltip_text.
	control.tooltip_text = ""
	control.set_meta("hint", hint)
	if anchor != null:
		control.set_meta("hint_anchor", anchor)
	if control.has_meta("hint_bound"):
		if control.get_global_rect().has_point(control.get_global_mouse_position()):
			_show_hint_above(control)
		return
	control.set_meta("hint_bound", true)
	control.mouse_entered.connect(_show_hint_above.bind(control))
	control.mouse_exited.connect(_hide_hint_above.bind(control))
	control.tree_exiting.connect(_hide_hint_above.bind(control))


static func hint_panel(viewport: Viewport) -> PanelContainer:
	var root := viewport.get_tree().root
	var panel: PanelContainer = (
		root.get_meta("hint_above_panel") if root.has_meta("hint_above_panel") else null
	)
	if panel == null or not is_instance_valid(panel):
		panel = PanelContainer.new()
		panel.name = "HintAbove"
		panel.add_theme_stylebox_override("panel", style(Rect2(0, 0, 48, 48)))
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var label := Label.new()
		label.add_theme_font_override("font", FONT)
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_color_override("font_color", INK)
		label.add_theme_constant_override("line_spacing", 0)
		panel.add_child(label)
		panel.hide()
		root.add_child(panel)
		root.set_meta("hint_above_panel", panel)
	return panel


static func _show_hint_above(control: Control) -> void:
	var hint: String = control.get_meta("hint", "")
	if hint.is_empty() or not control.is_visible_in_tree():
		return
	var panel := hint_panel(control.get_viewport())
	if not panel.is_inside_tree():
		return
	(panel.get_child(0) as Label).text = wrap_hint(hint)
	panel.get_parent().move_child(panel, -1)
	panel.show()
	panel.reset_size()
	var top := control.get_global_rect().position.y
	var anchor: Control = (
		control.get_meta("hint_anchor") if control.has_meta("hint_anchor") else null
	)
	if anchor != null and is_instance_valid(anchor) and anchor.is_visible_in_tree():
		top = minf(top, anchor.get_global_rect().position.y)
	var screen := control.get_viewport().get_visible_rect().size
	panel.position = Vector2(
		clampf(control.get_global_rect().position.x, 8.0, screen.x - panel.size.x - 8.0),
		maxf(8.0, top - panel.size.y - 8.0)
	)
	panel.set_meta("hint_owner", control)


static func hide_hints(node: Node) -> void:
	var root := node.get_tree().root
	if root.has_meta("hint_above_panel") and is_instance_valid(root.get_meta("hint_above_panel")):
		(root.get_meta("hint_above_panel") as Control).hide()


static func _hide_hint_above(control: Control) -> void:
	if not control.is_inside_tree():
		return
	var root := control.get_tree().root
	if not root.has_meta("hint_above_panel"):
		return
	var panel: PanelContainer = root.get_meta("hint_above_panel")
	if (
		is_instance_valid(panel)
		and panel.has_meta("hint_owner")
		and panel.get_meta("hint_owner") == control
	):
		panel.hide()


static func clear(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()
