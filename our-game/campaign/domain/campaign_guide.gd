class_name CampaignGuide
extends RefCounted

const BASE_STEPS := [
	"intro",
	"city",
	"zoom",
	"overlay",
	"investment",
	"research",
	"teams",
	"stock",
	"time",
	"speed",
	"projects",
	"finish"
]
const INFO_STEPS := [
	"intro",
	"finish",
	"completion",
	"national",
	"project_controls",
	"supply",
	"fund",
	"transfer",
	"stationing",
	"decision",
	"renewal"
]
const EVENT_STEPS := [
	"completion",
	"bubble",
	"awareness",
	"newspaper",
	"dispatch_teams",
	"dispatch_stock",
	"report",
	"repair"
]
const HIDDEN_SCREENS := [
	"menu",
	"newgame",
	"pause",
	"settings",
	"save",
	"load",
	"tutorial",
	"finish_confirm",
	"retrospective",
	"ending",
	"defeat"
]

var enabled: bool = true
var completed: Array[String] = []
var skipped: Array[String] = []
var active_step: String = ""
var return_step: String = ""
var crisis_id: String = ""


static func step_known(id: String) -> bool:
	return id in BASE_STEPS or id in EVENT_STEPS or id in INFO_STEPS


func done(id: String) -> bool:
	return id in completed or id in skipped


func record(id: String) -> void:
	if not step_known(id):
		return
	if not id in completed:
		completed.append(id)
	skipped.erase(id)
	if active_step == id:
		active_step = ""
	if return_step == id:
		return_step = ""


func record_project(kind: String) -> void:
	match kind:
		"local", "policy":
			record("investment")
		"research":
			record("research")
		"awareness":
			record("awareness")
		"team":
			record("teams")
		"stock":
			record("stock")
		"repair":
			record("repair")


func acknowledge() -> void:
	if active_step in INFO_STEPS:
		record(active_step)


func skip() -> void:
	if step_known(active_step) and not done(active_step):
		skipped.append(active_step)
	if return_step == active_step:
		return_step = ""
	active_step = ""


func close() -> void:
	enabled = false
	active_step = ""


func resume() -> void:
	enabled = true


func select_step(
	sim: RefCounted, screen: String, area_id: int = 0, definition_id: String = ""
) -> String:
	if not enabled or not sim.outcome.is_empty() or screen in HIDDEN_SCREENS:
		return ""
	if (
		crisis_id.is_empty()
		or (
			sim.crises.get_crisis(crisis_id).is_empty()
			and (not done("dispatch_teams") or not done("dispatch_stock"))
		)
	):
		if not sim.crises.active.is_empty():
			crisis_id = str(sim.crises.active.front().id)
		elif not sim.crises.reports.is_empty():
			crisis_id = str(sim.crises.reports.front().id)
	var priority := _crisis_step(sim, screen)
	var basics_done := true
	for id: String in BASE_STEPS:
		if id != "finish" and not done(id):
			basics_done = false
	if priority.is_empty() and basics_done and not done("finish"):
		priority = "finish"
	if priority.is_empty():
		priority = _context_step(sim, screen, definition_id)
	if not priority.is_empty():
		if active_step in BASE_STEPS and not done(active_step):
			return_step = active_step
		active_step = priority
		return active_step
	if (
		done("dispatch_teams")
		and done("dispatch_stock")
		and not sim.crises.get_crisis(crisis_id).is_empty()
	):
		active_step = (
			"completion" if not done("completion") and _has_completed_project(sim) else ""
		)
		return active_step
	if not return_step.is_empty() and not done(return_step) and _available(sim, return_step):
		active_step = return_step
		return_step = ""
		return active_step
	for id: String in BASE_STEPS:
		if not done(id) and _available(sim, id):
			active_step = id
			return id
	if not done("bubble") and not sim.bubbles.is_empty():
		active_step = "bubble"
	elif not done("awareness") and _project_available(sim, ["awareness"]):
		active_step = "awareness"
	elif not done("completion") and _has_completed_project(sim):
		active_step = "completion"
	elif not done("repair") and done("report") and _project_available(sim, ["repair"]):
		active_step = "repair"
	else:
		active_step = ""
	return active_step


