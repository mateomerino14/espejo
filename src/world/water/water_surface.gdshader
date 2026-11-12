shader_type spatial;
render_mode cull_back;
// Agua poca sobre la sal: devuelve el reflejo, más fuerte cuanto más rasante se mira, y la lluvia
// la pica con anillos que deforman la imagen.

uniform sampler2D reflection : source_color, filter_linear, repeat_disable;
uniform vec3 bed_color : source_color = vec3(0.05, 0.055, 0.06);
uniform float reflectivity = 0.9;
uniform float ripple_strength = 0.008;
// Anillos por metro y anillos por segundo
uniform float ripple_density = 2.5;
uniform float ripple_rate = 1.6;
// Charcos: en 0 el agua llena el rectángulo; más alto, se recorta en una mancha de borde irregular.
uniform float puddle_edge : hint_range(0.0, 1.0) = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Desplazamiento que deja cada gota: un anillo que crece y se apaga dentro de su celda.
vec2 ripples(vec2 world, float time) {
	vec2 cell = floor(world * ripple_density);
	vec2 offset = vec2(0.0);
	for (int i = -1; i <= 1; i++) {
		for (int j = -1; j <= 1; j++) {
			vec2 c = cell + vec2(float(i), float(j));
			vec2 center = (c + vec2(hash(c), hash(c + 17.0))) / ripple_density;
			float phase = fract(time * ripple_rate + hash(c + 5.0));
			vec2 to_point = world - center;
			float dist = length(to_point);
			float ring = sin((dist - phase * 0.35) * 60.0) * smoothstep(0.08, 0.0, abs(dist - phase * 0.35));
			offset += normalize(to_point + 1e-4) * ring * (1.0 - phase);
		}
	}
	return offset;
}

// Ruido liso por interpolación de valores al azar en una grilla.
float value_noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(cell);
	float b = hash(cell + vec2(1.0, 0.0));
	float c = hash(cell + vec2(0.0, 1.0));
	float d = hash(cell + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	if (puddle_edge > 0.0) {
		vec2 centered = (UV - 0.5) * 2.0;
		float wobble = value_noise(UV * 6.0) * 0.6 + value_noise(UV * 13.0) * 0.4;
		if (length(centered) > 1.0 - puddle_edge * wobble) {
			discard;
		}
	}
	vec2 world = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xz;
	vec2 uv = vec2(1.0 - SCREEN_UV.x, SCREEN_UV.y) + ripples(world, TIME) * ripple_strength;
	vec3 mirrored = texture(reflection, clamp(uv, vec2(0.001), vec2(0.999))).rgb;
	float facing = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float fresnel = mix(0.35, 1.0, pow(1.0 - facing, 3.0));
	ALBEDO = bed_color;
	ROUGHNESS = 0.05;
	SPECULAR = 0.2;
	EMISSION = mirrored * reflectivity * fresnel;
}
