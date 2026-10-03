extends SceneTree
var shop
var page
var failures:=0
func _initialize() -> void:
 run.call_deferred()
func capture(name_value: String) -> void:
 shop._sync(); shop.queue_redraw()
 if is_instance_valid(page): page.refresh(); page.queue_redraw()
 await process_frame
 await process_frame
 await create_timer(0.10).timeout
 if DisplayServer.get_name() != "headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://docs/testing/previews/unified-ui/%s-%dx%d.png" % [name_value,root.size.x,root.size.y])
func outfit() -> void:
 page.state.bag_size=Vector2i(12,8)
 if not page.state.items.any(func(i): return i.zone=="bag" and i.key=="tempered_sword"):
  page.state.add_item("tempered_sword","bag","player","",4)
  var weapon: Dictionary=page.state.items.back()
  weapon.affixes=[]
  weapon.max_durability=page.state.Quality.durability(weapon,24)
  weapon.durability=weapon.max_durability
 for key in ["bread","bread","steak","steak","steak","steak","power","potion"]:
  page.state.add_item(key,"bag","player")
func start() -> void:
 shop._start_exploration(); page=shop.exploration; page.set_process(false); page.combat.rng.seed=7; outfit()
func listen() -> void:
 while not page.combat.choices_available(): page._advance_dialogue()
func feed() -> void:
 if page.combat.hp <= 40:
  for item in page.state.items.duplicate():
   if item.zone=="bag" and item.key in ["bread","steak"]:
    page.combat.use_item(item.id)
func fight() -> void:
 for item in page.state.items.duplicate():
  if item.zone=="bag" and item.key=="power": page.combat.use_item(item.id); break
 page._fight()
 var ticks:=0
 while page.combat.phase=="battle" and ticks<1000:
  feed(); page._process(0.1); ticks+=1
func pickup() -> void:
 for item in page.state.items.duplicate():
  if item.zone=="loot": page._auto_pickup_loot(item.id)
func run() -> void:
 shop=load("res://main.tscn").instantiate(); root.add_child(shop); await process_frame
 shop.set_process(false)
 # Earn and read the request through the actual shop settlement.
 shop.customer_index=0; shop._apply_customer_profile(); shop._start_customer_conversation()
 shop.state.add_item("herb","stock","player")
 var request_material: Dictionary=shop.state.items.back()
 shop.state.move_item(request_material.id,"counter",Vector2i.ZERO,false)
 shop._settle()
 shop._set_dialogue_line(1,true)
 await capture("45-forest-request")
 start(); page.combat.route_index=0; page.combat.enter_event("hunter"); listen()
 await capture("45-forest-hunter")
 page._choose_event(0); page._process(1.5); page._advance_dialogue()
 if not shop.state.story_progress.hunter_saved: failures+=1
 page.leave(); page=null; await process_frame
 var rng:=RandomNumberGenerator.new()
 var before_customer_draw: Dictionary=shop.state.customer_memory.duplicate(true)
 for n in range(2000):
  shop.customer_rng.seed=n
  var next: int=shop._next_customer_index()
  shop.state.customer_memory=before_customer_draw.duplicate(true)
  if next==4: shop.customer_rng.seed=n; break
 await shop._next_trade()
 shop._set_dialogue_line(0,true)
 if shop.customer_index!=4: failures+=1
 await capture("45-forest-hunter-customer")
 start()
 # Six completed ordinary fights are a depth fixture; this boss itself uses real attacks.
 page.combat.encounter=6; page.combat.event_streak=2; page.combat.next_node()
 fight()
 if page.combat.phase!="victory":
  failures+=1; print("TREE_FAILED ",page.combat.phase," hp=",page.combat.hp); quit(1); return
 await capture("45-forest-heart-loot")
 print("STORY_TREE_VICTORY hp=",page.combat.hp," elapsed=",page.combat.elapsed)
 pickup(); page.leave(); page=null; await process_frame
 shop.customer_index=0; shop.get_node("ArtLayers").set_customer(load(shop.CUSTOMERS[0].portrait))
 shop._apply_customer_profile()
 var heart: Array=shop.state.items.filter(func(i): return i.key=="moonheart" and i.owner=="player" and i.zone=="bag")
 if heart.is_empty(): failures+=1; quit(1); return
 shop.state.move_item(heart[0].id,"counter",Vector2i(0,0),false)
 shop._settle()
 shop._set_dialogue_line(1,true)
 if shop.state.story_progress.stage!="delivered": failures+=1
 await capture("45-forest-heart-sale")
 start(); page.combat.next_node()
 await capture("45-forest-stag-ready")
 for item in page.state.items.duplicate():
  if item.zone=="bag" and item.key=="power": page.combat.use_item(item.id); break
 page._fight(); page._process(3.0)
 if page.combat.hp!=1 or page.combat.phase!="story": failures+=1
 await capture("45-forest-one-hp")
 page._advance_dialogue()
 await capture("45-forest-rescue")
 page._advance_dialogue(); page._advance_dialogue()
 var ticks:=0
 var arrow_seen:=false
 while page.combat.phase=="battle" and ticks<1000:
  feed(); page._process(0.1); ticks+=1
  if page.ally_attack_time>0 and not arrow_seen:
   page._process(0.12)
   await capture("45-forest-ally-attack"); arrow_seen=true
 if page.combat.phase!="story" or page.combat.enemy_hp!=0:
  failures+=1; print("STAG_FAILED ",page.combat.phase," hp=",page.combat.hp); quit(1); return
 page._advance_dialogue(); page._advance_dialogue()
 await capture("45-forest-victory-talk")
 print("STORY_STAG_VICTORY hp=",page.combat.hp," elapsed=",page.combat.elapsed)
 page._advance_dialogue()
 if shop.state.story_progress.stage!="recruited": failures+=1
 pickup(); page.leave(); page=null; await process_frame
 shop.shutter_closed=true; shop._door(); shop.modal.select("sylvie")
 await capture("45-forest-companion-cards")
 shop.modal.departed.emit("sylvie"); page=shop.exploration; page.set_process(false)
 page.state.bag_size=Vector2i(12,8)
 page.combat.event_streak=2; page.combat.next_node()
 if page.combat.companion!="sylvie" or page.combat.enemy.get("quest",false): failures+=1
 await capture("45-forest-next-outing")
 print("FOREST_STORY_PREVIEW: failures=",failures," stage=",shop.state.story_progress.stage," companion=",page.combat.companion)
 quit(1 if failures else 0)
