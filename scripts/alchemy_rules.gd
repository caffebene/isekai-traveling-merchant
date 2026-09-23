extends RefCounted
## All listed recipes are currently known. Counts matter; position/rotation/order do not.
const FUEL_YIELDS = {"slime_mucus":1,"ancient_wood":2}
const RECIPES = [
 {"ingredients":{"herb":2},"output":"potion"},
 {"ingredients":{"herb":1,"berry":2},"output":"power"},
]

static func recipes() -> Array:
 return RECIPES

static func evaluate(state, id: int) -> Dictionary:
 var result := {"ready":false,"output":"","preview_name":"","unknown":false,"status":"放入材料 · 隔天炼制","inputs":[],"cell":Vector2i(-1,-1),"rotated":false,"quantity":0,"fuel_id":-1,"placements":[]}
 var inputs: Array = state.items.filter(func(i): return i.zone == state.machine_zone(id))
 if inputs.is_empty():
  return result
 var counts := {}
 for item in inputs:
  if state.CATALOG[item.key].category != "材料":
   result.status = "材料区仅接受炼药材料"
   return result
  counts[item.key] = counts.get(item.key,0)+1
  result.inputs.append(item.id)
 result.output = "wastewater"
 result.unknown = true
 for recipe in RECIPES:
  if recipe.ingredients == counts:
   result.output = recipe.output
   result.unknown = false
   break
 result.preview_name = "？？？" if result.unknown else state.CATALOG[result.output].name
 var fuels: Array = state.items.filter(func(i): return i.zone == state.machine_fuel_zone(id))
 if fuels.is_empty():
  result.status = "缺少燃料"
  return result
 fuels.sort_custom(func(a,b): return a.cell.x < b.cell.x)
 var fuel: Dictionary = fuels[0]
 if not FUEL_YIELDS.has(fuel.key):
  result.status = "燃料无效"
  return result
 for other in fuels:
  if other.key != fuel.key:
   result.status = "燃料区只可放一种燃料"
   return result
 result.quantity = FUEL_YIELDS[fuel.key]
 result.fuel_id = fuel.id
 var reserved: Array[Rect2i] = []
 for n in range(result.quantity):
  var placement := find_space(state,result.output,state.machine_output_zone(id),reserved)
  if placement.is_empty():
   result.placements.clear()
   result.status = "产出空间不足"
   return result
  reserved.append(placement.rect)
  result.placements.append(placement)
 result.cell = result.placements[0].rect.position
 result.rotated = result.placements[0].rotated
 result.ready = true
 result.status = ""
 return result

static func find_space(state, key: String, zone: String, reserved: Array[Rect2i]) -> Dictionary:
 var probe := {"key":key,"rotated":false,"id":-1}
 for rotated in [false,true]:
  probe.rotated = rotated
  for y in range(state.zone_size(zone).y):
   for x in range(state.zone_size(zone).x):
    var cell := Vector2i(x,y)
    if not state.fits(probe,zone,cell,-1):
     continue
    var rect := Rect2i(cell,state.dimensions(probe))
    if not reserved.any(func(other): return rect.intersects(other)):
     return {"rect":rect,"rotated":rotated}
 return {}
