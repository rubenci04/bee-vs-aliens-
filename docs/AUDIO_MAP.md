# AUDIO_MAP — qué pista suena dónde (Lote 14)

Asignación de los cuatro `.mp3` de `audio/` por nombre de archivo; ninguno quedó ambiguo, así que **no hay nada "a confirmar por Rubén"** salvo el origen y la licencia (ver `docs/AUDIO_MUSIC_AUDIT.md`). No se renombró ni se borró ningún archivo.

| Archivo | Duración | Formato | Tema | Cuándo suena | Por qué |
|---|---:|---|---|---|---|
| `Menú Principal y Pantalla de Títulos.mp3` | 2:40,7 | mp3 | `title` | Pantalla de título | El nombre dice "Menú Principal y Pantalla de Títulos". |
| `Nivel 1 El Jardín Acción Fuerte 1era opcion.mp3` | 3:01,6 | mp3 | `level` | Nivel 1 (jardín), también durante el robot mini-jefe | "Nivel 1 El Jardín". |
| `Introducción al Jefe Final 1era opcion.mp3` | 1:05,9 | mp3 | `boss` | Cuando aparece la barra de la tarántula | "Introducción al Jefe Final" (la tarántula es el jefe final del Nivel 1). |
| `Jefe Derrotado y Pantalla de Victoria.mp3` | 1:03,5 | mp3 | `victory` | Al liberar a la tarántula | "Jefe Derrotado y Pantalla de Victoria". |

Las duraciones salen de `AudioStreamMP3.get_length()` (el título y el nivel duran ≈ 3 min y se repiten en loop; el jefe también; la victoria suena una vez).
