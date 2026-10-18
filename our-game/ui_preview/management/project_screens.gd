extends "res://ui_preview/shared/screen_view.gd"

const RED := Color("cf9584")
const Copy := preload("res://ui_preview/management/measure_copy.gd")
const EFFECT_LABELS := {
	"protection_earthquake": "Deprem hazırlığı",
	"protection_flood": "Sel hazırlığı",
	"protection_fire": "Yangın hazırlığı",
	"protection_avalanche": "Çığ hazırlığı",
	"protection_landslide": "Heyelan hazırlığı",
	"resilience": "Altyapı dayanıklılığı",
	"rescue_efficiency": "Kurtarma verimi",
	"evacuation": "Tahliye hazırlığı",
	"logistics_efficiency": "Lojistik verimi",
	"trust_decay_reduction": "Halkın güvenini koruma",
	"repair_efficiency": "Onarım verimi",
	"research_capacity": "Araştırma kapasitesi",
	"teams": "Yeni arama kurtarma ekibi",
	"stock": "Yeni yardım malzemesi",
	"damage": "Altyapı hasarı",
	"income": "Aylık gelir",
	"condition": "Merkez kondisyonu",
	"capacity_efficiency": "Ekip ve tesis verimi",
}

var _definition_id: String = "river_zoning"
var _area_id: int = 0
var _priority: bool = false
var _cancel_pending: int = -1
var _scroll_positions: Dictionary = {}
var _return_screen: String = ""
var _return_focus: NodePath
var _detail_history: Array[Dictionary] = []


func render(content: Control, screen: String) -> void:
	super.render(content, screen)
	match screen:
		"project":
			_project()
		"national":
			_national()
		"projects":
			_projects()


func show_project(definition_id: String, area_id: int = 0) -> void:
	var sim: Simulation = _shell.sim
	if sim.projects.definition_for(definition_id) == null:
		_shell.command_result({"ok": false, "message": "Bilinmeyen proje."})
		return
	_definition_id = definition_id
	_area_id = area_id
	_priority = false
	if _shell.open_screen != "project":
		_detail_history.clear()
		_scroll_positions["detail_" + definition_id] = 0
		_return_focus = _shell.screen_focus_path()
		_return_screen = (
			_shell.open_screen if _shell.open_screen in ["projects", "national", "research"] else ""
		)
	_shell.show_screen("project")


func guide_context() -> Dictionary:
	return {"definition_id": _definition_id, "area_id": _area_id}


