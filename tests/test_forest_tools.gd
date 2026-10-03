extends SceneTree
const Store = preload("res://scripts/trade_state.gd")
const Combat = preload("res://scripts/exploration_state.gd")
const Events = preload("res://scripts/forest_events.gd")
const Extra = preload("res://scripts/forest_extra_events.gd")
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  push_error(message)
func fixture(keys: Array = []) -> Array:
 var s=Store.new(); s.items.clear(); s.bag_size=Vector2i(12,8)
 for key in keys: check(s.add_item(key,"bag","player"),"test item fits: "+key)
 var c=Combat.new(); c.start(s); c.rng.seed=7
 return [s,c]
func listen(c) -> void:
 while c.phase == "event" and not c.choices_available(): c.advance_dialogue()
func finish(c) -> void:
 c.finish_event()
 while c.phase == "event_result": c.advance_dialogue()
func branch_seed(branch: int) -> int:
 var rng=RandomNumberGenerator.new()
 for n in range(100):
  rng.seed=n
  if rng.randi_range(0,1) == branch: return n
 return 0
func enter_variant(c,id: String,variant: String) -> void:
 for n in range(100):
  c.rng.seed=n
  if Events.build(id,c.memory,c.rng,c.inventory).variant == variant:
   c.rng.seed=n
   break
 check(c.enter_event(id),"eligible encounter: "+id)
 listen(c)
func option(c,id: String) -> Dictionary:
 return c.event.options.filter(func(o): return o.id == id)[0]
func choose(c,id: String) -> void:
 var choice: Dictionary=option(c,id)
 check(c.choose_event(id,c.event_item_id(choice)) == "","choose "+id)
 finish(c)
