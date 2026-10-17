extends "res://ui_preview/shared/screen_view.gd"

const RED := Color("cf9584")
const EFFECT_LABELS := {
	"protection_earthquake": "Deprem hazırlığı",
	"protection_flood": "Sel hazırlığı",
	"protection_fire": "Yangın hazırlığı",
	"protection_avalanche": "Çığ hazırlığı",
	"protection_landslide": "Heyelan hazırlığı",
	"resilience": "Altyapı direnci",
	"rescue_efficiency": "Kurtarma verimi",
	"evacuation": "Tahliye hazırlığı",
	"logistics_efficiency": "Lojistik verimi",
	"trust_decay_reduction": "Güven aşınması azalması",
	"repair_efficiency": "Onarım verimi",
	"research_capacity": "Araştırma slotu",
	"teams": "Yeni arama kurtarma ekibi",
	"stock": "Yeni yardım stoğu",
}

var _definition_id: String = "river_zoning"
var _area_id: int = 0
var _priority: bool = false
var _cancel_pending: int = -1
var _page: int = 0


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
	_shell.show_screen("project")


func _project() -> void:
	var sim: Simulation = _shell.sim
	var definition := sim.projects.definition_for(_definition_id)
	var area_name: String = (
		sim.areas[_area_id].name if definition.is_local() and sim.areas.has(_area_id) else "ULUSAL"
	)
	_title(definition.title.to_upper(), "PROJE AYRINTILARI / " + area_name.to_upper())
	var total: String = (
		"%d BP" % definition.cost_awareness
		if definition.kind == "awareness"
		else _shell.fmt_money(sim.projects.cost_for(definition.id, _area_id))
	)
	_metric("TOPLAM BEDEL", total, Rect2(0, 110, 432, 112), UI.GOLD)
	_metric("TAMAMLANMA", "%d AY" % definition.months, Rect2(456, 110, 432, 112), UI.INK)
	_metric(
		"ÖDEME",
		"BİLİNÇ PEŞİN" if definition.kind == "awareness" else "AYLIK TAKSİT",
		Rect2(912, 110, 432, 112),
		UI.TEAL
	)
	UI.text(_content, "ÇAPRAZ ETKİLER / TAMAMLANINCA AKTİF", Rect2(0, 258, 850, 30), 18, UI.GOLD)
	var row := 0
	for key: String in definition.effects:
		UI.text(
			_content,
			_effect_caption(key, float(definition.effects[key])),
			Rect2(0, 302 + row * 30, 850, 26),
			18,
			UI.INK
		)
		row += 1
	if definition.kind == "repair":
		_paragraph(
			"HASAR VE GELİR KAYBI HER ÖDENEN AYDA AZALIR. BEDEL BAŞLANGIÇ HASARINDAN HESAPLANIR.",
			Rect2(0, 302, 850, 100),
			UI.INK
		)
	UI.text(_content, "AÇILIŞ YILI: %d" % definition.year, Rect2(0, 504, 850, 28), 18, UI.MUTED)
	var available := sim.projects.availability(definition.id, _area_id, sim.clock.year)
	_paragraph(
		String(available.message).to_upper(),
		Rect2(0, 542, 850, 44),
		UI.TEAL if available.ok else RED
	)
	UI.panel(_content, Rect2(932, 268, 412, 250))
	UI.text(_content, "PROJE KAPASİTESİ", Rect2(952, 286, 370, 30), 18, UI.MUTED)
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
		_content,
		"%d/%d %s" % [count, capacity, "ARAŞTIRMA" if definition.is_research() else "UYGULAMA"],
		Rect2(952, 330, 370, 30)
	)
	UI.text(
		_content,
		"BAKIM: " + (_shell.fmt_money(definition.upkeep) + "/AY" if definition.upkeep else "YOK"),
		Rect2(952, 378, 370, 28),
		18,
		UI.MUTED
	)
	UI.text(
		_content,
		"İLK TAKSİT: " + _shell.fmt_money(sim.projects.monthly_cost_for(definition.id, _area_id)),
		Rect2(952, 414, 370, 28),
		18,
		UI.MUTED
	)
	UI.button(
		_content,
		"ÖNCELİKLİ" if _priority else "NORMAL ÖNCELİK",
		Rect2(952, 458, 370, 40),
		_toggle_priority,
		_priority
	)
	var begin := UI.button(_content, "BAŞLAT", Rect2(932, 620, 412, 48), _start)
	begin.disabled = not available.ok
	begin.tooltip_text = available.message
	UI.button(
		_content,
		"GERİ",
		Rect2(0, 620, 260, 48),
		(
			_shell.show_screen.bind("research" if definition.is_research() else "national")
			if not definition.is_local()
			else _shell.close_screen
		)
	)
	UI.button(
		_content, "PROJE TAKİBİ", Rect2(300, 620, 412, 48), _shell.show_screen.bind("projects")
	)


func _effect_caption(key: String, amount: float) -> String:
	var fraction := (
		key
		in [
			"rescue_efficiency",
			"evacuation",
			"logistics_efficiency",
			"trust_decay_reduction",
			"repair_efficiency"
		]
	)
	var value := "+%d%%" % roundi(amount * 100.0) if fraction else "+%d" % roundi(amount)
	return "%s: %s" % [String(EFFECT_LABELS.get(key, key)).to_upper(), value]


func _start() -> void:
	var sim: Simulation = _shell.sim
	var result := sim.start_project(_definition_id, _area_id)
	if result.ok and _priority:
		sim.projects.set_priority(result.uid, true)
	_shell.command_result(result)


func _toggle_priority() -> void:
	_priority = not _priority
	_shell.refresh_screen()


