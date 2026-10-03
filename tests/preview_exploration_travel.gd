extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var page = load("res://scripts/exploration.gd").new()
	page.state = load("res://scripts/trade_state.gd").new()
	root.add_child(page)
	page.set_process(false)
	page.combat.next_encounter()
	page._fight()
	page.combat.attack(999)
	page.combat.clear_loot()
	var directory := ProjectSettings.globalize_path("res://docs/testing/previews/forest-travel-frames")
	DirAccess.make_dir_recursive_absolute(directory)
	for n in range(60):
		if n == 12:
			page.combat.event_streak = 2
			page._primary()
		page._process(1.0/24.0)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(directory + "/%03d.png" % n)
	page.free()
	quit()
