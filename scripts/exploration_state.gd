extends RefCounted
signal presentation(data: Dictionary)
const Story = preload("res://scripts/forest_story.gd")
var story_dialogue: Array = []
var story_index := 0
var story_resume := ""
var companion := ""
var companion_clock := 0.0
var quest_opening_done := false

const ForestEvents = preload("res://scripts/forest_events.gd")
var route_index := -1
var event: Dictionary = {}
var event_result := ""
var pending_verdict := false
var active_verdict := false
var wish_debt := false
var enemy_first_attack := true
var boss_repair_shown := false
var memory: Dictionary = {}
var dialogue_index := 0
var result_dialogue: Array = []
var event_streak := 0

func can_collect() -> bool:
	return phase in ["victory", "event_loot"]

func route_finished() -> bool:
	return false

func _init_memory() -> void:
	if inventory.forest_memory.is_empty():
		inventory.forest_memory = {"step":0,"visits":{},"last_seen":{},"last_actions":{},"last_variants":{},"chest_refusals":0,"chest_fed":false,"mushrooms_respected":0,"mushroom_case":{},"court_delays":0,"frog_testimony":false,"well_debt":false,"pending":[],"history":[]}
	memory = inventory.forest_memory
	wish_debt = memory.well_debt

func _schedule(id: String, delay: int) -> void:
	if memory.pending.any(func(ticket): return ticket.id == id):
		return
	memory.pending.append({"id":id,"due":int(memory.step)+delay})

func _cancel(id: String) -> void:
	memory.pending = memory.pending.filter(func(ticket): return ticket.id != id)

func _ticket_valid(id: String) -> bool:
	return bool(memory.well_debt) if id == "collector" else ForestEvents.eligible(id,memory,inventory)

func next_node() -> void:
	if phase not in ["idle", "victory", "event_loot"]:
		return
	if inventory.story_progress.stage == "victory_pending":
		_story(Story.victory_lines(),"event_loot")
		return
	clear_loot()
	route_index += 1
	memory.step += 1
	event = {}
	event_result = ""
	enemy = {}
	enemy_hp = 0
	memory.pending = memory.pending.filter(func(ticket): return _ticket_valid(ticket.id))
	memory.pending.sort_custom(func(a,b): return a.due < b.due)
	var selected := ""
	for ticket in memory.pending:
		if not Story.quest_boss_pending(inventory) and int(ticket.due) <= int(memory.step) and (event_streak < 2 or ticket.id == "collector"):
			selected = ticket.id
			break
	if selected != "":
		_cancel(selected)
	elif not Story.quest_boss_pending(inventory) and event_streak < 2 and rng.randf() < 0.45:
		var pool: Array = []
		for id in ForestEvents.ROOT_WEIGHTS:
			if ForestEvents.eligible(id,memory,inventory) and int(memory.step)-int(memory.last_seen.get(id,-99)) >= 3 and not memory.pending.any(func(ticket): return ticket.id == id):
				for weight in range(ForestEvents.ROOT_WEIGHTS[id]):
					pool.append(id)
		if not pool.is_empty():
			selected = pool[rng.randi_range(0,pool.size()-1)]
	if Story.quest_boss_pending(inventory):
		selected = "quest_boss"
	if selected != "" and selected not in ["collector","quest_boss"]:
		enter_event(selected)
		return
	event_streak = 0
	phase = "idle"
	next_encounter()
	# Combat count controls elites/bosses; events never advance combat depth.
	if selected == "collector" and not boss:
		boss = true
		elite = false
		enemy = {"name":"月蚀古树王","hp":roundi(110*(1.0+(depth-1)*0.08)),"attack":roundi(14*(1.0+(depth-1)*0.045)),"color":"b99b65","drops":["ancient_wood","ore","herb"]}
	if boss and wish_debt:
		enemy["arrival_line"] = "你在井边签的账，该还了。"
	enemy["art"] = "hollow_stag" if enemy.get("quest",false) else "treant" if boss else ["slime","wolf","golem","red_wolf","treant"][(depth-1)%5]
	active_verdict = pending_verdict
	pending_verdict = false
	if active_verdict:
		enemy.attack = ceili(float(enemy.attack)*1.5)
	enemy_hp = enemy.hp
	enemy_first_attack = true
	boss_repair_shown = false

