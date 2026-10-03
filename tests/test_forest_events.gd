extends SceneTree
const Store = preload("res://scripts/trade_state.gd")
const Combat = preload("res://scripts/exploration_state.gd")
const Events = preload("res://scripts/forest_events.gd")
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  push_error(message)
func fixture() -> Array:
 var s = Store.new()
 s.items.clear()
 var c = Combat.new()
 c.start(s)
 c.rng.seed = 7
 return [s,c]
func listen(c) -> void:
 while c.phase == "event" and not c.choices_available():
  c.advance_dialogue()
func finish(c) -> void:
 c.finish_event()
 while c.phase == "event_result":
  c.advance_dialogue()
func choose(c, id: String, seed_value := 0) -> void:
 listen(c)
 c.rng.seed = seed_value
 var opts: Array = c.event.options.filter(func(o): return o.id == id)
 check(c.choose_event(id,c.event_item_id(opts[0])) == "","choice succeeds: "+id)
func bag(s,key: String) -> Dictionary:
 check(s.add_item(key,"bag","player"),"item fits: "+key)
 return s.items.back()
func branch_seed(branch: int) -> int:
 var random := RandomNumberGenerator.new()
 for n in range(100):
  random.seed = n
  if random.randi_range(0,1) == branch:
   return n
 return -1
