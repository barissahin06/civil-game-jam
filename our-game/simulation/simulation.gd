class_name Simulation
extends RefCounted
## Feature models own rules; this coordinator orders commands and calendar boundaries.

signal changed
signal notification_requested
signal reward_earned
signal supply_warning_requested(crisis_id: String)
signal management_warning_requested(message: String)

const END_DATE := "2026-12-31"
const CALM_MONTH_SECONDS := 1.5
const CRISIS_DAY_SECONDS := 1.5
# Map color saturation only; aid storage has no capacity limit.
const MAP_STOCK_SCALE := 160.0
var clock := CalendarClock.new()
var treasury := Treasury.new()
var trust := TrustState.new()
var projects := ProjectSystem.new()
var crises := CrisisSystem.new()
var logistics := LogisticsSystem.new()
var historical := HistoricalCatalog.new()
var decision_catalog := DecisionCatalog.new()
var decisions := DecisionSystem.new()
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
	if not decision_catalog.load_cards(definitions, historical.events, areas):
		return false
	treasury.money = 20000000 + (year - 1950) * 500000
	projects.setup(definitions, areas, treasury, trust)
	projects.initialize_era(year)
	decisions.setup(decision_catalog, projects, clock.day)
	treasury.refresh_forecast(areas, projects)
	content_fingerprint = (
		(
			historical.fingerprint
			+ FileAccess.get_file_as_string("res://management/data/measures.json")
			+ FileAccess.get_file_as_string("res://regions/data/service_areas.json")
			+ decision_catalog.fingerprint
		)
		. sha256_text()
	)
	crises.setup(areas, projects, trust, logistics)
	logistics.setup(areas, treasury, projects)
	while (
		_event_index < historical.events.size()
		and int(historical.events[_event_index].day) < clock.day
	):
		_event_index += 1
	_events_today()
	log_message("%d tarihsel oyunu hazır. Zamanı Başlat düğmesini kullan." % year)
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
			CRISIS_DAY_SECONDS
			if not crises.active.is_empty()
			else CALM_MONTH_SECONDS * float(target - clock.day) / maxi(1, next_month - clock.day)
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
	var running_clock := not paused
	while clock.day < target and outcome.is_empty():
		clock.advance_days(1)
		if clock.day_of_month == 1:
			_month_boundary()
		for notice: String in logistics.tick_day(clock.day, crises.active, crises):
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
		if running_clock and _check_supply_alerts():
			break
	changed.emit()


func _check_supply_alerts() -> bool:
	var triggered := false
	for crisis: Dictionary in crises.active:
		var forecast := crises.supply_forecast(str(crisis.id), logistics, clock.day)
		var shortage := int(forecast.first_shortage_day)
		var critical := bool(forecast.has_shortage) and shortage <= clock.day + 3
		if not critical:
			crisis.supply_alerted = false
		elif not bool(crisis.supply_alerted):
			crisis.supply_alerted = true
			paused = true
			triggered = true
			log_message(
				"%s: yardım ikmali gerekli; takvim durduruldu." % areas[int(crisis.area_id)].name
			)
			supply_warning_requested.emit(str(crisis.id))
	return triggered


