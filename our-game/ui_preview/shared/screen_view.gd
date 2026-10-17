extends RefCounted
## Common presentation helpers; navigation belongs to the shell.

const UI := preload("res://ui_preview/shared/ui_kit.gd")

var _shell: Control
var _content: Control


func setup(shell: Control) -> void:
	_shell = shell


func render(content: Control, _screen: String) -> void:
	_content = content


func _title(title: String, subtitle: String = "") -> void:
	UI.text(_content, title, Rect2(0, 0, 1350, 48), 36)
	if not subtitle.is_empty():
		UI.text(_content, subtitle, Rect2(0, 58, 1350, 30), 18, UI.MUTED)


func _paragraph(text: String, box: Rect2, color: Color) -> void:
	var label: Label = UI.text(_content, text, box, 18, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size = box.size
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP


func _line(box: Rect2, color: Color) -> void:
	var line := TextureRect.new()
	line.texture = UI.atlas(UI.CONTROLS, Rect2(248, 136, 1, 1))
	line.position = box.position
	line.size = box.size
	line.modulate = color
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(line)


func _metric(title: String, value: String, box: Rect2, color: Color) -> void:
	UI.panel(_content, box, true)
	UI.text(
		_content,
		title,
		Rect2(box.position + Vector2(18, 12), Vector2(box.size.x - 36, 28)),
		18,
		UI.MUTED
	)
	UI.text(
		_content,
		value,
		Rect2(box.position + Vector2(18, 44), Vector2(box.size.x - 36, 48)),
		36,
		color
	)
