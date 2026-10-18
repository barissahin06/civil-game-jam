extends "res://tests/integration/gameplay_ui.gd"
## All newspaper photographs in an isolated campaign; no player save or preference I/O.

const PHOTOS := preload("res://ui_preview/crisis/news_photos.gd")
const HATIP_DESCRIPTION := "Hatip Çayı'nın taşması sonucu Bentderesi ve çevresindeki yerleşimlerde yıkıcı su baskını."
const CAPTURE_IDS := [
	"historical-003",
	"historical-009",
	"historical-016",
	"historical-029",
	"historical-031",
	"historical-068",
	"historical-081",
	"historical-091",
	"historical-098"
]


func _run() -> void:
	capture_screens = "--capture" in OS.get_cmdline_user_args()
	root.size = Vector2i(1920, 1080)
	root.content_scale_size = root.size
	_main = load("res://ui_preview/scenes/main_preview.tscn").instantiate()
	root.add_child(_main)
	await process_frame
	_shell = _main
	_shell.auto_save_enabled = false
	_shell.sim.tutorial_enabled = false
	await _press_button("GAZETE")
	assert(_shell.open_screen == "newspaper")
	_check_paper()
	assert(_shell._screen_content.find_child("NewspaperPhoto", true, false) == null)
	assert(_label("KAMPANYADA HENÜZ AFET HABERİ YOK.") != null)
	await _capture("newspaper-empty")
	await _press_button("KAPAT")
	_shell.sim.advance_to(CalendarClock.date_to_day("1951-04-08"))
	await process_frame
	await process_frame
	assert(_shell.open_screen == "newspaper" and _shell.sim.news_queue.size() == 1)
	var close: Button = _find_button(_shell._modal, "KAPAT")
	assert(close.disabled, "Unread news must use its crisis CTA instead of being dismissed")
	await _click(close.get_global_rect().get_center())
	assert(_shell.open_screen == "newspaper" and _shell.sim.news_queue.size() == 1)
	_check_photo(_shell.sim.event_for("historical-001"))
	await _capture("newspaper-first-fallback")
	await _press_button("KRİZ MERKEZİNE GEÇ")
	assert(_shell.open_screen == "crisis" and _shell.sim.news_queue.is_empty())
	await _press_button("KAPAT")
	await _press_button("GAZETE")
	assert(_shell.open_screen == "newspaper")
	_check_photo(_shell.sim.latest_event())
	await _capture("newspaper-latest-reopened")
	var fingerprint: String = _shell.sim.content_fingerprint
	var representative: int = 0
	var specific: int = 0
	for entry: Dictionary in _shell.sim.historical.events:
		# Render catalog fixtures without advancing the campaign or changing historical data.
		_shell.sim.news_queue.clear()
		_shell.sim.news_queue.append({"kind": "newspaper", "id": entry.id})
		_shell.show_screen("newspaper")
		await process_frame
		await process_frame
		_check_photo(entry)
		_check_text(_main)
		if PHOTOS.path_for(entry).get_file().begins_with("_fallback_"):
			representative += 1
		else:
			specific += 1
		if entry.id in CAPTURE_IDS:
			await _capture("newspaper-" + entry.id)
	assert(representative == 40 and specific == 59)
	assert(_shell.sim.content_fingerprint == fingerprint)
	await _check_posterization()
	await _capture_font_specimen()
	_shell.sim.news_queue.clear()
	_shell.close_screen()
	await _press_button("GAZETE")
	_check_photo(_shell.sim.event_for("historical-001"))
	await _press_button("KRİZ MERKEZİNE GEÇ")
	assert(_shell.open_screen == "crisis", "Latest newspaper CTA must still accept real input")
	await _shell.audio.shutdown()
	_main.queue_free()
	await process_frame
	print(
		"NEWSPAPER_UI_PASS: centered two-column paper, 99 equal uncropped photo frames (59 specific / 40 representative), seven-tone print shader, empty archive, crisis CTA, latest reopen, Turkish alphabet and punctuation, text bounds; captures=",
		_capture_count
	)
	quit()


