extends GdUnitTestSuite


func _at_decision(card_id: String) -> Simulation:
	var sim := Simulation.new()
	assert_bool(sim.setup()).is_true()
	var card := sim.decisions.card_for(card_id)
	var event := sim.event_for(card.event_ids[0])
	if int(event.day) >= CalendarClock.date_to_day("1990-01-01"):
		assert_bool(sim.setup(1990)).is_true()
	var end := int(event.day) + int(event.response_window_days) + 2
	for iteration in range(1000):
		if not sim.news_queue.is_empty():
			var item: Dictionary = sim.news_queue.front()
			if item.kind == "decision":
				if item.id == card_id:
					return sim
				sim.choose_decision(item.id, "decline")
			else:
				sim.acknowledge()
		else:
			sim.trust.value = 100.0
			sim.advance_to(end)
	assert_bool(false).is_true()
	return sim


func test_three_pilots_require_a_choice_and_preview_matches_completion() -> void:
	for id: String in ["gediz_relocation", "samsun_flood", "construction_inspection"]:
		var sim := _at_decision(id)
		var snapshot := JSON.stringify(sim.to_dict())
		var preview := sim.decisions.preview(id)
		assert_str(JSON.stringify(sim.to_dict())).is_equal(snapshot)
		sim.acknowledge()
		assert_str(sim.news_queue.front().id).is_equal(id)
		sim.set_paused(false)
		assert_bool(sim.paused).is_true()
		var option: Dictionary = preview.options[0]
		var card := sim.decisions.card_for(id)
		var before := sim.projects.preparedness(
			int(card.area_id) if int(card.area_id) > 0 else 34, "earthquake"
		)
		assert_bool(sim.choose_decision(id, "full").ok).is_true()
		assert_bool(sim.choose_decision(id, "decline").ok).is_false()
		(
			assert_float(
				sim.projects.preparedness(
					int(card.area_id) if int(card.area_id) > 0 else 34, "earthquake"
				)
			)
			. is_equal(before)
		)
		(
			assert_object(SaveStore.new().restore(JSON.parse_string(JSON.stringify(sim.to_dict()))))
			. is_not_null()
		)
		for month in range(int(option.months)):
			sim.treasury.money = 1000000000
			sim.projects.tick_month(sim.clock.year)
		var completed := sim.projects.effect_preview(option.project_id, int(card.area_id))
		for index in range(option.effects.rows.size()):
			assert_float(float(completed.rows[index].before)).is_equal_approx(
				float(option.effects.rows[index].after), 0.001
			)
			assert_float(float(completed.rows[index].delta)).is_equal(0.0)
		(
			assert_object(SaveStore.new().restore(JSON.parse_string(JSON.stringify(sim.to_dict()))))
			. is_not_null()
		)


func test_local_and_national_orders_wait_without_payment_and_cancellation_keeps_choice() -> void:
	for id: String in ["gediz_relocation", "construction_inspection"]:
		var sim := _at_decision(id)
		var area_id := int(sim.decisions.card_for(id).area_id)
		if area_id == 0 and not "research_radio" in sim.projects.global_completed:
			sim.projects.global_completed.append("research_radio")
		var blocker := sim.start_project("strengthening" if area_id else "national_radio", area_id)
		assert_bool(blocker.ok).is_true()
		var result := sim.choose_decision(id, "full")
		assert_bool(result.ok).is_true()
		var project := sim.projects.get_project(int(result.uid))
		assert_str(project.status).is_equal("queued")
		assert_int(project.paid).is_equal(0)
		(
			assert_object(SaveStore.new().restore(JSON.parse_string(JSON.stringify(sim.to_dict()))))
			. is_not_null()
		)
		sim.projects.cancel(int(blocker.uid))
		assert_str(project.status).is_equal("active")
		assert_int(project.paid).is_equal(0)
		sim.projects.tick_month(sim.clock.year, false)
		assert_int(project.progress_months).is_equal(0)
		sim.projects.cancel(project.uid)
		assert_str(sim.decisions.records[id].choice_id).is_equal("full")
		(
			assert_bool(sim.projects.start(project.definition_id, area_id, sim.clock.year).ok)
			. is_false()
		)
		(
			assert_bool(
				sim.projects.enqueue_decision(project.definition_id, area_id, sim.clock.year).ok
			)
			. is_false()
		)


