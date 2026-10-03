extends SceneTree
## Preview of the actual runtime item textures, drawn with the shared item renderer.
const Art = preload("res://scripts/item_art.gd")
const Chrome = preload("res://scripts/popup_style.gd")
const KEYS = ["sword","iron_sword","copper_sword","copper_ore","copper_axe","copper_pickaxe","iron_axe","iron_pickaxe","tempered_sword","tempered_axe","wastewater"]

func _initialize() -> void:
 run.call_deferred()

func run() -> void:
 var canvas_size := Vector2i(1280,ceili(KEYS.size()/3.0)*252+84)
 root.size = canvas_size
 root.content_scale_size = canvas_size
 var board := Art.new()
 board.size = Vector2(canvas_size)
 board.mouse_filter = Control.MOUSE_FILTER_IGNORE
 board.draw.connect(func():
  board.draw_rect(Rect2(Vector2.ZERO,Vector2(canvas_size)),Chrome.BACKGROUND)
  board.draw_string(Chrome.font(true),Vector2(28,39),"异世界旅商 · 道具图片",HORIZONTAL_ALIGNMENT_LEFT,-1,24,Chrome.HEADER_TEXT)
  for i in range(KEYS.size()):
   var key: String = KEYS[i]
   var cell := Vector2(24+(i%3)*416,64+(i/3)*252)
   var card := Rect2(cell,Vector2(400,236))
   Chrome.draw_window(board,card)
   Chrome.title(board,Art.State.CATALOG[key].name,cell+Vector2(18,32))
   var dims: Vector2i = Art.State.CATALOG[key].size
   var image_size := Vector2(dims)*24
   board._draw_item({"key":key,"zone":"stock","rotated":false},Rect2(cell+Vector2(200,139)-image_size/2,image_size),false)
 )
 root.add_child(board)
 var report: Array[Dictionary] = []
 for key in Art.State.CATALOG:
  var texture: Texture2D = Art.ITEM_TEXTURES[key]
  if not texture.resource_path.ends_with(".png"):
   push_error("Non-PNG runtime item: "+key)
   quit(1)
   return
 for key in KEYS:
  var texture: Texture2D = Art.ITEM_TEXTURES[key]
  var image := texture.get_image()
  var expected: Vector2i = Art.State.CATALOG[key].size*96
  if image.get_size() != expected or image.get_format() != Image.FORMAT_RGBA8:
   push_error("Incorrect size or RGBA: "+key)
   quit(1)
   return
  for corner in [Vector2i.ZERO,Vector2i(expected.x-1,0),expected-Vector2i.ONE,Vector2i(0,expected.y-1)]:
   if image.get_pixelv(corner).a != 0:
    push_error("Opaque corner: "+key)
    quit(1)
    return
  report.append({"key":key,"path":texture.resource_path,"width":expected.x,"height":expected.y,"rgba":true,"transparent_corners":true,"alpha_bounds":str(image.get_used_rect())})
 var file := FileAccess.open("res://docs/testing/生成道具图片验收.json",FileAccess.WRITE)
 file.store_string(JSON.stringify({"date":"2026-10-02","runtime_png_count":Art.ITEM_TEXTURES.size(),"assets":report},"  "))
 await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://docs/testing/previews/unified-ui/generated-items.png")
 print("GENERATED ITEM PREVIEW PASS: ",KEYS.size()," assets; all runtime items use PNG")
 quit()
