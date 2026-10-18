extends GdUnitTestSuite

const TEST_PATH := "user://test-preparation-queue-isolated.json"


func after_test() -> void:
	for suffix: String in ["", ".tmp"]:
		if FileAccess.file_exists(TEST_PATH + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH + suffix))


func _fixture() -> Simulation:
	var sim := Simulation.new()
	assert_bool(sim.setup()).is_true()
	return sim


func _area_row(plan: Dictionary, area_id: int) -> Dictionary:
	for row: Dictionary in plan.areas:
		if int(row.area_id) == area_id:
			return row
	return {}


func _canonical(data: Dictionary) -> String:
	return JSON.stringify(JSON.parse_string(JSON.stringify(data)))


func test_orders_start_in_parallel_without_payment_or_early_output() -> void:
	var sim := _fixture()
	var money := sim.treasury.money
	var upkeep := sim.projects.calculate_upkeep()
	var teams: int = sim.areas[34].teams
	var stock: int = sim.areas[6].stock
	var first := sim.enqueue_preparation("rescue_team", 34)
	var second := sim.enqueue_preparation("aid_stock", 6)
	assert_bool(first.ok and second.ok).is_true()
	assert_int(sim.projects.active_count("local")).is_equal(2)
	assert_int(sim.treasury.money).is_equal(money)
	assert_int(sim.projects.calculate_upkeep()).is_equal(upkeep)
	assert_int(sim.areas[34].teams).is_equal(teams)
	assert_int(sim.areas[6].stock).is_equal(stock)
	sim.projects.tick_month(1950)
	assert_int(sim.treasury.money).is_equal(money - 2000000)
	assert_int(sim.projects.get_project(first.uid).progress_months).is_equal(1)
	assert_int(sim.projects.get_project(second.uid).progress_months).is_equal(1)
	sim.projects.tick_month(1950)
	assert_int(sim.areas[6].stock).is_equal(stock + 40)
	assert_int(sim.areas[34].teams).is_equal(teams)


func test_repeated_clicks_keep_fifo_and_next_job_does_not_pay_on_activation() -> void:
	var sim := _fixture()
	var first := sim.enqueue_preparation("rescue_team", 34)
	var second := sim.enqueue_preparation("aid_stock", 34)
	var third := sim.enqueue_preparation("rescue_team", 34)
	var money := sim.treasury.money
	var teams: int = sim.areas[34].teams
	var upkeep := sim.projects.calculate_upkeep()
	assert_str(sim.projects.get_project(second.uid).status).is_equal("queued")
	assert_str(sim.projects.get_project(third.uid).status).is_equal("queued")
	assert_bool(sim.start_project("rescue_team", 34).ok).is_false()
	for month: int in range(4):
		sim.projects.tick_month(1950)
	assert_str(sim.projects.get_project(first.uid).status).is_equal("completed")
	assert_int(sim.areas[34].teams).is_equal(teams + 1)
	assert_int(sim.projects.calculate_upkeep()).is_equal(upkeep + ProjectSystem.TEAM_UPKEEP)
	assert_str(sim.projects.get_project(second.uid).status).is_equal("active")
	assert_int(sim.projects.get_project(second.uid).progress_months).is_equal(0)
	assert_int(sim.projects.get_project(second.uid).paid).is_equal(0)
	assert_str(sim.projects.get_project(third.uid).status).is_equal("queued")
	assert_int(sim.treasury.money).is_equal(money - 4000000)
	for month: int in range(2):
		sim.projects.tick_month(1950)
	assert_str(sim.projects.get_project(second.uid).status).is_equal("completed")
	assert_str(sim.projects.get_project(third.uid).status).is_equal("active")
	assert_int(sim.projects.get_project(third.uid).paid).is_equal(0)
	assert_int(sim.treasury.money).is_equal(money - 6000000)


func test_busy_city_queues_and_cancellation_opens_only_its_next_order() -> void:
	var sim := _fixture()
	var existing := sim.start_project("river_zoning", 34)
	var first := sim.enqueue_preparation("aid_stock", 34)
	var second := sim.enqueue_preparation("rescue_team", 34)
	var elsewhere := sim.enqueue_preparation("rescue_team", 6)
	assert_str(sim.projects.get_project(first.uid).status).is_equal("queued")
	assert_str(sim.projects.get_project(second.uid).status).is_equal("queued")
	var money := sim.treasury.money
	assert_bool(sim.projects.cancel(existing.uid).ok).is_true()
	assert_str(sim.projects.get_project(first.uid).status).is_equal("active")
	assert_str(sim.projects.get_project(second.uid).status).is_equal("queued")
	assert_str(sim.projects.get_project(elsewhere.uid).status).is_equal("active")
	assert_int(sim.projects.get_project(first.uid).paid).is_equal(0)
	assert_int(sim.treasury.money).is_equal(money)


