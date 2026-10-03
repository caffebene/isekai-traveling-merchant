class_name TradeState
extends RefCounted

# counter remains as a legacy logical trade zone for state/API compatibility;
# its visible placement is free-form and is handled by shop.gd.
const SIZES = {"stock": Vector2i(30, 12), "display": Vector2i(10, 6), "customer": Vector2i(24, 4), "counter": Vector2i(43, 4), "loot": Vector2i(8, 4), "bag": Vector2i(6, 6)}
const Alchemy = preload("res://scripts/alchemy_rules.gd")
const Workbench = preload("res://scripts/workbench_rules.gd")
const Economy = preload("res://scripts/city_economy.gd")
# Retain the existing furnace item ID; its visible name and behavior are now workbench.
const MACHINES = ["pot", "alembic", "furnace"]
const CATALOG = {
 "wastewater": {"name":"废水","category":"杂物","value":1,"size":Vector2i(1,3),"color":"8c886d","desc":"未匹配配方的材料炼制成的废水。\n没有药效，无法在战斗中使用。"},
 "copper_ore": {"tags":["材料","矿石"], "name":"赤铜矿","category":"矿石","value":16,"size":Vector2i(2,2),"color":"bd815b","desc":"用于工作台锻造。"},
 "slime_mucus": {"tags":["材料","燃料"], "name":"史莱姆粘液","category":"燃料","value":10,"size":Vector2i(2,2),"color":"9fca75","desc":"史莱姆死亡后留下的粘液。\n锻造纯度 60% · 炼药产出 1瓶。"},
 "ancient_wood": {"tags":["材料","燃料"], "name":"古藤木","category":"燃料","value":28,"size":Vector2i(2,2),"color":"a77850","desc":"古木精身上脱落的硬木。\n锻造纯度 100% · 炼药产出 2瓶。"},
 "copper_sword": {"name":"赤铜剑","category":"武器","value":76,"size":Vector2i(2,6),"color":"c89067","attack":7,"base_durability":20,"desc":"攻击 7 · 耐久 20 / 20\n按图纸制作，燃料纯度决定最大耐久。"},
 "copper_axe": {"name":"赤铜斧","category":"武器","value":92,"size":Vector2i(3,5),"color":"c89067","attack":7,"base_durability":20,"desc":"攻击 7 · 耐久 20 / 20\n按图纸制作，燃料纯度决定最大耐久。"},
 "copper_pickaxe": {"name":"赤铜镐","category":"武器","value":108,"size":Vector2i(4,5),"color":"c89067","attack":7,"base_durability":20,"desc":"攻击 7 · 耐久 20 / 20\n按图纸制作，燃料纯度决定最大耐久。"},
 "iron_axe": {"name":"辉铁斧","category":"武器","value":156,"size":Vector2i(3,5),"color":"a2d7dc","attack":10,"base_durability":20,"desc":"攻击 10 · 耐久 20 / 20\n按图纸制作，燃料纯度决定最大耐久。"},
 "iron_pickaxe": {"name":"辉铁镐","category":"武器","value":188,"size":Vector2i(4,5),"color":"a2d7dc","attack":10,"base_durability":20,"desc":"攻击 10 · 耐久 20 / 20\n按图纸制作，燃料纯度决定最大耐久。"},
 "tempered_sword": {"name":"淬火剑","category":"武器","value":184,"size":Vector2i(2,6),"color":"e3ad77","attack":13,"base_durability":24,"desc":"攻击 13 · 耐久 24 / 24\n按图纸制作，燃料纯度决定最大耐久。"},
 "tempered_axe": {"name":"淬火斧","category":"武器","value":216,"size":Vector2i(3,5),"color":"e3ad77","attack":13,"base_durability":24,"desc":"攻击 13 · 耐久 24 / 24\n按图纸制作，燃料纯度决定最大耐久。"},
 "small_bag": {"name":"小背包", "category":"容器", "value":0, "size":Vector2i(3,4), "color":"a77c56", "desc":"旅商的随身背包。"},
 "pot": {"name":"烹饪锅", "category":"设备", "value":120, "size":Vector2i(3,3), "color":"b79a73", "desc":"点击展开内部空间。\n放入鲜兽肉，次日制成烤肉。"},
 "alembic": {"name":"炼药器", "category":"设备", "value":180, "size":Vector2i(3,4), "color":"89bdb0", "desc":"按配方放入材料和燃料，隔天炼制药水。\n只看材料种类与数量，不要求摆放位置。"},
 "furnace": {"name":"工作台", "category":"设备", "value":240, "size":Vector2i(4,4), "color":"bd8964", "desc":"打开工作台，按配方摆放矿石与燃料。\n隔天生成装备；燃料决定纯度与耐久。"},
 "iron_sword": {"name":"辉铁剑", "attack":10, "base_durability":20, "category":"武器", "value":140, "size":Vector2i(2,6), "color":"a2d7dc", "desc":"攻击 10 · 耐久 20 / 20\n辉铁打造的剑，可在工作台制作。"},
 "herb": {"tags":["材料","药材"], "name": "月光草", "category": "材料", "value": 18, "size": Vector2i(2,3), "color": "98bfad", "desc": "在月色中生长的草药。\n可投入炼药器，按配方炼制药剂。"},
 "moonheart": {"tags":["材料"], "name":"月蚀树心", "category":"材料", "value":80, "size":Vector2i(2,2), "color":"a6bfd2", "desc":"古树深处封存的月纹树心。\n希尔薇正在寻找它。"},
 "berry": {"tags":["材料","药材"], "name": "绯红果", "category": "材料", "value": 12, "size": Vector2i(1,1), "color": "d98683", "desc": "风栖镇郊外采摘的甜果。\n可烹饪，也可直接出售。"},
 "meat": {"tags":["材料","食物"], "heal":8, "name": "鲜兽肉", "category": "材料", "value": 24, "size": Vector2i(3,2), "color": "ce927e", "desc": "可直接食用恢复生命，也可烹饪为烤肉。"},
 "bread": {"heal":12, "name": "蜜糖面包", "category": "食物", "value": 26, "size": Vector2i(3,2), "color": "dfb779", "desc": "松软的旅行口粮。\n战斗中消耗：恢复 12 点生命。"},
 "steak": {"heal":20, "name": "香草烤肉", "category": "食物", "value": 40, "size": Vector2i(3,2), "color": "c8946c", "desc": "烤得恰到好处的肉排。\n战斗中消耗：恢复 20 点生命。"},
 "ore": {"tags":["材料","矿石"], "name": "辉铁矿", "category": "矿石", "value": 32, "size": Vector2i(2,2), "color": "a6bfd2", "desc": "带着蓝色晶纹的铁矿。\n放入工作台，按图纸打造辉铁装备。"},
 "sword": {"name": "旅人长剑", "category": "武器", "value": 96, "size": Vector2i(2,6), "color": "c1d3d7", "desc": "攻击 8  ·  耐久 20 / 20\n每次攻击消耗 1 点耐久。"},
 "potion": {"name": "防护药剂", "category": "药剂", "value": 45, "size": Vector2i(1,3), "color": "81bdc0", "desc": "封存着森林的守护之力。\n战斗中消耗：获得 15 点护盾。"},
 "power": {"name": "力量药剂", "category": "药剂", "value": 56, "size": Vector2i(1,3), "color": "b698cc", "desc": "散发着微弱的紫色光芒。\n本场战斗攻击力 +20%。"}
}
# Rows describe occupied cells inside the unchanged artwork bounds.
const FOOTPRINTS = {
 "copper_pickaxe":["1111","0110","0110","0110","0110"],
 "iron_pickaxe":["1111","0110","0110","0110","0110"],
 "copper_axe":["111","111","011","010","010"],
 "iron_axe":["111","111","011","010","010"],
 "tempered_axe":["111","111","011","010","010"],
}
const Quality = preload("res://scripts/weapon_quality.gd")
var quality_rng := RandomNumberGenerator.new()
var forest_memory: Dictionary = {}
var story_progress := {"stage":"none","hunter_saved":false}
var selected_companion := ""
var customer_memory: Dictionary = {}
const CustomerRoster = preload("res://scripts/customer_roster.gd")
const ForestStory = preload("res://scripts/forest_story.gd")
var items: Array[Dictionary] = []
var bag_size: Vector2i = SIZES.bag
var gold := 387
var day := 1
var completed := 0
var earnings := 0
var serial := 0
var round_index := 0
var patience := 3
var offer := 0
var buy_offer := 0
var sell_offer := 0
var active_trade_tab := "buy"
var last_reaction := ""
var customer_buy_category := "材料"
var customer_sell_key := "herb"
var customer_funds_limit := 150
var customer_funds := 150
var customer_goods: Array[String] = ["herb","berry","potion","ore"]
var loaded_day: Dictionary = {}
var economy = Economy.new()
var current_customer_name := ""

