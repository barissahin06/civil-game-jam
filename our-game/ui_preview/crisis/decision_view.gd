extends "res://ui_preview/shared/screen_view.gd"

const INK := Color("302c27")
const MUTED_INK := Color("76674f")
const POSITIVE_INK := Color("28613f")
const NEGATIVE_INK := Color("9b3830")
var selected_card: String = ""
var selected_option: String = ""


func render(content: Control, screen: String) -> void:
	super.render(content, screen)
	var sim: Simulation = _shell.sim
	if sim.news_queue.is_empty() or sim.news_queue.front().kind != "decision":
		return
	var card := sim.decisions.preview(sim.news_queue.front().id)
	if card.is_empty():
		return
	if selected_card != card.id:
		selected_card = card.id
		selected_option = ""
	var paper := Panel.new()
	paper.name = "DecisionPaper"
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
	UI.text(
		_content,
		"GELECEK AFETLER İÇİN ÖNLEM SEÇ / " + String(card.scope).to_upper(),
		Rect2(40, 24, 1360, 28),
		18,
		MUTED_INK
	)
	_body(_content, card.title, Rect2(40, 66, 1360, 70), INK, 28)
	_body(_content, card.description, Rect2(40, 146, 1360, 60), INK)
	_body(
		_content,
		"TARİHSEL BİLGİ: " + String(card.historical_note),
		Rect2(40, 218, 1360, 84),
		MUTED_INK
	)
	_line(Rect2(40, 316, 1360, 2), MUTED_INK)
	for index in range(card.options.size()):
		var option: Dictionary = card.options[index]
		var y := 332 + index * 116
		var title := _body(_content, option.title, Rect2(40, y, 244, 100), INK)
		title.name = "DecisionTitle_" + String(option.id)
		title.scroll_active = false
		title.tooltip_text = option.description
		var details := _body(_content, "", Rect2(300, y, 876, 100), INK)
		details.name = "DecisionDetails_" + String(option.id)
		details.bbcode_enabled = true
		details.text = _option_text(option)
		details.scroll_active = false
		var select: Button = UI.button(
			_content,
			"SEÇİLDİ" if selected_option == option.id else "BU SEÇENEĞİ SEÇ",
			Rect2(1192, y + 24, 208, 44),
			_select.bind(String(option.id)),
			selected_option == option.id
		)
		select.name = "DecisionOption_" + String(option.id)
		if index < card.options.size() - 1:
			_line(Rect2(40, y + 108, 1360, 1), MUTED_INK)
	_body(
		_content,
		"Tamamlamak güven puanı vermez; hazırlık ve sahadaki sonuçlar değerlendirilir. Seçim halka taahhüttür.\nİlerleme olmazsa 6 ayda uyarı, 12 aydan itibaren güven kaybı; iptal güveni bir kez 0,5 azaltır.",
		Rect2(40, 694, 1360, 46),
		MUTED_INK,
		16
	)
	_line(Rect2(40, 746, 1360, 2), MUTED_INK)
	_body(
		_content,
		"Seçim oyun boyunca kalıcıdır. Projeyi iptal etmek diğer seçenekleri açmaz.",
		Rect2(40, 764, 860, 54),
		INK
	)
	var confirm: Button = UI.button(
		_content, "SEÇİMİ ONAYLA", Rect2(940, 764, 460, 48), _confirm, false, UI.ButtonTone.DANGER
	)
	confirm.name = "DecisionConfirm"
	confirm.disabled = selected_option.is_empty()


func _option_text(option: Dictionary) -> String:
	if String(option.project_id).is_empty():
		var trust := (
			(
				"[color=#%s]halkın güveni %s[/color]"
				% [NEGATIVE_INK.to_html(false), ("%+.1f" % option.trust_change).replace(".", ",")]
			)
			if option.trust_change < 0
			else "[color=#%s]halkın güveni değişmez[/color]" % MUTED_INK.to_html(false)
		)
		return (
			(
				"[color=#%s]+ Avantaj: yeni harcama, bakım ve proje taahhüdü yok.[/color]\n"
				% POSITIVE_INK.to_html(false)
			)
			+ (
				"[color=#%s]- Kayıp: yeni koruma/kapasite yok;[/color] %s.\n"
				% [NEGATIVE_INK.to_html(false), trust]
			)
			+ String(option.description)
		)
	var gains: Array[String] = []
	for effect: Dictionary in option.effects.rows:
		var key := String(effect.key)
		var label: String = (
			String(HistoricalCatalog.KIND_NAMES[key.trim_prefix("protection_")]) + " hazırlığı"
			if key.begins_with("protection_")
			else (
				{
					"resilience": "Altyapı dayanıklılığı",
					"teams": "Kurtarma ekibi",
					"stock": "Yardım malzemesi",
					"evacuation": "Tahliye bonusu",
					"rescue_efficiency": "Kurtarma verimi",
					"logistics_efficiency": "Lojistik verimi",
					"repair_efficiency": "Onarım verimi",
					"trust_decay_reduction": "Güven aşınması koruması"
				}
				. get(key, key)
			)
		)
		var unit := (
			" puan"
			if effect.unit == "points"
			else " yüzde puan" if effect.unit == "percent" else ""
		)
		var tint := MUTED_INK
		if not is_zero_approx(effect.delta):
			tint = POSITIVE_INK if (effect.delta > 0) == effect.higher_is_better else NEGATIVE_INK
		gains.append(
			(
				"[color=#%s]%s %s%s[/color]"
				% [
					tint.to_html(false),
					label,
					(
						("%+.1f" % effect.delta).replace(".", ",")
						if key != "teams"
						else "%+d" % effect.delta
					),
					unit
				]
			)
		)
		if key == "teams":
			gains.append("[color=#%s]sel hazırlığı artmaz[/color]" % NEGATIVE_INK.to_html(false))
	var upkeep := (
		(
			"[color=#%s]%s/ay bakım[/color]"
			% [NEGATIVE_INK.to_html(false), _shell.fmt_money(int(option.upkeep))]
		)
		if int(option.upkeep) > 0
		else "bakım yok"
	)
	return (
		"+ Proje bitince kazanım: "
		+ "; ".join(gains)
		+ ".\n"
		+ (
			"[color=#%s]- Bedel: %s toplam[/color]; %s.\n"
			% [NEGATIVE_INK.to_html(false), _shell.fmt_money(int(option.cost_budget)), upkeep]
		)
		+ (
			"%d ay; %s/ay taksit; %s proje %s."
			% [
				option.months,
				_shell.fmt_money(int(option.installment)),
				"ulusal" if option.effects.get("global", false) else "yerel",
				"sırada bekler" if option.queued else "hemen başlar"
			]
		)
	)


func _body(
	parent: Control, text: String, box: Rect2, tint: Color, font_size: int = 18
) -> RichTextLabel:
	var body := RichTextLabel.new()
	body.position = box.position
	body.size = box.size
	body.text = text
	body.add_theme_font_override("normal_font", UI.FONT)
	body.add_theme_font_size_override("normal_font_size", font_size)
	body.add_theme_color_override("default_color", tint)
	body.scroll_active = true
	body.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(body)
	return body


func _select(option_id: String) -> void:
	selected_option = option_id
	_shell.refresh_screen()


func _confirm() -> void:
	var result: Dictionary = _shell.sim.choose_decision(selected_card, selected_option)
	_shell.command_result(result)
	if result.ok:
		selected_option = ""
		if _shell.sim.news_queue.is_empty():
			_shell.close_screen()
		else:
			_shell.show_screen(_shell.sim.news_queue.front().kind)
