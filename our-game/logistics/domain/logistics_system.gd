class_name LogisticsSystem
extends RefCounted

var shipments: Array[Dictionary] = []
var stationed: Array[Dictionary] = []
var sequence: int = 0
var _areas: Dictionary
var _treasury: Treasury
var _projects: ProjectSystem


func setup(areas: Dictionary, treasury: Treasury, projects: ProjectSystem = null) -> void:
	_areas = areas
	_treasury = treasury
	_projects = projects


func unit_overview() -> Dictionary:
	var summary := {
		"ready": 0, "total": 0, "stock": 0, "outbound": 0, "deployed": 0, "returning": 0
	}
	var centers: Array[Dictionary] = []
	var by_source: Dictionary = {}
	var ids := _areas.keys()
	ids.sort()
	for id: int in ids:
		var area: ServiceArea = _areas[id]
		var center := {
			"area_id": id,
			"name": area.name,
			"ready": area.teams,
			"total": area.total_teams,
			"stock": area.stock,
			"outbound": 0,
			"deployed": 0,
			"returning": 0,
		}
		centers.append(center)
		by_source[id] = center
	for shipment: Dictionary in shipments:
		if shipment.kind == "team" and shipment.state in ["outbound", "deployed", "returning"]:
			by_source[int(shipment.home)][shipment.state] += int(shipment.amount)
	for center: Dictionary in centers:
		center.home_ready = center.ready
		center.groups = ready_groups(int(center.area_id))
		center.guest_ready = 0
		for group: Dictionary in stationed:
			if int(group.location) == int(center.area_id):
				center.guest_ready += int(group.amount)
		center.ready += int(center.guest_ready)
		for key: String in summary:
			summary[key] += int(center[key])
	return {"summary": summary, "centers": centers}


func ready_groups(location: int) -> Array[Dictionary]:
	var groups: Array[Dictionary] = []
	if not _areas.has(location):
		return groups
	if _areas[location].teams > 0:
		groups.append({"home": location, "amount": _areas[location].teams})
	for group: Dictionary in stationed:
		if int(group.location) == location:
			groups.append({"home": int(group.home), "amount": int(group.amount)})
	groups.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.home) < int(b.home))
	return groups


func available_teams(location: int, home: int = 0) -> int:
	var owner := location if home == 0 else home
	for group: Dictionary in ready_groups(location):
		if int(group.home) == owner:
			return int(group.amount)
	return 0


func travel_days(source: int, target: int) -> int:
	if source == target:
		return 0
	var origin: ServiceArea = _areas[source]
	var destination: ServiceArea = _areas[target]
	var km := (
		Vector2(
			(origin.longitude - destination.longitude) * 85.0,
			(origin.latitude - destination.latitude) * 111.0
		)
		. length()
	)
	return 1 if km < 250.0 else (2 if km < 650.0 else 3)


func quote(
	source: int, target: int, kind: String, amount: int, home: int = 0, purpose: String = "crisis"
) -> Dictionary:
	var owner := source if home == 0 else home
	if (
		not _areas.has(source)
		or not _areas.has(target)
		or not kind in ["team", "stock"]
		or amount < 1
		or not _areas.has(owner)
		or not purpose in ["crisis", "transfer"]
	):
		return {"ok": false, "message": "Geçersiz gönderim"}
	var days := travel_days(source, target)
	var return_days := travel_days(target, owner) if kind == "team" and purpose == "crisis" else 0
	var available: int = available_teams(source, owner) if kind == "team" else _areas[source].stock
	var efficiency := (
		_projects.get_effect(source, "logistics_efficiency") if _projects != null else 0.0
	)
	return {
		"ok": available >= amount,
		"message": "Hazır" if available >= amount else "Kaynak merkezde yeterli kapasite yok",
		"days": days,
		"home": owner,
		"return_days": return_days,
		"fee":
		roundi(
			(
				amount
				* ((days + return_days) * 50000 if kind == "team" else days * 2500)
				/ (1.0 + maxf(0.0, efficiency))
			)
		),
		"available": available
	}


func en_route(crisis_id: String, kind: String, deadline: int) -> Dictionary:
	var result := {"on_time": 0, "late": 0}
	for shipment: Dictionary in shipments:
		if (
			shipment.state == "outbound"
			and shipment.purpose == "crisis"
			and shipment.crisis_id == crisis_id
			and shipment.kind == kind
		):
			var key := "on_time" if int(shipment.arrival) <= deadline else "late"
			result[key] += int(shipment.amount)
	return result


