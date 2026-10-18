extends Control

const UI := preload("res://ui_preview/shared/ui_kit.gd")
const LOGO_SECONDS: float = 3.5
const INTRO_SECONDS: float = 15.0
const TITLE_SECONDS: float = 3.5
const FADE_SECONDS: float = 0.5
const GODOT_SECONDS: float = 1.5
const SKIP_HOLD_SECONDS: float = 2.0
const SKIP_BAR_WIDTH: float = 358.0

var _tween: Tween
var _skip_fill: ColorRect
var _skip_hold: float = 0.0
var _skipped: bool = false


func _ready() -> void:
	var godot_splash: ColorRect = $GodotSplash
	var godot_logo: TextureRect = $GodotSplash/Logo
	var splash: ColorRect = $Splash
	var logo: TextureRect = $Splash/Logo
	var intro: ColorRect = $Intro
	var message: Label = $Intro/Message
	var source: Label = $Intro/Source
	var title_splash: ColorRect = $TitleSplash
	var title_logo: TextureRect = $TitleSplash/Logo
	title_logo.modulate.a = 0.0
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
	_build_skip_bar(intro)
	_tween = create_tween()
	_tween.tween_property(message, "modulate:a", 1.0, FADE_SECONDS)
	_tween.parallel().tween_property(source, "modulate:a", 1.0, FADE_SECONDS)
	_tween.tween_interval(INTRO_SECONDS - 2.0 * FADE_SECONDS)
	_tween.tween_property(intro, "modulate:a", 0.0, FADE_SECONDS)
	await _tween.finished
	intro.queue_free()
	if _skipped:
		title_splash.queue_free()
		$MainPreview.audio.start_music()
		return
	var title_tween := create_tween()
	title_tween.tween_property(title_logo, "modulate:a", 1.0, FADE_SECONDS)
	title_tween.tween_interval(TITLE_SECONDS - 2.0 * FADE_SECONDS)
	title_tween.tween_property(title_splash, "modulate:a", 0.0, FADE_SECONDS)
	await title_tween.finished
	title_splash.queue_free()
	$MainPreview.audio.start_music()


func _build_skip_bar(intro: Control) -> void:
	var bar := Control.new()
	bar.name = "SkipBar"
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	intro.add_child(bar)
	UI.panel(bar, Rect2(1500, 984, 390, 64))
	UI.text(bar, "ATLAMAK İÇİN ESC BASILI TUT", Rect2(1516, 990, 360, 24), 18, UI.MUTED)
	var track := ColorRect.new()
	track.color = Color("10181e")
	track.position = Vector2(1516, 1022)
	track.size = Vector2(SKIP_BAR_WIDTH, 12)
	bar.add_child(track)
	_skip_fill = ColorRect.new()
	_skip_fill.color = UI.GOLD
	_skip_fill.position = track.position
	_skip_fill.size = Vector2(0, 12)
	bar.add_child(_skip_fill)


func _process(delta: float) -> void:
	if _skipped or not is_instance_valid(_skip_fill):
		return
	_skip_hold = _skip_hold + delta if Input.is_key_pressed(KEY_ESCAPE) else 0.0
	_skip_fill.size.x = SKIP_BAR_WIDTH * minf(1.0, _skip_hold / SKIP_HOLD_SECONDS)
	if _skip_hold >= SKIP_HOLD_SECONDS:
		_skipped = true
		# Jump the running intro tween to its end; _ready then skips the title screen too.
		_tween.custom_step(INTRO_SECONDS)


func _input(event: InputEvent) -> void:
	# While the skip bar is up, ESC belongs to it and must not reach the menu.
	if (
		is_instance_valid(_skip_fill)
		and event is InputEventKey
		and (event as InputEventKey).keycode == KEY_ESCAPE
	):
		get_viewport().set_input_as_handled()
