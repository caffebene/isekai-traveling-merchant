extends RefCounted
## Instance-only weapon quality. All rolls use the caller's seeded generator.
const NAMES = ["白", "绿", "蓝", "紫", "金"]
const COLORS = [Color("dfd4bd"),Color("73a77a"),Color("6aafe6"),Color("b68ae0"),Color("e2c15b")]
const PRICES = [1.0,1.5,2.2,3.2,5.0]
const PROBABILITIES = {
 "slime_mucus":[50,30,15,4,1],
 "ancient_wood":[10,30,35,20,5],
 "customer":[35,35,20,8,2],
 "loot":[35,35,20,8,2],
}
const AFFIXES = {
 "sharp":{"name":"锋利","min":10,"max":20,"unit":"攻击"},
 "swift":{"name":"迅捷","min":8,"max":12,"unit":"攻速"},
 "sturdy":{"name":"坚固","min":20,"max":30,"unit":"最大耐久"},
 "critical":{"name":"会心","min":8,"max":12,"unit":"暴击率"},
 "leech":{"name":"汲取","min":10,"max":15,"unit":"吸血"},
}

static func tier(item: Dictionary) -> int:
 return clampi(int(item.get("quality",0)),0,4)

static func roll_quality(source: String, rng: RandomNumberGenerator) -> int:
 var weights: Array = PROBABILITIES.get(source,[100,0,0,0,0])
 return quality_at(weights,rng.randi_range(0,99))

static func quality_at(weights: Array, roll: int) -> int:
 var cumulative := 0
 for i in range(weights.size()):
  cumulative += int(weights[i])
  if roll < cumulative:
   return i
 return 4

static func roll_affixes(quality: int, rng: RandomNumberGenerator) -> Array[Dictionary]:
 var pool: Array = AFFIXES.keys()
 var result: Array[Dictionary] = []
 for i in range(clampi(quality,0,4)):
  var index := rng.randi_range(0,pool.size()-1)
  var key: String = pool.pop_at(index)
  result.append({"key":key,"value":rng.randi_range(AFFIXES[key].min,AFFIXES[key].max)})
 return result

static func bonus(item: Dictionary, key: String) -> int:
 for affix in item.get("affixes",[]):
  if affix.key == key:
   return int(affix.value)
 return 0

static func durability(item: Dictionary, base: int) -> int:
 return roundi(base*(1.0+bonus(item,"sturdy")/100.0))

static func affix_text(affix: Dictionary) -> String:
 var rule: Dictionary = AFFIXES[affix.key]
 return "%s +%d%s" % [rule.unit,affix.value,"%"]

