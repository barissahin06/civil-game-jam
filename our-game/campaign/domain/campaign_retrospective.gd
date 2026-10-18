class_name CampaignRetrospective
extends RefCounted
## Read-only campaign facts; presentation owns the final newspaper's prose.

const TOTAL_KEYS := ["rescued", "protected", "prevented_losses", "prevented_damage", "losses"]


static func build(sim: Simulation, reason: String) -> Dictionary:
	var totals := _empty_totals()
	var reports_by_event: Dictionary = {}
	for report: Dictionary in sim.crises.reports:
		var id := str(report.event_id)
		if not reports_by_event.has(id):
			reports_by_event[id] = _empty_totals()
			reports_by_event[id].reports_count = 0
		reports_by_event[id].reports_count += 1
		for key: String in TOTAL_KEYS:
			var amount := int(report[key])
			reports_by_event[id][key] += amount
			totals[key] += amount
	var active_ids: Dictionary = {}
	for crisis: Dictionary in sim.crises.active:
		active_ids[str(crisis.event_id)] = true
	var events: Array[Dictionary] = []
	var completed_count := 0
	var photo_event: Dictionary = {}
	var history := sim.historical.events.duplicate()
	history.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			return str(a.id) < str(b.id) if int(a.day) == int(b.day) else int(a.day) < int(b.day)
	)
	for event: Dictionary in history:
		var id := str(event.id)
		if not reports_by_event.has(id) and not active_ids.has(id):
			continue
		var row := _empty_totals()
		(
			row
			. merge(
				{
					"id": id,
					"name": str(event.name),
					"date": CalendarClock.day_to_iso(int(event.day)),
					"kind": str(event.kind),
					"active": active_ids.has(id),
					"reports_count": 0,
				}
			)
		)
		if reports_by_event.has(id):
			row.merge(reports_by_event[id], true)
		if not bool(row.active):
			completed_count += 1
			photo_event = event.duplicate(true)
		events.append(row)
	var grouped: Dictionary = {}
	for project: ActiveProject in sim.projects.projects:
		if project.status == "cancelled":
			continue
		var key := "%s:%d:%s" % [project.definition_id, project.area_id, project.status]
		if not grouped.has(key):
			var definition := sim.projects.definition_for(project.definition_id)
			grouped[key] = {
				"id": definition.id,
				"title": definition.title,
				"kind": definition.kind,
				"area_id": project.area_id,
				"area_name":
				str(sim.areas[project.area_id].name) if project.area_id != 0 else "Türkiye geneli",
				"status": project.status,
				"count": 0,
			}
		grouped[key].count += 1
	var completed_projects: Array[Dictionary] = []
	var unfinished_projects: Array[Dictionary] = []
	var keys := grouped.keys()
	keys.sort()
	for key: String in keys:
		var row: Dictionary = grouped[key]
		if row.status == "completed":
			row.erase("status")
			completed_projects.append(row)
		else:
			unfinished_projects.append(row)
	return {
		"reason": reason,
		"start_date": "%04d-01-01" % sim.start_year,
		"end_date": CalendarClock.day_to_iso(sim.clock.day),
		"event_count": events.size(),
		"completed_event_count": completed_count,
		"active_event_count": active_ids.size(),
		"totals": totals,
		"scores": sim.scores(),
		"trust": sim.trust.value,
		"events": events,
		"completed_projects": completed_projects,
		"unfinished_projects": unfinished_projects,
		"photo_event": photo_event,
	}


static func _empty_totals() -> Dictionary:
	return {"rescued": 0, "protected": 0, "prevented_losses": 0, "prevented_damage": 0, "losses": 0}