func _init() -> void:
 quality_rng.randomize()
 for key in ["sword","herb","herb","bread","ore","potion","potion","power","berry","berry","meat","steak","ore","bread"]:
  add_item(key, "stock", "player")
 for key in ["potion","bread","power"]:
  add_item(key, "stock", "player")
 for key in MACHINES:
  add_item(key,"stock","player")
 add_item("small_bag","stock","player")
 for key in ["copper_ore","copper_ore","copper_ore","slime_mucus"]:
  add_item(key,"stock","player")
 restock_customer()

func dimensions(item: Dictionary) -> Vector2i:
 var d: Vector2i = CATALOG[item.key].size
 return Vector2i(d.y,d.x) if item.rotated else d

static func footprint(item: Dictionary) -> Array[Vector2i]:
 var bounds: Vector2i = CATALOG[item.key].size
 var cells: Array[Vector2i] = []
 var mask: Array = FOOTPRINTS.get(item.key,[])
 for y in range(bounds.y):
  for x in range(bounds.x):
   if mask.is_empty() or mask[y][x] == "1":
    cells.append(Vector2i(bounds.y-1-y,x) if item.rotated else Vector2i(x,y))
 return cells

static func occupied_cells(item: Dictionary, at: Vector2i) -> Array[Vector2i]:
 var cells := footprint(item)
 for index in range(cells.size()):
  cells[index] += at
 return cells

