extends "res://ui_preview/shared/screen_view.gd"
## Campaign facts are frozen before deleting saves; this view only tells their story.

const PHOTOS := preload("res://ui_preview/crisis/news_photos.gd")
const NEWSPRINT := preload("res://ui_preview/crisis/newsprint.gdshader")
const INK := Color("302c27")
const MUTED := Color("76674f")
const PAGE_TITLES := ["BİR DÖNEMİN ARDINDAN", "AFETLER", "BIRAKILAN MİRAS"]

var summary: Dictionary = {}
var notice: String = ""
var page: int = 0
var _scrolls: Dictionary = {}
var _cancel: Button


func reset() -> void:
	summary = {}
	notice = ""
	page = 0
	_scrolls.clear()


func open(snapshot: Dictionary) -> void:
	reset()
	summary = snapshot


func render(content: Control, screen: String) -> void:
	super.render(content, screen)
	if screen == "finish_confirm":
		_confirmation()
		return
	_paper()
	var reason: String = summary.get("reason", "voluntary")
	var heading: String = (
		{
			"voluntary": "GÖREVİ DEVRETTİN",
			"ending": "2026 / KAMPANYA TAMAMLANDI",
			"defeat": "HALKIN GÜVENİ TÜKENDİ"
		}
		. get(reason, "KAMPANYA SONA ERDİ")
	)
	UI.text(_content, heading, Rect2(40, 24, 900, 28), 18, MUTED)
	var dates := UI.text(
		_content,
		"%s / %s" % [summary.start_date, summary.end_date],
		Rect2(920, 24, 480, 28),
		18,
		MUTED
	)
	dates.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var masthead := UI.text(_content, "BİR DÖNEMİN ARDINDAN", Rect2(40, 66, 1360, 48), 36, INK)
	masthead.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_line(Rect2(40, 128, 1360, 3), INK)
	for index in range(PAGE_TITLES.size()):
		UI.button(
			_content,
			PAGE_TITLES[index],
			Rect2(40 + index * 460, 152, 440, 36),
			_select_page.bind(index),
			page == index
		)
	if page == 0:
		_front_page()
	else:
		_details()
	var note := (
		UI
		. text(
			_content,
			"Sayılar olay bazlı simülasyon tahminidir; aynı kişi birden fazla afette yer alabilir. Önlemlerin toplam etkisi hesaplanır; tek bir projeye ayrı başarı yüklenmez.",
			Rect2(40, 674, 1360, 50),
			18,
			MUTED
		)
	)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_line(Rect2(40, 736, 1360, 2), MUTED)
	UI.text(
		_content,
		"ÖZEL SAYI / %d - %d" % [page + 1, PAGE_TITLES.size()],
		Rect2(40, 762, 620, 28),
		18,
		MUTED
	)
	UI.button(_content, "ANA MENÜYE DÖN", Rect2(920, 756, 480, 50), _shell.return_to_main_menu)


func _confirmation() -> void:
	_title("OYUNU BİTİRMEK İSTİYOR MUSUN?", "BU İŞLEM GERİ ALINAMAZ")
	_paragraph(
		"Oyun şu anki tarihte sona erecek. Atlatılan afetleri, tamamladığın önlemleri, kurtarma sonuçlarını ve önlenen kayıp/hasar tahminlerini anlatan kapanış gazetesi açılacak. Devam eden afetler ve yarım kalan işler ayrı gösterilecek. Gazeteden ana menüye dönebileceksin.",
		Rect2(0, 128, 1280, 148),
		UI.INK
	)
	_paragraph(
		"Otomatik kayıt ve üç manuel kayıt yuvasının TAMAMI kalıcı olarak silinecek. Başka oyunlara ait manuel kayıtlar da silinir. Bu oyuna kayıttan dönemezsin.",
		Rect2(0, 312, 1280, 112),
		Color("cf9584")
	)
	if not notice.is_empty():
		_paragraph(notice, Rect2(0, 448, 1280, 104), Color("cf9584"))
	_cancel = UI.button(_content, "VAZGEÇ", Rect2(0, 604, 300, 52), _shell.cancel_campaign_finish)
	_cancel.name = "CancelFinish"
	UI.button(
		_content,
		"KAYITLARI SİL VE BİTİR",
		Rect2(732, 604, 612, 52),
		_shell.confirm_campaign_finish,
		false,
		UI.ButtonTone.DANGER
	)


