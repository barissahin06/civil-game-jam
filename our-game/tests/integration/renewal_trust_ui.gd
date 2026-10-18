extends "res://tests/integration/gameplay_ui.gd"
## Isolated real input for renewal and a delayed public commitment.


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	root.content_scale_size = root.size
	root.gui_embed_subwindows = true
	_main = load("res://ui_preview/scenes/main_preview.tscn").instantiate()
	root.add_child(_main)
	await process_frame
	_shell = _main
	_shell.auto_save_enabled = false
	var sim := _shell.sim
	sim.tutorial_enabled = false
	sim.areas[34].condition = 70.0
	_shell.select_area(34)
	_check_text(_shell.city_panel)
	_shell.show_project("center_renewal", 34)
	await process_frame
	await process_frame
	assert(_shell.open_screen == "project")
	assert(sim.projects.cost_for("center_renewal", 34) == 2000000)
	_check_text(_main)
	await _capture_balance("renewal-project")
	var money := sim.treasury.money
	await _press_button("BAŞLAT")
	assert(sim.projects.projects.size() == 1 and sim.treasury.money == money)
	var renewal_uid: int = sim.projects.projects.front().uid
	assert(sim.projects.pause(renewal_uid).ok)
	assert(sim.projects.start("rescue_team", 34, 1950).ok)
	for month: int in range(4):
		sim.projects.tick_month(1950)
	assert(sim.projects.cost_for("center_renewal", 34) == 4000000)
	_shell.show_screen("projects")
	await process_frame
	await process_frame
	var renewal_row := _main.find_child("Project%d" % renewal_uid, true, false)
	var actual_payment := (
		_shell.fmt_money(sim.projects.installment_for(sim.projects.get_project(renewal_uid)))
		+ " TAKSİT"
	)
	assert(
		_has_text(renewal_row, actual_payment), "Active renewal must show its locked installment"
	)
	await _capture_balance("renewal-snapshot")
	_shell.show_project("center_renewal", 34)
	await process_frame
	await process_frame
	assert(_has_text(_main, _shell.fmt_money(2000000)))
	assert(
		_has_text(
			_main,
			(
				"SONRAKİ TAKSİT: "
				+ _shell.fmt_money(
					sim.projects.installment_for(sim.projects.get_project(renewal_uid))
				)
			)
		)
	)
	assert(sim.projects.resume(renewal_uid).ok)
	for month: int in range(6):
		sim.projects.tick_month(1950)
	assert(sim.areas[34].condition == 100.0 and sim.trust.value == 70.0)
	_shell.close_screen()
	var card: Dictionary = sim.decision_catalog.cards.front()
	assert(sim.decisions.offer(card.event_ids.front(), sim.clock.day).size() > 0)
	sim.news_queue.assign([{"kind": "decision", "id": card.id}])
	_shell.show_screen("decision")
	await process_frame
	await process_frame
	var option: Button = _main.find_child("DecisionOption_focused", true, false)
	await _click(option.get_global_rect().get_center())
	await _press_button("SEÇİMİ ONAYLA")
	var uid := int(sim.decisions.records[card.id].project_uid)
	assert(uid > 0 and sim.projects.pause(uid).ok)
	sim.set_paused(false)
	sim.advance_to(CalendarClock.date_to_day("1950-07-01"))
	assert(sim.paused and sim.decisions.commitment_status(uid, sim.clock.day).warned)
	var warning := (
		"Taahhüt uyarısı: %s için 6 aydır gerçek ilerleme yok."
		% sim.projects.definition_for(sim.projects.get_project(uid).definition_id).title
	)
	assert(sim.ticker.count(warning) == 1, "A management warning must be logged once")
	_shell.show_screen("projects")
	await process_frame
	await process_frame
	var commitment: Label = _main.find_child("Commitment", true, false)
	assert(commitment != null and commitment.text.contains("6 aydır"))
	_check_text(_main)
	await _capture_balance("commitment-warning")
	sim.advance_to(CalendarClock.date_to_day("1951-01-01"))
	assert(sim.decisions.commitment_status(uid, sim.clock.day).overdue)
	_shell.refresh_screen()
	await process_frame
	await process_frame
	var row := _main.find_child("Project%d" % uid, true, false)
	var cancel: Button = row.get_node("Cancel")
	assert(cancel.tooltip_text.contains("0,5"))
	sim.trust.change(0.25 - sim.trust.value, "İptal sonrası yenilgi sınırı")
	var trust_before := sim.trust.value
	await _click(cancel.get_global_rect().get_center())
	row = _main.find_child("Project%d" % uid, true, false)
	cancel = row.get_node("Cancel")
	await _click(cancel.get_global_rect().get_center())
	assert(sim.projects.get_project(uid).status == "cancelled")
	assert(is_equal_approx(sim.trust.value, maxf(0.0, trust_before - 0.5)))
	await process_frame
	await process_frame
	assert(sim.outcome == "defeat" and sim.paused)
	assert(_shell.open_screen == "defeat", "Cancellation must show defeat without resuming time")
	assert(SaveStore.new().restore(JSON.parse_string(JSON.stringify(sim.to_dict()))) != null)
	await _capture_balance("commitment-cancel-defeat")
	await _shell.audio.shutdown()
	_main.queue_free()
	await process_frame
	print(
		"RENEWAL_TRUST_UI_PASS: renewal quote/input, no completion reward,6/12month warning, commitment status and cancel cost"
	)
	quit()


func _has_text(parent: Node, text: String) -> bool:
	if parent is Label and parent.text == text:
		return true
	for child: Node in parent.get_children():
		if _has_text(child, text):
			return true
	return false


func _capture_balance(label: String) -> void:
	if not capture_screens:
		return
	await process_frame
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("res://../generated/balance-ui/" + label + ".png")
	assert(DirAccess.make_dir_recursive_absolute(path.get_base_dir()) == OK)
	assert(root.get_texture().get_image().save_png(path) == OK)
