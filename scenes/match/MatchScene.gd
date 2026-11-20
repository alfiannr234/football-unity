extends Control

signal match_completed(report: Dictionary)
signal mode_exited

enum RunMode { CAREER_MATCH, PRACTICE_MODE, DUEL_MODE, MOVIOLA_REPLAY }
enum MatchPhase { INTRO, SIMULATING, HALFTIME, ASK_SET_PIECE, KEY_MOMENT_AIM, BALL_IN_FLIGHT, TEAMMATE_CARRY, INCOMING_PASS, REBOUND_SCRAMBLE, TEAMMATE_PENALTY_WAIT, MOMENT_RESULT, FULLTIME }
enum MomentType { SHOT, PASS, DRIBBLE, FREE_KICK, PENALTY, TEAMMATE_PENALTY, TEAMMATE_PASS }

var run_mode: RunMode = RunMode.CAREER_MATCH
var duel_target: Dictionary = {}
var replay_clip: Dictionary = {}

# 3D World Nodes
var _viewport_container: SubViewportContainer
var _sub_viewport: SubViewport
var _world_3d: Node3D
var _camera: Camera3D
var _ball_sprite: Sprite3D
var _ball_shadow: Sprite3D
var _player_sprite: Sprite3D
var _player_shadow: Sprite3D
var _gk_sprite: Sprite3D
var _gk_shadow: Sprite3D
var _teammates: Array[Sprite3D] = []
var _defenders: Array[Sprite3D] = []
var _aim_mesh_inst: MeshInstance3D
var _aim_imm: ImmediateMesh
var _ring_mesh_inst: MeshInstance3D
var _ring_imm: ImmediateMesh
var _trail_mesh_inst: MeshInstance3D
var _trail_imm: ImmediateMesh

# HUD & Controls
var _score_lbl: Label
var _minute_lbl: Label
var _ticker_lbl: Label
var _speed_btn: Button
var _moment_banner: PanelContainer
var _moment_title_lbl: Label
var _moment_sub_lbl: Label
var _power_lbl: Label
var _spin_pad: SpinBallPad
var _dribble_pad: DribbleJoystickPad
var _dribble_input: Vector2 = Vector2.ZERO
var _dribble_facing: Vector2 = Vector2(0.0, -1.0)
var _skill_burst_timer: float = 0.0
var _match_stamina: float = 100.0
var _match_stamina_max: float = 100.0
var _stamina_bar_bg: PanelContainer
var _stamina_fill: ColorRect
var _stamina_lbl: Label
var _result_toast: Label
var _exit_btn: Button
var _pause_btn: Button
var _pause_panel: Control
var _is_paused: bool = false
var _action_bar: HBoxContainer
var _action_mode_btns: Dictionary = {}
var _player_badge_lbl: Label
var _goal_flash_rect: ColorRect
var _moviola_frame: PanelContainer
var _moviola_ctrl_bar: HBoxContainer
var _replay_cam_mode: String = "TV"
var _replay_speed: float = 0.5
var _replay_orbit_angle: float = 0.4
var _replay_orbit_dragging: bool = false

# 2D Broadcast Board, Halftime Locker, & Set-Piece Request Overlays
var _board_panel: Control
var _board_score_lbl: Label
var _board_min_lbl: Label
var _board_poss_lbl: Label
var _board_poss_bar: ColorRect
var _board_hl_lbl: Label
var _board_feed_vb: VBoxContainer
var _board_rating_lbl: Label
var _board_energy_bar: ColorRect
var _board_energy_lbl: Label
var _board_timeline: Control
var _board_events: Array[Dictionary] = []
var _board_paused: bool = false
var _strat_btn: Button
var _inten_btn: Button
var _halftime_panel: Control
var _halftime_done: bool = false
var _ask_panel: Control
var _pending_ask_type: MomentType = MomentType.FREE_KICK
var _sim_event_timer: float = 0.0

# Match Simulation State
var _phase: MatchPhase = MatchPhase.INTRO
var _minute: float = 1.0
var _sim_speed: float = 1.0
var _score_us: int = 0
var _score_them: int = 0
var _my_goals: int = 0
var _my_assists: int = 0
var _penalties_scored: int = 0
var _freekicks_scored: int = 0
var _dribbles_won: int = 0
var _passes_won: int = 0
var _rating: float = 6.2
var _shots_telemetry: Array[Dictionary] = []
var _key_moment_minutes: Array[int] = []
var _next_moment_idx: int = 0
var _practice_round: int = 0
var _duel_score: int = 0

# Key Moment Physics State
var _moment_type: MomentType = MomentType.SHOT
var _player_pos: Vector3 = Vector3(0.0, 0.0, -32.0)
var _ball_pos: Vector3 = Vector3(0.0, 0.115, -31.2)
var _ball_vel: Vector3 = Vector3.ZERO
var _ball_omega: Vector3 = Vector3.ZERO
var _trail_points: Array[Vector3] = []
var _gk_pos: Vector3 = Vector3(0.0, 0.0, -51.6)
var _gk_target_x: float = 0.0
var _gk_dive_dir: float = 0.0
var _gk_react_timer: float = 0.0
var _defender_positions: Array[Vector3] = []
var _defender_dirs: Array[float] = []
var _teammate_positions: Array[Vector3] = []
var _teammate_vels: Array[Vector3] = []
var _teammate_targets: Array[Vector3] = []
var _teammate_open_scores: Array[float] = []
var _rebound_grace: float = 0.0
var _rebound_timer: float = 0.0
var _shot_by_teammate: bool = false
var _post_rebound_eligible: bool = false
var _tm_penalty_timer: float = 0.0
var _tm_penalty_kicked: bool = false
var _carry_tm_idx: int = -1
var _carry_timer: float = 0.0
var _carry_shoot_at: float = 1.2
var _carry_pass_back: bool = false
var _carry_assist_pending: bool = false
var _carry_shrug_cd: float = 0.0
var _incoming_pass_tm_idx: int = -1
var _incoming_pass_timer: float = 0.0
var _incoming_pass_kicked: bool = false
var _anim_clock: float = 0.0
var _gk_sway_clock: float = 0.0
var _kick_offside_flags: Array[bool] = []
var _kick_offside_line_z: float = -35.0
var _goal_timeline: Array[Dictionary] = []
var _best_pass_openness: float = 0.0
var _last_pass_state: String = ""

# Slingshot Input State
var _dragging: bool = false
var _drag_start: Vector2 = Vector2.ZERO
var _drag_current: Vector2 = Vector2.ZERO
var _spin_offset: Vector2 = Vector2.ZERO
var _flight_timer: float = 0.0
var _result_timer: float = 0.0
var _camera_shake: float = 0.0
var _cam_target_pos: Vector3 = Vector3(0.0, 9.0, -18.0)
var _cam_look_pos: Vector3 = Vector3(0.0, 1.0, -52.5)

# Moviola Recording
var _current_clip_frames: Array = []
var _best_clip: Dictionary = {}
var _replay_idx: int = 0
var _replay_timer: float = 0.0

var _tex_home: Texture2D
var _tex_away: Texture2D
var _tex_keeper: Texture2D
var _tex_ball: Texture2D

func configure_career_match() -> void:
	run_mode = RunMode.CAREER_MATCH

func configure_practice() -> void:
	run_mode = RunMode.PRACTICE_MODE

func configure_duel(friend_dict: Dictionary) -> void:
	run_mode = RunMode.DUEL_MODE
	duel_target = friend_dict

func configure_moviola_replay(clip: Dictionary) -> void:
	run_mode = RunMode.MOVIOLA_REPLAY
	replay_clip = clip

func _ready() -> void:
	theme = UITheme.build_theme()
	SettingsManager.set_in_match(true)
	_tex_home = load("res://assets/sprites/characters/player_home_sheet.png")
	_tex_away = load("res://assets/sprites/characters/player_away_sheet.png")
	_tex_keeper = load("res://assets/sprites/characters/keeper_sheet.png")
	_tex_ball = load("res://assets/sprites/pitch/ball_sprite.png")

	_build_3d_stadium()
	_build_hud()
	_start_selected_mode()

func _exit_tree() -> void:
	SettingsManager.set_in_match(false)

func _build_3d_stadium() -> void:
	_viewport_container = SubViewportContainer.new()
	_viewport_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_viewport_container.stretch = true
	_viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_viewport_container)

	var ultra_light := bool(SettingsManager.data.get("ultra_light_mode", false))
	_sub_viewport = SubViewport.new()
	_sub_viewport.size = Vector2i(960, 540)
	_sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_sub_viewport.msaa_3d = Viewport.MSAA_DISABLED if ultra_light else Viewport.MSAA_4X
	_viewport_container.add_child(_sub_viewport)

	_world_3d = Node3D.new()
	_sub_viewport.add_child(_world_3d)

	# Championship Twilight Sky, ACES Tonemapping & Crisp Stadium Lighting
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("#0D1F3C")
	sky_mat.sky_horizon_color = Color("#D9824C")
	sky_mat.sky_curve = 0.09
	sky_mat.ground_bottom_color = Color("#0F1A28")
	sky_mat.ground_horizon_color = Color("#465D78")
	sky_mat.sun_angle_max = 18.0
	var sky := Sky.new()
	sky.sky_material = sky_mat
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_sky_contribution = 0.62
	env.ambient_light_color = Color("#DCE8F8")
	env.ambient_light_energy = 0.62
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 0.94
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.09
	env.adjustment_saturation = 1.12
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	env.fog_light_color = Color("#4B688E")
	env.fog_density = 0.0038
	env.fog_sky_affect = 0.22
	if not ultra_light:
		env.glow_enabled = true
		env.glow_intensity = 0.32
		env.glow_bloom = 0.06
		env.glow_hdr_threshold = 0.96
	world_env.environment = env
	_world_3d.add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, 26, 0)
	sun.light_color = Color("#FFF2D8")
	sun.light_energy = 0.92
	sun.shadow_enabled = not ultra_light
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_max_distance = 140.0
	_world_3d.add_child(sun)

	if not ultra_light:
		for fx in [-22.0, 22.0]:
			var flood_fill := OmniLight3D.new()
			flood_fill.position = Vector3(fx, 15.0, -44.0)
			flood_fill.light_color = Color("#FFF4DE")
			flood_fill.light_energy = 0.45
			flood_fill.omni_range = 70.0
			flood_fill.omni_attenuation = 1.2
			_world_3d.add_child(flood_fill)

	_build_stadium_architecture()

	_camera = Camera3D.new()
	_camera.fov = 50.0
	_camera.near = 0.2
	_camera.far = 300.0
	_world_3d.add_child(_camera)

	# Outer surround grass
	var surround := MeshInstance3D.new()
	var surr_m := PlaneMesh.new()
	surr_m.size = Vector2(110, 150)
	surround.mesh = surr_m
	surround.position = Vector3(0, -0.02, 0)
	var surr_mat := StandardMaterial3D.new()
	surr_mat.albedo_color = Color("#1F5A2E")
	surround.material_override = surr_mat
	_world_3d.add_child(surround)

	# Crisp Point-Filtered Striped Pitch
	var pitch := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(74.0, 114.0)
	pitch.mesh = pm
	var pmat := StandardMaterial3D.new()
	pmat.albedo_texture = load("res://assets/sprites/pitch/pitch_turf.png")
	pmat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	pmat.roughness = 0.95
	pitch.material_override = pmat
	_world_3d.add_child(pitch)

	# Top & Bottom Goals
	_create_goal_at(-SlingshotPhysics.PITCH_HALF_L, -1.0)
	_create_goal_at(SlingshotPhysics.PITCH_HALF_L, 1.0)

	# Perimeter Ad Boards & Stadium Stands
	var ad_tex: Texture2D = load("res://assets/sprites/pitch/ad_board.png")
	var ad_mat := StandardMaterial3D.new()
	ad_mat.albedo_texture = ad_tex
	ad_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	ad_mat.uv1_scale = Vector3(4.0, 1.0, 1.0)
	_add_box_mesh(Vector3(0, 0.55, -56.5), Vector3(72, 1.1, 0.3), ad_mat)
	_add_box_mesh(Vector3(-37.5, 0.55, 0), Vector3(0.3, 1.1, 112), ad_mat)
	_add_box_mesh(Vector3(37.5, 0.55, 0), Vector3(0.3, 1.1, 112), ad_mat)

	if not bool(SettingsManager.data.get("ultra_light_mode", false)):
		var crowd_tex: Texture2D = load("res://assets/sprites/pitch/stands_crowd.png")
		var crowd_mat := StandardMaterial3D.new()
		crowd_mat.albedo_texture = crowd_tex
		crowd_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		crowd_mat.uv1_scale = Vector3(6.0, 2.0, 1.0)
		_add_box_mesh(Vector3(0, 4.5, -66.0), Vector3(82, 9.0, 12.0), crowd_mat)
		_add_box_mesh(Vector3(-46.0, 4.5, 0), Vector3(10.0, 9.0, 120.0), crowd_mat)
		_add_box_mesh(Vector3(46.0, 4.5, 0), Vector3(10.0, 9.0, 120.0), crowd_mat)

	# Billboard Sprites (Player, Ball, GK, 3 Teammates, 4 Defenders)
	_player_sprite = _make_character_sprite(_tex_home, true)
	_player_shadow = _make_shadow_sprite(0.85)
	_gk_sprite = _make_character_sprite(_tex_keeper, false)
	_gk_shadow = _make_shadow_sprite(0.85)

	_ball_sprite = Sprite3D.new()
	_ball_sprite.texture = _tex_ball
	_ball_sprite.pixel_size = 0.007
	_ball_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_ball_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_world_3d.add_child(_ball_sprite)
	_ball_shadow = _make_shadow_sprite(0.45)

	for _i in range(3):
		var tm := _make_character_sprite(_tex_home, true)
		tm.visible = false
		_teammates.append(tm)
	for _i in range(5):
		var df := _make_character_sprite(_tex_away, false)
		df.visible = false
		_defenders.append(df)

	# ImmediateMesh helpers for Ground Ring (CINCIN), Aim Trajectory (AIM), and Ball Trail (JEJAK)
	_ring_imm = ImmediateMesh.new()
	_ring_mesh_inst = _make_imm_mesh_node(_ring_imm, 2.0)
	_aim_imm = ImmediateMesh.new()
	_aim_mesh_inst = _make_imm_mesh_node(_aim_imm, 2.0)
	_trail_imm = ImmediateMesh.new()
	_trail_mesh_inst = _make_imm_mesh_node(_trail_imm, 2.0)

