extends Control
const State = preload("res://scripts/trade_state.gd")
const Chrome = preload("res://scripts/popup_style.gd")
const INK = Chrome.TEXT
const GOLD = Chrome.ACCENT
const Quality = preload("res://scripts/weapon_quality.gd")
static var silhouette_cache: Dictionary = {}
const ITEM_OUTLINE = Color("171a17")
const ITEM_OUTLINE_OFFSETS = [
 Vector2(-1.35,-1.35), Vector2(0,-1.65), Vector2(1.35,-1.35),
 Vector2(-1.65,0), Vector2(1.65,0),
 Vector2(-1.35,1.35), Vector2(0,1.65), Vector2(1.35,1.35)
]
const ITEM_TEXTURES = {
 "moonheart": preload("res://assets/items/story/moonheart.png"),
 "wastewater": preload("res://assets/items/workbench/generated/wastewater.png"),
 "copper_pickaxe": preload("res://assets/items/workbench/generated/copper_pickaxe.png"),
 "slime_mucus": preload("res://assets/items/workbench/slime_mucus-unified.png"),
 "iron_pickaxe": preload("res://assets/items/workbench/generated/iron_pickaxe.png"),
 "copper_ore": preload("res://assets/items/workbench/generated/copper_ore.png"),
 "ancient_wood": preload("res://assets/items/workbench/ancient_wood-unified.png"),
 "tempered_axe": preload("res://assets/items/workbench/generated/tempered_axe.png"),
 "tempered_sword": preload("res://assets/items/workbench/generated/tempered_sword.png"),
 "alembic": preload("res://assets/items/workbench/alembic-machine-unified.png"),
 "iron_axe": preload("res://assets/items/workbench/generated/iron_axe.png"),
 "copper_sword": preload("res://assets/items/workbench/generated/copper_sword.png"),
 "copper_axe": preload("res://assets/items/workbench/generated/copper_axe.png"),
 # Keep the ordinary-fantasy-v2 batch active; the previous generated batch is archived.
 "small_bag": preload("res://assets/items/candidates/generated/small_bag.png"),
 "pot": preload("res://assets/items/candidates/generated/pot.png"),
 "furnace": preload("res://assets/items/workbench/workbench-machine-unified.png"),
 "iron_sword": preload("res://assets/items/workbench/generated/iron_sword.png"),
 "herb": preload("res://assets/items/candidates/generated/herb.png"),
 "berry": preload("res://assets/items/candidates/generated/berry.png"),
 "meat": preload("res://assets/items/candidates/generated/meat.png"),
 "bread": preload("res://assets/items/candidates/generated/bread.png"),
 "steak": preload("res://assets/items/candidates/generated/steak.png"),
 "ore": preload("res://assets/items/candidates/generated/ore.png"),
 "sword": preload("res://assets/items/workbench/generated/sword.png"),
 "potion": preload("res://assets/items/candidates/generated/potion.png"),
 "power": preload("res://assets/items/candidates/generated/power.png"),
}

func _style(bg: Color, border: Color, radius: int = 3) -> StyleBoxFlat:
 var s := StyleBoxFlat.new()
 s.bg_color = bg
 s.border_color = border
 s.set_border_width_all(1)
 s.set_corner_radius_all(radius)
 s.content_margin_left = 12
 s.content_margin_right = 12
 return s

func _draw_item(item: Dictionary, rect: Rect2, highlighted: bool) -> void:
 var center := rect.get_center()
 var texture = ITEM_TEXTURES.get(item.key)
 var item_rotation := PI/2 if item.rotated else 0.0
 if item.zone == "counter":
  item_rotation += float(item.get("counter_angle",0.0))
 if texture is Texture2D:
  # Final assets match the unrotated grid footprint and are alpha-cropped.
  var texture_size := rect.size if not item.rotated else Vector2(rect.size.y,rect.size.x)
  draw_set_transform(center,item_rotation)
  if State.CATALOG[item.key].category == "武器":
   draw_quality_texture(self,texture,Rect2(-texture_size*0.5,texture_size),Quality.tier(item))
  else:
   _draw_texture_with_outline(texture,texture_size)
  draw_set_transform(Vector2.ZERO)
 else:
  push_error("Missing item illustration: "+str(item.key))
  return
 if highlighted:
  if item.zone == "counter":
   draw_rect(rect.grow(-1),Chrome.TEXT,false,2)
  else:
   _draw_footprint(item,rect,Color.TRANSPARENT,Chrome.TEXT,2)

