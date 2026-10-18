class_name CrisisSystem
extends RefCounted

var active: Array[Dictionary] = []
var reports: Array[Dictionary] = []
var _areas: Dictionary
var _projects: ProjectSystem
var _trust: TrustState
var _logistics: LogisticsSystem


func setup(
	areas: Dictionary, projects: ProjectSystem, trust: TrustState, logistics: LogisticsSystem = null
) -> void:
	_areas = areas
	_projects = projects
	_trust = trust
	_logistics = logistics


func begin(event: Dictionary) -> void:
	var targets: Array[int] = []
	for area: ServiceArea in _areas.values():
		for province: Variant in event.province_ids:
			if int(province) in area.province_ids and not area.id in targets:
				targets.append(area.id)
	for id: int in targets:
		var area: ServiceArea = _areas[id]
		var protection := _projects.preparedness(id, event.kind)
		var damage := _model(event.kind).initial_damage(int(event.severity), protection)
		var previous_damage := area.damage
		area.damage = clampf(area.damage + damage, 0.0, 100.0)
		_trust.record_damage(str(event.id), id, area.damage - previous_damage, int(event.day))
		active.append(
			{
				"id": "%s-%d" % [event.id, id],
				"event_id": event.id,
				"name": event.name,
				"area_id": id,
				"kind": event.kind,
				"severity": event.severity,
				"start": event.day,
				"window": event.response_window_days,
				"elapsed": 0,
				"protection": protection,
				"damage": damage,
				"teams": 0,
				"stock": 0,
				"consumed_stock": 0,
				"aid_coverage_sum": 0.0,
				"supply_alerted": false,
				"funds": 0,
				"support_sum": 0.0,
				"baseline_support_sum": 0.0,
				"rescued": 0,
				"losses": 0,
				"counter_rescued": 0,
				"counter_losses": 0
			}
		)


func get_crisis(id: String) -> Dictionary:
	return LogisticsSystem._find(active, id)


func requirements(crisis: Dictionary) -> Dictionary:
	var daily := int(crisis.severity) * 5
	return {"teams": maxi(1, int(crisis.severity)), "stock": daily * 3, "daily_stock": daily}


func response_support(crisis: Dictionary, logistics: LogisticsSystem = null) -> Dictionary:
	var need := requirements(crisis)
	var transport := _logistics if logistics == null else logistics
	var effective_teams := float(crisis.teams)
	if transport != null:
		effective_teams = 0.0
		for shipment: Dictionary in transport.shipments:
			if (
				shipment.kind == "team"
				and shipment.state == "deployed"
				and shipment.crisis_id == crisis.id
			):
				effective_teams += (
					int(shipment.amount) * _areas[int(shipment.home)].capacity_efficiency()
				)
	var coverage := (
		minf(effective_teams / need.teams, 1.0) * 0.6
		+ minf(float(crisis.stock) / need.daily_stock, 1.0) * 0.4
	)
	var base_support := clampf(
		coverage * _projects.treasury.maintenance_ratio * (1.0 + float(crisis.funds) / 20000000.0),
		0.0,
		0.95
	)
	return {
		"base": base_support,
		"support":
		clampf(
			base_support * (1.0 + _projects.get_effect(int(crisis.area_id), "rescue_efficiency")),
			0.0,
			0.95
		)
	}