func test_decline_is_permanent_and_never_grants_money_or_a_project() -> void:
	var sim := _at_decision("samsun_flood")
	var money := sim.treasury.money
	var count := sim.projects.projects.size()
	sim.trust.value = 20.0
	assert_bool(sim.choose_decision("samsun_flood", "decline").ok).is_true()
	assert_float(sim.trust.value).is_equal(20.0)
	assert_int(sim.treasury.money).is_equal(money)
	assert_int(sim.projects.projects.size()).is_equal(count)
	for option: Dictionary in sim.decisions.card_for("samsun_flood").options:
		if not String(option.project_id).is_empty():
			assert_bool(sim.start_project(option.project_id, 55).ok).is_false()
	assert_array(sim.decisions.offer("historical-058", sim.clock.day)).is_empty()
	(
		assert_object(SaveStore.new().restore(JSON.parse_string(JSON.stringify(sim.to_dict()))))
		. is_not_null()
	)


func test_invalid_pending_and_project_links_are_rejected() -> void:
	var sim := _at_decision("gediz_relocation")
	var data := sim.to_dict()
	var store := SaveStore.new()
	assert_object(store.restore(data)).is_not_null()
	var bad := data.duplicate(true)
	bad.news_queue.clear()
	assert_object(store.restore(bad)).is_null()
	bad = data.duplicate(true)
	bad.decisions.records.gediz_relocation.choice_id = "invented"
	assert_object(store.restore(bad)).is_null()
	sim.choose_decision("gediz_relocation", "full")
	bad = sim.to_dict()
	bad.decisions.records.gediz_relocation.project_uid = 999999
	assert_object(store.restore(bad)).is_null()
	var project := sim.projects.get_project(int(sim.decisions.records.gediz_relocation.project_uid))
	for month in range(12):
		sim.treasury.money = 1000000000
		sim.projects.tick_month(sim.clock.year)
	bad = sim.to_dict()
	for area: Dictionary in bad.areas:
		if int(area.id) == 3:
			area.completed_measures.erase(project.definition_id)
	assert_object(store.restore(bad)).is_null()
	bad = sim.to_dict()
	bad.decisions.records.gediz_relocation.chosen_day += 1
	assert_object(store.restore(bad)).is_null()


func test_old_save_versions_are_rejected_without_migration() -> void:
	var sim := Simulation.new()
	assert_bool(sim.setup()).is_true()
	for version: int in [1, 2, 3]:
		var data := sim.to_dict()
		data.version = version
		assert_object(SaveStore.new().restore(data)).is_null()
	assert_int(int(sim.to_dict().version)).is_equal(4)


func test_every_card_and_alternative_round_trips_and_only_pays_once() -> void:
	var baseline := Simulation.new()
	assert_bool(baseline.setup()).is_true()
	assert_int(baseline.decision_catalog.cards.size()).is_equal(21)
	var store := SaveStore.new()
	for card: Dictionary in baseline.decision_catalog.cards:
		var pending := _at_decision(card.id).to_dict()
		for candidate: Dictionary in card.options:
			var sim := store.restore(JSON.parse_string(JSON.stringify(pending)))
			assert_object(sim).is_not_null()
			if sim == null:
				return
			var snapshot := JSON.stringify(sim.to_dict())
			var catalog_snapshot := JSON.stringify(sim.decision_catalog.cards)
			var preview := sim.decisions.preview(card.id)
			assert_str(JSON.stringify(sim.to_dict())).is_equal(snapshot)
			assert_str(JSON.stringify(sim.decision_catalog.cards)).is_equal(catalog_snapshot)
			var option: Dictionary
			for row: Dictionary in preview.options:
				if row.id == candidate.id:
					option = row
			var result := sim.choose_decision(card.id, candidate.id)
			assert_bool(result.ok).is_true()
			if candidate.id in ["full", "focused"]:
				assert_str(result.message).is_equal("Kalıcı karar: " + String(option.title))
			if candidate.id == "full":
				assert_str(option.description).is_equal(candidate.description)
			if candidate.id == "focused":
				assert_bool(String(option.title).begins_with("Önce")).is_false()
				assert_bool(String(option.description).begins_with("Önce")).is_false()
				if card.id == "samsun_flood":
					assert_str(option.title).is_equal("Bir arama kurtarma ekibi kur")
			assert_bool(sim.choose_decision(card.id, candidate.id).ok).is_false()
			if int(result.uid) > 0:
				var project := sim.projects.get_project(int(result.uid))
				for month in range(int(option.months)):
					sim.treasury.money = 1000000000
					sim.projects.tick_month(sim.clock.year)
				assert_str(project.status).is_equal("completed")
				assert_int(project.paid).is_equal(int(option.cost_budget))
				var complete := sim.projects.effect_preview(option.project_id, int(card.area_id))
				for index in range(option.effects.rows.size()):
					assert_float(float(complete.rows[index].before)).is_equal_approx(
						float(option.effects.rows[index].after), 0.001
					)
					assert_float(float(complete.rows[index].delta)).is_equal(0.0)
				var money := sim.treasury.money
				sim.projects.tick_month(sim.clock.year)
				assert_int(sim.treasury.money).is_equal(money)
			(
				assert_object(store.restore(JSON.parse_string(JSON.stringify(sim.to_dict()))))
				. is_not_null()
			)


