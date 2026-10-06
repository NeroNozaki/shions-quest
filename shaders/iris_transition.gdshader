shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;  // 0 = fully open, 1 = fully closed
uniform vec2 center = vec2(0.5, 0.5);

void fragment() {
	// Keep it a perfect circle even on non-square viewports
	vec2 uv = UV - center;
	uv.x *= SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;   // aspect correction

	float dist = length(uv);
	float radius = mix(1.5, 0.0, progress);   // 1.5 covers the corners

	COLOR.rgb = vec3(0.0);                   // pure black
	COLOR.a = step(radius, dist);            // outside the circle = black
}
