extends "res://ui_preview/shared/screen_view.gd"
var crisis_index: int = 0
var source_index: int = 0
var dispatch_kind: String = "team"
var amount: int = 1
var _feedback: String = ""


func render(content: Control, screen: String) -> void:
	super.render(content, screen)
	if screen == "fund":
		_fund()
	else:
		_crisis()


func selected() -> Dictionary:
	var active: Array[Dictionary] = _shell.sim.crises.active
	crisis_index = clampi(crisis_index, 0, maxi(0, active.size() - 1))
	return active[crisis_index] if not active.is_empty() else {}


func _crisis() -> void:
	var sim: Simulation = _shell.sim
	var target := selected()
	_title(
		"KRİZ VE LOJİSTİK",
		"%d AKTİF KRİZ / KAYNAKLARI ORTAK TAKVİMDE PAYLAŞTIR" % sim.crises.active.size()
	)
	if target.is_empty():
		_paragraph(
			"ŞU ANDA AKTİF AFET YOK. EKİP VE YARDIM STOKLARINI ŞEHİR PANELİNDEN HAZIRLAYABİLİRSİN.",
			Rect2(0, 150, 1200, 100),
			UI.MUTED
		)
		_shipments(310)
		return
	var area: ServiceArea = sim.areas[int(target.area_id)]
	var need := sim.crises.requirements(target)
	var card: Panel = UI.panel(_content, Rect2(0, 122, 496, 244), true)
	card.set_drag_forwarding(Callable(), _can_drop, _drop)
	UI.text(_content, area.name.to_upper(), Rect2(20, 140, 452, 48), 36, UI.GOLD)
	UI.text(
		_content,
		(
			"%s / GÜN %d-%d"
			% [
				String(HistoricalCatalog.KIND_NAMES[target.kind]).to_upper(),
				int(target.elapsed) + 1,
				target.window
			]
		),
		Rect2(20, 204, 452, 28)
	)
	UI.text(
		_content,
		"EKİP %d/%d / YARDIM %d/%d" % [target.teams, need.teams, target.stock, need.stock],
		Rect2(20, 254, 452, 28),
		18,
		UI.TEAL
	)
	UI.text(_content, "EKİBİ / YARDIMI BU KARTA BIRAK", Rect2(20, 314, 452, 28), 18, UI.MUTED)
	UI.button(_content, "GERİ", Rect2(0, 382, 64, 38), _change_crisis.bind(-1))
	UI.text(
		_content, "%d / %d" % [crisis_index + 1, sim.crises.active.size()], Rect2(80, 382, 320, 38)
	)
	UI.button(_content, "İLERİ", Rect2(408, 382, 88, 38), _change_crisis.bind(1))
	UI.button(_content, "ACİL BÜTÇE", Rect2(0, 450, 496, 48), _shell.show_screen.bind("fund"))
	var ids: Array = sim.areas.keys()
	source_index = wrapi(source_index, 0, ids.size())
	var source_id: int = ids[source_index]
	var source: ServiceArea = sim.areas[source_id]
	UI.text(_content, "KAYNAK MERKEZ", Rect2(548, 120, 796, 28), 18, UI.MUTED)
	UI.button(_content, "GERİ", Rect2(548, 166, 64, 42), _change_source.bind(-1))
	UI.text(_content, source.name.to_upper(), Rect2(630, 166, 620, 42), 36, UI.GOLD)
	UI.button(_content, "İLERİ", Rect2(1256, 166, 88, 42), _change_source.bind(1))
	var team: Button = UI.button(
		_content,
		"EKİP: %d" % source.teams,
		Rect2(548, 238, 382, 56),
		_set_kind.bind("team"),
		dispatch_kind == "team"
	)
	var stock: Button = UI.button(
		_content,
		"YARDIM: %d" % source.stock,
		Rect2(952, 238, 392, 56),
		_set_kind.bind("stock"),
		dispatch_kind == "stock"
	)
	team.set_drag_forwarding(_drag.bind(source_id, "team", team), Callable(), Callable())
	stock.set_drag_forwarding(_drag.bind(source_id, "stock", stock), Callable(), Callable())
	UI.button(_content, "-", Rect2(548, 330, 64, 42), _change_amount.bind(-1))
	UI.text(_content, "MİKTAR %d" % amount, Rect2(630, 330, 550, 42))
	UI.button(_content, "+", Rect2(1280, 330, 64, 42), _change_amount.bind(1))
	var quote := sim.logistics.quote(source_id, area.id, dispatch_kind, amount)
	UI.text(
		_content,
		(
			"VARIŞ: %d GÜN / TAŞIMA %s"
			% [quote.get("days", 0), _shell.fmt_money(int(quote.get("fee", 0)))]
		),
		Rect2(548, 400, 796, 32),
		18,
		UI.GOLD
	)
	var send: Button = UI.button(
		_content, "SEVK ET", Rect2(548, 456, 796, 52), _dispatch.bind(source_id)
	)
	send.disabled = not bool(quote.ok) or sim.treasury.money < int(quote.get("fee", 0))
	UI.text(_content, _feedback, Rect2(548, 526, 796, 28), 18, UI.TEAL)
	_shipments(570)
	UI.button(_content, "HARİTAYA DÖN", Rect2(0, 624, 496, 42), _shell.close_screen)