func _month_boundary() -> void:
	var settlement := treasury.collect_and_maintain(areas, projects)
	var management_notices := projects.age_capacity()
	var previous_progress: Dictionary = {}
	for project: ActiveProject in projects.projects:
		previous_progress[project.uid] = project.progress_months
	var awareness_was_complete := projects.awareness_complete()
	for completion: Dictionary in projects.tick_month(clock.year, bool(settlement.can_pay_budget)):
		reward_earned.emit()
		if completion.get("definition_id") == "repair":
			var area: ServiceArea = areas[int(completion.area_id)]
			log_message(
				(
					"%s: onarım tamamlandı. Kalan altyapı hasarı %%%d."
					% [area.name, roundi(area.damage)]
				)
			)
		else:
			log_message(str(completion.get("message", completion.get("title", "Proje tamamlandı"))))
	if not awareness_was_complete and projects.awareness_complete():
		log_message("Bilinç geliştirmeleri tamamlandı, yeni bilinç baloncukları üretilmeyecek.")
	for notice: String in decisions.review_month(clock.day, previous_progress):
		management_notices.append(notice)
	trust.review_recovery(clock.day, areas)
	trust.decay_month(projects.get_effect(0, "trust_decay_reduction"))
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
	if not management_notices.is_empty():
		for notice: String in management_notices:
			log_message(notice)
		paused = true
		management_warning_requested.emit("\n".join(management_notices))


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
	if news_queue.is_empty() or news_queue.front().kind == "decision":
		return
	var item: Dictionary = news_queue.pop_front()
	if item.kind == "report":
		var event_id := report_event_id(report_for(item.id))
		if (
			decisions._finished_day(self, event_id) >= decisions.since_day
			and not decisions._report_pending(self, event_id)
		):
			for id: String in decisions.offer(event_id, clock.day):
				news_queue.append({"kind": "decision", "id": id})
	changed.emit()
	if not news_queue.is_empty():
		notification_requested.emit()


func choose_decision(id: String, option_id: String) -> Dictionary:
	if (
		news_queue.is_empty()
		or news_queue.front().kind != "decision"
		or news_queue.front().id != id
	):
		return {"ok": false, "message": "Önce sıradaki karar gazetesini açın."}
	var result := decisions.choose(id, option_id, clock.day, clock.year)
	if result.ok:
		news_queue.pop_front()
		log_message(result.message)
		_check_ending()
		changed.emit()
		if not news_queue.is_empty():
			notification_requested.emit()
	return result


func start_project(id: String, area_id: int = 0) -> Dictionary:
	if not outcome.is_empty():
		return {"ok": false, "message": "Oyun tamamlandı"}
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


func enqueue_preparation(id: String, area_id: int) -> Dictionary:
	if not outcome.is_empty():
		return {"ok": false, "message": "Oyun tamamlandı"}
	var result := projects.enqueue_preparation(id, area_id, clock.year)
	if result.ok:
		learn("investment")
		log_message(result.message)
		changed.emit()
	return result


func cancel_project(uid: int) -> Dictionary:
	if not outcome.is_empty():
		return {"ok": false, "message": "Oyun tamamlandı"}
	var result := projects.cancel(uid)
	if result.ok:
		log_message(result.message)
		_check_ending()
		changed.emit()
	return result


func cancel_preparation(uid: int) -> Dictionary:
	if not outcome.is_empty():
		return {"ok": false, "message": "Oyun tamamlandı"}
	var project := projects.get_project(uid)
	if (
		project == null
		or project.status != "queued"
		or not project.definition_id in ProjectSystem.PREPARATION_IDS
	):
		return {"ok": false, "message": "Yalnız sırada bekleyen hazırlık geri alınabilir."}
	var result := projects.cancel(uid)
	if result.ok:
		result.message = "Sıradaki hazırlık geri alındı; ödeme yapılmamıştı."
		log_message(result.message)
		changed.emit()
	return result


func preparation_plan() -> Dictionary:
	return projects.preparation_plan(clock.year)


func map_overlay(mode: int) -> Dictionary:
	if mode < 0 or mode > 3:
		return {}
	var maximum := MAP_STOCK_SCALE if mode == 2 else 100.0
	var overlay_areas: Dictionary = {}
	for area: ServiceArea in areas.values():
		var value := 0.0
		match mode:
			1:
				for kind: String in ["earthquake", "flood", "fire", "avalanche", "landslide"]:
					value += projects.preparedness(area.id, kind) / 5.0
			2:
				value = float(area.stock)
			3:
				value = area.damage
		overlay_areas[area.id] = {
			"name": area.name,
			"region": area.region,
			"value": value,
			"ratio": clampf(value / maximum, 0.0, 1.0)
		}
	return {"mode": mode, "minimum": 0.0, "maximum": maximum, "areas": overlay_areas}


