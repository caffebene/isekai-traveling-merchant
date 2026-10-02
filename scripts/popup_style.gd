extends RefCounted
## Single runtime design system. See docs/game-design/整体视觉与UI规范.md.
const BACKGROUND = Color("15191e")
const PANEL = Color("222830")
const PANEL_ALT = Color("2c333d")
const TEXT = Color("f2eee5")
const MUTED = Color("aab2ba")
const FRAME = Color("69737e")
const DIVIDER = Color("3b4550")
const ORANGE = Color("ff6b35")
const CYAN = Color("55c7cc")
const WARNING = Color("e56b6f")
const DISABLED = Color("727b85")
const GRID = Color("1a2027")
const GRID_LINE = Color("37424d")
const SHADE = Color("101419c9")
const TITLE_SIZE = 24
const HEADING_SIZE = 20
const BODY_SIZE = 16
const SECONDARY_SIZE = 14
const CUT = 8.0
const HEADER = TEXT
const HEADER_TEXT = BACKGROUND
static var regular_face: SystemFont
static var bold_face: SystemFont
# Compatibility aliases for existing presenters; new code uses semantic names.
const PAPER = TEXT
const INK = TEXT
const DARK = BACKGROUND
const WALNUT = BACKGROUND
const BRASS = FRAME

static func font(bold := false) -> SystemFont:
 if bold and bold_face != null:
  return bold_face
 if not bold and regular_face != null:
  return regular_face
 var face := SystemFont.new()
 face.font_names = PackedStringArray(["PingFang SC","Noto Sans CJK SC","Microsoft YaHei"])
 face.font_weight = 700 if bold else 400
 if bold:
  bold_face = face
 else:
  regular_face = face
 return face

static func theme() -> Theme:
 var result := Theme.new()
 result.default_font = font()
 result.default_font_size = BODY_SIZE
 return result

static func box(color: Color, border := DIVIDER, radius := 0) -> StyleBoxFlat:
 var s := StyleBoxFlat.new()
 s.bg_color = color
 s.border_color = border
 s.set_border_width_all(0 if border == Color.TRANSPARENT else 1)
 s.set_corner_radius_all(radius)
 s.content_margin_left = 12
 s.content_margin_right = 12
 s.content_margin_top = 8
 s.content_margin_bottom = 8
 return s

static func panel() -> StyleBoxFlat:
 var s := box(PANEL,FRAME)
 s.shadow_color = Color(0,0,0,0.35)
 s.shadow_size = 4
 s.shadow_offset = Vector2(3,3)
 return s

static func header() -> StyleBoxFlat:
 return box(HEADER,Color.TRANSPARENT)

static func button(b: Button, primary := false) -> void:
 b.add_theme_font_override("font",font(true))
 b.add_theme_font_size_override("font_size",BODY_SIZE)
 b.add_theme_color_override("font_color",DARK if primary else TEXT)
 b.add_theme_color_override("font_hover_color",DARK if primary else TEXT)
 b.add_theme_color_override("font_pressed_color",DARK if primary else TEXT)
 b.add_theme_color_override("font_disabled_color",DISABLED)
 for mode in ["normal","hover","pressed","disabled"]:
  var fill: Color = ORANGE if primary else BACKGROUND
  var edge: Color = ORANGE if primary else DIVIDER
  if mode == "hover":
   fill = ORANGE.lightened(0.12) if primary else PANEL_ALT
  elif mode == "pressed":
   fill = ORANGE.darkened(0.12) if primary else BACKGROUND
  elif mode == "disabled":
   fill = PANEL_ALT
   edge = DIVIDER
  var style := box(fill,edge,2)
  style.border_width_bottom = 3 if mode != "pressed" else 1
  style.border_color = ORANGE.darkened(0.35) if primary and mode != "disabled" else edge
  style.content_margin_left = 12
  style.content_margin_right = 12
  style.content_margin_top = 4
  style.content_margin_bottom = 4
  b.add_theme_stylebox_override(mode,style)
 b.add_theme_stylebox_override("focus",box(Color.TRANSPARENT,ORANGE))
 b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
 if not b.has_meta("ui_feedback"):
  b.set_meta("ui_feedback",true)
  b.button_down.connect(func(): b.pivot_offset=b.size*0.5; _button_motion(b,Vector2(0.985,0.96)))
  b.button_up.connect(func(): _button_motion(b,Vector2.ONE))
  b.mouse_exited.connect(func(): _button_motion(b,Vector2.ONE))

