shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

// toggles
uniform bool enable_scanlines = true;
uniform bool enable_vignette = true;
uniform bool enable_curvature = true;
uniform bool enable_chromatic_aberration = true;

// scanlines
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.05;
uniform float scanline_spacing : hint_range(1.0, 8.0) = 8.0;

// vignette
uniform float vignette_strength : hint_range(0.0, 1.5) = 0.5;
uniform float vignette_softness : hint_range(0.1, 1.0) = 0.4;

// curvature
uniform float curvature : hint_range(0.0, 0.2) = 0.03;

// chromatic aberration
uniform float chroma_offset : hint_range(0.0, 5.0) = 1.2;

void fragment() {
    vec2 uv = SCREEN_UV;
    bool out_of_bounds = false;

    // --- CRT curvature ---
    if (enable_curvature) {
        //vec2 curved = uv - 0.5;
        //curved *= 1.0 + dot(curved, curved) * curvature;
        //uv = curved + 0.5;

        //if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        //    out_of_bounds = true;
        //}
    }

    if (out_of_bounds) {
        COLOR = vec4(0.0, 0.0, 0.0, 1.0);
    } else {
        // --- chromatic aberration ---
        vec4 col;
        if (enable_chromatic_aberration) {
            vec2 px = SCREEN_PIXEL_SIZE * 0.2; // 0.5 offset
            float r = texture(SCREEN_TEXTURE, uv + vec2(px.x, 0.0)).r;
            float g = texture(SCREEN_TEXTURE, uv).g;
            float b = texture(SCREEN_TEXTURE, uv - vec2(px.x, 0.0)).b;
            col = vec4(r, g, b, 1.0);
        } else {
            col = texture(SCREEN_TEXTURE, uv);
        }


        //// --- scanlines ---
       //if (enable_scanlines) {
			//// 8.0 distance 0.05 strength
            //float scanline = sin(FRAGCOORD.y * 3.1415 / 8.0) * 0.5 + 0.5;
            //col.rgb -= 0.05 * (1.0 - scanline);
        //}

        // --- vignette ---
        if (enable_vignette) {
            float dist = distance(uv, vec2(0.5));
			// 0.7 str 0.5 soft
            col.rgb *= 1.0 - smoothstep(0.5, 0.8, dist) * 0.7;
        }

        COLOR = col;
    }
}