func _shipments(y: int) -> void:
	var lines: Array[String] = []
	for shipment: Dictionary in _shell.sim.logistics.shipments:
		if shipment.state in ["outbound", "returning"]:
			lines.append(
				(
					"%s > %s / %d GÜN"
					% [
						_shell.sim.areas[int(shipment.source)].name,
						_shell.sim.areas[int(shipment.target)].name,
						maxi(0, int(shipment.arrival) - _shell.sim.clock.day)
					]
				)
			)
	UI.text(
		_content,
		"YOLDA: " + (" / ".join(lines.slice(0, 2)) if not lines.is_empty() else "SEVKİYAT YOK"),
		Rect2(548, y, 796, 62),
		18,
		UI.MUTED
	)


func _change_crisis(delta: int) -> void:
	crisis_index = wrapi(crisis_index + delta, 0, maxi(1, _shell.sim.crises.active.size()))
	_shell.refresh_screen()


func _change_source(delta: int) -> void:
	source_index = wrapi(source_index + delta, 0, _shell.sim.areas.size())
	_shell.refresh_screen()


func _set_kind(kind: String) -> void:
	dispatch_kind = kind
	amount = 1 if kind == "team" else 10
	_shell.refresh_screen()


func _change_amount(delta: int) -> void:
	amount = maxi(1, amount + delta * (1 if dispatch_kind == "team" else 10))
	_shell.refresh_screen()


func _dispatch(source_id: int) -> void:
	var target := selected()
	if target.is_empty():
		return
	var result: Dictionary = _shell.sim.dispatch(source_id, target.id, dispatch_kind, amount)
	_feedback = result.message
	_shell.command_result(result)


func _drag(_at: Vector2, source_id: int, kind: String, token: Button) -> Variant:
	var label := Label.new()
	label.text = "EKİP" if kind == "team" else "YARDIM"
	label.add_theme_font_override("font", UI.FONT)
	label.add_theme_font_size_override("font_size", 18)
	token.set_drag_preview(label)
	return {
		"tag": "dispatch", "source": source_id, "kind": kind, "amount": 1 if kind == "team" else 10
	}


func _can_drop(_at: Vector2, data: Variant) -> bool:
	return (
		data is Dictionary
		and data.get("tag") == "dispatch"
		and data.get("kind") in ["team", "stock"]
		and _shell.sim.areas.has(int(data.get("source", 0)))
		and not selected().is_empty()
	)


func _drop(at: Vector2, data: Variant) -> void:
	if _can_drop(at, data):
		_shell.command_result(
			_shell.sim.dispatch(
				int(data.source), selected().id, data.kind, int(data.get("amount", 1))
			)
		)


func _fund() -> void:
	var target := selected()
	_title("ACİL BÜTÇE DESTEĞİ", "EKİP VE YARDIMIN VERİMİNİ ARTIRIR / FİZİKSEL KAYNAK GEREKLİDİR")
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
			_pay.bind(value)
		)
		pay.disabled = int(target.funds) + value > 5000000 or _shell.sim.treasury.money < value
	UI.button(_content, "KRİZE DÖN", Rect2(0, 600, 432, 52), _shell.show_screen.bind("crisis"))


func _pay(value: int) -> void:
	_shell.command_result(_shell.sim.fund(selected().id, value))
