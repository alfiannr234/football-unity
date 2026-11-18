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
				"gk_reaction": 0.45,
				"gk_speed": 4.0,
				"defender_speed": 0.0,
				"can_steal": false,
				"chance_delta": 0,
				"aim_spread_mult": 0.65,
				"desc_id": "Lawan berhenti saat kamu membidik dan tak pernah merebut bola. Kiper lebih sering salah.",
				"desc_en": "EASY: opponents freeze while aiming and never steal. Keeper makes more mistakes.",
			}
		"SULIT":
			return {
				"gk_reaction": 0.16,
				"gk_speed": 6.5,
				"defender_speed": 2.4,
				"can_steal": true,
				"chance_delta": 0,
				"aim_spread_mult": 1.15,
				"desc_id": "Permainan utuh. Kamu ditekan saat membidik, bola bisa direbut dan kiper tak memberi celah.",
				"desc_en": "HARD: full pressing while aiming, ball can be stolen and keeper gives no gap.",
			}
		"EKSTREM":
			return {
				"gk_reaction": 0.09,
				"gk_speed": 7.6,
				"defender_speed": 3.5,
				"can_steal": true,
				"chance_delta": -1,
				"aim_spread_mult": 1.35,
				"desc_id": "Bintang dijaga ketat, peluang berkurang satu, lelah tendangan melenceng, lebih banyak blok, direbut tanpa peringatan, semua menuntut lebih.",
				"desc_en": "EXTREME: tight marking, one fewer chance, fatigue affects aim, aggressive tackles.",
			}
		_:
			return {
				"gk_reaction": 0.28,
				"gk_speed": 5.2,
				"defender_speed": 0.9,
				"can_steal": true,
				"chance_delta": 0,
				"aim_spread_mult": 0.90,
				"desc_id": "Lawan lebih lambat saat kamu membidik dan merebut bola dari jarak lebih dekat. Kiper agak lebih sering salah.",
				"desc_en": "NORMAL: opponents move slower while aiming and tackle only at closer range.",
			}
