extends Control
## Settings widgets own their signal connections for the lifetime of the screen.

const UI := preload("res://ui_preview/shared/ui_kit.gd")

var _audio: Node
var _music_toggle: Button
var _music_pause: Button
var _music_volume: HSlider
var _effects_volume: HSlider
var _music_percent: Label
var _effects_percent: Label


func setup(audio: Node) -> void:
	_audio = audio
	_music_toggle = UI.button(self, "", Rect2(0, 0, 312, 52), _audio.toggle_music_enabled)
	_music_toggle.tooltip_text = "Müziği açar veya kapatır. Efekt seslerini değiştirmez."
	_music_pause = UI.button(self, "", Rect2(336, 0, 312, 52), _audio.toggle_music_paused)
	_music_pause.tooltip_text = "Müziği bulunduğu noktada duraklatır veya sürdürür."
	UI.text(self, "MÜZİK SESİ", Rect2(0, 82, 500, 28), 18, UI.MUTED)
	_music_percent = UI.text(self, "", Rect2(552, 82, 96, 28), 18, UI.GOLD)
	_music_percent.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_music_volume = _volume_slider(122, "Müzik ses seviyesi")
	_music_volume.value_changed.connect(_set_music_volume)
	UI.text(self, "EFEKT SESİ", Rect2(0, 184, 500, 28), 18, UI.MUTED)
	_effects_percent = UI.text(self, "", Rect2(552, 184, 96, 28), 18, UI.GOLD)
	_effects_percent.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_effects_volume = _volume_slider(224, "Efekt ses seviyesi")
	_effects_volume.value_changed.connect(_set_effects_volume)
	_audio.settings_changed.connect(_refresh)
	_refresh()


func _volume_slider(y: float, title: String) -> HSlider:
	var slider := HSlider.new()
	slider.position = Vector2(12, y)
	slider.size = Vector2(624, 36)
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0
	slider.focus_mode = Control.FOCUS_ALL
	slider.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	slider.tooltip_text = title + ": %0–100. Sol/Sağ ok tuşlarıyla da ayarlanabilir."
	slider.add_theme_stylebox_override("slider", UI.style(Rect2(0, 56, 48, 32)))
	slider.add_theme_stylebox_override("grabber_area", UI.style(Rect2(168, 96, 48, 24)))
	slider.add_theme_stylebox_override("grabber_area_highlight", UI.style(Rect2(168, 96, 48, 24)))
	slider.add_theme_icon_override("grabber", UI.atlas(UI.CONTROLS, Rect2(112, 56, 48, 32)))
	slider.add_theme_icon_override(
		"grabber_highlight", UI.atlas(UI.CONTROLS, Rect2(56, 56, 48, 32))
	)
	add_child(slider)
	var focus := Panel.new()
	focus.position = Vector2(-12, -4)
	focus.size = slider.size + Vector2(24, 8)
	focus.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var frame := UI.style(Rect2(56, 56, 48, 32))
	frame.draw_center = false
	focus.add_theme_stylebox_override("panel", frame)
	focus.hide()
	slider.add_child(focus)
	slider.focus_entered.connect(focus.show)
	slider.focus_exited.connect(focus.hide)
	return slider


func _set_music_volume(percent: float) -> void:
	_audio.set_music_volume(percent / 100.0)


func _set_effects_volume(percent: float) -> void:
	_audio.set_effects_volume(percent / 100.0)


func _refresh() -> void:
	_music_toggle.text = "MÜZİK: " + ("AÇIK" if _audio.music_enabled else "KAPALI")
	_music_toggle.add_theme_stylebox_override(
		"normal", UI.style(Rect2(112 if _audio.music_enabled else 0, 56, 48, 32))
	)
	_music_pause.text = "MÜZİĞİ SÜRDÜR" if _audio.music_paused else "MÜZİĞİ DURAKLAT"
	_music_pause.disabled = not _audio.music_enabled
	_music_volume.set_value_no_signal(roundf(_audio.music_volume * 100.0))
	_effects_volume.set_value_no_signal(roundf(_audio.effects_volume * 100.0))
	_music_percent.text = "%%%d" % _music_volume.value
	_effects_percent.text = "%%%d" % _effects_volume.value
