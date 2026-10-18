class_name Catalog
extends RefCounted

const AREA_IDS := [1, 6, 7, 16, 21, 25, 26, 27, 31, 34, 35, 41, 42, 44, 45, 48, 53, 55, 61, 63, 65]
const RESEARCH_ERAS := [1950, 1970, 1990, 2005, 2020]

var validation_errors: Array[String] = []
var definitions: Dictionary = {}


func load_definitions(path: String = "res://management/data/measures.json") -> Dictionary:
	validation_errors.clear()
	definitions = {}
	var data: Variant = _load_json(path)
	if (
		not data is Dictionary
		or data.get("format_version") != 1
		or not data.get("measures") is Array
	):
		return _invalid("Tedbir kataloğu biçimi geçersiz.")
	var parsed: Dictionary = {}
	for record: Variant in data.measures:
		var definition := MeasureDefinition.from_dict(record)
		if definition == null or parsed.has(definition.id):
			return _invalid("Geçersiz veya yinelenmiş tedbir tanımı.")
		if (
			(definition.is_research() or definition.kind == "national")
			and not definition.id.begins_with("decision_")
			and not definition.year in RESEARCH_ERAS
		):
			return _invalid("Geçersiz araştırma veya ulusal önlem dönemi.")
		parsed[definition.id] = definition
	if parsed.is_empty():
		return _invalid("Tedbir kataloğu boş.")
	var resolved: Array[String] = []
	while resolved.size() < parsed.size():
		var before := resolved.size()
		for definition: MeasureDefinition in parsed.values():
			if definition.id in resolved:
				continue
			var ready := true
			for requirement: String in definition.prerequisites:
				if not parsed.has(requirement):
					return _invalid("Bilinmeyen önkoşul: " + requirement)
				if parsed[requirement].year > definition.year:
					return _invalid("Önkoşul daha sonraki bir döneme ait: " + requirement)
				if not requirement in resolved:
					ready = false
			if ready:
				resolved.append(definition.id)
		if before == resolved.size():
			return _invalid("Tedbir önkoşullarında döngü var.")
	definitions = parsed
	return definitions


func load_areas(
	start_year: int = 1950, path: String = "res://regions/data/service_areas.json"
) -> Dictionary:
	validation_errors.clear()
	if start_year < 1950 or start_year > 1990:
		return _invalid("Başlangıç yılı 1950–1990 arasında olmalı.")
	var data: Variant = _load_json(path)
	if not data is Dictionary or data.get("format_version") != 1 or not data.get("areas") is Array:
		return _invalid("Yönetim alanı biçimi geçersiz.")
	var parsed: Dictionary = {}
	var owned_provinces: Array[int] = []
	var region_counts: Dictionary = {}
	for record: Variant in data.areas:
		var area := ServiceArea.from_dict(record)
		if area == null or parsed.has(area.id) or not area.id in AREA_IDS:
			return _invalid("Geçersiz veya yinelenmiş yönetim merkezi.")
		for province: int in area.province_ids:
			if province in owned_provinces:
				return _invalid("Bir il birden fazla merkeze atanmış.")
			owned_provinces.append(province)
		region_counts[area.region] = int(region_counts.get(area.region, 0)) + 1
		var elapsed := start_year - 1950
		area.population = roundi(area.population * (1.0 + elapsed * 0.02))
		area.base_income = roundi(area.base_income * (1.0 + elapsed * 0.015))
		area.resilience = minf(100.0, area.resilience + elapsed * 0.3)
		area.teams += int(elapsed / 20)
		area.total_teams = area.teams
		area.stock += elapsed
		parsed[area.id] = area
	if parsed.size() != 21 or owned_provinces.size() != 81 or region_counts.size() != 7:
		return _invalid("21 merkez, 7 bölge ve 81 il gerekli.")
	for count: int in region_counts.values():
		if count != 3:
			return _invalid("Her bölgede üç yönetim merkezi gerekli.")
	return parsed


func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		validation_errors.append("Dosya bulunamadı: " + path)
		return null
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK:
		validation_errors.append("JSON okunamadı: " + path)
		return null
	return parser.data


func _invalid(message: String) -> Dictionary:
	validation_errors.append(message)
	return {}
