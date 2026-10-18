extends "res://ui_preview/shared/screen_view.gd"

const RED := Color("cf9584")
const AUDIO_CONTROLS := preload("res://ui_preview/campaign/audio_controls.gd")

var start_year: int = 1950
var tutorial_step: int = 0
var replace_confirmed: bool = false


func render(content: Control, screen: String) -> void:
	super.render(content, screen)
	match screen:
		"menu":
			_menu()
		"pause":
			_pause()
		"settings":
			_settings()
		"newgame":
			_newgame()
		"tutorial":
			_tutorial()


func _menu() -> void:
	UI.text(_content, "REWRITE IT", Rect2(0, 0, 520, 90), 72, UI.INK)
	UI.text(_content, "TARİHSEL AFET STRATEJİSİ", Rect2(0, 104, 520, 28), 18, UI.GOLD)
	_line(Rect2(0, 146, 500, 2), UI.GOLD)
	var automatic: Dictionary = _shell.saves.slot_summaries()[0]
	var resume: Button = UI.button(
		_content,
		"KAYITTAN DEVAM ET",
		Rect2(0, 188, 500, 52),
		_shell.continue_campaign,
		false,
		UI.ButtonTone.CONFIRM
	)
	resume.disabled = not bool(automatic.valid)
	resume.tooltip_text = "Son otomatik kayıt" if automatic.valid else "Geçerli otomatik kayıt yok."
	UI.button(_content, "YENİ OYUN", Rect2(0, 258, 500, 52), _shell.show_screen.bind("newgame"))
	UI.button(_content, "YÜKLE", Rect2(0, 328, 500, 52), _shell.save_slots.open.bind("load"))
	UI.button(_content, "AYARLAR", Rect2(0, 398, 500, 52), _shell.show_screen.bind("settings"))
	UI.button(_content, "KISA REHBER", Rect2(0, 468, 500, 52), _open_tutorial)
	UI.button(
		_content, "ÇIKIŞ", Rect2(0, 538, 500, 52), _shell.quit_game, false, UI.ButtonTone.DANGER
	)


func _settings() -> void:
	_title("AYARLAR")
	UI.text(_content, "GÖRÜNTÜ MODU", Rect2(0, 116, 960, 28), 18, UI.MUTED)
	var ids: Array[String] = ["fullscreen", "borderless", "windowed"]
	var titles: Array[String] = ["TAM EKRAN", "KENARLIKSIZ TAM EKRAN", "PENCERE"]
	for index in range(ids.size()):
		UI.button(
			_content,
			titles[index],
			Rect2(index * 304, 160, 288, 52),
			_shell.set_display_mode.bind(ids[index]),
			_shell.display.current_mode() == ids[index]
		)
	UI.text(
		_content, "F11: PENCERE / SEÇTİĞİN TAM EKRAN MODU", Rect2(0, 232, 1100, 28), 18, UI.MUTED
	)
	var audio_controls := AUDIO_CONTROLS.new()
	audio_controls.position = Vector2(0, 300)
	audio_controls.size = Vector2(650, 264)
	_content.add_child(audio_controls)
	audio_controls.setup(_shell.audio)
	_shake_setting(Rect2(720, 300, 624, 52))
	_paragraph(
		"Sarsıntı kapalıyken kırmızı afet vurgusu görünmeye devam eder.",
		Rect2(720, 382, 624, 100),
		UI.MUTED
	)
	UI.button(_content, "GERİ", Rect2(0, 600, 432, 52), _shell.close_screen)


