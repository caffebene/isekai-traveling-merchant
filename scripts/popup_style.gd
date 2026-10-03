extends RefCounted
## Single runtime design system. See docs/game-design/整体视觉与UI规范.md.
const BACKGROUND = Color("171513")
const PANEL = Color("171717")
const PANEL_ALT = Color("241c16")
const TEXT = Color("dfd4bd")
const MUTED = Color("a99478")
const FRAME = Color("8d6843")
const DIVIDER = Color("5e432e")
const ACCENT = Color("aa7943")
const ORANGE = ACCENT
const SUCCESS = Color("73a77a")
const CYAN = SUCCESS
const WARNING = Color("bd6b5c")
const DISABLED = Color("716459")
const GRID = Color("141210")
const GRID_LINE = Color("463725")
const SHADE = Color("100d0acc")
const TITLE_SIZE = 24
const HEADING_SIZE = 20
const BODY_SIZE = 16
const SECONDARY_SIZE = 14
const CUT = 0.0
const HEADER = PANEL
const HEADER_TEXT = Color("e2c98e")
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
 face.font_names = PackedStringArray(["Songti SC","Noto Serif CJK SC","SimSun"]) if bold else PackedStringArray(["PingFang SC","Noto Sans CJK SC","Microsoft YaHei"])
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
 s.set_corner_radius_all(maxi(4,radius))
 s.content_margin_left = 12
 s.content_margin_right = 12
 s.content_margin_top = 8
 s.content_margin_bottom = 8
 return s

static func panel() -> StyleBoxFlat:
 var s := box(PANEL,DIVIDER,5)
 s.set_border_width_all(4)
 s.border_color = DIVIDER
 s.border_width_top = 4
 s.border_width_bottom = 5
 s.shadow_color = Color(0,0,0,0.35)
 s.shadow_size = 4
 s.shadow_offset = Vector2(3,3)
 return s

static func header() -> StyleBoxFlat:
 return box(HEADER,Color.TRANSPARENT)

static func button(b: Button, primary := false) -> void:
 b.add_theme_font_override("font",font(true))
 b.add_theme_font_size_override("font_size",BODY_SIZE)
 b.add_theme_color_override("font_color",HEADER_TEXT if primary else TEXT)
 b.add_theme_color_override("font_hover_color",HEADER_TEXT if primary else TEXT)
 b.add_theme_color_override("font_pressed_color",HEADER_TEXT if primary else TEXT)
 b.add_theme_color_override("font_disabled_color",DISABLED)
 for mode in ["normal","hover","pressed","disabled"]:
  var fill: Color = Color("49301d") if primary else PANEL_ALT
  var edge: Color = FRAME if primary else DIVIDER
  if mode == "hover":
   fill = Color("614125") if primary else PANEL_ALT.lightened(0.12)
  elif mode == "pressed":
   fill = Color("352317") if primary else BACKGROUND
  elif mode == "disabled":
   fill = PANEL_ALT
   edge = DIVIDER
  var style := box(fill,edge,2)
  style.border_width_bottom = 3 if mode != "pressed" else 1
  style.border_color = ACCENT.darkened(0.35) if primary and mode != "disabled" else edge
  style.content_margin_left = 12
  style.content_margin_right = 12
  style.content_margin_top = 4
  style.content_margin_bottom = 4
  b.add_theme_stylebox_override(mode,style)
 b.add_theme_stylebox_override("focus",box(Color.TRANSPARENT,ACCENT))
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
 b.add_theme_font_override("font",font())
 b.add_theme_font_size_override("font_size",20)
 for mode in ["normal","hover","pressed","disabled"]:
  var style: StyleBoxFlat = b.get_theme_stylebox(mode).duplicate()
  style.content_margin_left = 0
  style.content_margin_right = 0
  style.content_margin_top = 0
  style.content_margin_bottom = 0
  style.set_border_width_all(1)
  b.add_theme_stylebox_override(mode,style)
 b.custom_minimum_size = Vector2(32,32)
 b.size = Vector2(32,32)

static func place_close(b: Button, window_width: float) -> void:
 b.position = Vector2(window_width-48,8)

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
 canvas.draw_style_box(panel(),rect)
 canvas.draw_style_box(box(Color.TRANSPARENT,FRAME,4),rect.grow(-4))
 if title_bar:
  canvas.draw_line(rect.position+Vector2(12,48),rect.position+Vector2(rect.size.x-12,48),DIVIDER,1.5)
 for point in [rect.position+Vector2(4,4),rect.position+Vector2(rect.size.x-7,4),rect.position+Vector2(4,rect.size.y-7),rect.end-Vector2(7,7)]:
  canvas.draw_rect(Rect2(point,Vector2(3,3)),FRAME)

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
 return Color(SUCCESS if valid else WARNING,alpha)

