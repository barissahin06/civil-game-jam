extends Control
## The roster and transfer controls share the simulation's resource quotes.
const UI := preload("res://ui_preview/shared/ui_kit.gd")
var _shell: Control
var _summary: Label
var _movements: Label
var _scroll: ScrollContainer
var _list: Control
var _rows: Dictionary = {}
var _source: OptionButton
var _target: OptionButton
var _team: Button
var _stock: Button
var _amount_label: Label
var _quote: Label
var _feedback: Label
var _transfer: Button
var _recall: Button
var _source_id: int = 0
var _home_id: int = 0
var _target_id: int = 0
var _kind: String = "team"
var _amount: int = 1
var _source_signature: String = ""


func setup(shell: Control) -> void:
	_shell = shell


func _ready() -> void:
	size = Vector2(580, 810)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.text(self, "EKİPLER VE YARDIM", Rect2(0, 0, 460, 44), 36)
	_summary = UI.text(self, "", Rect2(0, 56, 580, 26), 18, UI.TEAL)
	_movements = UI.text(self, "", Rect2(0, 86, 580, 26), 18, UI.GOLD)
	UI.text(self, "MERKEZLER / EKİP DURUMU", Rect2(0, 118, 580, 24), 18, UI.MUTED)
	_scroll = ScrollContainer.new()
	_scroll.position = Vector2(0, 150)
	_scroll.size = Vector2(580, 282)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll)
	_list = Control.new()
	_list.custom_minimum_size = Vector2(556, 0)
	_scroll.add_child(_list)
	UI.text(self, "MERKEZLER ARASI TAŞIMA", Rect2(0, 442, 580, 24), 18, UI.GOLD)
	_source = _picker(Rect2(0, 470, 580, 34))
	_source.item_selected.connect(_choose_source)
	_target = _picker(Rect2(0, 512, 580, 34))
	_target.item_selected.connect(_choose_target)
	_team = UI.button(self, "EKİP TAŞI", Rect2(0, 554, 284, 34), _set_kind.bind("team"))
	_stock = UI.button(self, "DEPOYA MALZEME", Rect2(296, 554, 284, 34), _set_kind.bind("stock"))
	UI.button(self, "-", Rect2(0, 596, 44, 34), _change_amount.bind(-1))
	_amount_label = UI.text(self, "", Rect2(56, 600, 224, 26), 18)
	UI.button(self, "+", Rect2(284, 596, 44, 34), _change_amount.bind(1))
	_quote = UI.text(self, "", Rect2(0, 638, 580, 44), 18, UI.GOLD)
	_quote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_transfer = UI.button(self, "TAŞIMAYI ONAYLA", Rect2(0, 692, 284, 36), _send)
	_recall = UI.button(self, "ASIL MERKEZE ÇAĞIR", Rect2(296, 692, 284, 36), _send.bind(true))
	_feedback = UI.text(self, "", Rect2(0, 738, 580, 56), 18, UI.TEAL)
	_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
				"stock": UI.text(row, "", Rect2(12, 84, 324, 24), 18, UI.MUTED),
				"center":
				UI.button(
					row, "MERKEZİ AÇ", Rect2(340, 6, 204, 34), _shell.show_unit_center.bind(id)
				),
				"dispatch":
				UI.button(
					row, "GÖNDERİM HAZIRLA", Rect2(340, 82, 204, 34), _shell.show_dispatch.bind(id)
				),
			}
		var view: Dictionary = _rows[id]
		view.title.text = String(center.name).to_upper()
		view.ready.text = "HAZIR %d / TOPLAM %d" % [center.ready, center.total]
		if int(center.guest_ready) > 0:
			view.ready.text = ("YEREL %d / MİSAFİR %d" % [center.home_ready, center.guest_ready])
		var groups: Array[String] = []
		for group: Dictionary in center.groups:
			groups.append(
				"%s üssü: %d hazır" % [_shell.sim.areas[int(group.home)].name, group.amount]
			)
		view.ready.tooltip_text = "\n".join(groups)
		view.ready.mouse_filter = Control.MOUSE_FILTER_PASS
		view.movement.text = (
			"YOLDA %d / GÖREVDE %d / DÖNÜŞ %d"
			% [center.outbound, center.deployed, center.returning]
		)
		view.stock.text = "YARDIM MALZEMESİ: %d" % center.stock
		view.dispatch.disabled = not center.can_dispatch
		view.dispatch.tooltip_text = center.dispatch_message
	_list.custom_minimum_size.y = overview.centers.size() * 132
	_refresh_transfer()


func _picker(box: Rect2) -> OptionButton:
	var picker := OptionButton.new()
	picker.position = box.position
	picker.size = box.size
	picker.add_theme_font_override("font", UI.FONT)
	picker.add_theme_font_size_override("font_size", 18)
	picker.add_theme_stylebox_override("normal", UI.style(Rect2(0, 56, 48, 32)))
	picker.add_theme_stylebox_override("hover", UI.style(Rect2(56, 56, 48, 32)))
	picker.get_popup().add_theme_font_override("font", UI.FONT)
	picker.get_popup().add_theme_font_size_override("font_size", 18)
	add_child(picker)
	return picker


