extends SceneTree

const Store = preload("res://scripts/trade_state.gd")
const Exploration = preload("res://scripts/exploration.gd")

var checks := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		push_error(message)
		quit(1)
		assert(ok,message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var store = Store.new()
	var page = Exploration.new()
	page.state = store
	root.add_child(page)
	await process_frame

	page.combat.phase = "victory"
	store.add_item("berry","loot","player")
	var first_loot: Dictionary = store.items.filter(func(i): return i.zone == "loot")[0]
	page.pointer = page.item_rect(first_loot).get_center()
	var double_click := InputEventMouseButton.new()
	double_click.button_index = MOUSE_BUTTON_LEFT
	double_click.pressed = true
	double_click.double_click = true
	page._gui_input(double_click)
	check(first_loot.zone == "bag","auto pickup moves loot into the bag")
	check(first_loot.cell == Vector2i.ZERO,"auto pickup uses the first available bag cell")

	store.items = store.items.filter(func(i): return i.zone not in ["bag","loot"])
	store.bag_size = Vector2i(3,2)
	store.add_item("herb","loot","player")
	var rotated_loot: Dictionary = store.items.filter(func(i): return i.zone == "loot")[0]
	page._auto_pickup_loot(rotated_loot.id)
	check(rotated_loot.zone == "bag","auto pickup retries with a rotated orientation")
	check(rotated_loot.rotated,"rotated orientation is persisted after auto pickup")

	store.items = store.items.filter(func(i): return i.zone not in ["bag","loot"])
	store.bag_size = Vector2i(1,1)
	store.add_item("berry","bag","player")
	store.add_item("berry","loot","player")
	var blocked_loot: Dictionary = store.items.filter(func(i): return i.zone == "loot")[0]
	page.pointer = page.item_rect(blocked_loot).get_center()
	var ctrl_click := InputEventMouseButton.new()
	ctrl_click.button_index = MOUSE_BUTTON_LEFT
	ctrl_click.pressed = true
	ctrl_click.ctrl_pressed = true
	page._gui_input(ctrl_click)
	check(blocked_loot.zone == "loot","loot remains in place when the bag is full")
	check(page.notice == "背包空间不足","full bag shows the shortage notice")
	print("PASS: %d exploration loot auto-pickup checks" % checks)
	quit()
