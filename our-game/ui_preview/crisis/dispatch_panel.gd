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
	_label("heading", "AFET MÜDAHALESİ", Rect2(0, 0, 270, 34), UI.GOLD)
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
	_label("day", "", Rect2(0, 78, 328, 28))
	_play = UI.button(self, "ZAMANI BAŞLAT", Rect2(340, 76, 240, 32), _toggle_time)
	_label("effect", "", Rect2(0, 110, 580, 26), UI.GOLD)
	_labels.effect.tooltip_text = "Hazırlık afet başındaki korumadır. Müdahale desteği sahadaki ekip, yardım, bakım verimi ve fonla hesaplanır. Yoldaki kaynak henüz katkı sağlamaz."
	_label("teams", "", Rect2(0, 142, 580, 26), UI.TEAL)
	_label("stock", "", Rect2(0, 168, 580, 66), UI.TEAL)
	_team = UI.button(self, "EKİP SEÇ", Rect2(0, 236, 284, 34), _set_kind.bind("team"))
	_stock = UI.button(self, "MALZEME SEÇ", Rect2(296, 236, 284, 34), _set_kind.bind("stock"))
	_team.set_meta("guide_target", "dispatch_teams")
	_stock.set_meta("guide_target", "dispatch_stock")
	_team.tooltip_text = "Türü ve miktarı seç; Gönderimi Onayla ile gönder. Sürüklemek daima 1 ekip veya 10 birim yardım malzemesi gönderir."
	_stock.tooltip_text = _team.tooltip_text
	_team.set_drag_forwarding(_drag.bind("team", _team), Callable(), Callable())
	_stock.set_drag_forwarding(_drag.bind("stock", _stock), Callable(), Callable())
	_source = _picker(Rect2(0, 274, 580, 34))
	_source.set_meta("guide_target", "dispatch_source")
	_source.item_selected.connect(_choose_source)
	UI.button(self, "-", Rect2(0, 318, 34, 32), _change_amount.bind(-1))
	_label("amount", "", Rect2(40, 318, 216, 32))
	UI.button(self, "+", Rect2(260, 318, 34, 32), _change_amount.bind(1))
	_fill = UI.button(self, "İHTİYACA GÖRE AYARLA", Rect2(304, 318, 276, 32), _fill_missing)
	_fill.set_meta("guide_target", "dispatch_fill")
	_label("quote", "", Rect2(0, 358, 580, 44), UI.GOLD)
	_send = UI.button(
		self, "GÖNDERİMİ ONAYLA", Rect2(0, 408, 580, 36), _dispatch, false, UI.ButtonTone.CONFIRM
	)
	_send.set_meta("guide_target", "dispatch_send")
	_label("feedback", "", Rect2(0, 452, 580, 44), UI.TEAL)
	_labels.stock.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_labels.stock.set_meta("guide_target", "supply")
	_labels.stock.mouse_filter = Control.MOUSE_FILTER_PASS
	_labels.quote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_labels.feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_operation = OPERATION.new()
	_operation.setup(_shell)
	_operation.position = Vector2(50, 506)
	add_child(_operation)
	_label("scene_caption", "SÜRÜKLE: 1 EKİP / 10 BİRİM MALZEME", Rect2(0, 782, 580, 26), UI.MUTED)
	_label(
		"guide",
		"GÖNDERİMİ ONAYLAMAK SEÇİLİ MİKTARI GÖNDERİR.\nSÜRÜKLEME: 1 EKİP / 10 BİRİM MALZEME.\nOTOMATİK MİKTAR YOLDAKİ DESTEĞİ SAYAR;\nMİKTAR KAYNAK VE BÜTÇEYLE SINIRLIDIR.",
		Rect2(0, 506, 580, 100),
		UI.MUTED
	)
	_labels.guide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_labels.guide.mouse_filter = Control.MOUSE_FILTER_PASS
	_labels.guide.tooltip_text = "Haritadaki çizgi yolculuğu gösterir. Varan ekipler sahada göreve başlar; yardım açığı ayrıca karşılanır. Hazırlık ilk etkiyi azaltır. Müdahale desteği gün gün hesaplanır. Sonuç raporu korumayı ve onarımı açıklar."
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
		"Seçilen afete bütçe desteği sağla." if valid else "Önce aktif bir afet seç."
	)
	_play.text = "ZAMANI BAŞLAT" if sim.paused else "ZAMANI DURDUR"
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
		var supply_days: String = ("%.1f" % feedback.stock.supply_days).replace(".", ",")
		_labels.stock.text = (
			"YARDIM MALZEMESİ: %d / %d BİRİM\nİHTİYAÇ: %d BİRİM/GÜN / YETER: %s GÜN\nYOLDA: %d / İLK EKSİK: %s"
			% [
				feedback.stock.field,
				feedback.stock.capacity,
				feedback.stock.daily,
				supply_days,
				feedback.stock.on_time,
				(
					CalendarClock.day_to_iso(int(feedback.stock.first_shortage_day))
					if feedback.stock.has_shortage
					else "YOK"
				)
			]
		)
		_labels.teams.tooltip_text = (
			"İhtiyaç %d / Geç varacak %d" % [feedback.teams.need, feedback.teams.late]
		)
		var arrivals: Array[String] = []
		for shipment: Dictionary in sim.logistics.shipments:
			if (
				shipment.purpose == "crisis"
				and shipment.crisis_id == target.id
				and shipment.kind == "stock"
				and shipment.state == "outbound"
			):
				arrivals.append(
					(
						"%s: %d birim"
						% [CalendarClock.day_to_iso(int(shipment.arrival)), shipment.amount]
					)
				)
		_labels.stock.tooltip_text = (
			"BEKLENEN VARIŞLAR\n"
			+ ("\n".join(arrivals) if not arrivals.is_empty() else "Yolda yardım yok")
		)
	else:
		_labels.day.text = "HEDEF SEÇ" if not sim.crises.active.is_empty() else "AKTİF AFET YOK"
		_labels.effect.text = "KAYNAK SEÇİMİN KORUNUR"
		_labels.teams.text = ""
		_labels.stock.text = ""
	_sync_sources(str(target.get("id", "")))
	var source: int = _view.source_id
	_team.modulate = UI.GOLD if _view.dispatch_kind == "team" else Color.WHITE
	_stock.modulate = UI.GOLD if _view.dispatch_kind == "stock" else Color.WHITE
	var id: String = str(target.get("id", ""))
	var quote := sim.dispatch_preview(
		source, id, _view.dispatch_kind, _view.amount, _view.source_home
	)
	_labels.amount.text = (
		"%d %s" % [_view.amount, "EKİP" if _view.dispatch_kind == "team" else "BİRİM MALZEME"]
	)
	_labels.quote.text = (
		"VARIŞ: %d GÜN\nTAŞIMA BEDELİ: %s%s"
		% [
			quote.get("days", 0),
			_shell.fmt_money(int(quote.get("fee", 0))),
			" / GEÇ VARIŞ" if quote.get("late", false) else ""
		]
	)
	_send.disabled = not bool(quote.get("ok", false))
	_send.tooltip_text = str(quote.get("message", "Hedef seç"))
	_fill.disabled = (
		sim.missing_dispatch_amount(source, id, _view.dispatch_kind, _view.source_home) == 0
	)
	_fill.tooltip_text = "Yoldaki zamanında destek düşülür; kapasite ve bütçeyle sınırlıdır."
	_labels.feedback.text = (
		_view._feedback
		if not _view._feedback.is_empty()
		else "Miktar mevcut kaynak ve bütçeyle sınırlıdır."
	)
	_labels.feedback.tooltip_text = _view._feedback
	if not _view._feedback.is_empty():
		_labels.feedback.add_theme_color_override("font_color", UI.TEAL)
	elif not quote.get("ok", false):
		_labels.feedback.text = str(quote.get("message", "Hedef seç"))
		_labels.feedback.add_theme_color_override("font_color", UI.GOLD)
	_operation.visible = _view.operation_scene_enabled
	_labels.scene_caption.visible = true
	_labels.guide.visible = not _view.operation_scene_enabled
	_operation.set_context(id, int(feedback.get("area_id", 31)))


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
			_target.add_item("MÜDAHALE EDİLECEK AFETİ SEÇ")
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
	if _source.get_popup().visible:
		return
	var options: Array[Dictionary] = _shell.sim.dispatch_options(id, _view.dispatch_kind)
	var signature: String = _view.dispatch_kind + id
	for option: Dictionary in options:
		signature += (
			"%d/%d/%d/%d/%d;"
			% [option.source, option.home, option.available, option.days, option.fee]
		)
	if signature != _source_signature and not _source.get_popup().visible:
		_source_signature = signature
		_source.clear()
		for option: Dictionary in options:
			var title := "%s / %d HAZIR" % [option.name.to_upper(), option.available]
			_source.add_item(title)
			_source.set_item_metadata(
				_source.item_count - 1, {"source": int(option.source), "home": int(option.home)}
			)
			_source.set_item_disabled(_source.item_count - 1, int(option.available) == 0)
			_source.set_item_tooltip(_source.item_count - 1, str(option.message))
	if _view.source_id == 0 and not options.is_empty():
		for option: Dictionary in options:
			if int(option.limit) > 0:
				_view.source_id = int(option.source)
				_view.source_home = int(option.home)
				break
	_source.select(-1)
	for index in range(_source.item_count):
		var group: Dictionary = _source.get_item_metadata(index)
		if (
			int(group.source) == _view.source_id
			and (
				int(group.home)
				== (_view.source_id if _view.source_home == 0 else _view.source_home)
			)
		):
			_source.select(index)
	if _source.selected == -1:
		_source.text = (
			"KAYNAK EKİP GRUBU SEÇ" if _view.dispatch_kind == "team" else "KAYNAK MERKEZ SEÇ"
		)
	_source.disabled = options.is_empty()
	_view.source_index = _shell.sim.areas.keys().find(_view.source_id)


