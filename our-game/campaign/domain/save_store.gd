class_name SaveStore
extends RefCounted

const PATH := "user://campaign_v1.json"
const MAX_FILE_BYTES := 16777216
const MAX_VALUE := 1000000000000
var error: String = ""
var slot_directory: String = "user://"


func slot_path(slot: int) -> String:
	if slot < 0 or slot > 3:
		return ""
	var filename := "campaign_v1.json" if slot == 0 else "manual_%d_v1.json" % slot
	return slot_directory.path_join(filename)


func slot_summaries() -> Array[Dictionary]:
	var previous_error := error
	var summaries: Array[Dictionary] = []
	for slot in range(4):
		var path := slot_path(slot)
		var exists := FileAccess.file_exists(path)
		var summary: Dictionary = {
			"slot": slot,
			"label": "OTOMATİK KAYIT" if slot == 0 else "MANUEL KAYIT %d" % slot,
			"exists": exists,
			"valid": false,
			"game_date": "",
			"start_year": 0,
			"saved_at": FileAccess.get_modified_time(path) if exists else 0,
			"error": ""
		}
		if exists:
			var simulation := load_campaign(path)
			if simulation == null:
				summary.error = error
			else:
				summary.valid = true
				summary.game_date = CalendarClock.day_to_iso(simulation.clock.day)
				summary.start_year = simulation.start_year
		summaries.append(summary)
	error = previous_error
	return summaries


func save(simulation: Simulation, path: String = PATH) -> bool:
	error = ""
	var text := JSON.stringify(simulation.to_dict())
	if text.to_utf8_buffer().size() > MAX_FILE_BYTES or restore(JSON.parse_string(text)) == null:
		error = "Kampanya durumu doğrulanamadı; önceki kayıt korundu."
		return false
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		error = "Kayıt dosyası yazılamadı."
		return false
	file.store_string(text)
	file.flush()
	var written := file.get_error() == OK
	file.close()
	if not written or FileAccess.get_file_as_string(path + ".tmp") != text:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path + ".tmp"))
		error = "Kayıt doğrulanamadı; önceki kayıt korundu."
		return false
	var result := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(path + ".tmp"), ProjectSettings.globalize_path(path)
	)
	if result != OK:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path + ".tmp"))
		error = "Kayıt tamamlanamadı; önceki kayıt korundu."
	return result == OK


func load_campaign(path: String = PATH) -> Simulation:
	error = ""
	if not FileAccess.file_exists(path):
		error = "Devam edilecek kayıt yok."
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > MAX_FILE_BYTES:
		error = "Kayıt okunamadı veya boyutu geçersiz. Dosya korundu."
		return null
	file.close()
	var parsed := JSON.new()
	var simulation: Simulation
	if parsed.parse(FileAccess.get_file_as_string(path)) == OK:
		simulation = restore(parsed.data)
	if simulation == null:
		error = "Kayıt bozuk, sürümü farklı veya katalog değişmiş. Dosya korundu."
	return simulation


