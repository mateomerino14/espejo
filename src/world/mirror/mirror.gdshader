shader_type spatial;
render_mode unshaded, cull_back;
// Vidrio espejado: muestra lo que ve la cámara del reflejo, algo oscurecido y manchado.

uniform sampler2D reflection : source_color, filter_linear;
uniform vec3 silver : source_color = vec3(0.86, 0.9, 0.94);
uniform float stain = 0.12;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec3 color = texture(reflection, vec2(1.0 - UV.x, UV.y)).rgb * silver;
	vec2 cell = floor(UV * 48.0);
	float spots = smoothstep(0.82, 1.0, hash(cell)) * stain;
	float edge = smoothstep(0.0, 0.08, min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y)));
	ALBEDO = color * (1.0 - spots) * mix(0.55, 1.0, edge);
}
