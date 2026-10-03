extends Control
## Shared alpha silhouette glow for small icons and information card previews.
const Art = preload("res://scripts/item_art.gd")
var texture: Texture2D
var quality := -1
func _draw() -> void:
 if texture == null:
  return
 var available := size-Vector2(8,8)
 var fit := minf(available.x/texture.get_width(),available.y/texture.get_height())
 var bounds := texture.get_size()*fit
 Art.draw_quality_texture(self,texture,Rect2((size-bounds)/2,bounds),quality)