func enter_event(id: String) -> bool:
	if not ForestEvents.eligible(id,memory,inventory):
		return false
	event = ForestEvents.build(id,memory,rng,inventory)
	dialogue_index = 0
	result_dialogue = []
	event_result = ""
	enemy = {}
	enemy_hp = 0
	event_streak += 1
	memory.visits[id] = int(memory.visits.get(id,0))+1
	memory.last_seen[id] = memory.step
	memory.last_variants[id] = event.variant
	phase = "event"
	presentation.emit({"kind":"event_enter","event":id})
	return true

func choices_available() -> bool:
	return phase == "event" and dialogue_index >= event.dialogue.size()-1

func current_dialogue() -> Dictionary:
	if phase == "story":
		return story_dialogue[story_index]
	var pages: Array = result_dialogue if phase == "event_result" else event.get("dialogue",[])
	return pages[mini(dialogue_index,pages.size()-1)] if not pages.is_empty() else {}

func advance_dialogue() -> void:
	if phase == "story":
		if story_index < story_dialogue.size()-1:
			story_index += 1
			if story_dialogue[story_index].get("heal",false):
				var restored := MAX_HP-hp
				hp = MAX_HP
				companion = "sylvie"
				companion_clock = 0.0
				inventory.story_progress.stage = "rescued"
				presentation.emit({"kind":"companion_enter"})
				presentation.emit({"kind":"heal","heal":restored})
		else:
			phase = story_resume
			if story_resume in ["victory","event_loot"]:
				inventory.story_progress.stage = "recruited"
			story_dialogue.clear()
		return
	if phase == "event" and not choices_available():
		dialogue_index += 1
	elif phase == "event_result":
		if dialogue_index < result_dialogue.size()-1:
			dialogue_index += 1
		else:
			phase = "event_loot"

func event_items(option: Dictionary) -> Array:
	if option.has("tool"):
		return ForestEvents.tool_items(option.tool,inventory,int(option.get("tool_cost",1)))
	return inventory.items.filter(func(item): return item.zone == "bag" and item.owner == "player" and item.key == option.get("item",""))

func event_item_id(option: Dictionary) -> int:
	var candidates := event_items(option)
	return int(candidates[0].id) if not candidates.is_empty() else -1

func event_option_error(option: Dictionary, item_id: int = -1) -> String:
	if inventory.gold < int(option.get("cost", 0)):
		return "金币不足"
	if option.has("tool") and not event_items(option).any(func(i): return i.id == item_id):
		return "需要耐久足够的%s" % ("斧头" if option.tool == "axe" else "镐子")
	if option.has("item"):
		if not inventory.items.any(func(i): return i.id == item_id and i.zone == "bag" and i.owner == "player" and i.key == option.item):
			return "缺少%s" % inventory.CATALOG[option.item].name
	return ""

