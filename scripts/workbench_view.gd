extends Control
## Read-only movable recipe notebook. Recipe evaluation stays in the existing rules.
signal close_requested
const Rules = preload("res://scripts/workbench_rules.gd")
const State = preload("res://scripts/trade_state.gd")
const Chrome = preload("res://scripts/popup_style.gd")
const Art = preload("res://scripts/item_art.gd")
var alchemy := false
var page := 0
var font: Font
var dragging := false

func _ready() -> void:
 font = Chrome.font()
 size = Vector2(520,620)
 mouse_filter = Control.MOUSE_FILTER_STOP
 var close := Button.new()
 close.text = "×"
 Chrome.close_button(close)
 Chrome.place_close(close,size.x)
 close.pressed.connect(func(): close_requested.emit())
 add_child(close)
 for direction in [-1,1]:
  var button := Button.new()
  button.text = "上一张" if direction < 0 else "下一张"
  button.position = Vector2(124 if direction < 0 else 300,576)
  button.size = Vector2(96,32)
  Chrome.button(button)
  button.pressed.connect(func(): page = posmod(page+direction,recipe_count()); queue_redraw())
  add_child(button)

func _gui_input(event: InputEvent) -> void:
 if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
  if event.pressed and event.position.y < 58 and event.position.x < size.x-56:
   dragging = true
  elif not event.pressed:
   dragging = false
 if event is InputEventMouseMotion and dragging:
  position = (position+event.relative).clamp(Vector2(8,8),Vector2(1600,868)-size-Vector2(8,8))
 accept_event()

func text(value: String, at: Vector2, size_value := 14, color := Chrome.BOOK_INK, centered := false) -> void:
 var width := font.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size_value).x
 draw_string(font,at-Vector2(width/2 if centered else 0.0,0),value,HORIZONTAL_ALIGNMENT_LEFT,-1,size_value,color)

func recipe_count() -> int:
 return State.Alchemy.recipes().size() if alchemy else Rules.recipes().size()

func icon(key: String, center: Vector2, bounds: Vector2) -> void:
 var texture: Texture2D = Art.ITEM_TEXTURES[key]
 var fit := minf(bounds.x/texture.get_width(),bounds.y/texture.get_height())
 var image_size := texture.get_size()*fit
 draw_texture_rect(texture,Rect2(center-image_size/2,image_size),false)

func arrow(points: PackedVector2Array) -> void:
 draw_polyline(points,Chrome.BOOK_INK,2.0,true)
 var tip := points[-1]
 var direction := (tip-points[-2]).normalized()
 var side := Vector2(-direction.y,direction.x)
 draw_polyline(PackedVector2Array([tip-direction*13+side*6,tip,tip-direction*13-side*6]),Chrome.BOOK_INK,2.0,true)

func clock(center: Vector2) -> void:
 draw_arc(center,13,0,TAU,32,Chrome.BOOK_INK,1.5,true)
 draw_line(center,center+Vector2(0,-8),Chrome.BOOK_INK,1.5,true)
 draw_line(center,center+Vector2(7,3),Chrome.BOOK_INK,1.5,true)
 text("次日",center+Vector2(0,35),14,Chrome.BOOK_INK,true)

func _draw() -> void:
 Chrome.draw_notebook(self,Rect2(Vector2.ZERO,size))
 draw_string(Chrome.font(true),Vector2(48,32),"炼药配方册" if alchemy else "锻造配方册",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Chrome.BOOK_INK)
 var recipe: Dictionary = State.Alchemy.recipes()[page] if alchemy else Rules.recipes()[page]
 text(State.CATALOG[recipe.output].name,Vector2(270,90),22,Chrome.BOOK_INK,true)
 if alchemy:
  _draw_alchemy_diagram(recipe)
 else:
  _draw_forge_diagram(recipe)
 text("%d / %d" % [page+1,recipe_count()],Vector2(260,598),14,Chrome.BOOK_INK,true)

