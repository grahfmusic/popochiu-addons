shader_type canvas_item;
render_mode unshaded;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform bool fx_enabled = true;

// Realistic CRT core
group_uniforms crt_core;
uniform bool crt_enabled = true;
uniform bool crt_use_screen_uv = true;
uniform vec2 crt_resolution = vec2(320.0, 180.0);
uniform float crt_scan_line_amount : hint_range(0.0, 1.0) = 1.0;
uniform float crt_warp_amount : hint_range(0.0, 5.0) = 0.1;
uniform float crt_noise_amount : hint_range(0.0, 0.3) = 0.03;
uniform float crt_interference_amount : hint_range(0.0, 1.0) = 0.2;
uniform float crt_grille_amount : hint_range(0.0, 1.0) = 0.1;
uniform float crt_grille_size : hint_range(1.0, 5.0) = 1.0;
uniform float crt_vignette_amount : hint_range(0.0, 2.0) = 0.6;
uniform float crt_vignette_intensity : hint_range(0.0, 1.0) = 0.4;
uniform float crt_aberration_amount : hint_range(0.0, 1.0) = 0.5;
uniform float crt_roll_line_amount : hint_range(0.0, 1.0) = 0.3;
uniform float crt_roll_speed : hint_range(-8.0, 8.0) = 1.0;
uniform float crt_scan_line_strength : hint_range(-12.0, -1.0) = -8.0;
uniform float crt_pixel_strength : hint_range(-4.0, 0.0) = -2.0;

float crt_random(vec2 uv) {
	return fract(cos(uv.x * 83.4827 + uv.y * 92.2842) * 43758.5453123);
}

vec3 crt_fetch_pixel(vec2 uv, vec2 offset) {
	vec2 pos = floor(uv * crt_resolution + offset) / crt_resolution + vec2(0.5) / crt_resolution;

	float noise = 0.0;
	if (crt_noise_amount > 0.0) {
		noise = crt_random(pos + fract(TIME)) * crt_noise_amount;
	}

	if (max(abs(pos.x - 0.5), abs(pos.y - 0.5)) > 0.5) {
		return vec3(0.0);
	}

	vec3 clr = texture(SCREEN_TEXTURE, pos, -16.0).rgb + noise;
	return clr;
}

vec2 crt_dist(vec2 pos) {
	pos *= crt_resolution;
	return -((pos - floor(pos)) - vec2(0.5));
}

float crt_gaus(float pos, float scale) {
	return exp2(scale * pos * pos);
}

vec3 crt_horz3(vec2 pos, float offset) {
	vec3 b = crt_fetch_pixel(pos, vec2(-1.0, offset));
	vec3 c = crt_fetch_pixel(pos, vec2(0.0, offset));
	vec3 d = crt_fetch_pixel(pos, vec2(1.0, offset));
	float dst = crt_dist(pos).x;
	float scale = crt_pixel_strength;
	float wb = crt_gaus(dst - 1.0, scale);
	float wc = crt_gaus(dst + 0.0, scale);
	float wd = crt_gaus(dst + 1.0, scale);
	return (b * wb + c * wc + d * wd) / max(wb + wc + wd, 1e-5);
}

float crt_scan_weight(vec2 pos, float offset) {
	float dst = crt_dist(pos).y;
	return crt_gaus(dst + offset, crt_scan_line_strength);
}

vec3 crt_tri(vec2 pos) {
	vec3 clr = crt_fetch_pixel(pos, vec2(0.0));
	if (crt_scan_line_amount <= 0.0) {
		return clr;
	}
	vec3 a = crt_horz3(pos, -1.0);
	vec3 b = crt_horz3(pos, 0.0);
	vec3 c = crt_horz3(pos, 1.0);

	float wa = crt_scan_weight(pos, -1.0);
	float wb = crt_scan_weight(pos, 0.0);
	float wc = crt_scan_weight(pos, 1.0);

	vec3 scanlines = a * wa + b * wb + c * wc;
	return mix(clr, scanlines, crt_scan_line_amount);
}

vec2 crt_warp(vec2 uv) {
	vec2 delta = uv - 0.5;
	float delta2 = dot(delta, delta);
	float delta4 = delta2 * delta2;
	float delta_offset = delta4 * crt_warp_amount;

	vec2 warped = uv + delta * delta_offset;
	return (warped - 0.5) / mix(1.0, 1.2, crt_warp_amount / 5.0) + 0.5;
}

float crt_vignette(vec2 uv) {
	uv *= 1.0 - uv;
	float vig = uv.x * uv.y * 15.0;
	return pow(vig, crt_vignette_intensity * crt_vignette_amount);
}

vec3 crt_grille(vec2 uv) {
	float unit = PI / 3.0;
	float scale = 2.0 * unit / max(crt_grille_size, 1e-5);
	float r = smoothstep(0.5, 0.8, cos(uv.x * scale - unit));
	float g = smoothstep(0.5, 0.8, cos(uv.x * scale + unit));
	float b = smoothstep(0.5, 0.8, cos(uv.x * scale + 3.0 * unit));
	return mix(vec3(1.0), vec3(r, g, b), crt_grille_amount);
}

float crt_roll_line(vec2 uv) {
	float x = uv.y * 3.0 - TIME * crt_roll_speed;
	float f = cos(x) * cos(x * 2.35 + 1.1) * cos(x * 4.45 + 2.3);
	float roll_line = smoothstep(0.5, 0.9, f);
	return roll_line * crt_roll_line_amount;
}

vec3 crt_apply(vec2 base_uv, vec2 fragcoord) {
	vec2 pos = crt_warp(base_uv);
	float line = 0.0;
	if (crt_roll_line_amount > 0.0) {
		line = crt_roll_line(pos);
	}
	vec2 sq_pix = floor(pos * crt_resolution) / crt_resolution + vec2(0.5) / crt_resolution;
	if (crt_interference_amount + crt_roll_line_amount > 0.0) {
		float interference = crt_random(sq_pix.yy + fract(TIME));
		pos.x += (interference * (crt_interference_amount + line * 6.0)) / max(crt_resolution.x, 1.0);
	}
	vec3 clr = crt_tri(pos);
	if (crt_aberration_amount > 0.0) {
		float chromatic = crt_aberration_amount + line * 2.0;
		vec2 chromatic_x = vec2(chromatic, 0.0) / max(crt_resolution.x, 1.0);
		vec2 chromatic_y = vec2(0.0, chromatic * 0.5) / max(crt_resolution.y, 1.0);
		float r = crt_tri(pos - chromatic_x).r;
		float g = crt_tri(pos + chromatic_y).g;
		float b = crt_tri(pos + chromatic_x).b;
		clr = vec3(r, g, b);
	}
	if (crt_grille_amount > 0.0) {
		clr *= crt_grille(fragcoord);
	}
	clr *= 1.0 + crt_scan_line_amount * 0.6 + line * 3.0 + crt_grille_amount * 2.0;
	if (crt_vignette_amount > 0.0) {
		clr *= crt_vignette(pos);
	}
	return clr;
}

void fragment() {
	vec2 base_uv = crt_use_screen_uv ? SCREEN_UV : UV;
	vec4 base_sample = texture(SCREEN_TEXTURE, base_uv);
	vec3 color = base_sample.rgb;
	float alpha = base_sample.a;

	if (fx_enabled && crt_enabled) {
		color = crt_apply(base_uv, FRAGCOORD.xy);
	}

	COLOR.rgb = clamp(color, 0.0, 1.0);
	COLOR.a = alpha;
}
