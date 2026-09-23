extends SceneTree

var checks := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		push_error(message)
		quit(1)
		assert(ok, message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var page = load("res://scripts/exploration.gd").new()
	page.state = load("res://scripts/trade_state.gd").new()
	root.add_child(page)
	await process_frame
	page.set_process(false)
	var stage: SubViewport = page.stage
	var space: Node3D = stage.world
	var layers: Node3D = space.get_node("Layers")
	check(stage.own_world_3d, "battle stage owns a real 3D viewport world")
	check(stage.camera.projection == Camera3D.PROJECTION_PERSPECTIVE, "battle stage camera is perspective")
	check(layers.get_child_count() == 9, "battle stage mounts eight scene layers and one transition ghost")
	check(space.layer_order()[0] == "Forest_01" and space.layer_order()[7] == "Forest_08", "battle stage starts at the first scene slice")
	check(space.get_script().resource_path == "res://scripts/battle_space_loop.gd", "battle stage uses the 3D ring-loop scene script")
	check(is_equal_approx(page.journey_depth_step, space.get_journey_depth_step()), "game travel step comes from the 3D stage")
	var camera_z: float = stage.camera.position.z
	page._primary()
	check(page.traveling and page.combat.encounter == 0, "encounter waits for travel")
	page._process(0.4)
	check(stage.camera.position.z == camera_z and space.transition_active, "game travel keeps the camera fixed and starts a visual transition")
	check(page.combat.hp == 60 and page.combat.elapsed == 0 and page.combat.encounter == 0, "travel cannot attack or double-start")
	page._process(1.0)
	check(page.traveling and page.travel_finish_pending and page.combat.encounter == 0, "arrival waits for the background transition before starting an encounter")
	check(is_equal_approx(page.journey_depth, 0.075), "travel retains completed forward displacement")
	for _step in range(4):
		space._process(0.033)
	page._process(0.0)
	check(not page.traveling and page.combat.encounter == 1 and page.combat.phase == "ready", "arrival starts exactly one encounter in preparation after the background transition")
	check(stage.camera.position.z == camera_z, "camera remains fixed after the transition")
	check(space.layer_order()[0] == "Forest_02" and space.layer_order()[7] == "Forest_01", "first crossed scene slice is committed after the ghost transition")
	page._process(0.2)
	check(page.combat.elapsed == 0, "enemy settling pauses combat clock")
	page._fight()
	page._process(0.1)
	check(page.combat.elapsed > 0, "combat resumes after settling")
	page.combat.attack(999)
	page._primary()
	check(not page.traveling and page.confirm_action == "next" and page.has_loot(), "uncollected loot still requires confirmation")
	page._primary()
	check(page.traveling and not page.has_loot(), "confirmed travel removes dropped loot")
	page._process(0.95)
	check(page.traveling and page.travel_finish_pending and page.combat.encounter == 1, "second arrival also waits for the background transition")
	for _step in range(4):
		space._process(0.033)
	page._process(0.0)
	check(page.combat.encounter == 2 and is_equal_approx(page.journey_depth, 0.15), "continuing advances encounter and visual travel once")
	check(space.layer_order()[0] == "Forest_03", "second crossed scene slice is committed in-game")
	for n in range(3):
		page._fight()
		page.combat.attack(999)
		page.combat.clear_loot()
		page._primary()
		page._process(0.95)
		for _step in range(4):
			space._process(0.033)
		page._process(0.0)
	check(page.combat.encounter == 5, "fifth encounter remains reachable")
	page._fight()
	page.combat.attack(999)
	page._begin_travel()
	check(page.traveling and page.combat.encounter == 5, "an additional journey can start after the fifth encounter")
	page.free()
	print("PASS: %d travel checks" % checks)
	quit()
