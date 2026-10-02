extends Control
## A shared name-only hover label for scene props and runtime items.
## The chrome is kept as a runtime layer so the same interaction treatment can
## be reused without baking text into any artwork.

const TIP_SIZE := Vector2(180, 48)
const ITEM_TIP_SIZE := Vector2(340, 212)
const ROOT_PADDING := Vector2(14, 18)
const TOPMOST_Z := 4096
const SHOW_SCALE_TIME := 0.16
const SHOW_FADE_TIME := 0.10
const HIDE_SCALE_TIME := 0.10
const HIDE_FADE_TIME := 0.08
const Chrome = preload("res://scripts/popup_style.gd")
const RED = Chrome.ORANGE
const BLACK = Chrome.BACKGROUND
const WHITE = Chrome.TEXT

var motion_panel: Control
var red_shadow: ColorRect
var panel: Panel
var label: Label
var body_label: Label
var bold_font: SystemFont
var tween: Tween
var current_key := ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = TOPMOST_Z
	bold_font = SystemFont.new()
	bold_font.font_names = PackedStringArray(["PingFang SC", "Noto Sans CJK SC", "Microsoft YaHei"])
	bold_font.font_weight = 700

	motion_panel = Control.new()
	motion_panel.name = "PanelMotion"
	motion_panel.position = Vector2.ZERO
	motion_panel.size = TIP_SIZE
	motion_panel.pivot_offset = Vector2(0, TIP_SIZE.y)
	motion_panel.rotation_degrees = 0.0
	motion_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(motion_panel)

	red_shadow = ColorRect.new()
	red_shadow.name = "RedShadow"
	red_shadow.position = Vector2(0, 8)
	red_shadow.size = Vector2(3,TIP_SIZE.y-16)
	red_shadow.color = RED
	red_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	motion_panel.add_child(red_shadow)

	panel = Panel.new()
	panel.name = "Panel"
	panel.size = TIP_SIZE
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _panel_style())
	motion_panel.add_child(panel)
	motion_panel.move_child(red_shadow,1)

	label = Label.new()
	label.name = "Label"
	label.position = Vector2(14, 4)
	label.size = Vector2(TIP_SIZE.x - 28, TIP_SIZE.y - 8)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_font_override("font", bold_font)
	label.add_theme_color_override("font_color", WHITE)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(label)
	hide()

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = BLACK
	style.border_color = Chrome.FRAME
	style.set_border_width_all(1)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 4
	style.shadow_offset = Vector2(3, 3)
	return style

func show_tip(key: String, text_value: String, screen_pos: Vector2, tilted := true, body_text := "", tip_z := TOPMOST_Z, side := 1.0, target_rect := Rect2(), alignment := "") -> void:
	if current_key == key and visible:
		return
	if tween:
		tween.kill()
	current_key = key
	z_index = tip_z
	var item_tip := body_text != ""
	var target_size := ITEM_TIP_SIZE if item_tip else TIP_SIZE
	if item_tip:
		var body_font := Chrome.font()
		var lines := 0
		for line_text in body_text.split("\n"):
			lines += maxi(1,ceili(body_font.get_string_size(line_text,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x/(target_size.x-28)))
		target_size.y = maxf(target_size.y,60+lines*22)
	var root_size := target_size + ROOT_PADDING
	size = root_size
	motion_panel.size = target_size
	motion_panel.pivot_offset = Vector2(0, target_size.y)
	motion_panel.rotation_degrees = 0.0
	red_shadow.size = Vector2(3,target_size.y-16)
	panel.size = target_size
	label.text = text_value
	label.position = Vector2(14, 5) if item_tip else Vector2(14, 4)
	label.size = Vector2(target_size.x - 28, 30 if item_tip else target_size.y - 8)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if item_tip else HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16 if item_tip else 17)
	if body_label == null:
		body_label = Label.new()
		body_label.name = "Body"
		body_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(body_label)
	body_label.visible = item_tip
	if item_tip:
		body_label.text = body_text
		body_label.position = Vector2(14, 39)
		body_label.size = Vector2(target_size.x - 28, target_size.y - 46)
		body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		body_label.add_theme_font_override("font",Chrome.font())
		body_label.add_theme_font_size_override("font_size", 14)
		body_label.add_theme_color_override("font_color", Chrome.MUTED)
	position = _tip_position(screen_pos,target_size,item_tip,side,target_rect,alignment)
	show()
	motion_panel.scale = Vector2(0.18, 0.82)
	motion_panel.modulate.a = 0.0
	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(motion_panel, "scale", Vector2.ONE, SHOW_SCALE_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(motion_panel, "modulate:a", 1.0, SHOW_FADE_TIME)

func hide_tip(key := "") -> void:
	if key != "" and current_key != key:
		return
	if not visible:
		current_key = ""
		return
	if tween:
		tween.kill()
	current_key = ""
	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(motion_panel, "scale", Vector2(0.7, 0.9), HIDE_SCALE_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(motion_panel, "modulate:a", 0.0, HIDE_FADE_TIME)
	tween.chain().tween_callback(func():
		if current_key == "":
			hide()
	)

func _tip_position(screen_pos: Vector2, target_size: Vector2, item_tip: bool, side := 1.0, target_rect := Rect2(), alignment := "") -> Vector2:
	var horizontal_offset := -target_size.x * 0.10 if side > 0.0 else -target_size.x * 0.90
	var desired := screen_pos + (Vector2(20, 18) if item_tip else Vector2(horizontal_offset, -target_size.y * 0.70))
	if not target_rect.has_area():
		return desired.clamp(Vector2(8, 8), get_viewport_rect().size - size - Vector2(8, 8))
	if alignment == "vertical_center":
		desired.y = target_rect.position.y + (target_rect.size.y - target_size.y) * 0.5
	elif alignment == "horizontal_center":
		desired.x = target_rect.position.x + (target_rect.size.x - target_size.x) * 0.5
	var viewport_size := get_viewport_rect().size
	return desired.clamp(Vector2(8, 8), viewport_size - size - Vector2(8, 8))
