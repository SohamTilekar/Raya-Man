shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;

uniform float silhouette_alpha : hint_range(0.0, 1.0) = 0.6; // Opacity of silhouette
uniform float color_tolerance : hint_range(0.0, 0.1) = 0.01;

void fragment() {
	vec4 sprite_color = texture(TEXTURE, UV);
	if (sprite_color.a <= 0.01) {
		discard;
	}

	vec4 screen_color = texture(screen_texture, SCREEN_UV);

	bool colors_match = all(lessThan(abs(sprite_color - screen_color), vec4(color_tolerance)));

	vec4 result_color;

	if (colors_match) {
		result_color = sprite_color;
	} else {
		// Calculate luminance of screen color (object in front)
		float screen_luminance = dot(screen_color.rgb, vec3(0.299, 0.587, 0.114));

		// Decide silhouette color based on object brightness in front
		vec3 silhouette_rgb = screen_luminance < 0.5 ? vec3(1.0) : vec3(0.0); // White if dark, Black if light

		result_color = vec4(silhouette_rgb, silhouette_alpha * sprite_color.a);
	}

	COLOR = result_color;
}