func test_cancel_unstarted_order_never_cancels_paid_work_or_charges_money() -> void:
	var sim := _fixture()
	var active := sim.enqueue_preparation("rescue_team", 34)
	var queued := sim.enqueue_preparation("aid_stock", 34)
	sim.projects.tick_month(1950)
	var money := sim.treasury.money
	assert_bool(sim.cancel_preparation(active.uid).ok).is_false()
	assert_bool(sim.cancel_preparation(999).ok).is_false()
	assert_bool(sim.cancel_preparation(queued.uid).ok).is_true()
	assert_bool(sim.cancel_preparation(queued.uid).ok).is_false()
	assert_str(sim.projects.get_project(queued.uid).status).is_equal("cancelled")
	assert_int(sim.projects.get_project(queued.uid).paid).is_equal(0)
	assert_int(sim.projects.get_project(active.uid).progress_months).is_equal(1)
	assert_int(sim.treasury.money).is_equal(money)
	assert_int(sim.preparation_plan().summary.queued_count).is_equal(0)


func test_insufficient_budget_waits_without_skipping_or_charging_queued_orders() -> void:
	var sim := _fixture()
	var first := sim.enqueue_preparation("aid_stock", 34)
	var second := sim.enqueue_preparation("rescue_team", 34)
	sim.treasury.money = 0
	sim.projects.tick_month(1950)
	assert_str(sim.projects.get_project(first.uid).status).is_equal("waiting")
	assert_str(sim.projects.get_project(second.uid).status).is_equal("queued")
	assert_int(sim.projects.get_project(first.uid).progress_months).is_equal(0)
	sim.treasury.money = 2000000
	sim.projects.tick_month(1950, false)
	assert_int(sim.treasury.money).is_equal(2000000)
	assert_int(sim.projects.get_project(first.uid).progress_months).is_equal(0)
	sim.projects.tick_month(1950)
	sim.projects.tick_month(1950)
	assert_str(sim.projects.get_project(first.uid).status).is_equal("completed")
	assert_str(sim.projects.get_project(second.uid).status).is_equal("active")
	assert_int(sim.projects.get_project(second.uid).paid).is_equal(0)
	assert_int(sim.treasury.money).is_equal(0)


func test_paused_same_action_blocks_fifo_until_resume_and_other_city_continues() -> void:
	var sim := _fixture()
	var paused := sim.enqueue_preparation("rescue_team", 34)
	var head := sim.enqueue_preparation("rescue_team", 34)
	var behind := sim.enqueue_preparation("aid_stock", 34)
	var elsewhere := sim.enqueue_preparation("aid_stock", 6)
	assert_bool(sim.projects.pause(paused.uid).ok).is_true()
	assert_bool(sim.projects.pause(head.uid).ok).is_false()
	assert_bool(sim.projects.resume(head.uid).ok).is_false()
	var row := _area_row(sim.preparation_plan(), 34)
	assert_bool(row.busy).is_false()
	assert_str(row.queued_blocked_reason).contains("Duraklatılan Arama kurtarma ekibi kur")
	sim.projects.tick_month(1950)
	assert_str(sim.projects.get_project(head.uid).status).is_equal("queued")
	assert_str(sim.projects.get_project(behind.uid).status).is_equal("queued")
	assert_int(sim.projects.get_project(elsewhere.uid).progress_months).is_equal(1)
	assert_bool(sim.projects.resume(paused.uid).ok).is_true()
	for month: int in range(4):
		sim.projects.tick_month(1950)
	assert_str(sim.projects.get_project(head.uid).status).is_equal("active")
	assert_int(sim.projects.get_project(head.uid).paid).is_equal(0)
	assert_str(sim.projects.get_project(behind.uid).status).is_equal("queued")