func _footprint_has_point(item: Dictionary, rect: Rect2, point: Vector2) -> bool:
 if not rect.has_point(point):
  return false
 var bounds: Vector2i = State.CATALOG[item.key].size
 if item.rotated:
  bounds = Vector2i(bounds.y,bounds.x)
 var cell_size := rect.size/Vector2(bounds)
 var cell := Vector2i(((point-rect.position)/cell_size).floor())
 return State.footprint(item).has(cell)

func _draw_footprint(item: Dictionary, rect: Rect2, fill: Color, edge := Color.TRANSPARENT, width := 1.0) -> void:
 var bounds: Vector2i = State.CATALOG[item.key].size
 if item.rotated:
  bounds = Vector2i(bounds.y,bounds.x)
 var cell_size := rect.size/Vector2(bounds)
 var cells := State.footprint(item)
 for cell in cells:
  var tile := Rect2(rect.position+Vector2(cell)*cell_size,cell_size)
  if fill.a > 0:
   draw_rect(tile,fill)
  if edge.a <= 0:
   continue
  if not cells.has(cell+Vector2i.UP):
   draw_line(tile.position,Vector2(tile.end.x,tile.position.y),edge,width)
  if not cells.has(cell+Vector2i.DOWN):
   draw_line(Vector2(tile.position.x,tile.end.y),tile.end,edge,width)
  if not cells.has(cell+Vector2i.LEFT):
   draw_line(tile.position,Vector2(tile.position.x,tile.end.y),edge,width)
  if not cells.has(cell+Vector2i.RIGHT):
   draw_line(Vector2(tile.end.x,tile.position.y),tile.end,edge,width)

func _draw_bag_bonus_area(inventory, item: Dictionary, grid: Rect2, cell_size: Vector2, at: Vector2i) -> void:
 for cell in inventory.bag_bonus_cells(item,at):
  var tile := Rect2(grid.position+Vector2(cell)*cell_size,cell_size).grow(-1)
  draw_rect(tile,Chrome.BONUS_AREA)
  draw_rect(tile,Chrome.BONUS_AREA_EDGE,false,1.0)

func _draw_texture_with_outline(texture: Texture2D, texture_size: Vector2, tint: Color = Color.WHITE) -> void:
 var texture_rect := Rect2(-texture_size*0.5,texture_size)
 for offset in ITEM_OUTLINE_OFFSETS:
  draw_texture_rect(texture,Rect2(texture_rect.position+offset,texture_rect.size),false,ITEM_OUTLINE)
 draw_texture_rect(texture,texture_rect,false,tint)

static func draw_quality_texture(canvas: CanvasItem, texture: Texture2D, rect: Rect2, quality: int) -> void:
 if quality >= 0:
  var identity := texture.get_instance_id()
  if not silhouette_cache.has(identity):
   var source := texture.get_image()
   source.decompress()
   source.convert(Image.FORMAT_RGBA8)
   for y in range(source.get_height()):
    for x in range(source.get_width()):
     var alpha := source.get_pixel(x,y).a
     source.set_pixel(x,y,Color(1,1,1,alpha))
   silhouette_cache[identity] = ImageTexture.create_from_image(source)
  var mask: Texture2D = silhouette_cache[identity]
  var color: Color = Quality.COLORS[clampi(quality,0,4)]
  var radius := minf(4.0+quality*0.7,minf(rect.size.x,rect.size.y)*0.18)
  for ring in [1.0,0.5]:
   var tint := Color(color, (0.055+quality*0.025) if ring == 1.0 else (0.14+quality*0.045))
   for n in range(12):
    var offset: Vector2 = Vector2.from_angle(n*TAU/12)*radius*float(ring)
    canvas.draw_texture_rect(mask,Rect2(rect.position+offset,rect.size),false,tint)
 canvas.draw_texture_rect(texture,rect,false)
