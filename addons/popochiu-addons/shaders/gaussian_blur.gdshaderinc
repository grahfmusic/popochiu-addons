#ifndef POPP_GAUSSIAN_BLUR_INC
#define POPP_GAUSSIAN_BLUR_INC

// Samples the screen texture with a simple radial blur kernel.
// `sample_count` controls the number of taps (minimum 2) while `radius_pixels`
// describes the radius in screen pixels.
vec3 popochiu_gaussian_blur(vec2 uv, int sample_count, float radius_pixels) {
	if (sample_count <= 1 || radius_pixels <= 0.00001) {
		return texture(SCREEN_TEXTURE, uv).rgb;
	}

	float tap_count = float(sample_count);
	vec3 accumulated = texture(SCREEN_TEXTURE, uv).rgb;
	vec2 pixel_size = SCREEN_PIXEL_SIZE.xy * radius_pixels;

	for (int i = 1; i < sample_count; i++) {
		float idx = float(i);
		// Distribute taps over a spiral to approximate a 2D gaussian kernel.
		float t = idx / (tap_count - 1.0);
		float angle = TAU * fract(idx * 0.61803398875); // golden angle spiral
		float scale = t;
		vec2 direction = vec2(cos(angle), sin(angle));
		vec2 offset = direction * pixel_size * scale;
		accumulated += texture(SCREEN_TEXTURE, uv + offset).rgb;
	}

	return accumulated / tap_count;
}

#endif // POPP_GAUSSIAN_BLUR_INC
