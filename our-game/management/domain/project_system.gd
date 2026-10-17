class_name ProjectSystem
extends RefCounted

const TEAM_UPKEEP := 40000

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
	return support_discount + clampf(get_effect(area_id, "repair_efficiency"), 0.0, 0.15)


func start(id: String, area_id: int, year: int) -> Dictionary:
	var available := availability(id, area_id, year)
	if not available.ok:
		return available
	var definition := definition_for(id)
	var owner_id := area_id if definition.is_local() else 0
	if not treasury.spend_awareness(definition.cost_awareness):
		return _result(false, "Yeterli bilinç puanı yok.")
	var project := ActiveProject.new()
	project.uid = _next_uid
	project.sequence = _next_uid
	_next_uid += 1
	project.definition_id = id
	project.area_id = owner_id
	project.cost_budget = cost_for(id, owner_id)
	if definition.kind == "repair":
		project.repair_damage = areas[owner_id].damage
		project.repair_support_used = clampi(int(repair_support.get(owner_id, 0)), 0, 5000000)
		project.repair_discount = _repair_discount(owner_id)
	projects.append(project)
	return _result(true, "Proje başlatıldı: " + definition.title, project.uid)


func monthly_cost_for(id: String, area_id: int = 0) -> int:
	var definition := definition_for(id)
	return 0 if definition == null else int(cost_for(id, area_id) / definition.months)


func availability(id: String, area_id: int, year: int) -> Dictionary:
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


func tick_month(_year: int, can_pay_budget: bool = true) -> Array[Dictionary]:
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
