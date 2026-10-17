extends Control
## Read-only fleet view; every shipment still goes through the existing crisis form.
const UI := preload("res://ui_preview/shared/ui_kit.gd")
var _shell: Control
var _summary: Label
var _movements: Label
var _scroll: ScrollContainer
var _list: Control
var _rows: Dictionary = {}


func setup(shell: Control) -> void:
	_shell = shell


func _ready() -> void:
	size = Vector2(580, 810)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.text(self, "BİRLİKLER", Rect2(0, 0, 460, 44), 36)
	_summary = UI.text(self, "", Rect2(0, 56, 580, 26), 18, UI.TEAL)
	_movements = UI.text(self, "", Rect2(0, 86, 580, 26), 18, UI.GOLD)
	UI.text(self, "MERKEZLER / EKİP DURUMU", Rect2(0, 118, 580, 24), 18, UI.MUTED)
	_scroll = ScrollContainer.new()
	_scroll.position = Vector2(0, 150)
	_scroll.size = Vector2(580, 628)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll)
	_list = Control.new()
	_list.custom_minimum_size = Vector2(556, 0)
	_scroll.add_child(_list)
	UI.text(self, "SEVK AÇ: KAYNAK MERKEZ HAZIR SEÇİLİR", Rect2(0, 788, 580, 22), 18, UI.MUTED)
	refresh()


func refresh() -> void:
	var overview: Dictionary = _shell.sim.unit_overview()
	var total: Dictionary = overview.summary
	_summary.text = "HAZIR / TOPLAM EKİP: %d / %d" % [total.ready, total.total]
	_movements.text = (
		"YOLDA %d / GÖREVDE %d / DÖNÜŞ %d" % [total.outbound, total.deployed, total.returning]
	)
	for index: int in range(overview.centers.size()):
		var center: Dictionary = overview.centers[index]
		var id: int = center.area_id
		if not _rows.has(id):
			var row := UI.panel(_list, Rect2(0, index * 132, 556, 124))
			_rows[id] = {
				"title": UI.text(row, "", Rect2(12, 6, 330, 24), 18, UI.GOLD),
				"ready": UI.text(row, "", Rect2(12, 32, 330, 24)),
				"movement": UI.text(row, "", Rect2(12, 58, 532, 24), 18, UI.MUTED),
				"stock": UI.text(row, "", Rect2(12, 84, 330, 24), 18, UI.MUTED),
				"center":
				UI.button(
					row, "MERKEZİ AÇ", Rect2(370, 6, 174, 34), _shell.show_unit_center.bind(id)
				),
				"dispatch":
				UI.button(row, "SEVK AÇ", Rect2(370, 82, 174, 34), _shell.show_dispatch.bind(id)),
			}
		var view: Dictionary = _rows[id]
		view.title.text = String(center.name).to_upper()
		view.ready.text = "HAZIR %d / TOPLAM %d" % [center.ready, center.total]
		view.movement.text = (
			"YOLDA %d / GÖREVDE %d / DÖNÜŞ %d"
			% [center.outbound, center.deployed, center.returning]
		)
		view.stock.text = "YARDIM STOĞU: %d" % center.stock
		view.dispatch.disabled = not center.can_dispatch
		view.dispatch.tooltip_text = center.dispatch_message
	_list.custom_minimum_size.y = overview.centers.size() * 132
