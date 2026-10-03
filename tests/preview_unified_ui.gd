extends SceneTree
## Actual game captures; no mockup renderer or alternative UI implementation.
const OUTPUT := "res://docs/testing/previews/unified-ui/"
var shop
var resolution := ""

func _initialize() -> void:
 run.call_deferred()

func capture(label: String) -> void:
 var was_processing: bool = shop.is_processing()
 shop.set_process(false)
 shop.queue_redraw()
 shop.bag_window_node.queue_redraw()
 shop.drag_canvas.queue_redraw()
 if label not in ["18-purchased-item","19-food-tooltip","23-raw-meat-tooltip","24-material-tooltip","30-fuel-tooltip","33-bag-weapon-details","35-support-hover","39-fuel-interval-hover"]:
  shop._hide_hover_tip()
  shop.hover_tip.hide()
 if is_instance_valid(shop.exploration):
  shop.exploration.queue_redraw()
 await process_frame
 await RenderingServer.frame_post_draw
 var image := root.get_texture().get_image()
 resolution = "%dx%d" % [image.get_width(),image.get_height()]
 image.save_png(OUTPUT+label+"-"+resolution+".png")
 if label in ["09-market","26-news-active","27-news-miners","28-news-quiet"]:
  var paper: Control = shop.market_board.window
  var paper_bounds: Rect2 = paper.get_global_transform_with_canvas()*Rect2(Vector2.ZERO,paper.size)
  var paper_scale := Vector2(image.get_width()/1600.0,image.get_height()/900.0)
  paper_bounds.position *= paper_scale
  paper_bounds.size *= paper_scale
  image.get_region(Rect2i(paper_bounds)).save_png(OUTPUT+label+"-detail-"+resolution+".png")
 if label in ["25-sale-invoice","03-mixed-trade"]:
  var invoice: Control = shop.trade_panel
  var invoice_bounds: Rect2 = invoice.get_global_transform_with_canvas()*Rect2(Vector2.ZERO,invoice.size)
  var invoice_scale := Vector2(image.get_width()/1600.0,image.get_height()/900.0)
  invoice_bounds.position *= invoice_scale
  invoice_bounds.size *= invoice_scale
  image.get_region(Rect2i(invoice_bounds)).save_png(OUTPUT+label+"-detail-"+resolution+".png")
 if label in ["07-recipe","21-alchemy-notebook","31-specific-fuel-recipe"]:
  var book: Control = shop.recipe_book
  var book_bounds: Rect2 = book.get_global_transform_with_canvas()*Rect2(Vector2.ZERO,book.size)
  var book_scale := Vector2(image.get_width()/1600.0,image.get_height()/900.0)
  book_bounds.position *= book_scale
  book_bounds.size *= book_scale
  image.get_region(Rect2i(book_bounds)).save_png(OUTPUT+("recipe-book" if label == "07-recipe" else label)+"-detail-"+resolution+".png")
 if label in ["18-purchased-item","23-raw-meat-tooltip","24-material-tooltip","30-fuel-tooltip","33-bag-weapon-details","35-support-hover","39-fuel-interval-hover"]:
  var detail_card: Control = shop.hover_tip.panel
  var detail_bounds: Rect2 = detail_card.get_global_transform_with_canvas()*Rect2(Vector2.ZERO,detail_card.size)
  var detail_scale := Vector2(image.get_width()/1600.0,image.get_height()/900.0)
  detail_bounds.position *= detail_scale
  detail_bounds.size *= detail_scale
  image.get_region(Rect2i(detail_bounds)).save_png(OUTPUT+label+"-detail-"+resolution+".png")
 if label == "19-food-tooltip":
  var card: Control = shop.hover_tip.panel
  var bounds: Rect2 = card.get_global_transform_with_canvas()*Rect2(Vector2.ZERO,card.size)
  var screen_scale := Vector2(image.get_width()/1600.0,image.get_height()/900.0)
  bounds.position *= screen_scale
  bounds.size *= screen_scale
  image.get_region(Rect2i(bounds)).save_png(OUTPUT+"food-card-detail-"+resolution+".png")
 shop.set_process(was_processing)

