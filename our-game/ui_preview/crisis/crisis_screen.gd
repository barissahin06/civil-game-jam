extends "res://ui_preview/shared/screen_view.gd"

const DISPATCH_PANEL := preload("res://ui_preview/crisis/dispatch_panel.gd")
var crisis_index: int = 0
var source_index: int = 0
var source_id: int = 0
var dispatch_kind: String = "team"
var amount: int = 1
var operation_scene_enabled: bool = false
var require_target_selection: bool = false
var _feedback: String = ""
var _panel: DISPATCH_PANEL


func render(content: Control, screen: String) -> void:
	super.render(content, screen)
	if screen == "fund":
		_fund()
	else:
		if not is_instance_valid(_panel) or _panel.get_parent() != content:
			_panel = DISPATCH_PANEL.new()
			_panel.setup(_shell, self)
			content.add_child(_panel)
		_panel.refresh()


func selected() -> Dictionary:
	var active: Array[Dictionary] = _shell.sim.crises.active
	crisis_index = clampi(crisis_index, 0, maxi(0, active.size() - 1))
	return active[crisis_index] if not active.is_empty() and not require_target_selection else {}


func open_from_source(source: int) -> void:
	source_id = source
	source_index = _shell.sim.areas.keys().find(source)
	require_target_selection = _shell.sim.crises.active.size() > 1
	_feedback = ""


func select_crisis(id: String) -> void:
	require_target_selection = false
	for index in range(_shell.sim.crises.active.size()):
		if _shell.sim.crises.active[index].id == id:
			crisis_index = index
	_feedback = ""


func _fund() -> void:
	var target := selected()
	_title("ACİL BÜTÇE DESTEĞİ")
	if target.is_empty():
		return
	_metric(
		"AKTARILAN / EN FAZLA ₺5 M",
		_shell.fmt_money(int(target.funds)),
		Rect2(0, 144, 650, 124),
		UI.GOLD
	)
	_paragraph(
		"DESTEK SINIRLI VERİM ARTIŞI VE KRİZ SONRASI ONARIM İNDİRİMİ SAĞLAR. EKİP VE STOK İHTİYACI DEVAM EDER.",
		Rect2(0, 316, 1200, 100),
		UI.INK
	)
	for index in range(3):
		var value: int = [1000000, 2000000, 3000000][index]
		var pay: Button = UI.button(
			_content,
			_shell.fmt_money(value) + " AKTAR",
			Rect2(index * 456, 478, 432, 54),
			_pay.bind(value),
			false,
			UI.ButtonTone.CAUTION
		)
		pay.disabled = int(target.funds) + value > 5000000 or _shell.sim.treasury.money < value
	UI.button(_content, "KRİZE DÖN", Rect2(0, 600, 432, 52), _shell.show_screen.bind("crisis"))


func _pay(value: int) -> void:
	_shell.command_result(_shell.sim.fund(selected().id, value))
