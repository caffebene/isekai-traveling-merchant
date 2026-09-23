extends SceneTree
# Bake the generated chroma-backed image through the game's cutout material.
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var source := Image.load_from_file("res://assets/exploration/merchant-back-chroma.png")
 var viewport := SubViewport.new()
 viewport.size = source.get_size()
 viewport.transparent_bg = true
 viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
 root.add_child(viewport)
 var sprite := TextureRect.new()
 sprite.texture = ImageTexture.create_from_image(source)
 sprite.size = source.get_size()
 var material := ShaderMaterial.new()
 material.shader = load("res://scripts/merchant_cutout.gdshader")
 sprite.material = material
 viewport.add_child(sprite)
 await process_frame
 await RenderingServer.frame_post_draw
 var result := viewport.get_texture().get_image()
 var cropped := result.get_region(result.get_used_rect())
 var error := cropped.save_png("res://assets/exploration/merchant-back.png")
 print("Merchant RGBA bake: ", error, " size: ", cropped.get_size())
 quit(error)
