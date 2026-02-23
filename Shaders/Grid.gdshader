shader_type canvas_item;
render_mode blend_add;

uniform vec2 grid_size = vec2(8.0, 8.0);
uniform vec2 offset = vec2(0.0, 0.0);
uniform float contrast = 1000.0;
uniform float line_width = 0.1;

uniform vec4 line_colour : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 background_colour : source_color = vec4(1.0, 1.0, 1.0, 0.0);

float soft_line(float x)
{
    return clamp(cos(x * PI) * contrast - (contrast - line_width), 0.0, 1.0);
}

vec2 square_grid(vec2 uv)
{
//    return step(fract(uv / grid_size + line_width * 0.5), vec2(line_width));
   // uv *= 3.2;        // What even is this number?
    return vec2(soft_line(uv.x), soft_line(uv.y));
}

void fragment()
{
    vec2 grid = square_grid((SCREEN_UV+ offset) * grid_size);
    float value = clamp(grid.x + grid.y, 0.0, 1.0);
    COLOR *= mix(background_colour, line_colour, value);
}