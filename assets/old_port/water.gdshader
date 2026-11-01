shader_type spatial;
render_mode cull_disabled;
varying vec3 world_pos;
void vertex() { world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
 float wave = sin(world_pos.x * 1.1 + world_pos.z * 1.7 + TIME * 1.1);
 float crossing = sin(world_pos.z * 2.7 - TIME * 0.7 + world_pos.x * 0.25);
 float sparkle = pow(max(0.0, wave * crossing), 18.0);
 ALBEDO = mix(vec3(0.12, 0.48, 0.53), vec3(0.21, 0.67, 0.65), wave * 0.12 + 0.45);
 ALBEDO += vec3(0.24,0.30,0.27) * sparkle * 0.35;
 ROUGHNESS = 0.23;
 SPECULAR = 0.7;
 NORMAL_MAP = vec3(0.5 + wave * 0.025, 0.5 + crossing * 0.025, 1.0);
}
