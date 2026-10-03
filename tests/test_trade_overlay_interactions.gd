extends SceneTree
const State = preload("res://scripts/trade_state.gd")

var checks := 0

func check(value: bool, message: String) -> void:
 checks += 1
 if not value:
  push_error("FAILED: " + message)
  quit(1)

func select_next_seed(shop, target: int) -> void:
 var before: Dictionary=shop.state.customer_memory.duplicate(true)
 for seed_value in range(2000):
  shop.customer_rng.seed=seed_value
  var next: int=shop._next_customer_index()
  shop.state.customer_memory=before.duplicate(true)
  if next==target:
   shop.customer_rng.seed=seed_value
   return
 push_error("unable to seed intended UI fixture")

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var shop = load("res://main.tscn").instantiate()
 root.add_child(shop)
 await process_frame
 shop.customer_index=0; shop._apply_customer_profile(); shop._start_customer_conversation(); shop._sync()
 check(not shop.customer_bag_open and not shop.ZONES.has("customer") and not shop.customer_bag_window_node.visible,"buyer without goods has no visible inventory or drop zone")
 check(shop.customer_bag_window_node.find_children("*","Button",true,false).is_empty(),"customer inventory has no close control")
 var escape := InputEventKey.new()
 escape.pressed = true
 escape.keycode = KEY_ESCAPE
 shop._customer_bag_input(escape)
 shop._unhandled_input(escape)
 check(not shop.customer_bag_open,"Escape does not open a buyer inventory")
 check(shop.door_art != null and shop.bed_art != null and shop.table_art != null,"scene props are installed")
 check(shop.computer_art != null and shop.phone_art != null and shop.bell_art != null and shop.door_closer_art != null,"new interaction props are installed")
 check(shop.computer_art.size == Vector2(240,210) and shop.phone_art.size.is_equal_approx(Vector2(66.1538,43)),"computer and phone match the reference layout proportions")
 check(shop.shutter_clip != null and shop.shutter_clip.size.y == 0.0 and shop.shutter_clip.position.y == 84.0,"roller shutter starts open at the original window position")
 shop.computer_art.emit_signal("pressed")
 check(shop.trade_panel.keep_open and shop.trade_panel.visible,"computer click opens the trade panel")
 check(shop.trade_panel.close != null,"trade panel exposes a close button")
 shop.computer_art.emit_signal("pressed")
 check(not shop.trade_panel.visible and not shop.trade_panel.keep_open,"clicking the computer again closes the trade panel")
 shop.computer_art.emit_signal("pressed")
 shop.trade_panel.close.emit_signal("pressed")
 check(not shop.trade_panel.visible and not shop.trade_panel.keep_open,"trade panel close button closes only the trade panel")
 shop.phone_art.emit_signal("pressed")
 check(shop.recorder_panel != null and shop.recorder_panel.size == Vector2(320,540),"phone click opens the shared history panel")
 shop.phone_art.emit_signal("pressed")
 check(shop.recorder_panel == null,"clicking the phone again closes the history panel")
 var bell_press := InputEventMouseButton.new()
 bell_press.button_index = MOUSE_BUTTON_LEFT
 bell_press.pressed = true
 shop._bell_gui_input(bell_press)
 check(shop.bell_hold_active,"bell press starts long-press mode")
 shop.bell_hold_time = shop.BELL_HOLD_DURATION
 select_next_seed(shop,1)
 shop._complete_bell_hold()
 await process_frame
 check(not shop.customer_bag_open,"departing customer closes inventory before replacement arrives")
 await create_timer(0.6).timeout
 check(shop.customer_bag_open and shop.ZONES.has("customer"),"selling customer automatically opens inventory")
 shop._customer_bag_input(escape)
 shop._unhandled_input(escape)
 check(shop.customer_bag_open,"Escape leaves the selling customer inventory open")
 check(shop.CustomerRoster.eligible(shop.state,shop.CUSTOMERS[shop.customer_index]) and not shop.bell_hold_active,"bell long press replaces the current customer")
 shop.get_node("ArtLayers").set_customer(null)
 select_next_seed(shop,0)
 shop._bell_gui_input(bell_press)
 await create_timer(0.6).timeout
 check(shop.CustomerRoster.eligible(shop.state,shop.CUSTOMERS[shop.customer_index]) and shop.get_node("ArtLayers/Window/Customer").visible,"bell click calls a customer when none is present")
 check(not shop.customer_bag_open and not shop.ZONES.has("customer"),"replacement buyer hides the previous seller inventory")
 check(shop.door_art.texture_click_mask != null and shop.bed_art.texture_click_mask != null,"door and bed use alpha hit masks")
 check(shop.get_node("ArtLayers").z_index < shop.door_art.z_index,"scene props are above the background")
 check(shop.table_art.z_index > shop.bed_art.z_index and shop.bed_art.z_index > shop.door_art.z_index,"table is the top overlay prop")
 var door_material := shop.door_art.material as ShaderMaterial
 var bed_material := shop.bed_art.material as ShaderMaterial
 shop.door_art.emit_signal("mouse_entered")
 check(door_material.get_shader_parameter("hovered") == true,"door hover enables outline")
 shop.door_art.emit_signal("mouse_exited")
 check(door_material.get_shader_parameter("hovered") == false,"door hover outline clears")
 shop.bed_art.emit_signal("mouse_entered")
 check(bed_material.get_shader_parameter("hovered") == true,"bed hover enables outline")
 shop.bed_art.emit_signal("mouse_exited")
 check(bed_material.get_shader_parameter("hovered") == false,"bed hover outline clears")
 shop.door_art.emit_signal("pressed")
 check(shop.modal == null and shop.toast.contains("关闭卷帘门"),"door click is blocked while the shutter is open")
 shop.bed_art.emit_signal("pressed")
 check(shop.modal == null and shop.toast.contains("关闭卷帘门") and shop.toast.contains("卧铺"),"bed click is blocked while the shutter is open")
 shop.door_closer_art.emit_signal("pressed")
 check(shop.modal != null,"door closer opens a confirmation popup before ending business")
 var confirm_close: Button
 for modal_child in shop.modal.find_children("*","Button",true,false):
  if modal_child is Button and modal_child.text == "关闭并结束营业":
   confirm_close = modal_child
 check(confirm_close != null,"close confirmation popup has an explicit confirm action")
 confirm_close.emit_signal("pressed")
 await create_timer(0.9).timeout
 check(shop.shutter_closed and shop.shutter_clip.visible and shop.shutter_clip.size.y == 362.0,"roller shutter closes from top to bottom")
 check(not shop.get_node("ArtLayers/Window/Customer").visible and not shop.customer_bag_open,"closing the shop removes the customer immediately")
 check(not shop.trade_panel.visible and not shop.dialogue_active,"closed shop has no active customer trade")
 var closed_shop_item: Dictionary = shop.state.items.filter(func(i): return i.owner == "player" and i.zone == "stock" and not State.MACHINES.has(i.key))[0]
 shop._quick_move(closed_shop_item.id)
 check(closed_shop_item.zone != "counter" and not shop.trade_panel.visible,"closed shop rejects new counter trades")
 check(not shop.dialogue_active,"closed shop does not trigger customer reaction")
 shop.door_art.emit_signal("pressed")
 check(shop.modal != null,"door click opens exploration modal after closing")
 shop._close_modal()
 shop.bed_art.emit_signal("pressed")
 check(shop.modal != null,"bed click opens rest modal after closing")
 shop._begin_day()
 check(shop.state.day == 2 and shop.next_day_ready and shop.shutter_closed and not shop.business_active,"sleeping prepares the next day behind the closed shutter")
 shop._open_shutter_for_business()
 await create_timer(0.9).timeout
 check(not shop.shutter_closed and shop.business_active and shop.get_node("ArtLayers/Window/Customer").visible and shop.CustomerRoster.eligible(shop.state,shop.CUSTOMERS[shop.customer_index]),"opening the next day starts business with the first customer")
 shop._next_trade()
 shop._close_shutter()
 await create_timer(0.6).timeout
 check(not shop.get_node("ArtLayers/Window/Customer").visible and not shop.dialogue_active,"closing cancels a pending customer arrival")
 await create_timer(0.4).timeout
 check(shop.shutter_closed and not shop.business_active,"pending customer cannot reopen a closed shop")
 shop._begin_day()
 shop._open_shutter_for_business()
 await create_timer(0.9).timeout
 var machine: Dictionary = shop.state.items.filter(func(i): return i.key == "pot")[0]
 shop._quick_move(machine.id)
 check(shop.open_machine == machine.id,"double-click path opens processing window")
 check(shop.machine_popups[machine.id].size == Vector2(232,226),"processing window matches the backpack chrome footprint")
 var moved_popup: Rect2 = shop.machine_popups[machine.id]
 moved_popup.position += Vector2(40,-24)
 shop.machine_popups[machine.id] = moved_popup
 shop._sync_machine_window(machine.id)
 check(shop.ZONES[shop.state.machine_zone(machine.id)].rect.position == moved_popup.position + Vector2(20,64),"processing grid follows dragged window")
 var machine_close: Button = shop.machine_closes[machine.id]
 check(machine_close.get_parent() == shop.machine_window_nodes[machine.id],"processing close button is inside the popup layer")
 check(machine_close.position == Vector2(moved_popup.size.x-48,8),"processing close button follows dragged window")
 var other_machines: Array[Dictionary] = shop.state.items.filter(func(i): return State.MACHINES.has(i.key) and i.id != machine.id)
 for other in other_machines:
  shop._quick_move(other.id)
 check(shop.machine_popups.size() == 3,"furnace, alembic and pot can stay open independently")
 for other in shop.state.items.filter(func(i): return State.MACHINES.has(i.key)):
  check(shop.ZONES.has(shop.state.machine_zone(other.id)),"each open processing window keeps its own drop zone")
 shop._open_bag()
 check(shop.open_bag and shop.machine_popups.size() == 3,"backpack does not close processing windows")
 check(shop.bag_close.get_parent() == shop.bag_window_node,"backpack close button is inside the popup layer")
 shop._close_bag()
 shop._close_machine(machine.id)
 check(shop.machine_popups.size() == 2,"closing one processing window leaves the others open")
 check(shop.machine_popups.has(other_machines[0].id) and shop.machine_popups.has(other_machines[1].id),"remaining processing windows stay open")
 var remaining_close: Button = shop.machine_closes[other_machines[0].id]
 remaining_close.emit_signal("pressed")
 check(shop.machine_popups.size() == 1,"nested close button closes only its own processing window")
 shop._close_machine()
 check(not shop.ZONES.has(shop.state.machine_zone(machine.id)),"closing processing window removes its drop zone")
 check(shop.machine_popups.is_empty(),"closing all processing windows clears the independent popup set")
 print("PASS: %d trade overlay interaction checks" % checks)
 quit()
