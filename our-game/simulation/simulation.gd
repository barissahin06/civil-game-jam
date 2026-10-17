class_name Simulation
extends RefCounted
## Feature models own rules; this coordinator orders commands and calendar boundaries.

signal changed
signal notification_requested

const END_DATE := "2026-12-31"
var clock := CalendarClock.new()
var treasury := Treasury.new()
var trust := TrustState.new()
var projects := ProjectSystem.new()
var crises := CrisisSystem.new()
var logistics := LogisticsSystem.new()
var historical := HistoricalCatalog.new()
var content_fingerprint: String = ""
var areas: Dictionary = {}
var paused: bool = true
var speed: int = 1
var start_year: int = 1950
var outcome: String = ""
var news_queue: Array[Dictionary] = []
var bubbles: Array[int] = []
var ticker: Array[String] = []
var tutorial_completed: Array[String] = []
var tutorial_enabled: bool = true
var _event_index: int = 0
var _accumulator: float = 0.0
var _calm_months: int = 0


func setup(year: int = 1950) -> bool:
	if year < 1950 or year > 1990:
		return false
	start_year = year
	clock.setup(year)
	var catalog := Catalog.new()
	areas = catalog.load_areas(year)
	var definitions := catalog.load_definitions()
	if areas.is_empty() or definitions.is_empty() or not historical.load_events():
		return false
	treasury.money = 20000000 + (year - 1950) * 500000
	projects.setup(definitions, areas, treasury, trust)
	projects.initialize_era(year)
	treasury.refresh_forecast(areas, projects)
	content_fingerprint = (
		(
			historical.fingerprint
			+ FileAccess.get_file_as_string("res://management/data/measures.json")
			+ FileAccess.get_file_as_string("res://regions/data/service_areas.json")
		)
		. sha256_text()
	)
	crises.setup(areas, projects, trust)
	logistics.setup(areas, treasury, projects)
	while (
		_event_index < historical.events.size()
		and int(historical.events[_event_index].day) < clock.day
	):
		_event_index += 1
	_events_today()
	log_message("%d tarihsel kampanyası hazır. Başlatmak için DEVAM düğmesini kullan." % year)
	return true


func set_paused(value: bool) -> void:
	paused = value or not news_queue.is_empty() or not outcome.is_empty()
	changed.emit()


func set_speed(value: int) -> void:
	if value in [1, 2, 4]:
		speed = value
		changed.emit()


func update(delta: float) -> void:
	if paused or delta <= 0.0 or not is_finite(delta) or not outcome.is_empty():
		return
	_accumulator += delta * speed
	var previous_day := clock.day
	while not paused:
		var next_month := clock.next_month_day()
		var target := clock.day + 1 if not crises.active.is_empty() else next_month
		if _event_index < historical.events.size():
			target = mini(target, int(historical.events[_event_index].day))
		target = mini(target, CalendarClock.date_to_day(END_DATE))
		var seconds := (
			1.0
			if not crises.active.is_empty()
			else 2.0 * float(target - clock.day) / maxi(1, next_month - clock.day)
		)
		if _accumulator < seconds:
			break
		_accumulator -= seconds
		advance_to(target)
		if paused:
			_accumulator = 0.0
	if clock.day != previous_day:
		changed.emit()


func advance_to(target: int) -> void:
	# One ordered calendar prevents skipped dates, duplicate taxes and lost parallel events.
	while clock.day < target and outcome.is_empty():
		clock.advance_days(1)
		if clock.day_of_month == 1:
			_month_boundary()
		for notice: String in logistics.tick_day(clock.day, crises.active):
			log_message(notice)
		for report: Dictionary in crises.tick_day(clock.day, logistics):
			news_queue.append({"kind": "report", "id": report.id})
			paused = true
		_events_today()
		_check_ending()
		if not news_queue.is_empty():
			paused = true
			notification_requested.emit()
			break
	changed.emit()


func _month_boundary() -> void:
	var settlement := treasury.collect_and_maintain(areas, projects)
	var awareness_was_complete := projects.awareness_complete()
	for completion: Dictionary in projects.tick_month(clock.year, bool(settlement.can_pay_budget)):
		log_message(str(completion.get("message", completion.get("title", "Proje tamamlandı"))))
	if not awareness_was_complete and projects.awareness_complete():
		log_message("Bilinç geliştirmeleri tamamlandı, yeni bilinç baloncukları üretilmeyecek.")
	var population := 0
	var damaged_population := 0.0
	for area: ServiceArea in areas.values():
		population += area.population
		damaged_population += area.population * area.damage
	trust.decay_month(
		projects.get_effect(0, "trust_decay_reduction"), damaged_population / maxi(1, population)
	)
	var starts_today: bool = (
		_event_index < historical.events.size()
		and int(historical.events[_event_index].day) == clock.day
	)
	if crises.active.is_empty() and not starts_today:
		_calm_months += 1
		if _calm_months % 2 == 0 and bubbles.size() < 3 and not projects.awareness_complete():
			var candidates: Array = areas.keys()
			var index := (_calm_months / 2) % candidates.size()
			for offset in range(candidates.size()):
				var id: int = candidates[(index + offset) % candidates.size()]
				if not id in bubbles:
					bubbles.append(id)
					break
	log_message(
		(
			"%s: gelir ₺%d / bakım ₺%d"
			% [CalendarClock.day_to_iso(clock.day), settlement.income, settlement.paid_upkeep]
		)
	)