func supply_forecast(
	id: String, logistics: LogisticsSystem, day: int, extra: Dictionary = {}
) -> Dictionary:
	var crisis := get_crisis(id)
	if crisis.is_empty():
		return {}
	var need := requirements(crisis)
	var deadline := int(crisis.start) + int(crisis.window)
	var arrivals: Dictionary = {}
	var on_time := 0
	var late := 0
	for shipment: Dictionary in logistics.shipments:
		if (
			shipment.purpose != "crisis"
			or shipment.state != "outbound"
			or shipment.kind != "stock"
			or shipment.crisis_id != id
		):
			continue
		var arrival := int(shipment.arrival)
		if arrival < day:
			continue
		if arrival <= deadline:
			on_time += int(shipment.amount)
			arrivals[arrival] = int(arrivals.get(arrival, 0)) + int(shipment.amount)
		else:
			late += int(shipment.amount)
	if not extra.is_empty():
		var arrival := int(extra.arrival)
		if arrival >= day and arrival <= deadline:
			on_time += int(extra.amount)
			arrivals[arrival] = int(arrivals.get(arrival, 0)) + int(extra.amount)
		elif arrival > deadline:
			late += int(extra.amount)
	var stock := int(crisis.stock)
	var capacity_ok := stock <= int(need.stock)
	var first_shortage_day := -1
	var has_shortage := false
	for forecast_day: int in range(day, deadline + 1):
		stock += int(arrivals.get(forecast_day, 0))
		if stock > int(need.stock):
			capacity_ok = false
		if forecast_day > day:
			var consumed := mini(stock, int(need.daily_stock))
			if consumed < int(need.daily_stock) and not has_shortage:
				first_shortage_day = forecast_day
				has_shortage = true
			stock -= consumed
	return {
		"daily": int(need.daily_stock),
		"capacity": int(need.stock),
		"supply_days": float(crisis.stock) / int(need.daily_stock),
		"first_shortage_day": first_shortage_day,
		"has_shortage": has_shortage,
		"capacity_ok": capacity_ok,
		"on_time": on_time,
		"late": late
	}


func feedback(id: String, logistics: LogisticsSystem) -> Dictionary:
	var crisis := get_crisis(id)
	if crisis.is_empty():
		return {}
	var need := requirements(crisis)
	var result := {
		"id": id,
		"area_id": int(crisis.area_id),
		"area_name": _areas[int(crisis.area_id)].name,
		"preparation": float(crisis.protection),
		"support": float(response_support(crisis, logistics).support) * 100.0,
		"elapsed": int(crisis.elapsed),
		"window": int(crisis.window),
		"remaining": maxi(0, int(crisis.window) - int(crisis.elapsed)),
		"status":
		"aid" if int(crisis.stock) > 0 else ("rescue" if int(crisis.teams) > 0 else "waiting")
	}
	for kind: String in ["team", "stock"]:
		var key := "teams" if kind == "team" else "stock"
		var transit := (
			supply_forecast(id, logistics, int(crisis.start) + int(crisis.elapsed))
			if kind == "stock"
			else logistics.en_route(id, kind, int(crisis.start) + int(crisis.window))
		)
		result[key] = {
			"field": int(crisis[key]),
			"on_time": int(transit.on_time),
			"late": int(transit.late),
			"need": int(need[key]),
			"missing": maxi(0, int(need[key]) - int(crisis[key]) - int(transit.on_time))
		}
		if kind == "stock":
			for name: String in [
				"daily", "capacity", "supply_days", "first_shortage_day", "has_shortage"
			]:
				result.stock[name] = transit[name]
	return result


func fund(id: String, amount: int, treasury: Treasury) -> Dictionary:
	var crisis := get_crisis(id)
	if crisis.is_empty() or amount <= 0 or amount + int(crisis.funds) > 5000000:
		return {"ok": false, "message": "Kriz başına en fazla ₺5 M acil destek"}
	if not treasury.spend(amount):
		return {"ok": false, "message": "Bütçe yetersiz"}
	crisis.funds += amount
	return {"ok": true, "message": "Acil bütçe sahaya aktarıldı"}