func choose_event(option_id: String, item_id: int = -1) -> String:
	if not choices_available():
		return "请先听完这段对话" if phase == "event" else "事件已结束"
	var options: Array = event.options.filter(func(o): return o.id == option_id)
	if options.is_empty():
		return "无效选项"
	var option: Dictionary = options[0]
	var error := event_option_error(option,item_id)
	if error != "":
		return error
	phase = "event_resolving"
	var used_tool: Dictionary = {}
	if option.has("tool"):
		used_tool = event_items(option).filter(func(i): return i.id == item_id)[0]
		used_tool.durability = int(used_tool.get("durability",20))-int(option.get("tool_cost",1))
	var cost := int(option.get("cost",0))
	inventory.gold -= cost
	if option.has("item"):
		inventory.items = inventory.items.filter(func(i): return i.id != item_id)
	var outcome: Dictionary = ForestEvents.outcome(option,rng)
	inventory.gold += int(outcome.get("gold",0))
	event_result = outcome.result
	if outcome.get("lose",false):
		var bag: Array = inventory.items.filter(func(i): return i.zone == "bag" and i.owner == "player")
		if not bag.is_empty():
			var lost: Dictionary = bag[rng.randi_range(0,bag.size()-1)]
			inventory.items = inventory.items.filter(func(i): return i.id != lost.id)
			event_result += " 你发现%s不见了。" % inventory.CATALOG[lost.key].name
		else:
			event_result = ("箱盖咬住手腕，但背包空着，没吞到行李。" if outcome.get("damage",0) > 0 else "宝箱扑向空背包，什么也没吞到。") if event.id == "chest" else "井底卷起一阵风，没能从空背包带走东西，只吐出浑水。"
	for item in inventory.items:
		if item.zone == "bag" and item.owner == "player" and item.key in WEAPON_KEYS:
			item.durability = clampi(int(item.get("durability",20))+int(outcome.get("repair",0))-int(outcome.get("wear",0)),0,int(item.get("max_durability",inventory.CATALOG[item.key].get("base_durability",20))))
	var before := hp
	hp = maxi(0,hp-int(outcome.get("damage",0)))
	hp = MAX_HP if outcome.get("full_heal",false) else mini(MAX_HP,hp+int(outcome.get("heal",0)))
	_remember_choice(option_id,outcome)
	pending_verdict = pending_verdict or outcome.get("verdict",false)
	wish_debt = bool(memory.well_debt)
	if hp == 0:
		_discard_bag()
		active_verdict = false
		phase = "defeat"
	else:
		for key in outcome.get("rewards",[]):
			inventory.add_item(key,"loot","player")
	result_dialogue = [ForestEvents.say("旁白",event_result)]
	dialogue_index = 0
	presentation.emit({"kind":"event_result","event":event.art,"hp_delta":hp-before,"text":event_result,"lost":outcome.get("lose",false),"rewards":outcome.get("rewards",[]),"tool_id":used_tool.get("id",-1),"tool_key":used_tool.get("key","")})
	return ""

func _remember_choice(action: String, outcome: Dictionary) -> void:
	if outcome.get("hunter_saved",false):
		inventory.story_progress.hunter_saved = true
	if outcome.get("camp_supply",false):
		memory["camp_fuel"] = 1
	if outcome.get("use_camp_fuel",false):
		memory["camp_fuel"] = 0
	if outcome.get("snail_payment",false):
		memory["snail_paid"] = int(memory.get("snail_paid",0))+1
	if outcome.get("snail_fed",false):
		memory["snail_fed"] = true
	var id: String = event.id
	memory.last_actions[id] = action
	memory.history.append({"step":memory.step,"id":id,"variant":event.variant,"action":action,"result":outcome.result})
	if memory.history.size() > 64:
		memory.history.pop_front()
	if id == "chest":
		if action == "skip":
			memory.chest_refusals += 1
			_schedule("chest",rng.randi_range(2,4))
		else:
			memory.chest_refusals = 0
			memory.chest_fed = memory.chest_fed or action == "feed"
			_cancel("chest")
	if outcome.get("respect",false):
		memory.mushrooms_respected += 1
	if outcome.get("case",false):
		memory.mushroom_case = {"description":"采草时扯翻了小蘑菇的屋顶","place":"路边蘑菇丛采草","witness":"frog" if event.variant == "moving" else "mushroom","source_step":memory.step}
		memory.frog_testimony = false
		_schedule("court",rng.randi_range(3,5))
		if event.variant == "moving":
			_schedule("frog",2)
	if outcome.get("testimony",false):
		memory.frog_testimony = true
	if outcome.get("settle_case",false):
		memory.mushroom_case = {}
		memory.frog_testimony = false
		memory.court_delays = 0
		_cancel("court")
	if outcome.get("delay_case",false):
		memory.court_delays += 1
		_schedule("court",rng.randi_range(3,5))
	if outcome.get("debt",false):
		memory.well_debt = true
		_schedule("collector",rng.randi_range(3,5))
	if outcome.get("repay",false):
		memory.well_debt = false
		_cancel("collector")

