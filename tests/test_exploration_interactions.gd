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

func move_to_bag(store, key: String) -> Dictionary:
	var item: Dictionary = store.items.filter(func(i): return i.key == key and i.owner == "player" and i.zone == "stock")[0]
	check(store.move_item(item.id,"bag",store.free_cell(item,"bag"),false) == "", "%s fits the travel bag" % key)
	return item

func double_click_at(page, item: Dictionary) -> void:
	page.pointer = page.item_rect(item).get_center()
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.double_click = true
	page._gui_input(event)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var store = Store.new()
	var page = Exploration.new()
	page.state = store
	root.add_child(page)
	await process_frame
	var sword: Dictionary = move_to_bag(store,"sword")
	var potion: Dictionary = move_to_bag(store,"potion")
	page.combat.next_encounter()
	page.refresh()
	check(page.combat.phase == "ready" and page.escape_button.visible and page.fight_button.visible,"preparation shows flee and fight buttons")
	page.pointer = page.item_rect(sword).get_center()
	page._sync_item_hover()
	check(page.hover_tip.visible and page.hover_tip.market_label.text.ends_with(" G") and not page.hover_tip.stat_labels.is_empty(),"battle item hover uses the shared full-info tip")
	page._hide_item_hover()
	check(page.escape_button.position == Vector2(page.UI_CENTER_X-270,810) and page.fight_button.position == Vector2(page.UI_CENTER_X+20,810) and page.escape_button.size == Vector2(250,52) and page.fight_button.size == Vector2(250,52),"preparation buttons use the same compact layout as victory actions")
	check(not page.primary.visible and not page.victory_return_button.visible,"preparation hides the exploration and victory actions")
	double_click_at(page,potion)
	check(not store.items.has(potion) and page.combat.shield == 15,"double-click uses a backpack potion during preparation")
	page._fight()
	page.refresh()
	check(page.combat.phase == "battle" and page.escape_button.visible and not page.fight_button.visible,"battle retains flee while hiding preparation fight button")
	var battle_potion: Dictionary = move_to_bag(store,"potion")
	double_click_at(page,battle_potion)
	check(not store.items.has(battle_potion),"double-click uses a backpack potion during battle")
	page.combat.attack(999)
	page.refresh()
	check(page.combat.phase == "victory" and page.victory_return_button.visible and page.continue_button.visible,"victory shows return and continue actions")
	page._victory_return()
	page.refresh()
	check(page.confirm_action == "return" and page.victory_return_button.text == "丢弃并返回","return action confirms before discarding uncollected loot")
	page._victory_return()
	check(page.combat.phase == "returned","confirmed return exits the exploration")
	page.free()

	store = Store.new()
	page = Exploration.new()
	page.state = store
	root.add_child(page)
	await process_frame
	move_to_bag(store,"sword")
	page.combat.next_encounter()
	page._fight()
	page.combat.hp = 1
	page.combat.end_turn()
	page.refresh()
	check(page.combat.phase == "defeat" and page.victory_return_button.visible and not page.continue_button.visible,"defeat shows only the return action")
	page._defeat_return()
	check(page.combat.phase == "returned","defeat return button ends the exploration")
	page.free()

	var shop = load("res://main.tscn").instantiate()
	root.add_child(shop)
	await process_frame
	var shop_sword: Dictionary = shop.state.items.filter(func(i): return i.key == "sword" and i.owner == "player" and i.zone == "stock")[0]
	check(shop.state.move_item(shop_sword.id,"bag",shop.state.free_cell(shop_sword,"bag"),false) == "","shop test item enters travel bag")
	shop._start_exploration()
	await process_frame
	shop.exploration.combat.next_encounter()
	var lost_name: String = shop.state.CATALOG[shop_sword.key].name
	shop.exploration._escape()
	check(shop.exploration == null and shop.modal != null,"flee returns to the wagon and opens a result popup")
	var popup_text := ""
	for modal_child in shop.modal.get_child(0).get_children():
		if modal_child is Label:
			popup_text += modal_child.text
	check(popup_text.contains("你已成功逃回商车") and popup_text.contains(lost_name),"flee popup names the dropped item")
	shop._close_modal()
	shop.queue_free()
	print("PASS: %d exploration interaction checks" % checks)
	quit()