func ignore_pointer(node: Node) -> void:
 if node is Control:
  node.mouse_filter = Control.MOUSE_FILTER_IGNORE
 for child in node.get_children():
  ignore_pointer(child)

func customer(index: int) -> void:
 shop._close_bag()
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
 ignore_pointer(shop)
 await create_timer(0.4).timeout
 for _step in range(10):
  shop._advance_dialogue(10.0)
 await capture("01-trade")
 await customer(0)
 var herbs: Array = shop.state.items.filter(func(i): return i.key == "herb" and i.owner == "player")
 for item in herbs.slice(0,2):
  shop._quick_move(item.id)
 shop._clear_dialogue()
 await capture("25-sale-invoice")
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
 shop._close_trade_panel()
 shop._hide_hover_tip()
 shop.toast_time = 0
 for item in shop.state.items.filter(func(i): return shop.State.MACHINES.has(i.key)):
  shop._open_machine(item.id)
 await capture("06-processing")
 var bench: Dictionary = shop.state.items.filter(func(i): return i.key == "furnace")[0]
 var original: Rect2 = shop.machine_popups[bench.id]
 shop.machine_popups[bench.id].position = Vector2(630,180)
 shop._sync_machine_window(bench.id)
 shop._start_conversation(["如果价格合适，就在柜台成交吧。"])
 shop._advance_dialogue(10.0)
 shop.queue_redraw()
 await capture("20-window-overlap")
 shop._clear_dialogue()
 shop.machine_popups[bench.id] = original
 shop._sync_machine_window(bench.id)
 shop.queue_redraw()
 shop._open_recipe_drawings()
 await capture("07-recipe")
 shop.recipe_book.page = 6
 shop.recipe_book.queue_redraw()
 await capture("31-specific-fuel-recipe")
 shop._open_recipe_drawings("alembic")
 shop.recipe_book.page = 1
 shop.recipe_book.queue_redraw()
 await capture("21-alchemy-notebook")
 shop.recipe_book.position = Vector2(700,120)
 await capture("22-notebook-moved")
 shop._close_recipe_book()
 shop._close_machine()
 shop._start_conversation(["这批材料来自森林边缘。","价格合适的话，我们就在柜台成交。"])
 for _step in range(10):
  shop._advance_dialogue(10.0)
 shop._open_recorder()
 await capture("08-history")
 shop._close_recorder()
 shop._open_market_board()
 await capture("09-market")
 var saved_day: int = shop.state.day
 var saved_city: String = shop.state.economy.city_id
 var saved_pressure: Dictionary = shop.state.economy.sold_pressure.duplicate(true)
 shop.state.day = 4
 shop.market_board.refresh()
 await capture("26-news-active")
 shop.state.economy.city_id = "ironvale"
 shop.state.day = 9
 shop.state.economy.record_sale("矿石",2)
 shop.market_board.refresh()
 await capture("27-news-miners")
 shop.state.day = 14
 shop.market_board.refresh()
 await capture("28-news-quiet")
 shop.state.day = saved_day
 shop.state.economy.city_id = saved_city
 shop.state.economy.sold_pressure = saved_pressure
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
 var paid: Dictionary = shop.state.items.filter(func(i): return i.owner == "customer" and i.key == "ore")[0]
 shop._quick_move(paid.id)
 shop._settle()
 shop._close_trade_panel()
 shop._clear_dialogue()
 await create_timer(1.4).timeout
 shop.set_process(false)
 shop._show_hover_tip("item:%d" % paid.id,str(shop.State.CATALOG[paid.key].name),Vector2(1020,130),false,shop._item_hover_details(paid))
 await create_timer(0.2).timeout
 await capture("18-purchased-item")
 shop._hide_hover_tip()
 var food: Dictionary = shop.state.items.filter(func(i): return i.key == "steak" and i.owner == "player")[0]
 shop._show_hover_tip("item:%d" % food.id,str(shop.State.CATALOG[food.key].name),Vector2(1020,130),false,shop._item_hover_details(food))
 await create_timer(0.2).timeout
 await capture("19-food-tooltip")
 shop._hide_hover_tip()
 for sample in [{"key":"meat","shot":"23-raw-meat-tooltip"},{"key":"herb","shot":"24-material-tooltip"},{"key":"slime_mucus","shot":"30-fuel-tooltip"}]:
  var sample_item: Dictionary = shop.state.items.filter(func(i): return i.key == sample.key and i.owner == "player")[0]
  shop._show_hover_tip("item:%d" % sample_item.id,str(shop.State.CATALOG[sample_item.key].name),Vector2(1020,130),false,shop._item_hover_details(sample_item))
  await create_timer(0.2).timeout
  await capture(sample.shot)
  shop._hide_hover_tip()
 shop.set_process(true)
 for key in ["sword","bread","potion"]:
  var candidates: Array = shop.state.items.filter(func(i): return i.key == key and i.owner == "player" and i.zone == "stock")
  if not candidates.is_empty():
   var item: Dictionary = candidates[0]
   shop.state.move_item(item.id,"bag",shop.state.free_cell(item,"bag"),false)
 # Show effective weapon values without overlays or a separate build summary.
 for stored in shop.state.items.filter(func(i): return i.zone == "bag"):
  shop.state.move_item(stored.id,"stock",shop.state.free_cell(stored,"stock"),stored.rotated)
 var bag_weapon: Dictionary = shop.state.items.filter(func(i): return i.key == "sword" and i.owner == "player")[0]
 var bag_ore: Dictionary = shop.state.items.filter(func(i): return i.key == "ore" and i.owner == "player")[0]
 shop.state.move_item(bag_weapon.id,"bag",Vector2i(0,0),false)
 shop.state.move_item(bag_ore.id,"bag",Vector2i(2,0),false)
 shop._open_bag()
 await capture("32-clean-backpack")
 shop.set_process(false)
 shop._show_hover_tip("item:%d" % bag_weapon.id,str(shop.State.CATALOG[bag_weapon.key].name),Vector2(1020,130),false,shop._item_hover_details(bag_weapon))
 await create_timer(0.2).timeout
 await capture("33-bag-weapon-details")
 shop.hover_id = bag_ore.id
 shop.mouse = shop._item_rect(bag_ore).get_center()
 shop._show_hover_tip("item:%d" % bag_ore.id,str(shop.State.CATALOG[bag_ore.key].name),Vector2(1020,130),false,shop._item_hover_details(bag_ore))
 await capture("35-support-hover")
 shop._hide_hover_tip()
 shop.hover_id = -1
 shop.drag_id = bag_ore.id
 shop.drag_rotated = false
 shop.drag_offset = Vector2.ZERO
 shop.mouse = shop.ZONES.bag.rect.position+Vector2(3,3)*shop.BAG_CELL
 await capture("36-support-drag")
 shop.drag_id = -1
 var interval_fuel: Dictionary = shop.state.items.filter(func(i): return i.key == "slime_mucus" and i.owner == "player")[0]
 shop.state.move_item(interval_fuel.id,"bag",Vector2i(2,2),false)
 shop.hover_id = interval_fuel.id
 shop.mouse = shop._item_rect(interval_fuel).get_center()
 shop._show_hover_tip("item:%d" % interval_fuel.id,str(shop.State.CATALOG[interval_fuel.key].name),Vector2(1020,130),false,shop._item_hover_details(interval_fuel))
 await capture("39-fuel-interval-hover")
 shop.hover_id = -1
 shop._hide_hover_tip()
 shop.set_process(true)
 shop._close_bag()
 if "--shop-only" in OS.get_cmdline_user_args():
  print("SHOP_UI_PREVIEW_SAVED ",resolution)
  quit()
  return
 shop._start_exploration()
 var page = shop.exploration
 page.set_process(false)
 page.combat.next_encounter()
 page.refresh()
 await capture("11-exploration-ready")
 page.pointer = page.item_rect(bag_weapon).get_center()
 page._sync_item_hover()
 await create_timer(0.2).timeout
 await capture("34-battle-weapon-details")
 page.pointer = page.item_rect(bag_ore).get_center()
 await capture("37-battle-support-hover")
 page.drag = bag_ore.id
 page.rotated = false
 page.offset = Vector2.ZERO
 page.pointer = page.zone_rect("bag").position+Vector2(3,3)*page.CELL_SIZE
 await capture("38-battle-support-drag")
 page.drag = -1
 page.pointer = Vector2(-20,-20)
 page._hide_item_hover()
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
