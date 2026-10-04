extends SceneTree
## DEV ONLY (GARDEN IDENTITY & AUDIO PASS 04). Objective signal analysis of every audio candidate in
## audition_candidates.gd: level, envelope, onset/attack, useful length, spectral centroid, band energy and
## spectral flatness (noise vs tone), plus one spectrogram sheet per category (rows in table order).
## This complements, and does not replace, listening with the audition scene (audio_audition.tscn).
##   godot --headless --path . --script res://dev/audio_audition/analyze_candidates.gd [-- only=<category>]
## Writes dev/audio_audition/analysis/metrics.tsv and analysis/<category>.png (folder has .gdignore).

const C := preload("res://dev/audio_audition/audition_candidates.gd")
const OUT := "res://dev/audio_audition/analysis/"
const N := 1024
const ROW_H := 150
const ENV_H := 36
const MAX_SECONDS := 8.0

var _cos := PackedFloat32Array()
var _sin := PackedFloat32Array()
var _window := PackedFloat32Array()


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	for k in N / 2:
		_cos.append(cos(-TAU * k / N))
		_sin.append(sin(-TAU * k / N))
	for i in N:
		_window.append(0.5 - 0.5 * cos(TAU * i / (N - 1)))
	var only := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("only="):
			only = arg.substr(5)
	var out := FileAccess.open(OUT + "metrics.tsv", FileAccess.WRITE)
	out.store_line("category\trow\tlabel\tlicense\tlength_s\tanalysed_s\tpeak_dbfs\trms_dbfs\tonset_ms\tattack_ms\tuseful_s\tcentroid_hz\tlow_pct\tlowmid_pct\tmid_pct\thigh_pct\tflatness\tpath")
	for category: String in C.CATEGORIES:
		if only != "" and category != only:
			continue
		var rows: Array = C.CATEGORIES[category]
		var sheet := Image.create_empty(900, rows.size() * (ROW_H + ENV_H + 8), false, Image.FORMAT_RGB8)
		sheet.fill(Color(0.08, 0.08, 0.1))
		for r in rows.size():
			var path: String = rows[r][1]
			var stream := C.load_stream(path)
			var length := stream.get_length() if stream != null else -1.0
			var mono := C.decode_mono(path, MAX_SECONDS)
			if mono.is_empty():
				push_error("Cannot decode " + path)
				continue
			var m := measure(mono)
			_draw_row(sheet, mono, r)
			out.store_line("\t".join(PackedStringArray([category, str(r), rows[r][0], rows[r][2], "%.2f" % length, "%.2f" % (mono.size() / AudioServer.get_mix_rate()),
					"%.1f" % m["peak_db"], "%.1f" % m["rms_db"], "%d" % m["onset_ms"], "%d" % m["attack_ms"], "%.2f" % m["useful_s"], "%d" % m["centroid"],
					"%d" % m["bands"][0], "%d" % m["bands"][1], "%d" % m["bands"][2], "%d" % m["bands"][3], "%.2f" % m["flatness"], path])))
			print("%-20s %d %-44s peak %6.1f rms %6.1f onset %4d atk %4d useful %5.2f cen %5d bands %s flat %.2f" % [category, r, rows[r][0].left(44), m["peak_db"], m["rms_db"], m["onset_ms"], m["attack_ms"], m["useful_s"], m["centroid"], str(m["bands"]), m["flatness"]])
		sheet.save_png(OUT + category + ".png")
	out.close()
	quit(0)


