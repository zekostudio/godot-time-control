shader_type canvas_item;

uniform sampler2D t0 : hint_screen_texture;
uniform float bloom_spread = 1;
uniform float bloom_intensity = 2;

void fragment() {
	ivec2 size = textureSize(t0, 0);

    float uv_x = SCREEN_UV.x * float(size.x);
    float uv_y = SCREEN_UV.y * float(size.y);

    vec4 sum = vec4(0.0);
    for (int n = 0; n < 9; ++n) {
        uv_y = (SCREEN_UV.y * float(size.y)) + float(bloom_spread * float(n - 4));
        vec4 h_sum = vec4(0.0);
        h_sum += texelFetch(t0, ivec2(int(uv_x) - int(4.0 * bloom_spread), int(uv_y)), 0);
        h_sum += texelFetch(t0, ivec2(int(uv_x) - int(3.0 * bloom_spread), int(uv_y)), 0);
        h_sum += texelFetch(t0, ivec2(int(uv_x) - int(2.0 * bloom_spread), int(uv_y)), 0);
        h_sum += texelFetch(t0, ivec2(int(uv_x) - int(bloom_spread), int(uv_y)), 0);
        h_sum += texelFetch(t0, ivec2(int(uv_x), int(uv_y)), 0);
        h_sum += texelFetch(t0, ivec2(int(uv_x) + int(bloom_spread), int(uv_y)), 0);
        h_sum += texelFetch(t0, ivec2(int(uv_x) + int(2.0 * bloom_spread), int(uv_y)), 0);
        h_sum += texelFetch(t0, ivec2(int(uv_x) + int(3.0 * bloom_spread), int(uv_y)), 0);
        h_sum += texelFetch(t0, ivec2(int(uv_x) + int(4.0 * bloom_spread), int(uv_y)), 0);
        sum += h_sum / 9.0;
    }

    COLOR = texture(t0, SCREEN_UV) + ((sum / 9.0) * bloom_intensity);
}
