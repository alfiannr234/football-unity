extends Node3D

# Interactive 3D City Explorer matching Video 3 (sheet_01..sheet_04):
# - 3D Street avenue with crosswalks, park median, trees, buildings, & glowing blue route dots
# - Top-left Radar Minimap showing player cone, streets, SNEAKERS, APARTEMEN, & STADION pins
# - Enterable SNEAKERS 3D boutique room (pedestals, inspect & buy footwear/headwear)
# - Enterable APARTEMEN room (with MODE EDIT & weekly stamina recovery)
# - Walk to STADION portal to jump directly to Match / Career

signal exited
signal start_match_from_city

enum ZoneMode { STREET, SNEAKERS_SHOP, APARTMENT_ROOM }

var _zone: ZoneMode = ZoneMode.STREET
var _target_landmark: String = "SNEAKERS"  # "SNEAKERS" | "APARTEMEN" | "STADION"
var _player_pos: Vector3 = Vector3(0.0, 0.0, 22.0)
var _drag_active: bool = false
var _drag_origin: Vector2 = Vector2.ZERO
var _move_vec: Vector2 = Vector2.ZERO

var _world_root: Node3D
var _player_rig: Sprite3D
var _cam: Camera3D
var _hud: Control
var _minimap: Control
var _dist_lbl: Label
var _enter_btn: Button
var _shop_panel: PanelContainer
var _apt_panel: PanelContainer
var _apt_edit_mode: bool = false
var _apt_rug_color_idx: int = 0
var _near_landmark: String = ""

const LANDMARKS := {
	"APARTEMEN": {"pos": Vector3(-12.0, 0.0, 22.0), "col": Color("#3B82F6"), "label": "APARTEMEN"},
	"STADION": {"pos": Vector3(0.0, 0.0, -34.0), "col": Color("#E89228"), "label": "STADION"},
	"SNEAKERS": {"pos": Vector3(14.0, 0.0, -8.0), "col": Color("#EC4899"), "label": "SNEAKERS"},
}

const SNEAKERS_STOCK := [
	{"id": "sneaker_tinggi", "name": "SNEAKER TINGGI", "price": 12000, "desc": "+2 KECEPATAN GAYA", "kind": "boot_boost", "val": 3},
	{"id": "durag_sutra", "name": "DURAG / IKAT KEPALA", "price": 6500, "desc": "AKSESORIS KEPALA UNIK", "kind": "headwear", "val": 3},
	{"id": "topi_bintang", "name": "TOPI BINTANG PRO", "price": 4800, "desc": "TOPI KASUAL KOTA", "kind": "headwear", "val": 1},
	{"id": "kacamata_vip", "name": "KACAMATA EMAS", "price": 7500, "desc": "STYLE BINTANG", "kind": "eyewear", "val": 1},
]

func configure(start_target: String = "SNEAKERS", start_inside_apartment: bool = false) -> void:
	_target_landmark = start_target
	if start_inside_apartment:
		_zone = ZoneMode.APARTMENT_ROOM
		_player_pos = Vector3(-12.0, 0.0, 22.0)

