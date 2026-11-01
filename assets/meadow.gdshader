shader_type spatial;
render_mode cull_disabled;
varying vec3 world_pos;
void vertex() { world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
 float n = sin(world_pos.x * 0.15 + sin(world_pos.z * 0.13)) * sin(world_pos.z * 0.19);
 vec3 base = COLOR.rgb;
 ALBEDO = mix(base * vec3(0.72, 0.92, 0.48), base * vec3(0.95, 1.10, 0.70), n * 0.5 + 0.5);
 ROUGHNESS = 1.0;
}
