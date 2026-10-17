extends "res://ui_preview/shared/screen_view.gd"
## Slot decisions belong here; SaveStore validates bytes and the shell adopts campaigns.

const RED := Color("cf9584")

var mode: String = "load"
var pending_slot: int = -1
var notice: String = ""
var _notice_error: bool = false


func open(requested_mode: String) -> void:
	if not requested_mode in ["save", "load"]:
		return
	mode = requested_mode
	pending_slot = -1
	notice = ""
	_notice_error = false
	_shell.show_screen(mode)


func render(content: Control, screen: String) -> void:
	super.render(content, screen)
	mode = screen
	_title(
		"OYUNU KAYDET" if mode == "save" else "KAYIT YÜKLE", "BİR OTOMATİK KAYIT / ÜÇ MANUEL KAYIT"
	)
	for summary: Dictionary in _shell.saves.slot_summaries():
		_slot_row(summary)
	if pending_slot >= 0:
		var prompt := (
			"MANUEL KAYIT %d üzerine yazılsın mı? Önceki kayıt değişecek." % pending_slot
			if mode == "save"
			else "Kayıt yüklensin mi? Kaydedilmemiş ilerleme değişecek."
		)
		_paragraph(prompt, Rect2(0, 548, 1344, 56), UI.GOLD)
		UI.button(_content, "VAZGEÇ", Rect2(720, 624, 240, 48), _cancel_confirmation)
		UI.button(
			_content,
			"ÜZERİNE YAZ" if mode == "save" else "ONAYLA: YÜKLE",
			Rect2(1024, 624, 320, 48),
			_execute.bind(pending_slot)
		)
	elif not notice.is_empty():
		_paragraph(notice, Rect2(0, 548, 1344, 56), RED if _notice_error else UI.TEAL)
	elif mode == "save":
		_paragraph(
			"Otomatik kayıt oyun tarafından güncellenir. Manuel kayıt için bir yuva seç.",
			Rect2(0, 548, 1344, 56),
			UI.MUTED
		)
	UI.button(_content, "GERİ", Rect2(0, 624, 240, 48), _shell.close_screen)


func _slot_row(summary: Dictionary) -> void:
	var slot: int = summary.slot
	var y := 112 + slot * 108
	UI.panel(_content, Rect2(0, y, 1344, 96), true)
	UI.text(_content, summary.label, Rect2(18, y + 7, 960, 26), 18, UI.GOLD)
	if bool(summary.valid):
		UI.text(
			_content,
			"Oyun tarihi: %s / Başlangıç: %d" % [summary.game_date, summary.start_year],
			Rect2(18, y + 34, 960, 26)
		)
		var updated: String = (
			Time.get_datetime_string_from_unix_time(int(summary.saved_at)).replace("T", " ")
			if int(summary.saved_at) > 0
			else "Bilinmiyor"
		)
		UI.text(
			_content, "Kayıt zamanı: %s UTC" % updated, Rect2(18, y + 61, 960, 26), 18, UI.MUTED
		)
	elif bool(summary.exists):
		_paragraph(str(summary.error), Rect2(18, y + 36, 970, 54), RED)
	else:
		UI.text(_content, "Boş kayıt yuvası", Rect2(18, y + 36, 970, 28), 18, UI.MUTED)
	var title: String = "OTOMATİK YÜKLE" if slot == 0 else "MANUEL %d YÜKLE" % slot
	if mode == "save":
		title = "OTOMATİK" if slot == 0 else "MANUEL %d KAYDET" % slot
	var action: Button = UI.button(
		_content, title, Rect2(1032, y + 24, 294, 48), _request.bind(slot)
	)
	action.disabled = (mode == "save" and slot == 0) or (mode == "load" and not summary.valid)


func _request(slot: int) -> void:
	var summaries: Array[Dictionary] = _shell.saves.slot_summaries()
	if slot < 0 or slot >= summaries.size() or (mode == "save" and slot == 0):
		return
	var summary: Dictionary = summaries[slot]
	if mode == "load" and not bool(summary.valid):
		notice = str(summary.error) if bool(summary.exists) else "Bu kayıt yuvası boş."
		_notice_error = true
		_shell.refresh_screen()
		return
	if (mode == "save" and bool(summary.exists)) or (mode == "load" and not _shell.in_frontend):
		pending_slot = slot
		notice = ""
		_shell.refresh_screen()
		return
	_execute(slot)


func _execute(slot: int) -> void:
	pending_slot = -1
	var result: Dictionary = (
		_shell.save_campaign_slot(slot) if mode == "save" else _shell.load_campaign_slot(slot)
	)
	notice = str(result.get("message", ""))
	_notice_error = not bool(result.get("ok", false))
	if mode == "save" or _notice_error:
		_shell.refresh_screen()


func _cancel_confirmation() -> void:
	pending_slot = -1
	notice = ""
	_shell.refresh_screen()