func _crisis_step(sim: RefCounted, screen: String) -> String:
	if (
		screen == "newspaper"
		and not done("newspaper")
		and not sim.news_queue.is_empty()
		and sim.news_queue.front().kind == "newspaper"
	):
		return "newspaper"
	if screen == "report" and not done("report") and not sim.crises.reports.is_empty():
		return "report"
	if not sim.news_queue.is_empty():
		return ""
	if not screen in ["", "crisis"]:
		return ""
	var crisis: Dictionary = sim.crises.get_crisis(crisis_id)
	if crisis.is_empty():
		return ""
	var feedback: Dictionary = sim.crisis_feedback(crisis_id)
	for kind: String in ["team", "stock"]:
		var id := "dispatch_teams" if kind == "team" else "dispatch_stock"
		if done(id):
			continue
		var key := "teams" if kind == "team" else "stock"
		if int(feedback[key].missing) == 0:
			record(id)
			continue
		for option: Dictionary in sim.dispatch_options(crisis_id, kind):
			if int(option.limit) > 0:
				var preview: Dictionary = sim.dispatch_preview(
					int(option.source), crisis_id, kind, 1, int(option.home)
				)
				if preview.ok and not preview.late:
					return id
	return ""


func _context_step(sim: RefCounted, screen: String, definition_id: String) -> String:
	var id := ""
	match screen:
		"national":
			id = "national"
		"projects":
			if done("projects"):
				id = "project_controls"
		"fund":
			id = "fund"
		"units":
			id = "transfer" if not done("transfer") else "stationing"
		"decision":
			id = "decision"
		"project":
			var definition: MeasureDefinition = sim.projects.definition_for(definition_id)
			if definition != null and definition.kind == "renewal":
				id = "renewal"
		"crisis":
			for crisis: Dictionary in sim.crises.active:
				if crisis.supply_alerted:
					id = "supply"
	return id if not id.is_empty() and not done(id) else ""


func _available(sim: RefCounted, id: String) -> bool:
	match id:
		"investment":
			return _project_available(sim, ["local", "policy"])
		"research":
			return _project_available(sim, ["research"])
		"teams", "stock":
			var preparation_id := "rescue_team" if id == "teams" else "aid_stock"
			for action: Dictionary in sim.preparation_plan().actions:
				if action.id == preparation_id:
					return bool(action.ok)
	return true


func _project_available(sim: RefCounted, kinds: Array, area_id: int = 0) -> bool:
	for definition: MeasureDefinition in sim.projects.definitions.values():
		if not definition.kind in kinds or definition.id.begins_with("decision_"):
			continue
		var targets: Array = [0]
		if definition.is_local():
			targets = [area_id] if sim.areas.has(area_id) else sim.areas.keys()
		for target: int in targets:
			if sim.projects.availability(definition.id, target, sim.clock.year).ok:
				return true
	return false


func _has_completed_project(sim: RefCounted) -> bool:
	for project: ActiveProject in sim.projects.projects:
		if project.status == "completed":
			return true
	return false


func to_dict() -> Dictionary:
	return {
		"enabled": enabled,
		"completed": completed.duplicate(),
		"skipped": skipped.duplicate(),
		"active_step": active_step,
		"return_step": return_step,
		"crisis_id": crisis_id
	}


func restore(data: Variant) -> bool:
	if not data is Dictionary or not data.get("enabled") is bool:
		return false
	var seen: Array[String] = []
	for key: String in ["completed", "skipped"]:
		if not data.get(key) is Array or data[key].size() > 40:
			return false
		for id: Variant in data[key]:
			if not id is String or not step_known(id) or id in seen:
				return false
			seen.append(id)
	for key: String in ["active_step", "return_step"]:
		var id: Variant = data.get(key)
		if not id is String or (not id.is_empty() and (not step_known(id) or id in seen)):
			return false
	if not data.get("crisis_id") is String or data.crisis_id.length() > 120:
		return false
	enabled = data.enabled
	completed.assign(data.completed)
	skipped.assign(data.skipped)
	active_step = data.active_step
	return_step = data.return_step
	crisis_id = data.crisis_id
	return true
