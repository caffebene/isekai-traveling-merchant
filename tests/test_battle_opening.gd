extends SceneTree
const Store = preload("res://scripts/trade_state.gd")
const Combat = preload("res://scripts/exploration_state.gd")
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
 checks+=1
 if not ok:
  failures+=1
  push_error(message)
func fixture(keys: Array) -> Array:
 var s=Store.new()
 s.items.clear()
 s.bag_size=Vector2i(12,8)
 for key in keys:
  s.add_item(key,"bag","player")
 var c=Combat.new()
 c.start(s); c.rng.seed=7; c.next_encounter()
 c.enemy.hp=1000; c.enemy_hp=1000
 return [s,c]
func _initialize() -> void:
 var f=fixture(["sword","iron_sword"])
 var s=f[0]; var c=f[1]
 var first: Dictionary=s.items[0]
 var second: Dictionary=s.items[1]
 var hits: Array=[]
 c.presentation.connect(func(data):
  if data.kind == "attack": hits.append(data.weapon_id))
 var damage: int=c.weapon_damage(first)
 c.begin_battle()
 check(c.enemy_hp == 1000-damage and first.durability == 19,"opening applies actual damage and one durability")
 check(hits == [first.id],"opening uses first weapon and normal attack signal")
 check(c.elapsed == 0 and c.enemy_clock == 0 and c.basic_clock == 0 and c.hp == 60,"opening advances no time or enemy strike")
 c.begin_battle()
 check(hits.size() == 1 and first.durability == 19,"repeat start cannot duplicate opening")
 var interval: float=c.weapon_interval(second)
 c.tick(interval-0.01)
 check(hits.size() == 1,"full cooldown required after opening")
 c.tick(0.01)
 check(hits == [first.id,second.id] and second.durability == 19,"normal cooldown rotates to second weapon")
 # Opening can break a weapon without skipping the next one.
 f=fixture(["sword","iron_sword"]); s=f[0]; c=f[1]
 first=s.items[0]; second=s.items[1]; first.durability=1
 c.begin_battle(); c.tick(c.weapon_interval(second))
 check(first.durability == 0 and second.durability == 19,"opening break keeps next weapon in sequence")
 # Empty and entirely broken builds both use the existing unarmed strike.
 for keys in [[],["sword"]]:
  f=fixture(keys); s=f[0]; c=f[1]
  if not s.items.is_empty(): s.items[0].durability=0
  c.begin_battle()
  check(c.enemy_hp == 995,"empty/broken build attacks immediately unarmed")
  c.tick(2)
  check(c.enemy_hp == 990,"unarmed continuation retains two second cooldown")
 # A lethal opening immediately grants victory and cannot trigger retaliation.
 f=fixture(["sword"]); s=f[0]; c=f[1]
 c.enemy_hp=1
 c.begin_battle()
 check(c.phase == "victory" and c.enemy_hp == 0 and c.hp == 60,"lethal opening resolves victory without enemy retaliation")
 var loot_count: int=s.items.filter(func(i): return i.zone == "loot").size()
 c.begin_battle(); c.tick(100)
 check(s.items.filter(func(i): return i.zone == "loot").size() == loot_count and c.hp == 60,"opening victory cannot resolve twice")
 # Slow and fine frames preserve identical scheduling after the immediate strike.
 var slow=fixture(["sword","iron_sword"])
 var fine=fixture(["sword","iron_sword"])
 slow[1].begin_battle(); fine[1].begin_battle()
 slow[1].tick(7.0)
 for n in range(70): fine[1].tick(0.1)
 check(slow[1].enemy_hp == fine[1].enemy_hp and slow[1].hp == fine[1].hp,"frame size preserves player and enemy schedule")
 print("OPENING_ATTACK: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
