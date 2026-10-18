extends SceneTree
## Deterministic diagnostic policies; never reads or writes player saves.

const RESERVE := 8000000


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var runs: Array[Dictionary] = []
	for year: int in [1950, 1990]:
		for policy: String in ["no_actions", "teams_only", "preparation_supply", "oversubscribed"]:
			var result := _campaign(year, policy)
			runs.append(result)
			print(JSON.stringify(result))
	var path := ProjectSettings.globalize_path("res://../generated/reports/checks/balance-v4.json")
	var output := FileAccess.open(path, FileAccess.WRITE)
	assert(output != null)
	output.store_string(JSON.stringify({"diagnostic_only": true, "runs": runs}, "  "))
	output.close()
	print("BALANCE_V4_PASS runs=8 no_state_resets=true")
	quit()


func _campaign(year: int, policy: String) -> Dictionary:
	var sim := Simulation.new()
	assert(sim.setup(year))
	var seconds := 0
	var last_month := ""
	var minimum_money := sim.treasury.money
	var minimum_maintenance := 1.0
	var waiting_months := 0
	var dispatches := 0
	var aid_shortfall_days := 0
	var last_day := sim.clock.day
	var response_day := sim.clock.day - 1
	var late_reserve_months: Array[float] = []
	var minimum_trust := sim.trust.value
	var warning_count: Array[int] = [0]
	sim.supply_warning_requested.connect(func(_id: String) -> void: warning_count[0] += 1)
	while sim.outcome.is_empty() and seconds < 6000:
		while not sim.news_queue.is_empty():
			var item: Dictionary = sim.news_queue.front()
			if item.kind == "decision":
				var choice := "decline" if policy in ["no_actions", "teams_only"] else "focused"
				if policy == "preparation_supply":
					var card := sim.decisions.preview(item.id)
					for option: Dictionary in card.options:
						if (
							option.id == "focused"
							and not _can_fund(sim, option.project_id, int(card.area_id))
						):
							choice = "decline"
				assert(sim.choose_decision(item.id, choice).ok)
			else:
				sim.acknowledge()
		var month := "%d-%d" % [sim.clock.year, sim.clock.month]
		if policy in ["preparation_supply", "oversubscribed"]:
			for id: int in sim.bubbles.duplicate():
				sim.collect_bubble(id)
			if month != last_month:
				_prepare(sim, policy == "oversubscribed")
		if month != last_month:
			if sim.clock.year >= maxi(year + 10, 2000):
				var outgoing := sim.treasury.last_upkeep
				for project: ActiveProject in sim.projects.projects:
					if project.occupies_slot():
						outgoing += sim.projects.installment_for(project)
				late_reserve_months.append(float(sim.treasury.money) / maxi(1, outgoing))
			for project: ActiveProject in sim.projects.projects:
				if project.status == "waiting":
					waiting_months += 1
			last_month = month
		if policy != "no_actions" and response_day != sim.clock.day:
			dispatches += _respond(sim, policy != "teams_only")
			response_day = sim.clock.day
		minimum_money = mini(minimum_money, sim.treasury.money)
		minimum_trust = minf(minimum_trust, sim.trust.value)
		minimum_maintenance = minf(minimum_maintenance, sim.treasury.maintenance_ratio)
		sim.set_paused(false)
		sim.update(1.0)
		if sim.clock.day != last_day:
			for crisis: Dictionary in sim.crises.active:
				var daily := int(sim.crises.requirements(crisis).daily_stock)
				if int(crisis.consumed_stock) < int(crisis.elapsed) * daily:
					aid_shortfall_days += 1
			last_day = sim.clock.day
		seconds += 1
	assert(not sim.outcome.is_empty(), "Balance policy did not terminate")
	late_reserve_months.sort()
	var renewals := 0
	for project: ActiveProject in sim.projects.projects:
		if project.definition_id == "center_renewal" and project.status == "completed":
			renewals += 1
	return {
		"start_year": year,
		"policy": policy,
		"date": CalendarClock.day_to_iso(sim.clock.day),
		"outcome": sim.outcome,
		"trust": sim.trust.value,
		"minimum_trust": minimum_trust,
		"completed_renewals": renewals,
		"late_median_reserve_months":
		(
			0.0
			if late_reserve_months.is_empty()
			else late_reserve_months[late_reserve_months.size() / 2]
		),
		"money": sim.treasury.money,
		"minimum_money": minimum_money,
		"minimum_maintenance": minimum_maintenance,
		"monthly_net": sim.treasury.last_net,
		"waiting_project_months": waiting_months,
		"projects": sim.projects.projects.size(),
		"dispatches": dispatches,
		"warnings": warning_count[0],
		"days_after_aid_shortfall": aid_shortfall_days,
		"modeled_seconds": seconds,
		"reports": sim.crises.reports.size(),
		"scores": sim.scores()
	}


