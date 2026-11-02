shader_type spatial;
render_mode specular_disabled;

uniform float resolution = 160.0;

void vertex() {
    vec4 view_pos = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
    vec4 clip_pos = PROJECTION_MATRIX * view_pos;

    float w = clip_pos.w;
    vec2 ndc = clip_pos.xy / max(abs(w), 0.0001);

    ndc = floor(ndc * resolution + 0.5) / resolution;
    clip_pos.xy = ndc * w;

    POSITION = clip_pos;
}
