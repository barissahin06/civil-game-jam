class_name MeasureDefinition
extends RefCounted

const KINDS := [
	"policy", "local", "research", "awareness", "national", "repair", "team", "stock", "renewal"
]

var id: String
var title: String
var kind: String
var tab: int
var year: int
var prerequisites: Array[String] = []
var cost_budget: int
var cost_awareness: int
var months: int
var upkeep: int
var effects: Dictionary = {}
var repeatable: bool


func is_research() -> bool:
	return kind in ["research", "awareness"]


func is_local() -> bool:
	return not is_research() and kind != "national"


static func from_dict(data: Variant) -> MeasureDefinition:
	if not data is Dictionary:
		return null
	for key: String in ["id", "title", "kind"]:
		if not data.get(key) is String or String(data[key]).is_empty():
			return null
	if not data.kind in KINDS:
		return null
	for key: String in ["tab", "year", "cost_budget", "cost_awareness", "months", "upkeep"]:
		if not ServiceArea._integer(data.get(key)) or int(data[key]) < 0:
			return null
	if int(data.months) < 1 or int(data.months) > 120 or int(data.tab) > 3:
		return null
	if int(data.year) < 1950 or int(data.year) > 2026:
		return null
	if not data.get("repeatable") is bool or not data.get("prerequisites") is Array:
		return null
	var requirements: Array[String] = []
	for requirement: Variant in data.prerequisites:
		if (
			not requirement is String
			or String(requirement).is_empty()
			or requirement in requirements
		):
			return null
		requirements.append(requirement)
	if not data.get("effects") is Dictionary:
		return null
	for key: Variant in data.effects:
		if not key is String or not ServiceArea._number(data.effects[key]):
			return null
		if float(data.effects[key]) < 0.0:
			return null
	var definition := MeasureDefinition.new()
	for key: String in [
		"id",
		"title",
		"kind",
		"tab",
		"year",
		"cost_budget",
		"cost_awareness",
		"months",
		"upkeep",
		"repeatable"
	]:
		definition.set(key, data[key])
	definition.prerequisites = requirements
	definition.effects = data.effects.duplicate(true)
	return definition
