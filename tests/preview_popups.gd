extends SceneTree
const State = preload("res://scripts/trade_state.gd")

func _initialize() -> void:
 run.call_deferred()

func run() -> void:
 var shop = load("res://main.tscn").instantiate()
 root.add_child(shop)
 await process_frame
 shop.customer_index = 1
 shop.get_node("ArtLayers").set_customer(load(shop.CUSTOMERS[1].portrait))
 shop._apply_customer_profile()
 shop._clear_dialogue()
 var offered = shop.state.items.filter(func(i): return i.owner == "customer")[0]
 shop._quick_move(offered.id)
 shop._clear_dialogue()
 shop._open_bag()
 await create_timer(0.5).timeout
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://docs/testing/previews/弹窗优化.png")
 shop._close_bag()
 shop._open_bag()
 for machine in shop.state.items.filter(func(i): return State.MACHINES.has(i.key)):
  shop._quick_move(machine.id)
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://docs/testing/previews/设备加工.png")
 print("POPUP_PREVIEW_SAVED")
 quit()
