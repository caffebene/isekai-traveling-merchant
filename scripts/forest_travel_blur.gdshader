shader_type canvas_item;
render_mode unshaded;

uniform float blur_radius : hint_range(0.0, 12.0) = 0.0;

void fragment() {
 // Interpolate the prefiltered mip levels for a smooth, inexpensive background blur.
 COLOR = textureLod(TEXTURE, UV, log2(1.0 + blur_radius));
}
