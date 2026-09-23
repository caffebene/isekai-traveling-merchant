extends SceneTree
func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var page = load("res://main.tscn").instantiate()
	root.add_child(page)
	await process_frame
	page._clear_dialogue()
	page.state.configure_customer("材料","",[])
	for key in ["bread","potion","power","berry","meat","steak","bread"]:
		var candidates: Array = page.state.items.filter(func(i): return i.key == key and i.zone == "stock")
		if candidates.is_empty():
			continue
		page._place_on_counter(candidates[0].id,Vector2(720,170),false)
		for n in range(90):
			await physics_frame
	for n in range(240):
		await physics_frame
	page._clear_dialogue()
	page.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/testing/previews/柜台物理.png")
	print("COUNTER_PHYSICS_PREVIEW_SAVED")
	quit()
