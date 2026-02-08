shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float effect_strength : hint_range(0.0, 1.0) = 0.9;
uniform float rewind_speed : hint_range(0.1, 10.0) = 3.0;
uniform float jitter_amount : hint_range(0.0, 0.08) = 0.02;
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.25;
uniform float chroma_shift : hint_range(0.0, 0.02) = 0.003;
uniform float snow_amount : hint_range(0.0, 1.0) = 0.14;

float hash12(vec2 p) {
	p = fract(p * vec2(123.34, 345.45));
	p += dot(p, p + 34.345);
	return fract(p.x * p.y);
}

float line_noise(float y, float t) {
	float row = floor(y * 320.0);
	float frame = floor(t * 28.0);
	return hash12(vec2(row, frame)) * 2.0 - 1.0;
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float t = TIME * rewind_speed;

	float horizontal_jitter = line_noise(uv.y, t) * jitter_amount;
	float wave_jitter = sin((uv.y * 200.0) + (t * 22.0)) * jitter_amount * 0.2;
	float roll_center = fract(-t * 0.13);
	float roll_bar = smoothstep(0.15, 0.0, abs(uv.y - roll_center));
	float rewind_drag = roll_bar * 0.02;
	vec2 sample_uv = vec2(clamp(uv.x + horizontal_jitter + wave_jitter - rewind_drag, 0.0, 1.0), uv.y);

	float channel_shift = chroma_shift * (0.3 + roll_bar);
	float r = texture(SCREEN_TEXTURE, sample_uv + vec2(channel_shift, 0.0)).r;
	float g = texture(SCREEN_TEXTURE, sample_uv).g;
	float b = texture(SCREEN_TEXTURE, sample_uv - vec2(channel_shift, 0.0)).b;
	vec3 base_color = vec3(r, g, b);

	float luma = dot(base_color, vec3(0.299, 0.587, 0.114));
	vec3 desat_color = mix(base_color, vec3(luma), 0.45);
	vec3 rewind_tint = vec3(0.82, 0.9, 1.05);
	vec3 tinted = desat_color * rewind_tint;

	float scanline = 0.5 + 0.5 * sin((uv.y + t * 0.25) * 900.0);
	tinted *= 1.0 - (scanline * scanline_strength);

	float snow = hash12(uv * vec2(1280.0, 720.0) + vec2(t * 90.0, -t * 40.0));
	tinted += (snow - 0.5) * snow_amount;

	float vignette = smoothstep(0.95, 0.2, distance(uv, vec2(0.5)));
	tinted *= mix(0.82, 1.0, vignette);

	float boost = 0.12 * roll_bar;
	vec3 final_effect = tinted + vec3(boost);
	vec3 original = texture(SCREEN_TEXTURE, uv).rgb;
	COLOR = vec4(mix(original, final_effect, effect_strength), 1.0);
}
