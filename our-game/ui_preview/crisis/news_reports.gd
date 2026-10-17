extends "res://ui_preview/shared/screen_view.gd"
const PHOTOS := preload("res://ui_preview/crisis/news_photos.gd")
const NEWSPRINT := preload("res://ui_preview/crisis/newsprint.gdshader")
const NEWSPAPER_SIZE := Vector2(1440, 840)
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
	var paper := Panel.new()
	paper.name = "NewspaperPaper"
	paper.size = NEWSPAPER_SIZE
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxTexture.new()
	style.texture = preload("res://ui_preview/assets/paper.png")
	style.texture_margin_left = 8
	style.texture_margin_right = 8
	style.texture_margin_top = 8
	style.texture_margin_bottom = 8
	paper.add_theme_stylebox_override("panel", style)
	_content.add_child(paper)
	var ink := Color("302c27")
	var muted := Color("76674f")
	UI.text(_content, "TARİHSEL AFET ARŞİVİ", Rect2(40, 26, 700, 28), 18, muted)
	var masthead := UI.text(_content, "YURTTAN HABERLER", Rect2(40, 66, 1360, 48), 36, ink)
	masthead.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_line(Rect2(40, 136, 1360, 4), ink)
	_line(Rect2(40, 144, 1360, 1), muted)
	if entry.is_empty():
		_paragraph("KAMPANYADA HENÜZ AFET HABERİ YOK.", Rect2(40, 220, 1360, 80), ink)
		return
	var date := UI.text(_content, entry.date, Rect2(950, 26, 320, 28), 18, muted)
	date.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var text_column := Control.new()
	text_column.name = "NewspaperTextColumn"
	text_column.position = Vector2(40, 192)
	text_column.size = Vector2(656, 500)
	text_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(text_column)
	var image_column := Control.new()
	image_column.name = "NewspaperImageColumn"
	image_column.position = Vector2(744, 192)
	image_column.size = text_column.size
	image_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(image_column)
	_line(Rect2(720, 192, 1, 500), muted)
	UI.text(
		text_column,
		String(HistoricalCatalog.KIND_NAMES[entry.kind]).to_upper(),
		Rect2(0, 0, 656, 28),
		18,
		muted
	)
	var headline: Label = UI.text(
		text_column, entry.name.to_upper(), Rect2(0, 40, 656, 144), 36, ink
	)
	headline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	headline.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	var description := UI.text(text_column, entry.description, Rect2(0, 210, 656, 260), 18, ink)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	var photo_path: String = PHOTOS.path_for(entry)
	var frame := ColorRect.new()
	frame.name = "NewspaperPhotoFrame"
	frame.size = Vector2(656, 376)
	frame.color = Color("cdbf98")
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image_column.add_child(frame)
	var photo := TextureRect.new()
	photo.name = "NewspaperPhoto"
	photo.position = Vector2(8, 8)
	photo.size = Vector2(640, 360)
	photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	photo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var print_material := ShaderMaterial.new()
	print_material.shader = NEWSPRINT
	photo.material = print_material
	if not photo_path.is_empty():
		photo.texture = load(photo_path)
	frame.add_child(photo)
	var caption := "GÖRSEL BULUNAMADI."
	if not photo_path.is_empty():
		caption = (
			"AYNI AFET TÜRÜNDEN TEMSİLİ GÖRSEL"
			if photo_path.get_file().begins_with("_fallback_")
			else "HABER GÖRSELİ"
		)
	var photo_caption := UI.text(image_column, caption, Rect2(0, 394, 656, 60), 18, muted)
	photo_caption.name = "NewspaperPhotoCaption"
	photo_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	photo.tooltip_text = entry.name + "\n" + caption
	_line(Rect2(40, 720, 1360, 2), muted)
	UI.button(
		_content,
		"KRİZ MERKEZİNE GEÇ",
		Rect2(744, 750, 656, 50),
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
	var explanation := sim.report_feedback(report)
	for index in range(3):
		var key: String = ["preparation_summary", "response_summary", "recovery_summary"][index]
		_paragraph(str(explanation[key]), Rect2(0, 144 + index * 42, 1344, 40), UI.INK)
	for index in range(3):
		var key: String = ["affected", "rescued", "safe"][index]
		_metric(
			["ETKİLENEN", "KURTARILAN", "GÜVENDE OLAN"][index],
			_shell.fmt_count(int(report[key])),
			Rect2(index * 456, 278, 432, 124),
			UI.TEAL
		)
	UI.text(
		_content,
		"Kurtarılanlar etkilenenlerin içindedir, üç sütun toplanmaz.",
		Rect2(0, 410, 1344, 30),
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
		Rect2(0, 524, 1344, 32),
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
			Rect2(0, 566, 1344, 32),
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
		Rect2(0, 448, 1310, 70),
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