func _make_imm_mesh_node(imm: ImmediateMesh, _w: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = imm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.no_depth_test = false
	mi.material_override = mat
	_world_3d.add_child(mi)
	return mi

func _add_box_mesh(pos: Vector3, sz: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = sz
	mi.mesh = bm
	mi.position = pos
	mi.material_override = mat
	_world_3d.add_child(mi)

func _build_stadium_architecture() -> void:
	var steel_mat := StandardMaterial3D.new()
	steel_mat.albedo_color = Color("#1B283A")
	steel_mat.metallic = 0.45
	steel_mat.roughness = 0.45

	var trim_mat := StandardMaterial3D.new()
	trim_mat.albedo_color = Color("#38B6FF")
	trim_mat.emission_enabled = true
	trim_mat.emission = Color("#38B6FF")
	trim_mat.emission_energy_multiplier = 0.9

	var pylon_lamp_mat := StandardMaterial3D.new()
	pylon_lamp_mat.albedo_color = Color("#FFF9E8")
	pylon_lamp_mat.emission_enabled = true
	pylon_lamp_mat.emission = Color("#FFF5D6")
	pylon_lamp_mat.emission_energy_multiplier = 2.4

	# Grandstand Roof Canopies & Glowing Fascia Ribbons
	_add_box_mesh(Vector3(0, 10.4, -65.0), Vector3(84.0, 0.75, 14.0), steel_mat)
	_add_box_mesh(Vector3(0, 9.85, -58.2), Vector3(82.0, 0.38, 0.45), trim_mat)
	_add_box_mesh(Vector3(-46.5, 10.4, -4.0), Vector3(12.5, 0.75, 122.0), steel_mat)
	_add_box_mesh(Vector3(-40.4, 9.85, -4.0), Vector3(0.45, 0.38, 118.0), trim_mat)
	_add_box_mesh(Vector3(46.5, 10.4, -4.0), Vector3(12.5, 0.75, 122.0), steel_mat)
	_add_box_mesh(Vector3(40.4, 9.85, -4.0), Vector3(0.45, 0.38, 118.0), trim_mat)

	# Structural Pillars behind North & Side Stands
	for px in [-38.0, -20.0, 0.0, 20.0, 38.0]:
		_add_box_mesh(Vector3(px, 5.2, -71.5), Vector3(0.9, 10.4, 0.9), steel_mat)
	for pz in [-48.0, -24.0, 0.0, 24.0, 48.0]:
		_add_box_mesh(Vector3(-52.0, 5.2, pz), Vector3(0.9, 10.4, 0.9), steel_mat)
		_add_box_mesh(Vector3(52.0, 5.2, pz), Vector3(0.9, 10.4, 0.9), steel_mat)

	# 4 Corner Floodlight Towers (North towers positioned within hero camera framing)
	for corner in [Vector3(-34.5, 0.0, -64.0), Vector3(34.5, 0.0, -64.0), Vector3(-42.0, 0.0, 56.0), Vector3(42.0, 0.0, 56.0)]:
		var mast_h := 16.5 if corner.z < 0.0 else 22.4
		_add_box_mesh(Vector3(corner.x, mast_h * 0.5, corner.z), Vector3(1.1, mast_h, 1.1), steel_mat)
		var head_pos := Vector3(corner.x * 0.97, mast_h + 0.4, corner.z * 0.97)
		var head := MeshInstance3D.new()
		var hm := BoxMesh.new()
		hm.size = Vector3(6.2, 2.6, 0.7)
		head.mesh = hm
		head.material_override = steel_mat
		head.position = head_pos
		_world_3d.add_child(head)
		head.look_at(Vector3(0.0, 0.0, corner.z * 0.35), Vector3.UP)

		var panel := MeshInstance3D.new()
		var pm := BoxMesh.new()
		pm.size = Vector3(5.6, 2.2, 0.16)
		panel.mesh = pm
		panel.material_override = pylon_lamp_mat
		panel.position = Vector3(0.0, 0.0, -0.42)
		head.add_child(panel)

	# Corner Flags & Technical Dugout Benches
	var flag_pole_mat := StandardMaterial3D.new()
	flag_pole_mat.albedo_color = Color("#F5F8FC")
	var flag_mat := StandardMaterial3D.new()
	flag_mat.albedo_color = Color("#F5C440")
	flag_mat.emission_enabled = true
	flag_mat.emission = Color("#D49B24")
	flag_mat.emission_energy_multiplier = 0.4
	for cx in [-34.5, 34.5]:
		for cz in [-52.5, 52.5]:
			_add_box_mesh(Vector3(cx, 0.7, cz), Vector3(0.08, 1.4, 0.08), flag_pole_mat)
			_add_box_mesh(Vector3(cx + (0.22 if cx < 0 else -0.22), 1.24, cz), Vector3(0.42, 0.28, 0.04), flag_mat)

	for dz in [-11.5, 11.5]:
		_add_box_mesh(Vector3(-39.2, 1.1, dz), Vector3(1.8, 2.2, 6.2), steel_mat)

func _create_goal_at(z_line: float, depth_dir: float) -> void:
	var post_mat := StandardMaterial3D.new()
	post_mat.albedo_color = Color("#F8FBFF")
	post_mat.metallic = 0.22
	post_mat.roughness = 0.28
	var hw := SlingshotPhysics.GOAL_HALF_W
	var gh := SlingshotPhysics.GOAL_HEIGHT
	var gd := SlingshotPhysics.GOAL_DEPTH * depth_dir

	_add_box_mesh(Vector3(-hw, gh * 0.5, z_line), Vector3(0.14, gh, 0.14), post_mat)
	_add_box_mesh(Vector3(hw, gh * 0.5, z_line), Vector3(0.14, gh, 0.14), post_mat)
	_add_box_mesh(Vector3(0, gh, z_line), Vector3(hw * 2.0 + 0.14, 0.14, 0.14), post_mat)
	# Rear Stanchions & Base Frame
	_add_box_mesh(Vector3(-hw, gh * 0.5, z_line + gd), Vector3(0.08, gh, 0.08), post_mat)
	_add_box_mesh(Vector3(hw, gh * 0.5, z_line + gd), Vector3(0.08, gh, 0.08), post_mat)
	_add_box_mesh(Vector3(0, 0.05, z_line + gd), Vector3(hw * 2.0 + 0.08, 0.08, 0.08), post_mat)
	_add_box_mesh(Vector3(-hw, 0.05, z_line + gd * 0.5), Vector3(0.08, 0.08, absf(gd)), post_mat)
	_add_box_mesh(Vector3(hw, 0.05, z_line + gd * 0.5), Vector3(0.08, 0.08, absf(gd)), post_mat)

	var net_mat := StandardMaterial3D.new()
	net_mat.albedo_texture = load("res://assets/sprites/pitch/goal_net.png")
	net_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	net_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	net_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	net_mat.uv1_scale = Vector3(5.0, 2.0, 1.0)
	_add_box_mesh(Vector3(0, gh * 0.5, z_line + gd), Vector3(hw * 2.0, gh, 0.04), net_mat)
	_add_box_mesh(Vector3(-hw, gh * 0.5, z_line + gd * 0.5), Vector3(0.04, gh, absf(gd)), net_mat)
	_add_box_mesh(Vector3(hw, gh * 0.5, z_line + gd * 0.5), Vector3(0.04, gh, absf(gd)), net_mat)
	_add_box_mesh(Vector3(0, gh, z_line + gd * 0.5), Vector3(hw * 2.0, 0.04, absf(gd)), net_mat)

func _make_character_sprite(tex: Texture2D, back_view: bool) -> Sprite3D:
	var sp := Sprite3D.new()
	sp.texture = tex
	sp.hframes = 4
	sp.vframes = 2
	sp.frame = 4 if back_view else 0
	sp.pixel_size = 0.026
	sp.offset = Vector2(0, 36)
	sp.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sp.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sp.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	_world_3d.add_child(sp)
	return sp

func _make_shadow_sprite(radius: float) -> Sprite3D:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for y in range(16):
		for x in range(16):
			var d := Vector2(x - 7.5, y - 7.5).length() / 7.5
			if d <= 1.0:
				img.set_pixel(x, y, Color(0, 0, 0, 0.45))
	var sp := Sprite3D.new()
	sp.texture = ImageTexture.create_from_image(img)
	sp.axis = Vector3.AXIS_Y
	sp.pixel_size = radius * 0.12
	sp.position = Vector3(0, 0.02, 0)
	_world_3d.add_child(sp)
	return sp

func _build_hud() -> void:
	# Top Broadcast Scorebug (Landscape compact bar)
	var top_bar := PanelContainer.new()
	top_bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_bar.offset_left = 10
	top_bar.offset_right = -10
	top_bar.offset_top = 8
	top_bar.offset_bottom = 52
	top_bar.add_theme_stylebox_override("panel", UITheme.make_box(Color(0.03, 0.07, 0.14, 0.92), UITheme.BORDER_CYAN, 1, 3))
	add_child(top_bar)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	top_bar.add_child(hb)

	_minute_lbl = Label.new()
	_minute_lbl.text = "1'"
	_minute_lbl.custom_minimum_size = Vector2(48, 0)
	_minute_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_minute_lbl.add_theme_font_override("font", UITheme.get_display_font())
	_minute_lbl.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	_minute_lbl.add_theme_font_size_override("font_size", 18)
	hb.add_child(_minute_lbl)

	_score_lbl = Label.new()
	_score_lbl.text = "DED 0 - 0 SVA"
	_score_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score_lbl.add_theme_font_override("font", UITheme.get_display_font())
	_score_lbl.add_theme_font_size_override("font_size", 18)
	hb.add_child(_score_lbl)

	_speed_btn = Button.new()
	_speed_btn.text = "2X"
	_speed_btn.custom_minimum_size = Vector2(54, 30)
	UITheme.style_btn(_speed_btn, Color("#183860"), UITheme.BORDER_CYAN)
	_speed_btn.pressed.connect(_on_toggle_speed)
	hb.add_child(_speed_btn)

	_exit_btn = Button.new()
	_exit_btn.text = "SKIP"
	_exit_btn.custom_minimum_size = Vector2(58, 30)
	UITheme.style_btn(_exit_btn, Color("#4E2424"), UITheme.ACCENT_RED)
	_exit_btn.pressed.connect(_on_skip_or_exit)
	hb.add_child(_exit_btn)

	_pause_btn = Button.new()
	_pause_btn.text = "II"
	_pause_btn.custom_minimum_size = Vector2(36, 30)
	UITheme.style_btn(_pause_btn, Color("#152A46"), UITheme.BORDER_CYAN)
	_pause_btn.pressed.connect(func(): AudioSynth.play_click(); _open_pause_menu())
	hb.add_child(_pause_btn)

	# Commentary Ticker Strip (top-left leaving center pitch open)
	var ticker_panel := PanelContainer.new()
	ticker_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	ticker_panel.offset_left = 10
	ticker_panel.offset_right = -380
	ticker_panel.offset_top = 56
	ticker_panel.offset_bottom = 82
	ticker_panel.add_theme_stylebox_override("panel", UITheme.make_box(Color(0.03, 0.06, 0.12, 0.85), UITheme.BORDER_STEEL, 1, 2))
	add_child(ticker_panel)

	_ticker_lbl = Label.new()
	_ticker_lbl.text = "Kickoff! Peluang emas menantimu di lapangan."
	_ticker_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ticker_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_ticker_lbl.clip_text = true
	_ticker_lbl.add_theme_font_size_override("font_size", 12)
	ticker_panel.add_child(_ticker_lbl)

	# Key Moment Prompt Banner
	_moment_banner = PanelContainer.new()
	_moment_banner.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_moment_banner.offset_left = 10
	_moment_banner.offset_right = -380
	_moment_banner.offset_top = 86
	_moment_banner.offset_bottom = 142
	_moment_banner.add_theme_stylebox_override("panel", UITheme.make_box(Color(0.05, 0.14, 0.28, 0.90), UITheme.ACCENT_GOLD, 2, 4))
	_moment_banner.visible = false
	add_child(_moment_banner)

	var mb_vb := VBoxContainer.new()
	_moment_banner.add_child(mb_vb)
	_moment_title_lbl = Label.new()
	_moment_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_moment_title_lbl.add_theme_font_override("font", UITheme.get_display_font())
	_moment_title_lbl.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	_moment_title_lbl.add_theme_font_size_override("font_size", 15)
	mb_vb.add_child(_moment_title_lbl)

	_moment_sub_lbl = Label.new()
	_moment_sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_moment_sub_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_moment_sub_lbl.add_theme_font_size_override("font_size", 11)
	mb_vb.add_child(_moment_sub_lbl)

	# Moviola TV Frame Banner + Interactive 3D Camera Controls (0.5x/1x | TV | GOL | ORBIT | BEBAS)
	_moviola_frame = PanelContainer.new()
	_moviola_frame.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_moviola_frame.offset_left = 10
	_moviola_frame.offset_right = -10
	_moviola_frame.offset_top = 86
	_moviola_frame.offset_bottom = 122
	_moviola_frame.add_theme_stylebox_override("panel", UITheme.make_box(Color("#122D54"), Color("#D94242"), 2, 2))
	_moviola_frame.visible = false
	var mov_lbl := Label.new()
	mov_lbl.text = "● REPLAY 3D • SERET UNTUK PUTAR KAMERA"
	mov_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mov_lbl.add_theme_font_override("font", UITheme.get_display_font())
	mov_lbl.add_theme_color_override("font_color", Color("#FFFFFF"))
	_moviola_frame.add_child(mov_lbl)
	add_child(_moviola_frame)

	_moviola_ctrl_bar = HBoxContainer.new()
	_moviola_ctrl_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_moviola_ctrl_bar.offset_left = 12
	_moviola_ctrl_bar.offset_right = -12
	_moviola_ctrl_bar.offset_top = -54
	_moviola_ctrl_bar.offset_bottom = -12
	_moviola_ctrl_bar.add_theme_constant_override("separation", 4)
	_moviola_ctrl_bar.visible = false
	add_child(_moviola_ctrl_bar)

	var spd_r := Button.new()
	spd_r.text = "0.5x"
	spd_r.custom_minimum_size = Vector2(56, 36)
	UITheme.style_btn(spd_r, Color("#1A263A"), UITheme.ACCENT_CYAN, 11)
	spd_r.pressed.connect(func():
		AudioSynth.play_click()
		_replay_speed = 1.0 if _replay_speed < 0.8 else 0.5
		spd_r.text = "1x" if _replay_speed > 0.8 else "0.5x"
	)
	_moviola_ctrl_bar.add_child(spd_r)

	for cam_m in ["TV", "GOL", "ORBIT", "BEBAS"]:
		var cb := Button.new()
		cb.text = cam_m
		cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cb.custom_minimum_size = Vector2(0, 36)
		UITheme.style_btn(cb, Color("#243A5E"), UITheme.ACCENT_GOLD, 11)
		cb.pressed.connect(func(): AudioSynth.play_click(); _replay_cam_mode = cam_m)
		_moviola_ctrl_bar.add_child(cb)

	_build_board_and_overlays()

	# Top-Right Unified Open-Play Action Pill (TEMBAK / UMPAN)
	_action_bar = HBoxContainer.new()
	_action_bar.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_action_bar.offset_left = -260
	_action_bar.offset_right = -10
	_action_bar.offset_top = 56
	_action_bar.offset_bottom = 90
	_action_bar.add_theme_constant_override("separation", 4)
	_action_bar.visible = false
	add_child(_action_bar)
	var main_act_btn := Button.new()
	main_act_btn.text = "TEMBAK / UMPAN"
	main_act_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_act_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UITheme.style_btn(main_act_btn, Color("#174A7A"), UITheme.ACCENT_GOLD, 11)
	_action_bar.add_child(main_act_btn)
	_action_mode_btns["MAIN"] = main_act_btn

	# eFootball / EA SPORTS FC Style Circular Virtual Joystick (Bottom-Left during Open Play)
	_dribble_pad = DribbleJoystickPad.new()
	_dribble_pad.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_dribble_pad.offset_left = 18
	_dribble_pad.offset_right = 158
	_dribble_pad.offset_top = -152
	_dribble_pad.offset_bottom = -12
	_dribble_pad.visible = false
	_dribble_pad.joy_changed.connect(func(v: Vector2): _dribble_input = v)
	add_child(_dribble_pad)

	# Bottom-Left Live Stamina Bar (above circular joystick)
	_stamina_bar_bg = PanelContainer.new()
	_stamina_bar_bg.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_stamina_bar_bg.offset_left = 18
	_stamina_bar_bg.offset_right = 178
	_stamina_bar_bg.offset_top = -176
	_stamina_bar_bg.offset_bottom = -156
	_stamina_bar_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stamina_bar_bg.add_theme_stylebox_override("panel", UITheme.make_box(Color(0.03, 0.07, 0.14, 0.90), UITheme.BORDER_CYAN, 1, 3))
	_stamina_bar_bg.visible = false
	add_child(_stamina_bar_bg)
	var st_ctrl := Control.new()
	st_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stamina_bar_bg.add_child(st_ctrl)
	_stamina_fill = ColorRect.new()
	_stamina_fill.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	_stamina_fill.anchor_right = 1.0
	_stamina_fill.color = UITheme.ACCENT_GREEN
	_stamina_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	st_ctrl.add_child(_stamina_fill)
	_stamina_lbl = Label.new()
	_stamina_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stamina_lbl.text = "STAMINA 100%"
	_stamina_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stamina_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_stamina_lbl.add_theme_font_size_override("font_size", 10)
	_stamina_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	_stamina_lbl.add_theme_constant_override("outline_size", 3)
	_stamina_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	st_ctrl.add_child(_stamina_lbl)

	# Bottom-Left Player Number/Name Badge
	_player_badge_lbl = Label.new()
	_player_badge_lbl.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_player_badge_lbl.offset_left = 18
	_player_badge_lbl.offset_top = -202
	_player_badge_lbl.offset_right = 240
	_player_badge_lbl.offset_bottom = -178
	_player_badge_lbl.add_theme_font_override("font", UITheme.get_display_font())
	_player_badge_lbl.add_theme_font_size_override("font_size", 15)
	_player_badge_lbl.add_theme_color_override("font_color", Color.WHITE)
	_player_badge_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	_player_badge_lbl.add_theme_constant_override("outline_size", 4)
	_player_badge_lbl.visible = false
	add_child(_player_badge_lbl)

	# Power Readout Badge (Bottom-Right above Spin Pad)
	_power_lbl = Label.new()
	_power_lbl.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_power_lbl.offset_left = -165
	_power_lbl.offset_right = -16
	_power_lbl.offset_top = -166
	_power_lbl.offset_bottom = -138
	_power_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_power_lbl.text = ""
	_power_lbl.add_theme_font_override("font", UITheme.get_display_font())
	_power_lbl.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	_power_lbl.add_theme_font_size_override("font_size", 18)
	add_child(_power_lbl)

	# Spin / Magnus Curve Touch Ball at Bottom-Right
	_spin_pad = SpinBallPad.new()
	_spin_pad.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_spin_pad.offset_left = -114
	_spin_pad.offset_top = -134
	_spin_pad.offset_right = -16
	_spin_pad.offset_bottom = -20
	_spin_pad.spin_changed.connect(func(sp: Vector2): _spin_offset = sp)
	add_child(_spin_pad)

	_goal_flash_rect = ColorRect.new()
	_goal_flash_rect.color = Color(1.0, 0.92, 0.45, 0.0)
	_goal_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_goal_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_goal_flash_rect)

	# Big Outcome Toast (GOAL!! / DITEPIS / TIANG!)
	_result_toast = Label.new()
	_result_toast.set_anchors_preset(Control.PRESET_CENTER)
	_result_toast.offset_left = -220
	_result_toast.offset_right = 220
	_result_toast.offset_top = -40
	_result_toast.offset_bottom = 40
	_result_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_toast.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_result_toast.add_theme_font_override("font", UITheme.get_display_font())
	_result_toast.add_theme_font_size_override("font_size", 32)
	_result_toast.add_theme_color_override("font_outline_color", Color.BLACK)
	_result_toast.add_theme_constant_override("outline_size", 6)
	_result_toast.visible = false
	add_child(_result_toast)

func _start_selected_mode() -> void:
	_score_us = 0
	_score_them = 0
	_my_goals = 0
	_my_assists = 0
	_penalties_scored = 0
	_freekicks_scored = 0
	_dribbles_won = 0
	_passes_won = 0
	_rating = 6.2
	_shots_telemetry.clear()
	_goal_timeline.clear()
	_best_clip = {}
	_match_stamina_max = 100.0
	_match_stamina = _match_stamina_max

	if run_mode == RunMode.MOVIOLA_REPLAY:
		_speed_btn.visible = false
		_spin_pad.visible = false
		_exit_btn.text = "TUTUP"
		_moviola_frame.visible = true
		_moviola_ctrl_bar.visible = true
		_score_lbl.text = str(replay_clip.get("match_title", "MOVIOLA REPLAY"))
		_minute_lbl.text = "%d'" % int(replay_clip.get("minute", 75))
		_ticker_lbl.text = str(replay_clip.get("caption", "Tayangan ulang momen krusial."))
		_replay_idx = 0
		_replay_timer = 0.0
		_phase = MatchPhase.BALL_IN_FLIGHT
		return

	if run_mode == RunMode.PRACTICE_MODE:
		_speed_btn.visible = false
		_exit_btn.text = "SELESAI"
		_practice_round = 1
		_score_lbl.text = "LATIHAN KETAPEL"
		_minute_lbl.text = "1/5"
		_trigger_key_moment(MomentType.FREE_KICK if randf() < 0.4 else MomentType.SHOT)
		return

	if run_mode == RunMode.DUEL_MODE:
		_speed_btn.visible = false
		_exit_btn.text = "BATAL"
		_practice_round = 1
		_duel_score = 0
		_score_lbl.text = "DUEL VS %s (%d)" % [str(duel_target.get("name", "TEMAN")).to_upper(), int(duel_target.get("score_them", 4))]
		_minute_lbl.text = "1/5"
		_trigger_key_moment(MomentType.PENALTY if _practice_round == 5 else MomentType.SHOT)
		return

	# CAREER_MATCH
	var club := CareerState.get_current_club()
	var fix := CareerState.get_current_fixture()
	var us_code: String = club.get("code", "DED")
	var them_code: String = fix.get("opp_code", "SVA")
	_score_lbl.text = "%s 0 - 0 %s" % [us_code, them_code]
	_minute = 1.0
	_sim_speed = 1.0
	_speed_btn.text = "1X"

	var visi := CareerState.get_effective_attribute("visi")
	var rel_tm := int(CareerState.career["playerProfile"]["relations"]["ruangGanti"])
	var diff_params: Dictionary = SettingsManager.get_difficulty_params()
	var chance_delta: int = int(diff_params.get("chance_delta", 0))
	var num_moments: int = maxi(2, 4 + (1 if visi >= 70 else 0) + (1 if rel_tm >= 60 else 0) + chance_delta)
	_key_moment_minutes.clear()
	for i in range(num_moments):
		var m := int(lerpf(10.0, 88.0, float(i) / maxf(1.0, float(num_moments - 1)))) + randi_range(-3, 3)
		_key_moment_minutes.append(clampi(m, 5, 90))
	_key_moment_minutes.sort()
	_next_moment_idx = 0
	_halftime_done = false
	_board_events.clear()
	_board_paused = false
	_phase = MatchPhase.SIMULATING
	if _board_panel != null and run_mode == RunMode.CAREER_MATCH:
		_board_panel.visible = true
		_spin_pad.visible = false
		_power_lbl.visible = false
		_sync_board_hud()
	AudioSynth.play_whistle(false)

func _process(delta: float) -> void:
	if _is_paused:
		return
	if run_mode == RunMode.MOVIOLA_REPLAY:
		_process_moviola_replay(delta)
		return

	_anim_clock += delta
	_update_camera(delta)

	match _phase:
		MatchPhase.SIMULATING:
			_process_simulation(delta)
		MatchPhase.KEY_MOMENT_AIM:
			_animate_gk_idle(delta)
			_animate_teammates(delta)
			if _moment_type in [MomentType.SHOT, MomentType.PASS, MomentType.DRIBBLE]:
				_process_dribble_control(delta)
			_update_pass_openness_ui()
			_draw_aim_and_ring()
		MatchPhase.TEAMMATE_PENALTY_WAIT:
			_process_teammate_penalty_wait(delta)
		MatchPhase.BALL_IN_FLIGHT:
			_process_ball_flight(delta)
		MatchPhase.TEAMMATE_CARRY:
			_process_teammate_carry(delta)
		MatchPhase.INCOMING_PASS:
			_process_incoming_pass(delta)
		MatchPhase.REBOUND_SCRAMBLE:
			_process_rebound_scramble(delta)
		MatchPhase.MOMENT_RESULT:
			_result_timer -= delta
			if _result_timer <= 0.0:
				_result_toast.visible = false
				_advance_after_moment()

func _process_simulation(delta: float) -> void:
	if _board_paused:
		return
	_minute += delta * 6.5 * _sim_speed
	_minute_lbl.text = "%d'" % mini(90, int(_minute))

	# Halftime Locker Room Stoppage at 45' (CAREER_MATCH)
	if run_mode == RunMode.CAREER_MATCH and _minute >= 45.0 and not _halftime_done:
		_halftime_done = true
		_open_halftime_locker()
		return

	# Gentle tactical pan over pitch during sim
	var pan_z := lerpf(15.0, -35.0, 0.5 + 0.5 * sin(_minute * 0.25))
	_cam_target_pos = Vector3(14.0 * cos(_minute * 0.15), 14.0, pan_z + 18.0)
	_cam_look_pos = Vector3(0.0, 0.5, pan_z)
	_player_pos = Vector3(sin(_minute * 0.2) * 8.0, 0.0, pan_z)
	_ball_pos = _player_pos + Vector3(0.0, 0.115, -1.2)
	_sync_3d_sprites()

	# Rich Live Commentary Events on 2D Crimson Match Board
	_sim_event_timer += delta * _sim_speed
	if _sim_event_timer >= 0.9:
		_sim_event_timer = 0.0
		_push_random_sim_event()

	# Random AI match events between user moments
	if randf() < delta * 0.14 * _sim_speed:
		var club := CareerState.get_current_club()
		var fix := CareerState.get_current_fixture()
		var diff := float(int(club["ovr"]) - int(fix["opp_ovr"])) * 0.015
		if randf() < 0.45 + diff:
			_score_us += 1
			var tm_scorer: String = _pick_squad_member_name(true)
			var tm_ast: String = _pick_squad_member_name(false)
			_goal_timeline.append({"minute": int(_minute), "scorer": tm_scorer, "assist": tm_ast, "is_us": true, "is_user_involved": false})
			var msg_u: String = "%d' GOL %s! %s memimpin!" % [int(_minute), tm_scorer, club["code"]]
			_ticker_lbl.text = msg_u
			_add_board_event(int(_minute), "GOAL", msg_u, true)
		else:
			_score_them += 1
			var opp_scorer: String = _pick_opp_scorer_name()
			_goal_timeline.append({"minute": int(_minute), "scorer": opp_scorer, "assist": "", "is_us": false, "is_user_involved": false})
			var msg_t: String = "%d' %s (%s) mencetak gol balasan!" % [int(_minute), opp_scorer, fix["opp_code"]]
			_ticker_lbl.text = msg_t
			_add_board_event(int(_minute), "OPP_GOAL", msg_t, false)
		_update_score_label()

	_sync_board_hud()

	if _next_moment_idx < _key_moment_minutes.size() and int(_minute) >= _key_moment_minutes[_next_moment_idx]:
		_next_moment_idx += 1
		var r := randf()
		var m_type := MomentType.SHOT
		if r < 0.18:
			m_type = MomentType.TEAMMATE_PASS
		elif r < 0.38:
			m_type = MomentType.PASS
		elif r < 0.54:
			m_type = MomentType.DRIBBLE
		elif r < 0.70:
			m_type = MomentType.FREE_KICK
		elif r < 0.82:
			m_type = MomentType.PENALTY
		if _board_panel != null:
			_board_panel.visible = false
		if run_mode == RunMode.CAREER_MATCH and (m_type == MomentType.FREE_KICK or m_type == MomentType.PENALTY) and randf() < 0.55:
			_open_ask_set_piece(m_type)
		elif run_mode == RunMode.CAREER_MATCH and m_type == MomentType.PENALTY and randf() < 0.30:
			_trigger_key_moment(MomentType.TEAMMATE_PENALTY)
		else:
			_trigger_key_moment(m_type)
		return

	if _minute >= 90.0:
		_finish_career_match()

func _trigger_key_moment(m_type: MomentType) -> void:
	_moment_type = m_type
	_phase = MatchPhase.KEY_MOMENT_AIM
	if _board_panel != null:
		_board_panel.visible = false
	_spin_pad.visible = (run_mode != RunMode.MOVIOLA_REPLAY and m_type != MomentType.TEAMMATE_PENALTY)
	_power_lbl.visible = (m_type != MomentType.TEAMMATE_PENALTY)
	_dragging = false
	_dribble_input = Vector2.ZERO
	_dribble_facing = Vector2(0.0, -1.0)
	_skill_burst_timer = 0.0
	# Each new event starts with fresh 100% match stamina
	_match_stamina_max = 100.0
	_match_stamina = _match_stamina_max
	if _dribble_pad != null:
		_dribble_pad.reset_joy()
	_spin_offset = Vector2.ZERO
	_spin_pad.reset_spin()
	_power_lbl.text = ""
	_trail_points.clear()
	_trail_imm.clear_surfaces()
	_aim_imm.clear_surfaces()
	_ring_imm.clear_surfaces()
	_current_clip_frames.clear()
	_shot_by_teammate = false
	_post_rebound_eligible = false
	_rebound_grace = 0.0
	_tm_penalty_kicked = false
	_carry_tm_idx = -1
	_carry_timer = 0.0
	_carry_pass_back = false
	_carry_assist_pending = false
	_carry_shrug_cd = 0.0
	_incoming_pass_tm_idx = -1
	_incoming_pass_timer = 0.0
	_incoming_pass_kicked = false
	_gk_sway_clock = 0.0
	_kick_offside_flags.clear()
	_kick_offside_line_z = -35.0

	# Setup positions on the attacking top half (goal at z = -52.5)
	for tm in _teammates:
		tm.visible = false
		tm.frame = 4
	for df in _defenders:
		df.visible = false
		df.frame = 0
	_player_sprite.frame = 4
	_gk_sprite.frame = 0
	_defender_positions.clear()
	_defender_dirs.clear()
	_teammate_positions.clear()
	_teammate_vels.clear()
	_teammate_targets.clear()
	_teammate_open_scores.clear()

	_gk_pos = Vector3(0.0, 0.0, -51.6)
	_gk_target_x = 0.0
	_gk_dive_dir = 0.0
	_gk_react_timer = float(SettingsManager.get_difficulty_params()["gk_reaction"])

	match m_type:
		MomentType.TEAMMATE_PENALTY:
			_setup_teammate_penalty()
			return
		MomentType.TEAMMATE_PASS:
			_setup_teammate_pass_to_user()
			return
		MomentType.PENALTY:
			_player_pos = Vector3(0.0, 0.0, -40.2)
			_ball_pos = Vector3(0.0, 0.115, -41.5)
			for i in range(2):
				_teammates[i].visible = true
				_teammate_positions.append(Vector3(-4.8 if i == 0 else 5.2, 0.0, -35.8))
				_teammate_vels.append(Vector3(0.0, 0.0, 0.0))
				_teammate_targets.append(Vector3(-4.2 if i == 0 else 4.5, 0.0, -43.0))
				_teammate_open_scores.append(2.0)
			for i in range(2):
				_defenders[i].visible = true
				_defender_positions.append(Vector3(-6.2 if i == 0 else 6.2, 0.0, -36.0))
				_defender_dirs.append(1.0 if i == 0 else -1.0)
			_moment_title_lbl.text = "PENALTI!"
			_moment_sub_lbl.text = "Tarik ketapel & atur putaran bola ke pojok gawang!"
			_ticker_lbl.text = "Hadiah PENALTI! Tarik bola ke belakang lalu lepaskan."
		MomentType.FREE_KICK:
			var x_off := randf_range(-9.0, 9.0)
			var z_off := randf_range(-33.0, -25.0)
			_player_pos = Vector3(x_off, 0.0, z_off + 1.4)
			_ball_pos = Vector3(x_off, 0.115, z_off)
			var wall_dir := (Vector3(0, 0, -52.5) - _ball_pos).normalized()
			var wall_center := _ball_pos + wall_dir * 9.15
			var perp := Vector3(-wall_dir.z, 0, wall_dir.x)
			for i in range(3):
				_defenders[i].visible = true
				_defender_positions.append(wall_center + perp * float(i - 1) * 0.95)
				_defender_dirs.append(0.0)
			for i in range(3, 5):
				_defenders[i].visible = true
				_defender_positions.append(Vector3((-4.5 if i == 3 else 4.5), 0.0, -39.5))
				_defender_dirs.append(1.0 if i == 3 else -1.0)
			# Position 3 teammates stationary in optimal onside attacking slots clear of the wall
			var kick_side: float = 1.0 if x_off >= 0.0 else -1.0
			var fk_tm_spots := [
				Vector3(-kick_side * 6.5, 0.0, -38.6),  # Back-post target (onside ahead of -39.5 line)
				Vector3(kick_side * 4.8, 0.0, -37.2),   # Near-post pocket clear of wall
				Vector3(clampf(x_off - kick_side * 5.8, -16.0, 16.0), 0.0, minf(-26.0, z_off - 2.2)),  # Short layoff
			]
			for i in range(fk_tm_spots.size()):
				if i < _teammates.size():
					_teammates[i].visible = true
					_teammate_positions.append(fk_tm_spots[i])
					_teammate_vels.append(Vector3.ZERO)
					_teammate_targets.append(fk_tm_spots[i])
					_teammate_open_scores.append(3.6)
			_moment_title_lbl.text = "TENDANGAN BEBAS!"
			_moment_sub_lbl.text = "Lengkungkan melewati pagar betis atau umpan rekan di posisi terbaik!"
			_ticker_lbl.text = "Bola mati berbahaya! Rekan siap diam di posisi terbaik."
		MomentType.PASS:
			_player_pos = Vector3(randf_range(-10.0, 10.0), 0.0, randf_range(-24.0, -18.0))
			_ball_pos = _player_pos + Vector3(0.0, 0.115, -0.8)
			_spawn_open_play_actors()
			_apply_open_play_prompt(MomentType.PASS)
		MomentType.DRIBBLE:
			_player_pos = Vector3(randf_range(-6.0, 6.0), 0.0, -30.0)
			_ball_pos = _player_pos + Vector3(0.0, 0.115, -0.8)
			_spawn_open_play_actors()
			_apply_open_play_prompt(MomentType.DRIBBLE)
		_:
			var sx := randf_range(-11.0, 11.0)
			var sz := randf_range(-37.0, -28.0)
			_player_pos = Vector3(sx, 0.0, sz + 1.0)
			_ball_pos = Vector3(sx, 0.115, sz)
			_spawn_open_play_actors()
			_apply_open_play_prompt(MomentType.SHOT)

	_moment_banner.visible = true
	_update_pass_openness_ui()
	_sync_action_bar()
	_configure_moment_camera()
	_sync_3d_sprites()
	_draw_aim_and_ring()
	AudioSynth.play_whistle(false)

func _spawn_open_play_actors() -> void:
	for tm in _teammates:
		tm.visible = false
	for df in _defenders:
		df.visible = false
	_teammate_positions.clear()
	_teammate_vels.clear()
	_teammate_targets.clear()
	_teammate_open_scores.clear()
	_defender_positions.clear()
	_defender_dirs.clear()

	var side := -1.0 if _player_pos.x > 0.0 else 1.0
	var base_z := clampf(_ball_pos.z - 2.0, -35.0, -18.0)
	# 3 forward-running teammates (always advance -Z toward opponent goal)
	var tm_defs := [
		[Vector3(clampf(_player_pos.x + side * 8.5, -18.0, 18.0), 0.0, base_z), Vector3(side * -1.1, 0.0, -3.5), Vector3(side * 4.2, 0.0, -47.0)],
		[Vector3(clampf(-_player_pos.x * 0.5 - side * 5.0, -14.0, 14.0), 0.0, base_z - 2.8), Vector3(side * 0.9, 0.0, -3.2), Vector3(0.0, 0.0, -47.5)],
		[Vector3(clampf(_player_pos.x - side * 5.5, -15.0, 15.0), 0.0, clampf(base_z + 2.0, -33.0, -16.0)), Vector3(side * 0.5, 0.0, -2.8), Vector3(-side * 2.8, 0.0, -44.5)],
	]
	for i in range(tm_defs.size()):
		if i < _teammates.size():
			_teammates[i].visible = true
			_teammate_positions.append(tm_defs[i][0])
			_teammate_vels.append(tm_defs[i][1])
			_teammate_targets.append(tm_defs[i][2])
			_teammate_open_scores.append(3.0)

	# 3 active defenders: def 0 presses carrier; def 1 & 2 shadow teammates!
	var def_defs := [
		Vector3(clampf(_ball_pos.x * 0.6, -10.0, 10.0), 0.0, maxf(-45.5, _ball_pos.z - 6.2)),
		Vector3(clampf(_teammate_positions[0].x - side * 1.6, -17.0, 17.0), 0.0, clampf(_teammate_positions[0].z - 3.2, -47.0, -26.0)),
		Vector3(clampf(_teammate_positions[1].x + side * 2.2, -16.0, 16.0), 0.0, clampf(_teammate_positions[1].z - 2.6, -47.0, -26.0)),
	]
	for i in range(def_defs.size()):
		if i < _defenders.size():
			_defenders[i].visible = true
			_defender_positions.append(def_defs[i])
			_defender_dirs.append(1.0 if i % 2 == 0 else -1.0)

func _apply_open_play_prompt(_t: MomentType) -> void:
	_moment_title_lbl.text = "PELUANG TERBUKA!"
	_moment_sub_lbl.text = "Gerakkan bebas pakai kursor kiri; berhenti & tarik ketapel untuk TEMBAK / UMPAN!"
	_ticker_lbl.text = "Bebas menggiring! Berhenti untuk tembak atau umpan."

func _configure_moment_camera() -> void:
	var persp := str(SettingsManager.data.get("perspective", "TV"))
	var dist_mult := lerpf(0.75, 1.35, float(SettingsManager.data.get("camera_dist", 0.85)))
	var angle_off := (float(SettingsManager.data.get("camera_angle", 0.5)) - 0.5) * 8.0

	if _moment_type == MomentType.TEAMMATE_PENALTY:
		_cam_target_pos = Vector3(0.0, 7.8, -22.0)
		_cam_look_pos = Vector3(0.0, 0.7, -42.5)
	elif persp == "LAPANGAN" or ((_moment_type == MomentType.PASS or _moment_type == MomentType.DRIBBLE) and persp != "BELAKANG"):
		# Tactical High-Angle Camera
		var tac_h: float = 14.5 if persp == "LAPANGAN" else 11.5
		var tac_b: float = 15.5 if persp == "LAPANGAN" else 13.5
		_cam_target_pos = _ball_pos + Vector3(angle_off, tac_h * dist_mult, tac_b * dist_mult)
		_cam_look_pos = Vector3(_ball_pos.x * 0.3, 0.6, -46.0)
	else:
		# Low-Angle Action Camera (BELAKANG = close 3rd-person shooter view; TV = broadcast diagonal)
		var height := 2.4 if persp == "BELAKANG" else 4.4
		var back := 5.6 if persp == "BELAKANG" else 9.2
		var side := (angle_off * 0.4) if persp == "BELAKANG" else (angle_off * 0.5 + 1.4)
		_cam_target_pos = _ball_pos + Vector3(side, height * dist_mult, back * dist_mult)
		_cam_look_pos = Vector3(_ball_pos.x * 0.25, 1.1, -52.5)

func _update_camera(delta: float) -> void:
	if _phase == MatchPhase.TEAMMATE_PENALTY_WAIT:
		_cam_target_pos = _cam_target_pos.lerp(Vector3(0.0, 7.8, -22.0), delta * 4.5)
		_cam_look_pos = _cam_look_pos.lerp(Vector3(0.0, 0.7, -42.5), delta * 5.0)
	elif _phase == MatchPhase.TEAMMATE_CARRY or _phase == MatchPhase.INCOMING_PASS:
		_cam_target_pos = _cam_target_pos.lerp(_ball_pos + Vector3(0.0, 6.2, 13.5), delta * 5.0)
		_cam_look_pos = _cam_look_pos.lerp(Vector3(_ball_pos.x * 0.45, 0.7, minf(_ball_pos.z - 6.0, -45.0)), delta * 5.5)
	elif _phase == MatchPhase.REBOUND_SCRAMBLE:
		_cam_target_pos = _cam_target_pos.lerp(_ball_pos + Vector3(0.0, 7.6, 15.0), delta * 4.5)
		_cam_look_pos = _cam_look_pos.lerp(Vector3(_ball_pos.x * 0.55, 0.6, minf(_ball_pos.z - 4.0, -43.0)), delta * 5.5)
	elif _phase == MatchPhase.BALL_IN_FLIGHT and _moment_type != MomentType.PASS:
		_cam_look_pos = _cam_look_pos.lerp(Vector3(_ball_pos.x * 0.6, maxf(0.8, _ball_pos.y), minf(_ball_pos.z, -44.0)), delta * 6.0)
		_cam_target_pos = _cam_target_pos.lerp(_ball_pos + Vector3(0.0, 4.2, 10.5), delta * 2.5)
	var shake_vec := Vector3.ZERO
	if _camera_shake > 0.01:
		var shake_scale := float(SettingsManager.data.get("camera_shake", 1.0))
		shake_vec = Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * _camera_shake * 0.25 * shake_scale
		_camera_shake = maxf(0.0, _camera_shake - delta * 3.5)
	_camera.global_position = _camera.global_position.lerp(_cam_target_pos + shake_vec, clampf(delta * 7.5, 0.0, 1.0))
	_camera.look_at(_cam_look_pos, Vector3.UP)

func _input(event: InputEvent) -> void:
	if _is_paused:
		return
	if run_mode == RunMode.MOVIOLA_REPLAY:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			_replay_orbit_dragging = event.pressed
		elif event is InputEventMouseMotion and _replay_orbit_dragging:
			_replay_orbit_angle += event.relative.x * 0.012
		return
	if _phase != MatchPhase.KEY_MOMENT_AIM:
		return
	if _is_user_dribbling_active():
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mb: InputEventMouseButton = event
		if _spin_pad.get_global_rect().has_point(mb.position):
			return
		if _dribble_pad != null and _dribble_pad.visible and _dribble_pad.get_global_rect().has_point(mb.position):
			return
		if _action_bar != null and _action_bar.visible and _action_bar.get_global_rect().has_point(mb.position):
			return
		if mb.pressed:
			if mb.position.y > 105:
				_dragging = true
				_drag_start = mb.position
				_drag_current = mb.position
		elif _dragging:
			_dragging = false
			_release_slingshot()
	elif event is InputEventMouseMotion and _dragging:
		_drag_current = event.position
		_draw_aim_and_ring()

func _release_slingshot() -> void:
	var delta_px := _drag_start - _drag_current
	if delta_px.length() < 14.0:
		_power_lbl.text = ""
		return
	_moment_banner.visible = false
	_aim_imm.clear_surfaces()
	_ring_imm.clear_surfaces()

	var kek := CareerState.get_effective_attribute("kekuatan") if CareerState.has_active_career else 68
	var ak := CareerState.get_effective_attribute("akurasi") if CareerState.has_active_career else 68
	var ef := CareerState.get_effective_attribute("efek") if CareerState.has_active_career else 68
	var pen := CareerState.get_effective_attribute("penalti") if CareerState.has_active_career else 68
	var bm := CareerState.get_effective_attribute("bolaMati") if CareerState.has_active_career else 68
	var diff_params: Dictionary = SettingsManager.get_difficulty_params()
	var diff_mult: float = float(diff_params.get("aim_spread_mult", 1.0))
	if CareerState.has_active_career and int(CareerState.career["playerProfile"]["energy"]) < 45 and str(SettingsManager.data.get("difficulty", "NORMAL")) == "EKSTREM":
		diff_mult *= 1.25

	var launch := SlingshotPhysics.compute_launch_params(
		delta_px, 210.0, kek, ak, ef, pen, bm, _spin_offset,
		_moment_type == MomentType.PENALTY,
		_moment_type == MomentType.FREE_KICK,
		diff_mult, true
	)
	_ball_vel = launch["velocity"]
	_ball_omega = launch["omega"]
	_flight_timer = 0.0
	# Snapshot FIFA Law 11 Offside positions at the exact instant the ball is kicked
	_kick_offside_line_z = _get_offside_line_z()
	_kick_offside_flags.clear()
	for ti in range(_teammate_positions.size()):
		var is_off: bool = (_moment_type != MomentType.PENALTY) and _is_teammate_offside(ti)
		_kick_offside_flags.append(is_off)
	_phase = MatchPhase.BALL_IN_FLIGHT
	_player_sprite.frame = 7  # back-view kick frame
	_camera_shake = 0.35 * float(launch["power_ratio"])
	AudioSynth.play_kick(float(launch["power_ratio"]))

	# Record start shot coordinates for telemetry
	_shots_telemetry.append({
		"type": _moment_type_str(),
		"outcome": "WIDE",
		"pitchCoord": {"x": clampf((_ball_pos.x + 34.0) / 68.0, 0.05, 0.95), "y": clampf((52.5 - _ball_pos.z) / 52.5, 0.05, 0.95)},
		"goalCoord": {"x": 0.5, "y": 0.5},
		"distanceMeters": snappedf(_ball_pos.distance_to(Vector3(0, 0, -52.5)), 0.1),
	})

func get_player_max_run_speed(spd_attr: int) -> float:
	# Realistic speed strictly driven by player's Kecepatan attribute (40..99 -> ~3.8..8.2 m/s)
	return lerpf(3.4, 8.2, clampf((float(spd_attr) - 35.0) / 64.0, 0.0, 1.0))

func _process_dribble_control(delta: float) -> void:
	if _skill_burst_timer > 0.0:
		_skill_burst_timer = maxf(0.0, _skill_burst_timer - delta)
	var kb := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)
	var joy: Vector2 = _dribble_input
	if kb.length() > 0.12:
		joy = kb.normalized()
	var is_moving := (joy.length() > 0.08 and not _dragging)
	var fisik_attr := CareerState.get_effective_attribute("fisik") if CareerState.has_active_career else 68
	var drain_mult: float = lerpf(1.22, 0.68, clampf(float(fisik_attr) / 99.0, 0.0, 1.0))

	if is_moving:
		var analog_mag := clampf(joy.length(), 0.0, 1.0)
		_dribble_facing = joy.normalized()
		var spd_attr := CareerState.get_effective_attribute("kecepatan") if CareerState.has_active_career else 60
		# Movement speed scales strictly with Kecepatan stat & analog deflection
		var max_run_spd: float = get_player_max_run_speed(spd_attr)
		var move_spd: float = max_run_spd * analog_mag
		if _skill_burst_timer > 0.0:
			move_spd *= 1.18
		if _match_stamina <= 0.1:
			move_spd *= 0.52
		elif _match_stamina < 18.0:
			move_spd *= 0.72
		# 40% shorter stamina duration (~28/s base * analog deflection * fisik mult); no in-event regen
		_match_stamina = maxf(0.0, _match_stamina - (28.0 * clampf(analog_mag, 0.30, 1.0)) * drain_mult * delta)
		# Unrestricted full-pitch movement while keeping ball cleanly in front of goal line (z >= -52.25)
		_player_pos.x = clampf(_player_pos.x + joy.x * move_spd * delta, -32.5, 32.5)
		_player_pos.z = clampf(_player_pos.z + joy.y * move_spd * delta, -51.4, 48.0)
		var tap_hop: float = absf(sin(_anim_clock * 14.0)) * 0.06
		_ball_pos = Vector3(clampf(_player_pos.x + _dribble_facing.x * 0.82, -33.2, 33.2), 0.115 + tap_hop, clampf(_player_pos.z + _dribble_facing.y * 0.82, -52.25, 48.8))
		_player_sprite.frame = 5 if fmod(_anim_clock, 0.28) < 0.14 else 6
		_configure_moment_camera()
	else:
		# Do NOT regenerate stamina when stopped; keep ball just inside goal line so slingshot shoots cleanly
		_player_sprite.frame = 4
		_ball_pos = Vector3(clampf(_player_pos.x + _dribble_facing.x * 0.78, -33.2, 33.2), 0.115, clampf(_player_pos.z + _dribble_facing.y * 0.78, -52.25, 48.8))
	_sync_stamina_hud()
	_sync_3d_sprites()