func finish_event() -> void:
	if phase == "event_resolving":
		phase = "event_result"
		dialogue_index = 0

func _clear_journey_effects() -> void:
	pending_verdict = false
	active_verdict = false
	wish_debt = false

const ENEMIES = [
	{"name":"苔原史莱姆","hp":22,"attack":5,"color":"83b6a0","drops":["herb","slime_mucus"]},
	{"name":"荆棘野狼","hp":30,"attack":7,"color":"9ba8b5","drops":["meat","berry"]},
	{"name":"林地石怪","hp":38,"attack":8,"color":"b59e7d","drops":["ore","copper_ore"]},
	{"name":"赤眼野狼","hp":42,"attack":9,"color":"bd8580","drops":["meat","berry"]},
	{"name":"古木精","hp":52,"attack":10,"color":"90a97b","drops":["herb","ancient_wood"]}
]
var inventory
var phase := "idle"
var encounter := 0
var hp := 60
var shield := 0
var energy := 3
var power := false
var enemy: Dictionary = {}
var enemy_hp := 0
var turn := 1
var elapsed := 0.0
var enemy_clock := 0.0
var basic_clock := 0.0
var clocks: Dictionary = {}
var message := ""
var last_fled := false
var last_lost_item_name := ""
var depth := 0
var elite := false
var boss := false
var weapon_cycle := 0
var next_weapon_id := -1
var rng := RandomNumberGenerator.new()

const MAX_HP := 60
const WEAPON_KEYS := ["sword", "iron_sword", "copper_sword", "copper_axe", "iron_axe", "copper_pickaxe", "iron_pickaxe", "tempered_sword", "tempered_axe"]
const USABLE_ITEM_KEYS := ["meat", "bread", "steak", "potion", "power"]

func start(store) -> void:
	inventory = store
	companion = store.selected_companion if Story.can_select(store,store.selected_companion) else ""
	story_dialogue.clear()
	story_index = 0
	companion_clock = 0.0
	quest_opening_done = false
	rng.randomize()
	route_index = -1
	event = {}
	event_result = ""
	_clear_journey_effects()
	_init_memory()
	event_streak = 0
	encounter = 0
	depth = 0
	hp = MAX_HP
	phase = "idle"
	enemy = {}
	enemy_hp = 0
	shield = 0
	message = ""
	last_fled = false
	last_lost_item_name = ""
	energy = 3
	power = false
	elapsed = 0.0
	enemy_clock = 0.0
	basic_clock = 0.0
	weapon_cycle = 0
	next_weapon_id = -1
	clocks.clear()
	enemy_first_attack = true
	boss_repair_shown = false

func clear_loot() -> void:
	inventory.items = inventory.items.filter(func(i): return i.zone != "loot")

func next_encounter() -> void:
	if phase not in ["idle","victory"]:
		return
	clear_loot()
	encounter += 1
	depth = encounter
	boss = depth % 7 == 0
	elite = not boss and depth % 3 == 0
	enemy = ENEMIES[(encounter-1) % ENEMIES.size()].duplicate()
	var hp_scale := 1.0 + float(depth-1) * 0.08
	var attack_scale := 1.0 + float(depth-1) * 0.045
	if elite:
		enemy.name = "精英·%s" % enemy.name
		hp_scale *= 1.35
		attack_scale *= 1.20
	if boss:
		enemy = {"name":"月蚀古树王","hp":110,"attack":14,"color":"b99b65","drops":["ancient_wood","ore","herb"]}
		hp_scale *= 1.0 + float(depth-7) * 0.035
	if Story.quest_boss_pending(inventory):
		boss = true
		elite = false
		enemy = {"name":"空心鹿王","hp":210,"attack":18,"color":"a6bfd2","drops":["ancient_wood","ore","power"],"art":"hollow_stag","quest":true,"arrival_line":"空壳里封着月光，它正等你走近。"}
		hp_scale = 1.0
		attack_scale = 1.0
		quest_opening_done = false
	enemy.hp = roundi(int(enemy.hp) * hp_scale)
	enemy.attack = roundi(int(enemy.attack) * attack_scale)
	enemy["art"] = "hollow_stag" if enemy.get("quest",false) else "treant" if boss else ["slime","wolf","golem","red_wolf","treant"][(depth-1)%5]
	enemy_hp = enemy.hp
	energy = 3
	shield = 0
	power = false
	turn = 1
	elapsed = 0.0
	enemy_clock = 0.0
	basic_clock = 0.0
	companion_clock = 0.0
	enemy_first_attack = true
	clocks.clear()
	weapon_cycle = 0
	next_weapon_id = -1
	phase = "ready"
	message = "遭遇%s，可以使用背包物品或开始战斗。" % enemy.name

