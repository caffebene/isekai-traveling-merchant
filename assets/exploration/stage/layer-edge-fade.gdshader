shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D layer_texture : source_color, filter_linear_mipmap;
uniform vec4 layer_tint : source_color = vec4(1.0);

void fragment() {
    vec4 texel = texture(layer_texture, UV);
    ALBEDO = texel.rgb * layer_tint.rgb;
    ALPHA = texel.a * layer_tint.a;
}