func _project() -> void:
	var sim: Simulation = _shell.sim
	var definition := sim.projects.definition_for(_definition_id)
	var planned: ActiveProject
	var owner_id := _area_id if definition.is_local() else 0
	for project: ActiveProject in sim.projects.projects:
		if (
			project.definition_id == definition.id
			and project.area_id == owner_id
			and not project.status in ["cancelled", "completed"]
		):
			planned = project
			break
	var quoted_cost := (
		planned.cost_budget if planned != null else sim.projects.cost_for(definition.id, _area_id)
	)
	var installment := (
		sim.projects.installment_for(planned)
		if planned != null
		else sim.projects.monthly_cost_for(definition.id, _area_id)
	)
	var area_name: String = (
		sim.areas[_area_id].name + " ve Çevresi"
		if definition.is_local() and sim.areas.has(_area_id)
		else "ÜLKE GENELİ"
	)
	_title(definition.title.to_upper(), "PROJE AYRINTILARI / " + area_name.to_upper())
	var body := ScrollContainer.new()
	body.name = "ProjectBody"
	body.position = Vector2(0, 92)
	body.size = Vector2(1344, 514)
	body.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.follow_focus = true
	_content.add_child(body)
	var details := Control.new()
	details.name = "Details"
	details.custom_minimum_size = Vector2(1320, 600)
	body.add_child(details)
	var screen_content := _content
	_content = details
	var description := UI.text(
		details, Copy.description_for(definition.id).to_upper(), Rect2(0, 0, 1320, 88), 18, UI.MUTED
	)
	description.name = "Description"
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var total: String = (
		"%d BİLİNÇ PUANI" % definition.cost_awareness
		if definition.kind == "awareness"
		else _shell.fmt_money(quoted_cost)
	)
	_metric("TOPLAM BEDEL", total, Rect2(0, 108, 424, 112), UI.GOLD)
	_metric("TAMAMLANMA", "%d AY" % definition.months, Rect2(448, 108, 424, 112), UI.INK)
	_metric(
		"ÖDEME",
		"PEŞİN" if definition.kind == "awareness" else "AYLIK TAKSİT",
		Rect2(896, 108, 424, 112),
		UI.TEAL
	)
	_project_effects(sim.projects.effect_preview(definition.id, _area_id), 244)
	UI.panel(details, Rect2(916, 244, 404, 250))
	UI.text(details, "AYNI ANDA ÇALIŞAN PROJE", Rect2(936, 260, 364, 30), 18, UI.MUTED)
	var count := sim.projects.active_count(
		(
			"research"
			if definition.is_research()
			else "national" if definition.kind == "national" else "local"
		),
		_area_id
	)
	var capacity := sim.projects.research_capacity if definition.is_research() else 1
	UI.text(
		details,
		"%d/%d %s" % [count, capacity, "ARAŞTIRMA" if definition.is_research() else "UYGULAMA"],
		Rect2(936, 300, 364, 30)
	)
	UI.text(
		details,
		"BAKIM: " + (_shell.fmt_money(definition.upkeep) + "/AY" if definition.upkeep else "YOK"),
		Rect2(936, 342, 364, 28),
		18,
		UI.MUTED
	)
	UI.text(
		details,
		("SONRAKİ TAKSİT: " if planned != null else "İLK TAKSİT: ") + _shell.fmt_money(installment),
		Rect2(936, 382, 364, 28),
		18,
		UI.MUTED
	)
	if not definition.id in ["rescue_team", "aid_stock"]:
		UI.button(
			details,
			"ÖDEME ÖNCELİĞİ: YÜKSEK" if _priority else "ÖDEME ÖNCELİĞİ: NORMAL",
			Rect2(936, 434, 364, 40),
			_toggle_priority,
			_priority
		)
	var gates := sim.projects.requirement_status(definition.id, _area_id, sim.clock.year)
	UI.text(details, "TARİH VE ARAŞTIRMA KOŞULLARI", Rect2(0, 520, 1320, 28), 18, UI.GOLD)
	UI.text(details, "%d YILINDA AÇILIR / %s" % [gates.year, "TARİH KİLİTLİ" if gates.year_locked else "TARİH KOŞULU TAMAM"], Rect2(0, 556, 1320, 28), 18, RED if gates.year_locked else UI.TEAL).name = "YearRequirement"
	var y := 594
	if gates.prerequisites.is_empty():
		UI.text(details, "ARAŞTIRMA ÖNKOŞULU YOK.", Rect2(0, y, 1320, 28), 18, UI.MUTED)
		y += 36
	else:
		UI.text(details, "TÜM ÖNKOŞULLAR GEREKLİDİR.", Rect2(0, y, 1320, 28), 18, UI.MUTED)
		y += 36
		for requirement: Dictionary in gates.prerequisites:
			var link := UI.button(
				details,
				(
					("TAMAM: " if requirement.completed else "GEREKLİ: ")
					+ requirement.title.to_upper()
				),
				Rect2(0, y, 1320, 36),
				_open_research.bind(requirement.id)
			)
			link.name = "Requirement_" + requirement.id
			link.add_theme_color_override("font_color", UI.TEAL if requirement.completed else RED)
			y += 44
	var unlocked := sim.projects.unlocks_for(definition.id)
	if not unlocked.is_empty():
		UI.text(
			details, "BU ARAŞTIRMANIN AÇTIĞI İÇERİKLER", Rect2(0, y + 12, 1320, 28), 18, UI.GOLD
		)
		y += 52
		for next: MeasureDefinition in unlocked:
			var link := UI.button(
				details,
				(
					(
						"ARAŞTIRMA: "
						if next.is_research()
						else "ULUSAL ÖNLEM: " if next.kind == "national" else "YEREL YATIRIM: "
					)
					+ next.title.to_upper()
				),
				Rect2(0, y, 1320, 36),
				_open_related.bind(next.id)
			)
			link.name = "Unlock_" + next.id
			link.tooltip_text = "Diğer tarih ve önkoşulları da karşılamak gerekir."
			y += 44
	details.custom_minimum_size.y = y + 12
	_content = screen_content
	var scroll_key := "detail_" + definition.id
	body.get_v_scroll_bar().value_changed.connect(
		func(value: float) -> void: _scroll_positions[scroll_key] = int(value)
	)
	body.set_deferred("scroll_vertical", int(_scroll_positions.get(scroll_key, 0)))
	var available := sim.projects.availability(definition.id, _area_id, sim.clock.year)
	var status := UI.text(
		_content,
		String(available.message).to_upper(),
		Rect2(0, 612, 910, 28),
		18,
		UI.TEAL if available.ok else RED
	)
	status.name = "Availability"
	status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	status.tooltip_text = available.message
	UI.button(_content, "GERİ", Rect2(0, 648, 260, 36), _back)
	UI.button(_content, "PROJELER", Rect2(280, 648, 300, 36), _shell.show_screen.bind("projects"))
	if definition.id in ["rescue_team", "aid_stock"]:
		_paragraph(
			"HAZIRLIK İŞLERİ İÇİN EKİP VE YARDIM HAZIRLA'YI AÇ.", Rect2(932, 612, 412, 72), UI.MUTED
		)
	else:
		var begin := UI.button(
			_content, "BAŞLAT", Rect2(932, 636, 412, 48), _start, false, UI.ButtonTone.CONFIRM
		)
		begin.disabled = not available.ok
		begin.set_meta("guide_target", "project_start")
		begin.tooltip_text = available.message


