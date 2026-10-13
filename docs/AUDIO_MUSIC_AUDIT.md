# AUDIO_MUSIC_AUDIT — auditoría de `audio/` y música (Lote 14)

Generado con `dev/lote14/_audio_audit.gd` (formato, duración y tamaño medidos en el motor) tras implementar el `MusicManager` (ver `docs/AUDIO_MAP.md` para la asignación de los cuatro temas). La columna **Origen y licencia** queda vacía a propósito: la completa Rubén (las pistas `.mp3` no figuran en `docs/THIRD_PARTY_AUDIO_CREDITS.md` ni en `audio/sfx/PROVENANCE.md`).

## Temas musicales (4 de 4 pedidos)

| Tema | Archivo | Dónde suena | Loop |
|---|---|---|---|
| `title` | `audio/Menú Principal y Pantalla de Títulos.mp3` | Pantalla de título (arranca con la escena, fade-in de 1 s). Al pulsar Jugar se hace crossfade al tema del nivel. | Sí |
| `level` | `audio/Nivel 1 El Jardín Acción Fuerte 1era opcion.mp3` | Nivel 1 desde que empieza, durante todo el recorrido y durante el robot mini-jefe. Un reinicio (R, Shift+R) lo vuelve a empezar desde el principio. | Sí |
| `boss` | `audio/Introducción al Jefe Final 1era opcion.mp3` | Crossfade de 1,5 s (potencia constante, cruzan a −3 dB) cuando aparece la barra de vida de la tarántula. Si se muere y se reinicia en el checkpoint del jefe, vuelve el tema del nivel y el del jefe entra otra vez con su barra. | Sí |
| `victory` | `audio/Jefe Derrotado y Pantalla de Victoria.mp3` | Al liberar a la tarántula: una sola vez; los últimos 3 s bajan solos hasta el silencio. | No |

Reglas del manager (`scripts/audio/music_manager.gd`, autoload `MusicManager`; el resto del juego lo llama por `BeeMusic`, que no hace nada si el autoload no está):
- **Pausa:** la música baja 12 dB mientras el juego está en pausa (y vuelve al reanudar). El menú de pausa tiene dos deslizadores, **MÚSICA** y **EFECTOS** (0-100 %; 100 % = el volumen por defecto de cada bus; teclado o mouse).
- **Muerte:** al caer Bee la música hace fade-out en 1,6 s; al reiniciar suena el tema que corresponde.
- **Bus separado `Music`** con **−8 dB** por defecto (los efectos van por `SFX`, −3 dB, y los ambientes por `Ambience`, −6 dB). Las **explosiones grandes** (la bomba) bajan la música 4 dB un instante (0,05 s de ataque, 0,35 s de sostén, 0,8 s de vuelta).
- **Loop** activado en la importación (`loop=true` en los `.mp3.import` de título, nivel y jefe; la victoria queda sin loop). El manager lo fija también por código como respaldo.
- Valores configurables al inicio del archivo: `CROSSFADE_SECONDS`, `DEATH_FADE_SECONDS`, `PAUSE_DUCK_DB`, `EXPLOSION_DUCK_DB`, `VICTORY_TAIL_FADE`, `MUSIC_DEFAULT_DB`.

## Lo que falta (no se pidió; no se inventó)
- Música del **Nivel 2 (laguna)** y de los biomas siguientes.
- **Derrota / game over**: hoy solo hay fade-out y el sonido de derrota de Bee.
- **Robot mini-jefe**: sigue el tema del nivel (así se pidió); un tema propio sería una mejora.
- **Fases de la tarántula** (el tema del jefe es uno solo) y un **sello de checkpoint** o de zona de combate.
- **Créditos** y música del menú de pausa.

## Todos los archivos de `audio/` (55 archivos medidos)

