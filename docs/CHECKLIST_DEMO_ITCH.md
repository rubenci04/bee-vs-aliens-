# Checklist para subir la demo a itch.io

## Antes de subir
- [ ] Plantillas de exportación instaladas y build de Windows generado (ver `docs/GUIA_EXPORT_DEMO.md`).
- [ ] Probar el `.exe` en otra PC o carpeta: título → Nivel 01 completo → vuelve al título.
- [ ] Revisar licencias y créditos: `assets/external/ASSET_PROVENANCE.md` y `docs/THIRD_PARTY_AUDIO_CREDITS.md`. Ojo: FX Laser y Sonniss **no se redistribuyen sueltos** (dentro del PCK está bien). Sonniss prohíbe usar sus sonidos para entrenar IA.
- [ ] Comprimir `builds/windows/` en `BeeAlien_demo_win64_v0.1.zip`.

## Página de itch.io
- **Nombre:** Bee Alien (demo)
- **Tipo:** Downloadable · Windows · Genre: Shooter
- **Descripción corta (≤ 140):** "Una abeja con un implante alien recupera su libertad y libera a los insectos controlados del jardín. Shmup 3D toon."
- **Descripción:** jardín gigante, una abeja diminuta contra una invasión alienígena; los animales controlados se liberan (no se matan); jefe NODO ALIEN; ~6–7 minutos, dos dificultades.
- **Controles:**
  - Mover: WASD / flechas
  - Disparar: X o clic izquierdo · Apuntar: mouse (sin mouse, auto-apuntado)
  - Aguijón: Z · Bomba alien: C
  - Pausa: Esc · Reintentar: R · Reinicio total: Shift+R
- **Capturas necesarias** (1280×720 o 1920×1080, sin HUD de debug):
  1. Título.
  2. Comienzo del jardín (Bee + flores + botella verde).
  3. Zona de combate con varios enemigos y la mira.
  4. Liberación ("LIBERADO") de un animal.
  5. Atardecer con luciérnagas y relés alien.
  6. Jefe NODO ALIEN.
  - Referencias ya generadas en `dev/visual_target/` (`noche2_*`, `noche3after_*`, `lote7_*`, `noche_title.png`).
- **Etiquetas:** shmup, bee, aliens, toon, godot, 3d, arcade.
- **Precio:** gratis / "pay what you want" (decisión del autor).
- **Visibilidad:** primero *Restricted* (solo con enlace) para probar la descarga; después pública.
