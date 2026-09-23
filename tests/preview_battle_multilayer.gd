extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene = load("res://scenes/battle_multilayer.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	if not DisplayServer.get_name() == "headless":
		root.get_texture().get_image().save_png("res://docs/testing/previews/battle-multilayer-scene.png")
	quit()
