extends SceneTree
const State = preload("res://scripts/trade_state.gd")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var shop = load("res://main.tscn").instantiate()
	root.add_child(shop)
	await process_frame
	shop._clear_dialogue()
	shop._show_hover_tip("art:ComputerArt","交易终端",Vector2(1360,350),true,"",4096,1.0)
	await create_timer(0.16).timeout
	await process_frame
	root.get_texture().get_image().save_png("res://docs/testing/previews/悬停提示-交互物.png")
	var item: Dictionary = shop.state.items.filter(func(entry): return entry.key == "herb")[0]
	shop.set_process(false)
	shop._show_hover_tip("item:%d" % item.id,str(State.CATALOG[item.key].name),Vector2(700,500),false,shop._item_hover_details(item))
	await create_timer(0.16).timeout
	await process_frame
	root.get_texture().get_image().save_png("res://docs/testing/previews/悬停提示-道具.png")
	root.get_texture().get_image().save_png("res://docs/testing/previews/悬停提示.png")
	print("HOVER_TIP_PREVIEW_SAVED")
	quit()