func restore(data: Variant) -> Simulation:
	if not data is Dictionary or data.get("version") != 1:
		return null
	for key: String in [
		"start_year",
		"day",
		"speed",
		"money",
		"awareness",
		"income",
		"upkeep",
		"net",
		"shipment_sequence",
		"event_index",
		"calm_months"
	]:
		if not ServiceArea._integer(data.get(key)) or absf(float(data[key])) > MAX_VALUE:
			return null
	if data.start_year < 1950 or data.start_year > 1990 or not int(data.speed) in [1, 2, 4]:
		return null
	if data.money < 0 or data.awareness < 0 or data.shipment_sequence < 0 or data.calm_months < 0:
		return null
	if data.income < 0 or data.upkeep < 0 or int(data.net) != int(data.income) - int(data.upkeep):
		return null
	for key: String in ["maintenance", "trust"]:
		if not ServiceArea._number(data.get(key)):
			return null
	if data.trust < 0 or data.trust > 100 or data.maintenance < 0 or data.maintenance > 1:
		return null
	if (
		not data.get("outcome") in ["", "ending", "defeat"]
		or not data.get("tutorial_enabled") is bool
	):
		return null
	for key: String in [
		"areas",
		"active",
		"reports",
		"shipments",
		"news_queue",
		"bubbles",
		"ticker",
		"tutorial",
		"trust_history"
	]:
		if not data.get(key) is Array or data[key].size() > 20000:
			return null
	var sim := Simulation.new()
	if not sim.setup(int(data.start_year)) or data.get("catalog") != sim.content_fingerprint:
		return null
	var day := int(data.day)
	if (
		day < sim.clock.day
		or day > CalendarClock.date_to_day(Simulation.END_DATE)
		or data.areas.size() != 21
	):
		return null
	if (
		(data.outcome == "ending")
		!= (day == CalendarClock.date_to_day(Simulation.END_DATE) and data.trust > 0)
	):
		return null
	if (data.outcome == "defeat") != (data.trust == 0):
		return null
	var restored: Dictionary = {}
	sim.news_queue.clear()
	sim.ticker.clear()
	sim.crises.active.clear()
	sim.crises.reports.clear()
	sim.logistics.shipments.clear()
	sim.trust.history.clear()
	for record: Variant in data.areas:
		var area := ServiceArea.from_dict(record)
		if area == null or not sim.areas.has(area.id) or restored.has(area.id):
			return null
		var baseline: ServiceArea = sim.areas[area.id]
		if (
			area.province_ids != baseline.province_ids
			or area.name != baseline.name
			or area.region != baseline.region
		):
			return null
		for key: String in [
			"population", "base_income", "base_upkeep", "resilience", "latitude", "longitude"
		]:
			if area.get(key) != baseline.get(key):
				return null
		if area.total_teams > 1000000 or area.stock > 1000000000:
			return null
		restored[area.id] = area
	sim.areas = restored
	sim.projects.setup(sim.projects.definitions, restored, sim.treasury, sim.trust)
	if not sim.projects.restore(data.get("projects")):
		return null
	sim.crises.setup(restored, sim.projects, sim.trust)
	sim.logistics.setup(restored, sim.treasury, sim.projects)
	var event_index := int(data.event_index)
	if event_index < 0 or event_index > sim.historical.events.size():
		return null
	for index in range(sim.historical.events.size()):
		if (int(sim.historical.events[index].day) <= day) != (index < event_index):
			return null
	var crisis_ids: Array[String] = []
	for record: Variant in data.active:
		if not _crisis_valid(record, sim, day) or record.id in crisis_ids:
			return null
		crisis_ids.append(record.id)
		sim.crises.active.append(record.duplicate(true))
	for record: Variant in data.reports:
		if not _report_valid(record, sim, day) or record.id in crisis_ids:
			return null
		crisis_ids.append(record.id)
		sim.crises.reports.append(record.duplicate(true))
	if not _event_records_complete(sim, event_index, day):
		return null
	var shipment_ids: Array[int] = []
	var reserved: Dictionary = {}
	for record: Variant in data.shipments:
		if not record is Dictionary:
			return null
		for key: String in ["id", "source", "target", "amount", "days", "arrival"]:
			if not ServiceArea._integer(record.get(key)) or absf(float(record[key])) > MAX_VALUE:
				return null
		if (
			record.arrival < CalendarClock.date_to_day("%04d-01-01" % sim.start_year)
			or record.arrival > CalendarClock.date_to_day(Simulation.END_DATE) + 3
		):
			return null
		if (
			not restored.has(int(record.source))
			or not restored.has(int(record.target))
			or record.amount < 1
			or record.amount > 1000000000
			or record.days < 0
			or record.days > 3
		):
			return null
		if (
			record.id < 1
			or record.id > data.shipment_sequence
			or int(record.id) in shipment_ids
			or not record.get("crisis_id") in crisis_ids
		):
			return null
		if (
			not record.get("kind") in ["team", "stock"]
			or not record.get("state") in ["outbound", "deployed", "returning", "done"]
		):
			return null
		if record.kind == "team" and record.state != "done":
			reserved[int(record.source)] = (
				int(reserved.get(int(record.source), 0)) + int(record.amount)
			)
		shipment_ids.append(int(record.id))
		sim.logistics.shipments.append(record.duplicate(true))
	if data.shipments.size() != int(data.shipment_sequence) or not _shipment_states_valid(sim, day):
		return null
	for area: ServiceArea in restored.values():
		if area.teams + int(reserved.get(area.id, 0)) != area.total_teams:
			return null
	var queued: Array[String] = []
	var last_news_day := CalendarClock.date_to_day("%d-01-01" % data.start_year)
	for item: Variant in data.news_queue:
		if (
			not item is Dictionary
			or not item.get("kind") in ["newspaper", "report", "research_done"]
			or not item.get("id") is String
		):
			return null
		if item.kind == "research_done":
			if not sim.projects.is_completed(item.id) or ("research_done:" + item.id) in queued:
				return null
			queued.append("research_done:" + item.id)
			sim.news_queue.append(item.duplicate(true))
			continue
		if (
			(item.kind == "newspaper" and sim.event_for(item.id).is_empty())
			or (item.kind == "report" and sim.report_for(item.id).is_empty())
		):
			return null
		var news_day := (
			int(sim.event_for(item.id).day)
			if item.kind == "newspaper"
			else int(sim.report_for(item.id).day)
		)
		var key: String = item.kind + ":" + item.id
		if news_day > day or news_day < last_news_day or key in queued:
			return null
		last_news_day = news_day
		queued.append(key)
		sim.news_queue.append(item.duplicate(true))
	for id: Variant in data.bubbles:
		if (
			not ServiceArea._integer(id)
			or not restored.has(int(id))
			or int(id) in sim.bubbles
			or sim.bubbles.size() >= 3
		):
			return null
		sim.bubbles.append(int(id))
	for text: Variant in data.ticker:
		if not text is String or text.length() > 2000:
			return null
		sim.ticker.append(text)
	for action: Variant in data.tutorial:
		if (
			not action in ["city", "investment", "research", "dispatch"]
			or action in sim.tutorial_completed
		):
			return null
		sim.tutorial_completed.append(action)
	for item: Variant in data.trust_history:
		if (
			not item is Dictionary
			or not ServiceArea._number(item.get("amount"))
			or absf(float(item.amount)) > 100.0
			or not item.get("reason") is String
			or item.reason.length() > 2000
		):
			return null
		sim.trust.history.append(item.duplicate(true))
	sim.clock.set_day(day)
	sim.treasury.money = int(data.money)
	sim.treasury.awareness_points = int(data.awareness)
	sim.treasury.maintenance_ratio = float(data.maintenance)
	sim.treasury.last_income = int(data.income)
	sim.treasury.last_upkeep = int(data.upkeep)
	sim.treasury.last_net = int(data.net)
	sim.trust.value = float(data.trust)
	sim.logistics.sequence = int(data.shipment_sequence)
	sim._event_index = event_index
	sim._calm_months = int(data.calm_months)
	sim.speed = int(data.speed)
	sim.outcome = data.outcome
	sim.tutorial_enabled = data.tutorial_enabled
	sim.paused = true
	return sim


