extends Control
const State = preload("res://scripts/trade_state.gd")
const INK = Color("eaddbd")
const GOLD = Color("d0ad70")
const ITEM_OUTLINE = Color("171a17")
const ITEM_OUTLINE_OFFSETS = [
 Vector2(-1.35,-1.35), Vector2(0,-1.65), Vector2(1.35,-1.35),
 Vector2(-1.65,0), Vector2(1.65,0),
 Vector2(-1.35,1.35), Vector2(0,1.65), Vector2(1.35,1.35)
]
const ITEM_TEXTURES = {
 "wastewater": preload("res://assets/items/workbench/wastewater.svg"),
 "copper_pickaxe": preload("res://assets/items/workbench/copper_pickaxe.svg"),
 "slime_mucus": preload("res://assets/items/workbench/slime_mucus.png"),
 "iron_pickaxe": preload("res://assets/items/workbench/iron_pickaxe.svg"),
 "copper_ore": preload("res://assets/items/workbench/copper_ore.svg"),
 "ancient_wood": preload("res://assets/items/workbench/ancient_wood.png"),
 "tempered_axe": preload("res://assets/items/workbench/tempered_axe.svg"),
 "tempered_sword": preload("res://assets/items/workbench/tempered_sword.svg"),
 "alembic": preload("res://assets/items/workbench/alembic-machine.png"),
 "iron_axe": preload("res://assets/items/workbench/iron_axe.svg"),
 "copper_sword": preload("res://assets/items/workbench/copper_sword.svg"),
 "copper_axe": preload("res://assets/items/workbench/copper_axe.svg"),
 # Keep the ordinary-fantasy-v2 batch active; the previous generated batch is archived.
 "small_bag": preload("res://assets/items/candidates/generated/small_bag.png"),
 "pot": preload("res://assets/items/candidates/generated/pot.png"),
 "furnace": preload("res://assets/items/workbench/workbench-machine.png"),
 "iron_sword": preload("res://assets/items/candidates/generated/iron_sword.png"),
 "herb": preload("res://assets/items/candidates/generated/herb.png"),
 "berry": preload("res://assets/items/candidates/generated/berry.png"),
 "meat": preload("res://assets/items/candidates/generated/meat.png"),
 "bread": preload("res://assets/items/candidates/generated/bread.png"),
 "steak": preload("res://assets/items/candidates/generated/steak.png"),
 "ore": preload("res://assets/items/candidates/generated/ore.png"),
 "sword": preload("res://assets/items/candidates/generated/sword.png"),
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
  _draw_texture_with_outline(texture,texture_size)
  draw_set_transform(Vector2.ZERO)
 else:
  var data: Dictionary = State.CATALOG[item.key]
  var color := Color(data.color)
  var scale_value := minf(rect.size.x/48.0,rect.size.y/64.0)
  draw_set_transform(center,item_rotation,Vector2.ONE*scale_value*0.87)
  _icon(item.key,color,1.0)
  draw_set_transform(Vector2.ZERO)
 if highlighted:
  draw_rect(rect.grow(-1),Color("f4ead2"),false,2)

func _draw_texture_with_outline(texture: Texture2D, texture_size: Vector2, tint: Color = Color.WHITE) -> void:
 var texture_rect := Rect2(-texture_size*0.5,texture_size)
 for offset in ITEM_OUTLINE_OFFSETS:
  draw_texture_rect(texture,Rect2(texture_rect.position+offset,texture_rect.size),false,ITEM_OUTLINE)
 draw_texture_rect(texture,texture_rect,false,tint)

func _poly(points: Array, color: Color) -> void:
 var packed := PackedVector2Array()
 for p in points:
  packed.append(Vector2(p[0],p[1]))
 draw_colored_polygon(packed,color)
 packed.append(packed[0])
 draw_polyline(packed,Color("302e25"),1.4,true)

func _icon(key: String, color: Color, a: float) -> void:
 var light := Color(color.lightened(0.35),a)
 var shade := Color(color.darkened(0.35),a)
 color.a = a
 match key:
  "pot":
   draw_arc(Vector2(0,-10),23,PI,TAU,24,GOLD,3,true)
   draw_style_box(_style(Color("4b5149"),GOLD,10),Rect2(-29,-8,58,39))
   draw_line(Vector2(-32,-8),Vector2(32,-8),GOLD,4,true)
   draw_line(Vector2(-19,30),Vector2(-23,38),shade,5)
   draw_line(Vector2(19,30),Vector2(23,38),shade,5)
  "alembic":
   _poly([[-8,-35],[8,-35],[8,-10],[26,23],[18,32],[-18,32],[-26,23],[-8,-10]],shade)
   _poly([[-18,13],[18,13],[22,23],[14,28],[-14,28],[-22,23]],color)
   draw_line(Vector2(9,-29),Vector2(25,-29),GOLD,4)
   draw_line(Vector2(25,-29),Vector2(30,16),GOLD,3)
   draw_rect(Rect2(-14,33,28,6),GOLD)
  "furnace":
   draw_style_box(_style(Color("69615a"),GOLD,5),Rect2(-29,-32,58,66))
   draw_rect(Rect2(5,-46,15,16),shade)
   draw_style_box(_style(Color("292b28"),GOLD,12),Rect2(-21,-12,42,38))
   _poly([[-12,22],[-17,13],[-7,3],[-1,12],[7,-1],[16,14],[9,23]],Color("d18a45"))
   draw_line(Vector2(-23,-21),Vector2(23,-21),shade,2)
  "small_bag":
   draw_style_box(_style(Color("594636"),GOLD,8),Rect2(-28,-33,56,66))
   draw_style_box(_style(Color("9a704e"),Color("d6ad76"),5),Rect2(-22,-19,44,44))
   draw_arc(Vector2(0,-18),17,PI,TAU,18,Color("d6ad76"),4,true)
   draw_line(Vector2(-15,8),Vector2(15,8),Color("d6ad76"),3)
  "potion","power":
   draw_circle(Vector2(1,15),18,Color("101a19"))
   _poly([[-7,-26],[7,-26],[7,-12],[17,0],[18,25],[12,31],[-12,31],[-18,25],[-17,0],[-7,-12]],shade)
   _poly([[-14,5],[14,5],[14,24],[9,27],[-10,27],[-14,22]],color)
   draw_line(Vector2(-8,6),Vector2(-8,21),light,3,true)
   draw_rect(Rect2(-8,-33,16,10),Color("bba078"))
   draw_line(Vector2(-9,-22),Vector2(9,-22),GOLD,3)
   draw_circle(Vector2(1,15),7,Color("e6d7a8"))
   draw_line(Vector2(-3,15),Vector2(5,15),shade,2)
   draw_line(Vector2(1,11),Vector2(1,19),shade,2)
  "sword","iron_sword":
   _poly([[0,-60],[8,-45],[5,24],[-5,24],[-8,-45]],color)
   draw_line(Vector2(0,-48),Vector2(0,22),light,2,true)
   _poly([[-18,22],[-15,16],[0,21],[15,16],[18,22],[4,28],[-4,28]],GOLD)
   draw_rect(Rect2(-4,28,8,21),Color("866144"))
   draw_circle(Vector2(0,52),6,GOLD)
  "herb":
   draw_line(Vector2(0,29),Vector2(1,-29),shade,3,true)
   for i in range(4):
    var y := -24+i*12
    _poly([[0,y+10],[-18,y+2],[-16,y-6],[-7,y-3]],color)
    _poly([[0,y+5],[17,y-9],[19,y],[8,y+7]],light)
   draw_line(Vector2(-7,24),Vector2(8,24),GOLD,4,true)
  "ore":
   _poly([[-26,13],[-17,-15],[-2,-23],[12,-15],[27,7],[17,25],[-13,27]],shade)
   _poly([[-17,-15],[-2,-23],[3,0],[-13,17],[-26,13]],light)
   _poly([[3,0],[12,-15],[27,7],[17,25]],color)
   draw_line(Vector2(3,0),Vector2(17,25),light,2,true)
  "berry":
   for p in [Vector2(-10,2),Vector2(8,4),Vector2(0,-10),Vector2(0,15)]:
    draw_circle(p,11,shade)
    draw_circle(p-Vector2(2,3),8,color)
    draw_circle(p-Vector2(4,5),2,light)
   _poly([[0,-16],[-12,-27],[0,-25],[4,-31],[9,-19]],Color("8ea876"))
  "bread":
   draw_style_box(_style(shade,Color("664a2c"),16),Rect2(-36,-18,72,38))
   draw_style_box(_style(color,color,14),Rect2(-34,-18,68,30))
   for i in range(3):
    draw_line(Vector2(-19+i*18,-11),Vector2(-25+i*18,3),light,4,true)
  "meat","steak":
   draw_circle(Vector2(29,-10),6,INK)
   draw_circle(Vector2(29,0),6,INK)
   draw_line(Vector2(7,1),Vector2(28,-5),INK,7,true)
   draw_style_box(_style(shade,Color("573a30"),15),Rect2(-33,-20,52,39))
   draw_style_box(_style(color,color,12),Rect2(-29,-17,42,29))
   for i in range(3):
    draw_line(Vector2(-23+i*11,-9),Vector2(-17+i*11,6),light if key == "meat" else shade,2,true)
