extends "res://scripts/item_art.gd"
## Window frame, inventory art and native buttons share one CanvasItem subtree.
const PopupSkin = preload("res://scripts/popup_style.gd")
const WorkbenchView = preload("res://scripts/workbench_view.gd")
var shop: Control
var kind := "machine"
var machine_id := -1
var state:
 get: return shop.state
var font: Font:
 get: return shop.font
var drag_id: int:
 get: return shop.drag_id
var BAG_CELL: Vector2:
 get: return shop.BAG_CELL
var CELL: Vector2:
 get: return shop.CELL
var bag_popup: Rect2:
 get: return Rect2(Vector2.ZERO,size)
var ZONES: Dictionary:
 get:
  var zones := {}
  for key in shop.ZONES:
   zones[key] = shop.ZONES[key].duplicate()
   zones[key].rect.position -= position
  return zones
func _find_item(id: int) -> Dictionary:
 return shop._find_item(id)
func _item_rect(item: Dictionary) -> Rect2:
 var rect: Rect2 = shop._item_rect(item)
 rect.position -= position
 return rect
func _text(value: String, at: Vector2, size_value := 16, color := INK, use_serif := false) -> void:
 draw_string(font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size_value,color)
func _panel(rect: Rect2, bg := PopupSkin.PANEL, border := PopupSkin.FRAME) -> void:
 draw_style_box(PopupSkin.box(bg,border),rect)
func _draw_zone(zone: String, visible_grid := true) -> void:
 var config: Dictionary = ZONES[zone]
 PopupSkin.draw_grid(self,config.rect,state.zone_size(zone),config.cell)
func _draw() -> void:
 if kind == "drag":
  _draw_drag()
  return
 if kind == "machine" and (not shop.machine_popups.has(machine_id) or _find_item(machine_id).is_empty()):
  return
 if kind == "machine" and _find_item(machine_id).key in ["furnace","alembic"]:
  WorkbenchView.draw_window(self,Rect2(Vector2.ZERO,size),machine_id)
  return
 var zone: String = kind if kind != "machine" else state.machine_zone(machine_id)
 if not ZONES.has(zone):
  return
 var title: String = "旅行背包" if kind == "bag" else ("%s的背包" % shop.CUSTOMERS[shop.customer_index].name if kind == "customer" else State.CATALOG[_find_item(machine_id).key].name)
 _draw_bag_shell(Rect2(Vector2.ZERO,size),title,"")
 _draw_zone(zone)
 if kind == "bag" and drag_id < 0:
  var hovered := _find_item(shop.hover_id)
  if not hovered.is_empty() and hovered.zone == "bag":
   _draw_bag_bonus_area(state,hovered,ZONES.bag.rect,BAG_CELL,hovered.cell)
   _draw_footprint(hovered,_item_rect(hovered),Color(PopupSkin.TEXT,0.12))
 for item in state.items:
  if item.zone == zone and item.id != drag_id:
   _draw_item(item,_item_rect(item),kind == "bag" and drag_id < 0 and shop.hover_id == item.id)
func _draw_drag() -> void:
 if drag_id >= 0:
  var item := _find_item(drag_id).duplicate()
  if not item.is_empty():
   item.rotated = shop.drag_rotated
   item.counter_angle = 0.0
   var d: Vector2i = state.dimensions(item)
   var zone: String = shop._zone_at(shop.mouse)
   if zone == "counter":
    var ghost_rect := Rect2(shop.mouse-shop.drag_offset,Vector2(d)*CELL)
    draw_rect(ghost_rect,PopupSkin.placement(true,0.18),true)
    draw_rect(ghost_rect.grow(-1),PopupSkin.TEXT,false,2)
   elif zone != "":
    var at: Vector2i = shop._cell_at(shop.mouse-shop.drag_offset,zone)
    var pos: Vector2 = ZONES[zone].rect.position+Vector2(at)*ZONES[zone].cell
    var valid: bool = shop._valid_drop(item,zone,at)
    if zone == "bag":
     _draw_bag_bonus_area(state,item,ZONES[zone].rect,ZONES[zone].cell,at)
    _draw_footprint(item,Rect2(pos,Vector2(d)*ZONES[zone].cell),PopupSkin.placement(valid),PopupSkin.SUCCESS if valid else PopupSkin.WARNING)
   var ghost_cell: Vector2 = BAG_CELL if item.zone == "bag" else CELL
   if zone != "" and zone != "counter":
    ghost_cell = ZONES[zone].cell
   _draw_item(item,Rect2(shop.mouse-shop.drag_offset,Vector2(d)*ghost_cell),true)

func _draw_bag_shell(rect: Rect2, title: String, hint: String) -> void:
 PopupSkin.draw_window(self,rect)
 PopupSkin.title(self,title,rect.position+Vector2(18,32))
 if hint != "":
  _text(hint,rect.position+Vector2(18,rect.size.y-12),14,PopupSkin.MUTED)