func _crisis_valid(record: Variant, sim: Simulation, day: int) -> bool:
	if not record is Dictionary:
		return false
	for key: String in [
		"area_id",
		"severity",
		"start",
		"window",
		"elapsed",
		"teams",
		"stock",
		"funds",
		"rescued",
		"losses",
		"counter_rescued",
		"counter_losses"
	]:
		if not ServiceArea._integer(record.get(key)) or absf(float(record[key])) > MAX_VALUE:
			return false
	for key: String in ["protection", "damage", "support_sum", "baseline_support_sum"]:
		if not ServiceArea._number(record.get(key)) or record[key] < 0:
			return false
	var event := sim.event_for(str(record.get("event_id", "")))
	if event.is_empty() or not sim.areas.has(int(record.area_id)):
		return false
	if not _area_owns_event(sim.areas[int(record.area_id)], event):
		return false
	if (
		record.get("id") != "%s-%d" % [event.id, record.area_id]
		or record.get("kind") != event.kind
		or record.get("name") != event.name
	):
		return false
	if (
		record.start != event.day
		or record.window != event.response_window_days
		or record.severity != event.severity
	):
		return false
	if (
		record.elapsed < 0
		or record.elapsed >= record.window
		or record.start + record.elapsed != day
	):
		return false
	if record.protection > 100 or record.damage > 100 or record.funds < 0 or record.funds > 5000000:
		return false
	for key: String in ["teams", "stock", "rescued", "losses", "counter_rescued", "counter_losses"]:
		if record[key] < 0 or record[key] > sim.areas[int(record.area_id)].population:
			return false
	return (
		float(record.support_sum) <= float(record.elapsed) * 0.95 + 0.00001
		and float(record.baseline_support_sum) <= float(record.elapsed) * 0.95 + 0.00001
	)