func affordable_amount(source: int, target: int, kind: String, maximum: int, home: int = 0) -> int:
	if maximum < 1:
		return 0
	var estimate := quote(source, target, kind, 1, home)
	if not estimate.ok:
		return 0
	var low := 0
	var high := mini(maximum, int(estimate.available))
	# Quotes round the full shipment; dividing a rounded unit fee can overspend.
	while low < high:
		var middle := ceili(float(low + high) / 2.0)
		if int(quote(source, target, kind, middle, home).fee) <= _treasury.money:
			low = middle
		else:
			high = middle - 1
	return low


func dispatch(
	source: int,
	target: int,
	crisis_id: String,
	kind: String,
	amount: int,
	day: int,
	home: int = 0,
	purpose: String = "crisis"
) -> Dictionary:
	var estimate := quote(source, target, kind, amount, home, purpose)
	if not estimate.ok:
		return estimate
	if purpose == "transfer" and source == target:
		return {"ok": false, "message": "Farklı bir hedef merkez seçin"}
	if not _treasury.spend(int(estimate.fee)):
		return {"ok": false, "message": "Taşıma bütçesi yetersiz"}
	var area: ServiceArea = _areas[source]
	if kind == "team":
		if int(estimate.home) == source:
			area.teams -= amount
		else:
			for group: Dictionary in stationed.duplicate():
				if int(group.location) == source and int(group.home) == int(estimate.home):
					group.amount -= amount
					if int(group.amount) == 0:
						stationed.erase(group)
					break
	else:
		area.stock -= amount
	sequence += 1
	shipments.append(
		{
			"id": sequence,
			"source": source,
			"home": int(estimate.home),
			"target": target,
			"purpose": purpose,
			"delivered": false,
			"crisis_id": crisis_id,
			"kind": kind,
			"amount": amount,
			"days": int(estimate.days),
			"return_days": int(estimate.return_days),
			"arrival": day + int(estimate.days),
			"state": "outbound"
		}
	)
	return {
		"ok": true,
		"message":
		(
			"%d gün içinde varış.%s"
			% [
				estimate.days,
				" Asıl merkeze dönüş bedele dahil" if purpose == "crisis" and kind == "team" else ""
			]
		)
	}


func transfer(
	source: int, target: int, kind: String, amount: int, day: int, home: int = 0
) -> Dictionary:
	return dispatch(source, target, "", kind, amount, day, home, "transfer")


func recall(location: int, home: int, amount: int, day: int) -> Dictionary:
	return transfer(location, home, "team", amount, day, home)


func _ready_at(home: int, location: int, amount: int) -> void:
	if home == location:
		_areas[home].teams += amount
		return
	for group: Dictionary in stationed:
		if int(group.home) == home and int(group.location) == location:
			group.amount += amount
			return
	stationed.append({"home": home, "location": location, "amount": amount})


func tick_day(day: int, active: Array[Dictionary], crises: CrisisSystem = null) -> Array[String]:
	var notices: Array[String] = []
	for shipment: Dictionary in shipments:
		if shipment.state == "returning" and day >= int(shipment.arrival):
			_areas[int(shipment.home)].teams += int(shipment.amount)
			shipment.state = "done"
			notices.append("Ekipler %s merkezine döndü" % _areas[int(shipment.home)].name)
		elif shipment.state == "outbound" and day >= int(shipment.arrival):
			if shipment.purpose == "transfer":
				if shipment.kind == "team":
					_ready_at(int(shipment.home), int(shipment.target), int(shipment.amount))
				else:
					_areas[int(shipment.target)].stock += int(shipment.amount)
				shipment.state = "done"
				notices.append("%s: konuşlandırma/ikmal ulaştı" % _areas[int(shipment.target)].name)
				continue
			var target := _find(active, shipment.crisis_id)
			if target.is_empty():
				_return(shipment, day)
			else:
				var key := "teams" if shipment.kind == "team" else "stock"
				target[key] += int(shipment.amount)
				shipment.delivered = true
				shipment.state = "deployed" if shipment.kind == "team" else "done"
				var message := (
					"%s: %d %s"
					% [
						_areas[int(shipment.target)].name,
						shipment.amount,
						"ekip göreve başladı" if shipment.kind == "team" else "yardım sahaya ulaştı"
					]
				)
				if crises != null:
					var feedback := crises.feedback(str(shipment.crisis_id), self)
					message += (
						" / eksik: %d ekip, %d yardım"
						% [feedback.teams.missing, feedback.stock.missing]
					)
				notices.append(message)
	return notices


func release(crisis_id: String, day: int) -> void:
	for shipment: Dictionary in shipments:
		if shipment.crisis_id == crisis_id and shipment.state == "deployed":
			_return(shipment, day)


func _return(shipment: Dictionary, day: int) -> void:
	if shipment.kind == "team":
		shipment.state = "returning"
		shipment.days = int(shipment.return_days)
		shipment.arrival = day + int(shipment.days)
		if int(shipment.days) == 0:
			_areas[int(shipment.home)].teams += int(shipment.amount)
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