static func draw_module_icon(canvas: CanvasItem, id: String, at: Vector2) -> void:
 if id == "roof_rack":
  canvas.draw_rect(Rect2(at+Vector2(3,12),Vector2(42,28)),TEXT,false,2)
  for x in [13,24,35]:
   canvas.draw_line(at+Vector2(x,12),at+Vector2(x,40),TEXT,2)
  canvas.draw_line(at+Vector2(0,44),at+Vector2(48,44),ACCENT,4)
 elif id == "hidden_compartment":
  var outline := PackedVector2Array([at+Vector2(24,5),at+Vector2(43,12),at+Vector2(39,32),at+Vector2(24,45),at+Vector2(9,32),at+Vector2(5,12),at+Vector2(24,5)])
  canvas.draw_polyline(outline,TEXT,2,true)
  canvas.draw_rect(Rect2(at+Vector2(18,23),Vector2(12,10)),ACCENT)
  canvas.draw_arc(at+Vector2(24,23),5,PI,TAU,16,TEXT,2,true)
 else:
  canvas.draw_rect(Rect2(at+Vector2(9,20),Vector2(30,19)),TEXT,false,2)
  canvas.draw_line(at+Vector2(5,17),at+Vector2(43,17),TEXT,2)
  for x in [17,25,33]:
   canvas.draw_line(at+Vector2(x,5),at+Vector2(x-3,11),TEXT,2)
  canvas.draw_colored_polygon(PackedVector2Array([at+Vector2(17,46),at+Vector2(24,40),at+Vector2(31,46)]),ACCENT)


# Recipe notebooks are physical illustrated pages, not management modals.
const BOOK_PAPER = Color("d7cbb2")
const BOOK_INK = Color("493c31")
const BOOK_WASH = Color("c2a29c")
const NEWS_PAPER = BOOK_PAPER
const NEWS_INK = BOOK_INK
const NEWS_MUTED = Color("796852")
const NEWS_RULE = Color("9a8262")

static func newspaper_panel() -> StyleBoxFlat:
 var style := box(NEWS_PAPER,FRAME,2)
 style.set_border_width_all(2)
 style.shadow_color = Color(0,0,0,0.4)
 style.shadow_size = 8
 style.shadow_offset = Vector2(4,5)
 return style
static func draw_notebook(canvas: CanvasItem, rect: Rect2) -> void:
 canvas.draw_style_box(box(Color("49392c"),DIVIDER,8),Rect2(rect.position+Vector2(4,5),rect.size))
 canvas.draw_style_box(box(BOOK_PAPER,FRAME,8),rect)
 canvas.draw_style_box(box(BOOK_PAPER.darkened(0.09),Color.TRANSPARENT,4),Rect2(rect.position+Vector2(6,5),Vector2(27,rect.size.y-10)))
 canvas.draw_style_box(box(Color(BOOK_WASH,0.35),Color.TRANSPARENT,18),Rect2(rect.position+Vector2(46,66),rect.size-Vector2(70,118)))
 canvas.draw_line(rect.position+Vector2(40,8),rect.position+Vector2(40,rect.size.y-8),Color(BOOK_INK,0.25),1)
 for y in range(80,int(rect.size.y)-30,90):
  canvas.draw_circle(rect.position+Vector2(25,y),4,BOOK_INK)
  canvas.draw_style_box(box(Color("969287"),Color("555349"),3),Rect2(rect.position+Vector2(-10,y-3),Vector2(38,6)))


static func draw_fuel_icon(canvas: CanvasItem, center: Vector2, scale_value := 1.0) -> void:
 # A category pictogram, distinct from specific inventory item artwork.
 var contour := PackedVector2Array([Vector2(0,-30),Vector2(5,-15),Vector2(15,-22),Vector2(14,-7),Vector2(23,5),Vector2(22,17),Vector2(13,27),Vector2(0,30),Vector2(-14,26),Vector2(-23,16),Vector2(-24,3),Vector2(-17,-10),Vector2(-14,1),Vector2(-7,-6)])
 for i in range(contour.size()):
  contour[i] = center + contour[i]*scale_value
 canvas.draw_colored_polygon(contour,BOOK_INK)
 var core := PackedVector2Array([center+Vector2(0,-2)*scale_value,center+Vector2(9,16)*scale_value,center+Vector2(0,23)*scale_value,center+Vector2(-9,16)*scale_value])
 canvas.draw_colored_polygon(core,BOOK_PAPER)

# Temporary adjacency preview, used only while hovering or dragging in the bag.
const BONUS_AREA := Color("E2C15B",0.25)
const BONUS_AREA_EDGE := Color("E2C15B",0.55)
