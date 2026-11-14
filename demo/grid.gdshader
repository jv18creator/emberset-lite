shader_type spatial;
// Demo floor: dark, lit, with a faint one-metre grid that fades with distance.

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 g = abs(fract(world_pos.xz) - 0.5);
	float line = smoothstep(0.47, 0.495, max(g.x, g.y));
	float far = 1.0 - smoothstep(4.0, 16.0, length(world_pos.xz));
	vec3 base = mix(vec3(0.01, 0.012, 0.018), vec3(0.045, 0.05, 0.07), line * far);
	// Far away the floor melts into the backdrop colour, so there is no visible edge.
	float near = 1.0 - smoothstep(12.0, 34.0, length(world_pos.xz));
	ALBEDO = base * near;
	// A little self light so the floor reads the same on every renderer.
	EMISSION = mix(vec3(0.0027, 0.0031, 0.0044), base * 0.9, near);
	ROUGHNESS = 0.85;
}
