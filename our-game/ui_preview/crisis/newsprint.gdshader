shader_type canvas_item;
render_mode unshaded;

void fragment() {
	vec4 photo = texture(TEXTURE, UV);
	float luminance = dot(photo.rgb, vec3(0.2126, 0.7152, 0.0722));
	float tone = floor(luminance * 6.0 + 0.5) / 6.0;
	vec3 ink = vec3(0.188235, 0.172549, 0.152941);
	vec3 paper = vec3(0.905882, 0.866667, 0.729412);
	COLOR = vec4(mix(ink, paper, tone), photo.a);
}
