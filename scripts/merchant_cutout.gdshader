shader_type canvas_item;
// Production chroma-key compositing for the generated magenta-backed sprite.
varying vec4 sprite_tint;
void vertex() { sprite_tint = COLOR; }
void fragment() {
 vec4 c = texture(TEXTURE, UV);
 float key = min(c.r, c.b) - c.g;
 float alpha = 1.0 - smoothstep(0.12, 0.55, key);
 // Suppress magenta contamination only on keyed edge pixels.
 if (key > 0.12) {
  c.rb = mix(c.rb, vec2(c.g), (1.0 - alpha) * 0.85);
 }
 COLOR = sprite_tint * vec4(c.rgb, c.a * alpha);
}
