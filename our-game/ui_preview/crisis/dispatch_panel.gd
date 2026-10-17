extends Control
## Persistent controls: simulation updates change values, never focus or node identity.

const UI := preload("res://ui_preview/shared/ui_kit.gd")
const OPERATION := preload("res://ui_preview/crisis/operation_view.gd")
var _shell: Control
var _view: RefCounted
var _target: OptionButton
var _source: OptionButton
var _labels: Dictionary = {}
var _team: Button
var _stock: Button
var _send: Button
var _fill: Button
var _quick_team: Button
var _quick_stock: Button
var _fund: Button
var _play: Button
var _operation: OPERATION
var _source_signature: String = ""
var _target_signature: String = ""
var _selected_target_id: String = ""


func setup(shell: Control, view: RefCounted) -> void:
	_shell = shell
	_view = view


func _ready() -> void:
	size = Vector2(580, 810)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label("heading", "KRİZ MERKEZİ", Rect2(0, 0, 270, 34), UI.GOLD)
	_fund = UI.button(
		self,
		"ACİL BÜTÇE",
		Rect2(292, 0, 184, 34),
		_shell.show_screen.bind("fund"),
		false,
		UI.ButtonTone.CAUTION
	)
	_target = _picker(Rect2(0, 38, 580, 34))
	_target.item_selected.connect(_choose_target)
	_label("day", "", Rect2(0, 78, 444, 28))
	_play = UI.button(self, "DEVAM", Rect2(464, 76, 116, 32), _toggle_time)
	_label("effect", "", Rect2(0, 110, 580, 26), UI.GOLD)
	_labels.effect.tooltip_text = "Hazırlık afet başındaki korumadır. Müdahale desteği sahadaki ekip, yardım, bakım verimi ve fonla hesaplanır. Yoldaki kaynak henüz katkı sağlamaz."
	_label("teams", "", Rect2(0, 142, 580, 26), UI.TEAL)
	_label("stock", "", Rect2(0, 174, 580, 26), UI.TEAL)
	_team = UI.button(self, "EKİP SEÇ", Rect2(0, 208, 284, 34), _set_kind.bind("team"))
	_stock = UI.button(self, "YARDIM SEÇ", Rect2(296, 208, 284, 34), _set_kind.bind("stock"))
	_team.set_drag_forwarding(_drag.bind("team", _team), Callable(), Callable())
	_stock.set_drag_forwarding(_drag.bind("stock", _stock), Callable(), Callable())
	_source = _picker(Rect2(0, 252, 580, 34))
	_source.item_selected.connect(_choose_source)
	UI.button(self, "-", Rect2(0, 296, 48, 32), _change_amount.bind(-1))
	_label("amount", "", Rect2(60, 296, 188, 32))
	UI.button(self, "+", Rect2(260, 296, 48, 32), _change_amount.bind(1))
	_fill = UI.button(self, "EKSİK KADAR SEÇ", Rect2(324, 296, 256, 32), _fill_missing)
	_label("quote", "", Rect2(0, 336, 580, 26), UI.GOLD)
	_send = UI.button(
		self, "SEVK ET", Rect2(0, 370, 580, 36), _dispatch, false, UI.ButtonTone.CONFIRM
	)
	_quick_team = UI.button(
		self,
		"1 EKİP GÖNDER",
		Rect2(0, 414, 284, 36),
		_quick.bind("team"),
		false,
		UI.ButtonTone.CONFIRM
	)
	_quick_stock = UI.button(
		self,
		"10 YARDIM GÖNDER",
		Rect2(296, 414, 284, 36),
		_quick.bind("stock"),
		false,
		UI.ButtonTone.CONFIRM
	)
	_label("team_fee", "", Rect2(0, 454, 284, 26), UI.MUTED)
	_label("stock_fee", "", Rect2(296, 454, 284, 26), UI.MUTED)
	_label("feedback", "", Rect2(0, 484, 580, 36), UI.TEAL)
	_labels.feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_operation = OPERATION.new()
	_operation.setup(_shell)
	_operation.position = Vector2(50, 524)
	add_child(_operation)
	_label("scene_caption", "TEMSİLİ SAHA / SİMÜLASYON DURUMU", Rect2(0, 794, 580, 26), UI.MUTED)
	_label("guide", "", Rect2(0, 536, 580, 240), UI.MUTED)
	_labels.guide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	set_drag_forwarding(Callable(), _can_drop, _drop)


func _label(key: String, value: String, box: Rect2, ink: Color = UI.INK) -> void:
	_labels[key] = UI.text(self, value, box, 18, ink)


