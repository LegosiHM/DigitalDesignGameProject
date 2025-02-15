shader_type canvas_item;

uniform sampler2D tile_texture;
uniform vec2 tile_texture_size;
uniform vec4 outline_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float outline_thickness = 2.0;

void fragment() {
    vec2 pixel_size = vec2(1.0) / tile_texture_size * outline_thickness;
    vec4 base_color = texture(tile_texture, UV);

    // Sample surrounding pixels
    vec4 left = texture(tile_texture, UV + vec2(-pixel_size.x, 0.0));
    vec4 right = texture(tile_texture, UV + vec2(pixel_size.x, 0.0));
    vec4 up = texture(tile_texture, UV + vec2(0.0, -pixel_size.y));
    vec4 down = texture(tile_texture, UV + vec2(0.0, pixel_size.y));

    // Detect tile edges based on transparency
    bool is_outline = (base_color.a > 0.1) && (left.a < 0.1 || right.a < 0.1 || up.a < 0.1 || down.a < 0.1);

    if (is_outline) {
        COLOR = outline_color;
    } else {
        COLOR = base_color;
    }
}
