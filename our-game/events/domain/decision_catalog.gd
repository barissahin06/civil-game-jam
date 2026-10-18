class_name DecisionCatalog
extends RefCounted

const PATH := "res://events/data/decisions.json"
const EFFECTS := [
	"protection_earthquake",
	"protection_flood",
	"protection_fire",
	"protection_avalanche",
	"protection_landslide",
	"resilience",
	"evacuation",
	"rescue_efficiency",
	"logistics_efficiency",
	"repair_efficiency",
	"teams"
]

var cards: Array[Dictionary] = []
var fingerprint: String = ""


func load_cards(
	definitions: Dictionary, events: Array[Dictionary], areas: Dictionary, path: String = PATH
) -> bool:
	cards.clear()
	fingerprint = ""
	if not FileAccess.file_exists(path):
		return false
	var text := FileAccess.get_file_as_string(path)
	var data: Variant = JSON.parse_string(text)
	if (
		not data is Dictionary
		or data.get("format_version") != 1
		or not data.get("note") is String
		or not data.get("cards") is Array
		or data.cards.is_empty()
	):
		return false
	var known_events: Dictionary = {}
	for event: Dictionary in events:
		known_events[event.id] = event
	var parsed: Array[Dictionary] = []
	var ids: Array[String] = []
	var project_ids: Array[String] = []
	for card: Variant in data.cards:
		if not card is Dictionary:
			return false
		for key: String in ["id", "title", "description", "historical_note"]:
			if not card.get(key) is String or String(card[key]).strip_edges().is_empty():
				return false
		if card.id in ids or not ServiceArea._integer(card.get("area_id")):
			return false
		var area_id := int(card.area_id)
		if area_id != 0 and not areas.has(area_id):
			return false
		if not card.get("event_ids") is Array or card.event_ids.is_empty():
			return false
		var event_ids: Array[String] = []
		for event_id: Variant in card.event_ids:
			if not event_id is String or event_id in event_ids or not known_events.has(event_id):
				return false
			if area_id != 0:
				var matches_area := false
				for province_id: Variant in known_events[event_id].province_ids:
					if int(province_id) in areas[area_id].province_ids:
						matches_area = true
				if not matches_area:
					return false
			event_ids.append(event_id)
		if not card.get("options") is Array or card.options.size() != 3:
			return false
		var option_ids: Array[String] = []
		for option: Variant in card.options:
			if not option is Dictionary:
				return false
			for key: String in ["id", "title", "description", "project_id"]:
				if not option.get(key) is String:
					return false
			if (
				option.id not in ["full", "focused", "decline"]
				or option.id in option_ids
				or option.title.strip_edges().is_empty()
				or option.description.strip_edges().is_empty()
				or not ServiceArea._number(option.get("trust_delta"))
			):
				return false
			var expected_trust := 0.0
			if (
				not is_finite(float(option.trust_delta))
				or float(option.trust_delta) != expected_trust
			):
				return false
			var project_id: String = option.project_id
			if option.id == "decline":
				if not project_id.is_empty():
					return false
			else:
				if (
					not project_id.begins_with("decision_")
					or project_id in project_ids
					or not definitions.get(project_id) is MeasureDefinition
				):
					return false
				var definition: MeasureDefinition = definitions[project_id]
				if (
					definition.kind not in ["local", "national", "team"]
					or definition.repeatable
					or definition.year != 1950
					or not definition.prerequisites.is_empty()
					or definition.cost_awareness != 0
					or definition.is_local() != (area_id != 0)
				):
					return false
				for effect: String in definition.effects:
					if effect not in EFFECTS or not is_finite(float(definition.effects[effect])):
						return false
					if effect == "teams" and definition.kind != "team":
						return false
				if definition.kind == "team":
					if (
						definition.effects.size() != 1
						or not ServiceArea._integer(definition.effects.get("teams"))
						or int(definition.effects.teams) != 1
					):
						return false
				project_ids.append(project_id)
			option_ids.append(option.id)
		ids.append(card.id)
		parsed.append(card.duplicate(true))
	cards = parsed
	fingerprint = text.sha256_text()
	return true
