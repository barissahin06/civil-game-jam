class_name ProjectSystem
extends RefCounted

const TEAM_UPKEEP := 40000
const MAX_REPAIR_EFFICIENCY := 0.15
const PREPARATION_IDS := ["rescue_team", "aid_stock"]

var projects: Array[ActiveProject] = []
var global_completed: Array[String] = []
var repair_support: Dictionary = {}
var research_capacity: int = 2
var definitions: Dictionary = {}
var areas: Dictionary = {}
var treasury: Treasury
var trust: TrustState
var _next_uid: int = 1


func setup(
	catalog: Dictionary, service_areas: Dictionary, funds: Treasury, public_trust: TrustState
) -> void:
	definitions = catalog
	areas = service_areas
	treasury = funds
	trust = public_trust
	projects.clear()
	global_completed.clear()
	repair_support.clear()
	research_capacity = 2
	_next_uid = 1


func definition_for(id: String) -> MeasureDefinition:
	return definitions.get(id) as MeasureDefinition


func get_project(uid: int) -> ActiveProject:
	for project: ActiveProject in projects:
		if project.uid == uid:
			return project
	return null


func is_completed(id: String, area_id: int = 0) -> bool:
	var definition := definition_for(id)
	if definition == null:
		return false
	if not definition.is_local():
		return id in global_completed
	return areas.has(area_id) and id in areas[area_id].completed_measures


func awareness_complete() -> bool:
	var found := false
	for definition: MeasureDefinition in definitions.values():
		if definition.kind == "awareness":
			found = true
			if not definition.id in global_completed:
				return false
	return found


func active_count(kind: String, area_id: int = 0) -> int:
	var count := 0
	for project: ActiveProject in projects:
		if not project.occupies_slot():
			continue
		var definition := definition_for(project.definition_id)
		if kind in ["research", "awareness"] and definition.is_research():
			count += 1
		elif kind == "national" and definition.kind == "national":
			count += 1
		elif not kind in ["research", "awareness", "national"] and definition.is_local():
			if area_id == 0 or project.area_id == area_id:
				count += 1
	return count


func cost_for(id: String, area_id: int = 0) -> int:
	var definition := definition_for(id)
	if definition == null:
		return 0
	if definition.kind == "repair":
		if not areas.has(area_id):
			return 0
		return repair_cost(areas[area_id].damage, _repair_discount(area_id))
	return definition.cost_budget


func repair_cost(damage: float, discount: float = 0.0) -> int:
	return roundi(
		(
			definition_for("repair").cost_budget
			* clampf(damage, 0.0, 100.0)
			/ 100.0
			* (1.0 - clampf(discount, 0.0, 1.0))
		)
	)


func _repair_discount(area_id: int) -> float:
	var support_discount := clampf(float(repair_support.get(area_id, 0)) / 25000000.0, 0.0, 0.2)
	return (
		support_discount
		+ clampf(get_effect(area_id, "repair_efficiency"), 0.0, MAX_REPAIR_EFFICIENCY)
	)


func start(id: String, area_id: int, year: int) -> Dictionary:
	var available := availability(id, area_id, year)
	if not available.ok:
		return available
	var definition := definition_for(id)
	var owner_id := area_id if definition.is_local() else 0
	if not treasury.spend_awareness(definition.cost_awareness):
		return _result(false, "Yeterli bilinç puanı yok.")
	var project := _create_project(definition, owner_id)
	return _result(true, "Proje başlatıldı: " + definition.title, project.uid)


func enqueue_preparation(id: String, area_id: int, year: int) -> Dictionary:
	if not id in PREPARATION_IDS:
		return _result(false, "Yalnız ekip ve yardım stoğu sıraya eklenebilir.")
	var available := _requirements(id, area_id, year)
	if not available.ok:
		return available
	var definition := definition_for(id)
	var project := _create_project(definition, area_id)
	project.status = "queued"
	_activate_preparation(area_id, year)
	return _result(
		true,
		(
			"%s: %s %s"
			% [
				areas[area_id].name,
				definition.title,
				"sıraya eklendi." if project.status == "queued" else "başlatıldı."
			]
		),
		project.uid
	)


