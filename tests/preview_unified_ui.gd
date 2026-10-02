extends SceneTree
## Actual game captures; no mockup renderer or alternative UI implementation.
const OUTPUT := "res://docs/testing/previews/unified-ui/"
var shop
var resolution := ""

func _initialize() -> void:
 run.call_deferred()

func capture(label: String) -> void:
 if is_instance_valid(shop.exploration):
  shop.exploration.queue_redraw()
 await process_frame
 await RenderingServer.frame_post_draw
 var image := root.get_texture().get_image()
 resolution = "%dx%d" % [image.get_width(),image.get_height()]
 image.save_png(OUTPUT+label+"-"+resolution+".png")

func customer(index: int) -> void:
 shop._close_bag()
 shop._close_customer_bag()
 shop._close_machine()
 shop.state.cancel_trade()
 shop.customer_index = index
 shop.get_node("ArtLayers").set_customer(load(shop.CUSTOMERS[index].portrait))
 shop._apply_customer_profile()
 shop._clear_dialogue()
 await create_timer(0.35).timeout

func run() -> void:
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
 shop = load("res://main.tscn").instantiate()
 root.add_child(shop)
 await create_timer(0.4).timeout
 for _step in range(10):
  shop._advance_dialogue(10.0)
 await capture("01-trade")
 await customer(1)
 var goods: Array = shop.state.items.filter(func(i): return i.owner == "customer")
 shop._quick_move(goods[0].id)
 shop._clear_dialogue()
 shop._open_bag()
 await capture("02-inventories")
 var sword: Dictionary = shop.state.items.filter(func(i): return i.key == "sword" and i.owner == "player")[0]
 shop._quick_move(sword.id)
 shop._clear_dialogue()
 await create_timer(0.7).timeout
 await capture("03-mixed-trade")
 await customer(3)
 for item in shop.state.items.filter(func(i): return i.owner == "customer"):
  shop._quick_move(item.id)
 shop._clear_dialogue()
 await capture("04-long-list")
 shop.state.gold = 0
 shop._settle()
 await capture("05-insufficient-gold")
 shop.state.gold = 387
 shop._clear_dialogue()
 shop.state.cancel_trade()
 shop._close_customer_bag()
 shop._close_trade_panel()
 shop._hide_hover_tip()
 shop.toast_time = 0
 for item in shop.state.items.filter(func(i): return shop.State.MACHINES.has(i.key)):
  shop._open_machine(item.id)
 await capture("06-processing")
 shop._open_recipe_drawings()
 await capture("07-recipe")
 shop._close_modal()
 shop._close_machine()
 shop._start_conversation(["这批材料来自森林边缘。","价格合适的话，我们就在柜台成交。"])
 for _step in range(10):
  shop._advance_dialogue(10.0)
 shop._open_recorder()
 await capture("08-history")
 shop._close_recorder()
 shop._open_market_board()
 await capture("09-market")
 shop._close_market_board()
 shop._open_module_shop()
 await capture("10-modules")
 shop._close_module_shop()
 shop._show_help()
 await capture("16-help")
 shop._close_modal()
 await process_frame
 shop._request_close_shutter()
 await capture("17-close-confirmation")
 shop._close_modal()
 shop._clear_dialogue()
 for key in ["sword","bread","potion"]:
  var candidates: Array = shop.state.items.filter(func(i): return i.key == key and i.owner == "player" and i.zone == "stock")
  if not candidates.is_empty():
   var item: Dictionary = candidates[0]
   shop.state.move_item(item.id,"bag",shop.state.free_cell(item,"bag"),false)
 shop._start_exploration()
 var page = shop.exploration
 page.set_process(false)
 page.combat.next_encounter()
 page.refresh()
 await capture("11-exploration-ready")
 page._fight()
 page.refresh()
 await capture("12-exploration-battle")
 page.combat.attack(999)
 page.state.bag_size = Vector2i(12,8)
 page.refresh()
 await capture("13-loot-large")
 var item: Dictionary = page.state.items.filter(func(i): return i.zone == "bag")[0]
 page.pointer = page.item_rect(item).get_center()
 page._sync_item_hover()
 await create_timer(0.2).timeout
 await capture("14-tooltip")
 page._hide_item_hover()
 page.combat.next_encounter()
 page._fight()
 page.combat.hp = 1
 page.combat.end_turn()
 page.refresh()
 await capture("15-defeat")
 print("UNIFIED_UI_PREVIEW_SAVED ",resolution)
 quit()