| Archivo | Formato | Duración | Tamaño | Dónde suena | Origen y licencia |
|---|---|---:|---:|---|---|
| `audio/Introducción al Jefe Final 1era opcion.mp3` | mp3 | 65,9 s | 1,5 MB | Jefe final: al aparecer la barra de la tarántula (tema `boss`, crossfade de 1,5 s, en loop). |  |
| `audio/Jefe Derrotado y Pantalla de Victoria.mp3` | mp3 | 63,5 s | 1,5 MB | Al liberar a la tarántula (tema `victory`, una sola vez y fade al final). |  |
| `audio/Menú Principal y Pantalla de Títulos.mp3` | mp3 | 160,7 s | 3,7 MB | Pantalla de título (MusicManager, tema `title`, en loop). |  |
| `audio/Nivel 1 El Jardín Acción Fuerte 1era opcion.mp3` | mp3 | 181,6 s | 4,2 MB | Nivel 1: desde que empieza y durante el robot mini-jefe (tema `level`, en loop). |  |
| `audio/ambience/dusk_loop.wav` | wav | 22,0 s | 1,9 MB | Ambiente del atardecer del Nivel 1 (BeeAmbience, bus Ambience). |  |
| `audio/ambience/garden_loop.wav` | wav | 21,5 s | 3,6 MB | Ambiente del jardín de día (BeeAmbience, bus Ambience). |  |
| `audio/sfx/PROVENANCE.md` | md | — | 18,6 KB | Documentación de licencias (no es audio). |  |
| `audio/sfx/enemies/organic_death.wav` | wav | 0,2 s | 9,1 KB | Caída de un enemigo orgánico (cue `organic_death`). |  |
| `audio/sfx/enemies/organic_hit.wav` | wav | 0,1 s | 4,8 KB | Impacto en animal (cue `organic_hit`). |  |
| `audio/sfx/enemies/tech_death.wav` | wav | 0,3 s | 12,1 KB | Explosión de tecnología (cue `tech_death`). |  |
| `audio/sfx/enemies/tech_hit.wav` | wav | 0,1 s | 5,2 KB | Impacto en tecnología (cue `tech_hit`; también avisos de robot/araña). |  |
| `audio/sfx/environment/crate.wav` | wav | 0,3 s | 10,8 KB | Caja, roca u hormiguero que se rompe (cue `crate`). |  |
| `audio/sfx/environment/human_step.wav` | wav | 0,3 s | 11,2 KB | Pasos del humano gigante (desactivado en el Nivel 1; flujo antiguo). |  |
| `audio/sfx/environment/human_warning.wav` | wav | 0,5 s | 20,7 KB | Aviso del humano gigante (desactivado en el Nivel 1). |  |
| `audio/sfx/licenses/Kenney_Impact.txt` | txt | — | 0,6 KB | Documentación de licencias (no es audio). |  |
| `audio/sfx/licenses/Kenney_Interface.txt` | txt | — | 0,6 KB | Documentación de licencias (no es audio). |  |
| `audio/sfx/licenses/Kenney_SciFi.txt` | txt | — | 0,6 KB | Documentación de licencias (no es audio). |  |
| `audio/sfx/pickups/bomb.wav` | wav | 0,3 s | 11,2 KB | Recoger una bomba (cue `bomb_pickup`). |  |
| `audio/sfx/pickups/pollen.wav` | wav | 0,1 s | 4,3 KB | Recoger polen / liberar un animal, más agudo (cues `pollen`, `liberate`). |  |
| `audio/sfx/pickups/spread.wav` | wav | 0,2 s | 8,2 KB | Recoger Spread (cue `spread_pickup`). |  |
| `audio/sfx/player/damage.wav` | wav | 0,2 s | 8,2 KB | Bee recibe daño (cue `bee_damage`). |  |
| `audio/sfx/player/defeat.wav` | wav | 0,4 s | 18,1 KB | Bee derrotada (cue `bee_defeat`). |  |
| `audio/sfx/real/base.wav` | wav | 0,2 s | 17,3 KB | Disparo base de Bee (cue `base`). |  |
| `audio/sfx/real/bee_damage.wav` | wav | 0,3 s | 25,0 KB | Bee recibe daño (cue `bee_damage`). |  |
| `audio/sfx/real/bee_defeat.wav` | wav | 0,3 s | 22,3 KB | Bee derrotada (cue `bee_defeat`). |  |
| `audio/sfx/real/bomb.wav` | wav | 0,7 s | 60,3 KB | Alien Bomb al explotar (cue `bomb`; baja un poco la música). |  |
| `audio/sfx/real/bomb_pickup.wav` | wav | 0,3 s | 22,3 KB | Recoger una bomba (cue `bomb_pickup`). |  |
| `audio/sfx/real/crate.wav` | wav | 0,3 s | 25,9 KB | Caja, roca u hormiguero que se rompe (cue `crate`). |  |
| `audio/sfx/real/human_step.wav` | wav | 0,6 s | 51,7 KB | Pasos del humano gigante (desactivado en el Nivel 1; flujo antiguo). |  |
| `audio/sfx/real/human_step_b.wav` | wav | 0,6 s | 51,7 KB | Pasos del humano gigante (desactivado en el Nivel 1; flujo antiguo). |  |
| `audio/sfx/real/human_step_c.wav` | wav | 0,6 s | 51,7 KB | Pasos del humano gigante (desactivado en el Nivel 1; flujo antiguo). |  |
| `audio/sfx/real/melee.wav` | wav | 0,3 s | 25,9 KB | Aguijón (Z) al golpear (cue `melee`). |  |
| `audio/sfx/real/organic_charge.wav` | wav | 0,7 s | 62,1 KB | Aviso de ataque orgánico (cue `organic_charge`). |  |
| `audio/sfx/real/organic_death.wav` | wav | 0,6 s | 51,7 KB | Caída de un enemigo orgánico (cue `organic_death`). |  |
| `audio/sfx/real/organic_hit.wav` | wav | 0,1 s | 10,2 KB | Impacto en animal (cue `organic_hit`). |  |
| `audio/sfx/real/pollen.wav` | wav | 0,1 s | 11,2 KB | Recoger polen / liberar un animal, más agudo (cues `pollen`, `liberate`). |  |
| `audio/sfx/real/spider_drop.wav` | wav | 0,7 s | 62,1 KB | Araña colgante: aviso, caída y retirada (cues `spider_*`). |  |
| `audio/sfx/real/spider_retract.wav` | wav | 0,6 s | 51,7 KB | Araña colgante: aviso, caída y retirada (cues `spider_*`). |  |
| `audio/sfx/real/spider_telegraph.wav` | wav | 0,6 s | 53,4 KB | Araña colgante: aviso, caída y retirada (cues `spider_*`). |  |
| `audio/sfx/real/spread.wav` | wav | 0,3 s | 29,3 KB | Disparo Spread de Bee (cue `spread`). |  |
| `audio/sfx/real/spread_pickup.wav` | wav | 0,3 s | 25,0 KB | Recoger Spread (cue `spread_pickup`). |  |
| `audio/sfx/real/tech_death.wav` | wav | 0,6 s | 51,7 KB | Explosión de tecnología (cue `tech_death`). |  |
| `audio/sfx/real/tech_hit.wav` | wav | 0,3 s | 24,2 KB | Impacto en tecnología (cue `tech_hit`; también avisos de robot/araña). |  |
| `audio/sfx/real/ufo_approach.wav` | wav | 5,0 s | 430,7 KB | UFO / jefe UFO (Nivel 7 y flujo antiguo; no suena en el Nivel 1 actual). |  |
| `audio/sfx/real/ufo_charge.wav` | wav | 0,5 s | 38,8 KB | UFO / jefe UFO (Nivel 7 y flujo antiguo; no suena en el Nivel 1 actual). |  |
| `audio/sfx/real/ufo_death.wav` | wav | 2,2 s | 189,5 KB | UFO / jefe UFO (Nivel 7 y flujo antiguo; no suena en el Nivel 1 actual). |  |
| `audio/sfx/real/ufo_hover.wav` | wav | 4,5 s | 387,6 KB | UFO / jefe UFO (Nivel 7 y flujo antiguo; no suena en el Nivel 1 actual). |  |
| `audio/sfx/real/ufo_sting.wav` | wav | 3,4 s | 292,9 KB | UFO / jefe UFO (Nivel 7 y flujo antiguo; no suena en el Nivel 1 actual). |  |
| `audio/sfx/real/walker_charge.wav` | wav | 0,7 s | 62,1 KB | Aviso de carga del robot caminante (cue `walker_charge`). |  |
| `audio/sfx/real/wasp_overload.wav` | wav | 0,7 s | 62,1 KB | Sobrecarga de la avispa (cue `wasp_overload`). |  |
| `audio/sfx/real/wing_buzz.wav` | wav | 3,6 s | 310,1 KB | Zumbido de alas de Bee (BeeAmbience). |  |
| `audio/sfx/weapons/base.wav` | wav | 0,1 s | 3,7 KB | Disparo base de Bee (cue `base`). |  |
| `audio/sfx/weapons/bomb.wav` | wav | 0,6 s | 25,0 KB | Alien Bomb al explotar (cue `bomb`; baja un poco la música). |  |
| `audio/sfx/weapons/melee.wav` | wav | 0,1 s | 6,1 KB | Aguijón (Z) al golpear (cue `melee`). |  |
| `audio/sfx/weapons/spread.wav` | wav | 0,1 s | 4,6 KB | Disparo Spread de Bee (cue `spread`). |  |
