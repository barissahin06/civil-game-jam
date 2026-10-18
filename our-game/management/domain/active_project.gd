class_name ActiveProject
extends RefCounted

const STATUSES := ["active", "waiting", "paused", "queued", "cancelled", "completed"]

var uid: int
var definition_id: String
var area_id: int
var progress_months: int = 0
var paid: int = 0
var status: String = "active"
var priority: bool = false
var sequence: int
var cost_budget: int
var repair_damage: float = 0.0
var repair_support_used: int = 0
var repair_discount: float = 0.0
var renewal_value: int = 0


func occupies_slot() -> bool:
	return status in ["active", "waiting"]


func to_dict() -> Dictionary:
	return {
		"uid": uid,
		"definition_id": definition_id,
		"area_id": area_id,
		"progress_months": progress_months,
		"paid": paid,
		"status": status,
		"priority": priority,
		"sequence": sequence,
		"cost_budget": cost_budget,
		"repair_damage": repair_damage,
		"repair_support_used": repair_support_used,
		"repair_discount": repair_discount,
		"renewal_value": renewal_value,
	}


static func from_dict(data: Variant) -> ActiveProject:
	if not data is Dictionary:
		return null
	for key: String in [
		"uid",
		"area_id",
		"progress_months",
		"paid",
		"sequence",
		"cost_budget",
		"repair_support_used",
		"renewal_value"
	]:
		if not ServiceArea._integer(data.get(key)) or int(data[key]) < 0:
			return null
	if int(data.uid) < 1 or int(data.sequence) < 1:
		return null
	if not data.get("definition_id") is String or String(data.definition_id).is_empty():
		return null
	if not data.get("status") is String or not data.status in STATUSES:
		return null
	if not data.get("priority") is bool or not ServiceArea._number(data.get("repair_damage")):
		return null
	if float(data.repair_damage) < 0.0 or float(data.repair_damage) > 100.0:
		return null
	if (
		int(data.repair_support_used) > 5000000
		or not ServiceArea._number(data.get("repair_discount"))
	):
		return null
	if float(data.repair_discount) < 0.0 or float(data.repair_discount) > 0.35:
		return null
	if data.status == "queued" and (int(data.progress_months) != 0 or int(data.paid) != 0):
		return null
	var project := ActiveProject.new()
	for key: String in [
		"uid",
		"definition_id",
		"area_id",
		"progress_months",
		"paid",
		"status",
		"priority",
		"sequence",
		"cost_budget",
		"repair_damage",
		"repair_support_used",
		"repair_discount",
		"renewal_value",
	]:
		project.set(key, data[key])
	return project