func unit_overview() -> Dictionary:
	var overview := logistics.unit_overview()
	for center: Dictionary in overview.centers:
		center.can_dispatch = false
		if not outcome.is_empty():
			center.dispatch_message = "Oyun tamamlandı"
		elif crises.active.is_empty():
			center.dispatch_message = "Gönderim için aktif afet gerekiyor"
		elif int(center.ready) == 0 and int(center.stock) == 0:
			center.dispatch_message = "Merkezde hazır ekip veya yardım yok"
		else:
			center.can_dispatch = true
			center.dispatch_message = "Bu merkezden gönderim hazırla"
	return overview


func dispatch(
	source: int, crisis_id: String, kind: String, amount: int, home: int = 0
) -> Dictionary:
	var crisis := crises.get_crisis(crisis_id)
	if crisis.is_empty() or not outcome.is_empty():
		return {"ok": false, "message": "Aktif hedef kriz seçilmeli"}
	var preview := dispatch_preview(source, crisis_id, kind, amount, home)
	if not preview.ok:
		return preview
	var result := logistics.dispatch(
		source, int(crisis.area_id), crisis_id, kind, amount, clock.day, home
	)
	if result.ok:
		learn("dispatch")
		log_message(result.message)
		for notice: String in logistics.tick_day(clock.day, crises.active, crises):
			log_message(notice)
		_rearm_supply_alerts()
		changed.emit()
	return result


func transfer_preview(
	source: int, target: int, kind: String, amount: int, home: int = 0
) -> Dictionary:
	var preview := {
		"ok": false,
		"message": "Geçerli merkez ve kaynak seçin",
		"days": 0,
		"fee": 0,
		"available": 0,
		"arrival": clock.day,
		"home": source if home == 0 else home
	}
	if not outcome.is_empty():
		preview.message = "Oyun tamamlandı"
		return preview
	preview.merge(logistics.quote(source, target, kind, amount, home, "transfer"), true)
	preview.arrival = clock.day + int(preview.days)
	if source == target:
		preview.ok = false
		preview.message = "Farklı bir hedef merkez seçin"
	elif preview.ok and int(preview.fee) > treasury.money:
		preview.ok = false
		preview.message = "Taşıma bütçesi yetersiz"
	return preview


func transfer_resources(
	source: int, target: int, kind: String, amount: int, home: int = 0
) -> Dictionary:
	var preview := transfer_preview(source, target, kind, amount, home)
	if not preview.ok:
		return preview
	var result := logistics.transfer(source, target, kind, amount, clock.day, home)
	if result.ok:
		log_message(result.message)
		for notice: String in logistics.tick_day(clock.day, crises.active, crises):
			log_message(notice)
		changed.emit()
	return result


func recall_teams(location: int, home: int, amount: int) -> Dictionary:
	if location == home:
		return {"ok": false, "message": "Ekip zaten asıl merkezinde"}
	return transfer_resources(location, home, "team", amount, home)


func _rearm_supply_alerts() -> void:
	for crisis: Dictionary in crises.active:
		var forecast := crises.supply_forecast(str(crisis.id), logistics, clock.day)
		if not bool(forecast.has_shortage) or int(forecast.first_shortage_day) > clock.day + 3:
			crisis.supply_alerted = false


func crisis_feedback(crisis_id: String) -> Dictionary:
	return crises.feedback(crisis_id, logistics)


func shipment_progress(shipment: Dictionary) -> float:
	var fraction := (
		clampf(_accumulator / CRISIS_DAY_SECONDS, 0.0, 1.0) if not crises.active.is_empty() else 0.0
	)
	var remaining := float(int(shipment.arrival) - clock.day) - fraction
	return 1.0 - clampf(remaining / maxi(1, int(shipment.days)), 0.0, 1.0)


func dispatch_preview(
	source: int, crisis_id: String, kind: String, amount: int, home: int = 0
) -> Dictionary:
	return _dispatch_preview(source, crisis_id, kind, amount, home)