func begin_battle() -> void:
	if phase != "ready" or enemy.is_empty() or enemy_hp <= 0:
		return
	phase = "battle"
	enemy_clock = 0.0
	basic_clock = 0.0
	message = "战斗开始，武器会自动攻击。"
	var armed: Array[Dictionary] = inventory.items.filter(func(i): return i.zone == "bag" and i.key in WEAPON_KEYS and i.get("durability",20) > 0)
	_player_strike(armed,0)

func attack(damage: int, weapon_id: int = -1, critical := false, leech_ratio := 0.0, actor := "player") -> void:
	if phase != "battle":
		return
	var multiplier := (1.2 if power else 1.0) if actor == "player" else 1.0
	var floor_hp := 1 if enemy.get("quest",false) and not quest_opening_done else 0
	var applied := mini(enemy_hp-floor_hp,ceili(damage * multiplier * (1.5 if critical else 1.0)))
	enemy_hp = maxi(0,enemy_hp - applied)
	presentation.emit({"kind":"hit", "actor":actor, "weapon_id":weapon_id, "damage":applied, "shield":0, "critical":critical})
	var restored := mini(MAX_HP-hp,floori(applied*leech_ratio))
	if restored > 0:
		hp += restored
		presentation.emit({"kind":"heal","heal":restored})
	if boss and not enemy.get("quest",false) and not boss_repair_shown and enemy_hp > 0 and enemy_hp <= int(enemy.hp)/2:
		boss_repair_shown = true
		presentation.emit({"kind":"boss_repair"})
	message = "命中%s，造成 %d 点伤害。" % [enemy.name,applied]
	if enemy_hp == 0:
		phase = "victory"
		active_verdict = false
		presentation.emit({"kind":"victory"})
		# Reserve space for the guaranteed quest object before ordinary random loot.
		if boss and not enemy.get("quest",false) and inventory.story_progress.stage == "requested":
			inventory.add_item("moonheart","loot","player")
		var pool: Array = enemy.get("drops",["herb"])
		var loot_count := mini(6,rng.randi_range(2,3) + depth/2 + (1 if elite else 0) + (2 if boss else 0))
		for i in range(loot_count):
			inventory.add_item(pool[rng.randi_range(0,pool.size()-1)],"loot","player")
		if enemy.get("quest",false):
			inventory.story_progress.stage = "victory_pending"
			_story(Story.victory_lines(),"victory")
		message = "第 %d 层胜利！收益随深度提高，整理后决定继续或撤退。" % depth

func basic_attack() -> void:
	if phase != "battle":
		return
	if energy <= 0:
		message = "行动力不足，请结束回合。"
		return
	energy -= 1
	presentation.emit({"kind":"attack", "actor":"player", "weapon_id":-1, "key":""})
	attack(5)