func _open_related(id: String) -> void:
	var sim: Simulation = _shell.sim
	var target := sim.projects.definition_for(id)
	_detail_history.append(_detail_context())
	var area: int = _area_id if _area_id != 0 else _shell.selected_area_id
	show_project(id, area if target.is_local() else 0)


func _detail_context() -> Dictionary:
	return {
		"id": _definition_id,
		"area": _area_id,
		"priority": _priority,
		"return_screen": _return_screen,
		"return_focus": _return_focus,
		"screen": _shell.open_screen,
		"focus": _shell.screen_focus_path()
	}


func _open_research(id: String) -> void:
	var context := _detail_context()
	context["history"] = _detail_history.duplicate()
	_shell.research.open_research(id, _restore_context.bind(context))


func _restore_context(context: Dictionary) -> void:
	if context.has("history"):
		_detail_history.assign(context.history)
	_definition_id = context.id
	_area_id = context.area
	_priority = context.priority
	_return_screen = context.return_screen
	_return_focus = context.return_focus
	_shell.show_screen(context.screen)
	_shell.restore_screen_focus(context.focus)


func _back() -> void:
	if not _detail_history.is_empty():
		_restore_context(_detail_history.pop_back())
		return
	if not _return_screen.is_empty():
		_shell.show_screen(_return_screen)
		_shell.restore_screen_focus(_return_focus)
		return
	_shell.close_screen()
	if _area_id != 0:
		_shell.select_area(_area_id)
		_shell.city_panel.select_tab(1)
		_shell.city_panel.restore_investment_focus()


