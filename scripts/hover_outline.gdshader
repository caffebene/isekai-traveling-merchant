shader_type canvas_item;
uniform bool hovered = false;
void fragment() {
 vec4 base = texture(TEXTURE, UV);
 float a = 0.0;
 vec2 d = TEXTURE_PIXEL_SIZE * 3.0;
 for(int x = -1; x <= 1; x++) {
  for(int y = -1; y <= 1; y++) {
   a = max(a,texture(TEXTURE,UV+vec2(float(x),float(y))*d).a);
  }
 }
 float edge = hovered ? max(0.0,a-base.a) : 0.0;
 COLOR = vec4(mix(base.rgb,vec3(1.0),edge),max(base.a,edge));
}