func _create_project(definition: MeasureDefinition, owner_id: int) -> ActiveProject:
	var project := ActiveProject.new()
	project.uid = _next_uid
	project.sequence = _next_uid
	_next_uid += 1
	project.definition_id = definition.id
	project.area_id = owner_id
	project.cost_budget = cost_for(definition.id, owner_id)
	if definition.kind == "repair":
		project.repair_damage = areas[owner_id].damage
		project.repair_support_used = clampi(int(repair_support.get(owner_id, 0)), 0, 5000000)
		project.repair_discount = _repair_discount(owner_id)
	projects.append(project)
	return project


func _activate_preparation(area_id: int, year: int = 0) -> void:
	var next: ActiveProject
	for project: ActiveProject in projects:
		if project.area_id == area_id and project.status == "queued":
			if next == null or project.sequence < next.sequence:
				next = project
	if next == null:
		return
	var definition := definition_for(next.definition_id)
	var available := availability(definition.id, area_id, year if year > 0 else definition.year)
	if available.ok:
		next.status = "active"


func monthly_cost_for(id: String, area_id: int = 0) -> int:
	var definition := definition_for(id)
	return 0 if definition == null else int(cost_for(id, area_id) / definition.months)


func preparation_plan(year: int) -> Dictionary:
	var actions: Array[Dictionary] = []
	for id: String in PREPARATION_IDS:
		var definition := definition_for(id)
		var available := _requirements(id, int(areas.keys().front()), year)
		(
			actions
			. append(
				{
					"id": id,
					"title": definition.title,
					"output_title":
					(
						"%d ekip" % int(definition.effects.teams)
						if id == "rescue_team"
						else "%d yardım" % int(definition.effects.stock)
					),
					"total_cost": definition.cost_budget,
					"monthly_cost": monthly_cost_for(id),
					"months": definition.months,
					"upkeep": TEAM_UPKEEP if id == "rescue_team" else definition.upkeep,
					"ok": available.ok,
					"message": available.message,
				}
			)
		)
	var summary := {"queued_count": 0, "active_count": 0, "monthly_commitment": 0, "queued_cost": 0}
	var by_area: Dictionary = {}
	var area_ids: Array = areas.keys()
	area_ids.sort()
	for area_id: int in area_ids:
		var area: ServiceArea = areas[area_id]
		by_area[area_id] = {
			"area_id": area.id,
			"name": area.name,
			"teams": area.teams,
			"stock": area.stock,
			"busy": false,
			"active_title": "",
			"active_progress": 0,
			"active_months": 0,
			"queued_teams": 0,
			"queued_stock": 0,
			"queued_count": 0,
			"queued_blocked_reason": "",
			"planned_count": 0,
			"last_uid": 0,
		}
	var pending: Array[Dictionary] = []
	var ordered := projects.duplicate()
	ordered.sort_custom(
		func(a: ActiveProject, b: ActiveProject) -> bool: return a.sequence < b.sequence
	)
	for project: ActiveProject in ordered:
		var definition := definition_for(project.definition_id)
		if project.occupies_slot():
			summary.monthly_commitment += installment_for(project)
			if definition.is_local():
				var row: Dictionary = by_area[project.area_id]
				row.busy = true
				row.active_title = definition.title
				row.active_progress = project.progress_months
				row.active_months = definition.months
		if (
			not definition.id in PREPARATION_IDS
			or not project.status in ["active", "waiting", "paused", "queued"]
		):
			continue
		var row: Dictionary = by_area[project.area_id]
		if project.status == "queued":
			if int(row.queued_count) == 0:
				var available := availability(definition.id, project.area_id, year)
				row.queued_blocked_reason = (
					"Sonraki aybaşında başlayacak." if available.ok else available.message
				)
				for other: ActiveProject in projects:
					if (
						other.area_id == project.area_id
						and other.definition_id == definition.id
						and other.status == "paused"
					):
						row.queued_blocked_reason = (
							"Duraklatılan %s sürdürülene veya iptal edilene kadar bekliyor."
							% definition.title
						)
			summary.queued_count += 1
			summary.queued_cost += project.cost_budget
			row.queued_count += 1
			row["queued_teams" if definition.id == "rescue_team" else "queued_stock"] += 1
			row.last_uid = project.uid
		if project.occupies_slot():
			summary.active_count += 1
		if project.occupies_slot() or project.status == "queued":
			row.planned_count += 1
		(
			pending
			. append(
				{
					"uid": project.uid,
					"area_id": project.area_id,
					"area_name": row.name,
					"title": definition.title,
					"status": project.status,
					"definition_id": definition.id,
					"progress_months": project.progress_months,
					"months": definition.months,
					"monthly_cost": installment_for(project),
				}
			)
		)
	return {"actions": actions, "summary": summary, "areas": by_area.values(), "pending": pending}