static func _button_motion(b: Button, target: Vector2) -> void:
 if b.has_meta("ui_tween"):
  var previous: Tween = b.get_meta("ui_tween")
  if previous and previous.is_valid():
   previous.kill()
 var motion := b.create_tween()
 b.set_meta("ui_tween",motion)
 motion.tween_property(b,"scale",target,0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

static func close_button(b: Button) -> void:
 button(b)
 b.size = Vector2(32,32)
 b.add_theme_font_size_override("font_size",20)

static func window_points(rect: Rect2, cut := CUT) -> PackedVector2Array:
 return PackedVector2Array([
  rect.position+Vector2(cut,0),rect.position+Vector2(rect.size.x,0),
  rect.position+Vector2(rect.size.x,rect.size.y-cut),rect.position+Vector2(rect.size.x-cut,rect.size.y),
  rect.position+Vector2(0,rect.size.y),rect.position+Vector2(0,cut)
 ])

static func header_points(rect: Rect2, cut := CUT) -> PackedVector2Array:
 return PackedVector2Array([
  rect.position+Vector2(cut,0),rect.position+Vector2(rect.size.x,0),
  rect.position+rect.size,rect.position+Vector2(0,rect.size.y),rect.position+Vector2(0,cut)
 ])

static func draw_window(canvas: CanvasItem, rect: Rect2, title_bar := true) -> void:
 canvas.draw_colored_polygon(window_points(Rect2(rect.position+Vector2(3,3),rect.size)),Color(0,0,0,0.35))
 canvas.draw_colored_polygon(window_points(rect),PANEL)
 var outline := window_points(rect)
 outline.append(outline[0])
 canvas.draw_polyline(outline,FRAME,1.0,true)
 if title_bar:
  canvas.draw_colored_polygon(header_points(Rect2(rect.position,Vector2(rect.size.x,48))),HEADER)
  canvas.draw_rect(Rect2(rect.position+Vector2(0,8),Vector2(4,32)),ORANGE)
  canvas.draw_line(rect.position+Vector2(0,48),rect.position+Vector2(rect.size.x,48),BACKGROUND,2)
  if rect.size.x >= 360:
   for offset in [76,88]:
    var p := rect.position+Vector2(rect.size.x-offset,10)
    canvas.draw_colored_polygon(PackedVector2Array([p,p+Vector2(5,0),p+Vector2(-5,28),p+Vector2(-10,28)]),DIVIDER)

static func window(host: Panel, title_bar := true) -> void:
 host.add_theme_stylebox_override("panel",StyleBoxEmpty.new())
 host.draw.connect(func(): draw_window(host,Rect2(Vector2.ZERO,host.size),title_bar))

static func title(canvas: CanvasItem, value: String, baseline: Vector2, size_value := HEADING_SIZE) -> void:
 canvas.draw_string(font(true),baseline,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size_value,HEADER_TEXT)

static func draw_grid(canvas: CanvasItem, rect: Rect2, dims: Vector2i, cell := Vector2(24,24)) -> void:
 canvas.draw_rect(rect,GRID)
 for x in range(dims.x+1):
  canvas.draw_line(rect.position+Vector2(x*cell.x,0),rect.position+Vector2(x*cell.x,rect.size.y),GRID_LINE)
 for y in range(dims.y+1):
  canvas.draw_line(rect.position+Vector2(0,y*cell.y),rect.position+Vector2(rect.size.x,y*cell.y),GRID_LINE)

static func placement(valid: bool, alpha := 0.25) -> Color:
 return Color(CYAN if valid else WARNING,alpha)

static func draw_module_icon(canvas: CanvasItem, id: String, at: Vector2) -> void:
 if id == "roof_rack":
  canvas.draw_rect(Rect2(at+Vector2(3,12),Vector2(42,28)),TEXT,false,2)
  for x in [13,24,35]:
   canvas.draw_line(at+Vector2(x,12),at+Vector2(x,40),TEXT,2)
  canvas.draw_line(at+Vector2(0,44),at+Vector2(48,44),ORANGE,4)
 elif id == "hidden_compartment":
  var outline := PackedVector2Array([at+Vector2(24,5),at+Vector2(43,12),at+Vector2(39,32),at+Vector2(24,45),at+Vector2(9,32),at+Vector2(5,12),at+Vector2(24,5)])
  canvas.draw_polyline(outline,TEXT,2,true)
  canvas.draw_rect(Rect2(at+Vector2(18,23),Vector2(12,10)),ORANGE)
  canvas.draw_arc(at+Vector2(24,23),5,PI,TAU,16,TEXT,2,true)
 else:
  canvas.draw_rect(Rect2(at+Vector2(9,20),Vector2(30,19)),TEXT,false,2)
  canvas.draw_line(at+Vector2(5,17),at+Vector2(43,17),TEXT,2)
  for x in [17,25,33]:
   canvas.draw_line(at+Vector2(x,5),at+Vector2(x-3,11),TEXT,2)
  canvas.draw_colored_polygon(PackedVector2Array([at+Vector2(17,46),at+Vector2(24,40),at+Vector2(31,46)]),ORANGE)