func _refresh_transfer() -> void:
	var options: Array[Dictionary] = []
	var signature := _kind
	for id: int in _shell.sim.areas:
		var area: ServiceArea = _shell.sim.areas[id]
		var groups: Array[Dictionary] = _shell.sim.logistics.ready_groups(id)
		if _kind == "stock" or groups.is_empty():
			groups = [{"home": id, "amount": area.stock if _kind == "stock" else 0}]
		for group: Dictionary in groups:
			var title := (
				"%s / %d %s"
				% [area.name.to_upper(), group.amount, "HAZIR" if _kind == "team" else "BİRİM"]
			)
			if int(group.home) != id:
				title += " / ÜS " + _shell.sim.areas[int(group.home)].name.to_upper()
			options.append(
				{"source": id, "home": int(group.home), "amount": int(group.amount), "title": title}
			)
			signature += "%d/%d/%d;" % [id, group.home, group.amount]
	if signature != _source_signature and not _source.get_popup().visible:
		_source_signature = signature
		_source.clear()
		for option: Dictionary in options:
			_source.add_item(option.title)
			_source.set_item_metadata(_source.item_count - 1, option)
			_source.set_item_disabled(_source.item_count - 1, int(option.amount) == 0)
		if _source_id == 0 and not options.is_empty():
			_source_id = int(options[0].source)
			_home_id = int(options[0].home)
		_source.select(-1)
		for index in range(_source.item_count):
			var option: Dictionary = _source.get_item_metadata(index)
			if int(option.source) == _source_id and int(option.home) == _home_id:
				_source.select(index)
		if _source.selected == -1:
			_source.text = "KAYNAK GRUBU SEÇ"
	if _target.item_count == 0:
		for id: int in _shell.sim.areas:
			_target.add_item("HEDEF: " + _shell.sim.areas[id].name.to_upper())
			_target.set_item_metadata(_target.item_count - 1, id)
			if _target_id == 0 and id != _source_id:
				_target_id = id
		for index in range(_target.item_count):
			if int(_target.get_item_metadata(index)) == _target_id:
				_target.select(index)
	_team.modulate = UI.GOLD if _kind == "team" else Color.WHITE
	_stock.modulate = UI.GOLD if _kind == "stock" else Color.WHITE
	_amount_label.text = "%d %s" % [_amount, "EKİP" if _kind == "team" else "BİRİM MALZEME"]
	var quote: Dictionary = _shell.sim.transfer_preview(
		_source_id, _target_id, _kind, _amount, _home_id
	)
	_quote.text = (
		"VARIŞ: %d GÜN / %s\nTAŞIMA BEDELİ: %s"
		% [
			quote.days,
			CalendarClock.day_to_iso(int(quote.arrival)),
			_shell.fmt_money(int(quote.fee))
		]
	)
	_transfer.disabled = not bool(quote.ok)
	_transfer.tooltip_text = str(quote.message)
	var recall: Dictionary = _shell.sim.transfer_preview(
		_source_id, _home_id, "team", _amount, _home_id
	)
	_recall.disabled = _kind != "team" or _source_id == _home_id or not bool(recall.ok)
	_recall.tooltip_text = (
		"ASIL ÜS: %s / %d GÜN / %s"
		% [
			_shell.sim.areas[_home_id].name if _shell.sim.areas.has(_home_id) else "",
			recall.days,
			_shell.fmt_money(int(recall.fee))
		]
	)
	if _feedback.text.is_empty():
		_feedback.text = "Ekipler asıl üslerini korur. Yardım hedef depoya eklenir."


func _choose_source(index: int) -> void:
	var option: Dictionary = _source.get_item_metadata(index)
	_source_id = int(option.source)
	_home_id = int(option.home)
	_feedback.text = ""
	_refresh_transfer()


func _choose_target(index: int) -> void:
	_target_id = int(_target.get_item_metadata(index))
	_feedback.text = ""
	_refresh_transfer()


func _set_kind(kind: String) -> void:
	_kind = kind
	_home_id = _source_id
	_amount = 1 if kind == "team" else 10
	_feedback.text = ""
	_refresh_transfer()


func _change_amount(delta: int) -> void:
	_amount = maxi(1, _amount + delta * (1 if _kind == "team" else 10))
	_feedback.text = ""
	_refresh_transfer()


func _send(recall: bool = false) -> void:
	var result: Dictionary = (
		_shell.sim.recall_teams(_source_id, _home_id, _amount)
		if recall
		else _shell.sim.transfer_resources(_source_id, _target_id, _kind, _amount, _home_id)
	)
	_feedback.text = str(result.message)
	_shell.command_result(result)
	refresh()