func fits(item: Dictionary, zone: String, at: Vector2i, ignore_id: int = -1) -> bool:
 var d := dimensions(item)
 var bounds: Vector2i = zone_size(zone)
 if at.x < 0 or at.y < 0 or at.x+d.x > bounds.x or at.y+d.y > bounds.y:
  return false
 var occupied := {}
 for cell in occupied_cells(item,at):
  occupied[cell] = true
 for other in items:
  if other.id == ignore_id or other.zone != zone:
   continue
  for cell in occupied_cells(other,other.cell):
   if occupied.has(cell):
    return false
 return true

func free_cell(item: Dictionary, zone: String) -> Vector2i:
 for y in range(zone_size(zone).y):
  for x in range(zone_size(zone).x):
   if fits(item,zone,Vector2i(x,y),item.id):
    return Vector2i(x,y)
 return Vector2i(-1,-1)

func add_item(key: String, zone: String, owner: String, source := "", quality := -1) -> bool:
 var item := {
  "id":serial,
  "key":key,
  "zone":zone,
  "owner":owner,
  "rotated":false,
  "cell":Vector2i.ZERO,
  "origin":{},
  "settled":false,
  "trade_rejected":false,
  # Counter items are rendered and simulated in screen space by shop.gd.
  # Keeping these fields in the state means the trade model remains the
  # source of truth when an item is moved back to a grid or settled.
  "counter_position":Vector2(-1,-1),
  "counter_angle":0.0,
  "counter_velocity":Vector2.ZERO,
  "counter_angular_velocity":0.0,
  "counter_sleeping":false,
 }
 var at := free_cell(item,zone)
 if at.x < 0 and item_size_is_rectangular(key):
  # Customer and loot areas are only four cells tall; auto-pack long items sideways.
  item.rotated = true
  at = free_cell(item,zone)
 if at.x < 0:
  return false
 if CATALOG[key].category == "武器":
  item.quality = clampi(quality,0,4) if quality >= 0 else Quality.roll_quality(source if source != "" else zone,quality_rng)
  item.affixes = Quality.roll_affixes(item.quality,quality_rng)
  item.max_durability = Quality.durability(item,CATALOG[key].get("base_durability",20))
  item.durability = item.max_durability
 item.cell = at
 serial += 1
 items.append(item)
 return true

func item_size_is_rectangular(key: String) -> bool:
 var size: Vector2i = CATALOG[key].size
 return size.x != size.y

func counter_items() -> Array[Dictionary]:
 return items.filter(func(i): return i.zone == "counter")

func buying_items() -> Array[Dictionary]:
 return items.filter(func(i): return i.zone == "counter" and i.owner == "customer" and not i.get("settled",false) and not i.get("trade_rejected",false))

func selling_items() -> Array[Dictionary]:
 return items.filter(func(i): return i.zone == "counter" and i.owner == "player" and not i.get("settled",false) and not i.get("trade_rejected",false))

func settled_counter_items() -> Array[Dictionary]:
 return items.filter(func(i): return i.zone == "counter" and i.get("settled",false))

func has_pending_trade() -> bool:
 return not buying_items().is_empty() or not selling_items().is_empty()

func buying() -> bool:
 return not buying_items().is_empty()

func selling() -> bool:
 return not selling_items().is_empty()

func customer_wants(item: Dictionary) -> bool:
 return customer_buy_category != "" and CATALOG[item.key].category == customer_buy_category

func customer_will_sell(item: Dictionary) -> bool:
 return (customer_sell_key == "*" and customer_goods.has(item.key)) or (customer_sell_key != "" and item.key == customer_sell_key)

func customer_reaction(item: Dictionary) -> String:
 var value: int = item_market_value(item)
 var multiplier := market_multiplier(item.key)
 if multiplier >= 1.35:
  return "顾客眼睛一亮：眼下正缺这个。"
 if value >= 45:
  return "顾客眼睛一亮：我很喜欢这个。"
 if value >= 25:
  return "顾客点头：这个正合我意。"
 return "顾客有点兴趣：这个可以看看。"

func total_value() -> int:
 var value := 0
 for item in buying_items()+selling_items():
  value += item_market_value(item)
 return value

func buying_value() -> int:
 var value := 0
 for item in buying_items():
  value += item_market_value(item)
 return value

func selling_value() -> int:
 var value := 0
 for item in selling_items():
  value += item_market_value(item)
 return value

func market_multiplier(key: String) -> float:
 var data: Dictionary = CATALOG[key]
 return economy.multiplier(key,data.category,day)

func market_value(key: String) -> int:
 var data: Dictionary = CATALOG[key]
 return economy.value(key,data.category,data.value,day)

func item_market_value(item: Dictionary) -> int:
 var data: Dictionary = CATALOG[item.key]
 var multiplier: float = Quality.PRICES[Quality.tier(item)] if data.category == "武器" else 1.0
 return maxi(1,roundi(float(data.value)*multiplier*market_multiplier(item.key)))

func market_report() -> String:
 return economy.market_report(CATALOG,day)

func bag_adjacent(a: Dictionary, b: Dictionary) -> bool:
 if a.get("zone","") != "bag" or b.get("zone","") != "bag":
  return false
 var occupied := {}
 for cell in occupied_cells(a,a.cell):
  occupied[cell] = true
 for cell in occupied_cells(b,b.cell):
  for direction in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
   if occupied.has(cell+direction):
    return true
 return false