func _draw_recipe_fuel(recipe: Dictionary, center: Vector2) -> void:
 var required_fuel: String = str(recipe.get("fuel",""))
 if required_fuel.is_empty():
  Chrome.draw_fuel_icon(self,center)
  text("任意燃料",center+Vector2(0,52),16,Chrome.BOOK_INK,true)
 else:
  icon(required_fuel,center,Vector2(74,60))
  text(State.CATALOG[required_fuel].name,center+Vector2(0,52),16,Chrome.BOOK_INK,true)

func _draw_forge_diagram(recipe: Dictionary) -> void:
 var points: Array = Rules.SHAPES[recipe.shape]
 var columns := 1
 for point: Vector2i in points:
  columns = maxi(columns,point.x+1)
 var origin := Vector2(166-columns*28,120)
 for i in range(points.size()):
  icon(recipe.materials[i],origin+Vector2(points[i])*56+Vector2(28,28),Vector2(54,54))
 var counts := {}
 for key in recipe.materials:
  counts[key] = counts.get(key,0)+1
 var x := 112.0
 for key in counts:
  icon(key,Vector2(x,320),Vector2(24,24))
  text("×%d" % counts[key],Vector2(x+17,326),14)
  x += 85
 _draw_recipe_fuel(recipe,Vector2(374,230))
 arrow(PackedVector2Array([Vector2(175,345),Vector2(195,362),Vector2(230,377)]))
 arrow(PackedVector2Array([Vector2(365,344),Vector2(324,361),Vector2(293,377)]))
 icon("furnace",Vector2(262,406),Vector2(110,88))
 clock(Vector2(222,483))
 arrow(PackedVector2Array([Vector2(290,453),Vector2(312,480),Vector2(331,508)]))
 icon(recipe.output,Vector2(370,504),Vector2(96,106))
 text("×1",Vector2(370,567),16,Chrome.BOOK_INK,true)

func _draw_alchemy_diagram(recipe: Dictionary) -> void:
 var keys: Array = recipe.ingredients.keys()
 for i in range(keys.size()):
  var x := 270.0 if keys.size() == 1 else 153.0+i*222
  icon(keys[i],Vector2(x,175),Vector2(94,112))
  text("×%d" % recipe.ingredients[keys[i]],Vector2(x,249),18,Chrome.BOOK_INK,true)
  arrow(PackedVector2Array([Vector2(x,266),Vector2(270+(x-270)*0.4,298),Vector2(270+(x-270)*0.17,322)]))
 icon("alembic",Vector2(270,374),Vector2(100,104))
 _draw_recipe_fuel(recipe,Vector2(98,365))
 arrow(PackedVector2Array([Vector2(156,405),Vector2(193,392),Vector2(215,382)]))
 clock(Vector2(255,476))
 arrow(PackedVector2Array([Vector2(302,432),Vector2(324,466),Vector2(353,488)]))
 icon(recipe.output,Vector2(386,508),Vector2(76,108))