func availability(id: String, area_id: int, year: int) -> Dictionary:
	var required := _requirements(id, area_id, year)
	if not required.ok:
		return required
	var definition := definition_for(id)
	if not definition.repeatable and is_completed(id, area_id):
		return _result(false, "Bu tedbir tamamlanmış.")
	for project: ActiveProject in projects:
		if (
			project.definition_id == id
			and project.area_id == (area_id if definition.is_local() else 0)
		):
			if project.status in ["active", "waiting", "paused"]:
				return _result(false, "Bu proje zaten planlanmış.")
	if definition.kind == "repair" and areas[area_id].damage <= 0.0:
		return _result(false, "Bu alanda onarım gerektiren hasar yok.")
	if not _slot_available(definition, area_id):
		return _result(false, "Aktif proje slotu dolu.")
	if treasury.awareness_points < definition.cost_awareness:
		return _result(false, "Yeterli bilinç puanı yok.")
	return _result(true, "Başlatılabilir.")


func _requirements(id: String, area_id: int, year: int) -> Dictionary:
	var definition := definition_for(id)
	if definition == null:
		return _result(false, "Bilinmeyen tedbir.")
	if definition.is_local() and not areas.has(area_id):
		return _result(false, "Geçerli bir yönetim merkezi seçin.")
	if year < definition.year:
		return _result(false, "%d yılında açılacak." % definition.year)
	for requirement: String in definition.prerequisites:
		if not is_completed(requirement, area_id):
			return _result(false, "Önkoşul: " + definition_for(requirement).title)
	return _result(true, "Başlatılabilir.")


func pause(uid: int) -> Dictionary:
	var project := get_project(uid)
	if project == null or not project.occupies_slot():
		return _result(false, "Bu proje duraklatılamaz.")
	project.status = "paused"
	return _result(true, "Proje duraklatıldı; ilerleme korunuyor.", uid)


func resume(uid: int) -> Dictionary:
	var project := get_project(uid)
	if project == null or project.status != "paused":
		return _result(false, "Bu proje sürdürülemez.")
	if not _slot_available(definition_for(project.definition_id), project.area_id):
		return _result(false, "Aktif proje slotu dolu.")
	project.status = "active"
	return _result(true, "Proje sürdürülüyor.", uid)


func cancel(uid: int) -> Dictionary:
	var project := get_project(uid)
	if project == null or project.status in ["cancelled", "completed"]:
		return _result(false, "Bu proje iptal edilemez.")
	project.status = "cancelled"
	if project.area_id != 0:
		_activate_preparation(project.area_id)
	return _result(true, "Proje iptal edildi; ödenen bedel iade edilmez.", uid)


func set_priority(uid: int, enabled: bool) -> Dictionary:
	var project := get_project(uid)
	if project == null or project.status in ["cancelled", "completed"]:
		return _result(false, "Bu projenin önceliği değiştirilemez.")
	project.priority = enabled
	return _result(true, "Proje önceliği güncellendi.", uid)


func installment_for(project: ActiveProject) -> int:
	var definition := definition_for(project.definition_id)
	# Cumulative integer division keeps the final installment exact for any TL total.
	return (
		int(project.cost_budget * (project.progress_months + 1) / definition.months) - project.paid
	)