func _trigger_dribble_skill() -> void:
	if _phase != MatchPhase.KEY_MOMENT_AIM or (_moment_type != MomentType.SHOT and _moment_type != MomentType.PASS and _moment_type != MomentType.DRIBBLE):
		return
	AudioSynth.play_click()
	_skill_burst_timer = 0.45
	var burst_dir: Vector2 = _dribble_facing if _dribble_facing.length() > 0.1 else Vector2(0.0, -1.0)
	var lat_side: float = signf(_dribble_input.x) if absf(_dribble_input.x) > 0.1 else (1.0 if _player_pos.x < 0.0 else -1.0)
	_player_pos.x = clampf(_player_pos.x + lat_side * 1.45, -32.5, 32.5)
	_player_pos.z = clampf(_player_pos.z + burst_dir.y * 1.35, -51.4, 48.0)
	_ball_pos = Vector3(clampf(_player_pos.x + burst_dir.x * 0.85, -33.2, 33.2), 0.14, clampf(_player_pos.z + burst_dir.y * 0.85, -52.25, 48.8))
	_player_sprite.frame = 7
	_sync_3d_sprites()

func _process_ball_flight(delta: float) -> void:
	_flight_timer += delta
	var sub_steps := 3
	var dt := delta / float(sub_steps)
	var ef := CareerState.get_effective_attribute("efek") if CareerState.has_active_career else 68

	for _s in range(sub_steps):
		var step := SlingshotPhysics.step_ball(_ball_pos, _ball_vel, _ball_omega, ef, dt)
		_ball_pos = step["pos"]
		_ball_vel = step["vel"]
		_ball_omega = step["omega"]
		var hit: String = str(step["hit"])

		if hit == "post":
			AudioSynth.play_post()
			_camera_shake = 0.7
			_post_rebound_eligible = true
		elif hit == "goal":
			_handle_goal_scored()
			return

		# Defenders move slightly during flight so passes & deflections stay alive
		for i in range(_defender_positions.size()):
			var d_spd := float(SettingsManager.get_difficulty_params().get("defender_speed", 1.4))
			if d_spd > 0.0:
				var intercept_dir := Vector3(_ball_pos.x - _defender_positions[i].x, 0.0, _ball_pos.z - _defender_positions[i].z)
				if intercept_dir.length() > 0.4 and intercept_dir.length() < 9.0:
					_defender_positions[i] += intercept_dir.normalized() * minf(3.2, d_spd * 0.9) * dt

		# Trigger post rebound scramble cleanly inside attacking box
		if _post_rebound_eligible and _ball_vel.z > 1.2 and _ball_pos.z > -50.8 and _ball_pos.z < -26.0 and absf(_ball_pos.x) < 16.0:
			_post_rebound_eligible = false
			_enter_rebound_scramble("KENA TIANG! REBUT REBOUND!")
			return

		# Check Defender / Wall collision
		for i in range(_defender_positions.size()):
			var dpos := _defender_positions[i]
			if Vector2(_ball_pos.x - dpos.x, _ball_pos.z - dpos.z).length() < 0.82 and _ball_pos.y < 1.95:
				if i < _defenders.size():
					_defenders[i].frame = 3
				AudioSynth.play_save()
				if _moment_type == MomentType.PASS:
					_ball_vel = Vector3(-_ball_vel.x * 0.4, 2.2, 6.0)
					_update_last_shot("BLOCKED")
					_show_moment_result("UMPAN DIPOTONG LAWAN!", UITheme.ACCENT_RED, 1.3)
					return
				if _ball_pos.z < -27.0 and randf() < 0.45:
					_ball_vel = Vector3(signf(_ball_pos.x - dpos.x + 0.05) * randf_range(3.0, 5.5), randf_range(1.6, 3.0), randf_range(3.5, 6.5))
					_enter_rebound_scramble("BOLA MEMANTUL BEK! REBUT REBOUND!")
					return
				_ball_vel.z = absf(_ball_vel.z) * 0.45
				_ball_vel.x += randf_range(-2.5, 2.5)
				_update_last_shot("BLOCKED")
				_show_moment_result("DIBLOK BEK!", UITheme.ACCENT_RED, 1.3)
				return

		# Check Live Teammate reception (PASS, SHOT, DRIBBLE, and FREE_KICK passes — with FIFA Law 11 Offside check!)
		if not _shot_by_teammate and not _incoming_pass_kicked and (_moment_type in [MomentType.PASS, MomentType.SHOT, MomentType.DRIBBLE, MomentType.FREE_KICK]) and _flight_timer > 0.05 and not _teammate_positions.is_empty():
			var catch_rad: float = 2.25 if (_moment_type == MomentType.PASS or _moment_type == MomentType.FREE_KICK) else 1.85
			for ti in range(_teammate_positions.size()):
				var tm_pos := _teammate_positions[ti]
				if Vector2(_ball_pos.x - tm_pos.x, _ball_pos.z - tm_pos.z).length() < catch_rad and _ball_pos.y < 1.95:
					if ti < _kick_offside_flags.size() and _kick_offside_flags[ti]:
						AudioSynth.play_whistle(true)
						_update_last_shot("OFFSIDE")
						_ticker_lbl.text = "Bendera hakim garis terangkat! Rekan berada di posisi OFFSIDE saat umpan dilepas."
						_draw_offside_line_freeze(_kick_offside_line_z)
						_show_moment_result("OFFSIDE! BENDERA TERANGKAT", UITheme.ACCENT_RED, 1.5)
						return
					if ti < _teammates.size():
						_teammates[ti].frame = 7
					if _moment_type == MomentType.SHOT or _moment_type == MomentType.DRIBBLE:
						_moment_type = MomentType.PASS
					_passes_won += 1
					_start_teammate_carry(ti, true)
					return

		# Goalkeeper Dive AI
		if _moment_type != MomentType.PASS:
			_update_gk_ai(dt)
			if Vector2(_ball_pos.x - _gk_pos.x, _ball_pos.z - _gk_pos.z).length() < 0.98 and _ball_pos.y < 2.25:
				AudioSynth.play_save()
				var rebound_chance := 0.62 if (_shot_by_teammate or _moment_type == MomentType.PENALTY or _ball_vel.length() > 21.0) else 0.48
				if randf() < rebound_chance and _ball_pos.z < -42.0:
					var parry_dir := signf(_ball_pos.x - _gk_pos.x)
					if absf(parry_dir) < 0.1:
						parry_dir = 1.0 if randf() > 0.5 else -1.0
					_ball_pos.z = -49.8
					_ball_vel = Vector3(parry_dir * randf_range(3.0, 6.2), randf_range(1.8, 3.3), randf_range(5.2, 8.8))
					_enter_rebound_scramble("TEMBAKAN REKAN DITEPIS KIPER! BEREBUT REBOUND!" if _shot_by_teammate else "DITEPIS KIPER! BEREBUT REBOUND!")
					return
				_ball_vel.z = absf(_ball_vel.z) * 0.45
				_ball_vel.x += signf(_ball_pos.x - _gk_pos.x) * 3.0
				_ball_vel.y = maxf(_ball_vel.y, 2.2)
				_update_last_shot("ON_TARGET")
				_show_moment_result("TEMBAKAN REKAN DITEPIS KIPER!" if _shot_by_teammate else "DITEPIS KIPER!", UITheme.ACCENT_CYAN, 1.4)
				return

	# Record Moviola keyframes
	if _current_clip_frames.size() < 90:
		_current_clip_frames.append({
			"ball": [_ball_pos.x, _ball_pos.y, _ball_pos.z],
			"gk": [_gk_pos.x, _gk_pos.z],
			"player": [_player_pos.x, _player_pos.z],
		})

	# Update Trail & Teammates
	_trail_points.append(_ball_pos)
	if _trail_points.size() > 24:
		_trail_points.pop_front()
	_draw_ball_trail()
	_animate_teammates(delta)
	_sync_3d_sprites()

	# Check Out of Bounds or Stopped
	if _ball_pos.z < -56.0 or absf(_ball_pos.x) > 36.0 or _flight_timer > 3.2 or (_flight_timer > 0.6 and _ball_vel.length() < 1.2):
		if _moment_type == MomentType.PASS:
			_update_last_shot("WIDE")
			_show_moment_result("UMPAN TERLALU JAUH!", Color("#F97316"), 1.3)
			return
		if _moment_type == MomentType.PENALTY or _moment_type == MomentType.TEAMMATE_PENALTY:
			_save_moviola_clip("PENALTI GAGAL")
		_update_last_shot("WIDE")
		_show_moment_result("MELEBAR!", Color("#F97316"), 1.3)

