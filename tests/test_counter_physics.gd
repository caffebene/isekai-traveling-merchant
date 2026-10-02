extends SceneTree
var failures := 0
var checks := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	run.call_deferred()

func advance(page, frames: int) -> void:
	for n in range(frames):
		await physics_frame
		page._step_counter_physics(1.0/60.0)

func lowest_collision_y(body: RigidBody2D) -> float:
	var result := -INF
	for child in body.get_children():
		if child is CollisionPolygon2D:
			for point in child.polygon:
				result = maxf(result,child.to_global(point).y)
	return result

func run() -> void:
	var page = load("res://main.tscn").instantiate()
	root.add_child(page)
	await process_frame
	page._clear_dialogue()
	page.state.configure_customer("材料","",[])
	var first: Dictionary = page.state.items.filter(func(i): return i.key == "potion")[0]
	var second: Dictionary = page.state.items.filter(func(i): return i.key == "bread")[0]
	page._place_on_counter(first.id,Vector2(720,250),false)
	await advance(page,240)
	var body: RigidBody2D = page.counter_world.bodies[first.id]
	check(absf(lowest_collision_y(body)-page.COUNTER_BASELINE_Y) < 4.0,"potion alpha contour lands on current countertop baseline")
	check(body.physics_material_override.bounce == 0.0,"zero restitution")
	check(not body.lock_rotation,"rotation is physically free")
	check(body.get_child(0) is CollisionPolygon2D,"uses source alpha polygons")
	page._place_on_counter(second.id,Vector2(748,280),false)
	await advance(page,360)
	check(absf(second.counter_angle) > 0.15,"off-center bread rotates after contact")
	var bread_body: RigidBody2D = page.counter_world.bodies[second.id]
	check(second.counter_position.y > 350.0,"bread falls under gravity after contacting bottle")
	check(lowest_collision_y(bread_body) <= page.COUNTER_BASELINE_Y+4.0,"bread alpha contour does not tunnel through current countertop baseline")
	page.state.cancel_trade()
	await advance(page,2)
	var support_item: Dictionary = page.state.items.filter(func(i): return i.key == "bread")[0]
	var upper_item: Dictionary = page.state.items.filter(func(i): return i.key == "bread" and i.id != support_item.id)[0]
	page._place_on_counter(support_item.id,Vector2(720,360),false)
	page._step_counter_physics(1.0/60.0)
	var support: RigidBody2D = page.counter_world.bodies[support_item.id]
	support.freeze = true
	page._place_on_counter(upper_item.id,Vector2(720,330),false)
	await advance(page,240)
	var supported_y: float = upper_item.counter_position.y
	page.state.move_item(support_item.id,"stock",page.state.free_cell(support_item,"stock"),false)
	await advance(page,240)
	check(upper_item.counter_position.y > supported_y+25.0,"removing support drops upper body")
	page.state.cancel_trade()
	await advance(page,2)
	check(page.counter_world.bodies.is_empty(),"cancel removes physics bodies")
	print("%s: %d rigid-body checks (%d failures)" % ["PASS" if failures == 0 else "FAIL",checks,failures])
	quit(1 if failures else 0)
