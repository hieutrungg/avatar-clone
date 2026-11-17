shader_type canvas_item;
render_mode unshaded;

uniform float storm = 0.0;

void fragment() {
	vec2 pixel = floor(UV * vec2(640.0, 384.0));
	float frame = floor(TIME * 24.0);
	if (storm > 0.5) {
		float gust_x = pixel.x + floor(pixel.y * (0.55 + 0.15 * sin(TIME * 2.0)));
		float band = floor(gust_x / 9.0);
		float travel = mod(pixel.y - frame * 14.0 + band * 37.0, 61.0);
		float downpour = step(mod(gust_x, 9.0), 1.0) * step(travel, 18.0);
		float hail = step(mod(gust_x + frame * 4.0, 31.0), 1.0) * step(mod(travel + band * 11.0, 41.0), 1.0);
		float sheet = 0.08 + 0.09 * pow(0.5 + 0.5 * sin(pixel.x * 0.025 + TIME * 2.7), 4.0);
		float flash = step(0.985, fract(TIME * 0.24)) * 0.30;
		COLOR = vec4(0.76, 0.87, 0.96, min(0.84, sheet + downpour * 0.47 + hail * 0.56 + flash));
	} else {
		float slanted_x = pixel.x + floor(pixel.y / 3.0);
		float column = floor(slanted_x / 18.0);
		float offset = mod(column * 37.0 + column * column * 13.0, 97.0);
		float line_y = mod(pixel.y - frame * 9.0 + offset, 97.0);
		float drop = step(mod(slanted_x, 18.0), 0.0) * step(line_y, 10.0);
		COLOR = vec4(0.69, 0.82, 0.93, drop * 0.46);
	}
}