func test_pause_leaves_slot_for_manual_action_and_paused_cancel_unblocks_head() -> void:
	var sim := _fixture()
	var paused := sim.enqueue_preparation("rescue_team", 34)
	var head := sim.enqueue_preparation("aid_stock", 34)
	assert_bool(sim.projects.pause(paused.uid).ok).is_true()
	assert_str(sim.projects.get_project(head.uid).status).is_equal("queued")
	var manual := sim.start_project("river_zoning", 34)
	assert_bool(manual.ok).is_true()
	assert_bool(sim.projects.resume(paused.uid).ok).is_false()
	assert_bool(sim.projects.cancel(manual.uid).ok).is_true()
	assert_str(sim.projects.get_project(head.uid).status).is_equal("active")
	assert_int(sim.projects.get_project(head.uid).paid).is_equal(0)
	var same := sim.enqueue_preparation("rescue_team", 34)
	assert_bool(sim.projects.cancel(head.uid).ok).is_true()
	assert_str(sim.projects.get_project(same.uid).status).is_equal("queued")
	assert_bool(sim.projects.cancel(paused.uid).ok).is_true()
	assert_str(sim.projects.get_project(same.uid).status).is_equal("active")


func test_cancel_blocked_fifo_head_activates_following_action_without_charge() -> void:
	var sim := _fixture()
	var paused := sim.enqueue_preparation("rescue_team", 34)
	var head := sim.enqueue_preparation("rescue_team", 34)
	var behind := sim.enqueue_preparation("aid_stock", 34)
	sim.projects.pause(paused.uid)
	var money := sim.treasury.money
	assert_bool(sim.cancel_preparation(head.uid).ok).is_true()
	assert_str(sim.projects.get_project(behind.uid).status).is_equal("active")
	assert_int(sim.projects.get_project(behind.uid).paid).is_equal(0)
	assert_int(sim.treasury.money).is_equal(money)


func test_command_validation_does_not_allocate_invalid_or_ended_orders() -> void:
	var sim := _fixture()
	for id: String in ["missing", "river_zoning", "repair", "national_radio"]:
		assert_bool(sim.enqueue_preparation(id, 34).ok).is_false()
	assert_bool(sim.enqueue_preparation("rescue_team", 0).ok).is_false()
	assert_bool(sim.projects.enqueue_preparation("rescue_team", 34, 1949).ok).is_false()
	var definition := sim.projects.definition_for("rescue_team")
	definition.prerequisites.append("research_structural")
	assert_bool(sim.enqueue_preparation("rescue_team", 34).ok).is_false()
	assert_int(sim.projects.projects.size()).is_equal(0)
	assert_int(sim.projects.to_dict().next_uid).is_equal(1)
	definition.prerequisites.clear()
	var queued := sim.enqueue_preparation("rescue_team", 34)
	var extra := sim.enqueue_preparation("aid_stock", 34)
	assert_bool(queued.ok and extra.ok).is_true()
	sim.outcome = "ending"
	assert_bool(sim.enqueue_preparation("rescue_team", 6).ok).is_false()
	assert_bool(sim.cancel_preparation(extra.uid).ok).is_false()
	assert_int(sim.projects.projects.size()).is_equal(2)


func test_save_round_trip_preserves_queue_payment_and_does_not_activate_on_load() -> void:
	var sim := _fixture()
	var first := sim.enqueue_preparation("rescue_team", 34)
	var second := sim.enqueue_preparation("aid_stock", 34)
	sim.enqueue_preparation("rescue_team", 34)
	sim.enqueue_preparation("rescue_team", 34)
	sim.advance_to(CalendarClock.date_to_day("1950-02-01"))
	sim.projects.pause(first.uid)
	var store := SaveStore.new()
	assert_bool(store.save(sim, TEST_PATH)).is_true()
	var restored := store.load_campaign(TEST_PATH)
	assert_object(restored).is_not_null()
	if restored == null:
		return
	assert_str(_canonical(restored.to_dict())).is_equal(_canonical(sim.to_dict()))
	assert_str(restored.projects.get_project(first.uid).status).is_equal("paused")
	assert_str(restored.projects.get_project(second.uid).status).is_equal("queued")
	assert_int(restored.projects.get_project(first.uid).paid).is_equal(1000000)
	var money := restored.treasury.money
	restored.advance_to(CalendarClock.date_to_day("1950-03-01"))
	assert_str(restored.projects.get_project(second.uid).status).is_equal("active")
	assert_int(restored.projects.get_project(second.uid).paid).is_equal(0)
	assert_int(restored.treasury.money).is_equal(money + 3315000)
	var legacy := _fixture()
	assert_bool(legacy.start_project("river_zoning", 34).ok).is_true()
	assert_object(store.restore(JSON.parse_string(JSON.stringify(legacy.to_dict())))).is_not_null()


