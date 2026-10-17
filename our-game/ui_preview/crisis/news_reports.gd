extends "res://ui_preview/shared/screen_view.gd"
var report_details: bool = false


func render(content: Control, screen: String) -> void:
	super.render(content, screen)
	if screen == "newspaper":
		_newspaper()
	else:
		_report()


func _newspaper() -> void:
	var sim: Simulation = _shell.sim
	var entry: Dictionary = {}
	if not sim.news_queue.is_empty() and sim.news_queue.front().kind == "newspaper":
		entry = sim.event_for(sim.news_queue.front().id)
	else:
		entry = sim.latest_event()
	_title("YURTTAN HABERLER", "TARİHSEL AFET ARŞİVİ")
	if entry.is_empty():
		_paragraph("KAMPANYADA HENÜZ AFET HABERİ YOK.", Rect2(0, 144, 1300, 80), UI.MUTED)
		return
	var paper := Panel.new()
	paper.position = Vector2(0, 122)
	paper.size = Vector2(1344, 426)
	var style := StyleBoxTexture.new()
	style.texture = preload("res://ui_preview/assets/paper.png")
	style.texture_margin_left = 8
	style.texture_margin_right = 8
	style.texture_margin_top = 8
	style.texture_margin_bottom = 8
	paper.add_theme_stylebox_override("panel", style)
	_content.add_child(paper)
	UI.text(_content, entry.date, Rect2(30, 146, 1268, 32), 18, Color("594d3c"))
	var headline: Label = UI.text(
		_content, entry.name.to_upper(), Rect2(30, 200, 1268, 102), 36, Color("302c27")
	)
	headline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_paragraph(entry.description, Rect2(30, 332, 1250, 170), Color("302c27"))
	UI.button(
		_content,
		"KRİZ MERKEZİNE GEÇ",
		Rect2(850, 600, 494, 52),
		(
			_shell.acknowledge_news
			if not sim.news_queue.is_empty()
			else _shell.show_screen.bind("crisis")
		)
	)


func _report() -> void:
	var sim: Simulation = _shell.sim
	var id := ""
	if not sim.news_queue.is_empty() and sim.news_queue.front().kind == "report":
		id = sim.news_queue.front().id
	var report := sim.report_for(id)
	_title("KRİZ SONRASI RAPOR", "SAYILAR SİMÜLASYON TAHMİNİDİR")
	if report.is_empty():
		_paragraph("HENÜZ TAMAMLANMIŞ MÜDAHALE YOK.", Rect2(0, 144, 1300, 80), UI.MUTED)
		return
	UI.text(
		_content,
		sim.areas[int(report.area_id)].name.to_upper() + " / " + report.name,
		Rect2(0, 104, 1344, 32),
		18,
		UI.GOLD
	)
	for index in range(3):
		var key: String = ["affected", "rescued", "safe"][index]
		_metric(
			["ETKİLENEN", "KURTARILAN", "GÜVENDE OLAN"][index],
			_shell.fmt_count(int(report[key])),
			Rect2(index * 456, 156, 432, 124),
			UI.TEAL
		)
	UI.text(
		_content,
		"Kurtarılanlar etkilenenlerin içindedir, üç sütun toplanmaz.",
		Rect2(0, 302, 1344, 30),
		18,
		UI.MUTED
	)
	_comparison(report)
	UI.text(
		_content,
		(
			"ONARIM TAHMİNİ %s / GÜVEN %+.1f"
			% [_shell.fmt_money(int(report.repair_estimate)), report.trust_delta]
		),
		Rect2(0, 478, 1344, 32),
		18,
		UI.GOLD
	)
	if report_details:
		UI.text(
			_content,
			(
				"CAN KAYBI TAHMİNİ: %s / ÖNLENEN: %s"
				% [
					_shell.fmt_count(int(report.losses)),
					_shell.fmt_count(int(report.prevented_losses))
				]
			),
			Rect2(0, 534, 1344, 32),
			18,
			UI.MUTED
		)
	UI.button(
		_content,
		"AYRINTILAR" if not report_details else "AYRINTILARI GİZLE",
		Rect2(0, 610, 432, 52),
		_details
	)
	UI.button(
		_content, "ONARIMI İNCELE", Rect2(456, 610, 432, 52), _repair.bind(int(report.area_id))
	)
	UI.button(
		_content,
		"RAPORU KAPAT",
		Rect2(912, 610, 432, 52),
		_shell.acknowledge_news if not sim.news_queue.is_empty() else _shell.close_screen
	)


func _comparison(report: Dictionary) -> void:
	_paragraph(
		(
			"TEDBİRSİZ EŞ HESABA GÖRE: %s KİŞİ ETKİLENMEKTEN KORUNDU, %s EK HASAR ÖNLENDİ. AYNI SEVK KARARLARIYLA HESAPLANAN SİMÜLASYON TAHMİNİ."
			% [
				_shell.fmt_count(int(report.protected)),
				_shell.fmt_money(int(report.prevented_damage))
			]
		),
		Rect2(0, 360, 1310, 100),
		UI.INK
	)


func _details() -> void:
	report_details = not report_details
	_shell.refresh_screen()


func _repair(area_id: int) -> void:
	if not _shell.sim.news_queue.is_empty():
		_shell.sim.acknowledge()
	if _shell.sim.news_queue.is_empty():
		_shell.show_project("repair", area_id)