func _project_effects(preview: Dictionary, top: float = 284) -> void:
	UI.text(
		_content, "PROJENİN ETKİLERİ / ŞİMDİ / TAMAMLANINCA", Rect2(0, top, 850, 28), 18, UI.GOLD
	)
	var scope: String = "ULUSAL ORTALAMA" if preview.global else "SEÇİLİ MERKEZ"
	if preview.global and preview.rows.size() == 1 and preview.rows[0].key == "research_capacity":
		scope = "ULUSAL KAPASİTE"
	var note: Label = UI.text(
		_content,
		"%s / BUGÜNKÜ KOŞULLAR / BAKIM %%%d" % [scope, roundi(preview.maintenance_ratio * 100.0)],
		Rect2(0, top + 30, 850, 22),
		18,
		UI.MUTED
	)
	note.mouse_filter = Control.MOUSE_FILTER_PASS
	note.tooltip_text = "Yalnız bu projenin tamamlanması karşılaştırılır. Diğer projeler, gelecekteki afetler ve bakım bütçesindeki değişimler öngörülmez. Beyaz çizgi mevcut değeri, renkli çizgi tamamlanma değerini gösterir. Onarım hasarı her ödenen ayda azaltır."
	var scroll := ScrollContainer.new()
	scroll.name = "ProjectEffects"
	scroll.position = Vector2(0, top + 58)
	scroll.size = Vector2(850, 180)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_content.add_child(scroll)
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 0)
	scroll.add_child(rows)
	for effect: Dictionary in preview.rows:
		var row := Control.new()
		row.name = String(effect.key)
		row.custom_minimum_size = Vector2(824, 62)
		row.mouse_filter = Control.MOUSE_FILTER_PASS
		rows.add_child(row)
		var key: String = effect.key
		var label: String = {"teams": "Toplam ekip", "stock": "Yardım malzemesi"}.get(
			key, EFFECT_LABELS.get(key, key)
		)
		UI.text(row, label.to_upper(), Rect2(0, 0, 360, 24))
		var delta: float = effect.delta
		var tint: Color = UI.MUTED
		if not is_zero_approx(delta):
			tint = UI.TEAL if (delta > 0.0) == bool(effect.higher_is_better) else RED
		var sign: String = "+" if delta > 0.0 else "-" if delta < 0.0 else ""
		var values := (
			"%s / %s (%s%s)"
			% [
				_effect_value(effect.before, effect.unit),
				_effect_value(effect.after, effect.unit),
				sign,
				_effect_value(absf(delta), effect.unit)
			]
		)
		var comparison: Label = UI.text(row, values, Rect2(372, 0, 452, 24), 18, tint)
		comparison.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		UI.text(row, _effect_value(effect.minimum, effect.unit), Rect2(0, 28, 40, 24), 18, UI.MUTED)
		var limit: String = _effect_value(effect.maximum, effect.unit)
		if not effect.bounded:
			limit = "ÖLÇEK " + limit
		var end: Label = UI.text(row, limit, Rect2(674, 28, 150, 24), 18, UI.MUTED)
		end.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.tooltip_text = label + ": " + values + "\nBeyaz: şimdi. Renkli: tamamlanınca."
		if not effect.bounded:
			row.tooltip_text += "\nÇubuğun ölçeği kapasite sınırı değildir."
		var track := Control.new()
		track.position = Vector2(48, 36)
		track.size = Vector2(612, 10)
		track.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(track)
		var scale: float = maxf(1.0, effect.maximum - effect.minimum)
		var current: float = (
			clampf((effect.before - effect.minimum) / scale, 0.0, 1.0) * track.size.x
		)
		var future: float = clampf((effect.after - effect.minimum) / scale, 0.0, 1.0) * track.size.x
		_effect_segment(track, Rect2(0, 0, 612, 10), Color("101e2b"))
		_effect_segment(track, Rect2(0, 0, minf(current, future), 10), UI.MUTED)
		_effect_segment(track, Rect2(minf(current, future), 0, absf(future - current), 10), tint)
		_effect_segment(track, Rect2(future - 1, -8, 2, 26), tint)
		_effect_segment(track, Rect2(current - 1, -6, 2, 22), UI.INK)