func tick_month(year: int, can_pay_budget: bool = true) -> Array[Dictionary]:
	var ordered: Array[ActiveProject] = []
	for project: ActiveProject in projects:
		if project.occupies_slot():
			ordered.append(project)
	ordered.sort_custom(
		func(a: ActiveProject, b: ActiveProject) -> bool:
			return a.priority if a.priority != b.priority else a.sequence < b.sequence
	)
	var notices: Array[Dictionary] = []
	for project: ActiveProject in ordered:
		var definition := definition_for(project.definition_id)
		var payment := installment_for(project)
		if (payment > 0 and not can_pay_budget) or not treasury.spend(payment):
			project.status = "waiting"
			continue
		project.status = "active"
		project.paid += payment
		project.progress_months += 1
		if definition.kind == "repair":
			var area: ServiceArea = areas[project.area_id]
			area.damage = maxf(0.0, area.damage - project.repair_damage / definition.months)
		if project.progress_months == definition.months:
			_complete(project, definition)
			notices.append(
				{
					"uid": project.uid,
					"area_id": project.area_id,
					"definition_id": definition.id,
					"title": definition.title
				}
			)
	# Start the next order after billing so it first pays on the following month boundary.
	for area_id: int in areas:
		_activate_preparation(area_id, year)
	return notices


func _complete(project: ActiveProject, definition: MeasureDefinition) -> void:
	assert(project.status != "completed")
	project.status = "completed"
	if definition.kind == "team":
		areas[project.area_id].teams += int(definition.effects.get("teams", 1))
		areas[project.area_id].total_teams += int(definition.effects.get("teams", 1))
	elif definition.kind == "stock":
		areas[project.area_id].stock += int(definition.effects.get("stock", 40))
	elif definition.kind == "repair":
		repair_support[project.area_id] = maxi(
			0, int(repair_support.get(project.area_id, 0)) - project.repair_support_used
		)
	elif definition.is_local():
		areas[project.area_id].completed_measures.append(definition.id)
	else:
		global_completed.append(definition.id)
		_update_capacity()
	if not definition.repeatable:
		trust.change(0.4 if definition.is_research() else 0.6, "Tamamlandı: " + definition.title)
	if definition.id == "evacuation_drills":
		treasury.awareness_points += 3


func get_effect(area_id: int, key: String) -> float:
	var result := 0.0
	var completed: Array[String] = global_completed.duplicate()
	if areas.has(area_id):
		completed.append_array(areas[area_id].completed_measures)
	for id: String in completed:
		var definition := definition_for(id)
		var efficiency := treasury.maintenance_ratio if definition.upkeep > 0 else 1.0
		result += float(definition.effects.get(key, 0.0)) * efficiency
	return result


func infrastructure(area_id: int) -> float:
	if not areas.has(area_id):
		return 0.0
	var area: ServiceArea = areas[area_id]
	return clampf(
		area.resilience * (1.0 - area.damage / 100.0) + get_effect(area_id, "resilience"),
		0.0,
		100.0
	)


func preparedness(area_id: int, disaster_kind: String) -> float:
	if not areas.has(area_id):
		return 0.0
	var baseline := infrastructure(area_id) * 0.3
	return clampf(
		(
			baseline
			+ get_effect(area_id, "protection_" + disaster_kind)
			+ get_effect(area_id, "evacuation") * 100.0
		),
		0.0,
		100.0
	)


func effect_preview(id: String, area_id: int = 0) -> Dictionary:
	var definition := definition_for(id)
	var rows: Array[Dictionary] = []
	var global := definition != null and not definition.is_local()
	var result := {"rows": rows, "global": global, "maintenance_ratio": treasury.maintenance_ratio}
	if definition == null or (definition.is_local() and not areas.has(area_id)):
		return result
	var projected := _effect_projection(definition, area_id)
	var keys: Array = definition.effects.keys()
	if definition.kind == "repair":
		keys = ["damage", "resilience", "income"]
	for key: String in keys:
		var before := _preview_value(key, area_id, global)
		var after := projected._preview_value(key, area_id, global)
		rows.append(_preview_row(key, before, after, area_id))
	return result