static func draw_window(shop: Control, rect: Rect2, id: int) -> void:
 var p := rect.position
 var alchemy_window: bool = shop._find_item(id).key == "alembic"
 var width := rect.size.x
 Chrome.draw_window(shop,rect)
 Chrome.title(shop,"炼药器" if alchemy_window else "工作台",p+Vector2(18,32))
 var plan: Dictionary = shop.state.alchemy_preview(id) if alchemy_window else shop.state.workbench_preview(id)
 var zones: Array = [shop.state.machine_zone(id),shop.state.machine_output_zone(id)] if alchemy_window else [shop.state.machine_fuel_zone(id),shop.state.machine_zone(id),shop.state.machine_output_zone(id)]
 var labels: Array = ["材料","产出"] if alchemy_window else ["燃料","输入","输出"]
 var xs: Array = [16,248] if alchemy_window else [16,152,384]
 var widths: Array = [216,120] if alchemy_window else [120,216,120]
 for n in range(zones.size()):
  var panel := Rect2(p+Vector2(xs[n],52),Vector2(widths[n],254))
  shop.draw_style_box(Chrome.box(Chrome.BACKGROUND,Chrome.DIVIDER),panel)
  shop.draw_line(panel.position+Vector2(2,2),panel.position+Vector2(panel.size.x-2,2),Chrome.DIVIDER,1)
  shop.draw_rect(Rect2(panel.position+Vector2(3,3),Vector2(3,panel.size.y-6)),Chrome.DIVIDER)
  shop._text(labels[n],p+Vector2(xs[n]+13,74),14,Chrome.TEXT)
  var grid: Rect2 = shop.ZONES[zones[n]].rect
  shop.draw_rect(grid,Chrome.GRID)
  var dimensions: Vector2i = shop.state.zone_size(zones[n])
  for x in range(dimensions.x+1):
   shop.draw_line(grid.position+Vector2(x*24,0),grid.position+Vector2(x*24,192),Chrome.GRID_LINE)
  for y in range(9):
   shop.draw_line(grid.position+Vector2(0,y*24),grid.position+Vector2(grid.size.x,y*24),Chrome.GRID_LINE)
  shop.draw_rect(grid.grow(1),Chrome.DIVIDER,false,1)
  for item in shop.state.items:
   if item.zone == zones[n]:
    if item.id != shop.drag_id:
     shop._draw_item(item,shop._item_rect(item),false)
 if plan.output != "":
  var out_grid: Rect2 = shop.ZONES[zones.back()].rect
  if alchemy_window and plan.unknown:
   # Never draw the real product texture or name before unknown brewing resolves.
   if plan.cell.x >= 0:
    var anchor := out_grid.position+Vector2(plan.cell)*24
    anchor.x = minf(anchor.x,out_grid.end.x-62)
    shop._text("？？？",anchor+Vector2(0,40),19,Chrome.TEXT)
   else:
    shop._text("？？？",out_grid.position+Vector2(48,-16),12,Chrome.MUTED)
  elif plan.cell.x >= 0:
   var previews: Array = plan.placements if alchemy_window else [{"rect":Rect2i(plan.cell,Vector2i.ZERO),"rotated":plan.rotated}]
   for placement in previews:
    var d: Vector2i = shop.state.CATALOG[plan.output].size
    var texture: Texture2D = shop.ITEM_TEXTURES[plan.output]
    var size_value := Vector2(d)*24
    var displayed_size := Vector2(size_value.y,size_value.x) if placement.rotated else size_value
    var center := out_grid.position+Vector2(placement.rect.position)*24+displayed_size/2
    shop.draw_set_transform(center,PI/2 if placement.rotated else 0.0)
    shop.draw_texture_rect(texture,Rect2(-size_value/2,size_value),false,Color(1,1,1,0.35))
    shop.draw_set_transform(Vector2.ZERO)
   if alchemy_window:
    shop._text("× %d" % plan.quantity,out_grid.position+Vector2(60,-16),12,Chrome.TEXT)
 if alchemy_window:
  var fuel_zone: String = shop.state.machine_fuel_zone(id)
  var fuel_grid: Rect2 = shop.ZONES[fuel_zone].rect
  shop.draw_style_box(Chrome.box(Chrome.BACKGROUND,Chrome.DIVIDER),Rect2(p+Vector2(16,310),Vector2(352,68)))
  shop._text("燃料",p+Vector2(28,348),14,Chrome.TEXT)
  shop.draw_rect(fuel_grid,Chrome.GRID)
  for x in range(13):
   shop.draw_line(fuel_grid.position+Vector2(x*24,0),fuel_grid.position+Vector2(x*24,48),Chrome.GRID_LINE)
  for y in range(3):
   shop.draw_line(fuel_grid.position+Vector2(0,y*24),fuel_grid.position+Vector2(288,y*24),Chrome.GRID_LINE)
  shop.draw_rect(fuel_grid,Chrome.DIVIDER,false,1)
  for item in shop.state.items:
   if item.zone == fuel_zone and item.id != shop.drag_id:
    shop._draw_item(item,shop._item_rect(item),false)
 elif not plan.ready and plan.output != "":
  shop._text(plan.status,p+Vector2(20,325),12,Chrome.MUTED)
