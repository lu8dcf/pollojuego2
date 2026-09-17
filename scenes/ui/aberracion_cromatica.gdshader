shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
// Rango reducido a máximo 0.05 para que sea sutil y no deforme en exceso
uniform float intensidad : hint_range(0.0, 0.05) = 0.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	
	if (intensidad <= 0.0001) {
		COLOR = texture(screen_texture, uv);
	} else {
		// Dirección desde el centro hacia los bordes para una distorsión natural
		vec2 dir = uv - vec2(0.5);
		vec2 offset = dir * intensidad;
		
		float r = texture(screen_texture, uv + offset).r;
		float g = texture(screen_texture, uv).g;
		float b = texture(screen_texture, uv - offset).b;
		float a = texture(screen_texture, uv).a;
		
		COLOR = vec4(r, g, b, a);
	}
}