shader_type canvas_item;

uniform bool enabled = false;

void fragment() {
	vec4 texture_color = texture(TEXTURE, UV);
	if (enabled) {
	float gray = dot(texture_color.rgb, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(vec3(gray), texture_color.a);
	} else {
		COLOR = texture_color;
}
}

