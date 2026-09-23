extends SceneTree

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var shop = load("res://main.tscn").instantiate()
 root.add_child(shop)
 await process_frame
 shop._clear_dialogue()
 await create_timer(0.45).timeout
 await process_frame
 root.get_texture().get_image().save_png("res://docs/testing/previews/交易场景-金属素材.png")
 shop.door_art.emit_signal("mouse_entered")
 shop.bed_art.emit_signal("mouse_entered")
 await process_frame
 root.get_texture().get_image().save_png("res://docs/testing/previews/交易场景-金属素材-hover.png")
 shop._start_customer_conversation()
 shop._advance_dialogue(10.0)
 await process_frame
 root.get_texture().get_image().save_png("res://docs/testing/previews/对话框预览.png")
 for n in range(8):
  shop._advance_dialogue(10.0)
 shop.phone_art.emit_signal("pressed")
 await process_frame
 root.get_texture().get_image().save_png("res://docs/testing/previews/手机历史记录.png")
 shop._close_recorder()
 shop._close_shutter()
 await create_timer(0.9).timeout
 await process_frame
 root.get_texture().get_image().save_png("res://docs/testing/previews/交易场景-金属素材-shutter-closed.png")
 print("TRADE_OVERLAY_PREVIEW_SAVED")
 quit()