const FUEL_INTERVAL_REDUCTION = {"slime_mucus":10,"ancient_wood":20}

static func bag_interval_reduction(item: Dictionary) -> int:
 return int(FUEL_INTERVAL_REDUCTION.get(item.key,0))

static func bag_support_bonus(item: Dictionary) -> int:
 return 3 if CATALOG[item.key].category == "矿石" else 2 if item.key == "power" else 0

func bag_bonus_cells(item: Dictionary, at: Vector2i) -> Array[Vector2i]:
 var result: Array[Vector2i] = []
 if bag_support_bonus(item) == 0 and bag_interval_reduction(item) == 0:
  return result
 var occupied := occupied_cells(item,at)
 var bounds := zone_size("bag")
 for cell in occupied:
  for direction in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
   var neighbor: Vector2i = cell+direction
   if neighbor.x >= 0 and neighbor.y >= 0 and neighbor.x < bounds.x and neighbor.y < bounds.y and not occupied.has(neighbor) and not result.has(neighbor):
    result.append(neighbor)
 return result

func bag_adjacent_items(item: Dictionary) -> Array[Dictionary]:
 return items.filter(func(other): return other.zone == "bag" and other.id != item.id and bag_adjacent(item,other))

func protected_bag_ids() -> Array[int]:
 var result: Array[int] = []
 if not economy.has_module("hidden_compartment"):
  return result
 var candidates: Array[Dictionary] = items.filter(func(i): return i.zone == "bag")
 candidates.sort_custom(func(a,b): return item_market_value(a) > item_market_value(b))
 for index in range(mini(2,candidates.size())):
  result.append(candidates[index].id)
 return result

func bag_effects(item: Dictionary) -> Dictionary:
 var neighbors := bag_adjacent_items(item)
 var ore_count := neighbors.filter(func(i): return CATALOG[i.key].category == "矿石").size()
 var power_count := neighbors.filter(func(i): return i.key == "power").size()
 var adjacent_weapons := neighbors.filter(func(i): return CATALOG[i.key].category == "武器").size()
 var base_attack: int = int(CATALOG[item.key].get("attack",8 if CATALOG[item.key].category == "武器" else 0))
 var damage_bonus: int = ore_count*3 + power_count*2 if CATALOG[item.key].category == "武器" else 0
 var base_heal: int = int(CATALOG[item.key].get("heal",0))
 var interval_multiplier := 1.0
 if CATALOG[item.key].category == "武器":
  for neighbor in neighbors:
   interval_multiplier *= 1.0-bag_interval_reduction(neighbor)/100.0
 return {
  "damage_bonus":damage_bonus,
  "final_attack":roundi(base_attack*(1.0+Quality.bonus(item,"sharp")/100.0))+damage_bonus,
  "attack_interval":2.0*interval_multiplier/(1.0+Quality.bonus(item,"swift")/100.0),
  "critical_chance":Quality.bonus(item,"critical")/100.0,
  "leech_ratio":Quality.bonus(item,"leech")/100.0,
  "free_use":item.zone == "bag" and item.cell.x < 2 and (base_heal > 0 or item.key in ["potion","power"]),
  "adjacent_weapons":adjacent_weapons,
  "support_bonus":bag_support_bonus(item),
  "protected":protected_bag_ids().has(item.id),
  "final_heal":base_heal+(8 if base_heal > 0 and economy.has_module("field_kitchen") else 0),
  "base_heal":base_heal,
 }

func bag_effect_text(item: Dictionary) -> String:
 if item.get("zone","") != "bag":
  return ""
 var effects := bag_effects(item)
 var lines: Array[String] = []
 if CATALOG[item.key].category == "武器":
  var base_attack: int = roundi(int(CATALOG[item.key].get("attack",8))*(1.0+Quality.bonus(item,"sharp")/100.0))
  lines.append("当前布局：攻击 %d → %d · 间隔 %.2f 秒" % [base_attack,effects.final_attack,effects.attack_interval])
 elif int(effects.adjacent_weapons) > 0 and int(effects.support_bonus) > 0:
  lines.append("已连接 %d 把武器：每把攻击 +%d" % [effects.adjacent_weapons,effects.support_bonus])
 if effects.free_use:
  lines.append("腰包生效：战斗中使用不消耗行动力")
 if int(effects.base_heal) > 0:
  lines.append("实际恢复：%d → %d 生命" % [effects.base_heal,effects.final_heal])
 if effects.protected:
  lines.append("隐藏夹层：战败时保留")
 return "\n".join(lines)

func refresh_offer() -> void:
 buy_offer = roundi(buying_value() * 1.12)
 sell_offer = roundi(selling_value() * 0.86)
 sell_offer = mini(sell_offer,customer_funds + buy_offer)
 if buying() and not selling():
  active_trade_tab = "buy"
 elif selling() and not buying():
  active_trade_tab = "sell"
 if active_trade_tab == "buy":
  offer = buy_offer
 else:
  offer = sell_offer

