class_name HistoricalCatalog
extends RefCounted

const PATH := "res://events/data/historical/events.json"
const KIND_NAMES := {
	"earthquake": "Deprem",
	"flood": "Sel",
	"fire": "Orman yangını",
	"avalanche": "Çığ",
	"landslide": "Heyelan"
}
var events: Array[Dictionary] = []
var fingerprint: String = ""


func load_events() -> bool:
	events.clear()
	var text := FileAccess.get_file_as_string(PATH)
	var data: Variant = JSON.parse_string(text)
	if not data is Dictionary or data.get("format_version") != 1 or not data.get("events") is Array:
		return false
	var ids: Array[String] = []
	for entry: Variant in data.events:
		if not entry is Dictionary:
			return false
		for key: String in ["id", "name", "date", "description", "kind"]:
			if not entry.get(key) is String:
				return false
		if entry.id in ids or CalendarClock.date_to_day(entry.date) == CalendarClock.INVALID_DAY:
			return false
		if not entry.kind in ["earthquake", "flood", "fire", "avalanche", "landslide"]:
			return false
		for key: String in ["severity", "response_window_days", "reference_casualties"]:
			if not ServiceArea._integer(entry.get(key)) or float(entry[key]) < 0:
				return false
		if (
			entry.severity < 1
			or entry.severity > 9
			or entry.response_window_days < 1
			or entry.response_window_days > 30
		):
			return false
		if not entry.get("province_ids") is Array or entry.province_ids.is_empty():
			return false
		for id: Variant in entry.province_ids:
			if not ServiceArea._integer(id) or id < 1 or id > 81:
				return false
		ids.append(entry.id)
		var item: Dictionary = entry.duplicate(true)
		item.day = CalendarClock.date_to_day(item.date)
		events.append(item)
	events.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			return a.day < b.day if a.day != b.day else a.id < b.id
	)
	fingerprint = text.sha256_text()
	return not events.is_empty()
