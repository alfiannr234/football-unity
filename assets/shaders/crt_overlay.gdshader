shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform float crt_strength : hint_range(0.0, 1.0) = 0.35;
uniform float scanline_count = 320.0;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.22;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec4 col = texture(screen_texture, uv);
	if (crt_strength > 0.001) {
		float scan = sin(uv.y * scanline_count * 3.14159265) * 0.5 + 0.5;
		float line_factor = mix(1.0, 0.94 + 0.06 * scan, crt_strength);
		vec2 d = uv - vec2(0.5);
		float vig = 1.0 - dot(d, d) * vignette_strength * crt_strength * 1.15;
		// Subtle contrast & color vibrancy lift for crisp broadcast clarity
		col.rgb = ((col.rgb - vec3(0.5)) * 1.04 + vec3(0.5)) * line_factor * vig;
		col.rgb = clamp(col.rgb, vec3(0.0), vec3(1.0));
	}
	COLOR = col;
}