func focus_cancel() -> void:
	if is_instance_valid(_cancel) and _cancel.is_inside_tree():
		_cancel.grab_focus()


func _paper() -> void:
	var paper := Panel.new()
	paper.name = "EndingPaper"
	paper.size = Vector2(1440, 840)
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxTexture.new()
	style.texture = preload("res://ui_preview/assets/paper.png")
	style.texture_margin_left = 8
	style.texture_margin_right = 8
	style.texture_margin_top = 8
	style.texture_margin_bottom = 8
	paper.add_theme_stylebox_override("panel", style)
	_content.add_child(paper)


func _front_page() -> void:
	var story := UI.text(_content, _story(), Rect2(40, 208, 656, 448), 18, INK)
	story.name = "EndingStory"
	story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_line(Rect2(720, 208, 1, 448), MUTED)
	var entry: Dictionary = summary.photo_event
	if not entry.is_empty():
		var photo := TextureRect.new()
		photo.name = "EndingPhoto"
		photo.position = Vector2(744, 208)
		photo.size = Vector2(656, 300)
		photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		photo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		photo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var material := ShaderMaterial.new()
		material.shader = NEWSPRINT
		photo.material = material
		var path := PHOTOS.path_for(entry)
		if not path.is_empty():
			photo.texture = load(path)
		_content.add_child(photo)
	else:
		_paragraph(
			"Her hazırlık, henüz yaşanmamış bir gün için bırakılan bir umuttur.",
			Rect2(768, 280, 600, 110),
			MUTED
		)
	var totals: Dictionary = summary.totals
	UI.text(
		_content,
		"%d AFET / %d TAMAMLANAN MÜDAHALE" % [summary.event_count, summary.completed_event_count],
		Rect2(744, 532, 656, 28),
		18,
		INK
	)
	UI.text(
		_content, "%s KURTARMA TAHMİNİ" % _count(totals.rescued), Rect2(744, 564, 656, 28), 18, INK
	)
	UI.text(
		_content, "%s KORUNMA TAHMİNİ" % _count(totals.protected), Rect2(744, 596, 656, 28), 18, INK
	)
	UI.text(
		_content,
		(
			"HAZIRLIK %d / MÜDAHALE %d / TOPARLANMA %d"
			% [summary.scores.preparation, summary.scores.response, summary.scores.recovery]
		),
		Rect2(744, 628, 656, 28),
		18,
		MUTED
	)


func _story() -> String:
	var totals: Dictionary = summary.totals
	var paragraphs: Array[String] = []
	if summary.event_count == 0:
		(
			paragraphs
			. append(
				"Bu görevde henüz bir afetle sınanmadın. Yine de hazırlığa ayrılan zaman, geleceğe bırakılan bir sözdür."
			)
		)
	else:
		(
			paragraphs
			. append(
				(
					"Bu yıllara dönüp bakınca, zor günlerde verilen emeğin izleri kalıyor. %d afet yaşandı; %d afetin müdahalesi tamamlandı."
					% [summary.event_count, summary.completed_event_count]
				)
			)
		)
	if int(totals.rescued) > 0 or int(totals.protected) > 0:
		(
			paragraphs
			. append(
				(
					"Tamamlanan müdahalelerde %s kurtarma, hazırlıkların toplam etkisiyle %s korunma tahmin edildi. Önlemler sayesinde önlenen kayıp %s, hasar karşılığı %s oldu."
					% [
						_count(totals.rescued),
						_count(totals.protected),
						_count(totals.prevented_losses),
						_shell.fmt_money(int(totals.prevented_damage))
					]
				)
			)
		)
	else:
		(
			paragraphs
			. append(
				"Tamamlanan raporlarda henüz bir kurtarma ya da korunma kazanımı görünmüyor. Hazırlık, zamanında destek ve yeterli ikmalin birlikte düşünülmesi gerekiyor."
			)
		)
	var completed: Array = summary.completed_projects
	if completed.is_empty():
		(
			paragraphs
			. append(
				"Yeni bir çalışma tamamlanmadan görev sona erdi. Dönemin hazır altyapısı bu değerlendirmede senin yaptığın bir yatırım sayılmadı."
			)
		)
	else:
		var names: Array[String] = []
		for index in range(mini(1, completed.size())):
			names.append(str(completed[index].title))
		(
			paragraphs
			. append(
				(
					"Geride bıraktığın çalışmalar arasında %s var. Tamamlanan her hazırlık, bir sonraki zor güne daha güçlü girmek için atılmış bir adım oldu."
					% " ve ".join(names)
				)
			)
		)
	var closing := ""
	if int(totals.losses) > 0:
		closing = (
			"%s tahmini can kaybının hatırası da bu dönemin bir parçası. " % _count(totals.losses)
		)
	if int(summary.active_event_count) > 0 or not summary.unfinished_projects.is_empty():
		closing += (
			"%d afette müdahale, %d işte çalışma sürüyordu. Bitmeyen işler başarı sayılmadı; sayılar yalnız sonuçlanan merkez raporlarını kapsıyor."
			% [summary.active_event_count, _project_count(summary.unfinished_projects)]
		)
	elif summary.reason == "defeat":
		closing += "Halkın güveni tükendi ve görev sona erdi. Bu deneyim, bir sonraki başlangıçta daha sağlam kararların yolunu açabilir."
	else:
		closing += "Bu sayfa kapanırken geriye yalnız sayılar değil, hazırlığın ve dayanışmanın geleceğe taşıdığı deneyim kalıyor."
	paragraphs.append(closing)
	return "\n\n".join(paragraphs)


