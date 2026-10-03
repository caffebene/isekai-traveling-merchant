extends SceneTree
const OUTPUT = "res://docs/testing/previews/unified-ui/"
var shop
func _initialize() -> void:
 run.call_deferred()
func capture(label: String) -> void:
 await create_timer(0.2).timeout
 await process_frame
 await RenderingServer.frame_post_draw
 var picture := root.get_texture().get_image()
 var resolution := "%dx%d" % [picture.get_width(),picture.get_height()]
 picture.save_png(OUTPUT+"43-quality-"+label+"-"+resolution+".png")
 print("QUALITY_PREVIEW ",label," ",resolution)
func run() -> void:
 shop = load("res://main.tscn").instantiate()
 root.add_child(shop)
 await process_frame
 shop.set_process(false)
 shop._clear_dialogue()
 shop._hide_hover_tip()
 shop.state.items.clear()
 shop.state.bag_size = Vector2i(12,8)
 shop.state.quality_rng.seed = 17
 shop.state.configure_customer("武器","",[])
 for n in range(5):
  assert(shop.state.add_item("iron_sword","bag","player","",n))
 shop._open_bag()
 shop._sync()
 await capture("bag")
 var gold: Dictionary = shop.state.items.back()
 gold.purity = 100
 gold.affixes = [{"key":"sharp","value":20},{"key":"swift","value":12},{"key":"critical","value":12},{"key":"leech","value":15}]
 shop._sync()
 shop._clear_dialogue()
 shop.hover_tip.show_item("quality:gold",shop.state.item_card_data(gold),shop.ITEM_TEXTURES[gold.key],Vector2(720,280))
 await capture("card")
 shop.hover_tip.hide_tip()
 for item in shop.state.items:
  shop._place_on_counter(item.id,Vector2(260+item.quality*156,690),item.quality % 2 == 1)
 shop._sync()
 shop._clear_dialogue()
 shop.trade_panel.keep_open = true
 shop.trade_panel.refresh(shop.state)
 shop.trade_panel.show()
 await capture("trade")
 shop._close_trade_panel()
 shop.state.add_item("ancient_wood","stock","player")
 var fuel: Dictionary = shop.state.items.back()
 shop.hover_tip.show_item("quality:fuel",shop.state.item_card_data(fuel),shop.ITEM_TEXTURES[fuel.key],Vector2(720,260))
 await capture("fuel")
 shop.hover_tip.hide_tip()
 var book = preload("res://scripts/workbench_view.gd").new()
 shop.add_child(book)
 book.position = Vector2(400,110)
 book.z_index = 60
 await capture("recipe")
 book.queue_free()
 # Real exploration renders the same five qualities, including a rotated icon.
 for item in shop.state.items.duplicate():
  if shop.state.CATALOG[item.key].category == "武器":
   shop.state.move_item(item.id,"bag",shop.state.free_cell(item,"bag"),false)
 shop.state.move_item(gold.id,"bag",Vector2i(0,6),true)
 shop.drag_id = gold.id
 shop.drag_rotated = true
 shop.drag_offset = Vector2.ZERO
 shop.mouse = Vector2(760,600)
 shop.queue_redraw()
 await capture("drag")
 shop.drag_id = -1
 shop._start_exploration()
 await process_frame
 shop.exploration.set_process(false)
 await capture("exploration")
 shop.state.add_item("iron_axe","loot","player","",4)
 shop.exploration.combat.phase = "victory"
 shop.exploration.queue_redraw()
 await capture("loot")
 quit()