func _effect_projection(definition: MeasureDefinition, area_id: int) -> ProjectSystem:
	var projected := ProjectSystem.new()
	projected.definitions = definitions
	projected.areas = areas.duplicate()
	projected.treasury = treasury
	projected.global_completed = global_completed.duplicate()
	if definition.is_local():
		var area := ServiceArea.from_dict(areas[area_id].to_dict())
		projected.areas[area_id] = area
		if definition.kind == "team":
			area.teams += int(definition.effects.get("teams", 1))
			area.total_teams += int(definition.effects.get("teams", 1))
		elif definition.kind == "stock":
			area.stock += int(definition.effects.get("stock", 40))
		elif definition.kind == "repair":
			area.damage = 0.0
		elif not definition.id in area.completed_measures:
			area.completed_measures.append(definition.id)
	elif not definition.id in projected.global_completed:
		projected.global_completed.append(definition.id)
	projected._update_capacity()
	return projected


func _preview_value(key: String, area_id: int, global: bool) -> float:
	if key == "research_capacity":
		return float(research_capacity)
	if not global:
		return _preview_area_value(key, area_id)
	var total := 0.0
	for id: int in areas:
		total += _preview_area_value(key, id)
	return total / maxi(1, areas.size())


func _preview_area_value(key: String, area_id: int) -> float:
	if key.begins_with("protection_"):
		return preparedness(area_id, key.trim_prefix("protection_"))
	if key == "resilience":
		return infrastructure(area_id)
	if key == "teams":
		return float(areas[area_id].total_teams)
	if key == "stock":
		return float(areas[area_id].stock)
	if key == "damage":
		return areas[area_id].damage
	if key == "income":
		return float(areas[area_id].income())
	var effect := get_effect(area_id, key)
	if key == "repair_efficiency":
		effect = clampf(effect, 0.0, MAX_REPAIR_EFFICIENCY)
	elif key == "trust_decay_reduction":
		effect = clampf(effect, 0.0, TrustState.MAX_DECAY_REDUCTION)
	return effect * 100.0


func _preview_row(key: String, before: float, after: float, area_id: int) -> Dictionary:
	var unit := "percent"
	var maximum := 100.0
	var bounded := false
	if key.begins_with("protection_") or key in ["resilience", "damage"]:
		unit = "points"
		bounded = true
	elif key in ["teams", "stock", "research_capacity"]:
		unit = "count"
		maximum = 5.0 if key == "teams" else 160.0
		if key == "research_capacity":
			maximum = 3.0
			bounded = true
	elif key == "income":
		unit = "money"
		maximum = float(areas[area_id].base_income)
		bounded = true
	elif key in ["repair_efficiency", "trust_decay_reduction"]:
		maximum = (
			(
				MAX_REPAIR_EFFICIENCY
				if key == "repair_efficiency"
				else TrustState.MAX_DECAY_REDUCTION
			)
			* 100.0
		)
		bounded = true
	if not bounded:
		maximum = maxf(maximum, maxf(before, after))
	return {
		"key": key,
		"before": before,
		"after": after,
		"delta": after - before,
		"minimum": 0.0,
		"maximum": maximum,
		"unit": unit,
		"higher_is_better": key != "damage",
		"bounded": bounded,
	}


func calculate_upkeep() -> int:
	var result := 0
	for area: ServiceArea in areas.values():
		result += area.base_upkeep + area.total_teams * TEAM_UPKEEP
		for id: String in area.completed_measures:
			result += definition_for(id).upkeep
	for id: String in global_completed:
		result += definition_for(id).upkeep
	return result


func initialize_era(year: int) -> void:
	for definition: MeasureDefinition in definitions.values():
		if definition.kind != "research" or definition.year > year - 20:
			continue
		var ready := true
		for requirement: String in definition.prerequisites:
			ready = ready and requirement in global_completed
		if ready and not definition.id in global_completed:
			global_completed.append(definition.id)
	_update_capacity()


