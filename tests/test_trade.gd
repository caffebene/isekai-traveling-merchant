extends SceneTree
const State = preload("res://scripts/trade_state.gd")
var checks := 0

func check(value: bool, message: String) -> void:
 checks += 1
 if not value:
  push_error("FAILED: " + message)
  quit(1)
  assert(value,message)

func first(s, owner: String) -> Dictionary:
 return s.items.filter(func(i): return i.owner == owner)[0]

func place(s, item: Dictionary) -> void:
 check(s.move_item(item.id,"counter",s.free_cell(item,"counter"),item.rotated) == "", "place on counter")

func _initialize() -> void:
 for key in State.CATALOG:
  var size: Vector2i = State.CATALOG[key].size
  check(size.x >= 1 and size.y >= 1 and mini(size.x,size.y) <= 4,"item footprint follows grid rules: %s" % key)
 var s = State.new()
 s.configure_customer("材料","",[])
 var wrong: Dictionary = s.items.filter(func(i): return i.owner == "player" and i.key == "sword")[0]
 check(s.move_item(wrong.id,"counter",Vector2i(0,0),true) == "", "non-wanted sale can enter counter")
 check(wrong.zone == "counter" and wrong.trade_rejected and s.last_reaction == "我没有意愿买这个。","non-wanted sale stays out of trade list")
 s.cancel_trade()
 var seller: Dictionary = s.items.filter(func(i): return i.owner == "player" and i.key == "herb")[0]
 var old_gold: int = s.gold
 place(s,seller)
 check(s.last_reaction != "","wanted item produces customer reaction")
 var sale: int = s.sell_offer
 check(s.settle().begins_with("交易完成"),"wanted sale succeeds")
 check(s.gold == old_gold+sale,"sale credits gold")
 check(seller.owner == "customer" and seller.zone == "customer","sold item moves to customer grid")
 check(s.counter_items().is_empty(),"sale clears counter")
 s.configure_customer("材料","",[],100)
 for n in range(8):
  s.add_item("herb","stock","player")
 var budget_items: Array[Dictionary] = s.items.filter(func(i): return i.owner == "player" and i.key == "herb" and i.zone == "stock")
 for budget_item in budget_items:
  check(s.move_item(budget_item.id,"counter",s.free_cell(budget_item,"counter"),false) == "","budget test item enters counter")
 check(s.sell_offer <= 100,"customer offer respects 100 G budget")
 check(s.settle().begins_with("交易完成"),"budget-capped sale settles")
 check(s.customer_funds >= 0 and s.customer_funds <= 100,"customer funds stay within budget")
 s.configure_customer("材料","sword",["sword"])
 s.add_item("herb","stock","player")
 var bought: Dictionary = first(s,"customer")
 var id: int = bought.id
 check(s.move_item(id,"stock",Vector2i(15,3),false) != "", "unpaid goods cannot enter player storage")
 place(s,bought)
 check(s.buying(),"customer goods trigger buy")
 var mixed_seller: Dictionary = s.items.filter(func(i): return i.owner == "player" and i.key == "herb")[0]
 check(s.move_item(mixed_seller.id,"counter",s.free_cell(mixed_seller,"counter"),false) == "", "mixed ownership accepted")
 var buy_offer: int = s.buy_offer
 var mixed_sale: int = s.sell_offer
 var mixed_gold: int = s.gold
 check(s.settle().begins_with("交易完成"),"mixed trade succeeds")
 check(s.gold == mixed_gold-buy_offer+mixed_sale,"mixed payment is netted")
 check(bought.owner == "player" and bought.zone == "counter" and bought.settled,"bought goods stay for manual move")
 check(mixed_seller.owner == "customer" and mixed_seller.zone == "customer","sold goods move to customer grid")
 check(s.move_item(bought.id,"stock",s.free_cell(bought,"stock"),bought.rotated) == "","bought goods can be moved manually")
 check(not bought.settled,"manual move clears settled state")
 s.configure_customer("武器","sword",["sword"])
 bought = first(s,"customer")
 var origin: Vector2i = bought.cell
 place(s,bought)
 s.cancel_trade()
 check(bought.zone == "customer" and bought.cell == origin,"cancel restores source")
 s.add_item("sword","stock","player")
 seller = s.items.filter(func(i): return i.key == "sword" and i.owner == "player")[0]
 check(s.move_item(seller.id,"counter",Vector2i(0,0),true) == "","rotation accepted")
 check(s.dimensions(seller) == Vector2i(6,2),"rotation swaps footprint")
 check(s.move_item(seller.id,"counter",Vector2i(49,0),true) != "","bounds enforced")
 var another: Dictionary = s.items.filter(func(i): return i.key == "sword" and i.owner == "player" and i.id != seller.id)[0]
 check(s.move_item(another.id,"counter",Vector2i(0,0),false) != "","overlap rejected")
 s.cancel_trade()
 check(not seller.rotated,"cancel restores original rotation")
 s = State.new()
 s.configure_customer("","sword",["sword"])
 place(s,first(s,"customer"))
 for i in range(3):
  s.negotiate(1)
 check(s.patience == 0,"bad offers consume patience")
 var final_offer: int = s.offer
 s.negotiate(999)
 check(s.offer == final_offer,"no negotiation after patience exhausted")
 s = State.new()
 for recipe in [["pot","meat","steak"]]:
  var device: Dictionary = s.items.filter(func(i): return i.key == recipe[0])[0]
  var raw: Dictionary = s.items.filter(func(i): return i.key == recipe[1] and i.owner == "player")[0]
  var zone: String = s.machine_zone(device.id)
  check(s.move_item(raw.id,zone,Vector2i.ZERO,recipe[0] == "furnace") == "","load device input")
  check(raw.key == recipe[1],"production not instant")
  var previous_day: int = s.day
  s.advance_day()
  check(s.day == previous_day+1,"advance calendar")
  check(raw.key == recipe[2] and raw.zone == zone,"next day output stays in device")
  check(s.move_item(raw.id,"stock",s.free_cell(raw,"stock"),raw.rotated) == "","retrieve produced item")
 var device: Dictionary = s.items.filter(func(i): return i.key == "pot")[0]
 var wrong_ingredient: Dictionary = s.items.filter(func(i): return i.key == "ore" and i.owner == "player")[0]
 check(s.move_item(wrong_ingredient.id,s.machine_zone(device.id),Vector2i.ZERO,false) != "","wrong recipe input rejected")
 check(s.move_item(device.id,"counter",Vector2i.ZERO,false) != "","loaded devices cannot be sold")
 for item in s.items:
  check(s.fits(item,item.zone,item.cell,item.id),"all final placements valid")
 s = State.new()
 var bag: Dictionary = s.items.filter(func(i): return i.key == "small_bag")[0]
 check(s.dimensions(bag) == Vector2i(3,4),"initial backpack footprint is 3x4")
 check(State.SIZES.bag == Vector2i(6,6),"backpack opens a 6x6 grid")
 var bag_item: Dictionary = s.items.filter(func(i): return i.key == "berry" and i.owner == "player")[0]
 check(s.dimensions(s.items.filter(func(i): return i.key == "power")[0]) == Vector2i(1,3),"power potion footprint is 1x3")
 check(s.dimensions(bag_item) == Vector2i(1,1),"red berry footprint is 1x1")
 check(s.move_item(bag_item.id,"bag",Vector2i(0,0),false) == "","item can enter backpack")
 check(bag_item.zone == "bag" and bag_item.cell == Vector2i.ZERO,"backpack stores item")
 check(s.move_item(bag.id,"bag",Vector2i(2,0),false) != "","backpack cannot contain itself")
 check(s.move_item(bag_item.id,"bag",Vector2i(6,5),false) != "","backpack bounds enforced")
 check(s.move_item(bag_item.id,"stock",s.free_cell(bag_item,"stock"),false) == "","item can leave backpack")
 print("PASS: %d trade and inventory checks" % checks)
 quit(0)
