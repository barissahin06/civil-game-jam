class_name TrustState
extends RefCounted

const MIN_VALUE := 0.0
const MAX_VALUE := 100.0

var value: float = 70.0
var history: Array[Dictionary] = []
var damage_records: Array[Dictionary] = []

const MONTHLY_BASE_DECAY := 0.01
const MONTHLY_DAMAGE_DECAY_PER_POINT := 0.0015
const MAX_DECAY_REDUCTION := 0.85


func change(amount: float, reason: String) -> void:
	assert(is_finite(amount))
	var previous := value
	value = clampf(value + amount, MIN_VALUE, MAX_VALUE)
	if not is_equal_approx(previous, value):
		history.append({"amount": value - previous, "reason": reason})
		if history.size() > 200:
			history.pop_front()


func feedback() -> Dictionary:
	var latest: Dictionary = history.back() if not history.is_empty() else {}
	return {
		"value": value,
		"minimum": MIN_VALUE,
		"maximum": MAX_VALUE,
		"latest_amount": float(latest.get("amount", 0.0)),
		"latest_reason": str(latest.get("reason", "Henüz değişim yok")),
		"has_change": not history.is_empty(),
	}


func decay_month(reduction: float = 0.0) -> void:
	change(
		-MONTHLY_BASE_DECAY * (1.0 - clampf(reduction, 0.0, MAX_DECAY_REDUCTION)),
		"Aylık güven aşınması"
	)


func assess_response(
	preparation: float,
	response: float,
	teams: float,
	aid: float,
	reason: String,
	severity: float = 1.0
) -> float:
	var adjustment := clampf(
		(
			3.0 * (clampf(response, 0.0, 1.0) - 0.65)
			+ 0.8 * (clampf(preparation, 0.0, 1.0) - 0.35)
			- 0.6 * (1.0 - clampf(teams, 0.0, 1.0))
			- 1.2 * (1.0 - clampf(aid, 0.0, 1.0))
		),
		-3.0,
		1.42
	)
	if adjustment > 0.0:
		adjustment *= 0.8 / 1.42
	adjustment = clampf(adjustment * clampf(severity / 6.0, 1.0, 1.5), -3.0, 1.2)
	var previous := value
	change(adjustment, reason)
	return value - previous


static func month_index(day: int) -> int:
	var date := Time.get_date_dict_from_unix_time(day * CalendarClock.DAY_SECONDS)
	return int(date.year) * 12 + int(date.month) - 1


static func elapsed_months(since: int, day: int) -> int:
	var months := month_index(day) - month_index(since)
	if months <= 0:
		return 0
	var first := Time.get_date_dict_from_unix_time(since * CalendarClock.DAY_SECONDS)
	var current := Time.get_date_dict_from_unix_time(day * CalendarClock.DAY_SECONDS)
	var next_year := int(current.year) + (1 if int(current.month) == 12 else 0)
	var next_month := 1 if int(current.month) == 12 else int(current.month) + 1
	var next_start := CalendarClock.date_to_day("%04d-%02d-01" % [next_year, next_month])
	var last_date := Time.get_date_dict_from_unix_time((next_start - 1) * CalendarClock.DAY_SECONDS)
	var anniversary := mini(int(first.day), int(last_date.day))
	return months - (1 if int(current.day) < anniversary else 0)


func record_damage(event_id: String, area_id: int, amount: float, day: int) -> void:
	assert(is_finite(amount) and amount >= 0.0)
	if is_zero_approx(amount):
		return
	for record: Dictionary in damage_records:
		if record.event_id == event_id and int(record.area_id) == area_id:
			record.remaining_damage += amount
			return
	damage_records.append(
		{
			"event_id": event_id,
			"area_id": area_id,
			"day": day,
			"remaining_damage": amount,
			"recoverable_loss": 0.0,
			"last_review_month": month_index(day)
		}
	)


func repair_damage(area_id: int, amount: float) -> float:
	assert(is_finite(amount) and amount >= 0.0)
	var previous := value
	var remaining := amount
	damage_records.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			return (
				int(a.day) < int(b.day)
				if a.day != b.day
				else String(a.event_id) < String(b.event_id)
			)
	)
	for record: Dictionary in damage_records.duplicate():
		if int(record.area_id) != area_id or remaining <= 0.0:
			continue
		var repaired := minf(remaining, float(record.remaining_damage))
		var refund := float(record.recoverable_loss) * repaired / float(record.remaining_damage)
		record.recoverable_loss = maxf(0.0, float(record.recoverable_loss) - refund)
		record.remaining_damage = maxf(0.0, float(record.remaining_damage) - repaired)
		remaining -= repaired
		change(refund, "Gerçek onarımla geri kazanılan güven")
		if is_zero_approx(float(record.remaining_damage)):
			damage_records.erase(record)
	return value - previous


func review_recovery(day: int, areas: Dictionary) -> float:
	var population := 0
	for area: ServiceArea in areas.values():
		population += area.population
	var previous := value
	for record: Dictionary in damage_records:
		if int(record.last_review_month) >= month_index(day):
			continue
		record.last_review_month = month_index(day)
		if elapsed_months(int(record.day), day) < 6:
			continue
		var before := value
		var area: ServiceArea = areas[int(record.area_id)]
		change(
			(
				-float(record.remaining_damage)
				* MONTHLY_DAMAGE_DECAY_PER_POINT
				* float(area.population)
				/ maxi(1, population)
			),
			"Onarılmayan altyapının güven etkisi"
		)
		record.recoverable_loss += (before - value) * 0.5
	return value - previous


func restore_recovery(data: Variant, areas: Dictionary, day: int) -> bool:
	if not data is Array or data.size() > 4096:
		return false
	var restored: Array[Dictionary] = []
	var totals: Dictionary = {}
	var seen: Dictionary = {}
	for record: Variant in data:
		if not record is Dictionary:
			return false
		if not record.get("event_id") is String or String(record.event_id).is_empty():
			return false
		for key: String in ["area_id", "day", "last_review_month"]:
			if not ServiceArea._integer(record.get(key)):
				return false
		if not areas.has(int(record.area_id)) or int(record.day) > day:
			return false
		if int(record.day) < CalendarClock.date_to_day("1950-01-01"):
			return false
		if (
			int(record.last_review_month) < month_index(int(record.day))
			or int(record.last_review_month) > month_index(day)
		):
			return false
		for key: String in ["remaining_damage", "recoverable_loss"]:
			if not ServiceArea._number(record.get(key)):
				return false
		if float(record.remaining_damage) <= 0.0 or float(record.remaining_damage) > 100.0:
			return false
		var maximum_refund := (
			100.0
			* MONTHLY_DAMAGE_DECAY_PER_POINT
			* 0.5
			* maxi(0, int(record.last_review_month) - month_index(int(record.day)) - 5)
		)
		if (
			float(record.recoverable_loss) < 0.0
			or float(record.recoverable_loss) > maximum_refund + 0.000001
		):
			return false
		var identity := "%s:%d" % [record.event_id, int(record.area_id)]
		if seen.has(identity):
			return false
		seen[identity] = true
		totals[int(record.area_id)] = (
			float(totals.get(int(record.area_id), 0.0)) + float(record.remaining_damage)
		)
		restored.append(record.duplicate(true))
	for area: ServiceArea in areas.values():
		if not is_equal_approx(float(totals.get(area.id, 0.0)), area.damage):
			return false
	damage_records = restored
	return true
