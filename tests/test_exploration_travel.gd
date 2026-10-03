extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
 checks+=1
 if not ok:
  failures+=1
  push_error(message)
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var page = load("res://scripts/exploration.gd").new()
 page.state = load("res://scripts/trade_state.gd").new()
 root.add_child(page)
 await process_frame
 page.set_process(false)
 check(not page.get_children().any(func(n): return n is SubViewport),"static background has no multi-layer viewport")
 page.combat.rng.seed=1
 page._primary(); page._process(page.TRAVEL_DURATION*0.4)
 check(page.traveling and page.combat.route_index == -1,"walking defers encounter generation")
 check(page.combat.elapsed == 0 and page.combat.hp == 60,"walking does not tick combat")
 page._process(page.TRAVEL_DURATION*0.6); page._process(page.ARRIVAL_DURATION)
 check(not page.traveling and page.combat.route_index == 0,"arrival generates exactly one encounter")
 page.combat.enter_event("chest"); page.arrival=1; page.refresh()
 check(page.dialogue_button.visible and not page.event_buttons[0].visible,"introduction precedes choices")
 while not page.combat.choices_available():
  page._advance_dialogue()
 check(not page.dialogue_button.visible and page.event_buttons[0].visible,"final dialogue opens choices")
 check(page.event_buttons[2].position.y == 438,"options occupy no hint rows")
 page._choose_event(2)
 check(not page.combat.can_collect(),"result animation blocks collection")
 page._process(1.5)
 check(page.combat.phase == "event_result" and page.dialogue_button.visible,"result waits for reading")
 page._advance_dialogue()
 check(page.combat.can_collect() and page.continue_button.visible,"choice result permits indefinite continuation")
 page.combat.event_streak=2
 page._continue_exploration(); page._process(1); page._process(page.ARRIVAL_DURATION)
 check(page.combat.phase == "ready" and page.combat.encounter == 1,"battle follows event pacing")
 page._fight(); page._process(0.1)
 check(page.combat.elapsed > 0,"combat timer resumes after arrival")
 page.combat.attack(999)
 page._continue_exploration()
 check(not page.traveling and page.confirm_action == "next","unpicked loot still confirms loss")
 page._continue_exploration()
 check(page.traveling and not page.has_loot(),"confirmed continuation discards loot")
 page._process(1); page._process(page.ARRIVAL_DURATION)
 page.combat.phase="victory"; page.combat.boss=true; page.refresh()
 check(page.continue_button.visible and page.victory_return_button.visible,"boss victory offers continue and return")
 page._begin_travel()
 check(page.traveling,"no route cap after boss")
 page.free()
 print("TRAVEL: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