func _initialize() -> void:
 var f=fixture(); var s=f[0]; var c=f[1]
 check(not c.enter_event("logging") and not c.enter_event("mining"),"no tools means no resource encounters")
 s.add_item("iron_axe","stock","player")
 check(not c.enter_event("logging"),"stockroom tools are not carried tools")
 var tool: Dictionary=s.items.back()
 tool.zone="bag"; tool.owner="customer"
 check(not c.enter_event("logging"),"customer tool cannot unlock logging")
 tool.owner="player"; tool.durability=0
 check(not c.enter_event("logging"),"broken axe cannot unlock logging")
 tool.durability=1
 check(c.enter_event("logging"),"one remaining durability unlocks cautious logging")
 listen(c)
 check(c.event_item_id(option(c,"chop")) == -1,"heavy chop disabled below three durability")
 var before: int=tool.durability
 check(c.choose_event("chop",tool.id) != "" and tool.durability == before and c.phase == "event","insufficient durability does not resolve or spend")
 choose(c,"prune")
 check(tool.durability == 0 and s.items.has(tool),"cautious chop consumes one and retains broken item")
 check(s.items.filter(func(i): return i.zone == "loot").map(func(i): return i.key) == ["ancient_wood"],"wood enters existing loot")
 check(c.choose_event("prune",tool.id) != "" and tool.durability == 0,"repeat settlement cannot spend durability again")
 c.clear_loot(); c.event_streak=2; c.next_node(); c.begin_battle()
 check(c.enemy_hp == int(c.enemy.hp)-5,"broken harvesting tool falls back to unarmed opening")
 # Every existing axe/pick family unlocks only its matching resource.
 for kind in Events.TOOL_KEYS:
  for key in Events.TOOL_KEYS[kind]:
   f=fixture([key]); s=f[0]; c=f[1]
   var id: String="logging" if kind == "axe" else "mining"
   check(c.enter_event(id),"tool family unlocks "+key)
   check(not Events.eligible("mining" if kind == "axe" else "logging",c.memory,s),"wrong tool family rejected")
 # Select the actual tool, revalidate ownership/location/durability before locking.
 f=fixture(["copper_axe","iron_axe","sword"]); s=f[0]; c=f[1]
 var first: Dictionary=s.items[0]; var second: Dictionary=s.items[1]
 first.durability=1; second.durability=8
 c.enter_event("logging"); listen(c)
 check(c.event_item_id(option(c,"chop")) == second.id,"default skips insufficient first axe")
 check(c.choose_event("chop",s.items[2].id) != "","sword cannot be substituted for axe")
 second.zone="stock"
 check(c.choose_event("chop",second.id) != "" and second.durability == 8,"moved tool cannot be spent")
 second.zone="bag"; second.owner="customer"
 check(c.choose_event("chop",second.id) != "" and second.durability == 8,"ownership revalidated")
 second.owner="player"; second.durability=2
 check(c.choose_event("chop",second.id) != "","changed durability revalidated")
 second.durability=8
 var presented: Array=[]
 c.presentation.connect(func(data):
  if data.kind == "event_result": presented.append(data))
 check(c.choose_event("chop",second.id) == "","selected valid second tool used")
 check(second.durability == 5 and first.durability == 1,"only chosen tool loses three durability")
 check(presented.size() == 1 and presented[0].tool_id == second.id and presented[0].tool_key == "iron_axe","presentation carries true harvesting tool")
 finish(c)
 check(c.result_dialogue.size() == 1,"harvesting adds no inventory receipt dialogue")
 # Gathering uses the common defeat/loot path even when rewards cannot fit.
 f=fixture(["iron_pickaxe"]); s=f[0]; c=f[1]
 enter_variant(c,"mining","fractured"); c.hp=5; c.rng.seed=branch_seed(1)
 var pick: Dictionary=s.items[0]
 var pick_before: int=pick.durability
 choose(c,"dig")
 check(c.phase == "defeat" and c.hp == 0,"mining accident can kill through normal defeat")
 check(pick.durability == pick_before-3 and not s.items.has(pick),"fatal gathering spends chosen tool then applies defeat loss")
 check(s.items.filter(func(i): return i.zone == "loot").is_empty(),"fatal gathering never emits rewards")
 f=fixture(["iron_axe"]); s=f[0]; c=f[1]
 s.bag_size=Vector2i(1,1)
 enter_variant(c,"logging","hollow"); c.rng.seed=branch_seed(0); choose(c,"chop")
 check(s.items.filter(func(i): return i.zone == "loot").size()==2,"full bag keeps wood in loot for existing collection flow")
 # Seed every random outcome and every option of all new story variants.
 for id in Extra.VARIANTS:
  for variant in Extra.VARIANTS[id]:
   var template: Dictionary=Extra.build(id,{},variant)
   for choice in template.options:
    for branch in range(choice.outcomes.size()):
     f=fixture(["iron_axe","iron_pickaxe","ancient_wood","berry","potion"]); s=f[0]; c=f[1]
     s.gold=100; c.hp=30
     enter_variant(c,id,variant)
     var actual: Dictionary=option(c,choice.id)
     var selected_id: int=c.event_item_id(actual)
     var selected: Array=s.items.filter(func(i): return i.id == selected_id)
     var durability: int=int(selected[0].get("durability",0)) if not selected.is_empty() else 0
     c.rng.seed=branch_seed(branch)
     check(c.choose_event(choice.id,selected_id) == "","seeded choice: "+id+"/"+variant+"/"+choice.id)
     var result: Dictionary=choice.outcomes[branch]
     check(c.hp == mini(60,30-int(result.get("damage",0))+int(result.get("heal",0))),"actual outcome health")
     check(s.gold == 100-int(choice.get("cost",0)),"actual cost")
     check(s.items.filter(func(i): return i.zone == "loot").map(func(i): return i.key) == result.get("rewards",[]),"actual material rewards")
     if choice.has("tool"):
      check(selected[0].durability == durability-int(choice.tool_cost) and s.items.has(selected[0]),"specific tool spent and retained")
     elif choice.has("item"):
      check(not s.items.any(func(i): return i.id == selected_id),"real sacrifice consumed")
     else:
      check(s.items.filter(func(i): return i.key in ["iron_axe","iron_pickaxe"]).all(func(i): return i.durability == i.max_durability),"non-harvesting choice does not wear tools")
     finish(c)
 # Warmth is earned by real wood, retained on return, then consumed once.
 f=fixture(["ancient_wood"]); s=f[0]; c=f[1]; c.hp=10
 c.enter_event("camp"); listen(c); choose(c,"fuel")
 check(c.hp == 34 and c.memory.camp_fuel == 1,"wood grants recovery and later warmth")
 c.leave(); c.start(s); c.hp=20
 c.enter_event("camp"); listen(c)
 check(c.event.variant == "warm" and str(c.event.dialogue).contains("先前添过柴"),"warm callback requires real prior fuel")
 choose(c,"rest")
 check(c.hp == 36 and c.memory.camp_fuel == 0,"warm rest consumes reserve once")
 c.enter_event("camp")
 check(c.event.variant != "warm","no invented remaining warmth")
 # Snail recognition is grounded in two payments or actual feeding.
 f=fixture(); s=f[0]; c=f[1]; s.gold=100
 for n in range(2):
  c.enter_event("snail"); listen(c)
  check(c.event.variant != "neighbor","not recognized before two paid visits")
  choose(c,"pay")
 c.enter_event("snail"); listen(c)
 check(c.event.variant == "neighbor" and option(c,"accept").get("cost",0) == 0,"actual payments unlock free gift")
 choose(c,"accept")
 check(s.gold == 80,"free gift does not deduct money")
 f=fixture(["berry"]); s=f[0]; c=f[1]
 c.enter_event("snail"); listen(c); choose(c,"fruit")
 c.enter_event("snail")
 check(c.event.variant == "neighbor" and str(c.event.dialogue).contains("上回的果子"),"actual fruit earns correct greeting")
 # The infinite pool checks current carried gear rather than a stale departure flag.
 for with_tools in [false,true]:
  f=fixture(["iron_axe","iron_pickaxe"] if with_tools else []); s=f[0]; c=f[1]
  for item in s.items:
   item.durability=999; item.max_durability=999
  var found: Array=[]
  for n in range(160):
   c.hp=60; c.next_node()
   if c.phase == "event":
    found.append(c.event.id); listen(c)
    var id: String="skip" if c.event.id != "court" else "guilty"
    choose(c,id)
   else:
    c.begin_battle(); c.attack(1000000)
  check(found.has("logging") == with_tools and found.has("mining") == with_tools,"scheduler gates resources on live tool inventory")
 print("FOREST_TOOLS: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