func _picker(box: Rect2) -> OptionButton:
	var picker := OptionButton.new()
	picker.position = box.position
	picker.size = box.size
	picker.add_theme_font_override("font", UI.FONT)
	picker.add_theme_font_size_override("font_size", 18)
	picker.add_theme_stylebox_override("normal", UI.style(Rect2(0, 56, 48, 32)))
	picker.add_theme_stylebox_override("hover", UI.style(Rect2(56, 56, 48, 32)))
	picker.add_theme_stylebox_override("focus", UI.style(Rect2(56, 56, 48, 32)))
	picker.get_popup().add_theme_font_override("font", UI.FONT)
	picker.get_popup().add_theme_font_size_override("font_size", 18)
	add_child(picker)
	return picker


func refresh() -> void:
	if not is_node_ready():
		return
	var sim: Simulation = _shell.sim
	_sync_targets()
	var target: Dictionary = _view.selected()
	var feedback: Dictionary = sim.crisis_feedback(str(target.get("id", "")))
	var valid := not feedback.is_empty()
	_fund.disabled = not valid
	_fund.tooltip_text = (
		"Seçilen krize bütçe desteği sağla." if valid else "Önce aktif bir kriz seç."
	)
	_play.text = "DEVAM" if sim.paused else "DURAKLAT"
	_play.disabled = not valid
	if valid:
		_selected_target_id = target.id
		_labels.day.text = (
			"%s / GÜN %d/%d"
			% [
				String(HistoricalCatalog.KIND_NAMES[target.kind]).to_upper(),
				int(feedback.elapsed) + 1,
				feedback.window
			]
		)
		_labels.effect.text = (
			"HAZIRLIK %%%d / MÜDAHALE DESTEĞİ %%%d"
			% [roundi(feedback.preparation), roundi(feedback.support)]
		)
		_labels.teams.text = _need_line("EKİP", feedback.teams)
		_labels.stock.text = _need_line("YARDIM", feedback.stock)
		_labels.teams.tooltip_text = (
			"İhtiyaç %d / Geç varacak %d" % [feedback.teams.need, feedback.teams.late]
		)
		_labels.stock.tooltip_text = (
			"İhtiyaç %d / Geç varacak %d" % [feedback.stock.need, feedback.stock.late]
		)
	else:
		_labels.day.text = "HEDEF SEÇ" if not sim.crises.active.is_empty() else "AKTİF KRİZ YOK"
		_labels.effect.text = "KAYNAK SEÇİMİN KORUNUR"
		_labels.teams.text = ""
		_labels.stock.text = ""
	_sync_sources(str(target.get("id", "")))
	var source: int = _view.source_id
	_team.modulate = UI.GOLD if _view.dispatch_kind == "team" else Color.WHITE
	_stock.modulate = UI.GOLD if _view.dispatch_kind == "stock" else Color.WHITE
	var id: String = str(target.get("id", ""))
	var quote := sim.dispatch_preview(source, id, _view.dispatch_kind, _view.amount)
	_labels.amount.text = "MİKTAR %d" % _view.amount
	_labels.quote.text = (
		"%d GÜN / %s%s"
		% [
			quote.get("days", 0),
			_shell.fmt_money(int(quote.get("fee", 0))),
			" / GEÇ VARIŞ" if quote.get("late", false) else ""
		]
	)
	_send.disabled = not bool(quote.get("ok", false))
	_send.tooltip_text = str(quote.get("message", "Hedef seç"))
	_fill.disabled = sim.missing_dispatch_amount(source, id, _view.dispatch_kind) == 0
	_fill.tooltip_text = "Yoldaki zamanında destek düşülür; kapasite ve bütçeyle sınırlıdır."
	_update_quick(_quick_team, "team_fee", source, id, "team")
	_update_quick(_quick_stock, "stock_fee", source, id, "stock")
	_labels.feedback.text = _view._feedback
	_labels.feedback.tooltip_text = _view._feedback
	_operation.visible = _view.operation_scene_enabled
	_labels.scene_caption.visible = _view.operation_scene_enabled
	_labels.guide.visible = not _view.operation_scene_enabled
	_operation.set_context(id, int(feedback.get("area_id", 31)))
	_labels.guide.text = "SEVK SONRASI\nHaritadaki çizgi yolculuğu gösterir.\nVaran ekipler sahada göreve başlar.\nYardım açığı ayrıca karşılanır.\n\nHazırlık ilk etkiyi azaltır.\nMüdahale desteği gün gün hesaplanır.\nSonuç raporu korumayı ve onarımı açıklar."


func _need_line(title: String, need: Dictionary) -> String:
	return "%s: SAHADA %d / YOLDA %d / EKSİK %d" % [title, need.field, need.on_time, need.missing]


