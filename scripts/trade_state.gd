class_name TradeState
extends RefCounted

# counter remains as a legacy logical trade zone for state/API compatibility;
# its visible placement is free-form and is handled by shop.gd.
const SIZES = {"stock": Vector2i(30, 12), "display": Vector2i(10, 6), "customer": Vector2i(24, 4), "counter": Vector2i(43, 4), "loot": Vector2i(8, 4), "bag": Vector2i(6, 6)}
const Alchemy = preload("res://scripts/alchemy_rules.gd")
const Workbench = preload("res://scripts/workbench_rules.gd")
# Retain the existing furnace item ID; its visible name and behavior are now workbench.
const MACHINES = ["pot", "alembic", "furnace"]
const CATALOG = {
 "wastewater": {"name":"废水","category":"杂物","value":1,"size":Vector2i(1,3),"color":"8c886d","desc":"未匹配配方的材料炼制成的废水。\n没有药效，无法在战斗中使用。"},
 "copper_ore": {"name":"赤铜矿","category":"矿石","value":16,"size":Vector2i(2,2),"color":"bd815b","desc":"用于工作台配方，每件占2×2格。"},
 "slime_mucus": {"name":"史莱姆粘液","category":"燃料","value":10,"size":Vector2i(2,2),"color":"9fca75","desc":"史莱姆死亡后留下的粘液。\n锻造纯度 60% · 炼药产出 1瓶。"},
 "ancient_wood": {"name":"古藤木","category":"燃料","value":28,"size":Vector2i(2,2),"color":"a77850","desc":"古木精身上脱落的硬木。\n锻造纯度 100% · 炼药产出 2瓶。"},
 "copper_sword": {"name":"赤铜剑","category":"武器","value":76,"size":Vector2i(2,6),"color":"c89067","attack":7,"base_durability":20,"desc":"攻击 7 · 耐久 20 / 20\n按图纸制作，燃料纯度决定最大耐久。"},
 "copper_axe": {"name":"赤铜斧","category":"武器","value":92,"size":Vector2i(3,5),"color":"c89067","attack":7,"base_durability":20,"desc":"攻击 7 · 耐久 20 / 20\n按图纸制作，燃料纯度决定最大耐久。"},
 "copper_pickaxe": {"name":"赤铜镐","category":"武器","value":108,"size":Vector2i(4,5),"color":"c89067","attack":7,"base_durability":20,"desc":"攻击 7 · 耐久 20 / 20\n按图纸制作，燃料纯度决定最大耐久。"},
 "iron_axe": {"name":"辉铁斧","category":"武器","value":156,"size":Vector2i(3,5),"color":"a2d7dc","attack":10,"base_durability":20,"desc":"攻击 10 · 耐久 20 / 20\n按图纸制作，燃料纯度决定最大耐久。"},
 "iron_pickaxe": {"name":"辉铁镐","category":"武器","value":188,"size":Vector2i(4,5),"color":"a2d7dc","attack":10,"base_durability":20,"desc":"攻击 10 · 耐久 20 / 20\n按图纸制作，燃料纯度决定最大耐久。"},
 "tempered_sword": {"name":"淬火剑","category":"武器","value":184,"size":Vector2i(2,6),"color":"e3ad77","attack":13,"base_durability":24,"desc":"攻击 13 · 耐久 24 / 24\n按图纸制作，燃料纯度决定最大耐久。"},
 "tempered_axe": {"name":"淬火斧","category":"武器","value":216,"size":Vector2i(3,5),"color":"e3ad77","attack":13,"base_durability":24,"desc":"攻击 13 · 耐久 24 / 24\n按图纸制作，燃料纯度决定最大耐久。"},
 "small_bag": {"name":"小背包", "category":"容器", "value":0, "size":Vector2i(3,4), "color":"a77c56", "desc":"旅商的初始背包，占用 3 × 4 格。\n点击打开：内部有 6 × 6 格。"},
 "pot": {"name":"烹饪锅", "category":"设备", "value":120, "size":Vector2i(3,3), "color":"b79a73", "desc":"点击展开内部空间。\n放入鲜兽肉，次日制成烤肉。"},
 "alembic": {"name":"炼药锅", "category":"设备", "value":180, "size":Vector2i(3,4), "color":"89bdb0", "desc":"按配方放入材料和燃料，隔天炼制药水。\n只看材料种类与数量，不要求摆放位置。"},
 "furnace": {"name":"工作台", "category":"设备", "value":240, "size":Vector2i(4,4), "color":"bd8964", "desc":"打开工作台，按配方摆放矿石与燃料。\n隔天生成装备；燃料决定纯度与耐久。"},
 "iron_sword": {"name":"辉铁剑", "attack":10, "base_durability":20, "category":"武器", "value":140, "size":Vector2i(2,6), "color":"a2d7dc", "desc":"攻击 10 · 耐久 20 / 20\n辉铁打造的剑，可在工作台制作。"},
 "herb": {"name": "月光草", "category": "材料", "value": 18, "size": Vector2i(2,3), "color": "98bfad", "desc": "在月色中生长的草药。\n可投入炼药锅，按配方炼制药剂。"},
 "berry": {"name": "绯红果", "category": "材料", "value": 12, "size": Vector2i(1,1), "color": "d98683", "desc": "风栖镇郊外采摘的甜果。\n可烹饪，也可直接出售。"},
 "meat": {"name": "鲜兽肉", "category": "材料", "value": 24, "size": Vector2i(3,2), "color": "ce927e", "desc": "适合烹饪的鲜肉。\n投入烹饪锅可制成烤肉。"},
 "bread": {"name": "蜜糖面包", "category": "食物", "value": 26, "size": Vector2i(3,2), "color": "dfb779", "desc": "松软的旅行口粮。\n战斗中消耗：恢复 12 点生命。"},
 "steak": {"name": "香草烤肉", "category": "食物", "value": 40, "size": Vector2i(3,2), "color": "c8946c", "desc": "烤得恰到好处的肉排。\n战斗中消耗：恢复 20 点生命。"},
 "ore": {"name": "辉铁矿", "category": "矿石", "value": 32, "size": Vector2i(2,2), "color": "a6bfd2", "desc": "带着蓝色晶纹的铁矿。\n放入工作台，按图纸打造辉铁装备。"},
 "sword": {"name": "旅人长剑", "category": "武器", "value": 96, "size": Vector2i(2,6), "color": "c1d3d7", "desc": "攻击 8  ·  耐久 20 / 20\n每次攻击消耗 1 点耐久。"},
 "potion": {"name": "防护药剂", "category": "药剂", "value": 45, "size": Vector2i(1,3), "color": "81bdc0", "desc": "封存着森林的守护之力。\n战斗中消耗：获得 15 点护盾。"},
 "power": {"name": "力量药剂", "category": "药剂", "value": 56, "size": Vector2i(1,3), "color": "b698cc", "desc": "散发着微弱的紫色光芒。\n本场战斗攻击力 +20%。"}
}
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