func select_trade_tab(tab: String) -> void:
 if tab == "buy" and buying():
  active_trade_tab = "buy"
 elif tab == "sell" and selling():
  active_trade_tab = "sell"
 refresh_offer()

func configure_customer(buy_category: String, sell_key: String, goods: Array, funds := 150, customer_name := "") -> void:
 customer_buy_category = buy_category
 customer_sell_key = sell_key
 customer_funds_limit = clampi(int(funds),100,200)
 customer_funds = customer_funds_limit
 customer_goods.clear()
 current_customer_name = customer_name
 for key in goods:
  customer_goods.append(str(key))
 active_trade_tab = "buy" if customer_buy_category != "" else "sell"
 restock_customer(customer_goods.duplicate(),true)

func move_item(id: int, zone: String, cell: Vector2i, rotated: bool) -> String:
 last_reaction = ""
 var index := items.find_custom(func(i): return i.id == id)
 if index < 0:
  return "物品不存在"
 var item: Dictionary = items[index]
 var error := placement_error(item,zone)
 if error != "":
  return error
 if item.owner == "customer" and zone not in ["customer","counter"]:
  return "请先将商品放到柜台，完成购买后再入库。"
 if item.owner == "player" and zone == "customer":
  return "将商品放在交易柜台，即可向顾客出售。"
 var old_rotation: bool = item.rotated
 item.rotated = rotated
 if not fits(item,zone,cell,id):
  item.rotated = old_rotation
  return "这里空间不足，请旋转物品或换一个位置。"
 if item.zone != "counter" and zone == "counter":
  item.origin = {"zone":item.zone,"cell":item.cell,"rotated":old_rotation}
 var previous_zone: String = item.zone
 item.zone = zone
 item.cell = cell
 var entering_counter := previous_zone != "counter" and zone == "counter"
 if entering_counter:
  item.trade_rejected = (item.owner == "player" and not customer_wants(item)) or (item.owner == "customer" and not customer_will_sell(item))
  if item.trade_rejected:
   last_reaction = "我没有意愿买这个。" if item.owner == "player" else "这件商品暂时不出售。"
 elif previous_zone == "counter" and zone != "counter":
  item.trade_rejected = false
 if previous_zone == "counter" and zone != "counter" and item.get("settled",false):
  item.settled = false
 if zone != "counter":
  _clear_counter_physics(item)
 if zone.begins_with("machine_") and previous_zone != zone:
  loaded_day[item.id] = day
 if zone != "counter":
  item.origin = {}
 refresh_offer()
 if entering_counter and not item.trade_rejected and item.owner == "player":
  last_reaction = customer_reaction(item)
 return ""

# Counter placement intentionally has no grid/cell collision. The UI supplies
# a screen-space drop point and the visual layer resolves gravity and stacking.
# The regular move_item() API remains grid-compatible for existing state tests
# and non-UI callers.
func move_item_to_counter(id: int, position: Vector2, rotated: bool) -> String:
 last_reaction = ""
 var index := items.find_custom(func(i): return i.id == id)
 if index < 0:
  return "物品不存在"
 var item: Dictionary = items[index]
 var error := placement_error(item,"counter")
 if error != "":
  return error
 if item.owner == "customer" and item.zone not in ["customer","counter"]:
  return "请先将商品放到柜台，完成购买后再入库。"
 if item.owner == "player" and item.zone == "customer":
  return "将商品放在交易柜台，即可向顾客出售。"
 var old_rotation: bool = item.rotated
 var previous_zone: String = item.zone
 item.rotated = rotated
 if previous_zone != "counter":
  item.origin = {"zone":item.zone,"cell":item.cell,"rotated":old_rotation}
 item.zone = "counter"
 # Keep a valid legacy cell for save/test callers without using it for UI
 # placement. A free cell is best-effort because the counter is now free-form.
 var legacy_cell := free_cell(item,"counter")
 item.cell = legacy_cell if legacy_cell.x >= 0 else Vector2i.ZERO
 item.counter_position = position
 item.counter_angle = 0.0
 item.counter_velocity = Vector2.ZERO
 item.counter_angular_velocity = 0.0
 item.counter_sleeping = false
 if previous_zone != "counter":
  item.trade_rejected = (item.owner == "player" and not customer_wants(item)) or (item.owner == "customer" and not customer_will_sell(item))
  if item.trade_rejected:
   last_reaction = "我没有意愿买这个。" if item.owner == "player" else "这件商品暂时不出售。"
 if previous_zone == "counter" and item.get("settled",false):
  item.settled = false
 if not item.trade_rejected and item.owner == "player" and previous_zone != "counter":
  last_reaction = customer_reaction(item)
 refresh_offer()
 return ""

func _clear_counter_physics(item: Dictionary) -> void:
 item.counter_position = Vector2(-1,-1)
 item.counter_angle = 0.0
 item.counter_velocity = Vector2.ZERO
 item.counter_angular_velocity = 0.0
 item.counter_sleeping = false