func _dispatch_preview(
	source: int, crisis_id: String, kind: String, amount: int, home: int, stock_limit: int = -1
) -> Dictionary:
	var result := {
		"ok": false,
		"message": "Aktif hedef kriz seçilmeli",
		"source": source,
		"home": source if home == 0 else home,
		"source_name": areas[source].name if areas.has(source) else "",
		"amount": amount,
		"available": 0,
		"days": 0,
		"fee": 0,
		"arrival": clock.day,
		"late": false,
		"missing": 0
	}
	var crisis := crises.get_crisis(crisis_id)
	if crisis.is_empty() or not outcome.is_empty():
		return result
	result.merge(logistics.quote(source, int(crisis.area_id), kind, amount, home), true)
	result.arrival = clock.day + int(result.days)
	result.late = int(result.arrival) > int(crisis.start) + int(crisis.window)
	if kind in ["team", "stock"]:
		var key := "teams" if kind == "team" else "stock"
		result.missing = int(crisis_feedback(crisis_id)[key].missing)
		if kind == "stock" and not result.late:
			result.missing = (
				stock_limit
				if stock_limit >= 0
				else _stock_delivery_limit(crisis_id, int(result.arrival))
			)
			if result.ok and amount > int(result.missing):
				result.ok = false
				result.message = "Varışta saha kapasitesi dolu; daha küçük bir parti veya farklı zaman seçin"
	if result.ok and int(result.fee) > treasury.money:
		result.ok = false
		result.message = "Taşıma bütçesi yetersiz"
	return result


func _stock_delivery_limit(crisis_id: String, arrival: int) -> int:
	var crisis := crises.get_crisis(crisis_id)
	var low := 0
	var high := int(crises.requirements(crisis).stock)
	while low < high:
		var middle := ceili(float(low + high) / 2.0)
		var forecast := crises.supply_forecast(
			crisis_id, logistics, clock.day, {"arrival": arrival, "amount": middle}
		)
		if bool(forecast.capacity_ok):
			low = middle
		else:
			high = middle - 1
	return low


func missing_dispatch_amount(source: int, crisis_id: String, kind: String, home: int = 0) -> int:
	var preview := dispatch_preview(source, crisis_id, kind, 1, home)
	if not preview.ok or preview.late:
		return 0
	var crisis := crises.get_crisis(crisis_id)
	return logistics.affordable_amount(
		source, int(crisis.area_id), kind, int(preview.missing), home
	)


func dispatch_options(crisis_id: String, kind: String) -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	var crisis := crises.get_crisis(crisis_id)
	if crisis.is_empty() or not kind in ["team", "stock"]:
		return options
	var stock_limits: Dictionary = {}
	for source: int in areas:
		var arrival := clock.day + logistics.travel_days(source, int(crisis.area_id))
		if kind == "stock" and not stock_limits.has(arrival):
			stock_limits[arrival] = _stock_delivery_limit(crisis_id, arrival)
		var groups: Array[Dictionary] = []
		if kind == "team":
			groups = logistics.ready_groups(source)
		if groups.is_empty():
			groups.append({"home": source})
		for group: Dictionary in groups:
			var owner := int(group.home)
			var preview := _dispatch_preview(
				source,
				crisis_id,
				kind,
				1 if kind == "team" else 10,
				owner,
				int(stock_limits.get(arrival, -1))
			)
			var quick := _quick_status(preview.duplicate())
			preview.merge(
				{
					"name":
					(
						areas[source].name
						if owner == source
						else "%s / üs %s" % [areas[source].name, areas[owner].name]
					),
					"limit":
					(
						0
						if preview.late
						else logistics.affordable_amount(
							source, int(crisis.area_id), kind, int(preview.missing), owner
						)
					),
					"quick_ok": quick.ok,
					"quick_message": quick.message
				}
			)
			options.append(preview)
	options.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			if int(a.days) != int(b.days):
				return int(a.days) < int(b.days)
			if int(a.fee) != int(b.fee):
				return int(a.fee) < int(b.fee)
			if int(a.source) != int(b.source):
				return int(a.source) < int(b.source)
			return int(a.home) < int(b.home)
	)
	return options


