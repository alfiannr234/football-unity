extends Node

signal settings_changed
signal crt_toggled(enabled: bool)

const SETTINGS_PATH := "user://settings.json"

var data: Dictionary = {
	"language": "id",
	"music_vol": 0.8,
	"sfx_vol": 1.0,
	"radio_track": "PRAMUSIM",
	"radio_shuffle": true,
	"vibration": true,
	"difficulty": "NORMAL",
	"perspective": "TV",
	"camera_dist": 0.85,
	"camera_angle": 0.50,
	"camera_shake": 1.0,
	"motion_controls": true,
	"crt_effect": true,
	"light_mode": false,
	"ultra_light_mode": false,
	"battery_saver": true,
	"rotation_mode": "BUKA",
	"notif_enabled": true,
	"data_analytics": true,
	"show_numbers": false,
}

var _idle_timer: float = 0.0
var _in_match: bool = false

func _ready() -> void:
	load_settings()
	apply_runtime_settings()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton or event is InputEventScreenTouch or event is InputEventKey:
		_idle_timer = 0.0
		if Engine.max_fps != 60 and not data.get("light_mode", false):
			Engine.max_fps = 60

func _process(delta: float) -> void:
	if _in_match:
		if Engine.max_fps != 60:
			Engine.max_fps = 60
		return
	if data.get("battery_saver", true):
		_idle_timer += delta
		if _idle_timer > 2.5 and Engine.max_fps != 30:
			Engine.max_fps = 30

func set_in_match(active: bool) -> void:
	_in_match = active
	_idle_timer = 0.0
	Engine.max_fps = 60

func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		for k in parsed.keys():
			if data.has(k):
				data[k] = parsed[k]

func save_settings() -> void:
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(data, "\t"))

func set_setting(key: String, value: Variant) -> void:
	data[key] = value
	save_settings()
	apply_runtime_settings()
	if key == "crt_effect":
		crt_toggled.emit(bool(value))
	settings_changed.emit()

func apply_runtime_settings() -> void:
	if data.get("ultra_light_mode", false):
		data["crt_effect"] = false
	elif data.get("light_mode", false):
		data["crt_effect"] = false
	if _in_match:
		Engine.max_fps = 60
	elif not data.get("battery_saver", true):
		Engine.max_fps = 60

func tr_text(id_str: String, en_str: String) -> String:
	return id_str if data.get("language", "id") == "id" else en_str

func get_difficulty_params() -> Dictionary:
	match str(data.get("difficulty", "NORMAL")):
		"MUDAH":
			return {
				"gk_reaction": 0.38,
				"gk_speed": 3.8,
				"defender_speed": 0.0,
				"dribble_defender_speed": 1.15,
				"aim_defender_scale": 0.0,
				"aim_teammate_scale": 0.0,
				"steal_dist": 0.0,
				"can_steal": false,
				"chance_delta": 0,
				"aim_spread_mult": 0.65,
				"desc_id": "Saat membidik semua rekan & lawan berhenti dan bek tak pernah merebut bola.",
				"desc_en": "EASY: all teammates and opponents stop while aiming and defenders never steal.",
			}
		"SULIT":
			return {
				"gk_reaction": 0.14,
				"gk_speed": 6.4,
				"defender_speed": 3.05,
				"dribble_defender_speed": 3.85,
				"aim_defender_scale": 0.54,
				"aim_teammate_scale": 0.38,
				"steal_dist": 1.16,
				"can_steal": true,
				"chance_delta": 0,
				"aim_spread_mult": 1.15,
				"desc_id": "Permainan utuh. Kamu ditekan saat membidik, bola bisa direbut dan kiper tak memberi celah.",
				"desc_en": "HARD: full pressing while aiming, ball can be stolen and keeper gives no gap.",
			}
		"EKSTREM":
			return {
				"gk_reaction": 0.08,
				"gk_speed": 7.5,
				"defender_speed": 4.25,
				"dribble_defender_speed": 4.95,
				"aim_defender_scale": 0.68,
				"aim_teammate_scale": 0.52,
				"steal_dist": 1.28,
				"can_steal": true,
				"chance_delta": -1,
				"aim_spread_mult": 1.35,
				"desc_id": "Bintang dijaga ketat, peluang berkurang satu, lelah tendangan melenceng, lebih banyak blok, direbut tanpa peringatan, semua menuntut lebih.",
				"desc_en": "EXTREME: tight marking, one fewer chance, fatigue affects aim, aggressive tackles.",
			}
		_:
			return {
				"gk_reaction": 0.22,
				"gk_speed": 5.2,
				"defender_speed": 2.15,
				"dribble_defender_speed": 2.85,
				"aim_defender_scale": 0.40,
				"aim_teammate_scale": 0.22,
				"steal_dist": 0.98,
				"can_steal": true,
				"chance_delta": 0,
				"aim_spread_mult": 0.90,
				"desc_id": "Rekan & lawan melambat saat belum bergerak atau membidik; bek cepat menekan & merebut.",
				"desc_en": "NORMAL: teammates & opponents move slowly while idle or aiming; faster defenders press.",
			}
