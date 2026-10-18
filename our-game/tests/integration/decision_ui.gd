extends "res://tests/integration/gameplay_ui.gd"
## Real input and rendering; campaigns stay in memory and never touch player slots.


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	root.content_scale_size = root.size
	_main = load("res://ui_preview/scenes/main_preview.tscn").instantiate()
	root.add_child(_main)
	await process_frame
	_shell = _main
	_shell.auto_save_enabled = false
	for id: String in ["gediz_relocation", "samsun_flood", "construction_inspection"]:
		var sim := _seed(id)
		_shell.sim = sim
		_shell._bind_simulation(true)
		_shell.show_screen("decision")
		await process_frame
		await process_frame
		var paper := _shell._screen_content.get_node("DecisionPaper") as Panel
		assert(paper.size == Vector2(1440, 840))
		assert(paper.get_global_rect().get_center().is_equal_approx(Vector2(960, 540)))
		var confirm := _shell._screen_content.get_node("DecisionConfirm") as Button
		assert(confirm.disabled)
		var old_day := sim.clock.day
		sim.set_paused(false)
		sim.update(100.0)
		assert(sim.paused and sim.clock.day == old_day)
		await _key(KEY_ESCAPE)
		assert(_shell.open_screen == "pause")
		await _key(KEY_ESCAPE)
		assert(_shell.open_screen == "decision" and sim.news_queue.front().id == id)
		var option := _shell._screen_content.get_node("DecisionOption_full") as Button
		await _click(option.get_global_rect().get_center())
		confirm = _shell._screen_content.get_node("DecisionConfirm") as Button
		assert(not confirm.disabled)
		_assert_summary_layout(sim.decisions.card_for(id))
		await _capture("decision-" + id)
		var pending := SaveStore.new().restore(JSON.parse_string(JSON.stringify(sim.to_dict())))
		assert(pending != null and pending.news_queue.front().id == id)
		confirm = _shell._screen_content.get_node("DecisionConfirm") as Button
		var move := InputEventMouseMotion.new()
		move.position = confirm.get_global_rect().get_center()
		move.global_position = move.position
		Input.parse_input_event(move)
		Input.flush_buffered_events()
		await process_frame
		await _click(confirm.get_global_rect().get_center())
		assert(sim.decisions.records[id].choice_id == "full")
		assert(not sim.choose_decision(id, "decline").ok)
		assert(SaveStore.new().restore(JSON.parse_string(JSON.stringify(sim.to_dict()))) != null)
	var alternatives := 0
	assert(_shell.sim.decision_catalog.cards.size() == 21)
	# The complete catalog must fit without hiding effects behind a scroll area.
	for card: Dictionary in _shell.sim.decision_catalog.cards:
		var sim := Simulation.new()
		assert(sim.setup())
		await _show_fixture(sim, card.id)
		assert(_shell._screen_content.get_node("DecisionOption_decline") != null)
		assert(_shell._screen_content.get_node("DecisionConfirm").disabled)
		_assert_summary_layout(card)
		alternatives += card.options.size()
		if card.id == "hazard_zoning":
			await _capture("decision-hazard_zoning")
		for child: Node in _shell._screen_content.get_children():
			if child is RichTextLabel:
				var text: String = child.get_parsed_text()
				for index in range(text.length()):
					var code := text.unicode_at(index)
					assert(
						code in [9, 10, 13] or UI.FONT.has_char(code),
						"Missing decision font glyph: " + text[index]
					)
	assert(alternatives == 63)
	await _check_waiting_and_zero_previews()
	_shell.sim.news_queue.clear()
	await _shell.audio.shutdown()
	_main.queue_free()
	await process_frame
	print(
		"DECISION_UI_PASS: Gediz/Samsun/Marmara input, pause/restore, 21 cards/63 alternatives, four-line summaries, colors and glyphs; captures=",
		_capture_count
	)
	quit()


func _assert_summary_layout(card: Dictionary) -> void:
	var preview := _shell.sim.decisions.preview(card.id)
	var paper := _shell._screen_content.get_node("DecisionPaper") as Panel
	for option: Dictionary in preview.options:
		var title := (
			_shell._screen_content.get_node("DecisionTitle_" + String(option.id)) as RichTextLabel
		)
		var details := (
			_shell._screen_content.get_node("DecisionDetails_" + String(option.id)) as RichTextLabel
		)
		var button := (
			_shell._screen_content.get_node("DecisionOption_" + String(option.id)) as Button
		)
		assert(title != null and details != null and button != null)
		for label: RichTextLabel in [title, details]:
			assert(not label.scroll_active and not label.get_v_scroll_bar().visible)
			assert(label.get_content_height() <= label.size.y, "Clipped decision: " + label.text)
			assert(label.get_content_width() <= label.size.x, "Wide decision: " + label.text)
			assert(paper.get_global_rect().encloses(label.get_global_rect()))
		assert(not title.get_global_rect().intersects(details.get_global_rect()))
		assert(not details.get_global_rect().intersects(button.get_global_rect()))
		assert(details.get_line_count() >= 3 and details.get_line_count() <= 4)
		assert(details.bbcode_enabled)
		assert(details.text.count("[color=") == details.text.count("[/color]"))
		var positive := String(option.project_id).is_empty()
		for effect: Dictionary in option.effects.rows:
			positive = (
				positive
				or (
					not is_zero_approx(effect.delta)
					and (effect.delta > 0) == effect.higher_is_better
				)
			)
		if positive:
			assert(details.text.contains("[color=#28613f]"), "Missing positive decision color")
		assert(details.text.contains("[color=#9b3830]"), "Missing negative decision color")
		var text := details.get_parsed_text()
		assert(not text.contains("[color=") and not text.contains("[/color]"))
		assert(text.contains("+") and text.contains("-"))
		if option.id == "decline":
			assert(title.get_parsed_text() == "İki projeyi de reddet")
			assert(text.contains("Bu iki projeyi bu oyunda bir daha başlatamazsın."))
		if not String(option.project_id).is_empty():
			assert(text.contains(_shell.fmt_money(int(option.cost_budget))))
			assert(text.contains(_shell.fmt_money(int(option.installment))))
			assert(text.contains("%d ay" % option.months))
			if int(option.upkeep) > 0:
				assert(text.contains(_shell.fmt_money(int(option.upkeep))))
			for effect: Dictionary in option.effects.rows:
				var amount := (
					"%+d" % effect.delta
					if effect.key == "teams"
					else ("%+.1f" % effect.delta).replace(".", ",")
				)
				assert(text.contains(amount), "Missing actual decision delta: " + amount)
				if effect.key == "teams":
					assert(_has_colored_text(details, "9b3830", "sel hazırlığı artmaz"))
		elif not is_zero_approx(option.trust_change):
			assert(text.contains(("%+.1f" % option.trust_change).replace(".", ",")))


