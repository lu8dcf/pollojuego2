shader_type canvas_item;

uniform vec4 fade_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float progress : hint_range(0.0, 1.0) = 0.0;

const float MAX_ALPHA = 0.80; 

void fragment() {
    COLOR = vec4(fade_color.rgb, fade_color.a * MAX_ALPHA * progress);
}