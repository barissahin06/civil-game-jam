extends GdUnitTestSuite


func test_main_scene_loads() -> void:
	var scene := load("res://core/scenes/main.tscn") as PackedScene
	assert_object(scene).is_not_null()
	var instance := scene.instantiate()
	assert_bool(instance is Control).is_true()
	instance.free()
