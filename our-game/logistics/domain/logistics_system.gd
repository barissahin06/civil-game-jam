class_name LogisticsSystem
extends RefCounted

var shipments: Array[Dictionary] = []
var sequence: int = 0
var _areas: Dictionary
var _treasury: Treasury
var _projects: ProjectSystem


func setup(areas: Dictionary, treasury: Treasury, projects: ProjectSystem = null) -> void:
	_areas = areas
	_treasury = treasury
	_projects = projects


func quote(source: int, target: int, kind: String, amount: int) -> Dictionary:
	if (
		not _areas.has(source)
		or not _areas.has(target)
		or not kind in ["team", "stock"]
		or amount < 1
	):
		return {"ok": false, "message": "Geçersiz sevkiyat"}
	var origin: ServiceArea = _areas[source]
	var destination: ServiceArea = _areas[target]
	var dx := (origin.longitude - destination.longitude) * 85.0
	var dy := (origin.latitude - destination.latitude) * 111.0
	var km := Vector2(dx, dy).length()
	var days := 0 if source == target else (1 if km < 250.0 else (2 if km < 650.0 else 3))
	var available: int = origin.teams if kind == "team" else origin.stock
	var efficiency := (
		_projects.get_effect(source, "logistics_efficiency") if _projects != null else 0.0
	)
	return {
		"ok": available >= amount,
		"message": "Hazır" if available >= amount else "Kaynak merkezde yeterli kapasite yok",
		"days": days,
		"fee":
		roundi(
			days * amount * (100000 if kind == "team" else 2500) / (1.0 + maxf(0.0, efficiency))
		),
		"available": available
	}


func dispatch(
	source: int, target: int, crisis_id: String, kind: String, amount: int, day: int
) -> Dictionary:
	var estimate := quote(source, target, kind, amount)
	if not estimate.ok:
		return estimate
	if not _treasury.spend(int(estimate.fee)):
		return {"ok": false, "message": "Taşıma bütçesi yetersiz"}
	var area: ServiceArea = _areas[source]
	if kind == "team":
		area.teams -= amount
	else:
		area.stock -= amount
	sequence += 1
	shipments.append(
		{
			"id": sequence,
			"source": source,
			"target": target,
			"crisis_id": crisis_id,
			"kind": kind,
			"amount": amount,
			"days": int(estimate.days),
			"arrival": day + int(estimate.days),
			"state": "outbound"
		}
	)
	return {
		"ok": true, "message": "%d gün içinde varış; dönüş taşıma bedeline dahil" % estimate.days
	}


func tick_day(day: int, active: Array[Dictionary]) -> Array[String]:
	var notices: Array[String] = []
	for shipment: Dictionary in shipments:
		if shipment.state == "returning" and day >= int(shipment.arrival):
			_areas[int(shipment.source)].teams += int(shipment.amount)
			shipment.state = "done"
			notices.append("Ekipler %s merkezine döndü" % _areas[int(shipment.source)].name)
		elif shipment.state == "outbound" and day >= int(shipment.arrival):
			var target := _find(active, shipment.crisis_id)
			if target.is_empty():
				_return(shipment, day)
			else:
				var key := "teams" if shipment.kind == "team" else "stock"
				target[key] += int(shipment.amount)
				shipment.state = "deployed" if shipment.kind == "team" else "done"
				notices.append(
					(
						"%s merkezine %d %s ulaştı"
						% [
							_areas[int(shipment.target)].name,
							shipment.amount,
							"ekip" if shipment.kind == "team" else "yardım"
						]
					)
				)
	return notices


func release(crisis_id: String, day: int) -> void:
	for shipment: Dictionary in shipments:
		if shipment.crisis_id == crisis_id and shipment.state == "deployed":
			_return(shipment, day)


func _return(shipment: Dictionary, day: int) -> void:
	if shipment.kind == "team":
		shipment.state = "returning"
		shipment.arrival = day + int(shipment.days)
		if int(shipment.days) == 0:
			_areas[int(shipment.source)].teams += int(shipment.amount)
			shipment.state = "done"
	else:
		# A shipment that misses the response window still supplies local recovery stores.
		_areas[int(shipment.target)].stock += int(shipment.amount)
		shipment.state = "done"


static func _find(active: Array[Dictionary], id: String) -> Dictionary:
	for crisis: Dictionary in active:
		if crisis.id == id:
			return crisis
	return {}