func use_item(id: int) -> void:
	if phase not in ["ready","battle"]:
		return
	var index: int = inventory.items.find_custom(func(i): return i.id == id and i.zone == "bag")
	if index < 0:
		return
	var item: Dictionary = inventory.items[index]
	if item.key in WEAPON_KEYS:
		message = "武器会在战斗中自动攻击。"
		return
	if item.key not in USABLE_ITEM_KEYS:
		message = "这是贸易材料，战斗中无法直接使用。"
		return
	if phase == "battle" and not _in_belt(item) and energy <= 0:
		message = "行动力不足，请结束回合。"
		return
	if int(inventory.bag_effects(item).base_heal) > 0 and hp == MAX_HP:
		message = "生命已满，无需消耗食物。"
		return
	if item.key == "power" and power:
		message = "力量药剂已经生效。"
		return
	if phase == "battle" and not _in_belt(item):
		energy -= 1
	var previous_hp := hp
	var previous_shield := shield
	match item.key:
		"meat","bread","steak": hp = mini(MAX_HP,hp+int(inventory.bag_effects(item).final_heal))
		"potion": shield += 15
		"power": power = true
	message = "使用了%s。" % inventory.CATALOG[item.key].name
	inventory.items.remove_at(index)
	presentation.emit({"kind":"use", "item_id":id, "item":item.duplicate(), "key":item.key, "heal":hp-previous_hp, "shield":shield-previous_shield})

func _story(pages: Array, resume: String) -> void:
	story_dialogue = pages
	story_index = 0
	story_resume = resume
	phase = "story"
	presentation.emit({"kind":"story_enter"})

func end_turn() -> void:
	if phase != "battle":
		return
	if enemy.get("quest",false) and not quest_opening_done:
		quest_opening_done = true
		var actual_damage := maxi(0,hp-1)
		hp = 1
		shield = 0
		if wish_debt:
			wish_debt = false
			memory.well_debt = false
			_cancel("collector")
		enemy_first_attack = false
		presentation.emit({"kind":"hit","actor":"enemy","weapon_id":-1,"damage":actual_damage,"shield":0})
		_story([{"speaker":"旁白","text":"一声脆响，提灯掉在路边。你想撑起身子，胳膊却使不上劲。"},{"speaker":"希尔薇","text":"别动。先喝这个……慢点，别呛着。树心调的药，我带来了。", "heal":true},{"speaker":"希尔薇","text":"能站了吗？你看前头，我盯它的腿。"}],"battle")
		return
	var strike := int(enemy.attack)
	if boss and enemy_first_attack and wish_debt:
		strike *= 2
		wish_debt = false
		memory.well_debt = false
		_cancel("collector")
	enemy_first_attack = false
	var absorbed := mini(shield,strike)
	var damage: int = maxi(0,strike-shield)
	shield = maxi(0,shield-strike)
	var actual_damage := mini(hp,damage)
	hp = maxi(0,hp-damage)
	presentation.emit({"kind":"hit", "actor":"enemy", "weapon_id":-1, "damage":actual_damage, "shield":absorbed})
	message = "%s发动攻击，受到 %d 点伤害。" % [enemy.name,damage]
	if hp == 0:
		_discard_bag()
		active_verdict = false
		phase = "defeat"
		message = "你已战败，将遗失背包所有物品。"
	else:
		turn += 1
		energy = 3

func flee() -> Dictionary:
	if phase not in ["ready","battle"]:
		return {}
	last_fled = true
	last_lost_item_name = ""
	var bag_items: Array[Dictionary] = inventory.items.filter(func(i): return i.zone == "bag")
	var lost: Dictionary = {}
	if not bag_items.is_empty():
		lost = bag_items[rng.randi_range(0,bag_items.size()-1)].duplicate()
		last_lost_item_name = inventory.CATALOG[lost.key].name
		inventory.items = inventory.items.filter(func(i): return i.id != lost.id)
	clear_loot()
	_clear_journey_effects()
	phase = "returned"
	message = "逃跑时遗失了%s。" % inventory.CATALOG[lost.key].name if not lost.is_empty() else "你安全返回了商车。"
	return lost

func _discard_bag() -> void:
	var protected_ids: Array[int] = inventory.protected_bag_ids()
	inventory.items = inventory.items.filter(func(i): return i.zone != "bag" or protected_ids.has(i.id))
	clocks.clear()

