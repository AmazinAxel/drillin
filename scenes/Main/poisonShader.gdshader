shader_type canvas_item;

uniform float intensity: hint_range(0.0, 1.0) = 0.0;
uniform float time_offset: hint_range(0.0, 100.0) = 0.0;

void fragment() {
	float t = TIME + time_offset;
	
	vec2 uv = UV;
	float wave_strength = intensity * 0.03;
	uv.x += sin(uv.y * 8.0 + t * 2.1) * wave_strength;
	uv.y += cos(uv.x * 6.0 + t * 1.7) * wave_strength;
	
	float breathe = sin(t * 1.2) * 0.5 + 0.5;
	uv += (uv - 0.5) * breathe * intensity * 0.02;
	
	vec4 base = texture(TEXTURE, uv);
	
	float aberration = intensity * 0.012;
	float r = texture(TEXTURE, uv + vec2(aberration, 0.0)).r;
	float g = base.g;
	float b = texture(TEXTURE, uv - vec2(aberration, 0.0)).b;
	base.rgb = vec3(r, g, b);
	
	vec3 poison_color = vec3(0.1, 0.9, 0.15);
	base.rgb = mix(base.rgb, base.rgb * poison_color, intensity * 0.6);
	
	vec2 center = UV - 0.5;
	float vignette = 1.0 - dot(center, center) * 2.5;
	float vignette_pulse = 1.0 - (sin(t * 1.8) * 0.5 + 0.5) * intensity * 0.4;
	base.rgb *= mix(1.0, vignette * vignette_pulse, intensity);
	
	float flash = (sin(t * 2.5) * 0.5 + 0.5) * intensity * 0.08;
	base.rgb += vec3(0.0, flash, 0.0);
	
	float gray = dot(base.rgb, vec3(0.299, 0.587, 0.114));
	base.rgb = mix(base.rgb, vec3(gray), intensity * 0.3);
	
	COLOR = base;
}