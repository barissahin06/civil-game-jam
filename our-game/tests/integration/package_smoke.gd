extends SceneTree
## Run standard Godot with --main-pack pointing to the extracted portable PCK.


func _initialize() -> void:
	set_meta("simulation_test", true)
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	root.content_scale_size = root.size
	if not _require(
		ProjectSettings.get_setting("application/config/name") == "Revert it", "game brand"
	):
		return
	if not _require(OS.get_user_data_dir().get_file() == "Civil Game Jam", "legacy save directory"):
		return
	if not _require(
		FileAccess.file_exists("res://events/data/historical/events.json"), "runtime catalog"
	):
		return
	if not _require(
		(
			not FileAccess.file_exists("res://events/historical/events.json")
			and not ResourceLoader.exists("res://addons/gdUnit4/plugin.cfg")
			and not ResourceLoader.exists("res://tests/unit/test_projects.gd")
		),
		"development files excluded"
	):
		return
	var packed := load("res://core/scenes/main.tscn") as PackedScene
	if not _require(packed != null, "main scene"):
		return
	var main: Node = packed.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var shell: Node = main.get_node("MainPreview")
	await main.get_node("Intro").tree_exited
	var isolated_store: RefCounted = shell.get("saves")
	isolated_store.set("slot_directory", "user://test-revert-package-empty-slots")
	var sim: Variant = shell.get("sim")
	if not _require(
		sim != null and sim.areas.size() == 21 and sim.historical.events.size() == 99,
		"21 areas and 99 historical events"
	):
		return
	if not _require(not bool(shell.get("auto_save_enabled")), "player saves disabled"):
		return
	var arguments := OS.get_cmdline_user_args()
	var capture_flag := arguments.find("--capture")
	shell.call("return_to_main_menu")
	await process_frame
	await process_frame
	var hud: Control = shell.get("hud")
	var map: Control = shell.get("map_view")
	if not _require(
		(
			bool(shell.get("in_frontend"))
			and not hud.is_visible_in_tree()
			and not map.is_visible_in_tree()
		),
		"standalone main menu hides gameplay"
	):
		return
	if capture_flag >= 0:
		if not _require(capture_flag + 1 < arguments.size(), "capture destination"):
			return
		RenderingServer.force_draw(false)
		if not _require(
			root.get_texture().get_image().save_png(arguments[capture_flag + 1]) == OK,
			"native menu capture"
		):
			return
	shell.call("show_screen", "load")
	if not _require(str(shell.get("open_screen")) == "load", "packaged save-slot view"):
		return
	shell.call("show_screen", "newgame")
	if not _require(
		str(shell.get("open_screen")) == "newgame", "campaign selection from main menu"
	):
		return
	shell.call("start_campaign", 1950)
	sim = shell.get("sim")
	shell.call("show_screen", "newgame")
	shell.call("show_screen", "menu")
	if not _require(
		(
			not bool(shell.get("in_frontend"))
			and str(shell.get("open_screen")).is_empty()
			and hud.is_visible_in_tree()
			and map.is_visible_in_tree()
		),
		"campaign selection blocked in gameplay"
	):
		return
	if not _require(sim.start_project("river_zoning", 31).ok, "local project"):
		return
	if not _require(sim.start_project("research_structural").ok, "research project"):
		return
	sim.set_paused(false)
	sim.update(300.0)
	if not _require(
		(
			Time.get_date_string_from_unix_time(int(sim.clock.day) * 86400) == "1951-04-08"
			and sim.paused
			and sim.news_queue.size() == 1
			and sim.crises.active.size() == 1
		),
		"first disaster pauses on its historical date"
	):
		return
	if not _require(
		(
			sim.projects.is_completed("river_zoning", 31)
			and sim.projects.is_completed("research_structural")
		),
		"projects completed"
	):
		return
	sim.acknowledge()
	var target: Dictionary = sim.crises.active.front()
	if not _require(sim.dispatch(31, target.id, "team", 1).ok, "local team"):
		return
	if not _require(sim.dispatch(31, target.id, "stock", 40).ok, "local aid"):
		return
	if not _require(sim.dispatch(1, target.id, "team", 1).ok, "distant team"):
		return
	sim.advance_to(int(target.start) + int(target.window))
	if not _require(sim.crises.reports.size() == 1, "crisis report"):
		return
	var report: Dictionary = sim.report_for()
	if not _require(report.rescued > 0 and report.rescued <= report.affected, "human outcomes"):
		return
	var saved: Dictionary = sim.to_dict()
	var store: RefCounted = shell.get("saves")
	if not _require(
		store.call("restore", JSON.parse_string(JSON.stringify(saved))) != null, "save roundtrip"
	):
		return
	main.queue_free()
	await process_frame
	print(
		"PACKAGED_GAMEPLAY_PASS: native UI, 21 areas, 99 events, projects, crisis, logistics, report and save validation"
	)
	quit()


func _require(condition: bool, detail: String) -> bool:
	# Keep checks explicit when testing exported bytecode and resources.
	if not condition:
		push_error("CHECK FAILED: packaged " + detail)
		quit(1)
	return condition