func _init() -> void:
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

func fits(item: Dictionary, zone: String, at: Vector2i, ignore_id: int = -1) -> bool:
 var d := dimensions(item)
 var bounds: Vector2i = zone_size(zone)
 if at.x < 0 or at.y < 0 or at.x+d.x > bounds.x or at.y+d.y > bounds.y:
  return false
 var rect := Rect2i(at,d)
 for other in items:
  if other.id == ignore_id or other.zone != zone:
   continue
  if rect.intersects(Rect2i(other.cell, dimensions(other))):
   return false
 return true

func free_cell(item: Dictionary, zone: String) -> Vector2i:
 for y in range(zone_size(zone).y):
  for x in range(zone_size(zone).x):
   if fits(item,zone,Vector2i(x,y),item.id):
    return Vector2i(x,y)
 return Vector2i(-1,-1)

func add_item(key: String, zone: String, owner: String) -> bool:
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
 if CATALOG[key].category == "武器":
  item.max_durability = CATALOG[key].get("base_durability",20)
  item.durability = item.max_durability
 var at := free_cell(item,zone)
 if at.x < 0 and item_size_is_rectangular(key):
  # Customer and loot areas are only four cells tall; auto-pack long items sideways.
  item.rotated = true
  at = free_cell(item,zone)
 if at.x < 0:
  return false
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
 var value: int = CATALOG[item.key].value
 if value >= 45:
  return "顾客眼睛一亮：我很喜欢这个。"
 if value >= 25:
  return "顾客点头：这个正合我意。"
 return "顾客有点兴趣：这个可以看看。"

