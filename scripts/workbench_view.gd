extends Control
## Read-only recipe drawings. No placement guides or automatic filling.
const Rules = preload("res://scripts/workbench_rules.gd")
const State = preload("res://scripts/trade_state.gd")
const Chrome = preload("res://scripts/popup_style.gd")
var alchemy := false
var page := 0
var font: Font

func _ready() -> void:
 font = Chrome.font()
 mouse_filter = Control.MOUSE_FILTER_IGNORE

func text(value: String, at: Vector2, size_value := 14, color := Chrome.TEXT) -> void:
 draw_string(font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size_value,color)

func recipe_count() -> int:
 return State.Alchemy.recipes().size() if alchemy else Rules.recipes().size()

func _draw() -> void:
 if alchemy:
  _draw_alchemy_recipe()
  return
 var recipe: Dictionary = Rules.recipes()[page]
 var data: Dictionary = State.CATALOG[recipe.output]
 Chrome.draw_window(self,Rect2(0,0,640,480))
 Chrome.title(self,"配方图纸",Vector2(26,32))
 text("%02d / %02d" % [page+1,Rules.recipes().size()],Vector2(490,31),14,Chrome.HEADER_TEXT)
 text(data.name,Vector2(28,92),24)
 text("材料摆放图",Vector2(28,122),14,Chrome.MUTED)
 var origin := Vector2(28,138)
 draw_rect(Rect2(origin,Vector2(228,228)),Chrome.GRID)
 for n in range(9):
  draw_line(origin+Vector2(n*28.5,0),origin+Vector2(n*28.5,228),Chrome.GRID_LINE)
  draw_line(origin+Vector2(0,n*28.5),origin+Vector2(228,n*28.5),Chrome.GRID_LINE)
 for i in range(recipe.materials.size()):
  var point: Vector2i = Rules.SHAPES[recipe.shape][i]
  var rect := Rect2(origin+Vector2(1,1)*28.5+Vector2(point)*57,Vector2(56,56))
  var material: Dictionary = State.CATALOG[recipe.materials[i]]
  draw_rect(rect,Color(Color(material.color),0.22))
  draw_rect(rect,Color(material.color),false,1.5)
  text("铜" if recipe.materials[i] == "copper_ore" else "铁",rect.position+Vector2(18,35),20,Color(material.color).lightened(0.25))
 text("每块材料占 2 × 2 格",Vector2(28,389),14,Chrome.MUTED)
 text("材料",Vector2(292,150),14,Chrome.MUTED)
 var counts := {}
 for key in recipe.materials:
  counts[key] = counts.get(key,0)+1
 var y := 181
 for key in counts:
  text("%s × %d" % [State.CATALOG[key].name,counts[key]],Vector2(292,y),17)
  y += 28
 text("燃料（每件消耗一份）",Vector2(292,260),14,Chrome.MUTED)
 text("任意燃料" if recipe.fuel == "" else State.CATALOG[recipe.fuel].name+" · 指定燃料",Vector2(292,289),17,Chrome.ORANGE if recipe.fuel != "" else Chrome.TEXT)
 text("史莱姆粘液 60%  /  古藤木 100%",Vector2(292,318),14,Chrome.MUTED)
 text("纯度越高，成品最大耐久越高。",Vector2(292,343),14,Chrome.MUTED)
 text("次日产出 × 1  ·  攻击 %d" % data.get("attack",8),Vector2(292,388),15)
 text("形状可平移，斧形可左右镜像；混搭无配方时产出赤铜装备。",Vector2(28,421),14,Chrome.MUTED)

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
  shop._text("▣" if alchemy_window else ["◆","▣","▣"][n],p+Vector2(xs[n]+13,74),15,Chrome.ORANGE if n == 0 and not alchemy_window else Chrome.MUTED)
  shop._text(labels[n],p+Vector2(xs[n]+35,74),14,Chrome.TEXT)
  var grid: Rect2 = shop.ZONES[zones[n]].rect
  shop.draw_rect(grid,Chrome.GRID)
  var dimensions: Vector2i = shop.state.zone_size(zones[n])
  for x in range(dimensions.x+1):
   shop.draw_line(grid.position+Vector2(x*24,0),grid.position+Vector2(x*24,192),Chrome.GRID_LINE)
  for y in range(9):
   shop.draw_line(grid.position+Vector2(0,y*24),grid.position+Vector2(grid.size.x,y*24),Chrome.GRID_LINE)
  shop.draw_rect(grid.grow(1),Chrome.DIVIDER,false,1)
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

func _draw_alchemy_recipe() -> void:
 var recipe: Dictionary = State.Alchemy.recipes()[page]
 Chrome.draw_window(self,Rect2(0,0,640,480))
 Chrome.title(self,"炼药配方图纸",Vector2(26,32))
 text("%02d / %02d" % [page+1,recipe_count()],Vector2(490,31),14,Chrome.HEADER_TEXT)
 text(State.CATALOG[recipe.output].name,Vector2(28,96),24)
 text("材料搭配",Vector2(28,137),14,Chrome.MUTED)
 var y := 162
 for key in recipe.ingredients:
  draw_style_box(Chrome.box(Chrome.BACKGROUND,Chrome.DIVIDER),Rect2(28,y,282,66))
  var texture: Texture2D = preload("res://scripts/item_art.gd").ITEM_TEXTURES[key]
  var fit := 44.0 / maxf(texture.get_width(),texture.get_height())
  var icon_size := texture.get_size()*fit
  draw_texture_rect(texture,Rect2(Vector2(59,y+33)-icon_size/2,icon_size),false)
  text("%s × %d" % [State.CATALOG[key].name,recipe.ingredients[key]],Vector2(94,y+40),18)
  y += 82
 draw_line(Vector2(337,152),Vector2(337,347),Chrome.DIVIDER)
 text("产出",Vector2(366,169),15,Chrome.MUTED)
 var product: Texture2D = preload("res://scripts/item_art.gd").ITEM_TEXTURES[recipe.output]
 draw_texture_rect(product,Rect2(440,189,30,90),false)
 text(State.CATALOG[recipe.output].name,Vector2(391,311),19)
 text("防护 +15" if recipe.output == "potion" else "本场攻击力 +20%",Vector2(385,339),15,Chrome.MUTED)
 text("燃料     史莱姆粘液 ×1瓶   /   古藤木 ×2瓶",Vector2(28,383),15,Chrome.TEXT)
