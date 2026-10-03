extends SceneTree
const State = preload("res://scripts/trade_state.gd")
var checks := 0

func check(value: bool, message: String) -> void:
 checks += 1
 if not value:
  push_error(message)
  quit(1)
  assert(value,message)

func _initialize() -> void:
 var state = State.new()
 var initial: Dictionary = state.items[0]
 check(state.item_card_data(initial).purchase_price == null,"initial goods do not fabricate a purchase price")
 state.configure_customer("","*",["bread","ore","potion"])
 var batch: Array[Dictionary] = state.items.filter(func(i): return i.owner == "customer")
 for item in batch:
  check(state.move_item(item.id,"counter",state.free_cell(item,"counter"),item.rotated) == "","purchase goods reach counter")
 state.buy_offer = 73
 var before: int = state.gold
 check(state.settle().begins_with("交易完成"),"batch purchase settles")
 var total_cost := 0
 for item in batch:
  check(item.has("purchase_price") and item.purchase_price > 0,"successful purchase records each actual cost")
  total_cost += int(item.purchase_price)
 check(total_cost == 73 and before-state.gold == 73,"allocated item costs sum exactly to the paid batch price")
 var purchased: Dictionary = batch[0]
 var recorded: int = purchased.purchase_price
 state.day += 2
 check(state.item_card_data(purchased).purchase_price == recorded,"market changes do not rewrite historical purchase cost")
 check(state.move_item(purchased.id,"stock",state.free_cell(purchased,"stock"),purchased.rotated) == "","purchased item can be stored")
 check(purchased.purchase_price == recorded,"moving an item retains its cost")
 check(state.item_card_data(purchased).quantity == 1,"physical inventory instance displays its own quantity")
 state.configure_customer("","ore",["ore"])
 var unpaid: Dictionary = state.items.filter(func(i): return i.owner == "customer")[0]
 state.move_item(unpaid.id,"counter",state.free_cell(unpaid,"counter"),unpaid.rotated)
 state.gold = 0
 check(state.settle().begins_with("金币不足"),"unaffordable purchase fails")
 check(not unpaid.has("purchase_price"),"failed payment never records purchase history")
 var weapon: Dictionary = state.items.filter(func(i): return State.CATALOG[i.key].category == "武器" and i.owner == "player")[0]
 weapon.durability = 7
 var details: Dictionary = state.item_card_data(weapon)
 check(details.stats.any(func(row): return row.label == "耐久" and row.value.begins_with("7 /")),"detail card uses live durability")
 var bag: Dictionary = state.items.filter(func(i): return i.key == "small_bag")[0]
 check(state.item_card_data(bag).category == "背包" and state.item_card_data(bag).tags == ["背包"],"backpack presents the meaningful backpack type")
 check(details.tags == ["武器"],"item card excludes redundant generic tags")
 var meat: Dictionary = state.items.filter(func(i): return i.key == "meat")[0]
 check(state.item_card_data(meat).stats.any(func(row): return row.label == "生命恢复" and row.value == "8"),"raw meat shows its actual healing")
 var herb: Dictionary = state.items.filter(func(i): return i.key == "herb")[0]
 check(state.item_card_data(herb).stats.is_empty(),"non-stat materials have no detailed values")
 check(state.items.all(func(i): return not state.item_card_data(i).stats.any(func(row): return row.label == "占格")),"no item card exposes footprint as a detailed stat")
 var expected_tags := {"ore":["材料","矿石"],"copper_ore":["材料","矿石"],"slime_mucus":["材料","燃料"],"ancient_wood":["材料","燃料"],"herb":["材料","药材"],"berry":["材料","药材"],"meat":["材料","食物"]}
 for key in expected_tags:
  var sample := {"key":key,"zone":"stock","id":-1,"cell":Vector2i.ZERO,"rotated":false}
  check(state.item_card_data(sample).tags == expected_tags[key],"processing material exposes meaningful tags: " + key)
 for zone in ["stock","counter","loot","bag"]:
  var support := {"key":"ore","zone":zone,"id":-1,"cell":Vector2i.ZERO,"rotated":false}
  check(state.item_card_data(support).stats.any(func(row): return row.label == "相邻武器攻击" and row.value == "+3"),"ore support value visible in " + zone)
 var power_support := {"key":"power","zone":"stock","id":-1,"cell":Vector2i.ZERO,"rotated":false}
 check(state.item_card_data(power_support).stats.any(func(row): return row.label == "相邻武器攻击" and row.value == "+2"),"power potion shows adjacent bonus outside bag")
 for key in ["slime_mucus","ancient_wood"]:
  var fuel := {"key":key,"zone":"stock","id":-1,"cell":Vector2i.ZERO,"rotated":false}
  check(state.item_card_data(fuel).stats.any(func(row): return row.label == "相邻武器攻击间隔" and row.value == "-%d%%" % State.FUEL_INTERVAL_REDUCTION[key]),"fuel interval bonus is a percentage outside bag: " + key)
 var ore_card := state.item_card_data({"key":"ore","zone":"stock","id":-1,"cell":Vector2i.ZERO,"rotated":false})
 check(not ore_card.stats.any(func(row): return row.label == "相邻武器攻击间隔"),"ore no longer advertises interval effects")
 print("PASS: %d item card and purchase cost checks" % checks)
 quit()
