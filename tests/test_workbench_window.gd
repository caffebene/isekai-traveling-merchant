extends SceneTree
const State = preload("res://scripts/trade_state.gd")
var checks := 0
var failures := 0
var capture := false

func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  push_error("FAILED: "+message)


func _initialize() -> void:
 capture = "--capture" in OS.get_cmdline_user_args()
 run.call_deferred()

func shot(filename: String) -> void:
 if not capture:
  return
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://docs/testing/previews/"+filename+".png")

func run() -> void:
 var shop = load("res://main.tscn").instantiate()
 root.add_child(shop)
 await process_frame
 shop._clear_dialogue()
 var bench: Dictionary = shop.state.items.filter(func(i): return i.key == "furnace")[0]
 var id: int = bench.id
 shop._open_machine(id)
 check(shop.machine_popups[id].size == Vector2(520,340),"workbench reference proportions")
 check(shop.state.zone_size(shop.state.machine_zone(id)) == Vector2i(8,8),"8x8 input")
 for zone in shop.state.machine_zones(id):
  check(shop.ZONES.has(zone),"three independent drop targets")
  check(shop._zone_at(shop.ZONES[zone].rect.get_center()) == zone,"hit testing resolves each zone")
 await shot("工作台-空白")
 var ores: Array = shop.state.items.filter(func(i): return i.key == "copper_ore")
 for n in range(3):
  shop.drag_id = ores[n].id
  shop.drag_rotated = false
  shop.drag_offset = Vector2.ZERO
  shop._finish_drag(shop.ZONES[shop.state.machine_zone(id)].rect.position+Vector2(24,24+n*48))
  check(ores[n].zone == shop.state.machine_zone(id),"drag drop ore through shop")
 var fuel: Dictionary = shop.state.items.filter(func(i): return i.key == "slime_mucus")[0]
 shop.drag_id = fuel.id
 shop.drag_rotated = false
 shop.drag_offset = Vector2.ZERO
 shop._finish_drag(shop.ZONES[shop.state.machine_fuel_zone(id)].rect.position)
 check(fuel.zone == shop.state.machine_fuel_zone(id),"drag fuel through shop")
 check(shop.state.workbench_preview(id).ready,"dragged recipe ready")
 check(shop._item_at(shop._item_rect(ores[1]).get_center()) == ores[1].id,"input item hit testing")
 await shot("工作台-待加工")
 shop.recipe_buttons[id].emit_signal("pressed")
 check(shop.modal != null and shop.drag_id == -1,"button opens read-only drawings")
 var drawing = shop.modal.get_child(0)
 check(drawing.page == 0,"first recipe page")
 for child in drawing.get_children():
  if child is Button and child.text == "下一张":
   child.emit_signal("pressed")
 check(drawing.page == 1,"next recipe drawing")
 drawing.page = 6
 drawing.queue_redraw()
 await shot("工作台-配方图纸")
 shop._close_modal()
 shop.state.advance_day()
 var output: Array = shop.state.items.filter(func(i): return i.zone == shop.state.machine_output_zone(id))
 check(output.size() == 1,"day transition creates output")
 check(shop._item_at(shop._item_rect(output[0]).get_center()) == output[0].id,"output item hit testing")
 await shot("工作台-已完成")
 shop._close_machine(id)
 for zone in shop.state.machine_zones(id):
  check(not shop.ZONES.has(zone),"closing removes every zone")
 shop._open_machine(id)
 check(shop.state.items.any(func(i): return i.id == output[0].id),"close and reopen keeps contents")
 var old_rect: Rect2 = shop.machine_popups[id]
 shop.machine_popups[id] = Rect2(old_rect.position+Vector2(80,20),old_rect.size)
 shop._sync_machine_window(id)
 check(shop.ZONES[shop.state.machine_fuel_zone(id)].rect.position == old_rect.position+Vector2(108,110),"zones move with the window")
 for key in ["pot","alembic"]:
  var machine: Dictionary = shop.state.items.filter(func(i): return i.key == key)[0]
  shop._open_machine(machine.id)
 check(shop.machine_popups.size() == 3,"other machines still independently open")
 shop._close_machine(id)
 check(shop.machine_popups.size() == 2,"close workbench preserves other machines")
 # Every new item has a real texture and participates in the counter's geometry cache.
 shop.customer_index = 3
 shop._apply_customer_profile()
 var goods: Array = shop.state.items.filter(func(i): return i.owner == "customer")
 check(goods.size() == 10,"merchant stocks complete supplies")
 for item in goods:
  shop._quick_move(item.id)
  check(item.zone == "counter" and not item.trade_rejected,"supply is purchasable through the actual shop")
 await process_frame
 check(shop.state.buying_items().size() == 10,"purchase includes all supply types")
 shop.customer_index = 1
 shop._apply_customer_profile()
 var product: Dictionary = output[0]
 shop._quick_move(product.id)
 check(shop.state.selling_items().any(func(i): return i.id == product.id),"crafted equipment is accepted by the weapon buyer")
 var previous_gold: int = shop.state.gold
 check(shop.state.settle().begins_with("交易完成"),"crafted equipment sale settles")
 check(shop.state.gold > previous_gold and product.owner == "customer","crafted equipment yields sale income")
 print("WORKBENCH WINDOW %s: %d checks (%d failures)" % ["PASS" if failures == 0 else "FAIL",checks,failures])
 shop.queue_free()
 await process_frame
 quit(1 if failures else 0)
