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
	check(shop.market_board.articles_column.get_child_count() > 0,"market board publishes newspaper stories")
	var market_text := all_text(shop.market_board)
	check(market_text.contains("风栖镇商报") and market_text.contains("街头消息") and not market_text.contains("价格原因"),"newspaper uses headlines and rumors instead of a quote table")
	check(not market_text.contains("%") and not market_text.contains("精确预测") and not market_text.contains("天后"),"newspaper does not reveal numeric price changes or exact event dates")
	check(not market_text.contains("骑士团驻扎"),"distant events are not listed as an omniscient calendar")
	shop.state.day = 4
	shop.market_board.refresh()
	await process_frame
	market_text = all_text(shop.market_board)
	check(market_text.contains("本城新闻") and market_text.contains("街头消息") and market_text.contains("炼药师集会") and market_text.contains("骑士团驻扎"),"active news and upcoming rumors can coexist")
	shop.state.economy.city_id = "ironvale"
	shop.state.day = 9
	shop.state.economy.record_sale("矿石",2)
	shop.market_board.refresh()
	await process_frame
	market_text = all_text(shop.market_board)
	check(market_text.contains("铁砧城商报") and market_text.contains("矿队归来") and market_text.contains("摊位上的旧货"),"newspaper follows city events and qualitative supply pressure")
	var news_text := all_text(shop.market_board.articles_column)+all_text(shop.market_board.local_column)
	var number := RegEx.new()
	number.compile("[0-9%]")
	check(number.search(news_text) == null,"news copy contains no prices, percentages, dates or pressure levels")
	shop.state.day = 14
	shop.market_board.refresh()
	await process_frame
	check(all_text(shop.market_board).contains("市集照常开张"),"quiet days publish everyday news instead of expired events")
	check(shop.market_board.travel_button.visible and shop.market_board.travel_button.text.contains("35 G"),"newspaper preserves the departure action and its actual fare")
	var before_travel_gold: int = shop.state.gold
	shop.market_board.travel_button.emit_signal("pressed")
	check(shop.state.economy.city_id == "ironvale" and shop.state.gold == before_travel_gold,"newspaper departure preserves the existing closed-shutter requirement")
	shop.state.day = 15
	shop._open_market_board()
	await process_frame
	check(not shop.market_board.travel_button.visible,"newspaper hides departure outside the travel day")
	shop.state.economy.city_id = "windrest"
	shop.state.day = 1
	shop._close_market_board()
	shop._open_module_shop()
	await process_frame
	var module_text := all_text(shop.module_shop)
	check(module_text.contains("标准容量") and module_text.contains("容量 +33%"),"module card compares backpack before and after")
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
	var card: Dictionary = shop.state.item_card_data(sword)
	check(card.stats.any(func(row): return row.label == "攻击" and row.value == "11"),"weapon detail shows final attack including adjacent ore")
	check(card.stats.any(func(row): return row.label == "攻击间隔" and row.value == "2.00 秒"),"weapon detail shows actual modified attack interval")
	check(card.stats.any(func(row): return row.label == "夹层保护" and row.value == "战败保留"),"weapon detail retains real protection state")
	print("PASS: %d game-depth UI checks" % checks)
	quit(0)