func _effect_value(value: float, unit: String) -> String:
	if unit == "money":
		return _shell.fmt_money(roundi(value))
	if unit == "count":
		return str(roundi(value))
	var amount: String = (
		str(roundi(value))
		if is_equal_approx(value, roundf(value))
		else String.num(value, 2).replace(".", ",")
	)
	return amount + ("%" if unit == "percent" else "")


func _effect_segment(parent: Control, box: Rect2, tint: Color) -> void:
	var fill := TextureRect.new()
	fill.texture = UI.atlas(UI.CONTROLS, Rect2(248, 136, 1, 1))
	fill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fill.position = box.position
	fill.size = box.size
	fill.modulate = tint
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(fill)


func _start() -> void:
	var sim: Simulation = _shell.sim
	var result := sim.start_project(_definition_id, _area_id)
	if result.ok and _priority:
		sim.projects.set_priority(result.uid, true)
	_shell.command_result(result)


func _toggle_priority() -> void:
	_priority = not _priority
	_shell.refresh_screen()


func _list(screen: String, count: int, row_height: int) -> Control:
	var scroll := ScrollContainer.new()
	scroll.name = "ProjectList"
	scroll.position = Vector2(0, 108)
	scroll.size = Vector2(1344, 552)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_content.add_child(scroll)
	var rows := Control.new()
	rows.name = "Rows"
	rows.custom_minimum_size = Vector2(1320, count * row_height)
	scroll.add_child(rows)
	scroll.get_v_scroll_bar().value_changed.connect(
		func(value: float) -> void: _scroll_positions[screen] = int(value)
	)
	scroll.set_deferred("scroll_vertical", int(_scroll_positions.get(screen, 0)))
	return rows


func _national() -> void:
	var sim: Simulation = _shell.sim
	_title(
		"ÜLKE GENELİ ÖNLEMLER",
		(
			"AYNI ANDA ÇALIŞAN PROJE: %d/1 / ARAŞTIRMA ADINA TIKLAYARAK AĞA GİT."
			% sim.projects.active_count("national")
		)
	)
	var definitions: Array[MeasureDefinition] = []
	for definition: MeasureDefinition in sim.projects.definitions.values():
		if definition.kind == "national" and not definition.id.begins_with("decision_"):
			definitions.append(definition)
	definitions.sort_custom(
		func(a: MeasureDefinition, b: MeasureDefinition) -> bool: return a.year < b.year
	)
	var rows := _list("national", 1, 0)
	var y := 0
	var last_year := 0
	for definition: MeasureDefinition in definitions:
		if definition.year != last_year:
			last_year = definition.year
			UI.text(rows, "%d / %s" % [last_year, "DÖNEM KİLİTLİ" if last_year > sim.clock.year else "DÖNEM AÇIK"], Rect2(12, y, 1296, 38), 24, UI.MUTED if last_year > sim.clock.year else UI.GOLD).name = (
				"EraTitle%d" % last_year
			)
			y += 48
		var row := UI.panel(rows, Rect2(0, y, 1320, 224), true)
		row.name = definition.id
		UI.text(row, definition.title.to_upper(), Rect2(12, 6, 1110, 28), 18, UI.GOLD)
		UI.text(row, Copy.explanation_for(definition.id).to_upper(), Rect2(12, 38, 1296, 26), 18, UI.MUTED).name = "Explanation"
		var available := sim.projects.availability(definition.id, 0, sim.clock.year)
		var gates := sim.projects.requirement_status(definition.id, 0, sim.clock.year)
		var state := (
			"TAMAMLANDI"
			if sim.projects.is_completed(definition.id)
			else String(available.message).to_upper()
		)
		for project: ActiveProject in sim.projects.projects:
			if (
				project.definition_id == definition.id
				and project.status in ["active", "waiting", "paused", "queued"]
			):
				state = Copy.status_for(project.status)
		UI.text(
			row,
			(
				"%s / %d AY / %s TAKSİT / %s BAKIM"
				% [
					_shell.fmt_money(definition.cost_budget),
					definition.months,
					_shell.fmt_money(sim.projects.monthly_cost_for(definition.id, 0)),
					_shell.fmt_money(definition.upkeep)
				]
			),
			Rect2(12, 70, 1296, 26),
			18
		)
		var status := UI.text(
			row,
			state,
			Rect2(12, 102, 1296, 26),
			18,
			UI.TEAL if available.ok or sim.projects.is_completed(definition.id) else UI.MUTED
		)
		status.name = "State"
		status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		status.tooltip_text = state
		status.mouse_filter = Control.MOUSE_FILTER_PASS
		UI.text(
			row,
			(
				"TÜM ARAŞTIRMA ÖNKOŞULLARI GEREKLİ"
				if gates.prerequisites.size() > 1
				else "ARAŞTIRMA ÖNKOŞULU"
			),
			Rect2(12, 134, 1296, 26),
			18,
			UI.MUTED
		)
		for index: int in range(gates.prerequisites.size()):
			var requirement: Dictionary = gates.prerequisites[index]
			var link := UI.button(
				row,
				("TAMAM: " if requirement.completed else "GEREK: ") + requirement.title.to_upper(),
				Rect2(12 + index * 650, 174, 638, 36),
				_open_research.bind(requirement.id)
			)
			link.name = "Requirement_" + requirement.id
			link.clip_text = true
			link.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			link.tooltip_text = (
				requirement.title
				+ (" / Tamamlandı" if requirement.completed else " / Henüz tamamlanmadı")
			)
			link.add_theme_color_override(
				"font_color", UI.TEAL if requirement.completed else UI.MUTED
			)
		var inspect := UI.button(
			row, "İNCELE", Rect2(1160, 4, 148, 32), show_project.bind(definition.id, 0)
		)
		inspect.name = "Inspect"
		y += 236
	rows.custom_minimum_size.y = y


