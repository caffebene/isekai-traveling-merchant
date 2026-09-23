extends Control
## Read-only recipe drawings. No placement guides or automatic filling.
const Rules = preload("res://scripts/workbench_rules.gd")
const State = preload("res://scripts/trade_state.gd")
const Chrome = preload("res://scripts/popup_style.gd")
var alchemy := false
var page := 0
var font: Font

func _ready() -> void:
 font = SystemFont.new()
 font.font_names = ["PingFang SC","Noto Sans CJK SC","sans-serif"]
 mouse_filter = Control.MOUSE_FILTER_IGNORE

func text(value: String, at: Vector2, size_value := 14, color := Chrome.PAPER) -> void:
 draw_string(font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size_value,color)

func recipe_count() -> int:
 return State.Alchemy.recipes().size() if alchemy else Rules.recipes().size()

func _draw() -> void:
 if alchemy:
  _draw_alchemy_recipe()
  return
 var recipe: Dictionary = Rules.recipes()[page]
 var data: Dictionary = State.CATALOG[recipe.output]
 draw_style_box(Chrome.panel(),Rect2(0,0,640,480))
 draw_rect(Rect2(8,8,624,48),Chrome.PANEL_ALT)
 draw_rect(Rect2(8,8,5,48),Chrome.ORANGE)
 text("配方图纸",Vector2(26,39),22)
 text("%02d / %02d" % [page+1,Rules.recipes().size()],Vector2(513,39),14,Chrome.MUTED)
 text(data.name,Vector2(28,92),24)
 text("材料摆放图",Vector2(28,122),13,Chrome.MUTED)
 var origin := Vector2(28,138)
 draw_rect(Rect2(origin,Vector2(228,228)),Color("14242d"))
 for n in range(9):
  draw_line(origin+Vector2(n*28.5,0),origin+Vector2(n*28.5,228),Color("31444e"))
  draw_line(origin+Vector2(0,n*28.5),origin+Vector2(228,n*28.5),Color("31444e"))
 for i in range(recipe.materials.size()):
  var point: Vector2i = Rules.SHAPES[recipe.shape][i]
  var rect := Rect2(origin+Vector2(1,1)*28.5+Vector2(point)*57,Vector2(56,56))
  var material: Dictionary = State.CATALOG[recipe.materials[i]]
  draw_rect(rect,Color(Color(material.color),0.22))
  draw_rect(rect,Color(material.color),false,1.5)
  text("铜" if recipe.materials[i] == "copper_ore" else "铁",rect.position+Vector2(18,35),20,Color(material.color).lightened(0.25))
 text("每块材料占 2 × 2 格",Vector2(28,389),13,Chrome.MUTED)
 text("材料",Vector2(292,150),14,Chrome.MUTED)
 var counts := {}
 for key in recipe.materials:
  counts[key] = counts.get(key,0)+1
 var y := 181
 for key in counts:
  text("%s × %d" % [State.CATALOG[key].name,counts[key]],Vector2(292,y),17)
  y += 28
 text("燃料（每件消耗一份）",Vector2(292,260),14,Chrome.MUTED)
 text("任意燃料" if recipe.fuel == "" else State.CATALOG[recipe.fuel].name+" · 指定燃料",Vector2(292,289),17,Chrome.ORANGE if recipe.fuel != "" else Chrome.PAPER)
 text("史莱姆粘液 60%  /  古藤木 100%",Vector2(292,318),13,Chrome.MUTED)
 text("纯度越高，成品最大耐久越高。",Vector2(292,343),13,Chrome.MUTED)
 text("次日产出 × 1  ·  攻击 %d" % data.get("attack",8),Vector2(292,388),15)
 text("形状可平移，斧形可左右镜像；混搭无配方时产出赤铜装备。",Vector2(28,421),13,Chrome.MUTED)

