shader_type canvas_item;
// Pantalla del visor: tinte frío, grano, aberración de color y viñeta.

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float aberration = 0.004;
uniform float grain = 0.07;
uniform float desaturation = 0.35;
uniform vec3 tint : source_color = vec3(0.8, 0.9, 1.0);
uniform float vignette_start = 0.32;
uniform float vignette_end = 0.85;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 offset = (uv - 0.5) * aberration;
	vec3 color = vec3(
		texture(screen_texture, uv + offset).r,
		texture(screen_texture, uv).g,
		texture(screen_texture, uv - offset).b
	);
	float luminance = dot(color, vec3(0.299, 0.587, 0.114));
	color = mix(color, vec3(luminance), desaturation) * tint;
	float noise = fract(sin(dot(uv + fract(TIME), vec2(12.9898, 78.233))) * 43758.5453);
	color += (noise - 0.5) * grain;
	color *= smoothstep(vignette_end, vignette_start, distance(uv, vec2(0.5)));
	COLOR = vec4(color, 1.0);
}
