extends SceneTree

const Store = preload("res://scripts/trade_state.gd")
const Combat = preload("res://scripts/exploration_state.gd")

var checks := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		push_error("FAILED: " + message)
		quit(1)
		assert(ok,message)

func move_to_bag(store, key: String, cell: Vector2i) -> Dictionary:
	var item: Dictionary = store.items.filter(func(i): return i.key == key and i.owner == "player" and i.zone == "stock")[0]
	check(store.move_item(item.id,"bag",cell,false) == "",key + " enters build grid")
	return item

func _initialize() -> void:
	var s = Store.new()
	check(s.economy.city_name() == "风栖镇","campaign starts in Windrest")
	check(s.market_value("ore") > Store.CATALOG.ore.value,"ore is scarce in forest city")
	check(s.market_value("herb") < Store.CATALOG.herb.value,"herb is abundant in forest city")
	s.day = 3
	check(s.economy.active_event(s.day).name == "炼药师集会","announced city event activates")
	check(s.market_multiplier("potion") > 1.2,"event raises relevant demand")
	var before_pressure := s.market_value("herb")
	s.economy.record_sale("材料",4)
	check(s.market_value("herb") < before_pressure,"repeated sales reduce local demand")
	s.economy.advance_day()
	check(int(s.economy.sold_pressure.windrest["材料"]) == 3,"demand pressure recovers over time")
	s.configure_customer("材料","",[],150,"希尔薇")
	check(s.economy.relationship("希尔薇") == 0,"customer relationship starts at zero")
	s.economy.record_trade("希尔薇")
	s.economy.record_trade("希尔薇")
	check(s.economy.intelligence(3,"希尔薇").contains("骑士团驻扎") and not s.economy.intelligence(3).contains("骑士团驻扎"),"trusted customer reveals a rumor earlier than the public paper")
	check(not s.economy.intelligence(3,"希尔薇").contains("天后") and not s.economy.intelligence(3,"希尔薇").contains("%"),"customer intelligence stays qualitative")
	check(not s.economy.market_report(Store.CATALOG,3).contains(" G") and not s.economy.market_report(Store.CATALOG,3).contains("%"),"legacy market report cannot leak exact quotes")
	s.day = 7
	var old_gold: int = s.gold
	check(s.can_travel(),"trade route opens on cycle day seven")
	check(s.travel_to_next_city().contains("铁砧城"),"travel reaches second city")
	check(s.day == 8 and s.gold == old_gold-35,"travel costs gold and one day")
	check(s.market_value("herb") > Store.CATALOG.herb.value,"cross-city herb arbitrage exists")

	s = Store.new()
	var module_gold: int = s.gold
	check(s.install_module("roof_rack").contains("车顶货架"),"roof rack can be installed")
	check(s.bag_size == Vector2i(8,6) and s.gold == module_gold-180,"roof rack changes usable space and costs gold")
	s.gold += 300
	check(s.install_module("hidden_compartment").contains("隐藏夹层"),"second module can be installed")
	check(s.install_module("field_kitchen").contains("最多"),"module limit creates a build choice")

	s = Store.new()
	check(s.install_module("hidden_compartment").contains("隐藏夹层"),"hidden compartment can be a first build choice")
	move_to_bag(s,"sword",Vector2i(0,0))
	move_to_bag(s,"potion",Vector2i(2,0))
	move_to_bag(s,"berry",Vector2i(3,0))
	var protected_combat = Combat.new()
	protected_combat.start(s)
	protected_combat._discard_bag()
	check(s.items.filter(func(i): return i.zone == "bag").size() == 2,"hidden compartment preserves exactly two valuables on defeat")

	s = Store.new()
	check(s.install_module("field_kitchen").contains("行军灶"),"field kitchen can be installed")
	var bread := move_to_bag(s,"bread",Vector2i(0,0))
	var kitchen_combat = Combat.new()
	kitchen_combat.start(s)
	kitchen_combat.next_encounter()
	kitchen_combat.hp = 20
	kitchen_combat.use_item(bread.id)
	check(kitchen_combat.hp == 40,"field kitchen adds eight healing to bread")

	s = Store.new()
	var sword := move_to_bag(s,"sword",Vector2i(0,0))
	var ore := move_to_bag(s,"ore",Vector2i(2,0))
	var c = Combat.new()
	c.start(s)
	check(c.weapon_damage(sword) == 11,"adjacent ore adds weapon damage")
	check(is_equal_approx(c.weapon_interval(sword),2.0),"ore does not change adjacent weapon interval")
	check(c._adjacent(sword,ore),"grid edge adjacency is detected")
	var fuel := move_to_bag(s,"slime_mucus",Vector2i(2,2))
	check(is_equal_approx(c.weapon_interval(sword),1.8),"adjacent slime reduces interval by ten percent")
	check(c.weapon_damage(sword) == 11,"fuel interval boost does not alter attack damage")
	s.add_item("ancient_wood","stock","player")
	var wood: Dictionary = s.items.back()
	check(s.move_item(wood.id,"bag",Vector2i(2,4),false) == "","wood can join the same adjacent weapon")
	check(is_equal_approx(c.weapon_interval(sword),1.44),"fuel percentage reductions multiply")
	check(s.move_item(fuel.id,"bag",Vector2i(4,0),false) == "","fuel moves away from the weapon")
	check(is_equal_approx(c.weapon_interval(sword),1.6),"nonadjacent fuel does not change weapon interval")
	for n in range(7):
		c.next_encounter()
		if n < 6:
			c.phase = "victory"
	check(c.boss and c.depth == 7 and c.enemy.name == "月蚀古树王","seventh depth is a boss encounter")

	print("PASS: %d game-depth checks" % checks)
	quit(0)
