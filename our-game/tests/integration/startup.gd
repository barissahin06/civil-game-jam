extends SceneTree


func _initialize() -> void:
	var scene := load("res://core/scenes/main.tscn") as PackedScene
	if scene == null:
		push_error("CHECK FAILED: main scene could not be loaded")
		quit(1)
		return
	var main := scene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	assert(main.has_node("Splash"))
	assert(is_equal_approx(main.LOGO_SECONDS, 3.5))
	var godot_logo: TextureRect = main.get_node("GodotSplash/Logo")
	while godot_logo.modulate.a < 0.99:
		await process_frame
	while godot_logo.modulate.a > 0.75:
		await process_frame
	assert(godot_logo.modulate.a > 0.0 and godot_logo.modulate.a < 0.75)
	if "--capture" in OS.get_cmdline_user_args():
		RenderingServer.force_draw(false)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../generated/startup-godot-fade.png")
	await main.get_node("GodotSplash").tree_exited
	var logo: TextureRect = main.get_node("Splash/Logo")
	assert(
		logo.get_global_rect().get_center().is_equal_approx(
			root.get_visible_rect().get_center() + Vector2(0.0, -20.0)
		)
	)
	while logo.modulate.a < 0.99:
		await process_frame
	if "--capture" in OS.get_cmdline_user_args():
		RenderingServer.force_draw(false)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../generated/startup-logo.png")
	while logo.modulate.a > 0.75:
		await process_frame
	assert(main.has_node("Splash"))
	assert(logo.modulate.a > 0.0 and logo.modulate.a < 0.75)
	if "--capture" in OS.get_cmdline_user_args():
		RenderingServer.force_draw(false)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../generated/startup-logo-fade.png")
	await create_timer(0.6).timeout
	assert(not main.has_node("Splash"))
	assert(main.has_node("Intro"))
	assert(is_equal_approx(main.INTRO_SECONDS, 15.0))
	var intro: ColorRect = main.get_node("Intro")
	var message: Label = intro.get_node("Message")
	assert(not message.text.contains("TÜRKİYE AFET HAFIZASI"))
	assert(message.text.ends_with("Peki, öncesinde önlemler alınsaydı ne olurdu?"))
	if "--capture" in OS.get_cmdline_user_args():
		await create_timer(0.5).timeout
		RenderingServer.force_draw(false)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../generated/startup-intro.png")
	while intro.modulate.a > 0.75:
		await process_frame
	assert(intro.modulate.a > 0.0 and intro.modulate.a < 0.75)
	if "--capture" in OS.get_cmdline_user_args():
		RenderingServer.force_draw(false)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../generated/startup-intro-fade.png")
	await intro.tree_exited
	assert(main.get_node("MainPreview").is_visible_in_tree())
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../generated/startup-menu.png")
	print("STARTUP PASS")
	quit()
