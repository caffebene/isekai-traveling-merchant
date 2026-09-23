extends RefCounted
## Shared dark-industrial chrome for inventory, trade and processing windows.
##
## The scene art already carries the ZZZ-inspired metal language. Keeping the
## chrome here as tokens lets every runtime window use the same frame, header
## and button states without duplicating style boxes in each presenter.
const PAPER = Color("f1f0eb")
const INK = Color("f1f0eb")
const DARK = Color("11161a")
const MUTED = Color("a7afb3")
const WALNUT = Color("12181d")
const BRASS = Color("e7e4dc")
const PANEL = Color("11181df5")
const PANEL_ALT = Color("202a30")
const CYAN = Color("32c5d1")
const ORANGE = Color("ff5a2f")
const WARNING = Color("d98683")

static func box(color: Color, border := BRASS, radius := 0) -> StyleBoxFlat:
 var s := StyleBoxFlat.new()
 s.bg_color = color
 s.border_color = border
 s.set_border_width_all(1)
 s.set_corner_radius_all(radius)
 return s

static func panel() -> StyleBoxFlat:
 var s := box(PANEL,BRASS,0)
 s.shadow_color = Color(0.0,0.0,0.0,0.58)
 s.shadow_size = 8
 s.shadow_offset = Vector2(5,5)
 s.content_margin_left = 12
 s.content_margin_right = 12
 s.content_margin_top = 10
 s.content_margin_bottom = 10
 return s

static func header() -> StyleBoxFlat:
 var s := box(PANEL_ALT,BRASS,0)
 s.border_width_bottom = 1
 s.content_margin_left = 12
 s.content_margin_right = 12
 return s

static func button(b: Button, primary := false) -> void:
 b.add_theme_font_size_override("font_size",14)
 b.add_theme_color_override("font_color",DARK if primary else PAPER)
 b.add_theme_color_override("font_hover_color",DARK)
 b.add_theme_color_override("font_pressed_color",DARK)
 b.add_theme_color_override("font_disabled_color",Color("6e7a70"))
 var normal := box(ORANGE if primary else Color("1b2429"),ORANGE if primary else BRASS,0)
 var hover := box(CYAN if primary else ORANGE,INK,0)
 var pressed := box(Color("d9d6cf") if primary else Color("303b41"),INK,0)
 var disabled := box(Color("20272b"),Color("556067"),0)
 normal.content_margin_left = 10
 normal.content_margin_right = 10
 hover.content_margin_left = 10
 hover.content_margin_right = 10
 pressed.content_margin_left = 10
 pressed.content_margin_right = 10
 b.add_theme_stylebox_override("normal",normal)
 b.add_theme_stylebox_override("hover",hover)
 b.add_theme_stylebox_override("pressed",pressed)
 b.add_theme_stylebox_override("disabled",disabled)
 b.add_theme_stylebox_override("focus",box(Color(0,0,0,0),ORANGE,0))
 b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

static func window_points(rect: Rect2, cut := 10.0) -> PackedVector2Array:
 return PackedVector2Array([
  rect.position + Vector2(cut,0),
  rect.position + Vector2(rect.size.x,0),
  rect.position + Vector2(rect.size.x,rect.size.y-cut),
  rect.position + Vector2(rect.size.x-cut,rect.size.y),
  rect.position + Vector2(0,rect.size.y),
  rect.position + Vector2(0,cut)
 ])

static func header_points(rect: Rect2, cut := 10.0) -> PackedVector2Array:
 return PackedVector2Array([
  rect.position + Vector2(cut,0),
  rect.position + Vector2(rect.size.x,0),
  rect.position + Vector2(rect.size.x,rect.size.y),
  rect.position + Vector2(0,rect.size.y),
  rect.position + Vector2(0,cut)
 ])