func _show_fixture(sim: Simulation, id: String) -> void:
	var card := sim.decisions.card_for(id)
	sim.decisions.offer(card.event_ids[0], sim.clock.day)
	sim.news_queue = [{"kind": "decision", "id": id}]
	_shell.sim = sim
	_shell._bind_simulation(true)
	_shell.show_screen("decision")
	await process_frame
	await process_frame


func _check_waiting_and_zero_previews() -> void:
	var queued := Simulation.new()
	assert(queued.setup())
	assert(queued.start_project("strengthening", 3).ok)
	await _show_fixture(queued, "gediz_relocation")
	_assert_summary_layout(queued.decisions.card_for("gediz_relocation"))
	for id: String in ["full", "focused"]:
		var details := _shell._screen_content.get_node("DecisionDetails_" + id) as RichTextLabel
		assert(details.get_parsed_text().contains("sırada"))
		assert(not details.get_parsed_text().contains("hemen başlar"))
	var old_trust: float = queued.trust.value
	var old_project_count := queued.projects.projects.size()
	var reject := _shell._screen_content.get_node("DecisionOption_decline") as Button
	await _click(reject.get_global_rect().get_center())
	var confirm := _shell._screen_content.get_node("DecisionConfirm") as Button
	assert(not confirm.disabled)
	await _click(confirm.get_global_rect().get_center())
	assert(queued.decisions.records.gediz_relocation.choice_id == "decline")
	assert(queued.decisions.records.gediz_relocation.project_uid == 0)
	assert(queued.projects.projects.size() == old_project_count)
	assert(is_equal_approx(queued.trust.value, old_trust))
	assert(
		(
			_shell._status.text
			== "İki proje de reddedildi. Bu iki projeyi bu oyunda bir daha başlatamazsın."
		)
	)
	for id: String in ["full", "focused"]:
		assert(not queued.choose_decision("gediz_relocation", id).ok)
	var limited := Simulation.new()
	assert(limited.setup())
	limited.areas[3].completed_measures.append("decision_gediz_relocation_full")
	limited.trust.value = 0.0
	await _show_fixture(limited, "gediz_relocation")
	_assert_summary_layout(limited.decisions.card_for("gediz_relocation"))
	var zero := _shell._screen_content.get_node("DecisionDetails_full") as RichTextLabel
	var preview := limited.decisions.preview("gediz_relocation")
	for effect: Dictionary in preview.options[0].effects.rows:
		assert(is_zero_approx(effect.delta))
		assert(_has_colored_text(zero, "76674f", "+0,0"), "Zero effect must use neutral ink")
		assert(not _has_colored_text(zero, "28613f", "+0,0"))
		assert(not _has_colored_text(zero, "9b3830", "+0,0"))
	var decline := _shell._screen_content.get_node("DecisionDetails_decline") as RichTextLabel
	assert(_has_colored_text(decline, "76674f", "halkın güveni değişmez"))
	assert(not _has_colored_text(decline, "28613f", "halkın güveni değişmez"))
	assert(not _has_colored_text(decline, "9b3830", "halkın güveni değişmez"))
	assert(not decline.get_parsed_text().contains("+0,0"))


func _has_colored_text(label: RichTextLabel, tint: String, text: String) -> bool:
	var spans := label.text.split("[color=#" + tint + "]")
	for index: int in range(1, spans.size()):
		if spans[index].get_slice("[/color]", 0).contains(text):
			return true
	return false


func _seed(id: String) -> Simulation:
	var sim := Simulation.new()
	assert(sim.setup(1950 if id == "gediz_relocation" else 1990))
	var card := sim.decisions.card_for(id)
	var event := sim.event_for(card.event_ids[0])
	var end := int(event.day) + int(event.response_window_days) + 2
	for iteration in range(1000):
		if sim.news_queue.is_empty():
			sim.trust.value = 100.0
			sim.advance_to(end)
		elif sim.news_queue.front().kind == "decision":
			if sim.news_queue.front().id == id:
				return sim
			assert(sim.choose_decision(sim.news_queue.front().id, "decline").ok)
		else:
			sim.acknowledge()
	assert(false, "Decision fixture did not reach " + id)
	return sim


func _key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	await process_frame
	event = InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = false
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	await process_frame
