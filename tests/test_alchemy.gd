extends SceneTree
const State = preload("res://scripts/trade_state.gd")
var checks := 0
var failures := 0

func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  push_error("FAILED: "+message)

func fixture():
 var s = State.new()
 s.items.clear()
 s.serial = 0
 s.add_item("alembic","stock","player")
 s.add_item("slime_mucus",s.machine_fuel_zone(0),"player")
 return s

func put(s, key: String, cell: Vector2i, rotated := false) -> Dictionary:
 check(s.add_item(key,"stock","player"),"add material")
 var item: Dictionary = s.items.back()
 check(s.move_item(item.id,s.machine_zone(0),cell,rotated) == "","place material")
 return item

func _initialize() -> void:
 run.call_deferred()

func run() -> void:
 for recipe in State.Alchemy.recipes():
  for rotated in [false,true]:
   var s = fixture()
   var keys: Array = []
   for key in recipe.ingredients:
    for n in range(recipe.ingredients[key]):
     keys.append(key)
   if rotated:
    keys.reverse()
   var positions := [Vector2i(1,1),Vector2i(5,4),Vector2i(0,6)] if rotated else [Vector2i(5,4),Vector2i(0,0),Vector2i(7,0)]
   for n in range(keys.size()):
    put(s,keys[n],positions[n],rotated)
   var plan: Dictionary = s.alchemy_preview(0)
   check(plan.ready and not plan.unknown and plan.output == recipe.output,"exact counts match regardless of position/order/rotation")
   check(plan.preview_name == State.CATALOG[recipe.output].name,"known preview reveals correct potion")
   s.advance_day()
   var products: Array = s.items.filter(func(i): return i.zone == s.machine_output_zone(0))
   check(products.size() == 1 and products[0].key == recipe.output,"one potion per combination")
   check(s.items.filter(func(i): return i.zone == s.machine_zone(0)).is_empty(),"all recipe ingredients consumed")
   s.advance_day()
   check(s.items.filter(func(i): return i.zone == s.machine_output_zone(0)).size() == 1,"no repeat production or reprocessing product")
   var product: Dictionary = products[0]
   check(s.move_item(product.id,"stock",s.free_cell(product,"stock"),false) == "","retrieve potion")
   check(s.move_item(product.id,s.machine_output_zone(0),Vector2i.ZERO,false) != "","cannot refill output manually")
 for keys in [["herb"],["berry"],["herb","herb","berry"],["herb","herb","herb"],["meat"]]:
  var s = fixture()
  for n in range(keys.size()):
   put(s,keys[n],Vector2i(n*2,0))
  var plan: Dictionary = s.alchemy_preview(0)
  check(plan.ready and plan.unknown and plan.preview_name == "？？？","unknown combination masked")
  check(not plan.status.contains("废水"),"status does not reveal outcome")
  s.advance_day()
  var waste: Array = s.items.filter(func(i): return i.zone == s.machine_output_zone(0))
  check(waste.size() == 1 and waste[0].key == "wastewater","unknown combination actually makes wastewater")
  check(s.items.filter(func(i): return i.zone == s.machine_zone(0)).is_empty(),"failed brewing consumes all inputs")
  check(s.move_item(waste[0].id,s.machine_zone(0),Vector2i.ZERO,false) != "","wastewater cannot re-enter materials")
 var s = fixture()
 check(not s.alchemy_preview(0).ready and s.alchemy_preview(0).preview_name == "","empty pot does not make wastewater")
 for key in ["ore","slime_mucus","potion","sword"]:
  s.add_item(key,"stock","player")
  var item: Dictionary = s.items.back()
  check(s.move_item(item.id,s.machine_zone(0),Vector2i.ZERO,false) != "","reject non-material "+key)
 var herb := put(s,"herb",Vector2i.ZERO)
 herb.owner = "customer"
 check(s.move_item(herb.id,s.machine_zone(0),Vector2i(2,0),false) != "","reject unpaid materials")
 herb.owner = "player"
 for n in range(8):
  s.add_item("ore",s.machine_output_zone(0),"player")
 var snapshot: Array = s.items.filter(func(i): return i.owner == "player").duplicate(true)
 check(not s.alchemy_preview(0).ready,"full output pauses unknown brewing")
 s.advance_day()
 check(s.items.filter(func(i): return i.owner == "player") == snapshot,"full output preserves inputs")
 for item in s.items.filter(func(i): return i.zone == s.machine_output_zone(0)):
  s.items.erase(item)
 s.advance_day()
 check(s.items.any(func(i): return i.key == "wastewater"),"resume once space exists")
 fuel_checks()
 await window_checks()
 print("ALCHEMY %s: %d checks (%d failures)" % ["PASS" if failures == 0 else "FAIL",checks,failures])
 quit(1 if failures else 0)

func shot(name: String) -> void:
 if not "--capture" in OS.get_cmdline_user_args():
  return
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://docs/testing/previews/"+name+".png")

