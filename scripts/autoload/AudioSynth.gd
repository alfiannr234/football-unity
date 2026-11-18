extends Node

# Procedural chiptune & match SFX synthesizer using AudioStreamGenerator.
# Works 100% offline with zero external audio assets and gracefully no-ops under headless Dummy audio driver.

var _sfx_player: AudioStreamPlayer
var _bgm_player: AudioStreamPlayer
var _sfx_playback: AudioStreamGeneratorPlayback
var _bgm_playback: AudioStreamGeneratorPlayback

var _sample_rate: float = 22050.0
var _active_sfx: Array[Dictionary] = []
var _bgm_phase: float = 0.0
var _bgm_step_timer: float = 0.0
var _bgm_step_idx: int = 0
var _audio_ready: bool = false
var bgm_track_override: String = ""

const TRACKS := {
	"HOME": [329.63, 392.00, 440.00, 523.25, 493.88, 392.00, 329.63, 293.66],
	"PRAMUSIM": [261.63, 329.63, 392.00, 523.25, 392.00, 329.63, 293.66, 349.23],
	"STADION": [220.00, 261.63, 329.63, 440.00, 392.00, 329.63, 293.66, 329.63],
	"MALAM JUARA": [196.00, 246.94, 293.66, 392.00, 440.00, 392.00, 329.63, 293.66],
}

func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var sfx_gen := AudioStreamGenerator.new()
	sfx_gen.mix_rate = _sample_rate
	sfx_gen.buffer_length = 0.12
	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.stream = sfx_gen
	add_child(_sfx_player)
	_sfx_player.play()
	_sfx_playback = _sfx_player.get_stream_playback()

	var bgm_gen := AudioStreamGenerator.new()
	bgm_gen.mix_rate = _sample_rate
	bgm_gen.buffer_length = 0.25
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.stream = bgm_gen
	add_child(_bgm_player)
	_bgm_player.play()
	_bgm_playback = _bgm_player.get_stream_playback()
	_audio_ready = true

func _process(delta: float) -> void:
	if not _audio_ready:
		return
	_fill_sfx()
	_fill_bgm(delta)

func _fill_sfx() -> void:
	if _sfx_playback == null:
		return
	var frames: int = _sfx_playback.get_frames_available()
	if frames <= 0:
		return
	var vol: float = float(SettingsManager.data.get("sfx_vol", 1.0)) * 0.28
	for _i in range(frames):
		var sample := 0.0
		var keep: Array[Dictionary] = []
		for s in _active_sfx:
			var t: float = s["t"]
			var dur: float = s["dur"]
			if t < dur:
				var env := 1.0 - (t / dur)
				var freq: float = lerpf(s["f0"], s["f1"], t / dur)
				var wave := 0.0
				match s["type"]:
					"square":
						wave = 1.0 if sin(TAU * freq * t) >= 0.0 else -1.0
					"noise":
						wave = randf_range(-1.0, 1.0)
					_:
						wave = sin(TAU * freq * t)
				sample += wave * env * s["amp"]
				s["t"] = t + (1.0 / _sample_rate)
				keep.append(s)
		_active_sfx = keep
		sample = clampf(sample * vol, -0.95, 0.95)
		_sfx_playback.push_frame(Vector2(sample, sample))

func _fill_bgm(delta: float) -> void:
	if _bgm_playback == null:
		return
	var track_name: String = bgm_track_override if not bgm_track_override.is_empty() else str(SettingsManager.data.get("radio_track", "PRAMUSIM"))
	var music_vol: float = float(SettingsManager.data.get("music_vol", 0.8))
	var frames: int = _bgm_playback.get_frames_available()
	if frames <= 0:
		return
	if track_name == "MATI" or music_vol <= 0.01:
		for _i in range(frames):
			_bgm_playback.push_frame(Vector2.ZERO)
		return
	var notes: Array = TRACKS.get(track_name, TRACKS["PRAMUSIM"])
	var step_dur := 0.24
	for _i in range(frames):
		_bgm_step_timer += 1.0 / _sample_rate
		if _bgm_step_timer >= step_dur:
			_bgm_step_timer -= step_dur
			_bgm_step_idx = (_bgm_step_idx + 1) % notes.size()
		var freq: float = float(notes[_bgm_step_idx])
		_bgm_phase = fmod(_bgm_phase + (freq / _sample_rate), 1.0)
		var env := clampf(1.0 - (_bgm_step_timer / step_dur) * 0.75, 0.1, 1.0)
		var tri := 4.0 * absf(_bgm_phase - 0.5) - 1.0
		var v := tri * env * music_vol * 0.08
		_bgm_playback.push_frame(Vector2(v, v))

func _push_tone(f0: float, f1: float, dur: float, wave_type: String = "sine", amp: float = 0.6) -> void:
	if not _audio_ready or float(SettingsManager.data.get("sfx_vol", 1.0)) <= 0.01:
		return
	if _active_sfx.size() > 12:
		return
	_active_sfx.append({"f0": f0, "f1": f1, "dur": dur, "t": 0.0, "type": wave_type, "amp": amp})

func play_click() -> void:
	_push_tone(640.0, 820.0, 0.045, "square", 0.25)

func play_kick(power: float = 0.8) -> void:
	_push_tone(190.0, 62.0, 0.11, "sine", 0.8 * clampf(power, 0.3, 1.2))
	_push_tone(240.0, 90.0, 0.06, "noise", 0.35 * clampf(power, 0.3, 1.0))

func play_whistle(long_blast: bool = false) -> void:
	var dur := 0.38 if long_blast else 0.16
	_push_tone(2650.0, 2780.0, dur, "sine", 0.45)
	_push_tone(2420.0, 2500.0, dur, "sine", 0.25)

func play_post() -> void:
	_push_tone(520.0, 495.0, 0.28, "square", 0.55)

func play_goal() -> void:
	_push_tone(523.25, 523.25, 0.12, "square", 0.45)
	_push_tone(659.25, 659.25, 0.18, "square", 0.45)
	_push_tone(783.99, 1046.5, 0.35, "square", 0.5)
	_push_tone(300.0, 240.0, 0.55, "noise", 0.35)

func play_save() -> void:
	_push_tone(320.0, 140.0, 0.14, "noise", 0.5)

func play_level_up() -> void:
	_push_tone(440.0, 880.0, 0.24, "square", 0.45)

func play_achievement() -> void:
	_push_tone(587.33, 880.0, 0.22, "square", 0.4)

func play_note(freq: float, dur: float = 0.22) -> void:
	_push_tone(freq, freq * 1.01, dur, "sine", 0.5)

func play_ring_tap(perfect: bool) -> void:
	if perfect:
		_push_tone(660.0, 990.0, 0.09, "square", 0.38)
	else:
		_push_tone(320.0, 240.0, 0.08, "sine", 0.28)
