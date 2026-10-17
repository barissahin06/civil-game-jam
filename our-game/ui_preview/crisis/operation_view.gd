extends TextureRect
## State comes from the simulation; these authored poses never advance gameplay.

const SHEET := preload("res://ui_preview/assets/operations.png")
var _shell: Control
var _crisis_id: String = ""
var _area_id: int = 31
var _phase: float = 0.0
var _region := AtlasTexture.new()


func setup(shell: Control) -> void:
	_shell = shell


func _ready() -> void:
	size = Vector2(480, 270)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_region.atlas = SHEET
	texture = _region
	_update_frame()


func set_context(id: String, area: int) -> void:
	_crisis_id = id
	_area_id = area
	_update_frame()


func _process(delta: float) -> void:
	if not _shell.sim.paused:
		_phase += delta * _shell.sim.speed
	_update_frame()


func _update_frame() -> void:
	if _shell == null:
		return
	var feedback: Dictionary = _shell.sim.crisis_feedback(_crisis_id)
	var state := 0
	if not feedback.is_empty():
		if int(feedback.stock.field) > 0:
			state = 2
		elif int(feedback.teams.field) > 0:
			state = 1
	elif _shell.sim.areas.has(_area_id):
		var report: Dictionary = _shell.sim.report_for()
		if not report.is_empty() and int(report.area_id) == _area_id:
			state = 4 if is_zero_approx(_shell.sim.areas[_area_id].damage) else 3
	_region.region = Rect2((state * 2 + int(_phase / 0.35) % 2) * 480, 0, 480, 270)
