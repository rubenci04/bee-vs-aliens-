"""Record the local audio audit; writes only documentation inside Bee Alien 3D."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LIB = Path(r"D:\proyectos\V_Asset_Library\01_Extracted\audio")
selected = json.loads((ROOT / "dev/audio_asset_review/selected.json").read_text(encoding="utf-8"))
candidates = json.loads((ROOT / "dev/audio_asset_review/candidates.json").read_text(encoding="utf-8"))
packs = [
    ("(free)FX_Laser_Sound_Pack", "Autor no indicado", "License.txt + README.txt", "Licencia propia: uso comercial/modificación; no redistribuir originales/asset packs; crédito opcional", "APPROVED; no seleccionado"),
    ("kenney_impact-sounds", "Kenney / www.kenney.nl", "License.txt", "CC0; comercial y modificación; atribución opcional", "APPROVED; seleccionado"),
    ("kenney_interface-sounds", "Kenney / www.kenney.nl", "License.txt", "CC0; comercial y modificación; atribución opcional", "APPROVED; seleccionado"),
    ("kenney_sci-fi-sounds", "Kenney / www.kenney.nl", "License.txt", "CC0; comercial y modificación; atribución opcional", "APPROVED; seleccionado"),
    ("Sci-Fi Weapon SFX by Lentikula", "Lentikula", "Readme.txt", "CC0; comercial y modificación; atribución opcional", "APPROVED; no seleccionado"),
    ("Sonniss.com-GDC2026-GameAudioBundle", "Autores por subcarpeta; distribuido por Sonniss / https://sonniss.com", "Readme.txt + License - GDC Game Audio.pdf", "Royalty-free: comercial/modificación sin atribución; no venta como sounds sueltos, no reclamar autoría; prohíbe entrenamiento/desarrollo de IA", "APPROVED para juego; no seleccionado"),
]
lines = ["# Audio Asset Inventory", "", f"Ruta descubierta: `{LIB}`. Biblioteca sólo leída; originales intactos. La evidencia son los LICENSE/README/PDF locales, no la palabra free del nombre.", "", "| Pack | Audios / formato | Autor/fuente | Evidencia | Licencia/restricciones | Estado |", "|---|---|---|---|---|---|"]
total = 0
for name, author, evidence, license_text, status in packs:
    files = [x for x in (LIB / name).rglob("*") if x.suffix.lower() in {".wav", ".ogg", ".mp3", ".flac"}]
    total += len(files)
    formats = ", ".join(sorted({x.suffix for x in files}))
    lines.append(f"| {name} | {len(files)} / {formats} | {author} | {evidence} | {license_text} | {status} |")
lines += ["", f"Total: **{total} audios**, seis packs. 0 APPROVED WITH ATTRIBUTION, 0 PENDING, 0 REJECTED por licencia. Tres packs aprobados no usados por curación; no significa licencia rechazada.", "", f"**{len(candidates)} candidatos / {len(set(r['source'] for r in candidates))} archivos únicos revisados por decodificación y metadata**, no por escucha humana fiable: duración, onset/tail, peak y RMS. Nombres/clasificación del pack guiaron la shortlist (1–4 por cue). Datos completos: `dev/audio_asset_review/candidates.json`. No se decodificaron/importaron los 676 sonidos indiscriminadamente.", "", "## Candidatos y selección", "", "| Cue | Candidatos (rutas relativas a la biblioteca) | Principal / decisión |", "|---|---|---|"]
for cue in dict.fromkeys(r["cue"] for r in candidates):
    rows = [r for r in candidates if r["cue"] == cue]
    names = "<br>".join(f"`{r['source']}` ({r['duration']:.3f}s)" for r in rows)
    main = selected.get(cue, {}).get("source", "Placeholder procedural conservado")
    if cue == "bomb":
        main += " + lowFrequency_explosion_000.ogg (máximo dos capas)"
    if cue == "tech_death":
        main += "; reutiliza el candidato corto revisado en Bomb"
    lines.append(f"| {cue} | {names} | {main} |")
lines += ["", "## Descartes y reservas", "", "Lentikula: rifles de 2.34–2.55s y pistolas de 1.4–1.6s incluyendo cola/silencio; preferida la familia Kenney corta y coherente. FX Laser y Sonniss: legalmente utilizables, pero sin promoción porque la shortlist cubre los eventos con packs pequeños; Sonniss tiene recordings extensos, voces/gore/ambientes que no se ajustan a esta pasada. No se copiaron estos packs ni se usaron para entrenar/desarrollar IA.", "", "Organic death: slime_001 dura 4.71s y slime_000 no asegura mejora estética sin escucha; se conserva el chirp procedural sin gore. Human warning: forceField/explosion no comunica inequívocamente aviso de humano; se conserva el pulse V01. Para crate se eligió el impacto de tabla más breve; aún requiere escucha para confirmar que se percibe como ruptura y no sólo golpe.", "", "No se afirma que una duración/forma de onda demuestre calidad artística. La elección sonora final necesita playtest humano A/B."]
(ROOT / "docs/AUDIO_ASSET_INVENTORY.md").write_text("\n".join(lines) + "\n", encoding="utf-8")

provenance_path = ROOT / "audio/sfx/PROVENANCE.md"
old = provenance_path.read_text(encoding="utf-8").split("## REAL ASSETS V02")[0].strip()
old = old.replace("# Bee SFX V01 — procedencia", "# Bee SFX — procedencia\n\n## PROCEDURAL PLACEHOLDERS")
real = ["", "## REAL ASSETS V02", "", "14 WAV seleccionados, derivados de 15 OGG originales CC0 de Kenney. Los 16 placeholders originales permanecen intactos. Copias de licencias: `licenses/Kenney_SciFi.txt`, `licenses/Kenney_Impact.txt`, `licenses/Kenney_Interface.txt`.", "", "Autor: Kenney. Fuente de distribución: biblioteca local del usuario; fuente indicada por los packs: www.kenney.nl. Licencia: CC0 (http://creativecommons.org/publicdomain/zero/1.0/), atribución no obligatoria. Créditos de cortesía: `docs/THIRD_PARTY_AUDIO_CREDITS.md`.", "", "Las rutas Source siguientes son relativas a `D:\\proyectos\\V_Asset_Library\\01_Extracted\\audio`. El script `tools/integrate_audio_v02.gd` modifica únicamente las copias elegidas; nunca los originales.", ""]
for cue, record in selected.items():
    real += [f"### {cue}", f"- Original: `{record['source']}`", f"- SHA256 original: `{record['source_sha256']}`", f"- Bee: `{record['output']}` ({record['duration']:.3f}s)", f"- SHA256 Bee: `{record['output_sha256']}`", f"- Cambios: {record['edits']}; pitch baked {record['pitch_baked']}."]
    if "second_source" in record:
        real += [f"- Segunda capa CC0: `{record['second_source']}`", f"- SHA256 segunda capa: `{record['second_sha256']}`"]
    real += [""]
provenance_path.write_text(old + "\n" + "\n".join(real), encoding="utf-8")
(ROOT / "docs/THIRD_PARTY_AUDIO_CREDITS.md").write_text("# Third-party Audio Credits\n\nKenney — Sci-Fi Sounds (1.0), Impact Sounds (1.0), Interface Sounds (1.0).\n\nwww.kenney.nl · CC0: http://creativecommons.org/publicdomain/zero/1.0/\n\nCrédito de cortesía; no es requisito de estos tres packs. Las copias, hashes y modificaciones están en audio/sfx/PROVENANCE.md. No se usó audio de FX Laser, Lentikula o Sonniss en gameplay V02.\n", encoding="utf-8")
print(f"AUDIT audio={total} candidates={len(candidates)} selected_cues={len(selected)} source_files=15 placeholders_preserved=16")
