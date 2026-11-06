// Mejora visual: cielo del jardín dibujado en una esfera que sigue a la cámara (no usa el Sky de Godot: cambiar los colores de un
// Sky obliga a recalcular su mapa de reflejos, y acá el color cambia a lo largo de todo el nivel).
// Degradé, sol con halo, nubes de dos tonos estilo dibujo animado y estrellas.
shader_type spatial;
render_mode unshaded, cull_front, fog_disabled, shadows_disabled;

uniform vec3 sky_top : source_color = vec3(0.16, 0.48, 0.92);
uniform vec3 sky_horizon : source_color = vec3(0.76, 0.9, 0.98);
uniform vec3 cloud_light : source_color = vec3(1.0);
uniform vec3 cloud_shadow : source_color = vec3(0.72, 0.84, 0.95);
uniform vec3 sun_disc : source_color = vec3(1.0, 0.97, 0.8);
uniform vec3 sun_dir = vec3(0.45, 0.34, -1.0);
uniform float cloud_amount = 0.46;
uniform float stars = 0.0;
uniform float scroll = 0.0;

varying vec3 ray;

void vertex() {
	ray = (MODEL_MATRIX * vec4(VERTEX, 0.0)).xyz;
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
	return noise2(p) * 0.55 + noise2(p * 2.03 + 11.0) * 0.3 + noise2(p * 4.1 + 5.0) * 0.15;
}

void fragment() {
	vec3 d = normalize(ray);
	float up = clamp(d.y, -0.2, 1.0);
	vec3 color = mix(sky_horizon, sky_top, pow(smoothstep(-0.02, 0.62, up), 0.75));

	// Sol: disco nítido y halo suave.
	vec3 s = normalize(sun_dir);
	float facing = max(dot(d, s), 0.0);
	float disc = smoothstep(0.9975, 0.9985, facing);
	color += sun_disc * (pow(facing, 90.0) * 0.45 + pow(facing, 10.0) * 0.16);
	color = mix(color, sun_disc * 1.25, disc);

	// Estrellas: se ven donde no hay nubes.
	float star_mask = 0.0;
	if (stars > 0.001 && up > 0.02) {
		vec2 star_uv = vec2(atan(d.x, -d.z) * 150.0, up * 210.0);
		vec2 cell = floor(star_uv);
		float pick = hash21(cell);
		float twinkle = 0.6 + 0.4 * sin(TIME * (1.0 + pick * 3.0) + pick * 40.0);
		float round_star = smoothstep(0.42, 0.1, length(fract(star_uv) - 0.5)); // Puntos redondos, no cuadraditos.
		star_mask = step(0.982, pick) * round_star * twinkle * stars * smoothstep(0.03, 0.2, up);
	}

	// Nubes de dibujo animado: base plana y copete de bultos. Dos capas, la lejana más chica y más pálida.
	float angle = atan(d.x, -d.z);
	float cover = 0.0;
	float lit = 0.0;
	for (int layer = 0; layer < 2; layer++) {
		float fl = float(layer);
		float base = mix(0.2, 0.1, fl);
		float size = mix(0.13, 0.065, fl);
		vec2 q = vec2(angle * mix(5.0, 9.0, fl) + scroll * mix(0.0035, 0.0015, fl) + TIME * mix(0.006, 0.003, fl) + fl * 17.0, fl * 3.0);
		float mask_big = noise2(q);
		float bumps = mask_big * 0.65 + noise2(q * 3.1) * 0.25 + noise2(q * 7.3) * 0.1;
		float top = max(bumps - (0.86 - cloud_amount * 0.62), 0.0) * size * 3.6;
		if (top > 0.0) {
			float wob = (noise2(q * 4.0) - 0.5) * 0.008;
			float inside = smoothstep(base + top + 0.002, base + top, up) * smoothstep(base + wob - 0.002, base + wob, up);
			if (inside > cover) {
				cover = inside;
				lit = smoothstep(base + top * 0.32, base + top * 0.36, up);
			}
		}
	}
	cover *= smoothstep(0.0, 0.06, up);
	color += vec3(star_mask);
	color = mix(color, mix(cloud_shadow, cloud_light, lit), cover);
	ALBEDO = color;
}
