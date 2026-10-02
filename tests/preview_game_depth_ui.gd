extends SceneTree

func capture(path: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(path)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var shop = load("res://main.tscn").instantiate()
	root.add_child(shop)
	await process_frame
	shop._open_market_board()
	await capture("res://docs/testing/previews/深度版-商品行情.png")
	shop._close_market_board()
	await process_frame
	shop._open_module_shop()
	await capture("res://docs/testing/previews/深度版-商车改装.png")
	shop._buy_module("roof_rack")
	shop.state.gold += 500
	shop._buy_module("hidden_compartment")
	shop._close_module_shop()
	var sword: Dictionary = shop.state.items.filter(func(i): return i.key == "sword" and i.owner == "player" and i.zone == "stock")[0]
	var ore: Dictionary = shop.state.items.filter(func(i): return i.key == "ore" and i.owner == "player" and i.zone == "stock")[0]
	shop.state.move_item(sword.id,"bag",Vector2i(0,0),false)
	shop.state.move_item(ore.id,"bag",Vector2i(2,0),false)
	shop._open_bag()
	await capture("res://docs/testing/previews/深度版-背包Build.png")
	quit(0)
