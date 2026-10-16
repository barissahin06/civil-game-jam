extends SceneTree


func _initialize() -> void:
	var scene := load("res://core/scenes/main.tscn") as PackedScene
	if scene == null:
		push_error("CHECK FAILED: main scene could not be loaded")
		quit(1)
		return
	root.add_child(scene.instantiate())
	await process_frame
	await process_frame
	print("STARTUP PASS")
	quit()