func _details() -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "EndingList"
	scroll.position = Vector2(40, 208)
	scroll.size = Vector2(1360, 448)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_content.add_child(scroll)
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 22)
	scroll.add_child(rows)
	if page == 1:
		if summary.events.is_empty():
			_row(rows, "Bu görev süresinde henüz afet yaşanmadı.")
		for event: Dictionary in summary.events:
			var status := "MÜDAHALE SÜRÜYOR" if event.active else "MÜDAHALE TAMAMLANDI"
			_row(
				rows,
				(
					"%s / %s / %s\n%s kurtarma, %s korunma; %s kayıp ve %s hasar önlendi. Tahmini can kaybı: %s.%s"
					% [
						event.date,
						event.name,
						status,
						_count(event.rescued),
						_count(event.protected),
						_count(event.prevented_losses),
						_shell.fmt_money(int(event.prevented_damage)),
						_count(event.losses),
						(
							" Sayılar yalnız sonuçlanan merkez raporlarını kapsar."
							if event.active
							else ""
						)
					]
				)
			)
	else:
		_row(rows, "TAMAMLANAN ÇALIŞMALAR")
		_project_rows(rows, summary.completed_projects, "Bu görevde yeni bir çalışma tamamlanmadı.")
		_row(rows, "YARIM KALAN ÇALIŞMALAR / BAŞARI SAYILMAZ")
		_project_rows(rows, summary.unfinished_projects, "Yarım kalan çalışma yok.")
	scroll.set_deferred("scroll_vertical", int(_scrolls.get(page, 0)))


func _project_rows(rows: VBoxContainer, records: Array, empty_text: String) -> void:
	if records.is_empty():
		_row(rows, empty_text)
	var statuses := {
		"active": "Devam ediyor",
		"waiting": "Ödeme bekliyor",
		"paused": "Duraklatıldı",
		"queued": "Sırada"
	}
	for record: Dictionary in records:
		var status: String = statuses.get(record.get("status", "completed"), "Tamamlandı")
		_row(
			rows,
			"%s / %s / %d çalışma / %s" % [record.title, record.area_name, record.count, status]
		)


func _row(parent: VBoxContainer, value: String) -> void:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("font_color", INK)
	parent.add_child(label)


func _select_page(index: int) -> void:
	var list := _content.get_node_or_null("EndingList") as ScrollContainer
	if list != null:
		_scrolls[page] = list.scroll_vertical
	page = index
	_shell.refresh_screen()


func _count(value: Variant) -> String:
	return _shell.fmt_count(int(value))


func _project_count(records: Array) -> int:
	var count := 0
	for record: Dictionary in records:
		count += int(record.count)
	return count
