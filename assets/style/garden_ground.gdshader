// Mejora visual: suelo del jardín por zonas, dibujado por completo en el shader (sin texturas importadas).
// Césped con franjas de corte, mantillo con virutas, huerta con surcos, tierra húmeda con musgo y patio de baldosas.
// Las mismas 3 bandas de luz que el resto del estilo toon.
shader_type spatial;
render_mode specular_disabled;

uniform float edge_lawn = 64.0;
uniform float edge_bed = 185.0;
uniform float edge_patch = 262.0;
uniform float edge_shade = 294.0;
uniform float mid_band = 0.62;
uniform float band_softness = 0.03;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float noise2(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x), mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm2(vec2 p) {
	return noise2(p) * 0.6 + noise2(p * 2.1 + 7.3) * 0.28 + noise2(p * 4.3 + 3.1) * 0.12;
}

vec3 bands(vec3 a, vec3 b, vec3 c, float n) {
	return n < 0.42 ? a : (n < 0.58 ? b : c);
}

void fragment() {
	vec2 p = world_pos.xz;
	float dist = length(world_pos - (INV_VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz);
	float detail = 1.0 - smoothstep(26.0, 70.0, dist); // A lo lejos el dibujo se aplana: evita el centelleo.
	float wobble = (noise2(p * 0.11) - 0.5) * 12.0; // Los límites entre zonas son orgánicos, no una línea recta.
	float bx = world_pos.x + wobble;
	float n = fbm2(p * 0.42);
	float fine = noise2(p * 3.4);

	// Césped: dos verdes con franjas de corte, más manchas de trébol.
	float mow = step(0.5, fract(p.y * 0.17 + noise2(p * 0.05) * 0.2));
	vec3 lawn = bands(vec3(0.36, 0.5, 0.25), vec3(0.42, 0.57, 0.28), vec3(0.49, 0.63, 0.32), n + (mow - 0.5) * 0.16 * detail);
	lawn = mix(lawn, lawn * vec3(1.14, 1.12, 0.9), step(0.78, fine) * detail * 0.7);

	// Mantillo del macizo: virutas alargadas, oscuras y cálidas, con musgo.
	float chip = noise2(vec2(p.x * 2.6, p.y * 7.0) + noise2(p * 1.3) * 2.0);
	vec3 bed = bands(vec3(0.33, 0.24, 0.19), vec3(0.41, 0.3, 0.22), vec3(0.5, 0.37, 0.26), chip);
	bed = mix(bed, vec3(0.33, 0.44, 0.24), smoothstep(0.6, 0.64, n) * 0.85);

	// Huerta: surcos paralelos a X y paja.
	float furrow = sin(p.y * 2.3 + noise2(p * 0.3) * 1.2) * 0.5 + 0.5;
	vec3 soil = mix(mix(vec3(0.3, 0.21, 0.15), vec3(0.45, 0.32, 0.2), step(0.45, furrow)), vec3(0.54, 0.4, 0.25), step(0.82, furrow));
	soil = mix(soil, vec3(0.75, 0.62, 0.3), step(0.86, noise2(vec2(p.x * 5.0, p.y * 1.6))) * detail * 0.8);

	// Sombra: tierra húmeda y musgo, con manchas de luz que se mueven entre las hojas.
	vec3 shade = bands(vec3(0.17, 0.27, 0.23), vec3(0.2, 0.34, 0.26), vec3(0.25, 0.42, 0.28), n + (fine - 0.5) * 0.14);
	float dapple = smoothstep(0.62, 0.66, noise2(p * 0.42 + vec2(TIME * 0.03, -TIME * 0.018)) * 0.7 + noise2(p * 1.1 - TIME * 0.02) * 0.3);
	shade = mix(shade, shade * 1.5 + vec3(0.1, 0.13, 0.03), dapple * 0.75);

	// Patio: baldosas en hilada con juntas y pasto entre ellas.
	vec2 tile = vec2(p.x / 2.4, p.y / 1.3);
	float row = floor(tile.y);
	tile.x += mod(row, 2.0) * 0.5;
	vec2 id = floor(tile);
	vec2 f = abs(fract(tile) - 0.5);
	float joint = step(0.45, f.x) + step(0.42, f.y);
	float tone = hash21(id);
	vec3 slab = mix(vec3(0.5, 0.45, 0.43), vec3(0.66, 0.6, 0.55), tone);
	slab = mix(slab, slab * 0.84, step(0.6, noise2(p * 1.6 + id)) * detail);
	vec3 patio = mix(slab, mix(vec3(0.17, 0.2, 0.14), vec3(0.26, 0.4, 0.17), step(0.55, fine)), clamp(joint, 0.0, 1.0) * detail);

	vec3 color = lawn;
	color = mix(color, bed, smoothstep(edge_lawn - 2.0, edge_lawn + 2.0, bx));
	color = mix(color, soil, smoothstep(edge_bed - 2.0, edge_bed + 2.0, bx));
	color = mix(color, shade, smoothstep(edge_patch - 2.0, edge_patch + 2.0, bx));
	color = mix(color, patio, smoothstep(edge_shade - 2.0, edge_shade + 2.0, bx));
	ALBEDO = pow(color, vec3(2.2)); // Los colores de arriba están pensados como se ven en pantalla (sRGB).
	ROUGHNESS = 1.0;
}

void light() {
	float ndl = dot(NORMAL, LIGHT) * ATTENUATION;
	float level = mid_band * smoothstep(0.0, band_softness, ndl) + (1.0 - mid_band) * smoothstep(0.45 - band_softness, 0.45 + band_softness, ndl);
	DIFFUSE_LIGHT += LIGHT_COLOR / PI * level;
}
