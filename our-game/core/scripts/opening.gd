extends Control

const LOGO_SECONDS: float = 3.5
const INTRO_SECONDS: float = 15.0
const FADE_SECONDS: float = 0.5
const GODOT_SECONDS: float = 1.5


func _ready() -> void:
	var godot_splash: ColorRect = $GodotSplash
	var godot_logo: TextureRect = $GodotSplash/Logo
	var splash: ColorRect = $Splash
	var logo: TextureRect = $Splash/Logo
	var intro: ColorRect = $Intro
	var message: Label = $Intro/Message
	var source: Label = $Intro/Source
	logo.modulate.a = 0.0
	message.modulate.a = 0.0
	source.modulate.a = 0.0
	godot_logo.modulate.a = 0.0
	var godot_tween := create_tween()
	godot_tween.tween_property(godot_logo, "modulate:a", 1.0, FADE_SECONDS)
	godot_tween.tween_interval(GODOT_SECONDS - 2.0 * FADE_SECONDS)
	godot_tween.tween_property(godot_logo, "modulate:a", 0.0, FADE_SECONDS)
	await godot_tween.finished
	godot_splash.queue_free()
	var logo_tween := create_tween()
	logo_tween.tween_property(logo, "modulate:a", 1.0, FADE_SECONDS)
	logo_tween.tween_interval(LOGO_SECONDS - 2.0 * FADE_SECONDS)
	logo_tween.tween_property(logo, "modulate:a", 0.0, FADE_SECONDS)
	await logo_tween.finished
	splash.queue_free()
	var intro_tween := create_tween()
	intro_tween.tween_property(message, "modulate:a", 1.0, FADE_SECONDS)
	intro_tween.parallel().tween_property(source, "modulate:a", 1.0, FADE_SECONDS)
	intro_tween.tween_interval(INTRO_SECONDS - 2.0 * FADE_SECONDS)
	intro_tween.tween_property(intro, "modulate:a", 0.0, FADE_SECONDS)
	await intro_tween.finished
	intro.queue_free()