func cancel_trade() -> void:
 for item in counter_items():
  if item.get("settled",false):
   continue
  var origin: Dictionary = item.origin
  item.rotated = origin.get("rotated",false)
  var zone: String = origin.get("zone","stock" if item.owner == "player" else "customer")
  var cell: Vector2i = origin.get("cell",Vector2i.ZERO)
  if not fits(item,zone,cell,item.id):
   cell = free_cell(item,zone)
  if cell.x < 0 and item.owner == "player":
   zone = "display" if zone == "stock" else "stock"
   cell = free_cell(item,zone)
  if cell.x >= 0:
   item.zone = zone
   item.cell = cell
   item.origin = {}
   _clear_counter_physics(item)
 refresh_offer()

func negotiate(price: int) -> String:
 if not has_pending_trade():
  return "先将物品放到柜台上吧。"
 if patience <= 0:
  return "这是我的最终报价啦。"
 var fair := buying_value() if active_trade_tab == "buy" else selling_value()
 if fair <= 0:
  return "这个标签页还没有待结算商品。"
 var accepted := price >= ceili(fair * 0.94) if active_trade_tab == "buy" else price <= floori(fair * 1.10) and price <= customer_funds + buy_offer
 if active_trade_tab == "sell" and price > customer_funds + buy_offer:
  return "我的资金上限是 %d G。" % customer_funds
 if accepted and price > 0:
  if active_trade_tab == "buy":
   buy_offer = price
  else:
   sell_offer = price
  offer = price
  return "这个价格可以，成交吧。"
 patience -= 1
 return "这个价格有些为难……再考虑一下？" if patience > 0 else "这是我最后能接受的价格了。"

func settle() -> String:
 var buying_batch := buying_items()
 var selling_batch := selling_items()
 if buying_batch.is_empty() and selling_batch.is_empty():
  return "柜台上还没有商品。"
 if gold < buy_offer:
  return "金币不足，无法买入。"
 if customer_funds + buy_offer < sell_offer:
  return "顾客的资金不足，最多还能支付 %d G。" % (customer_funds + buy_offer)
 var customer_placements: Array[Dictionary] = []
 var reserved: Array[Vector2i] = []
 for item in selling_batch:
  var placement := _customer_sale_placement(item,reserved)
  if placement.is_empty():
   return "顾客格子空间不足，暂时无法接收这些商品。"
  customer_placements.append(placement)
  reserved.append_array(placement.cells)
 ForestStory.sold(self,current_customer_name,selling_batch)
 CustomerRoster.completed(self,current_customer_name,selling_batch,buying_batch)
 _record_purchase_prices(buying_batch)
 for i in range(selling_batch.size()):
  var item: Dictionary = selling_batch[i]
  item.zone = "customer"
  item.cell = customer_placements[i].rect.position
  item.rotated = customer_placements[i].rotated
  item.owner = "customer"
  item.origin = {}
  item.settled = true
  economy.record_sale(str(CATALOG[item.key].category))
 for item in buying_batch:
  item.owner = "player"
  item.origin = {}
  item.settled = true
 gold -= buy_offer
 gold += sell_offer
 customer_funds = clampi(customer_funds - sell_offer + buy_offer,0,customer_funds_limit)
 earnings += sell_offer - buy_offer
 completed += 1
 economy.record_trade(current_customer_name)
 patience = 3
 buy_offer = 0
 sell_offer = 0
 offer = 0
 active_trade_tab = "buy"
 return "交易完成，期待下次与你相遇。"

func _customer_sale_placement(item: Dictionary, reserved: Array[Vector2i]) -> Dictionary:
 # Plan all packing before mutating goods or money. Long crafted equipment
 # needs rotation to fit the customer's four-row inventory.
 var probe := item.duplicate()
 for rotation in [bool(item.rotated),not bool(item.rotated)]:
  probe.rotated = rotation
  for y in range(SIZES.customer.y):
   for x in range(SIZES.customer.x):
    var cell := Vector2i(x,y)
    if not fits(probe,"customer",cell,probe.id):
     continue
    var rect := Rect2i(cell,dimensions(probe))
    var cells := occupied_cells(probe,cell)
    if cells.any(func(occupied): return reserved.has(occupied)):
     continue
    return {"rect":rect,"rotated":rotation,"cells":cells}
 return {}

func restock_customer(goods: Array = [], force_goods := false) -> void:
 cancel_trade()
 items = items.filter(func(i): return i.owner != "customer")
 if force_goods:
  customer_goods.clear()
  for key in goods:
   customer_goods.append(str(key))
 var spawn_goods: Array = customer_goods
 for key in spawn_goods:
  add_item(key,"customer","customer")
 patience = 3
 round_index += 1

func zone_size(zone: String) -> Vector2i:
 if zone == "bag":
  return bag_size
 if zone.begins_with("machine_"):
  var parts := zone.split("_")
  var id := int(parts[1])
  var index := items.find_custom(func(i): return i.id == id and i.key == "furnace")
  if index >= 0:
   return Vector2i(8,8) if parts.size() == 2 else Vector2i(4,8)
  var alchemy_index := items.find_custom(func(i): return i.id == id and i.key == "alembic")
  if alchemy_index >= 0:
   if zone == machine_fuel_zone(id):
    return Vector2i(12,2)
   return Vector2i(8,8) if parts.size() == 2 else Vector2i(4,8) if zone == machine_output_zone(id) else Vector2i.ZERO
  return Vector2i(8,5)
 return SIZES.get(zone,Vector2i.ZERO)