func measure(mono: PackedFloat32Array) -> Dictionary:
	var rate := AudioServer.get_mix_rate()
	var peak := 0.0
	var peak_at := 0
	var energy := 0.0
	for i in mono.size():
		var a := absf(mono[i])
		energy += mono[i] * mono[i]
		if a > peak:
			peak = a
			peak_at = i
	var threshold := peak * 0.01 # -40 dB under the peak
	var first := 0
	while first < mono.size() and absf(mono[first]) < threshold:
		first += 1
	var last := mono.size() - 1
	while last > first and absf(mono[last]) < threshold:
		last -= 1
	var attack_threshold := peak * 0.9
	var reach := first
	while reach < mono.size() and absf(mono[reach]) < attack_threshold:
		reach += 1
	# Spectrum over the useful part (hop N/2, at most 160 frames).
	var spectrum := PackedFloat32Array()
	spectrum.resize(N / 2)
	var frames := 0
	var flat_sum := 0.0
	var hop := maxi(N / 2, (last - first) / 160)
	var start := first
	while start + N <= last + 1:
		var mags := fft_mag(mono, start)
		var log_sum := 0.0
		var lin_sum := 0.0
		for k in range(1, N / 2):
			spectrum[k] += mags[k]
			log_sum += log(mags[k] + 1e-9)
			lin_sum += mags[k]
		flat_sum += exp(log_sum / (N / 2 - 1)) / (lin_sum / (N / 2 - 1) + 1e-9)
		frames += 1
		start += hop
	var bands := [0.0, 0.0, 0.0, 0.0]
	var total := 0.0
	var weighted := 0.0
	for k in range(1, N / 2):
		var f := k * rate / N
		var p := spectrum[k] * spectrum[k]
		total += p
		weighted += f * p
		bands[0 if f < 250.0 else (1 if f < 1000.0 else (2 if f < 4000.0 else 3))] += p
	var pct := []
	for b in bands:
		pct.append(roundi(100.0 * b / maxf(total, 1e-12)))
	return {"peak_db": linear_to_db(maxf(peak, 1e-9)), "rms_db": linear_to_db(sqrt(energy / mono.size())), "onset_ms": int(1000.0 * first / rate),
			"attack_ms": int(1000.0 * (reach - first) / rate), "useful_s": float(last - first) / rate, "centroid": int(weighted / maxf(total, 1e-12)),
			"bands": pct, "flatness": flat_sum / maxf(frames, 1)}


## Magnitudes of a Hann-windowed N-point FFT starting at `start`.
func fft_mag(mono: PackedFloat32Array, start: int) -> PackedFloat32Array:
	var re := PackedFloat32Array()
	var im := PackedFloat32Array()
	re.resize(N)
	im.resize(N)
	# Bit-reversed load.
	var bits := 10
	for i in N:
		var j := 0
		var x := i
		for b in bits:
			j = (j << 1) | (x & 1)
			x >>= 1
		re[j] = mono[start + i] * _window[i] if start + i < mono.size() else 0.0
	var size := 2
	while size <= N:
		var half := size / 2
		var step := N / size
		for s in range(0, N, size):
			for k in half:
				var wr := _cos[k * step]
				var wi := _sin[k * step]
				var a := s + k
				var b := a + half
				var tr := wr * re[b] - wi * im[b]
				var ti := wr * im[b] + wi * re[b]
				re[b] = re[a] - tr
				im[b] = im[a] - ti
				re[a] += tr
				im[a] += ti
		size *= 2
	var mags := PackedFloat32Array()
	mags.resize(N / 2)
	for k in N / 2:
		mags[k] = sqrt(re[k] * re[k] + im[k] * im[k])
	return mags


## One row: envelope strip (peak per column, dB) over a log-frequency spectrogram (40 Hz - 16 kHz).
func _draw_row(sheet: Image, mono: PackedFloat32Array, row: int) -> void:
	var rate := AudioServer.get_mix_rate()
	var width := sheet.get_width()
	var top := row * (ROW_H + ENV_H + 8)
	var per_col := maxi(1, mono.size() / width)
	for x in width:
		var a := 0.0
		for i in range(x * per_col, mini((x + 1) * per_col, mono.size())):
			a = maxf(a, absf(mono[i]))
		var h := int(clampf((linear_to_db(maxf(a, 1e-6)) + 60.0) / 60.0, 0.0, 1.0) * (ENV_H - 2))
		for y in h:
			sheet.set_pixel(x, top + ENV_H - 1 - y, Color(0.95, 0.8, 0.3))
	var columns := mini(220, maxi(1, (mono.size() - N) / 256))
	for x in columns:
		var start := int(float(x) / columns * maxf(mono.size() - N, 0))
		var mags := fft_mag(mono, start)
		for y in ROW_H:
			var f := 40.0 * pow(16000.0 / 40.0, 1.0 - float(y) / (ROW_H - 1))
			var k := clampi(int(f * N / rate), 1, N / 2 - 1)
			var db := linear_to_db(mags[k] / (N * 0.25) + 1e-9)
			var t := clampf((db + 90.0) / 90.0, 0.0, 1.0)
			var color := Color(0.05, 0.05, 0.2).lerp(Color(0.6, 0.1, 0.6), clampf(t * 2.0, 0.0, 1.0)).lerp(Color(1.0, 0.9, 0.3), clampf(t * 2.0 - 1.0, 0.0, 1.0))
			var x0 := int(float(x) / columns * width)
			var x1 := int(float(x + 1) / columns * width)
			for xx in range(x0, maxi(x1, x0 + 1)):
				sheet.set_pixel(mini(xx, width - 1), top + ENV_H + y, color)