func _national() -> void:
	var sim: Simulation = _shell.sim
	_title("ULUSAL TEDBİRLER", "AKTİF PROJE: %d/1" % sim.projects.active_count("national"))
	var index := 0
	for definition: MeasureDefinition in sim.projects.definitions.values():
		if definition.kind != "national":
			continue
		var x := index * 456
		UI.panel(_content, Rect2(x, 122, 418, 388), true)
		UI.icon(_content, 6 if index != 1 else 3, Vector2(x + 18, 144), UI.GOLD)
		UI.text(_content, definition.title.to_upper(), Rect2(x + 18, 202, 382, 32), 18, UI.GOLD)
		var effects: Array[String] = []
		for key: String in definition.effects:
			effects.append(_effect_caption(key, float(definition.effects[key])))
		_paragraph("\n".join(effects), Rect2(x + 18, 254, 380, 104), UI.INK)
		UI.text(
			_content,
			"%s / %d AY" % [_shell.fmt_money(definition.cost_budget), definition.months],
			Rect2(x + 18, 364, 380, 30)
		)
		UI.text(
			_content,
			(
				"TAMAMLANDI"
				if sim.projects.is_completed(definition.id)
				else "%d DÖNEMİ" % definition.year
			),
			Rect2(x + 18, 410, 380, 28),
			18,
			UI.MUTED
		)
		UI.button(
			_content, "İNCELE", Rect2(x + 18, 460, 382, 36), show_project.bind(definition.id, 0)
		)
		index += 1
	UI.button(
		_content,
		"ARAŞTIRMA AĞACINI AÇ",
		Rect2(0, 614, 480, 46),
		_shell.show_screen.bind("research")
	)


func _projects() -> void:
	var sim: Simulation = _shell.sim
	var pending: Array[ActiveProject] = []
	for project: ActiveProject in sim.projects.projects:
		if project.status in ["active", "waiting", "paused"]:
			pending.append(project)
	_title(
		"PROJE TAKİBİ",
		(
			"AYLIK BAKIM %s / VERİM %d%%"
			% [
				_shell.fmt_money(sim.projects.calculate_upkeep()),
				roundi(sim.treasury.maintenance_ratio * 100)
			]
		)
	)
	var last_page := maxi(0, int((pending.size() - 1) / 3))
	_page = clampi(_page, 0, last_page)
	for row: int in range(3):
		var index := _page * 3 + row
		if index >= pending.size():
			break
		var project := pending[index]
		var definition := sim.projects.definition_for(project.definition_id)
		var y := 108 + row * 160
		var area_name: String = sim.areas[project.area_id].name if project.area_id else "ULUSAL"
		UI.panel(_content, Rect2(0, y, 1344, 146), true)
		UI.text(
			_content,
			area_name.to_upper() + " / " + definition.title.to_upper(),
			Rect2(18, y + 12, 1060, 30),
			18,
			UI.GOLD
		)
		UI.text(
			_content,
			"%d / %d AY" % [project.progress_months, definition.months],
			Rect2(1130, y + 12, 190, 30),
			18,
			UI.MUTED
		)
		UI.bar(
			_content,
			Vector2(18, y + 62),
			684,
			float(project.progress_months) / definition.months * 100.0,
			UI.TEAL
		)
		var caption: String = {
			"active": "DEVAM EDİYOR", "waiting": "BÜTÇE BEKLİYOR", "paused": "DURAKLATILDI"
		}[project.status]
		UI.text(
			_content,
			caption,
			Rect2(18, y + 86, 720, 26),
			18,
			RED if project.status == "waiting" else UI.MUTED
		)
		UI.text(
			_content,
			"ÖDENEN: " + _shell.fmt_money(project.paid),
			Rect2(18, y + 114, 720, 24),
			18,
			UI.MUTED
		)
		UI.button(
			_content,
			"ÖNCELİKLİ" if project.priority else "NORMAL",
			Rect2(754, y + 66, 182, 42),
			_queue_priority.bind(project.uid),
			project.priority
		)
		UI.button(
			_content,
			"DEVAM ET" if project.status == "paused" else "DURAKLAT",
			Rect2(950, y + 66, 182, 42),
			_queue_pause.bind(project.uid)
		)
		var cancel := UI.button(
			_content,
			"ONAYLA" if _cancel_pending == project.uid else "İPTAL",
			Rect2(1146, y + 66, 182, 42),
			_queue_cancel.bind(project.uid)
		)
		cancel.tooltip_text = "İptal için iki kez tıklayın. Ödenen taksitler iade edilmez."
	if pending.is_empty():
		_paragraph(
			"AKTİF PROJE YOK. ŞEHİR YATIRIMLARINDAN, ULUSAL TEDBİRLERDEN VEYA ARAŞTIRMA AĞACINDAN BAŞLAYIN.",
			Rect2(0, 150, 1250, 100),
			UI.MUTED
		)
	UI.button(_content, "GERİ", Rect2(0, 620, 80, 40), _change_page.bind(-1)).disabled = _page == 0
	UI.text(
		_content,
		"%d / %d SAYFA / %d PROJE" % [_page + 1, last_page + 1, pending.size()],
		Rect2(114, 628, 900, 28),
		18,
		UI.MUTED
	)
	UI.button(_content, "İLERİ", Rect2(1264, 620, 80, 40), _change_page.bind(1)).disabled = (
		_page == last_page
	)


func _change_page(offset: int) -> void:
	_page += offset
	_shell.refresh_screen()


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
		_shell.command_result(sim.projects.cancel(uid))
	else:
		_cancel_pending = uid
		_shell.refresh_screen()