func machine_zone(id: int) -> String:
 return "machine_%d" % id

func machine_fuel_zone(id: int) -> String:
 return "machine_%d_fuel" % id

func machine_output_zone(id: int) -> String:
 return "machine_%d_output" % id

func machine_zones(id: int) -> Array[String]:
 var index := items.find_custom(func(i): return i.id == id and i.key == "furnace")
 if index >= 0:
  return [machine_zone(id),machine_fuel_zone(id),machine_output_zone(id)]
 var alchemy_index := items.find_custom(func(i): return i.id == id and i.key == "alembic")
 if alchemy_index >= 0:
  return [machine_zone(id),machine_output_zone(id),machine_fuel_zone(id)]
 return [machine_zone(id)]

func alchemy_preview(id: int) -> Dictionary:
 return Alchemy.evaluate(self,id)

func workbench_preview(id: int) -> Dictionary:
 return Workbench.evaluate(self,id)

func item_description(item: Dictionary) -> String:
 var data: Dictionary = CATALOG[item.key]
 if data.category != "武器":
  return data.desc
 var detail := "攻击 %d · 耐久 %d / %d" % [bag_effects(item).final_attack,item.get("durability",20),item.get("max_durability",data.get("base_durability",20))]
 if item.has("purity"):
  detail += " · 纯度 %d%%" % item.purity
 return detail+"\n"+str(data.desc).get_slice("\n",1)

func _record_purchase_prices(batch: Array[Dictionary]) -> void:
 # Allocate the negotiated batch cost by current item value, to whole gold.
 # The largest remainders receive leftover gold; ties follow item identity.
 if batch.is_empty():
  return
 var total_weight := 0
 for item in batch:
  total_weight += maxi(1,item_market_value(item))
 var allocations: Array[Dictionary] = []
 var allocated := 0
 for item in batch:
  var numerator: int = buy_offer*maxi(1,item_market_value(item))
  var gold_share := floori(float(numerator)/total_weight)
  allocations.append({"item":item,"gold_share":gold_share,"remainder":numerator % total_weight})
  allocated += gold_share
 allocations.sort_custom(func(a,b): return a.remainder > b.remainder if a.remainder != b.remainder else a.item.id < b.item.id)
 for n in range(buy_offer-allocated):
  allocations[n].gold_share += 1
 for entry in allocations:
  entry.item.purchase_price = int(entry.gold_share)

func item_card_data(item: Dictionary) -> Dictionary:
 var data: Dictionary = CATALOG[item.key]
 var effects := bag_effects(item)
 var display_category: String = "背包" if item.key == "small_bag" else str(data.category)
 var stats: Array[Dictionary] = []
 if data.category == "武器":
  stats.append({"label":"品质","value":Quality.NAMES[Quality.tier(item)]+"色"})
  stats.append({"label":"攻击","value":str(effects.final_attack)})
  stats.append({"label":"耐久","value":"%d / %d" % [item.get("durability",20),item.get("max_durability",data.get("base_durability",20))]})
  stats.append({"label":"攻击间隔","value":"%.2f 秒" % effects.attack_interval})
  if item.has("purity"):
   stats.append({"label":"锻造纯度","value":"%d%%" % item.purity})
  for affix in item.get("affixes",[]):
   stats.append({"label":Quality.AFFIXES[affix.key].name,"value":Quality.affix_text(affix)})
 elif int(effects.base_heal) > 0:
  stats.append({"label":"生命恢复","value":str(effects.final_heal)})
 elif item.key == "potion":
  stats.append({"label":"护盾","value":"15"})
 elif item.key == "power":
  stats.append({"label":"攻击增幅","value":"20%"})
 elif item.key in ["slime_mucus","ancient_wood"]:
  stats.append({"label":"锻造纯度","value":"60%" if item.key == "slime_mucus" else "100%"})
  stats.append({"label":"炼药产出","value":"1 瓶" if item.key == "slime_mucus" else "2 瓶"})
 if bag_support_bonus(item) > 0:
  stats.append({"label":"相邻武器攻击","value":"+%d" % bag_support_bonus(item)})
 if bag_interval_reduction(item) > 0:
  stats.append({"label":"相邻武器攻击间隔","value":"-%d%%" % bag_interval_reduction(item)})
 if item.get("zone","") == "bag":
  if effects.free_use:
   stats.append({"label":"行动力消耗","value":"0 · 腰包"})
  if effects.protected:
   stats.append({"label":"夹层保护","value":"战败保留"})
 var description: String = data.desc
 if data.category == "武器":
  description = description.get_slice("\n",1)
 return {"quality":Quality.tier(item) if data.category == "武器" else -1,"name":data.name,"category":display_category,"quantity":maxi(1,int(item.get("quantity",1))),
  "market_price":item_market_value(item),"purchase_price":item.get("purchase_price",null),
  "description":description,"tags":Array(data.get("tags",[display_category])).duplicate(),"stats":stats}

