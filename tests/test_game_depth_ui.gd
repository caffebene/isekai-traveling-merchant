extends SceneTree

var checks := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		push_error("FAILED: " + message)
		quit(1)
		assert(ok,message)

func all_text(node: Node) -> String:
	var result := ""
	if node is Label or node is Button:
		result += str(node.text) + "\n"
	for child in node.get_children():
		result += all_text(child)
	return result

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var shop = load("res://main.tscn").instantiate()
	root.add_child(shop)
	await process_frame
	shop._open_market_board()
	await process_frame
	check(is_instance_valid(shop.market_board),"market board opens as a dedicated screen")
	check(shop.market_board.rows.get_child_count() >= 12,"market board lists individual tradable items")
	var market_text := all_text(shop.market_board)
	check(market_text.contains("基础") and market_text.contains("现价") and market_text.contains("涨跌") and market_text.contains("价格原因"),"market table exposes the complete price breakdown")
	check(market_text.contains("月光草") and market_text.contains("炼药师集会") and market_text.contains("+45%"),"event calendar names exact items and multipliers")
	shop._close_market_board()
	shop._open_module_shop()
	await process_frame
	var module_text := all_text(shop.module_shop)
	check(module_text.contains("6 × 6 · 36 格") and module_text.contains("8 × 6 · 48 格"),"module card compares backpack before and after")
	check(module_text.contains("背包物品全部遗失") and module_text.contains("价值最高的 2 件"),"module card exposes defeat protection")
	shop._buy_module("roof_rack")
	check(shop.state.bag_size == Vector2i(8,6) and all_text(shop.module_shop).contains("插槽 1 / 2"),"installed module updates its proof immediately")
	shop.state.gold += 500
	shop._buy_module("hidden_compartment")
	shop._close_module_shop()
	var sword: Dictionary = shop.state.items.filter(func(i): return i.key == "sword" and i.owner == "player" and i.zone == "stock")[0]
	var ore: Dictionary = shop.state.items.filter(func(i): return i.key == "ore" and i.owner == "player" and i.zone == "stock")[0]
	check(shop.state.move_item(sword.id,"bag",Vector2i(0,0),false) == "","weapon enters build grid")
	check(shop.state.move_item(ore.id,"bag",Vector2i(2,0),false) == "","ore activates beside weapon")
	shop._open_bag()
	check(shop.state.bag_effect_text(sword).contains("攻击 8 → 11") and shop.state.bag_effect_text(sword).contains("战败时保留"),"item tooltip proves layout and module effects")
	print("PASS: %d game-depth UI checks" % checks)
	quit(0)