static func draw_window(shop: Control, rect: Rect2, id: int) -> void:
 var p := rect.position
 var alchemy_window: bool = shop._find_item(id).key == "alembic"
 var width := rect.size.x
 # Layered metal frame, clipped corners, fasteners and orange edge markers.
 shop.draw_colored_polygon(Chrome.window_points(Rect2(p+Vector2(5,6),rect.size),9),Color(0,0,0,0.65))
 shop.draw_colored_polygon(Chrome.window_points(rect,9),Color("101519"))
 var outline := Chrome.window_points(rect.grow(-2),8)
 outline.append(outline[0])
 shop.draw_polyline(outline,Color("8b8e88"),2,true)
 shop.draw_rect(rect.grow(-8),Color("303537"),false,3)
 shop.draw_rect(Rect2(p+Vector2(16,10),Vector2(width-32,34)),Color("20292f"))
 shop.draw_line(p+Vector2(18,11),p+Vector2(width-19,11),Color("8c918e"))
 shop.draw_rect(Rect2(p+Vector2(16,12),Vector2(6,30)),Chrome.ORANGE)
 shop._text("炼药锅" if alchemy_window else "工作台",p+Vector2(32,34),21,Chrome.PAPER)
 shop._text("A L C H E M Y" if alchemy_window else "W O R K B E N C H",p+Vector2(132,33),8,Color("879498"))
 for side in [8,width-14]:
  for y in [68,244,296]:
   shop.draw_colored_polygon(PackedVector2Array([p+Vector2(side,y),p+Vector2(side+6,y+6),p+Vector2(side+6,y+23),p+Vector2(side,y+17)]),Chrome.ORANGE)
 for bolt in [Vector2(10,10),Vector2(width-10,10),Vector2(10,rect.size.y-10),Vector2(width-10,rect.size.y-10)]:
  shop.draw_circle(p+bolt,3,Color("777e7d"))
  shop.draw_line(p+bolt-Vector2(1,1),p+bolt+Vector2(1,1),Color("172024"),1)
 var plan: Dictionary = shop.state.alchemy_preview(id) if alchemy_window else shop.state.workbench_preview(id)
 var zones: Array = [shop.state.machine_zone(id),shop.state.machine_output_zone(id)] if alchemy_window else [shop.state.machine_fuel_zone(id),shop.state.machine_zone(id),shop.state.machine_output_zone(id)]
 var labels: Array = ["材料","产出"] if alchemy_window else ["燃料","输入","输出"]
 var xs: Array = [16,248] if alchemy_window else [16,152,384]
 var widths: Array = [216,120] if alchemy_window else [120,216,120]
 for n in range(zones.size()):
  var panel := Rect2(p+Vector2(xs[n],52),Vector2(widths[n],254))
  shop.draw_style_box(Chrome.box(Color("192126"),Color("777d7e"),2),panel)
  shop.draw_line(panel.position+Vector2(2,2),panel.position+Vector2(panel.size.x-2,2),Color("a0a49b"),1)
  shop.draw_rect(Rect2(panel.position+Vector2(3,3),Vector2(3,panel.size.y-6)),Color("44494b"))
  shop._text("▣" if alchemy_window else ["◆","▣","▣"][n],p+Vector2(xs[n]+13,74),15,Chrome.ORANGE if n == 0 and not alchemy_window else Color("d1b79e"))
  shop._text(labels[n],p+Vector2(xs[n]+35,74),14,Chrome.PAPER)
  var grid: Rect2 = shop.ZONES[zones[n]].rect
  shop.draw_rect(grid,Color("10191e"))
  var dimensions: Vector2i = shop.state.zone_size(zones[n])
  for x in range(dimensions.x+1):
   shop.draw_line(grid.position+Vector2(x*24,0),grid.position+Vector2(x*24,192),Color("29343a"))
  for y in range(9):
   shop.draw_line(grid.position+Vector2(0,y*24),grid.position+Vector2(grid.size.x,y*24),Color("29343a"))
  shop.draw_rect(grid.grow(1),Color("636d70"),false,1)
  shop._text("%d × 8" % dimensions.x,Vector2(grid.get_center().x-15,p.y+298),10,Chrome.MUTED)
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
    shop._text("？？？",anchor+Vector2(0,40),19,Chrome.PAPER)
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
    shop._text("× %d" % plan.quantity,out_grid.position+Vector2(60,-16),12,Chrome.PAPER)
 if alchemy_window:
  var fuel_zone: String = shop.state.machine_fuel_zone(id)
  var fuel_grid: Rect2 = shop.ZONES[fuel_zone].rect
  shop.draw_style_box(Chrome.box(Color("192126"),Color("777d7e")),Rect2(p+Vector2(16,310),Vector2(352,68)))
  shop._text("燃料",p+Vector2(28,348),14,Chrome.PAPER)
  shop.draw_rect(fuel_grid,Color("10191e"))
  for x in range(13):
   shop.draw_line(fuel_grid.position+Vector2(x*24,0),fuel_grid.position+Vector2(x*24,48),Color("29343a"))
  for y in range(3):
   shop.draw_line(fuel_grid.position+Vector2(0,y*24),fuel_grid.position+Vector2(288,y*24),Color("29343a"))
  shop.draw_rect(fuel_grid,Color("636d70"),false,1)
  for item in shop.state.items:
   if item.zone == fuel_zone and item.id != shop.drag_id:
    shop._draw_item(item,shop._item_rect(item),false)
 elif not plan.ready and plan.output != "":
  shop._text(plan.status,p+Vector2(20,325),12,Chrome.MUTED)

func _draw_alchemy_recipe() -> void:
 var recipe: Dictionary = State.Alchemy.recipes()[page]
 draw_style_box(Chrome.panel(),Rect2(0,0,640,480))
 draw_rect(Rect2(8,8,624,48),Chrome.PANEL_ALT)
 draw_rect(Rect2(8,8,5,48),Chrome.ORANGE)
 text("炼药配方图纸",Vector2(26,39),22)
 text("%02d / %02d" % [page+1,recipe_count()],Vector2(513,39),14,Chrome.MUTED)
 text(State.CATALOG[recipe.output].name,Vector2(28,96),24)
 text("材料搭配",Vector2(28,137),14,Chrome.MUTED)
 var y := 162
 for key in recipe.ingredients:
  draw_style_box(Chrome.box(Color("1b2a2e"),Color("526a70")),Rect2(28,y,282,66))
  var texture: Texture2D = preload("res://scripts/item_art.gd").ITEM_TEXTURES[key]
  var fit := 44.0 / maxf(texture.get_width(),texture.get_height())
  var icon_size := texture.get_size()*fit
  draw_texture_rect(texture,Rect2(Vector2(59,y+33)-icon_size/2,icon_size),false)
  text("%s × %d" % [State.CATALOG[key].name,recipe.ingredients[key]],Vector2(94,y+40),18)
  y += 82
 draw_line(Vector2(337,152),Vector2(337,347),Color("526a70"))
 text("产出",Vector2(366,169),15,Chrome.MUTED)
 var product: Texture2D = preload("res://scripts/item_art.gd").ITEM_TEXTURES[recipe.output]
 draw_texture_rect(product,Rect2(440,189,30,90),false)
 text(State.CATALOG[recipe.output].name,Vector2(391,311),19)
 text("防护 +15" if recipe.output == "potion" else "本场攻击力 +20%",Vector2(385,339),15,Chrome.MUTED)
 text("燃料     史莱姆粘液 ×1瓶   /   古藤木 ×2瓶",Vector2(28,383),15,Chrome.PAPER)
