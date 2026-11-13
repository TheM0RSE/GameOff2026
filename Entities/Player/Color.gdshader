shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture;
uniform int range_per_color = 1;

void fragment() {
    // Sample the original screen texture
    vec4 original_color = texture(screen_texture, SCREEN_UV);

    // Quantize colors 
    float new_r = float(original_color.r) * float(range_per_color);
    new_r = round(new_r) / float(range_per_color);

    float new_g = float(original_color.g) * float(range_per_color);
    new_g = round(new_g) / float(range_per_color);

    float new_b = float(original_color.b) * float(range_per_color);
    new_b = round(new_b) / float(range_per_color);

    // Poop out "Indexed color"
    COLOR = vec4(new_r,new_g,new_b,1.0);
}