extends RefCounted
## Pure recipe evaluation shared by previews, recipe drawings and overnight settlement.
const ORES = ["copper_ore", "ore"]
const FUELS = {
 "slime_mucus": {"purity":60, "multiplier":1.0},
 "ancient_wood": {"purity":100, "multiplier":1.5},
}
const SHAPES = {
 "sword": [Vector2i(0,0),Vector2i(0,1),Vector2i(0,2)],
 "axe": [Vector2i(0,0),Vector2i(1,0),Vector2i(0,1),Vector2i(0,2)],
 "pickaxe": [Vector2i(0,0),Vector2i(1,0),Vector2i(2,0),Vector2i(1,1),Vector2i(1,2)],
}

static func recipes() -> Array[Dictionary]:
 var result: Array[Dictionary] = []
 for shape in SHAPES:
  for ore in ORES:
   var materials: Array[String] = []
   for point in SHAPES[shape]:
    materials.append(ore)
   result.append({"shape":shape,"materials":materials,"output":("copper_" if ore == "copper_ore" else "iron_")+shape,"fuel":""})
 result.append({"shape":"sword","materials":["ore","copper_ore","ore"],"output":"tempered_sword","fuel":"ancient_wood"})
 result.append({"shape":"axe","materials":["ore","copper_ore","ore","ore"],"output":"tempered_axe","fuel":"ancient_wood"})
 return result

static func evaluate(state, id: int) -> Dictionary:
 var result := {"ready":false,"output":"","status":"摆放材料 · 隔天完成","inputs":[],"fuel_id":-1,"purity":0,"max_durability":0,"cell":Vector2i(-1,-1),"rotated":false,"fallback":false,"fuel_key":"","quality_probabilities":[]}
 var inputs: Array = state.items.filter(func(i): return i.zone == state.machine_zone(id))
 if inputs.is_empty():
  return result
 var anchor := Vector2i(999,999)
 for item in inputs:
  if not ORES.has(item.key):
   result.status = "材料区仅接受矿石"
   return result
  anchor.x = mini(anchor.x,item.cell.x)
  anchor.y = mini(anchor.y,item.cell.y)
 var placed := {}
 for item in inputs:
  placed[item.cell-anchor] = item.key
  result.inputs.append(item.id)
 var shape_found := ""
 var ordered: Array[String] = []
 for shape in SHAPES:
  if SHAPES[shape].size() != inputs.size():
   continue
  for mirror in [false,true] if shape == "axe" else [false]:
   var candidate: Array[String] = []
   for point: Vector2i in SHAPES[shape]:
    var cell := Vector2i(1-point.x,point.y) if mirror else point
    if not placed.has(cell*2):
     break
    candidate.append(placed[cell*2])
   if candidate.size() == inputs.size():
    shape_found = shape
    ordered = candidate
    break
  if shape_found != "":
   break
 if shape_found == "":
  result.status = "摆放未成形 · 不消耗材料"
  return result
 result.output = "copper_"+shape_found
 result.fallback = true
 var required_fuel := ""
 for recipe in recipes():
  if recipe.shape == shape_found and recipe.materials == ordered:
   result.output = recipe.output
   required_fuel = recipe.fuel
   result.fallback = false
   break
 var fuels: Array = state.items.filter(func(i): return i.zone == state.machine_fuel_zone(id))
 if fuels.is_empty():
  result.status = "缺少燃料 · 不消耗材料"
  return result
 fuels.sort_custom(func(a,b): return a.cell.y < b.cell.y or (a.cell.y == b.cell.y and a.cell.x < b.cell.x))
 var fuel: Dictionary = fuels[0]
 if not FUELS.has(fuel.key):
  result.status = "燃料无效 · 不消耗材料"
  return result
 for other in fuels:
  if other.key != fuel.key:
   result.status = "燃料区只能放同一种燃料"
   return result
 if required_fuel != "" and fuel.key != required_fuel:
  result.status = "需要「%s」" % state.CATALOG[required_fuel].name
  return result
 result.fuel_key = fuel.key
 result.quality_probabilities = state.Quality.PROBABILITIES[fuel.key].duplicate()
 result.fuel_id = fuel.id
 result.purity = FUELS[fuel.key].purity
 result.max_durability = roundi(state.CATALOG[result.output].get("base_durability",20)*FUELS[fuel.key].multiplier)
 var probe := {"key":result.output,"rotated":false,"id":-1}
 result.cell = state.free_cell(probe,state.machine_output_zone(id))
 if result.cell.x < 0:
  probe.rotated = true
  result.cell = state.free_cell(probe,state.machine_output_zone(id))
  result.rotated = true
 if result.cell.x < 0:
  result.status = "产出空间不足 · 暂停加工"
  return result
 result.ready = true
 result.status = "搭配不符 → 最低级成品" if result.fallback else "配方就绪 · 明日产出"
 return result