func _events_today() -> void:
	while (
		_event_index < historical.events.size()
		and int(historical.events[_event_index].day) == clock.day
	):
		var event := historical.events[_event_index]
		crises.begin(event)
		news_queue.append({"kind": "newspaper", "id": event.id})
		_event_index += 1
		paused = true
		notification_requested.emit()


func acknowledge() -> void:
	if not news_queue.is_empty():
		news_queue.pop_front()
	changed.emit()
	if not news_queue.is_empty():
		notification_requested.emit()


func start_project(id: String, area_id: int = 0) -> Dictionary:
	if not outcome.is_empty():
		return {"ok": false, "message": "Kampanya tamamlandı"}
	var result := projects.start(id, area_id, clock.year)
	if result.ok:
		var definition := projects.definition_for(id)
		if definition.is_research():
			learn("research")
		elif definition.is_local():
			learn("investment")
		log_message(result.message)
		changed.emit()
	return result


func dispatch(source: int, crisis_id: String, kind: String, amount: int) -> Dictionary:
	var crisis := crises.get_crisis(crisis_id)
	if crisis.is_empty() or not outcome.is_empty():
		return {"ok": false, "message": "Aktif hedef kriz seçilmeli"}
	var result := logistics.dispatch(
		source, int(crisis.area_id), crisis_id, kind, amount, clock.day
	)
	if result.ok:
		logistics.tick_day(clock.day, crises.active)
		learn("dispatch")
		log_message(result.message)
		changed.emit()
	return result


func fund(crisis_id: String, amount: int) -> Dictionary:
	if not outcome.is_empty():
		return {"ok": false, "message": "Kampanya tamamlandı"}
	var result := crises.fund(crisis_id, amount, treasury)
	if result.ok:
		log_message(result.message)
		changed.emit()
	return result


func collect_bubble(id: int) -> void:
	if id in bubbles:
		bubbles.erase(id)
		treasury.awareness_points += 5
		log_message("%s: +5 bilinç puanı" % areas[id].name)
		changed.emit()


func learn(action: String) -> void:
	if not action in tutorial_completed:
		tutorial_completed.append(action)


func log_message(message: String) -> void:
	ticker.append(message)
	if ticker.size() > 100:
		ticker.pop_front()


func event_for(id: String) -> Dictionary:
	for event: Dictionary in historical.events:
		if event.id == id:
			return event
	return {}


func report_for(id: String = "") -> Dictionary:
	for report: Dictionary in crises.reports:
		if report.id == id:
			return report
	return crises.reports.back() if id.is_empty() and not crises.reports.is_empty() else {}


func scores() -> Dictionary:
	var preparation := 0.0
	var recovery := 0.0
	var response := 0.0
	for area: ServiceArea in areas.values():
		for kind: String in ["earthquake", "flood", "fire", "avalanche", "landslide"]:
			preparation += projects.preparedness(area.id, kind) / 5.0
		recovery += 100.0 - area.damage
	for report: Dictionary in crises.reports:
		response += float(report.quality)
	return {
		"preparation": roundi(preparation / 21.0),
		"response":
		roundi(response / crises.reports.size()) if not crises.reports.is_empty() else 0,
		"recovery": roundi(recovery / 21.0)
	}


func _check_ending() -> void:
	if trust.value <= 0.0:
		outcome = "defeat"
	elif clock.day >= CalendarClock.date_to_day(END_DATE):
		outcome = "ending"
	if not outcome.is_empty():
		paused = true
		notification_requested.emit()


func to_dict() -> Dictionary:
	var area_records: Array[Dictionary] = []
	for area: ServiceArea in areas.values():
		area_records.append(area.to_dict())
	return {
		"version": 1,
		"catalog": content_fingerprint,
		"start_year": start_year,
		"day": clock.day,
		"speed": speed,
		"outcome": outcome,
		"money": treasury.money,
		"awareness": treasury.awareness_points,
		"maintenance": treasury.maintenance_ratio,
		"income": treasury.last_income,
		"upkeep": treasury.last_upkeep,
		"net": treasury.last_net,
		"trust": trust.value,
		"trust_history": trust.history,
		"areas": area_records,
		"projects": projects.to_dict(),
		"active": crises.active,
		"reports": crises.reports,
		"shipments": logistics.shipments,
		"shipment_sequence": logistics.sequence,
		"event_index": _event_index,
		"news_queue": news_queue,
		"bubbles": bubbles,
		"ticker": ticker,
		"calm_months": _calm_months,
		"tutorial": tutorial_completed,
		"tutorial_enabled": tutorial_enabled
	}
