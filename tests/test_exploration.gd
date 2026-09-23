extends SceneTree

const Store = preload("res://scripts/trade_state.gd")
const Combat = preload("res://scripts/exploration_state.gd")

var checks := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		push_error(message)
		quit(1)
		assert(ok,message)

func move_to_bag(store, key: String) -> Dictionary:
	var item: Dictionary = store.items.filter(func(i): return i.key == key and i.owner == "player" and i.zone == "stock")[0]
	var cell: Vector2i = store.free_cell(item,"bag")
	check(store.move_item(item.id,"bag",cell,false) == "", "%s fits the travel bag" % key)
	return item

func _initialize() -> void:
	var s = Store.new()
	var c = Combat.new()
	var forbidden_drops := ["sword","iron_sword","potion","power","bread","steak"]
	for enemy in Combat.ENEMIES:
		check(not enemy.drops.is_empty(),"%s has a material drop table" % enemy.name)
		for key in enemy.drops:
			check(not forbidden_drops.has(key),"%s drops materials only" % enemy.name)
	check(Combat.ENEMIES[-1].name == "古木精" and Combat.ENEMIES[-1].drops.has("ancient_wood"),"tree monster drops ancient wood")
	c.start(s)
	check(c.phase == "idle" and c.encounter == 0 and c.enemy.is_empty(),"start at preparation")
	c.tick(10)
	check(c.hp == 60 and c.encounter == 0 and c.enemy.is_empty(),"waiting does not spawn enemy or consume exploration")
	var sword: Dictionary = move_to_bag(s,"sword")
	var potion: Dictionary = move_to_bag(s,"potion")
	c.next_encounter()
	check(c.phase == "ready" and c.encounter == 1,"exploration enters preparation when an enemy appears")
	c.tick(10)
	check(c.phase == "ready" and c.enemy_hp == c.enemy.hp and sword.get("durability",20) == 20,"preparation pauses combat timers")
	c.hp = 40
	c.use_item(potion.id)
	check(c.phase == "ready" and c.hp == 40 and c.shield == 15 and not s.items.has(potion),"preparation allows manual potion use without spending energy")
	c.shield = 0
	c.begin_battle()
	check(c.phase == "battle","fight action starts battle")
	c.tick(2)
	var sword_after_attack: Dictionary = s.items.filter(func(i): return i.id == sword.id)[0]
	check(c.enemy_hp == 14 and sword_after_attack.get("durability",20) == 19,"weapon auto attacks and loses durability")
	var second_potion: Dictionary = move_to_bag(s,"potion")
	c.hp = 30
	c.tick(3)
	check(c.hp == 25 and s.items.has(second_potion),"enemy attacks while battle is active but does not auto-consume potions")
	c.use_item(second_potion.id)
	check(c.hp == 25 and c.shield == 15 and not s.items.has(second_potion),"battle potion uses are triggered explicitly")
	c.attack(999)
	check(c.phase == "victory","battle can end in victory")
	var loot: Array = s.items.filter(func(i): return i.zone == "loot")
	check(loot.size() >= 2 and loot.size() <= 3,"random loot generated")
	s.bag_size = Vector2i(12,8)
	var cell: Vector2i = s.free_cell(loot[0],"bag")
	check(c.pickup(loot[0].id,cell,false) == "","manual pickup succeeds")
	var kept: int = loot[0].id
	c.next_encounter()
	check(s.items.any(func(i): return i.id == kept and i.zone == "bag"),"collected loot persists")
	check(not s.items.any(func(i): return i.zone == "loot"),"uncollected loot discarded")
	check(c.phase == "ready" and c.encounter == 2,"continuing enters preparation instead of immediately starting combat")
	for n in range(9):
		c.begin_battle()
		c.attack(999)
		if n < 8:
			c.next_encounter()
	check(c.encounter == 10 and c.phase == "victory","exploration remains unlimited beyond five encounters")

	s = Store.new()
	c = Combat.new()
	c.start(s)
	move_to_bag(s,"sword")
	move_to_bag(s,"potion")
	var bag_before: int = s.items.filter(func(i): return i.zone == "bag").size()
	c.next_encounter()
	var lost: Dictionary = c.flee()
	check(c.phase == "returned" and lost.size() > 0,"flee returns to the wagon from preparation")
	check(s.items.filter(func(i): return i.zone == "bag").size() == bag_before-1 and not s.items.any(func(i): return i.id == lost.id),"flee randomly drops exactly one backpack item")

	s = Store.new()
	c = Combat.new()
	c.start(s)
	move_to_bag(s,"sword")
	move_to_bag(s,"potion")
	c.next_encounter()
	c.begin_battle()
	c.hp = 1
	c.end_turn()
	check(c.phase == "defeat" and s.items.filter(func(i): return i.zone == "bag").is_empty(),"zero health discards every backpack item")
	var previous: int = c.enemy_hp
	c.tick(30)
	check(c.enemy_hp == previous,"defeat stops timers")

	s = Store.new()
	c = Combat.new()
	c.start(s)
	c.next_encounter()
	c.begin_battle()
	c.tick(2)
	check(c.enemy_hp == 17,"empty bag auto fallback")
	var bread: Dictionary = move_to_bag(s,"bread")
	c.hp = 30
	c.use_item(bread.id)
	check(not s.items.has(bread) and c.hp == 42,"food is only consumed by an explicit use action")
	print("PASS: %d exploration checks" % checks)
	quit()