func test_decision_project_and_stationed_teams_restore_without_repayment() -> void:
	var sim := _at_decision("gediz_relocation")
	assert_bool(sim.choose_decision("gediz_relocation", "full").ok).is_true()
	assert_bool(sim.transfer_resources(6, 31, "team", 1).ok).is_true()
	sim.advance_to(sim.clock.day + 3)
	var money := sim.treasury.money
	var data: Variant = JSON.parse_string(JSON.stringify(sim.to_dict()))
	var loaded := SaveStore.new().restore(data)
	assert_object(loaded).is_not_null()
	if loaded != null:
		assert_int(loaded.treasury.money).is_equal(money)
		assert_int(loaded.logistics.available_teams(31, 6)).is_equal(1)
		assert_str(loaded.decisions.records.gediz_relocation.choice_id).is_equal("full")
		assert_bool(loaded.choose_decision("gediz_relocation", "full").ok).is_false()
		assert_int(loaded.treasury.money).is_equal(money)


func _review_day(chosen: int, months: int) -> int:
	var month := TrustState.month_index(chosen) + months
	return CalendarClock.date_to_day("%04d-%02d-01" % [int(month / 12), month % 12 + 1])


func _queued_promise() -> Simulation:
	var sim := _at_decision("gediz_relocation")
	assert_bool(sim.start_project("strengthening", 3).ok).is_true()
	assert_bool(sim.choose_decision("gediz_relocation", "full").ok).is_true()
	return sim


func test_queued_promise_warns_once_then_loses_trust_monthly_until_real_progress() -> void:
	var sim := _queued_promise()
	var record: Dictionary = sim.decisions.records.gediz_relocation
	var chosen := int(record.chosen_day)
	var project := sim.projects.get_project(int(record.project_uid))
	assert_str(project.status).is_equal("queued")
	var previous := {project.uid: project.progress_months}
	var before := sim.trust.value
	sim.clock.set_day(_review_day(chosen, 6))
	assert_array(sim.decisions.review_month(sim.clock.day, previous)).is_empty()
	sim.clock.set_day(_review_day(chosen, 7))
	assert_int(sim.decisions.review_month(sim.clock.day, previous).size()).is_equal(1)
	assert_float(sim.trust.value).is_equal(before)
	assert_array(sim.decisions.review_month(sim.clock.day, previous)).is_empty()
	sim.clock.set_day(_review_day(chosen, 13))
	sim.decisions.review_month(sim.clock.day, previous)
	assert_float(sim.trust.value).is_equal_approx(before - 0.1, 0.000001)
	assert_array(sim.decisions.review_month(sim.clock.day, previous)).is_empty()
	sim.clock.set_day(_review_day(chosen, 14))
	sim.decisions.review_month(sim.clock.day, previous)
	assert_float(sim.trust.value).is_equal_approx(before - 0.2, 0.000001)
	for blocker: ActiveProject in sim.projects.projects:
		if blocker.area_id == 3 and blocker.uid != project.uid and blocker.occupies_slot():
			sim.projects.cancel(blocker.uid)
	assert_bool(sim.projects.pause(project.uid).ok).is_true()
	assert_bool(sim.projects.resume(project.uid).ok).is_true()
	assert_int(record.last_progress_day).is_equal(chosen)
	sim.clock.set_day(_review_day(chosen, 15))
	sim.treasury.money = 1000000000
	sim.projects.tick_month(sim.clock.year)
	sim.decisions.review_month(sim.clock.day, previous)
	assert_int(record.last_progress_day).is_equal(sim.clock.day)
	assert_float(sim.trust.value).is_equal_approx(before - 0.2, 0.000001)
	assert_bool(sim.projects.pause(project.uid).ok).is_true()
	sim.clock.set_day(_review_day(int(record.last_progress_day), 6))
	previous[project.uid] = project.progress_months
	assert_int(sim.decisions.review_month(sim.clock.day, previous).size()).is_equal(1)


