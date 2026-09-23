extends RefCounted
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
var rng := RandomNumberGenerator.new()

const MAX_HP := 60
const WEAPON_KEYS := ["sword", "iron_sword", "copper_sword", "copper_axe", "iron_axe", "copper_pickaxe", "iron_pickaxe", "tempered_sword", "tempered_axe"]
const USABLE_ITEM_KEYS := ["bread", "steak", "potion", "power"]

func start(store) -> void:
 inventory = store
 rng.randomize()
 encounter = 0
 hp = MAX_HP
 phase = "idle"
 enemy = {}
 enemy_hp = 0
 shield = 0
 message = ""
 last_fled = false
 last_lost_item_name = ""

func clear_loot() -> void:
 inventory.items = inventory.items.filter(func(i): return i.zone != "loot")

func next_encounter() -> void:
 if phase not in ["idle","victory"]:
  return
 clear_loot()
 enemy = ENEMIES[encounter % ENEMIES.size()].duplicate()
 encounter += 1
 enemy_hp = enemy.hp
 energy = 3
 shield = 0
 power = false
 turn = 1
 elapsed = 0.0
 enemy_clock = 0.0
 basic_clock = 0.0
 clocks.clear()
 phase = "ready"
 message = "遭遇%s，可以使用背包物品或开始战斗。" % enemy.name

func begin_battle() -> void:
 if phase != "ready" or enemy.is_empty() or enemy_hp <= 0:
  return
 phase = "battle"
 enemy_clock = 0.0
 basic_clock = 0.0
 message = "战斗开始，武器会自动攻击。"

func attack(damage: int) -> void:
 if phase != "battle":
  return
 enemy_hp = maxi(0,enemy_hp - ceili(damage * (1.2 if power else 1.0)))
 message = "命中%s，造成 %d 点伤害。" % [enemy.name,ceili(damage * (1.2 if power else 1.0))]
 if enemy_hp == 0:
  phase = "victory"
  var pool: Array = enemy.get("drops",["herb"])
  for i in range(rng.randi_range(2,3)):
   inventory.add_item(pool[rng.randi_range(0,pool.size()-1)],"loot","player")
  message = "胜利！将掉落物拖入背包后，再继续探索或返回。"

func basic_attack() -> void:
 if phase != "battle":
  return
 if energy <= 0:
  message = "行动力不足，请结束回合。"
  return
 energy -= 1
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
 if phase == "battle" and energy <= 0:
  message = "行动力不足，请结束回合。"
  return
 if item.key in ["bread","steak"] and hp == MAX_HP:
  message = "生命已满，无需消耗食物。"
  return
 if item.key == "power" and power:
  message = "力量药剂已经生效。"
  return
 if phase == "battle":
  energy -= 1
 match item.key:
  "bread": hp = mini(MAX_HP,hp+12)
  "steak": hp = mini(MAX_HP,hp+20)
  "potion": shield += 15
  "power": power = true
 message = "使用了%s。" % inventory.CATALOG[item.key].name
 inventory.items.remove_at(index)

func end_turn() -> void:
 if phase != "battle":
  return
 var damage: int = maxi(0,int(enemy.attack)-shield)
 shield = maxi(0,shield-int(enemy.attack))
 hp = maxi(0,hp-damage)
 message = "%s发动攻击，受到 %d 点伤害。" % [enemy.name,damage]
 if hp == 0:
  _discard_bag()
  phase = "defeat"
  message = "你已战败，将遗失背包所有物品。"
 else:
  turn += 1
  energy = 3

func flee() -> Dictionary:
 if phase != "ready":
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
 phase = "returned"
 message = "逃跑时遗失了%s。" % inventory.CATALOG[lost.key].name if not lost.is_empty() else "你安全返回了商车。"
 return lost

func _discard_bag() -> void:
 inventory.items = inventory.items.filter(func(i): return i.zone != "bag")
 clocks.clear()

func pickup(id: int, cell: Vector2i, rotated: bool) -> String:
 if phase != "victory":
  return "战斗结束后才能拾取。"
 return inventory.move_item(id,"bag",cell,rotated)

func leave() -> void:
 clear_loot()
 phase = "returned"

func cooldown(key: String) -> float:
 return 2.0 if key in WEAPON_KEYS else 5.0

func tick(delta: float) -> void:
 if phase != "battle":
  return
 elapsed += delta
 enemy_clock += delta
 basic_clock += delta
 var armed: Array[Dictionary] = inventory.items.filter(func(i): return i.zone == "bag" and i.key in WEAPON_KEYS and i.get("durability",20) > 0)
 if basic_clock >= 2.0:
  basic_clock = 0.0
  energy = 3
  if armed.is_empty():
   basic_attack()
  else:
   _auto_weapon_attack(armed[0])
 if phase == "battle" and enemy_clock >= 3.0:
  enemy_clock = 0.0
  end_turn()

func _auto_weapon_attack(item: Dictionary) -> void:
 if phase != "battle" or item.is_empty() or item.get("durability",20) <= 0:
  return
 item.durability = item.get("durability",20)-1
 attack(inventory.CATALOG[item.key].get("attack",8))
