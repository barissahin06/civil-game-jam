extends Control
## Persistent map order palette; pricing, slots and queue state belong to the model.
const UI := preload("res://ui_preview/shared/ui_kit.gd")
var action_id: String = ""
var _shell: Control
var _actions: Dictionary = {}
var _rows: Dictionary = {}
var _details: Label
var _summary: Label
var _instruction: Label
var _scroll: ScrollContainer
var _list: Control


func setup(shell: Control) -> void:
	_shell = shell
	hide()


func _ready() -> void:
	position = Vector2(16, 174)
	size = Vector2(400, 846)
	mouse_filter = Control.MOUSE_FILTER_STOP
	UI.panel(self, Rect2(Vector2.ZERO, size), true)
	UI.text(self, "HAZIRLIK PLANLA", Rect2(16, 12, 320, 32), 18, UI.GOLD)
	UI.button(self, "×", Rect2(350, 10, 34, 32), close)
	_instruction = _paragraph(
		"BİR EYLEM SEÇ.\nSONRA HARİTADA MERKEZLERE TIKLA.", Rect2(16, 54, 368, 52), UI.INK
	)
	_actions.rescue_team = UI.button(
		self, "EKİP KUR", Rect2(16, 116, 174, 42), select_action.bind("rescue_team")
	)
	_actions.aid_stock = UI.button(
		self, "YARDIM HAZIRLA", Rect2(202, 116, 182, 42), select_action.bind("aid_stock")
	)
	_details = _paragraph("", Rect2(16, 172, 368, 100), UI.GOLD)
	_summary = _paragraph("", Rect2(16, 282, 368, 78), UI.MUTED)
	_summary.mouse_filter = Control.MOUSE_FILTER_PASS
	_scroll = ScrollContainer.new()
	_scroll.position = Vector2(16, 372)
	_scroll.size = Vector2(368, 408)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll)
	_list = Control.new()
	_list.custom_minimum_size = Vector2(344, 0)
	_scroll.add_child(_list)
	UI.text(self, "- SON BEKLEYEN EMRİ KALDIRIR", Rect2(16, 790, 368, 24), 18, UI.MUTED)
	UI.text(self, "ESC / ×: PLANLAMADAN ÇIK", Rect2(16, 816, 368, 24), 18, UI.MUTED)
	hide()


func open() -> void:
	action_id = ""
	show()
	refresh()
	_shell.map_view.refresh()


func close() -> void:
	action_id = ""
	hide()
	_shell.map_view.refresh()


func select_action(id: String) -> void:
	action_id = id
	refresh()
	_shell.map_view.refresh()


func order(area_id: int) -> void:
	if action_id.is_empty():
		_shell.preview_notice("Önce Ekip Kur veya Yardım Hazırla seç.")
		return
	_shell.command_result(_shell.sim.enqueue_preparation(action_id, area_id))


func refresh() -> void:
	if not visible:
		return
	var plan: Dictionary = _shell.sim.preparation_plan()
	_details.text = "EYLEM SEÇİLMEDİ\nHER TIKLAMA BİR HAZIRLIK EMRİ EKLER."
	for action: Dictionary in plan.actions:
		var button: Button = _actions[action.id]
		button.disabled = not action.ok
		button.tooltip_text = action.message
		button.add_theme_stylebox_override(
			"normal", UI.style(Rect2(112 if action_id == action.id else 0, 56, 48, 32))
		)
		if action.id == action_id:
			_details.text = (
				"%s\n%s / %d AY / %s TAKSİT\nBAKIM: %s/AY"
				% [
					String(action.output_title).to_upper(),
					_shell.fmt_money(action.total_cost),
					action.months,
					_shell.fmt_money(action.monthly_cost),
					_shell.fmt_money(action.upkeep)
				]
			)
	_instruction.text = (
		"BİR EYLEM SEÇ.\nSONRA HARİTADA MERKEZLERE TIKLA."
		if action_id.is_empty()
		else "HER TIKLAMA BİR EMİR EKLER.\nDOLU MERKEZDE SIRAYA EKLENİR."
	)
	_summary.text = (
		"AKTİF: %d / SIRADA: %d\nAYLIK PROJE TAKSİTİ: %s\nSIRADAKİ EMİRLER ÜCRET ÖDEMEZ."
		% [
			plan.summary.active_count,
			plan.summary.queued_count,
			_shell.fmt_money(plan.summary.monthly_commitment)
		]
	)
	_summary.tooltip_text = (
		"Aylık taksit, tüm çalışan projeleri kapsar. Bekleyen emirlerin toplam bedeli: "
		+ _shell.fmt_money(plan.summary.queued_cost)
	)
	for index in range(plan.areas.size()):
		var area: Dictionary = plan.areas[index]
		if not _rows.has(area.area_id):
			var row := UI.panel(_list, Rect2(0, index * 124, 344, 116))
			var title := UI.text(row, "", Rect2(8, 4, 238, 26), 18, UI.GOLD)
			var progress := UI.text(row, "", Rect2(250, 4, 86, 26), 18, UI.MUTED)
			var inventory := UI.text(row, "", Rect2(8, 30, 328, 24), 18, UI.MUTED)
			var active := UI.text(row, "", Rect2(8, 54, 328, 26), 18)
			active.mouse_filter = Control.MOUSE_FILTER_PASS
			var queue := UI.text(row, "", Rect2(8, 84, 280, 26), 18, UI.TEAL)
			var undo := UI.button(
				row,
				"-",
				Rect2(300, 82, 36, 28),
				_undo.bind(area.area_id),
				false,
				UI.ButtonTone.DANGER
			)
			_rows[area.area_id] = {
				"title": title,
				"progress": progress,
				"inventory": inventory,
				"active": active,
				"queue": queue,
				"undo": undo,
				"last_uid": 0
			}
		var view: Dictionary = _rows[area.area_id]
		view.title.text = String(area.name).to_upper()
		view.inventory.text = "STOK: %d EKİP / %d YARDIM" % [area.teams, area.stock]
		view.active.text = (
			String(area.active_title).to_upper() if area.busy else "YEREL PROJE SLOTU BOŞ"
		)
		view.progress.text = (
			"%d/%d AY" % [area.active_progress, area.active_months] if area.busy else ""
		)
		view.active.tooltip_text = view.active.text
		if not String(area.queued_blocked_reason).is_empty():
			view.active.tooltip_text += "\n" + String(area.queued_blocked_reason)
			if not area.busy:
				view.active.text = "SIRA BEKLİYOR / ÜZERİNE GEL"
		view.active.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		view.queue.text = "SIRA: %d EKİP / %d YARDIM" % [area.queued_teams, area.queued_stock]
		view.last_uid = area.last_uid
		view.undo.disabled = int(area.last_uid) == 0
		view.undo.tooltip_text = "Bu merkezdeki son bekleyen emri kaldır. Henüz ödeme yapılmadı."
	_list.custom_minimum_size.y = plan.areas.size() * 124


func _undo(area_id: int) -> void:
	_shell.command_result(_shell.sim.cancel_preparation(int(_rows[area_id].last_uid)))


func _paragraph(content: String, box: Rect2, ink: Color) -> Label:
	var label := UI.text(self, content, box, 18, ink)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label
