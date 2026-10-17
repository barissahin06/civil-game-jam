class_name CalendarClock
extends RefCounted

const DAY_SECONDS := 86400
const INVALID_DAY := -2147483648

var day: int = date_to_day("1950-01-01")
var year: int:
	get:
		return int(Time.get_date_dict_from_unix_time(day * DAY_SECONDS).year)
var month: int:
	get:
		return int(Time.get_date_dict_from_unix_time(day * DAY_SECONDS).month)
var day_of_month: int:
	get:
		return int(Time.get_date_dict_from_unix_time(day * DAY_SECONDS).day)


static func date_to_day(iso: String) -> int:
	var pattern := RegEx.new()
	pattern.compile("^[0-9]{4}-[0-9]{2}-[0-9]{2}$")
	if pattern.search(iso) == null:
		return INVALID_DAY
	var parts := iso.split("-")
	var parsed_year := int(parts[0])
	var parsed_month := int(parts[1])
	var parsed_day := int(parts[2])
	if parsed_year < 1 or parsed_year > 9998 or parsed_month < 1 or parsed_month > 12:
		return INVALID_DAY
	var month_start := Time.get_unix_time_from_datetime_string(
		"%04d-%02d-01T00:00:00" % [parsed_year, parsed_month]
	)
	var next_year := parsed_year + (1 if parsed_month == 12 else 0)
	var next_month := 1 if parsed_month == 12 else parsed_month + 1
	var next_start := Time.get_unix_time_from_datetime_string(
		"%04d-%02d-01T00:00:00" % [next_year, next_month]
	)
	if parsed_day < 1 or parsed_day > int((next_start - month_start) / DAY_SECONDS):
		return INVALID_DAY
	var timestamp := month_start + (parsed_day - 1) * DAY_SECONDS
	if Time.get_date_string_from_unix_time(timestamp) != iso:
		return INVALID_DAY
	return int(floor(float(timestamp) / DAY_SECONDS))


static func day_to_iso(value: int) -> String:
	return Time.get_date_string_from_unix_time(value * DAY_SECONDS)


func setup(start_year: int) -> void:
	assert(start_year >= 1950 and start_year <= 1990)
	day = date_to_day("%04d-01-01" % start_year)


func next_month_day() -> int:
	var following_year := year + (1 if month == 12 else 0)
	var following_month := 1 if month == 12 else month + 1
	return date_to_day("%04d-%02d-01" % [following_year, following_month])


func advance_days(count: int) -> void:
	assert(count >= 0)
	day += count


func set_day(value: int) -> void:
	assert(value != INVALID_DAY)
	day = value
