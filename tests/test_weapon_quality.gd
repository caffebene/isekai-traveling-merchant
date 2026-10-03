extends SceneTree
const State = preload("res://scripts/trade_state.gd")
const Q = preload("res://scripts/weapon_quality.gd")
const Combat = preload("res://scripts/exploration_state.gd")
var checks := 0
func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok:
  push_error(message)
  quit(1)
  assert(ok,message)
func _initialize() -> void:
 var rng := RandomNumberGenerator.new()
 rng.seed = 12345
 for source in Q.PROBABILITIES:
  var counts := [0,0,0,0,0]
  for n in range(100):
   counts[Q.quality_at(Q.PROBABILITIES[source],n)] += 1
  check(counts == Q.PROBABILITIES[source],"exact probability boundaries "+source)
  for n in range(5):
   var affixes := Q.roll_affixes(n,rng)
   check(affixes.size() == n,"affix count")
   var unique := {}
   for affix in affixes:
    unique[affix.key] = true
    check(affix.value >= Q.AFFIXES[affix.key].min and affix.value <= Q.AFFIXES[affix.key].max,"affix range")
   check(unique.size() == n,"no duplicates")
 var other := RandomNumberGenerator.new()
 rng.seed = 97
 other.seed = 97
 for n in range(30):
  check(Q.roll_quality("loot",rng) == Q.roll_quality("loot",other),"seeded quality")
  check(Q.roll_affixes(4,rng) == Q.roll_affixes(4,other),"seeded affixes")
 var s = State.new()
 s.items.clear()
 s.quality_rng.seed = 77
 var previous := 0
 for n in range(5):
  check(s.add_item("iron_sword","stock","player","loot",n),"explicit quality")
  var item: Dictionary = s.items.back()
  check(item.quality == n and item.affixes.size() == n,"explicit override")
  var value: int = s.item_market_value(item)
  check(value > previous,"strictly increasing value")
  previous = value
  var snapshot: Dictionary = item.duplicate(true)
  s.item_card_data(item)
  check(item == snapshot,"card reads do not reroll")
 var legacy := {"key":"iron_sword","zone":"stock","id":-1,"cell":Vector2i.ZERO,"rotated":false}
 check(s.item_market_value(legacy) == s.market_value("iron_sword"),"legacy white price")
 check(Q.tier(legacy) == 0 and Q.bonus(legacy,"sharp") == 0,"legacy no affixes")
 s.items.clear()
 s.add_item("iron_sword","bag","player","",4)
 var weapon: Dictionary = s.items.back()
 weapon.affixes = [{"key":"sharp","value":20},{"key":"swift","value":10},{"key":"critical","value":100},{"key":"leech","value":15}]
 check(s.bag_effects(weapon).final_attack == 12,"percent attack")
 check(is_equal_approx(s.bag_effects(weapon).attack_interval,2.0/1.1),"attack speed")
 s.add_item("ore","stock","player")
 var ore: Dictionary = s.items.back()
 s.move_item(ore.id,"bag",Vector2i(2,0),false)
 check(s.bag_effects(weapon).final_attack == 15,"adjacency added after percent")
 check(is_equal_approx(s.bag_effects(weapon).attack_interval,2.0/1.1),"ore keeps base interval and swift still applies")
 s.items.erase(ore)
 s.add_item("slime_mucus","bag","player")
 var interval_fuel: Dictionary = s.items.back()
 check(is_equal_approx(s.bag_effects(weapon).attack_interval,2.0*0.9/1.1),"fuel percentage and swift stack in final interval")
 s.items.erase(interval_fuel)
 var c = Combat.new()
 c.start(s)
 c.next_encounter()
 c.begin_battle()
 c.enemy_hp = 100
 c.hp = 40
 c.power = true
 var durability_before: int = weapon.durability
 c._auto_weapon_attack(weapon)
 check(c.enemy_hp == 78,"critical and power single rounding")
 check(c.hp == 43,"leech floors actual damage")
 check(weapon.durability == durability_before-1,"critical consumes one durability")
 c.enemy_hp = 4
 c.hp = 40
 c._auto_weapon_attack(weapon)
 check(c.phase == "victory" and c.hp == 40,"overkill excluded from leech")
 c.phase = "battle"
 c.enemy_hp = 20
 c.hp = 59
 c.attack(12,weapon.id,true,0.15)
 check(c.hp == 60,"killing leech respects hp cap")
 c.phase = "battle"
 c.enemy_hp = 100
 c.hp = 40
 c.basic_attack()
 check(c.hp == 40,"unarmed does not leech")
 weapon.durability = 0
 c._auto_weapon_attack(weapon)
 check(weapon.durability == 0,"broken weapon cannot attack")
 # Successful purchase allocation uses instance prices and conserves total gold.
 s.items.clear()
 s.configure_customer("","iron_sword",["iron_sword","iron_sword"])
 var batch: Array[Dictionary] = s.items.duplicate()
 batch[0].quality = 0
 batch[1].quality = 4
 s.buy_offer = 101
 s._record_purchase_prices(batch)
 check(batch[0].purchase_price+batch[1].purchase_price == 101,"cost conservation")
 check(batch[1].purchase_price > batch[0].purchase_price,"quality-weighted allocation")
 # Preview cannot advance quality RNG; fuel and sturdy durability stack once.
 s.items.clear()
 s.add_item("furnace","stock","player")
 var id: int = s.items.back().id
 for y in range(3):
  s.add_item("copper_ore","stock","player")
  s.move_item(s.items.back().id,s.machine_zone(id),Vector2i(0,y*2),false)
 s.add_item("ancient_wood","stock","player")
 s.move_item(s.items.back().id,s.machine_fuel_zone(id),Vector2i.ZERO,false)
 var saved_rng: int = s.quality_rng.state
 var plan: Dictionary = s.workbench_preview(id)
 for n in range(20):
  s.workbench_preview(id)
 check(s.quality_rng.state == saved_rng,"preview does not consume RNG")
 check(plan.quality_probabilities == Q.PROBABILITIES.ancient_wood,"preview shows fuel probabilities")
 s.advance_day()
 var product: Dictionary = s.items.filter(func(i): return i.zone == s.machine_output_zone(id))[0]
 check(product.max_durability == Q.durability(product,30),"fuel then sturdy")
 check(product.durability == product.max_durability,"fresh full durability")
 var fixed := product.duplicate(true)
 s.advance_day()
 check(product == fixed,"cross day retains generated attributes")
 check(not s.item_card_data({"key":"ancient_wood","zone":"stock","id":-1,"cell":Vector2i.ZERO}).stats.any(func(row): return str(row.label).contains("概率")),"fuel probability hidden")
 # Failed creation also leaves RNG untouched.
 saved_rng = s.quality_rng.state
 check(not s.add_item("iron_sword","invalid","player","loot"),"no space creation fails")
 check(s.quality_rng.state == saved_rng,"failed creation no roll")
 print("PASS: %d weapon quality checks" % checks)
 quit()