func item_hover_details(item: Dictionary, action_hint := "") -> String:
 var data: Dictionary = CATALOG[item.key]
 var details := [
  ("未拥有" if item.owner == "customer" else "已拥有")+"  /  "+str(data.category),
  "本地行情 %d G（基础估值 %d G）" % [item_market_value(item),data.value],
  item_description(item),
 ]
 if action_hint == "":
  action_hint = "双击展开 · 拖动原料" if MACHINES.has(item.key) else "拖动放置 · 双击移入 / 移出柜台"
 details.append(action_hint)
 var layout_effect := bag_effect_text(item)
 if layout_effect != "":
  details.append(layout_effect)
 return "\n".join(details)

func placement_error(item: Dictionary, zone: String) -> String:
 if zone == "bag" and item.key == "small_bag":
  return "背包不能放进自己内部。"
 if zone == "bag" and item.owner != "player":
  return "只有自己的物品可以放入背包。"
 if MACHINES.has(item.key):
  if zone not in ["stock","display"]:
   return "设备只能放在自己的格子内。"
 if zone.begins_with("machine_"):
  var id := int(zone.split("_")[1])
  var device_index := items.find_custom(func(i): return i.id == id and MACHINES.has(i.key))
  if device_index < 0:
   return "设备不存在。"
  if items[device_index].key == "alembic":
   if item.owner != "player":
    return "只有自己的材料可以放入炼药器。"
   if zone == machine_output_zone(id):
    return "产出区只能领取成品。"
   if zone == machine_fuel_zone(id):
    if not Alchemy.FUEL_YIELDS.has(item.key):
     return "燃料区只能放入燃料。"
    for other in items:
     if other.zone == zone and other.id != item.id and other.key != item.key:
      return "燃料区只可放一种燃料。"
    return ""
   if zone != machine_zone(id) or CATALOG[item.key].category != "材料":
    return "炼药器只能放入材料类物品。"
   return ""
  if items[device_index].key == "furnace":
   if item.owner != "player":
    return "只有自己的物品可以放入工作台。"
   if zone == machine_output_zone(id):
    return "产出区只能领取成品。"
   if zone == machine_fuel_zone(id):
    if not Workbench.FUELS.has(item.key):
     return "燃料区只能放入燃料。"
    for other in items:
     if other.zone == zone and other.id != item.id and other.key != item.key:
      return "燃料区只可放一种燃料，请先取出原燃料。"
    return ""
   if zone != machine_zone(id) or not Workbench.ORES.has(item.key):
    return "材料区只能放入配方矿石。"
   return ""
  if zone == item.zone:
   return ""
  var accepted: Array = {"pot":["meat"]}[items[device_index].key]
  if item.owner != "player" or not accepted.has(item.key):
   return "该设备无法加工这件物品。"
 return ""

func advance_day() -> void:
 cancel_trade()
 day += 1
 economy.advance_day()
 for device in items.duplicate():
  if not MACHINES.has(device.key):
   continue
  var zone := machine_zone(device.id)
  var inputs: Array[Dictionary] = items.filter(func(i): return i.zone == zone and loaded_day.get(i.id,day) < day)
  if device.key in ["furnace","alembic"]:
   var plan: Dictionary = workbench_preview(device.id) if device.key == "furnace" else alchemy_preview(device.id)
   if not plan.ready:
    continue
   # Stage the complete batch before consuming any ingredients or fuel.
   var produced_ids: Array[int] = []
   for n in range(plan.get("quantity",1)):
    if not add_item(plan.output,machine_output_zone(device.id),"player",plan.get("fuel_key","") if device.key == "furnace" else ""):
     break
    var product: Dictionary = items.back()
    produced_ids.append(product.id)
    if device.key == "furnace":
     product.purity = plan.purity
     product.max_durability = Quality.durability(product,plan.max_durability)
     product.durability = product.max_durability
   if produced_ids.size() != plan.get("quantity",1):
    items = items.filter(func(i): return not produced_ids.has(i.id))
    continue
   var consumed: Array = plan.inputs.duplicate()
   consumed.append(plan.fuel_id)
   items = items.filter(func(i): return not consumed.has(i.id))
   for consumed_id in consumed:
    loaded_day.erase(consumed_id)
  else:
   for item in inputs:
    if item.key != "meat":
     continue
    # Cooking preserves its footprint, including rotation.
    item.key = "steak"
    loaded_day.erase(item.id)
 completed = 0
 earnings = 0
 restock_customer()

func can_travel() -> bool:
 return economy.can_travel(day)

func travel_to_next_city() -> String:
 if not can_travel():
  return "商路只在每个周期第 7 天开放。"
 if gold < Economy.TRAVEL_COST:
  return "前往下一座城市需要 %d G 路费。" % Economy.TRAVEL_COST
 gold -= Economy.TRAVEL_COST
 economy.travel()
 advance_day()
 return "已抵达%s。" % economy.city_name()

func install_module(module_id: String) -> String:
 var cost := economy.module_cost(module_id)
 if economy.has_module(module_id):
  return "该模块已经安装。"
 if economy.modules.size() >= 2:
  return "商车最多安装两个模块。"
 if gold < cost:
  return "金币不足，需要 %d G。" % cost
 gold -= cost
 economy.install_module(module_id)
 if module_id == "roof_rack":
  bag_size = Vector2i(8,6)
 return "已安装%s。" % economy.module_name(module_id)
