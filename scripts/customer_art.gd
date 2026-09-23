extends "res://scripts/item_art.gd"

## Customer portraits use the same outline offsets and color as inventory items.
@export var texture: Texture2D:
 get:
  return _texture
 set(value):
  _texture = value
  queue_redraw()

var _texture: Texture2D

func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE

func _notification(what: int) -> void:
 if what == NOTIFICATION_RESIZED:
  queue_redraw()

func _draw() -> void:
 if _texture == null:
  return
 var source_size := _texture.get_size()
 if source_size.x <= 0.0 or source_size.y <= 0.0:
  return
 var scale_value := minf(size.x/source_size.x,size.y/source_size.y)
 var draw_size := source_size*scale_value
 var portrait_rect := Rect2((size-draw_size)*0.5,draw_size)
 draw_set_transform(portrait_rect.get_center())
 _draw_texture_with_outline(_texture,draw_size)
 draw_set_transform(Vector2.ZERO)
