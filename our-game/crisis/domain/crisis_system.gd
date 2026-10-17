class_name CrisisSystem
extends RefCounted

var active: Array[Dictionary] = []
var reports: Array[Dictionary] = []
var _areas: Dictionary
var _projects: ProjectSystem
var _trust: TrustState


func setup(areas: Dictionary, projects: ProjectSystem, trust: TrustState) -> void:
	_areas = areas
	_projects = projects
	_trust = trust


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
		area.damage = clampf(area.damage + damage, 0.0, 100.0)
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
	return {"teams": maxi(1, int(crisis.severity)), "stock": int(crisis.severity) * 20}


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
		if day <= int(crisis.start):
			continue
		var model := _model(crisis.kind)
		var area: ServiceArea = _areas[int(crisis.area_id)]
		var need := requirements(crisis)
		var coverage := (
			minf(float(crisis.teams) / need.teams, 1.0) * 0.6
			+ minf(float(crisis.stock) / need.stock, 1.0) * 0.4
		)
		var bonus := _projects.get_effect(area.id, "rescue_efficiency")
		var base_support := clampf(
			(
				coverage
				* _projects.treasury.maintenance_ratio
				* (1.0 + float(crisis.funds) / 20000000.0)
			),
			0.0,
			0.95
		)
		var support := clampf(base_support * (1.0 + bonus), 0.0, 0.95)
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
		area.damage = minf(100.0, area.damage + model.daily_damage(int(crisis.severity), support))
		if int(crisis.elapsed) >= int(crisis.window):
			_projects.repair_support[area.id] = mini(
				5000000, int(_projects.repair_support.get(area.id, 0)) + int(crisis.funds)
			)
			var quality := float(crisis.support_sum) / int(crisis.window)
			var trust_delta := _trust.assess_response(
				float(crisis.protection) / 100.0,
				quality,
				float(crisis.teams) / int(need.teams),
				float(crisis.stock) / int(need.stock),
				"%s müdahale sonucu" % area.name
			)
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
					"name": crisis.name,
					"area_id": area.id,
					"day": day,
					"quality": quality * 100.0,
					"trust_delta": trust_delta,
					"losses": crisis.losses,
					"protected": maxi(0, int(baseline.affected) - int(actual.affected)),
					"prevented_losses": maxi(0, int(crisis.counter_losses) - int(crisis.losses)),
					"prevented_damage":
					_projects.repair_cost(maxf(0.0, baseline_damage - actual_damage)),
					"repair_estimate": _projects.cost_for("repair", area.id),
					"funds": crisis.funds
				},
				true
			)
			reports.append(report)
			finished.append(report)
			active.erase(crisis)
			logistics.release(crisis.id, day)
	return finished


func _model(kind: String) -> DisasterModel:
	return OngoingDisasterModel.new() if kind in ["flood", "fire"] else SuddenDisasterModel.new()