func pickup(id: int, cell: Vector2i, rotated: bool) -> String:
	if not can_collect():
		return "结算后才能拾取。"
	return inventory.move_item(id,"bag",cell,rotated)

func leave() -> void:
	clear_loot()
	_clear_journey_effects()
	phase = "returned"

func cooldown(key: String) -> float:
	return 2.0 if key in WEAPON_KEYS else 5.0

func _adjacent(a: Dictionary, b: Dictionary) -> bool:
	return inventory.bag_adjacent(a,b)

func _adjacent_items(item: Dictionary) -> Array[Dictionary]:
	return inventory.items.filter(func(other): return other.zone == "bag" and other.id != item.id and _adjacent(item,other))

func weapon_damage(item: Dictionary) -> int:
	return int(inventory.bag_effects(item).final_attack)

func weapon_interval(item: Dictionary) -> float:
	return float(inventory.bag_effects(item).attack_interval)

func _in_belt(item: Dictionary) -> bool:
	return bool(inventory.bag_effects(item).free_use)

func build_summary() -> String:
	var weapons: Array[Dictionary] = inventory.items.filter(func(i): return i.zone == "bag" and i.key in WEAPON_KEYS)
	if weapons.is_empty():
		return "徒手 · 5 伤害"
	var parts: Array[String] = []
	for weapon in weapons:
		parts.append("%s %d伤害/%.1f秒" % [inventory.CATALOG[weapon.key].name,weapon_damage(weapon),weapon_interval(weapon)])
	return " · ".join(parts)

func tick(delta: float) -> void:
	if phase != "battle" or delta <= 0.0:
		return
	# Advance to each scheduled strike in chronological order. A slow frame must
	# not erase cooldown remainder or let a defeated enemy attack afterwards.
	var remaining := delta
	while remaining > 0.000001 and phase == "battle":
		var armed: Array[Dictionary] = inventory.items.filter(func(i): return i.zone == "bag" and i.key in WEAPON_KEYS and i.get("durability",20) > 0)
		var weapon_index := armed.find_custom(func(i): return i.id == next_weapon_id)
		if weapon_index < 0:
			weapon_index = 0
		var interval := 2.0 if armed.is_empty() else weapon_interval(armed[weapon_index])
		var ally_due := maxf(0.0,4.0-companion_clock) if companion == "sylvie" else INF
		var step := minf(remaining,minf(ally_due,minf(maxf(0.0,interval-basic_clock),maxf(0.0,3.0-enemy_clock))))
		elapsed += step
		enemy_clock += step
		basic_clock += step
		if companion == "sylvie":
			companion_clock += step
		remaining -= step
		if basic_clock >= interval-0.000001:
			basic_clock = maxf(0.0,basic_clock-interval)
			_player_strike(armed,weapon_index)
		if phase == "battle" and enemy_clock >= 3.0-0.000001:
			enemy_clock = maxf(0.0,enemy_clock-3.0)
			end_turn()

		if phase == "battle" and companion == "sylvie" and companion_clock >= 4.0-0.000001:
			companion_clock = maxf(0.0,companion_clock-4.0)
			presentation.emit({"kind":"companion_attack"})
			attack(6,-1,false,0.0,"companion")

func _player_strike(armed: Array[Dictionary], weapon_index: int) -> void:
	energy = 3
	if armed.is_empty():
		basic_attack()
	else:
		next_weapon_id = int(armed[(weapon_index+1) % armed.size()].id)
		_auto_weapon_attack(armed[weapon_index])
		weapon_cycle = (weapon_index+1) % armed.size()

func _auto_weapon_attack(item: Dictionary) -> void:
	if phase != "battle" or item.is_empty() or item.get("durability",20) <= 0:
		return
	presentation.emit({"kind":"attack", "actor":"player", "weapon_id":item.id, "key":item.key})
	item.durability = item.get("durability",20)-1
	var effects: Dictionary = inventory.bag_effects(item)
	var critical := rng.randf() < float(effects.critical_chance)
	attack(weapon_damage(item),item.id,critical,float(effects.leech_ratio))
