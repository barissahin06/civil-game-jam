class_name ServiceArea
extends RefCounted

var id: int
var name: String
var region: String
var population: int
var base_income: int
var base_upkeep: int
var resilience: float
var damage: float = 0.0
var teams: int
var total_teams: int
var stock: int
var province_ids: Array[int] = []
var completed_measures: Array[String] = []
var latitude: float
var longitude: float


func income() -> int:
	return roundi(base_income * (1.0 - clampf(damage, 0.0, 100.0) / 100.0))


func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"region": region,
		"population": population,
		"base_income": base_income,
		"base_upkeep": base_upkeep,
		"resilience": resilience,
		"damage": damage,
		"teams": teams,
		"total_teams": total_teams,
		"stock": stock,
		"province_ids": province_ids.duplicate(),
		"completed_measures": completed_measures.duplicate(),
		"latitude": latitude,
		"longitude": longitude,
	}


static func from_dict(data: Variant) -> ServiceArea:
	if not data is Dictionary:
		return null
	for key: String in [
		"id", "population", "base_income", "base_upkeep", "teams", "total_teams", "stock"
	]:
		if not _integer(data.get(key)) or int(data[key]) < 0:
			return null
	if int(data.id) < 1 or int(data.id) > 81 or int(data.population) == 0:
		return null
	if int(data.teams) > int(data.total_teams):
		return null
	for key: String in ["name", "region"]:
		if not data.get(key) is String or String(data[key]).is_empty():
			return null
	for key: String in ["resilience", "damage", "latitude", "longitude"]:
		if not _number(data.get(key)):
			return null
	if float(data.resilience) < 0.0 or float(data.resilience) > 100.0:
		return null
	if float(data.damage) < 0.0 or float(data.damage) > 100.0:
		return null
	if absf(float(data.latitude)) > 90.0 or absf(float(data.longitude)) > 180.0:
		return null
	if not data.get("province_ids") is Array or data.province_ids.is_empty():
		return null
	var province_ids_checked: Array[int] = []
	for province: Variant in data.province_ids:
		if not _integer(province) or int(province) < 1 or int(province) > 81:
			return null
		if int(province) in province_ids_checked:
			return null
		province_ids_checked.append(int(province))
	if not int(data.id) in province_ids_checked or not data.get("completed_measures") is Array:
		return null
	var completed: Array[String] = []
	for measure: Variant in data.completed_measures:
		if not measure is String or String(measure).is_empty() or measure in completed:
			return null
		completed.append(measure)
	var area := ServiceArea.new()
	for key: String in [
		"id",
		"name",
		"region",
		"population",
		"base_income",
		"base_upkeep",
		"resilience",
		"damage",
		"teams",
		"total_teams",
		"stock",
		"latitude",
		"longitude"
	]:
		area.set(key, data[key])
	area.province_ids = province_ids_checked
	area.completed_measures = completed
	return area


static func _number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))


static func _integer(value: Variant) -> bool:
	return _number(value) and float(value) == floor(float(value))