func tick_day(day: int, logistics: LogisticsSystem) -> Array[Dictionary]:
	var finished: Array[Dictionary] = []
	for crisis: Dictionary in active.duplicate():
		if day <= int(crisis.start) + int(crisis.elapsed):
			continue
		var model := _model(crisis.kind)
		var area: ServiceArea = _areas[int(crisis.area_id)]
		var need := requirements(crisis)
		var response := response_support(crisis, logistics)
		var base_support := float(response.base)
		var support := float(response.support)
		var consumed := mini(int(crisis.stock), int(need.daily_stock))
		crisis.stock -= consumed
		crisis.consumed_stock += consumed
		crisis.aid_coverage_sum += float(consumed) / int(need.daily_stock)
		crisis.support_sum += support
		crisis.baseline_support_sum += base_support
		var actual := model.estimate(
			area.population,
			int(crisis.severity),
			float(crisis.protection),
			support,
			int(crisis.elapsed),
			int(crisis.window)
		)
		var baseline := model.estimate(
			area.population,
			int(crisis.severity),
			0.0,
			base_support,
			int(crisis.elapsed),
			int(crisis.window)
		)
		crisis.losses += int(actual.losses)
		crisis.counter_losses += int(baseline.losses)
		crisis.elapsed += 1
		actual.rescued = roundi(
			int(actual.affected) * float(crisis.support_sum) / int(crisis.elapsed)
		)
		crisis.rescued = actual.rescued
		crisis.counter_rescued = roundi(
			int(baseline.affected) * float(crisis.baseline_support_sum) / int(crisis.elapsed)
		)
		var previous_damage := area.damage
		area.damage = minf(100.0, area.damage + model.daily_damage(int(crisis.severity), support))
		_trust.record_damage(str(crisis.event_id), area.id, area.damage - previous_damage, day)
		if int(crisis.elapsed) >= int(crisis.window):
			_projects.repair_support[area.id] = mini(
				5000000, int(_projects.repair_support.get(area.id, 0)) + int(crisis.funds)
			)
			var quality := float(crisis.support_sum) / int(crisis.window)
			var aid_coverage := float(crisis.aid_coverage_sum) / int(crisis.window)
			var report: Dictionary = actual.duplicate(true)
			var actual_damage := model.total_damage(
				int(crisis.severity),
				float(crisis.protection),
				int(crisis.elapsed),
				float(crisis.support_sum)
			)
			var baseline_damage := model.total_damage(
				int(crisis.severity), 0.0, int(crisis.elapsed), float(crisis.baseline_support_sum)
			)
			report.merge(
				{
					"id": crisis.id,
					"event_id": crisis.event_id,
					"name": crisis.name,
					"area_id": area.id,
					"day": day,
					"quality": quality * 100.0,
					"severity": int(crisis.severity),
					"preparation": float(crisis.protection) / 100.0,
					"team_coverage": clampf(float(crisis.teams) / int(need.teams), 0.0, 1.0),
					"trust_delta": 0.0,
					"trust_assessed": false,
					"losses": crisis.losses,
					"protected": maxi(0, int(baseline.affected) - int(actual.affected)),
					"prevented_losses": maxi(0, int(crisis.counter_losses) - int(crisis.losses)),
					"prevented_damage":
					_projects.repair_cost(maxf(0.0, baseline_damage - actual_damage)),
					"repair_estimate": _projects.cost_for("repair", area.id),
					"funds": crisis.funds,
					"consumed_stock": crisis.consumed_stock,
					"returned_stock": crisis.stock,
					"aid_coverage": aid_coverage
				},
				true
			)
			reports.append(report)
			finished.append(report)
			area.stock += int(crisis.stock)
			crisis.stock = 0
			active.erase(crisis)
			logistics.release(crisis.id, day)
	for report: Dictionary in finished:
		_assess_event(str(report.event_id))
	return finished


func _assess_event(event_id: String) -> void:
	for crisis: Dictionary in active:
		if crisis.event_id == event_id:
			return
	var event_reports: Array[Dictionary] = []
	var preparation := 0.0
	var response := 0.0
	var teams := 0.0
	var aid := 0.0
	var weight := 0.0
	for report: Dictionary in reports:
		if report.event_id != event_id:
			continue
		if bool(report.trust_assessed):
			return
		event_reports.append(report)
		var exposed := float(maxi(1, int(report.exposed)))
		weight += exposed
		preparation += float(report.preparation) * exposed
		response += float(report.quality) / 100.0 * exposed
		teams += float(report.team_coverage) * exposed
		aid += float(report.aid_coverage) * exposed
	if event_reports.is_empty():
		return
	var carrier: Dictionary = event_reports.back()
	var delta := _trust.assess_response(
		preparation / weight,
		response / weight,
		teams / weight,
		aid / weight,
		"%s ulusal müdahale sonucu" % carrier.name,
		float(carrier.severity)
	)
	for report: Dictionary in event_reports:
		report.trust_assessed = true
	carrier.trust_delta = delta
	carrier.national_trust_delta = delta


func _model(kind: String) -> DisasterModel:
	return OngoingDisasterModel.new() if kind in ["flood", "fire"] else SuddenDisasterModel.new()