func _ready() -> void:
	var ultra_light := bool(SettingsManager.data.get("ultra_light_mode", false))
	var env := WorldEnvironment.new()
	var e := Environment.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("#1F4E8C")
	sky_mat.sky_horizon_color = Color("#E6BA90")
	sky_mat.sky_curve = 0.11
	sky_mat.ground_bottom_color = Color("#1F3329")
	sky_mat.ground_horizon_color = Color("#6A849E")
	var sky := Sky.new()
	sky.sky_material = sky_mat
	e.background_mode = Environment.BG_SKY
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_sky_contribution = 0.65
	e.ambient_light_color = Color("#DCE8F6")
	e.ambient_light_energy = 0.68
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	e.tonemap_exposure = 0.90
	e.adjustment_enabled = true
	e.adjustment_contrast = 1.09
	e.adjustment_saturation = 1.12
	e.fog_enabled = true
	e.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	e.fog_light_color = Color("#88A2BE")
	e.fog_density = 0.0046
	e.fog_sky_affect = 0.25
	if not ultra_light:
		e.glow_enabled = true
		e.glow_intensity = 0.28
		e.glow_bloom = 0.05
		e.glow_hdr_threshold = 0.96
	env.environment = e
	add_child(env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, 30.0, 0.0)
	sun.light_color = Color("#FFF4DE")
	sun.light_energy = 0.96
	sun.shadow_enabled = not ultra_light
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_max_distance = 110.0
	add_child(sun)

	_cam = Camera3D.new()
	_cam.fov = 48.0
	add_child(_cam)

	_world_root = Node3D.new()
	add_child(_world_root)

	_player_rig = Sprite3D.new()
	_player_rig.texture = load("res://assets/sprites/characters/player_white_sheet.png")
	_player_rig.hframes = 4
	_player_rig.vframes = 2
	_player_rig.frame = 4
	_player_rig.pixel_size = 0.0325
	_player_rig.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	_player_rig.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_player_rig.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	add_child(_player_rig)

	# Ground Contact Shadow Disc beneath Player
	var sh_img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for sy in range(16):
		for sx in range(16):
			var d := Vector2(sx - 7.5, sy - 7.5).length() / 7.5
			if d <= 1.0:
				sh_img.set_pixel(sx, sy, Color(0, 0, 0, (1.0 - d) * 0.55))
	var sh_sp := Sprite3D.new()
	sh_sp.texture = ImageTexture.create_from_image(sh_img)
	sh_sp.axis = Vector3.AXIS_Y
	sh_sp.pixel_size = 0.09
	sh_sp.position = Vector3(0.0, -0.84, 0.0)
	_player_rig.add_child(sh_sp)

	_build_hud()
	_rebuild_zone()

func _add_emissive_box(pos: Vector3, box_size: Vector3, col: Color, emit_energy: float, parent: Node3D) -> MeshInstance3D:
	var mi := _add_box(pos, box_size, col, parent)
	var mat: StandardMaterial3D = mi.material_override as StandardMaterial3D
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = emit_energy
	return mi

