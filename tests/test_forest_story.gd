extends SceneTree
const Store=preload("res://scripts/trade_state.gd")
const Combat=preload("res://scripts/exploration_state.gd")
const Story=preload("res://scripts/forest_story.gd")
const Events=preload("res://scripts/forest_events.gd")
var checks:=0
var failures:=0
func check(value: bool, text: String) -> void:
 checks+=1
 if not value:
  failures+=1; push_error(text)
func fixture() -> Array:
 var s=Store.new(); s.items.clear(); s.bag_size=Vector2i(12,8)
 var c=Combat.new(); c.start(s)
 return [s,c]
func listen(c) -> void:
 while c.phase=="event" and not c.choices_available(): c.advance_dialogue()
func sell(s, name_value: String, key: String, success:=true) -> void:
 s.configure_customer("材料","",[],120,name_value)
 s.add_item(key,"stock","player")
 var item: Dictionary=s.items.back()
 s.move_item(item.id,"counter",Vector2i(0,0),false)
 if not success: s.sell_offer=1000
 var result: String=s.settle()
 check(result.begins_with("交易完成")==success,"real trade result")
func _initialize() -> void:
 run.call_deferred()
func run() -> void:
 var f=fixture(); var s=f[0]; var c=f[1]
 check(Events.eligible("hunter",c.memory,s),"injured hunter available before help")
 c.enter_event("hunter"); listen(c)
 check(c.choose_event("aid",-1)!="" and not s.story_progress.hunter_saved,"missing potion cannot unlock customer")
 s.add_item("potion","stock","player")
 var potion: Dictionary=s.items.back()
 check(c.choose_event("aid",potion.id)!="","stockroom medicine is not carried")
 potion.zone="bag"
 check(c.choose_event("aid",potion.id)=="","real carried potion used")
 check(not s.items.has(potion) and s.story_progress.hunter_saved,"one potion consumed and customer unlocked")
 check(c.choose_event("aid",potion.id)!="","repeat aid rejected")
 check(not Events.eligible("hunter",c.memory,s),"healed hunter not invented as injured again")
 c.leave(); c.start(s)
 check(s.story_progress.hunter_saved,"customer unlock survives return")
 f=fixture(); s=f[0]; c=f[1]
 c.enter_event("hunter"); listen(c); c.choose_event("bandage")
 check(not s.story_progress.hunter_saved,"temporary bandage does not falsely unlock")
 var lines: Array=Story.customer_lines(s,"希尔薇",[])
 check(not lines.has(Story.REQUEST_LINE) and s.story_progress.stage=="none","arrival never offers request before a successful trade")
 Story.hear_line(s,"希尔薇",Story.REQUEST_LINE)
 check(s.story_progress.stage=="none","unearned request line cannot bypass trade gate")
 sell(s,"希尔薇","herb")
 lines=Story.customer_lines(s,"希尔薇",[])
 check(lines.has(Story.REQUEST_LINE) and s.story_progress.stage=="none","successful trade exposes request without auto-reading it")
 Story.hear_line(s,"莱昂",Story.REQUEST_LINE)
 check(s.story_progress.stage=="none","only Sylvie can issue request")
 Story.hear_line(s,"希尔薇",Story.REQUEST_LINE)
 check(s.story_progress.stage=="requested","actual heard request recorded")
 c.start(s); c.next_encounter(); c.begin_battle(); c.attack(99999)
 check(not s.items.any(func(i): return i.key=="moonheart"),"ordinary fight cannot drop quest heart")
 c.encounter=6; c.next_encounter(); c.begin_battle(); c.attack(99999)
 check(s.items.filter(func(i): return i.key=="moonheart" and i.zone=="loot").size()==1,"boss victory guarantees one real heart in loot")
 check(s.story_progress.stage=="requested","loot/possession alone never delivers request")
 c.clear_loot(); c.encounter=6; c.next_encounter(); c.begin_battle(); c.attack(99999)
 check(s.items.any(func(i): return i.key=="moonheart"),"discarded or lost heart can drop again")
 c.clear_loot()
 sell(s,"布洛克","moonheart")
 check(s.story_progress.stage=="requested","wrong customer never advances main story")
 sell(s,"希尔薇","herb")
 check(s.story_progress.stage=="requested","wrong goods never advances story")
 sell(s,"希尔薇","moonheart",false)
 check(s.story_progress.stage=="requested","failed transaction never advances story")
 s.cancel_trade()
 sell(s,"希尔薇","moonheart")
 check(s.story_progress.stage=="delivered","actual successful sale opens next chapter")
 c.phase="idle"; c.start(s)
 c.memory.pending.append({"id":"chest","due":0})
 c.next_node()
 check(c.enemy.get("quest",false) and c.enemy.hp==210 and c.enemy.attack==18,"next outing faces higher difficulty quest boss")
 check(c.memory.pending.any(func(t): return t.id=="chest"),"quest encounter does not erase pending causal events")
 check(not Story.can_select(s,"sylvie"),"delivery alone does not unlock teammate")
 c.memory.well_debt=true; c.wish_debt=true
 c.memory.pending.append({"id":"collector","due":0})
 c.shield=100; c.begin_battle(); c.attack(99999)
 check(c.enemy_hp==1 and c.phase=="battle","moon seal preserves actual final HP until opening scene")
 var before: int=c.hp
 c.tick(3.0)
 check(c.hp==1 and c.phase=="story" and c.shield==0,"first boss strike reaches one HP even with shield")
 check(not c.wish_debt and not c.memory.well_debt and not c.memory.pending.any(func(t): return t.id=="collector"),"scripted first strike consumes wish debt exactly once")
 var elapsed: float=c.elapsed
 c.tick(100)
 check(c.hp==1 and c.elapsed==elapsed,"story reading pauses real battle clocks")
 c.advance_dialogue()
 check(c.hp==60 and c.companion=="sylvie" and s.story_progress.stage=="rescued","Sylvie enters and heals at her actual dialogue")
 c.advance_dialogue(); c.advance_dialogue()
 check(c.phase=="battle" and not Story.can_select(s,"sylvie"),"rescue resumes fight without premature roster unlock")
 c.shield=10; c.end_turn()
 check(c.hp==52 and c.phase=="battle" and c.shield==0,"later strike uses normal shield damage and never repeats rescue")
 c.attack(99999)
 check(c.phase=="story" and s.story_progress.stage=="victory_pending" and not c.can_collect(),"victory offers actual companion conversation before loot")
 while c.phase=="story": c.advance_dialogue()
 check(s.story_progress.stage=="recruited" and c.phase=="victory" and c.can_collect(),"completed victory conversation unlocks cards")
 check(Story.can_select(s,"") and Story.can_select(s,"sylvie") and not Story.can_select(s,"unknown"),"only unlocked valid cards accepted")
 c.leave(); s.selected_companion="sylvie"; c.start(s); c.next_encounter()
 check(c.companion=="sylvie" and not c.enemy.get("quest",false),"next outing selects Sylvie and resumes normal infinite pool")
 c.enemy.hp=999; c.enemy_hp=999; c.enemy.attack=0
 c.begin_battle(); var enemy_before: int=c.enemy_hp
 c.tick(4.0)
 check(c.enemy_hp==enemy_before-16,"two unarmed hits plus six damage independent ally attack")
 c.leave(); s.selected_companion=""; c.start(s)
 check(c.companion=="","solo card removes follower without losing unlock")
 # Slow/short frame equivalence for the additional attack scheduler.
 var pairs: Array=[]
 for n in range(2):
  f=fixture(); s=f[0]; c=f[1]
  s.story_progress.stage="recruited"; s.selected_companion="sylvie"; c.start(s); c.next_encounter()
  c.enemy.hp=999; c.enemy_hp=999; c.enemy.attack=0; c.begin_battle()
  if n==0: c.tick(12.0)
  else:
   for frame in range(120): c.tick(0.1)
  pairs.append([c.enemy_hp,c.hp,c.enemy_clock,c.companion_clock])
 check(pairs[0][0]==pairs[1][0] and is_equal_approx(pairs[0][3],pairs[1][3]),"ally scheduler respects chronological slow frame equivalence")
 # Escape after rescue keeps quest retryable without granting the roster.
 f=fixture(); s=f[0]; c=f[1]; s.story_progress.stage="delivered"; c.next_node(); c.begin_battle(); c.tick(3)
 while c.phase=="story": c.advance_dialogue()
 c.flee(); c.start(s); c.next_node()
 check(c.enemy.get("quest",false) and not Story.can_select(s,"sylvie"),"escaping rescue fight requires later real victory")
 c.begin_battle(); c.tick(3)
 while c.phase=="story": c.advance_dialogue()
 c.hp=1; c.end_turn()
 check(c.phase=="defeat" and s.story_progress.stage=="rescued","death after rescue does not grant roster")
 c.start(s); c.next_node()
 check(c.enemy.get("quest",false),"defeated quest remains retryable")
 s.story_progress.stage="victory_pending"; c.leave(); c.start(s); c.next_node()
 check(c.phase=="story","unfinished victory conversation resumes on later outing")
 while c.phase=="story": c.advance_dialogue()
 check(s.story_progress.stage=="recruited" and c.phase=="event_loot","resumed conversation unlocks only after completion")
 # UI: hearing, customer chance, and card dispatch use the production entry points.
 var shop=load("res://main.tscn").instantiate(); root.add_child(shop); await process_frame
 shop.shutter_closed=true
 shop._door()
 var departure: Button=shop.modal.find_children("*","Button",true,false).filter(func(b): return b.text=="前往野外")[0]
 departure.pressed.emit()
 await process_frame
 check(shop.exploration!=null and shop.exploration.combat.inventory==shop.state,"normal door button loads exploration with the current store")
 check(shop.exploration.combat.companion=="" and shop.exploration.combat.phase=="idle","fresh departure initializes solo exploration")
 shop.exploration.combat.leave()
 shop.exploration.finished.emit()
 await process_frame
 check(shop.exploration==null,"normal exploration returns to the shop")
 shop.customer_index=0; shop._apply_customer_profile()
 sell(shop.state,"希尔薇","herb")
 shop._record_dialogue_line(Story.REQUEST_LINE)
 check(shop.state.story_progress.stage=="requested","shop dialogue records earned request")
 shop.customer_rng.seed=7
 var hunter_seen:=false
 for n in range(30):
  shop.customer_index=n%4
  check(shop._next_customer_index()!=4,"locked hunter never appears")
 shop.state.story_progress.hunter_saved=true
 for n in range(30):
  shop.customer_index=n%4
  var next: int=shop._next_customer_index()
  if next==4:
   hunter_seen=true; shop.customer_index=4
   check(shop._next_customer_index()!=4,"hunter cannot repeat consecutively")
 check(hunter_seen,"saved hunter has actual chance to visit")
 shop.state.story_progress.stage="recruited"; shop.shutter_closed=true; shop._door()
 check(shop.modal.get_script().resource_path.ends_with("companion_picker.gd"),"door displays real character cards")
 shop.modal.select("sylvie"); shop.modal.departed.emit(shop.modal.selected)
 check(shop.exploration.combat.companion=="sylvie","selected card dispatches actual companion")
 print("FOREST_STORY: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
