extends SceneTree
## Import ImageGen's alpha into the existing unrotated 96px/cell footprint.
## This is sizing/alpha cleanup only; style changes use ImageGen.
func _initialize() -> void:
 var args := OS.get_cmdline_user_args()
 var manifest_path := args[0] if not args.is_empty() else "res://assets/items/unified-generation.json"
 var definitions: Array = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
 for entry in definitions:
  var source := Image.load_from_file(entry.source)
  if source == null:
   push_error("Missing generated source: "+entry.source)
   quit(1)
   return
  source.convert(Image.FORMAT_RGBA8)
  for y in range(source.get_height()):
   for x in range(source.get_width()):
    var pixel := source.get_pixel(x,y)
    if pixel.a < 12.0/255.0:
     source.set_pixel(x,y,Color.TRANSPARENT)
  var crop := source.get_region(source.get_used_rect())
  var dims := Vector2i(entry.dims[0],entry.dims[1]) if entry.has("dims") else Vector2i(3,4) if entry.name == "alembic-machine" else Vector2i(4,4) if entry.name == "workbench-machine" else Vector2i(2,2)
  var size_value := dims*96
  var factor := minf(size_value.x*0.94/crop.get_width(),size_value.y*0.94/crop.get_height())
  crop.resize(maxi(1,roundi(crop.get_width()*factor)),maxi(1,roundi(crop.get_height()*factor)),Image.INTERPOLATE_LANCZOS)
  var result := Image.create(size_value.x,size_value.y,false,Image.FORMAT_RGBA8)
  result.fill(Color.TRANSPARENT)
  result.blit_rect(crop,Rect2i(Vector2i.ZERO,crop.get_size()),(size_value-crop.get_size())/2)
  DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://"+entry.target.get_base_dir()))
  var error := result.save_png("res://"+entry.target)
  if error != OK:
   push_error("Failed to save "+entry.target)
   quit(1)
   return
  print("Imported ",entry.target," ",size_value)
 quit()