func _update_gk_ai(dt: float) -> void:
	if _gk_react_timer > 0.0:
		_gk_react_timer -= dt
		return
	var diff_p := SettingsManager.get_difficulty_params()
	var gk_spd := float(diff_p["gk_speed"])
	# Predict where ball crosses z = -51.6
	if _ball_vel.z < -1.0:
		var t_to_goal := (-51.6 - _ball_pos.z) / _ball_vel.z
		if t_to_goal > 0.0 and t_to_goal < 1.8:
			_gk_target_x = clampf(_ball_pos.x + _ball_vel.x * t_to_goal * 0.72, -3.2, 3.2)
	var dx := _gk_target_x - _gk_pos.x
	_gk_pos.x += clampf(dx, -gk_spd * dt, gk_spd * dt)

func _is_user_dribbling_active() -> bool:
	if _phase != MatchPhase.KEY_MOMENT_AIM or not (_moment_type in [MomentType.SHOT, MomentType.PASS, MomentType.DRIBBLE]):
		return false
	if _dragging:
		return false
	if _dribble_input.length() > 0.08 or _skill_burst_timer > 0.0:
		return true
	var kb := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)
	return kb.length() > 0.12

func _get_offside_line_z() -> float:
	# FIFA Law 11 (attacking toward -Z, GK at -51.6 is last opponent):
	# Second-last opponent is deepest active outfield defender, capped by ball Z and halfway line (0.0).
	var deepest_def_z: float = 0.0
	var found_def := false
	for i in range(_defender_positions.size()):
		if i < _defenders.size() and not _defenders[i].visible:
			continue
		if absf(_defender_positions[i].x) > 33.5:
			continue
		if not found_def or _defender_positions[i].z < deepest_def_z:
			deepest_def_z = _defender_positions[i].z
			found_def = true
	if not found_def:
		return minf(0.0, _ball_pos.z)
	return minf(0.0, minf(_ball_pos.z, deepest_def_z))

func _is_teammate_offside(tm_idx: int) -> bool:
	if tm_idx < 0 or tm_idx >= _teammate_positions.size():
		return false
	if tm_idx < _teammates.size() and not _teammates[tm_idx].visible:
		return false
	if _moment_type == MomentType.PENALTY:
		return false
	var line_z: float = _get_offside_line_z()
	return _teammate_positions[tm_idx].z < (line_z - 0.35)

func _draw_offside_line_freeze(line_z: float) -> void:
	_ring_imm.clear_surfaces()
	_ring_imm.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var c := Color(0.98, 0.20, 0.25, 0.92)
	var x := -33.0
	while x < 33.0:
		var x1 := minf(33.0, x + 1.8)
		for vtx in [Vector3(x, 0.06, line_z - 0.14), Vector3(x1, 0.06, line_z - 0.14), Vector3(x1, 0.06, line_z + 0.14), Vector3(x, 0.06, line_z - 0.14), Vector3(x1, 0.06, line_z + 0.14), Vector3(x, 0.06, line_z + 0.14)]:
			_ring_imm.surface_set_color(c)
			_ring_imm.surface_add_vertex(vtx)
		x += 2.8
	_ring_imm.surface_end()

func _get_moment_time_scales() -> Dictionary:
	var diff_p: Dictionary = SettingsManager.get_difficulty_params()
	var base_def_spd: float = float(diff_p.get("defender_speed", 1.6))
	var drib_def_spd: float = float(diff_p.get("dribble_defender_speed", 2.2))
	var aim_tm_scale: float = float(diff_p.get("aim_teammate_scale", 0.22))
	var aim_def_scale: float = float(diff_p.get("aim_defender_scale", 0.34))

	if _phase != MatchPhase.KEY_MOMENT_AIM:
		return {"teammate": 1.0, "defender_speed": base_def_spd, "active_dribble": false}
	if _moment_type == MomentType.FREE_KICK:
		# Teammates stand stationary in optimal positions during free kick aiming
		return {"teammate": 0.0, "defender_speed": 0.0, "active_dribble": false}
	if _moment_type in [MomentType.SHOT, MomentType.PASS, MomentType.DRIBBLE]:
		if _is_user_dribbling_active():
			# User actively moving player: teammates & defenders move at normal mode speed
			return {"teammate": 1.0, "defender_speed": drib_def_spd, "active_dribble": true}
		# User hasn't moved yet OR is pulling back to shoot/pass: teammates & opponents move slowly (0.0 on MUDAH)
		var drag_slow: float = 0.72 if _dragging else 1.0
		return {"teammate": aim_tm_scale * drag_slow, "defender_speed": base_def_spd * aim_def_scale * drag_slow, "active_dribble": false}
	return {"teammate": aim_tm_scale, "defender_speed": base_def_spd * aim_def_scale, "active_dribble": false}

func _animate_gk_idle(delta: float) -> void:
	var diff_p: Dictionary = SettingsManager.get_difficulty_params()
	var scales := _get_moment_time_scales()
	var eff_def_speed: float = float(scales["defender_speed"])
	var tm_scale: float = float(scales["teammate"])
	var drib_def_spd: float = maxf(1.0, float(diff_p.get("dribble_defender_speed", 2.2)))
	var gk_time_scale: float = maxf(tm_scale, eff_def_speed / drib_def_spd)
	if _moment_type == MomentType.FREE_KICK or _moment_type == MomentType.PENALTY:
		gk_time_scale = 0.45 if str(SettingsManager.data.get("difficulty", "NORMAL")) != "MUDAH" else 0.0
	if gk_time_scale > 0.01:
		_gk_sway_clock += delta * gk_time_scale
		_gk_pos.x = sin(_gk_sway_clock * 3.0) * 0.85
	var can_steal: bool = bool(diff_p.get("can_steal", false))
	var steal_dist: float = float(diff_p.get("steal_dist", 1.05))
	var stride_front: int = 1 if fmod(_anim_clock * maxf(0.22, tm_scale), 0.34) < 0.17 else 2

	if _moment_type in [MomentType.SHOT, MomentType.PASS, MomentType.DRIBBLE]:
		# Identify nearest active defender on pitch to press ball carrier across all open play
		var chaser_idx: int = -1
		var best_dist: float = 999.0
		for j in range(_defender_positions.size()):
			if j < _defenders.size() and not _defenders[j].visible:
				continue
			if absf(_defender_positions[j].x) > 30.0:
				continue
			var dj: float = Vector2(_ball_pos.x - _defender_positions[j].x, _ball_pos.z - _defender_positions[j].z).length()
			if dj < best_dist:
				best_dist = dj
				chaser_idx = j

		for i in range(_defender_positions.size()):
			if i == chaser_idx:
				# Pressing defender moves toward ball carrier to tackle/steal (speed scaled by mode & slow-mo)
				var to_ball: Vector3 = Vector3(_ball_pos.x - _defender_positions[i].x, 0.0, _ball_pos.z - _defender_positions[i].z)
				var dist: float = to_ball.length()
				if eff_def_speed > 0.01 and dist > 0.01:
					_defender_positions[i] += to_ball.normalized() * eff_def_speed * delta
					if i < _defenders.size():
						_defenders[i].frame = stride_front
				elif i < _defenders.size():
					_defenders[i].frame = 0
				if can_steal and run_mode != RunMode.MOVIOLA_REPLAY and _phase == MatchPhase.KEY_MOMENT_AIM and eff_def_speed > 0.01 and dist < steal_dist:
					if i < _defenders.size():
						_defenders[i].frame = 3
					_dragging = false
					_aim_imm.clear_surfaces()
					_ring_imm.clear_surfaces()
					_moment_banner.visible = false
					_shots_telemetry.append({
						"type": _moment_type_str(),
						"outcome": "BLOCKED",
						"pitchCoord": {"x": clampf((_ball_pos.x + 34.0) / 68.0, 0.05, 0.95), "y": clampf((52.5 - _ball_pos.z) / 52.5, 0.05, 0.95)},
						"goalCoord": {"x": 0.5, "y": 0.5},
						"distanceMeters": snappedf(_ball_pos.distance_to(Vector3(0, 0, -52.5)), 0.1),
					})
					AudioSynth.play_save()
					_show_moment_result("DIREBUT BEK!", UITheme.ACCENT_RED, 1.2)
					return
			else:
				# Secondary defenders shadow attacking teammates & support pressure at mode-scaled speed
				var tm_idx: int = maxi(0, i - 1) if chaser_idx == 0 else (i if i < chaser_idx else i - 1)
				if eff_def_speed > 0.01 and tm_idx < _teammate_positions.size():
					var tm_target: Vector3 = _teammate_positions[tm_idx] + Vector3(0.0, 0.0, -2.0)
					var to_tm: Vector3 = Vector3(tm_target.x - _defender_positions[i].x, 0.0, tm_target.z - _defender_positions[i].z)
					if to_tm.length() > 0.65:
						_defender_positions[i] += to_tm.normalized() * eff_def_speed * 0.92 * delta
						if i < _defenders.size():
							_defenders[i].frame = stride_front
					elif i < _defenders.size():
						_defenders[i].frame = 0
				elif i < _defenders.size():
					_defenders[i].frame = 0
	_sync_3d_sprites()