func total_value() -> int:
 var value := 0
 for item in buying_items()+selling_items():
  value += CATALOG[item.key].value
 return value

func buying_value() -> int:
 var value := 0
 for item in buying_items():
  value += CATALOG[item.key].value
 return value

func selling_value() -> int:
 var value := 0
 for item in selling_items():
  value += CATALOG[item.key].value
 return value

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

func configure_customer(buy_category: String, sell_key: String, goods: Array, funds := 150) -> void:
 customer_buy_category = buy_category
 customer_sell_key = sell_key
 customer_funds_limit = clampi(int(funds),100,200)
 customer_funds = customer_funds_limit
 customer_goods.clear()
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
 var reserved: Array[Rect2i] = []
 for item in selling_batch:
  var placement := _customer_sale_placement(item,reserved)
  if placement.is_empty():
   return "顾客格子空间不足，暂时无法接收这些商品。"
  customer_placements.append(placement)
  reserved.append(placement.rect)
 for i in range(selling_batch.size()):
  var item: Dictionary = selling_batch[i]
  item.zone = "customer"
  item.cell = customer_placements[i].rect.position
  item.rotated = customer_placements[i].rotated
  item.owner = "customer"
  item.origin = {}
  item.settled = true
 for item in buying_batch:
  item.owner = "player"
  item.origin = {}
  item.settled = true
 gold -= buy_offer
 gold += sell_offer
 customer_funds = clampi(customer_funds - sell_offer + buy_offer,0,customer_funds_limit)
 earnings += sell_offer - buy_offer
 completed += 1
 patience = 3
 buy_offer = 0
 sell_offer = 0
 offer = 0
 active_trade_tab = "buy"
 return "交易完成，期待下次与你相遇。"

func _customer_sale_placement(item: Dictionary, reserved: Array[Rect2i]) -> Dictionary:
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
    if reserved.any(func(other): return rect.intersects(other)):
     continue
    return {"rect":rect,"rotated":rotation}
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
 var detail := "攻击 %d · 耐久 %d / %d" % [data.get("attack",8),item.get("durability",20),item.get("max_durability",data.get("base_durability",20))]
 if item.has("purity"):
  detail += " · 纯度 %d%%" % item.purity
 return detail+"\n"+str(data.desc).get_slice("\n",1)

func item_hover_details(item: Dictionary, action_hint := "") -> String:
 var data: Dictionary = CATALOG[item.key]
 var dimensions_value: Vector2i = dimensions(item)
 var details := [
  ("未拥有" if item.owner == "customer" else "已拥有")+"  /  "+str(data.category),
  "估值 %d G  ·  占用 %d × %d" % [data.value,dimensions_value.x,dimensions_value.y],
  item_description(item),
 ]
 if action_hint == "":
  action_hint = "双击展开 · 拖动原料" if MACHINES.has(item.key) else "拖动放置 · 双击移入 / 移出柜台"
 details.append(action_hint)
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
    return "只有自己的材料可以放入炼药锅。"
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
    return "炼药锅只能放入材料类物品。"
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
    if not add_item(plan.output,machine_output_zone(device.id),"player"):
     break
    var product: Dictionary = items.back()
    produced_ids.append(product.id)
    if device.key == "furnace":
     product.purity = plan.purity
     product.max_durability = plan.max_durability
     product.durability = plan.max_durability
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
