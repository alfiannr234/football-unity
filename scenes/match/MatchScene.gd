extends Control

signal match_completed(report: Dictionary)
signal mode_exited

enum RunMode { CAREER_MATCH, PRACTICE_MODE, DUEL_MODE, MOVIOLA_REPLAY }
enum MatchPhase { INTRO, SIMULATING, HALFTIME, ASK_SET_PIECE, KEY_MOMENT_AIM, HEADER_TIMING, QTE_DRIBBLE_DUEL, QTE_LONG_CONTROL, BALL_IN_FLIGHT, TEAMMATE_CARRY, INCOMING_PASS, THROW_IN_PREP, REBOUND_SCRAMBLE, TEAMMATE_PENALTY_WAIT, MOMENT_RESULT, COIN_FLIP, PENALTY_SHOOTOUT, FULLTIME }
enum MomentType { SHOT, PASS, DRIBBLE, FREE_KICK, PENALTY, TEAMMATE_PENALTY, TEAMMATE_PASS, THROW_IN, HEADER_CROSS, DRIBBLE_DUEL, LONG_PASS_CONTROL, CORNER_KICK, GK_BUILDUP }

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
var _our_gk_sprite: Sprite3D
var _our_gk_shadow: Sprite3D
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
var _aim_power_pill: PanelContainer
var _aim_power_pill_lbl: Label
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
var _rating_delta_lbl: Label
var _qte_overlay: ShrinkingQTEOverlay
var _exit_btn: Button
var _pause_btn: Button
var _pause_panel: Control
var _is_paused: bool = false
var _action_bar: HBoxContainer
var _action_mode_btns: Dictionary = {}
var _player_badge_lbl: Label
var _scorebug_root: Control
var _sb_comp_ring: MatchHudWidgets.CompEmblemRing
var _sb_rating_ring: MatchHudWidgets.RatingRingGauge
var _sb_home_bar: PanelContainer
var _sb_away_bar: PanelContainer
var _sb_home_crest: ClubCrest
var _sb_away_crest: ClubCrest
var _sb_home_code_lbl: Label
var _sb_away_code_lbl: Label
var _sb_min_panel: PanelContainer
var _sb_comp_ribbon_panel: PanelContainer
var _sb_comp_ribbon_lbl: Label
var _ticker_panel: PanelContainer
var _top_right_bar: HBoxContainer
var _player_card_panel: PanelContainer
var _player_card_num_lbl: Label
var _player_card_avatar: PixelAvatar
var _player_card_name_lbl: Label
var _player_card_pos_lbl: Label
var _player_card_strip: PanelContainer
var _player_card_last_key: String = ""
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
var _board_hl_portraits: HBoxContainer
var _board_hl_badge: Label
var _board_hl_name_lbl: Label
var _board_hl_action_lbl: Label
var _board_hero_card: PanelContainer
var _board_mini_stats_vb: VBoxContainer
var _hero_hl_queue: Array[Dictionary] = []
var _hero_hl_timer: float = 0.0
var _shots_us: int = 0
var _shots_them: int = 0
var _saves_us: int = 0
var _saves_them: int = 0
var _corners_us: int = 0
var _corners_them: int = 0
var _gk_buildup_count: int = 0
var _fouls_us: int = 0
var _fouls_them: int = 0
var _board_cards_bar: PanelContainer
var _board_cards_lbl: Label
var _board_sub_banner: PanelContainer
var _board_feed_vb: VBoxContainer
var _board_rating_lbl: Label
var _board_energy_bar: ColorRect
var _board_energy_lbl: Label
var _board_timeline: Control
var _board_events: Array[Dictionary] = []
var _board_paused: bool = false
var _board_bg: Control
var _board_emblem: Control
var _board_comp_lbl: Label
var _board_stad_lbl: Label
var _board_home_lbl: Label
var _board_away_lbl: Label
var _board_home_score: Label
var _board_away_score: Label
var _board_home_badge_wrap: Control
var _board_away_badge_wrap: Control
var _board_tab_btns: Array[Button] = []
var _board_views: Array[Control] = []
var _board_view_idx: int = 0
var _board_stats_vb: VBoxContainer
var _board_squad_vb: VBoxContainer
var _board_sparkline: Control
var _board_rating_hist: Array[float] = [6.2]
var _board_hold_fast: bool = false
var _board_spd_btn: Button
var _board_pause_btn: Button
var _strat_btn: Button
var _inten_btn: Button
var _lineup_panel: Control
var _lineup_timer: float = 0.0
var _halftime_panel: Control
var _halftime_done: bool = false
var _quiz_bonus_energy: bool = false
var _in_extra_time: bool = false
var _et_end_min: float = 90.0
var _pen_us: int = -1
var _pen_them: int = -1
var _invader_shown: bool = false
var _invader_panel: Control
var _coin_flip_panel: Control
var _coin_canvas: Control
var _coin_status_lbl: Label
var _coin_go_btn: Button
var _coin_choice_btns: Array[Button] = []
var _coin_choice: String = "ANGKA"
var _coin_result: String = "GAMBAR"
var _coin_winner_us: bool = true
var _coin_anim_t: float = 0.0
var _coin_spinning: bool = false
var _pso_panel: Control
var _pso_score_lbl: Label
var _pso_status_lbl: Label
var _pso_row_us: HBoxContainer
var _pso_row_them: HBoxContainer
var _pso_btn_row: HBoxContainer
var _pso_done_btn: Button
var _pso_us_kicks: Array[String] = []
var _pso_them_kicks: Array[String] = []
var _pso_round: int = 1
var _pso_user_first: bool = true
var _pso_turn_us: bool = true
var _pso_waiting_kick: bool = false
var _ask_panel: Control
var _pending_ask_type: MomentType = MomentType.FREE_KICK
var _sim_event_timer: float = 0.0
var _our_lineup: Array[Dictionary] = []
var _opp_lineup: Array[Dictionary] = []
var _our_bench: Array[Dictionary] = []
var _opp_bench: Array[Dictionary] = []
var _our_yellows: int = 0
var _our_reds: int = 0
var _opp_yellows: int = 0
var _opp_reds: int = 0
var _active_injuries: Array[Dictionary] = []
var _total_injuries_match: int = 0
var _last_card_min: float = -20.0
var _last_injury_min: float = -25.0
var _user_match_energy: float = 100.0
var _match_extra_energy_drain: float = 0.0
var _user_subbed_out: bool = false
var _user_sub_minute: int = -1

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
var _defender_slide_timers: Array[float] = []
var _defender_slide_dirs: Array[Vector3] = []
var _defender_slid_this_kick: Array[bool] = []
var _teammate_positions: Array[Vector3] = []
var _teammate_vels: Array[Vector3] = []
var _teammate_targets: Array[Vector3] = []
var _teammate_open_scores: Array[float] = []
var _rebound_grace: float = 0.0
var _rebound_timer: float = 0.0
var _shot_by_teammate: bool = false
var _post_rebound_eligible: bool = false
var _scramble_from_penalty_rebound: bool = false
var _tm_penalty_timer: float = 0.0
var _tm_penalty_kicked: bool = false
var _throw_in_side: float = 1.0
var _throw_in_z: float = -24.0
var _throw_in_timer: float = 0.0
var _throw_in_duration: float = 2.4
var _throw_in_thrown: bool = false
var _throw_in_flight_t: float = 0.0
var _throw_in_flight_dur: float = 0.72
var _throw_in_start_pos: Vector3 = Vector3.ZERO
var _throw_in_target_pos: Vector3 = Vector3.ZERO
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
var _goal_candidates: Array[Dictionary] = []
var _acrobatic_ready_style: String = ""
var _acrobatic_anim_style: String = ""
var _acrobatic_anim_timer: float = 0.0
var _acrobatic_anim_dur: float = 0.60
var _last_shot_style: String = "AKSI SOLO"
var _shot_on_target_credit: bool = false
var _key_pass_awarded: bool = false
var _qte_progress: float = 0.0
var _qte_duration: float = 1.35
var _qte_perfect_tol: float = 0.12
var _qte_good_tol: float = 0.24
var _qte_label: String = ""
var _qte_resolved: bool = false
var _cross_start: Vector3 = Vector3.ZERO
var _cross_target: Vector3 = Vector3.ZERO
var _cross_peak_y: float = 5.2
var _cross_passer_idx: int = 0
var _header_aim_vel: Vector3 = Vector3.ZERO
var _header_aim_omega: Vector3 = Vector3.ZERO
var _duel_player_start: Vector3 = Vector3.ZERO
var _duel_def_start: Vector3 = Vector3.ZERO
var _best_pass_openness: float = 0.0
var _our_gk_pos: Vector3 = Vector3(0.0, 0.0, 48.8)
var _controlling_teammate_idx: int = -1
var _user_assisted_pass: bool = false
var _user_hockey_assist_eligible: bool = false
var _scramble_is_loose_pass: bool = false
var _incoming_pass_is_our_gk: bool = false
var _corner_taker_is_user: bool = false
var _corner_side: float = 1.0
var _last_pass_state: String = ""
var _pending_foul_moment: int = -1
var _pending_foul_spot: Vector3 = Vector3.ZERO
var _dribble_tackle_grace: float = 0.0
var _last_kick_power_ratio: float = 0.0
var _celebrating_goal: bool = false
var _celebration_t: float = 0.0
var _celebration_origin: Vector3 = Vector3.ZERO
var _celebration_confetti: Control
var _celebration_particles: Array[Dictionary] = []
var _goal_popup_panel: PanelContainer
var _goal_replay_active: bool = false
var _goal_replay_delay: float = 0.0
var _goal_replay_frames: Array = []
var _goal_replay_idx: int = 0
var _goal_replay_accum: float = 0.0
var _goal_replay_snapped_cam: bool = false
var _goal_replay_banner: PanelContainer
var _pending_celeb_info: Dictionary = {}
var _last_live_ticker_txt: String = "PERTANDINGAN BERLANGSUNG SEIMBANG"

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
	_our_gk_sprite = _make_character_sprite(_tex_keeper, true)
	_our_gk_sprite.modulate = Color(1.0, 0.92, 0.52)
	_our_gk_shadow = _make_shadow_sprite(0.85)

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
	# =========================================================================
	# 1. TOP-CENTER BROADCAST SCOREBUG (Gambar 1: Emblem + Club + White Score + Club + Rating Ring + B1/B2 Min + Comp Ribbon)
	# =========================================================================
	_scorebug_root = Control.new()
	_scorebug_root.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_scorebug_root.offset_left = -226
	_scorebug_root.offset_right = 226
	_scorebug_root.offset_top = 4
	_scorebug_root.offset_bottom = 84
	_scorebug_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_scorebug_root)

	var sb_vb := VBoxContainer.new()
	sb_vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	sb_vb.alignment = BoxContainer.ALIGNMENT_BEGIN
	sb_vb.add_theme_constant_override("separation", 2)
	sb_vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scorebug_root.add_child(sb_vb)

	var main_hb := HBoxContainer.new()
	main_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	main_hb.add_theme_constant_override("separation", 0)
	main_hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sb_vb.add_child(main_hb)

	# Left Circular Competition Emblem
	_sb_comp_ring = MatchHudWidgets.CompEmblemRing.new()
	_sb_comp_ring.custom_minimum_size = Vector2(40, 40)
	main_hb.add_child(_sb_comp_ring)

	# Home Team Bar (Crest + 3-letter Code)
	_sb_home_bar = PanelContainer.new()
	_sb_home_bar.custom_minimum_size = Vector2(106, 32)
	_sb_home_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_sb_home_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hb_sb := StyleBoxFlat.new()
	hb_sb.bg_color = Color("#1B3654", 0.94)
	hb_sb.border_color = Color("#7DD3FC", 0.65)
	hb_sb.border_width_top = 1
	hb_sb.border_width_bottom = 1
	hb_sb.content_margin_left = 8
	hb_sb.content_margin_right = 8
	_sb_home_bar.add_theme_stylebox_override("panel", hb_sb)
	main_hb.add_child(_sb_home_bar)

	var home_in := HBoxContainer.new()
	home_in.alignment = BoxContainer.ALIGNMENT_CENTER
	home_in.add_theme_constant_override("separation", 6)
	home_in.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sb_home_bar.add_child(home_in)
	_sb_home_crest = ClubCrest.new()
	_sb_home_crest.custom_minimum_size = Vector2(22, 22)
	_sb_home_crest.mouse_filter = Control.MOUSE_FILTER_IGNORE
	home_in.add_child(_sb_home_crest)
	_sb_home_code_lbl = Label.new()
	_sb_home_code_lbl.text = "PBO"
	_sb_home_code_lbl.add_theme_font_override("font", UITheme.get_display_font())
	_sb_home_code_lbl.add_theme_font_size_override("font_size", 15)
	_sb_home_code_lbl.add_theme_color_override("font_color", Color("#F8FAFC"))
	home_in.add_child(_sb_home_code_lbl)

	# Crisp Bright White Center Score Box (Gambar 1: 0 - 0!)
	var score_box := PanelContainer.new()
	score_box.custom_minimum_size = Vector2(74, 34)
	score_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	score_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sc_sb := StyleBoxFlat.new()
	sc_sb.bg_color = Color("#F5F8FC")
	sc_sb.border_color = Color("#CBD5E1")
	sc_sb.set_border_width_all(1)
	sc_sb.content_margin_left = 6
	sc_sb.content_margin_right = 6
	score_box.add_theme_stylebox_override("panel", sc_sb)
	main_hb.add_child(score_box)

	_score_lbl = Label.new()
	_score_lbl.text = "0 - 0"
	_score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_score_lbl.add_theme_font_override("font", UITheme.get_display_font())
	_score_lbl.add_theme_font_size_override("font_size", 20)
	_score_lbl.add_theme_color_override("font_color", Color("#0B1320"))
	score_box.add_child(_score_lbl)

	# Away Team Bar (3-letter Code + Crest)
	_sb_away_bar = PanelContainer.new()
	_sb_away_bar.custom_minimum_size = Vector2(106, 32)
	_sb_away_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_sb_away_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ab_sb: StyleBoxFlat = hb_sb.duplicate()
	ab_sb.bg_color = Color("#1B4970", 0.94)
	_sb_away_bar.add_theme_stylebox_override("panel", ab_sb)
	main_hb.add_child(_sb_away_bar)

	var away_in := HBoxContainer.new()
	away_in.alignment = BoxContainer.ALIGNMENT_CENTER
	away_in.add_theme_constant_override("separation", 6)
	away_in.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sb_away_bar.add_child(away_in)
	_sb_away_code_lbl = Label.new()
	_sb_away_code_lbl.text = "DSI"
	_sb_away_code_lbl.add_theme_font_override("font", UITheme.get_display_font())
	_sb_away_code_lbl.add_theme_font_size_override("font_size", 15)
	_sb_away_code_lbl.add_theme_color_override("font_color", Color("#F8FAFC"))
	away_in.add_child(_sb_away_code_lbl)
	_sb_away_crest = ClubCrest.new()
	_sb_away_crest.custom_minimum_size = Vector2(22, 22)
	_sb_away_crest.mouse_filter = Control.MOUSE_FILTER_IGNORE
	away_in.add_child(_sb_away_crest)

	# Right Circular Live Match Rating Gauge (Gambar 1: 6,4!)
	_sb_rating_ring = MatchHudWidgets.RatingRingGauge.new()
	_sb_rating_ring.custom_minimum_size = Vector2(40, 40)
	main_hb.add_child(_sb_rating_ring)

	# Half + Minute Pill right under Score Box (B1 13' / B2 56')
	var min_cc := CenterContainer.new()
	min_cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sb_vb.add_child(min_cc)
	_sb_min_panel = PanelContainer.new()
	_sb_min_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m_sb := StyleBoxFlat.new()
	m_sb.bg_color = Color("#132338", 0.94)
	m_sb.border_color = Color("#5BB2E8", 0.72)
	m_sb.set_border_width_all(1)
	m_sb.set_corner_radius_all(3)
	m_sb.content_margin_left = 10
	m_sb.content_margin_right = 10
	m_sb.content_margin_top = 1
	m_sb.content_margin_bottom = 1
	_sb_min_panel.add_theme_stylebox_override("panel", m_sb)
	min_cc.add_child(_sb_min_panel)

	_minute_lbl = Label.new()
	_minute_lbl.text = "B1 1'"
	_minute_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_minute_lbl.add_theme_font_override("font", UITheme.get_display_font())
	_minute_lbl.add_theme_color_override("font_color", Color("#F8FAFC"))
	_minute_lbl.add_theme_font_size_override("font_size", 12)
	_sb_min_panel.add_child(_minute_lbl)

	# Competition & Week Ribbon right underneath Half/Minute pill
	var rib_cc := CenterContainer.new()
	rib_cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sb_vb.add_child(rib_cc)
	_sb_comp_ribbon_panel = PanelContainer.new()
	_sb_comp_ribbon_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var r_sb := StyleBoxFlat.new()
	r_sb.bg_color = Color("#1E4B72", 0.92)
	r_sb.set_corner_radius_all(2)
	r_sb.content_margin_left = 12
	r_sb.content_margin_right = 12
	r_sb.content_margin_top = 1
	r_sb.content_margin_bottom = 1
	_sb_comp_ribbon_panel.add_theme_stylebox_override("panel", r_sb)
	rib_cc.add_child(_sb_comp_ribbon_panel)

	_sb_comp_ribbon_lbl = Label.new()
	_sb_comp_ribbon_lbl.text = "LIGA KE-3  •  PEKAN 1"
	_sb_comp_ribbon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sb_comp_ribbon_lbl.add_theme_font_override("font", UITheme.get_display_font())
	_sb_comp_ribbon_lbl.add_theme_font_size_override("font_size", 9)
	_sb_comp_ribbon_lbl.add_theme_color_override("font_color", Color("#E2F2FF"))
	_sb_comp_ribbon_panel.add_child(_sb_comp_ribbon_lbl)

	# Top-Right Compact Controls (1X, SKIP, and iconic square dark II Pause button!)
	_top_right_bar = HBoxContainer.new()
	_top_right_bar.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_top_right_bar.offset_left = -172
	_top_right_bar.offset_right = -10
	_top_right_bar.offset_top = 8
	_top_right_bar.offset_bottom = 46
	_top_right_bar.alignment = BoxContainer.ALIGNMENT_END
	_top_right_bar.add_theme_constant_override("separation", 6)
	add_child(_top_right_bar)

	_speed_btn = Button.new()
	_speed_btn.text = "1X"
	_speed_btn.custom_minimum_size = Vector2(44, 34)
	UITheme.style_btn(_speed_btn, Color("#11233A"), UITheme.BORDER_CYAN, 11)
	_speed_btn.pressed.connect(_on_toggle_speed)
	_top_right_bar.add_child(_speed_btn)

	_exit_btn = Button.new()
	_exit_btn.text = "SKIP"
	_exit_btn.custom_minimum_size = Vector2(52, 34)
	UITheme.style_btn(_exit_btn, Color("#4A1E24"), UITheme.ACCENT_RED, 11)
	_exit_btn.pressed.connect(_on_skip_or_exit)
	_top_right_bar.add_child(_exit_btn)

	_pause_btn = Button.new()
	_pause_btn.text = "II"
	_pause_btn.custom_minimum_size = Vector2(38, 36)
	UITheme.style_btn(_pause_btn, Color("#0A101B"), Color("#3B5578"), 14)
	_pause_btn.pressed.connect(func(): AudioSynth.play_click(); _open_pause_menu())
	_top_right_bar.add_child(_pause_btn)

	# Commentary Ticker Strip (Sleek centered pill right under scorebug ribbon like Gambar 1!)
	_ticker_panel = PanelContainer.new()
	_ticker_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_ticker_panel.offset_left = -224
	_ticker_panel.offset_right = 224
	_ticker_panel.offset_top = 86
	_ticker_panel.offset_bottom = 110
	_ticker_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ticker_panel.add_theme_stylebox_override("panel", UITheme.make_box(Color(0.04, 0.07, 0.13, 0.86), Color("#2A4160"), 1, 5))
	add_child(_ticker_panel)

	_ticker_lbl = Label.new()
	_ticker_lbl.text = "Kickoff! Peluang emas menantimu di lapangan."
	_ticker_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ticker_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_ticker_lbl.clip_text = true
	_ticker_lbl.add_theme_font_size_override("font_size", 11)
	_ticker_lbl.add_theme_color_override("font_color", Color("#F1F5F9"))
	_ticker_panel.add_child(_ticker_lbl)

	# Key Moment Prompt Banner (compact centered right below ticker)
	_moment_banner = PanelContainer.new()
	_moment_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_moment_banner.offset_left = -210
	_moment_banner.offset_right = 210
	_moment_banner.offset_top = 114
	_moment_banner.offset_bottom = 160
	_moment_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_moment_banner.add_theme_stylebox_override("panel", UITheme.make_box(Color(0.05, 0.11, 0.22, 0.88), UITheme.ACCENT_GOLD, 1, 5))
	_moment_banner.visible = false
	add_child(_moment_banner)

	var mb_vb := VBoxContainer.new()
	mb_vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mb_vb.add_theme_constant_override("separation", 1)
	_moment_banner.add_child(mb_vb)
	_moment_title_lbl = Label.new()
	_moment_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_moment_title_lbl.add_theme_font_override("font", UITheme.get_display_font())
	_moment_title_lbl.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	_moment_title_lbl.add_theme_font_size_override("font_size", 14)
	mb_vb.add_child(_moment_title_lbl)

	_moment_sub_lbl = Label.new()
	_moment_sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_moment_sub_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_moment_sub_lbl.add_theme_font_size_override("font_size", 10)
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

	# Confetti particle layer & animated Goal Scorer Pop-Up Banner (3D pitch celebrations)
	_celebration_confetti = Control.new()
	_celebration_confetti.set_anchors_preset(Control.PRESET_FULL_RECT)
	_celebration_confetti.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_celebration_confetti.visible = false
	_celebration_confetti.draw.connect(_draw_celebration_confetti)
	add_child(_celebration_confetti)

	_goal_popup_panel = PanelContainer.new()
	_goal_popup_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_goal_popup_panel.offset_left = -220
	_goal_popup_panel.offset_right = 220
	_goal_popup_panel.offset_top = -142
	_goal_popup_panel.offset_bottom = -28
	_goal_popup_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_goal_popup_panel.visible = false
	_goal_popup_panel.add_theme_stylebox_override("panel", UITheme.make_box(Color("#091426", 0.96), UITheme.ACCENT_GOLD, 2, 8))
	add_child(_goal_popup_panel)

	# Instant Goal Replay Top Broadcast Pill (Behind Opponent GK POV)
	_goal_replay_banner = PanelContainer.new()
	_goal_replay_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_goal_replay_banner.offset_left = -188
	_goal_replay_banner.offset_right = 188
	_goal_replay_banner.offset_top = 60
	_goal_replay_banner.offset_bottom = 90
	_goal_replay_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_goal_replay_banner.visible = false
	_goal_replay_banner.add_theme_stylebox_override("panel", UITheme.make_box(Color("#081224", 0.94), Color("#DC2645"), 2, 6))
	add_child(_goal_replay_banner)
	var gr_lbl := Label.new()
	gr_lbl.text = "● TAYANGAN ULANG  •  BELAKANG GAWANG"
	gr_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gr_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	gr_lbl.add_theme_font_override("font", UITheme.get_display_font())
	gr_lbl.add_theme_font_size_override("font_size", 11)
	gr_lbl.add_theme_color_override("font_color", Color("#FB7185"))
	_goal_replay_banner.add_child(gr_lbl)

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

	# Bottom-Left Controlled Player Broadcast Card (Gambar 1: White Number Box + Portrait + REAL Player/Teammate Name!)
	_player_card_panel = PanelContainer.new()
	_player_card_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_player_card_panel.offset_left = 18
	_player_card_panel.offset_top = -226
	_player_card_panel.offset_right = 246
	_player_card_panel.offset_bottom = -182
	_player_card_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_player_card_panel.visible = false
	var pc_sb := StyleBoxFlat.new()
	pc_sb.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	_player_card_panel.add_theme_stylebox_override("panel", pc_sb)
	add_child(_player_card_panel)

	var pc_hb := HBoxContainer.new()
	pc_hb.add_theme_constant_override("separation", 0)
	pc_hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_player_card_panel.add_child(pc_hb)

	# Left White Shirt Number Square (exact Gambar 1: [29]!)
	var num_box := PanelContainer.new()
	num_box.custom_minimum_size = Vector2(44, 40)
	num_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var nb_sb := StyleBoxFlat.new()
	nb_sb.bg_color = Color("#F5F8FC")
	nb_sb.border_color = Color("#CBD5E1")
	nb_sb.set_border_width_all(1)
	nb_sb.corner_radius_top_left = 6
	nb_sb.corner_radius_bottom_left = 6
	num_box.add_theme_stylebox_override("panel", nb_sb)
	pc_hb.add_child(num_box)

	_player_card_num_lbl = Label.new()
	_player_card_num_lbl.text = "9"
	_player_card_num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_player_card_num_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_player_card_num_lbl.add_theme_font_override("font", UITheme.get_display_font())
	_player_card_num_lbl.add_theme_font_size_override("font_size", 18)
	_player_card_num_lbl.add_theme_color_override("font_color", Color("#0C1322"))
	num_box.add_child(_player_card_num_lbl)

	# Right Club-Tinted Nameplate (Portrait + Real Name + Position)
	_player_card_strip = PanelContainer.new()
	_player_card_strip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_player_card_strip.custom_minimum_size = Vector2(174, 40)
	_player_card_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ps_sb := StyleBoxFlat.new()
	ps_sb.bg_color = Color("#132842", 0.90)
	ps_sb.border_color = Color("#5BB2E8", 0.65)
	ps_sb.border_width_top = 1
	ps_sb.border_width_bottom = 1
	ps_sb.border_width_right = 1
	ps_sb.corner_radius_top_right = 6
	ps_sb.corner_radius_bottom_right = 6
	ps_sb.content_margin_left = 6
	ps_sb.content_margin_right = 8
	ps_sb.content_margin_top = 2
	ps_sb.content_margin_bottom = 2
	_player_card_strip.add_theme_stylebox_override("panel", ps_sb)
	pc_hb.add_child(_player_card_strip)

	var strip_hb := HBoxContainer.new()
	strip_hb.alignment = BoxContainer.ALIGNMENT_BEGIN
	strip_hb.add_theme_constant_override("separation", 6)
	strip_hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_player_card_strip.add_child(strip_hb)

	_player_card_avatar = PixelAvatar.new()
	_player_card_avatar.full_body = false
	_player_card_avatar.custom_minimum_size = Vector2(30, 32)
	_player_card_avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip_hb.add_child(_player_card_avatar)

	var nm_vb := VBoxContainer.new()
	nm_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nm_vb.alignment = BoxContainer.ALIGNMENT_CENTER
	nm_vb.add_theme_constant_override("separation", 0)
	nm_vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip_hb.add_child(nm_vb)

	_player_card_name_lbl = Label.new()
	_player_card_name_lbl.text = "PEMAIN"
	_player_card_name_lbl.clip_text = true
	_player_card_name_lbl.add_theme_font_override("font", UITheme.get_display_font())
	_player_card_name_lbl.add_theme_font_size_override("font_size", 13)
	_player_card_name_lbl.add_theme_color_override("font_color", Color("#FFFFFF"))
	nm_vb.add_child(_player_card_name_lbl)

	_player_card_pos_lbl = Label.new()
	_player_card_pos_lbl.text = "ST"
	_player_card_pos_lbl.add_theme_font_override("font", UITheme.get_display_font())
	_player_card_pos_lbl.add_theme_font_size_override("font_size", 9)
	_player_card_pos_lbl.add_theme_color_override("font_color", Color("#93C5FD"))
	nm_vb.add_child(_player_card_pos_lbl)

	# Keep _player_badge_lbl alias synced cleanly for compatibility (hidden because _player_card_panel replaces it!)
	_player_badge_lbl = Label.new()
	_player_badge_lbl.visible = false
	_player_badge_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
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

	_aim_power_pill = PanelContainer.new()
	_aim_power_pill.visible = false
	_aim_power_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_aim_power_pill.add_theme_stylebox_override("panel", UITheme.make_box(Color("#081326E8"), UITheme.ACCENT_GOLD, 2, 6))
	add_child(_aim_power_pill)
	_aim_power_pill_lbl = Label.new()
	_aim_power_pill_lbl.text = "50%"
	_aim_power_pill_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aim_power_pill_lbl.add_theme_font_override("font", UITheme.get_display_font())
	_aim_power_pill_lbl.add_theme_font_size_override("font_size", 14)
	_aim_power_pill.add_child(_aim_power_pill_lbl)

	# Spin / Strike Angle Touch Ball at Bottom-Right (bottom half = loft / lambung)
	_spin_pad = SpinBallPad.new()
	_spin_pad.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_spin_pad.offset_left = -114
	_spin_pad.offset_top = -134
	_spin_pad.offset_right = -16
	_spin_pad.offset_bottom = -20
	_spin_pad.spin_changed.connect(func(sp: Vector2):
		_spin_offset = sp
		if _dragging:
			_draw_aim_and_ring()
	)
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

	# Live Rating Delta Sub-Badge right beneath Outcome Toast (+0.1 / +0.2 / -0.3)
	_rating_delta_lbl = Label.new()
	_rating_delta_lbl.set_anchors_preset(Control.PRESET_CENTER)
	_rating_delta_lbl.offset_left = -220
	_rating_delta_lbl.offset_right = 220
	_rating_delta_lbl.offset_top = 34
	_rating_delta_lbl.offset_bottom = 66
	_rating_delta_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rating_delta_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_rating_delta_lbl.add_theme_font_override("font", UITheme.get_display_font())
	_rating_delta_lbl.add_theme_font_size_override("font_size", 16)
	_rating_delta_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	_rating_delta_lbl.add_theme_constant_override("outline_size", 4)
	_rating_delta_lbl.visible = false
	add_child(_rating_delta_lbl)

	# Shrinking Circle Quick-Time-Event Overlay (Header Timing, 1v1 Dribble Duel, Long Pass Control)
	_qte_overlay = ShrinkingQTEOverlay.new()
	_qte_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_qte_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_qte_overlay.visible = false
	add_child(_qte_overlay)

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
	_goal_candidates.clear()
	_acrobatic_ready_style = ""
	_acrobatic_anim_style = ""
	_acrobatic_anim_timer = 0.0
	_last_shot_style = "AKSI SOLO"
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
	_minute = 1.0
	_sim_speed = 1.0
	_speed_btn.text = "1X"
	_sync_broadcast_scorebug()
	_apply_control_layout_settings()

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
	_quiz_bonus_energy = false
	_in_extra_time = false
	_et_end_min = 90.0
	_pen_us = -1
	_pen_them = -1
	_invader_shown = false
	_pending_foul_moment = -1
	_pending_foul_spot = Vector3.ZERO
	_dribble_tackle_grace = 0.0
	_board_hold_fast = false
	_board_view_idx = 0
	_board_rating_hist = [6.2]
	_board_events.clear()
	_hero_hl_queue.clear()
	_hero_hl_timer = 0.0
	_shots_us = 0
	_shots_them = 0
	_saves_us = 0
	_saves_them = 0
	_corners_us = 0
	_corners_them = 0
	_gk_buildup_count = 0
	_fouls_us = 0
	_fouls_them = 0
	_board_paused = false
	_our_yellows = 0
	_our_reds = 0
	_opp_yellows = 0
	_opp_reds = 0
	_active_injuries.clear()
	_total_injuries_match = 0
	_last_card_min = -20.0
	_last_injury_min = -25.0
	_user_match_energy = float(CareerState.career["playerProfile"].get("energy", 100))
	_match_extra_energy_drain = 0.0
	_user_subbed_out = false
	_user_sub_minute = -1
	_init_match_rosters()
	if _board_panel != null:
		_board_panel.visible = false
		_refresh_board_header_identities()
		_switch_board_tab(0)
	if _coin_flip_panel != null:
		_coin_flip_panel.visible = false
	if _pso_panel != null:
		_pso_panel.visible = false
	if _invader_panel != null:
		_invader_panel.visible = false
	if _board_sub_banner != null:
		_board_sub_banner.visible = false
	if _board_cards_bar != null:
		_board_cards_bar.visible = false
	if _board_feed_vb != null:
		while _board_feed_vb.get_child_count() > 0:
			var fc: Node = _board_feed_vb.get_child(0)
			_board_feed_vb.remove_child(fc)
			fc.queue_free()
	_spin_pad.visible = false
	_power_lbl.visible = false
	_phase = MatchPhase.INTRO
	_open_lineup_intro()

func _process(delta: float) -> void:
	if _scorebug_root != null:
		var hide_3d_hud: bool = (_board_panel != null and _board_panel.visible) or _phase == MatchPhase.INTRO
		_scorebug_root.visible = not hide_3d_hud
		if _ticker_panel != null:
			_ticker_panel.visible = not hide_3d_hud and run_mode != RunMode.MOVIOLA_REPLAY
		if _top_right_bar != null:
			_top_right_bar.visible = not hide_3d_hud
	if _is_paused:
		return
	if run_mode == RunMode.MOVIOLA_REPLAY:
		_process_moviola_replay(delta)
		return

	_anim_clock += delta
	if _acrobatic_anim_timer > 0.0:
		_acrobatic_anim_timer = maxf(0.0, _acrobatic_anim_timer - delta)
	_update_camera(delta)

	match _phase:
		MatchPhase.INTRO:
			_lineup_timer += delta
			if _lineup_timer >= 4.6:
				_start_match_kickoff()
		MatchPhase.SIMULATING:
			_process_simulation(delta)
		MatchPhase.KEY_MOMENT_AIM:
			_animate_gk_idle(delta)
			_animate_teammates(delta)
			if _moment_type in [MomentType.SHOT, MomentType.PASS, MomentType.DRIBBLE]:
				_process_dribble_control(delta)
				if _acrobatic_ready_style != "":
					if _dribble_input.length() > 0.25:
						_acrobatic_ready_style = ""
						_ball_pos.y = 0.115
					else:
						var base_y: float = 1.48 if _acrobatic_ready_style == "SALTO" else 1.02
						_ball_pos.y = base_y + sin(_anim_clock * 7.5) * 0.10
						_sync_3d_sprites()
			_update_pass_openness_ui()
			_draw_aim_and_ring()
		MatchPhase.HEADER_TIMING:
			_process_header_timing(delta)
		MatchPhase.QTE_DRIBBLE_DUEL:
			_process_qte_dribble_duel(delta)
		MatchPhase.QTE_LONG_CONTROL:
			_process_qte_long_control(delta)
		MatchPhase.TEAMMATE_PENALTY_WAIT:
			_process_teammate_penalty_wait(delta)
		MatchPhase.BALL_IN_FLIGHT:
			_process_ball_flight(delta)
		MatchPhase.TEAMMATE_CARRY:
			_process_teammate_carry(delta)
		MatchPhase.INCOMING_PASS:
			_process_incoming_pass(delta)
		MatchPhase.THROW_IN_PREP:
			_process_throw_in_prep(delta)
		MatchPhase.REBOUND_SCRAMBLE:
			_process_rebound_scramble(delta)
		MatchPhase.MOMENT_RESULT:
			if _goal_replay_active:
				_process_goal_replay(delta)
			else:
				if _celebrating_goal:
					_process_goal_celebration(delta)
				_result_timer -= delta
				if _result_timer <= 0.0:
					_stop_goal_celebration()
					_result_toast.visible = false
					if _rating_delta_lbl != null:
						_rating_delta_lbl.visible = false
					_advance_after_moment()
		MatchPhase.COIN_FLIP:
			if _coin_spinning and _coin_canvas != null:
				_coin_anim_t += delta
				_coin_canvas.queue_redraw()
				if _coin_anim_t >= 1.35:
					_finish_coin_spin()

func _is_current_knockout_match() -> bool:
	if run_mode != RunMode.CAREER_MATCH or not CareerState.has_active_career:
		return false
	var fix := CareerState.get_current_fixture()
	if bool(fix.get("is_knockout", false)):
		return true
	var st_lbl := str(fix.get("stage", ""))
	if st_lbl in ["8 BESAR", "SEMI FINAL", "FINAL", "16 BESAR", "32 BESAR", "BABAK 1"]:
		return true
	var comp := str(fix.get("comp", ""))
	return comp in ["PIALA", "TURNAMEN_ASIA", "PIALA_DUNIA_KLUB", "PIALA_SUPER_EROPA"]

func _process_simulation(delta: float) -> void:
	if _board_paused:
		return
	if _hero_hl_timer > 0.0:
		_hero_hl_timer -= delta
	if _hero_hl_timer <= 0.0 and not _hero_hl_queue.is_empty():
		var next_hl: Dictionary = _hero_hl_queue.pop_front()
		_display_hero_highlight(next_hl)
		if bool(next_hl.get("log_feed", false)):
			_append_small_feed_row(int(next_hl.get("min", 0)), str(next_hl.get("kind", "ASSIST")), str(next_hl.get("feed_txt", "")), next_hl.get("accent", UITheme.ACCENT_CYAN), bool(next_hl.get("is_us", true)), true)
		_hero_hl_timer = 1.25
	var eff_speed: float = 4.5 if _board_hold_fast else _sim_speed
	var min_step: float = delta * 6.5 * eff_speed
	_minute += min_step
	_sync_broadcast_scorebug()

	# 20% faster in-match Energy drain while user is on the pitch (scaled by Intensity & Fisik)
	if run_mode == RunMode.CAREER_MATCH and not _user_subbed_out:
		var inten: String = str(CareerState.career.get("careerMeta", {}).get("intensity", "SEDANG")) if CareerState.has_active_career else "SEDANG"
		var inten_mult: float = 1.25 if inten == "TINGGI" else (0.85 if inten == "RENDAH" else 1.0)
		var fis_attr: int = CareerState.get_effective_attribute("fisik") if CareerState.has_active_career else 65
		var fis_mult: float = lerpf(1.18, 0.78, clampf(float(fis_attr) / 99.0, 0.0, 1.0))
		_user_match_energy = maxf(0.0, _user_match_energy - min_step * 0.24 * inten_mult * fis_mult)

	# Halftime Locker Room Stoppage at 45' (CAREER_MATCH)
	if run_mode == RunMode.CAREER_MATCH and _minute >= 45.0 and not _halftime_done:
		_halftime_done = true
		_open_halftime_locker()
		return

	# Process active injured players (return in random time, or coach sub if >10 min!)
	_process_active_injuries()
	# Coach checks whether to substitute user for low energy or poor performance
	_check_coach_user_substitution()

	# Gentle tactical pan over pitch during sim
	var pan_z := lerpf(15.0, -35.0, 0.5 + 0.5 * sin(_minute * 0.25))
	_cam_target_pos = Vector3(14.0 * cos(_minute * 0.15), 14.0, pan_z + 18.0)
	_cam_look_pos = Vector3(0.0, 0.5, pan_z)
	_player_pos = Vector3(sin(_minute * 0.2) * 8.0, 0.0, pan_z)
	_ball_pos = _player_pos + Vector3(0.0, 0.115, -1.2)
	_sync_3d_sprites()

	# Rich Live Commentary & Highlight Events on 2D Crimson Match Board
	_sim_event_timer += delta * _sim_speed
	if _sim_event_timer >= 0.95:
		_sim_event_timer = 0.0
		_push_random_sim_event()

	# Random AI match goals between user moments (with real scorer + optional assister portraits!)
	if randf() < delta * 0.14 * _sim_speed:
		var club := CareerState.get_current_club()
		var fix := CareerState.get_current_fixture()
		var diff := float(int(club["ovr"]) - int(fix["opp_ovr"])) * 0.015
		if randf() < 0.45 + diff:
			_score_us += 1
			var scorer_p: Dictionary = _pick_roster_player(true, false, true)
			var ast_p: Dictionary = _pick_roster_player(true, false, false, str(scorer_p.get("name", ""))) if randf() < 0.72 else {}
			var sc_name: String = str(scorer_p.get("name", "REKAN")).to_upper()
			var ast_name: String = str(ast_p.get("name", "")).to_upper() if not ast_p.is_empty() else ""
			_goal_timeline.append({"minute": int(_minute), "scorer": sc_name, "assist": ast_name, "is_us": true, "is_user_involved": false})
			var msg_u: String = "%d' GOL %s%s! (%s)" % [int(_minute), sc_name, (" • AST %s" % ast_name if not ast_name.is_empty() else ""), club["code"]]
			_ticker_lbl.text = msg_u
			_add_rich_board_highlight(int(_minute), "GOAL", "GOL! %s" % sc_name, ("Assist: %s (%s)" % [ast_name, club["code"]] if not ast_name.is_empty() else "Gol solo %s!" % club["code"]), scorer_p, ast_p, true)
		else:
			_score_them += 1
			var opp_sc: Dictionary = _pick_roster_player(false, false, true)
			var opp_ast: Dictionary = _pick_roster_player(false, false, false, str(opp_sc.get("name", ""))) if randf() < 0.65 else {}
			var osc_name: String = str(opp_sc.get("name", "LAWAN")).to_upper()
			var oast_name: String = str(opp_ast.get("name", "")).to_upper() if not opp_ast.is_empty() else ""
			_goal_timeline.append({"minute": int(_minute), "scorer": osc_name, "assist": oast_name, "is_us": false, "is_user_involved": false})
			var msg_t: String = "%d' GOL %s (%s)%s" % [int(_minute), osc_name, fix["opp_code"], (" • AST %s" % oast_name if not oast_name.is_empty() else "")]
			_ticker_lbl.text = msg_t
			_add_rich_board_highlight(int(_minute), "OPP_GOAL", "GOL LAWAN: %s" % osc_name, ("Assist: %s (%s)" % [oast_name, fix["opp_code"]] if not oast_name.is_empty() else "Gol %s!" % fix["opp_code"]), opp_sc, opp_ast, false)
		_update_score_label()

	# Mid-match Final Pitch Invader event (New 6 detail)
	if run_mode == RunMode.CAREER_MATCH and not _invader_shown and _minute >= 62.0 and _minute <= 72.0:
		var fx_inv := CareerState.get_current_fixture()
		if str(fx_inv.get("stage", "")) == "FINAL" and randf() < delta * 0.25:
			_invader_shown = true
			_open_pitch_invader_popup()
			return

	_sync_board_hud()

	if not _user_subbed_out and _next_moment_idx < _key_moment_minutes.size() and int(_minute) >= _key_moment_minutes[_next_moment_idx]:
		_next_moment_idx += 1
		var r := randf()
		var m_type := MomentType.SHOT
		if r < 0.03 and _gk_buildup_count < 1:
			m_type = MomentType.GK_BUILDUP
			_gk_buildup_count += 1
		elif r < 0.14:
			m_type = MomentType.THROW_IN
		elif r < 0.27:
			m_type = MomentType.CORNER_KICK
		elif r < 0.37:
			m_type = MomentType.HEADER_CROSS
		elif r < 0.47:
			m_type = MomentType.DRIBBLE_DUEL
		elif r < 0.56:
			m_type = MomentType.LONG_PASS_CONTROL
		elif r < 0.65:
			m_type = MomentType.TEAMMATE_PASS
		elif r < 0.76:
			m_type = MomentType.SHOT
		elif r < 0.85:
			m_type = MomentType.PASS
		elif r < 0.92:
			m_type = MomentType.FREE_KICK
		else:
			m_type = MomentType.PENALTY
		if _board_panel != null:
			_board_panel.visible = false
		if run_mode == RunMode.CAREER_MATCH and (m_type == MomentType.FREE_KICK or m_type == MomentType.PENALTY or m_type == MomentType.CORNER_KICK) and randf() < 0.70:
			_open_ask_set_piece(m_type, randf() < 0.50)
		elif run_mode == RunMode.CAREER_MATCH and m_type == MomentType.PENALTY and randf() < 0.30:
			_trigger_key_moment(MomentType.TEAMMATE_PENALTY)
		else:
			_trigger_key_moment(m_type)
		return

	if _minute >= _et_end_min:
		if _is_current_knockout_match() and _score_us == _score_them:
			if not _in_extra_time:
				_in_extra_time = true
				_et_end_min = 120.0
				_board_hold_fast = false
				AudioSynth.play_whistle(false)
				var u_d: Dictionary = _get_user_roster_dict()
				_add_rich_board_highlight(90, "INFO", "PERPANJANGAN WAKTU!", "Skor imbang %d-%d! Laga berlanjut ke 91' - 120'!" % [_score_us, _score_them], u_d, {}, true)
				if not _user_subbed_out:
					_key_moment_minutes.append(randi_range(96, 114))
					_key_moment_minutes.sort()
				_sync_board_hud()
				return
			else:
				_open_coin_flip_phase()
				return
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
	_scramble_from_penalty_rebound = false
	_rebound_grace = 0.0
	_tm_penalty_kicked = false
	_throw_in_thrown = false
	_throw_in_timer = 0.0
	_throw_in_flight_t = 0.0
	_carry_tm_idx = -1
	_carry_timer = 0.0
	_carry_pass_back = false
	_carry_assist_pending = false
	_carry_shrug_cd = 0.0
	_incoming_pass_tm_idx = -1
	_incoming_pass_timer = 0.0
	_incoming_pass_kicked = false
	_gk_sway_clock = 0.0
	_our_gk_pos = Vector3(0.0, 0.0, 48.8)
	if is_instance_valid(_our_gk_sprite):
		_our_gk_sprite.frame = 4
	_controlling_teammate_idx = -1
	_user_assisted_pass = false
	_user_hockey_assist_eligible = false
	_scramble_is_loose_pass = false
	_incoming_pass_is_our_gk = false
	_corner_taker_is_user = false
	_kick_offside_flags.clear()
	_kick_offside_line_z = -35.0
	_shot_on_target_credit = false
	_key_pass_awarded = false
	_qte_progress = 0.0
	_qte_resolved = false
	_dribble_tackle_grace = 0.45
	if _qte_overlay != null:
		_qte_overlay.visible = false
	if _rating_delta_lbl != null:
		_rating_delta_lbl.visible = false

	# Setup positions on the attacking top half (goal at z = -52.5)
	for tm in _teammates:
		tm.visible = false
		tm.frame = 4
	for df in _defenders:
		df.visible = false
		df.frame = 0
		df.rotation_degrees.z = 0.0
	_player_sprite.visible = true
	_player_sprite.frame = 4
	_gk_sprite.frame = 0
	_defender_positions.clear()
	_defender_dirs.clear()
	_defender_slide_timers.clear()
	_defender_slide_dirs.clear()
	_defender_slid_this_kick.clear()
	_teammate_positions.clear()
	_teammate_vels.clear()
	_teammate_targets.clear()
	_teammate_open_scores.clear()

	_gk_pos = Vector3(0.0, 0.0, -51.6)
	_gk_target_x = 0.0
	_gk_dive_dir = 0.0
	_gk_sprite.rotation_degrees = Vector3.ZERO
	_gk_react_timer = float(get_opp_gk_profile().get("reaction_delay", 0.22))

	match m_type:
		MomentType.TEAMMATE_PENALTY:
			_setup_teammate_penalty()
			return
		MomentType.TEAMMATE_PASS:
			_setup_teammate_pass_to_user()
			return
		MomentType.THROW_IN:
			_setup_throw_in_moment()
			return
		MomentType.GK_BUILDUP:
			_setup_gk_buildup_moment()
			return
		MomentType.CORNER_KICK:
			_setup_corner_kick_moment()
			return
		MomentType.HEADER_CROSS:
			_setup_header_cross_moment()
			return
		MomentType.DRIBBLE_DUEL:
			_setup_dribble_duel_qte()
			return
		MomentType.LONG_PASS_CONTROL:
			_setup_long_pass_control_qte()
			return
		MomentType.PENALTY:
			_player_pos = Vector3(0.0, 0.0, -40.2)
			_ball_pos = Vector3(0.0, 0.115, -41.5)
			for i in range(2):
				_teammates[i].visible = true
				_teammate_positions.append(Vector3(-5.8 if i == 0 else 5.8, 0.0, -33.4))
				_teammate_vels.append(Vector3(0.0, 0.0, 0.0))
				_teammate_targets.append(Vector3(-4.2 if i == 0 else 4.5, 0.0, -43.0))
				_teammate_open_scores.append(2.0)
			for i in range(2):
				_defenders[i].visible = true
				_defender_positions.append(Vector3(-9.2 if i == 0 else 9.2, 0.0, -34.8))
				_defender_dirs.append(1.0 if i == 0 else -1.0)
			_moment_title_lbl.text = "PENALTI!"
			_moment_sub_lbl.text = "Tarik ketapel & atur putaran bola ke pojok gawang!"
			_ticker_lbl.text = "Hadiah PENALTI! Tarik bola ke belakang lalu lepaskan."
		MomentType.FREE_KICK:
			var x_off := randf_range(-9.0, 9.0)
			var z_off := randf_range(-33.0, -25.0)
			if _pending_foul_spot != Vector3.ZERO:
				x_off = clampf(_pending_foul_spot.x, -26.0, 26.0)
				z_off = clampf(_pending_foul_spot.z, -35.6, -16.0)
				_pending_foul_spot = Vector3.ZERO
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
		_cam_target_pos = Vector3(0.0, 9.2, -19.2)
		_cam_look_pos = Vector3(0.0, 0.7, -41.5)
	elif _moment_type == MomentType.THROW_IN:
		var t_origin: Vector3 = _teammate_positions[0] if not _teammate_positions.is_empty() else Vector3(_throw_in_side * 34.15, 0.0, _throw_in_z)
		var mid_t: Vector3 = t_origin.lerp(_player_pos, 0.52)
		_cam_target_pos = mid_t + Vector3(-_throw_in_side * 8.2, 10.6, 15.8)
		_cam_look_pos = mid_t + Vector3(_throw_in_side * 1.2, 0.9, -2.0)
	elif _moment_type == MomentType.HEADER_CROSS:
		_cam_target_pos = _player_pos + Vector3(0.0, 8.6, 15.5)
		_cam_look_pos = Vector3(_player_pos.x * 0.35, 1.3, -47.0)
	elif _moment_type == MomentType.CORNER_KICK:
		if _corner_taker_is_user:
			_cam_target_pos = Vector3(_corner_side * 37.2, 4.2, -55.4)
			_cam_look_pos = Vector3(_corner_side * 4.0, 0.9, -45.6)
		else:
			_cam_target_pos = _player_pos + Vector3(-_corner_side * 3.5, 8.2, 15.0)
			_cam_look_pos = Vector3(0.0, 1.2, -46.5)
	elif _moment_type == MomentType.DRIBBLE_DUEL:
		_cam_target_pos = _player_pos + Vector3(1.8, 4.6, 8.5)
		_cam_look_pos = Vector3(_player_pos.x * 0.5, 0.8, _player_pos.z - 8.0)
	elif _moment_type == MomentType.LONG_PASS_CONTROL:
		_cam_target_pos = _player_pos + Vector3(0.0, 9.2, 16.0)
		_cam_look_pos = Vector3(_player_pos.x * 0.5, 1.5, _player_pos.z - 2.0)
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
		_cam_target_pos = _cam_target_pos.lerp(Vector3(0.0, 9.2, -19.2), delta * 4.5)
		_cam_look_pos = _cam_look_pos.lerp(Vector3(0.0, 0.7, -41.5), delta * 5.0)
	elif _phase == MatchPhase.THROW_IN_PREP:
		var t_org: Vector3 = _teammate_positions[0] if not _teammate_positions.is_empty() else Vector3(_throw_in_side * 34.15, 0.0, _throw_in_z)
		var focus_t: Vector3 = t_org.lerp(_player_pos, 0.56 if not _throw_in_thrown else 0.72)
		_cam_target_pos = _cam_target_pos.lerp(focus_t + Vector3(-_throw_in_side * 8.0, 10.4, 15.6), delta * 5.0)
		_cam_look_pos = _cam_look_pos.lerp(focus_t.lerp(_ball_pos, 0.28) + Vector3(0.0, 0.85, -1.8), delta * 5.5)
	elif _phase == MatchPhase.TEAMMATE_CARRY or _phase == MatchPhase.INCOMING_PASS:
		if _incoming_pass_is_our_gk:
			_cam_target_pos = _cam_target_pos.lerp(_ball_pos + Vector3(0.0, 7.6, 15.5), delta * 5.0)
			_cam_look_pos = _cam_look_pos.lerp(_player_pos.lerp(_ball_pos, 0.35) + Vector3(0.0, 0.8, -5.0), delta * 5.5)
		else:
			_cam_target_pos = _cam_target_pos.lerp(_ball_pos + Vector3(0.0, 6.2, 13.5), delta * 5.0)
			_cam_look_pos = _cam_look_pos.lerp(Vector3(_ball_pos.x * 0.45, 0.7, minf(_ball_pos.z - 6.0, -45.0)), delta * 5.5)
	elif _phase == MatchPhase.HEADER_TIMING:
		_cam_target_pos = _cam_target_pos.lerp(_player_pos + Vector3(0.0, 7.2, 13.5), delta * 5.0)
		_cam_look_pos = _cam_look_pos.lerp(_player_pos.lerp(_ball_pos, 0.35) + Vector3(0.0, 1.2, -3.0), delta * 6.0)
	elif _phase == MatchPhase.QTE_DRIBBLE_DUEL:
		_cam_target_pos = _cam_target_pos.lerp(_player_pos + Vector3(1.5, 4.4, 8.2), delta * 5.5)
		_cam_look_pos = _cam_look_pos.lerp(_player_pos + Vector3(0.0, 0.8, -6.5), delta * 6.0)
	elif _phase == MatchPhase.QTE_LONG_CONTROL:
		_cam_target_pos = _cam_target_pos.lerp(_player_pos + Vector3(0.0, 8.2, 14.5), delta * 4.5)
		_cam_look_pos = _cam_look_pos.lerp(_player_pos.lerp(_ball_pos, 0.42) + Vector3(0.0, 1.2, 0.0), delta * 5.5)
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
	if _phase in [MatchPhase.HEADER_TIMING, MatchPhase.QTE_DRIBBLE_DUEL, MatchPhase.QTE_LONG_CONTROL]:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if event.position.y > 76:
				_handle_qte_tap()
		elif event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
				_handle_qte_tap()
		return
	if _phase == MatchPhase.THROW_IN_PREP:
		if not _throw_in_thrown and _throw_in_timer >= 0.35:
			if event is InputEventKey and event.pressed and not event.echo:
				if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
					_release_teammate_throw_in()
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
	if _aim_power_pill != null:
		_aim_power_pill.visible = false
	var delta_px := _drag_start - _drag_current
	if delta_px.length() < 14.0:
		_power_lbl.text = ""
		return
	_moment_banner.visible = false
	if _rating_delta_lbl != null:
		_rating_delta_lbl.visible = false
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
	_shot_on_target_credit = false
	_key_pass_awarded = false
	# Snapshot FIFA Law 11 Offside positions at the exact instant the ball is kicked
	_kick_offside_line_z = _get_offside_line_z()
	_kick_offside_flags.clear()
	for ti in range(_teammate_positions.size()):
		var is_off: bool = (_moment_type != MomentType.PENALTY and _moment_type != MomentType.CORNER_KICK and ti != _controlling_teammate_idx) and _is_teammate_offside(ti)
		_kick_offside_flags.append(is_off)

	if _moment_type == MomentType.HEADER_CROSS or (_moment_type == MomentType.CORNER_KICK and not _corner_taker_is_user):
		# Step 1 complete: lock user's desired header direction, then launch high aerial cross from wing/corner!
		_header_aim_vel = launch["velocity"]
		_header_aim_vel.y = clampf(_header_aim_vel.y * 0.52, -1.5, 4.6)
		_header_aim_omega = launch["omega"] * 0.55
		_launch_header_cross_timing()
		return

	_ball_vel = _rotate_corner_launch(launch["velocity"]) if (_moment_type == MomentType.CORNER_KICK and _corner_taker_is_user) else launch["velocity"]
	_ball_omega = launch["omega"]
	_last_kick_power_ratio = float(launch.get("power_ratio", 0.5))
	# Detect & execute acrobatic SALTO (Bicycle Kick) or VOLI (Volley) on counter-attack pass reception!
	if _controlling_teammate_idx < 0 and _acrobatic_ready_style == "SALTO":
		_last_shot_style = "SALTO"
		_acrobatic_anim_style = "SALTO"
		_acrobatic_anim_dur = 0.66
		_acrobatic_anim_timer = 0.66
		_ball_vel *= 1.10
		_acrobatic_ready_style = ""
	elif _controlling_teammate_idx < 0 and _acrobatic_ready_style == "VOLI":
		_last_shot_style = "VOLI"
		_acrobatic_anim_style = "VOLI"
		_acrobatic_anim_dur = 0.52
		_acrobatic_anim_timer = 0.52
		_ball_vel *= 1.08
		_acrobatic_ready_style = ""
	elif _moment_type == MomentType.FREE_KICK:
		_last_shot_style = "TENDANGAN BEBAS"
	elif _moment_type == MomentType.PENALTY:
		_last_shot_style = "PENALTI"
	elif _moment_type == MomentType.HEADER_CROSS:
		_last_shot_style = "SUNDULAN"
	elif _ball_pos.distance_to(Vector3(0, 0, -52.5)) >= 24.0:
		_last_shot_style = "JARAK JAUH"
	else:
		_last_shot_style = "AKSI SOLO"
	_flight_timer = 0.0
	_current_clip_frames.clear()
	_current_clip_frames.append({
		"ball": [_ball_pos.x, _ball_pos.y, _ball_pos.z],
		"gk": [_gk_pos.x, _gk_pos.z],
		"player": [_player_pos.x, _player_pos.z],
		"gk_dive": 0.0,
	})
	_clear_defender_slides()
	_gk_react_timer = float(get_opp_gk_profile().get("reaction_delay", 0.22))
	_gk_dive_dir = 0.0
	_gk_sprite.rotation_degrees = Vector3.ZERO
	_shot_by_teammate = (_controlling_teammate_idx >= 0)
	_carry_assist_pending = (_controlling_teammate_idx >= 0 and _user_assisted_pass)
	_phase = MatchPhase.BALL_IN_FLIGHT
	if _controlling_teammate_idx >= 0 and _controlling_teammate_idx < _teammates.size():
		_teammates[_controlling_teammate_idx].frame = 7
	else:
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

func _get_active_carrier_pos() -> Vector3:
	if _controlling_teammate_idx >= 0 and _controlling_teammate_idx < _teammate_positions.size():
		return _teammate_positions[_controlling_teammate_idx]
	return _player_pos

func get_teammate_speed_scale(tm_idx: int = -1) -> float:
	var avg_ovr: float = 64.0
	if CareerState.has_active_career:
		var sq: Array = CareerState.career.get("clubSquad", {}).get("starters", [])
		var sum_ovr: float = 0.0
		var cnt: int = 0
		var tm_ovrs: Array[float] = []
		for p in sq:
			if bool(p.get("is_user", false)):
				continue
			var po: float = float(p.get("ovr", 62))
			sum_ovr += po
			cnt += 1
			tm_ovrs.append(po)
		if tm_idx >= 0 and tm_idx < tm_ovrs.size():
			avg_ovr = tm_ovrs[tm_idx]
		elif cnt > 0:
			avg_ovr = sum_ovr / float(cnt)
	return lerpf(0.68, 0.96, clampf((avg_ovr - 45.0) / 48.0, 0.0, 1.0))

func _rotate_corner_launch(vel: Vector3) -> Vector3:
	var to_box := Vector2(0.0 - _ball_pos.x, -44.2 - _ball_pos.z)
	if to_box.length() < 0.1:
		return vel
	var fwd := to_box.normalized()
	var right := Vector2(-fwd.y, fwd.x)
	var world_xz := fwd * (-vel.z) + right * vel.x
	return Vector3(world_xz.x, maxf(vel.y, 0.0), world_xz.y)

func get_player_max_run_speed(spd_attr: int) -> float:
	# Realistic speed strictly driven by player's Kecepatan attribute (40..99 -> ~3.8..8.2 m/s)
	return lerpf(3.4, 8.2, clampf((float(spd_attr) - 35.0) / 64.0, 0.0, 1.0))

func _read_user_move_vec() -> Vector2:
	var kx: float = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	var ky: float = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	if Input.is_key_pressed(KEY_D):
		kx += 1.0
	if Input.is_key_pressed(KEY_A):
		kx -= 1.0
	if Input.is_key_pressed(KEY_S):
		ky += 1.0
	if Input.is_key_pressed(KEY_W):
		ky -= 1.0
	var kb := Vector2(clampf(kx, -1.0, 1.0), clampf(ky, -1.0, 1.0))
	if kb.length() > 0.12:
		return kb.normalized()
	return _dribble_input

func _process_dribble_control(delta: float) -> void:
	if _skill_burst_timer > 0.0:
		_skill_burst_timer = maxf(0.0, _skill_burst_timer - delta)
	var joy: Vector2 = _read_user_move_vec()
	var is_moving := (joy.length() > 0.08 and not _dragging)
	var fisik_attr := CareerState.get_effective_attribute("fisik") if CareerState.has_active_career else 68
	var drain_mult: float = lerpf(1.22, 0.68, clampf(float(fisik_attr) / 99.0, 0.0, 1.0))
	var ctrl_tm := (_controlling_teammate_idx >= 0 and _controlling_teammate_idx < _teammate_positions.size())
	var carrier_pos := _teammate_positions[_controlling_teammate_idx] if ctrl_tm else _player_pos

	if is_moving:
		var analog_mag := clampf(joy.length(), 0.0, 1.0)
		_dribble_facing = joy.normalized()
		var spd_attr := CareerState.get_effective_attribute("kecepatan") if CareerState.has_active_career else 60
		# Movement speed scales with Kecepatan stat (or teammate OVR speed when controlling a teammate)
		var max_run_spd: float = get_player_max_run_speed(spd_attr) if not ctrl_tm else (get_player_max_run_speed(68) * get_teammate_speed_scale(_controlling_teammate_idx))
		var move_spd: float = max_run_spd * analog_mag
		if _skill_burst_timer > 0.0:
			move_spd *= 1.18
		if _match_stamina <= 0.1:
			move_spd *= 0.52
		elif _match_stamina < 18.0:
			move_spd *= 0.72
		# 40% shorter stamina duration (~28/s base * analog deflection * fisik mult); no in-event regen
		_match_stamina = maxf(0.0, _match_stamina - (28.0 * clampf(analog_mag, 0.30, 1.0)) * drain_mult * delta)
		# Active movement also drains live match energy (~20% more demanding overall)
		_user_match_energy = maxf(0.0, _user_match_energy - 1.45 * analog_mag * delta)
		_match_extra_energy_drain += 0.48 * analog_mag * delta
		# Unrestricted full-pitch movement while keeping ball cleanly in front of goal line (z >= -52.25)
		carrier_pos.x = clampf(carrier_pos.x + joy.x * move_spd * delta, -32.5, 32.5)
		carrier_pos.z = clampf(carrier_pos.z + joy.y * move_spd * delta, -51.4, 48.0)
		if ctrl_tm:
			_teammate_positions[_controlling_teammate_idx] = carrier_pos
			if _controlling_teammate_idx < _teammates.size():
				_teammates[_controlling_teammate_idx].frame = 5 if fmod(_anim_clock, 0.28) < 0.14 else 6
		else:
			_player_pos = carrier_pos
			_player_sprite.frame = 5 if fmod(_anim_clock, 0.28) < 0.14 else 6
		var tap_hop: float = absf(sin(_anim_clock * 14.0)) * 0.06
		_ball_pos = Vector3(clampf(carrier_pos.x + _dribble_facing.x * 0.82, -33.2, 33.2), 0.115 + tap_hop, clampf(carrier_pos.z + _dribble_facing.y * 0.82, -52.25, 48.8))
		_configure_moment_camera()
	else:
		# Do NOT regenerate stamina when stopped; keep ball just inside goal line so slingshot shoots cleanly
		if ctrl_tm and _controlling_teammate_idx < _teammates.size():
			_teammates[_controlling_teammate_idx].frame = 4
		else:
			_player_sprite.frame = 4
		_ball_pos = Vector3(clampf(carrier_pos.x + _dribble_facing.x * 0.78, -33.2, 33.2), 0.115, clampf(carrier_pos.z + _dribble_facing.y * 0.78, -52.25, 48.8))
	_sync_stamina_hud()
	_sync_3d_sprites()

func _trigger_dribble_skill() -> void:
	if _phase != MatchPhase.KEY_MOMENT_AIM or (_moment_type != MomentType.SHOT and _moment_type != MomentType.PASS and _moment_type != MomentType.DRIBBLE):
		return
	AudioSynth.play_click()
	_skill_burst_timer = 0.45
	var burst_dir: Vector2 = _dribble_facing if _dribble_facing.length() > 0.1 else Vector2(0.0, -1.0)
	var ctrl_tm := (_controlling_teammate_idx >= 0 and _controlling_teammate_idx < _teammate_positions.size())
	var cpos := _teammate_positions[_controlling_teammate_idx] if ctrl_tm else _player_pos
	var lat_side: float = signf(_dribble_input.x) if absf(_dribble_input.x) > 0.1 else (1.0 if cpos.x < 0.0 else -1.0)
	cpos.x = clampf(cpos.x + lat_side * 1.45, -32.5, 32.5)
	cpos.z = clampf(cpos.z + burst_dir.y * 1.35, -51.4, 48.0)
	if ctrl_tm:
		_teammate_positions[_controlling_teammate_idx] = cpos
		if _controlling_teammate_idx < _teammates.size():
			_teammates[_controlling_teammate_idx].frame = 7
	else:
		_player_pos = cpos
		_player_sprite.frame = 7
	_ball_pos = Vector3(clampf(cpos.x + burst_dir.x * 0.85, -33.2, 33.2), 0.14, clampf(cpos.z + burst_dir.y * 0.85, -52.25, 48.8))
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
			if not _shot_by_teammate:
				_credit_on_target_shot("KENA TIANG")
		elif hit == "goal":
			_handle_goal_scored()
			return

		# Agile OVR-scaled Defenders move & SLIDE-TACKLE to intercept passes & low shots!
		var opp_agil: float = get_opp_defender_agility()
		_ensure_defender_slide_arrays()
		var d_spd := float(SettingsManager.get_difficulty_params().get("defender_speed", 1.4))
		for i in range(_defender_positions.size()):
			if i < _defenders.size() and not _defenders[i].visible:
				continue
			var intercept_dir := Vector3(_ball_pos.x - _defender_positions[i].x, 0.0, _ball_pos.z - _defender_positions[i].z)
			var dist_i: float = intercept_dir.length()
			if _defender_slide_timers[i] > 0.0:
				_defender_slide_timers[i] = maxf(0.0, _defender_slide_timers[i] - dt)
				_defender_positions[i] += _defender_slide_dirs[i] * (7.6 * opp_agil) * dt
				var ball_passed: bool = Vector2(_ball_pos.x - _defender_positions[i].x, _ball_pos.z - _defender_positions[i].z).dot(Vector2(_defender_slide_dirs[i].x, _defender_slide_dirs[i].z)) < -0.25
				if _defender_slide_timers[i] <= 0.0 or (_defender_slide_timers[i] < 0.28 and (ball_passed or _ball_pos.y > 1.85)):
					_defender_slide_timers[i] = 0.0
					if i < _defenders.size():
						_defenders[i].billboard = BaseMaterial3D.BILLBOARD_ENABLED
						_defenders[i].rotation_degrees = Vector3.ZERO
						_defenders[i].frame = 0
				elif i < _defenders.size():
					_defenders[i].frame = 3
					_defenders[i].rotation_degrees.z = 42.0 if _defender_slide_dirs[i].x >= 0.0 else -42.0
			elif d_spd > 0.0 and dist_i > 0.35 and dist_i < (10.5 * opp_agil):
				# Trigger slide tackle lunge ONLY after ball is kicked, once per kick, when low pass/shot zips within agile lunge range!
				if _flight_timer > 0.04 and not _defender_slid_this_kick[i] and _ball_pos.y < 1.35 and dist_i < (3.2 * opp_agil) and dist_i > 0.85 and _ball_vel.length() > 7.5 and _moment_type != MomentType.PENALTY and _moment_type != MomentType.TEAMMATE_PENALTY:
					_defender_slid_this_kick[i] = true
					_defender_slide_timers[i] = 0.36
					_defender_slide_dirs[i] = intercept_dir.normalized()
					if i < _defenders.size():
						_defenders[i].frame = 3
						_defenders[i].rotation_degrees.z = 42.0 if _defender_slide_dirs[i].x >= 0.0 else -42.0
				else:
					_defender_positions[i] += intercept_dir.normalized() * minf(6.2, d_spd * 1.25 * opp_agil) * dt

		# Trigger post rebound scramble cleanly inside attacking box
		if _post_rebound_eligible and _ball_vel.z > 1.2 and _ball_pos.z > -50.8 and _ball_pos.z < -26.0 and absf(_ball_pos.x) < 16.0:
			_post_rebound_eligible = false
			_scramble_from_penalty_rebound = (_moment_type == MomentType.TEAMMATE_PENALTY or _moment_type == MomentType.PENALTY)
			_enter_rebound_scramble("KENA TIANG! REBUT REBOUND!")
			return

		# Check Defender / Wall / Slide-Tackle collision
		for i in range(_defender_positions.size()):
			var dpos := _defender_positions[i]
			var is_sliding: bool = (i < _defender_slide_timers.size() and _defender_slide_timers[i] > 0.0)
			var block_r: float = 1.18 if is_sliding else 0.82
			if Vector2(_ball_pos.x - dpos.x, _ball_pos.z - dpos.z).length() < block_r and _ball_pos.y < (1.45 if is_sliding else 1.95):
				if i < _defenders.size():
					_defenders[i].frame = 3
				AudioSynth.play_save()
				if _shot_by_teammate:
					_credit_key_pass_if_pending()
					_update_last_shot("BLOCKED")
					_show_moment_result("TEMBAKAN REKAN DISLEDING BEK!" if is_sliding else "TEMBAKAN REKAN DIBLOK BEK!", UITheme.ACCENT_GOLD if _key_pass_awarded else UITheme.ACCENT_RED, 1.35)
					return
				if _moment_type == MomentType.PASS:
					_ball_vel = Vector3(-_ball_vel.x * 0.4, 2.2, 6.0)
					_adjust_rating(-0.25, "UMPAN DISLEDING" if is_sliding else "UMPAN DIPOTONG")
					_update_last_shot("BLOCKED")
					_show_moment_result("UMPAN DISLEDING BEK!" if is_sliding else "UMPAN DIPOTONG LAWAN!", UITheme.ACCENT_RED, 1.3)
					return
				if _ball_pos.z < -27.0 and randf() < 0.45:
					_ball_vel = Vector3(signf(_ball_pos.x - dpos.x + 0.05) * randf_range(3.0, 5.5), randf_range(1.6, 3.0), randf_range(3.5, 6.5))
					_enter_rebound_scramble("BOLA DISLEDING BEK! REBUT REBOUND!" if is_sliding else "BOLA MEMANTUL BEK! REBUT REBOUND!")
					return
				_ball_vel.z = absf(_ball_vel.z) * 0.45
				_ball_vel.x += randf_range(-2.5, 2.5)
				_adjust_rating(-0.20, "DISLEDING BEK" if is_sliding else "DIBLOK BEK")
				_update_last_shot("BLOCKED")
				_show_moment_result("DISLEDING BEK!" if is_sliding else "DIBLOK BEK!", UITheme.ACCENT_RED, 1.3)
				return

		# Check Return Pass to User when User is currently controlling a teammate
		if _controlling_teammate_idx >= 0 and _carry_tm_idx < 0 and not _incoming_pass_kicked and _flight_timer > 0.14:
			if Vector2(_ball_pos.x - _player_pos.x, _ball_pos.z - _player_pos.z).length() < 1.95 and _ball_pos.y < 2.25:
				_controlling_teammate_idx = -1
				_user_assisted_pass = false
				_passes_won += 1
				_enter_user_follow_up_shot("BOLA KEMBALI KE KAMU!", "Rekan mengembalikan bola — tarik ketapel TEMBAK atau umpan!")
				return

		# Check Live Teammate reception (only for USER kicks — never let a teammate intercept another teammate's shot on goal!)
		if not _shot_by_teammate and _carry_tm_idx < 0 and not _incoming_pass_kicked and (_moment_type in [MomentType.PASS, MomentType.SHOT, MomentType.DRIBBLE, MomentType.FREE_KICK, MomentType.HEADER_CROSS, MomentType.CORNER_KICK, MomentType.GK_BUILDUP]) and _flight_timer > 0.05 and not _teammate_positions.is_empty():
			var catch_rad: float = 2.45 if _moment_type == MomentType.CORNER_KICK else (2.25 if (_moment_type in [MomentType.PASS, MomentType.FREE_KICK, MomentType.HEADER_CROSS]) else 1.85)
			for ti in range(_teammate_positions.size()):
				if ti == _controlling_teammate_idx:
					continue
				var tm_pos := _teammate_positions[ti]
				if Vector2(_ball_pos.x - tm_pos.x, _ball_pos.z - tm_pos.z).length() < catch_rad and _ball_pos.y < 2.45:
					if ti < _kick_offside_flags.size() and _kick_offside_flags[ti]:
						AudioSynth.play_whistle(true)
						_adjust_rating(-0.25, "OFFSIDE")
						_update_last_shot("OFFSIDE")
						_ticker_lbl.text = "Bendera hakim garis terangkat! Rekan berada di posisi OFFSIDE saat umpan dilepas."
						_draw_offside_line_freeze(_kick_offside_line_z)
						_show_moment_result("OFFSIDE! BENDERA TERANGKAT", UITheme.ACCENT_RED, 1.5)
						return
					if ti < _teammates.size():
						_teammates[ti].frame = 7
					_passes_won += 1
					var is_box_or_corner: bool = (_moment_type in [MomentType.CORNER_KICK, MomentType.HEADER_CROSS, MomentType.FREE_KICK] or tm_pos.z < -31.5)
					if is_box_or_corner:
						_start_teammate_carry(ti, _controlling_teammate_idx < 0, true, _user_hockey_assist_eligible)
					else:
						_enter_teammate_user_control(ti, _controlling_teammate_idx < 0)
					return

		# Goalkeeper Dive AI (Reflex & Parry Reach scaled by Opponent GK OVR + Advances Closer!)
		if _moment_type != MomentType.PASS:
			_update_gk_ai(dt)
			var gk_prof: Dictionary = get_opp_gk_profile()
			var gk_reach: float = 1.08 * float(gk_prof.get("reach", 1.0))
			if Vector2(_ball_pos.x - _gk_pos.x, _ball_pos.z - _gk_pos.z).length() < gk_reach and _ball_pos.y < (2.38 * float(gk_prof.get("reach", 1.0))):
				_gk_sprite.frame = 3
				AudioSynth.play_save()
				var opp_gk: Dictionary = _pick_roster_player(false, true, false)
				var gk_nm: String = str(opp_gk.get("name", "KIPER")).to_upper()
				_add_rich_board_highlight(int(_minute), "SAVE", "PENYELAMATAN %s!" % gk_nm, "Kiper lawan menepis tembakan berbahaya!", opp_gk, {}, false)
				if _shot_by_teammate:
					_credit_key_pass_if_pending()
				else:
					_credit_on_target_shot("DITEPIS KIPER")
				var is_tm_pen: bool = (_moment_type == MomentType.TEAMMATE_PENALTY)
				var rebound_chance := 0.86 if is_tm_pen else (0.62 if (_shot_by_teammate or _moment_type == MomentType.PENALTY or _ball_vel.length() > 21.0) else 0.48)
				if randf() < rebound_chance and _ball_pos.z < -42.0:
					var parry_dir := signf(_ball_pos.x - _gk_pos.x)
					if absf(parry_dir) < 0.1:
						parry_dir = 1.0 if randf() > 0.5 else -1.0
					_scramble_from_penalty_rebound = (is_tm_pen or _moment_type == MomentType.PENALTY)
					_ball_pos.z = -48.4 if is_tm_pen else -49.8
					_ball_vel = Vector3(parry_dir * randf_range(2.2, 4.8), randf_range(1.4, 2.6), randf_range(6.2, 9.2)) if is_tm_pen else Vector3(parry_dir * randf_range(3.0, 6.2), randf_range(1.8, 3.3), randf_range(5.2, 8.8))
					_enter_rebound_scramble("PENALTI DITEPIS KIPER! KEJAR REBOUND!" if is_tm_pen else ("TEMBAKAN REKAN DITEPIS KIPER! BEREBUT REBOUND!" if _shot_by_teammate else "DITEPIS KIPER! BEREBUT REBOUND!"))
					return
				_ball_vel.z = absf(_ball_vel.z) * 0.45
				_ball_vel.x += signf(_ball_pos.x - _gk_pos.x) * 3.0
				_ball_vel.y = maxf(_ball_vel.y, 2.2)
				_update_last_shot("ON_TARGET")
				_show_moment_result("TEMBAKAN REKAN DITEPIS KIPER!" if _shot_by_teammate else "DITEPIS KIPER!", UITheme.ACCENT_CYAN, 1.4)
				return

	# Record Moviola & Goal-Replay keyframes
	if _current_clip_frames.size() < 90:
		_current_clip_frames.append({
			"ball": [_ball_pos.x, _ball_pos.y, _ball_pos.z],
			"gk": [_gk_pos.x, _gk_pos.z],
			"player": [_player_pos.x, _player_pos.z],
			"gk_dive": _gk_dive_dir,
		})

	# Update Trail & Teammates
	_trail_points.append(_ball_pos)
	if _trail_points.size() > 24:
		_trail_points.pop_front()
	_draw_ball_trail()
	if _moment_type == MomentType.TEAMMATE_PENALTY and _tm_penalty_kicked:
		# Box-edge players (user + defenders) surge into box immediately after penalty kick is struck!
		var pen_stride: int = 5 if fmod(_anim_clock, 0.26) < 0.13 else 6
		_player_pos.z = maxf(-45.5, _player_pos.z - 5.2 * delta)
		_player_sprite.frame = pen_stride
		for di in range(_defender_positions.size()):
			_defender_positions[di].z = maxf(-46.5, _defender_positions[di].z - 4.4 * delta)
			if di < _defenders.size():
				_defenders[di].frame = 1 if fmod(_anim_clock, 0.28) < 0.14 else 2
	_animate_teammates(delta)
	_sync_3d_sprites()

	# Pass into Open Space inside Pitch triggers live Chase instead of WIDE; only OOB fails wide
	var is_oob: bool = (_ball_pos.z < -53.2 or _ball_pos.z > 54.0 or absf(_ball_pos.x) > 34.4)
	var in_pitch_xz: bool = (_ball_pos.z >= -52.0 and _ball_pos.z <= 50.8 and absf(_ball_pos.x) <= 33.4)
	var is_shot_on_frame := false
	if _ball_vel.z < -0.5:
		var t_goal: float = (-52.5 - _ball_pos.z) / _ball_vel.z
		if t_goal > 0.0 and t_goal < 4.5:
			var pred_goal_x: float = _ball_pos.x + _ball_vel.x * t_goal
			if absf(pred_goal_x) <= 6.0:
				is_shot_on_frame = true
	var is_curved_fk: bool = (_moment_type == MomentType.FREE_KICK and absf(_spin_offset.x) > 0.25)
	var h_speed_now: float = Vector2(_ball_vel.x, _ball_vel.z).length()
	var is_long_kick: bool = (_last_kick_power_ratio >= 0.65)
	# Strong kicks (>= 65%) fly uninterrupted at full pace across midfield until slowing down or deep flight!
	var pass_scramble_ready: bool = false
	if is_long_kick:
		pass_scramble_ready = (_flight_timer >= 1.45 and _ball_pos.y < 1.85) or (_flight_timer >= 0.65 and h_speed_now < 9.5 and _ball_pos.y < 1.85)
	else:
		pass_scramble_ready = (_flight_timer >= 0.45 and _ball_pos.y < 2.1 and _moment_type in [MomentType.SHOT, MomentType.PASS, MomentType.DRIBBLE, MomentType.GK_BUILDUP] and not is_shot_on_frame) or (_moment_type == MomentType.PASS and _flight_timer >= 0.42 and _ball_pos.y < 2.1)
	var loose_pass_trigger: bool = (
		in_pitch_xz
		and _carry_tm_idx < 0
		and _moment_type != MomentType.PENALTY
		and _moment_type != MomentType.TEAMMATE_PENALTY
		and (
			pass_scramble_ready
			or (_flight_timer >= 0.65 and h_speed_now < 5.2 and _ball_pos.z > -51.0 and not is_curved_fk)
			or (_flight_timer >= 0.65 and _moment_type == MomentType.CORNER_KICK and _ball_pos.y < 1.35)
		)
	)
	if loose_pass_trigger:
		_enter_rebound_scramble("BOLA KE RUANG KOSONG! KEJAR BOLA!", true)
		return
	if is_oob or _flight_timer > 4.8 or (_flight_timer > 0.85 and _ball_vel.length() < 1.1):
		if _shot_by_teammate:
			_credit_key_pass_if_pending()
			_update_last_shot("WIDE")
			_show_moment_result("TEMBAKAN REKAN MELEBAR!", UITheme.ACCENT_GOLD if _key_pass_awarded else Color("#F97316"), 1.35)
			return
		if _moment_type == MomentType.PASS:
			_adjust_rating(-0.25, "UMPAN KELUAR")
			_update_last_shot("WIDE")
			_show_moment_result("UMPAN KELUAR LAPANGAN!", Color("#F97316"), 1.3)
			return
		if _moment_type == MomentType.PENALTY or _moment_type == MomentType.TEAMMATE_PENALTY:
			_save_moviola_clip("PENALTI GAGAL")
		if not _shot_on_target_credit:
			_adjust_rating(-0.30, "MELEBAR")
		_update_last_shot("WIDE")
		_show_moment_result("MELEBAR!", Color("#F97316"), 1.3)

func get_opp_gk_ovr(override_ovr: int = -1) -> int:
	if override_ovr > 0:
		return clampi(override_ovr, 45, 96)
	if not _opp_lineup.is_empty():
		return clampi(int(_opp_lineup[0].get("ovr", 62)), 45, 96)
	if run_mode == RunMode.CAREER_MATCH and CareerState.has_active_career:
		return clampi(int(CareerState.get_current_fixture().get("opp_ovr", 64)), 45, 96)
	return 66

func get_opp_gk_profile(override_ovr: int = -1) -> Dictionary:
	var gk_ovr: int = get_opp_gk_ovr(override_ovr)
	var ovr_norm: float = clampf((float(gk_ovr) - 48.0) / 44.0, 0.0, 1.0)
	var diff_p: Dictionary = SettingsManager.get_difficulty_params()
	var base_react: float = float(diff_p.get("gk_reaction", 0.22))
	var base_spd: float = float(diff_p.get("gk_speed", 5.2))
	return {
		"ovr": gk_ovr,
		"reaction_delay": clampf(base_react * lerpf(1.22, 0.40, ovr_norm), 0.06, 0.56),
		"dive_speed": clampf(base_spd * lerpf(0.68, 1.24, ovr_norm), 2.5, 9.6),
		"reach": lerpf(0.92, 1.38, ovr_norm),
		"read_accuracy": lerpf(0.66, 0.98, ovr_norm),
		"rush_speed": clampf(lerpf(1.8, 3.7, ovr_norm), 1.8, 3.8),
		"chase_scale": lerpf(0.60, 0.96, ovr_norm),
	}

func _get_gk_desired_z(ball_z: float) -> float:
	if _moment_type == MomentType.PENALTY or _moment_type == MomentType.TEAMMATE_PENALTY or _moment_type == MomentType.FREE_KICK:
		return -51.6
	if ball_z >= -36.0 or absf(_ball_pos.x) >= 16.5:
		return -51.6
	return clampf(ball_z, -51.6, -37.0)

func _update_gk_ai(dt: float) -> void:
	if _gk_react_timer > 0.0:
		_gk_react_timer -= dt
		return
	var prof: Dictionary = get_opp_gk_profile()
	var gk_spd: float = float(prof["dive_speed"])
	var rush_spd: float = float(prof.get("rush_speed", 2.8))
	var read_acc: float = float(prof["read_accuracy"])
	if _moment_type != MomentType.PENALTY and _moment_type != MomentType.TEAMMATE_PENALTY and _moment_type != MomentType.FREE_KICK and _ball_pos.z < -36.0 and _ball_pos.z > -50.2 and absf(_ball_pos.x) < 16.5:
		var des_z: float = _get_gk_desired_z(_ball_pos.z)
		_gk_pos.z = move_toward(_gk_pos.z, des_z, rush_spd * dt)
	# GK holds line horizontally until shot travels toward goal, then reacts/dives explosively by OVR reflex
	if _ball_vel.z < -0.6:
		var t_to_goal: float = (_gk_pos.z - _ball_pos.z) / _ball_vel.z
		if t_to_goal > 0.0 and t_to_goal < 1.9:
			var spin_bend_est: float = _ball_omega.y * 0.35 * t_to_goal * t_to_goal * read_acc
			var pred_x: float = _ball_pos.x + (_ball_vel.x * t_to_goal + spin_bend_est) * read_acc
			_gk_target_x = clampf(pred_x, -3.55, 3.55)
		var dx: float = _gk_target_x - _gk_pos.x
		var step_x: float = clampf(dx, -gk_spd * dt, gk_spd * dt)
		_gk_pos.x += step_x
		if absf(dx) > 0.34:
			_gk_dive_dir = signf(dx)
			_gk_sprite.frame = 3
		else:
			_gk_dive_dir = 0.0
			_gk_sprite.frame = 0
	else:
		_gk_dive_dir = 0.0
		_gk_sprite.frame = 0

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
	if tm_idx == _controlling_teammate_idx:
		return false
	if tm_idx < _teammates.size() and not _teammates[tm_idx].visible:
		return false
	if _moment_type == MomentType.PENALTY or _moment_type == MomentType.CORNER_KICK:
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

func get_opp_defender_agility(override_ovr: int = -1) -> float:
	var opp_ovr: int = override_ovr
	if opp_ovr < 0:
		if run_mode == RunMode.CAREER_MATCH and CareerState.has_active_career:
			opp_ovr = int(CareerState.get_current_fixture().get("opp_ovr", 64))
		else:
			opp_ovr = 68
	return lerpf(0.90, 1.66, clampf((float(opp_ovr) - 50.0) / 42.0, 0.0, 1.0))

func _ensure_defender_slide_arrays() -> void:
	while _defender_slide_timers.size() < _defender_positions.size():
		_defender_slide_timers.append(0.0)
	while _defender_slide_dirs.size() < _defender_positions.size():
		_defender_slide_dirs.append(Vector3.ZERO)
	while _defender_slid_this_kick.size() < _defender_positions.size():
		_defender_slid_this_kick.append(false)

func _clear_defender_slides() -> void:
	for i in range(_defender_slide_timers.size()):
		_defender_slide_timers[i] = 0.0
	for i in range(_defender_slid_this_kick.size()):
		_defender_slid_this_kick[i] = false
	for df in _defenders:
		if is_instance_valid(df):
			df.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			df.rotation_degrees = Vector3.ZERO
			df.frame = 0

func _get_moment_time_scales() -> Dictionary:
	var diff_p: Dictionary = SettingsManager.get_difficulty_params()
	var agil: float = get_opp_defender_agility()
	var base_def_spd: float = float(diff_p.get("defender_speed", 1.6)) * agil
	var drib_def_spd: float = float(diff_p.get("dribble_defender_speed", 2.2)) * agil
	var aim_tm_scale: float = float(diff_p.get("aim_teammate_scale", 0.22))
	var aim_def_scale: float = float(diff_p.get("aim_defender_scale", 0.34))

	if _phase != MatchPhase.KEY_MOMENT_AIM:
		return {"teammate": 1.0, "defender_speed": base_def_spd, "active_dribble": false}
	if _moment_type == MomentType.FREE_KICK or _moment_type == MomentType.HEADER_CROSS:
		# Teammates stand stationary in optimal positions during free kick & aerial cross header aiming
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
	# GK holds goal line when ball is outside penalty area; once ball enters penalty area, GK chases/advances with identical timing to defenders (slows when aiming/shooting, moves when player moves)
	var stride_front: int = 1 if fmod(_anim_clock * maxf(0.22, tm_scale), 0.34) < 0.17 else 2
	var can_steal: bool = bool(diff_p.get("can_steal", false))
	var steal_dist: float = float(diff_p.get("steal_dist", 1.05))
	_gk_dive_dir = 0.0
	_gk_sprite.frame = 0
	if _moment_type != MomentType.PENALTY and _moment_type != MomentType.FREE_KICK:
		var gk_prof_idle: Dictionary = get_opp_gk_profile()
		var gk_chase_spd: float = eff_def_speed * float(gk_prof_idle.get("chase_scale", 0.78))
		var ball_in_box: bool = (_ball_pos.z < -36.0 and absf(_ball_pos.x) < 16.5)
		if ball_in_box and eff_def_speed > 0.01:
			var gk_tgt := Vector3(clampf(_ball_pos.x, -12.0, 12.0), 0.0, clampf(_ball_pos.z, -51.6, -37.0))
			var to_gk_tgt := Vector3(gk_tgt.x - _gk_pos.x, 0.0, gk_tgt.z - _gk_pos.z)
			var dist_gk: float = to_gk_tgt.length()
			if dist_gk > 0.05:
				_gk_pos += to_gk_tgt.normalized() * gk_chase_spd * delta
				_gk_sprite.frame = stride_front
			if can_steal and run_mode != RunMode.MOVIOLA_REPLAY and _phase == MatchPhase.KEY_MOMENT_AIM and _moment_type in [MomentType.SHOT, MomentType.PASS, MomentType.DRIBBLE] and dist_gk < maxf(0.90, steal_dist * 0.92):
				_gk_sprite.frame = 3
				_dragging = false
				_aim_imm.clear_surfaces()
				_ring_imm.clear_surfaces()
				_moment_banner.visible = false
				AudioSynth.play_save()
				if _controlling_teammate_idx >= 0:
					if _user_assisted_pass:
						_carry_assist_pending = true
						_credit_key_pass_if_pending()
					_show_moment_result("REKAN DISERGAP KIPER!", UITheme.ACCENT_GOLD if _key_pass_awarded else UITheme.ACCENT_RED, 1.2)
				else:
					_adjust_rating(-0.25, "DISERGAP KIPER")
					_show_moment_result("DISERGAP KIPER!", UITheme.ACCENT_RED, 1.2)
				return
		elif not ball_in_box and eff_def_speed > 0.01 and (_gk_pos.z > -51.55 or absf(_gk_pos.x) > 0.08):
			var home_dir := Vector3(0.0 - _gk_pos.x, 0.0, -51.6 - _gk_pos.z)
			var dist_home: float = home_dir.length()
			if dist_home > 0.08:
				_gk_pos += home_dir.normalized() * minf(dist_home, gk_chase_spd * delta)
				_gk_sprite.frame = stride_front
			else:
				_gk_pos = Vector3(0.0, 0.0, -51.6)

	if _moment_type in [MomentType.SHOT, MomentType.PASS, MomentType.DRIBBLE]:
		_dribble_tackle_grace = maxf(0.0, _dribble_tackle_grace - delta)
		_ensure_defender_slide_arrays()
		var opp_agil: float = get_opp_defender_agility()
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
				var to_ball: Vector3 = Vector3(_ball_pos.x - _defender_positions[i].x, 0.0, _ball_pos.z - _defender_positions[i].z)
				var dist: float = to_ball.length()
				if _defender_slide_timers[i] > 0.0:
					_defender_slide_timers[i] = maxf(0.0, _defender_slide_timers[i] - delta)
					_defender_positions[i] += _defender_slide_dirs[i] * (7.1 * opp_agil) * delta
					if i < _defenders.size():
						_defenders[i].frame = 3
						_defenders[i].rotation_degrees.z = 42.0 if _defender_slide_dirs[i].x >= 0.0 else -42.0
					if _defender_slide_timers[i] <= 0.0:
						if i < _defenders.size():
							_defenders[i].billboard = BaseMaterial3D.BILLBOARD_ENABLED
							_defenders[i].rotation_degrees = Vector3.ZERO
							_defenders[i].frame = 0
				else:
					# Pressing defender moves toward ball carrier and may lunge into a tackle
					if eff_def_speed > 0.01 and dist > 0.01:
						_defender_positions[i] += to_ball.normalized() * eff_def_speed * delta
						if i < _defenders.size():
							_defenders[i].frame = stride_front
						if _dribble_tackle_grace <= 0.0 and _is_user_dribbling_active() and not _defender_slid_this_kick[i] and dist >= 1.05 and dist < 2.35 * clampf(opp_agil, 0.85, 1.3) and randf() < delta * 2.4:
							_defender_slid_this_kick[i] = true
							_defender_slide_timers[i] = 0.34
							_defender_slide_dirs[i] = to_ball.normalized()
					elif i < _defenders.size():
						_defenders[i].frame = 0
				var cur_dist := Vector2(_ball_pos.x - _defender_positions[i].x, _ball_pos.z - _defender_positions[i].z).length()
				var tackle_reach: float = maxf(0.90, steal_dist)
				var tackle_enabled: bool = (can_steal or _is_user_dribbling_active()) and eff_def_speed > 0.01
				if tackle_enabled and _dribble_tackle_grace <= 0.0 and run_mode != RunMode.MOVIOLA_REPLAY and _phase == MatchPhase.KEY_MOMENT_AIM and cur_dist < tackle_reach:
					_resolve_carrier_tackle_outcome(_get_active_carrier_pos(), i, _defender_slide_timers[i] > 0.0, true)
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
	# During Free Kick, Penalty, Aerial Cross Header, & Corner Kick aiming, non-controlled teammates stay stationary in optimal positions
	if _phase == MatchPhase.KEY_MOMENT_AIM and (_moment_type == MomentType.FREE_KICK or _moment_type == MomentType.PENALTY or _moment_type == MomentType.HEADER_CROSS or _moment_type == MomentType.CORNER_KICK):
		for i in range(_teammates.size()):
			if i != _controlling_teammate_idx and _teammates[i].visible:
				_teammates[i].frame = 4
		_sync_3d_sprites()
		return
	var scales := _get_moment_time_scales()
	var tm_scale: float = float(scales["teammate"])
	var stride_back: int = 5 if fmod(_anim_clock * maxf(0.22, tm_scale), 0.32) < 0.16 else 6
	for i in range(_teammate_positions.size()):
		if i == _controlling_teammate_idx:
			continue
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
				var spd := (2.85 if i == 0 else (2.45 if i == 1 else 2.10)) * get_teammate_speed_scale(i)
				_teammate_vels[i] = to_t.normalized() * spd
		_teammate_vels[i].z = minf(_teammate_vels[i].z, 0.0)
		_teammate_positions[i] += _teammate_vels[i] * tm_scale * delta
		_teammate_positions[i].x = clampf(_teammate_positions[i].x, -22.0, 22.0)
		_teammate_positions[i].z = clampf(_teammate_positions[i].z, -48.5, 42.0)
		if i < _teammates.size():
			_teammates[i].frame = stride_back if (_teammate_vels[i].length() * tm_scale) > 0.25 else 4
	# When user controls a teammate, keep user's own player jogging steadily in forward support
	if _controlling_teammate_idx >= 0 and _phase == MatchPhase.KEY_MOMENT_AIM and tm_scale > 0.01:
		var u_nxt_z: float = maxf(-47.5, _player_pos.z - 2.2 * tm_scale * delta)
		_player_pos = Vector3(_player_pos.x, 0.0, u_nxt_z)
		_player_sprite.frame = stride_back
	_sync_3d_sprites()

func _update_pass_openness_ui() -> void:
	_teammate_open_scores.resize(_teammate_positions.size())
	var best := 0.0
	for i in range(_teammate_positions.size()):
		if i == _controlling_teammate_idx:
			_teammate_open_scores[i] = 0.0
			continue
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

func _enter_teammate_user_control(tm_idx: int, from_direct_user_pass: bool) -> void:
	if tm_idx < 0 or tm_idx >= _teammate_positions.size():
		return
	var was_user: bool = (_controlling_teammate_idx < 0 and from_direct_user_pass)
	if was_user:
		_user_assisted_pass = true
		_user_hockey_assist_eligible = false
	elif _controlling_teammate_idx >= 0:
		_user_assisted_pass = false
		_user_hockey_assist_eligible = true
	else:
		_user_assisted_pass = false
		_user_hockey_assist_eligible = false
	_controlling_teammate_idx = tm_idx
	_carry_tm_idx = -1
	_dribble_tackle_grace = 0.45
	_clear_defender_slides()
	_phase = MatchPhase.KEY_MOMENT_AIM
	_moment_type = MomentType.SHOT
	_shot_by_teammate = false
	_carry_assist_pending = _user_assisted_pass
	_post_rebound_eligible = false
	_incoming_pass_kicked = false
	_incoming_pass_is_our_gk = false
	_dragging = false
	_dribble_input = Vector2.ZERO
	_dribble_facing = Vector2(0.0, -1.0)
	_ball_vel = Vector3.ZERO
	_ball_omega = Vector3.ZERO
	_spin_offset = Vector2.ZERO
	_spin_pad.reset_spin()
	_spin_pad.visible = (run_mode != RunMode.MOVIOLA_REPLAY)
	_power_lbl.visible = true
	_power_lbl.text = ""
	var cpos: Vector3 = _teammate_positions[tm_idx]
	_ball_pos = Vector3(clampf(cpos.x, -32.8, 32.8), 0.115, clampf(cpos.z - 0.82, -52.25, 48.8))
	if tm_idx < _teammates.size():
		_teammates[tm_idx].frame = 4
	var ctrl_info: Dictionary = _get_controlled_player_info()
	var tm_disp: String = str(ctrl_info.get("name", "REKAN")).to_upper()
	var tm_num: int = int(ctrl_info.get("num", 8))
	var combo_hint := "Oper rekan lain lalu gol (+0.1 rating) atau tembak langsung!" if _user_assisted_pass else "Kombinasi tim aktif - umpan atau tembak!"
	_moment_title_lbl.text = "KENDALIKAN %s (#%d)!" % [tm_disp, tm_num]
	_moment_sub_lbl.text = combo_hint
	_ticker_lbl.text = "Bola di kaki %s (#%d)! Giring bebas, tembak, atau oper ke rekan lain!" % [tm_disp, tm_num]
	_moment_banner.visible = true
	_update_pass_openness_ui()
	_sync_action_bar()
	_configure_moment_camera()
	_sync_3d_sprites()
	_draw_aim_and_ring()
	AudioSynth.play_click()

func _evaluate_teammate_shot_or_layoff(tm_idx: int, from_rebound: bool) -> void:
	if tm_idx < 0 or tm_idx >= _teammate_positions.size():
		return
	# On rebounds & box pickups, the teammate executes the finish themselves directly!
	_start_teammate_carry(tm_idx, not from_rebound, true, _user_hockey_assist_eligible)

func _start_teammate_carry(tm_idx: int, is_assist: bool, quick_exec: bool = false, is_combo: bool = false) -> void:
	if tm_idx < 0 or tm_idx >= _teammate_positions.size():
		return
	_phase = MatchPhase.TEAMMATE_CARRY
	_carry_tm_idx = tm_idx
	_controlling_teammate_idx = -1
	_carry_timer = 0.0
	_carry_shrug_cd = 0.0
	_shot_by_teammate = true
	_carry_assist_pending = is_assist
	_user_hockey_assist_eligible = is_combo
	_post_rebound_eligible = false
	_dragging = false
	_clear_defender_slides()
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
	if _player_card_panel != null:
		_player_card_panel.visible = false

	var tm_pos: Vector3 = _teammate_positions[tm_idx]
	# Never pass back to user after user passed to teammate — teammate pushes forward & finishes directly
	_carry_pass_back = false
	if quick_exec:
		_carry_shoot_at = 0.14 if tm_pos.z < -39.0 else 0.36
	else:
		_carry_shoot_at = 0.25 if tm_pos.z < -41.5 else randf_range(0.55, 0.92)
	_moment_banner.visible = true
	_moment_title_lbl.text = "REKAN LANGSUNG EKSEKUSI!" if quick_exec else "REKAN BAWA BOLA!"
	_moment_sub_lbl.text = "Rekan menerima bola dan langsung menembak ke gawang!" if quick_exec else "Rekan menerima umpanmu dan menggiring maju ke kotak penalti!"
	_ticker_lbl.text = "Rekan bersiap mengeksekusi peluang di area pertahanan lawan!"
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
	var carry_spd := 4.8 * get_teammate_speed_scale(_carry_tm_idx)
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

	# Opposing defenders actively chase the carrying teammate to stop/tackle them (OVR-scaled agility)!
	var diff_p: Dictionary = SettingsManager.get_difficulty_params()
	var def_base: float = float(diff_p.get("dribble_defender_speed", 2.2))
	var opp_agil_c: float = get_opp_defender_agility()
	var chase_spd: float = clampf((def_base * 1.18 + 1.25) * opp_agil_c, 1.8, 6.2)
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

	_gk_dive_dir = 0.0
	var gk_rush_c: float = float(get_opp_gk_profile().get("rush_speed", 4.0))
	_gk_pos.z = move_toward(_gk_pos.z, _get_gk_desired_z(carrier.z), gk_rush_c * 0.65 * delta)
	_trail_points.clear()
	_trail_imm.clear_surfaces()
	_sync_3d_sprites()

	if hit_def:
		_resolve_carrier_tackle_outcome(carrier, 0, randf() < 0.45, false)
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
		_gk_react_timer = float(get_opp_gk_profile().get("reaction_delay", 0.25))
		_post_rebound_eligible = true
		_phase = MatchPhase.BALL_IN_FLIGHT
		_moment_type = MomentType.SHOT
		_shot_by_teammate = true
		_moment_banner.visible = false
		AudioSynth.play_kick(0.88)

func _setup_gk_buildup_moment() -> void:
	_phase = MatchPhase.INCOMING_PASS
	_moment_type = MomentType.GK_BUILDUP
	_incoming_pass_is_our_gk = true
	_incoming_pass_tm_idx = -1
	_incoming_pass_timer = 0.0
	_incoming_pass_kicked = false
	_shot_by_teammate = false
	_carry_assist_pending = false
	_spin_pad.visible = false
	_power_lbl.visible = false

	_our_gk_pos = Vector3(0.0, 0.0, 46.5)
	if is_instance_valid(_our_gk_sprite):
		_our_gk_sprite.frame = 4
	# User attacker positions ahead in midfield/attack; friendly GK passes to backline defender (Teammate 0)
	_player_pos = Vector3(randf_range(-6.0, 6.0), 0.0, 6.0)
	_ball_pos = Vector3(0.0, 0.12, 45.1)

	# Teammate 0 = friendly defender in backline (z=31.5) receiving GK's pass; Teammates 1 & 2 support ahead
	var tm_spots := [
		Vector3(randf_range(-8.0, 8.0), 0.0, 31.5),
		Vector3(-10.5, 0.0, 14.0),
		Vector3(9.5, 0.0, -4.0),
	]
	for i in range(tm_spots.size()):
		if i < _teammates.size():
			_teammates[i].visible = true
			_teammate_positions.append(tm_spots[i])
			_teammate_vels.append(Vector3(0.0, 0.0, -0.6 if i == 0 else -1.8))
			_teammate_targets.append(Vector3(tm_spots[i].x * 0.7, 0.0, -45.5))
			_teammate_open_scores.append(3.2)

	var def_spots := [
		Vector3(clampf(_teammate_positions[0].x, -10.0, 10.0), 0.0, 5.0),
		Vector3(-7.0, 0.0, -10.0),
		Vector3(6.5, 0.0, -24.0),
	]
	for i in range(def_spots.size()):
		if i < _defenders.size():
			_defenders[i].visible = true
			_defender_positions.append(def_spots[i])
			_defender_dirs.append(1.0)

	_moment_title_lbl.text = "MULAI SERANGAN DARI KIPER!"
	_moment_sub_lbl.text = "Kiper timmu mengoper bola ke bek — bangun serangan dari lini belakang!"
	_ticker_lbl.text = "Kiper memberikan bola ke bek rekan! Kendalikan bek lalu oper ke depan!"
	_moment_banner.visible = true
	_sync_action_bar()
	_configure_moment_camera()
	_sync_3d_sprites()
	AudioSynth.play_whistle(false)

func setup_corner_variant(user_takes: bool) -> void:
	_trigger_key_moment(MomentType.CORNER_KICK)
	_setup_corner_kick_moment(1 if user_takes else 0)

func _setup_corner_kick_moment(force_user_taker: int = -1) -> void:
	_teammate_positions.clear()
	_teammate_vels.clear()
	_teammate_targets.clear()
	_teammate_open_scores.clear()
	_defender_positions.clear()
	_defender_dirs.clear()
	for tm in _teammates:
		tm.visible = false
		tm.frame = 4
	for df in _defenders:
		df.visible = false
		df.frame = 0

	_corner_side = -1.0 if randf() < 0.5 else 1.0
	if force_user_taker == 1:
		_corner_taker_is_user = true
	elif force_user_taker == 0:
		_corner_taker_is_user = false
	else:
		_corner_taker_is_user = (randf() < 0.5)

	_phase = MatchPhase.KEY_MOMENT_AIM
	_moment_type = MomentType.CORNER_KICK
	var corner_spot := Vector3(_corner_side * 32.0, 0.115, -51.0)

	if _corner_taker_is_user:
		# Variant A: User takes the corner kick, curving the ball to attacking teammates in the box
		_ball_pos = corner_spot
		_player_pos = Vector3(_corner_side * 32.8, 0.0, -51.8)
		var box_tms := [
			Vector3(-1.2, 0.0, -45.2),
			Vector3(3.6, 0.0, -43.5),
			Vector3(-_corner_side * 6.8, 0.0, -41.5),
		]
		for i in range(box_tms.size()):
			if i < _teammates.size():
				_teammates[i].visible = true
				_teammate_positions.append(box_tms[i])
				_teammate_vels.append(Vector3.ZERO)
				_teammate_targets.append(box_tms[i])
				_teammate_open_scores.append(3.4)
		var box_defs := [
			Vector3(-3.0, 0.0, -46.2),
			Vector3(2.8, 0.0, -45.6),
			Vector3(-7.0, 0.0, -43.0),
			Vector3(_corner_side * 17.5, 0.0, -44.0),
		]
		for i in range(box_defs.size()):
			if i < _defenders.size():
				_defenders[i].visible = true
				_defender_positions.append(box_defs[i])
				_defender_dirs.append(1.0)
		_moment_title_lbl.text = "TENDANGAN SUDUT (KAMU EKSEKUTOR)!"
		_moment_sub_lbl.text = "Lengkungkan umpan sudut ke rekan di kotak penalti atau ke gawang!"
		_ticker_lbl.text = "Tendangan sudut! Tarik ketapel & atur EFEK untuk mengirim umpan akurat!"
	else:
		# Variant B: Teammate takes corner kick; User aims header/volley direction inside the box + Shrinking Circle QTE!
		_player_pos = Vector3(clampf(-_corner_side * 1.8, -5.0, 5.0), 0.0, randf_range(-45.5, -42.5))
		_cross_passer_idx = 0
		_cross_start = Vector3(corner_spot.x, 0.15, corner_spot.z)
		_cross_target = Vector3(_player_pos.x, 1.55, _player_pos.z)
		_cross_peak_y = 6.0
		_ball_pos = _cross_start
		var tm_spots := [
			Vector3(_corner_side * 32.8, 0.0, -51.8),
			Vector3(_corner_side * 4.5, 0.0, -44.0),
			Vector3(-_corner_side * 6.5, 0.0, -41.5),
		]
		for i in range(tm_spots.size()):
			if i < _teammates.size():
				_teammates[i].visible = true
				_teammate_positions.append(tm_spots[i])
				_teammate_vels.append(Vector3.ZERO)
				_teammate_targets.append(tm_spots[i])
				_teammate_open_scores.append(3.4)
		var def_spots := [
			Vector3(_player_pos.x + _corner_side * 1.9, 0.0, -45.5),
			Vector3(-_corner_side * 4.5, 0.0, -44.8),
		]
		for i in range(def_spots.size()):
			if i < _defenders.size():
				_defenders[i].visible = true
				_defender_positions.append(def_spots[i])
				_defender_dirs.append(1.0)
		_moment_title_lbl.text = "TENDANGAN SUDUT REKAN!"
		_moment_sub_lbl.text = "Rekan ambil korner — arahkan sundulanmu lalu TAP saat bola tiba!"
		_ticker_lbl.text = "Tendangan sudut oleh rekan! Tentukankan arah sundulan/voli sebelum dieksekusi!"

	_moment_banner.visible = true
	_spin_pad.visible = (run_mode != RunMode.MOVIOLA_REPLAY)
	_power_lbl.visible = true
	_sync_action_bar()
	_configure_moment_camera()
	_sync_3d_sprites()
	_draw_aim_and_ring()
	AudioSynth.play_whistle(false)

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
		Vector3(clampf(user_x + side * 2.2, -14.0, 14.0), 0.0, user_z - 7.8),
		Vector3(clampf(user_x + side * 6.2, -16.0, 16.0), 0.0, user_z - 6.6),
		Vector3(clampf(-user_x, -14.0, 14.0), 0.0, user_z - 9.2),
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

# ==============================================================================
# LEMPARAN DALAM REKAN SETIM (HANYA REKAN YANG MELEMPAR + USER GERAK BEBAS + AUTO-AIM!)
# ==============================================================================
func setup_throw_in_for_test(side: float = 1.0, z_pos: float = -24.0) -> void:
	_trigger_key_moment(MomentType.THROW_IN)
	_setup_throw_in_moment(side, z_pos)

func _setup_throw_in_moment(side_override: float = 0.0, z_override: float = 999.0) -> void:
	_phase = MatchPhase.THROW_IN_PREP
	_moment_type = MomentType.THROW_IN
	_controlling_teammate_idx = -1
	_throw_in_side = side_override if absf(side_override) > 0.1 else (-1.0 if randf() < 0.5 else 1.0)
	_throw_in_z = clampf(z_override, -40.0, -10.0) if z_override < 900.0 else randf_range(-34.0, -16.0)
	_throw_in_timer = 0.0
	_throw_in_duration = 2.4
	_throw_in_thrown = false
	_throw_in_flight_t = 0.0
	_throw_in_flight_dur = 0.70
	_shot_by_teammate = false
	_carry_assist_pending = false
	_dribble_input = Vector2.ZERO
	if _dribble_pad != null:
		_dribble_pad.reset_joy()
	_trail_points.clear()
	_trail_imm.clear_surfaces()
	_aim_imm.clear_surfaces()
	_ring_imm.clear_surfaces()

	for tm in _teammates:
		tm.visible = false
		tm.frame = 4
	for df in _defenders:
		df.visible = false
		df.frame = 0
		df.rotation_degrees.z = 0.0
	_teammate_positions.clear()
	_teammate_vels.clear()
	_teammate_targets.clear()
	_teammate_open_scores.clear()
	_defender_positions.clear()
	_defender_dirs.clear()

	# Teammate 0 stands strictly on the touchline (x = +/-34.15) holding ball overhead!
	var thrower_pos := Vector3(_throw_in_side * 34.15, 0.0, _throw_in_z)
	_teammates[0].visible = true
	_teammate_positions.append(thrower_pos)
	_teammate_vels.append(Vector3.ZERO)
	_teammate_targets.append(thrower_pos)
	_teammate_open_scores.append(2.0)

	# Supporting teammates further inward/forward as passing options after reception
	var supp_spots := [
		Vector3(_throw_in_side * 12.0, 0.0, clampf(_throw_in_z - 5.5, -45.0, -12.0)),
		Vector3(-_throw_in_side * 5.0, 0.0, clampf(_throw_in_z - 8.5, -46.0, -15.0)),
	]
	for si in range(supp_spots.size()):
		if si + 1 < _teammates.size():
			_teammates[si + 1].visible = true
			_teammate_positions.append(supp_spots[si])
			_teammate_vels.append(Vector3.ZERO)
			_teammate_targets.append(supp_spots[si])
			_teammate_open_scores.append(3.0)

	# User player starts ~10m inside from sideline, FREE TO RUN to open space!
	_player_pos = Vector3(_throw_in_side * 24.0, 0.0, clampf(_throw_in_z - 1.5, -42.0, -10.0))
	_player_sprite.visible = true
	_player_sprite.frame = 4

	# Defenders nearby (def 0 loosely shadows user with lag so moving creates genuine space!)
	var def_spots := [
		Vector3(_throw_in_side * 20.8, 0.0, clampf(_throw_in_z - 4.8, -46.0, -12.0)),
		Vector3(_throw_in_side * 11.5, 0.0, clampf(_throw_in_z - 9.0, -47.0, -16.0)),
		Vector3(-_throw_in_side * 3.5, 0.0, clampf(_throw_in_z - 11.0, -48.0, -20.0)),
	]
	for di in range(def_spots.size()):
		if di < _defenders.size():
			_defenders[di].visible = true
			_defender_positions.append(def_spots[di])
			_defender_dirs.append(1.0)

	# Ball lifted overhead in thrower's hands!
	_ball_pos = Vector3(thrower_pos.x - _throw_in_side * 0.18, 1.95, thrower_pos.z)
	_ball_vel = Vector3.ZERO
	_ball_omega = Vector3.ZERO
	_throw_in_start_pos = _ball_pos
	_throw_in_target_pos = _player_pos

	_moment_title_lbl.text = "LEMPARAN DALAM REKAN!"
	_moment_sub_lbl.text = "Gerakkan pemainmu untuk cari ruang kosong, bola otomatis diarahkan pas ke kamu!"
	_ticker_lbl.text = "Lemparan rekan! Cari ruang (SPACE = lempar)."
	_moment_banner.visible = true
	_sync_action_bar()
	_configure_moment_camera()
	_sync_3d_sprites()
	_draw_throw_in_aim_ring(thrower_pos)
	AudioSynth.play_whistle(false)

func _release_teammate_throw_in() -> void:
	if _throw_in_thrown:
		return
	_throw_in_thrown = true
	_throw_in_flight_t = 0.0
	var thrower_pos: Vector3 = _teammate_positions[0] if not _teammate_positions.is_empty() else Vector3(_throw_in_side * 34.15, 0.0, _throw_in_z)
	_throw_in_start_pos = Vector3(thrower_pos.x - _throw_in_side * 0.22, 1.95, thrower_pos.z)
	_throw_in_target_pos = _player_pos + Vector3(0.0, 0.0, -0.45)
	var dist_t: float = Vector2(_throw_in_target_pos.x - _throw_in_start_pos.x, _throw_in_target_pos.z - _throw_in_start_pos.z).length()
	_throw_in_flight_dur = clampf(dist_t / 16.5, 0.48, 1.05)
	if not _teammates.is_empty():
		_teammates[0].frame = 7
	_moment_title_lbl.text = "BOLA DILEMPAR KE ARAHMU!"
	_moment_sub_lbl.text = "Lemparan auto-aim meluncur tepat menuju posisimu!"
	AudioSynth.play_kick(0.55)

func _draw_throw_in_aim_ring(thrower_pos: Vector3) -> void:
	_ring_imm.clear_surfaces()
	_aim_imm.clear_surfaces()
	var tgt: Vector3 = _player_pos
	# Crisp glowing cyan auto-aim reception ring around user's feet
	var ring_col := Color("#38BDF8") if not _throw_in_thrown else Color("#FACC15")
	_ring_imm.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var segs := 32
	var r_in := 1.45
	var r_out := 1.72
	for i in range(segs):
		if i % 3 == 2:
			continue
		var a0: float = float(i) / float(segs) * TAU
		var a1: float = float(i + 1) / float(segs) * TAU
		var p0_in := Vector3(tgt.x + cos(a0) * r_in, 0.05, tgt.z + sin(a0) * r_in)
		var p0_out := Vector3(tgt.x + cos(a0) * r_out, 0.05, tgt.z + sin(a0) * r_out)
		var p1_in := Vector3(tgt.x + cos(a1) * r_in, 0.05, tgt.z + sin(a1) * r_in)
		var p1_out := Vector3(tgt.x + cos(a1) * r_out, 0.05, tgt.z + sin(a1) * r_out)
		_ring_imm.surface_set_color(ring_col)
		_ring_imm.surface_add_vertex(p0_in)
		_ring_imm.surface_add_vertex(p0_out)
		_ring_imm.surface_add_vertex(p1_out)
		_ring_imm.surface_add_vertex(p0_in)
		_ring_imm.surface_add_vertex(p1_out)
		_ring_imm.surface_add_vertex(p1_in)
	_ring_imm.surface_end()

	# Dotted auto-aim throw arc preview from thrower's overhead hands -> live user position!
	if not _throw_in_thrown:
		var start_p := Vector3(thrower_pos.x - _throw_in_side * 0.2, 1.95, thrower_pos.z)
		var end_p := Vector3(tgt.x, 0.25, tgt.z)
		var dist_h: float = Vector2(end_p.x - start_p.x, end_p.z - start_p.z).length()
		var peak_h: float = clampf(dist_h * 0.12, 1.2, 3.1)
		_aim_imm.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		var steps := 14
		for si in range(steps):
			if si % 2 == 1:
				continue
			var u0: float = float(si) / float(steps)
			var u1: float = float(si + 1) / float(steps)
			var p0 := start_p.lerp(end_p, u0)
			p0.y = lerpf(1.95, 0.25, u0) + sin(u0 * PI) * peak_h
			var p1 := start_p.lerp(end_p, u1)
			p1.y = lerpf(1.95, 0.25, u1) + sin(u1 * PI) * peak_h
			var dir_xz := Vector3(p1.x - p0.x, 0.0, p1.z - p0.z)
			var side_v := Vector3(-dir_xz.z, 0.0, dir_xz.x).normalized() * 0.14 if dir_xz.length() > 0.01 else Vector3(0.14, 0.0, 0.0)
			var col_a := Color(0.22, 0.85, 1.0, 0.78)
			_aim_imm.surface_set_color(col_a)
			_aim_imm.surface_add_vertex(p0 - side_v)
			_aim_imm.surface_add_vertex(p0 + side_v)
			_aim_imm.surface_add_vertex(p1 + side_v)
			_aim_imm.surface_add_vertex(p0 - side_v)
			_aim_imm.surface_add_vertex(p1 + side_v)
			_aim_imm.surface_add_vertex(p1 - side_v)
		_aim_imm.surface_end()

func _process_throw_in_prep(delta: float) -> void:
	_throw_in_timer += delta
	var stride_back: int = 5 if fmod(_anim_clock, 0.28) < 0.14 else 6
	var stride_front: int = 1 if fmod(_anim_clock, 0.30) < 0.15 else 2
	var thrower_pos: Vector3 = _teammate_positions[0] if not _teammate_positions.is_empty() else Vector3(_throw_in_side * 34.15, 0.0, _throw_in_z)

	# 1. User Player CAN MOVE FREELY (Joystick / WASD / Arrow Keys) before & during throw-in!
	var joy: Vector2 = _read_user_move_vec()
	if joy.length() > 0.08:
		var spd_attr: int = CareerState.get_effective_attribute("kecepatan") if CareerState.has_active_career else 68
		var move_spd: float = get_player_max_run_speed(spd_attr) * clampf(joy.length(), 0.0, 1.0)
		_dribble_facing = joy.normalized()
		var nx: float = clampf(_player_pos.x + joy.x * move_spd * delta, -31.8, 31.8)
		var nz: float = clampf(_player_pos.z + joy.y * move_spd * delta, -48.5, 14.0)
		var cand := Vector3(nx, 0.0, nz)
		# Keep within realistic throw-in reach (28m from touchline taker)
		var from_t := Vector2(cand.x - thrower_pos.x, cand.z - thrower_pos.z)
		if from_t.length() > 28.0:
			var clamped_2d: Vector2 = from_t.normalized() * 28.0
			cand.x = clampf(thrower_pos.x + clamped_2d.x, -31.8, 31.8)
			cand.z = clampf(thrower_pos.z + clamped_2d.y, -48.5, 14.0)
		_player_pos = cand
		_player_sprite.frame = stride_back
	else:
		_player_sprite.frame = 4

	# 2. Defender 0 loosely shadows user with realistic reaction lag so user movement creates space!
	if not _defender_positions.is_empty():
		var mark_tgt := Vector3(clampf(_player_pos.x - _throw_in_side * 1.8, -30.0, 30.0), 0.0, clampf(_player_pos.z - 2.6, -48.0, 12.0))
		var to_m := Vector3(mark_tgt.x - _defender_positions[0].x, 0.0, mark_tgt.z - _defender_positions[0].z)
		if to_m.length() > 0.35:
			_defender_positions[0] += to_m.normalized() * 2.55 * delta
			if not _defenders.is_empty():
				_defenders[0].frame = stride_front
		elif not _defenders.is_empty():
			_defenders[0].frame = 0

	# 3. Preparation vs Live Auto-Aim Overhead Throw Flight!
	if not _throw_in_thrown:
		var windup_bob: float = sin(_throw_in_timer * 6.0) * 0.07
		_ball_pos = Vector3(thrower_pos.x - _throw_in_side * 0.18, 1.95 + windup_bob, thrower_pos.z)
		if not _teammates.is_empty():
			_teammates[0].frame = 4
		var rem_s: float = maxf(0.0, _throw_in_duration - _throw_in_timer)
		_moment_sub_lbl.text = "Cari ruang kosong (%.1fd), bola otomatis diarahkan pas ke posisimu!" % rem_s
		_draw_throw_in_aim_ring(thrower_pos)
		if _throw_in_timer >= _throw_in_duration:
			_release_teammate_throw_in()
	else:
		_throw_in_flight_t += delta
		var u: float = clampf(_throw_in_flight_t / maxf(0.15, _throw_in_flight_dur), 0.0, 1.0)
		# LIVE AUTO-AIM HOMING: tracks user's live position so the throw ALWAYS lands accurately at user!
		var desired_land := _player_pos + Vector3(0.0, 0.0, -0.55)
		_throw_in_target_pos = _throw_in_target_pos.lerp(desired_land, clampf(delta * 14.0, 0.0, 1.0))
		var dist_h: float = Vector2(_throw_in_target_pos.x - _throw_in_start_pos.x, _throw_in_target_pos.z - _throw_in_start_pos.z).length()
		var peak_h: float = clampf(dist_h * 0.12, 1.2, 3.1)
		var horiz := _throw_in_start_pos.lerp(_throw_in_target_pos, u)
		var arc_y: float = lerpf(1.95, 0.12, u) + sin(u * PI) * peak_h
		_ball_pos = Vector3(horiz.x, arc_y, horiz.z)
		_trail_points.append(_ball_pos)
		if _trail_points.size() > 18:
			_trail_points.pop_front()
		_draw_ball_trail()
		_draw_throw_in_aim_ring(thrower_pos)

		if u >= 1.0:
			# Move throw-in taker smoothly back inside touchline as an active passing teammate
			if not _teammate_positions.is_empty():
				_teammate_positions[0] = Vector3(_throw_in_side * 31.2, 0.0, _throw_in_z)
				_teammate_vels[0] = Vector3(-_throw_in_side * 1.2, 0.0, -2.6)
				_teammate_targets[0] = Vector3(_throw_in_side * 22.0, 0.0, clampf(_throw_in_z - 12.0, -47.0, -14.0))
			_passes_won += 1
			_enter_user_follow_up_shot(
				"LEMPARAN DITERIMA PAS!",
				"Bola lemparan dalam tepat di kakimu! Giring bebas, oper rekan, atau tembak!"
			)
			return

	_sync_3d_sprites()

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

	if _incoming_pass_is_our_gk:
		var def_recv_pos: Vector3 = _teammate_positions[0] if not _teammate_positions.is_empty() else _player_pos
		if not _teammate_positions.is_empty():
			def_recv_pos.z = clampf(def_recv_pos.z - 0.8 * delta, -12.0, 38.0)
			_teammate_positions[0] = def_recv_pos
			if not _teammates.is_empty():
				_teammates[0].frame = stride_back
		_player_pos.z = clampf(_player_pos.z - 1.4 * delta, -20.0, 20.0)
		_player_sprite.frame = stride_back
		_gk_dive_dir = 0.0
		if not _incoming_pass_kicked:
			if _incoming_pass_timer >= 0.38:
				_incoming_pass_kicked = true
				_clear_defender_slides()
				if is_instance_valid(_our_gk_sprite):
					_our_gk_sprite.frame = 7
				AudioSynth.play_kick(0.66)
		else:
			var target_gk := def_recv_pos + Vector3(0.0, 0.12, -0.75)
			var to_t := target_gk - _ball_pos
			var dist_gk := Vector2(to_t.x, to_t.z).length()
			if dist_gk > 0.05:
				var step_gk := Vector3(to_t.x, 0.0, to_t.z).normalized() * minf(dist_gk, 16.5 * delta)
				_ball_pos.x += step_gk.x
				_ball_pos.z += step_gk.z
				_ball_pos.y = 0.12 + 0.55 * sin(clampf((_incoming_pass_timer - 0.38) * 2.8, 0.0, PI))
			if dist_gk < 1.25 or _incoming_pass_timer >= 2.2:
				_incoming_pass_is_our_gk = false
				if not _teammate_positions.is_empty():
					_enter_teammate_user_control(0, false)
					_moment_title_lbl.text = "BOLA DARI KIPER KE BEK!"
					_moment_sub_lbl.text = "Bek menerima bola kiper — giring atau oper ke pemainmu di depan!"
				else:
					_enter_user_follow_up_shot("BOLA DARI KIPER DITERIMA!", "Kendalikan serangan dari bawah! Giring, oper rekan, atau tembak!")
				return
		_animate_teammates(delta)
		_sync_3d_sprites()
		return

	# User runs forward into pocket; passer advances until kick, then ball zips to user's feet
	_player_pos.z = clampf(_player_pos.z - 3.6 * delta, -44.5, -18.0)
	_player_sprite.frame = stride_back
	_gk_dive_dir = 0.0

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
			_clear_defender_slides()
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
			# Counter-attack pass into attacking zone can trigger SALTO (Bicycle Kick) or VOLI (Volley)!
			var acro_style: String = ""
			if _player_pos.z <= -22.0:
				var tek_bonus: float = float(CareerState.get_effective_attribute("teknik") - 60) * 0.003 if CareerState.has_active_career else 0.0
				var roll_a: float = randf()
				if roll_a < clampf(0.20 + tek_bonus, 0.14, 0.30):
					acro_style = "SALTO"
				elif roll_a < clampf(0.46 + tek_bonus, 0.36, 0.58):
					acro_style = "VOLI"
			if acro_style == "SALTO":
				_enter_user_follow_up_shot("PELUANG SALTO! (SERANGAN BALIK)", "Bola melambung pas di atas kepala! Tarik ketapel untuk TENDANGAN SALTO!", "SALTO")
			elif acro_style == "VOLI":
				_enter_user_follow_up_shot("PELUANG VOLI! (SERANGAN BALIK)", "Umpan lambung matang! Tarik ketapel untuk TENDANGAN VOLI keras!", "VOLI")
			else:
				_enter_user_follow_up_shot("UMPAN REKAN DITERIMA!", "Tarik ketapel TEMBAK, kirim UMPAN lagi, atau pakai DRIBEL!")
			return

	var agil_inc: float = get_opp_defender_agility()
	var d_base_inc: float = float(SettingsManager.get_difficulty_params().get("dribble_defender_speed", 2.2))
	_ensure_defender_slide_arrays()
	for i in range(_defender_positions.size()):
		if i < _defenders.size() and not _defenders[i].visible:
			continue
		if _incoming_pass_kicked:
			var to_ball_inc := Vector3(_ball_pos.x - _defender_positions[i].x, 0.0, _ball_pos.z - _defender_positions[i].z)
			var dist_b: float = to_ball_inc.length()
			if _defender_slide_timers[i] > 0.0:
				_defender_slide_timers[i] = maxf(0.0, _defender_slide_timers[i] - delta)
				_defender_positions[i] += _defender_slide_dirs[i] * (7.5 * agil_inc) * delta
				var inc_passed: bool = Vector2(_ball_pos.x - _defender_positions[i].x, _ball_pos.z - _defender_positions[i].z).dot(Vector2(_defender_slide_dirs[i].x, _defender_slide_dirs[i].z)) < -0.25
				if _defender_slide_timers[i] <= 0.0 or (_defender_slide_timers[i] < 0.28 and (inc_passed or _ball_pos.y > 1.85)):
					_defender_slide_timers[i] = 0.0
					if i < _defenders.size():
						_defenders[i].billboard = BaseMaterial3D.BILLBOARD_ENABLED
						_defenders[i].rotation_degrees = Vector3.ZERO
						_defenders[i].frame = 0
				elif i < _defenders.size():
					_defenders[i].frame = 3
					_defenders[i].rotation_degrees.z = 42.0 if _defender_slide_dirs[i].x >= 0.0 else -42.0
			elif d_base_inc > 0.5 and not _defender_slid_this_kick[i] and dist_b < (3.4 * agil_inc) and dist_b > 0.90 and _ball_pos.y < 1.35:
				# Agile defender launches slide tackle ONLY after teammate kicked the pass, once per pass
				_defender_slid_this_kick[i] = true
				_defender_slide_timers[i] = 0.36
				_defender_slide_dirs[i] = to_ball_inc.normalized()
				if i < _defenders.size():
					_defenders[i].frame = 3
					_defenders[i].rotation_degrees.z = 42.0 if _defender_slide_dirs[i].x >= 0.0 else -42.0
			else:
				var tgt_d := Vector3(_player_pos.x + (float(i) - 1.0) * 2.4, 0.0, maxf(-45.5, _player_pos.z - 4.8))
				var to_d := Vector3(tgt_d.x - _defender_positions[i].x, 0.0, tgt_d.z - _defender_positions[i].z)
				if to_d.length() > 0.3:
					_defender_positions[i] += to_d.normalized() * (2.4 * agil_inc) * delta
					if i < _defenders.size():
						_defenders[i].frame = stride_front
			var is_sl: bool = (_defender_slide_timers[i] > 0.0)
			if Vector2(_ball_pos.x - _defender_positions[i].x, _ball_pos.z - _defender_positions[i].z).length() < (1.15 if is_sl else 0.78) and _ball_pos.y < 1.35:
				AudioSynth.play_save()
				_sync_3d_sprites()
				_show_moment_result("UMPAN REKAN DISLEDING BEK!" if is_sl else "UMPAN REKAN DIPOTONG BEK!", UITheme.ACCENT_RED, 1.35)
				return
		else:
			var tgt_d := Vector3(_player_pos.x + (float(i) - 1.0) * 2.6, 0.0, maxf(-45.5, _player_pos.z - 5.5))
			var to_d := Vector3(tgt_d.x - _defender_positions[i].x, 0.0, tgt_d.z - _defender_positions[i].z)
			if to_d.length() > 0.3:
				_defender_positions[i] += to_d.normalized() * (2.2 * agil_inc) * delta
				if i < _defenders.size():
					_defenders[i].frame = stride_front
	_sync_3d_sprites()

func _enter_user_follow_up_shot(title_msg: String, sub_msg: String, acrobatic_style: String = "") -> void:
	_phase = MatchPhase.KEY_MOMENT_AIM
	_moment_type = MomentType.SHOT
	_controlling_teammate_idx = -1
	_acrobatic_ready_style = acrobatic_style
	_user_assisted_pass = false
	_user_hockey_assist_eligible = false
	_shot_by_teammate = false
	_carry_assist_pending = false
	_incoming_pass_kicked = false
	_incoming_pass_is_our_gk = false
	_post_rebound_eligible = false
	_scramble_is_loose_pass = false
	_dragging = false
	_clear_defender_slides()
	_dribble_input = Vector2.ZERO
	_spin_offset = Vector2.ZERO
	_spin_pad.reset_spin()
	_spin_pad.visible = (run_mode != RunMode.MOVIOLA_REPLAY)
	_power_lbl.visible = true
	_power_lbl.text = ""
	_ball_vel = Vector3.ZERO
	_ball_omega = Vector3.ZERO
	_player_sprite.frame = 4
	var init_ball_y: float = 1.48 if _acrobatic_ready_style == "SALTO" else (1.02 if _acrobatic_ready_style == "VOLI" else 0.115)
	_ball_pos = _player_pos + Vector3(0.0, init_ball_y, -0.95)
	_moment_title_lbl.text = title_msg
	_moment_sub_lbl.text = sub_msg
	_ticker_lbl.text = "Peluang terbuka! Giring bebas atau langsung tembak/umpan!"
	_moment_banner.visible = true
	_update_pass_openness_ui()
	_sync_action_bar()
	_configure_moment_camera()
	_sync_3d_sprites()
	_draw_aim_and_ring()
	AudioSynth.play_click()

func _enter_rebound_scramble(banner_msg: String, is_loose_pass: bool = false) -> void:
	_phase = MatchPhase.REBOUND_SCRAMBLE
	_scramble_is_loose_pass = is_loose_pass
	_rebound_timer = 0.0
	_rebound_grace = 0.12 if is_loose_pass else 0.24
	if is_loose_pass:
		# Preserve strong >= 65% long-ball momentum; only gently cushion soft through-balls
		var hvel := Vector2(_ball_vel.x, _ball_vel.z)
		var max_cap: float = 22.0 if _last_kick_power_ratio >= 0.65 else 13.5
		if hvel.length() > max_cap:
			hvel = hvel.normalized() * max_cap
			_ball_vel.x = hvel.x
			_ball_vel.z = hvel.y
	_dragging = false
	_clear_defender_slides()
	_spin_pad.visible = false
	_power_lbl.visible = false
	if _action_bar != null:
		_action_bar.visible = false
	if _dribble_pad != null:
		_dribble_pad.visible = false
	if _stamina_bar_bg != null:
		_stamina_bar_bg.visible = false
	_moment_banner.visible = true
	_moment_title_lbl.text = "KEJAR BOLA!" if is_loose_pass else "BOLA REBOUND!"
	_moment_sub_lbl.text = banner_msg
	_ticker_lbl.text = banner_msg
	_aim_imm.clear_surfaces()
	_ring_imm.clear_surfaces()

	# Ensure box battle / loose-ball chase feels populated with at least 2 teammates and 2-3 chasing defenders
	while _teammate_positions.size() < 2 and _teammate_positions.size() < _teammates.size():
		var tidx := _teammate_positions.size()
		var sx := clampf(_ball_pos.x + (-4.8 if tidx == 0 else 4.8), -28.0, 28.0)
		var sz := clampf(_ball_pos.z + 4.5, -45.0, 44.0)
		_teammates[tidx].visible = true
		_teammate_positions.append(Vector3(sx, 0.0, sz))
		_teammate_vels.append(Vector3.ZERO)
		_teammate_targets.append(Vector3(sx, 0.0, maxf(-48.0, sz - 5.0)))
		_teammate_open_scores.append(2.5)
	while _defender_positions.size() < 2 and _defender_positions.size() < _defenders.size():
		var didx := _defender_positions.size()
		var dx := clampf(_ball_pos.x + (-4.2 if didx == 0 else 4.2), -28.0, 28.0)
		var dz := clampf(_ball_pos.z - 5.2, -48.0, 40.0)
		_defenders[didx].visible = true
		_defender_positions.append(Vector3(dx, 0.0, dz))
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
	var grass_damp: float = 0.22 if (_scramble_is_loose_pass and _last_kick_power_ratio >= 0.65) else (0.50 if _scramble_is_loose_pass else 0.45)
	_ball_vel.x *= maxf(0.0, 1.0 - grass_damp * delta)
	_ball_vel.z *= maxf(0.0, 1.0 - grass_damp * delta)

	var stride_back: int = 5 if fmod(_anim_clock, 0.28) < 0.14 else 6
	var stride_front: int = 1 if fmod(_anim_clock, 0.28) < 0.14 else 2
	var lead_pt := Vector3(clampf(_ball_pos.x + _ball_vel.x * 0.16, -32.8, 32.8), 0.0, clampf(_ball_pos.z + _ball_vel.z * 0.16, -51.5, 50.0))

	# 1. User runs toward ball (full speed on rebound or if user wasn't the recent passer)
	var spd_attr := CareerState.get_effective_attribute("kecepatan") if CareerState.has_active_career else 68
	var user_spd := lerpf(5.8, 8.4, float(spd_attr) / 100.0)
	var u_chase_mult: float = 0.72 if (_scramble_is_loose_pass and _controlling_teammate_idx < 0 and _rebound_timer < 0.55) else 1.0
	var u_dir := Vector3(lead_pt.x - _player_pos.x, 0.0, lead_pt.z - _player_pos.z)
	if u_dir.length() > 0.1:
		_player_pos += u_dir.normalized() * (user_spd * u_chase_mult) * delta
	_player_sprite.frame = stride_back

	# 2. Rank teammates & opponents by proximity so players closest to the empty-space ball sprint to chase it!
	var tm_dists: Array[Dictionary] = []
	for i in range(_teammate_positions.size()):
		if _scramble_is_loose_pass and i == _controlling_teammate_idx and _rebound_timer < 0.55:
			continue
		var d_tm := Vector2(_ball_pos.x - _teammate_positions[i].x, _ball_pos.z - _teammate_positions[i].z).length()
		tm_dists.append({"idx": i, "dist": d_tm})
	tm_dists.sort_custom(func(a, b): return float(a["dist"]) < float(b["dist"]))
	var near_tm_a: int = int(tm_dists[0]["idx"]) if tm_dists.size() >= 1 else -1
	var near_tm_b: int = int(tm_dists[1]["idx"]) if tm_dists.size() >= 2 else -1

	for i in range(_teammate_positions.size()):
		if _scramble_is_loose_pass and i == _controlling_teammate_idx and _rebound_timer < 0.55:
			continue
		var dist_to_b := Vector2(_ball_pos.x - _teammate_positions[i].x, _ball_pos.z - _teammate_positions[i].z).length()
		var is_nearby_tm := (i == near_tm_a or i == near_tm_b or dist_to_b < 15.0)
		var t_tgt := lead_pt if is_nearby_tm else Vector3(-_ball_pos.x * 0.4, 0.0, maxf(-44.0, _ball_pos.z - 2.0))
		var t_dir := Vector3(t_tgt.x - _teammate_positions[i].x, 0.0, t_tgt.z - _teammate_positions[i].z)
		if t_dir.length() > 0.15:
			var tm_chase_spd: float = ((6.1 if i == near_tm_a else 5.2) if _scramble_is_loose_pass else (5.6 if i == near_tm_a else 4.8)) * get_teammate_speed_scale(i)
			_teammate_positions[i] += t_dir.normalized() * tm_chase_spd * delta
			if i < _teammates.size():
				_teammates[i].frame = stride_back

	# 3. Nearby opponent defenders chase loose ball based on difficulty & OVR agility
	var diff_p := SettingsManager.get_difficulty_params()
	var def_chase_spd := clampf((float(diff_p.get("defender_speed", 1.6)) * 1.25 + 3.8) * get_opp_defender_agility(), 4.2, 9.2)
	var df_dists: Array[Dictionary] = []
	for i in range(_defender_positions.size()):
		if i < _defenders.size() and not _defenders[i].visible:
			continue
		var d_df := Vector2(_ball_pos.x - _defender_positions[i].x, _ball_pos.z - _defender_positions[i].z).length()
		df_dists.append({"idx": i, "dist": d_df})
	df_dists.sort_custom(func(a, b): return float(a["dist"]) < float(b["dist"]))
	var near_df_a: int = int(df_dists[0]["idx"]) if df_dists.size() >= 1 else -1
	var near_df_b: int = int(df_dists[1]["idx"]) if df_dists.size() >= 2 else -1

	for i in range(_defender_positions.size()):
		if i < _defenders.size() and not _defenders[i].visible:
			continue
		var dist_df := Vector2(_ball_pos.x - _defender_positions[i].x, _ball_pos.z - _defender_positions[i].z).length()
		var is_nearby_df := (i == near_df_a or i == near_df_b or dist_df < 15.0)
		var d_tgt := lead_pt if is_nearby_df else Vector3(clampf(_ball_pos.x * 0.4, -10.0, 10.0), 0.0, clampf(_ball_pos.z - 6.0, -47.0, 25.0))
		var d_dir := Vector3(d_tgt.x - _defender_positions[i].x, 0.0, d_tgt.z - _defender_positions[i].z)
		if d_dir.length() > 0.15:
			var sp_mult := 1.0 if i == near_df_a else 0.85
			_defender_positions[i] += d_dir.normalized() * def_chase_spd * sp_mult * delta
			if i < _defenders.size():
				_defenders[i].frame = stride_front

	# 4. Opponent GK only advances & chases loose ball once it enters the penalty area!
	if _ball_pos.z < -36.0 and absf(_ball_pos.x) < 16.5:
		var gk_rush := float(get_opp_gk_profile().get("rush_speed", 2.8))
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
		var tm_protected: bool = (_carry_assist_pending or _shot_by_teammate or _controlling_teammate_idx >= 0 or _user_assisted_pass or _user_hockey_assist_eligible)
		if Vector2(_gk_pos.x - _ball_pos.x, _gk_pos.z - _ball_pos.z).length() < 1.18:
			_gk_sprite.frame = 3
			AudioSynth.play_save()
			if _carry_assist_pending or _user_assisted_pass:
				_carry_assist_pending = true
				_credit_key_pass_if_pending()
			elif not _shot_on_target_credit and not tm_protected and not _scramble_is_loose_pass:
				_adjust_rating(-0.15, "REBOUND GAGAL")
			_show_moment_result("BOLA DIAMANKAN KIPER!" if _scramble_is_loose_pass else "REBOUND DIAMANKAN KIPER!", UITheme.ACCENT_GOLD if _key_pass_awarded else UITheme.ACCENT_CYAN, 1.35)
			return
		for i in range(_defender_positions.size()):
			if i < _defenders.size() and not _defenders[i].visible:
				continue
			if Vector2(_defender_positions[i].x - _ball_pos.x, _defender_positions[i].z - _ball_pos.z).length() < 1.08:
				if i < _defenders.size():
					_defenders[i].frame = 3
				AudioSynth.play_save()
				if _carry_assist_pending or _user_assisted_pass:
					_carry_assist_pending = true
					_credit_key_pass_if_pending()
				elif not _shot_on_target_credit and not tm_protected:
					_adjust_rating(-0.15, "DIREBUT BEK" if _scramble_is_loose_pass else "REBOUND GAGAL")
				_show_moment_result("BOLA DIKEJAR & DIREBUT BEK!" if _scramble_is_loose_pass else "REBOUND DISAPU BEK LAWAN!", UITheme.ACCENT_GOLD if _key_pass_awarded else UITheme.ACCENT_RED, 1.35)
				return
		for i in range(_teammate_positions.size()):
			if _scramble_is_loose_pass and i == _controlling_teammate_idx and _rebound_timer < 0.55:
				continue
			if Vector2(_teammate_positions[i].x - _ball_pos.x, _teammate_positions[i].z - _ball_pos.z).length() < 1.35:
				if _scramble_is_loose_pass and i < _kick_offside_flags.size() and _kick_offside_flags[i]:
					AudioSynth.play_whistle(true)
					_adjust_rating(-0.25, "OFFSIDE")
					_draw_offside_line_freeze(_kick_offside_line_z)
					_show_moment_result("OFFSIDE! BENDERA TERANGKAT", UITheme.ACCENT_RED, 1.4)
					return
				if i < _teammates.size():
					_teammates[i].frame = 7
				if _scramble_is_loose_pass:
					_passes_won += 1
					if _teammate_positions[i].z < -31.5:
						_start_teammate_carry(i, _controlling_teammate_idx < 0, true, _user_hockey_assist_eligible)
					else:
						_enter_teammate_user_control(i, _controlling_teammate_idx < 0)
				else:
					# Rebound chased & won by a teammate -> AUTOMATIC IMMEDIATE SHOT ON GOAL!
					_fire_teammate_auto_shot(i, _scramble_from_penalty_rebound)
				return
		var user_can_pickup: bool = (not _scramble_is_loose_pass or _controlling_teammate_idx >= 0 or _rebound_timer >= 0.55) and _ball_pos.z < (49.5 if _scramble_is_loose_pass else -24.0)
		if user_can_pickup and Vector2(_player_pos.x - _ball_pos.x, _player_pos.z - _ball_pos.z).length() < 1.32:
			var tit := "BOLA KEJARAN DIDAPAT!" if _scramble_is_loose_pass else "REBOUND DIDAPAT! TEMBAK!"
			_enter_user_follow_up_shot(tit, "Bola dikuasai! Giring bebas atau langsung tembak/umpan!")
			return

	var z_back_lim: float = 52.5 if _scramble_is_loose_pass else -16.0
	if _rebound_timer > 4.2 or _ball_pos.z < -56.0 or _ball_pos.z > z_back_lim or absf(_ball_pos.x) > 36.0:
		if _carry_assist_pending or _user_assisted_pass:
			_carry_assist_pending = true
			_credit_key_pass_if_pending()
		elif not _shot_on_target_credit and not (_shot_by_teammate or _controlling_teammate_idx >= 0 or _user_hockey_assist_eligible):
			_adjust_rating(-0.15, "BOLA KELUAR" if _scramble_is_loose_pass else "REBOUND GAGAL")
		_show_moment_result("BOLA KELUAR LAPANGAN!" if _scramble_is_loose_pass else "BOLA REBOUND KELUAR!", UITheme.ACCENT_GOLD if _key_pass_awarded else Color("#F97316"), 1.25)

func _fire_teammate_auto_shot(tm_idx: int, from_penalty_rebound: bool = false) -> void:
	if tm_idx < 0 or tm_idx >= _teammate_positions.size():
		return
	var shooter_pos: Vector3 = _teammate_positions[tm_idx]
	if tm_idx < _teammates.size():
		_teammates[tm_idx].frame = 7
	# Place ball cleanly at teammate's shooting boot facing opponent goal
	_ball_pos = Vector3(shooter_pos.x, 0.14, maxf(-51.8, shooter_pos.z - 0.72))
	# Aim instinctively away from the diving/out-of-position GK toward the open corner!
	var open_side: float = 1.0 if _gk_pos.x <= 0.0 else -1.0
	var aim_x: float = open_side * randf_range(1.15, 3.25)
	var aim_pt := Vector3(aim_x, randf_range(0.35, 1.55), -52.6)
	var shot_spd: float = randf_range(24.5, 29.0)
	_ball_vel = (aim_pt - _ball_pos).normalized() * shot_spd + Vector3(0.0, 0.85, 0.0)
	_ball_omega = Vector3(0.0, open_side * randf_range(0.8, 1.8), 0.0)
	_flight_timer = 0.0
	_gk_react_timer = float(get_opp_gk_profile().get("reaction_delay", 0.24)) * 1.18
	_post_rebound_eligible = false
	_scramble_from_penalty_rebound = false
	_scramble_is_loose_pass = false
	_carry_tm_idx = -1
	_controlling_teammate_idx = -1
	_shot_by_teammate = true
	_moment_type = MomentType.SHOT
	_phase = MatchPhase.BALL_IN_FLIGHT
	_clear_defender_slides()
	_aim_imm.clear_surfaces()
	_ring_imm.clear_surfaces()
	_moment_banner.visible = true
	_moment_title_lbl.text = "REKAN SAMBAR REBOUND PENALTI!" if from_penalty_rebound else "REKAN LANGSUNG TEMBAK REBOUND!"
	_moment_sub_lbl.text = "Rekan mendapatkan bola muntah dan otomatis melepaskan tembakan ke gawang!"
	_ticker_lbl.text = "Rekan sambar rebound dan langsung menembak!"
	_sync_3d_sprites()
	AudioSynth.play_kick(0.92)

static func is_outside_penalty_box(pos: Vector3) -> bool:
	# Pitch penalty area outer white line is at z = -36.5; D-arc extends around penalty spot (0, -41.5) radius 9.15m!
	var dist_to_spot: float = Vector2(pos.x, pos.z - (-41.5)).length()
	return pos.z > -36.2 and dist_to_spot >= 9.35

func setup_teammate_penalty_for_test() -> void:
	_trigger_key_moment(MomentType.TEAMMATE_PENALTY)

func trigger_penalty_rebound_for_test() -> void:
	_tm_penalty_kicked = true
	_scramble_from_penalty_rebound = true
	_ball_pos = Vector3(3.2, 0.25, -43.5)
	_ball_vel = Vector3(0.8, 0.8, 2.2)
	_gk_pos = Vector3(-2.6, 0.0, -51.2)
	if _teammate_positions.size() > 1:
		_teammate_positions[1] = Vector3(3.6, 0.0, -42.4)
	_player_pos = Vector3(-4.5, 0.0, -35.5)
	_enter_rebound_scramble("PENALTI DITEPIS KIPER! KEJAR REBOUND!")
	_rebound_grace = 0.0

func _setup_teammate_penalty() -> void:
	_phase = MatchPhase.TEAMMATE_PENALTY_WAIT
	_tm_penalty_timer = 0.0
	_tm_penalty_kicked = false
	_shot_by_teammate = true
	_post_rebound_eligible = true
	_scramble_from_penalty_rebound = false
	_ball_pos = Vector3(0.0, 0.115, -41.5)
	_ball_vel = Vector3.ZERO
	_ball_omega = Vector3.ZERO

	# ONLY Teammate 0 (penalty taker) is inside the box; ALL other players (User + Teammates + Defenders) stand STRICTLY OUTSIDE the penalty box & D-arc!
	_teammates[0].visible = true
	_teammate_positions.append(Vector3(0.0, 0.0, -38.8))
	_teammate_vels.append(Vector3(0.0, 0.0, -2.8))
	_teammate_targets.append(Vector3(0.0, 0.0, -41.2))
	_teammate_open_scores.append(2.0)

	_teammates[1].visible = true
	_teammate_positions.append(Vector3(5.4, 0.0, -33.2))
	_teammate_vels.append(Vector3.ZERO)
	_teammate_targets.append(Vector3(3.8, 0.0, -45.5))
	_teammate_open_scores.append(2.5)

	if _teammates.size() > 2:
		_teammates[2].visible = true
		_teammate_positions.append(Vector3(-9.6, 0.0, -35.0))
		_teammate_vels.append(Vector3.ZERO)
		_teammate_targets.append(Vector3(-4.6, 0.0, -45.5))
		_teammate_open_scores.append(2.4)

	# User player strictly outside BOTH the 16.5m box (z = -36.5) AND the D-arc (dist >= 9.35m from spot)!
	_player_pos = Vector3(-4.2, 0.0, -32.8)

	var d_spots := [
		Vector3(-7.4, 0.0, -34.4),
		Vector3(2.4, 0.0, -31.8),
		Vector3(8.8, 0.0, -34.8),
		Vector3(-1.8, 0.0, -31.8),
	]
	for i in range(d_spots.size()):
		if i < _defenders.size():
			_defenders[i].visible = true
			_defender_positions.append(d_spots[i])
			_defender_dirs.append(1.0)

	_moment_title_lbl.text = "PENALTI REKAN SETIM!"
	_moment_sub_lbl.text = "Semua pemain bersiap di luar kotak penalti, antisipasi bola rebound!"
	_ticker_lbl.text = "Penalti rekan setim! Bersiap kejar bola rebound."
	_moment_banner.visible = true
	_sync_action_bar()
	_configure_moment_camera()
	_sync_3d_sprites()
	AudioSynth.play_whistle(false)

func _process_teammate_penalty_wait(delta: float) -> void:
	_tm_penalty_timer += delta
	var stride_back: int = 5 if fmod(_anim_clock, 0.28) < 0.14 else 6
	# User stays strictly outside penalty box & D-arc while bobbing on toes ready to rush in
	_player_pos.x = -4.2 + sin(_anim_clock * 4.0) * 0.22
	_player_pos.z = -32.8
	_gk_dive_dir = 0.0
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
		_gk_react_timer = float(get_opp_gk_profile().get("reaction_delay", 0.25))
		_phase = MatchPhase.BALL_IN_FLIGHT
		AudioSynth.play_kick(0.85)
		# All box-edge teammates immediately burst forward into the box for potential rebound!
		_teammate_vels[0] = Vector3(0.0, 0.0, -1.8)
		if _teammate_vels.size() > 1:
			_teammate_vels[1] = Vector3(-0.8, 0.0, -5.0)
		if _teammate_vels.size() > 2:
			_teammate_vels[2] = Vector3(1.2, 0.0, -4.8)

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
	var u_dict: Dictionary = _get_user_roster_dict()
	if _shot_by_teammate:
		var tm_p: Dictionary = _pick_roster_player(true, false, true)
		var tm_name: String = str(tm_p.get("name", _pick_squad_member_name(true))).to_upper()
		if _carry_assist_pending:
			_my_assists += 1
			_adjust_rating(1.1, "ASSIST")
			_update_score_label()
			_update_last_shot("GOAL")
			_add_rich_board_highlight(int(_minute), "GOAL", "GOL %s!" % tm_name, "Assist brilian dari %s!" % u_name, tm_p, u_dict, true)
			_save_moviola_clip("ASSIST CANTIK!")
			_goal_timeline.append({"minute": int(_minute), "scorer": tm_name, "assist": u_name, "is_us": true, "is_user_involved": true, "clip": _best_clip.duplicate(true)})
			if is_instance_valid(_goal_flash_rect):
				_goal_flash_rect.color = Color(1.0, 0.92, 0.45, 0.55)
				create_tween().tween_property(_goal_flash_rect, "color:a", 0.0, 0.38)
			_start_goal_replay_then_celebration(tm_name, int(_minute), u_name, false)
			_show_moment_result("ASSIST! REKAN CETAK GOL!", UITheme.ACCENT_GOLD, 2.2)
			return
		var combo_bonus := _user_hockey_assist_eligible
		if combo_bonus:
			_adjust_rating(0.1, "KOMBINASI TIM")
		else:
			_adjust_rating(0.35, "GOL TIM")
		_update_score_label()
		_update_last_shot("GOAL")
		_add_rich_board_highlight(int(_minute), "GOAL", "GOL %s!" % tm_name, ("Kombinasi umpan apik bersama %s!" % u_name) if combo_bonus else "Rekan setim menjebol gawang lawan!", tm_p, u_dict if combo_bonus else {}, true)
		_save_moviola_clip("GOL KOMBINASI TIM!" if combo_bonus else "GOL REKAN SETIM!")
		_goal_timeline.append({"minute": int(_minute), "scorer": tm_name, "assist": "", "is_us": true, "is_user_involved": combo_bonus})
		if is_instance_valid(_goal_flash_rect):
			_goal_flash_rect.color = Color(1.0, 0.92, 0.45, 0.55)
			create_tween().tween_property(_goal_flash_rect, "color:a", 0.0, 0.38)
		_start_goal_replay_then_celebration(tm_name, int(_minute), "", false)
		_show_moment_result("GOOOOL KOMBINASI TIM! (+0.1 RATING)" if combo_bonus else "GOOOOL REKAN SETIM!", UITheme.ACCENT_GOLD, 2.2)
		return
	_my_goals += 1
	if _moment_type == MomentType.PENALTY:
		_penalties_scored += 1
	elif _moment_type == MomentType.FREE_KICK:
		_freekicks_scored += 1
	_adjust_rating(1.3, "GOL")
	_duel_score += 2
	_update_score_label()
	_update_last_shot("GOAL")
	_save_moviola_clip("GOL SPEKTAKULER!")
	var ast_tm: Dictionary = _pick_roster_player(true, false, false) if (_moment_type in [MomentType.HEADER_CROSS, MomentType.LONG_PASS_CONTROL, MomentType.TEAMMATE_PASS]) else {}
	var ast_nm: String = str(ast_tm.get("name", "")).to_upper() if not ast_tm.is_empty() else ""
	var goal_style: String = _last_shot_style if not _last_shot_style.is_empty() else "AKSI SOLO"
	var base_g_sc: int = 78
	match goal_style:
		"SALTO":
			base_g_sc = 96
			_adjust_rating(0.25, "GOL SALTO")
		"VOLI":
			base_g_sc = 91
			_adjust_rating(0.15, "GOL VOLI")
		"TENDANGAN BEBAS":
			base_g_sc = 86
		"JARAK JAUH":
			base_g_sc = 85
		"SUNDULAN":
			base_g_sc = 76
		"PENALTI":
			base_g_sc = 60
	var g_dist_m: float = snappedf(_player_pos.distance_to(Vector3(0, 0, -52.5)), 0.1)
	_goal_candidates.append({
		"style": goal_style,
		"minute": int(_minute),
		"score": base_g_sc + mini(6, int(g_dist_m * 0.18)),
		"distance": g_dist_m,
	})
	var hl_desc: String = ("Gol %s! Assist: %s" % [goal_style, ast_nm]) if not ast_nm.is_empty() else ("Gol %s spektakuler!" % goal_style)
	_add_rich_board_highlight(int(_minute), "GOAL", "GOL %s!" % u_name, hl_desc, u_dict, ast_tm, true)
	_goal_timeline.append({"minute": int(_minute), "scorer": u_name, "assist": ast_nm, "style": goal_style, "is_us": true, "is_user_involved": true, "clip": _best_clip.duplicate(true)})
	if is_instance_valid(_goal_flash_rect):
		_goal_flash_rect.color = Color(1.0, 0.92, 0.45, 0.65)
		create_tween().tween_property(_goal_flash_rect, "color:a", 0.0, 0.40)
	_start_goal_replay_then_celebration(u_name, int(_minute), ast_nm, true)
	var banner_g: String = "GOOOOL SALTO SPEKTAKULER!!" if goal_style == "SALTO" else ("GOOOOL VOLI MEMATIKAN!!" if goal_style == "VOLI" else "GOOOOL!!")
	_show_moment_result(banner_g, UITheme.ACCENT_GOLD, 2.45)

func _start_goal_replay_then_celebration(scorer_name: String, goal_min: int, assist_name: String, is_user_goal: bool) -> void:
	_pending_celeb_info = {
		"scorer": scorer_name,
		"minute": goal_min,
		"assist": assist_name,
		"is_user": is_user_goal,
		"player_pos": _player_pos,
		"gk_pos": _gk_pos,
	}
	# Build clean replay sequence ending with ball rippling the back of the opponent net!
	var frames: Array = []
	var src_frames: Array = _current_clip_frames
	if src_frames.size() >= 3:
		var start_i: int = maxi(0, src_frames.size() - 30)
		for fi in range(start_i, src_frames.size()):
			frames.append(src_frames[fi].duplicate(true))
	else:
		# Synthesize smooth approach trajectory if goal was triggered directly
		var end_x: float = clampf(_ball_pos.x, -3.1, 3.1)
		var end_y: float = clampf(_ball_pos.y, 0.35, 1.95)
		var start_p: Vector3 = _player_pos + Vector3(0.0, 0.15, -0.8)
		for fi in range(14):
			var t_f: float = float(fi) / 13.0
			var bx: float = lerpf(start_p.x, end_x, t_f)
			var by: float = lerpf(0.15, end_y, t_f) + sin(t_f * PI) * 0.45
			var bz: float = lerpf(start_p.z, -52.6, t_f)
			var gkx: float = lerpf(0.0, clampf(end_x * 0.55, -2.5, 2.5), clampf((t_f - 0.35) / 0.65, 0.0, 1.0))
			frames.append({
				"ball": [bx, by, bz],
				"gk": [gkx, -51.6],
				"player": [_player_pos.x, _player_pos.z],
				"gk_dive": signf(end_x) if t_f > 0.4 else 0.0,
			})

	# Append 5 trailing net-ripple frames so the ball visibly hits the back netting in slow-mo!
	var last_f: Dictionary = frames[frames.size() - 1]
	var lb: Array = last_f.get("ball", [0.0, 0.8, -52.6])
	var lgk: Array = last_f.get("gk", [_gk_pos.x, -51.6])
	var lpl: Array = last_f.get("player", [_player_pos.x, _player_pos.z])
	var ldive: float = float(last_f.get("gk_dive", _gk_dive_dir))
	for ni in range(1, 6):
		var nf: float = float(ni) / 5.0
		var nz: float = clampf(float(lb[2]) - nf * 1.45, -54.3, -52.55)
		var ny: float = maxf(0.12, float(lb[1]) * (1.0 - nf * 0.55))
		frames.append({
			"ball": [clampf(float(lb[0]), -3.45, 3.45), ny, nz],
			"gk": [float(lgk[0]), float(lgk[1])],
			"player": [float(lpl[0]), float(lpl[1])],
			"gk_dive": ldive,
		})

	_goal_replay_frames = frames
	_goal_replay_active = true
	_goal_replay_delay = 0.45
	_goal_replay_idx = 0
	_goal_replay_accum = 0.0
	_goal_replay_snapped_cam = false
	_celebrating_goal = false
	if is_instance_valid(_goal_popup_panel):
		_goal_popup_panel.visible = false
	if is_instance_valid(_celebration_confetti):
		_celebration_confetti.visible = false

func _process_goal_replay(delta: float) -> void:
	if _goal_replay_delay > 0.0:
		_goal_replay_delay -= delta
		return

	if not _goal_replay_snapped_cam:
		_goal_replay_snapped_cam = true
		_trail_points.clear()
		if is_instance_valid(_result_toast):
			_result_toast.visible = false
		if is_instance_valid(_goal_replay_banner):
			_goal_replay_banner.visible = true

	var step_dt: float = 0.052  # Smooth slow-motion broadcast replay (~19 fps)
	_goal_replay_accum += delta
	while _goal_replay_accum >= step_dt and _goal_replay_idx < _goal_replay_frames.size():
		_goal_replay_accum -= step_dt
		var fr: Dictionary = _goal_replay_frames[_goal_replay_idx]
		var bp: Array = fr.get("ball", [0.0, 0.5, -52.0])
		var gp: Array = fr.get("gk", [0.0, -51.6])
		var pp: Array = fr.get("player", [0.0, -34.0])
		_ball_pos = Vector3(float(bp[0]), float(bp[1]), float(bp[2]))
		_gk_pos = Vector3(float(gp[0]), 0.0, float(gp[1]))
		_player_pos = Vector3(float(pp[0]), 0.0, float(pp[1]))
		_gk_dive_dir = float(fr.get("gk_dive", 0.0))
		if absf(_gk_dive_dir) > 0.1:
			_gk_sprite.frame = 3
		else:
			_gk_sprite.frame = 0
		_player_sprite.frame = 7 if _goal_replay_idx < 4 else 4
		_trail_points.append(_ball_pos)
		if _trail_points.size() > 18:
			_trail_points.pop_front()
		_goal_replay_idx += 1

	# Behind Opponent GK POV Camera (positioned behind opponent goal net at z = -56.4 looking out!)
	var pov_x: float = clampf(_ball_pos.x * 0.42, -2.6, 2.6)
	var cam_behind_goal := Vector3(pov_x, 2.05, -56.4)
	var look_toward_pitch := Vector3(_ball_pos.x * 0.68, maxf(0.85, _ball_pos.y * 0.85), clampf(_ball_pos.z + 6.5, -51.2, -24.0))
	if _goal_replay_idx <= 2:
		_camera.global_position = cam_behind_goal
		_camera.look_at(look_toward_pitch, Vector3.UP)
	_cam_target_pos = cam_behind_goal
	_cam_look_pos = look_toward_pitch
	_draw_ball_trail()
	_sync_3d_sprites()

	# Transition seamlessly from Behind-GK Goal Replay -> On-Pitch Celebration + Scorer Pop-Up!
	if _goal_replay_idx >= _goal_replay_frames.size():
		_goal_replay_active = false
		if is_instance_valid(_goal_replay_banner):
			_goal_replay_banner.visible = false
		_trail_points.clear()
		if _trail_imm != null:
			_trail_imm.clear_surfaces()
		_gk_dive_dir = 0.0
		_gk_sprite.frame = 0
		_player_pos = _pending_celeb_info.get("player_pos", _player_pos)
		_gk_pos = _pending_celeb_info.get("gk_pos", _gk_pos)
		var is_u_g: bool = bool(_pending_celeb_info.get("is_user", true))
		_camera.global_position = _player_pos + Vector3(0.0, 5.5, 10.0)
		_start_goal_celebration(
			str(_pending_celeb_info.get("scorer", "PEMAIN")),
			int(_pending_celeb_info.get("minute", int(_minute))),
			str(_pending_celeb_info.get("assist", "")),
			is_u_g
		)
		_result_timer = 2.35 if is_u_g else 1.75

func _start_goal_celebration(scorer_name: String, goal_min: int, assist_name: String, is_user_goal: bool) -> void:
	_celebrating_goal = true
	_celebration_t = 0.0
	_celebration_origin = _player_pos
	_celebration_particles.clear()
	var club: Dictionary = CareerState.get_current_club() if CareerState.has_active_career else GameData.clubs[0]
	var c_pri: Color = UITheme.parse_color(club.get("primary", Color("#2563EB")), Color("#2563EB"))
	var c_sec: Color = UITheme.parse_color(club.get("secondary", Color("#FFFFFF")), Color("#FFFFFF"))
	var pal: Array[Color] = [UITheme.ACCENT_GOLD, c_pri, c_sec, Color("#FB7185"), Color("#38BDF8")]
	for i in range(48):
		var ang: float = randf() * TAU
		var spd: float = randf_range(90.0, 290.0)
		_celebration_particles.append({
			"x": 480.0 + randf_range(-160.0, 160.0),
			"y": 240.0 + randf_range(-80.0, 40.0),
			"vx": cos(ang) * spd,
			"vy": sin(ang) * spd - randf_range(60.0, 140.0),
			"sz": randf_range(4.0, 8.0),
			"col": pal[i % pal.size()],
		})
	if is_instance_valid(_celebration_confetti):
		_celebration_confetti.visible = true
		_celebration_confetti.queue_redraw()

	# Build Goal Scorer Pop-Up Banner (Name + Minute + Score + Avatar!)
	if is_instance_valid(_goal_popup_panel):
		for ch in _goal_popup_panel.get_children():
			_goal_popup_panel.remove_child(ch)
			ch.queue_free()
		var pop_sb := StyleBoxFlat.new()
		pop_sb.bg_color = Color("#081326", 0.96)
		pop_sb.border_color = UITheme.ACCENT_GOLD if is_user_goal else UITheme.ACCENT_CYAN
		pop_sb.set_border_width_all(2)
		pop_sb.border_width_left = 6
		pop_sb.set_corner_radius_all(8)
		pop_sb.content_margin_left = 12
		pop_sb.content_margin_right = 14
		pop_sb.content_margin_top = 8
		pop_sb.content_margin_bottom = 8
		_goal_popup_panel.add_theme_stylebox_override("panel", pop_sb)

		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 12)
		hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_goal_popup_panel.add_child(hb)

		var av_wrap := PanelContainer.new()
		av_wrap.custom_minimum_size = Vector2(64, 86)
		av_wrap.add_theme_stylebox_override("panel", UITheme.make_box(Color("#12243F"), UITheme.ACCENT_GOLD if is_user_goal else UITheme.BORDER_CYAN, 1, 5))
		av_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hb.add_child(av_wrap)
		var av := PixelAvatar.new()
		av.custom_minimum_size = Vector2(56, 78)
		av.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if is_user_goal and CareerState.has_active_career:
			av.configure_from_career()
		else:
			av.configure_random_npc(absi(scorer_name.hash()), club, false)
		av.anim_mode = "CELEBRATE"
		av_wrap.add_child(av)

		var mid_vb := VBoxContainer.new()
		mid_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mid_vb.alignment = BoxContainer.ALIGNMENT_CENTER
		mid_vb.add_theme_constant_override("separation", 3)
		mid_vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hb.add_child(mid_vb)

		var tag_l := Label.new()
		tag_l.text = "★ GOOOOL! SELEBRASI PEMAIN!" if is_user_goal else "★ GOOOOL TIM!"
		tag_l.add_theme_font_override("font", UITheme.get_display_font())
		tag_l.add_theme_font_size_override("font_size", 11)
		tag_l.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
		mid_vb.add_child(tag_l)

		var nm_l := Label.new()
		nm_l.text = scorer_name.to_upper()
		nm_l.clip_text = true
		nm_l.add_theme_font_override("font", UITheme.get_display_font())
		nm_l.add_theme_font_size_override("font_size", 20)
		nm_l.add_theme_color_override("font_color", Color.WHITE)
		mid_vb.add_child(nm_l)

		var fix_d: Dictionary = CareerState.get_current_fixture() if CareerState.has_active_career else {}
		var my_code: String = str(club.get("code", "TIM")).to_upper()
		var opp_code: String = str(fix_d.get("opp_code", "LWN")).to_upper()
		var sub_txt: String = "%s %d - %d %s" % [my_code, _score_us, _score_them, opp_code]
		if not assist_name.is_empty():
			sub_txt = "ASSIST: %s  •  %s" % [assist_name.to_upper(), sub_txt]
		var sub_l := Label.new()
		sub_l.text = sub_txt
		sub_l.add_theme_font_size_override("font_size", 10)
		sub_l.add_theme_color_override("font_color", Color("#93C5FD"))
		mid_vb.add_child(sub_l)

		var min_box := PanelContainer.new()
		min_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		min_box.custom_minimum_size = Vector2(68, 54)
		min_box.add_theme_stylebox_override("panel", UITheme.make_box(Color("#3B1422"), UITheme.ACCENT_GOLD, 2, 6))
		min_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hb.add_child(min_box)
		var m_vb := VBoxContainer.new()
		m_vb.alignment = BoxContainer.ALIGNMENT_CENTER
		m_vb.add_theme_constant_override("separation", 0)
		m_vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		min_box.add_child(m_vb)
		var ml1 := Label.new()
		ml1.text = "MENIT"
		ml1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ml1.add_theme_font_size_override("font_size", 8)
		ml1.add_theme_color_override("font_color", Color("#FCA5A5"))
		var ml2 := Label.new()
		ml2.text = "%d'" % maxi(1, goal_min)
		ml2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ml2.add_theme_font_override("font", UITheme.get_display_font())
		ml2.add_theme_font_size_override("font_size", 20)
		ml2.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
		m_vb.add_child(ml1)
		m_vb.add_child(ml2)

		_goal_popup_panel.visible = true
		_goal_popup_panel.modulate.a = 0.0
		_goal_popup_panel.pivot_offset = Vector2(220.0, 57.0)
		_goal_popup_panel.scale = Vector2(0.82, 0.82)
		var ptw := create_tween()
		ptw.tween_property(_goal_popup_panel, "modulate:a", 1.0, 0.22)
		ptw.parallel().tween_property(_goal_popup_panel, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _process_goal_celebration(delta: float) -> void:
	_celebration_t += delta
	# 1. User player celebration run toward corner + joyful fist-pump hops!
	var run_dir_x: float = 1.0 if _celebration_origin.x >= 0.0 else -1.0
	if _celebration_t < 0.72:
		_player_pos.x = clampf(_player_pos.x + run_dir_x * 4.6 * delta, -30.0, 30.0)
		_player_pos.z = clampf(_player_pos.z + 2.4 * delta, -49.0, 42.0)
		_player_pos.y = absf(sin(_celebration_t * 14.0)) * 0.25
		_player_sprite.frame = 1 if fmod(_celebration_t, 0.24) < 0.12 else 2
	else:
		# Celebratory jump & triumphant fist-pump dance!
		_player_pos.y = absf(sin((_celebration_t - 0.72) * 11.5)) * 0.68
		_player_sprite.frame = 7 if fmod(_celebration_t, 0.30) < 0.15 else 0

	# 2. Teammates sprint over & bounce around celebrating user
	for ti in range(_teammate_positions.size()):
		if ti >= _teammates.size() or not _teammates[ti].visible:
			continue
		var t_off := Vector3((-2.1 if ti % 2 == 0 else 2.1), 0.0, 1.5 + float(ti) * 0.6)
		var tgt: Vector3 = _player_pos + t_off
		var diff := Vector3(tgt.x - _teammate_positions[ti].x, 0.0, tgt.z - _teammate_positions[ti].z)
		if diff.length() > 0.35:
			_teammate_positions[ti] += diff.normalized() * 6.8 * delta
			_teammates[ti].frame = 1 if fmod(_celebration_t + float(ti) * 0.1, 0.24) < 0.12 else 2
		else:
			_teammate_positions[ti].y = absf(sin((_celebration_t + float(ti) * 0.4) * 10.5)) * 0.48
			_teammates[ti].frame = 7

	# 3. Heroic celebration camera swoop toward the celebrating scorer
	var zoom_t: float = clampf(_celebration_t / 0.85, 0.0, 1.0)
	var pan_x: float = sin(_celebration_t * 1.4) * 2.2
	_cam_target_pos = Vector3(_player_pos.x + pan_x, lerpf(8.5, 4.4, zoom_t), _player_pos.z + lerpf(11.5, 6.8, zoom_t))
	_cam_look_pos = Vector3(_player_pos.x, 1.15 + _player_pos.y * 0.4, _player_pos.z)

	# 4. Golden expanding pulse ring around the celebrating player
	if _ring_imm != null:
		_ring_imm.clear_surfaces()
		var pulse_r: float = 0.9 + fmod(_celebration_t * 2.8, 2.2)
		_ring_imm.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
		for ri in range(25):
			var a: float = float(ri) * TAU / 24.0
			_ring_imm.surface_add_vertex(Vector3(_player_pos.x + cos(a) * pulse_r, 0.08, _player_pos.z + sin(a) * pulse_r))
		_ring_imm.surface_end()

	# 5. Update 2D confetti burst particles
	for pt in _celebration_particles:
		pt["x"] = float(pt["x"]) + float(pt["vx"]) * delta
		pt["vy"] = float(pt["vy"]) + 320.0 * delta
		pt["y"] = float(pt["y"]) + float(pt["vy"]) * delta
	if is_instance_valid(_celebration_confetti):
		_celebration_confetti.queue_redraw()
	_sync_3d_sprites()

func _stop_goal_celebration() -> void:
	_goal_replay_active = false
	if is_instance_valid(_goal_replay_banner):
		_goal_replay_banner.visible = false
	if not _celebrating_goal:
		return
	_celebrating_goal = false
	_player_pos.y = 0.0
	for ti in range(_teammate_positions.size()):
		_teammate_positions[ti].y = 0.0
	if _ring_imm != null:
		_ring_imm.clear_surfaces()
	if is_instance_valid(_celebration_confetti):
		_celebration_confetti.visible = false
	if is_instance_valid(_goal_popup_panel):
		_goal_popup_panel.visible = false
	_sync_3d_sprites()

func _draw_celebration_confetti() -> void:
	if not is_instance_valid(_celebration_confetti) or not _celebrating_goal:
		return
	for pt in _celebration_particles:
		var s: float = float(pt["sz"])
		_celebration_confetti.draw_rect(Rect2(float(pt["x"]), float(pt["y"]), s, s * 0.65), pt["col"], true)

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
	if _player_card_panel != null:
		_player_card_panel.visible = false
	if _qte_overlay != null:
		_qte_overlay.visible = false
	_result_toast.text = msg
	_result_toast.add_theme_color_override("font_color", col)
	_result_toast.pivot_offset = _result_toast.size * 0.5
	_result_toast.scale = Vector2(1.28, 1.28)
	_result_toast.visible = true
	create_tween().tween_property(_result_toast, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)

func _resolve_carrier_tackle_outcome(carrier_pos: Vector3, def_idx: int, is_sliding: bool, is_user_controlled: bool) -> void:
	if def_idx >= 0 and def_idx < _defenders.size():
		_defenders[def_idx].frame = 3
	_dragging = false
	_aim_imm.clear_surfaces()
	_ring_imm.clear_surfaces()
	_moment_banner.visible = false
	var drib_attr := CareerState.get_effective_attribute("dribel") if CareerState.has_active_career else 64
	var agil := get_opp_defender_agility()
	var foul_chance := clampf(0.28 + float(drib_attr - 58) * 0.0045 + (0.16 if is_sliding else 0.0) + (0.16 if _skill_burst_timer > 0.0 else 0.0) - (agil - 1.0) * 0.12, 0.24, 0.68)

	if randf() < foul_chance and _moment_type != MomentType.PENALTY:
		AudioSynth.play_whistle(false)
		_controlling_teammate_idx = -1
		_carry_tm_idx = -1
		_shot_by_teammate = false
		_carry_assist_pending = false
		_adjust_rating(0.15, "DILANGGAR BEK")
		if randf() < 0.45:
			_opp_yellows += 1
			var card_p: Dictionary = _pick_roster_player(false, false, false)
			_add_rich_board_highlight(int(_minute), "YELLOW_CARD", "KARTU KUNING LAWAN!", "%s mengganjal keras pembawa bola!" % str(card_p.get("name", "BEK LAWAN")), card_p, {}, false)
		var in_box: bool = (carrier_pos.z <= -36.0 and absf(carrier_pos.x) <= 20.16)
		if in_box:
			_pending_foul_moment = int(MomentType.PENALTY)
			_pending_foul_spot = Vector3(0.0, 0.0, -41.5)
			_ticker_lbl.text = "PELANGGARAN DI AREA PENALTI! Wasit menunjuk titik putih!"
			_add_rich_board_highlight(int(_minute), "INFO", "HADIAH PENALTI!", "Bek lawan menjatuhkan pembawa bola di kotak penalti!", _get_user_roster_dict(), {}, true)
			_show_moment_result("PELANGGARAN! HADIAH PENALTI!", UITheme.ACCENT_GOLD, 1.15)
		else:
			_pending_foul_moment = int(MomentType.FREE_KICK)
			_pending_foul_spot = Vector3(clampf(carrier_pos.x, -26.0, 26.0), 0.0, clampf(carrier_pos.z, -35.6, -16.0))
			_ticker_lbl.text = "PELANGGARAN BEK! Hadiah tendangan bebas di depan pertahanan lawan!"
			_add_rich_board_highlight(int(_minute), "INFO", "TENDANGAN BEBAS!", "Tekel keras di luar kotak penalti berujung pelanggaran!", _get_user_roster_dict(), {}, true)
			_show_moment_result("PELANGGARAN! TENDANGAN BEBAS!", UITheme.ACCENT_CYAN, 1.15)
		return

	# Clean tackle (bola kerebut)
	AudioSynth.play_save()
	if is_user_controlled:
		_shots_telemetry.append({
			"type": _moment_type_str(),
			"outcome": "BLOCKED",
			"pitchCoord": {"x": clampf((_ball_pos.x + 34.0) / 68.0, 0.05, 0.95), "y": clampf((52.5 - _ball_pos.z) / 52.5, 0.05, 0.95)},
			"goalCoord": {"x": 0.5, "y": 0.5},
			"distanceMeters": snappedf(_ball_pos.distance_to(Vector3(0, 0, -52.5)), 0.1),
		})
		if _controlling_teammate_idx >= 0:
			if _user_assisted_pass:
				_carry_assist_pending = true
				_credit_key_pass_if_pending()
			_show_moment_result("REKAN DIREBUT BEK!", UITheme.ACCENT_GOLD if _key_pass_awarded else UITheme.ACCENT_RED, 1.2)
		else:
			_adjust_rating(-0.30, "DIREBUT BEK")
			_show_moment_result("BOLA KEREBUT BEK!", UITheme.ACCENT_RED, 1.2)
	else:
		_credit_key_pass_if_pending()
		_shot_by_teammate = false
		_carry_assist_pending = false
		_update_last_shot("BLOCKED")
		_add_board_event(int(_minute), "INFO", "%d' Rekan yang membawa bola dihentikan bek lawan!" % int(_minute), false)
		_show_moment_result("REKAN DIHENTIKAN BEK!", UITheme.ACCENT_GOLD if _key_pass_awarded else UITheme.ACCENT_RED, 1.35)

func _advance_after_moment() -> void:
	for tm in _teammates:
		tm.visible = false
	for df in _defenders:
		df.visible = false
	_trail_imm.clear_surfaces()

	if _pending_foul_moment >= 0:
		var next_foul := _pending_foul_moment as MomentType
		_pending_foul_moment = -1
		_trigger_key_moment(next_foul)
		return

	if run_mode == RunMode.PRACTICE_MODE:
		_practice_round += 1
		if _practice_round > 5:
			mode_exited.emit()
			return
		_minute_lbl.text = "%d/5" % _practice_round
		_score_lbl.text = "LATIHAN (%d GOL)" % _my_goals
		var p_next := MomentType.SHOT
		match _practice_round:
			2: p_next = MomentType.HEADER_CROSS
			3: p_next = MomentType.DRIBBLE_DUEL
			4: p_next = MomentType.LONG_PASS_CONTROL
			5: p_next = MomentType.FREE_KICK
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
	_board_hold_fast = false
	if _quiz_bonus_energy:
		_user_match_energy = minf(100.0, _user_match_energy + 4.0)
	AudioSynth.play_whistle(true)
	var shots_copy: Array = []
	for s in _shots_telemetry:
		shots_copy.append(s)
	var net_extra_drain: int = int(round(_match_extra_energy_drain)) - (4 if _quiz_bonus_energy else 0)
	var motm_p: Dictionary = _compute_match_motm_player()
	var report := CareerState.finish_match({
		"score_us": _score_us,
		"score_them": _score_them,
		"pen_us": _pen_us,
		"pen_them": _pen_them,
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
		"goal_candidates": _goal_candidates.duplicate(true),
		"motm_player": motm_p,
		"extra_energy_drain": net_extra_drain,
		"subbed_out": _user_subbed_out,
		"sub_minute": _user_sub_minute,
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
	if _acrobatic_anim_timer > 0.0:
		var ap: float = clampf(1.0 - (_acrobatic_anim_timer / maxf(0.01, _acrobatic_anim_dur)), 0.0, 1.0)
		var arc: float = sin(ap * PI)
		if _acrobatic_anim_style == "SALTO":
			_player_sprite.global_position = _player_pos + Vector3(0.0, arc * 1.15, 0.0)
			_player_sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED
			_player_sprite.rotation_degrees = Vector3(-16.0, 0.0, -arc * 205.0)
		else:
			_player_sprite.global_position = _player_pos + Vector3(0.0, arc * 0.72, 0.0)
			_player_sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED
			_player_sprite.rotation_degrees = Vector3(-12.0, 0.0, -arc * 58.0)
	else:
		_player_sprite.global_position = _player_pos
		_player_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_player_sprite.rotation_degrees = Vector3.ZERO
	_player_shadow.global_position = Vector3(_player_pos.x, 0.03, _player_pos.z)
	_gk_sprite.global_position = _gk_pos
	if absf(_gk_dive_dir) > 0.1 and (_phase == MatchPhase.BALL_IN_FLIGHT or _goal_replay_active):
		_gk_sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		_gk_sprite.rotation_degrees = Vector3(-12.0, 0.0, -28.0 if _gk_dive_dir > 0.0 else 28.0)
	else:
		_gk_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_gk_sprite.rotation_degrees = Vector3.ZERO
	_gk_shadow.global_position = Vector3(_gk_pos.x, 0.03, _gk_pos.z)
	if is_instance_valid(_our_gk_sprite):
		_our_gk_sprite.global_position = _our_gk_pos
	if is_instance_valid(_our_gk_shadow):
		_our_gk_shadow.global_position = Vector3(_our_gk_pos.x, 0.03, _our_gk_pos.z)
	_ball_sprite.global_position = _ball_pos
	_ball_shadow.global_position = Vector3(_ball_pos.x, 0.03, _ball_pos.z)
	var shadow_scale := clampf(1.0 - _ball_pos.y * 0.14, 0.35, 1.0)
	_ball_shadow.scale = Vector3.ONE * shadow_scale

	for i in range(_teammate_positions.size()):
		if i < _teammates.size():
			_teammates[i].global_position = _teammate_positions[i]
	for i in range(_defender_positions.size()):
		if i < _defenders.size():
			var sliding: bool = (i < _defender_slide_timers.size() and _defender_slide_timers[i] > 0.0)
			_defenders[i].global_position = _defender_positions[i]
			if sliding:
				var sdir_x: float = _defender_slide_dirs[i].x if i < _defender_slide_dirs.size() else 1.0
				_defenders[i].billboard = BaseMaterial3D.BILLBOARD_DISABLED
				_defenders[i].rotation_degrees = Vector3(-16.0, 0.0, 56.0 if sdir_x >= 0.0 else -56.0)
				_defenders[i].frame = 3
			else:
				_defenders[i].billboard = BaseMaterial3D.BILLBOARD_ENABLED
				_defenders[i].rotation_degrees = Vector3.ZERO

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

	# Ground Slingshot Ring (CINCIN) around active ball carrier's feet as bold 3D dashed ribbon
	var carrier_pos: Vector3 = _get_active_carrier_pos()
	_ring_imm.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var segs := 36
	var r_in := 2.05
	var r_out := 2.32
	for i in range(segs):
		if i % 3 == 2:
			continue
		var a0 := float(i) / float(segs) * TAU
		var a1 := float(i + 1) / float(segs) * TAU
		var p0_in := Vector3(carrier_pos.x + cos(a0) * r_in, 0.05, carrier_pos.z + sin(a0) * r_in)
		var p0_out := Vector3(carrier_pos.x + cos(a0) * r_out, 0.05, carrier_pos.z + sin(a0) * r_out)
		var p1_in := Vector3(carrier_pos.x + cos(a1) * r_in, 0.05, carrier_pos.z + sin(a1) * r_in)
		var p1_out := Vector3(carrier_pos.x + cos(a1) * r_out, 0.05, carrier_pos.z + sin(a1) * r_out)
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
	# eFootball / EA FC directional cursor ring & pointer wedge under active carrier whenever actively dribbling
	if _is_user_dribbling_active():
		var ang_f := atan2(_dribble_facing.y, _dribble_facing.x)
		var arr_col := UITheme.ACCENT_GOLD if _skill_burst_timer > 0.0 else Color("#22D3EE")
		var tip := Vector3(carrier_pos.x + cos(ang_f) * 3.1, 0.06, carrier_pos.z + sin(ang_f) * 3.1)
		var b_l := Vector3(carrier_pos.x + cos(ang_f - 0.35) * 2.25, 0.06, carrier_pos.z + sin(ang_f - 0.35) * 2.25)
		var b_r := Vector3(carrier_pos.x + cos(ang_f + 0.35) * 2.25, 0.06, carrier_pos.z + sin(ang_f + 0.35) * 2.25)
		for vtx in [tip, b_r, b_l]:
			_ring_imm.surface_set_color(arr_col)
			_ring_imm.surface_add_vertex(vtx)
	# Draw live teammate movement rings, free-kick/header/corner target rings, & Offside line warning!
	if _moment_type in [MomentType.SHOT, MomentType.PASS, MomentType.DRIBBLE, MomentType.FREE_KICK, MomentType.HEADER_CROSS, MomentType.CORNER_KICK]:
		var any_offside := false
		for ti in range(_teammate_positions.size()):
			if ti == _controlling_teammate_idx:
				continue
			if (_moment_type == MomentType.HEADER_CROSS or (_moment_type == MomentType.CORNER_KICK and not _corner_taker_is_user)) and ti == _cross_passer_idx:
				continue
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
			if _moment_type != MomentType.FREE_KICK and _moment_type != MomentType.HEADER_CROSS and ti < _teammate_vels.size() and _teammate_vels[ti].length() > 0.35:
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
		if _aim_power_pill != null:
			_aim_power_pill.visible = false
		return

	var delta_px := _drag_start - _drag_current
	if delta_px.length() < 12.0:
		_power_lbl.text = "0%"
		if _aim_power_pill != null:
			_aim_power_pill.visible = false
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
	var pct := int(launch.get("power_pct", int(round(float(launch["power_ratio"]) * 100.0))))
	var pwr_col: Color = SlingshotPhysics.get_power_color(pct)
	var loft_tag := " • LAMBUNG" if bool(launch.get("is_lofted", false)) else " • DATAR"
	_power_lbl.text = "%d%%%s" % [pct, loft_tag]
	_power_lbl.add_theme_color_override("font_color", pwr_col)
	aim_col = pwr_col

	var is_header_qte := (_moment_type == MomentType.HEADER_CROSS or (_moment_type == MomentType.CORNER_KICK and not _corner_taker_is_user))
	var preview_origin: Vector3 = Vector3(_player_pos.x, 1.55, _player_pos.z) if is_header_qte else _ball_pos
	var preview_vel: Vector3 = _rotate_corner_launch(launch["velocity"]) if (_moment_type == MomentType.CORNER_KICK and _corner_taker_is_user) else launch["velocity"]
	var preview_omega: Vector3 = launch["omega"]
	if is_header_qte:
		preview_vel.y = clampf(preview_vel.y * 0.52, -1.5, 4.6)
		preview_omega *= 0.55

	var steps_preview := int(lerpf(12.0, 28.0, float(ak + (bm if _moment_type in [MomentType.FREE_KICK, MomentType.CORNER_KICK] else 0)) / 180.0))
	var pts := SlingshotPhysics.predict_trajectory(preview_origin, preview_vel, preview_omega, ef, steps_preview, 0.04)
	if pts.size() >= 2:
		if _moment_type in [MomentType.SHOT, MomentType.PASS, MomentType.DRIBBLE, MomentType.FREE_KICK, MomentType.HEADER_CROSS, MomentType.CORNER_KICK]:
			var aims_tm_idx: int = -1
			for pt in pts:
				for ti in range(_teammate_positions.size()):
					if ti == _controlling_teammate_idx:
						continue
					if is_header_qte and ti == _cross_passer_idx:
						continue
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
					pwr_col = UITheme.ACCENT_RED
				else:
					_power_lbl.text = "%d%% • %s" % [pct, ("SUNDUL UMPAN" if is_header_qte else "UMPAN")]

		# Floating Power Percentage Pill pinned right on the projected shot direction!
		if _aim_power_pill != null and _camera != null:
			var mid_pt: Vector3 = pts[mini(pts.size() - 1, maxi(1, int(pts.size() * 0.45)))]
			if not _camera.is_position_behind(mid_pt):
				var sp2 := _camera.unproject_position(mid_pt)
				var vp := get_viewport_rect().size
				_aim_power_pill_lbl.text = "%d%%%s" % [pct, " ▲" if bool(launch.get("is_lofted", false)) else ""]
				_aim_power_pill_lbl.add_theme_color_override("font_color", pwr_col)
				_aim_power_pill.add_theme_stylebox_override("panel", UITheme.make_box(Color("#081326E8"), pwr_col, 2, 6))
				var p_sz := Vector2(78.0 if bool(launch.get("is_lofted", false)) else 58.0, 26.0)
				_aim_power_pill.size = p_sz
				_aim_power_pill.position = Vector2(
					clampf(sp2.x - p_sz.x * 0.5, 12.0, maxf(12.0, vp.x - p_sz.x - 12.0)),
					clampf(sp2.y - 36.0, 56.0, maxf(56.0, vp.y - p_sz.y - 12.0))
				)
				_aim_power_pill.visible = true
			else:
				_aim_power_pill.visible = false
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

func _adjust_rating(delta_r: float, reason: String = "") -> void:
	_rating = clampf(_rating + delta_r, 3.0, 10.0)
	if _rating_delta_lbl != null:
		var sign_s: String = "+" if delta_r >= 0.0 else ""
		var tag_s: String = ("  (%s)" % reason) if not reason.is_empty() else ""
		_rating_delta_lbl.text = "RATING %s%.1f%s  •  %.1f" % [sign_s, delta_r, tag_s, _rating]
		_rating_delta_lbl.add_theme_color_override("font_color", UITheme.ACCENT_GREEN if delta_r > 0.0 else UITheme.ACCENT_RED)
		_rating_delta_lbl.visible = true

func _credit_on_target_shot(reason: String) -> void:
	if _shot_on_target_credit:
		return
	_shot_on_target_credit = true
	_adjust_rating(0.1, reason)

func _credit_key_pass_if_pending() -> void:
	if _key_pass_awarded or not _carry_assist_pending:
		return
	_key_pass_awarded = true
	_adjust_rating(0.1, "UMPAN KUNCI")

func _configure_qte_timing(stat_val: int) -> void:
	var diff_s: String = str(SettingsManager.data.get("difficulty", "NORMAL"))
	match diff_s:
		"MUDAH": _qte_duration = 1.65
		"SULIT": _qte_duration = 1.12
		"EKSTREM": _qte_duration = 0.96
		_: _qte_duration = 1.35
	var stat_t: float = clampf(float(stat_val) / 99.0, 0.0, 1.0)
	_qte_perfect_tol = lerpf(0.09, 0.14, stat_t)
	_qte_good_tol = lerpf(0.19, 0.28, stat_t)
	_qte_progress = 0.0
	_qte_resolved = false

func _update_qte_overlay_pos(world_pt: Vector3) -> void:
	if _qte_overlay == null:
		return
	var scr := Vector2(480.0, 290.0)
	if _camera != null and not _camera.is_position_behind(world_pt):
		var proj := _camera.unproject_position(world_pt)
		scr = Vector2(clampf(proj.x, 230.0, 730.0), clampf(proj.y, 185.0, 390.0))
	_qte_overlay.configure_state(scr, _qte_progress, _qte_perfect_tol, _qte_good_tol, _qte_label)
	_qte_overlay.visible = true
	_qte_overlay.queue_redraw()

# ---------------------------------------------------------------------------
# NEW INTERACTIVE MOMENT 1: AERIAL CROSS HEADER (AIM -> LOB -> TIMED HEADER)
# ---------------------------------------------------------------------------
func _setup_header_cross_moment() -> void:
	_phase = MatchPhase.KEY_MOMENT_AIM
	_moment_type = MomentType.HEADER_CROSS
	var side: float = -1.0 if randf() < 0.5 else 1.0
	_player_pos = Vector3(randf_range(-3.2, 3.2), 0.0, randf_range(-43.0, -39.5))
	var wing_pos := Vector3(side * 15.5, 0.0, -35.8)
	_cross_passer_idx = 0
	_cross_start = Vector3(wing_pos.x - side * 0.6, 0.15, wing_pos.z)
	_cross_target = Vector3(_player_pos.x, 1.55, _player_pos.z)
	_cross_peak_y = 5.4
	_ball_pos = _cross_start

	# Teammate 0: wing crosser; Teammates 1 & 2: box attacking options for header layoff!
	var tm_spots := [
		wing_pos,
		Vector3(-side * 5.2, 0.0, -42.5),
		Vector3(clampf(_player_pos.x + side * 4.5, -10.0, 10.0), 0.0, -40.5),
	]
	for i in range(tm_spots.size()):
		if i < _teammates.size():
			_teammates[i].visible = true
			_teammate_positions.append(tm_spots[i])
			_teammate_vels.append(Vector3.ZERO)
			_teammate_targets.append(tm_spots[i])
			_teammate_open_scores.append(3.4)

	# Defenders inside box (placed slightly deeper so teammates start cleanly onside)
	var def_spots := [
		Vector3(_player_pos.x + side * 1.9, 0.0, -44.2),
		Vector3(-side * 4.0, 0.0, -44.5),
	]
	for i in range(def_spots.size()):
		if i < _defenders.size():
			_defenders[i].visible = true
			_defender_positions.append(def_spots[i])
			_defender_dirs.append(1.0)

	_moment_title_lbl.text = "UMPAN LAMBUNG! ARAHKAN SUNDULAN"
	_moment_sub_lbl.text = "Tarik ketapel untuk arah sundulan ke GAWANG atau REKAN, lalu tap saat bola pas!"
	_ticker_lbl.text = "Rekan siap melepas umpan lambung — tentukan arah sundulanmu dulu!"
	_moment_banner.visible = true
	_spin_pad.visible = true
	_power_lbl.visible = true
	_sync_action_bar()
	_configure_moment_camera()
	_sync_3d_sprites()
	_draw_aim_and_ring()
	AudioSynth.play_whistle(false)

func _launch_header_cross_timing() -> void:
	_phase = MatchPhase.HEADER_TIMING
	var ak := CareerState.get_effective_attribute("akurasi") if CareerState.has_active_career else 68
	var fis := CareerState.get_effective_attribute("fisik") if CareerState.has_active_career else 68
	_configure_qte_timing(int((ak + fis) / 2))
	_qte_label = "SUNDUL KORNER!" if _moment_type == MomentType.CORNER_KICK else "SUNDUL SEKARANG!"
	_spin_pad.visible = false
	_power_lbl.visible = false
	if _cross_passer_idx < _teammates.size():
		_teammates[_cross_passer_idx].frame = 7
	_moment_title_lbl.text = "UMPAN TENDANGAN SUDUT DATANG!" if _moment_type == MomentType.CORNER_KICK else "BOLA LAMBUNG DATANG!"
	_moment_sub_lbl.text = "Tunggu momen tepat saat bola sampai di kepalamu lalu TAP / KLIK / SPASI!"
	_ticker_lbl.text = "Bola melambung menuju kepalamu — bersiap menyundul!"
	_moment_banner.visible = true
	_trail_points.clear()
	_trail_imm.clear_surfaces()
	AudioSynth.play_kick(0.82)
	_update_qte_overlay_pos(_cross_target)

func _process_header_timing(delta: float) -> void:
	_qte_progress += delta / maxf(0.4, _qte_duration)
	var t_arc: float = clampf(_qte_progress, 0.0, 1.18)
	var p: Vector3 = _cross_start.lerp(_cross_target, minf(1.0, t_arc))
	if t_arc <= 1.0:
		p.y = lerpf(_cross_start.y, _cross_target.y, t_arc) + sin(t_arc * PI) * _cross_peak_y
	else:
		# Ball sails slightly past user if late
		var past_dir := (_cross_target - _cross_start).normalized()
		p = _cross_target + Vector3(past_dir.x, -0.45, past_dir.z) * ((t_arc - 1.0) * 14.0)
	_ball_pos = p
	_trail_points.append(_ball_pos)
	if _trail_points.size() > 20:
		_trail_points.pop_front()
	_draw_ball_trail()
	_sync_3d_sprites()
	_update_qte_overlay_pos(_cross_target)

	if _qte_progress > 1.24 and not _qte_resolved:
		_qte_resolved = true
		if _qte_overlay != null:
			_qte_overlay.visible = false
		_adjust_rating(-0.25, "TERLAMBAT SUNDUL")
		AudioSynth.play_save()
		_show_moment_result("TERLAMBAT MENYUNDUL!", UITheme.ACCENT_RED, 1.35)

# ---------------------------------------------------------------------------
# NEW INTERACTIVE MOMENT 2: 1v1 DRIBBLE DUEL (SHRINKING CIRCLE QTE)
# ---------------------------------------------------------------------------
func _setup_dribble_duel_qte() -> void:
	_phase = MatchPhase.QTE_DRIBBLE_DUEL
	_moment_type = MomentType.DRIBBLE_DUEL
	var drib := CareerState.get_effective_attribute("dribel") if CareerState.has_active_career else 68
	_configure_qte_timing(drib)
	_qte_label = "KECOH BEK!"
	_spin_pad.visible = false
	_power_lbl.visible = false
	if _dribble_pad != null:
		_dribble_pad.visible = false
	if _stamina_bar_bg != null:
		_stamina_bar_bg.visible = false

	var sx: float = randf_range(-5.0, 5.0)
	_player_pos = Vector3(sx, 0.0, -26.5)
	_duel_player_start = _player_pos
	_ball_pos = _player_pos + Vector3(0.0, 0.115, -0.85)
	_duel_def_start = Vector3(sx + randf_range(-0.6, 0.6), 0.0, -34.2)

	# Defender 0 faces user 1v1; Defenders 1 & 2 cover further back
	var def_spots := [
		_duel_def_start,
		Vector3(clampf(sx - 6.5, -16.0, 16.0), 0.0, -40.5),
		Vector3(clampf(sx + 6.5, -16.0, 16.0), 0.0, -41.0),
	]
	for i in range(def_spots.size()):
		if i < _defenders.size():
			_defenders[i].visible = true
			_defender_positions.append(def_spots[i])
			_defender_dirs.append(1.0)

	# 3 attacking teammates onside ready after user beats the 1v1 defender
	var tm_spots := [
		Vector3(clampf(sx + 7.5, -16.0, 16.0), 0.0, -34.0),
		Vector3(clampf(sx - 7.0, -16.0, 16.0), 0.0, -35.5),
		Vector3(clampf(-sx * 0.5, -12.0, 12.0), 0.0, -30.5),
	]
	for i in range(tm_spots.size()):
		if i < _teammates.size():
			_teammates[i].visible = true
			_teammate_positions.append(tm_spots[i])
			_teammate_vels.append(Vector3(0.0, 0.0, -2.5))
			_teammate_targets.append(Vector3(tm_spots[i].x, 0.0, -46.5))
			_teammate_open_scores.append(3.2)

	_moment_title_lbl.text = "DUEL 1v1 DRIBEL!"
	_moment_sub_lbl.text = "Bek menghadang! TAP / KLIK / SPASI saat lingkaran mengecil pas di cincin hijau!"
	_ticker_lbl.text = "Duel satu lawan satu! Waktunya mengecoh bek lawan!"
	_moment_banner.visible = true
	_sync_action_bar()
	_configure_moment_camera()
	_sync_3d_sprites()
	_update_qte_overlay_pos(_player_pos + Vector3(0.0, 1.4, -2.0))
	AudioSynth.play_whistle(false)

func _process_qte_dribble_duel(delta: float) -> void:
	_qte_progress += delta / maxf(0.4, _qte_duration)
	var t_app: float = clampf(_qte_progress, 0.0, 1.15)
	var stride_back: int = 5 if fmod(_anim_clock, 0.26) < 0.13 else 6
	var stride_front: int = 1 if fmod(_anim_clock, 0.28) < 0.14 else 2
	_player_pos = _duel_player_start.lerp(Vector3(_duel_player_start.x, 0.0, _duel_def_start.z + 2.4), minf(1.0, t_app))
	_player_sprite.frame = stride_back
	var hop := absf(sin(_anim_clock * 15.0)) * 0.055
	_ball_pos = Vector3(_player_pos.x, 0.115 + hop, _player_pos.z - 0.82)
	if not _defender_positions.is_empty():
		_defender_positions[0] = _duel_def_start.lerp(Vector3(_duel_player_start.x, 0.0, _duel_def_start.z + 1.1), minf(1.0, t_app))
		_defenders[0].frame = stride_front
	_sync_3d_sprites()
	_update_qte_overlay_pos(_player_pos + Vector3(0.0, 1.4, -1.2))

	if _qte_progress > 1.24 and not _qte_resolved:
		_qte_resolved = true
		if _qte_overlay != null:
			_qte_overlay.visible = false
		if not _defenders.is_empty():
			_defenders[0].frame = 3
		AudioSynth.play_save()
		_adjust_rating(-0.30, "DRIBEL GAGAL")
		_show_moment_result("DRIBEL GAGAL! DIREBUT BEK", UITheme.ACCENT_RED, 1.35)

# ---------------------------------------------------------------------------
# NEW INTERACTIVE MOMENT 3: LONG PASS FIRST-TOUCH CONTROL (SHRINKING CIRCLE QTE)
# ---------------------------------------------------------------------------
func _setup_long_pass_control_qte() -> void:
	_phase = MatchPhase.QTE_LONG_CONTROL
	_moment_type = MomentType.LONG_PASS_CONTROL
	var drib := CareerState.get_effective_attribute("dribel") if CareerState.has_active_career else 68
	var fis := CareerState.get_effective_attribute("fisik") if CareerState.has_active_career else 68
	_configure_qte_timing(int((drib + fis) / 2))
	_qte_duration *= 1.12
	_qte_label = "KONTROL BOLA!"
	_spin_pad.visible = false
	_power_lbl.visible = false
	if _dribble_pad != null:
		_dribble_pad.visible = false
	if _stamina_bar_bg != null:
		_stamina_bar_bg.visible = false

	var side: float = -1.0 if randf() < 0.5 else 1.0
	_player_pos = Vector3(clampf(-side * randf_range(3.5, 7.5), -11.0, 11.0), 0.0, randf_range(-32.5, -27.5))
	var passer_pos := Vector3(side * 13.5, 0.0, -7.5)
	_cross_start = Vector3(passer_pos.x, 0.15, passer_pos.z - 0.6)
	_cross_target = Vector3(_player_pos.x, 0.32, _player_pos.z - 0.55)
	_cross_peak_y = 6.2
	_ball_pos = _cross_start

	var tm_spots := [
		passer_pos,
		Vector3(clampf(_player_pos.x + side * 7.5, -16.0, 16.0), 0.0, _player_pos.z - 4.0),
		Vector3(clampf(-_player_pos.x * 0.5, -13.0, 13.0), 0.0, _player_pos.z - 6.0),
	]
	for i in range(tm_spots.size()):
		if i < _teammates.size():
			_teammates[i].visible = true
			_teammate_positions.append(tm_spots[i])
			_teammate_vels.append(Vector3(0.0, 0.0, -2.6))
			_teammate_targets.append(Vector3(tm_spots[i].x, 0.0, -46.5))
			_teammate_open_scores.append(3.2)
	_teammates[0].frame = 7

	var def_spots := [
		Vector3(clampf(_player_pos.x + side * 2.4, -14.0, 14.0), 0.0, _player_pos.z - 7.5),
		Vector3(clampf(tm_spots[1].x - side * 1.5, -16.0, 16.0), 0.0, tm_spots[1].z - 3.5),
		Vector3(clampf(tm_spots[2].x + side * 1.5, -16.0, 16.0), 0.0, tm_spots[2].z - 3.2),
	]
	for i in range(def_spots.size()):
		if i < _defenders.size():
			_defenders[i].visible = true
			_defender_positions.append(def_spots[i])
			_defender_dirs.append(1.0)

	_moment_title_lbl.text = "UMPAN JAUH MELAMBUNG!"
	_moment_sub_lbl.text = "TAP / KLIK / SPASI tepat saat lingkaran pas untuk mengontrol bola!"
	_ticker_lbl.text = "Rekan mengirim umpan lambung jauh — siapkan sentuhan pertamamu!"
	_moment_banner.visible = true
	_trail_points.clear()
	_trail_imm.clear_surfaces()
	_sync_action_bar()
	_configure_moment_camera()
	_sync_3d_sprites()
	_update_qte_overlay_pos(_player_pos + Vector3(0.0, 1.3, 0.0))
	AudioSynth.play_kick(0.92)

func _process_qte_long_control(delta: float) -> void:
	_qte_progress += delta / maxf(0.4, _qte_duration)
	var t_arc: float = clampf(_qte_progress, 0.0, 1.18)
	var p: Vector3 = _cross_start.lerp(_cross_target, minf(1.0, t_arc))
	if t_arc <= 1.0:
		p.y = lerpf(_cross_start.y, _cross_target.y, t_arc) + sin(t_arc * PI) * _cross_peak_y
	else:
		p = _cross_target + Vector3(0.0, 0.4, -6.5) * (t_arc - 1.0)
	_ball_pos = p
	_trail_points.append(_ball_pos)
	if _trail_points.size() > 22:
		_trail_points.pop_front()
	_draw_ball_trail()
	_sync_3d_sprites()
	_update_qte_overlay_pos(_player_pos + Vector3(0.0, 1.3, 0.0))

	if _qte_progress > 1.24 and not _qte_resolved:
		_qte_resolved = true
		if _qte_overlay != null:
			_qte_overlay.visible = false
		AudioSynth.play_save()
		_adjust_rating(-0.30, "GAGAL KONTROL")
		_show_moment_result("GAGAL KONTROL BOLA!", UITheme.ACCENT_RED, 1.35)

func _handle_qte_tap() -> void:
	if _qte_resolved:
		return
	_qte_resolved = true
	if _qte_overlay != null:
		_qte_overlay.visible = false
	var err: float = absf(_qte_progress - 1.0)
	var is_perfect: bool = (err <= _qte_perfect_tol)
	var is_good: bool = (err <= _qte_good_tol)

	if _phase == MatchPhase.HEADER_TIMING:
		_moment_banner.visible = false
		if is_good:
			_player_sprite.frame = 7
			var pow_scale: float = 1.08 if is_perfect else 0.94
			_ball_pos = Vector3(_player_pos.x, 1.55, _player_pos.z - 0.35)
			_ball_vel = _header_aim_vel * pow_scale
			if not is_perfect:
				_ball_vel.x += randf_range(-1.4, 1.4)
			_ball_omega = _header_aim_omega
			_flight_timer = 0.0
			_gk_react_timer = float(get_opp_gk_profile().get("reaction_delay", 0.25))
			_phase = MatchPhase.BALL_IN_FLIGHT
			_camera_shake = 0.45 if is_perfect else 0.25
			AudioSynth.play_kick(0.95 if is_perfect else 0.72)
			if is_perfect:
				_adjust_rating(0.15, "SUNDULAN SEMPURNA")
			_ticker_lbl.text = "SUNDULAN SEMPURNA!" if is_perfect else "Sundulan terarah!"
			_shots_telemetry.append({
				"type": "HEADER_CROSS", "outcome": "WIDE",
				"pitchCoord": {"x": clampf((_ball_pos.x + 34.0) / 68.0, 0.05, 0.95), "y": clampf((52.5 - _ball_pos.z) / 52.5, 0.05, 0.95)},
				"goalCoord": {"x": 0.5, "y": 0.5},
				"distanceMeters": snappedf(_ball_pos.distance_to(Vector3(0, 0, -52.5)), 0.1),
			})
		else:
			var early_s: String = "TERLALU CEPAT MENYUNDUL!" if _qte_progress < 1.0 else "SUNDULAN MELESET!"
			AudioSynth.play_save()
			_adjust_rating(-0.25, "SUNDULAN GAGAL")
			_show_moment_result(early_s, UITheme.ACCENT_RED, 1.35)
		return

	if _phase == MatchPhase.QTE_DRIBBLE_DUEL:
		if is_good:
			_dribbles_won += 1
			_adjust_rating(0.30 if is_perfect else 0.20, "BEK TERLEWATI")
			var side_ev: float = 1.0 if _player_pos.x <= 0.0 else -1.0
			_player_pos = Vector3(clampf(_player_pos.x + side_ev * 2.2, -24.0, 24.0), 0.0, clampf(_duel_def_start.z - 2.6, -46.0, -20.0))
			if not _defender_positions.is_empty():
				_defender_positions[0] = Vector3(_duel_def_start.x - side_ev * 1.5, 0.0, _duel_def_start.z + 3.2)
				_defenders[0].frame = 3
			AudioSynth.play_ring_tap(true)
			_enter_user_follow_up_shot(
				"BEK TERLEWATI! (%s)" % ("SEMPURNA!" if is_perfect else "BAGUS!"),
				"Ruang terbuka! Gerak bebas, tembak ke gawang, atau umpan rekan!"
			)
		else:
			if not _defenders.is_empty():
				_defenders[0].frame = 3
			AudioSynth.play_save()
			_adjust_rating(-0.30, "DRIBEL GAGAL")
			_show_moment_result("DRIBEL GAGAL! DIREBUT BEK", UITheme.ACCENT_RED, 1.35)
		return

	if _phase == MatchPhase.QTE_LONG_CONTROL:
		if is_good:
			_adjust_rating(0.20 if is_perfect else 0.10, "KONTROL SEMPURNA")
			_trail_points.clear()
			_trail_imm.clear_surfaces()
			AudioSynth.play_ring_tap(true)
			_enter_user_follow_up_shot(
				"KONTROL %s!" % ("SEMPURNA" if is_perfect else "BAGUS"),
				"Bola jinak di kakimu! Giring bebas atau langsung tembak/umpan!"
			)
		else:
			AudioSynth.play_save()
			_adjust_rating(-0.30, "GAGAL KONTROL")
			_show_moment_result("GAGAL KONTROL BOLA!", UITheme.ACCENT_RED, 1.35)

func _moment_type_str() -> String:
	match _moment_type:
		MomentType.PASS: return "PASS"
		MomentType.DRIBBLE: return "DRIBBLE"
		MomentType.FREE_KICK: return "FREE_KICK"
		MomentType.PENALTY: return "PENALTY"
		MomentType.TEAMMATE_PASS: return "TEAMMATE_PASS"
		MomentType.HEADER_CROSS: return "HEADER_CROSS"
		MomentType.DRIBBLE_DUEL: return "DRIBBLE_DUEL"
		MomentType.LONG_PASS_CONTROL: return "LONG_PASS_CONTROL"
		MomentType.CORNER_KICK: return "CORNER_KICK"
		MomentType.GK_BUILDUP: return "GK_BUILDUP"
		_: return "OPEN_PLAY"

func _update_score_label() -> void:
	if run_mode != RunMode.CAREER_MATCH:
		return
	_sync_broadcast_scorebug()

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
	# 1. Broadcast Highlight Board (Gambar 6 2-Column Split + Competition-Adaptive Themes)
	_board_panel = Control.new()
	_board_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_board_panel.visible = false
	add_child(_board_panel)

	_board_bg = Control.new()
	_board_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_board_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_board_bg.draw.connect(_draw_board_backdrop)
	_board_panel.add_child(_board_bg)

	var outer_hb := HBoxContainer.new()
	outer_hb.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer_hb.offset_left = 12
	outer_hb.offset_right = -12
	outer_hb.offset_top = 10
	outer_hb.offset_bottom = -10
	outer_hb.add_theme_constant_override("separation", 12)
	_board_panel.add_child(outer_hb)

	# =========================================================================
	# LEFT BROADCAST RAIL (~356px): Scoreboard | 2 Tabs | Momentum + 4 Stats | Rating/Energy | Controls
	# =========================================================================
	var left_rail := VBoxContainer.new()
	left_rail.custom_minimum_size = Vector2(356, 0)
	left_rail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_rail.add_theme_constant_override("separation", 6)
	outer_hb.add_child(left_rail)

	# 1A. Broadcast Scoreboard Card
	var top_card := PanelContainer.new()
	top_card.add_theme_stylebox_override("panel", UITheme.make_box(Color("#0A1D4D", 0.72), Color("#60A5FA", 0.35), 1, 6))
	left_rail.add_child(top_card)
	var thb := HBoxContainer.new()
	thb.add_theme_constant_override("separation", 8)
	top_card.add_child(thb)

	_board_emblem = Control.new()
	_board_emblem.custom_minimum_size = Vector2(56, 56)
	_board_emblem.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_board_emblem.draw.connect(_draw_comp_emblem)
	thb.add_child(_board_emblem)

	var hdr_vb := VBoxContainer.new()
	hdr_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr_vb.add_theme_constant_override("separation", 2)
	thb.add_child(hdr_vb)

	var comp_top_hb := HBoxContainer.new()
	comp_top_hb.add_theme_constant_override("separation", 4)
	hdr_vb.add_child(comp_top_hb)
	_board_comp_lbl = Label.new()
	_board_comp_lbl.text = "PIALA ELITE"
	_board_comp_lbl.clip_text = true
	_board_comp_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_board_comp_lbl.add_theme_font_override("font", UITheme.get_display_font())
	_board_comp_lbl.add_theme_font_size_override("font_size", 10)
	_board_comp_lbl.add_theme_color_override("font_color", Color("#E2ECFF"))
	comp_top_hb.add_child(_board_comp_lbl)

	var skip_b := Button.new()
	skip_b.text = "SKIP >>"
	skip_b.custom_minimum_size = Vector2(56, 18)
	skip_b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	UITheme.style_btn(skip_b, Color("#4E2424", 0.85), UITheme.ACCENT_RED, 9)
	skip_b.pressed.connect(_on_skip_or_exit)
	comp_top_hb.add_child(skip_b)

	# Team Row 1 (Home)
	var r1 := HBoxContainer.new()
	r1.add_theme_constant_override("separation", 6)
	hdr_vb.add_child(r1)
	_board_home_badge_wrap = CenterContainer.new()
	_board_home_badge_wrap.custom_minimum_size = Vector2(20, 18)
	r1.add_child(_board_home_badge_wrap)
	_board_home_lbl = Label.new()
	_board_home_lbl.text = "KLUB KITA"
	_board_home_lbl.clip_text = true
	_board_home_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_board_home_lbl.add_theme_font_override("font", UITheme.get_display_font())
	_board_home_lbl.add_theme_font_size_override("font_size", 12)
	_board_home_lbl.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	r1.add_child(_board_home_lbl)
	var s1_box := PanelContainer.new()
	s1_box.custom_minimum_size = Vector2(28, 22)
	s1_box.add_theme_stylebox_override("panel", UITheme.make_box(Color("#1D4ED8", 0.75), Color("#93C5FD", 0.5), 1, 3))
	r1.add_child(s1_box)
	_board_home_score = Label.new()
	_board_home_score.text = "0"
	_board_home_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_board_home_score.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_board_home_score.add_theme_font_override("font", UITheme.get_display_font())
	_board_home_score.add_theme_font_size_override("font_size", 16)
	_board_home_score.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	s1_box.add_child(_board_home_score)

	# Team Row 2 (Away)
	var r2 := HBoxContainer.new()
	r2.add_theme_constant_override("separation", 6)
	hdr_vb.add_child(r2)
	_board_away_badge_wrap = CenterContainer.new()
	_board_away_badge_wrap.custom_minimum_size = Vector2(20, 18)
	r2.add_child(_board_away_badge_wrap)
	_board_away_lbl = Label.new()
	_board_away_lbl.text = "LAWAN"
	_board_away_lbl.clip_text = true
	_board_away_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_board_away_lbl.add_theme_font_override("font", UITheme.get_display_font())
	_board_away_lbl.add_theme_font_size_override("font_size", 12)
	_board_away_lbl.add_theme_color_override("font_color", Color("#D1DCEB"))
	r2.add_child(_board_away_lbl)
	var s2_box := PanelContainer.new()
	s2_box.custom_minimum_size = Vector2(28, 22)
	s2_box.add_theme_stylebox_override("panel", UITheme.make_box(Color("#1D4ED8", 0.75), Color("#93C5FD", 0.5), 1, 3))
	r2.add_child(s2_box)
	_board_away_score = Label.new()
	_board_away_score.text = "0"
	_board_away_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_board_away_score.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_board_away_score.add_theme_font_override("font", UITheme.get_display_font())
	_board_away_score.add_theme_font_size_override("font_size", 16)
	_board_away_score.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	s2_box.add_child(_board_away_score)

	# Bottom Header Subrow: Stadium left + White Capsule Clock Pill right
	var stad_hb := HBoxContainer.new()
	hdr_vb.add_child(stad_hb)
	_board_stad_lbl = Label.new()
	_board_stad_lbl.text = "STADION NASIONAL"
	_board_stad_lbl.clip_text = true
	_board_stad_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_board_stad_lbl.add_theme_font_size_override("font_size", 9)
	_board_stad_lbl.add_theme_color_override("font_color", Color("#9EB4D8"))
	stad_hb.add_child(_board_stad_lbl)

	var clk_pill := PanelContainer.new()
	clk_pill.custom_minimum_size = Vector2(64, 20)
	clk_pill.add_theme_stylebox_override("panel", UITheme.make_box(Color("#E6ECF4"), Color("#FFFFFF"), 1, 9))
	stad_hb.add_child(clk_pill)
	_board_min_lbl = Label.new()
	_board_min_lbl.text = "0'"
	_board_min_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_board_min_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_board_min_lbl.add_theme_font_override("font", UITheme.get_display_font())
	_board_min_lbl.add_theme_font_size_override("font_size", 12)
	_board_min_lbl.add_theme_color_override("font_color", Color("#0E1A30"))
	clk_pill.add_child(_board_min_lbl)

	_board_score_lbl = Label.new()
	_board_score_lbl.visible = false
	top_card.add_child(_board_score_lbl)

	# 1B. 2 Sleek View Toggle Tabs (SOROTAN | SKUAD, matching Gambar 6)
	var tab_hb := HBoxContainer.new()
	tab_hb.add_theme_constant_override("separation", 6)
	left_rail.add_child(tab_hb)
	_board_tab_btns.clear()
	var tab_names := ["▶ SOROTAN", "● SKUAD"]
	for ti in range(tab_names.size()):
		var tb := Button.new()
		tb.text = tab_names[ti]
		tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tb.custom_minimum_size = Vector2(0, 28)
		tb.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var cap_ti := ti
		tb.pressed.connect(func(): AudioSynth.play_click(); _switch_board_tab(cap_ti))
		tab_hb.add_child(tb)
		_board_tab_btns.append(tb)

	# 1C. Momentum Timeline + 4 Compact Bidirectional Live Stats Panel (Gambar 6!)
	var poss_box := PanelContainer.new()
	poss_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	poss_box.add_theme_stylebox_override("panel", UITheme.make_box(Color("#09193D", 0.65), Color("#60A5FA", 0.25), 1, 6))
	left_rail.add_child(poss_box)
	var pvb := VBoxContainer.new()
	pvb.add_theme_constant_override("separation", 5)
	poss_box.add_child(pvb)
	_board_poss_lbl = Label.new()
	_board_poss_lbl.text = "PENGUASAAN BOLA 52%"
	_board_poss_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_board_poss_lbl.add_theme_font_override("font", UITheme.get_display_font())
	_board_poss_lbl.add_theme_font_size_override("font_size", 12)
	_board_poss_lbl.add_theme_color_override("font_color", Color("#FB7185"))
	pvb.add_child(_board_poss_lbl)
	var p_bg := ColorRect.new()
	p_bg.color = Color("#0F172A", 0.7)
	p_bg.custom_minimum_size = Vector2(0, 4)
	pvb.add_child(p_bg)
	_board_poss_bar = ColorRect.new()
	_board_poss_bar.color = Color("#38BDF8")
	_board_poss_bar.custom_minimum_size = Vector2(180, 4)
	p_bg.add_child(_board_poss_bar)
	_board_timeline = Control.new()
	_board_timeline.custom_minimum_size = Vector2(0, 72)
	_board_timeline.draw.connect(_draw_board_timeline)
	pvb.add_child(_board_timeline)

	_board_mini_stats_vb = VBoxContainer.new()
	_board_mini_stats_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_board_mini_stats_vb.alignment = BoxContainer.ALIGNMENT_CENTER
	_board_mini_stats_vb.add_theme_constant_override("separation", 5)
	pvb.add_child(_board_mini_stats_vb)
	_board_stats_vb = _board_mini_stats_vb

	# 1D. Rating + Sparkline | Energy Bar (Gambar 6 bottom-left)
	var bot_top := HBoxContainer.new()
	bot_top.add_theme_constant_override("separation", 6)
	left_rail.add_child(bot_top)

	var r_panel := PanelContainer.new()
	r_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r_panel.add_theme_stylebox_override("panel", UITheme.make_box(Color("#081533", 0.78), Color("#60A5FA", 0.25), 1, 5))
	bot_top.add_child(r_panel)
	var r_hb := HBoxContainer.new()
	r_hb.add_theme_constant_override("separation", 6)
	r_panel.add_child(r_hb)
	_board_rating_lbl = Label.new()
	_board_rating_lbl.text = "RATING\n6,2"
	_board_rating_lbl.add_theme_font_override("font", UITheme.get_display_font())
	_board_rating_lbl.add_theme_font_size_override("font_size", 13)
	_board_rating_lbl.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	r_hb.add_child(_board_rating_lbl)
	_board_sparkline = Control.new()
	_board_sparkline.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_board_sparkline.custom_minimum_size = Vector2(54, 28)
	_board_sparkline.draw.connect(_draw_rating_sparkline)
	r_hb.add_child(_board_sparkline)

	var e_panel := PanelContainer.new()
	e_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	e_panel.add_theme_stylebox_override("panel", UITheme.make_box(Color("#081533", 0.78), Color("#60A5FA", 0.25), 1, 5))
	bot_top.add_child(e_panel)
	var e_vb := VBoxContainer.new()
	e_vb.alignment = BoxContainer.ALIGNMENT_CENTER
	e_vb.add_theme_constant_override("separation", 3)
	e_panel.add_child(e_vb)
	var e_top := HBoxContainer.new()
	e_vb.add_child(e_top)
	var e_title := Label.new()
	e_title.text = "ENERGI"
	e_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	e_title.add_theme_font_size_override("font_size", 9)
	e_title.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	e_top.add_child(e_title)
	_board_energy_lbl = Label.new()
	_board_energy_lbl.text = "100%"
	_board_energy_lbl.add_theme_font_override("font", UITheme.get_display_font())
	_board_energy_lbl.add_theme_font_size_override("font_size", 11)
	_board_energy_lbl.add_theme_color_override("font_color", UITheme.ACCENT_GREEN)
	e_top.add_child(_board_energy_lbl)
	var e_bg := ColorRect.new()
	e_bg.color = Color("#111B2E")
	e_bg.custom_minimum_size = Vector2(0, 7)
	e_vb.add_child(e_bg)
	_board_energy_bar = ColorRect.new()
	_board_energy_bar.color = UITheme.ACCENT_GREEN
	_board_energy_bar.custom_minimum_size = Vector2(120, 7)
	e_bg.add_child(_board_energy_bar)

	# 1E. Tactical Controls Row (STRATEGI | INTENSITAS | TAHAN | II | x1)
	var tac_hb := HBoxContainer.new()
	tac_hb.add_theme_constant_override("separation", 4)
	left_rail.add_child(tac_hb)
	_strat_btn = Button.new()
	_strat_btn.text = "STRATEGI\nSEIMBANG"
	_strat_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_strat_btn.custom_minimum_size = Vector2(0, 38)
	_strat_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	UITheme.style_btn(_strat_btn, Color("#B46924"), UITheme.ACCENT_GOLD, 9)
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
	_inten_btn.custom_minimum_size = Vector2(0, 38)
	_inten_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	UITheme.style_btn(_inten_btn, Color("#A85B1E"), UITheme.ACCENT_GOLD, 9)
	_inten_btn.pressed.connect(func():
		AudioSynth.play_click()
		var opts := ["RENDAH", "SEDANG", "TINGGI"]
		var cur: String = str(CareerState.career["careerMeta"].get("intensity", "SEDANG"))
		var nxt: String = opts[(opts.find(cur) + 1) % opts.size()]
		CareerState.career["careerMeta"]["intensity"] = nxt
		_inten_btn.text = "INTENSITAS\n" + nxt
	)
	tac_hb.add_child(_inten_btn)

	var hold_b := Button.new()
	hold_b.text = "▸▸\nTAHAN"
	hold_b.custom_minimum_size = Vector2(54, 38)
	hold_b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	UITheme.style_btn(hold_b, Color("#0E2244"), UITheme.ACCENT_CYAN, 9)
	hold_b.button_down.connect(func(): _board_hold_fast = true; AudioSynth.play_click())
	hold_b.button_up.connect(func(): _board_hold_fast = false)
	tac_hb.add_child(hold_b)

	_board_pause_btn = Button.new()
	_board_pause_btn.text = "II"
	_board_pause_btn.custom_minimum_size = Vector2(34, 38)
	_board_pause_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	UITheme.style_btn(_board_pause_btn, Color("#0E1D38"), UITheme.BORDER_STEEL, 11)
	_board_pause_btn.pressed.connect(func(): AudioSynth.play_click(); _open_pause_menu())
	tac_hb.add_child(_board_pause_btn)

	_board_spd_btn = Button.new()
	_board_spd_btn.text = "x1"
	_board_spd_btn.custom_minimum_size = Vector2(36, 38)
	_board_spd_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	UITheme.style_btn(_board_spd_btn, Color("#0E1D38"), UITheme.ACCENT_CYAN, 11)
	_board_spd_btn.pressed.connect(func(): _on_toggle_speed(); _board_spd_btn.text = "x%d" % int(_sim_speed))
	tac_hb.add_child(_board_spd_btn)

	# =========================================================================
	# RIGHT STAGE COLUMN (~570px): BIG HERO HIGHLIGHT + SMALL COMPACT FEED (Gambar 6!)
	# =========================================================================
	var right_stage := VBoxContainer.new()
	right_stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_stage.add_theme_constant_override("separation", 8)
	outer_hb.add_child(right_stage)

	# Card Warning & User Subbed Banners
	_board_cards_bar = PanelContainer.new()
	_board_cards_bar.visible = false
	_board_cards_bar.add_theme_stylebox_override("panel", UITheme.make_box(Color("#47131A", 0.9), UITheme.ACCENT_GOLD, 1, 4))
	right_stage.add_child(_board_cards_bar)
	_board_cards_lbl = Label.new()
	_board_cards_lbl.text = ""
	_board_cards_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_board_cards_lbl.add_theme_font_override("font", UITheme.get_display_font())
	_board_cards_lbl.add_theme_font_size_override("font_size", 10)
	_board_cards_lbl.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	_board_cards_bar.add_child(_board_cards_lbl)

	_board_sub_banner = PanelContainer.new()
	_board_sub_banner.visible = false
	_board_sub_banner.add_theme_stylebox_override("panel", UITheme.make_box(Color("#1A263C", 0.9), UITheme.ACCENT_CYAN, 1, 4))
	right_stage.add_child(_board_sub_banner)
	var sub_b_lbl := Label.new()
	sub_b_lbl.name = "SubLbl"
	sub_b_lbl.text = "DIGANTI PELATIH • MENONTON SISA LAGA DARI BANGKU CADANGAN"
	sub_b_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_b_lbl.add_theme_font_override("font", UITheme.get_display_font())
	sub_b_lbl.add_theme_font_size_override("font_size", 10)
	sub_b_lbl.add_theme_color_override("font_color", UITheme.ACCENT_CYAN)
	_board_sub_banner.add_child(sub_b_lbl)

	var views_wrap := Control.new()
	views_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_stage.add_child(views_wrap)
	_board_views.clear()

	# View 0: BIG HERO HIGHLIGHT BANNER + SMALL COMPACT COMMENTARY FEED
	var feed_col := VBoxContainer.new()
	feed_col.set_anchors_preset(Control.PRESET_FULL_RECT)
	feed_col.add_theme_constant_override("separation", 10)
	views_wrap.add_child(feed_col)
	_board_views.append(feed_col)

	_board_hero_card = PanelContainer.new()
	_board_hero_card.custom_minimum_size = Vector2(0, 108)
	var hero_sb := StyleBoxFlat.new()
	hero_sb.bg_color = Color("#122D6D", 0.72)
	hero_sb.border_color = Color("#60A5FA", 0.50)
	hero_sb.border_width_left = 4
	hero_sb.border_width_top = 1
	hero_sb.border_width_right = 1
	hero_sb.border_width_bottom = 1
	hero_sb.set_corner_radius_all(6)
	hero_sb.content_margin_left = 10
	hero_sb.content_margin_right = 12
	hero_sb.content_margin_top = 8
	hero_sb.content_margin_bottom = 8
	_board_hero_card.add_theme_stylebox_override("panel", hero_sb)
	feed_col.add_child(_board_hero_card)

	var hl_hb := HBoxContainer.new()
	hl_hb.alignment = BoxContainer.ALIGNMENT_BEGIN
	hl_hb.add_theme_constant_override("separation", 14)
	_board_hero_card.add_child(hl_hb)

	var port_frame := PanelContainer.new()
	port_frame.custom_minimum_size = Vector2(82, 86)
	port_frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	port_frame.add_theme_stylebox_override("panel", UITheme.make_box(Color("#0D1D42", 0.85), Color("#93C5FD", 0.45), 1, 5))
	hl_hb.add_child(port_frame)
	_board_hl_portraits = HBoxContainer.new()
	_board_hl_portraits.alignment = BoxContainer.ALIGNMENT_CENTER
	port_frame.add_child(_board_hl_portraits)

	var hl_text_vb := VBoxContainer.new()
	hl_text_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hl_text_vb.alignment = BoxContainer.ALIGNMENT_CENTER
	hl_text_vb.add_theme_constant_override("separation", 3)
	hl_hb.add_child(hl_text_vb)

	_board_hl_badge = Label.new()
	_board_hl_badge.text = "● 0' • KICKOFF"
	_board_hl_badge.add_theme_font_override("font", UITheme.get_display_font())
	_board_hl_badge.add_theme_font_size_override("font_size", 11)
	_board_hl_badge.add_theme_color_override("font_color", Color("#93C5FD"))
	hl_text_vb.add_child(_board_hl_badge)

	_board_hl_name_lbl = Label.new()
	_board_hl_name_lbl.text = "PERTANDINGAN DIMULAI"
	_board_hl_name_lbl.clip_text = true
	_board_hl_name_lbl.add_theme_font_override("font", UITheme.get_display_font())
	_board_hl_name_lbl.add_theme_font_size_override("font_size", 21)
	_board_hl_name_lbl.add_theme_color_override("font_color", Color.WHITE)
	hl_text_vb.add_child(_board_hl_name_lbl)

	_board_hl_action_lbl = Label.new()
	_board_hl_action_lbl.text = "MENUNGGU MOMEN PENTING..."
	_board_hl_action_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_board_hl_action_lbl.add_theme_font_override("font", UITheme.get_display_font())
	_board_hl_action_lbl.add_theme_font_size_override("font_size", 15)
	_board_hl_action_lbl.add_theme_color_override("font_color", Color("#86EFAC"))
	hl_text_vb.add_child(_board_hl_action_lbl)

	_board_hl_lbl = Label.new()
	_board_hl_lbl.visible = false
	hl_text_vb.add_child(_board_hl_lbl)

	# Small Compact Feed resting cleanly over the competition pitch/star watermark
	var f_scroll := ScrollContainer.new()
	f_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	f_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	feed_col.add_child(f_scroll)
	_board_feed_vb = VBoxContainer.new()
	_board_feed_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_board_feed_vb.add_theme_constant_override("separation", 4)
	f_scroll.add_child(_board_feed_vb)

	# View 1: SKUAD
	var sq_scroll := ScrollContainer.new()
	sq_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	sq_scroll.visible = false
	views_wrap.add_child(sq_scroll)
	_board_squad_vb = VBoxContainer.new()
	_board_squad_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_board_squad_vb.add_theme_constant_override("separation", 6)
	sq_scroll.add_child(_board_squad_vb)
	_board_views.append(sq_scroll)

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

	# 4. Pre-Match Animated Lineup Showcase Panel
	_lineup_panel = Control.new()
	_lineup_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_lineup_panel.visible = false
	add_child(_lineup_panel)

	# 5. Coin Flip Panel (after 120' draw in 8 BESAR / SEMI / FINAL)
	_coin_flip_panel = Control.new()
	_coin_flip_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_coin_flip_panel.visible = false
	add_child(_coin_flip_panel)

	# 6. Penalty Shootout Panel
	_pso_panel = Control.new()
	_pso_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pso_panel.visible = false
	add_child(_pso_panel)

	# 7. Pitch Invader Popup Panel
	_invader_panel = Control.new()
	_invader_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_invader_panel.visible = false
	add_child(_invader_panel)

func _get_active_comp_theme() -> Dictionary:
	var comp := "LIGA"
	var nat_id := 0
	if CareerState.has_active_career:
		var fix := CareerState.get_current_fixture()
		comp = str(fix.get("comp", "LIGA"))
		nat_id = int(CareerState.get_current_club().get("nation_id", 0))
	return GameData.get_competition_theme(comp, nat_id)

func _draw_board_backdrop() -> void:
	if _board_bg == null:
		return
	var s := _board_bg.size
	if s.x <= 0 or s.y <= 0:
		return
	var th := _get_active_comp_theme()
	var top_col: Color = th.get("bg_top", Color("#132D72"))
	var bot_col: Color = th.get("bg_bot", Color("#0B1B4C"))
	var acc_col: Color = th.get("accent", Color("#38BDF8"))
	var pat: String = str(th.get("pattern", "stars"))

	# Vertical gradient backdrop bands
	var bands := 14
	var bh := s.y / float(bands)
	for i in range(bands):
		var t := float(i) / float(bands - 1)
		_board_bg.draw_rect(Rect2(0, float(i) * bh, s.x, bh + 1.5), top_col.lerp(bot_col, t))

	# Unique procedural pattern per competition
	if pat == "stars":
		for i in range(28):
			var sx := fmod(float(i * 197 + 43), s.x)
			var sy := fmod(float(i * 113 + 29), s.y)
			var r := 2.0 + float(i % 4) * 1.4
			_board_bg.draw_circle(Vector2(sx, sy), r, Color(1, 1, 1, 0.08 + 0.04 * float(i % 3)))
			if i % 4 == 0:
				_board_bg.draw_line(Vector2(sx - 8, sy), Vector2(sx + 8, sy), Color(acc_col.r, acc_col.g, acc_col.b, 0.10), 1.5)
				_board_bg.draw_line(Vector2(sx, sy - 8), Vector2(sx, sy + 8), Color(acc_col.r, acc_col.g, acc_col.b, 0.10), 1.5)
	elif pat == "waves":
		for i in range(6):
			var y0 := s.y * (0.12 + float(i) * 0.15)
			_board_bg.draw_line(Vector2(0, y0 + 35), Vector2(s.x, y0 - 45), Color(acc_col.r, acc_col.g, acc_col.b, 0.10), 18.0)
	elif pat == "beams":
		for i in range(7):
			var x0 := s.x * (float(i) / 6.0)
			_board_bg.draw_line(Vector2(x0 - 80, 0), Vector2(x0 + 140, s.y), Color(acc_col.r, acc_col.g, acc_col.b, 0.09), 28.0)
	elif pat == "rays":
		var origin := Vector2(s.x * 0.5, s.y * 0.22)
		for i in range(18):
			var ang := float(i) * TAU / 18.0
			var p2 := origin + Vector2(cos(ang), sin(ang)) * (s.x * 0.8)
			_board_bg.draw_line(origin, p2, Color(acc_col.r, acc_col.g, acc_col.b, 0.08), 16.0)
		for j in range(24):
			var fx := fmod(float(j * 173 + 61), s.x)
			var fy := fmod(float(j * 97 + 19), s.y)
			var fc: Color = [Color("#FACC15", 0.22), Color("#38BDF8", 0.22), Color("#F43F5E", 0.22), Color("#4ADE80", 0.22)][j % 4]
			_board_bg.draw_rect(Rect2(fx, fy, 5, 3), fc)
	else:
		_board_bg.draw_rect(Rect2(0, 0, s.x, s.y * 0.35), Color(acc_col.r, acc_col.g, acc_col.b, 0.08))

	# Faint giant pitch center line & center circle (+ star ring for Elite) centered behind right stage (Gambar 6!)
	var mid_y := s.y * 0.54
	var mid_x := s.x * 0.68
	var wc := Color(1, 1, 1, 0.065)
	_board_bg.draw_line(Vector2(s.x * 0.36, mid_y), Vector2(s.x, mid_y), wc, 2.5)
	var rad_c := minf(s.x, s.y) * 0.24
	_board_bg.draw_arc(Vector2(mid_x, mid_y), rad_c, 0.0, TAU, 48, wc, 2.5)
	if pat == "stars":
		for si in range(8):
			var ang := float(si) * TAU / 8.0 - PI * 0.5
			var sc := Vector2(mid_x, mid_y) + Vector2(cos(ang), sin(ang)) * (rad_c * 1.18)
			var spts := PackedVector2Array()
			for sp_i in range(10):
				var sa := -PI * 0.5 + float(sp_i) * PI / 5.0
				var sr := 16.0 if sp_i % 2 == 0 else 6.8
				spts.append(sc + Vector2(cos(sa), sin(sa)) * sr)
			_board_bg.draw_colored_polygon(spts, Color(1, 1, 1, 0.07))

func _draw_comp_emblem() -> void:
	if _board_emblem == null:
		return
	var th := _get_active_comp_theme()
	var c := _board_emblem.size * 0.5
	var rad := minf(c.x, c.y) - 3.0
	var bg_c: Color = th.get("badge_bg", Color("#1F4BB8"))
	var ring_c: Color = th.get("badge_ring", Color("#E2E8F0"))
	var emb: String = str(th.get("emblem", "star"))
	_board_emblem.draw_circle(c, rad, bg_c)
	_board_emblem.draw_arc(c, rad, 0.0, TAU, 36, ring_c, 3.0)
	_board_emblem.draw_arc(c, rad - 5.0, 0.0, TAU, 32, Color(1, 1, 1, 0.25), 1.5)
	if emb == "star":
		var pts := PackedVector2Array([
			c + Vector2(-12, -13), c + Vector2(12, -13), c + Vector2(12, 2),
			c + Vector2(0, 14), c + Vector2(-12, 2)
		])
		_board_emblem.draw_colored_polygon(pts, Color("#F1F5F9"))
		_board_emblem.draw_circle(c + Vector2(0, -3), 5.0, bg_c)
	elif emb == "rings":
		_board_emblem.draw_arc(c + Vector2(-6, -2), 7.5, 0.0, TAU, 20, Color("#38BDF8"), 2.5)
		_board_emblem.draw_arc(c + Vector2(6, -2), 7.5, 0.0, TAU, 20, Color("#FACC15"), 2.5)
		_board_emblem.draw_arc(c + Vector2(0, 5), 7.5, 0.0, TAU, 20, Color("#4ADE80"), 2.5)
	elif emb == "flame":
		_board_emblem.draw_rect(Rect2(c.x - 9, c.y - 11, 18, 18), Color("#FB923C"))
		_board_emblem.draw_circle(c + Vector2(0, 5), 8.0, Color("#FDE047"))
	elif emb == "leaf":
		_board_emblem.draw_circle(c, 11.0, Color("#4ADE80"))
		_board_emblem.draw_line(c + Vector2(0, -10), c + Vector2(0, 10), Color("#052E16"), 2.5)
	else:
		_board_emblem.draw_rect(Rect2(c.x - 10, c.y - 10, 20, 14), Color("#FACC15"))
		_board_emblem.draw_rect(Rect2(c.x - 4, c.y + 4, 8, 7), Color("#FACC15"))

func _refresh_board_header_identities() -> void:
	if _board_panel == null or not CareerState.has_active_career:
		return
	var club := CareerState.get_current_club()
	var fix := CareerState.get_current_fixture()
	var comp: String = str(fix.get("comp", "LIGA"))
	_board_comp_lbl.text = str(fix.get("comp_label", "LIGA")).to_upper()
	_board_stad_lbl.text = GameData.get_club_stadium_name(int(club["id"]) if bool(fix.get("is_home", true)) else int(fix.get("opp_club_id", 0)))

	for w in [_board_home_badge_wrap, _board_away_badge_wrap]:
		for ch in w.get_children():
			ch.queue_free()

	if comp in ["TIMNAS", "TURNAMEN_ASIA"]:
		var my_nat := clampi(int(CareerState.career["playerProfile"].get("nationId", 16)), 0, maxi(0, GameData.nations.size() - 1))
		var opp_nat := clampi(int(fix.get("opp_nat_id", 0)), 0, maxi(0, GameData.nations.size() - 1))
		_board_home_lbl.text = str(GameData.nations[my_nat]["name"]).to_upper()
		_board_away_lbl.text = str(fix.get("opp_name", "LAWAN")).to_upper()
		_board_home_badge_wrap.add_child(UITheme.make_flag_rect(my_nat, Vector2(22, 16)))
		_board_away_badge_wrap.add_child(UITheme.make_flag_rect(opp_nat, Vector2(22, 16)))
	else:
		_board_home_lbl.text = str(club["name"]).to_upper()
		_board_away_lbl.text = str(fix.get("opp_name", "LAWAN")).to_upper()
		var c1 := ClubCrest.new()
		c1.custom_minimum_size = Vector2(20, 20)
		c1.set_club(int(club["id"]))
		_board_home_badge_wrap.add_child(c1)
		var c2 := ClubCrest.new()
		c2.custom_minimum_size = Vector2(20, 20)
		c2.set_club(int(fix.get("opp_club_id", 0)))
		_board_away_badge_wrap.add_child(c2)

	if _board_bg != null:
		_board_bg.queue_redraw()
	if _board_emblem != null:
		_board_emblem.queue_redraw()

func _switch_board_tab(idx: int) -> void:
	_board_view_idx = clampi(idx, 0, maxi(0, _board_views.size() - 1))
	for i in range(_board_views.size()):
		_board_views[i].visible = (i == _board_view_idx)
	for i in range(_board_tab_btns.size()):
		var act := (i == _board_view_idx)
		UITheme.style_btn(_board_tab_btns[i], Color("#1D4ED8") if act else Color("#0A152C", 0.72), UITheme.ACCENT_CYAN if act else Color("#FFFFFF", 0.2), 11)
	if _board_view_idx == 1:
		_refresh_squad_tab()

func _refresh_stats_tab() -> void:
	if _board_mini_stats_vb == null or not CareerState.has_active_career:
		return
	for c in _board_mini_stats_vb.get_children():
		_board_mini_stats_vb.remove_child(c)
		c.queue_free()
	var rows := [
		[maxi(_shots_us, _score_us), "●", maxi(_shots_them, _score_them)],
		[_saves_us, "✓", _saves_them],
		[_corners_us, "▸", _corners_them],
		[_fouls_us + _our_yellows + _our_reds, "!", _fouls_them + _opp_yellows + _opp_reds],
	]
	for rw in rows:
		var lv: int = int(rw[0])
		var ic: String = str(rw[1])
		var rv: int = int(rw[2])
		var max_v: float = maxf(1.0, float(maxi(lv, rv)))
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 6)
		_board_mini_stats_vb.add_child(hb)

		var l1 := Label.new()
		l1.text = str(lv)
		l1.custom_minimum_size = Vector2(20, 0)
		l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		l1.add_theme_font_override("font", UITheme.get_display_font())
		l1.add_theme_font_size_override("font_size", 11)
		l1.add_theme_color_override("font_color", Color.WHITE)
		hb.add_child(l1)

		var l_bg := ColorRect.new()
		l_bg.color = Color("#0F1D3A")
		l_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l_bg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		l_bg.custom_minimum_size = Vector2(0, 5)
		hb.add_child(l_bg)
		var l_fill := ColorRect.new()
		l_fill.color = Color("#EF4444")
		l_fill.anchor_left = 0.0
		l_fill.anchor_right = float(lv) / max_v if lv > 0 else 0.0
		l_fill.anchor_bottom = 1.0
		l_bg.add_child(l_fill)

		var ic_l := Label.new()
		ic_l.text = ic
		ic_l.custom_minimum_size = Vector2(18, 0)
		ic_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ic_l.add_theme_font_size_override("font_size", 10)
		ic_l.add_theme_color_override("font_color", Color("#94A3B8"))
		hb.add_child(ic_l)

		var r_bg := ColorRect.new()
		r_bg.color = Color("#0F1D3A")
		r_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r_bg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		r_bg.custom_minimum_size = Vector2(0, 5)
		hb.add_child(r_bg)
		var r_fill := ColorRect.new()
		r_fill.color = Color("#38BDF8")
		r_fill.anchor_left = 1.0 - (float(rv) / max_v if rv > 0 else 0.0)
		r_fill.anchor_right = 1.0
		r_fill.anchor_bottom = 1.0
		r_bg.add_child(r_fill)

		var l2 := Label.new()
		l2.text = str(rv)
		l2.custom_minimum_size = Vector2(20, 0)
		l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		l2.add_theme_font_override("font", UITheme.get_display_font())
		l2.add_theme_font_size_override("font_size", 11)
		l2.add_theme_color_override("font_color", Color.WHITE)
		hb.add_child(l2)

func _pos_badge_color(pos: String) -> Color:
	var pu: String = pos.to_upper()
	if pu == "GK":
		return Color("#B47B1B")
	if pu in ["CB", "LB", "RB", "LWB", "RWB"]:
		return Color("#2A68B8")
	if pu in ["CDM", "CM", "LM", "RM", "CAM"]:
		return Color("#6B4BC4")
	return Color("#B8324A")

func _sync_live_lineup_ratings() -> void:
	for pl in _our_lineup:
		if bool(pl.get("is_user", false)):
			pl["rating"] = clampf(_rating, 4.0, 10.0)
			pl["goals"] = _my_goals
		elif not pl.has("rating"):
			pl["rating"] = 6.0
	for pl in _opp_lineup:
		if not pl.has("rating"):
			pl["rating"] = 6.0

func _compute_match_motm_player() -> Dictionary:
	_sync_live_lineup_ratings()
	var our_club: Dictionary = CareerState.get_current_club() if CareerState.has_active_career else GameData.clubs[0]
	var opp_club: Dictionary = GameData.clubs[1]
	if CareerState.has_active_career:
		var fix: Dictionary = CareerState.get_current_fixture()
		opp_club = GameData.clubs[clampi(int(fix.get("opp_club_id", 1)), 0, GameData.clubs.size() - 1)]
	var best_p: Dictionary = {}
	var best_rtg: float = -1.0
	for pair in [[_our_lineup, our_club, true], [_opp_lineup, opp_club, false]]:
		var arr: Array = pair[0]
		var clb: Dictionary = pair[1]
		var is_us_side: bool = bool(pair[2])
		for pl_item in arr:
			var pl: Dictionary = pl_item
			var r: float = float(pl.get("rating", 6.0))
			if r > best_rtg:
				best_rtg = r
				best_p = {
					"name": str(pl.get("name", "PEMAIN")),
					"pos": str(pl.get("pos", "ST")),
					"ovr": int(pl.get("ovr", 65)),
					"seed": int(pl.get("seed", 1)),
					"rating": snappedf(r, 0.1),
					"goals": int(pl.get("goals", 0)),
					"is_user": bool(pl.get("is_user", false)),
					"is_us": is_us_side,
					"club_id": int(clb.get("id", 0)),
					"club_name": str(clb.get("name", "KLUB")),
				}
	return best_p

func _refresh_squad_tab() -> void:
	if _board_squad_vb == null:
		return
	_sync_live_lineup_ratings()
	for c in _board_squad_vb.get_children():
		_board_squad_vb.remove_child(c)
		c.queue_free()

	# Top Live Ticker Pill (Gambar 1: "• 23' ADU SEIMBANG DI LINI TENGAH")
	var tick_p := PanelContainer.new()
	var tsb := StyleBoxFlat.new()
	tsb.bg_color = Color("#1A2D42", 0.88)
	tsb.border_color = Color("#314B69")
	tsb.set_border_width_all(1)
	tsb.set_corner_radius_all(5)
	tsb.content_margin_left = 10
	tsb.content_margin_right = 10
	tsb.content_margin_top = 5
	tsb.content_margin_bottom = 5
	tick_p.add_theme_stylebox_override("panel", tsb)
	_board_squad_vb.add_child(tick_p)
	var tick_l := Label.new()
	tick_l.text = "•  %d'  %s" % [maxi(1, int(_minute)), _last_live_ticker_txt.to_upper()]
	tick_l.clip_text = true
	tick_l.add_theme_font_override("font", UITheme.get_display_font())
	tick_l.add_theme_font_size_override("font_size", 10)
	tick_l.add_theme_color_override("font_color", Color("#E2E8F0"))
	tick_p.add_child(tick_l)

	var our_club: Dictionary = CareerState.get_current_club() if CareerState.has_active_career else GameData.clubs[0]
	var opp_club: Dictionary = GameData.clubs[1]
	var opp_name: String = "TIM LAWAN"
	if CareerState.has_active_career:
		var fix: Dictionary = CareerState.get_current_fixture()
		opp_club = GameData.clubs[clampi(int(fix.get("opp_club_id", 1)), 0, GameData.clubs.size() - 1)]
		opp_name = str(fix.get("opp_name", opp_club.get("name", "TIM LAWAN")))

	var col_hb := HBoxContainer.new()
	col_hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_hb.add_theme_constant_override("separation", 10)
	_board_squad_vb.add_child(col_hb)

	var sides := [
		{"name": str(our_club.get("name", "TIM KITA")).to_upper(), "club": our_club, "starters": _our_lineup, "bench": _our_bench},
		{"name": opp_name.to_upper(), "club": opp_club, "starters": _opp_lineup, "bench": _opp_bench},
	]
	for sd_item in sides:
		var sd: Dictionary = sd_item
		var clb: Dictionary = sd["club"]
		var svb := VBoxContainer.new()
		svb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		svb.add_theme_constant_override("separation", 2)
		col_hb.add_child(svb)

		# Team Header: ▸ [ClubCrest] TEAM NAME
		var hdr_hb := HBoxContainer.new()
		hdr_hb.add_theme_constant_override("separation", 5)
		svb.add_child(hdr_hb)
		var arr_l := Label.new()
		arr_l.text = "▸"
		arr_l.add_theme_font_size_override("font_size", 10)
		arr_l.add_theme_color_override("font_color", Color("#CBD5E1"))
		hdr_hb.add_child(arr_l)
		var cr := ClubCrest.new()
		cr.custom_minimum_size = Vector2(15, 15)
		cr.set_club(int(clb.get("id", 0)))
		hdr_hb.add_child(cr)
		var tn_l := Label.new()
		tn_l.text = str(sd["name"])
		tn_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tn_l.clip_text = true
		tn_l.add_theme_font_override("font", UITheme.get_display_font())
		tn_l.add_theme_font_size_override("font_size", 10)
		tn_l.add_theme_color_override("font_color", Color.WHITE)
		hdr_hb.add_child(tn_l)

		# Sub-header: # PEMAIN | OVR | RTG
		var sh_hb := HBoxContainer.new()
		sh_hb.add_theme_constant_override("separation", 4)
		svb.add_child(sh_hb)
		var sh1 := Label.new()
		sh1.text = "  # PEMAIN"
		sh1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sh1.add_theme_font_size_override("font_size", 8)
		sh1.add_theme_color_override("font_color", Color("#8FA6C0"))
		sh_hb.add_child(sh1)
		for sh_col in [["OVR", 24], ["RTG", 28]]:
			var scl := Label.new()
			scl.text = str(sh_col[0])
			scl.custom_minimum_size = Vector2(int(sh_col[1]), 0)
			scl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			scl.add_theme_font_size_override("font_size", 8)
			scl.add_theme_color_override("font_color", Color("#8FA6C0"))
			sh_hb.add_child(scl)

		# 11 Starters
		var starters: Array = sd["starters"]
		for pl_item in starters:
			var pl: Dictionary = pl_item
			svb.add_child(_make_squad_rating_row(pl, false))

		# CADANGAN Section (Gambar 1 bottom!)
		var bench: Array = sd["bench"]
		if not bench.is_empty():
			var sp_b := Control.new()
			sp_b.custom_minimum_size = Vector2(0, 4)
			svb.add_child(sp_b)
			var bh_l := Label.new()
			bh_l.text = "▸ CADANGAN"
			bh_l.add_theme_font_override("font", UITheme.get_display_font())
			bh_l.add_theme_font_size_override("font_size", 9)
			bh_l.add_theme_color_override("font_color", Color("#CBD5E1"))
			svb.add_child(bh_l)
			for bp_item in bench:
				var bp: Dictionary = bp_item
				svb.add_child(_make_squad_rating_row(bp, true))

func _make_squad_rating_row(pl: Dictionary, is_bench: bool) -> PanelContainer:
	var is_u: bool = bool(pl.get("is_user", false))
	var pc := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#163954", 0.92) if is_u else Color("#0A1727", 0.55)
	sb.border_color = Color("#38BDF8") if is_u else Color(1, 1, 1, 0.06)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	sb.content_margin_left = 4
	sb.content_margin_right = 4
	sb.content_margin_top = 1
	sb.content_margin_bottom = 1
	pc.add_theme_stylebox_override("panel", sb)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 4)
	pc.add_child(hb)

	# Position Badge
	var pos_s: String = str(pl.get("pos", "CM"))
	var pos_p := PanelContainer.new()
	pos_p.custom_minimum_size = Vector2(26, 14)
	var psb := StyleBoxFlat.new()
	psb.bg_color = _pos_badge_color(pos_s)
	psb.set_corner_radius_all(2)
	psb.content_margin_left = 2
	psb.content_margin_right = 2
	pos_p.add_theme_stylebox_override("panel", psb)
	var pos_l := Label.new()
	pos_l.text = pos_s
	pos_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pos_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pos_l.add_theme_font_override("font", UITheme.get_display_font())
	pos_l.add_theme_font_size_override("font_size", 7)
	pos_l.add_theme_color_override("font_color", Color.WHITE)
	pos_p.add_child(pos_l)
	hb.add_child(pos_p)

	# #Number + Player Name
	var nm_txt: String = "%d %s" % [int(pl.get("num", 9)), str(pl.get("name", "PEMAIN"))]
	if bool(pl.get("subbed_out", false)):
		nm_txt += " [OUT]"
	var nm_l := Label.new()
	nm_l.text = nm_txt
	nm_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nm_l.clip_text = true
	nm_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	nm_l.add_theme_font_override("font", UITheme.get_display_font())
	nm_l.add_theme_font_size_override("font_size", 9)
	nm_l.add_theme_color_override("font_color", Color("#67E8F9") if is_u else (Color("#94A3B8") if is_bench else Color("#F1F5F9")))
	hb.add_child(nm_l)

	# Match events icons (goals / cards)
	var g_cnt: int = int(pl.get("goals", 0))
	if g_cnt > 0:
		var gl := Label.new()
		gl.text = "●%d" % g_cnt if g_cnt > 1 else "●"
		gl.add_theme_font_size_override("font_size", 8)
		gl.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
		hb.add_child(gl)
	if bool(pl.get("red", false)):
		var rc := ColorRect.new()
		rc.custom_minimum_size = Vector2(6, 9)
		rc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		rc.color = Color("#EF4444")
		hb.add_child(rc)
	elif int(pl.get("yellows", 0)) > 0:
		var yc := ColorRect.new()
		yc.custom_minimum_size = Vector2(6, 9)
		yc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		yc.color = Color("#FACC15")
		hb.add_child(yc)

	# OVR Badge
	var ovr_v: int = int(pl.get("ovr", 60))
	var ovr_p := PanelContainer.new()
	ovr_p.custom_minimum_size = Vector2(22, 14)
	var osb := StyleBoxFlat.new()
	osb.bg_color = Color("#182B44")
	osb.border_color = UITheme.ACCENT_GOLD if ovr_v >= 78 else (Color("#94A3B8") if ovr_v >= 65 else Color("#B47B48"))
	osb.set_border_width_all(1)
	osb.set_corner_radius_all(4)
	ovr_p.add_theme_stylebox_override("panel", osb)
	var ovr_l := Label.new()
	ovr_l.text = str(ovr_v)
	ovr_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ovr_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ovr_l.add_theme_font_override("font", UITheme.get_display_font())
	ovr_l.add_theme_font_size_override("font_size", 8)
	ovr_l.add_theme_color_override("font_color", Color.WHITE)
	ovr_p.add_child(ovr_l)
	hb.add_child(ovr_p)

	# Live RTG column (comma decimal: "6,3" or "-" for unused bench)
	var rtg_l := Label.new()
	rtg_l.custom_minimum_size = Vector2(28, 0)
	rtg_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rtg_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rtg_l.add_theme_font_override("font", UITheme.get_display_font())
	rtg_l.add_theme_font_size_override("font_size", 9)
	if is_bench:
		rtg_l.text = "-"
		rtg_l.add_theme_color_override("font_color", Color("#64748B"))
	else:
		var rv: float = float(pl.get("rating", 6.0))
		rtg_l.text = ("%.1f" % rv).replace(".", ",")
		var rcol: Color = Color("#67E8F9") if is_u else (UITheme.ACCENT_GOLD if rv >= 7.5 else (Color("#86EFAC") if rv >= 6.5 else Color("#E2E8F0")))
		rtg_l.add_theme_color_override("font_color", rcol)
	hb.add_child(rtg_l)
	return pc

func _draw_rating_sparkline() -> void:
	if _board_sparkline == null or _board_rating_hist.is_empty():
		return
	var s := _board_sparkline.size
	_board_sparkline.draw_line(Vector2(2, s.y * 0.5), Vector2(s.x - 2, s.y * 0.5), Color(1, 1, 1, 0.2), 1.0)
	var pts := PackedVector2Array()
	var n := maxi(2, _board_rating_hist.size())
	for i in range(_board_rating_hist.size()):
		var x := lerpf(4.0, s.x - 4.0, float(i) / float(n - 1))
		var rt := clampf((_board_rating_hist[i] - 4.0) / 6.0, 0.0, 1.0)
		pts.append(Vector2(x, lerpf(s.y - 4.0, 4.0, rt)))
	if pts.size() >= 2:
		_board_sparkline.draw_polyline(pts, UITheme.TEXT_WHITE, 2.0)
		_board_sparkline.draw_circle(pts[pts.size() - 1], 3.0, UITheme.ACCENT_GOLD)
	elif pts.size() == 1:
		_board_sparkline.draw_circle(pts[0], 3.0, UITheme.TEXT_WHITE)

func _init_match_rosters() -> void:
	_our_lineup.clear()
	_opp_lineup.clear()
	_our_bench.clear()
	_opp_bench.clear()
	var our_club: Dictionary = (CareerState.get_current_club() if CareerState.has_active_career else GameData.clubs[0]).duplicate()
	var opp_club: Dictionary = GameData.clubs[1].duplicate()
	var opp_ovr: int = 62
	if CareerState.has_active_career:
		var fix: Dictionary = CareerState.get_current_fixture()
		var opp_id: int = clampi(int(fix.get("opp_club_id", 1)), 0, GameData.clubs.size() - 1)
		opp_club = GameData.clubs[opp_id].duplicate()
		opp_ovr = int(fix.get("opp_ovr", opp_club.get("ovr", 62)))
		var user_is_home: bool = bool(fix.get("is_home", true))
		var left_c: Dictionary = our_club if user_is_home else opp_club
		var right_c: Dictionary = opp_club if user_is_home else our_club
		var our_kit: Dictionary = CareerState.get_selected_match_kit(user_is_home, left_c, right_c)
		var opp_kit: Dictionary = CareerState.get_selected_match_kit(not user_is_home, left_c, right_c)
		for kk in ["primary", "secondary", "shorts", "pattern"]:
			if our_kit.has(kk):
				our_club[kk] = our_kit[kk]
			if opp_kit.has(kk):
				opp_club[kk] = opp_kit[kk]

	var default_positions: Array[String] = ["GK", "LB", "CB", "CB", "RB", "CM", "CM", "CM", "LW", "RW", "ST"]
	var default_nums: Array[int] = [1, 3, 4, 5, 2, 6, 8, 10, 7, 11, 9]
	var our_cid: int = int(our_club.get("id", 0))
	var opp_cid: int = int(opp_club.get("id", 1))

	if CareerState.has_active_career:
		var sq: Dictionary = CareerState.career.get("clubSquad", {})
		var st_arr: Array = sq.get("starters", [])
		for i in range(mini(11, st_arr.size())):
			var sp: Dictionary = st_arr[i]
			var is_u: bool = bool(sp.get("is_user", false))
			var num_v: int = int(CareerState.career["playerProfile"].get("appearance", {}).get("shirt_num", 9)) if is_u else int(sp.get("number", default_nums[i]))
			var p_name: String = str(CareerState.career["playerProfile"].get("name", sp.get("name", "PEMAIN"))) if is_u else str(sp.get("name", "REKAN"))
			_our_lineup.append({
				"name": p_name.to_upper(),
				"pos": str(sp.get("pos", default_positions[i])),
				"num": num_v,
				"ovr": int(CareerState.career["playerProfile"].get("ovr", 60)) if is_u else int(sp.get("ovr", 60)),
				"seed": int(sp.get("seed", our_cid * 100 + i)),
				"is_user": is_u,
				"club": our_club,
				"yellows": 0, "red": false, "injured": false, "subbed_out": false,
			})
		var bn_arr: Array = sq.get("bench", [])
		for j in range(bn_arr.size()):
			var bp: Dictionary = bn_arr[j]
			_our_bench.append({
				"name": str(bp.get("name", "CADANGAN")).to_upper(),
				"pos": str(bp.get("pos", "CM")),
				"num": int(bp.get("number", 12 + j)),
				"ovr": int(bp.get("ovr", 56)),
				"seed": int(bp.get("seed", our_cid * 100 + 30 + j)),
				"is_user": false,
				"club": our_club,
				"yellows": 0, "red": false, "injured": false, "subbed_out": false,
			})

	# Ensure 11 starters & at least 5 bench players for our club
	while _our_lineup.size() < 11:
		var idx: int = _our_lineup.size()
		var ln: String = GameData.LAST_NAMES[(our_cid * 7 + idx * 5) % GameData.LAST_NAMES.size()]
		_our_lineup.append({
			"name": ln.to_upper(),
			"pos": default_positions[idx],
			"num": default_nums[idx],
			"ovr": clampi(int(our_club.get("ovr", 60)) + (idx % 5) - 2, 46, 92),
			"seed": our_cid * 100 + idx + 11,
			"is_user": (idx == 10),
			"club": our_club,
			"yellows": 0, "red": false, "injured": false, "subbed_out": false,
		})
	while _our_bench.size() < 5:
		var bi: int = _our_bench.size()
		var bln: String = GameData.LAST_NAMES[(our_cid * 13 + bi * 11 + 3) % GameData.LAST_NAMES.size()]
		_our_bench.append({
			"name": bln.to_upper(),
			"pos": ["GK", "CB", "CM", "RW", "ST"][bi % 5],
			"num": 14 + bi,
			"ovr": clampi(int(our_club.get("ovr", 60)) - 4 + bi, 44, 86),
			"seed": our_cid * 100 + 50 + bi,
			"is_user": false,
			"club": our_club,
			"yellows": 0, "red": false, "injured": false, "subbed_out": false,
		})

	# Build 11 starters + 5 bench for Opponent club
	for i in range(11):
		var oln: String = GameData.LAST_NAMES[(opp_cid * 9 + i * 7 + 5) % GameData.LAST_NAMES.size()]
		_opp_lineup.append({
			"name": oln.to_upper(),
			"pos": default_positions[i],
			"num": default_nums[i],
			"ovr": clampi(opp_ovr + (i % 5) - 2, 46, 92),
			"seed": opp_cid * 100 + i + 7,
			"is_user": false,
			"club": opp_club,
			"yellows": 0, "red": false, "injured": false, "subbed_out": false,
		})
	for j in range(5):
		var obln: String = GameData.LAST_NAMES[(opp_cid * 11 + j * 9 + 19) % GameData.LAST_NAMES.size()]
		_opp_bench.append({
			"name": obln.to_upper(),
			"pos": ["GK", "CB", "CM", "LW", "ST"][j],
			"num": 14 + j,
			"ovr": clampi(opp_ovr - 4 + j, 44, 86),
			"seed": opp_cid * 100 + 60 + j,
			"is_user": false,
			"club": opp_club,
			"yellows": 0, "red": false, "injured": false, "subbed_out": false,
		})

	for idx_r in range(_our_lineup.size()):
		_our_lineup[idx_r]["rating"] = 6.3 if idx_r == 0 else (6.2 if idx_r <= 4 else 6.0)
		_our_lineup[idx_r]["goals"] = 0
	for idx_r in range(_opp_lineup.size()):
		_opp_lineup[idx_r]["rating"] = 6.3 if idx_r == 0 else (6.2 if idx_r <= 4 else 6.0)
		_opp_lineup[idx_r]["goals"] = 0
	for bp in _our_bench:
		bp["rating"] = 6.0
		bp["goals"] = 0
	for bp in _opp_bench:
		bp["rating"] = 6.0
		bp["goals"] = 0

func _open_lineup_intro() -> void:
	_lineup_timer = 0.0
	if _lineup_panel == null:
		_start_match_kickoff()
		return
	for c in _lineup_panel.get_children():
		_lineup_panel.remove_child(c)
		c.queue_free()

	var our_club: Dictionary = CareerState.get_current_club() if CareerState.has_active_career else GameData.clubs[0]
	var opp_club: Dictionary = GameData.clubs[1]
	var comp_title: String = "PERTANDINGAN LIGA"
	if CareerState.has_active_career:
		var fix: Dictionary = CareerState.get_current_fixture()
		var opp_id: int = clampi(int(fix.get("opp_club_id", 1)), 0, GameData.clubs.size() - 1)
		opp_club = GameData.clubs[opp_id]
		comp_title = str(fix.get("comp_label", "LIGA")).to_upper()

	var bg := ColorRect.new()
	bg.color = Color("#07101C")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_lineup_panel.add_child(bg)

	var root_vb := VBoxContainer.new()
	root_vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_vb.offset_left = 10
	root_vb.offset_right = -10
	root_vb.offset_top = 8
	root_vb.offset_bottom = -8
	root_vb.add_theme_constant_override("separation", 6)
	_lineup_panel.add_child(root_vb)

	# Broadcast Header
	var hdr := PanelContainer.new()
	hdr.add_theme_stylebox_override("panel", UITheme.make_box(Color("#121F34"), UITheme.ACCENT_GOLD, 2, 6))
	root_vb.add_child(hdr)
	var hhb := HBoxContainer.new()
	hhb.add_theme_constant_override("separation", 10)
	hdr.add_child(hhb)

	var ttl := Label.new()
	ttl.text = "SUSUNAN PEMAIN • %s" % comp_title
	ttl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ttl.add_theme_font_override("font", UITheme.get_display_font())
	ttl.add_theme_font_size_override("font_size", 15)
	ttl.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	hhb.add_child(ttl)

	var vs_lbl := Label.new()
	vs_lbl.text = "%s (%d)  VS  %s (%d)" % [str(our_club.get("code", "TIM")), int(our_club.get("ovr", 60)), str(opp_club.get("code", "LWN")), int(opp_club.get("ovr", 60))]
	vs_lbl.add_theme_font_override("font", UITheme.get_display_font())
	vs_lbl.add_theme_font_size_override("font_size", 13)
	vs_lbl.add_theme_color_override("font_color", Color.WHITE)
	hhb.add_child(vs_lbl)

	var kick_btn := Button.new()
	kick_btn.text = "MULAI LAGA >"
	kick_btn.custom_minimum_size = Vector2(128, 30)
	UITheme.style_btn(kick_btn, Color("#14532D"), UITheme.ACCENT_GREEN, 11)
	kick_btn.pressed.connect(func(): AudioSynth.play_click(); _start_match_kickoff())
	hhb.add_child(kick_btn)

	# Twin Tactical Lineup Pitches (Our XI vs Opponent XI)
	var pitches_hb := HBoxContainer.new()
	pitches_hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pitches_hb.add_theme_constant_override("separation", 10)
	root_vb.add_child(pitches_hb)

	pitches_hb.add_child(_build_lineup_pitch_card(our_club, _our_lineup, true))
	pitches_hb.add_child(_build_lineup_pitch_card(opp_club, _opp_lineup, false))

	var foot := Label.new()
	foot.text = "STARTING XI (4-3-3) — KICKOFF OTOMATIS SEBENTAR LAGI"
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	foot.add_theme_font_size_override("font_size", 10)
	foot.add_theme_color_override("font_color", Color("#94A3B8"))
	root_vb.add_child(foot)

	_lineup_panel.visible = true
	AudioSynth.play_whistle(false)

func _build_lineup_pitch_card(club_dict: Dictionary, lineup_arr: Array[Dictionary], is_us: bool) -> PanelContainer:
	var c_prim: Color = club_dict.get("primary", UITheme.ACCENT_CYAN if is_us else UITheme.ACCENT_RED)
	var pitch := PanelContainer.new()
	pitch.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pitch.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pitch.add_theme_stylebox_override("panel", UITheme.make_box(Color("#124D2C"), c_prim, 2, 8))

	var pvb := VBoxContainer.new()
	pvb.add_theme_constant_override("separation", 4)
	pitch.add_child(pvb)

	# Team Name Strip
	var team_hdr := PanelContainer.new()
	team_hdr.add_theme_stylebox_override("panel", UITheme.make_box(Color("#0D261C"), c_prim, 1, 4))
	pvb.add_child(team_hdr)
	var t_lbl := Label.new()
	t_lbl.text = "%s • %s (OVR %d)" % [("TIM KAMU" if is_us else "TIM LAWAN"), str(club_dict.get("name", "KLUB")).to_upper(), int(club_dict.get("ovr", 60))]
	t_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t_lbl.add_theme_font_override("font", UITheme.get_display_font())
	t_lbl.add_theme_font_size_override("font_size", 11)
	t_lbl.add_theme_color_override("font_color", UITheme.ACCENT_GOLD if is_us else Color("#F8FAFC"))
	team_hdr.add_child(t_lbl)

	# 4-3-3 Formation Lines: FWD (8,9,10), MID (5,6,7), DEF (1,2,3,4), GK (0)
	var line_groups: Array = [[8, 9, 10], [5, 6, 7], [1, 2, 3, 4], [0]]
	# Stagger reveal order from GK -> DEF -> MID -> FWD!
	var delays: Array[float] = [1.45, 0.95, 0.50, 0.12]
	for g_idx in range(line_groups.size()):
		var row_indices: Array = line_groups[g_idx]
		var row_hb := HBoxContainer.new()
		row_hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
		row_hb.alignment = BoxContainer.ALIGNMENT_CENTER
		row_hb.add_theme_constant_override("separation", 6)
		row_hb.modulate = Color(1.0, 1.0, 1.0, 0.0)
		pvb.add_child(row_hb)

		for p_idx in row_indices:
			if p_idx >= lineup_arr.size():
				continue
			var p: Dictionary = lineup_arr[p_idx]
			var is_u: bool = bool(p.get("is_user", false))
			var is_gk: bool = (p_idx == 0 or str(p.get("pos", "")) == "GK")
			var card := PanelContainer.new()
			card.custom_minimum_size = Vector2(96, 86)
			card.add_theme_stylebox_override("panel", UITheme.make_box(Color("#1B3B2A") if not is_u else Color("#3A2B0E"), UITheme.ACCENT_GOLD if is_u else Color("#4ADE80", 0.55), 2 if is_u else 1, 5))
			row_hb.add_child(card)

			var cvb := VBoxContainer.new()
			cvb.alignment = BoxContainer.ALIGNMENT_CENTER
			cvb.add_theme_constant_override("separation", 1)
			card.add_child(cvb)

			var av := _make_highlight_avatar(p, Vector2(40, 36), is_gk)
			av.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			cvb.add_child(av)

			var nm_lbl := Label.new()
			var p_nm: String = str(p.get("name", "PEMAIN"))
			nm_lbl.text = ("%s#%d %s" % [("★ " if is_u else ""), int(p.get("num", 9)), p_nm])
			nm_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			nm_lbl.clip_text = true
			nm_lbl.custom_minimum_size = Vector2(88, 14)
			nm_lbl.add_theme_font_size_override("font_size", 9)
			nm_lbl.add_theme_color_override("font_color", UITheme.ACCENT_GOLD if is_u else Color.WHITE)
			cvb.add_child(nm_lbl)

			var pos_lbl := Label.new()
			pos_lbl.text = "%s • %d" % [str(p.get("pos", "CM")), int(p.get("ovr", 60))]
			pos_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			pos_lbl.add_theme_font_size_override("font_size", 8)
			pos_lbl.add_theme_color_override("font_color", Color("#93C5FD") if is_us else Color("#FCA5A5"))
			cvb.add_child(pos_lbl)

		# Staggered line reveal tween
		var tw := create_tween()
		tw.tween_interval(delays[g_idx])
		tw.tween_property(row_hb, "modulate:a", 1.0, 0.36).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	return pitch

func _start_match_kickoff() -> void:
	if _phase != MatchPhase.INTRO:
		return
	_phase = MatchPhase.SIMULATING
	if _lineup_panel != null:
		_lineup_panel.visible = false
	if _board_panel != null:
		_board_panel.visible = true
	AudioSynth.play_whistle(false)
	var u_dict: Dictionary = _get_user_roster_dict()
	_add_rich_board_highlight(0, "INFO", "KICKOFF!", "%s memulai laga bersama tim!" % str(u_dict.get("name", "PEMAIN")), u_dict, {}, true)
	_sync_board_hud()

func _get_user_roster_dict() -> Dictionary:
	for p in _our_lineup:
		if bool(p.get("is_user", false)):
			return p
	var club: Dictionary = CareerState.get_current_club() if CareerState.has_active_career else GameData.clubs[0]
	var uname: String = str(CareerState.career["playerProfile"].get("name", "PEMAIN")).to_upper() if CareerState.has_active_career else "PEMAIN"
	var snum: int = int(CareerState.career["playerProfile"].get("appearance", {}).get("shirt_num", 9)) if CareerState.has_active_career else 9
	return {"name": uname, "pos": "ST", "num": snum, "ovr": 65, "seed": 99, "is_user": true, "club": club}

func _pick_roster_player(is_us: bool, want_gk: bool, prefer_attacker: bool, exclude_name: String = "") -> Dictionary:
	var arr: Array[Dictionary] = _our_lineup if is_us else _opp_lineup
	if arr.is_empty():
		_init_match_rosters()
		arr = _our_lineup if is_us else _opp_lineup
	if want_gk:
		for p in arr:
			if str(p.get("pos", "")) == "GK" and not bool(p.get("subbed_out", false)) and not bool(p.get("red", false)):
				return p
		return arr[0] if not arr.is_empty() else {}
	var pref_pool: Array[Dictionary] = []
	var any_pool: Array[Dictionary] = []
	for p in arr:
		if bool(p.get("is_user", false)) or bool(p.get("subbed_out", false)) or bool(p.get("red", false)):
			continue
		if str(p.get("pos", "")) == "GK":
			continue
		if not exclude_name.is_empty() and str(p.get("name", "")).to_upper() == exclude_name.to_upper():
			continue
		any_pool.append(p)
		var pos_s: String = str(p.get("pos", "CM"))
		if prefer_attacker and pos_s in ["ST", "CF", "LW", "RW", "CAM"]:
			pref_pool.append(p)
		elif not prefer_attacker and pos_s in ["CM", "CDM", "CAM", "LW", "RW", "LB", "RB", "CB"]:
			pref_pool.append(p)
	if not pref_pool.is_empty():
		return pref_pool[randi() % pref_pool.size()]
	if not any_pool.is_empty():
		return any_pool[randi() % any_pool.size()]
	return arr[mini(1, arr.size() - 1)] if not arr.is_empty() else {}

func _make_highlight_avatar(p_dict: Dictionary, sz: Vector2, is_gk_kit: bool = false) -> PixelAvatar:
	var av := PixelAvatar.new()
	av.full_body = false
	av.custom_minimum_size = sz
	if bool(p_dict.get("is_user", false)) and CareerState.has_active_career:
		av.configure_from_career()
		var u_club: Dictionary = p_dict.get("club", {})
		if not u_club.is_empty():
			av.apply_kit(u_club)
	else:
		var club_d: Dictionary = p_dict.get("club", GameData.clubs[0])
		if is_gk_kit or str(p_dict.get("pos", "")) == "GK":
			var gk_club: Dictionary = club_d.duplicate()
			gk_club["primary"] = Color("#7C3AED") if (int(p_dict.get("seed", 0)) % 2 == 0) else Color("#EAB308")
			gk_club["secondary"] = Color("#0F172A")
			gk_club["pattern"] = "solid"
			av.configure_from_seed(int(p_dict.get("seed", 17)), gk_club, int(p_dict.get("num", 1)))
			av.glove_color = Color("#F8FAFC")
		else:
			av.configure_from_seed(int(p_dict.get("seed", 17)), club_d, int(p_dict.get("num", 9)))
	return av

func _make_portrait_card(p_dict: Dictionary, tag_txt: String, tag_col: Color, is_gk_kit: bool = false, card_kind: String = "") -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(142, 126)
	card.add_theme_stylebox_override("panel", UITheme.make_box(Color("#2D0A14"), tag_col, 2, 8))
	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 3)
	card.add_child(vb)

	var top_hb := HBoxContainer.new()
	top_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	top_hb.add_theme_constant_override("separation", 5)
	vb.add_child(top_hb)

	if card_kind == "YELLOW_CARD" or card_kind == "RED_CARD":
		var cr := ColorRect.new()
		cr.custom_minimum_size = Vector2(11, 15)
		cr.color = Color("#FACC15") if card_kind == "YELLOW_CARD" else Color("#EF4444")
		top_hb.add_child(cr)
	elif card_kind == "INJURY" or card_kind == "INJURY_SUB":
		var med := Label.new()
		med.text = "+"
		med.add_theme_font_override("font", UITheme.get_display_font())
		med.add_theme_font_size_override("font_size", 14)
		med.add_theme_color_override("font_color", Color("#EF4444"))
		top_hb.add_child(med)

	var tag_lbl := Label.new()
	tag_lbl.text = tag_txt
	tag_lbl.add_theme_font_override("font", UITheme.get_display_font())
	tag_lbl.add_theme_font_size_override("font_size", 11)
	tag_lbl.add_theme_color_override("font_color", tag_col)
	top_hb.add_child(tag_lbl)

	var av := _make_highlight_avatar(p_dict, Vector2(68, 60), is_gk_kit)
	av.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(av)

	var nm := Label.new()
	nm.text = "#%d %s" % [int(p_dict.get("num", 9)), str(p_dict.get("name", "PEMAIN"))]
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.clip_text = true
	nm.custom_minimum_size = Vector2(132, 16)
	nm.add_theme_font_override("font", UITheme.get_display_font())
	nm.add_theme_font_size_override("font_size", 11)
	nm.add_theme_color_override("font_color", Color.WHITE)
	vb.add_child(nm)
	return card

func _display_hero_highlight(item: Dictionary) -> void:
	var m: int = int(item.get("min", 0))
	var badge_title: String = str(item.get("badge", "SOROTAN"))
	var hero_name: String = str(item.get("name", "PEMAIN")).to_upper()
	var hero_action: String = str(item.get("action", "")).to_upper()
	var accent_col: Color = item.get("accent", Color("#86EFAC"))
	var p: Dictionary = item.get("player", {})
	var is_gk: bool = bool(item.get("is_gk", false))

	if _board_hl_badge != null:
		_board_hl_badge.text = "● %d' • %s" % [m, badge_title]
		_board_hl_badge.add_theme_color_override("font_color", accent_col)
	if _board_hl_name_lbl != null:
		_board_hl_name_lbl.text = hero_name
	if _board_hl_action_lbl != null:
		_board_hl_action_lbl.text = hero_action
		_board_hl_action_lbl.add_theme_color_override("font_color", accent_col)
	if _board_hl_lbl != null:
		_board_hl_lbl.text = "%s\n%s" % [hero_name, hero_action]

	if _board_hero_card != null:
		var th := _get_active_comp_theme()
		var card_bg: Color = (th.get("bg_top", Color("#132D72")) as Color).lightened(0.08)
		var hsb := StyleBoxFlat.new()
		hsb.bg_color = Color(card_bg.r, card_bg.g, card_bg.b, 0.78)
		hsb.border_color = accent_col
		hsb.border_width_left = 4
		hsb.border_width_top = 1
		hsb.border_width_right = 1
		hsb.border_width_bottom = 1
		hsb.set_corner_radius_all(6)
		hsb.content_margin_left = 10
		hsb.content_margin_right = 12
		hsb.content_margin_top = 8
		hsb.content_margin_bottom = 8
		_board_hero_card.add_theme_stylebox_override("panel", hsb)

	if _board_hl_portraits != null:
		for c in _board_hl_portraits.get_children():
			_board_hl_portraits.remove_child(c)
			c.queue_free()
		if not p.is_empty():
			var av := _make_highlight_avatar(p, Vector2(74, 74), is_gk)
			_board_hl_portraits.add_child(av)

func _append_small_feed_row(m: int, kind: String, text_line: String, accent_col: Color, is_us: bool, major_tint: bool = false) -> void:
	if _board_feed_vb == null:
		return
	var row := PanelContainer.new()
	if major_tint:
		var row_bg := Color("#3E1322", 0.58) if is_us else Color("#0B1A34", 0.58)
		if kind == "YELLOW_CARD" or kind == "RED_CARD":
			row_bg = Color("#133A3E", 0.65)
		elif kind == "ASSIST":
			row_bg = Color("#0D3348", 0.62)
		row.add_theme_stylebox_override("panel", UITheme.make_box(row_bg, Color(accent_col.r, accent_col.g, accent_col.b, 0.35), 1, 3))
	else:
		var emp := StyleBoxEmpty.new()
		emp.content_margin_left = 4
		emp.content_margin_right = 4
		emp.content_margin_top = 2
		emp.content_margin_bottom = 2
		row.add_theme_stylebox_override("panel", emp)

	var rhb := HBoxContainer.new()
	rhb.add_theme_constant_override("separation", 8)
	row.add_child(rhb)

	var m_lbl := Label.new()
	m_lbl.text = "%d'" % m
	m_lbl.custom_minimum_size = Vector2(28, 0)
	m_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	m_lbl.add_theme_font_size_override("font_size", 10)
	m_lbl.add_theme_color_override("font_color", Color("#94A3B8"))
	rhb.add_child(m_lbl)

	var ic_box := PanelContainer.new()
	ic_box.custom_minimum_size = Vector2(16, 16)
	ic_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var ic_bg := Color("#1E3A5F", 0.85)
	var k_icon := "•"
	match kind:
		"GOAL", "OPP_GOAL":
			ic_bg = Color("#D97706") if kind == "GOAL" else Color("#DC2626")
			k_icon = "●"
		"ASSIST":
			ic_bg = Color("#0284C7")
			k_icon = "★"
		"SAVE":
			ic_bg = Color("#0E7490")
			k_icon = "✓"
		"YELLOW_CARD":
			ic_bg = Color("#CA8A04")
			k_icon = "!"
		"RED_CARD":
			ic_bg = Color("#DC2626")
			k_icon = "X"
		"USER_SUB", "INJURY_SUB":
			ic_bg = Color("#0D9488")
			k_icon = "▲"
		"CORNER":
			ic_bg = Color("#4338CA")
			k_icon = "▸"
	ic_box.add_theme_stylebox_override("panel", UITheme.make_box(ic_bg, Color.TRANSPARENT, 0, 2))
	var icon_lbl := Label.new()
	icon_lbl.text = k_icon
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 9)
	icon_lbl.add_theme_color_override("font_color", Color.WHITE)
	ic_box.add_child(icon_lbl)
	rhb.add_child(ic_box)

	var txt_lbl := Label.new()
	txt_lbl.text = text_line.to_upper()
	txt_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	txt_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	txt_lbl.add_theme_font_size_override("font_size", 10)
	txt_lbl.add_theme_color_override("font_color", accent_col if major_tint else Color("#DCE8F8"))
	rhb.add_child(txt_lbl)

	_board_feed_vb.add_child(row)
	_board_feed_vb.move_child(row, 0)
	while _board_feed_vb.get_child_count() > 26:
		var last_c: Node = _board_feed_vb.get_child(_board_feed_vb.get_child_count() - 1)
		_board_feed_vb.remove_child(last_c)
		last_c.queue_free()

func _add_rich_board_highlight(m: int, kind: String, title: String, desc: String, p1: Dictionary, p2: Dictionary, is_us: bool) -> void:
	_board_events.append({"min": m, "kind": kind, "us": is_us})
	var accent_col: Color = Color("#86EFAC")
	var badge_title: String = "SOROTAN"
	var p1_gk: bool = false
	var hero_name: String = str(p1.get("name", title)).to_upper() if not p1.is_empty() else title.to_upper()
	var hero_action: String = desc.to_upper() if not desc.is_empty() else title.to_upper()

	match kind:
		"GOAL", "OPP_GOAL":
			if is_us:
				_shots_us += 1
			else:
				_shots_them += 1
			accent_col = UITheme.ACCENT_GOLD if kind == "GOAL" else Color("#FCA5A5")
			badge_title = "GOL! (%d-%d)" % [_score_us, _score_them]
			hero_action = "CETAK GOL! (%d-%d)" % [_score_us, _score_them]
		"SAVE":
			if is_us:
				_saves_us += 1
				_shots_them += 1
			else:
				_saves_them += 1
				_shots_us += 1
			accent_col = UITheme.ACCENT_CYAN
			badge_title = "PENYELAMATAN"
			hero_action = "TEPISAN GEMILANG KIPER!"
			p1_gk = true
		"SHOT":
			if is_us:
				_shots_us += 1
			else:
				_shots_them += 1
			accent_col = Color("#86EFAC") if is_us else Color("#FCA5A5")
			badge_title = "PELUANG"
		"CORNER":
			if is_us:
				_corners_us += 1
			else:
				_corners_them += 1
			accent_col = Color("#93C5FD")
			badge_title = "KORNER"
		"YELLOW_CARD":
			if is_us:
				_fouls_us += 1
			else:
				_fouls_them += 1
			accent_col = Color("#FACC15")
			badge_title = "KARTU KUNING"
			hero_action = "KARTU KUNING • PELANGGARAN KERAS"
		"RED_CARD":
			if is_us:
				_fouls_us += 1
			else:
				_fouls_them += 1
			accent_col = Color("#EF4444")
			badge_title = "KARTU MERAH!"
			hero_action = "DIUSIR WASIT • KARTU MERAH!"
		"INJURY":
			accent_col = Color("#FB923C")
			badge_title = "CEDERA"
		"INJURY_RETURN":
			accent_col = UITheme.ACCENT_GREEN
			badge_title = "PULIH"
		"INJURY_SUB", "USER_SUB":
			accent_col = UITheme.ACCENT_CYAN
			badge_title = "PERGANTIAN"
			if not p2.is_empty():
				hero_action = "DIGANTIKAN OLEH %s" % str(p2.get("name", "CADANGAN")).to_upper()

	# Show Goal Scorer FIRST on the Big Hero Highlight Banner, then queue Assister right after!
	var main_item := {
		"min": m,
		"kind": kind,
		"badge": badge_title,
		"name": hero_name,
		"action": hero_action,
		"accent": accent_col,
		"player": p1,
		"is_gk": p1_gk,
		"is_us": is_us,
	}
	_display_hero_highlight(main_item)
	_hero_hl_timer = 1.25

	var feed_line := "%s • %s" % [title, desc] if (not desc.is_empty() and desc != title) else title
	_last_live_ticker_txt = feed_line
	# Update live ratings & goals on the involved roster entries
	var p1_nm: String = str(p1.get("name", "")).to_upper()
	var p2_nm: String = str(p2.get("name", "")).to_upper()
	var target_list: Array[Dictionary] = _our_lineup if is_us else _opp_lineup
	for pl in target_list:
		var r_now: float = float(pl.get("rating", 6.0))
		if str(pl.get("name", "")).to_upper() == p1_nm:
			if kind in ["GOAL", "OPP_GOAL"]:
				pl["goals"] = int(pl.get("goals", 0)) + 1
				pl["rating"] = clampf(r_now + 0.9, 4.0, 10.0)
			elif kind == "SAVE":
				pl["rating"] = clampf(r_now + 0.35, 4.0, 10.0)
			elif kind == "SHOT":
				pl["rating"] = clampf(r_now + 0.15, 4.0, 10.0)
			elif kind == "YELLOW_CARD":
				pl["rating"] = clampf(r_now - 0.30, 4.0, 10.0)
			elif kind == "RED_CARD":
				pl["rating"] = clampf(r_now - 1.0, 4.0, 10.0)
		elif not p2_nm.is_empty() and str(pl.get("name", "")).to_upper() == p2_nm and kind in ["GOAL", "OPP_GOAL"]:
			pl["rating"] = clampf(r_now + 0.55, 4.0, 10.0)
	if _board_view_idx == 1 and _board_panel != null and _board_panel.visible:
		_refresh_squad_tab()

	var is_major := kind in ["GOAL", "OPP_GOAL", "YELLOW_CARD", "RED_CARD", "USER_SUB", "INJURY_SUB", "SAVE"]
	_append_small_feed_row(m, kind, feed_line, accent_col, is_us, is_major)

	if kind in ["GOAL", "OPP_GOAL"] and not p2.is_empty():
		var ast_nm := str(p2.get("name", "REKAN")).to_upper()
		var sc_nm := str(p1.get("name", "REKAN")).to_upper()
		_hero_hl_queue.append({
			"min": m,
			"kind": "ASSIST",
			"badge": "ASIS!",
			"name": ast_nm,
			"action": "UMPAN ASIS UNTUK %s!" % sc_nm,
			"accent": Color("#67E8F9"),
			"player": p2,
			"is_gk": false,
			"is_us": is_us,
			"log_feed": true,
			"feed_txt": "ASIS %s UNTUK GOL %s!" % [ast_nm, sc_nm],
		})

	if _board_timeline != null:
		_board_timeline.queue_redraw()
	_refresh_stats_tab()

func _add_board_event(m: int, kind: String, txt: String, is_us: bool) -> void:
	var p: Dictionary = _pick_roster_player(is_us, kind == "SAVE", kind == "GOAL")
	_add_rich_board_highlight(m, kind, kind, txt, p, {}, is_us)

func _update_board_cards_banner() -> void:
	if _board_cards_bar == null or _board_cards_lbl == null:
		return
	var our_code: String = str(CareerState.get_current_club().get("code", "TIM")) if CareerState.has_active_career else "TIM"
	var opp_code: String = str(CareerState.get_current_fixture().get("opp_code", "LWN")) if CareerState.has_active_career else "LWN"
	var parts: Array[String] = []
	if _our_yellows > 2 or _our_reds > 2:
		var seg: String = our_code + ":"
		if _our_yellows > 2:
			seg += " %d KARTU KUNING" % _our_yellows
		if _our_reds > 2:
			seg += " %d KARTU MERAH" % _our_reds
		parts.append(seg)
	if _opp_yellows > 2 or _opp_reds > 2:
		var seg2: String = opp_code + ":"
		if _opp_yellows > 2:
			seg2 += " %d KARTU KUNING" % _opp_yellows
		if _opp_reds > 2:
			seg2 += " %d KARTU MERAH" % _opp_reds
		parts.append(seg2)

	if parts.is_empty():
		_board_cards_bar.visible = false
	else:
		_board_cards_lbl.text = "PERINGATAN KARTU (>2)  •  " + "   |   ".join(PackedStringArray(parts))
		_board_cards_bar.visible = true

func _trigger_match_card(is_us: bool, is_red: bool) -> void:
	var p: Dictionary = _pick_roster_player(is_us, false, false)
	if p.is_empty():
		return
	var p_name: String = str(p.get("name", "PEMAIN"))
	var team_code: String = str(CareerState.get_current_club().get("code", "TIM") if is_us else CareerState.get_current_fixture().get("opp_code", "LWN")) if CareerState.has_active_career else ("TIM" if is_us else "LWN")
	var m_now: int = mini(90, int(_minute))
	if not is_red:
		p["yellows"] = int(p.get("yellows", 0)) + 1
		if is_us:
			_our_yellows += 1
		else:
			_opp_yellows += 1
		if int(p["yellows"]) >= 2:
			p["red"] = true
			if is_us:
				_our_reds += 1
			else:
				_opp_reds += 1
			_add_rich_board_highlight(m_now, "RED_CARD", "KARTU MERAH %s (%s)!" % [p_name, team_code], "Kartu kuning kedua — %s diusir wasit!" % p_name, p, {}, is_us)
		else:
			_add_rich_board_highlight(m_now, "YELLOW_CARD", "KARTU KUNING %s (%s)" % [p_name, team_code], "Pelanggaran keras di menit %d'." % m_now, p, {}, is_us)
	else:
		p["red"] = true
		if is_us:
			_our_reds += 1
		else:
			_opp_reds += 1
		_add_rich_board_highlight(m_now, "RED_CARD", "KARTU MERAH %s (%s)!" % [p_name, team_code], "Tekel berbahaya langsung diganjar kartu merah!", p, {}, is_us)
	_update_board_cards_banner()

func _pop_bench_sub(is_us: bool, want_gk: bool = false) -> Dictionary:
	var bench_arr: Array[Dictionary] = _our_bench if is_us else _opp_bench
	if not bench_arr.is_empty():
		for i in range(bench_arr.size()):
			var bp: Dictionary = bench_arr[i]
			var is_gk: bool = (str(bp.get("pos", "")) == "GK")
			if is_gk == want_gk:
				bench_arr.remove_at(i)
				return bp
		var fallback_p: Dictionary = bench_arr.pop_front()
		return fallback_p
	var club_d: Dictionary = CareerState.get_current_club() if (is_us and CareerState.has_active_career) else GameData.clubs[1]
	return {"name": "CADANGAN", "pos": "GK" if want_gk else "CM", "num": 19, "ovr": 58, "seed": 777, "is_user": false, "club": club_d, "yellows": 0, "red": false, "injured": false, "subbed_out": false}

func _trigger_match_injury(is_us: bool, force_will_return: int = -1, force_recovery: int = -1) -> void:
	var arr: Array[Dictionary] = _our_lineup if is_us else _opp_lineup
	var candidates: Array[Dictionary] = []
	for p in arr:
		if bool(p.get("is_user", false)) or bool(p.get("injured", false)) or bool(p.get("subbed_out", false)) or bool(p.get("red", false)):
			continue
		if str(p.get("pos", "")) == "GK":
			continue
		candidates.append(p)
	if candidates.is_empty():
		return
	var p: Dictionary = candidates[randi() % candidates.size()]
	p["injured"] = true
	var p_name: String = str(p.get("name", "PEMAIN"))
	var team_code: String = str(CareerState.get_current_club().get("code", "TIM") if is_us else CareerState.get_current_fixture().get("opp_code", "LWN")) if CareerState.has_active_career else ("TIM" if is_us else "LWN")
	var m_now: int = mini(90, int(_minute))
	var will_return: bool = (force_will_return == 1) if force_will_return >= 0 else (randf() < 0.58)

	if not will_return:
		# Possibility 1: Severe injury — cannot continue, coach immediately substitutes
		p["subbed_out"] = true
		var sub_p: Dictionary = _pop_bench_sub(is_us)
		var sub_name: String = str(sub_p.get("name", "CADANGAN"))
		arr.append(sub_p)
		_add_rich_board_highlight(m_now, "INJURY_SUB", "%s CEDERA PARAH (%s)!" % [p_name, team_code], "Tidak bisa lanjut! Pelatih memasukkan %s." % sub_name, p, sub_p, is_us)
	else:
		# Possibility 2: Treated off-pitch with random recovery time (if >10 min, coach subs them out!)
		var rec_mins: int = force_recovery if force_recovery > 0 else randi_range(4, 16)
		_active_injuries.append({
			"player": p,
			"is_us": is_us,
			"start_min": m_now,
			"recovery_mins": rec_mins,
			"team_code": team_code,
		})
		_add_rich_board_highlight(m_now, "INJURY", "%s CEDERA (%s)" % [p_name, team_code], "Mendapat perawatan medis di pinggir lapangan...", p, {}, is_us)

func _process_active_injuries() -> void:
	if _active_injuries.is_empty():
		return
	var m_now: int = mini(90, int(_minute))
	for i in range(_active_injuries.size() - 1, -1, -1):
		var inj: Dictionary = _active_injuries[i]
		var p: Dictionary = inj["player"]
		var is_us: bool = bool(inj["is_us"])
		var start_m: int = int(inj["start_min"])
		var rec_m: int = int(inj["recovery_mins"])
		var team_code: String = str(inj["team_code"])
		var elapsed: int = m_now - start_m
		if rec_m > 10 and elapsed >= 10:
			# Recovery took more than 10 minutes -> Coach replaces the injured player!
			p["subbed_out"] = true
			var sub_p: Dictionary = _pop_bench_sub(is_us)
			var arr: Array[Dictionary] = _our_lineup if is_us else _opp_lineup
			arr.append(sub_p)
			_add_rich_board_highlight(m_now, "INJURY_SUB", "%s DIGANTI (>10 MENIT)!" % str(p.get("name", "PEMAIN")), "Cedera terlalu lama (%s) — %s masuk menggantikan!" % [team_code, str(sub_p.get("name", "CADANGAN"))], p, sub_p, is_us)
			_active_injuries.remove_at(i)
		elif rec_m <= 10 and elapsed >= rec_m:
			# Player recovers in time and returns to the pitch!
			p["injured"] = false
			_add_rich_board_highlight(m_now, "INJURY_RETURN", "%s KEMBALI KE LAPANGAN!" % str(p.get("name", "PEMAIN")), "Pulih dalam %d menit & kembali membela %s." % [rec_m, team_code], p, {}, is_us)
			_active_injuries.remove_at(i)

func _check_coach_user_substitution() -> void:
	if run_mode != RunMode.CAREER_MATCH or _user_subbed_out:
		return
	if _minute >= 28.0 and _user_match_energy <= 22.0:
		_substitute_user_out("ENERGI HAMPIR HABIS (%d%%)" % int(round(_user_match_energy)))
	elif _minute >= 58.0 and _rating < 5.6:
		_substitute_user_out("PERFORMA KURANG BAGUS (RATING %.1f)" % _rating)

func _substitute_user_out(reason: String) -> void:
	if _user_subbed_out:
		return
	_user_subbed_out = true
	_user_sub_minute = mini(90, int(_minute))
	var u_dict: Dictionary = _get_user_roster_dict()
	u_dict["subbed_out"] = true
	var sub_p: Dictionary = _pop_bench_sub(true)
	_our_lineup.append(sub_p)
	_add_rich_board_highlight(_user_sub_minute, "USER_SUB", "PELATIH MENGGANTIMU!", "%s — %s masuk menggantikanmu." % [reason, str(sub_p.get("name", "CADANGAN"))], u_dict, sub_p, true)
	if _board_sub_banner != null:
		var lbl := _board_sub_banner.get_node_or_null("SubLbl") as Label
		if lbl != null:
			lbl.text = "DIGANTI PELATIH DI MENIT %d' (%s) — SIMULASI LANJUT" % [_user_sub_minute, reason]
		_board_sub_banner.visible = true
	AudioSynth.play_whistle(false)

func _push_random_sim_event() -> void:
	var r: float = randf()
	var is_us: bool = randf() < 0.52
	var m_now: int = mini(90, int(_minute))
	var tot_y: int = _our_yellows + _opp_yellows
	var tot_r: int = _our_reds + _opp_reds
	if r < 0.24:
		var gk_p: Dictionary = _pick_roster_player(is_us, true, false)
		var team_c: String = str(CareerState.get_current_club().get("code", "TIM") if is_us else CareerState.get_current_fixture().get("opp_code", "LWN")) if CareerState.has_active_career else ("TIM" if is_us else "LWN")
		_add_rich_board_highlight(m_now, "SAVE", "PENYELAMATAN %s!" % str(gk_p.get("name", "KIPER")), "TEPISAN GEMILANG KIPER %s!" % team_c, gk_p, {}, is_us)
	elif r < 0.42:
		var sp: Dictionary = _pick_roster_player(is_us, false, true)
		var shot_acts := ["SUNDUL TINGGI", "VOLI MELAMBUNG DI ATAS", "SEPAKAN KERAS MELEBAR", "TEMBAKAN JARAK JAUH TIPIS"]
		var act_s: String = shot_acts[randi() % shot_acts.size()]
		_add_rich_board_highlight(m_now, "SHOT", "%s %s" % [str(sp.get("name", "PEMAIN")), act_s], act_s, sp, {}, is_us)
	elif r < 0.54:
		var cp: Dictionary = _pick_roster_player(is_us, false, false)
		_add_rich_board_highlight(m_now, "CORNER", "KORNER! %s KIRIM BOLA" % str(cp.get("name", "PEMAIN")), "KIRIM UMPAN KORNER MELENGKUNG", cp, {}, is_us)
	elif r < 0.60 and tot_y < 3 and (_minute - _last_card_min) >= 16.0:
		_last_card_min = _minute
		_trigger_match_card(is_us, false)
	elif r < 0.615 and tot_r < 1 and _minute >= 24.0 and (_minute - _last_card_min) >= 22.0:
		_last_card_min = _minute
		_trigger_match_card(is_us, true)
	elif r < 0.64 and _total_injuries_match < 1 and _active_injuries.is_empty() and _minute >= 18.0 and _minute <= 78.0 and (_minute - _last_injury_min) >= 25.0:
		_total_injuries_match += 1
		_last_injury_min = _minute
		_trigger_match_injury(is_us)
	else:
		# Small tactical commentary highlight in the feed below without displacing Big Hero Banner (Gambar 6!)
		var small_lines := [
			["INFO", "BLOK TENGAH, PRESSING HANYA SAAT PERLU"],
			["FOUL", "FOUL DI LINI TENGAH"],
			["INFO", "DUEL SEIMBANG, TAK ADA YANG MAU KALAH"],
			["INFO", "IRAMA TURUN, LAGA MULAI TEMPO SEDANG"],
			["INFO", "DUA ORANG KE BOLA, TAK ADA JALAN KELUAR"],
		]
		var pick: Array = small_lines[randi() % small_lines.size()]
		if str(pick[0]) == "FOUL":
			if is_us:
				_fouls_us += 1
			else:
				_fouls_them += 1
			_refresh_stats_tab()
		_append_small_feed_row(m_now, str(pick[0]), str(pick[1]), Color("#DCE8F8"), is_us, false)

func _draw_board_timeline() -> void:
	if _board_timeline == null:
		return
	var s := _board_timeline.size
	var y_mid := s.y * 0.50
	var max_m: float = 120.0 if _in_extra_time else 90.0
	_board_timeline.draw_line(Vector2(10, y_mid), Vector2(s.x - 10, y_mid), Color("#64748B", 0.55), 1.5)
	_board_timeline.draw_line(Vector2(10, 6), Vector2(26, 6), Color("#EF4444"), 2.0)
	_board_timeline.draw_line(Vector2(10, s.y - 6), Vector2(26, s.y - 6), Color("#38BDF8"), 2.0)
	var half_x := lerpf(10.0, s.x - 10.0, 45.0 / max_m)
	_board_timeline.draw_line(Vector2(half_x, 8), Vector2(half_x, s.y - 12), Color("#94A3B8", 0.45), 1.0)
	if _in_extra_time:
		var x90 := lerpf(10.0, s.x - 10.0, 90.0 / max_m)
		_board_timeline.draw_line(Vector2(x90, 8), Vector2(x90, s.y - 12), Color("#94A3B8", 0.45), 1.0)

	var font := UITheme.get_ui_font()
	if font != null:
		_board_timeline.draw_string(font, Vector2(8, s.y - 2), "0", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("#94A3B8"))
		_board_timeline.draw_string(font, Vector2(half_x - 6, s.y - 2), "45", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("#94A3B8"))
		_board_timeline.draw_string(font, Vector2(s.x - 24, s.y - 2), "120" if _in_extra_time else "90", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("#94A3B8"))

	for ev in _board_events:
		var x := lerpf(10.0, s.x - 10.0, clampf(float(ev["min"]) / max_m, 0.0, 1.0))
		var is_u := bool(ev["us"])
		var k: String = str(ev["kind"])
		var bar_h := 22.0 if k.contains("GOAL") else (14.0 if k == "SAVE" else 10.0)
		var bar_col := Color("#EF4444") if is_u else Color("#38BDF8")
		var y1 := y_mid - bar_h if is_u else y_mid + bar_h
		_board_timeline.draw_line(Vector2(x, y_mid), Vector2(x, y1), bar_col, 4.0)
		if k.contains("GOAL"):
			_board_timeline.draw_circle(Vector2(x, y1 + (-4.0 if is_u else 4.0)), 3.5, Color("#F8FAFC"))
		elif k == "YELLOW_CARD":
			_board_timeline.draw_rect(Rect2(x - 2, s.y - 14, 5, 7), Color("#FACC15"))
		elif k == "RED_CARD":
			_board_timeline.draw_rect(Rect2(x - 2, s.y - 14, 5, 7), Color("#EF4444"))

func _sync_board_hud() -> void:
	if _board_panel == null or not CareerState.has_active_career:
		return
	var club := CareerState.get_current_club()
	var fix := CareerState.get_current_fixture()
	var eng: int = clampi(int(round(_user_match_energy)), 0, 100)
	_board_min_lbl.text = "%d'" % mini(int(_et_end_min), int(_minute))
	if _board_home_score != null:
		_board_home_score.text = str(_score_us)
	if _board_away_score != null:
		_board_away_score.text = str(_score_them)
	_board_score_lbl.text = "%s %d - %d %s" % [club["code"], _score_us, _score_them, fix["opp_code"]]
	var poss: int = clampi(50 + int(club["ovr"]) - int(fix["opp_ovr"]), 34, 68)
	_board_poss_lbl.text = "%s %d%%" % [str(club["name"]).to_upper(), poss]
	var p_bg := _board_poss_bar.get_parent() as Control
	var p_w: float = p_bg.size.x if (p_bg != null and p_bg.size.x > 20.0) else 360.0
	_board_poss_bar.size.x = p_w * (float(poss) / 100.0)
	_board_rating_lbl.text = ("RATING\n%.1f" % _rating).replace(".", ",")
	if _board_rating_hist.is_empty() or absf(_board_rating_hist[_board_rating_hist.size() - 1] - _rating) >= 0.05:
		_board_rating_hist.append(_rating)
		if _board_rating_hist.size() > 14:
			_board_rating_hist.remove_at(0)
	if _board_sparkline != null:
		_board_sparkline.queue_redraw()
	_board_energy_lbl.text = "%d%%" % eng
	var e_bg := _board_energy_bar.get_parent() as Control
	var e_w: float = e_bg.size.x if (e_bg != null and e_bg.size.x > 20.0) else 360.0
	_board_energy_bar.size.x = e_w * (float(eng) / 100.0)
	_board_energy_bar.color = UITheme.ACCENT_RED if eng <= 25 else (UITheme.ACCENT_GOLD if eng < 45 else UITheme.ACCENT_GREEN)
	_board_energy_lbl.add_theme_color_override("font_color", _board_energy_bar.color)
	_update_board_cards_banner()
	_refresh_stats_tab()
	if _board_view_idx == 1:
		_refresh_squad_tab()

func _open_halftime_locker() -> void:
	_phase = MatchPhase.HALFTIME
	_board_hold_fast = false
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
	if _player_card_panel != null:
		_player_card_panel.visible = false
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
	bg.anchor_bottom = 0.30
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_halftime_panel.add_child(bg)

	var trim_line := ColorRect.new()
	trim_line.color = UITheme.ACCENT_RED
	trim_line.anchor_left = 0.0
	trim_line.anchor_right = 1.0
	trim_line.anchor_top = 0.30
	trim_line.anchor_bottom = 0.30
	trim_line.offset_bottom = 3
	_halftime_panel.add_child(trim_line)

	var card := PanelContainer.new()
	card.anchor_left = 0.16
	card.anchor_right = 0.84
	card.anchor_top = 0.56
	card.anchor_bottom = 0.56
	card.offset_top = -178
	card.offset_bottom = 178
	card.add_theme_stylebox_override("panel", UITheme.make_box(Color("#150C12", 0.96), UITheme.ACCENT_GOLD, 2, 10))
	_halftime_panel.add_child(card)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	card.add_child(vb)

	var st_str: String = "UNGGUL" if _score_us > _score_them else ("TERTINGGAL" if _score_us < _score_them else "SKOR SERI")
	var ttl := Label.new()
	ttl.text = "HALFTIME: %d - %d (%s)" % [_score_us, _score_them, st_str]
	ttl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ttl.add_theme_font_override("font", UITheme.get_display_font())
	ttl.add_theme_font_size_override("font_size", 18)
	vb.add_child(ttl)

	var eng: int = clampi(int(round(_user_match_energy)), 0, 100)
	var info := Label.new()
	info.text = "RATING: %.1f  •  ENERGI: %d%%" % [_rating, eng]
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(info)

	# KUIS RUANG GANTI (+4 ENERGI SAAT PELUIT AKHIR)
	var quiz_box := PanelContainer.new()
	quiz_box.add_theme_stylebox_override("panel", UITheme.make_box(Color("#0D1C32"), UITheme.ACCENT_CYAN, 1, 6))
	vb.add_child(quiz_box)
	var qvb := VBoxContainer.new()
	qvb.add_theme_constant_override("separation", 5)
	quiz_box.add_child(qvb)

	var q_hdr := Label.new()
	q_hdr.text = "★ KUIS RUANG GANTI  •  BENAR = +4 ENERGI SAAT PELUIT AKHIR"
	q_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	q_hdr.add_theme_font_size_override("font_size", 11)
	q_hdr.add_theme_color_override("font_color", UITheme.ACCENT_CYAN)
	qvb.add_child(q_hdr)

	var tm_sample: Dictionary = _our_lineup[randi_range(0, maxi(0, _our_lineup.size() - 1))] if not _our_lineup.is_empty() else {"name": "KAPLAN", "num": 10, "pos": "CM"}
	for p_item in _our_lineup:
		if not bool(p_item.get("is_user", false)):
			tm_sample = p_item
			break
	var ans_num: int = int(tm_sample.get("num", 10))
	var q_txt := Label.new()
	q_txt.text = "Berapa nomor punggung rekan setimmu, %s (%s)?" % [str(tm_sample.get("name", "REKAN")), str(tm_sample.get("pos", "CM"))]
	q_txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	q_txt.add_theme_font_size_override("font_size", 12)
	qvb.add_child(q_txt)

	var opts_nums: Array[int] = [ans_num, (ans_num + 3) % 30 + 1, (ans_num + 7) % 30 + 1]
	opts_nums.shuffle()
	var q_hb := HBoxContainer.new()
	q_hb.add_theme_constant_override("separation", 6)
	qvb.add_child(q_hb)
	var q_btns: Array[Button] = []
	for opt_n in opts_nums:
		var qb := Button.new()
		qb.text = "#%d" % opt_n
		qb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		qb.custom_minimum_size = Vector2(0, 34)
		UITheme.style_btn(qb, Color("#132C4E"), UITheme.BORDER_CYAN, 13)
		var picked_n := opt_n
		qb.pressed.connect(func():
			for ob in q_btns:
				ob.disabled = true
			if picked_n == ans_num:
				_quiz_bonus_energy = true
				AudioSynth.play_achievement()
				q_hdr.text = "✓ BENAR! +4 ENERGI AKAN DITERIMA SAAT PELUIT AKHIR"
				q_hdr.add_theme_color_override("font_color", UITheme.ACCENT_GREEN)
				UITheme.style_btn(qb, Color("#14532D"), UITheme.ACCENT_GREEN, 13)
			else:
				q_hdr.text = "X KURANG TEPAT! JAWABANNYA #%d" % ans_num
				q_hdr.add_theme_color_override("font_color", UITheme.ACCENT_RED)
				UITheme.style_btn(qb, Color("#7F1D1D"), UITheme.ACCENT_RED, 13)
		)
		q_hb.add_child(qb)
		q_btns.append(qb)

	var drink_b := Button.new()
	drink_b.text = "BELI MINUMAN ENERGI (+28%) • $13.500"
	drink_b.custom_minimum_size = Vector2(0, 38)
	UITheme.style_btn(drink_b, Color("#401A20"), UITheme.ACCENT_GOLD, 12)
	drink_b.pressed.connect(func():
		if CareerState.buy_emergency_drink(13500):
			_user_match_energy = minf(100.0, _user_match_energy + 28.0)
			info.text = "RATING: %.1f  •  ENERGI: %d%% (PULIH!)" % [_rating, int(round(_user_match_energy))]
			AudioSynth.play_achievement()
			drink_b.text = "ENERGI PULIH! SIAP TAMPIL"
			drink_b.disabled = true
	)
	vb.add_child(drink_b)

	var go2 := Button.new()
	go2.text = "BABAK KEDUA"
	go2.custom_minimum_size = Vector2(0, 44)
	UITheme.style_btn(go2, Color("#0E1D30"), UITheme.ACCENT_CYAN, 17)
	go2.pressed.connect(func():
		AudioSynth.play_whistle(false)
		_halftime_panel.visible = false
		_phase = MatchPhase.SIMULATING
		if _board_panel != null:
			_board_panel.visible = true
	)
	vb.add_child(go2)
	_halftime_panel.visible = true

func _open_pitch_invader_popup() -> void:
	_board_paused = true
	_board_hold_fast = false
	for c in _invader_panel.get_children():
		c.queue_free()
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.04, 0.08, 0.80)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_invader_panel.add_child(dim)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	_invader_panel.add_child(cc)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(520, 0)
	card.add_theme_stylebox_override("panel", UITheme.make_box(Color("#123524"), UITheme.ACCENT_GOLD, 2, 10))
	cc.add_child(card)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	card.add_child(vb)
	var hdr := Label.new()
	hdr.text = "▲ PENYUSUP MASUK LAPANGAN! (%d')" % int(_minute)
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr.add_theme_font_override("font", UITheme.get_display_font())
	hdr.add_theme_font_size_override("font_size", 18)
	hdr.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	vb.add_child(hdr)
	var av := PixelAvatar.new()
	av.custom_minimum_size = Vector2(96, 110)
	av.configure_from_career()
	av.anim_mode = "CELEBRATE"
	var chb := HBoxContainer.new()
	chb.alignment = BoxContainer.ALIGNMENT_CENTER
	chb.add_child(av)
	vb.add_child(chb)
	var desc := Label.new()
	desc.text = "Seorang suporter nekat melompati papan iklan mengenakan jerseymu! Petugas keamanan mengejarnya sebelum laga berlanjut."
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(desc)
	var btn := Button.new()
	btn.text = "KETUK UNTUK LANJUT"
	btn.custom_minimum_size = Vector2(0, 44)
	UITheme.style_btn(btn, Color("#173B66"), UITheme.ACCENT_CYAN, 15)
	btn.pressed.connect(func():
		AudioSynth.play_click()
		CareerState.apply_cutscene_effects({"fans": 2})
		_invader_panel.visible = false
		_board_paused = false
		_add_rich_board_highlight(int(_minute), "INFO", "PENYUSUP DIAMANKAN", "Suporter nekat berlari pakai jerseymu! (+2 Fans)", _get_user_roster_dict(), {}, true)
	)
	vb.add_child(btn)
	_invader_panel.visible = true

func _open_coin_flip_phase() -> void:
	_phase = MatchPhase.COIN_FLIP
	_board_hold_fast = false
	_coin_spinning = false
	_coin_anim_t = 0.0
	if _board_panel != null:
		_board_panel.visible = false
	for c in _coin_flip_panel.get_children():
		c.queue_free()

	var dim := ColorRect.new()
	dim.color = Color("#081B12", 0.94)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_coin_flip_panel.add_child(dim)

	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	_coin_flip_panel.add_child(cc)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(540, 0)
	card.add_theme_stylebox_override("panel", UITheme.make_box(Color("#12261C"), UITheme.ACCENT_GOLD, 2, 12))
	cc.add_child(card)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	card.add_child(vb)

	var ttl := Label.new()
	ttl.text = "UNDIAN KOIN ADU PENALTI (120': %d - %d)" % [_score_us, _score_them]
	ttl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ttl.add_theme_font_override("font", UITheme.get_display_font())
	ttl.add_theme_font_size_override("font_size", 18)
	ttl.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	vb.add_child(ttl)

	_coin_canvas = Control.new()
	_coin_canvas.custom_minimum_size = Vector2(0, 140)
	_coin_canvas.draw.connect(_draw_pixel_coin)
	vb.add_child(_coin_canvas)

	_coin_status_lbl = Label.new()
	_coin_status_lbl.text = "PILIH SISI KOIN! Pemenang undian menentukan penendang pertama."
	_coin_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_coin_status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_coin_status_lbl.add_theme_font_override("font", UITheme.get_display_font())
	_coin_status_lbl.add_theme_font_size_override("font_size", 14)
	vb.add_child(_coin_status_lbl)

	var btn_hb := HBoxContainer.new()
	btn_hb.add_theme_constant_override("separation", 12)
	vb.add_child(btn_hb)
	_coin_choice_btns.clear()
	for side_txt in ["ANGKA", "GAMBAR"]:
		var b := Button.new()
		b.text = "●  " + side_txt
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 48)
		UITheme.style_btn(b, Color("#5A4212"), UITheme.ACCENT_GOLD, 16)
		var cap_s: String = str(side_txt)
		b.pressed.connect(func(): _start_coin_spin(cap_s))
		btn_hb.add_child(b)
		_coin_choice_btns.append(b)

	_coin_go_btn = Button.new()
	_coin_go_btn.text = "LANJUT ADU PENALTI"
	_coin_go_btn.visible = false
	_coin_go_btn.custom_minimum_size = Vector2(0, 46)
	UITheme.style_btn(_coin_go_btn, Color("#153B6E"), UITheme.ACCENT_CYAN, 16)
	_coin_go_btn.pressed.connect(func():
		AudioSynth.play_click()
		_coin_flip_panel.visible = false
		_open_penalty_shootout()
	)
	vb.add_child(_coin_go_btn)
	_coin_flip_panel.visible = true

func _start_coin_spin(choice: String) -> void:
	AudioSynth.play_click()
	_coin_choice = choice
	_coin_result = "GAMBAR" if randf() < 0.5 else "ANGKA"
	_coin_winner_us = (_coin_choice == _coin_result)
	_coin_anim_t = 0.0
	_coin_spinning = true
	_coin_status_lbl.text = "MELEMPAR KOIN..."
	for b in _coin_choice_btns:
		b.disabled = true

func _draw_pixel_coin() -> void:
	if _coin_canvas == null:
		return
	var c := _coin_canvas.size * 0.5
	var spin_w := absf(cos(_coin_anim_t * 14.0)) if _coin_spinning else 1.0
	var rad_x := maxf(8.0, 52.0 * spin_w)
	var rad_y := 52.0
	_coin_canvas.draw_rect(Rect2(c.x - rad_x, c.y - rad_y, rad_x * 2.0, rad_y * 2.0), Color("#D97706"))
	_coin_canvas.draw_rect(Rect2(c.x - rad_x * 0.85, c.y - rad_y * 0.85, rad_x * 1.7, rad_y * 1.7), Color("#FACC15"))
	if not _coin_spinning or spin_w > 0.45:
		var lbl := _coin_result if not _coin_spinning else ("GAMBAR" if int(_coin_anim_t * 10.0) % 2 == 0 else "ANGKA")
		var font := UITheme.get_ui_font()
		if font != null:
			_coin_canvas.draw_string(font, c + Vector2(-28, 6), lbl, HORIZONTAL_ALIGNMENT_CENTER, 56, 13, Color("#78350F"))

func _finish_coin_spin() -> void:
	_coin_spinning = false
	_coin_canvas.queue_redraw()
	_pso_user_first = _coin_winner_us
	if _coin_winner_us:
		AudioSynth.play_achievement()
	else:
		AudioSynth.play_click()
	var order_note := "TIMMU MENENDANG PERTAMA!" if _pso_user_first else "LAWAN MENENDANG PERTAMA!"
	_coin_status_lbl.text = "KOIN MENUNJUKKAN %s.\n%s" % [_coin_result, order_note]
	_coin_status_lbl.add_theme_color_override("font_color", UITheme.ACCENT_GREEN if _coin_winner_us else UITheme.ACCENT_GOLD)
	_coin_go_btn.visible = true

func _open_penalty_shootout() -> void:
	_phase = MatchPhase.PENALTY_SHOOTOUT
	_pso_us_kicks.clear()
	_pso_them_kicks.clear()
	_pso_round = 1
	_pso_turn_us = _pso_user_first
	_pso_waiting_kick = true
	for c in _pso_panel.get_children():
		c.queue_free()

	var dim := ColorRect.new()
	dim.color = Color("#081424", 0.95)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pso_panel.add_child(dim)

	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pso_panel.add_child(cc)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(600, 0)
	card.add_theme_stylebox_override("panel", UITheme.make_box(Color("#0D1E38"), UITheme.ACCENT_GOLD, 2, 12))
	cc.add_child(card)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	card.add_child(vb)

	var hdr := Label.new()
	hdr.text = "● ADU PENALTI (8 BESAR / GUGUR)"
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr.add_theme_font_override("font", UITheme.get_display_font())
	hdr.add_theme_font_size_override("font_size", 18)
	hdr.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	vb.add_child(hdr)

	_pso_score_lbl = Label.new()
	_pso_score_lbl.text = "PENALTI: 0 - 0"
	_pso_score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pso_score_lbl.add_theme_font_override("font", UITheme.get_display_font())
	_pso_score_lbl.add_theme_font_size_override("font_size", 24)
	vb.add_child(_pso_score_lbl)

	_pso_row_us = HBoxContainer.new()
	_pso_row_us.alignment = BoxContainer.ALIGNMENT_CENTER
	_pso_row_us.add_theme_constant_override("separation", 6)
	vb.add_child(_pso_row_us)

	_pso_row_them = HBoxContainer.new()
	_pso_row_them.alignment = BoxContainer.ALIGNMENT_CENTER
	_pso_row_them.add_theme_constant_override("separation", 6)
	vb.add_child(_pso_row_them)

	_pso_status_lbl = Label.new()
	_pso_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pso_status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_pso_status_lbl.add_theme_font_size_override("font_size", 14)
	vb.add_child(_pso_status_lbl)

	_pso_btn_row = HBoxContainer.new()
	_pso_btn_row.add_theme_constant_override("separation", 8)
	vb.add_child(_pso_btn_row)

	_pso_done_btn = Button.new()
	_pso_done_btn.text = "SELESAI & LIHAT HASIL"
	_pso_done_btn.visible = false
	_pso_done_btn.custom_minimum_size = Vector2(0, 44)
	UITheme.style_btn(_pso_done_btn, UITheme.ACCENT_AMBER, UITheme.ACCENT_GOLD, 16)
	_pso_done_btn.pressed.connect(func():
		AudioSynth.play_click()
		_pso_panel.visible = false
		_finish_career_match()
	)
	vb.add_child(_pso_done_btn)

	_pso_panel.visible = true
	_render_pso_board()

func _pso_goals(arr: Array[String]) -> int:
	var cnt := 0
	for k in arr:
		if k == "✓":
			cnt += 1
	return cnt

func _render_pso_board() -> void:
	var g_us := _pso_goals(_pso_us_kicks)
	var g_them := _pso_goals(_pso_them_kicks)
	var club := CareerState.get_current_club()
	var fix := CareerState.get_current_fixture()
	_pso_score_lbl.text = "%s %d - %d %s" % [club["code"], g_us, g_them, fix["opp_code"]]

	for r in [_pso_row_us, _pso_row_them]:
		for ch in r.get_children():
			ch.queue_free()
	var slots := maxi(5, maxi(_pso_us_kicks.size(), _pso_them_kicks.size()))
	for r_pair in [[club["code"], _pso_us_kicks, _pso_row_us], [fix["opp_code"], _pso_them_kicks, _pso_row_them]]:
		var nm := Label.new()
		nm.text = str(r_pair[0])
		nm.custom_minimum_size = Vector2(48, 0)
		nm.add_theme_font_override("font", UITheme.get_display_font())
		r_pair[2].add_child(nm)
		var arr: Array = r_pair[1]
		for i in range(slots):
			var mark: String = arr[i] if i < arr.size() else "•"
			var ml := Label.new()
			ml.text = mark
			ml.custom_minimum_size = Vector2(28, 28)
			ml.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			ml.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			ml.add_theme_font_override("font", UITheme.get_display_font())
			ml.add_theme_color_override("font_color", UITheme.ACCENT_GREEN if mark == "✓" else (UITheme.ACCENT_RED if mark == "X" else UITheme.TEXT_MUTED))
			r_pair[2].add_child(ml)

	for ch in _pso_btn_row.get_children():
		ch.queue_free()

	# Check completion condition
	var k_u := _pso_us_kicks.size()
	var k_t := _pso_them_kicks.size()
	var finished := false
	if k_u <= 5 and k_t <= 5:
		var rem_u := 5 - k_u
		var rem_t := 5 - k_t
		if g_us > g_them + rem_t or g_them > g_us + rem_u:
			finished = true
		elif k_u == 5 and k_t == 5 and g_us != g_them:
			finished = true
	elif k_u == k_t and g_us != g_them:
		finished = true

	if finished:
		_pen_us = g_us
		_pen_them = g_them
		var won := g_us > g_them
		_pso_status_lbl.text = "MENANG ADU PENALTI! (%d - %d)" % [g_us, g_them] if won else "KALAH ADU PENALTI (%d - %d)" % [g_us, g_them]
		_pso_status_lbl.add_theme_color_override("font_color", UITheme.ACCENT_GREEN if won else UITheme.ACCENT_RED)
		_pso_done_btn.visible = true
		return

	if _pso_turn_us:
		var is_user_kick := (k_u == 0 and not _user_subbed_out)
		var kicker_name: String = CareerState.career["playerProfile"]["name"] if is_user_kick else "REKAN TIM"
		_pso_status_lbl.text = "GILIRAN %s (#%d) — PILIH ARAH TEMBAKAN!" % [kicker_name, k_u + 1]
		for dir_i in range(3):
			var dirs := ["← KIRI", "▲ TENGAH", "→ KANAN"]
			var kb := Button.new()
			kb.text = dirs[dir_i]
			kb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			kb.custom_minimum_size = Vector2(0, 44)
			UITheme.style_btn(kb, Color("#153B6E"), UITheme.ACCENT_CYAN, 13)
			var cap_d := dir_i
			var cap_uk := is_user_kick
			kb.pressed.connect(func(): _pso_take_kick(cap_d, cap_uk))
			_pso_btn_row.add_child(kb)
	else:
		_pso_status_lbl.text = "GILIRAN LAWAN (#%d) — PILIH ARAH TEBAKAN KIPER!" % (k_t + 1)
		for dir_i in range(3):
			var dirs := ["← LOMPAT KIRI", "▲ DIAM TENGAH", "→ LOMPAT KANAN"]
			var kb := Button.new()
			kb.text = dirs[dir_i]
			kb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			kb.custom_minimum_size = Vector2(0, 44)
			UITheme.style_btn(kb, Color("#3B1C24"), UITheme.ACCENT_GOLD, 13)
			var cap_d := dir_i
			kb.pressed.connect(func(): _pso_keeper_dive(cap_d))
			_pso_btn_row.add_child(kb)

func _pso_take_kick(dir_idx: int, is_user_kick: bool) -> void:
	var gk_dir := randi_range(0, 2)
	var pen_attr := CareerState.get_effective_attribute("penalti") if is_user_kick else 70
	var conv_chance := clampf(0.55 + float(pen_attr) * 0.0038, 0.58, 0.94)
	var scored := (dir_idx != gk_dir) or (randf() < conv_chance * 0.65)
	if is_user_kick and scored:
		_penalties_scored += 1
		_adjust_rating(0.4, "Penalti Adu Tos!")
	_pso_us_kicks.append("✓" if scored else "X")
	if scored:
		AudioSynth.play_goal()
	else:
		AudioSynth.play_save()
	_pso_turn_us = false
	_render_pso_board()

func _pso_keeper_dive(dive_idx: int) -> void:
	var opp_dir := randi_range(0, 2)
	var saved := (dive_idx == opp_dir and randf() < 0.55) or randf() < 0.14
	_pso_them_kicks.append("X" if saved else "✓")
	if saved:
		AudioSynth.play_save()
	else:
		AudioSynth.play_whistle(false)
	_pso_turn_us = true
	_render_pso_board()

func _execute_set_piece_outcome(user_takes: bool) -> void:
	if user_takes:
		if _pending_ask_type == MomentType.CORNER_KICK:
			setup_corner_variant(true)
		else:
			_trigger_key_moment(_pending_ask_type)
	else:
		if _pending_ask_type == MomentType.PENALTY:
			_trigger_key_moment(MomentType.TEAMMATE_PENALTY)
		elif _pending_ask_type == MomentType.CORNER_KICK:
			setup_corner_variant(false)
		else:
			_phase = MatchPhase.SIMULATING
			if _board_panel != null:
				_board_panel.visible = true

func _open_ask_set_piece(m_type: MomentType, teammate_asks: bool = false) -> void:
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
	card.offset_left = 120
	card.offset_right = -120
	card.offset_top = -175
	card.offset_bottom = -18
	card.add_theme_stylebox_override("panel", UITheme.make_box(Color("#121A26", 0.96), UITheme.ACCENT_GOLD, 2, 10))
	_ask_panel.add_child(card)

	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", 14)
	m.add_theme_constant_override("margin_right", 14)
	m.add_theme_constant_override("margin_top", 10)
	m.add_theme_constant_override("margin_bottom", 10)
	card.add_child(m)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	m.add_child(vb)

	var stat_key: String = "penalti" if m_type == MomentType.PENALTY else "bolaMati"
	var stat_name: String = "PENALTI" if m_type == MomentType.PENALTY else "BOLA MATI"
	var attr_val: int = CareerState.get_effective_attribute(stat_key)
	var chance_pct: int = clampi(int(round(20.0 + float(attr_val) * 0.72)), 20, 95)
	var sp_lbl: String = "PENALTI" if m_type == MomentType.PENALTY else ("TENDANGAN SUDUT" if m_type == MomentType.CORNER_KICK else "TENDANGAN BEBAS")

	var h := Label.new()
	h.text = ("REKAN MEMINTA BOLA %s — BERIKAN?" % sp_lbl) if teammate_asks else ("%s MILIK REKAN SETIM — MINTA BOLA?" % sp_lbl)
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	vb.add_child(h)

	var sub_l := Label.new()
	sub_l.text = ("Kepercayaan bertahan (%s %d): %d%%" % [stat_name, attr_val, chance_pct]) if teammate_asks else ("Peluang disetujui (%s %d): %d%%" % [stat_name, attr_val, chance_pct])
	sub_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_l.add_theme_color_override("font_color", UITheme.ACCENT_CYAN)
	sub_l.add_theme_font_size_override("font_size", 12)
	vb.add_child(sub_l)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	vb.add_child(hb)

	var b_yes := Button.new()
	b_yes.text = "YA" if teammate_asks else ("YA (%d%%)" % chance_pct)
	b_yes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_yes.custom_minimum_size = Vector2(0, 44)
	UITheme.style_btn(b_yes, Color("#17462E"), UITheme.ACCENT_GREEN, 13)
	b_yes.pressed.connect(func():
		AudioSynth.play_click()
		_ask_panel.visible = false
		if teammate_asks:
			if CareerState.career.has("playerProfile") and CareerState.career["playerProfile"].has("relations"):
				var cur_rg := int(CareerState.career["playerProfile"]["relations"].get("ruangGanti", 50))
				CareerState.career["playerProfile"]["relations"]["ruangGanti"] = clampi(cur_rg + 1, 0, 100)
			_add_board_event(int(_minute), "INFO", "%d' Kamu memberikan %s kepada rekan setim (+1 Ruang Ganti)." % [int(_minute), sp_lbl], true)
			_execute_set_piece_outcome(false)
		else:
			if randi_range(1, 100) <= chance_pct:
				_add_board_event(int(_minute), "INFO", "%d' Rekan menyetujui! Kamu mengeksekusi %s." % [int(_minute), sp_lbl], true)
				_execute_set_piece_outcome(true)
			else:
				var rej_msg := "%d' Rekan menolak — siap bola rebound!" % int(_minute) if _pending_ask_type == MomentType.PENALTY else "%d' Rekan menolak dan eksekusi sendiri." % int(_minute)
				_add_board_event(int(_minute), "INFO", rej_msg, false)
				_execute_set_piece_outcome(false)
	)
	hb.add_child(b_yes)

	var b_no := Button.new()
	b_no.text = ("TIDAK (%d%%)" % chance_pct) if teammate_asks else "TIDAK"
	b_no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b_no.custom_minimum_size = Vector2(0, 44)
	UITheme.style_btn(b_no, Color("#4E2424"), UITheme.ACCENT_RED, 13)
	b_no.pressed.connect(func():
		AudioSynth.play_click()
		_ask_panel.visible = false
		if teammate_asks:
			if randi_range(1, 100) <= chance_pct:
				_add_board_event(int(_minute), "INFO", "%d' Rekan mengalah — kamu tetap ambil %s!" % [int(_minute), sp_lbl], true)
				_execute_set_piece_outcome(true)
			else:
				_add_board_event(int(_minute), "INFO", "%d' Kapten menyerahkan %s kepada rekan." % [int(_minute), sp_lbl], false)
				_execute_set_piece_outcome(false)
		else:
			_add_board_event(int(_minute), "INFO", "%d' Kamu membiarkan rekan mengambil %s." % [int(_minute), sp_lbl], true)
			_execute_set_piece_outcome(false)
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

func _get_match_comp_theme() -> Dictionary:
	if run_mode != RunMode.CAREER_MATCH or not CareerState.has_active_career:
		return MatchHudWidgets.get_comp_theme("LIGA", "LATIHAN")
	var fix: Dictionary = CareerState.get_current_fixture()
	return MatchHudWidgets.get_comp_theme(str(fix.get("comp", "LIGA")), str(fix.get("comp_label", "")))

func _get_half_minute_str() -> String:
	var m_i: int = mini(int(_et_end_min), maxi(1, int(_minute)))
	var half_s: String = "ET" if m_i > 90 else ("B2" if m_i > 45 else "B1")
	return "%s %d'" % [half_s, m_i]

func _sync_broadcast_scorebug() -> void:
	if _score_lbl == null or _minute_lbl == null:
		return
	var th: Dictionary = _get_match_comp_theme()
	var acc: Color = th.get("accent", Color("#3878A8"))
	var acc_hi: Color = th.get("accent_hi", Color("#7DD3FC"))
	var pill_bg: Color = th.get("pill_bg", Color("#265B84"))
	var bar_bg: Color = th.get("bar_bg", Color("#193047"))

	if _sb_comp_ring != null:
		_sb_comp_ring.set_theme_info(th)
	if _sb_rating_ring != null:
		_sb_rating_ring.set_rating(_rating, acc_hi)

	if run_mode == RunMode.CAREER_MATCH and CareerState.has_active_career:
		var club: Dictionary = CareerState.get_current_club()
		var fix: Dictionary = CareerState.get_current_fixture()
		var is_home: bool = bool(fix.get("is_home", true))
		var our_cid: int = int(club.get("id", 0))
		var opp_cid: int = clampi(int(fix.get("opp_club_id", 1)), 0, maxi(0, GameData.clubs.size() - 1))
		var our_code: String = str(club.get("code", "KLB")).left(3).to_upper()
		var opp_code: String = str(fix.get("opp_code", "LWN")).left(3).to_upper()

		var left_cid: int = our_cid if is_home else opp_cid
		var right_cid: int = opp_cid if is_home else our_cid
		var left_code: String = our_code if is_home else opp_code
		var right_code: String = opp_code if is_home else our_code
		var left_sc: int = _score_us if is_home else _score_them
		var right_sc: int = _score_them if is_home else _score_us

		if _sb_home_crest != null:
			_sb_home_crest.set_club(left_cid)
		if _sb_away_crest != null:
			_sb_away_crest.set_club(right_cid)
		if _sb_home_code_lbl != null:
			_sb_home_code_lbl.text = left_code
		if _sb_away_code_lbl != null:
			_sb_away_code_lbl.text = right_code
		_score_lbl.text = "%d - %d" % [left_sc, right_sc]
		_minute_lbl.text = _get_half_minute_str()

		if _sb_comp_ribbon_lbl != null:
			var wk_n: int = int(CareerState.career.get("careerMeta", {}).get("week", 1))
			var c_lbl: String = str(fix.get("comp_label", "LIGA")).to_upper()
			var stage_s: String = str(fix.get("stage", "")).to_upper()
			if not stage_s.is_empty() and not c_lbl.contains(stage_s):
				_sb_comp_ribbon_lbl.text = "%s  •  %s" % [c_lbl, stage_s]
			else:
				_sb_comp_ribbon_lbl.text = "%s  •  PEKAN %d" % [c_lbl, wk_n]

		if _sb_home_bar != null:
			var hs := StyleBoxFlat.new()
			hs.bg_color = Color(bar_bg.r, bar_bg.g, bar_bg.b, 0.95)
			hs.border_color = Color(acc_hi.r, acc_hi.g, acc_hi.b, 0.72)
			hs.border_width_top = 1
			hs.border_width_bottom = 1
			hs.content_margin_left = 8
			hs.content_margin_right = 8
			_sb_home_bar.add_theme_stylebox_override("panel", hs)
		if _sb_away_bar != null:
			var asb := StyleBoxFlat.new()
			asb.bg_color = Color(acc.r, acc.g, acc.b, 0.90)
			asb.border_color = Color(acc_hi.r, acc_hi.g, acc_hi.b, 0.72)
			asb.border_width_top = 1
			asb.border_width_bottom = 1
			asb.content_margin_left = 8
			asb.content_margin_right = 8
			_sb_away_bar.add_theme_stylebox_override("panel", asb)
		if _sb_min_panel != null:
			var ms := StyleBoxFlat.new()
			ms.bg_color = Color(bar_bg.r, bar_bg.g, bar_bg.b, 0.96)
			ms.border_color = Color(acc_hi.r, acc_hi.g, acc_hi.b, 0.78)
			ms.set_border_width_all(1)
			ms.set_corner_radius_all(3)
			ms.content_margin_left = 10
			ms.content_margin_right = 10
			ms.content_margin_top = 1
			ms.content_margin_bottom = 1
			_sb_min_panel.add_theme_stylebox_override("panel", ms)
		if _sb_comp_ribbon_panel != null:
			var rs := StyleBoxFlat.new()
			rs.bg_color = Color(pill_bg.r, pill_bg.g, pill_bg.b, 0.92)
			rs.set_corner_radius_all(2)
			rs.content_margin_left = 12
			rs.content_margin_right = 12
			rs.content_margin_top = 1
			rs.content_margin_bottom = 1
			_sb_comp_ribbon_panel.add_theme_stylebox_override("panel", rs)

func _get_controlled_player_info() -> Dictionary:
	var club: Dictionary = CareerState.get_current_club() if CareerState.has_active_career else GameData.clubs[0]
	if _controlling_teammate_idx >= 0:
		# Resolve real non-user outfield starter from _our_lineup (NEVER generic "REKAN #3"!)
		var outfield: Array[Dictionary] = []
		var defenders: Array[Dictionary] = []
		for p in _our_lineup:
			if bool(p.get("is_user", false)):
				continue
			var pos_s: String = str(p.get("pos", "CM")).to_upper()
			if pos_s == "GK":
				continue
			outfield.append(p)
			if pos_s in ["CB", "LB", "RB", "LWB", "RWB", "CDM"]:
				defenders.append(p)
		var picked: Dictionary = {}
		var is_backline_ctrl: bool = (_controlling_teammate_idx == 0 and _teammate_positions.size() > 0 and _teammate_positions[0].z > 10.0)
		if is_backline_ctrl and not defenders.is_empty():
			picked = defenders[0]
		elif not outfield.is_empty():
			picked = outfield[_controlling_teammate_idx % outfield.size()]
		if not picked.is_empty():
			var raw_n: String = str(picked.get("name", "SANTOSO")).strip_edges().to_upper()
			var parts: PackedStringArray = raw_n.split(" ")
			var disp_n: String = parts[parts.size() - 1] if parts.size() >= 2 else raw_n
			return {
				"name": disp_n.left(14),
				"full_name": raw_n,
				"num": int(picked.get("num", 4 + _controlling_teammate_idx)),
				"pos": str(picked.get("pos", "CM")).to_upper(),
				"seed": int(picked.get("seed", 101 + _controlling_teammate_idx * 19)),
				"is_user": false,
				"club": picked.get("club", club),
			}
		var fb_ln: String = str(GameData.LAST_NAMES[(_controlling_teammate_idx * 7 + int(club.get("id", 0))) % GameData.LAST_NAMES.size()]).to_upper()
		return {
			"name": fb_ln.left(14),
			"full_name": fb_ln,
			"num": 4 + _controlling_teammate_idx,
			"pos": "CB" if is_backline_ctrl else "CM",
			"seed": 31 + _controlling_teammate_idx * 17,
			"is_user": false,
			"club": club,
		}

	if CareerState.has_active_career:
		var prof: Dictionary = CareerState.career["playerProfile"]
		var u_nm: String = str(prof.get("name", "PEMAIN")).strip_edges().to_upper()
		var u_parts: PackedStringArray = u_nm.split(" ")
		var u_disp: String = u_parts[u_parts.size() - 1] if u_parts.size() >= 2 else u_nm
		return {
			"name": u_disp.left(14),
			"full_name": u_nm,
			"num": int(prof.get("appearance", {}).get("shirt_num", 9)),
			"pos": str(prof.get("favoritePosition", "ST")).to_upper(),
			"seed": 0,
			"is_user": true,
			"club": club,
		}
	return {"name": "PEMAIN", "full_name": "PEMAIN", "num": 9, "pos": "ST", "seed": 0, "is_user": true, "club": club}

func _apply_control_layout_settings() -> void:
	var left_handed: bool = bool(SettingsManager.data.get("left_handed", false))
	var joy_pct: int = clampi(int(SettingsManager.data.get("joy_size", 100)), 60, 140)
	var op_pct: int = clampi(int(SettingsManager.data.get("joy_opacity", 70)), 15, 100)
	var joy_sz: float = round(140.0 * float(joy_pct) / 100.0)
	var open_play: bool = (_phase == MatchPhase.KEY_MOMENT_AIM and run_mode != RunMode.MOVIOLA_REPLAY and (_moment_type in [MomentType.SHOT, MomentType.PASS, MomentType.DRIBBLE]))

	if _dribble_pad != null:
		_dribble_pad.modulate.a = clampf(float(op_pct) / 100.0, 0.15, 1.0)
		if left_handed:
			_dribble_pad.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
			_dribble_pad.offset_left = -18.0 - joy_sz
			_dribble_pad.offset_right = -18.0
		else:
			_dribble_pad.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
			_dribble_pad.offset_left = 18.0
			_dribble_pad.offset_right = 18.0 + joy_sz
		_dribble_pad.offset_top = -12.0 - joy_sz
		_dribble_pad.offset_bottom = -12.0
		_dribble_pad.queue_redraw()

	var card_bot: float = (-18.0 - joy_sz - 24.0) if open_play else -14.0
	var st_bot: float = (-18.0 - joy_sz) if open_play else -14.0
	if _stamina_bar_bg != null:
		if left_handed:
			_stamina_bar_bg.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
			_stamina_bar_bg.offset_left = -246.0
			_stamina_bar_bg.offset_right = -18.0
		else:
			_stamina_bar_bg.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
			_stamina_bar_bg.offset_left = 18.0
			_stamina_bar_bg.offset_right = 246.0
		_stamina_bar_bg.offset_top = st_bot - 18.0
		_stamina_bar_bg.offset_bottom = st_bot

	if _player_card_panel != null:
		if left_handed:
			_player_card_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
			_player_card_panel.offset_left = -246.0
			_player_card_panel.offset_right = -18.0
		else:
			_player_card_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
			_player_card_panel.offset_left = 18.0
			_player_card_panel.offset_right = 246.0
		_player_card_panel.offset_top = card_bot - 44.0
		_player_card_panel.offset_bottom = card_bot

	if _spin_pad != null:
		if left_handed:
			_spin_pad.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
			_spin_pad.offset_left = 16.0
			_spin_pad.offset_right = 114.0
		else:
			_spin_pad.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
			_spin_pad.offset_left = -114.0
			_spin_pad.offset_right = -16.0
		_spin_pad.offset_top = -134.0
		_spin_pad.offset_bottom = -20.0

	if _power_lbl != null:
		if left_handed:
			_power_lbl.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
			_power_lbl.offset_left = 16.0
			_power_lbl.offset_right = 180.0
			_power_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		else:
			_power_lbl.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
			_power_lbl.offset_left = -180.0
			_power_lbl.offset_right = -16.0
			_power_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_power_lbl.offset_top = -166.0
		_power_lbl.offset_bottom = -138.0

func _sync_action_bar() -> void:
	if _action_bar == null:
		return
	var open_play: bool = (_phase == MatchPhase.KEY_MOMENT_AIM and run_mode != RunMode.MOVIOLA_REPLAY and (_moment_type in [MomentType.SHOT, MomentType.PASS, MomentType.DRIBBLE]))
	var throw_in_move: bool = (_phase == MatchPhase.THROW_IN_PREP and run_mode != RunMode.MOVIOLA_REPLAY)
	_action_bar.visible = open_play
	if _dribble_pad != null:
		_dribble_pad.visible = (open_play or throw_in_move)
	if _stamina_bar_bg != null:
		_stamina_bar_bg.visible = (open_play or throw_in_move)
		if open_play or throw_in_move:
			_sync_stamina_hud()
	if _spin_pad != null:
		_spin_pad.visible = (_phase == MatchPhase.KEY_MOMENT_AIM and run_mode != RunMode.MOVIOLA_REPLAY and _moment_type != MomentType.TEAMMATE_PENALTY)
	if _power_lbl != null:
		_power_lbl.visible = (_phase == MatchPhase.KEY_MOMENT_AIM and run_mode != RunMode.MOVIOLA_REPLAY and _moment_type != MomentType.TEAMMATE_PENALTY)
	if open_play:
		_last_pass_state = ""
		_update_pass_openness_ui()

	_apply_control_layout_settings()
	_sync_broadcast_scorebug()

	var show_card: bool = ((_phase == MatchPhase.KEY_MOMENT_AIM or _phase == MatchPhase.THROW_IN_PREP) and run_mode != RunMode.MOVIOLA_REPLAY)
	if _player_card_panel != null:
		_player_card_panel.visible = show_card
	if show_card:
		var p_info: Dictionary = _get_controlled_player_info()
		var p_nm: String = str(p_info.get("name", "PEMAIN"))
		var p_num: int = int(p_info.get("num", 9))
		var p_pos: String = str(p_info.get("pos", "ST"))
		var is_u: bool = bool(p_info.get("is_user", true))
		if _player_badge_lbl != null:
			_player_badge_lbl.text = "#%d %s" % [p_num, p_nm]
		if _player_card_num_lbl != null:
			_player_card_num_lbl.text = str(p_num)
		if _player_card_name_lbl != null:
			_player_card_name_lbl.text = p_nm
			_player_card_name_lbl.add_theme_color_override("font_color", UITheme.ACCENT_GOLD if is_u else Color("#FFFFFF"))
		if _player_card_pos_lbl != null:
			_player_card_pos_lbl.text = "%s • %s" % [p_pos, "KAMU" if is_u else "REKAN TIM"]
			_player_card_pos_lbl.add_theme_color_override("font_color", Color("#FDE68A") if is_u else Color("#93C5FD"))
		var cache_k: String = "%s_%d_%d" % [p_nm, p_num, int(p_info.get("seed", 0))]
		if _player_card_avatar != null and cache_k != _player_card_last_key:
			_player_card_last_key = cache_k
			if is_u:
				_player_card_avatar.configure_from_career()
			else:
				_player_card_avatar.configure_from_seed(int(p_info.get("seed", 42)), p_info.get("club", CareerState.get_current_club()), p_num)
			_player_card_avatar.full_body = false
			_player_card_avatar.anim_mode = "NONE"
			_player_card_avatar.queue_redraw()
		if _player_card_strip != null:
			var th: Dictionary = _get_match_comp_theme()
			var b_bg: Color = th.get("bar_bg", Color("#132842"))
			var b_bd: Color = UITheme.ACCENT_GOLD if is_u else th.get("accent_hi", Color("#5BB2E8"))
			var ps_sb := StyleBoxFlat.new()
			ps_sb.bg_color = Color(b_bg.r, b_bg.g, b_bg.b, 0.92)
			ps_sb.border_color = Color(b_bd.r, b_bd.g, b_bd.b, 0.78)
			ps_sb.border_width_top = 1
			ps_sb.border_width_bottom = 1
			ps_sb.border_width_right = 1
			ps_sb.corner_radius_top_right = 6
			ps_sb.corner_radius_bottom_right = 6
			ps_sb.content_margin_left = 6
			ps_sb.content_margin_right = 8
			ps_sb.content_margin_top = 2
			ps_sb.content_margin_bottom = 2
			_player_card_strip.add_theme_stylebox_override("panel", ps_sb)

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

func _restart_current_match() -> void:
	_is_paused = false
	_dragging = false
	_goal_replay_active = false
	_celebrating_goal = false
	_stop_goal_celebration()
	if is_instance_valid(_pause_panel):
		_pause_panel.queue_free()
	_controlling_teammate_idx = -1
	_player_card_last_key = ""
	if _player_card_panel != null:
		_player_card_panel.visible = false
	if _moment_banner != null:
		_moment_banner.visible = false
	_start_selected_mode()

func _make_pause_bar_btn(label_txt: String, icon_kind: String, icon_col: Color, bg_col: Color, border_col: Color, bottom_bw: int = 2) -> Button:
	var btn := Button.new()
	btn.text = ""
	btn.custom_minimum_size = Vector2(0, 62)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var n := StyleBoxFlat.new()
	n.bg_color = bg_col
	n.border_color = border_col
	n.set_border_width_all(1)
	n.border_width_bottom = bottom_bw
	n.set_corner_radius_all(4)
	var h: StyleBoxFlat = n.duplicate()
	h.bg_color = bg_col.lightened(0.12)
	h.border_color = Color("#FFFFFF")
	var pr: StyleBoxFlat = n.duplicate()
	pr.bg_color = bg_col.darkened(0.10)
	btn.add_theme_stylebox_override("normal", n)
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_stylebox_override("pressed", pr)
	btn.add_theme_stylebox_override("focus", h)

	var mc := MarginContainer.new()
	mc.set_anchors_preset(Control.PRESET_FULL_RECT)
	mc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mc.add_theme_constant_override("margin_left", 16)
	mc.add_theme_constant_override("margin_right", 16)
	btn.add_child(mc)

	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mc.add_child(hb)

	var ico := MatchHudWidgets.PauseMenuIcon.new()
	ico.kind = icon_kind
	ico.col = icon_col
	ico.custom_minimum_size = Vector2(24, 24)
	hb.add_child(ico)

	var lbl := Label.new()
	lbl.text = label_txt
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_override("font", UITheme.get_display_font())
	lbl.add_theme_font_size_override("font_size", 16 if icon_kind == "PLAY" else 13)
	lbl.add_theme_color_override("font_color", Color("#FFFFFF"))
	hb.add_child(lbl)

	var r_pad := Control.new()
	r_pad.custom_minimum_size = Vector2(24, 24)
	r_pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(r_pad)
	return btn

func _open_pause_menu() -> void:
	if is_instance_valid(_pause_panel):
		_pause_panel.queue_free()
	_is_paused = true
	_dragging = false
	_pause_panel = Control.new()
	_pause_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_pause_panel)

	var th: Dictionary = _get_match_comp_theme()
	var pill_bg: Color = th.get("pill_bg", Color("#265B84"))
	var acc_hi: Color = th.get("accent_hi", Color("#7DD3FC"))
	var resume_bd: Color = th.get("resume_border", Color("#E11D48"))

	# Translucent broadcast glass backdrop so live pitch & scorebug subtly show through (Gambar 3!)
	var dim := ColorRect.new()
	dim.color = Color(0.015, 0.03, 0.06, 0.80)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_panel.add_child(dim)

	var main_wrap := Control.new()
	main_wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_panel.add_child(main_wrap)

	# 1. TOP HEADER BAR: Left = JEDA [B1 13'] | Right = [PBO 0-0 DSI] (Themed dynamically!)
	var hdr_hb := HBoxContainer.new()
	hdr_hb.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hdr_hb.offset_left = 36
	hdr_hb.offset_right = -36
	hdr_hb.offset_top = 18
	hdr_hb.offset_bottom = 62
	hdr_hb.add_theme_constant_override("separation", 14)
	main_wrap.add_child(hdr_hb)

	var jeda_lbl := Label.new()
	jeda_lbl.text = "JEDA"
	jeda_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	jeda_lbl.add_theme_font_override("font", UITheme.get_display_font())
	jeda_lbl.add_theme_font_size_override("font_size", 24)
	jeda_lbl.add_theme_color_override("font_color", Color("#FFFFFF"))
	hdr_hb.add_child(jeda_lbl)

	var min_pill := PanelContainer.new()
	min_pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var mp_sb := StyleBoxFlat.new()
	mp_sb.bg_color = pill_bg
	mp_sb.border_color = acc_hi
	mp_sb.set_border_width_all(1)
	mp_sb.set_corner_radius_all(4)
	mp_sb.content_margin_left = 10
	mp_sb.content_margin_right = 10
	mp_sb.content_margin_top = 4
	mp_sb.content_margin_bottom = 4
	min_pill.add_theme_stylebox_override("panel", mp_sb)
	var mp_lbl := Label.new()
	mp_lbl.text = _get_half_minute_str()
	mp_lbl.add_theme_font_override("font", UITheme.get_display_font())
	mp_lbl.add_theme_font_size_override("font_size", 11)
	mp_lbl.add_theme_color_override("font_color", Color("#FFFFFF"))
	min_pill.add_child(mp_lbl)
	hdr_hb.add_child(min_pill)

	var h_spacer := Control.new()
	h_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr_hb.add_child(h_spacer)

	# Top-Right Dynamic Score Pill (Gambar 3: [BIL 0-0 POL]!)
	var sc_pill := PanelContainer.new()
	sc_pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var sp_sb := mp_sb.duplicate()
	sp_sb.content_margin_left = 16
	sp_sb.content_margin_right = 16
	sp_sb.content_margin_top = 7
	sp_sb.content_margin_bottom = 7
	sc_pill.add_theme_stylebox_override("panel", sp_sb)
	var sc_txt: String = "%s %d-%d %s" % [
		_sb_home_code_lbl.text if _sb_home_code_lbl != null else "PBO",
		_score_us,
		_score_them,
		_sb_away_code_lbl.text if _sb_away_code_lbl != null else "DSI",
	]
	if run_mode == RunMode.CAREER_MATCH and CareerState.has_active_career:
		var fix_p: Dictionary = CareerState.get_current_fixture()
		var is_hm: bool = bool(fix_p.get("is_home", true))
		sc_txt = "%s %d-%d %s" % [
			_sb_home_code_lbl.text if _sb_home_code_lbl != null else "KLB",
			_score_us if is_hm else _score_them,
			_score_them if is_hm else _score_us,
			_sb_away_code_lbl.text if _sb_away_code_lbl != null else "LWN",
		]
	var sp_lbl := Label.new()
	sp_lbl.text = sc_txt
	sp_lbl.add_theme_font_override("font", UITheme.get_display_font())
	sp_lbl.add_theme_font_size_override("font_size", 15)
	sp_lbl.add_theme_color_override("font_color", Color("#FFFFFF"))
	sc_pill.add_child(sp_lbl)
	hdr_hb.add_child(sc_pill)

	# 2. MAIN TWO-COLUMN BODY (Left = 5 Action Bars | Right = 3 Control Customization Cards!)
	var cols := HBoxContainer.new()
	cols.set_anchors_preset(Control.PRESET_FULL_RECT)
	cols.offset_left = 36
	cols.offset_right = -36
	cols.offset_top = 94
	cols.offset_bottom = -34
	cols.add_theme_constant_override("separation", 24)
	main_wrap.add_child(cols)

	# LEFT COLUMN (52% width): LANJUT, CARA MAIN, SETELAN, ULANGI, KELUAR LAGA
	var left_vb := VBoxContainer.new()
	left_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_vb.size_flags_stretch_ratio = 1.08
	left_vb.alignment = BoxContainer.ALIGNMENT_CENTER
	left_vb.add_theme_constant_override("separation", 14)
	cols.add_child(left_vb)

	var res_b: Button = _make_pause_bar_btn("LANJUT", "PLAY", Color("#FFFFFF"), Color("#090E16", 0.94), resume_bd, 4)
	res_b.pressed.connect(func():
		AudioSynth.play_click()
		_is_paused = false
		if is_instance_valid(_pause_panel):
			_pause_panel.queue_free()
	)
	left_vb.add_child(res_b)

	var how_b: Button = _make_pause_bar_btn("CARA MAIN", "CONE", Color("#7DD3FC"), Color("#090E16", 0.88), Color("#1F334D"), 2)
	how_b.pressed.connect(func():
		AudioSynth.play_click()
		main_wrap.visible = false
		_open_how_to_play_subpanel(main_wrap, th)
	)
	left_vb.add_child(how_b)

	var set_b: Button = _make_pause_bar_btn("SETELAN", "GEAR", Color("#CBD5E1"), Color("#090E16", 0.88), Color("#1F334D"), 2)
	set_b.pressed.connect(func():
		AudioSynth.play_click()
		main_wrap.visible = false
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
	left_vb.add_child(set_b)

	var rep_b: Button = _make_pause_bar_btn("ULANGI", "REPLAY", Color("#FDE68A"), Color("#6E4815", 0.95), Color("#A67528"), 3)
	rep_b.pressed.connect(func():
		AudioSynth.play_click()
		_restart_current_match()
	)
	left_vb.add_child(rep_b)

	var exit_b: Button = _make_pause_bar_btn("KELUAR LAGA", "EXIT", Color("#FFFFFF"), Color("#D45454", 0.95), Color("#F08080"), 3)
	exit_b.pressed.connect(func():
		AudioSynth.play_click()
		_is_paused = false
		if is_instance_valid(_pause_panel):
			_pause_panel.queue_free()
		_on_skip_or_exit()
	)
	left_vb.add_child(exit_b)

	# RIGHT COLUMN (48% width): KIDAL, UKURAN, OPASITAS Live On-Pitch Control Cards!
	var right_vb := VBoxContainer.new()
	right_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vb.size_flags_stretch_ratio = 0.96
	right_vb.alignment = BoxContainer.ALIGNMENT_CENTER
	right_vb.add_theme_constant_override("separation", 18)
	cols.add_child(right_vb)

	var card_sb := StyleBoxFlat.new()
	card_sb.bg_color = Color(0.03, 0.06, 0.11, 0.68)
	card_sb.border_color = Color(0.20, 0.34, 0.52, 0.45)
	card_sb.set_border_width_all(1)
	card_sb.set_corner_radius_all(6)
	card_sb.content_margin_left = 16
	card_sb.content_margin_right = 16
	card_sb.content_margin_top = 14
	card_sb.content_margin_bottom = 14

	# Card 1: KIDAL (Left-Handed Toggle: TAK / YA)
	var kidal_c := PanelContainer.new()
	kidal_c.custom_minimum_size = Vector2(0, 114)
	kidal_c.add_theme_stylebox_override("panel", card_sb.duplicate())
	right_vb.add_child(kidal_c)

	var khb := HBoxContainer.new()
	khb.alignment = BoxContainer.ALIGNMENT_CENTER
	khb.add_theme_constant_override("separation", 12)
	kidal_c.add_child(khb)

	var k_ico := MatchHudWidgets.PauseMenuIcon.new()
	k_ico.kind = "SWAP"
	k_ico.col = Color("#EC4899")
	k_ico.custom_minimum_size = Vector2(24, 24)
	khb.add_child(k_ico)

	var k_lbl := Label.new()
	k_lbl.text = "KIDAL"
	k_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	k_lbl.add_theme_font_override("font", UITheme.get_display_font())
	k_lbl.add_theme_font_size_override("font_size", 14)
	k_lbl.add_theme_color_override("font_color", Color("#F8FAFC"))
	khb.add_child(k_lbl)

	var kidal_btn := Button.new()
	kidal_btn.custom_minimum_size = Vector2(82, 42)
	kidal_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var is_lh: bool = bool(SettingsManager.data.get("left_handed", false))
	kidal_btn.text = "YA" if is_lh else "TAK"
	UITheme.style_btn(kidal_btn, pill_bg if is_lh else Color("#0A101B"), acc_hi if is_lh else Color("#283E5C"), 13)
	kidal_btn.pressed.connect(func():
		AudioSynth.play_click()
		var nv: bool = not bool(SettingsManager.data.get("left_handed", false))
		SettingsManager.set_setting("left_handed", nv)
		kidal_btn.text = "YA" if nv else "TAK"
		UITheme.style_btn(kidal_btn, pill_bg if nv else Color("#0A101B"), acc_hi if nv else Color("#283E5C"), 13)
		_apply_control_layout_settings()
	)
	khb.add_child(kidal_btn)

	# Card 2: UKURAN (Joystick Size Slider: 60% .. 140%)
	var size_c := PanelContainer.new()
	size_c.custom_minimum_size = Vector2(0, 114)
	size_c.add_theme_stylebox_override("panel", card_sb.duplicate())
	right_vb.add_child(size_c)

	var shb := HBoxContainer.new()
	shb.alignment = BoxContainer.ALIGNMENT_CENTER
	shb.add_theme_constant_override("separation", 12)
	size_c.add_child(shb)

	var s_ico := MatchHudWidgets.PauseMenuIcon.new()
	s_ico.kind = "JOY"
	s_ico.col = Color("#38BDF8")
	s_ico.custom_minimum_size = Vector2(24, 24)
	shb.add_child(s_ico)

	var s_lbl := Label.new()
	s_lbl.text = "UKURAN"
	s_lbl.custom_minimum_size = Vector2(78, 0)
	s_lbl.add_theme_font_override("font", UITheme.get_display_font())
	s_lbl.add_theme_font_size_override("font_size", 13)
	s_lbl.add_theme_color_override("font_color", Color("#F8FAFC"))
	shb.add_child(s_lbl)

	var cur_sz: int = clampi(int(SettingsManager.data.get("joy_size", 100)), 60, 140)
	var sz_sl := HSlider.new()
	sz_sl.min_value = 60
	sz_sl.max_value = 140
	sz_sl.step = 5
	sz_sl.value = cur_sz
	sz_sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sz_sl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	MatchHudWidgets.style_cyan_slider(sz_sl, Color("#38BDF8"))
	shb.add_child(sz_sl)

	var sz_val_lbl := Label.new()
	sz_val_lbl.text = "%d%%" % cur_sz
	sz_val_lbl.custom_minimum_size = Vector2(46, 0)
	sz_val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	sz_val_lbl.add_theme_font_override("font", UITheme.get_display_font())
	sz_val_lbl.add_theme_font_size_override("font_size", 13)
	sz_val_lbl.add_theme_color_override("font_color", Color("#E2F2FF"))
	shb.add_child(sz_val_lbl)

	sz_sl.value_changed.connect(func(v: float):
		var iv: int = int(round(v))
		sz_val_lbl.text = "%d%%" % iv
		SettingsManager.set_setting("joy_size", iv)
		_apply_control_layout_settings()
	)

	# Card 3: OPASITAS (Joystick Opacity Slider: 15% .. 100%)
	var op_c := PanelContainer.new()
	op_c.custom_minimum_size = Vector2(0, 114)
	op_c.add_theme_stylebox_override("panel", card_sb.duplicate())
	right_vb.add_child(op_c)

	var ohb := HBoxContainer.new()
	ohb.alignment = BoxContainer.ALIGNMENT_CENTER
	ohb.add_theme_constant_override("separation", 12)
	op_c.add_child(ohb)

	var o_ico := MatchHudWidgets.PauseMenuIcon.new()
	o_ico.kind = "EYE"
	o_ico.col = Color("#38BDF8")
	o_ico.custom_minimum_size = Vector2(24, 24)
	ohb.add_child(o_ico)

	var o_lbl := Label.new()
	o_lbl.text = "OPASITAS"
	o_lbl.custom_minimum_size = Vector2(78, 0)
	o_lbl.add_theme_font_override("font", UITheme.get_display_font())
	o_lbl.add_theme_font_size_override("font_size", 13)
	o_lbl.add_theme_color_override("font_color", Color("#F8FAFC"))
	ohb.add_child(o_lbl)

	var cur_op: int = clampi(int(SettingsManager.data.get("joy_opacity", 70)), 15, 100)
	var op_sl := HSlider.new()
	op_sl.min_value = 15
	op_sl.max_value = 100
	op_sl.step = 5
	op_sl.value = cur_op
	op_sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	op_sl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	MatchHudWidgets.style_cyan_slider(op_sl, Color("#38BDF8"))
	ohb.add_child(op_sl)

	var op_val_lbl := Label.new()
	op_val_lbl.text = "%d%%" % cur_op
	op_val_lbl.custom_minimum_size = Vector2(46, 0)
	op_val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	op_val_lbl.add_theme_font_override("font", UITheme.get_display_font())
	op_val_lbl.add_theme_font_size_override("font_size", 13)
	op_val_lbl.add_theme_color_override("font_color", Color("#E2F2FF"))
	ohb.add_child(op_val_lbl)

	op_sl.value_changed.connect(func(v: float):
		var iv: int = int(round(v))
		op_val_lbl.text = "%d%%" % iv
		SettingsManager.set_setting("joy_opacity", iv)
		_apply_control_layout_settings()
	)

func _open_how_to_play_subpanel(parent_main: Control, th: Dictionary) -> void:
	var card := PanelContainer.new()
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.custom_minimum_size = Vector2(580, 344)
	card.offset_left = -290
	card.offset_right = 290
	card.offset_top = -172
	card.offset_bottom = 172
	var acc_hi: Color = th.get("accent_hi", Color("#7DD3FC"))
	var sb := UITheme.make_box(Color("#09111E", 0.96), acc_hi, 2, 10)
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 16
	sb.content_margin_bottom = 16
	card.add_theme_stylebox_override("panel", sb)
	_pause_panel.add_child(card)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	card.add_child(vb)

	var ttl := Label.new()
	ttl.text = "CARA MAIN  •  PANDUAN KONTROL LAGA"
	ttl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ttl.add_theme_font_override("font", UITheme.get_display_font())
	ttl.add_theme_font_size_override("font_size", 16)
	ttl.add_theme_color_override("font_color", acc_hi)
	vb.add_child(ttl)

	var tips: Array = [
		["1. GIRING BOLA (JOYSTICK)", "Geser joystick bundar di pojok bawah untuk menggiring bola melewati bek lawan. Atur KIDAL, UKURAN & OPASITAS di menu JEDA."],
		["2. TEMBAK & UMPAN KETAPEL", "Tarik mundur dari bola/layar lalu lepas untuk menendang. Kekuatan 65%+ melepas umpan panjang akurat ke rekan yang terbuka."],
		["3. SUDUT & EFEK BOLA (SPIN)", "Geser titik merah di bola kanan bawah untuk efek melengkung kiri/kanan, atau tarik ke separuh bawah untuk tendangan LAMBUNG."],
		["4. KENDALIKAN REKAN & KOMBINASI", "Saat mengoper ke rekan setim, kamu langsung mengendalikan rekan tersebut (lihat kartu nama asli di pojok bawah) untuk operan balik atau gol!"],
	]
	for tp in tips:
		var box := PanelContainer.new()
		var bsb := UITheme.make_box(Color("#0E1A2D"), Color("#243A59"), 1, 5)
		bsb.content_margin_left = 10
		bsb.content_margin_right = 10
		bsb.content_margin_top = 6
		bsb.content_margin_bottom = 6
		box.add_theme_stylebox_override("panel", bsb)
		var ivb := VBoxContainer.new()
		ivb.add_theme_constant_override("separation", 2)
		box.add_child(ivb)
		var l1 := Label.new()
		l1.text = str(tp[0])
		l1.add_theme_font_override("font", UITheme.get_display_font())
		l1.add_theme_font_size_override("font_size", 11)
		l1.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
		var l2 := Label.new()
		l2.text = str(tp[1])
		l2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l2.add_theme_font_size_override("font_size", 10)
		l2.add_theme_color_override("font_color", Color("#CBD5E1"))
		ivb.add_child(l1)
		ivb.add_child(l2)
		vb.add_child(box)

	var back_b := Button.new()
	back_b.text = "KEMBALI KE JEDA"
	back_b.custom_minimum_size = Vector2(0, 42)
	UITheme.style_btn(back_b, th.get("pill_bg", Color("#265B84")), acc_hi, 13)
	back_b.pressed.connect(func():
		AudioSynth.play_click()
		card.queue_free()
		if is_instance_valid(parent_main):
			parent_main.visible = true
	)
	vb.add_child(back_b)


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
		var is_loft := spin.y > 0.08
		if is_loft:
			draw_arc(center, rad - 2.0, 0.12 * PI, 0.88 * PI, 16, Color("#38BDF8", 0.75), 3.0)
		draw_circle(dot, 6.0, Color("#38BDF8") if is_loft else Color("#EF4444"))
		draw_arc(dot, 6.0, 0.0, TAU, 16, Color.WHITE, 1.2)
		var lbl_txt := "LAMBUNG ▲" if is_loft else "SUDUT BOLA"
		draw_string(UITheme.get_ui_font(), Vector2(4, size.y - 4), lbl_txt, HORIZONTAL_ALIGNMENT_CENTER, size.x - 8, 10, Color("#38BDF8") if is_loft else Color("#F5C542"))

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


class ShrinkingQTEOverlay extends Control:
	var center_pos: Vector2 = Vector2(480.0, 290.0)
	var progress: float = 0.0
	var perfect_tol: float = 0.12
	var good_tol: float = 0.24
	var prompt_label: String = "TAP!"

	func configure_state(pos: Vector2, prog: float, p_tol: float, g_tol: float, lbl: String) -> void:
		center_pos = pos
		progress = prog
		perfect_tol = p_tol
		good_tol = g_tol
		prompt_label = lbl

	func _draw() -> void:
		var c := center_pos
		var target_r: float = 46.0
		var start_r: float = 128.0
		var shrink_r: float = maxf(16.0, lerpf(start_r, target_r, progress))
		var band_px: float = maxf(8.0, (start_r - target_r) * good_tol)
		var err: float = absf(progress - 1.0)
		var in_perfect: bool = (err <= perfect_tol)
		var in_good: bool = (err <= good_tol)

		# Subtle dark backing disc
		draw_circle(c, target_r + band_px + 6.0, Color(0.02, 0.05, 0.11, 0.56))
		# Sweet-spot green target zone ring
		draw_arc(c, target_r, 0.0, TAU, 48, Color(0.16, 0.85, 0.45, 0.34), band_px * 1.45)
		draw_arc(c, target_r, 0.0, TAU, 48, Color("#FACC15") if in_perfect else Color("#4ADE80"), 3.2)
		# Inner center pulse dot
		draw_circle(c, 8.0, Color("#FACC15") if in_perfect else Color(0.18, 0.82, 0.92, 0.78))

		# Shrinking outer ring!
		var ring_col: Color = Color("#FACC15") if in_perfect else (Color("#4ADE80") if in_good else (Color("#EF4444") if progress > 1.0 + good_tol else Color("#F8FAFC")))
		draw_arc(c, shrink_r, 0.0, TAU, 48, Color(ring_col.r, ring_col.g, ring_col.b, 0.32), 9.0)
		draw_arc(c, shrink_r, 0.0, TAU, 48, ring_col, 4.0)

		# Crisp action label & tap instruction below ring
		var fnt := UITheme.get_display_font()
		var lbl_y := c.y + target_r + band_px + 24.0
		draw_rect(Rect2(c.x - 120.0, lbl_y - 18.0, 240.0, 42.0), Color(0.03, 0.07, 0.14, 0.88))
		draw_rect(Rect2(c.x - 120.0, lbl_y - 18.0, 240.0, 42.0), ring_col, false, 2.0)
		draw_string(fnt, Vector2(c.x - 116.0, lbl_y + 1.0), prompt_label, HORIZONTAL_ALIGNMENT_CENTER, 232.0, 14, ring_col)
		draw_string(UITheme.get_ui_font(), Vector2(c.x - 116.0, lbl_y + 17.0), "TAP / KLIK / SPASI SAAT PAS!", HORIZONTAL_ALIGNMENT_CENTER, 232.0, 10, Color("#E2E8F0"))