func to_dict() -> Dictionary:
	var records: Array[Dictionary] = []
	for project: ActiveProject in projects:
		records.append(project.to_dict())
	return {
		"projects": records,
		"global_completed": global_completed.duplicate(),
		"next_uid": _next_uid,
		"repair_support": repair_support.duplicate(),
	}


func restore(data: Variant) -> bool:
	if (
		not data is Dictionary
		or not data.get("projects") is Array
		or not data.get("global_completed") is Array
	):
		return false
	if not ServiceArea._integer(data.get("next_uid")) or int(data.next_uid) < 1:
		return false
	if not data.get("repair_support") is Dictionary:
		return false
	var support: Dictionary = {}
	for key: Variant in data.repair_support:
		if not (key is int or key is String or key is float) or not str(key).is_valid_int():
			return false
		var area_id := int(key)
		var amount: Variant = data.repair_support[key]
		if not areas.has(area_id) or support.has(area_id) or not ServiceArea._integer(amount):
			return false
		if int(amount) < 0 or int(amount) > 5000000:
			return false
		support[area_id] = int(amount)
	var completed: Array[String] = []
	for id: Variant in data.global_completed:
		if not id is String or not definitions.has(id) or id in completed:
			return false
		if definition_for(id).is_local():
			return false
		completed.append(id)
	var restored: Array[ActiveProject] = []
	var used_ids: Array[int] = []
	var used_sequences: Array[int] = []
	var pending_keys: Array[String] = []
	for record: Variant in data.projects:
		var project := ActiveProject.from_dict(record)
		if project == null or not definitions.has(project.definition_id) or project.uid in used_ids:
			return false
		var definition := definition_for(project.definition_id)
		if project.status == "queued" and not definition.id in PREPARATION_IDS:
			return false
		if project.uid >= int(data.next_uid) or project.sequence in used_sequences:
			return false
		if definition.is_local() and not areas.has(project.area_id):
			return false
		if not definition.is_local() and project.area_id != 0:
			return false
		if project.progress_months > definition.months or project.paid > project.cost_budget:
			return false
		if project.cost_budget != definition.cost_budget and definition.kind != "repair":
			return false
		if definition.kind == "repair":
			if (
				project.cost_budget
				!= roundi(
					(
						definition.cost_budget
						* project.repair_damage
						/ 100.0
						* (1.0 - project.repair_discount)
					)
				)
			):
				return false
		elif (
			project.repair_support_used != 0
			or project.repair_discount != 0.0
			or project.repair_damage != 0.0
		):
			return false
		if project.paid != int(project.cost_budget * project.progress_months / definition.months):
			return false
		if (project.status == "completed") != (project.progress_months == definition.months):
			return false
		var key := "%s:%d" % [definition.id, project.area_id]
		if project.status in ["active", "waiting", "paused"]:
			if key in pending_keys:
				return false
			pending_keys.append(key)
		used_ids.append(project.uid)
		used_sequences.append(project.sequence)
		restored.append(project)
	var old_projects := projects
	var old_completed := global_completed
	projects = restored
	global_completed = completed
	_update_capacity()
	var valid := active_count("research") <= research_capacity and active_count("national") <= 1
	for area: ServiceArea in areas.values():
		valid = valid and active_count("local", area.id) <= 1
		for id: String in area.completed_measures:
			valid = valid and definitions.has(id) and definition_for(id).is_local()
	if not valid:
		projects = old_projects
		global_completed = old_completed
		_update_capacity()
		return false
	_next_uid = int(data.next_uid)
	repair_support = support
	return true


func _slot_available(definition: MeasureDefinition, area_id: int) -> bool:
	if definition.is_research():
		return active_count("research") < research_capacity
	if definition.kind == "national":
		return active_count("national") < 1
	return active_count("local", area_id) < 1


func _update_capacity() -> void:
	research_capacity = 2 + mini(1, int(get_effect(0, "research_capacity")))


func _result(ok: bool, message: String, uid: int = 0) -> Dictionary:
	return {"ok": ok, "message": message, "uid": uid}