func _projects() -> void:
	var sim: Simulation = _shell.sim
	var pending: Array[ActiveProject] = []
	for project: ActiveProject in sim.projects.projects:
		if project.status in ["active", "waiting", "paused", "queued"]:
			pending.append(project)
	_title(
		"PROJELER",
		(
			"AYLIK BAKIM %s / VERİM %d%%"
			% [
				_shell.fmt_money(sim.projects.calculate_upkeep()),
				roundi(sim.treasury.maintenance_ratio * 100)
			]
		)
	)
	var rows := _list("projects", pending.size(), 176)
	for index in range(pending.size()):
		var project := pending[index]
		var definition := sim.projects.definition_for(project.definition_id)
		var row := UI.panel(rows, Rect2(0, index * 176, 1320, 168), true)
		row.name = "Project%d" % project.uid
		var area_name: String = (
			sim.areas[project.area_id].name + " ve Çevresi" if project.area_id else "ÜLKE GENELİ"
		)
		var title := UI.text(
			row,
			area_name.to_upper() + " / " + definition.title.to_upper(),
			Rect2(12, 2, 920, 26),
			18,
			UI.GOLD
		)
		title.tooltip_text = title.text
		title.mouse_filter = Control.MOUSE_FILTER_PASS
		var commitment := sim.decisions.commitment_status(project.uid, sim.clock.day)
		var explanation := UI.text(
			row,
			(
				String(commitment.description)
				if commitment.committed
				else Copy.explanation_for(definition.id).to_upper()
			),
			Rect2(12, 34, 1296, 26),
			18,
			RED if commitment.overdue else UI.GOLD if commitment.warned else UI.MUTED
		)
		explanation.name = "Commitment" if commitment.committed else "Explanation"
		explanation.tooltip_text = explanation.text
		var payment: String = (
			"%d BİLİNÇ PUANI PEŞİN" % definition.cost_awareness
			if definition.kind == "awareness"
			else (_shell.fmt_money(sim.projects.installment_for(project)) + " TAKSİT")
		)
		var installment := UI.text(row, payment, Rect2(952, 2, 356, 26), 18, UI.GOLD)
		installment.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		var caption := Copy.status_for(project.status)
		var summary := UI.text(
			row,
			(
				"%s / %d/%d AY / %s ÖDENDİ"
				% [
					caption,
					project.progress_months,
					definition.months,
					_shell.fmt_money(project.paid)
				]
			),
			Rect2(12, 72, 1296, 26),
			18,
			RED if project.status == "waiting" else UI.MUTED
		)
		summary.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		summary.tooltip_text = summary.text
		summary.mouse_filter = Control.MOUSE_FILTER_PASS
		UI.bar(
			row,
			Vector2(12, 108),
			1296,
			float(project.progress_months) / definition.months * 100.0,
			UI.TEAL
		)
		var inspect := UI.button(
			row,
			"İNCELE",
			Rect2(12, 126, 136, 34),
			show_project.bind(definition.id, project.area_id)
		)
		inspect.name = "Inspect"
		var priority := UI.button(
			row,
			"ÖDEME ÖNCELİĞİ: YÜKSEK" if project.priority else "ÖDEME ÖNCELİĞİ: NORMAL",
			Rect2(160, 126, 360, 34),
			_queue_priority.bind(project.uid),
			project.priority
		)
		priority.name = "Priority"
		priority.tooltip_text = "Aylık ödeme önceliği. Şehirde bekleyen işlerin eklenme sırasını değiştirmez."
		var pause := UI.button(
			row,
			"DEVAM ET" if project.status == "paused" else "DURAKLAT",
			Rect2(532, 126, 200, 34),
			_queue_pause.bind(project.uid),
			false,
			UI.ButtonTone.CONFIRM if project.status == "paused" else UI.ButtonTone.CAUTION
		)
		pause.name = "Pause"
		pause.disabled = project.status == "queued"
		var cancel := UI.button(
			row,
			"İPTALİ ONAYLA" if _cancel_pending == project.uid else "İPTAL",
			Rect2(744, 126, 200, 34),
			_queue_cancel.bind(project.uid),
			false,
			UI.ButtonTone.DANGER
		)
		cancel.name = "Cancel"
		cancel.tooltip_text = "İptal için iki kez tıklayın. Ödenen taksitler iade edilmez."
		if commitment.committed:
			cancel.tooltip_text += " Halka verilen sözün iptali güveni bir kez 0,5 azaltır."
		if _cancel_pending == project.uid:
			var warning := UI.text(
				row, "ÖDENEN TAKSİTLER İADE EDİLMEZ.", Rect2(964, 124, 344, 44), 18, RED
			)
			warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if pending.is_empty():
		_paragraph(
			"PROJE YOK. ŞEHİR YATIRIMLARINDAN, ÜLKE GENELİ ÖNLEMLERDEN VEYA ARAŞTIRMALARDAN BAŞLAYIN.",
			Rect2(0, 150, 1250, 100),
			UI.MUTED
		)


func _queue_priority(uid: int) -> void:
	var sim: Simulation = _shell.sim
	var project := sim.projects.get_project(uid)
	if project != null:
		_shell.command_result(sim.projects.set_priority(uid, not project.priority))


func _queue_pause(uid: int) -> void:
	var sim: Simulation = _shell.sim
	var project := sim.projects.get_project(uid)
	if project != null:
		_shell.command_result(
			sim.projects.resume(uid) if project.status == "paused" else sim.projects.pause(uid)
		)


func _queue_cancel(uid: int) -> void:
	var sim: Simulation = _shell.sim
	if _cancel_pending == uid:
		_cancel_pending = -1
		_shell.command_result(sim.cancel_project(uid))
	else:
		_cancel_pending = uid
		_shell.refresh_screen()