func _choose_target(index: int) -> void:
	var id: String = str(_target.get_item_metadata(index))
	if not id.is_empty():
		_selected_target_id = id
		_view.select_crisis(id)
	_view._feedback = ""
	refresh()


func _choose_source(index: int) -> void:
	var group: Dictionary = _source.get_item_metadata(index)
	_view.source_id = int(group.source)
	_view.source_home = int(group.home)
	_view._feedback = ""
	refresh()


func _set_kind(kind: String) -> void:
	_view.dispatch_kind = kind
	_view.source_home = _view.source_id
	_view.amount = 1 if kind == "team" else 10
	_view._feedback = ""
	refresh()


func _change_amount(delta: int) -> void:
	_view.amount = maxi(1, _view.amount + delta * (1 if _view.dispatch_kind == "team" else 10))
	_view._feedback = ""
	refresh()


func _fill_missing() -> void:
	var id: String = str(_view.selected().get("id", ""))
	_view.amount = maxi(
		1,
		_shell.sim.missing_dispatch_amount(
			_view.source_id, id, _view.dispatch_kind, _view.source_home
		)
	)
	_view._feedback = ""
	refresh()


func _dispatch() -> void:
	_result(
		_shell.sim.dispatch(
			_view.source_id,
			str(_view.selected().get("id", "")),
			_view.dispatch_kind,
			_view.amount,
			_view.source_home
		)
	)


func _result(result: Dictionary) -> void:
	_view._feedback = result.message
	_shell.command_result(result)
	refresh()


func _toggle_time() -> void:
	_shell.sim.set_paused(not _shell.sim.paused)
	refresh()


func _drag(_at: Vector2, kind: String, token: Button) -> Variant:
	var preview := Label.new()
	preview.text = "1 EKİP" if kind == "team" else "10 BİRİM YARDIM MALZEMESİ"
	preview.add_theme_font_override("font", UI.FONT)
	token.set_drag_preview(preview)
	return {
		"tag": "dispatch",
		"source": _view.source_id,
		"home": _view.source_home,
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
				int(data.get("amount", 0)),
				int(data.get("home", 0))
			)
		)