func _respond(sim: Simulation, aid: bool) -> int:
	var sent := 0
	var active := sim.crises.active.duplicate()
	active.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool: return int(a.severity) > int(b.severity)
	)
	for crisis: Dictionary in active:
		for kind: String in ["team", "stock"] if aid else ["team"]:
			var origins: Array[Dictionary] = []
			for id: int in sim.areas:
				var quote := sim.logistics.quote(id, int(crisis.area_id), kind, 1)
				if int(quote.available) > 0:
					quote.source = id
					origins.append(quote)
			origins.sort_custom(
				func(a: Dictionary, b: Dictionary) -> bool:
					if int(a.days) != int(b.days):
						return int(a.days) < int(b.days)
					return int(a.source) < int(b.source)
			)
			for option: Dictionary in origins:
				var amount := sim.missing_dispatch_amount(
					int(option.source), crisis.id, kind, int(option.home)
				)
				if (
					amount > 0
					and (
						sim
						. dispatch(int(option.source), crisis.id, kind, amount, int(option.home))
						. ok
					)
				):
					sent += 1
		if aid and int(crisis.funds) == 0 and sim.treasury.money >= RESERVE + 1000000:
			sim.fund(crisis.id, 1000000)
	return sent


func _prepare(sim: Simulation, overcommit: bool) -> void:
	if sim.treasury.maintenance_ratio < 1.0:
		return
	for area: ServiceArea in sim.areas.values():
		if area.condition <= ProjectSystem.RENEWAL_WARNING:
			_try_project(sim, "center_renewal", area.id, overcommit)
		if area.damage >= 10.0:
			_try_project(sim, "repair", area.id, overcommit)
		if area.stock < 80:
			_try_project(sim, "aid_stock", area.id, overcommit)
		if area.total_teams < 2:
			_try_project(sim, "rescue_team", area.id, overcommit)
		for id: String in [
			"river_zoning",
			"assembly_areas",
			"strengthening",
			"firebreak",
			"slope_control",
			"gas_cutoff"
		]:
			if _try_project(sim, id, area.id, overcommit):
				break
	for definition: MeasureDefinition in sim.projects.definitions.values():
		if definition.is_research() or definition.kind == "national":
			_try_project(sim, definition.id, 0, overcommit)


func _try_project(sim: Simulation, id: String, area_id: int, overcommit: bool) -> bool:
	if not overcommit and sim.treasury.money < RESERVE:
		return false
	if not sim.projects.availability(id, area_id, sim.clock.year).ok:
		return false
	if not overcommit:
		var proposed_definition := sim.projects.definition_for(id)
		if proposed_definition.kind in ["local", "national", "team"]:
			var recurring := float(sim.projects.calculate_upkeep())
			for area: ServiceArea in sim.areas.values():
				recurring += (
					sim.projects.installed_value(area.id) * ProjectSystem.RENEWAL_COST_RATIO / 100.0
				)
			for project: ActiveProject in sim.projects.projects:
				if project.status in ["cancelled", "completed"]:
					continue
				var definition := sim.projects.definition_for(project.definition_id)
				recurring += definition.upkeep
				if definition.kind in ["local", "team"]:
					recurring += definition.cost_budget * ProjectSystem.RENEWAL_COST_RATIO / 100.0
			recurring += proposed_definition.upkeep
			if proposed_definition.kind in ["local", "team"]:
				recurring += (
					proposed_definition.cost_budget * ProjectSystem.RENEWAL_COST_RATIO / 100.0
				)
			# A cautious policy leaves income for aid, repairs and installments, including future upkeep.
			if recurring > sim.treasury.last_income * 0.65:
				return false
		if not _can_fund(sim, id, area_id):
			return false
	return bool(sim.start_project(id, area_id).ok)


func _can_fund(sim: Simulation, id: String, area_id: int) -> bool:
	var definition := sim.projects.definition_for(id)
	var cash := float(sim.treasury.money)
	var proposed := sim.projects.cost_for(id, area_id)
	# Use the same upkeep + normal installment definition as the measured reserve.
	for ahead: int in range(1, 13):
		var outgoing := float(sim.treasury.last_upkeep)
		for project: ActiveProject in sim.projects.projects:
			if not project.occupies_slot():
				continue
			var active := sim.projects.definition_for(project.definition_id)
			var remaining := active.months - project.progress_months
			if ahead <= remaining:
				outgoing += float(project.cost_budget - project.paid) / remaining
			else:
				outgoing += active.upkeep
		if ahead <= definition.months:
			outgoing += float(proposed) / definition.months
		else:
			outgoing += definition.upkeep
		cash += sim.treasury.last_income - outgoing
		if cash < outgoing * 4.5:
			return false
	return true