func _animate_teammates(delta: float) -> void:
	# During Free Kick aiming, teammates stay completely stationary in their optimal set-piece positions
	if _phase == MatchPhase.KEY_MOMENT_AIM and _moment_type == MomentType.FREE_KICK:
		for i in range(_teammates.size()):
			if _teammates[i].visible:
				_teammates[i].frame = 4
		_sync_3d_sprites()
		return
	var scales := _get_moment_time_scales()
	var tm_scale: float = float(scales["teammate"])
	var stride_back: int = 5 if fmod(_anim_clock * maxf(0.22, tm_scale), 0.32) < 0.16 else 6
	for i in range(_teammate_positions.size()):
		if i < _teammate_targets.size() and _phase == MatchPhase.KEY_MOMENT_AIM and _moment_type in [MomentType.SHOT, MomentType.PASS, MomentType.DRIBBLE]:
			# Enforce strictly forward (-Z) target progression; never retreat (+Z)
			if _teammate_targets[i].z > _teammate_positions[i].z:
				_teammate_targets[i].z = maxf(-48.5, _teammate_positions[i].z - 3.5)
			var tgt: Vector3 = _teammate_targets[i]
			var to_t: Vector3 = Vector3(tgt.x - _teammate_positions[i].x, 0.0, minf(0.0, tgt.z - _teammate_positions[i].z))
			if to_t.length() < 1.2:
				var next_x: float = clampf(-tgt.x * 0.7 + randf_range(-4.0, 4.0), -17.0, 17.0)
				var next_z: float = maxf(-48.5, _teammate_positions[i].z - randf_range(3.5, 7.0))
				_teammate_targets[i] = Vector3(next_x, 0.0, next_z)
			else:
				var spd := 3.6 if i == 0 else (3.1 if i == 1 else 2.5)
				_teammate_vels[i] = to_t.normalized() * spd
		_teammate_vels[i].z = minf(_teammate_vels[i].z, 0.0)
		_teammate_positions[i] += _teammate_vels[i] * tm_scale * delta
		_teammate_positions[i].x = clampf(_teammate_positions[i].x, -22.0, 22.0)
		_teammate_positions[i].z = clampf(_teammate_positions[i].z, -48.5, -12.0)
		if i < _teammates.size():
			_teammates[i].frame = stride_back if (_teammate_vels[i].length() * tm_scale) > 0.25 else 4
	_sync_3d_sprites()

func _update_pass_openness_ui() -> void:
	_teammate_open_scores.resize(_teammate_positions.size())
	var best := 0.0
	for i in range(_teammate_positions.size()):
		var min_d := 12.0
		for dpos in _defender_positions:
			var dist := Vector2(_teammate_positions[i].x - dpos.x, _teammate_positions[i].z - dpos.z).length()
			min_d = minf(min_d, dist)
		_teammate_open_scores[i] = min_d
		best = maxf(best, min_d)
	_best_pass_openness = best
	if _action_mode_btns.has("MAIN") and _action_bar != null and _action_bar.visible:
		var mb: Button = _action_mode_btns["MAIN"]
		var state_key: String = ("BEBAS" if best >= 3.2 else ("GERAK" if best >= 1.95 else "DIJAGA"))
		if state_key == _last_pass_state:
			return
		_last_pass_state = state_key
		if best >= 3.2:
			mb.text = "TEMBAK / UMPAN !"
			UITheme.style_btn(mb, Color("#174A7A"), UITheme.ACCENT_GREEN, 11)
		elif best >= 1.95:
			mb.text = "TEMBAK / UMPAN +"
			UITheme.style_btn(mb, Color("#174A7A"), UITheme.ACCENT_GOLD, 11)
		else:
			mb.text = "TEMBAK / UMPAN"
			UITheme.style_btn(mb, Color("#122B4A"), UITheme.BORDER_CYAN, 11)

func _evaluate_teammate_shot_or_layoff(tm_idx: int, from_rebound: bool) -> void:
	if tm_idx < 0 or tm_idx >= _teammate_positions.size():
		return
	var tm_pos: Vector3 = _teammate_positions[tm_idx]
	if from_rebound and tm_pos.z > -41.5 and _player_pos.distance_to(tm_pos) < 12.0:
		_launch_pass_to_user(tm_idx, "UMPAN REBOUND REKAN!", "Rekan menyodorkan bola rebound — bersiap TEMBAK!")
		return
	_start_teammate_carry(tm_idx, not from_rebound)

func _start_teammate_carry(tm_idx: int, is_assist: bool) -> void:
	if tm_idx < 0 or tm_idx >= _teammate_positions.size():
		return
	_phase = MatchPhase.TEAMMATE_CARRY
	_carry_tm_idx = tm_idx
	_carry_timer = 0.0
	_carry_shrug_cd = 0.0
	_shot_by_teammate = true
	_carry_assist_pending = is_assist
	_post_rebound_eligible = false
	_dragging = false
	_ball_vel = Vector3.ZERO
	_ball_omega = Vector3.ZERO
	_aim_imm.clear_surfaces()
	_ring_imm.clear_surfaces()
	_spin_pad.visible = false
	_power_lbl.visible = false
	if _action_bar != null:
		_action_bar.visible = false
	if _dribble_pad != null:
		_dribble_pad.visible = false
	if _stamina_bar_bg != null:
		_stamina_bar_bg.visible = false
	if _player_badge_lbl != null:
		_player_badge_lbl.visible = false

	var tm_pos: Vector3 = _teammate_positions[tm_idx]
	# Never pass back to user after user passed to teammate — teammate always pushes forward to finish
	_carry_pass_back = false
	_carry_shoot_at = 0.45 if (not is_assist and tm_pos.z < -41.5) else randf_range(0.78, 1.28)
	_moment_banner.visible = true
	_moment_title_lbl.text = "REKAN BAWA BOLA!"
	_moment_sub_lbl.text = "Rekan menerima umpanmu dan menggiring maju ke kotak penalti!"
	_ticker_lbl.text = "Rekan menggiring bola — bek lawan mulai menutup ruang!"
	AudioSynth.play_click()

func _process_teammate_carry(delta: float) -> void:
	if _carry_tm_idx < 0 or _carry_tm_idx >= _teammate_positions.size():
		_show_moment_result("BOLA TERBUANG!", Color("#F97316"), 1.0)
		return
	_carry_timer += delta
	_carry_shrug_cd = maxf(0.0, _carry_shrug_cd - delta)
	var stride_back: int = 5 if fmod(_anim_clock, 0.26) < 0.13 else 6
	var stride_front: int = 1 if fmod(_anim_clock, 0.28) < 0.14 else 2

	var carrier: Vector3 = _teammate_positions[_carry_tm_idx]
	var lane_tgt := Vector3(clampf(carrier.x * 0.48, -6.5, 6.5), 0.0, -47.2)
	var dir_to_box := Vector3(lane_tgt.x - carrier.x, 0.0, minf(-0.35, lane_tgt.z - carrier.z)).normalized()
	var carry_spd := 5.6
	carrier += dir_to_box * carry_spd * delta
	carrier.x = clampf(carrier.x, -21.0, 21.0)
	carrier.z = clampf(carrier.z, -48.5, -14.0)
	_teammate_positions[_carry_tm_idx] = carrier
	if _carry_tm_idx < _teammates.size():
		_teammates[_carry_tm_idx].frame = stride_back
	var hop := absf(sin(_anim_clock * 15.0)) * 0.055
	_ball_pos = Vector3(carrier.x + dir_to_box.x * 0.78, 0.115 + hop, carrier.z + dir_to_box.z * 0.78)

	# Other teammates & user player sprint forward to support / look for pass or rebound
	for ti in range(_teammate_positions.size()):
		if ti == _carry_tm_idx:
			continue
		var tp: Vector3 = _teammate_positions[ti]
		var supp_z: float = maxf(-48.2, tp.z - 4.0 * delta)
		_teammate_positions[ti] = Vector3(tp.x, 0.0, supp_z)
		if ti < _teammates.size():
			_teammates[ti].frame = stride_back
	var user_lane_x: float = clampf(-carrier.x * 0.65, -7.5, 7.5)
	var u_dir := Vector3(user_lane_x - _player_pos.x, 0.0, minf(-0.4, -42.5 - _player_pos.z)).normalized()
	_player_pos.x = clampf(_player_pos.x + u_dir.x * 4.4 * delta, -16.0, 16.0)
	_player_pos.z = clampf(_player_pos.z + u_dir.z * 4.4 * delta, -46.5, -16.0)
	_player_sprite.frame = stride_back

	# Opposing defenders actively chase the carrying teammate to stop/tackle them!
	var diff_p: Dictionary = SettingsManager.get_difficulty_params()
	var def_base: float = float(diff_p.get("dribble_defender_speed", 2.2))
	var chase_spd: float = clampf(def_base * 1.18 + 1.25, 1.8, 5.2)
	var steal_prob: float = clampf(0.32 + chase_spd * 0.11, 0.35, 0.88)
	if str(SettingsManager.data.get("difficulty", "NORMAL")) == "MUDAH":
		steal_prob = 0.22
	var hit_def := false
	for i in range(_defender_positions.size()):
		var dp: Vector3 = _defender_positions[i]
		if i < _defenders.size() and not _defenders[i].visible:
			continue
		var to_car := Vector3(carrier.x - dp.x, 0.0, carrier.z - dp.z)
		var dist := to_car.length()
		if dist > 0.1:
			_defender_positions[i] += to_car.normalized() * chase_spd * delta
		if i < _defenders.size():
			_defenders[i].frame = stride_front
		if dist < 1.02 and _carry_timer > 0.24 and _carry_shrug_cd <= 0.0:
			if randf() < steal_prob:
				hit_def = true
				if i < _defenders.size():
					_defenders[i].frame = 3
				break
			else:
				_carry_shrug_cd = 0.45

	_gk_pos.x = move_toward(_gk_pos.x, clampf(carrier.x * 0.35, -2.5, 2.5), 3.0 * delta)
	_trail_points.clear()
	_trail_imm.clear_surfaces()
	_sync_3d_sprites()

	if hit_def:
		AudioSynth.play_save()
		_shot_by_teammate = false
		_carry_assist_pending = false
		_update_last_shot("BLOCKED")
		_add_board_event(int(_minute), "INFO", "%d' Rekan yang membawa bola dihentikan bek lawan!" % int(_minute), false)
		_show_moment_result("REKAN DIHENTIKAN BEK!", UITheme.ACCENT_RED, 1.35)
		return

	# Opportunity: carrying teammate passes back to our rushing striker (one-two)!
	if _carry_pass_back and _carry_timer >= 0.72 and _player_pos.z > -47.0 and _player_pos.distance_to(carrier) > 3.2:
		_launch_pass_to_user(_carry_tm_idx, "UMPAN BALIK REKAN!", "Rekan mengumpan balik ke kakimu — bersiap TEMBAK!")
		return

	# Shoot toward goal in real 3D!
	if _carry_timer >= _carry_shoot_at or carrier.z <= -43.8:
		if _carry_tm_idx < _teammates.size():
			_teammates[_carry_tm_idx].frame = 7
		var corner := -1.0 if randf() < 0.5 else 1.0
		var aim_x := corner * randf_range(0.75, 3.35)
		var aim_pt := Vector3(aim_x, randf_range(0.55, 1.95), -52.6)
		var spd := randf_range(22.5, 29.0)
		_ball_vel = (aim_pt - _ball_pos).normalized() * spd + Vector3(0.0, 1.15, 0.0)
		_ball_omega = Vector3(0.0, corner * randf_range(-2.2, 2.2), 0.0)
		_flight_timer = 0.0
		_post_rebound_eligible = true
		_phase = MatchPhase.BALL_IN_FLIGHT
		_moment_type = MomentType.SHOT
		_shot_by_teammate = true
		_moment_banner.visible = false
		AudioSynth.play_kick(0.88)

func _setup_teammate_pass_to_user() -> void:
	_phase = MatchPhase.INCOMING_PASS
	_incoming_pass_tm_idx = 0
	_incoming_pass_timer = 0.0
	_incoming_pass_kicked = false
	_shot_by_teammate = false
	_carry_assist_pending = false
	_spin_pad.visible = false
	_power_lbl.visible = false

	var side := -1.0 if randf() < 0.5 else 1.0
	var user_x := clampf(-side * randf_range(2.0, 6.5), -10.0, 10.0)
	var user_z := randf_range(-33.5, -27.5)
	_player_pos = Vector3(user_x, 0.0, user_z)

	# Teammate 0 carries ball on opposite wing ready to pass into user's stride!
	var passer_pos := Vector3(clampf(user_x + side * 9.5, -18.0, 18.0), 0.0, user_z + 4.2)
	_teammates[0].visible = true
	_teammate_positions.append(passer_pos)
	_teammate_vels.append(Vector3(-side * 1.4, 0.0, -3.6))
	_teammate_targets.append(Vector3(clampf(passer_pos.x - side * 3.0, -16.0, 16.0), 0.0, -45.5))
	_teammate_open_scores.append(2.8)
	for i in range(1, 3):
		_teammates[i].visible = true
		_teammate_positions.append(Vector3(clampf(-user_x + float(i) * side * 3.0, -16.0, 16.0), 0.0, user_z - 2.0))
		_teammate_vels.append(Vector3(0.0, 0.0, -2.8))
		_teammate_targets.append(Vector3(-user_x * 0.4, 0.0, -47.0))
		_teammate_open_scores.append(2.4)

	var def_spots := [
		Vector3(clampf(user_x + side * 1.8, -14.0, 14.0), 0.0, user_z - 6.8),
		Vector3(passer_pos.x - side * 2.2, 0.0, passer_pos.z - 4.0),
		Vector3(clampf(-user_x, -14.0, 14.0), 0.0, user_z - 9.0),
	]
	for i in range(def_spots.size()):
		if i < _defenders.size():
			_defenders[i].visible = true
			_defender_positions.append(def_spots[i])
			_defender_dirs.append(1.0)

	_ball_pos = Vector3(passer_pos.x - side * 0.7, 0.115, passer_pos.z - 0.6)
	_moment_title_lbl.text = "PELUANG UMPAN REKAN!"
	_moment_sub_lbl.text = "Rekan melihat larimu — bersiap menyambut umpan terobosan!"
	_ticker_lbl.text = "Rekan membawa bola di sisi lapangan & mencari celah umpan kepadamu."
	_moment_banner.visible = true
	_sync_action_bar()
	_configure_moment_camera()
	_sync_3d_sprites()
	AudioSynth.play_whistle(false)

func _launch_pass_to_user(tm_idx: int, title_txt: String, sub_txt: String) -> void:
	_phase = MatchPhase.INCOMING_PASS
	_incoming_pass_tm_idx = tm_idx
	_incoming_pass_timer = 0.0
	_incoming_pass_kicked = true
	_shot_by_teammate = false
	_carry_assist_pending = false
	if tm_idx >= 0 and tm_idx < _teammates.size():
		_teammates[tm_idx].frame = 7
	_moment_title_lbl.text = title_txt
	_moment_sub_lbl.text = sub_txt
	_moment_banner.visible = true
	_sync_action_bar()
	AudioSynth.play_kick(0.6)

func _process_incoming_pass(delta: float) -> void:
	_incoming_pass_timer += delta
	var stride_back: int = 5 if fmod(_anim_clock, 0.28) < 0.14 else 6
	var stride_front: int = 1 if fmod(_anim_clock, 0.30) < 0.15 else 2

	# User runs forward into pocket; passer advances until kick, then ball zips to user's feet
	_player_pos.z = clampf(_player_pos.z - 3.6 * delta, -44.5, -18.0)
	_player_sprite.frame = stride_back
	_gk_pos.x = sin(_anim_clock * 3.2) * 0.7

	if not _incoming_pass_kicked:
		if _incoming_pass_tm_idx >= 0 and _incoming_pass_tm_idx < _teammate_positions.size():
			var ppos: Vector3 = _teammate_positions[_incoming_pass_tm_idx]
			var to_u := Vector3(_player_pos.x - ppos.x, 0.0, _player_pos.z - ppos.z).normalized()
			ppos += Vector3(to_u.x * 2.2, 0.0, -3.2) * delta
			_teammate_positions[_incoming_pass_tm_idx] = ppos
			if _incoming_pass_tm_idx < _teammates.size():
				_teammates[_incoming_pass_tm_idx].frame = stride_back
			var hop := absf(sin(_anim_clock * 14.0)) * 0.05
			_ball_pos = Vector3(ppos.x + to_u.x * 0.72, 0.115 + hop, ppos.z + to_u.z * 0.72)
		if _incoming_pass_timer >= 0.55:
			_incoming_pass_kicked = true
			if _incoming_pass_tm_idx >= 0 and _incoming_pass_tm_idx < _teammates.size():
				_teammates[_incoming_pass_tm_idx].frame = 7
			AudioSynth.play_kick(0.62)
	else:
		var target_pt := _player_pos + Vector3(0.0, 0.12, -0.85)
		var to_target := target_pt - _ball_pos
		var dist := Vector2(to_target.x, to_target.z).length()
		var pass_spd := 14.5
		if dist > 0.05:
			var step_xz := Vector3(to_target.x, 0.0, to_target.z).normalized() * minf(dist, pass_spd * delta)
			_ball_pos.x += step_xz.x
			_ball_pos.z += step_xz.z
			_ball_pos.y = 0.12 + clampf(dist * 0.06, 0.0, 0.45) * sin(clampf(_incoming_pass_timer * 4.0, 0.0, PI))
		if dist < 1.15 or _incoming_pass_timer >= 2.1:
			_enter_user_follow_up_shot("UMPAN REKAN DITERIMA!", "Tarik ketapel TEMBAK, kirim UMPAN lagi, atau pakai DRIBEL!")
			return

	for i in range(_defender_positions.size()):
		var tgt_d := Vector3(_player_pos.x + (float(i) - 1.0) * 2.6, 0.0, maxf(-45.5, _player_pos.z - 5.5))
		var to_d := Vector3(tgt_d.x - _defender_positions[i].x, 0.0, tgt_d.z - _defender_positions[i].z)
		if to_d.length() > 0.3:
			_defender_positions[i] += to_d.normalized() * 2.2 * delta
			if i < _defenders.size():
				_defenders[i].frame = stride_front
	_sync_3d_sprites()

func _enter_user_follow_up_shot(title_msg: String, sub_msg: String) -> void:
	_phase = MatchPhase.KEY_MOMENT_AIM
	_moment_type = MomentType.SHOT
	_shot_by_teammate = false
	_carry_assist_pending = false
	_incoming_pass_kicked = false
	_post_rebound_eligible = false
	_dragging = false
	_dribble_input = Vector2.ZERO
	_spin_offset = Vector2.ZERO
	_spin_pad.reset_spin()
	_spin_pad.visible = (run_mode != RunMode.MOVIOLA_REPLAY)
	_power_lbl.visible = true
	_power_lbl.text = ""
	_ball_vel = Vector3.ZERO
	_ball_omega = Vector3.ZERO
	_player_sprite.frame = 4
	_ball_pos = _player_pos + Vector3(0.0, 0.115, -0.95)
	_moment_title_lbl.text = title_msg
	_moment_sub_lbl.text = sub_msg
	_ticker_lbl.text = "Umpan rekan matang! Giring bebas atau langsung tembak/umpan!"
	_moment_banner.visible = true
	_update_pass_openness_ui()
	_sync_action_bar()
	_configure_moment_camera()
	_sync_3d_sprites()
	_draw_aim_and_ring()
	AudioSynth.play_click()

func _enter_rebound_scramble(banner_msg: String) -> void:
	_phase = MatchPhase.REBOUND_SCRAMBLE
	_rebound_timer = 0.0
	_rebound_grace = 0.24
	_dragging = false
	_spin_pad.visible = false
	_power_lbl.visible = false
	if _action_bar != null:
		_action_bar.visible = false
	if _dribble_pad != null:
		_dribble_pad.visible = false
	if _stamina_bar_bg != null:
		_stamina_bar_bg.visible = false
	_moment_banner.visible = true
	_moment_title_lbl.text = "BOLA REBOUND!"
	_moment_sub_lbl.text = banner_msg
	_ticker_lbl.text = banner_msg
	_aim_imm.clear_surfaces()
	_ring_imm.clear_surfaces()

	# Ensure box battle feels populated with at least 2 teammates and 2-3 chasing defenders
	while _teammate_positions.size() < 2 and _teammate_positions.size() < _teammates.size():
		var tidx := _teammate_positions.size()
		var sx := -5.2 if tidx == 0 else 5.2
		_teammates[tidx].visible = true
		_teammate_positions.append(Vector3(sx, 0.0, -37.5))
		_teammate_vels.append(Vector3.ZERO)
		_teammate_targets.append(Vector3(sx, 0.0, -45.0))
		_teammate_open_scores.append(2.5)
	while _defender_positions.size() < 2 and _defender_positions.size() < _defenders.size():
		var didx := _defender_positions.size()
		_defenders[didx].visible = true
		_defender_positions.append(Vector3(-4.5 if didx == 0 else 4.5, 0.0, -41.5))
		_defender_dirs.append(1.0)

