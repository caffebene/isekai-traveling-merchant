extends SceneTree
const Events = preload("res://scripts/forest_events.gd")
var page
var failures := 0
func _initialize() -> void:
 call_deferred("run")
func capture(name_value: String) -> void:
 page.refresh(); page.queue_redraw()
 await process_frame
 await process_frame
 await create_timer(0.10).timeout
 if DisplayServer.get_name() != "headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://docs/testing/previews/unified-ui/%s-%dx%d.png" % [name_value,root.size.x,root.size.y])
func show_event(id: String, seed_value := 0) -> void:
 page.combat.clear_loot()
 page.combat.route_index+=1
 page.combat.memory.step+=1
 page.combat.rng.seed=seed_value
 if not page.combat.enter_event(id):
  failures+=1
 page.arrival=1
 page.event_animation=0
 page.attack_time=0
 page.player_hit=0
 page.enemy_hit=0
 page.enemy_lunge=0
 page.reward_flight=0
 page.floats.clear()
 page.notice=""
 page.refresh()
func listen() -> void:
 while not page.combat.choices_available():
  page._advance_dialogue()
func finish() -> void:
 page._process(1.5)
 while page.combat.phase == "event_result":
  page._advance_dialogue()
func pickup() -> void:
 for item in page.state.items.duplicate():
  if item.zone == "loot":
   page._auto_pickup_loot(item.id)
 page.combat.clear_loot()
func branch_seed(branch: int) -> int:
 var rng := RandomNumberGenerator.new()
 for n in range(100):
  rng.seed=n
  if rng.randi_range(0,1) == branch:
   return n
 return 0
func run() -> void:
 var scene = load("res://main.tscn").instantiate()
 root.add_child(scene)
 await process_frame
 scene.state.bag_size=Vector2i(8,6)
 # A reproducible equipped test fixture; all event changes use the real selection API.
 for key in ["tempered_sword","ore","bread","potion","power","berry"]:
  scene.state.add_item(key,"bag","player")
 scene._start_exploration()
 page=scene.exploration
 page.state.bag_size=Vector2i(8,6)
 page.set_process(false)
 show_event("chest",7)
 await capture("37-forest-first-dialogue")
 listen(); await capture("26-forest-chest")
 for n in range(3):
  if n>0:
   show_event("chest"); listen()
  page._choose_event(2); finish()
 show_event("chest"); page._advance_dialogue()
 await capture("38-forest-chest-memory")
 listen(); page._choose_event(1)
 page._process(0.5); await capture("27-forest-event-result")
 page._process(1.0); await capture("39-forest-result-dialogue")
 finish(); await capture("28-forest-event-loot"); pickup()
 # A baseline normal fight uses real elapsed-time attacks.
 page.combat.phase="idle"; page.combat.event={}; page.combat.next_encounter()
 await capture("11-exploration-ready")
 page._fight(); page._process(2.65); await capture("12-exploration-battle")
 while page.combat.phase == "battle":
  page._process(0.1)
 if page.combat.phase != "victory":
  failures+=1
 page.combat.clear_loot()
 # Select a real moving-mushrooms plot with a deterministic generator seed.
 var mushroom_seed := 0
 for n in range(100):
  page.combat.rng.seed=n
  if Events.build("mushrooms",page.combat.memory,page.combat.rng).variant == "moving":
   mushroom_seed=n; break
 show_event("mushrooms",mushroom_seed)
 listen(); await capture("40-forest-mushrooms")
 page.combat.rng.seed=branch_seed(1); page._choose_event(0); finish(); page.combat.clear_loot()
 show_event("frog"); listen(); await capture("30-forest-frog")
 page._choose_event(1); finish()
 show_event("court"); listen(); await capture("29-forest-court")
 page._choose_event(0); finish()
 show_event("well"); listen(); await capture("31-forest-well")
 page._choose_event(1); finish(); pickup()
 page.combat.memory.pending.filter(func(t): return t.id == "collector")[0].due=0
 page.combat.next_node(); page.combat.event={}
 if not page.combat.boss:
  failures+=1
 await capture("32-forest-boss-ready")
 # Actual consumables and combat clock, no direct damage/HP change to clear the boss.
 for key in ["bread","power","potion"]:
  for item in page.state.items.duplicate():
   if item.zone == "bag" and item.key == key:
    page.combat.use_item(item.id)
 page._fight(); page._process(3.0)
 await capture("33-forest-boss-debt")
 var repair_seen := false
 var ticks := 0
 while page.combat.phase == "battle" and ticks<1000:
  if page.combat.hp <= 40:
   for item in page.state.items.duplicate():
    if item.zone == "bag" and item.key in ["bread","steak"]:
     page.combat.use_item(item.id)
  page._process(0.1)
  if page.repair_time>1.7 and not repair_seen:
   await capture("34-forest-boss-repair"); repair_seen=true
  ticks+=1
 print("BOSS_RESULT ",page.combat.phase," hp=",page.combat.hp," attack=",page.combat.enemy.attack," build=",page.combat.build_summary())
 await capture("35-forest-finish")
 if page.combat.phase != "victory" or not page.continue_button.visible:
  failures+=1
 await capture("36-forest-large-bag")
 page.state.bag_size=Vector2i(12,8)
 await capture("13-loot-large")
 if page.state.items.filter(func(i): return i.zone == "bag").is_empty():
  quit(1); return
 var item: Dictionary=page.state.items.filter(func(i): return i.zone == "bag")[0]
 page.pointer=page.item_rect(item).get_center(); page._sync_item_hover()
 await capture("14-tooltip"); page._hide_item_hover()
 pickup(); page.combat.event_streak=2
 page._begin_travel(); page._process(page.TRAVEL_DURATION*0.5)
 await capture("42-forest-travel-blur")
 page._process(page.TRAVEL_DURATION*0.5); page._process(page.ARRIVAL_DURATION)
 await capture("41-forest-after-boss")
 print("INFINITE_FOREST_PREVIEW: phase=%s encounters=%d hp=%d failures=%d" % [page.combat.phase,page.combat.route_index+1,page.combat.hp,failures])
 page.combat.begin_battle(); page.combat.hp=1; page.combat.end_turn()
 await capture("15-defeat"); await capture("35-forest-defeat")
 quit(1 if failures else 0)