func quick_dispatch_preview(
	source: int, crisis_id: String, kind: String, home: int = 0
) -> Dictionary:
	var preview := dispatch_preview(source, crisis_id, kind, 1 if kind == "team" else 10, home)
	return _quick_status(preview)


func _quick_status(preview: Dictionary) -> Dictionary:
	if not preview.ok:
		return preview
	if preview.late:
		preview.ok = false
		preview.message = "Müdahale süresinden sonra varır. Standart formu kullanabilirsin"
	elif int(preview.missing) < int(preview.amount):
		preview.ok = false
		preview.message = (
			"İhtiyaç sahada veya yolda karşılanıyor"
			if int(preview.missing) == 0
			else "Kalan ihtiyaç için Eksik kadar seç düğmesini kullan"
		)
	return preview


func quick_dispatch(source: int, crisis_id: String, kind: String, home: int = 0) -> Dictionary:
	var preview := quick_dispatch_preview(source, crisis_id, kind, home)
	if not preview.ok:
		return preview
	return dispatch(source, crisis_id, kind, int(preview.amount), home)


func fund(crisis_id: String, amount: int) -> Dictionary:
	if not outcome.is_empty():
		return {"ok": false, "message": "Oyun tamamlandı"}
	var result := crises.fund(crisis_id, amount, treasury)
	if result.ok:
		log_message(result.message)
		changed.emit()
	return result


func collect_bubble(id: int) -> void:
	if id in bubbles:
		bubbles.erase(id)
		treasury.awareness_points += 5
		reward_earned.emit()
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


func latest_event() -> Dictionary:
	return historical.events[_event_index - 1] if _event_index > 0 else {}


func report_for(id: String = "") -> Dictionary:
	for report: Dictionary in crises.reports:
		if report.id == id:
			return report
	return crises.reports.back() if id.is_empty() and not crises.reports.is_empty() else {}


func report_event_id(report: Dictionary) -> String:
	return String(report.get("id", "")).trim_suffix("-%d" % int(report.get("area_id", 0)))


func report_feedback(report: Dictionary) -> Dictionary:
	if report.is_empty() or not areas.has(int(report.get("area_id", 0))):
		return {}
	var area: ServiceArea = areas[int(report.area_id)]
	return {
		"area_name": area.name,
		"preparation_summary":
		(
			"Hazırlık tahmini: %d kişi korundu. %d kayıp ve ₺%d hasar önlendi."
			% [report.protected, report.prevented_losses, report.prevented_damage]
		),
		"response_summary":
		(
			"Müdahale desteği %%%d. Tahmini %d kişi kurtarıldı. Güven %+.1f."
			% [roundi(float(report.quality)), report.rescued, report.trust_delta]
		),
		"recovery_summary":
		(
			"Bölge altyapısı iyileşti. Kalan hasar yok."
			if is_zero_approx(area.damage)
			else (
				"Kalan hasar %%%d. Rapor anındaki onarım tahmini ₺%d."
				% [roundi(area.damage), report.repair_estimate]
			)
		)
	}


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
		"version": 4,
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
		"damage_records": trust.damage_records,
		"areas": area_records,
		"projects": projects.to_dict(),
		"decisions": decisions.to_dict(),
		"active": crises.active,
		"reports": crises.reports,
		"shipments": logistics.shipments,
		"stationed": logistics.stationed,
		"shipment_sequence": logistics.sequence,
		"event_index": _event_index,
		"news_queue": news_queue,
		"bubbles": bubbles,
		"ticker": ticker,
		"calm_months": _calm_months,
		"tutorial": tutorial_completed,
		"tutorial_enabled": tutorial_enabled
	}