func _sync_targets() -> void:
	var active: Array[Dictionary] = _shell.sim.crises.active
	var signature := (
		str(active.map(func(item: Dictionary) -> String: return item.id))
		+ str(_view.require_target_selection)
	)
	if signature != _target_signature:
		_target_signature = signature
		_target.clear()
		if _view.require_target_selection:
			_target.add_item("HEDEF KRİZ SEÇ")
			_target.set_item_metadata(0, "")
		for target: Dictionary in active:
			_target.add_item(
				(
					_shell.sim.areas[int(target.area_id)].name.to_upper()
					+ " / "
					+ target.name.to_upper()
				)
			)
			_target.set_item_metadata(_target.item_count - 1, target.id)
	if not _view.require_target_selection and not active.is_empty():
		if not _selected_target_id.is_empty():
			for index in range(active.size()):
				if active[index].id == _selected_target_id:
					_view.crisis_index = index
		_target.select(_view.crisis_index)


func _sync_sources(id: String) -> void:
	var options: Array[Dictionary] = _shell.sim.dispatch_options(id, _view.dispatch_kind)
	var signature := ""
	for option: Dictionary in options:
		signature += "%d/%d/%d/%d;" % [option.source, option.available, option.days, option.fee]
	if signature != _source_signature and not _source.get_popup().visible:
		_source_signature = signature
		_source.clear()
		for option: Dictionary in options:
			var title := (
				"%s / %d HAZIR / %d GÜN / %s/%s"
				% [
					option.name.to_upper(),
					option.available,
					option.days,
					_shell.fmt_money(int(option.fee)),
					"1E" if _view.dispatch_kind == "team" else "10Y"
				]
			)
			_source.add_item(title)
			_source.set_item_metadata(_source.item_count - 1, option.source)
			_source.set_item_disabled(_source.item_count - 1, int(option.available) == 0)
			_source.set_item_tooltip(_source.item_count - 1, str(option.message))
	if _view.source_id == 0 and not options.is_empty():
		for option: Dictionary in options:
			if int(option.limit) > 0:
				_view.source_id = int(option.source)
				break
	for index in range(_source.item_count):
		if int(_source.get_item_metadata(index)) == _view.source_id:
			_source.select(index)
	_source.disabled = options.is_empty()
	_view.source_index = _shell.sim.areas.keys().find(_view.source_id)


func _update_quick(button: Button, label: String, source: int, id: String, kind: String) -> void:
	var quote: Dictionary = _shell.sim.quick_dispatch_preview(source, id, kind)
	button.disabled = not bool(quote.get("ok", false))
	button.tooltip_text = str(quote.get("message", ""))
	_labels[label].text = (
		"%s / %d GÜN" % [_shell.fmt_money(int(quote.get("fee", 0))), int(quote.get("days", 0))]
	)


func _choose_target(index: int) -> void:
	var id: String = str(_target.get_item_metadata(index))
	if not id.is_empty():
		_selected_target_id = id
		_view.select_crisis(id)
	refresh()


func _choose_source(index: int) -> void:
	_view.source_id = int(_source.get_item_metadata(index))
	refresh()


func _set_kind(kind: String) -> void:
	_view.dispatch_kind = kind
	_view.amount = 1 if kind == "team" else 10
	refresh()


func _change_amount(delta: int) -> void:
	_view.amount = maxi(1, _view.amount + delta * (1 if _view.dispatch_kind == "team" else 10))
	refresh()


func _fill_missing() -> void:
	var id: String = str(_view.selected().get("id", ""))
	_view.amount = maxi(
		1, _shell.sim.missing_dispatch_amount(_view.source_id, id, _view.dispatch_kind)
	)
	refresh()


func _dispatch() -> void:
	_result(
		_shell.sim.dispatch(
			_view.source_id, str(_view.selected().get("id", "")), _view.dispatch_kind, _view.amount
		)
	)


func _quick(kind: String) -> void:
	_result(_shell.sim.quick_dispatch(_view.source_id, str(_view.selected().get("id", "")), kind))


func _result(result: Dictionary) -> void:
	_view._feedback = result.message
	_shell.command_result(result)
	refresh()


func _toggle_time() -> void:
	_shell.sim.set_paused(not _shell.sim.paused)
	refresh()


func _drag(_at: Vector2, kind: String, token: Button) -> Variant:
	var preview := Label.new()
	preview.text = "1 EKİP" if kind == "team" else "10 YARDIM"
	preview.add_theme_font_override("font", UI.FONT)
	token.set_drag_preview(preview)
	return {
		"tag": "dispatch",
		"source": _view.source_id,
		"kind": kind,
		"amount": 1 if kind == "team" else 10
	}


func _can_drop(_at: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("tag") == "dispatch" and not _view.selected().is_empty()


func _drop(at: Vector2, data: Variant) -> void:
	if _can_drop(at, data):
		_result(
			_shell.sim.dispatch(
				int(data.get("source", 0)),
				_view.selected().id,
				str(data.get("kind", "")),
				int(data.get("amount", 0))
			)
		)