func window_checks() -> void:
 var shop = load("res://main.tscn").instantiate()
 root.add_child(shop)
 await process_frame
 shop._clear_dialogue()
 var device: Dictionary = shop.state.items.filter(func(i): return i.key == "alembic")[0]
 var id: int = device.id
 shop._open_machine(id)
 check(shop.machine_popups[id].size == Vector2(384,388),"two-bay brewing window")
 check(shop.state.machine_zones(id).size() == 3,"input, output and bottom fuel")
 var fuel: Dictionary = shop.state.items.filter(func(i): return i.key == "slime_mucus")[0]
 check(shop.state.move_item(fuel.id,shop.state.machine_fuel_zone(id),Vector2i.ZERO,false) == "","load bottom fuel")
 var inputs: String = shop.state.machine_zone(id)
 var outputs: String = shop.state.machine_output_zone(id)
 check(shop._zone_at(shop.ZONES[outputs].rect.get_center()) == outputs,"output hit target")
 var herb: Dictionary = shop.state.items.filter(func(i): return i.key == "herb")[0]
 shop.drag_id = herb.id
 shop.drag_rotated = false
 shop.drag_offset = Vector2.ZERO
 shop._finish_drag(shop.ZONES[inputs].rect.position)
 check(herb.zone == inputs,"drag material through shop")
 shop.mouse = shop.ZONES[outputs].rect.get_center()
 check(shop._show_workbench_preview(),"unknown preview tooltip exists")
 check(shop.hover_tip.label.text == "？？？" and not shop.hover_tip.body_label.text.contains("废水"),"tooltip also conceals wastewater")
 shop._hide_hover_tip()
 await shot("炼药器-未知组合")
 shop.recipe_buttons[id].emit_signal("pressed")
 var drawing = shop.modal.get_child(0)
 check(drawing.alchemy and drawing.recipe_count() == 2,"alchemy recipe drawings share modal")
 for child in drawing.get_children():
  if child is Button and child.text == "下一张":
   child.emit_signal("pressed")
 check(drawing.page == 1,"alchemy recipe paging")
 await shot("炼药器-配方图纸")
 shop._close_modal()
 shop._close_machine(id)
 shop._open_machine(id)
 check(shop.state.alchemy_preview(id).unknown,"closing preserves input")
 shop.state.advance_day()
 var waste: Dictionary = shop.state.items.filter(func(i): return i.zone == outputs)[0]
 check(waste.key == "wastewater" and shop._item_at(shop._item_rect(waste).get_center()) == waste.id,"completed waste is real retrievable item")
 await shot("炼药器-废水")
 var remaining_herbs: Array = shop.state.items.filter(func(i): return i.key == "herb" and i.owner == "player")
 shop.state.add_item("herb","stock","player")
 remaining_herbs.append(shop.state.items.back())
 for n in range(2):
  check(shop.state.move_item(remaining_herbs[n].id,inputs,Vector2i(1+n*4,1+n*3),false) == "","arbitrary placement in actual UI")
 check(shop.state.alchemy_preview(id).preview_name == "防护药剂","known preview alongside prior output")
 await shot("炼药器-已知配方")
 shop.state.add_item("slime_mucus",shop.state.machine_fuel_zone(id),"player")
 shop.state.advance_day()
 check(shop.state.items.filter(func(i): return i.zone == outputs).size() == 2,"new potion accumulates beside wastewater")
 var furnace: Dictionary = shop.state.items.filter(func(i): return i.key == "furnace")[0]
 shop._open_machine(furnace.id)
 shop._close_machine(id)
 check(shop.machine_popups.has(furnace.id) and not shop.ZONES.has(outputs),"closing alchemy preserves workbench")
 shop.queue_free()
 await process_frame

func fuel_checks() -> void:
 for fuel in State.Alchemy.FUEL_YIELDS:
  for known in [false,true]:
   var s = fixture()
   s.items = s.items.filter(func(i): return i.key != "slime_mucus")
   s.add_item(fuel,s.machine_fuel_zone(0),"player")
   s.add_item(fuel,s.machine_fuel_zone(0),"player")
   put(s,"herb",Vector2i.ZERO)
   if known:
    put(s,"herb",Vector2i(3,3))
   var plan: Dictionary = s.alchemy_preview(0)
   var quantity: int = State.Alchemy.FUEL_YIELDS[fuel]
   check(plan.ready and plan.quantity == quantity and plan.placements.size() == quantity,"fuel determines batch size")
   check(plan.preview_name == ("防护药剂" if known else "？？？"),"fuel does not reveal unknown recipe")
   s.advance_day()
   var outputs: Array = s.items.filter(func(i): return i.zone == s.machine_output_zone(0))
   check(outputs.size() == quantity,"actual batch matches fuel")
   check(s.items.filter(func(i): return i.zone == s.machine_fuel_zone(0)).size() == 1,"only one fuel consumed per batch")
   for item in outputs:
    check(s.fits(item,item.zone,item.cell,item.id),"batch bottles do not overlap")
 var s = fixture()
 s.items = s.items.filter(func(i): return i.key != "slime_mucus")
 put(s,"herb",Vector2i.ZERO)
 var snapshot: Array = s.items.filter(func(i): return i.owner == "player").duplicate(true)
 check(not s.alchemy_preview(0).ready and s.alchemy_preview(0).preview_name == "？？？","missing fuel keeps unknown identity masked")
 s.advance_day()
 check(s.items.filter(func(i): return i.owner == "player") == snapshot,"no fuel consumes nothing")
 s.add_item("ancient_wood",s.machine_fuel_zone(0),"player")
 s.add_item("slime_mucus","stock","player")
 check(s.move_item(s.items.back().id,s.machine_fuel_zone(0),Vector2i(2,0),false) != "","mixed fuel rejected")
 # Leave exactly one bottle column free, enough for one bottle but not two.
 for x in range(4):
  for y in range(6 if x == 3 else 8):
   s.add_item("berry",s.machine_output_zone(0),"player")
   s.items.back().cell = Vector2i(x,y)
 snapshot = s.items.filter(func(i): return i.owner == "player").duplicate(true)
 check(not s.alchemy_preview(0).ready,"require space for the complete two-bottle batch")
 s.advance_day()
 check(s.items.filter(func(i): return i.owner == "player") == snapshot,"partial batch must not consume fuel or ingredients")
