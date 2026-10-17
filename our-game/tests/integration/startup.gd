extends SceneTree


func _initialize() -> void:
	root.size = Vector2i(1920, 1080)
	root.content_scale_size = root.size
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
	assert(is_equal_approx(main.TITLE_SECONDS, 3.5))
	var title: ColorRect = main.get_node("TitleSplash")
	var title_logo: TextureRect = title.get_node("Logo")
	assert(title.color == Color.BLACK)
	assert(title.mouse_filter == Control.MOUSE_FILTER_STOP)
	assert(title.get_global_rect().is_equal_approx(root.get_visible_rect()))
	assert(title.get_index() > main.get_node("MainPreview").get_index())
	assert(title.get_index() < main.get_node("Intro").get_index())
	assert(title_logo.texture.resource_path == "res://assets/branding/rewrite_it.png")
	assert(title_logo.texture.get_size() == Vector2(1152.0, 432.0))
	assert(title_logo.size == Vector2(1152.0, 432.0))
	assert(
		title_logo.get_global_rect().get_center().is_equal_approx(
			root.get_visible_rect().get_center()
		)
	)
	assert(title_logo.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST)
	assert(is_zero_approx(title_logo.modulate.a))
	var godot_logo: TextureRect = main.get_node("GodotSplash/Logo")
	while godot_logo.modulate.a < 0.99:
		await process_frame
	while godot_logo.modulate.a > 0.75:
		await process_frame
	assert(godot_logo.modulate.a > 0.0 and godot_logo.modulate.a < 0.75)
	if "--capture" in OS.get_cmdline_user_args():
		RenderingServer.force_draw(false)
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
		root.get_texture().get_image().save_png("res://../generated/startup-logo.png")
	while logo.modulate.a > 0.75:
		await process_frame
	assert(main.has_node("Splash"))
	assert(logo.modulate.a > 0.0 and logo.modulate.a < 0.75)
	if "--capture" in OS.get_cmdline_user_args():
		RenderingServer.force_draw(false)
		root.get_texture().get_image().save_png("res://../generated/startup-logo-fade.png")
	await create_timer(0.6).timeout
	assert(not main.has_node("Splash"))
	assert(main.has_node("Intro"))
	assert(is_equal_approx(main.INTRO_SECONDS, 15.0))
	var intro: ColorRect = main.get_node("Intro")
	var message: Label = intro.get_node("Message")
	assert(is_zero_approx(title_logo.modulate.a))
	assert(not message.text.contains("TÜRKİYE AFET HAFIZASI"))
	assert(message.text.ends_with("Peki, öncesinde önlemler alınsaydı ne olurdu?"))
	if "--capture" in OS.get_cmdline_user_args():
		await create_timer(0.5).timeout
		RenderingServer.force_draw(false)
		root.get_texture().get_image().save_png("res://../generated/startup-intro.png")
	while intro.modulate.a > 0.75:
		assert(is_zero_approx(title_logo.modulate.a))
		await process_frame
	assert(intro.modulate.a > 0.0 and intro.modulate.a < 0.75)
	assert(is_zero_approx(title_logo.modulate.a))
	if "--capture" in OS.get_cmdline_user_args():
		RenderingServer.force_draw(false)
		root.get_texture().get_image().save_png("res://../generated/startup-intro-fade.png")
	while is_instance_valid(intro) and intro.is_inside_tree():
		assert(is_zero_approx(title_logo.modulate.a))
		await process_frame
	assert(title.is_visible_in_tree() and is_equal_approx(title.modulate.a, 1.0))
	while title_logo.modulate.a < 0.5:
		await process_frame
	assert(title_logo.modulate.a > 0.0 and title_logo.modulate.a < 1.0)
	if "--capture" in OS.get_cmdline_user_args():
		RenderingServer.force_draw(false)
		root.get_texture().get_image().save_png("res://../generated/startup-title-fade-in.png")
	while title_logo.modulate.a < 0.99:
		await process_frame
	if "--capture" in OS.get_cmdline_user_args():
		RenderingServer.force_draw(false)
		root.get_texture().get_image().save_png("res://../generated/startup-title.png")
	while title.modulate.a > 0.75:
		assert(title_logo.modulate.a >= 0.99)
		await process_frame
	assert(title.modulate.a > 0.0 and title.modulate.a < 0.75)
	if "--capture" in OS.get_cmdline_user_args():
		RenderingServer.force_draw(false)
		root.get_texture().get_image().save_png("res://../generated/startup-title-fade-out.png")
	await title.tree_exited
	assert(not main.has_node("TitleSplash"))
	assert(main.get_node("MainPreview").is_visible_in_tree())
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../generated/startup-menu.png")
	main.queue_free()
	await process_frame
	var skipper := scene.instantiate()
	root.add_child(skipper)
	await skipper.get_node("Splash").tree_exited
	await process_frame
	var fill: ColorRect = skipper._skip_fill
	assert(skipper.get_node("Intro/SkipBar").is_visible_in_tree())
	_escape(true)
	await create_timer(1.0).timeout
	assert(fill.size.x > 100.0 and skipper.has_node("Intro"))
	if "--capture" in OS.get_cmdline_user_args():
		RenderingServer.force_draw(false)
		root.get_texture().get_image().save_png("res://../generated/startup-skip.png")
	_escape(false)
	await process_frame
	await process_frame
	assert(is_zero_approx(fill.size.x))
	_escape(true)
	await create_timer(2.3).timeout
	_escape(false)
	assert(not skipper.has_node("Intro") and not skipper.has_node("TitleSplash"))
	assert(skipper.get_node("MainPreview").is_visible_in_tree())
	print("STARTUP PASS")
	quit()


func _escape(pressed: bool) -> void:
	var key := InputEventKey.new()
	key.keycode = KEY_ESCAPE
	key.physical_keycode = KEY_ESCAPE
	key.pressed = pressed
	Input.parse_input_event(key)
	Input.flush_buffered_events()
