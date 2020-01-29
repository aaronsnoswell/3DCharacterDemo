shader_type spatial;
render_mode unshaded;
render_mode depth_test_disable;

uniform vec4 color : hint_color = vec4(vec3(0.2), 1.0);

void fragment() {
	ALBEDO = color.rgb;
}