func _add_box(pos: Vector3, box_size: Vector3, col: Color, parent: Node3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var m := BoxMesh.new()
	m.size = box_size
	mi.mesh = m
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 0.9
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi

func _rebuild_zone() -> void:
	for c in _world_root.get_children():
		c.queue_free()

	_shop_panel.visible = (_zone == ZoneMode.SNEAKERS_SHOP)
	_apt_panel.visible = (_zone == ZoneMode.APARTMENT_ROOM)
	_enter_btn.visible = false

	if _zone == ZoneMode.STREET:
		_build_street_world()
	elif _zone == ZoneMode.SNEAKERS_SHOP:
		_build_sneakers_interior()
	else:
		_build_apartment_interior()

	_sync_player_and_camera()

func _build_street_world() -> void:
	# Ground Lawn, Asphalt Roads & Concrete Sidewalk Curbs
	_add_box(Vector3(0, -0.22, 0), Vector3(110, 0.4, 130), Color("#346A36"), _world_root)
	_add_box(Vector3(0, -0.15, -4), Vector3(11.0, 0.35, 92.0), Color("#2B313A"), _world_root)
	_add_box(Vector3(4, -0.14, -8), Vector3(38.0, 0.35, 9.0), Color("#2B313A"), _world_root)

	# Sidewalks & Raised Kerbstone Borders
	_add_box(Vector3(-7.0, -0.09, 4), Vector3(3.2, 0.36, 74), Color("#ABA592"), _world_root)
	_add_box(Vector3(7.0, -0.09, 4), Vector3(3.2, 0.36, 74), Color("#ABA592"), _world_root)
	_add_box(Vector3(-5.45, -0.05, 4), Vector3(0.24, 0.38, 74), Color("#9CA3AE"), _world_root)
	_add_box(Vector3(5.45, -0.05, 4), Vector3(0.24, 0.38, 74), Color("#9CA3AE"), _world_root)

	for cz in range(-5, 6, 2):
		_add_box(Vector3(-3.0 + float(cz) * 0.9, -0.04, -2.5), Vector3(0.48, 0.25, 2.2), Color("#EEF2F6"), _world_root)

	# Crisp Dotted Center Road Line + Bike Shoulder Line
	for z in range(-42, 34, 4):
		_add_box(Vector3(0, -0.04, float(z)), Vector3(0.22, 0.2, 1.6), Color("#F0C848"), _world_root)

	# Architectural City Blocks with Rooftop Parapets & Warm Glowing Windows
	for idx_b in range(3):
		var bz: float = [-22.0, 6.0, 22.0][idx_b]
		var lh: float = [9.4, 10.6, 8.8][idx_b]
		var rh: float = [10.8, 9.6, 11.2][idx_b]
		_add_box(Vector3(-14.8, lh * 0.5, bz), Vector3(11.0, lh, 10.0), Color("#737F8E"), _world_root)
		_add_box(Vector3(-14.8, lh + 0.35, bz), Vector3(11.4, 0.7, 10.4), Color("#4A5566"), _world_root)
		_add_box(Vector3(16.8, rh * 0.5, bz), Vector3(11.0, rh, 10.0), Color("#86847C"), _world_root)
		_add_box(Vector3(16.8, rh + 0.35, bz), Vector3(11.4, 0.7, 10.4), Color("#565B64"), _world_root)
		for wy in [2.4, 4.8, 7.2]:
			for wz_off in [-2.6, 0.0, 2.6]:
				_add_emissive_box(Vector3(-9.25, wy, bz + wz_off), Vector3(0.18, 1.2, 1.4), Color("#FFE2A4"), 0.55, _world_root)
				_add_emissive_box(Vector3(11.25, wy, bz + wz_off), Vector3(0.18, 1.2, 1.4), Color("#FFE2A4"), 0.55, _world_root)

	# Streetlights & Layered Canopy Trees with Stone Planters
	for tz in [-26, -16, 2, 12, 20]:
		var fz := float(tz)
		_add_box(Vector3(-6.8, 0.3, fz), Vector3(1.2, 0.6, 1.2), Color("#6E747C"), _world_root)
		_add_box(Vector3(-6.8, 1.4, fz), Vector3(0.4, 2.2, 0.4), Color("#6C4830"), _world_root)
		_add_box(Vector3(-6.8, 3.0, fz), Vector3(2.3, 2.2, 2.3), Color("#266A36"), _world_root)
		_add_box(Vector3(-6.8, 4.1, fz), Vector3(1.5, 1.2, 1.5), Color("#368444"), _world_root)

		_add_box(Vector3(6.8, 0.3, fz), Vector3(1.2, 0.6, 1.2), Color("#6E747C"), _world_root)
		_add_box(Vector3(6.8, 1.4, fz), Vector3(0.4, 2.2, 0.4), Color("#6C4830"), _world_root)
		_add_box(Vector3(6.8, 3.0, fz), Vector3(2.3, 2.2, 2.3), Color("#2C743C"), _world_root)
		_add_box(Vector3(6.8, 4.1, fz), Vector3(1.5, 1.2, 1.5), Color("#3D924C"), _world_root)

	for lz in [-28.0, -12.0, 4.0, 20.0]:
		for sx in [-5.7, 5.7]:
			var arm_dir: float = 0.6 if sx < 0.0 else -0.6
			_add_box(Vector3(sx, 2.3, lz), Vector3(0.18, 4.6, 0.18), Color("#242C38"), _world_root)
			_add_box(Vector3(sx + arm_dir, 4.55, lz), Vector3(1.2, 0.16, 0.18), Color("#242C38"), _world_root)
			_add_emissive_box(Vector3(sx + arm_dir * 1.4, 4.42, lz), Vector3(0.45, 0.18, 0.35), Color("#FFF4CA"), 1.6, _world_root)

	# Parked Pixel Cars along Curb
	_add_box(Vector3(-4.2, 0.42, 10.0), Vector3(1.6, 0.65, 3.4), Color("#C43B3B"), _world_root)
	_add_box(Vector3(-4.2, 0.92, 10.2), Vector3(1.35, 0.5, 1.8), Color("#DCE6F2"), _world_root)
	_add_box(Vector3(4.2, 0.42, -17.0), Vector3(1.6, 0.65, 3.4), Color("#3476B8"), _world_root)
	_add_box(Vector3(4.2, 0.92, -16.8), Vector3(1.35, 0.5, 1.8), Color("#DCE6F2"), _world_root)

	# Grand Colosseum Stadion Arch & Twin Floodlights (North end at z = -34)
	_add_box(Vector3(0, 4.0, -39.5), Vector3(28, 8.0, 6.5), Color("#22344A"), _world_root)
	_add_box(Vector3(0, 8.4, -39.5), Vector3(29.2, 0.9, 7.2), Color("#384C64"), _world_root)
	_add_emissive_box(Vector3(0, 6.6, -36.1), Vector3(22.0, 0.55, 0.3), Color("#E89228"), 1.2, _world_root)
	_add_box(Vector3(0, 2.2, -36.2), Vector3(6.4, 4.4, 0.4), Color("#101824"), _world_root)
	for stx in [-13.0, 13.0]:
		_add_box(Vector3(stx, 9.5, -39.0), Vector3(0.8, 11.0, 0.8), Color("#2A3B4F"), _world_root)
		_add_emissive_box(Vector3(stx, 14.5, -38.4), Vector3(3.2, 1.6, 0.4), Color("#FFF8DF"), 2.1, _world_root)
	_add_emissive_box(Vector3(0, 0.06, -34), Vector3(5.0, 0.1, 3.0), Color("#E89228"), 0.45, _world_root)

	# Sneakers Boutique Exterior (East at (14, 0, -8))
	_add_box(Vector3(15.5, 2.9, -11.5), Vector3(8.2, 5.8, 5.2), Color("#C96524"), _world_root)
	_add_box(Vector3(15.5, 3.2, -8.7), Vector3(7.6, 0.45, 1.4), Color("#ECEEF4"), _world_root)
	_add_emissive_box(Vector3(15.5, 1.6, -8.85), Vector3(5.2, 2.2, 0.2), Color("#FFD98E"), 0.65, _world_root)
	_add_emissive_box(Vector3(14.0, 0.07, -8.0), Vector3(4.2, 0.1, 3.2), Color("#EC4899"), 0.55, _world_root)

	# Apartment Entrance Porch & Pad (West at (-12, 0, 22))
	_add_box(Vector3(-9.3, 2.7, 22.0), Vector3(1.8, 0.35, 3.6), Color("#344458"), _world_root)
	_add_emissive_box(Vector3(-12.0, 0.07, 22.0), Vector3(4.0, 0.1, 3.2), Color("#3B82F6"), 0.55, _world_root)

	# Glowing Blue Breadcrumb Path Dots toward Target Landmark
	var dst: Vector3 = LANDMARKS.get(_target_landmark, LANDMARKS["SNEAKERS"])["pos"]
	for s in range(1, 16):
		var t: float = float(s) / 16.0
		var p: Vector3 = Vector3(0.0, 0.06, 20.0).lerp(dst, t)
		_add_emissive_box(p, Vector3(0.55, 0.08, 0.55), Color("#58B4FF"), 1.05, _world_root)

func _build_sneakers_interior() -> void:
	_add_box(Vector3(0, -0.2, 0), Vector3(16, 0.4, 16), Color("#262B34"), _world_root)
	_add_box(Vector3(0, 2.5, -5.5), Vector3(14, 5, 1.0), Color("#1A1E24"), _world_root)
	_add_emissive_box(Vector3(0, 4.6, -4.8), Vector3(12.0, 0.25, 0.3), Color("#58B4FF"), 1.3, _world_root)
	for x in range(-5, 6, 2):
		for y in range(1, 5):
			var c := Color("#E47824") if (x + y) % 2 == 0 else Color("#ECEEE8")
			_add_box(Vector3(float(x), float(y), -4.9), Vector3(1.5, 0.65, 0.4), c, _world_root)
	# Center "UNIK" Pedestal with Glowing Rim
	_add_box(Vector3(0, 0.7, -1.0), Vector3(2.2, 1.4, 2.2), Color("#14181E"), _world_root)
	_add_emissive_box(Vector3(0, 1.42, -1.0), Vector3(2.26, 0.08, 2.26), Color("#EA7E22"), 1.1, _world_root)
	_add_box(Vector3(0, 1.65, -1.0), Vector3(0.9, 0.45, 0.5), Color("#EA7E22"), _world_root)
	_player_pos = Vector3(-1.5, 0.0, 3.0)

func _build_apartment_interior() -> void:
	var floor_cols := [Color("#6A4B34"), Color("#3E546E"), Color("#4B5B40")]
	var rug_col: Color = floor_cols[_apt_rug_color_idx % floor_cols.size()]
	_add_box(Vector3(0, -0.2, 0), Vector3(14, 0.4, 12), Color("#7B5E42"), _world_root)
	_add_box(Vector3(0, 0.02, 0), Vector3(6.2, 0.06, 4.6), rug_col, _world_root)
	_add_box(Vector3(0, 2.2, -5.0), Vector3(14, 4.4, 0.6), Color("#B8B4A8"), _world_root)
	_add_box(Vector3(0, 0.22, -4.65), Vector3(14, 0.44, 0.14), Color("#4A3626"), _world_root)
	_add_box(Vector3(-3.8, 0.6, -3.5), Vector3(3.2, 1.2, 2.0), Color("#305278"), _world_root)
	_add_box(Vector3(-3.8, 1.26, -4.2), Vector3(2.6, 0.35, 0.55), Color("#DCE4F0"), _world_root)
	_add_box(Vector3(3.6, 0.8, -3.8), Vector3(2.4, 1.6, 1.2), Color("#222630"), _world_root)
	_add_emissive_box(Vector3(3.6, 2.35, -4.2), Vector3(2.2, 1.25, 0.14), Color("#3B82F6"), 0.55, _world_root)
	_add_box(Vector3(0.0, 2.7, -4.65), Vector3(2.0, 1.4, 0.1), Color("#266038"), _world_root)
	_add_emissive_box(Vector3(-6.0, 1.75, -4.0), Vector3(0.55, 0.45, 0.55), Color("#FFE299"), 1.2, _world_root)
	_player_pos = Vector3(0.0, 0.0, 1.8)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	_hud = Control.new()
	_hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hud.theme = UITheme.build_theme()
	_hud.gui_input.connect(_on_hud_drag_input)
	layer.add_child(_hud)

	# Top Bar: Minimap Radar | Landmark Pill | KELUAR
	var top_hb := HBoxContainer.new()
	top_hb.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_hb.offset_left = 10
	top_hb.offset_right = -10
	top_hb.offset_top = 10
	top_hb.offset_bottom = 108
	top_hb.add_theme_constant_override("separation", 8)
	_hud.add_child(top_hb)

	var map_box := PanelContainer.new()
	map_box.custom_minimum_size = Vector2(102, 96)
	map_box.add_theme_stylebox_override("panel", UITheme.make_box(Color("#121A24", 0.92), UITheme.BORDER_CYAN, 2, 4))
	top_hb.add_child(map_box)
	var mvb := VBoxContainer.new()
	map_box.add_child(mvb)
	_minimap = Control.new()
	_minimap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_minimap.draw.connect(_draw_minimap)
	mvb.add_child(_minimap)
	_dist_lbl = Label.new()
	_dist_lbl.text = "340 m • KOTA"
	_dist_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dist_lbl.add_theme_font_size_override("font_size", 10)
	_dist_lbl.add_theme_color_override("font_color", UITheme.ACCENT_CYAN)
	mvb.add_child(_dist_lbl)

	var info_card := PanelContainer.new()
	info_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_card.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	info_card.add_theme_stylebox_override("panel", UITheme.make_box(Color("#0D1829", 0.90), Color("#2B486B"), 1, 6))
	top_hb.add_child(info_card)

	var info_vb := VBoxContainer.new()
	info_vb.add_theme_constant_override("separation", 4)
	info_card.add_child(info_vb)

	var cash_l := Label.new()
	var c_val: int = int(CareerState.career["playerProfile"]["cash"]) if CareerState.has_active_career else 5000
	cash_l.text = "TUJUAN: %s • %s" % [_target_landmark, UITheme.format_cash(c_val)]
	cash_l.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	cash_l.add_theme_font_size_override("font_size", 12)
	info_vb.add_child(cash_l)

	# Route shortcuts
	var r_hb := HBoxContainer.new()
	r_hb.add_theme_constant_override("separation", 4)
	info_vb.add_child(r_hb)
	for lm in ["SNEAKERS", "APARTEMEN", "STADION"]:
		var b := Button.new()
		b.text = lm.left(5)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UITheme.style_btn(b, Color("#172C46"), LANDMARKS[lm]["col"], 10)
		b.pressed.connect(func():
			AudioSynth.play_click()
			_target_landmark = lm
			_zone = ZoneMode.STREET
			_rebuild_zone()
		)
		r_hb.add_child(b)

	var exit_b := Button.new()
	exit_b.text = "KELUAR"
	exit_b.custom_minimum_size = Vector2(78, 38)
	exit_b.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	UITheme.style_btn(exit_b, Color("#3A1A22"), UITheme.ACCENT_RED, 12)
	exit_b.pressed.connect(func(): AudioSynth.play_click(); exited.emit(); queue_free())
	top_hb.add_child(exit_b)

	# Prompt button when near building door
	_enter_btn = Button.new()
	_enter_btn.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_enter_btn.offset_left = 290
	_enter_btn.offset_right = -290
	_enter_btn.offset_top = -74
	_enter_btn.offset_bottom = -20
	_enter_btn.visible = false
	UITheme.style_btn(_enter_btn, Color("#1C486E"), UITheme.ACCENT_GOLD, 16)
	_enter_btn.pressed.connect(_on_enter_landmark)
	_hud.add_child(_enter_btn)

	# SNEAKERS Shop Overlay Card
	_shop_panel = PanelContainer.new()
	_shop_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_shop_panel.offset_left = 140
	_shop_panel.offset_right = -140
	_shop_panel.offset_top = -270
	_shop_panel.offset_bottom = -14
	_shop_panel.add_theme_stylebox_override("panel", UITheme.make_box(Color("#121820", 0.94), Color("#EA7E22"), 2, 10))
	_hud.add_child(_shop_panel)
	_populate_shop_panel()

	# APARTEMEN Interior Card (MODE EDIT + ISTIRAHAT + KELUAR)
	_apt_panel = PanelContainer.new()
	_apt_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_apt_panel.offset_left = 180
	_apt_panel.offset_right = -180
	_apt_panel.offset_top = -205
	_apt_panel.offset_bottom = -14
	_apt_panel.add_theme_stylebox_override("panel", UITheme.make_box(Color("#141E2B", 0.94), Color("#58B4FF"), 2, 10))
	_hud.add_child(_apt_panel)
	_populate_apartment_panel()

func _populate_shop_panel() -> void:
	for c in _shop_panel.get_children():
		c.queue_free()
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	_shop_panel.add_child(vb)

	var top_hb := HBoxContainer.new()
	vb.add_child(top_hb)
	var title := Label.new()
	title.text = "SNEAKERS • KOLEKSI UNIK"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", Color("#EA7E22"))
	top_hb.add_child(title)
	var back_b := Button.new()
	back_b.text = "KE JALAN"
	back_b.pressed.connect(func(): AudioSynth.play_click(); _zone = ZoneMode.STREET; _player_pos = Vector3(11.0, 0, -5.0); _rebuild_zone())
	top_hb.add_child(back_b)

	for item in SNEAKERS_STOCK:
		var hb := HBoxContainer.new()
		vb.add_child(hb)
		var lb := Label.new()
		lb.text = "%s\n%s" % [item["name"], item["desc"]]
		lb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lb.add_theme_font_size_override("font_size", 11)
		hb.add_child(lb)
		var buy_b := Button.new()
		var price: int = int(item["price"])
		var can_buy: bool = CareerState.has_active_career and int(CareerState.career["playerProfile"]["cash"]) >= price
		buy_b.text = "BELI %s" % UITheme.format_cash(price)
		buy_b.disabled = not can_buy
		UITheme.style_btn(buy_b, Color("#78481A") if can_buy else Color("#282022"), Color("#F5C542") if can_buy else Color("#664444"), 11)
		buy_b.pressed.connect(func():
			if not CareerState.has_active_career:
				return
			var p: Dictionary = CareerState.career["playerProfile"]
			if int(p["cash"]) < price:
				return
			p["cash"] = int(p["cash"]) - price
			if item["kind"] == "headwear":
				p["appearance"]["headwear"] = int(item["val"])
			elif item["kind"] == "eyewear":
				p["appearance"]["eyewear"] = int(item["val"])
			elif item["kind"] == "boot_boost":
				p["attributes"]["kecepatan"] = mini(99, int(p["attributes"]["kecepatan"]) + int(item["val"]))
				CareerState.recalculate_ovr()
			CareerState.save_active_career()
			CareerState.career_updated.emit()
			AudioSynth.play_achievement()
			_populate_shop_panel()
		)
		hb.add_child(buy_b)

func _populate_apartment_panel() -> void:
	for c in _apt_panel.get_children():
		c.queue_free()
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	_apt_panel.add_child(vb)

	var h := Label.new()
	h.text = "APARTEMEN • %s" % ("MODE EDIT AKTIF" if _apt_edit_mode else "RUANG ISTIRAHAT")
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.add_theme_color_override("font_color", UITheme.ACCENT_CYAN)
	vb.add_child(h)

	var r_hb := HBoxContainer.new()
	r_hb.add_theme_constant_override("separation", 8)
	vb.add_child(r_hb)

	var edit_b := Button.new()
	edit_b.text = "MODE EDIT"
	edit_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit_b.custom_minimum_size = Vector2(0, 42)
	UITheme.style_btn(edit_b, Color("#26582E"), UITheme.ACCENT_GREEN, 12)
	edit_b.pressed.connect(func():
		AudioSynth.play_click()
		_apt_edit_mode = true
		_apt_rug_color_idx = (_apt_rug_color_idx + 1) % 3
		_rebuild_zone()
		_populate_apartment_panel()
	)
	r_hb.add_child(edit_b)

	var rest_b := Button.new()
	rest_b.text = "ISTIRAHAT (+20 ENERGI)"
	rest_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rest_b.custom_minimum_size = Vector2(0, 42)
	UITheme.style_btn(rest_b, Color("#173B66"), UITheme.ACCENT_GOLD, 12)
	rest_b.pressed.connect(func():
		if CareerState.has_active_career:
			var cur_w: int = int(CareerState.career["careerMeta"]["week"])
			if int(CareerState.career["careerMeta"].get("visitedHomeWeek", 0)) != cur_w:
				CareerState.career["careerMeta"]["visitedHomeWeek"] = cur_w
				CareerState.career["playerProfile"]["energy"] = mini(100, int(CareerState.career["playerProfile"]["energy"]) + 20)
				CareerState.save_active_career()
				CareerState.career_updated.emit()
				AudioSynth.play_achievement()
	)
	r_hb.add_child(rest_b)

	var out_b := Button.new()
	out_b.text = "KELUAR KE JALAN KOTA"
	out_b.custom_minimum_size = Vector2(0, 40)
	UITheme.style_btn(out_b, Color("#1E2C42"), UITheme.BORDER_CYAN, 12)
	out_b.pressed.connect(func(): AudioSynth.play_click(); _zone = ZoneMode.STREET; _player_pos = Vector3(-9.0, 0, 22.0); _rebuild_zone())
	vb.add_child(out_b)

func _on_hud_drag_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
		var mb: InputEventMouseButton = ev
		if mb.pressed:
			_drag_active = true
			_drag_origin = mb.position
			_move_vec = Vector2.ZERO
		else:
			_drag_active = false
			_move_vec = Vector2.ZERO
	elif ev is InputEventMouseMotion and _drag_active:
		var delta_v: Vector2 = (ev.position - _drag_origin)
		if delta_v.length() > 10.0:
			_move_vec = delta_v.normalized()
		else:
			_move_vec = Vector2.ZERO

func _process(delta: float) -> void:
	if _zone != ZoneMode.STREET:
		return
	var inp := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)
	if inp.length() < 0.1:
		inp = _move_vec
	if inp.length() > 0.1:
		inp = inp.normalized()
		_player_pos += Vector3(inp.x, 0.0, inp.y) * 9.5 * delta
		_player_pos.x = clampf(_player_pos.x, -20.0, 20.0)
		_player_pos.z = clampf(_player_pos.z, -36.0, 28.0)

	# Proximity detection
	_near_landmark = ""
	for lm in LANDMARKS.keys():
		if _player_pos.distance_to(LANDMARKS[lm]["pos"]) < 4.5:
			_near_landmark = str(lm)
			break

	if not _near_landmark.is_empty():
		_enter_btn.text = "MASUK: %s" % _near_landmark
		_enter_btn.visible = true
	else:
		_enter_btn.visible = false

	var t_pos: Vector3 = LANDMARKS.get(_target_landmark, LANDMARKS["SNEAKERS"])["pos"]
	_dist_lbl.text = "%d m • KOTA" % int(_player_pos.distance_to(t_pos) * 10.0)
	_minimap.queue_redraw()
	_sync_player_and_camera()

