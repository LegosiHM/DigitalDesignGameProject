shader_type canvas_item;

uniform vec4 drop_shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.5);
uniform vec2 shadow_offset = vec2(0.0, 0.1);

uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float outline_width : hint_range(0, 20) = 10.0;
uniform int pattern : hint_range(0, 2) = 2; // 0 = diamond, 1 = circle, 2 = square
uniform bool inside = false;
uniform bool add_margins = true;

void vertex() {
    float max_offset = max(abs(shadow_offset.x), abs(shadow_offset.y));
    VERTEX *= 1.0 + 2.0 * max_offset; // Expand for shadow space

    if (add_margins) {
        VERTEX += (UV * 2.0 - 1.0) * outline_width; // Expand for outline
    }
}

vec4 sample_texture(sampler2D texture, vec2 uv) {
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        return vec4(0.0);
    }
    return texture(texture, uv);
}

bool hasContraryNeighbour(vec2 uv, vec2 texture_pixel_size, sampler2D texture) {
    for (float i = -ceil(outline_width); i <= ceil(outline_width); i++) {
        float x = abs(i) > outline_width ? outline_width * sign(i) : i;
        float offset;

        if (pattern == 0) {
            offset = outline_width - abs(x);
        } else if (pattern == 1) {
            offset = floor(sqrt(pow(outline_width + 0.5, 2) - x * x));
        } else if (pattern == 2) {
            offset = outline_width;
        }

        for (float j = -ceil(offset); j <= ceil(offset); j++) {
            float y = abs(j) > offset ? offset * sign(j) : j;
            vec2 xy = uv + texture_pixel_size * vec2(x, y);

            if ((xy != clamp(xy, vec2(0.0), vec2(1.0)) || texture(texture, xy).a <= 0.0) == inside) {
                return true;
            }
        }
    }
    return false;
}

void fragment() {
    float max_offset = max(abs(shadow_offset.x), abs(shadow_offset.y));
    vec2 uv = UV * (1.0 + 2.0 * max_offset) - vec2(max_offset);

    vec4 shadow_color = vec4(drop_shadow_color.rgb, sample_texture(TEXTURE, uv - shadow_offset).a * drop_shadow_color.a);
    vec4 original_color = sample_texture(TEXTURE, uv);

    vec2 texture_pixel_size = TEXTURE_PIXEL_SIZE;
    if (add_margins) {
        texture_pixel_size = vec2(1.0) / (vec2(1.0) / TEXTURE_PIXEL_SIZE + vec2(outline_width * 2.0));
        uv = (uv - texture_pixel_size * outline_width) * TEXTURE_PIXEL_SIZE / texture_pixel_size;
    }

    vec4 final_color = shadow_color; // Start with shadow in the background

    if (original_color.a > 0.0) {
        final_color = original_color; // Draw object over shadow
    }

    // Ensure outline detection happens on the original object, NOT the shadow
    if ((original_color.a > 0.0) == inside && hasContraryNeighbour(uv, TEXTURE_PIXEL_SIZE, TEXTURE)) {
        final_color.rgb = inside ? mix(final_color.rgb, outline_color.rgb, outline_color.a) : outline_color.rgb;
        final_color.a = max(final_color.a, outline_color.a); // Ensure the outline is fully visible
    }

    COLOR = final_color;
}