func _pause() -> void:
	var title: Label = UI.text(_content, "OYUN DURAKLATILDI", Rect2(0, 0, 560, 48), 36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.button(
		_content,
		"DEVAM ET",
		Rect2(0, 100, 560, 52),
		_shell.close_screen,
		false,
		UI.ButtonTone.CONFIRM
	)
	UI.button(_content, "KAYDET", Rect2(0, 182, 560, 52), _shell.save_slots.open.bind("save"))
	UI.button(_content, "YÜKLE", Rect2(0, 264, 560, 52), _shell.save_slots.open.bind("load"))
	UI.button(_content, "AYARLAR", Rect2(0, 346, 560, 52), _shell.show_screen.bind("settings"))
	UI.button(_content, "KISA REHBER", Rect2(0, 428, 560, 52), _open_tutorial)
	UI.button(
		_content,
		"ANA MENÜYE DÖN",
		Rect2(0, 510, 560, 52),
		_shell.return_to_main_menu,
		false,
		UI.ButtonTone.CAUTION
	)
	UI.button(
		_content,
		"OYUNU BİTİR",
		Rect2(0, 592, 560, 52),
		_shell.request_campaign_finish,
		false,
		UI.ButtonTone.DANGER
	)


func _shake_setting(rect: Rect2) -> void:
	var shake: Button = UI.button(
		_content,
		"AFET SARSINTISI: " + ("AÇIK" if _shell.map_shake_enabled else "KAPALI"),
		rect,
		_shell.toggle_map_shake,
		_shell.map_shake_enabled
	)
	shake.tooltip_text = "Yeni afet başladığında harita ve HUD kısa süre sarsılır. Kapatıldığında kırmızı afet bölgesi ve kısa kırmızı uyarı korunur."


func _open_tutorial() -> void:
	tutorial_step = 0
	_shell.show_screen("tutorial")


func _newgame() -> void:
	_title("YENİ OYUN", "BAŞLANGIÇ YILINI SEÇ / HER OYUN 2026 SONUNDA BİTER")
	UI.panel(_content, Rect2(0, 120, 650, 188), true)
	UI.text(_content, "TARİHSEL", Rect2(24, 142, 580, 36), 36, UI.GOLD)
	_paragraph(
		"GERÇEK AFET TARİHLERİ. DÖNEME UYGUN BAŞLANGIÇ EKONOMİSİ VE HAZIRLIK.",
		Rect2(24, 210, 590, 80),
		UI.INK
	)
	var sandbox: Button = UI.button(
		_content, "SERBEST OYUN / HENÜZ KULLANILAMIYOR", Rect2(694, 120, 650, 188), Callable()
	)
	sandbox.disabled = true
	sandbox.tooltip_text = "Henüz kullanılamıyor."
	UI.text(_content, "BAŞLANGIÇ YILI", Rect2(0, 366, 600, 30), 18, UI.MUTED)
	var previous: Button = UI.button(_content, "-", Rect2(0, 420, 60, 52), _change_year.bind(-1))
	previous.disabled = start_year == 1950
	UI.text(_content, str(start_year), Rect2(90, 418, 180, 56), 36, UI.GOLD)
	var next: Button = UI.button(_content, "+", Rect2(290, 420, 60, 52), _change_year.bind(1))
	next.disabled = start_year == 1990
	UI.text(_content, "1950 - 1990", Rect2(400, 432, 400, 30), 18, UI.MUTED)
	UI.text(_content, "01 OCAK %d  /  31 ARALIK 2026" % start_year, Rect2(0, 516, 1260, 32))
	UI.button(
		_content,
		"OTOMATİK KAYDIN YERİNE BAŞLAT" if replace_confirmed else "YENİ OYUNU BAŞLAT",
		Rect2(810, 600, 534, 52),
		_start_campaign,
		false,
		UI.ButtonTone.DANGER if replace_confirmed else UI.ButtonTone.CONFIRM
	)
	if replace_confirmed:
		UI.text(
			_content,
			"Otomatik kayıt değişecek. Üç manuel kayıt yuvası korunur.",
			Rect2(0, 558, 1344, 28),
			18,
			RED
		)
	UI.button(_content, "GERİ", Rect2(0, 600, 260, 52), _shell.show_screen.bind("menu"))


func _change_year(delta: int) -> void:
	start_year = clampi(start_year + delta, 1950, 1990)
	_shell.refresh_screen()


func _start_campaign() -> void:
	if FileAccess.file_exists(_shell.saves.slot_path(0)) and not replace_confirmed:
		replace_confirmed = true
		_shell.refresh_screen()
		return
	replace_confirmed = false
	_shell.start_campaign(start_year)


func _tutorial() -> void:
	_title("OYUN REHBERİ", "GENEL BAKIŞ / UYGULAMALI DERSLER KAMPANYANIN İÇİNDE AÇILIR")
	var titles := [
		"1 / BİR ŞEHİR SEÇ",
		"2 / YEREL YATIRIM PLANLA",
		"3 / ARAŞTIRMAYI İNCELE",
		"4 / İLK GÖNDERİMİ HAZIRLA"
	]
	var descriptions := [
		"HARİTADAKİ İL SINIRINA TIKLA. SOLDA NÜFUS, GELİR, ALTYAPI VE HAZIRLIĞI İNCELE.",
		"ŞEHİR PANELİNDE YATIRIM SEKMESİNE GEÇ. BEDELİ, AYLIK TAKSİTİ VE TAMAMLANMA SÜRESİNİ KARŞILAŞTIR.",
		"YATIRIM VE ARAŞTIRMA > ARAŞTIRMALAR SEKMESİNİ AÇ. TEKNİK ARAŞTIRMALAR VE BİLİNÇ GELİŞTİRMELERİ ORTAK KAPASİTEYİ KULLANIR. EKİP VE YARDIM MALZEMESİ İÇİN EKİP VE YARDIM HAZIRLA'YI KULLAN.",
		"KRİZDE KAYNAK MERKEZİ SEÇ. EKİBİ HEDEF KARTA SÜRÜKLE VEYA GÖNDERİMİ ONAYLA DÜĞMESİNİ KULLAN. VARIŞ GÜNÜNE DİKKAT ET."
	]
	UI.text(_content, titles[tutorial_step], Rect2(0, 144, 1300, 54), 36, UI.GOLD)
	_paragraph(descriptions[tutorial_step], Rect2(0, 256, 1120, 170), UI.INK)
	UI.text(_content, "%d / 4" % (tutorial_step + 1), Rect2(0, 484, 500, 36), 18, UI.MUTED)
	UI.button(_content, "GENEL BAKIŞI KAPAT", Rect2(0, 600, 432, 54), _shell.close_screen)
	if not _shell.in_frontend:
		UI.button(_content, "REHBERE DEVAM ET", Rect2(456, 600, 432, 54), _shell.resume_guide)
	var finish_label: String = "ANA MENÜYE DÖN" if _shell.in_frontend else "HARİTAYA GEÇ"
	UI.button(
		_content,
		finish_label if tutorial_step == 3 else "İLERİ",
		Rect2(912, 600, 432, 54),
		_next_tutorial,
		false,
		(
			UI.ButtonTone.CONFIRM
			if tutorial_step == 3 and not _shell.in_frontend
			else UI.ButtonTone.NEUTRAL
		)
	)


func _next_tutorial() -> void:
	if tutorial_step == 3:
		_shell.close_screen()
	else:
		tutorial_step += 1
		_shell.refresh_screen()
