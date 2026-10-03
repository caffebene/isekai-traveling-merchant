extends SceneTree
const State = preload("res://scripts/trade_state.gd")
const Rules = preload("res://scripts/workbench_rules.gd")
const Combat = preload("res://scripts/exploration_state.gd")
var checks := 0
var failures := 0

func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  push_error("FAILED: "+message)


func fixture():
 var s = State.new()
 s.items.clear()
 s.serial = 0
 s.loaded_day.clear()
 s.add_item("furnace","stock","player")
 return s

func add(s, key: String, zone: String, cell: Vector2i) -> Dictionary:
 check(s.add_item(key,"stock","player"),"create "+key)
 var item: Dictionary = s.items.back()
 check(s.move_item(item.id,zone,cell,false) == "","place "+key)
 return item

func load_recipe(s, recipe: Dictionary, mirror := false, shift := Vector2i.ZERO) -> void:
 for n in range(recipe.materials.size()):
  var point: Vector2i = Rules.SHAPES[recipe.shape][n]
  if mirror:
   point.x = 1-point.x
  add(s,recipe.materials[n],s.machine_zone(0),shift+point*2)

func _initialize() -> void:
 var initial = State.new()
 check(initial.items.filter(func(i): return i.key == "furnace").size() == 1,"start with one workbench")
 check(initial.items.filter(func(i): return i.key == "copper_ore").size() == 3,"starter ore makes a sword")
 check(initial.items.any(func(i): return i.key == "slime_mucus"),"starter fuel")
 for recipe in Rules.recipes():
  for fuel in Rules.FUELS:
   if recipe.fuel != "" and fuel != recipe.fuel:
    continue
   var s = fixture()
   load_recipe(s,recipe,false,Vector2i(1,1))
   add(s,fuel,s.machine_fuel_zone(0),Vector2i.ZERO)
   add(s,fuel,s.machine_fuel_zone(0),Vector2i(2,0))
   var plan: Dictionary = s.workbench_preview(0)
   check(plan.ready and plan.output == recipe.output and not plan.fallback,"recipe preview "+recipe.output)
   check(s.items.filter(func(i): return i.zone == s.machine_output_zone(0)).is_empty(),"preview not real output")
   s.advance_day()
   var products: Array = s.items.filter(func(i): return i.zone == s.machine_output_zone(0))
   check(products.size() == 1 and products[0].key == recipe.output,"overnight output matches preview")
   check(products[0].purity == Rules.FUELS[fuel].purity and products[0].durability == State.Quality.durability(products[0],plan.max_durability),"fuel affects actual durability")
   check(products[0].max_durability == products[0].durability,"fresh product at full durability")
   check(s.items.filter(func(i): return i.zone == s.machine_zone(0)).is_empty(),"consume complete recipe")
   check(s.items.filter(func(i): return i.zone == s.machine_fuel_zone(0)).size() == 1,"consume only one fuel")
   s.advance_day()
   check(s.items.filter(func(i): return i.zone == s.machine_output_zone(0)).size() == 1,"no automatic refill or duplicate output")
   var product: Dictionary = products[0]
   check(s.move_item(product.id,"bag",Vector2i.ZERO,false) == "","retrieve to bag")
   check(s.move_item(product.id,s.machine_output_zone(0),Vector2i.ZERO,false) != "","output cannot be manually filled")
   var combat = Combat.new()
   combat.start(s)
   combat.next_encounter()
   combat.enemy.hp = 1000
   combat.enemy_hp = 1000
   combat.begin_battle()
   var before: int = combat.enemy_hp
   product.affixes = product.affixes.filter(func(a): return a.key not in ["critical","leech"])
   combat.tick(combat.weapon_interval(product))
   check(combat.enemy_hp == before-combat.weapon_damage(product),"crafted weapon usable in combat")
   check(product.durability == product.max_durability-2,"combat consumes actual durability")
   check(s.item_description(product).contains("/ %d" % product.max_durability),"tooltip shows instance max durability")
 # Left/right mirror retains the material-position contract for advanced axes.
 for recipe in Rules.recipes():
  if recipe.shape != "axe":
   continue
  var s = fixture()
  load_recipe(s,recipe,true,Vector2i(3,1))
  add(s,"ancient_wood",s.machine_fuel_zone(0),Vector2i.ZERO)
  check(s.workbench_preview(0).output == recipe.output and s.workbench_preview(0).ready,"mirrored axe")
 var s = fixture()
 var basic: Dictionary = Rules.recipes()[0]
 load_recipe(s,basic)
 var snapshot: Array = s.items.duplicate(true)
 s.advance_day()
 check(s.items.filter(func(i): return i.owner == "player") == snapshot,"missing fuel preserves everything")
 add(s,"slime_mucus",s.machine_fuel_zone(0),Vector2i.ZERO)
 var second_wood: Dictionary = add(s,"ancient_wood","stock",Vector2i(8,0))
 check(s.move_item(second_wood.id,s.machine_fuel_zone(0),Vector2i(2,0),false) != "","cannot mix fuels")
 check(s.move_item(second_wood.id,s.machine_zone(0),Vector2i(4,0),false) != "","reject fuel in input")
 var extra := add(s,"ore","stock",Vector2i(10,0))
 check(s.move_item(extra.id,s.machine_fuel_zone(0),Vector2i(2,0),false) != "","reject ore in fuel")
 check(s.move_item(extra.id,s.machine_zone(0),Vector2i(4,0),false) == "","extra material fits")
 check(not s.workbench_preview(0).ready,"extra material invalidates the whole input")
 var input_count: int = s.items.size()
 s.advance_day()
 check(s.items.size() == input_count,"invalid shape consumes nothing")
 # A valid silhouette with no material recipe falls back to its basic category.
 s = fixture()
 load_recipe(s,{"shape":"sword","materials":["ore","ore","copper_ore"]})
 add(s,"ancient_wood",s.machine_fuel_zone(0),Vector2i.ZERO)
 check(s.workbench_preview(0).ready and s.workbench_preview(0).fallback and s.workbench_preview(0).output == "copper_sword","fallback preserves item category")
 s.advance_day()
 check(s.items.any(func(i): return i.key == "copper_sword" and i.max_durability == State.Quality.durability(i,30)),"fallback keeps fuel purity")
 # Advanced recipe requires the specified fuel, without downgrading or consuming.
 s = fixture()
 load_recipe(s,Rules.recipes()[6])
 add(s,"slime_mucus",s.machine_fuel_zone(0),Vector2i.ZERO)
 check(not s.workbench_preview(0).ready and not s.workbench_preview(0).fallback,"rare fuel is a hard requirement")
 snapshot = s.items.duplicate(true)
 s.advance_day()
 check(s.items.filter(func(i): return i.owner == "player") == snapshot,"wrong rare fuel consumes nothing")
 # Output packing is checked before any input is destroyed.
 s = fixture()
 load_recipe(s,basic)
 add(s,"slime_mucus",s.machine_fuel_zone(0),Vector2i.ZERO)
 for n in range(8):
  check(s.add_item("ore",s.machine_output_zone(0),"player"),"fill output fixture")
 check(not s.workbench_preview(0).ready and s.workbench_preview(0).status.contains("空间"),"full output blocks preview")
 snapshot = s.items.duplicate(true)
 s.advance_day()
 check(s.items.filter(func(i): return i.owner == "player") == snapshot,"full output consumes nothing")
 for item in s.items.filter(func(i): return i.zone == s.machine_output_zone(0)):
  s.items.erase(item)
 s.advance_day()
 check(s.items.any(func(i): return i.key == "copper_sword"),"production resumes after room is made")
 # Supply is available for purchase, including all fuel tiers.
 s.configure_customer("","*",["ore","copper_ore","slime_mucus","ancient_wood"])
 for item in s.items.filter(func(i): return i.owner == "customer"):
  check(s.customer_will_sell(item),"merchant sells listed material/fuel")
 # Long crafted goods rotate into the customer inventory, with unique slots.
 s = fixture()
 s.configure_customer("武器","",[])
 for key in ["copper_sword","iron_sword","iron_axe"]:
  check(s.add_item(key,"stock","player"),"create batch sale item")
  check(s.move_item_to_counter(s.items.back().id,Vector2(700,200),false) == "","place long equipment on counter")
 check(s.settle().begins_with("交易完成"),"batch long equipment sale")
 for item in s.items.filter(func(i): return i.owner == "customer"):
  check(s.fits(item,"customer",item.cell,item.id),"batch sold goods do not overlap")
 s = fixture()
 s.configure_customer("武器","",[])
 for n in range(5):
  check(s.add_item("iron_pickaxe","stock","player"),"create oversized batch")
  check(s.move_item_to_counter(s.items.back().id,Vector2(700,200),false) == "","place oversized batch")
 snapshot = s.items.duplicate(true)
 var before_gold: int = s.gold
 check(s.settle().contains("空间不足"),"reject batch that cannot fit")
 check(s.items == snapshot and s.gold == before_gold,"failed packing preserves all goods, rotations and money")
 print("WORKBENCH %s: %d checks (%d failures)" % ["PASS" if failures == 0 else "FAIL",checks,failures])
 quit(1 if failures else 0)
