extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var shop = scene
	if not shop.has_method("_start_exploration"):
		shop = scene.find_child("Shop",true,false)
	if "--large-bag" in OS.get_cmdline_user_args():
		shop.state.bag_size = Vector2i(12,8)
	for key in ["sword","bread","potion"]:
		var item: Dictionary = shop.state.items.filter(func(i): return i.key == key and i.owner == "player")[0]
		shop.state.move_item(item.id,"bag",shop.state.free_cell(item,"bag"),false)
	shop._start_exploration()
	var preview_ready := "--ready" in OS.get_cmdline_user_args()
	var preview_defeat := "--defeat" in OS.get_cmdline_user_args()
	if "--battle" in OS.get_cmdline_user_args() or "--victory" in OS.get_cmdline_user_args() or preview_ready or preview_defeat:
		for argument in OS.get_cmdline_user_args():
			if argument.begins_with("--enemy="):
				shop.exploration.combat.encounter = maxi(0,int(argument.trim_prefix("--enemy="))-1)
		shop.exploration.combat.next_encounter()
		if not preview_ready:
			shop.exploration._fight()
		if "--victory" in OS.get_cmdline_user_args():
			shop.exploration.combat.attack(999)
		elif preview_defeat:
			shop.exploration.combat.hp = 1
			shop.exploration.combat.end_turn()
	await process_frame
	await process_frame
	if "--tooltip" in OS.get_cmdline_user_args():
		var preview_item: Dictionary = shop.exploration.state.items.filter(func(entry): return entry.zone == "bag")[0]
		shop.exploration.set_process(false)
		shop.exploration.pointer = shop.exploration.item_rect(preview_item).get_center()
		shop.exploration._sync_item_hover()
		await create_timer(0.2).timeout
	if "--action" in OS.get_cmdline_user_args():
		await create_timer(2.12).timeout
	if not DisplayServer.get_name() == "headless":
		var suffix := "tooltip" if "--tooltip" in OS.get_cmdline_user_args() else "victory" if "--victory" in OS.get_cmdline_user_args() else "defeat" if preview_defeat else "ready" if preview_ready else "battle" if "--battle" in OS.get_cmdline_user_args() else "idle"
		if "--large-bag" in OS.get_cmdline_user_args():
			suffix += "-large"
		root.get_texture().get_image().save_png("res://docs/testing/previews/exploration-%s.png" % suffix)
	quit()