func _initialize() -> void:
 var f := fixture()
 var s = f[0]
 var c = f[1]
 check(not c.enter_event("court"),"court cannot exist before actual collection")
 c.enter_event("chest")
 check(c.event.dialogue.size() >= 2 and not c.choices_available(),"encounter has multi-page introduction")
 check(c.choose_event("open") != "" and s.items.is_empty(),"premature choice cannot mutate resources")
 check(not str(c.event.dialogue).contains("赶我走"),"first chest does not invent history")
 for n in range(3):
  if n > 0:
   c.enter_event("chest")
  check(c.event.variant != "pursuit","pursuit not shown before three refusals")
  choose(c,"skip")
  check(c.memory.pending.filter(func(t): return t.id == "chest").size() == 1,"follow-up tickets coalesce")
  check(c.choose_event("skip") != "","repeat clicks locked")
  finish(c)
 c.enter_event("chest")
 check(c.event.variant == "pursuit" and str(c.event.dialogue).contains("3回"),"three actual refusals unlock callback")
 var bread := bag(s,"bread")
 bag(s,"bread")
 listen(c)
 check(c.choose_event("feed",999) != "" and c.phase == "event","requires real item identity")
 check(c.choose_event("feed",bread.id) == "","specific bread consumed")
 check(not s.items.any(func(i): return i.id == bread.id) and s.items.filter(func(i): return i.key == "bread").size() == 1,"only chosen copy consumed")
 check(not c.can_collect() and c.phase == "event_resolving","animation gates pickup")
 var item_count: int = s.items.size()
 check(c.choose_event("feed",bread.id) != "" and s.items.size() == item_count,"one settlement only")
 c.finish_event()
 check(c.phase == "event_result" and not c.can_collect(),"result is readable before collection")
 finish(c)
 check(c.can_collect() and c.memory.chest_fed and c.memory.chest_refusals == 0,"feeding records friendship")
 c.enter_event("chest")
 check(c.event.variant == "friend","friend is grounded in bread")
 # Mushroom cause, delayed lawsuit, real witness and conditional testimony.
 f=fixture(); s=f[0]; c=f[1]
 c.memory.last_variants.mushrooms = "quiet"
 c.enter_event("mushrooms")
 check(c.event.variant == "moving","last variant excluded")
 choose(c,"collect",branch_seed(1)); finish(c)
 check(not c.memory.mushroom_case.is_empty() and c.memory.mushroom_case.witness == "frog","collection incident records actual witness")
 check(c.memory.pending.any(func(t): return t.id == "court" and t.due >= 3),"court deferred after incident")
 check(not Events.eligible("mushrooms",c.memory),"cannot overwrite unresolved case")
 c.enter_event("frog")
 check(c.event.variant == "witness" and c.event.options[1].outcomes[0].has("testimony"),"frog recognizes witnessed case")
 bag(s,"berry"); choose(c,"fruit"); finish(c)
 check(c.memory.frog_testimony,"real sacrifice obtains evidence")
 c.enter_event("court")
 check(c.event.variant == "witness" and c.event.options[1].outcomes[0].weight == 3,"evidence modifies probability")
 choose(c,"delay"); finish(c)
 check(not c.memory.mushroom_case.is_empty() and c.memory.court_delays == 1,"escaping does not erase case")
 c.enter_event("court")
 check(str(c.event.dialogue).contains("上回你从左边跑"),"escape callback requires actual escape")
 s.gold=9; listen(c)
 check(c.choose_event("guilty") != "" and s.gold == 9,"insufficient money does not resolve")
 s.gold=10; choose(c,"guilty"); finish(c)
 check(s.gold == 0 and c.memory.mushroom_case.is_empty() and not c.memory.frog_testimony,"settlement clears case and evidence")
 check(not c.enter_event("court"),"settled case cannot reappear")
 # Both collection branches and respecting mushrooms.
 f=fixture(); s=f[0]; c=f[1]
 c.enter_event("mushrooms"); choose(c,"collect",branch_seed(0)); finish(c)
 check(c.memory.mushroom_case.is_empty(),"harmless collection cannot trigger court")
 for n in range(2):
  c.enter_event("mushrooms"); choose(c,"observe"); finish(c)
 c.enter_event("mushrooms")
 check(c.event.variant == "gift" and c.event.options[0].outcomes.size() == 1,"two friendly acts unlock gift")
 # Debt persists across retreats and gets consumed by first boss strike only.
 f=fixture(); s=f[0]; c=f[1]
 c.enter_event("well"); choose(c,"credit"); finish(c)
 c.leave(); c.start(s)
 check(c.wish_debt and c.memory.well_debt,"return preserves unpaid debt")
 c.enter_event("well")
 check(c.event.variant == "unpaid" and c.event.options[1].id == "repay","well recognizes debt")
 s.gold=20; choose(c,"repay"); finish(c)
 check(not c.wish_debt and not c.memory.well_debt and not c.memory.pending.any(func(t): return t.id == "collector"),"repayment cancels debt and collector")
 c.enter_event("well"); choose(c,"credit"); finish(c)
 c.memory.pending[0].due = 0
 c.next_node()
 check(c.boss and c.encounter == 1,"debt collector interrupts infinite route")
 c.begin_battle(); c.shield=999
 var shield_before: int=c.shield
 c.end_turn()
 check(shield_before-c.shield == c.enemy.attack*2 and not c.memory.well_debt,"first attack doubles before shield and clears debt")
 shield_before=c.shield; c.end_turn()
 check(shield_before-c.shield == c.enemy.attack,"debt consumed exactly once")
 c.attack(99999)
 check(c.phase == "victory" and not c.route_finished(),"boss does not end exploration")
 # Verdict persists through events, affects one battle, return clears transient penalty.
 f=fixture(); s=f[0]; c=f[1]
 c.enter_event("mushrooms"); choose(c,"collect",branch_seed(1)); finish(c)
 c.enter_event("court"); choose(c,"appeal",branch_seed(1)); finish(c)
 check(c.pending_verdict,"failed appeal queues verdict")
 c.enter_event("frog"); choose(c,"skip"); finish(c)
 c.event_streak=2; c.next_node()
 check(c.active_verdict and c.enemy.attack == 8 and not c.pending_verdict,"next battle consumes rounded verdict")
 c.begin_battle(); c.attack(999); check(not c.active_verdict,"victory clears verdict")
 c.pending_verdict=true; c.leave(); c.start(s)
 check(not c.pending_verdict and not c.active_verdict,"return clears combat verdict")
 # Wear/repair clamp to real crafted maximum, random loss ignores compartment.
 f=fixture(); s=f[0]; c=f[1]
 var sword := bag(s,"tempered_sword")
 sword.max_durability=32; sword.durability=30
 c.memory.last_variants.frog="healer"; c.enter_event("frog")
 choose(c,"kiss",branch_seed(0)); finish(c)
 check(sword.durability == 32,"repair clamps to actual crafted maximum")
 check(c.result_dialogue.size() == 1 and c.result_dialogue[0].speaker == "旁白","only story result, no inventory receipt dialogue")
 sword.durability=2; c.memory.last_variants.frog="healer"; c.enter_event("frog")
 choose(c,"kiss",branch_seed(1)); finish(c)
 check(sword.durability == 0,"weapon loss clamps at zero")
 s.economy.modules.append("hidden_compartment")
 c.enter_event("chest"); c.event.options[0].outcomes=[{"damage":12,"lose":true,"result":"咬住行李。"}]
 choose(c,"open"); finish(c)
 check(not s.items.any(func(i): return i.id == sword.id),"events ignore hidden compartment")
 c.enter_event("chest"); c.event.options[0].outcomes=[{"lose":true,"result":"扑了个空。"}]
 choose(c,"open"); finish(c)
 check(c.phase == "event_loot","empty bag loss resolves safely")
 bag(s,"ore"); c.hp=1
 c.enter_event("chest"); c.event.options[0].outcomes=[{"damage":12,"rewards":["herb"],"result":"咬了一口。"}]
 choose(c,"open"); c.finish_event()
 check(c.phase == "defeat" and c.hp == 0 and not s.items.any(func(i): return i.zone == "loot"),"event death has no reward or dialogue phase override")
 check(s.items.size() == 1,"existing defeat protection preserved")
 # Full bag rewards stay in loot; infinite scheduler goes beyond many bosses.
 f=fixture(); s=f[0]; c=f[1]
 for y in range(6):
  for x in range(6):
   s.add_item("herb","bag","player")
 c.enter_event("chest"); c.event.options[0].outcomes=[{"rewards":["ore","potion"],"result":"包裹。"}]
 choose(c,"open"); finish(c)
 check(s.items.filter(func(i): return i.zone == "loot").size() == 2,"full bag does not destroy event loot")
 c.leave(); c.start(s); c.rng.seed=7
 var court_without_cause := false
 var max_streak := 0
 for n in range(180):
  c.next_node()
  if c.phase == "event":
   court_without_cause = court_without_cause or c.event.id == "court"
   max_streak=maxi(max_streak,c.event_streak)
   choose(c,"skip" if c.event.id != "court" else "guilty",n)
   finish(c)
  else:
   c.begin_battle(); c.attack(1000000)
 check(c.route_index == 179 and c.encounter > 70 and not c.route_finished(),"unlimited encounters past repeated bosses")
 check(not court_without_cause and max_streak <= 2,"causal eligibility and battle pacing")
 check(c.memory.history.size() <= 64,"history bounded for infinite runs")
 # Seeded settlement coverage for every available option/outcome in each base event.
 for event_id in Events.EVENTS:
  var definition: Dictionary = Events.EVENTS[event_id]
  for option in definition.options:
   for branch in range(option.outcomes.size()):
    f=fixture(); s=f[0]; c=f[1]
    s.gold=100; c.hp=30
    bag(s,"sword"); bag(s,"bread"); bag(s,"berry")
    if event_id == "court":
     c.memory.mushroom_case={"description":"采草毁屋","place":"蘑菇丛","witness":"mushroom"}
    # Force a base storyline by finding its generation seed, never replace result data.
    var target: String = {"chest":"hungry","mushrooms":"quiet","frog":"healer","well":"hungry","court":"roof"}[event_id]
    for seed_value in range(100):
     c.rng.seed=seed_value
     if Events.build(event_id,c.memory,c.rng).variant == target:
      c.rng.seed=seed_value
      break
    c.enter_event(event_id)
    choose(c,option.id,branch_seed(branch)); finish(c)
    var expected: Dictionary=option.outcomes[branch]
    var expected_hp: int=60 if expected.get("full_heal",false) else mini(60,30-int(expected.get("damage",0))+int(expected.get("heal",0)))
    check(c.hp == expected_hp,"seeded actual health: %s/%s/%d" % [event_id,option.id,branch])
    check(s.gold == 100-int(option.get("cost",0))+int(expected.get("gold",0)),"seeded cost/reward: "+event_id)
    check(s.items.filter(func(i): return i.zone == "loot").size() == expected.get("rewards",[]).size(),"seeded reward count: "+event_id)
 # A battle escape consumes the existing loss rule and clears verdict only.
 f=fixture(); s=f[0]; c=f[1]
 bag(s,"ore"); c.next_encounter(); c.begin_battle(); c.active_verdict=true
 c.flee()
 check(c.phase == "returned" and s.items.is_empty() and not c.active_verdict,"battle can flee using original random loss")
 print("FOREST_EVENTS: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
