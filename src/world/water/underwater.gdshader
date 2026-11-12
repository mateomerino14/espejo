shader_type spatial;
render_mode unshaded, cull_front, depth_draw_never;
// El agua vista desde abajo: lo que hay arriba se ve verdoso, oscuro y temblando.

uniform sampler2D screen : hint_screen_texture, filter_linear_mipmap;
uniform vec3 tint : source_color = vec3(0.12, 0.26, 0.3);
uniform float murk = 0.55;
uniform float wobble = 0.012;

void fragment() {
	vec2 world = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xz;
	vec2 offset = vec2(sin(world.x * 3.0 + TIME * 1.7), cos(world.y * 2.6 + TIME * 1.3)) * wobble;
	vec3 above = textureLod(screen, SCREEN_UV + offset, 1.5).rgb;
	ALBEDO = mix(above, tint, murk);
}
