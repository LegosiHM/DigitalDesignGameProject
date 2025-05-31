shader_type canvas_item;

uniform bool hover = false;
uniform vec4 glow_color : source_color = vec4(2.0, 2.8, 2, 1.0); // full alpha

void fragment() {
    COLOR = vec4(1.0); // Fully transparent
    if (hover) {
        COLOR = glow_color * 3.0; // HDR glow trigger (needs WorldEnvironment glow)
    }
}
