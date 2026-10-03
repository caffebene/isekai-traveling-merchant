extends SceneTree
const State = preload("res://scripts/trade_state.gd")
const Art = preload("res://scripts/item_art.gd")
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok:
  push_error(message)
  failures += 1
func _initialize() -> void:
 for key in ["copper_pickaxe","iron_pickaxe"]:
  var s = State.new()
  s.items.clear()
  check(s.add_item(key,"bag","player"),"pickaxe enters bag")
  var pick: Dictionary = s.items[0]
  check(s.footprint(pick).size() == 12,"pickaxe occupies its T rather than all twenty cells")
  check(s.add_item("potion","stock","player"),"potion exists")
  var potion: Dictionary = s.items[1]
  check(s.move_item(potion.id,"bag",Vector2i(0,1),false) == "","potion fits beside the handle inside its bounds")
  check(s.bag_adjacent(pick,potion),"interlocking potion touches the actual handle")
  check(s.move_item(potion.id,"bag",Vector2i(1,1),false) != "","occupied handle rejects overlap")
  check(potion.cell == Vector2i(0,1),"failed placement preserves the original position")
  var probe := pick.duplicate()
  probe.rotated = true
  check(s.dimensions(probe) == Vector2i(5,4),"rotation preserves the artwork bounds")
  check(s.footprint(probe).has(Vector2i(4,0)) and not s.footprint(probe).has(Vector2i(0,0)),"rotation transforms the T clockwise")
  check(not s.fits(probe,"bag",Vector2i(2,0),pick.id),"rotated bounds cannot leave the bag")
  var art = Art.new()
  check(not art._footprint_has_point(pick,Rect2(0,0,96,120),Vector2(12,60)),"handle-side empty cells do not intercept clicks")
  check(art._footprint_has_point(pick,Rect2(0,0,96,120),Vector2(36,60)),"the handle remains clickable")
  art.free()
  s.items.clear()
  s.items.append(pick)
  s.bag_size = Vector2i(4,5)
  check(s.add_item("berry","bag","player"),"auto-packing uses a T-shaped empty corner")
  check(s.items[1].cell == Vector2i(0,1),"auto-packing finds internal empty cells")
  var reserved: Array[Vector2i] = s.occupied_cells(probe,Vector2i.ZERO)
  var berry: Dictionary = s.items[1].duplicate()
  berry.zone = "counter"
  var packed: Dictionary = s._customer_sale_placement(berry,reserved)
  check(not packed.is_empty() and packed.rect.position == Vector2i.ZERO,"batch packing reserves actual cells rather than rectangles")
 var s = State.new()
 s.items.clear()
 s.configure_customer("武器","",[],5000)
 s.add_item("iron_pickaxe","stock","player")
 var sword: Dictionary = s.items[0]
 check(s.move_item(sword.id,"counter",Vector2i.ZERO,true) == "","pickaxe offered for sale")
 var free_shape: Array[Vector2i] = s.occupied_cells(sword,Vector2i.ZERO)
 for y in range(4):
  for x in range(24):
   var cell := Vector2i(x,y)
   if free_shape.has(cell):
    continue
   s.add_item("berry","customer","customer")
   s.items[-1].cell = cell
 check(s.settle().begins_with("交易完成"),"sale settles into a matching irregular customer-space gap")
 check(sword.owner == "customer" and sword.cell == Vector2i.ZERO and sword.rotated,"settlement uses the planned occupied cells")
 var used := {}
 var overlaps := false
 for item in s.items:
  for cell in s.occupied_cells(item,item.cell):
   overlaps = overlaps or used.has(cell)
   used[cell] = true
 check(not overlaps and used.size() == 96,"settled customer inventory fills all cells without overlap")
 var axe := {"key":"iron_axe","rotated":false,"cell":Vector2i.ZERO,"zone":"bag"}
 var corner := {"key":"berry","rotated":false,"cell":Vector2i(0,4),"zone":"bag"}
 check(s.bag_adjacent(axe,corner),"axe handle adjacency uses its occupied edges")
 corner.cell = Vector2i(0,3)
 var diagonal := {"key":"berry","rotated":false,"cell":Vector2i(3,3),"zone":"bag"}
 check(not s.bag_adjacent(axe,diagonal),"empty bounding edges do not activate adjacency")
 var support := {"key":"ore","zone":"bag","cell":Vector2i(2,2),"rotated":false}
 var ring: Array[Vector2i] = s.bag_bonus_cells(support,support.cell)
 check(ring.size() == 8,"two by two support highlights eight orthogonal neighbor cells")
 check(not ring.has(Vector2i(1,1)) and not ring.has(Vector2i(2,2)),"bonus area excludes diagonals and own footprint")
 ring = s.bag_bonus_cells(support,Vector2i.ZERO)
 check(ring.size() == 4 and ring.all(func(cell): return cell.x >= 0 and cell.y >= 0),"bonus area clips at bag corner")
 support.key = "power"
 support.rotated = true
 ring = s.bag_bonus_cells(support,Vector2i(1,1))
 check(ring.size() == 8 and ring.has(Vector2i(4,1)) and not ring.has(Vector2i(1,3)),"rotated potion previews neighbors of the actual rotated footprint")
 support.key = "herb"
 check(s.bag_bonus_cells(support,Vector2i.ZERO).is_empty(),"ordinary material has no bonus region")
 support.key = "slime_mucus"
 support.rotated = false
 check(s.bag_bonus_cells(support,Vector2i(1,1)).size() == 8,"fuel interval support uses the same adjacent preview")
 print("PASS: %d weapon footprint checks" % checks if failures == 0 else "FAIL: %d footprint checks (%d failures)" % [checks,failures])
 quit(0 if failures == 0 else 1)