func _check_photo(entry: Dictionary) -> void:
	var paper: Panel = _check_paper()
	var text_column: Control = _shell._screen_content.get_node("NewspaperTextColumn")
	var image_column: Control = _shell._screen_content.get_node("NewspaperImageColumn")
	assert(text_column.position == Vector2(40, 192))
	assert(image_column.position == Vector2(744, 192))
	assert(text_column.size == Vector2(656, 500) and image_column.size == text_column.size)
	assert(paper.get_global_rect().encloses(text_column.get_global_rect()))
	assert(paper.get_global_rect().encloses(image_column.get_global_rect()))
	assert(not text_column.get_global_rect().intersects(image_column.get_global_rect()))
	var frame: ColorRect = image_column.get_node("NewspaperPhotoFrame")
	var photo: TextureRect = frame.get_node("NewspaperPhoto")
	var caption: Label = image_column.get_node("NewspaperPhotoCaption")
	assert(
		photo.is_visible_in_tree() and frame.is_visible_in_tree() and caption.is_visible_in_tree()
	)
	assert(photo.texture != null and photo.texture.resource_path == PHOTOS.path_for(entry))
	assert(photo.texture.get_width() > 0 and photo.texture.get_height() > 0)
	assert(photo.expand_mode == TextureRect.EXPAND_IGNORE_SIZE)
	assert(photo.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	assert(frame.size == Vector2(656, 376))
	assert(photo.position == Vector2(8, 8) and photo.size == Vector2(640, 360))
	assert(photo.material is ShaderMaterial)
	var print_material: ShaderMaterial = photo.material
	assert(print_material.shader.resource_path == "res://ui_preview/crisis/newsprint.gdshader")
	assert(photo.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	assert(frame.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	assert(frame.get_global_rect().encloses(photo.get_global_rect()))
	assert(image_column.get_global_rect().encloses(frame.get_global_rect()))
	assert(image_column.get_global_rect().encloses(caption.get_global_rect()))
	assert(not frame.get_global_rect().intersects(caption.get_global_rect()))
	assert(not caption.text.is_empty())
	assert(
		(
			("TEMSİLİ" in caption.text.to_upper())
			== photo.texture.resource_path.get_file().begins_with("_fallback_")
		)
	)
	for text: String in [entry.date, entry.name.to_upper(), entry.description]:
		var label := _label(text)
		assert(label != null, "Newspaper text missing: " + text)
		assert(paper.get_global_rect().encloses(label.get_global_rect()))
		if text != entry.date:
			assert(text_column.get_global_rect().encloses(label.get_global_rect()))
		assert(not label.get_global_rect().intersects(frame.get_global_rect()))
		assert(not label.get_global_rect().intersects(caption.get_global_rect()))
	if entry.id == "historical-081":
		assert(entry.description == HATIP_DESCRIPTION)
		assert(_label(HATIP_DESCRIPTION).text.contains("Çayı'nın"))
		assert(UI.FONT.has_char(39))
	var cta: Button = _find_button(_shell._screen_content, "KRİZ MERKEZİNE GEÇ")
	assert(cta != null and cta.position == Vector2(744, 750))
	assert(cta.size == Vector2(656, 50))
	assert(paper.get_global_rect().encloses(cta.get_global_rect()))
	assert(not image_column.get_global_rect().intersects(cta.get_global_rect()))
	assert(not text_column.get_global_rect().intersects(cta.get_global_rect()))


func _check_paper() -> Panel:
	var content: Control = _shell._screen_content
	var paper: Panel = content.find_child("NewspaperPaper", true, false)
	assert(paper != null and paper.is_visible_in_tree())
	assert(content.size == Vector2(1440, 840) and paper.size == content.size)
	assert(paper.position == Vector2.ZERO)
	assert(paper.get_global_rect().get_center().is_equal_approx(Vector2(root.size) / 2.0))
	assert(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(paper.get_global_rect()))
	var close: Button = _find_button(_shell._modal, "KAPAT")
	assert(close != null and paper.get_global_rect().encloses(close.get_global_rect()))
	return paper


func _check_posterization() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var photo: TextureRect = _shell._screen_content.find_child("NewspaperPhoto", true, false)
	var ramp := Image.create(256, 1, false, Image.FORMAT_RGBA8)
	for x: int in range(256):
		var gray := float(x) / 255.0
		ramp.set_pixel(x, 0, Color(gray, gray, gray))
	var swatch := TextureRect.new()
	swatch.position = Vector2(32, 1024)
	swatch.size = Vector2(256, 24)
	swatch.texture = ImageTexture.create_from_image(ramp)
	swatch.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	swatch.material = photo.material
	swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_main.add_child(swatch)
	await process_frame
	RenderingServer.force_draw(false)
	var picture := root.get_texture().get_image()
	var tones: Array[int] = []
	for x: int in range(256):
		var tone := picture.get_pixel(32 + x, 1036)
		assert(tone.r >= tone.g and tone.g >= tone.b, "Print tones must share warm paper and ink")
		if tone.to_rgba32() not in tones:
			tones.append(tone.to_rgba32())
	assert(tones.size() == 7, "Native photo shader must render seven distinct posterized tones")
	swatch.queue_free()
	await process_frame


func _capture_font_specimen() -> void:
	var specimen := Control.new()
	_main.add_child(specimen)
	UI.panel(specimen, Rect2(120, 220, 1680, 620))
	UI.text(specimen, "TÜRKÇE HARFLER / NOKTALAMA", Rect2(160, 250, 1600, 48), 36)
	var rows: Array[String] = [
		"ABCÇDEFGĞHIİJKLMNOÖPRSŞTUÜVYZ",
		"abcçdefgğhıijklmnoöprsştuüvyz",
		"ÂÎÛ âîû ' ‘ ’ “ ” « » – — … × • ₺"
	]
	for index: int in range(rows.size()):
		UI.text(specimen, rows[index], Rect2(160, 320 + index * 60, 1600, 48), 36)
	var ascii := ""
	for codepoint: int in range(32, 127):
		ascii += String.chr(codepoint)
	UI.text(specimen, ascii, Rect2(160, 520, 1600, 28))
	UI.text(specimen, HATIP_DESCRIPTION, Rect2(160, 580, 1600, 28))
	await _capture("newspaper-font-coverage")
	specimen.queue_free()
	await process_frame


func _label(text: String) -> Label:
	for node: Node in _shell._screen_content.find_children("*", "Label", true, false):
		if node is Label and node.text == text:
			return node
	return null
