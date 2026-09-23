shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix;
uniform sampler2D ground_art : source_color, filter_linear_mipmap, repeat_enable;
void fragment() {
 vec3 art = texture(ground_art, UV * 1.5).rgb;
 float value = dot(art, vec3(0.299, 0.587, 0.114));
 vec3 moonlit = mix(vec3(0.06, 0.10, 0.14), art * vec3(0.95, 1.0, 1.0), 0.88);
 float distance_fade = smoothstep(18.0, 110.0, length(VERTEX));
 ALBEDO = mix(moonlit, moonlit * vec3(0.75, 0.82, 0.90), distance_fade);
 float depth = smoothstep(-80.0, 80.0, VERTEX.z);
 float road_half_width = mix(2.0, 7.0, depth);
 float road_edge = 1.0 - smoothstep(road_half_width, road_half_width + 2.0, abs(VERTEX.x));
 if (road_edge < 0.02) {
  discard;
 }
 ALPHA = road_edge * 0.94;
}
