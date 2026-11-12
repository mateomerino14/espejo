shader_type canvas_item;
// La pantalla como foto revelada: tonos sepia y las esquinas más oscuras.

uniform sampler2D screen : hint_screen_texture, filter_linear;
uniform float vignette = 1.3;

void fragment() {
	vec3 color = texture(screen, SCREEN_UV).rgb;
	float light = dot(color, vec3(0.3, 0.59, 0.11));
	vec2 from_center = UV - 0.5;
	float edge = 1.0 - dot(from_center, from_center) * vignette;
	COLOR = vec4(vec3(light * 1.08, light * 0.95, light * 0.76) * edge, 1.0);
}
