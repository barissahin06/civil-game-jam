extends "res://ui_preview/shared/screen_view.gd"

const RED := Color("cf9584")

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
		"ending":
			_ending(false)
		"defeat":
			_ending(true)


func _menu() -> void:
	UI.text(_content, "REWRITE IT", Rect2(0, 0, 520, 90), 72, UI.INK)
	UI.text(_content, "TARİHSEL AFET STRATEJİSİ", Rect2(0, 104, 520, 28), 18, UI.GOLD)
	_line(Rect2(0, 146, 500, 2), UI.GOLD)
	var automatic: Dictionary = _shell.saves.slot_summaries()[0]
	var resume: Button = UI.button(
		_content, "KAYITTAN DEVAM ET", Rect2(0, 188, 500, 52), _shell.continue_campaign
	)
	resume.disabled = not bool(automatic.valid)
	resume.tooltip_text = "Son otomatik kayıt" if automatic.valid else "Geçerli otomatik kayıt yok."
	UI.button(_content, "YENİ OYUN", Rect2(0, 258, 500, 52), _shell.show_screen.bind("newgame"))
	UI.button(_content, "YÜKLE", Rect2(0, 328, 500, 52), _shell.save_slots.open.bind("load"))
	UI.button(_content, "AYARLAR", Rect2(0, 398, 500, 52), _shell.show_screen.bind("settings"))
	UI.button(_content, "KISA REHBER", Rect2(0, 468, 500, 52), _open_tutorial)
	UI.button(_content, "ÇIKIŞ", Rect2(0, 538, 500, 52), _shell.get_tree().quit)


func _settings() -> void:
	_title("AYARLAR")
	var fullscreen := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	UI.button(
		_content,
		"TAM EKRAN: " + ("AÇIK" if fullscreen else "KAPALI"),
		Rect2(0, 148, 650, 60),
		_shell.toggle_fullscreen
	)
	UI.text(_content, "F11 KISAYOLUYLA TAM EKRANI DEĞİŞTİR", Rect2(0, 222, 960, 28), 18, UI.MUTED)
	_shake_setting(Rect2(0, 300, 650, 60))
	_paragraph(
		"Sarsıntı kapalıyken kırmızı afet vurgusu görünmeye devam eder.",
		Rect2(0, 382, 1100, 70),
		UI.MUTED
	)
	UI.button(_content, "GERİ", Rect2(0, 600, 432, 52), _shell.close_screen)