func _process_rebound_scramble(delta: float) -> void:
	_rebound_timer += delta
	_rebound_grace = maxf(0.0, _rebound_grace - delta)
	var sub := 2
	var dt := delta / float(sub)
	for _s in range(sub):
		var step := SlingshotPhysics.step_ball(_ball_pos, _ball_vel, Vector3.ZERO, 45, dt)
		_ball_pos = step["pos"]
		_ball_vel = step["vel"]
		if str(step["hit"]) == "goal":
			_handle_goal_scored()
			return
	_ball_vel.x *= maxf(0.0, 1.0 - 0.65 * delta)
	_ball_vel.z *= maxf(0.0, 1.0 - 0.65 * delta)

	var stride_back: int = 5 if fmod(_anim_clock, 0.28) < 0.14 else 6
	var stride_front: int = 1 if fmod(_anim_clock, 0.28) < 0.14 else 2

	# 1. User sprints toward rebound ball
	var spd_attr := CareerState.get_effective_attribute("kecepatan") if CareerState.has_active_career else 68
	var user_spd := lerpf(5.8, 8.4, float(spd_attr) / 100.0)
	var u_dir := Vector3(_ball_pos.x - _player_pos.x, 0.0, _ball_pos.z - _player_pos.z)
	if u_dir.length() > 0.1:
		_player_pos += u_dir.normalized() * user_spd * delta
	_player_sprite.frame = stride_back

	# 2. Living teammates sprint toward rebound ball (closest chases fast, second supports box)
	for i in range(_teammate_positions.size()):
		var t_tgt := _ball_pos if i < 2 else Vector3(-_ball_pos.x * 0.4, 0.0, maxf(-44.0, _ball_pos.z - 2.0))
		var t_dir := Vector3(t_tgt.x - _teammate_positions[i].x, 0.0, t_tgt.z - _teammate_positions[i].z)
		if t_dir.length() > 0.15:
			_teammate_positions[i] += t_dir.normalized() * (6.9 if i == 0 else 5.8) * delta
			if i < _teammates.size():
				_teammates[i].frame = stride_back

	# 3. Opponent defenders chase loose ball based on difficulty
	var diff_p := SettingsManager.get_difficulty_params()
	var def_chase_spd := clampf(float(diff_p.get("defender_speed", 1.4)) * 1.15 + 3.4, 3.6, 7.6)
	for i in range(_defender_positions.size()):
		var d_dir := Vector3(_ball_pos.x - _defender_positions[i].x, 0.0, _ball_pos.z - _defender_positions[i].z)
		if d_dir.length() > 0.15:
			var sp_mult := 1.0 if i < 2 else 0.72
			_defender_positions[i] += d_dir.normalized() * def_chase_spd * sp_mult * delta
			if i < _defenders.size():
				_defenders[i].frame = stride_front

	# 4. Opponent GK rushes out for loose rebounds in inner box
	if _ball_pos.z < -39.5 and absf(_ball_pos.x) < 9.5:
		var gk_rush := clampf(float(diff_p.get("gk_speed", 6.2)) * 0.68, 3.4, 6.2)
		var g_dir := Vector3(_ball_pos.x - _gk_pos.x, 0.0, _ball_pos.z - _gk_pos.z)
		if g_dir.length() > 0.15:
			_gk_pos += g_dir.normalized() * gk_rush * delta
		_gk_sprite.frame = stride_front

	_trail_points.append(_ball_pos)
	if _trail_points.size() > 20:
		_trail_points.pop_front()
	_draw_ball_trail()
	_sync_3d_sprites()

	# Check physical race winner after grace delay
	if _rebound_grace <= 0.0 and _ball_pos.y < 1.85:
		if Vector2(_gk_pos.x - _ball_pos.x, _gk_pos.z - _ball_pos.z).length() < 1.18:
			_gk_sprite.frame = 3
			AudioSynth.play_save()
			_show_moment_result("REBOUND DIAMANKAN KIPER!", UITheme.ACCENT_CYAN, 1.35)
			return
		for i in range(_defender_positions.size()):
			if Vector2(_defender_positions[i].x - _ball_pos.x, _defender_positions[i].z - _ball_pos.z).length() < 1.08:
				if i < _defenders.size():
					_defenders[i].frame = 3
				AudioSynth.play_save()
				_show_moment_result("REBOUND DISAPU BEK LAWAN!", UITheme.ACCENT_RED, 1.35)
				return
		if Vector2(_player_pos.x - _ball_pos.x, _player_pos.z - _ball_pos.z).length() < 1.25 and _ball_pos.z < -24.0:
			_enter_user_follow_up_shot("REBOUND DIDAPAT! TEMBAK!", "Bola muntah di kakimu — segera tarik ketapel!")
			return
		for i in range(_teammate_positions.size()):
			if Vector2(_teammate_positions[i].x - _ball_pos.x, _teammate_positions[i].z - _ball_pos.z).length() < 1.25:
				if i < _teammates.size():
					_teammates[i].frame = 7
				_evaluate_teammate_shot_or_layoff(i, true)
				return

	if _rebound_timer > 3.2 or _ball_pos.z < -56.0 or _ball_pos.z > -16.0 or absf(_ball_pos.x) > 36.0:
		_show_moment_result("BOLA REBOUND KELUAR!", Color("#F97316"), 1.25)

func _setup_teammate_penalty() -> void:
	_phase = MatchPhase.TEAMMATE_PENALTY_WAIT
	_tm_penalty_timer = 0.0
	_tm_penalty_kicked = false
	_shot_by_teammate = true
	_post_rebound_eligible = true
	_ball_pos = Vector3(0.0, 0.115, -41.5)
	_ball_vel = Vector3.ZERO
	_ball_omega = Vector3.ZERO

	# Teammate 0 takes penalty; User + Teammate 1 + Defenders crouch alert on the 16m line for rebounds!
	_teammates[0].visible = true
	_teammate_positions.append(Vector3(0.0, 0.0, -38.6))
	_teammate_vels.append(Vector3(0.0, 0.0, -2.8))
	_teammate_targets.append(Vector3(0.0, 0.0, -41.2))
	_teammate_open_scores.append(2.0)

	_teammates[1].visible = true
	_teammate_positions.append(Vector3(5.2, 0.0, -35.8))
	_teammate_vels.append(Vector3.ZERO)
	_teammate_targets.append(Vector3(4.0, 0.0, -45.0))
	_teammate_open_scores.append(2.5)

	_player_pos = Vector3(-4.0, 0.0, -35.8)

	var d_spots := [Vector3(-6.2, 0.0, -36.0), Vector3(3.2, 0.0, -35.9), Vector3(7.4, 0.0, -36.4)]
	for i in range(d_spots.size()):
		if i < _defenders.size():
			_defenders[i].visible = true
			_defender_positions.append(d_spots[i])
			_defender_dirs.append(1.0)

	_moment_title_lbl.text = "PENALTI REKAN SETIM!"
	_moment_sub_lbl.text = "Bersiap di garis kotak 16m — antisipasi bola rebound!"
	_ticker_lbl.text = "Rekan maju ke titik putih. Bersiap jika kiper menepis!"
	_moment_banner.visible = true
	_sync_action_bar()
	_configure_moment_camera()
	_sync_3d_sprites()
	AudioSynth.play_whistle(false)

func _process_teammate_penalty_wait(delta: float) -> void:
	_tm_penalty_timer += delta
	var stride_back: int = 5 if fmod(_anim_clock, 0.28) < 0.14 else 6
	# User & box edge players bob slightly on toes, ready to pounce
	_player_pos.x = -4.0 + sin(_anim_clock * 4.0) * 0.25
	_gk_pos.x = sin(_anim_clock * 5.0) * 0.55
	if not _teammate_positions.is_empty():
		var to_spot := -41.1 - _teammate_positions[0].z
		if absf(to_spot) > 0.08:
			_teammate_positions[0].z = move_toward(_teammate_positions[0].z, -41.1, 3.0 * delta)
			_teammates[0].frame = stride_back
	_sync_3d_sprites()

	if _tm_penalty_timer >= 0.92 and not _tm_penalty_kicked:
		_tm_penalty_kicked = true
		_teammates[0].frame = 7
		var corner := -1.0 if randf() < 0.5 else 1.0
		var tgt_x := corner * randf_range(1.6, 3.35)
		var spd := randf_range(21.5, 26.0)
		_ball_vel = Vector3(tgt_x, randf_range(2.2, 4.4), -10.0).normalized() * spd
		_ball_omega = Vector3(0.0, corner * 1.4, 0.0)
		_flight_timer = 0.0
		_phase = MatchPhase.BALL_IN_FLIGHT
		AudioSynth.play_kick(0.85)
		# Teammates & defenders start surging toward box right after the strike!
		_teammate_vels[0] = Vector3(0.0, 0.0, -1.6)
		if _teammate_vels.size() > 1:
			_teammate_vels[1] = Vector3(-0.6, 0.0, -3.5)

func _pick_squad_member_name(prefer_attacker: bool) -> String:
	if CareerState.has_active_career:
		var sq: Array = CareerState.career.get("clubSquad", {}).get("starters", [])
		var pool: Array[String] = []
		for p in sq:
			if bool(p.get("is_user", false)):
				continue
			if prefer_attacker and str(p.get("pos", "")) in ["ST", "LW", "RW", "CAM"]:
				pool.append(str(p.get("name", "REKAN")))
			elif not prefer_attacker:
				pool.append(str(p.get("name", "REKAN")))
		if not pool.is_empty():
			return pool[randi() % pool.size()].to_upper()
	var fallback := ["PURNOMO", "SILALAHI", "PRATAMA", "RAHMAN", "SETIAWAN"]
	return fallback[randi() % fallback.size()]

func _pick_opp_scorer_name() -> String:
	var pool := ["HUTAPEA", "GINTING", "WIJAYA", "BASRI", "PANJAITAN", "MAULANA", "SANTOSO"]
	return pool[randi() % pool.size()]

func _handle_goal_scored() -> void:
	AudioSynth.play_goal()
	_camera_shake = 1.0
	_score_us += 1
	var u_name: String = str(CareerState.career["playerProfile"].get("name", "PEMAIN")).to_upper() if CareerState.has_active_career else "PEMAIN"
	if _shot_by_teammate:
		var tm_name: String = _pick_squad_member_name(true)
		if _carry_assist_pending:
			_my_assists += 1
			_rating = minf(10.0, _rating + 1.1)
			_update_score_label()
			_update_last_shot("GOAL")
			_add_board_event(int(_minute), "GOAL", "%d' ASSIST! Rekan tuntaskan umpanmu menjadi GOL!" % int(_minute), true)
			_save_moviola_clip("ASSIST CANTIK!")
			_goal_timeline.append({"minute": int(_minute), "scorer": tm_name, "assist": u_name, "is_us": true, "is_user_involved": true, "clip": _best_clip.duplicate(true)})
			if is_instance_valid(_goal_flash_rect):
				_goal_flash_rect.color = Color(1.0, 0.92, 0.45, 0.55)
				create_tween().tween_property(_goal_flash_rect, "color:a", 0.0, 0.38)
			_show_moment_result("ASSIST! REKAN CETAK GOL!", UITheme.ACCENT_GOLD, 1.6)
			return
		_rating = minf(10.0, _rating + 0.35)
		_update_score_label()
		_add_board_event(int(_minute), "GOAL", "%d' GOL REKAN SETIM!" % int(_minute), true)
		_save_moviola_clip("GOL REKAN SETIM!")
		_goal_timeline.append({"minute": int(_minute), "scorer": tm_name, "assist": "", "is_us": true, "is_user_involved": false})
		if is_instance_valid(_goal_flash_rect):
			_goal_flash_rect.color = Color(1.0, 0.92, 0.45, 0.55)
			create_tween().tween_property(_goal_flash_rect, "color:a", 0.0, 0.38)
		_show_moment_result("GOOOOL REKAN SETIM!", UITheme.ACCENT_GOLD, 1.6)
		return
	_my_goals += 1
	if _moment_type == MomentType.PENALTY:
		_penalties_scored += 1
	elif _moment_type == MomentType.FREE_KICK:
		_freekicks_scored += 1
	_rating = minf(10.0, _rating + 1.3)
	_duel_score += 2
	_update_score_label()
	_update_last_shot("GOAL")
	_save_moviola_clip("GOL SPEKTAKULER!")
	_goal_timeline.append({"minute": int(_minute), "scorer": u_name, "assist": "", "is_us": true, "is_user_involved": true, "clip": _best_clip.duplicate(true)})
	if is_instance_valid(_goal_flash_rect):
		_goal_flash_rect.color = Color(1.0, 0.92, 0.45, 0.65)
		create_tween().tween_property(_goal_flash_rect, "color:a", 0.0, 0.40)
	_show_moment_result("GOOOOL!!", UITheme.ACCENT_GOLD, 1.65)

func _update_last_shot(outcome: String) -> void:
	if _shots_telemetry.is_empty():
		return
	var s := _shots_telemetry[_shots_telemetry.size() - 1]
	s["outcome"] = outcome
	var gx := clampf((_ball_pos.x + SlingshotPhysics.GOAL_HALF_W) / (SlingshotPhysics.GOAL_HALF_W * 2.0), 0.05, 0.95)
	var gy := clampf(_ball_pos.y / SlingshotPhysics.GOAL_HEIGHT, 0.05, 0.95)
	s["goalCoord"] = {"x": gx, "y": gy}

func _save_moviola_clip(caption: String) -> void:
	_best_clip = {
		"minute": int(_minute),
		"caption": caption,
		"frames": _current_clip_frames.duplicate(true),
	}

func _show_moment_result(msg: String, col: Color, dur: float) -> void:
	_phase = MatchPhase.MOMENT_RESULT
	_result_timer = dur
	if _action_bar != null:
		_action_bar.visible = false
	if _dribble_pad != null:
		_dribble_pad.visible = false
	if _stamina_bar_bg != null:
		_stamina_bar_bg.visible = false
	if _player_badge_lbl != null:
		_player_badge_lbl.visible = false
	_result_toast.text = msg
	_result_toast.add_theme_color_override("font_color", col)
	_result_toast.pivot_offset = _result_toast.size * 0.5
	_result_toast.scale = Vector2(1.28, 1.28)
	_result_toast.visible = true
	create_tween().tween_property(_result_toast, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)

func _advance_after_moment() -> void:
	for tm in _teammates:
		tm.visible = false
	for df in _defenders:
		df.visible = false
	_trail_imm.clear_surfaces()

	if run_mode == RunMode.PRACTICE_MODE:
		_practice_round += 1
		if _practice_round > 5:
			mode_exited.emit()
			return
		_minute_lbl.text = "%d/5" % _practice_round
		_score_lbl.text = "LATIHAN (%d GOL)" % _my_goals
		var p_next := MomentType.TEAMMATE_PASS if _practice_round == 3 else (MomentType.FREE_KICK if _practice_round % 2 == 0 else MomentType.SHOT)
		_trigger_key_moment(p_next)
		return

	if run_mode == RunMode.DUEL_MODE:
		_practice_round += 1
		if _practice_round > 5:
			var aid := str(duel_target.get("code", "duel"))
			CareerState.global_profile["friends_duels"][aid] = {"us": _duel_score, "them": int(duel_target.get("score_them", 4))}
			CareerState.save_global_profile()
			mode_exited.emit()
			return
		_minute_lbl.text = "%d/5" % _practice_round
		_trigger_key_moment(MomentType.PENALTY if _practice_round == 5 else MomentType.SHOT)
		return

	_phase = MatchPhase.SIMULATING
	if _board_panel != null and run_mode == RunMode.CAREER_MATCH:
		_board_panel.visible = true
		_spin_pad.visible = false
		_power_lbl.visible = false
		_sync_board_hud()

func _finish_career_match() -> void:
	_phase = MatchPhase.FULLTIME
	AudioSynth.play_whistle(true)
	var shots_copy: Array = []
	for s in _shots_telemetry:
		shots_copy.append(s)
	var report := CareerState.finish_match({
		"score_us": _score_us,
		"score_them": _score_them,
		"my_goals": _my_goals,
		"my_assists": _my_assists,
		"rating": _rating,
		"penalties_scored": _penalties_scored,
		"freekicks_scored": _freekicks_scored,
		"dribbles_won": _dribbles_won,
		"passes_won": _passes_won,
		"shots": shots_copy,
		"moviola_clip": _best_clip,
		"goal_timeline": _goal_timeline.duplicate(true),
	})
	match_completed.emit(report)

func _process_moviola_replay(delta: float) -> void:
	var frames: Array = replay_clip.get("frames", [])
	if frames.is_empty():
		_camera.global_position = Vector3(0.0, 3.2, -32.0)
		_camera.look_at(Vector3(0, 1.0, -52.5), Vector3.UP)
		return
	var step_int: float = 0.032 / maxf(0.25, _replay_speed)
	_replay_timer += delta
	if _replay_timer >= step_int:
		_replay_timer = 0.0
		_replay_idx = (_replay_idx + 1) % frames.size()
		var fr: Dictionary = frames[_replay_idx]
		var bp: Array = fr.get("ball", [0, 0.115, -40])
		var gp: Array = fr.get("gk", [0, -51.6])
		var pp: Array = fr.get("player", [0, -39])
		_ball_pos = Vector3(float(bp[0]), float(bp[1]), float(bp[2]))
		_gk_pos = Vector3(float(gp[0]), 0.0, float(gp[1]))
		_player_pos = Vector3(float(pp[0]), 0.0, float(pp[1]))
		_sync_3d_sprites()
	if _replay_cam_mode == "GOL":
		_camera.global_position = Vector3(_ball_pos.x * 0.25, 2.2, -55.0)
		_camera.look_at(_ball_pos + Vector3(0, 0.5, 0), Vector3.UP)
	elif _replay_cam_mode == "ORBIT":
		_replay_orbit_angle += delta * 0.65
		var rad := 10.5
		_camera.global_position = Vector3(_ball_pos.x + cos(_replay_orbit_angle) * rad, 4.0, _ball_pos.z + sin(_replay_orbit_angle) * rad)
		_camera.look_at(_ball_pos + Vector3(0, 0.8, 0), Vector3.UP)
	elif _replay_cam_mode == "BEBAS":
		var rad := 9.0
		_camera.global_position = Vector3(_ball_pos.x + cos(_replay_orbit_angle) * rad, 4.5, _ball_pos.z + sin(_replay_orbit_angle) * rad)
		_camera.look_at(_ball_pos + Vector3(0, 0.7, 0), Vector3.UP)
	else:
		_camera.global_position = Vector3(_ball_pos.x * 0.4 + 4.5, 3.6, _ball_pos.z + 9.5)
		_camera.look_at(Vector3(_ball_pos.x * 0.3, maxf(0.8, _ball_pos.y), minf(_ball_pos.z, -48.0)), Vector3.UP)

func _sync_3d_sprites() -> void:
	_player_sprite.global_position = _player_pos
	_player_shadow.global_position = Vector3(_player_pos.x, 0.03, _player_pos.z)
	_gk_sprite.global_position = _gk_pos
	_gk_shadow.global_position = Vector3(_gk_pos.x, 0.03, _gk_pos.z)
	_ball_sprite.global_position = _ball_pos
	_ball_shadow.global_position = Vector3(_ball_pos.x, 0.03, _ball_pos.z)
	var shadow_scale := clampf(1.0 - _ball_pos.y * 0.14, 0.35, 1.0)
	_ball_shadow.scale = Vector3.ONE * shadow_scale

	for i in range(_teammate_positions.size()):
		if i < _teammates.size():
			_teammates[i].global_position = _teammate_positions[i]
	for i in range(_defender_positions.size()):
		if i < _defenders.size():
			_defenders[i].global_position = _defender_positions[i]

