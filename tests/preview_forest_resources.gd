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
func show_event(id: String, variant: String) -> void:
 page.combat.clear_loot()
 page.combat.route_index+=1
 page.combat.memory.step+=1
 var seed_value := 0
 for n in range(100):
  page.combat.rng.seed=n
  var event: Dictionary=Events.build(id,page.combat.memory,page.combat.rng,page.state)
  if event.get("variant","") == variant:
   seed_value=n; break
 page.combat.rng.seed=seed_value
 if not page.combat.enter_event(id):
  failures+=1
 page.arrival=1
 page.event_animation=0
 page.attack_time=0
 page.player_hit=0
 page.enemy_hit=0
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
func select_item(item: Dictionary) -> void:
 page.pointer=page.item_rect(item).position+Vector2(page.state.footprint(item)[0])*page.CELL_SIZE+Vector2(12,12)
 var click := InputEventMouseButton.new()
 click.button_index=MOUSE_BUTTON_LEFT
 click.pressed=true
 page._gui_input(click)
func choose(index: int) -> void:
 var candidates: Array=page.combat.event_items(page.combat.event.options[index])
 page._choose_event(index)
 if page.event_option_selection != "":
  select_item(candidates.back())
func branch_seed(branch: int) -> int:
 var rng := RandomNumberGenerator.new()
 for n in range(100):
  rng.seed=n
  if rng.randi_range(0,1)==branch:
   return n
 return 0
func run() -> void:
 var scene = load("res://main.tscn").instantiate()
 root.add_child(scene)
 await process_frame
 scene._start_exploration()
 page=scene.exploration
 page.set_process(false)
 page.state.bag_size=Vector2i(12,8)
 for key in ["iron_axe","copper_axe","iron_pickaxe","berry"]:
  page.state.add_item(key,"bag","player")
 page.combat.hp=35 # Injured preview fixture; healing is then applied through actual choices.
 show_event("logging","hollow"); listen()
 await capture("44-forest-logging")
 var axes: Array=page.combat.event_items(page.combat.event.options[0])
 var before: int=axes.back().durability
 page._choose_event(0)
 await capture("44-forest-tool-selection")
 page.combat.rng.seed=branch_seed(0)
 select_item(axes.back())
 if axes.back().durability != before-3 or page.active_weapon != axes.back().id:
  failures+=1
 page._process(0.15); await capture("44-forest-chopping")
 finish(); await capture("44-forest-wood-loot"); pickup()
 show_event("mining","fractured"); listen()
 await capture("44-forest-mining")
 page.combat.rng.seed=branch_seed(1)
 choose(0); page._process(0.15)
 await capture("44-forest-mining-result")
 finish(); pickup()
 show_event("camp","sleepy"); listen()
 await capture("44-forest-camp")
 choose(1); finish()
 if page.combat.hp != 54 or page.combat.memory.get("camp_fuel",0)!=1:
  failures+=1
 show_event("camp","warm"); page._advance_dialogue()
 await capture("44-forest-camp-memory")
 listen(); choose(0); finish()
 if page.combat.memory.get("camp_fuel",0)!=0:
  failures+=1
 show_event("snail","inspector"); listen()
 await capture("44-forest-snail")
 choose(0); finish(); pickup()
 show_event("snail","moving"); listen(); choose(0); finish(); pickup()
 show_event("snail","neighbor"); page._advance_dialogue()
 await capture("44-forest-snail-memory")
 listen(); choose(0); finish(); pickup()
 print("FOREST_RESOURCE_PREVIEW: failures=",failures," hp=",page.combat.hp," camp=",page.combat.memory.get("camp_fuel",0)," paid=",page.combat.memory.get("snail_paid",0))
 quit(1 if failures else 0)