func _sync_player_and_camera() -> void:
	_player_rig.position = _player_pos + Vector3(0.0, 0.9, 0.0)
	if _zone == ZoneMode.STREET:
		_cam.position = _player_pos + Vector3(0.0, 5.6, 10.2)
		_cam.look_at(_player_pos + Vector3(0.0, 2.0, -11.0), Vector3.UP)
	else:
		_cam.position = Vector3(0.0, 5.2, 8.2)
		_cam.look_at(Vector3(0.0, 1.0, -1.2), Vector3.UP)

func _on_enter_landmark() -> void:
	AudioSynth.play_click()
	if _near_landmark == "SNEAKERS":
		_zone = ZoneMode.SNEAKERS_SHOP
		_rebuild_zone()
	elif _near_landmark == "APARTEMEN":
		_zone = ZoneMode.APARTMENT_ROOM
		_rebuild_zone()
	elif _near_landmark == "STADION":
		start_match_from_city.emit()
		queue_free()

func _draw_minimap() -> void:
	var s := _minimap.size
	_minimap.draw_rect(Rect2(Vector2.ZERO, s), Color("#1C242C"))
	var map_x := func(wx: float) -> float:
		return clampf((wx + 24.0) / 48.0 * s.x, 4.0, s.x - 4.0)
	var map_y := func(wz: float) -> float:
		return clampf((wz + 40.0) / 72.0 * s.y, 4.0, s.y - 4.0)
	# Streets
	_minimap.draw_rect(Rect2(map_x.call(-4), 4, 10, s.y - 8), Color("#38424E"))
	_minimap.draw_rect(Rect2(4, map_y.call(-12), s.x - 8, 8), Color("#38424E"))
	# Landmarks
	for lm in LANDMARKS.keys():
		var lp: Vector3 = LANDMARKS[lm]["pos"]
		_minimap.draw_circle(Vector2(map_x.call(lp.x), map_y.call(lp.z)), 5.0, LANDMARKS[lm]["col"])
	# Player indicator
	_minimap.draw_circle(Vector2(map_x.call(_player_pos.x), map_y.call(_player_pos.z)), 4.0, Color.WHITE)