func _draw_aim_and_ring() -> void:
	_ring_imm.clear_surfaces()
	_aim_imm.clear_surfaces()

	var ring_col := Color("#38E068")
	var aim_col := Color("#F8FAFC")
	if CareerState.has_active_career:
		var cos_d: Dictionary = CareerState.career["playerProfile"]["cosmetics"]
		for r in GameData.cosmetics_catalog.get("CINCIN", []):
			if r["id"] == cos_d.get("ringId", "default"):
				ring_col = r["color"]
				break
		for a in GameData.cosmetics_catalog.get("AIM", []):
			if a["id"] == cos_d.get("aimId", "default"):
				aim_col = a["color"]
				break

	# Ground Slingshot Ring (CINCIN) around player's feet as bold 3D dashed ribbon
	_ring_imm.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var segs := 36
	var r_in := 2.05
	var r_out := 2.32
	for i in range(segs):
		if i % 3 == 2:
			continue
		var a0 := float(i) / float(segs) * TAU
		var a1 := float(i + 1) / float(segs) * TAU
		var p0_in := Vector3(_player_pos.x + cos(a0) * r_in, 0.05, _player_pos.z + sin(a0) * r_in)
		var p0_out := Vector3(_player_pos.x + cos(a0) * r_out, 0.05, _player_pos.z + sin(a0) * r_out)
		var p1_in := Vector3(_player_pos.x + cos(a1) * r_in, 0.05, _player_pos.z + sin(a1) * r_in)
		var p1_out := Vector3(_player_pos.x + cos(a1) * r_out, 0.05, _player_pos.z + sin(a1) * r_out)
		for vtx in [p0_in, p0_out, p1_out, p0_in, p1_out, p1_in]:
			_ring_imm.surface_set_color(ring_col)
			_ring_imm.surface_add_vertex(vtx)
	if _moment_type == MomentType.SHOT or _moment_type == MomentType.DRIBBLE:
		var g_in := 3.45
		var g_out := 3.62
		var g_col := Color("#F5E050", 0.85)
		for i in range(segs):
			var a0 := float(i) / float(segs) * TAU
			var a1 := float(i + 1) / float(segs) * TAU
			var p0_in := Vector3(_ball_pos.x + cos(a0) * g_in, 0.04, _ball_pos.z + sin(a0) * g_in)
			var p0_out := Vector3(_ball_pos.x + cos(a0) * g_out, 0.04, _ball_pos.z + sin(a0) * g_out)
			var p1_in := Vector3(_ball_pos.x + cos(a1) * g_in, 0.04, _ball_pos.z + sin(a1) * g_in)
			var p1_out := Vector3(_ball_pos.x + cos(a1) * g_out, 0.04, _ball_pos.z + sin(a1) * g_out)
			for vtx in [p0_in, p0_out, p1_out, p0_in, p1_out, p1_in]:
				_ring_imm.surface_set_color(g_col)
				_ring_imm.surface_add_vertex(vtx)
	# eFootball / EA FC directional cursor ring & pointer wedge under player whenever actively dribbling
	if _is_user_dribbling_active():
		var ang_f := atan2(_dribble_facing.y, _dribble_facing.x)
		var arr_col := UITheme.ACCENT_GOLD if _skill_burst_timer > 0.0 else Color("#22D3EE")
		var tip := Vector3(_player_pos.x + cos(ang_f) * 3.1, 0.06, _player_pos.z + sin(ang_f) * 3.1)
		var b_l := Vector3(_player_pos.x + cos(ang_f - 0.35) * 2.25, 0.06, _player_pos.z + sin(ang_f - 0.35) * 2.25)
		var b_r := Vector3(_player_pos.x + cos(ang_f + 0.35) * 2.25, 0.06, _player_pos.z + sin(ang_f + 0.35) * 2.25)
		for vtx in [tip, b_r, b_l]:
			_ring_imm.surface_set_color(arr_col)
			_ring_imm.surface_add_vertex(vtx)
	# Draw live teammate movement rings, free-kick target rings, & Offside line warning!
	if _moment_type in [MomentType.SHOT, MomentType.PASS, MomentType.DRIBBLE, MomentType.FREE_KICK]:
		var any_offside := false
		for ti in range(_teammate_positions.size()):
			var tp: Vector3 = _teammate_positions[ti]
			var is_off: bool = _is_teammate_offside(ti)
			if is_off:
				any_offside = true
			var od: float = _teammate_open_scores[ti] if ti < _teammate_open_scores.size() else 2.0
			var alpha_tm: float = 0.92 if (_moment_type == MomentType.PASS or is_off) else 0.62
			var tm_col := Color(0.98, 0.22, 0.25, 0.94) if is_off else (Color(0.28, 0.88, 0.50, alpha_tm) if od >= 3.2 else (Color(0.16, 0.82, 0.92, alpha_tm) if od >= 1.95 else Color(0.96, 0.45, 0.16, alpha_tm)))
			var tr_in := 1.15
			var tr_out := 1.38
			for i in range(18):
				var a0 := float(i) / 18.0 * TAU
				var a1 := float(i + 1) / 18.0 * TAU
				var p0_in := Vector3(tp.x + cos(a0) * tr_in, 0.05, tp.z + sin(a0) * tr_in)
				var p0_out := Vector3(tp.x + cos(a0) * tr_out, 0.05, tp.z + sin(a0) * tr_out)
				var p1_in := Vector3(tp.x + cos(a1) * tr_in, 0.05, tp.z + sin(a1) * tr_in)
				var p1_out := Vector3(tp.x + cos(a1) * tr_out, 0.05, tp.z + sin(a1) * tr_out)
				for vtx in [p0_in, p0_out, p1_out, p0_in, p1_out, p1_in]:
					_ring_imm.surface_set_color(tm_col)
					_ring_imm.surface_add_vertex(vtx)
			if _moment_type != MomentType.FREE_KICK and ti < _teammate_vels.size() and _teammate_vels[ti].length() > 0.35:
				var vdir := _teammate_vels[ti].normalized()
				var side_v := Vector3(-vdir.z, 0.0, vdir.x) * 0.22
				var r_start := tp + Vector3(0.0, 0.05, 0.0) + vdir * 1.4
				var r_end := r_start + vdir * (3.0 if _moment_type == MomentType.PASS else 1.8)
				for vtx in [r_start - side_v, r_start + side_v, r_end + side_v, r_start - side_v, r_end + side_v, r_end - side_v]:
					_ring_imm.surface_set_color(tm_col)
					_ring_imm.surface_add_vertex(vtx)
		if any_offside:
			var off_z: float = _get_offside_line_z()
			var off_col := Color(0.98, 0.24, 0.28, 0.78)
			var lx := -32.0
			while lx < 32.0:
				var lx1 := minf(32.0, lx + 1.6)
				for vtx in [Vector3(lx, 0.05, off_z - 0.11), Vector3(lx1, 0.05, off_z - 0.11), Vector3(lx1, 0.05, off_z + 0.11), Vector3(lx, 0.05, off_z - 0.11), Vector3(lx1, 0.05, off_z + 0.11), Vector3(lx, 0.05, off_z + 0.11)]:
					_ring_imm.surface_set_color(off_col)
					_ring_imm.surface_add_vertex(vtx)
				lx += 2.6
	_ring_imm.surface_end()

	if not _dragging:
		return

	var delta_px := _drag_start - _drag_current
	if delta_px.length() < 12.0:
		_power_lbl.text = "0%"
		return

	var kek := CareerState.get_effective_attribute("kekuatan") if CareerState.has_active_career else 68
	var ak := CareerState.get_effective_attribute("akurasi") if CareerState.has_active_career else 68
	var ef := CareerState.get_effective_attribute("efek") if CareerState.has_active_career else 68
	var pen := CareerState.get_effective_attribute("penalti") if CareerState.has_active_career else 68
	var bm := CareerState.get_effective_attribute("bolaMati") if CareerState.has_active_career else 68

	var launch := SlingshotPhysics.compute_launch_params(
		delta_px, 210.0, kek, ak, ef, pen, bm, _spin_offset,
		_moment_type == MomentType.PENALTY,
		_moment_type == MomentType.FREE_KICK,
		1.0, false
	)
	var pct := int(round(float(launch["power_ratio"]) * 100.0))
	_power_lbl.text = "%d%%" % pct
	_power_lbl.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)

	var steps_preview := int(lerpf(12.0, 28.0, float(ak + (bm if _moment_type == MomentType.FREE_KICK else 0)) / 180.0))
	var pts := SlingshotPhysics.predict_trajectory(_ball_pos, launch["velocity"], launch["omega"], ef, steps_preview, 0.04)
	if pts.size() >= 2:
		if _moment_type in [MomentType.SHOT, MomentType.PASS, MomentType.DRIBBLE, MomentType.FREE_KICK]:
			var aims_tm_idx: int = -1
			for pt in pts:
				for ti in range(_teammate_positions.size()):
					var tp: Vector3 = _teammate_positions[ti]
					if Vector2(pt.x - tp.x, pt.z - tp.z).length() < 2.2:
						aims_tm_idx = ti
						break
				if aims_tm_idx >= 0:
					break
			if aims_tm_idx >= 0:
				if _is_teammate_offside(aims_tm_idx):
					_power_lbl.text = "%d%% • OFFSIDE!" % pct
					_power_lbl.add_theme_color_override("font_color", UITheme.ACCENT_RED)
				else:
					_power_lbl.text = "%d%% • UMPAN" % pct
		_aim_imm.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in range(pts.size() - 1):
			var p0 := pts[i]
			var p1 := pts[i + 1]
			var dir_xz := Vector3(p1.x - p0.x, 0.0, p1.z - p0.z).normalized()
			var side_core := Vector3(-dir_xz.z, 0.0, dir_xz.x) * 0.13
			var side_halo := Vector3(-dir_xz.z, 0.0, dir_xz.x) * 0.25
			var alpha := 1.0 - float(i) / float(pts.size()) * 0.72
			var c_halo := Color(aim_col.r, aim_col.g, aim_col.b, alpha * 0.28)
			var c := Color(aim_col.r, aim_col.g, aim_col.b, alpha)
			for vtx in [p0 - side_halo, p0 + side_halo, p1 + side_halo, p0 - side_halo, p1 + side_halo, p1 - side_halo]:
				_aim_imm.surface_set_color(c_halo)
				_aim_imm.surface_add_vertex(vtx)
			for vtx in [p0 - side_core, p0 + side_core, p1 + side_core, p0 - side_core, p1 + side_core, p1 - side_core]:
				_aim_imm.surface_set_color(c)
				_aim_imm.surface_add_vertex(vtx)
		_aim_imm.surface_end()

func _draw_ball_trail() -> void:
	_trail_imm.clear_surfaces()
	if _trail_points.size() < 2:
		return
	var trail_col := Color("#E2E8F0")
	if CareerState.has_active_career:
		var tid := str(CareerState.career["playerProfile"]["cosmetics"].get("trailId", "default"))
		for t in GameData.cosmetics_catalog.get("JEJAK", []):
			if t["id"] == tid:
				trail_col = t["color"]
				break
	_trail_imm.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in range(_trail_points.size()):
		var a := float(i) / float(_trail_points.size())
		_trail_imm.surface_set_color(Color(trail_col.r, trail_col.g, trail_col.b, a))
		_trail_imm.surface_add_vertex(_trail_points[i])
	_trail_imm.surface_end()

func _moment_type_str() -> String:
	match _moment_type:
		MomentType.PASS: return "PASS"
		MomentType.DRIBBLE: return "DRIBBLE"
		MomentType.FREE_KICK: return "FREE_KICK"
		MomentType.PENALTY: return "PENALTY"
		MomentType.TEAMMATE_PASS: return "TEAMMATE_PASS"
		_: return "OPEN_PLAY"

func _update_score_label() -> void:
	if run_mode != RunMode.CAREER_MATCH:
		return
	var club := CareerState.get_current_club()
	var fix := CareerState.get_current_fixture()
	_score_lbl.text = "%s %d - %d %s" % [club.get("code", "DED"), _score_us, _score_them, fix.get("opp_code", "SVA")]

func _on_toggle_speed() -> void:
	AudioSynth.play_click()
	if _sim_speed < 1.5:
		_sim_speed = 2.0
		_speed_btn.text = "2X"
	elif _sim_speed < 3.0:
		_sim_speed = 4.0
		_speed_btn.text = "4X"
	else:
		_sim_speed = 1.0
		_speed_btn.text = "1X"

func _on_skip_or_exit() -> void:
	AudioSynth.play_click()
	if run_mode != RunMode.CAREER_MATCH:
		mode_exited.emit()
		return
	# Fast-forward remaining minutes cleanly
	while _minute < 90.0:
		_minute += 10.0
		if randf() < 0.25:
			_score_us += 1
		if randf() < 0.22:
			_score_them += 1
	_finish_career_match()

func _build_board_and_overlays() -> void:
	# 1. Crimson 2D Live Match Broadcast Board (matching 05_v2_match_board.png!)
	_board_panel = ColorRect.new()
	_board_panel.color = Color("#561121")
	_board_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_board_panel.visible = false
	add_child(_board_panel)

	var bvb := VBoxContainer.new()
	bvb.set_anchors_preset(Control.PRESET_FULL_RECT)
	bvb.offset_left = 10
	bvb.offset_right = -10
	bvb.offset_top = 10
	bvb.offset_bottom = -10
	bvb.add_theme_constant_override("separation", 8)
	_board_panel.add_child(bvb)

	var top_card := PanelContainer.new()
	top_card.add_theme_stylebox_override("panel", UITheme.make_box(Color("#9A1B32"), Color("#FFFFFF"), 2, 4))
	bvb.add_child(top_card)
	var thb := HBoxContainer.new()
	thb.add_theme_constant_override("separation", 8)
	top_card.add_child(thb)
	_board_min_lbl = Label.new()
	_board_min_lbl.text = "0'"
	_board_min_lbl.custom_minimum_size = Vector2(56, 46)
	_board_min_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_board_min_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_board_min_lbl.add_theme_font_override("font", UITheme.get_display_font())
	_board_min_lbl.add_theme_font_size_override("font_size", 22)
	_board_min_lbl.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	thb.add_child(_board_min_lbl)

	_board_score_lbl = Label.new()
	_board_score_lbl.text = "LIGA KE-3 • 0 - 0"
	_board_score_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_board_score_lbl.add_theme_font_override("font", UITheme.get_display_font())
	_board_score_lbl.add_theme_font_size_override("font_size", 16)
	thb.add_child(_board_score_lbl)

	var skip_b := Button.new()
	skip_b.text = "SKIP >>"
	UITheme.style_btn(skip_b, Color("#4E2424"), UITheme.ACCENT_RED, 11)
	skip_b.pressed.connect(_on_skip_or_exit)
	thb.add_child(skip_b)

	var f_scroll := ScrollContainer.new()
	var body_hb := HBoxContainer.new()
	body_hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_hb.add_theme_constant_override("separation", 10)
	bvb.add_child(body_hb)

	var left_col := VBoxContainer.new()
	left_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_col.size_flags_stretch_ratio = 0.45
	left_col.add_theme_constant_override("separation", 6)
	body_hb.add_child(left_col)

	var right_col := VBoxContainer.new()
	right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_col.size_flags_stretch_ratio = 0.55
	right_col.add_theme_constant_override("separation", 6)
	body_hb.add_child(right_col)

	# Possession + Timeline Track
	var poss_box := PanelContainer.new()
	poss_box.add_theme_stylebox_override("panel", UITheme.make_box(Color("#360A14"), Color("#842838"), 1, 4))
	left_col.add_child(poss_box)
	var pvb := VBoxContainer.new()
	pvb.add_theme_constant_override("separation", 4)
	poss_box.add_child(pvb)
	_board_poss_lbl = Label.new()
	_board_poss_lbl.text = "PENGUASAAN BOLA 52%"
	_board_poss_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_board_poss_lbl.add_theme_font_size_override("font_size", 11)
	pvb.add_child(_board_poss_lbl)
	var p_bg := ColorRect.new()
	p_bg.color = Color("#1F080D")
	p_bg.custom_minimum_size = Vector2(0, 6)
	pvb.add_child(p_bg)
	_board_poss_bar = ColorRect.new()
	_board_poss_bar.color = Color("#EBF1F6")
	_board_poss_bar.custom_minimum_size = Vector2(200, 6)
	p_bg.add_child(_board_poss_bar)
	_board_timeline = Control.new()
	_board_timeline.custom_minimum_size = Vector2(0, 32)
	_board_timeline.draw.connect(_draw_board_timeline)
	pvb.add_child(_board_timeline)

	# Featured Event Card
	var hl_box := PanelContainer.new()
	hl_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hl_box.add_theme_stylebox_override("panel", UITheme.make_box(Color("#6C182A"), Color("#D64056"), 2, 6))
	left_col.add_child(hl_box)
	_board_hl_lbl = Label.new()
	_board_hl_lbl.text = "KICKOFF! MENUNGGU MOMEN PERTANDINGAN..."
	_board_hl_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_board_hl_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_board_hl_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_board_hl_lbl.add_theme_font_override("font", UITheme.get_display_font())
	_board_hl_lbl.add_theme_font_size_override("font_size", 13)
	hl_box.add_child(_board_hl_lbl)

	# Bottom Rating/Energy + Tactical Strip inside Left Col
	var stat_hb := HBoxContainer.new()
	stat_hb.add_theme_constant_override("separation", 8)
	left_col.add_child(stat_hb)
	_board_rating_lbl = Label.new()
	_board_rating_lbl.text = "RATING 6.2"
	_board_rating_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_board_rating_lbl.add_theme_font_override("font", UITheme.get_display_font())
	_board_rating_lbl.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	stat_hb.add_child(_board_rating_lbl)
	_board_energy_lbl = Label.new()
	_board_energy_lbl.text = "ENERGI 100%"
	_board_energy_lbl.add_theme_color_override("font_color", UITheme.ACCENT_GREEN)
	stat_hb.add_child(_board_energy_lbl)

	var e_bg := ColorRect.new()
	e_bg.color = Color("#240A10")
	e_bg.custom_minimum_size = Vector2(0, 6)
	left_col.add_child(e_bg)
	_board_energy_bar = ColorRect.new()
	_board_energy_bar.color = UITheme.ACCENT_GREEN
	_board_energy_bar.custom_minimum_size = Vector2(220, 6)
	e_bg.add_child(_board_energy_bar)

	var tac_hb := HBoxContainer.new()
	tac_hb.add_theme_constant_override("separation", 4)
	left_col.add_child(tac_hb)
	_strat_btn = Button.new()
	_strat_btn.text = "STRATEGI\nSEIMBANG"
	_strat_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.style_btn(_strat_btn, Color("#885A22"), UITheme.ACCENT_GOLD, 10)
	_strat_btn.pressed.connect(func():
		AudioSynth.play_click()
		var opts := ["SEIMBANG", "MENYERANG", "BERTAHAN"]
		var cur: String = str(CareerState.career["careerMeta"].get("strategy", "SEIMBANG"))
		var nxt: String = opts[(opts.find(cur) + 1) % opts.size()]
		CareerState.career["careerMeta"]["strategy"] = nxt
		_strat_btn.text = "STRATEGI\n" + nxt
	)
	tac_hb.add_child(_strat_btn)

	_inten_btn = Button.new()
	_inten_btn.text = "INTENSITAS\nSEDANG"
	_inten_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.style_btn(_inten_btn, Color("#7A4A20"), UITheme.ACCENT_GOLD, 10)
	_inten_btn.pressed.connect(func():
		AudioSynth.play_click()
		var opts := ["RENDAH", "SEDANG", "TINGGI"]
		var cur: String = str(CareerState.career["careerMeta"].get("intensity", "SEDANG"))
		var nxt: String = opts[(opts.find(cur) + 1) % opts.size()]
		CareerState.career["careerMeta"]["intensity"] = nxt
		_inten_btn.text = "INTENSITAS\n" + nxt
	)
	tac_hb.add_child(_inten_btn)

	var pause_b := Button.new()
	pause_b.text = "II"
	pause_b.custom_minimum_size = Vector2(36, 36)
	UITheme.style_btn(pause_b, Color("#240A10"), UITheme.BORDER_STEEL, 12)
	pause_b.pressed.connect(func(): AudioSynth.play_click(); _open_pause_menu())
	tac_hb.add_child(pause_b)

	# Scrollable Commentary Log in Right Col
	var log_hdr := UITheme.make_section_header("KOMENTAR LANGSUNG")
	right_col.add_child(log_hdr)
	var feed_panel := PanelContainer.new()
	feed_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	feed_panel.add_theme_stylebox_override("panel", UITheme.make_box(Color("#320912"), Color("#782434"), 1, 6))
	right_col.add_child(feed_panel)
	f_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	feed_panel.add_child(f_scroll)
	_board_feed_vb = VBoxContainer.new()
	_board_feed_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_board_feed_vb.add_theme_constant_override("separation", 4)
	f_scroll.add_child(_board_feed_vb)

	var spd_b := Button.new()
	spd_b.text = "x1"
	spd_b.custom_minimum_size = Vector2(40, 36)
	UITheme.style_btn(spd_b, Color("#240A10"), UITheme.ACCENT_CYAN, 12)
	spd_b.pressed.connect(func(): _on_toggle_speed(); spd_b.text = "x%d" % int(_sim_speed))
	tac_hb.add_child(spd_b)

	# 2. Halftime Locker Panel
	_halftime_panel = Control.new()
	_halftime_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_halftime_panel.visible = false
	add_child(_halftime_panel)

	# 3. Ask Set-Piece Panel
	_ask_panel = Control.new()
	_ask_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ask_panel.visible = false
	add_child(_ask_panel)