func _pause() -> void:
	var title: Label = UI.text(_content, "OYUN DURAKLATILDI", Rect2(0, 0, 560, 48), 36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.button(_content, "DEVAM ET", Rect2(0, 140, 560, 60), _shell.close_screen)
	UI.button(_content, "KAYDET", Rect2(0, 230, 560, 60), _shell.save_slots.open.bind("save"))
	UI.button(_content, "YÜKLE", Rect2(0, 320, 560, 60), _shell.save_slots.open.bind("load"))
	UI.button(_content, "AYARLAR", Rect2(0, 410, 560, 60), _shell.show_screen.bind("settings"))
	UI.button(_content, "KISA REHBER", Rect2(0, 500, 560, 60), _open_tutorial)
	UI.button(_content, "ANA MENÜYE DÖN", Rect2(0, 590, 560, 60), _shell.return_to_main_menu)


func _shake_setting(rect: Rect2) -> void:
	var shake: Button = UI.button(
		_content,
		"HARİTA SARSINTISI: " + ("AÇIK" if _shell.map_shake_enabled else "KAPALI"),
		rect,
		_shell.toggle_map_shake,
		_shell.map_shake_enabled
	)
	shake.tooltip_text = "Yalnız harita sarsılır. Kapatıldığında kısa kırmızı afet uyarısı korunur."


func _open_tutorial() -> void:
	tutorial_step = 0
	_shell.show_screen("tutorial")


func _newgame() -> void:
	_title("YENİ KAMPANYA", "BAŞLANGIÇ YILINI SEÇ / HER KAMPANYA 2026 SONUNDA BİTER")
	UI.panel(_content, Rect2(0, 120, 650, 188), true)
	UI.text(_content, "TARİHSEL", Rect2(24, 142, 580, 36), 36, UI.GOLD)
	_paragraph(
		"GERÇEK AFET TARİHLERİ. DÖNEME UYGUN BAŞLANGIÇ EKONOMİSİ VE HAZIRLIK.",
		Rect2(24, 210, 590, 80),
		UI.INK
	)
	var sandbox: Button = UI.button(
		_content, "SANDBOX / KİLİTLİ", Rect2(694, 120, 650, 188), Callable()
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
		"ONAYLA: YENİ KAMPANYA" if replace_confirmed else "KAMPANYAYI AÇ",
		Rect2(850, 600, 494, 52),
		_start_campaign
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
	tutorial_step = 0
	_shell.show_screen("tutorial")


func _ending(defeat: bool) -> void:
	_title(
		"ULUSAL GÜVEN TÜKENDİ" if defeat else "KAMPANYA TAMAMLANDI",
		(
			"ERKEN YENİLGİ / MÜDAHALE DEĞERLENDİRMESİ"
			if defeat
			else "31 ARALIK 2026 / KAMPANYA PERFORMANSI"
		)
	)
	if defeat:
		_metric("ULUSAL GÜVEN", "0 / 100", Rect2(0, 144, 650, 124), RED)
		_paragraph(
			"GECİKEN MÜDAHALELER VE KARŞILANAMAYAN İHTİYAÇLAR GÜVENİ TÜKETTİ. YENİ KAMPANYADA HAZIRLIK, EKİP DAĞILIMI VE ÖDEME ÖNCELİKLERİNİ DEĞERLENDİR.",
			Rect2(0, 324, 1100, 180),
			UI.INK
		)
	else:
		for index in range(3):
			var title: String = ["HAZIRLIK", "MÜDAHALE", "TOPARLANMA"][index]
			var scores: Dictionary = _shell.sim.scores()
			var value: int = scores[["preparation", "response", "recovery"][index]]
			_metric(title, "%d / 100" % value, Rect2(index * 456, 144, 432, 124), UI.TEAL)
			UI.bar(_content, Vector2(index * 456 + 20, 300), 392, value, UI.TEAL)
		_paragraph(
			"KORUYUCU TEDBİRLER, ZAMANINDA MÜDAHALE VE ONARIM BİRBİRİNİ TAMAMLADI. BAŞARIN HER BAŞLIKTA AYRI DEĞERLENDİRİLİR.",
			Rect2(0, 382, 1200, 130),
			UI.INK
		)
	UI.button(_content, "ANA MENÜ", Rect2(912, 600, 432, 54), _shell.return_to_main_menu)


func _tutorial() -> void:
	_title("İLK ADIMLAR", "KISA REHBER / İSTEDİĞİN ZAMAN ATLAYABİLİRSİN")
	var titles := [
		"1 / BİR ŞEHİR SEÇ",
		"2 / YEREL YATIRIM PLANLA",
		"3 / ARAŞTIRMAYI İNCELE",
		"4 / İLK SEVKİYATI PLANLA"
	]
	var descriptions := [
		"HARİTADAKİ İL SINIRINA TIKLA. SOLDA NÜFUS, GELİR, ALTYAPI VE HAZIRLIĞI İNCELE.",
		"ŞEHİR PANELİNDE YATIRIM SEKMESİNE GEÇ. BEDELİ, AYLIK TAKSİTİ VE TAMAMLANMA SÜRESİNİ KARŞILAŞTIR.",
		"TEKNİK ARAŞTIRMALAR VE BİLİNÇ GELİŞTİRMELERİ ORTAK ARAŞTIRMA KAPASİTESİNİ KULLANIR. ÖNKOŞULLARI VE AÇILIŞ YILLARINI İNCELE.",
		"KRİZDE KAYNAK MERKEZİ SEÇ. EKİBİ HEDEF KARTA SÜRÜKLE VEYA SEVK ET DÜĞMESİNİ KULLAN. VARIŞ GÜNÜNE DİKKAT ET."
	]
	UI.text(_content, titles[tutorial_step], Rect2(0, 144, 1300, 54), 36, UI.GOLD)
	_paragraph(descriptions[tutorial_step], Rect2(0, 256, 1120, 170), UI.INK)
	UI.text(_content, "%d / 4" % (tutorial_step + 1), Rect2(0, 484, 500, 36), 18, UI.MUTED)
	UI.button(_content, "REHBERİ ATLA", Rect2(0, 600, 432, 54), _skip_tutorial)
	var finish_label: String = "ANA MENÜYE DÖN" if _shell.in_frontend else "HARİTAYA GEÇ"
	UI.button(
		_content,
		finish_label if tutorial_step == 3 else "İLERİ",
		Rect2(912, 600, 432, 54),
		_next_tutorial
	)


func _next_tutorial() -> void:
	if tutorial_step == 3:
		_shell.close_screen()
	else:
		tutorial_step += 1
		_shell.refresh_screen()


func _skip_tutorial() -> void:
	_shell.sim.tutorial_enabled = false
	_shell.sim.changed.emit()
	_shell.close_screen()