func test_promise_restore_preserves_warning_and_rejects_timer_resets() -> void:
	var sim := _queued_promise()
	var record: Dictionary = sim.decisions.records.gediz_relocation
	var project := sim.projects.get_project(int(record.project_uid))
	var previous := {project.uid: project.progress_months}
	sim.clock.set_day(_review_day(int(record.chosen_day), 7))
	assert_int(sim.decisions.review_month(sim.clock.day, previous).size()).is_equal(1)
	var data: Dictionary = JSON.parse_string(JSON.stringify(sim.decisions.to_dict()))
	var restored := DecisionSystem.new()
	restored.setup(sim.decision_catalog, sim.projects, sim.decisions.since_day)
	assert_bool(restored.restore(data, sim)).is_true()
	assert_array(restored.review_month(sim.clock.day, previous)).is_empty()
	var bad := data.duplicate(true)
	bad.records.gediz_relocation.last_progress_day = sim.clock.day
	assert_bool(restored.restore(bad, sim)).is_false()
	bad = data.duplicate(true)
	bad.records.gediz_relocation.last_review_month = TrustState.month_index(sim.clock.day) + 1
	assert_bool(restored.restore(bad, sim)).is_false()
	var before := sim.trust.value
	sim.projects.cancel(project.uid)
	assert_float(sim.trust.value).is_equal_approx(before - 0.5, 0.000001)
	sim.clock.set_day(_review_day(int(record.chosen_day), 13))
	assert_array(restored.review_month(sim.clock.day, previous)).is_empty()
	assert_float(sim.trust.value).is_equal_approx(before - 0.5, 0.000001)


func test_commitment_status_is_read_only_and_distinguishes_normal_and_closed_projects() -> void:
	var sim := _queued_promise()
	var record: Dictionary = sim.decisions.records.gediz_relocation
	var uid := int(record.project_uid)
	sim.clock.set_day(_review_day(int(record.chosen_day), 7))
	var before := JSON.stringify(sim.to_dict())
	var status := sim.decisions.commitment_status(uid, sim.clock.day)
	assert_bool(status.committed).is_true()
	assert_int(status.idle_months).is_equal(6)
	assert_bool(status.warned).is_true()
	assert_bool(status.overdue).is_false()
	assert_str(status.description).contains("6 ayda uyarı")
	assert_str(JSON.stringify(sim.to_dict())).is_equal(before)
	for project: ActiveProject in sim.projects.projects:
		if project.uid != uid:
			(
				assert_bool(sim.decisions.commitment_status(project.uid, sim.clock.day).committed)
				. is_false()
			)
	sim.projects.cancel(uid)
	status = sim.decisions.commitment_status(uid, sim.clock.day)
	assert_bool(status.committed).is_true()
	assert_bool(status.warned).is_false()
	assert_str(status.description).contains("takip kapandı")


func test_cancelling_last_trust_promise_ends_campaign_and_preserves_valid_save() -> void:
	var sim := _queued_promise()
	var uid := int(sim.decisions.records.gediz_relocation.project_uid)
	sim.trust.value = 0.4
	assert_bool(sim.cancel_project(uid).ok).is_true()
	assert_float(sim.trust.value).is_equal(0.0)
	assert_str(sim.outcome).is_equal("defeat")
	assert_bool(sim.paused).is_true()
	(
		assert_object(SaveStore.new().restore(JSON.parse_string(JSON.stringify(sim.to_dict()))))
		. is_not_null()
	)
	var before := JSON.stringify(sim.to_dict())
	assert_bool(sim.cancel_project(sim.projects.projects.front().uid).ok).is_false()
	assert_str(JSON.stringify(sim.to_dict())).is_equal(before)