func _add_board_event(m: int, kind: String, txt: String, is_us: bool) -> void:
	_board_events.append({"min": m, "kind": kind, "us": is_us})
	if _board_hl_lbl != null:
		_board_hl_lbl.text = txt
	if _board_feed_vb != null:
		var lbl := Label.new()
		lbl.text = txt
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", UITheme.ACCENT_GOLD if kind == "GOAL" else Color("#E2E8F0"))
		_board_feed_vb.add_child(lbl)
		_board_feed_vb.move_child(lbl, 0)
	if _board_timeline != null:
		_board_timeline.queue_redraw()

func _push_random_sim_event() -> void:
	var events := [
		["INFO", "Laga berjalan ketat di lini tengah.", true],
		["FOUL", "Kartu kuning akibat tekel terlambat di sisi kanan.", false],
		["CORNER", "Tendangan penjuru melengkung ke tiang dekat!", true],
		["SAVE", "Kiper menepis sepakan jarak jauh dengan gemilang!", true],
	]
	var ev: Array = events[randi() % events.size()]
	_add_board_event(int(_minute), ev[0], "%d' %s" % [int(_minute), ev[1]], bool(ev[2]))

func _draw_board_timeline() -> void:
	if _board_timeline == null:
		return
	var s := _board_timeline.size
	_board_timeline.draw_line(Vector2(10, s.y * 0.5), Vector2(s.x - 10, s.y * 0.5), Color("#804050"), 2.0)
	_board_timeline.draw_line(Vector2(s.x * 0.5, 4), Vector2(s.x * 0.5, s.y - 4), Color("#804050"), 1.0)
	for ev in _board_events:
		var x := lerpf(10.0, s.x - 10.0, clampf(float(ev["min"]) / 90.0, 0.0, 1.0))
		var y0 := s.y * 0.5
		var dy := -11.0 if bool(ev["us"]) else 11.0
		var col := UITheme.ACCENT_GOLD if str(ev["kind"]).contains("GOAL") else Color.WHITE
		_board_timeline.draw_line(Vector2(x, y0), Vector2(x, y0 + dy), col, 3.0)

func _sync_board_hud() -> void:
	if _board_panel == null or not CareerState.has_active_career:
		return
	var club := CareerState.get_current_club()
	var fix := CareerState.get_current_fixture()
	var eng: int = maxi(20, int(CareerState.career["playerProfile"]["energy"]) - int(_minute * 0.18))
	_board_min_lbl.text = "%d'" % mini(90, int(_minute))
	_board_score_lbl.text = "%s %d - %d %s" % [club["code"], _score_us, _score_them, fix["opp_code"]]
	var poss: int = clampi(50 + int(club["ovr"]) - int(fix["opp_ovr"]), 34, 68)
	_board_poss_lbl.text = "%s %d%%" % [str(club["name"]).to_upper(), poss]
	var p_bg := _board_poss_bar.get_parent() as Control
	var p_w: float = p_bg.size.x if (p_bg != null and p_bg.size.x > 20.0) else 360.0
	_board_poss_bar.size.x = p_w * (float(poss) / 100.0)
	_board_rating_lbl.text = "RATING %.1f" % _rating
	_board_energy_lbl.text = "ENERGI %d%%" % eng
	var e_bg := _board_energy_bar.get_parent() as Control
	var e_w: float = e_bg.size.x if (e_bg != null and e_bg.size.x > 20.0) else 360.0
	_board_energy_bar.size.x = e_w * (float(eng) / 100.0)
	_board_energy_bar.color = UITheme.ACCENT_GREEN if eng >= 45 else UITheme.ACCENT_GOLD

func _open_halftime_locker() -> void:
	_phase = MatchPhase.HALFTIME
	if _board_panel != null:
		_board_panel.visible = false
	_spin_pad.visible = false
	_power_lbl.visible = false
	if _dribble_pad != null:
		_dribble_pad.visible = false
	if _stamina_bar_bg != null:
		_stamina_bar_bg.visible = false
	if _action_bar != null:
		_action_bar.visible = false
	if _player_badge_lbl != null:
		_player_badge_lbl.visible = false
	for c in _halftime_panel.get_children():
		c.queue_free()
	AudioSynth.play_whistle(false)

	var base_bg := ColorRect.new()
	base_bg.color = Color("#0D0A10")
	base_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_halftime_panel.add_child(base_bg)

	var bg := TextureRect.new()
	bg.texture = load("res://assets/sprites/backgrounds/locker_room.png")
	bg.anchor_left = 0.0
	bg.anchor_right = 1.0
	bg.anchor_top = 0.0
	bg.anchor_bottom = 0.34
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_halftime_panel.add_child(bg)

	var trim_line := ColorRect.new()
	trim_line.color = UITheme.ACCENT_RED
	trim_line.anchor_left = 0.0
	trim_line.anchor_right = 1.0
	trim_line.anchor_top = 0.34
	trim_line.anchor_bottom = 0.34
	trim_line.offset_bottom = 3
	_halftime_panel.add_child(trim_line)

	var card := PanelContainer.new()
	card.anchor_left = 0.20
	card.anchor_right = 0.80
	card.anchor_top = 0.5
	card.anchor_bottom = 0.5
	card.offset_top = -135
	card.offset_bottom = 135
	card.add_theme_stylebox_override("panel", UITheme.make_box(Color("#1A0D12", 0.94), UITheme.ACCENT_RED, 2, 12))
	_halftime_panel.add_child(card)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	card.add_child(vb)

	var st_str: String = "UNGGUL" if _score_us > _score_them else ("TERTINGGAL" if _score_us < _score_them else "SKOR SERI")
	var ttl := Label.new()
	ttl.text = "HALFTIME: %d - %d\n%s" % [_score_us, _score_them, st_str]
	ttl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ttl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ttl.add_theme_font_override("font", UITheme.get_display_font())
	ttl.add_theme_font_size_override("font_size", 18)
	vb.add_child(ttl)

	var eng: int = int(CareerState.career["playerProfile"]["energy"]) if CareerState.has_active_career else 80
	var info := Label.new()
	info.text = "RATING: %.1f  •  ENERGI: %d%%\nPelatih: Fokus 45 menit kedua!" % [_rating, eng]
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(info)

	var drink_b := Button.new()
	drink_b.text = "BELI MINUMAN ENERGI (+28%) • $13.500"
	drink_b.custom_minimum_size = Vector2(0, 42)
	UITheme.style_btn(drink_b, Color("#401A20"), UITheme.ACCENT_GOLD, 12)
	drink_b.pressed.connect(func():
		if CareerState.buy_emergency_drink(13500):
			AudioSynth.play_achievement()
			drink_b.text = "ENERGI PULIH! SIAP TAMPIL"
			drink_b.disabled = true
	)
	vb.add_child(drink_b)

	var go2 := Button.new()
	go2.text = "BABAK KEDUA"
	go2.custom_minimum_size = Vector2(0, 48)
	UITheme.style_btn(go2, Color("#0E1D30"), UITheme.ACCENT_CYAN, 18)
	go2.pressed.connect(func():
		AudioSynth.play_whistle(false)
		_halftime_panel.visible = false
		_phase = MatchPhase.SIMULATING
		if _board_panel != null:
			_board_panel.visible = true
	)
	vb.add_child(go2)
	_halftime_panel.visible = true

func _open_ask_set_piece(m_type: MomentType) -> void:
	_phase = MatchPhase.ASK_SET_PIECE
	_pending_ask_type = m_type
	for c in _ask_panel.get_children():
		c.queue_free()

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.04, 0.08, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ask_panel.add_child(dim)

	var card := PanelContainer.new()
	card.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	card.offset_left = 140
	card.offset_right = -140
	card.offset_top = -150
	card.offset_bottom = -18
	card.add_theme_stylebox_override("panel", UITheme.make_box(Color("#121A26", 0.96), UITheme.ACCENT_GOLD, 2, 10))
	_ask_panel.add_child(card)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	card.add_child(vb)

	var rel_rg: int = int(CareerState.career["playerProfile"]["relations"]["ruangGanti"])
	var yes_pct: int = clampi(38 + int(rel_rg * 0.5), 25, 92)
	var sp_lbl: String = "PENALTI" if m_type == MomentType.PENALTY else "TENDANGAN BEBAS"
	var h := Label.new()
	h.text = "%s MILIK REKAN SETIM — MINTA EKSEKUSI?" % sp_lbl
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	vb.add_child(h)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	vb.add_child(hb)

	var b_yes := Button.new()
	b_yes.text = "MINTA (YA %d%%)" % yes_pct
	b_yes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_yes.custom_minimum_size = Vector2(0, 44)
	UITheme.style_btn(b_yes, Color("#17462E"), UITheme.ACCENT_GREEN, 13)
	b_yes.pressed.connect(func():
		AudioSynth.play_click()
		_ask_panel.visible = false
		if randi_range(1, 100) <= yes_pct:
			_add_board_event(int(_minute), "INFO", "%d' Rekan memberimu bola untuk %s!" % [int(_minute), sp_lbl], true)
			_trigger_key_moment(_pending_ask_type)
		elif _pending_ask_type == MomentType.PENALTY:
			_add_board_event(int(_minute), "INFO", "%d' Rekan mengeksekusi penalti — bersiap rebound!" % int(_minute), true)
			_trigger_key_moment(MomentType.TEAMMATE_PENALTY)
		else:
			_add_board_event(int(_minute), "INFO", "%d' Rekan menolak dan eksekusi sendiri." % int(_minute), false)
			_phase = MatchPhase.SIMULATING
			if _board_panel != null:
				_board_panel.visible = true
	)
	hb.add_child(b_yes)

	var b_no := Button.new()
	b_no.text = "BIARKAN (TIDAK)"
	b_no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_no.custom_minimum_size = Vector2(0, 44)
	UITheme.style_btn(b_no, Color("#4E2424"), UITheme.ACCENT_RED, 13)
	b_no.pressed.connect(func():
		AudioSynth.play_click()
		_ask_panel.visible = false
		if _pending_ask_type == MomentType.PENALTY:
			_trigger_key_moment(MomentType.TEAMMATE_PENALTY)
		else:
			_phase = MatchPhase.SIMULATING
			if _board_panel != null:
				_board_panel.visible = true
	)
	hb.add_child(b_no)
	_ask_panel.visible = true

func _sync_stamina_hud() -> void:
	if _stamina_fill == null or _stamina_lbl == null:
		return
	var ratio: float = clampf(_match_stamina / maxf(1.0, _match_stamina_max), 0.0, 1.0)
	_stamina_fill.anchor_right = ratio
	var st_col: Color = UITheme.ACCENT_GREEN if ratio >= 0.45 else (UITheme.ACCENT_GOLD if ratio >= 0.20 else UITheme.ACCENT_RED)
	_stamina_fill.color = st_col
	_stamina_lbl.text = "STM %d%%" % int(round(_match_stamina))

func _sync_action_bar() -> void:
	if _action_bar == null:
		return
	var open_play := (_phase == MatchPhase.KEY_MOMENT_AIM and run_mode != RunMode.MOVIOLA_REPLAY and (_moment_type in [MomentType.SHOT, MomentType.PASS, MomentType.DRIBBLE]))
	_action_bar.visible = open_play
	if _dribble_pad != null:
		_dribble_pad.visible = open_play
	if _stamina_bar_bg != null:
		_stamina_bar_bg.visible = open_play
		if open_play:
			_sync_stamina_hud()
	if _spin_pad != null:
		_spin_pad.visible = (_phase == MatchPhase.KEY_MOMENT_AIM and run_mode != RunMode.MOVIOLA_REPLAY and _moment_type != MomentType.TEAMMATE_PENALTY)
	if _power_lbl != null:
		_power_lbl.visible = (_phase == MatchPhase.KEY_MOMENT_AIM and run_mode != RunMode.MOVIOLA_REPLAY and _moment_type != MomentType.TEAMMATE_PENALTY)
	if open_play:
		_last_pass_state = ""
		_update_pass_openness_ui()
	if _player_badge_lbl != null:
		_player_badge_lbl.visible = (_phase == MatchPhase.KEY_MOMENT_AIM and run_mode != RunMode.MOVIOLA_REPLAY)
		if open_play:
			_player_badge_lbl.offset_top = -202
			_player_badge_lbl.offset_bottom = -178
		else:
			_player_badge_lbl.offset_top = -52
			_player_badge_lbl.offset_bottom = -24
		if _player_badge_lbl.visible:
			if CareerState.has_active_career:
				var prof: Dictionary = CareerState.career["playerProfile"]
				var num := int(prof.get("appearance", {}).get("shirt_num", 9))
				_player_badge_lbl.text = "#%d %s" % [num, str(prof.get("name", "PEMAIN")).to_upper()]
			else:
				_player_badge_lbl.text = "#9 PEMAIN"

func _switch_open_play_action(new_t: MomentType) -> void:
	if _phase != MatchPhase.KEY_MOMENT_AIM or _moment_type == new_t:
		return
	_dragging = false
	_aim_imm.clear_surfaces()
	_ring_imm.clear_surfaces()
	_moment_type = new_t
	if _teammate_positions.is_empty() or _defender_positions.is_empty():
		_spawn_open_play_actors()
	_apply_open_play_prompt(new_t)
	_sync_action_bar()
	_configure_moment_camera()
	_sync_3d_sprites()
	_draw_aim_and_ring()

func _open_pause_menu() -> void:
	if is_instance_valid(_pause_panel):
		_pause_panel.queue_free()
	_is_paused = true
	_dragging = false
	_pause_panel = Control.new()
	_pause_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_pause_panel)

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.04, 0.09, 0.86)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_panel.add_child(dim)

	var card := PanelContainer.new()
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.custom_minimum_size = Vector2(440, 276)
	card.offset_left = -220
	card.offset_right = 220
	card.offset_top = -138
	card.offset_bottom = 138
	card.add_theme_stylebox_override("panel", UITheme.make_box(Color("#0A1526"), UITheme.ACCENT_CYAN, 2, 14))
	_pause_panel.add_child(card)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	card.add_child(vb)

	var ttl := Label.new()
	ttl.text = "JEDA PERTANDINGAN"
	ttl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ttl.add_theme_font_override("font", UITheme.get_display_font())
	ttl.add_theme_font_size_override("font_size", 20)
	ttl.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	vb.add_child(ttl)

	var info := Label.new()
	info.text = "MODE: %s   •   KAMERA: %s" % [
		str(SettingsManager.data.get("difficulty", "NORMAL")),
		str(SettingsManager.data.get("perspective", "TV")),
	]
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_color_override("font_color", UITheme.ACCENT_CYAN)
	info.add_theme_font_size_override("font_size", 12)
	vb.add_child(info)

	var res_b := Button.new()
	res_b.text = "> LANJUTKAN"
	res_b.custom_minimum_size = Vector2(0, 48)
	UITheme.style_btn(res_b, Color("#17462E"), UITheme.ACCENT_GREEN, 15)
	res_b.pressed.connect(func():
		AudioSynth.play_click()
		_is_paused = false
		if is_instance_valid(_pause_panel):
			_pause_panel.queue_free()
	)
	vb.add_child(res_b)

	var set_b := Button.new()
	set_b.text = "SETELAN (KESULITAN & KAMERA)"
	set_b.custom_minimum_size = Vector2(0, 48)
	UITheme.style_btn(set_b, Color("#173B66"), UITheme.ACCENT_CYAN, 14)
	set_b.pressed.connect(func():
		AudioSynth.play_click()
		card.visible = false
		var sm: Control = (load("res://scenes/modals/SettingsModal.gd") as GDScript).new()
		sm.call("configure", "LAGA", true)
		sm.set_anchors_preset(Control.PRESET_FULL_RECT)
		sm.connect("closed", func():
			_gk_react_timer = float(SettingsManager.get_difficulty_params()["gk_reaction"])
			if _phase == MatchPhase.KEY_MOMENT_AIM:
				_configure_moment_camera()
			_open_pause_menu()
		)
		_pause_panel.add_child(sm)
	)
	vb.add_child(set_b)

	var exit_b := Button.new()
	exit_b.text = "< KELUAR LAGA"
	exit_b.custom_minimum_size = Vector2(0, 44)
	UITheme.style_btn(exit_b, Color("#562828"), UITheme.ACCENT_RED, 13)
	exit_b.pressed.connect(func():
		AudioSynth.play_click()
		_is_paused = false
		if is_instance_valid(_pause_panel):
			_pause_panel.queue_free()
		_on_skip_or_exit()
	)
	vb.add_child(exit_b)


class SpinBallPad extends Control:
	signal spin_changed(offset: Vector2)
	var spin: Vector2 = Vector2.ZERO
	var _active: bool = false

	func reset_spin() -> void:
		spin = Vector2.ZERO
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			_active = event.pressed
			if _active:
				_update_spin(event.position)
		elif event is InputEventMouseMotion and _active:
			_update_spin(event.position)

	func _update_spin(pos: Vector2) -> void:
		var center := size * 0.5
		var rad := minf(size.x, size.y) * 0.42
		var v := (pos - center) / maxf(rad, 1.0)
		if v.length() > 1.0:
			v = v.normalized()
		spin = v
		queue_redraw()
		spin_changed.emit(spin)

	func _draw() -> void:
		var center := Vector2(size.x * 0.5, size.y * 0.44)
		var rad := minf(size.x, size.y) * 0.36
		draw_circle(center, rad + 3, Color(0.04, 0.08, 0.16, 0.85))
		draw_circle(center, rad, Color("#EEF2F6"))
		draw_arc(center, rad, 0, TAU, 24, Color("#1E293B"), 2.0)
		draw_line(center - Vector2(rad, 0), center + Vector2(rad, 0), Color(0.2, 0.3, 0.4, 0.3), 1.0)
		draw_line(center - Vector2(0, rad), center + Vector2(0, rad), Color(0.2, 0.3, 0.4, 0.3), 1.0)
		var dot := center + spin * rad * 0.78
		draw_circle(dot, 6.0, Color("#EF4444"))
		draw_string(UITheme.get_ui_font(), Vector2(26, size.y - 4), "EFEK", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#F5C542"))

class DribbleJoystickPad extends Control:
	signal joy_changed(vec: Vector2)
	var joy_vec: Vector2 = Vector2.ZERO
	var _active: bool = false

	func reset_joy() -> void:
		_active = false
		joy_vec = Vector2.ZERO
		queue_redraw()
		joy_changed.emit(joy_vec)

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			_active = event.pressed
			if _active:
				_update_joy(event.position)
			else:
				reset_joy()
		elif event is InputEventMouseMotion and _active:
			_update_joy(event.position)

	func _update_joy(pos: Vector2) -> void:
		var center := size * 0.5
		var rad := minf(size.x, size.y) * 0.40
		var v := (pos - center) / maxf(rad, 1.0)
		if v.length() > 1.0:
			v = v.normalized()
		joy_vec = v
		queue_redraw()
		joy_changed.emit(joy_vec)

	func _draw() -> void:
		var center := size * 0.5
		var rad := minf(size.x, size.y) * 0.40
		var active_col := Color("#FACC15") if _active else Color("#38BDF8")
		# Translucent outer well + glowing eFootball / EA FC circle border
		draw_circle(center, rad + 4.0, Color(0.03, 0.08, 0.16, 0.68))
		draw_arc(center, rad + 3.0, 0.0, TAU, 36, Color(active_col.r, active_col.g, active_col.b, 0.30), 6.0)
		draw_arc(center, rad, 0.0, TAU, 36, active_col, 2.5)
		# Cardinal guidance ticks
		for d in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
			draw_line(center + d * (rad - 8.0), center + d * (rad - 2.0), Color(active_col.r, active_col.g, active_col.b, 0.65), 2.0)
		if joy_vec.length() > 0.08:
			var ang := joy_vec.angle()
			draw_arc(center, rad, ang - 0.55, ang + 0.55, 16, Color("#4ADE80"), 4.0)
		var knob := center + joy_vec * (rad - 10.0)
		draw_circle(knob, 21.0, Color(0.08, 0.16, 0.28, 0.90))
		draw_circle(knob, 17.0, active_col)
		draw_circle(knob - Vector2(4.0, 4.0), 5.0, Color(1.0, 1.0, 1.0, 0.65))
		draw_arc(knob, 18.0, 0.0, TAU, 24, Color.WHITE, 2.0)