func _report_valid(record: Variant, sim: Simulation, day: int) -> bool:
	if (
		not record is Dictionary
		or not record.get("id") is String
		or not record.get("name") is String
	):
		return false
	for key: String in [
		"area_id",
		"day",
		"exposed",
		"affected",
		"rescued",
		"safe",
		"losses",
		"protected",
		"prevented_losses",
		"prevented_damage",
		"repair_estimate",
		"funds"
	]:
		if (
			not ServiceArea._integer(record.get(key))
			or absf(float(record[key])) > MAX_VALUE
			or (key != "day" and record[key] < 0)
		):
			return false
	for key: String in ["quality", "trust_delta"]:
		if not ServiceArea._number(record.get(key)):
			return false
	if not sim.areas.has(int(record.area_id)):
		return false
	var suffix := "-%d" % int(record.area_id)
	if not String(record.id).ends_with(suffix):
		return false
	var event := sim.event_for(String(record.id).trim_suffix(suffix))
	if (
		event.is_empty()
		or record.name != event.name
		or not _area_owns_event(sim.areas[int(record.area_id)], event)
	):
		return false
	if int(record.day) != int(event.day) + int(event.response_window_days) or record.day > day:
		return false
	if record.exposed > sim.areas[int(record.area_id)].population or record.funds > 5000000:
		return false
	return (
		record.affected + record.safe == record.exposed
		and record.rescued <= record.affected
		and record.losses <= record.affected
		and record.protected <= record.exposed
		and record.quality >= 0
		and record.quality <= 100
		and absf(float(record.trust_delta)) <= 100.0
	)


func _area_owns_event(area: ServiceArea, event: Dictionary) -> bool:
	for province: Variant in event.province_ids:
		if int(province) in area.province_ids:
			return true
	return false


func _event_records_complete(sim: Simulation, event_index: int, day: int) -> bool:
	var expected: Dictionary = {}
	var start_day := CalendarClock.date_to_day("%04d-01-01" % sim.start_year)
	for index: int in range(event_index):
		var event: Dictionary = sim.historical.events[index]
		if int(event.day) < start_day:
			continue
		for area: ServiceArea in sim.areas.values():
			if _area_owns_event(area, event):
				expected["%s-%d" % [event.id, area.id]] = (
					int(event.day) + int(event.response_window_days) > day
				)
	for record: Dictionary in sim.crises.active:
		if not expected.has(record.id) or not bool(expected[record.id]):
			return false
		expected.erase(record.id)
	for record: Dictionary in sim.crises.reports:
		if not expected.has(record.id) or bool(expected[record.id]):
			return false
		expected.erase(record.id)
	return expected.is_empty()


func _shipment_states_valid(sim: Simulation, day: int) -> bool:
	var deployed: Dictionary = {}
	var delivered: Dictionary = {}
	for shipment: Dictionary in sim.logistics.shipments:
		var active := sim.crises.get_crisis(shipment.crisis_id)
		var report := sim.report_for(shipment.crisis_id)
		var target_area := int(active.area_id) if not active.is_empty() else int(report.area_id)
		if int(shipment.target) != target_area:
			return false
		var event_id: String = shipment.crisis_id.trim_suffix("-%d" % target_area)
		var event := sim.event_for(event_id)
		var quote := sim.logistics.quote(
			int(shipment.source), target_area, shipment.kind, int(shipment.amount)
		)
		if int(shipment.days) != int(quote.days):
			return false
		var arrival := int(shipment.arrival)
		var days := int(shipment.days)
		match String(shipment.state):
			"outbound":
				if arrival <= day or arrival > day + days:
					return false
				var dispatch_day := arrival - days
				if (
					dispatch_day < int(event.day)
					or dispatch_day >= int(event.day) + int(event.response_window_days)
				):
					return false
			"deployed":
				if (
					shipment.kind != "team"
					or active.is_empty()
					or arrival > day
					or arrival - days < int(event.day)
				):
					return false
				deployed[shipment.crisis_id] = (
					int(deployed.get(shipment.crisis_id, 0)) + int(shipment.amount)
				)
			"returning":
				if (
					shipment.kind != "team"
					or report.is_empty()
					or days == 0
					or arrival <= day
					or arrival > day + days
					or arrival - days < int(report.day)
				):
					return false
			"done":
				if arrival > day:
					return false
				if shipment.kind == "team" and (report.is_empty() or arrival < int(report.day)):
					return false
				if shipment.kind == "stock" and not active.is_empty():
					delivered[shipment.crisis_id] = (
						int(delivered.get(shipment.crisis_id, 0)) + int(shipment.amount)
					)
	for crisis: Dictionary in sim.crises.active:
		if (
			int(crisis.teams) != int(deployed.get(crisis.id, 0))
			or int(crisis.stock) != int(delivered.get(crisis.id, 0))
		):
			return false
	return true
