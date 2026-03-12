shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

uniform float intensity : hint_range(0.0, 3.0) = 0.0;

uniform vec4 poison_tint : source_color = vec4(0.08, 0.45, 0.03, 1.0);
uniform float warp_strength : hint_range(0.0, 0.05) = 0.012;
uniform float wave_speed : hint_range(0.0, 5.0) = 1.8;
uniform float vignette_radius : hint_range(0.0, 1.0) = 0.55;
uniform float vignette_softness : hint_range(0.0, 1.0) = 0.45;
uniform float desaturation : hint_range(0.0, 1.0) = 0.3;
uniform float pulse_speed : hint_range(0.0, 5.0) = 0.9;

void fragment() {
	float t = TIME;
	float eff = intensity;

	vec2 uv = SCREEN_UV;

	float warp1_x = sin(uv.y * 8.0 + t * wave_speed) * warp_strength * eff;
	float warp1_y = cos(uv.x * 6.0 + t * wave_speed * 0.7) * warp_strength * eff;
	float warp2_x = sin(uv.y * 20.0 + t * wave_speed * 2.1 + 1.5) * warp_strength * 0.4 * eff;
	float warp2_y = cos(uv.x * 15.0 + t * wave_speed * 1.6) * warp_strength * 0.4 * eff;

	float swirl_angle = eff * 0.08 * sin(t * 0.5);
	float cx = uv.x - 0.5;
	float cy = uv.y - 0.5;
	float swirl_x = cx * cos(swirl_angle) - cy * sin(swirl_angle) + 0.5 - uv.x;
	float swirl_y = cx * sin(swirl_angle) + cy * cos(swirl_angle) + 0.5 - uv.y;

	vec2 warped_uv = uv + vec2(warp1_x + warp2_x, warp1_y + warp2_y) + vec2(swirl_x, swirl_y) * eff * 0.5;
	warped_uv = clamp(warped_uv, 0.001, 0.999);

	vec4 screen_color = texture(screen_texture, warped_uv);

	float aberration = eff * 0.005;
	float r = texture(screen_texture, warped_uv + vec2(aberration, 0.0)).r;
	float b = texture(screen_texture, warped_uv - vec2(aberration, 0.0)).b;
	screen_color.rgb = vec3(r, screen_color.g, b);

	float luma = dot(screen_color.rgb, vec3(0.299, 0.587, 0.114));
	screen_color.rgb = mix(screen_color.rgb, vec3(luma), desaturation * eff);

	vec2 centered = uv - 0.5;
	float dist = length(centered);
	float vign = smoothstep(vignette_radius, vignette_radius - vignette_softness, dist);
	
	float pulse = 0.5 + 0.5 * sin(t * pulse_speed);
	float edge_mask = 1.0 - vign; // 0 at center, 1 at edges
	float tint_amount = edge_mask * eff * mix(0.5, 0.85, pulse);
	screen_color.rgb = mix(screen_color.rgb, poison_tint.rgb, tint_amount);

	float dark_edges = edge_mask * eff * 0.35;
	screen_color.rgb = mix(screen_color.rgb, poison_tint.rgb * 0.15, dark_edges);

	COLOR = vec4(screen_color.rgb, 1.0);
}