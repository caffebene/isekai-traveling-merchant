extends SceneTree
const OUTPUT := "res://docs/testing/previews/unified-ui/"
func _initialize() -> void:
 run.call_deferred()
func run() -> void:
 var shop = load("res://main.tscn").instantiate()
 root.add_child(shop)
 await process_frame
 shop.set_process(false)
 shop._clear_dialogue()
 shop._hide_hover_tip()
 shop.hover_tip.hide()
 shop.state.add_item("iron_pickaxe","bag","player")
 var pick: Dictionary = shop.state.items.filter(func(i): return i.key == "iron_pickaxe")[0]
 var potion: Dictionary = shop.state.items.filter(func(i): return i.key == "potion" and i.zone == "stock")[0]
 shop.state.move_item(potion.id,"bag",Vector2i(0,1),false)
 shop._open_bag()
 shop._sync()
 await process_frame
 # Highlight the same T-shaped footprint used by real drag placement.
 shop.drag_id = pick.id
 shop.drag_rotated = false
 shop.drag_offset = Vector2.ZERO
 shop.mouse = shop.ZONES.bag.rect.position
 shop.queue_redraw()
 await process_frame
 await RenderingServer.frame_post_draw
 var picture := root.get_texture().get_image()
 var resolution := "%dx%d" % [picture.get_width(),picture.get_height()]
 picture.save_png(OUTPUT+"29-weapon-footprint-"+resolution+".png")
 var bounds: Rect2 = shop.bag_window_node.get_global_transform_with_canvas()*Rect2(Vector2.ZERO,shop.bag_window_node.size+Vector2(360,0))
 var scale := Vector2(picture.get_width()/1600.0,picture.get_height()/900.0)
 bounds.position *= scale
 bounds.size *= scale
 picture.get_region(Rect2i(bounds)).save_png(OUTPUT+"29-weapon-footprint-detail-"+resolution+".png")
 print("WEAPON_FOOTPRINT_PREVIEW_SAVED ",resolution)
 quit()