func test_malformed_queued_records_are_rejected_without_mutating_live_state() -> void:
	var sim := _fixture()
	sim.enqueue_preparation("rescue_team", 34)
	sim.enqueue_preparation("aid_stock", 34)
	var before := sim.projects.to_dict().duplicate(true)
	var bad := before.duplicate(true)
	bad.projects[1].progress_months = 1
	bad.projects[1].paid = 1000000
	assert_bool(sim.projects.restore(bad)).is_false()
	bad = before.duplicate(true)
	bad.projects[1].paid = 1
	assert_bool(sim.projects.restore(bad)).is_false()
	bad = before.duplicate(true)
	bad.projects[1].repair_damage = 1.0
	assert_bool(sim.projects.restore(bad)).is_false()
	bad = before.duplicate(true)
	bad.projects[1].definition_id = "river_zoning"
	bad.projects[1].cost_budget = 6000000
	assert_bool(sim.projects.restore(bad)).is_false()
	bad = before.duplicate(true)
	bad.projects[1].status = "active"
	assert_bool(sim.projects.restore(bad)).is_false()
	bad = before.duplicate(true)
	bad.projects[1].uid = bad.projects[0].uid
	assert_bool(sim.projects.restore(bad)).is_false()
	assert_str(_canonical(sim.projects.to_dict())).is_equal(_canonical(before))
	var saved := sim.to_dict().duplicate(true)
	saved.projects.projects[1].status = "queued"
	saved.projects.projects[1].progress_months = 1
	saved.projects.projects[1].paid = 1000000
	assert_object(SaveStore.new().restore(saved)).is_null()


func test_plan_reports_domain_costs_inventory_and_unstarted_cancel_uid_read_only() -> void:
	var sim := _fixture()
	sim.projects.definition_for("rescue_team").upkeep = 123
	sim.start_project("river_zoning", 34)
	var team := sim.enqueue_preparation("rescue_team", 34)
	var stock := sim.enqueue_preparation("aid_stock", 34)
	sim.enqueue_preparation("rescue_team", 6)
	var before := _canonical(sim.to_dict())
	var plan := sim.preparation_plan()
	assert_int(plan.actions.size()).is_equal(2)
	assert_str(plan.actions[0].id).is_equal("rescue_team")
	assert_str(plan.actions[0].output_title).is_equal("1 ekip")
	assert_int(plan.actions[0].total_cost).is_equal(4000000)
	assert_int(plan.actions[0].monthly_cost).is_equal(1000000)
	assert_int(plan.actions[0].months).is_equal(4)
	assert_int(plan.actions[0].upkeep).is_equal(40000)
	assert_str(plan.actions[1].output_title).is_equal("40 yardım")
	assert_int(plan.areas.size()).is_equal(30)
	assert_int(plan.summary.queued_count).is_equal(2)
	assert_int(plan.summary.active_count).is_equal(1)
	assert_int(plan.summary.monthly_commitment).is_equal(2000000)
	assert_int(plan.summary.queued_cost).is_equal(6000000)
	var row := _area_row(plan, 34)
	assert_bool(row.busy).is_true()
	assert_str(row.active_title).is_equal("Dere yatağı imar düzeni")
	assert_int(row.active_months).is_equal(6)
	assert_int(row.teams).is_equal(sim.areas[34].teams)
	assert_int(row.stock).is_equal(sim.areas[34].stock)
	assert_int(row.queued_teams).is_equal(1)
	assert_int(row.queued_stock).is_equal(1)
	assert_int(row.queued_count).is_equal(2)
	assert_int(row.planned_count).is_equal(2)
	assert_int(row.last_uid).is_equal(stock.uid)
	assert_int(plan.pending.size()).is_equal(3)
	assert_int(plan.pending[0].uid).is_equal(team.uid)
	assert_str(plan.pending[0].status).is_equal("queued")
	assert_int(plan.pending[0].monthly_cost).is_equal(1000000)
	row.stock = -123
	plan.actions[0].total_cost = -123
	plan.pending[0].status = "completed"
	assert_str(_canonical(sim.to_dict())).is_equal(before)
	assert_bool(sim.cancel_preparation(stock.uid).ok).is_true()
	assert_int(_area_row(sim.preparation_plan(), 34).last_uid).is_equal(team.uid)
