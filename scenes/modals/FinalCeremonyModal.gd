extends Control

# 4-Part Cinematic Final Match & Trophy Winning Ceremony Modal
# Supports BOTH Club Elite/Continental/Cup Finals AND All Confederation / Timnas Finals:
#   MODE_PRE_FINAL_ARRIVAL (0): Video 1 - 4-shot Team Bus Arrival, 2 Police Escort Cars,
#                               Low Front Bus Approach, Illuminated Final Stadium Entrance + TV Crew
#   MODE_TROPHY_CELEBRATION (1): Videos 2 -> 3 -> 4 sequentially:
#       ACT_PODIUM_LIFT (0):       Pitch Championship Podium, Sweeping Spotlights, Pyro Cannons, 9 Players + Trophy Lift
#       ACT_LAP_OF_HONOUR (1):     PUTARAN HORMAT - Touchline LED Boards, 6 Players Handoff/Walk/Lift + Right Card
#       ACT_AIRPORT_HOMECOMING (2): PIALA PULANG - Sunset/Twilight Airport Charter Jet, Red-Carpet Stairs + Rolling Counter Card

signal finished

const MODE_PRE_FINAL_ARRIVAL := 0
const MODE_TROPHY_CELEBRATION := 1

const ACT_PODIUM_LIFT := 0
const ACT_LAP_OF_HONOUR := 1
const ACT_AIRPORT_HOMECOMING := 2
const ACT_TROPHY_CABINET := 3
const ACT_VICTORY_DEDICATION := 4

const PRE_SHOT_DURATIONS: Array[float] = [2.6, 2.6, 2.2, 3.0]
const PODIUM_AUTO_DURATION: float = 6.4

var _mode: int = MODE_PRE_FINAL_ARRIVAL
var _ctx: Dictionary = {}
var _act: int = ACT_PODIUM_LIFT
var _pre_shot: int = 0
var _t: float = 0.0
var _shot_t: float = 0.0
var _fade_alpha: float = 1.0
var _fade_color: Color = Color(0.02, 0.04, 0.09, 1.0)
var _closing: bool = false
var _prev_bgm: String = ""

# Card, counter & dedication choice animation state
var _card_revealed: bool = false
var _card_slide: float = 0.0
var _card_target_w: float = 340.0
var _counter_val: int = 0
var _counter_target: int = 20000
var _counter_t: float = 0.0
var _dedication_chosen: bool = false
var _dedication_anim_t: float = 0.0
var _dedication_rows: Array[Dictionary] = []

# Scene UI references
var _stage_canvas: Control = null
var _actor_layer: Control = null
var _fg_canvas: Control = null
var _overlay_layer: Control = null
var _top_pill: PanelContainer = null
var _pill_kicker: Label = null
var _pill_title: Label = null
var _pill_badge_holder: Control = null
var _skip_btn: Button = null
var _loading_bar_wrap: PanelContainer = null
var _loading_fill: ColorRect = null
var _loading_lbl: Label = null
var _right_card: PanelContainer = null
var _counter_lbl: Label = null
var _fade_rect: ColorRect = null

# Active actor nodes (cleared cleanly on every scene switch)
var _avatars: Array[PixelAvatar] = []
var _reporter_npc: NpcAvatar = null

# Deterministic lightweight particle pools (zero per-frame allocations)
var _confetti: Array[Dictionary] = []
var _smoke: Array[Dictionary] = []
var _sparks: Array[Dictionary] = []
var _stars: Array[Vector3] = []
var _crowd_seeds: Array[Dictionary] = []

func configure(mode_idx: int, ctx: Dictionary = {}) -> void:
	_mode = mode_idx
	_ctx = ctx.duplicate(true) if not ctx.is_empty() else _fallback_context()
	_counter_target = maxi(10000, int(_ctx.get("waiting_fans", 20000)))

func _fallback_context() -> Dictionary:
	if CareerState.has_active_career:
		return CareerState.build_final_ceremony_context()
	return {
		"is_timnas": false,
		"confed": "UEFA",
		"comp_key": "PIALA_ELITE",
		"comp_title": "PIALA ELITE",
		"comp_short": "ELITE",
		"team_name": "KLUB ELITE",
		"team_code": "ELB",
		"club_id": 0,
		"nation_id": 16,
		"nation_code": "IDN",
		"primary": Color("#1D4ED8"),
		"secondary": Color("#F8FAFC"),
		"pattern": "stripes",
		"accent": Color("#38BDF8"),
		"trophy_style": "BIG_EARS",
		"waiting_fans": 35000,
		"stadium_name": "ARENA FINAL ELITE",
		"airline_name": "AEROLINEAS",
		"led_ticker": "ELB  •  PIALA ELITE",
		"player_name": "BINTANG",
		"player_num": 10,
		"opp_name": "FINALIS",
		"opp_code": "FIN",
		"year": 2026,
		"score_us": 2,
		"score_them": 1,
		"bonus_legacy": 55,
		"bonus_followers": 22000,
		"squad_samples": [
			{"name": "SILVA", "num": 4, "seed": 411},
			{"name": "GOMEZ", "num": 7, "seed": 523},
			{"name": "DIAZ", "num": 11, "seed": 631},
			{"name": "LOPEZ", "num": 8, "seed": 743},
			{"name": "PEREZ", "num": 6, "seed": 857},
			{"name": "RUIZ", "num": 2, "seed": 967},
			{"name": "TORRES", "num": 19, "seed": 1087},
			{"name": "COSTA", "num": 1, "seed": 1193},
		],
	}

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UITheme.build_theme()
	clip_contents = true

	if _ctx.is_empty():
		_ctx = _fallback_context()
		_counter_target = maxi(10000, int(_ctx.get("waiting_fans", 20000)))

	_prev_bgm = AudioSynth.bgm_track_override
	AudioSynth.bgm_track_override = "MALAM JUARA"
	if _mode == MODE_TROPHY_CELEBRATION:
		AudioSynth.play_goal()
	else:
		AudioSynth.play_achievement()

	_init_particle_pools()
	_build_shell()

	if _mode == MODE_PRE_FINAL_ARRIVAL:
		_enter_pre_shot(0, false)
	else:
		_enter_trophy_act(ACT_PODIUM_LIFT, false)

func _exit_tree() -> void:
	AudioSynth.bgm_track_override = _prev_bgm

func _get_primary() -> Color:
	return UITheme.parse_color(_ctx.get("primary", Color("#1D4ED8")), Color("#1D4ED8"))

func _get_secondary() -> Color:
	return UITheme.parse_color(_ctx.get("secondary", Color("#F8FAFC")), Color("#F8FAFC"))

func _get_accent() -> Color:
	return UITheme.parse_color(_ctx.get("accent", Color("#38BDF8")), Color("#38BDF8"))

func _init_particle_pools() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261123 + int(_ctx.get("club_id", 0)) * 31 + int(_ctx.get("nation_id", 0)) * 17
	var pri: Color = _get_primary()
	var sec: Color = _get_secondary()
	var acc: Color = _get_accent()
	var palette: Array[Color] = [pri, sec, Color("#FACC15"), acc, Color("#FFFFFF"), pri.lightened(0.25)]

	_confetti.clear()
	for i in range(95):
		_confetti.append({
			"x": rng.randf_range(0.0, 960.0),
			"y": rng.randf_range(-40.0, 540.0),
			"vx": rng.randf_range(-24.0, 24.0),
			"vy": rng.randf_range(38.0, 105.0),
			"sz": rng.randf_range(3.5, 7.0),
			"phase": rng.randf_range(0.0, TAU),
			"col": palette[i % palette.size()],
		})

	_smoke.clear()
	for i in range(44):
		var side: float = -1.0 if (i % 2 == 0) else 1.0
		_smoke.append({
			"side": side,
			"offset": rng.randf_range(0.0, 1.0),
			"speed": rng.randf_range(0.24, 0.52),
			"rad": rng.randf_range(16.0, 40.0),
			"drift": rng.randf_range(-18.0, 18.0),
			"col_idx": i % 3,
		})

	_sparks.clear()
	for i in range(60):
		_sparks.append({
			"side": -1.0 if (i % 2 == 0) else 1.0,
			"life": rng.randf_range(0.0, 1.0),
			"spd": rng.randf_range(0.75, 1.55),
			"ang_off": rng.randf_range(-0.24, 0.24),
			"dist": rng.randf_range(75.0, 175.0),
			"sz": rng.randf_range(2.0, 4.2),
		})

	_stars.clear()
	for i in range(52):
		_stars.append(Vector3(rng.randf_range(10.0, 950.0), rng.randf_range(8.0, 195.0), rng.randf_range(0.0, TAU)))

	_crowd_seeds.clear()
	for i in range(72):
		_crowd_seeds.append({
			"u": float(i) / 72.0,
			"jit_x": rng.randf_range(-4.0, 4.0),
			"jit_y": rng.randf_range(-3.0, 3.0),
			"phase": rng.randf_range(0.0, TAU),
			"has_flag": (i % 4 == 0),
			"col_kind": i % 4,
			"skin": rng.randi_range(0, 4),
		})

func _build_shell() -> void:
	# Layer 0: Custom-drawn procedural 16-bit cinematic stage
	_stage_canvas = _CeremonyCanvas.new()
	_stage_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stage_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage_canvas.set("owner_modal", self)
	add_child(_stage_canvas)

	# Layer 1: Human-proportioned PixelAvatar & NpcAvatar actors
	_actor_layer = Control.new()
	_actor_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_actor_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_actor_layer.clip_contents = true
	add_child(_actor_layer)

	# Layer 1.5: Foreground trophy, cameraman, tarmac crowd & confetti rendered crisp in front of actors
	_fg_canvas = _CeremonyForegroundCanvas.new()
	_fg_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fg_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fg_canvas.set("owner_modal", self)
	add_child(_fg_canvas)

	# Layer 2: Broadcast HUD Pill, Skip Button, Loading Bar & Right Celebration Cards
	_overlay_layer = Control.new()
	_overlay_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay_layer.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_overlay_layer)

	# Top-Left Broadcast Context Pill (matching all 4 reference videos)
	_top_pill = PanelContainer.new()
	_top_pill.position = Vector2(18, 16)
	var acc: Color = _get_accent()
	var pill_sb: StyleBoxFlat = UITheme.make_box(Color(0.04, 0.08, 0.16, 0.88), Color(acc.r, acc.g, acc.b, 0.78), 2, 6)
	pill_sb.content_margin_left = 10
	pill_sb.content_margin_right = 14
	pill_sb.content_margin_top = 6
	pill_sb.content_margin_bottom = 6
	_top_pill.add_theme_stylebox_override("panel", pill_sb)
	_overlay_layer.add_child(_top_pill)

	var pill_hb := HBoxContainer.new()
	pill_hb.add_theme_constant_override("separation", 10)
	_top_pill.add_child(pill_hb)

	_pill_badge_holder = CenterContainer.new()
	_pill_badge_holder.custom_minimum_size = Vector2(30, 30)
	pill_hb.add_child(_pill_badge_holder)
	_populate_team_badge(_pill_badge_holder, Vector2(28, 28))

	var pill_vb := VBoxContainer.new()
	pill_vb.add_theme_constant_override("separation", 1)
	pill_hb.add_child(pill_vb)

	_pill_kicker = Label.new()
	_pill_kicker.add_theme_font_size_override("font_size", 10)
	_pill_kicker.add_theme_color_override("font_color", Color("#FACC15"))
	pill_vb.add_child(_pill_kicker)

	_pill_title = Label.new()
	_pill_title.add_theme_font_override("font", UITheme.get_display_font())
	_pill_title.add_theme_font_size_override("font_size", 14)
	_pill_title.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	pill_vb.add_child(_pill_title)

	# Bottom-Right Skip / Quick Advance Button (shown on auto-advancing shots & Podium Act)
	_skip_btn = Button.new()
	_skip_btn.text = "LEWATI >>"
	_skip_btn.custom_minimum_size = Vector2(118, 34)
	_skip_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_skip_btn.offset_left = -136
	_skip_btn.offset_top = -50
	_skip_btn.offset_right = -18
	_skip_btn.offset_bottom = -16
	UITheme.style_btn(_skip_btn, Color(0.06, 0.11, 0.22, 0.86), Color(acc.r, acc.g, acc.b, 0.72), 12)
	_skip_btn.pressed.connect(_on_skip_pressed)
	_overlay_layer.add_child(_skip_btn)

	# Bottom-Center Stadium Kickoff Loading Strip (only visible at end of Pre-Match Shot 3)
	_loading_bar_wrap = PanelContainer.new()
	_loading_bar_wrap.visible = false
	_loading_bar_wrap.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_loading_bar_wrap.offset_left = 230
	_loading_bar_wrap.offset_right = -230
	_loading_bar_wrap.offset_top = -62
	_loading_bar_wrap.offset_bottom = -16
	var lsb: StyleBoxFlat = UITheme.make_box(Color(0.04, 0.08, 0.16, 0.92), Color("#FACC15"), 2, 6)
	lsb.content_margin_left = 12
	lsb.content_margin_right = 12
	lsb.content_margin_top = 6
	lsb.content_margin_bottom = 6
	_loading_bar_wrap.add_theme_stylebox_override("panel", lsb)
	_overlay_layer.add_child(_loading_bar_wrap)

	var lvb := VBoxContainer.new()
	lvb.add_theme_constant_override("separation", 4)
	_loading_bar_wrap.add_child(lvb)

	_loading_lbl = Label.new()
	_loading_lbl.text = "MEMASUKI LAPANGAN FINAL..."
	_loading_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loading_lbl.add_theme_font_override("font", UITheme.get_display_font())
	_loading_lbl.add_theme_font_size_override("font_size", 11)
	_loading_lbl.add_theme_color_override("font_color", Color("#FACC15"))
	lvb.add_child(_loading_lbl)

	var track := ColorRect.new()
	track.custom_minimum_size = Vector2(0, 8)
	track.color = Color("#16233A")
	lvb.add_child(track)

	_loading_fill = ColorRect.new()
	_loading_fill.color = Color("#38BDF8")
	_loading_fill.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_loading_fill.size = Vector2(0, 8)
	track.add_child(_loading_fill)

	# Full-screen transition fade curtain (black between cuts, luminous white mist for Airport Act!)
	_fade_rect = ColorRect.new()
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.color = Color(0.02, 0.04, 0.09, 0.0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade_rect)

func _populate_team_badge(holder: Control, sz: Vector2) -> void:
	for c in holder.get_children():
		holder.remove_child(c)
		c.queue_free()
	if bool(_ctx.get("is_timnas", false)):
		var flag_sz := Vector2(sz.x, sz.y * 0.68)
		var fl: Control = UITheme.make_flag_by_code(
			str(_ctx.get("nation_code", "IDN")),
			[_get_primary(), _get_secondary()],
			flag_sz
		)
		holder.add_child(fl)
	else:
		var cr := ClubCrest.new()
		cr.custom_minimum_size = sz
		cr.set_club(int(_ctx.get("club_id", 0)))
		cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(cr)

func _clear_actors() -> void:
	for c in _actor_layer.get_children():
		_actor_layer.remove_child(c)
		c.queue_free()
	_avatars.clear()
	_reporter_npc = null

func _clear_right_card() -> void:
	if _right_card != null and is_instance_valid(_right_card):
		if _right_card.get_parent() != null:
			_right_card.get_parent().remove_child(_right_card)
		_right_card.queue_free()
	_right_card = null
	_counter_lbl = null
	_card_revealed = false
	_card_slide = 0.0
	_card_target_w = 340.0
	_dedication_chosen = false
	_dedication_anim_t = 0.0
	_dedication_rows.clear()

func _make_squad_avatar(is_user: bool, sample: Dictionary, kit: Dictionary, sz: Vector2, anim: String, phase: float, show_num: bool = false) -> PixelAvatar:
	var av := PixelAvatar.new()
	av.custom_minimum_size = sz
	av.size = sz
	av.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if is_user:
		if CareerState.has_active_career:
			av.configure_from_career()
		else:
			av.configure_from_seed(777, kit, int(_ctx.get("player_num", 10)))
		av.apply_kit(kit)
	else:
		av.configure_from_seed(int(sample.get("seed", 317)), kit, int(sample.get("num", 7)))
	av.show_number_badge = show_num
	av.show_shorts_number = show_num
	av.anim_mode = anim
	av.anim_phase = phase
	return av

func _get_team_kit() -> Dictionary:
	return {
		"primary": _get_primary(),
		"secondary": _get_secondary(),
		"pattern": str(_ctx.get("pattern", "stripes")),
	}

# ==============================================================================
# SCENE & ACT TRANSITIONS
# ==============================================================================
func _enter_pre_shot(shot_idx: int, play_fade: bool = true) -> void:
	_pre_shot = clampi(shot_idx, 0, 3)
	_shot_t = 0.0
	_clear_actors()
	_clear_right_card()
	_loading_bar_wrap.visible = false
	_skip_btn.visible = true
	_skip_btn.text = "LEWATI >>"

	_pill_kicker.text = "FINAL  •  %s" % str(_ctx.get("comp_title", "PIALA ELITE"))
	_pill_title.text = str(_ctx.get("team_name", "KLUB ELITE"))

	if play_fade:
		_fade_color = Color(0.02, 0.04, 0.09, 1.0)
		_fade_alpha = 0.85
	else:
		_fade_color = Color(0.02, 0.04, 0.09, 1.0)
		_fade_alpha = 0.95

	if _pre_shot == 3:
		# Shot 4: Stadium Exterior Entrance + Live Side-Profile TV Reporter + Squad walking inside!
		var kit: Dictionary = _get_team_kit()
		var samples: Array = _ctx.get("squad_samples", [])
		var s0: Dictionary = samples[0] if samples.size() > 0 else {"seed": 411, "num": 4}
		var s1: Dictionary = samples[1] if samples.size() > 1 else {"seed": 523, "num": 7}

		var av_left: PixelAvatar = _make_squad_avatar(false, s0, kit, Vector2(62, 102), "RUN", 0.3, false)
		var av_user: PixelAvatar = _make_squad_avatar(true, {}, kit, Vector2(68, 112), "RUN", 0.0, false)
		var av_right: PixelAvatar = _make_squad_avatar(false, s1, kit, Vector2(62, 102), "RUN", 0.7, false)
		_actor_layer.add_child(av_left)
		_actor_layer.add_child(av_right)
		_actor_layer.add_child(av_user)
		_avatars = [av_left, av_user, av_right]

		_reporter_npc = NpcAvatar.new()
		_reporter_npc.configure_role("REPORTER", true, kit)
		_reporter_npc.anim_mode = "TALK"
		_reporter_npc.size = Vector2(96, 128)
		_reporter_npc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_actor_layer.add_child(_reporter_npc)
		_position_actors()

func _enter_trophy_act(act_idx: int, play_fade: bool = true) -> void:
	_act = clampi(act_idx, ACT_PODIUM_LIFT, ACT_VICTORY_DEDICATION)
	_shot_t = 0.0
	_clear_actors()
	_clear_right_card()
	_loading_bar_wrap.visible = false
	_pill_kicker.add_theme_color_override("font_color", Color("#FACC15"))

	var kit: Dictionary = _get_team_kit()
	var samples: Array = _ctx.get("squad_samples", [])

	if _act == ACT_PODIUM_LIFT:
		# Video 2: Pitch Championship Podium + 9 Human-Proportioned Squad Avatars
		_pill_kicker.text = "JUARA %s" % str(_ctx.get("comp_title", "PIALA ELITE"))
		_pill_title.text = str(_ctx.get("team_name", "KLUB ELITE"))
		_skip_btn.visible = true
		_skip_btn.text = "LANJUT >>"
		_fade_color = Color(0.02, 0.05, 0.12, 1.0)
		_fade_alpha = 0.92 if not play_fade else 0.85

		# 9 players arranged on podium: 4 left, USER center hero (index 4), 4 right
		for i in range(9):
			var is_u: bool = (i == 4)
			var sm_idx: int = i if i < 4 else (i - 1)
			var sm: Dictionary = samples[sm_idx % maxi(1, samples.size())] if not samples.is_empty() else {"seed": 300 + i * 73, "num": i + 2}
			var av_sz: Vector2 = Vector2(68, 112) if is_u else Vector2(56, 92)
			var av: PixelAvatar = _make_squad_avatar(is_u, sm, kit, av_sz, "CHEER", float(i) * 0.42, false)
			_actor_layer.add_child(av)
			_avatars.append(av)
		AudioSynth.play_achievement()

	elif _act == ACT_LAP_OF_HONOUR:
		# Video 3: PUTARAN HORMAT - 6 Players with visible jersey numbers along touchline + Right Card
		_pill_kicker.text = "PUTARAN HORMAT  •  %s" % str(_ctx.get("comp_title", "PIALA ELITE"))
		_pill_title.text = "%s  •  %s" % [str(_ctx.get("team_name", "KLUB ELITE")), str(_ctx.get("player_name", "BINTANG"))]
		_skip_btn.visible = false
		_fade_color = Color(0.02, 0.04, 0.09, 1.0)
		_fade_alpha = 0.88 if play_fade else 0.0

		# 6 players along touchline: index 2 = User center star, index 3 = Captain/Teammate handing over trophy
		for i in range(6):
			var is_u: bool = (i == 2)
			var sm_idx: int = i if i < 2 else (i - 1)
			var sm: Dictionary = samples[sm_idx % maxi(1, samples.size())] if not samples.is_empty() else {"seed": 410 + i * 67, "num": 3 + i * 2}
			var av_sz: Vector2 = Vector2(78, 128) if is_u else Vector2(72, 118)
			var av: PixelAvatar = _make_squad_avatar(is_u, sm, kit, av_sz, "IDLE", float(i) * 0.35, true)
			_actor_layer.add_child(av)
			_avatars.append(av)
		_build_lap_of_honour_card()
		AudioSynth.play_achievement()

	elif _act == ACT_AIRPORT_HOMECOMING:
		# Video 4: PIALA PULANG - Luminous white mist fade-in to Sunset/Twilight Airport Jet + Rolling Counter!
		_pill_kicker.text = "PIALA PULANG  •  %s" % str(_ctx.get("comp_title", "PIALA ELITE"))
		_pill_title.text = str(_ctx.get("team_name", "KLUB ELITE"))
		_skip_btn.visible = false
		_fade_color = Color(0.95, 0.97, 1.0, 1.0)  # Iconic Video 4 white mist fade-in!
		_fade_alpha = 1.0 if play_fade else 0.0
		_counter_val = 0
		_counter_t = 0.0

		# User + 2 Teammates descending the red-carpet boarding stairs
		var s0: Dictionary = samples[0] if samples.size() > 0 else {"seed": 411, "num": 4}
		var s1: Dictionary = samples[1] if samples.size() > 1 else {"seed": 523, "num": 7}
		var av_u: PixelAvatar = _make_squad_avatar(true, {}, kit, Vector2(64, 104), "RUN", 0.0, false)
		var av_t1: PixelAvatar = _make_squad_avatar(false, s0, kit, Vector2(58, 94), "RUN", 0.4, false)
		var av_t2: PixelAvatar = _make_squad_avatar(false, s1, kit, Vector2(56, 90), "RUN", 0.8, false)
		_actor_layer.add_child(av_t2)
		_actor_layer.add_child(av_t1)
		_actor_layer.add_child(av_u)
		_avatars = [av_u, av_t1, av_t2]
		_build_airport_homecoming_card()
		AudioSynth.play_goal()

	elif _act == ACT_TROPHY_CABINET:
		# Video A (12-49-42): LEMARIMU - Cozy Illuminated Trophy Room + Back-View Player + Right Trophy Count Card
		_pill_kicker.text = "LEMARIMU"
		_pill_kicker.add_theme_color_override("font_color", Color("#F87171"))
		_pill_title.text = str(_ctx.get("player_name", "BINTANG"))
		_skip_btn.visible = false
		_fade_color = Color(0.02, 0.03, 0.06, 1.0)
		_fade_alpha = 0.92 if play_fade else 0.0
		_build_trophy_cabinet_card()
		AudioSynth.play_achievement()

	elif _act == ACT_VICTORY_DEDICATION:
		# Video B (12-50-02): JUARA / KELILING LAPANGAN - Night Pitch-Side + 3 Dedication Choices + RELASIMU Reveal!
		_pill_kicker.text = "JUARA"
		_pill_kicker.add_theme_color_override("font_color", Color("#F87171"))
		_pill_title.text = str(_ctx.get("team_name", "KLUB ELITE"))
		_skip_btn.visible = false
		_fade_color = Color(0.02, 0.04, 0.08, 1.0)
		_fade_alpha = 0.85 if play_fade else 0.0
		var av_hero: PixelAvatar = _make_squad_avatar(true, {}, kit, Vector2(126, 206), "IDLE", 0.0, false)
		_actor_layer.add_child(av_hero)
		_avatars = [av_hero]
		_build_victory_dedication_card()
		AudioSynth.play_achievement()

	_position_actors()

func _build_lap_of_honour_card() -> void:
	_clear_right_card()
	var acc: Color = _get_accent()
	_right_card = PanelContainer.new()
	_right_card.custom_minimum_size = Vector2(332, 0)
	var sb: StyleBoxFlat = UITheme.make_box(Color(0.04, 0.08, 0.16, 0.94), acc, 2, 10)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 16
	sb.content_margin_bottom = 16
	_right_card.add_theme_stylebox_override("panel", sb)
	_overlay_layer.add_child(_right_card)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	_right_card.add_child(vb)

	var kicker := Label.new()
	kicker.text = "JUARA %s" % str(_ctx.get("comp_title", "PIALA ELITE"))
	kicker.add_theme_font_override("font", UITheme.get_display_font())
	kicker.add_theme_font_size_override("font_size", 12)
	kicker.add_theme_color_override("font_color", Color("#FACC15"))
	vb.add_child(kicker)

	var title := Label.new()
	title.text = "PUTARAN HORMAT"
	title.add_theme_font_override("font", UITheme.get_display_font())
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	vb.add_child(title)

	var sep := ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 2)
	sep.color = Color(acc.r, acc.g, acc.b, 0.45)
	vb.add_child(sep)

	var team_row := HBoxContainer.new()
	team_row.add_theme_constant_override("separation", 10)
	vb.add_child(team_row)

	var badge_c := CenterContainer.new()
	badge_c.custom_minimum_size = Vector2(34, 34)
	team_row.add_child(badge_c)
	_populate_team_badge(badge_c, Vector2(32, 32))

	var t_vb := VBoxContainer.new()
	t_vb.add_theme_constant_override("separation", 2)
	t_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	team_row.add_child(t_vb)

	var tn := Label.new()
	tn.text = str(_ctx.get("team_name", "KLUB ELITE"))
	tn.add_theme_font_override("font", UITheme.get_display_font())
	tn.add_theme_font_size_override("font_size", 14)
	tn.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	tn.clip_text = true
	t_vb.add_child(tn)

	var sc := Label.new()
	sc.text = "FINAL %d - %d vs %s  •  %d" % [
		int(_ctx.get("score_us", 2)),
		int(_ctx.get("score_them", 1)),
		str(_ctx.get("opp_code", "FIN")),
		int(_ctx.get("year", 2026)),
	]
	sc.add_theme_font_size_override("font_size", 11)
	sc.add_theme_color_override("font_color", Color("#93C5FD"))
	t_vb.add_child(sc)

	var copy := Label.new()
	copy.text = "Seluruh tribun berdiri memberi tepuk tangan panjang. %s mengangkat piala di hadapan suporter yang tak pernah berhenti bernyanyi." % str(_ctx.get("player_name", "BINTANG"))
	copy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_theme_font_size_override("font_size", 12)
	copy.add_theme_color_override("font_color", Color("#CBD5E1"))
	vb.add_child(copy)

	var reward_box := PanelContainer.new()
	var rsb: StyleBoxFlat = UITheme.make_box(Color(0.08, 0.14, 0.25, 0.90), Color("#FACC15"), 1, 6)
	rsb.content_margin_left = 10
	rsb.content_margin_right = 10
	rsb.content_margin_top = 6
	rsb.content_margin_bottom = 6
	reward_box.add_theme_stylebox_override("panel", rsb)
	vb.add_child(reward_box)

	var rew_lbl := Label.new()
	rew_lbl.text = "+%d WARISAN  •  +%s PENGIKUT" % [
		int(_ctx.get("bonus_legacy", 55)),
		_format_int_dots(int(_ctx.get("bonus_followers", 22000))),
	]
	rew_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rew_lbl.add_theme_font_override("font", UITheme.get_display_font())
	rew_lbl.add_theme_font_size_override("font_size", 11)
	rew_lbl.add_theme_color_override("font_color", Color("#FACC15"))
	reward_box.add_child(rew_lbl)

	var btn := Button.new()
	btn.text = "LANJUT"
	btn.custom_minimum_size = Vector2(0, 42)
	UITheme.style_btn(btn, Color("#1E40AF"), Color("#38BDF8"), 14)
	btn.pressed.connect(func():
		AudioSynth.play_click()
		_enter_trophy_act(ACT_AIRPORT_HOMECOMING, true)
	)
	vb.add_child(btn)

	_right_card.visible = false
	_right_card.size = Vector2(336.0, 260.0)

func _build_airport_homecoming_card() -> void:
	_clear_right_card()
	_right_card = PanelContainer.new()
	_right_card.custom_minimum_size = Vector2(332, 0)
	var sb: StyleBoxFlat = UITheme.make_box(Color(0.05, 0.08, 0.15, 0.94), Color("#F59E0B"), 2, 10)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 16
	sb.content_margin_bottom = 16
	_right_card.add_theme_stylebox_override("panel", sb)
	_overlay_layer.add_child(_right_card)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 9)
	_right_card.add_child(vb)

	var title := Label.new()
	title.text = "PIALA PULANG"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", UITheme.get_display_font())
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("#FACC15"))
	vb.add_child(title)

	# Giant Live Rolling Supporter Counter Card (Video 4 signature element!)
	var cnt_panel := PanelContainer.new()
	var csb: StyleBoxFlat = UITheme.make_box(Color(0.08, 0.12, 0.22, 0.95), Color("#F59E0B"), 1, 8)
	csb.content_margin_left = 12
	csb.content_margin_right = 12
	csb.content_margin_top = 10
	csb.content_margin_bottom = 10
	cnt_panel.add_theme_stylebox_override("panel", csb)
	vb.add_child(cnt_panel)

	var cnt_vb := VBoxContainer.new()
	cnt_vb.add_theme_constant_override("separation", 2)
	cnt_panel.add_child(cnt_vb)

	_counter_lbl = Label.new()
	_counter_lbl.text = "0"
	_counter_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_counter_lbl.add_theme_font_override("font", UITheme.get_display_font())
	_counter_lbl.add_theme_font_size_override("font_size", 32)
	_counter_lbl.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	cnt_vb.add_child(_counter_lbl)

	var sub_cnt := Label.new()
	sub_cnt.text = "DITUNGGU  •  SUPORTER DI BANDARA"
	sub_cnt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_cnt.add_theme_font_override("font", UITheme.get_display_font())
	sub_cnt.add_theme_font_size_override("font_size", 11)
	sub_cnt.add_theme_color_override("font_color", Color("#FBBF24"))
	cnt_vb.add_child(sub_cnt)

	var quote := Label.new()
	quote.text = "Piala itu terbang di kursinya sendiri, sabuk terpasang. Tak ada yang melepasnya sepanjang penerbangan."
	quote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quote.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quote.add_theme_font_size_override("font_size", 12)
	quote.add_theme_color_override("font_color", Color("#E2E8F0"))
	vb.add_child(quote)

	var footer_hb := HBoxContainer.new()
	footer_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	footer_hb.add_theme_constant_override("separation", 8)
	vb.add_child(footer_hb)

	var b_hold := CenterContainer.new()
	b_hold.custom_minimum_size = Vector2(24, 24)
	footer_hb.add_child(b_hold)
	_populate_team_badge(b_hold, Vector2(22, 22))

	var foot_lbl := Label.new()
	foot_lbl.text = "%s  •  JUARA %s" % [str(_ctx.get("team_name", "KLUB")), str(_ctx.get("comp_title", "PIALA ELITE"))]
	foot_lbl.add_theme_font_size_override("font_size", 10)
	foot_lbl.add_theme_color_override("font_color", Color("#93C5FD"))
	foot_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	foot_lbl.clip_text = true
	footer_hb.add_child(foot_lbl)

	var btn := Button.new()
	btn.text = "LANJUT"
	btn.custom_minimum_size = Vector2(0, 42)
	UITheme.style_btn(btn, Color("#B45309"), Color("#FACC15"), 14)
	btn.pressed.connect(func():
		AudioSynth.play_click()
		_enter_trophy_act(ACT_TROPHY_CABINET, true)
	)
	vb.add_child(btn)

	_right_card.visible = false
	_right_card.size = Vector2(336.0, 260.0)

func _build_trophy_cabinet_card() -> void:
	_clear_right_card()
	_card_target_w = 348.0
	_right_card = PanelContainer.new()
	_right_card.custom_minimum_size = Vector2(348, 0)
	var sb: StyleBoxFlat = UITheme.make_box(Color(0.09, 0.09, 0.12, 0.90), Color(1.0, 1.0, 1.0, 0.16), 1, 8)
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 18
	sb.content_margin_bottom = 18
	_right_card.add_theme_stylebox_override("panel", sb)
	_overlay_layer.add_child(_right_card)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	_right_card.add_child(vb)

	var title := Label.new()
	title.text = "JUARA %s" % str(_ctx.get("comp_title", "PIALA ELITE"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", UITheme.get_display_font())
	title.add_theme_font_size_override("font_size", 19)
	title.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	vb.add_child(title)

	var sub_k := Label.new()
	sub_k.text = "DI TEMPATNYA"
	sub_k.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_k.add_theme_font_override("font", UITheme.get_display_font())
	sub_k.add_theme_font_size_override("font_size", 12)
	sub_k.add_theme_color_override("font_color", Color("#F87171"))
	vb.add_child(sub_k)

	var cnt_l := Label.new()
	cnt_l.text = str(maxi(1, int(_ctx.get("cabinet_count", 1))))
	cnt_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cnt_l.add_theme_font_override("font", UITheme.get_display_font())
	cnt_l.add_theme_font_size_override("font_size", 36)
	cnt_l.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	vb.add_child(cnt_l)

	var cap_l := Label.new()
	cap_l.text = "DI LEMARIMU"
	cap_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap_l.add_theme_font_size_override("font_size", 10)
	cap_l.add_theme_color_override("font_color", Color("#94A3B8"))
	vb.add_child(cap_l)

	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 6)
	vb.add_child(sp)

	var btn: Button = PressStageBackdrop.build_crimson_cta_button("LANJUT")
	btn.pressed.connect(func():
		AudioSynth.play_click()
		_enter_trophy_act(ACT_VICTORY_DEDICATION, true)
	)
	vb.add_child(btn)

	_right_card.visible = false
	_right_card.size = Vector2(348.0, 210.0)

func _get_dedication_choices() -> Array[Dictionary]:
	return [
		{
			"label": "ANGKAT UNTUK TRIBUN",
			"recap": "Angkat Untuk Tribun",
			"icon": "MIC",
			"color": Color("#554B8E"),
			"chips": [["+10 Fans", false], ["+3 Pers", false]],
			"effects": {"fans": 10, "pers": 3},
		},
		{
			"label": "BIAR GRUP YANG ANGKAT",
			"recap": "Biar Grup Yang Angkat",
			"icon": "JERSEY",
			"color": Color("#996920"),
			"chips": [["+16 Tim", false], ["+1 Pelatih", false]],
			"effects": {"ruangGanti": 16, "pelatih": 1},
		},
		{
			"label": "BERIKAN KE PELATIH",
			"recap": "Berikan Ke Pelatih",
			"icon": "COACH",
			"color": Color("#1E6A73"),
			"chips": [["+4 Pelatih", false], ["+2 Tim", false]],
			"effects": {"pelatih": 4, "ruangGanti": 2},
		},
	]

func _build_victory_dedication_card() -> void:
	_clear_right_card()
	_card_target_w = 472.0
	_right_card = PanelContainer.new()
	_right_card.custom_minimum_size = Vector2(472, 0)
	var sb: StyleBoxFlat = UITheme.make_box(Color(0.05, 0.07, 0.11, 0.78), Color(1.0, 1.0, 1.0, 0.10), 1, 8)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	_right_card.add_theme_stylebox_override("panel", sb)
	_overlay_layer.add_child(_right_card)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	_right_card.add_child(vb)

	var story := Label.new()
	story.text = "Juara. Pialanya benar-benar berat dan stadion tak akan ke mana-mana. Tinggal satu putaran keliling lapangan, dan semua berharap kamu mempersembahkannya untuk seseorang."
	story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	story.add_theme_font_size_override("font_size", 12)
	story.add_theme_color_override("font_color", Color("#F1F5F9"))
	vb.add_child(story)

	var row_hb := HBoxContainer.new()
	row_hb.add_theme_constant_override("separation", 8)
	vb.add_child(row_hb)

	var choices: Array[Dictionary] = _get_dedication_choices()
	for ci in range(choices.size()):
		var ch: Dictionary = choices[ci]
		var btn: Button = PressStageBackdrop.build_square_event_choice_button(
			str(ch["label"]),
			str(ch["icon"]),
			ch["color"],
			ch["chips"]
		)
		var idx_copy: int = ci
		btn.pressed.connect(func(): _apply_dedication_choice(idx_copy))
		row_hb.add_child(btn)

	_card_revealed = true
	_card_slide = 0.0
	_right_card.visible = true
	_right_card.size = Vector2(472.0, 248.0)

func _apply_dedication_choice(choice_idx: int) -> void:
	if _dedication_chosen:
		return
	var choices: Array[Dictionary] = _get_dedication_choices()
	var ch: Dictionary = choices[clampi(choice_idx, 0, choices.size() - 1)]
	AudioSynth.play_click()
	_dedication_chosen = true
	_dedication_anim_t = 0.0
	_dedication_rows.clear()

	if not _avatars.is_empty():
		_avatars[0].anim_mode = "CHEER"

	var res: Dictionary = CareerState.apply_final_dedication_choice(ch["effects"])
	var deltas: Dictionary = res.get("deltas", {})
	var before_m: Dictionary = res.get("before", {})
	var after_m: Dictionary = res.get("after", {})

	if _right_card == null or not is_instance_valid(_right_card):
		return
	for c in _right_card.get_children():
		_right_card.remove_child(c)
		c.queue_free()

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	_right_card.add_child(vb)

	var story := Label.new()
	story.text = "Juara. Pialanya benar-benar berat dan stadion tak akan ke mana-mana. Tinggal satu putaran keliling lapangan, dan semua berharap kamu mempersembahkannya untuk seseorang."
	story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	story.add_theme_font_size_override("font_size", 11)
	story.add_theme_color_override("font_color", Color("#CBD5E1"))
	vb.add_child(story)

	var recap := Label.new()
	recap.text = "KELILING LAPANGAN: %s" % str(ch["recap"])
	recap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	recap.add_theme_font_override("font", UITheme.get_display_font())
	recap.add_theme_font_size_override("font_size", 13)
	recap.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	vb.add_child(recap)

	var hdr_hb := HBoxContainer.new()
	hdr_hb.add_theme_constant_override("separation", 6)
	vb.add_child(hdr_hb)
	var flag_sq := ColorRect.new()
	flag_sq.custom_minimum_size = Vector2(10, 12)
	flag_sq.color = Color("#E11D48")
	flag_sq.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hdr_hb.add_child(flag_sq)
	var rel_hdr := Label.new()
	rel_hdr.text = "RELASIMU"
	rel_hdr.add_theme_font_override("font", UITheme.get_display_font())
	rel_hdr.add_theme_font_size_override("font_size", 11)
	rel_hdr.add_theme_color_override("font_color", Color("#E2E8F0"))
	hdr_hb.add_child(rel_hdr)

	var rel_grid := HBoxContainer.new()
	rel_grid.add_theme_constant_override("separation", 10)
	vb.add_child(rel_grid)

	var labels_map := {"pelatih": "Pelatih", "ruangGanti": "Ruang ganti", "fans": "Suporter", "pers": "Pers"}
	for rk in deltas.keys():
		var dv: int = int(deltas[rk])
		if dv == 0:
			continue
		var r_box := PanelContainer.new()
		r_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var rsb: StyleBoxFlat = UITheme.make_box(Color(0.08, 0.11, 0.18, 0.90), Color(1.0, 1.0, 1.0, 0.14), 1, 5)
		rsb.content_margin_left = 10
		rsb.content_margin_right = 10
		rsb.content_margin_top = 7
		rsb.content_margin_bottom = 7
		r_box.add_theme_stylebox_override("panel", rsb)
		rel_grid.add_child(r_box)

		var rhb := HBoxContainer.new()
		rhb.add_theme_constant_override("separation", 6)
		r_box.add_child(rhb)

		var nm_l := Label.new()
		nm_l.text = str(labels_map.get(rk, rk.capitalize()))
		nm_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nm_l.add_theme_font_size_override("font_size", 11)
		nm_l.add_theme_color_override("font_color", Color("#E2E8F0"))
		rhb.add_child(nm_l)

		var dl_l := Label.new()
		dl_l.text = "%s%d" % [("+" if dv > 0 else ""), dv]
		dl_l.add_theme_font_override("font", UITheme.get_display_font())
		dl_l.add_theme_font_size_override("font_size", 12)
		dl_l.add_theme_color_override("font_color", Color("#4ADE80") if dv > 0 else Color("#F87171"))
		rhb.add_child(dl_l)

		var val_l := Label.new()
		var bv: int = int(before_m.get(rk, 60))
		var av_v: int = int(after_m.get(rk, bv + dv))
		val_l.text = str(bv)
		val_l.add_theme_font_override("font", UITheme.get_display_font())
		val_l.add_theme_font_size_override("font_size", 13)
		val_l.add_theme_color_override("font_color", Color("#F87171") if dv < 0 else Color("#FCA5A5"))
		rhb.add_child(val_l)
		_dedication_rows.append({"lbl": val_l, "from": bv, "to": av_v})

	var ok_b: Button = PressStageBackdrop.build_crimson_cta_button("LANJUTKAN")
	ok_b.pressed.connect(func():
		AudioSynth.play_click()
		_finish_ceremony()
	)
	vb.add_child(ok_b)
	AudioSynth.play_goal()

func _format_int_dots(val: int) -> String:
	var s: String = str(absi(val))
	var out: String = ""
	var cnt: int = 0
	for i in range(s.length() - 1, -1, -1):
		if cnt > 0 and cnt % 3 == 0:
			out = "." + out
		out = s[i] + out
		cnt += 1
	return out

func _on_skip_pressed() -> void:
	AudioSynth.play_click()
	if _mode == MODE_PRE_FINAL_ARRIVAL:
		_finish_ceremony()
	elif _act == ACT_PODIUM_LIFT:
		_enter_trophy_act(ACT_LAP_OF_HONOUR, true)
	elif _act == ACT_LAP_OF_HONOUR:
		_enter_trophy_act(ACT_AIRPORT_HOMECOMING, true)
	elif _act == ACT_AIRPORT_HOMECOMING:
		_enter_trophy_act(ACT_TROPHY_CABINET, true)
	elif _act == ACT_TROPHY_CABINET:
		_enter_trophy_act(ACT_VICTORY_DEDICATION, true)
	else:
		_finish_ceremony()

func _finish_ceremony() -> void:
	if _closing:
		return
	_closing = true
	finished.emit()
	queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var ke: InputEventKey = event as InputEventKey
		if ke.keycode == KEY_ESCAPE or ke.keycode == KEY_SPACE or ke.keycode == KEY_ENTER:
			if _mode == MODE_PRE_FINAL_ARRIVAL:
				_on_skip_pressed()
			elif _act == ACT_PODIUM_LIFT:
				_enter_trophy_act(ACT_LAP_OF_HONOUR, true)
			elif _act == ACT_LAP_OF_HONOUR and _card_revealed:
				_enter_trophy_act(ACT_AIRPORT_HOMECOMING, true)
			elif _act == ACT_AIRPORT_HOMECOMING and _card_revealed:
				_enter_trophy_act(ACT_TROPHY_CABINET, true)
			elif _act == ACT_TROPHY_CABINET and _card_revealed:
				_enter_trophy_act(ACT_VICTORY_DEDICATION, true)
			elif _act == ACT_VICTORY_DEDICATION and _dedication_chosen:
				_finish_ceremony()
			get_viewport().set_input_as_handled()

# ==============================================================================
# FRAME UPDATE (PURE _process, ZERO LOOPING TWEENS)
# ==============================================================================
func _process(delta: float) -> void:
	if _closing:
		return
	var dt: float = minf(delta, 0.05)
	_t += dt
	_shot_t += dt

	# Fade curtain decay
	if _fade_alpha > 0.0:
		var fade_spd: float = 1.65 if (_mode == MODE_TROPHY_CELEBRATION and _act == ACT_AIRPORT_HOMECOMING) else 2.2
		_fade_alpha = maxf(0.0, _fade_alpha - dt * fade_spd)
	_fade_rect.color = Color(_fade_color.r, _fade_color.g, _fade_color.b, _fade_alpha)

	# Update confetti particles
	var vw: float = maxf(size.x, 960.0)
	var vh: float = maxf(size.y, 540.0)
	for c in _confetti:
		var ny: float = float(c["y"]) + float(c["vy"]) * dt
		var nx: float = float(c["x"]) + (float(c["vx"]) + sin(_t * 3.1 + float(c["phase"])) * 20.0) * dt
		if ny > vh + 14.0:
			ny = -12.0
			nx = fmod(nx + vw * 1.37, vw)
		c["x"] = nx
		c["y"] = ny

	# Mode state machines
	if _mode == MODE_PRE_FINAL_ARRIVAL:
		var dur: float = PRE_SHOT_DURATIONS[clampi(_pre_shot, 0, PRE_SHOT_DURATIONS.size() - 1)]
		if _pre_shot == 3 and _shot_t >= 1.65:
			_loading_bar_wrap.visible = true
			var lp: float = clampf((_shot_t - 1.65) / 1.25, 0.0, 1.0)
			if _loading_fill != null and _loading_fill.get_parent() is Control:
				var pw: float = (_loading_fill.get_parent() as Control).size.x
				_loading_fill.size.x = pw * lp
		if _shot_t >= dur:
			if _pre_shot < 3:
				_enter_pre_shot(_pre_shot + 1, true)
			else:
				_finish_ceremony()
				return
	else:
		if _act == ACT_PODIUM_LIFT:
			if _shot_t >= PODIUM_AUTO_DURATION:
				_enter_trophy_act(ACT_LAP_OF_HONOUR, true)
		elif _act == ACT_LAP_OF_HONOUR:
			# Update touchline 6-player choreography (0..1.4 handoff, 1.4..3.4 march, 3.4+ lift + card!)
			for i in range(_avatars.size()):
				var av: PixelAvatar = _avatars[i]
				if _shot_t < 1.4:
					av.anim_mode = "TALK" if (i == 2 or i == 3) else "IDLE"
				elif _shot_t < 3.4:
					av.anim_mode = "RUN"
				else:
					av.anim_mode = "CHEER"
			if _shot_t >= 3.55 and not _card_revealed:
				_card_revealed = true
				if _right_card != null:
					_right_card.visible = true
				AudioSynth.play_goal()
		elif _act == ACT_AIRPORT_HOMECOMING:
			# Update boarding stairs descent choreography (0..2.2 walk down, 2.2+ trophy lift!)
			for i in range(_avatars.size()):
				var av: PixelAvatar = _avatars[i]
				if _shot_t < 2.25:
					av.anim_mode = "RUN"
				else:
					av.anim_mode = "CHEER"
			if _shot_t >= 1.85 and not _card_revealed:
				_card_revealed = true
				if _right_card != null:
					_right_card.visible = true
			if _card_revealed:
				_counter_t += dt
				var ease_p: float = 1.0 - pow(1.0 - clampf(_counter_t / 1.85, 0.0, 1.0), 3.0)
				_counter_val = int(round(float(_counter_target) * ease_p))
				if _counter_lbl != null:
					_counter_lbl.text = _format_int_dots(_counter_val)
		elif _act == ACT_TROPHY_CABINET:
			if _shot_t >= 1.15 and not _card_revealed:
				_card_revealed = true
				if _right_card != null:
					_right_card.visible = true
		elif _act == ACT_VICTORY_DEDICATION:
			if _dedication_chosen and not _dedication_rows.is_empty():
				_dedication_anim_t = minf(1.0, _dedication_anim_t + dt * 1.6)
				var rp: float = 1.0 - pow(1.0 - _dedication_anim_t, 3.0)
				for row in _dedication_rows:
					var rl: Label = row["lbl"]
					if is_instance_valid(rl):
						var v_now: int = int(round(lerpf(float(row["from"]), float(row["to"]), rp)))
						rl.text = str(v_now)

	# Smooth card slide-in on the right side (strictly shrink-wrapped so card never stretches off bottom!)
	if _card_revealed and _right_card != null:
		_card_slide = minf(1.0, _card_slide + dt * 3.8)
		var ease_s: float = 1.0 - pow(1.0 - _card_slide, 3.0)
		var card_w: float = _card_target_w
		var card_h: float = minf(_right_card.get_combined_minimum_size().y, vh - 96.0)
		_right_card.size = Vector2(card_w, card_h)
		var target_x: float = vw - card_w - 20.0
		var start_x: float = vw + 24.0
		var target_y: float = clampf((vh - card_h) * (0.64 if _act == ACT_VICTORY_DEDICATION else 0.50), 62.0, vh - card_h - 20.0)
		_right_card.position = Vector2(lerpf(start_x, target_x, ease_s), target_y)

	_position_actors()
	if _stage_canvas != null:
		_stage_canvas.queue_redraw()
	if _fg_canvas != null:
		_fg_canvas.queue_redraw()

func _position_actors() -> void:
	var vw: float = maxf(size.x, 960.0)
	var vh: float = maxf(size.y, 540.0)

	if _mode == MODE_PRE_FINAL_ARRIVAL and _pre_shot == 3:
		# Players striding up red carpet toward stadium gate, side-profile TV reporter right foreground
		var walk_p: float = clampf(_shot_t / 2.2, 0.0, 1.0)
		var base_y: float = lerpf(vh * 0.72, vh * 0.58, walk_p)
		var sc: float = lerpf(1.05, 0.90, walk_p)
		var cx: float = vw * 0.46
		var x_offs: Array[float] = [-68.0, 0.0, 68.0]
		for i in range(mini(3, _avatars.size())):
			var av: PixelAvatar = _avatars[i]
			av.scale = Vector2(sc, sc)
			av.position = Vector2(cx + x_offs[i] * sc - av.size.x * 0.5 * sc, base_y - av.size.y * sc * (1.0 if i == 1 else 0.94))
		if _reporter_npc != null:
			_reporter_npc.position = Vector2(vw * 0.71, vh * 0.62)

	elif _mode == MODE_TROPHY_CELEBRATION and _act == ACT_PODIUM_LIFT:
		# 9 squad players celebrating atop the raised center podium deck!
		var podium_cx: float = vw * 0.50
		var deck_y: float = vh * 0.645
		var slots_x: Array[float] = [-212.0, -162.0, -110.0, -58.0, 0.0, 58.0, 110.0, 162.0, 212.0]
		var slots_y: Array[float] = [6.0, 3.0, 0.0, -2.0, -12.0, -2.0, 0.0, 3.0, 6.0]
		for i in range(mini(slots_x.size(), _avatars.size())):
			var av: PixelAvatar = _avatars[i]
			var jump: float = absf(sin(_t * 5.8 + float(i) * 0.65)) * (8.0 if i == 4 else 6.0)
			av.scale = Vector2.ONE
			av.position = Vector2(podium_cx + slots_x[i] - av.size.x * 0.5, deck_y + slots_y[i] - av.size.y - jump)

	elif _mode == MODE_TROPHY_CELEBRATION and _act == ACT_LAP_OF_HONOUR:
		# 6 players along touchline on left-center 60% so right Celebration Card never overlaps them!
		var march_p: float = clampf((_shot_t - 1.4) / 2.0, 0.0, 1.0)
		var group_shift: float = lerpf(85.0, 0.0, march_p)
		var base_xs: Array[float] = [62.0, 142.0, 232.0, 322.0, 404.0, 482.0]
		var foot_y: float = vh * 0.84
		for i in range(mini(base_xs.size(), _avatars.size())):
			var av: PixelAvatar = _avatars[i]
			var hop: float = 0.0
			if _shot_t >= 3.4:
				hop = absf(sin(_t * 6.0 + float(i) * 0.55)) * (6.0 if i == 2 else 4.0)
			av.scale = Vector2.ONE
			av.position = Vector2(base_xs[i] + group_shift - av.size.x * 0.5, foot_y - av.size.y - hop + (0.0 if i == 2 else 6.0))

	elif _mode == MODE_TROPHY_CELEBRATION and _act == ACT_AIRPORT_HOMECOMING:
		# 3 players emerging from jet cabin door & descending red-carpet boarding stairs cleanly side-by-side!
		var zoom_p: float = clampf(_shot_t / 3.2, 0.0, 1.0)
		var cam_s: float = lerpf(1.0, 1.08, zoom_p)
		var top_pt := Vector2(vw * 0.365, vh * 0.445)
		var bot_targets: Array[Vector2] = [
			Vector2(vw * 0.465, vh * 0.755),  # User front-center at red carpet foot
			Vector2(vw * 0.388, vh * 0.745),  # Teammate 1 left beside stairs
			Vector2(vw * 0.535, vh * 0.745),  # Teammate 2 right beside stairs (still clear of card at x=604!)
		]
		for i in range(mini(3, _avatars.size())):
			var av: PixelAvatar = _avatars[i]
			var delay: float = float(i) * 0.28
			var step_p: float = clampf((_shot_t - delay) / 1.95, 0.0, 1.0)
			var pos_pt: Vector2 = top_pt.lerp(bot_targets[i], step_p)
			var hop: float = absf(sin(_t * 5.8 + float(i))) * 5.0 if _shot_t >= 2.25 else 0.0
			av.scale = Vector2(cam_s * 0.88, cam_s * 0.88)
			av.position = Vector2(pos_pt.x - av.size.x * 0.5 * av.scale.x, pos_pt.y - av.size.y * av.scale.y - hop)

	elif _mode == MODE_TROPHY_CELEBRATION and _act == ACT_VICTORY_DEDICATION:
		if not _avatars.is_empty():
			var hero: PixelAvatar = _avatars[0]
			hero.scale = Vector2.ONE
			hero.position = Vector2(vw * 0.24 - hero.size.x * 0.5, vh * 0.69 - hero.size.y)

# ==============================================================================
# TEST & PREVIEW HOOKS
# ==============================================================================
func get_ceremony_state() -> Dictionary:
	return {
		"mode": _mode,
		"act": _act,
		"pre_shot": _pre_shot,
		"elapsed": _t,
		"shot_t": _shot_t,
		"card_revealed": _card_revealed,
		"counter_val": _counter_val,
		"counter_target": _counter_target,
		"avatars_count": _avatars.size(),
		"dedication_chosen": _dedication_chosen,
	}

func advance_step_for_test() -> void:
	if _mode == MODE_PRE_FINAL_ARRIVAL:
		if _pre_shot < 3:
			_enter_pre_shot(_pre_shot + 1, false)
		else:
			_finish_ceremony()
	else:
		if _act == ACT_PODIUM_LIFT:
			_enter_trophy_act(ACT_LAP_OF_HONOUR, false)
		elif _act == ACT_LAP_OF_HONOUR:
			_enter_trophy_act(ACT_AIRPORT_HOMECOMING, false)
		elif _act == ACT_AIRPORT_HOMECOMING:
			_enter_trophy_act(ACT_TROPHY_CABINET, false)
		elif _act == ACT_TROPHY_CABINET:
			_enter_trophy_act(ACT_VICTORY_DEDICATION, false)
		else:
			_finish_ceremony()

func select_dedication_choice_for_test(choice_idx: int = 1) -> void:
	if _mode == MODE_TROPHY_CELEBRATION and _act == ACT_VICTORY_DEDICATION:
		_apply_dedication_choice(choice_idx)
		_dedication_anim_t = 1.0
		_process(0.016)

func jump_to_state_for_preview(mode_idx: int, sub_idx: int, t_sec: float) -> void:
	_mode = mode_idx
	if _mode == MODE_PRE_FINAL_ARRIVAL:
		_enter_pre_shot(sub_idx, false)
	else:
		_enter_trophy_act(sub_idx, false)
	_fade_alpha = 0.0
	_fade_rect.color.a = 0.0
	_t = t_sec
	_shot_t = t_sec
	if _mode == MODE_TROPHY_CELEBRATION and _act == ACT_LAP_OF_HONOUR and t_sec >= 3.55:
		_card_revealed = true
		_card_slide = 1.0
		if _right_card != null:
			_right_card.visible = true
	elif _mode == MODE_TROPHY_CELEBRATION and _act == ACT_AIRPORT_HOMECOMING and t_sec >= 1.85:
		_card_revealed = true
		_card_slide = 1.0
		_counter_t = 2.0
		_counter_val = _counter_target
		if _right_card != null:
			_right_card.visible = true
		if _counter_lbl != null:
			_counter_lbl.text = _format_int_dots(_counter_val)
	elif _mode == MODE_TROPHY_CELEBRATION and _act == ACT_TROPHY_CABINET and t_sec >= 1.15:
		_card_revealed = true
		_card_slide = 1.0
		if _right_card != null:
			_right_card.visible = true
	elif _mode == MODE_TROPHY_CELEBRATION and _act == ACT_VICTORY_DEDICATION:
		_card_revealed = true
		_card_slide = 1.0
	_process(0.016)

# ==============================================================================
# PROCEDURAL 16-BIT CINEMATIC STAGE RENDERER (ALL 4 VIDEOS)
# ==============================================================================
class _CeremonyCanvas extends Control:
	var owner_modal: Control = null

	func _draw() -> void:
		if owner_modal == null or not is_instance_valid(owner_modal):
			return
		var w: float = maxf(size.x, 960.0)
		var h: float = maxf(size.y, 540.0)
		var mode: int = int(owner_modal.get("_mode"))
		if mode == MODE_PRE_FINAL_ARRIVAL:
			var shot: int = int(owner_modal.get("_pre_shot"))
			match shot:
				0: _draw_pre_shot0_avenue_bus(w, h)
				1: _draw_pre_shot1_police_convoy(w, h)
				2: _draw_pre_shot2_bus_closeup(w, h)
				_: _draw_pre_shot3_stadium_gate(w, h)
		else:
			var act: int = int(owner_modal.get("_act"))
			match act:
				ACT_PODIUM_LIFT: _draw_act0_podium_lift(w, h)
				ACT_LAP_OF_HONOUR: _draw_act1_lap_of_honour(w, h)
				ACT_AIRPORT_HOMECOMING: _draw_act2_airport_homecoming(w, h)
				ACT_TROPHY_CABINET: _draw_act3_trophy_cabinet(w, h)
				_: _draw_act4_victory_dedication_bg(w, h)

	func _pri() -> Color:
		return owner_modal.call("_get_primary")

	func _sec() -> Color:
		return owner_modal.call("_get_secondary")

	func _acc() -> Color:
		return owner_modal.call("_get_accent")

	func _ctx() -> Dictionary:
		return owner_modal.get("_ctx")

	func _t() -> float:
		return float(owner_modal.get("_t"))

	func _st() -> float:
		return float(owner_modal.get("_shot_t"))

	# --------------------------------------------------------------------------
	# SHARED ART PRIMITIVES
	# --------------------------------------------------------------------------
	func _draw_vertical_gradient(w: float, y0: float, y1: float, c_top: Color, c_bot: Color, bands: int = 12) -> void:
		var bh: float = (y1 - y0) / float(bands)
		for i in range(bands):
			var frac: float = float(i) / float(maxi(1, bands - 1))
			draw_rect(Rect2(0.0, y0 + float(i) * bh, w, bh + 1.5), c_top.lerp(c_bot, frac))

	func _draw_confetti_layer(alpha_mult: float = 1.0) -> void:
		var conf: Array = owner_modal.get("_confetti")
		var t: float = _t()
		for c in conf:
			var col: Color = c["col"]
			var sz: float = float(c["sz"])
			var spin: float = absf(cos(t * 5.0 + float(c["phase"])))
			draw_rect(Rect2(float(c["x"]), float(c["y"]), sz, maxf(1.8, sz * spin)), Color(col.r, col.g, col.b, col.a * alpha_mult))

	func _draw_stadium_silhouette(cx: float, base_y: float, sw: float, sh: float, acc: Color, stadium_nm: String) -> void:
		# Glowing floodlight sky cones behind stadium
		for fi in range(4):
			var fx: float = cx - sw * 0.44 + float(fi) * (sw * 0.293)
			var fy: float = base_y - sh * 1.18
			draw_rect(Rect2(fx - 3.0, fy, 6.0, sh * 0.72), Color("#26354F"))
			draw_rect(Rect2(fx - 12.0, fy - 8.0, 24.0, 10.0), Color("#E2E8F0"))
			draw_circle(Vector2(fx, fy - 2.0), 16.0, Color(1.0, 0.98, 0.86, 0.35))
			var beam := PackedVector2Array([
				Vector2(fx - 10.0, fy),
				Vector2(fx + 10.0, fy),
				Vector2(fx + (cx - fx) * 0.55 + 48.0, base_y + 18.0),
				Vector2(fx + (cx - fx) * 0.55 - 48.0, base_y + 18.0),
			])
			draw_colored_polygon(beam, Color(0.85, 0.95, 1.0, 0.08))

		# Stadium bowl structure & glowing roof fascia
		var bowl := PackedVector2Array([
			Vector2(cx - sw * 0.50, base_y),
			Vector2(cx - sw * 0.44, base_y - sh * 0.84),
			Vector2(cx, base_y - sh),
			Vector2(cx + sw * 0.44, base_y - sh * 0.84),
			Vector2(cx + sw * 0.50, base_y),
		])
		draw_colored_polygon(bowl, Color("#15243D"))
		draw_polyline(bowl, Color(acc.r, acc.g, acc.b, 0.75), 2.5)
		# Horizontal illuminated glass tiers
		for ti in range(3):
			var ty: float = base_y - sh * (0.24 + float(ti) * 0.22)
			var tw: float = sw * (0.90 - float(ti) * 0.09)
			draw_rect(Rect2(cx - tw * 0.5, ty, tw, 6.0), Color(acc.r, acc.g, acc.b, 0.42 + float(ti) * 0.14))
		# Central stadium glowing portal & name sign (auto-sized to never clip!)
		var fdisp: Font = UITheme.get_display_font()
		var lbl_txt: String = stadium_nm.left(22)
		var tsz: Vector2 = fdisp.get_string_size(lbl_txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 9)
		var sign_w: float = maxf(sw * 0.32, tsz.x + 18.0)
		draw_rect(Rect2(cx - sign_w * 0.5 - 4.0, base_y - sh * 0.34, sign_w + 8.0, sh * 0.34), Color("#0B162A"))
		draw_rect(Rect2(cx - sign_w * 0.5, base_y - sh * 0.32, sign_w, 16.0), Color(acc.r, acc.g, acc.b, 0.88))
		draw_string(fdisp, Vector2(cx - tsz.x * 0.5, base_y - sh * 0.32 + 11.5), lbl_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("#06101E"))

	func _draw_smoke_plumes(w: float, h: float, base_y: float, spread_x: float) -> void:
		var smoke: Array = owner_modal.get("_smoke")
		var t: float = _t()
		var pri: Color = _pri()
		var sec: Color = _sec()
		var acc: Color = _acc()
		for sm in smoke:
			var side: float = float(sm["side"])
			var life: float = fmod(float(sm["offset"]) + t * float(sm["speed"]), 1.0)
			var sx: float = (w * 0.5 + side * spread_x) + float(sm["drift"]) * life + sin(t * 2.2 + float(sm["offset"]) * 8.0) * 10.0 * side
			var sy: float = base_y - life * 175.0
			var rad: float = float(sm["rad"]) * (0.55 + life * 1.15)
			var alpha: float = (1.0 - life) * 0.38
			var ck: int = int(sm["col_idx"])
			var col: Color = pri if ck == 0 else (Color("#EF4444") if ck == 1 else acc.lerp(sec, 0.45))
			draw_circle(Vector2(sx, sy), rad, Color(col.r, col.g, col.b, alpha))
			# Bright flare core at base
			if life < 0.20:
				draw_circle(Vector2(w * 0.5 + side * spread_x, base_y), 7.0, Color(1.0, 0.92, 0.65, 0.80))

	func _draw_crowd_strip(x0: float, x1: float, y0: float, y1: float, rows: int, wave_flags: bool) -> void:
		var seeds: Array = owner_modal.get("_crowd_seeds")
		var t: float = _t()
		var pri: Color = _pri()
		var sec: Color = _sec()
		var acc: Color = _acc()
		var skins: Array[Color] = [Color("#F3CFAF"), Color("#DCAA84"), Color("#B9805A"), Color("#8F5A3B"), Color("#603A24")]
		for r in range(rows):
			var frac_r: float = float(r) / float(maxi(1, rows))
			var ry: float = lerpf(y0, y1, frac_r)
			var sc: float = lerpf(0.68, 1.15, frac_r)
			var cnt: int = maxi(8, int((x1 - x0) / (17.0 * sc)))
			for i in range(cnt):
				var sd: Dictionary = seeds[(r * 19 + i * 7) % seeds.size()]
				var fx: float = lerpf(x0, x1, float(i) / float(maxi(1, cnt - 1))) + float(sd["jit_x"])
				var hop: float = absf(sin(t * 5.2 + float(sd["phase"]) + float(i) * 0.4)) * 4.5 * sc
				var fy: float = ry - hop
				var ck: int = int(sd["col_kind"])
				var jersey: Color = pri if ck == 0 else (sec if ck == 1 else (pri.darkened(0.22) if ck == 2 else Color("#1E293B")))
				var skin: Color = skins[int(sd["skin"]) % skins.size()]
				# Body & raised cheering arms
				draw_rect(Rect2(fx - 4.5 * sc, fy - 10.0 * sc, 9.0 * sc, 11.0 * sc), jersey)
				draw_rect(Rect2(fx - 7.0 * sc, fy - 14.0 * sc, 2.5 * sc, 6.0 * sc), jersey)
				draw_rect(Rect2(fx + 4.5 * sc, fy - 14.0 * sc, 2.5 * sc, 6.0 * sc), jersey)
				# Head
				draw_rect(Rect2(fx - 3.0 * sc, fy - 16.0 * sc, 6.0 * sc, 6.0 * sc), skin)
				draw_rect(Rect2(fx - 3.0 * sc, fy - 17.5 * sc, 6.0 * sc, 2.2 * sc), Color("#111622"))
				# Waving team flag
				if wave_flags and bool(sd["has_flag"]) and (r % 2 == 0):
					var sw_ang: float = sin(t * 6.5 + float(sd["phase"])) * 7.0
					var pole_top := Vector2(fx + 6.0 * sc + sw_ang, fy - 34.0 * sc)
					draw_line(Vector2(fx + 5.0 * sc, fy - 10.0 * sc), pole_top, Color("#CBD5E1"), 1.6)
					var fl_pts := PackedVector2Array([
						pole_top,
						pole_top + Vector2(16.0 * sc, 2.0 + sw_ang * 0.25),
						pole_top + Vector2(14.0 * sc, 11.0 * sc + sw_ang * 0.2),
						pole_top + Vector2(0.0, 9.5 * sc),
					])
					draw_colored_polygon(fl_pts, pri if (i % 2 == 0) else acc)
					draw_rect(Rect2(pole_top.x + 2.0, pole_top.y + 3.5 * sc, 10.0 * sc, 2.5 * sc), sec)

	func _draw_cameraman(pos: Vector2, sc: float, facing_right: bool) -> void:
		var dir: float = 1.0 if facing_right else -1.0
		var t: float = _t()
		# Legs & dark broadcast jacket
		draw_rect(Rect2(pos.x - 10.0 * sc, pos.y - 26.0 * sc, 8.0 * sc, 26.0 * sc), Color("#111827"))
		draw_rect(Rect2(pos.x + 2.0 * sc, pos.y - 26.0 * sc, 8.0 * sc, 26.0 * sc), Color("#1F2937"))
		draw_rect(Rect2(pos.x - 13.0 * sc, pos.y - 54.0 * sc, 26.0 * sc, 30.0 * sc), Color("#1E293B"))
		draw_rect(Rect2(pos.x - 11.0 * sc, pos.y - 50.0 * sc, 22.0 * sc, 6.0 * sc), Color("#FACC15"))  # TV bib stripe
		# Head + headset
		draw_rect(Rect2(pos.x - 8.0 * sc, pos.y - 68.0 * sc, 16.0 * sc, 14.0 * sc), Color("#DCA680"))
		draw_rect(Rect2(pos.x - 9.0 * sc, pos.y - 71.0 * sc, 18.0 * sc, 5.0 * sc), Color("#0F172A"))
		# Shoulder TV broadcast camera + matte box lens + blinking REC LED
		var cam_x: float = pos.x + dir * 2.0 * sc - (14.0 * sc if facing_right else 20.0 * sc)
		draw_rect(Rect2(cam_x, pos.y - 66.0 * sc, 32.0 * sc, 14.0 * sc), Color("#0B1120"))
		draw_rect(Rect2(cam_x + (30.0 * sc if facing_right else -10.0 * sc), pos.y - 64.0 * sc, 10.0 * sc, 10.0 * sc), Color("#334155"))
		if sin(t * 7.5) > 0.0:
			draw_circle(Vector2(cam_x + (24.0 * sc if facing_right else 6.0 * sc), pos.y - 62.0 * sc), 2.8 * sc, Color("#EF4444"))

	func _draw_steward(pos: Vector2, sc: float) -> void:
		draw_rect(Rect2(pos.x - 7.0 * sc, pos.y - 22.0 * sc, 6.0 * sc, 22.0 * sc), Color("#0F172A"))
		draw_rect(Rect2(pos.x + 1.0 * sc, pos.y - 22.0 * sc, 6.0 * sc, 22.0 * sc), Color("#1E293B"))
		# Hi-vis yellow steward vest with silver reflective stripes
		draw_rect(Rect2(pos.x - 10.0 * sc, pos.y - 46.0 * sc, 20.0 * sc, 25.0 * sc), Color("#EAB308"))
		draw_rect(Rect2(pos.x - 10.0 * sc, pos.y - 34.0 * sc, 20.0 * sc, 3.0 * sc), Color("#F8FAFC"))
		draw_rect(Rect2(pos.x - 10.0 * sc, pos.y - 28.0 * sc, 20.0 * sc, 3.0 * sc), Color("#F8FAFC"))
		draw_rect(Rect2(pos.x - 6.0 * sc, pos.y - 58.0 * sc, 12.0 * sc, 12.0 * sc), Color("#D8A17C"))
		draw_rect(Rect2(pos.x - 7.0 * sc, pos.y - 61.0 * sc, 14.0 * sc, 4.0 * sc), Color("#111827"))

	func _draw_championship_trophy(center: Vector2, sc: float) -> void:
		var style: String = str(_ctx().get("trophy_style", "BIG_EARS"))
		var t: float = _t()
		var glow_r: float = (30.0 + sin(t * 5.0) * 4.0) * sc
		var is_gold: bool = style in ["WORLD_CUP", "CONFED_GOLD", "EUROPA_CUP"]
		var metal_main: Color = Color("#F5C430") if is_gold else Color("#E2E8F0")
		var metal_hi: Color = Color("#FEF08A") if is_gold else Color("#FFFFFF")
		var metal_sh: Color = Color("#B45309") if is_gold else Color("#94A3B8")
		var base_col: Color = Color("#1E293B") if not is_gold else Color("#14532D")
		var halo: Color = Color(1.0, 0.85, 0.25, 0.24) if is_gold else Color(0.75, 0.90, 1.0, 0.24)
		draw_circle(center, glow_r, halo)

		if style == "WORLD_CUP":
			# Iconic Golden Globe World Cup silhouette
			draw_circle(center + Vector2(0, -14.0 * sc), 12.0 * sc, metal_main)
			draw_circle(center + Vector2(-3.0 * sc, -17.0 * sc), 4.5 * sc, metal_hi)
			var stem := PackedVector2Array([
				center + Vector2(-8.0 * sc, -5.0 * sc),
				center + Vector2(8.0 * sc, -5.0 * sc),
				center + Vector2(11.0 * sc, 14.0 * sc),
				center + Vector2(-11.0 * sc, 14.0 * sc),
			])
			draw_colored_polygon(stem, metal_main)
			draw_rect(Rect2(center.x - 13.0 * sc, center.y + 14.0 * sc, 26.0 * sc, 6.0 * sc), base_col)
			draw_rect(Rect2(center.x - 14.0 * sc, center.y + 20.0 * sc, 28.0 * sc, 4.0 * sc), metal_sh)
		else:
			# Iconic Big-Eared Championship Cup (Video 2 / Video 3 / Video 4!)
			# Big curved ears/handles
			draw_arc(center + Vector2(-14.0 * sc, -9.0 * sc), 9.5 * sc, PI * 0.45, PI * 1.55, 14, metal_main, 3.6 * sc)
			draw_arc(center + Vector2(14.0 * sc, -9.0 * sc), 9.5 * sc, -PI * 0.55, PI * 0.55, 14, metal_main, 3.6 * sc)
			# Cup body
			var cup := PackedVector2Array([
				center + Vector2(-15.0 * sc, -22.0 * sc),
				center + Vector2(15.0 * sc, -22.0 * sc),
				center + Vector2(10.0 * sc, 4.0 * sc),
				center + Vector2(-10.0 * sc, 4.0 * sc),
			])
			draw_colored_polygon(cup, metal_main)
			draw_rect(Rect2(center.x - 10.0 * sc, center.y - 20.0 * sc, 5.5 * sc, 21.0 * sc), metal_hi)
			draw_rect(Rect2(center.x + 4.0 * sc, center.y - 20.0 * sc, 4.5 * sc, 21.0 * sc), metal_sh)
			# Team ribbons tied to handles!
			draw_line(center + Vector2(-16.0 * sc, -2.0 * sc), center + Vector2(-20.0 * sc + sin(t * 7.0) * 3.0, 12.0 * sc), _pri(), 2.4 * sc)
			draw_line(center + Vector2(16.0 * sc, -2.0 * sc), center + Vector2(20.0 * sc - sin(t * 7.0) * 3.0, 12.0 * sc), _sec(), 2.4 * sc)
			# Stem & pedestal
			draw_rect(Rect2(center.x - 4.0 * sc, center.y + 4.0 * sc, 8.0 * sc, 10.0 * sc), metal_sh)
			draw_rect(Rect2(center.x - 13.0 * sc, center.y + 14.0 * sc, 26.0 * sc, 5.0 * sc), metal_main)
			draw_rect(Rect2(center.x - 15.0 * sc, center.y + 19.0 * sc, 30.0 * sc, 5.0 * sc), base_col)

		# Twinkling 4-point star sparkles around the trophy!
		for si in range(3):
			var sp_p: float = absf(sin(t * 4.5 + float(si) * 2.1))
			if sp_p > 0.45:
				var sp_pos: Vector2 = center + Vector2(-18.0 + float(si) * 18.0, -24.0 + float(si % 2) * 14.0) * sc
				var sr: float = (4.0 + sp_p * 5.0) * sc
				draw_line(sp_pos - Vector2(sr, 0), sp_pos + Vector2(sr, 0), Color("#FFFFFF"), 1.6)
				draw_line(sp_pos - Vector2(0, sr), sp_pos + Vector2(0, sr), Color("#FFFFFF"), 1.6)

	func _draw_police_car(cx: float, cy: float, sc: float, flash_phase: float) -> void:
		var t: float = _t()
		var red_on: bool = sin(t * 16.0 + flash_phase) > 0.0
		# Ground shadow & bright headlight cones
		draw_rect(Rect2(cx - 42.0 * sc, cy + 16.0 * sc, 84.0 * sc, 12.0 * sc), Color(0, 0, 0, 0.45))
		var cone_l := PackedVector2Array([
			Vector2(cx - 28.0 * sc, cy + 12.0 * sc), Vector2(cx - 16.0 * sc, cy + 12.0 * sc),
			Vector2(cx - 10.0 * sc, cy + 90.0 * sc), Vector2(cx - 48.0 * sc, cy + 90.0 * sc),
		])
		var cone_r := PackedVector2Array([
			Vector2(cx + 16.0 * sc, cy + 12.0 * sc), Vector2(cx + 28.0 * sc, cy + 12.0 * sc),
			Vector2(cx + 48.0 * sc, cy + 90.0 * sc), Vector2(cx + 10.0 * sc, cy + 90.0 * sc),
		])
		draw_colored_polygon(cone_l, Color(1.0, 0.96, 0.78, 0.22))
		draw_colored_polygon(cone_r, Color(1.0, 0.96, 0.78, 0.22))
		# Tires
		draw_rect(Rect2(cx - 38.0 * sc, cy + 6.0 * sc, 13.0 * sc, 16.0 * sc), Color("#090D16"))
		draw_rect(Rect2(cx + 25.0 * sc, cy + 6.0 * sc, 13.0 * sc, 16.0 * sc), Color("#090D16"))
		# White & navy police body
		draw_rect(Rect2(cx - 38.0 * sc, cy - 10.0 * sc, 76.0 * sc, 24.0 * sc), Color("#E2E8F0"))
		draw_rect(Rect2(cx - 38.0 * sc, cy + 4.0 * sc, 76.0 * sc, 10.0 * sc), Color("#1E3A8A"))
		# Hood + cabin roof + windshield
		var cabin := PackedVector2Array([
			Vector2(cx - 30.0 * sc, cy - 10.0 * sc),
			Vector2(cx - 22.0 * sc, cy - 28.0 * sc),
			Vector2(cx + 22.0 * sc, cy - 28.0 * sc),
			Vector2(cx + 30.0 * sc, cy - 10.0 * sc),
		])
		draw_colored_polygon(cabin, Color("#F8FAFC"))
		var wind := PackedVector2Array([
			Vector2(cx - 24.0 * sc, cy - 12.0 * sc),
			Vector2(cx - 18.0 * sc, cy - 24.0 * sc),
			Vector2(cx + 18.0 * sc, cy - 24.0 * sc),
			Vector2(cx + 24.0 * sc, cy - 12.0 * sc),
		])
		draw_colored_polygon(wind, Color("#0F1D36"))
		# Front grille & glowing headlights
		draw_rect(Rect2(cx - 14.0 * sc, cy - 1.0 * sc, 28.0 * sc, 9.0 * sc), Color("#0F172A"))
		draw_rect(Rect2(cx - 34.0 * sc, cy - 3.0 * sc, 13.0 * sc, 7.0 * sc), Color("#FEF9C3"))
		draw_rect(Rect2(cx + 21.0 * sc, cy - 3.0 * sc, 13.0 * sc, 7.0 * sc), Color("#FEF9C3"))
		# Flashing RED & BLUE Siren Lightbar + bright glowing halos!
		draw_rect(Rect2(cx - 16.0 * sc, cy - 34.0 * sc, 32.0 * sc, 6.0 * sc), Color("#1E293B"))
		var col_l: Color = Color("#EF4444") if red_on else Color("#7F1D1D")
		var col_r: Color = Color("#1D4ED8") if red_on else Color("#38BDF8")
		draw_rect(Rect2(cx - 15.0 * sc, cy - 34.0 * sc, 14.0 * sc, 6.0 * sc), col_l)
		draw_rect(Rect2(cx + 1.0 * sc, cy - 34.0 * sc, 14.0 * sc, 6.0 * sc), col_r)
		if red_on:
			draw_circle(Vector2(cx - 9.0 * sc, cy - 31.0 * sc), 24.0 * sc, Color(1.0, 0.22, 0.22, 0.34))
			draw_circle(Vector2(cx - 9.0 * sc, cy - 31.0 * sc), 10.0 * sc, Color(1.0, 0.65, 0.65, 0.55))
		else:
			draw_circle(Vector2(cx + 9.0 * sc, cy - 31.0 * sc), 24.0 * sc, Color(0.20, 0.72, 1.0, 0.34))
			draw_circle(Vector2(cx + 9.0 * sc, cy - 31.0 * sc), 10.0 * sc, Color(0.75, 0.94, 1.0, 0.55))

	func _draw_team_bus_front(cx: float, cy: float, sc: float, show_marquee: bool) -> void:
		var pri: Color = _pri()
		var sec: Color = _sec()
		var acc: Color = _acc()
		var t: float = _t()
		var bounce: float = sin(t * 14.0) * 1.4 * sc
		var by: float = cy + bounce
		# Ground shadow & bright headlight beams
		draw_rect(Rect2(cx - 72.0 * sc, cy + 48.0 * sc, 144.0 * sc, 18.0 * sc), Color(0, 0, 0, 0.50))
		for side in [-1.0, 1.0]:
			var h_cone := PackedVector2Array([
				Vector2(cx + side * 44.0 * sc, by + 34.0 * sc),
				Vector2(cx + side * 62.0 * sc, by + 34.0 * sc),
				Vector2(cx + side * 110.0 * sc, by + 135.0 * sc),
				Vector2(cx + side * 18.0 * sc, by + 135.0 * sc),
			])
			draw_colored_polygon(h_cone, Color(1.0, 0.96, 0.80, 0.18))
		# Side mirrors
		draw_rect(Rect2(cx - 82.0 * sc, by - 28.0 * sc, 10.0 * sc, 24.0 * sc), Color("#1E293B"))
		draw_rect(Rect2(cx + 72.0 * sc, by - 28.0 * sc, 10.0 * sc, 24.0 * sc), Color("#1E293B"))
		# Wheels
		draw_rect(Rect2(cx - 66.0 * sc, by + 32.0 * sc, 22.0 * sc, 26.0 * sc), Color("#090D16"))
		draw_rect(Rect2(cx + 44.0 * sc, by + 32.0 * sc, 22.0 * sc, 26.0 * sc), Color("#090D16"))
		# Main Tall Bus Chassis in Team Colors
		draw_rect(Rect2(cx - 70.0 * sc, by - 76.0 * sc, 140.0 * sc, 120.0 * sc), pri)
		draw_rect(Rect2(cx - 66.0 * sc, by - 82.0 * sc, 132.0 * sc, 8.0 * sc), pri.lightened(0.14))
		# Diagonal/horizontal secondary livery stripes
		draw_rect(Rect2(cx - 70.0 * sc, by + 12.0 * sc, 140.0 * sc, 8.0 * sc), sec)
		draw_rect(Rect2(cx - 70.0 * sc, by + 22.0 * sc, 140.0 * sc, 4.0 * sc), acc)
		# Dark panoramic windshield with reflection streaks
		draw_rect(Rect2(cx - 62.0 * sc, by - 54.0 * sc, 124.0 * sc, 54.0 * sc), Color("#0B162C"))
		draw_line(Vector2(cx - 50.0 * sc, by - 50.0 * sc), Vector2(cx - 32.0 * sc, by - 4.0 * sc), Color(0.65, 0.86, 1.0, 0.18), 6.0 * sc)
		draw_line(Vector2(cx + 12.0 * sc, by - 50.0 * sc), Vector2(cx + 28.0 * sc, by - 4.0 * sc), Color(0.65, 0.86, 1.0, 0.14), 4.0 * sc)
		# Top LED Destination Marquee (<TEAM_NAME> • FINAL)
		draw_rect(Rect2(cx - 54.0 * sc, by - 71.0 * sc, 108.0 * sc, 14.0 * sc), Color("#080E1A"))
		if show_marquee:
			var fdisp: Font = UITheme.get_display_font()
			var m_txt: String = "%s • FINAL" % str(_ctx().get("team_code", "ELB"))
			var fsz: int = clampi(int(round(10.0 * sc)), 8, 18)
			var m_sz: Vector2 = fdisp.get_string_size(m_txt, HORIZONTAL_ALIGNMENT_CENTER, -1, fsz)
			draw_string(fdisp, Vector2(cx - m_sz.x * 0.5, by - 60.5 * sc), m_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, Color("#FACC15"))
		# Nose emblem plate + grille + bumper + bright headlights
		draw_rect(Rect2(cx - 22.0 * sc, by + 2.0 * sc, 44.0 * sc, 9.0 * sc), Color("#0F172A"))
		draw_circle(Vector2(cx, by + 16.0 * sc), 9.0 * sc, sec)
		draw_circle(Vector2(cx, by + 16.0 * sc), 6.5 * sc, pri.darkened(0.15))
		draw_rect(Rect2(cx - 64.0 * sc, by + 28.0 * sc, 22.0 * sc, 10.0 * sc), Color("#FEF9C3"))
		draw_rect(Rect2(cx + 42.0 * sc, by + 28.0 * sc, 22.0 * sc, 10.0 * sc), Color("#FEF9C3"))
		draw_circle(Vector2(cx - 53.0 * sc, by + 33.0 * sc), 16.0 * sc, Color(1.0, 0.96, 0.72, 0.35))
		draw_circle(Vector2(cx + 53.0 * sc, by + 33.0 * sc), 16.0 * sc, Color(1.0, 0.96, 0.72, 0.35))
		draw_rect(Rect2(cx - 72.0 * sc, by + 40.0 * sc, 144.0 * sc, 8.0 * sc), Color("#1E293B"))

	# --------------------------------------------------------------------------
	# VIDEO 1: PRE-MATCH FINAL ENTRANCE (4 SHOTS)
	# --------------------------------------------------------------------------
	func _draw_pre_shot0_avenue_bus(w: float, h: float) -> void:
		var t: float = _t()
		var st: float = _st()
		var p: float = clampf(st / 2.6, 0.0, 1.0)
		var pri: Color = _pri()
		var sec: Color = _sec()
		var acc: Color = _acc()
		var hor_y: float = h * 0.42

		# Night sky + stadium horizon
		_draw_vertical_gradient(w, 0.0, hor_y, Color("#060D1E"), Color("#162849"), 10)
		_draw_stadium_silhouette(w * 0.5, hor_y + 12.0, 440.0, 128.0, acc, str(_ctx().get("stadium_name", "ARENA FINAL")))

		# Wide avenue sidewalks & perspective boulevard narrowing toward stadium
		draw_rect(Rect2(0.0, hor_y, w, h - hor_y), Color("#1A2233"))
		var road := PackedVector2Array([
			Vector2(w * 0.40, hor_y), Vector2(w * 0.60, hor_y),
			Vector2(w * 0.80, h), Vector2(w * 0.20, h),
		])
		draw_colored_polygon(road, Color("#111722"))
		draw_line(Vector2(w * 0.40, hor_y), Vector2(w * 0.20, h), Color("#64748B"), 3.0)
		draw_line(Vector2(w * 0.60, hor_y), Vector2(w * 0.80, h), Color("#64748B"), 3.0)
		# Scrolling dashed road markings
		for di in range(8):
			var frac: float = fmod(float(di) / 8.0 + t * 0.55, 1.0)
			var ry: float = lerpf(hor_y + 8.0, h, frac * frac)
			var dash_h: float = lerpf(4.0, 22.0, frac)
			draw_rect(Rect2(w * 0.5 - 2.5, ry, 5.0, dash_h), Color("#CBD5E1"))

		# Cheering fans & waving flags packed densely along BOTH sidewalks!
		_draw_crowd_strip(14.0, w * 0.34, hor_y + 14.0, h - 14.0, 7, true)
		_draw_crowd_strip(w * 0.66, w - 14.0, hor_y + 14.0, h - 14.0, 7, true)

		# Overhead Team Bus (rear 3/4 view) rolling up the boulevard toward the Final Stadium!
		var bus_y: float = lerpf(h * 0.78, h * 0.52, p)
		var bsc: float = lerpf(1.22, 0.68, p)
		var cx: float = w * 0.5
		# Shadow & glowing red tail lights
		draw_rect(Rect2(cx - 56.0 * bsc, bus_y - 68.0 * bsc, 112.0 * bsc, 148.0 * bsc), Color(0, 0, 0, 0.36))
		# Roof top panel
		draw_rect(Rect2(cx - 50.0 * bsc, bus_y - 72.0 * bsc, 100.0 * bsc, 118.0 * bsc), pri.lightened(0.10))
		draw_rect(Rect2(cx - 42.0 * bsc, bus_y - 66.0 * bsc, 84.0 * bsc, 106.0 * bsc), pri)
		# Roof team stripe & AC pods
		draw_rect(Rect2(cx - 10.0 * bsc, bus_y - 68.0 * bsc, 20.0 * bsc, 112.0 * bsc), sec)
		draw_rect(Rect2(cx - 26.0 * bsc, bus_y - 44.0 * bsc, 52.0 * bsc, 20.0 * bsc), Color("#E2E8F0"))
		draw_rect(Rect2(cx - 22.0 * bsc, bus_y - 6.0 * bsc, 44.0 * bsc, 16.0 * bsc), Color("#CBD5E1"))
		# Rear vertical face & glowing red taillights
		draw_rect(Rect2(cx - 50.0 * bsc, bus_y + 44.0 * bsc, 100.0 * bsc, 34.0 * bsc), pri.darkened(0.18))
		draw_rect(Rect2(cx - 42.0 * bsc, bus_y + 48.0 * bsc, 84.0 * bsc, 16.0 * bsc), Color("#0B162C"))
		draw_rect(Rect2(cx - 46.0 * bsc, bus_y + 66.0 * bsc, 18.0 * bsc, 6.0 * bsc), Color("#EF4444"))
		draw_rect(Rect2(cx + 28.0 * bsc, bus_y + 66.0 * bsc, 18.0 * bsc, 6.0 * bsc), Color("#EF4444"))
		draw_circle(Vector2(cx - 37.0 * bsc, bus_y + 69.0 * bsc), 14.0 * bsc, Color(1.0, 0.20, 0.20, 0.30))
		draw_circle(Vector2(cx + 37.0 * bsc, bus_y + 69.0 * bsc), 14.0 * bsc, Color(1.0, 0.20, 0.20, 0.30))

		# Rising smoke flares from both supporter flanks + drifting confetti!
		_draw_smoke_plumes(w, h, h * 0.72, 235.0)
		_draw_confetti_layer(0.85)

	func _draw_pre_shot1_police_convoy(w: float, h: float) -> void:
		var st: float = _st()
		var p: float = clampf(st / 2.6, 0.0, 1.0)
		var acc: Color = _acc()
		var hor_y: float = h * 0.36

		_draw_vertical_gradient(w, 0.0, hor_y, Color("#070E20"), Color("#162848"), 10)
		_draw_stadium_silhouette(w * 0.5, hor_y + 10.0, 380.0, 108.0, acc, str(_ctx().get("stadium_name", "ARENA FINAL")))

		# Boulevard corridor
		draw_rect(Rect2(0.0, hor_y, w, h - hor_y), Color("#1A2334"))
		var road := PackedVector2Array([
			Vector2(w * 0.34, hor_y), Vector2(w * 0.66, hor_y),
			Vector2(w * 0.88, h), Vector2(w * 0.12, h),
		])
		draw_colored_polygon(road, Color("#111724"))

		# Packed fans behind steel barricades + hi-vis stewards on both sides!
		_draw_crowd_strip(10.0, w * 0.25, hor_y + 14.0, h - 16.0, 6, true)
		_draw_crowd_strip(w * 0.75, w - 10.0, hor_y + 14.0, h - 16.0, 6, true)
		# Steel barricades
		draw_line(Vector2(w * 0.32, hor_y + 10.0), Vector2(w * 0.14, h), Color("#94A3B8"), 4.0)
		draw_line(Vector2(w * 0.68, hor_y + 10.0), Vector2(w * 0.86, h), Color("#94A3B8"), 4.0)
		for si in range(3):
			var sf: float = 0.25 + float(si) * 0.30
			var sy: float = lerpf(hor_y + 30.0, h - 20.0, sf)
			var ssc: float = lerpf(0.65, 1.05, sf)
			_draw_steward(Vector2(lerpf(w * 0.31, w * 0.15, sf), sy), ssc)
			_draw_steward(Vector2(lerpf(w * 0.69, w * 0.85, sf), sy), ssc)

		# Club Team Bus advancing behind the 2 police cars
		var bus_sc: float = lerpf(0.76, 1.08, p)
		var bus_y: float = lerpf(h * 0.50, h * 0.58, p)
		_draw_team_bus_front(w * 0.5, bus_y, bus_sc, true)

		# 2 Police Escort Cars side-by-side leading the convoy with flashing red/blue sirens!
		var pol_sc: float = lerpf(0.78, 1.24, p)
		var pol_y: float = lerpf(h * 0.64, h * 0.79, p)
		var sep_x: float = lerpf(92.0, 146.0, p)
		_draw_police_car(w * 0.5 - sep_x, pol_y, pol_sc, 0.0)
		_draw_police_car(w * 0.5 + sep_x, pol_y, pol_sc, PI)

		_draw_smoke_plumes(w, h, h * 0.66, 300.0)
		_draw_confetti_layer(0.70)

	func _draw_pre_shot2_bus_closeup(w: float, h: float) -> void:
		var st: float = _st()
		var p: float = clampf(st / 2.2, 0.0, 1.0)
		var acc: Color = _acc()
		var t: float = _t()

		# Dramatic low-angle twilight/night sky with stadium towers & booming fireworks behind
		_draw_vertical_gradient(w, 0.0, h * 0.56, Color("#050A18"), Color("#182C52"), 10)
		# Sky firework bursts behind the bus
		for fi in range(3):
			var fx: float = w * (0.20 + float(fi) * 0.30)
			var fy: float = h * (0.18 + float(fi % 2) * 0.10)
			var fp: float = fmod(t * 0.95 + float(fi) * 0.33, 1.0)
			var rad: float = fp * 72.0
			var fa: float = maxf(0.0, 1.0 - fp) * 0.80
			for sp in range(14):
				var ang: float = float(sp) * TAU / 14.0
				draw_circle(Vector2(fx + cos(ang) * rad, fy + sin(ang) * rad), 2.8, Color(1.0, 0.88, 0.32, fa))
		_draw_stadium_silhouette(w * 0.5, h * 0.56, 620.0, 165.0, acc, str(_ctx().get("stadium_name", "ARENA FINAL")))

		# Asphalt foreground
		draw_rect(Rect2(0.0, h * 0.56, w, h * 0.44), Color("#0E1522"))
		_draw_crowd_strip(0.0, w * 0.22, h * 0.52, h - 10.0, 3, true)
		_draw_crowd_strip(w * 0.78, w, h * 0.52, h - 10.0, 3, true)

		# Heroic Low-Angle Front Close-Up of the Team Bus rolling right toward camera!
		var sc: float = lerpf(1.65, 2.25, p)
		var by: float = lerpf(h * 0.64, h * 0.72, p)
		_draw_team_bus_front(w * 0.5, by, sc, true)
		_draw_smoke_plumes(w, h, h * 0.78, 325.0)
		_draw_confetti_layer(0.90)

	func _draw_pre_shot3_stadium_gate(w: float, h: float) -> void:
		var acc: Color = _acc()
		var pri: Color = _pri()
		var sec: Color = _sec()
		var hor_y: float = h * 0.52

		# Illuminated Night Final Stadium Exterior Plaza
		_draw_vertical_gradient(w, 0.0, hor_y, Color("#060D1F"), Color("#152A4C"), 10)
		# Stadium facade filling upper backdrop
		draw_rect(Rect2(60.0, 68.0, w - 120.0, hor_y - 68.0), Color("#13223A"))
		draw_rect(Rect2(60.0, 68.0, w - 120.0, 12.0), acc)
		# Vertical stadium facade ribs & warm interior windows
		for ri in range(14):
			var rx: float = 82.0 + float(ri) * ((w - 164.0) / 13.0)
			draw_rect(Rect2(rx - 4.0, 80.0, 8.0, hor_y - 80.0), Color("#1E3354"))
			draw_rect(Rect2(rx + 12.0, 108.0, 34.0, 72.0), Color(acc.r, acc.g, acc.b, 0.22))

		# Grand Central Stadium Entrance Arch & Glowing Tunnel
		var gx: float = w * 0.46
		draw_rect(Rect2(gx - 128.0, 114.0, 256.0, hor_y - 114.0), Color("#0A1324"))
		draw_rect(Rect2(gx - 134.0, 106.0, 268.0, 26.0), pri)
		draw_rect(Rect2(gx - 134.0, 130.0, 268.0, 4.0), Color("#FACC15"))
		var fdisp: Font = UITheme.get_display_font()
		var gate_txt: String = str(_ctx().get("stadium_name", "STADION FINAL"))
		var gsz: Vector2 = fdisp.get_string_size(gate_txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 13)
		draw_string(fdisp, Vector2(gx - gsz.x * 0.5, 124.0), gate_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, sec)
		# Bright illuminated stadium pitch tunnel glow inside doorway
		draw_rect(Rect2(gx - 92.0, 152.0, 184.0, hor_y - 152.0), Color(0.82, 0.94, 1.0, 0.26))
		draw_rect(Rect2(gx - 72.0, 168.0, 144.0, hor_y - 168.0), Color(0.95, 0.98, 1.0, 0.35))

		# Plaza concrete floor & Red-Carpet Entrance Walkway
		draw_rect(Rect2(0.0, hor_y, w, h - hor_y), Color("#182132"))
		var carpet := PackedVector2Array([
			Vector2(gx - 88.0, hor_y), Vector2(gx + 88.0, hor_y),
			Vector2(gx + 150.0, h), Vector2(gx - 150.0, h),
		])
		draw_colored_polygon(carpet, Color("#991B1B"))
		draw_line(Vector2(gx - 88.0, hor_y), Vector2(gx - 150.0, h), Color("#FACC15"), 3.0)
		draw_line(Vector2(gx + 88.0, hor_y), Vector2(gx + 150.0, h), Color("#FACC15"), 3.0)

		# Cheering crowd behind left/right barricades + yellow-vest stewards
		_draw_crowd_strip(10.0, gx - 160.0, hor_y + 10.0, h - 25.0, 4, true)
		_draw_crowd_strip(gx + 165.0, w - 10.0, hor_y + 10.0, h - 25.0, 4, true)
		_draw_steward(Vector2(gx - 122.0, hor_y + 62.0), 0.92)
		_draw_steward(Vector2(gx + 128.0, hor_y + 62.0), 0.92)

	# --------------------------------------------------------------------------
	# VIDEO 2 (ACT 0): PITCH CHAMPIONSHIP PODIUM LIFT
	# --------------------------------------------------------------------------
	func _draw_act0_podium_lift(w: float, h: float) -> void:
		var t: float = _t()
		var pri: Color = _pri()
		var sec: Color = _sec()
		var acc: Color = _acc()
		var stand_top: float = h * 0.14
		var pitch_y: float = h * 0.56

		# Night stadium roof & sky
		_draw_vertical_gradient(w, 0.0, stand_top + 28.0, Color("#040812"), Color("#0B162C"), 6)
		# Stadium roof floodlight banks
		for fi in range(6):
			var fx: float = 80.0 + float(fi) * ((w - 160.0) / 5.0)
			draw_rect(Rect2(fx - 26.0, 14.0, 52.0, 10.0), Color("#F8FAFC"))
			draw_circle(Vector2(fx, 20.0), 28.0, Color(0.85, 0.94, 1.0, 0.22))

		# Packed double-tier stadium stands with camera flashes
		draw_rect(Rect2(0.0, stand_top, w, pitch_y - stand_top), Color("#0C1629"))
		draw_rect(Rect2(0.0, stand_top + (pitch_y - stand_top) * 0.48, w, 8.0), Color("#1E3354"))
		_draw_crowd_strip(8.0, w - 8.0, stand_top + 18.0, pitch_y - 26.0, 5, true)
		# Camera flash pops in the stands
		for fl_i in range(10):
			var fp: float = fmod(t * 2.4 + float(fl_i) * 0.71, 1.0)
			if fp < 0.12:
				var flx: float = fmod(float(fl_i) * 113.0 + 47.0, w - 40.0) + 20.0
				var fly: float = stand_top + 24.0 + fmod(float(fl_i) * 67.0, pitch_y - stand_top - 48.0)
				draw_circle(Vector2(flx, fly), 9.0, Color(1.0, 1.0, 1.0, 0.85))

		# Glowing perimeter LED boards at pitch edge
		draw_rect(Rect2(0.0, pitch_y - 18.0, w, 18.0), Color("#091426"))
		draw_rect(Rect2(0.0, pitch_y - 16.0, w, 14.0), Color(acc.r, acc.g, acc.b, 0.82))

		# Night-lit striped emerald football pitch
		var stripe_cnt: int = 10
		var sw: float = w / float(stripe_cnt)
		for si in range(stripe_cnt):
			var sc_col: Color = Color("#165A32") if (si % 2 == 0) else Color("#1B6B3B")
			draw_rect(Rect2(float(si) * sw, pitch_y, sw + 1.0, h - pitch_y), sc_col)
		# Crisp pitch lines
		draw_line(Vector2(0.0, pitch_y + 10.0), Vector2(w, pitch_y + 10.0), Color(1, 1, 1, 0.35), 2.0)

		# ICONIC VIDEO 2 SWEEPING VERTICAL BLUE / CYAN / GOLD STADIUM SPOTLIGHTS!
		for bi in range(6):
			var bx_top: float = w * (0.08 + float(bi) * 0.168)
			var sweep: float = sin(t * 1.45 + float(bi) * 1.15) * 115.0
			var bx_bot: float = bx_top + sweep
			var beam_col: Color = Color(0.22, 0.74, 1.0, 0.14) if (bi % 2 == 0) else Color(0.98, 0.82, 0.24, 0.11)
			var poly := PackedVector2Array([
				Vector2(bx_top - 16.0, 18.0),
				Vector2(bx_top + 16.0, 18.0),
				Vector2(bx_bot + 72.0, h),
				Vector2(bx_bot - 72.0, h),
			])
			draw_colored_polygon(poly, beam_col)

		# CENTER CHAMPIONSHIP PODIUM & BACKLIT ARCH BACKDROP
		var pcx: float = w * 0.50
		var deck_y: float = h * 0.645
		var p_half: float = 258.0
		# Backlit trophy arch wall behind players (tall enough so header text sits proudly ABOVE the lifted trophy!)
		draw_rect(Rect2(pcx - p_half + 16.0, deck_y - 208.0, (p_half - 16.0) * 2.0, 208.0), Color("#081224"))
		draw_rect(Rect2(pcx - p_half + 16.0, deck_y - 208.0, (p_half - 16.0) * 2.0, 28.0), pri)
		draw_rect(Rect2(pcx - p_half + 16.0, deck_y - 180.0, (p_half - 16.0) * 2.0, 4.0), Color("#FACC15"))
		var fdisp: Font = UITheme.get_display_font()
		var arch_txt: String = "JUARA %s  •  %d" % [str(_ctx().get("comp_title", "PIALA ELITE")), int(_ctx().get("year", 2026))]
		var asz: Vector2 = fdisp.get_string_size(arch_txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 13)
		draw_string(fdisp, Vector2(pcx - asz.x * 0.5, deck_y - 189.0), arch_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, sec)
		# Repeating illuminated sponsor/club medallions on podium backdrop
		for mi in range(7):
			var mx: float = pcx - 195.0 + float(mi) * 65.0
			draw_circle(Vector2(mx, deck_y - 98.0), 14.0, Color(acc.r, acc.g, acc.b, 0.25))
			draw_arc(Vector2(mx, deck_y - 98.0), 14.0, 0.0, TAU, 18, Color("#FACC15"), 1.5)

		# 2 Angled Pyro / Firework Spark Cannons flanking podium left & right!
		var sparks: Array = owner_modal.get("_sparks")
		for side in [-1.0, 1.0]:
			var can_base := Vector2(pcx + side * (p_half + 14.0), deck_y + 18.0)
			var can_tip := can_base + Vector2(side * 16.0, -24.0)
			draw_line(can_base, can_tip, Color("#334155"), 8.0)
			draw_circle(can_tip, 9.0, Color(1.0, 0.88, 0.35, 0.65))
		for sp in sparks:
			var side: float = float(sp["side"])
			var life: float = fmod(float(sp["life"]) + t * float(sp["spd"]), 1.0)
			var origin := Vector2(pcx + side * (p_half + 30.0), deck_y - 6.0)
			var base_ang: float = (-PI * 0.34 if side > 0.0 else -PI * 0.66) + float(sp["ang_off"])
			var dist: float = float(sp["dist"]) * life
			var grav: float = 92.0 * life * life
			var sx: float = origin.x + cos(base_ang) * dist
			var sy: float = origin.y + sin(base_ang) * dist + grav
			var fa: float = maxf(0.0, 1.0 - life)
			var scol: Color = Color(1.0, 0.94, 0.45, fa) if life < 0.5 else Color(1.0, 0.58, 0.16, fa)
			draw_circle(Vector2(sx, sy), float(sp["sz"]), scol)

		# Raised Black Metallic Podium Deck + Front Illuminated Steps
		draw_rect(Rect2(pcx - p_half, deck_y, p_half * 2.0, 52.0), Color("#0B111E"))
		draw_rect(Rect2(pcx - p_half, deck_y, p_half * 2.0, 6.0), acc)
		draw_rect(Rect2(pcx - p_half, deck_y + 46.0, p_half * 2.0, 6.0), Color("#FACC15"))
		# Center champion plinth (slightly elevated under user)
		draw_rect(Rect2(pcx - 42.0, deck_y - 12.0, 84.0, 14.0), Color("#1E293B"))
		draw_rect(Rect2(pcx - 42.0, deck_y - 12.0, 84.0, 3.0), Color("#FACC15"))
		# 4 Front Stairs
		for st_i in range(4):
			var stw: float = 112.0 + float(st_i) * 14.0
			var sty: float = deck_y + 14.0 + float(st_i) * 11.0
			draw_rect(Rect2(pcx - stw * 0.5, sty, stw, 9.0), Color("#1F2937") if (st_i % 2 == 0) else Color("#334155"))
			draw_rect(Rect2(pcx - stw * 0.5, sty, stw, 2.0), Color(acc.r, acc.g, acc.b, 0.7))

	# --------------------------------------------------------------------------
	# VIDEO 3 (ACT 1): PUTARAN HORMAT (TOUCHLINE WALK & TROPHY LIFT)
	# --------------------------------------------------------------------------
	func _draw_act1_lap_of_honour(w: float, h: float) -> void:
		var t: float = _t()
		var st: float = _st()
		var acc: Color = _acc()
		var led_y: float = h * 0.49
		var led_h: float = 34.0
		var pitch_y: float = led_y + led_h

		# Packed cheering stadium stands filling upper half
		_draw_vertical_gradient(w, 0.0, led_y, Color("#060D1E"), Color("#11213D"), 8)
		_draw_crowd_strip(6.0, w - 6.0, 32.0, led_y - 10.0, 6, true)

		# Bright Camera Flash pops across stands
		for fl_i in range(8):
			var fp: float = fmod(t * 2.0 + float(fl_i) * 0.83, 1.0)
			if fp < 0.13:
				draw_circle(Vector2(fmod(float(fl_i) * 137.0 + 40.0, w - 60.0) + 30.0, 42.0 + fmod(float(fl_i) * 53.0, led_y - 68.0)), 10.0, Color(1, 1, 1, 0.82))

		# Glowing Scrolling LED Advertising Boards along touchline (Video 3 signature!)
		draw_rect(Rect2(0.0, led_y, w, led_h), Color("#071122"))
		draw_rect(Rect2(0.0, led_y + 3.0, w, led_h - 6.0), acc.darkened(0.18))
		draw_rect(Rect2(0.0, led_y + 2.0, w, 2.5), Color("#FACC15"))
		draw_rect(Rect2(0.0, led_y + led_h - 4.0, w, 2.5), Color("#FACC15"))
		var fdisp: Font = UITheme.get_display_font()
		var ticker: String = "%s   •   JUARA %d   •   " % [str(_ctx().get("led_ticker", "ELB • PIALA ELITE")), int(_ctx().get("year", 2026))]
		var tw: float = maxf(240.0, fdisp.get_string_size(ticker, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x)
		var scroll_x: float = -fmod(t * 72.0, tw)
		var draw_x: float = scroll_x
		while draw_x < w + tw:
			draw_string(fdisp, Vector2(draw_x, led_y + 22.0), ticker, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#FFFFFF"))
			draw_x += tw

		# Lush Horizontal-Striped Touchline Turf
		for si in range(7):
			var sy: float = pitch_y + float(si) * ((h - pitch_y) / 7.0)
			var sh: float = (h - pitch_y) / 7.0 + 1.5
			draw_rect(Rect2(0.0, sy, w, sh), Color("#176236") if (si % 2 == 0) else Color("#1D7541"))
		# Crisp white touchline stripe
		draw_rect(Rect2(0.0, pitch_y + 20.0, w, 4.0), Color(1, 1, 1, 0.55))

	# --------------------------------------------------------------------------
	# VIDEO 4 (ACT 2): PIALA PULANG (TWILIGHT AIRPORT CHARTER JET HOMECOMING)
	# --------------------------------------------------------------------------
	func _draw_act2_airport_homecoming(w: float, h: float) -> void:
		var t: float = _t()
		var st: float = _st()
		var pri: Color = _pri()
		var sec: Color = _sec()
		var acc: Color = _acc()
		var hor_y: float = h * 0.56

		# Golden-Amber Sunset transitioning into Starry Violet-Indigo Twilight Sky (Video 4!)
		_draw_vertical_gradient(w, 0.0, hor_y * 0.52, Color("#090F24"), Color("#2E1D46"), 8)
		_draw_vertical_gradient(w, hor_y * 0.52, hor_y, Color("#2E1D46"), Color("#D97736"), 10)
		# Warm golden sunset glow near horizon
		draw_circle(Vector2(w * 0.34, hor_y), 145.0, Color(1.0, 0.72, 0.30, 0.22))

		# Twinkling twilight stars in upper sky
		var stars: Array = owner_modal.get("_stars")
		for st_v in stars:
			var sv: Vector3 = st_v
			var tw: float = 0.45 + 0.55 * sin(t * 3.2 + sv.z)
			draw_rect(Rect2(sv.x, sv.y, 2.2, 2.2), Color(1.0, 0.98, 0.90, tw * 0.85))

		# Twilight celebratory fireworks over airport!
		for fi in range(3):
			var fx: float = w * (0.14 + float(fi) * 0.21)
			var fy: float = h * (0.17 + float(fi % 2) * 0.08)
			var fp: float = fmod(t * 0.72 + float(fi) * 0.37, 1.0)
			var rad: float = fp * 56.0
			var fa: float = maxf(0.0, 1.0 - fp) * 0.85
			var fcol: Color = Color(1.0, 0.86, 0.34, fa) if fi != 1 else Color(acc.r, acc.g, acc.b, fa)
			for sp in range(12):
				var ang: float = float(sp) * TAU / 12.0
				draw_circle(Vector2(fx + cos(ang) * rad, fy + sin(ang) * rad), 2.4, fcol)

		# Modern Glowing Airport Terminal & Control Tower along horizon
		draw_rect(Rect2(0.0, hor_y - 46.0, w, 46.0), Color("#151C2F"))
		# Control tower (right-center background)
		draw_rect(Rect2(w * 0.56, hor_y - 118.0, 22.0, 76.0), Color("#1E293B"))
		draw_rect(Rect2(w * 0.545, hor_y - 134.0, 52.0, 18.0), Color("#334155"))
		draw_rect(Rect2(w * 0.55, hor_y - 130.0, 42.0, 9.0), Color("#FDE68A"))
		if sin(t * 5.0) > 0.0:
			draw_circle(Vector2(w * 0.571, hor_y - 140.0), 4.0, Color("#EF4444"))
		# Warm illuminated airport terminal glass facade
		for wi in range(18):
			var wx: float = 16.0 + float(wi) * 52.0
			draw_rect(Rect2(wx, hor_y - 34.0, 36.0, 22.0), Color(1.0, 0.84, 0.45, 0.45))

		# Airport Tarmac Apron & Runway Markings
		draw_rect(Rect2(0.0, hor_y, w, h - hor_y), Color("#1A202E"))
		draw_line(Vector2(0.0, hor_y + 18.0), Vector2(w, hor_y + 18.0), Color("#F59E0B"), 2.0)
		for ri in range(12):
			draw_circle(Vector2(40.0 + float(ri) * 84.0, hor_y + 6.0), 3.0, Color("#38BDF8"))

		# Subtle camera zoom scale centered on Charter Jet & Red-Carpet Boarding Stairs
		var zoom_p: float = clampf(st / 3.2, 0.0, 1.0)
		var zs: float = lerpf(1.0, 1.08, zoom_p)
		var jx: float = w * 0.25
		var jy: float = h * 0.48

		# GIANT WHITE CHARTER JET (AEROLINEAS + Club Stripe + Tail Fin!)
		# Jet ground shadow
		draw_rect(Rect2(jx - 210.0 * zs, jy + 70.0 * zs, 410.0 * zs, 20.0 * zs), Color(0, 0, 0, 0.36))
		# Swept vertical tail fin in club primary + secondary stripe
		var tail := PackedVector2Array([
			Vector2(jx - 210.0 * zs, jy - 8.0 * zs),
			Vector2(jx - 246.0 * zs, jy - 104.0 * zs),
			Vector2(jx - 192.0 * zs, jy - 104.0 * zs),
			Vector2(jx - 134.0 * zs, jy - 16.0 * zs),
		])
		draw_colored_polygon(tail, pri)
		draw_line(Vector2(jx - 222.0 * zs, jy - 92.0 * zs), Vector2(jx - 168.0 * zs, jy - 14.0 * zs), sec, 7.0 * zs)
		# Fuselage body (white upper with ample room for airline lettering, silver belly, rounded nose cone)
		var fuse := PackedVector2Array([
			Vector2(jx - 212.0 * zs, jy - 28.0 * zs),
			Vector2(jx + 150.0 * zs, jy - 30.0 * zs),
			Vector2(jx + 206.0 * zs, jy + 4.0 * zs),
			Vector2(jx + 196.0 * zs, jy + 26.0 * zs),
			Vector2(jx - 196.0 * zs, jy + 22.0 * zs),
		])
		draw_colored_polygon(fuse, Color("#F1F5F9"))
		# Silver underbelly & club cheatline stripe
		draw_rect(Rect2(jx - 190.0 * zs, jy + 10.0 * zs, 376.0 * zs, 12.0 * zs), Color("#CBD5E1"))
		draw_rect(Rect2(jx - 196.0 * zs, jy + 4.0 * zs, 384.0 * zs, 6.0 * zs), pri)
		draw_rect(Rect2(jx - 196.0 * zs, jy + 1.0 * zs, 384.0 * zs, 3.0 * zs), Color("#FACC15"))
		# Cockpit windows
		var cock := PackedVector2Array([
			Vector2(jx + 154.0 * zs, jy - 18.0 * zs),
			Vector2(jx + 184.0 * zs, jy - 4.0 * zs),
			Vector2(jx + 158.0 * zs, jy - 2.0 * zs),
		])
		draw_colored_polygon(cock, Color("#0F172A"))
		# Row of illuminated warm cabin windows
		for cwi in range(14):
			draw_rect(Rect2(jx - 152.0 * zs + float(cwi) * 19.0 * zs, jy - 11.0 * zs, 10.0 * zs, 9.0 * zs), Color("#1E293B"))
			draw_rect(Rect2(jx - 150.0 * zs + float(cwi) * 19.0 * zs, jy - 9.0 * zs, 6.0 * zs, 5.0 * zs), Color("#FEF08A"))
		# Airline Name printed cleanly centered above cabin windows!
		var fdisp: Font = UITheme.get_display_font()
		var air_nm: String = str(_ctx().get("airline_name", "AEROLINEAS"))
		draw_string(fdisp, Vector2(jx - 134.0 * zs, jy - 16.0 * zs), air_nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, pri.darkened(0.20))
		# Swept Wing & Turbofan Engine + Landing Gear
		var wing := PackedVector2Array([
			Vector2(jx - 44.0 * zs, jy + 14.0 * zs),
			Vector2(jx + 44.0 * zs, jy + 14.0 * zs),
			Vector2(jx - 72.0 * zs, jy + 62.0 * zs),
			Vector2(jx - 118.0 * zs, jy + 54.0 * zs),
		])
		draw_colored_polygon(wing, Color("#94A3B8"))
		draw_rect(Rect2(jx - 26.0 * zs, jy + 26.0 * zs, 44.0 * zs, 20.0 * zs), Color("#334155"))
		draw_circle(Vector2(jx + 18.0 * zs, jy + 36.0 * zs), 10.0 * zs, Color("#0F172A"))
		# Landing gear struts & tires
		draw_rect(Rect2(jx + 130.0 * zs, jy + 22.0 * zs, 6.0 * zs, 46.0 * zs), Color("#475569"))
		draw_circle(Vector2(jx + 133.0 * zs, jy + 72.0 * zs), 9.0 * zs, Color("#090D16"))
		draw_rect(Rect2(jx - 48.0 * zs, jy + 26.0 * zs, 8.0 * zs, 44.0 * zs), Color("#475569"))
		draw_circle(Vector2(jx - 44.0 * zs, jy + 74.0 * zs), 10.0 * zs, Color("#090D16"))

		# Open Cabin Door & RED-CARPET MOBILE BOARDING STAIRS (where user & teammates walk down!)
		var door_pt := Vector2(w * 0.355, h * 0.445)
		draw_rect(Rect2(door_pt.x - 14.0, door_pt.y - 34.0, 26.0, 40.0), Color("#0B1120"))
		draw_rect(Rect2(door_pt.x - 11.0, door_pt.y - 30.0, 20.0, 34.0), Color("#FEF3C7"))  # warm cabin light
		var stairs_bot := Vector2(w * 0.465, h * 0.725)
		# Steel boarding stairs frame
		var stair_poly := PackedVector2Array([
			door_pt + Vector2(-10.0, 6.0),
			door_pt + Vector2(36.0, 6.0),
			stairs_bot + Vector2(34.0, 0.0),
			stairs_bot + Vector2(-28.0, 0.0),
		])
		draw_colored_polygon(stair_poly, Color("#334155"))
		# Red Carpet Runner rolling down the stairs!
		var carpet_poly := PackedVector2Array([
			door_pt + Vector2(-2.0, 6.0),
			door_pt + Vector2(26.0, 6.0),
			stairs_bot + Vector2(22.0, 0.0),
			stairs_bot + Vector2(-16.0, 0.0),
		])
		draw_colored_polygon(carpet_poly, Color("#B91C1C"))
		for sti in range(8):
			var sf: float = float(sti) / 7.0
			var sp0: Vector2 = (door_pt + Vector2(-2.0, 6.0)).lerp(stairs_bot + Vector2(-16.0, 0.0), sf)
			var sp1: Vector2 = (door_pt + Vector2(26.0, 6.0)).lerp(stairs_bot + Vector2(22.0, 0.0), sf)
			draw_line(sp0, sp1, Color("#FACC15"), 1.6)
		# Stair handrails
		draw_line(door_pt + Vector2(-10.0, -18.0), stairs_bot + Vector2(-28.0, -24.0), Color("#E2E8F0"), 2.4)
		draw_line(door_pt + Vector2(36.0, -18.0), stairs_bot + Vector2(34.0, -24.0), Color("#E2E8F0"), 2.4)

		# Yellow Airport Tug Cart & Safety Cones (authentic Video 4 detail!)
		var tug_x: float = w * 0.09
		var tug_y: float = h * 0.68
		draw_rect(Rect2(tug_x, tug_y, 58.0, 26.0), Color("#EAB308"))
		draw_rect(Rect2(tug_x + 34.0, tug_y - 16.0, 22.0, 18.0), Color("#0F172A"))
		draw_circle(Vector2(tug_x + 12.0, tug_y + 28.0), 8.0, Color("#090D16"))
		draw_circle(Vector2(tug_x + 46.0, tug_y + 28.0), 8.0, Color("#090D16"))
		for ci in range(3):
			var cx_cone: float = w * 0.22 + float(ci) * 34.0
			var cone := PackedVector2Array([Vector2(cx_cone, h * 0.72), Vector2(cx_cone + 10.0, h * 0.72), Vector2(cx_cone + 5.0, h * 0.695)])
			draw_colored_polygon(cone, Color("#F97316"))

	# --------------------------------------------------------------------------
	# VIDEO A (ACT 3): LEMARIMU - COZY TROPHY ROOM + GLASS CABINET + BACK-VIEW PLAYER!
	# --------------------------------------------------------------------------
	func _draw_act3_trophy_cabinet(w: float, h: float) -> void:
		var t: float = _t()
		var st: float = _st()
		var pan_p: float = clampf((st - 0.65) / 0.85, 0.0, 1.0)
		var ease_pan: float = pan_p * pan_p * (3.0 - 2.0 * pan_p)
		var room_cx: float = lerpf(w * 0.50, w * 0.31, ease_pan)

		# Warm Cozy Room Perspective Walls & Dark Wood Floor (exact Video A palette!)
		draw_rect(Rect2(0.0, 0.0, w, h), Color("#26221B"))
		# Back warm cream-beige plaster wall framed by angled dark side walls
		var wall_l: float = room_cx - 320.0
		var wall_r: float = room_cx + 320.0
		var wall_bot: float = h * 0.71
		draw_rect(Rect2(wall_l, 0.0, wall_r - wall_l, wall_bot), Color("#6E6049"))
		# Soft ceiling lamp glow cone washing down the back wall
		for gi in range(6):
			var gr: float = 130.0 + float(gi) * 44.0
			draw_circle(Vector2(room_cx, h * 0.26), gr, Color(1.0, 0.90, 0.68, 0.045))
		# Left & right angled corner shadows
		var left_w := PackedVector2Array([Vector2(0, 0), Vector2(wall_l, 0), Vector2(wall_l, wall_bot), Vector2(0, h * 0.82)])
		var right_w := PackedVector2Array([Vector2(wall_r, 0), Vector2(w, 0), Vector2(w, h * 0.82), Vector2(wall_r, wall_bot)])
		draw_colored_polygon(left_w, Color("#3E372C"))
		draw_colored_polygon(right_w, Color("#3E372C"))
		# Dark charcoal wainscoting baseboard along back & side walls
		draw_rect(Rect2(wall_l, wall_bot - 66.0, wall_r - wall_l, 66.0), Color("#242429"))
		draw_rect(Rect2(wall_l, wall_bot - 68.0, wall_r - wall_l, 4.0), Color("#15161A"))
		# Dark oak hardwood floor
		draw_rect(Rect2(0.0, wall_bot, w, h - wall_bot), Color("#171516"))
		# Plush Deep Crimson Carpet Rug under the player & cabinet!
		var rug := PackedVector2Array([
			Vector2(room_cx - 185.0, wall_bot + 4.0),
			Vector2(room_cx + 185.0, wall_bot + 4.0),
			Vector2(room_cx + 225.0, h * 0.94),
			Vector2(room_cx - 225.0, h * 0.94),
		])
		draw_colored_polygon(rug, Color("#6F1D27"))
		draw_polyline(rug + PackedVector2Array([rug[0]]), Color("#9B2C38"), 2.0)

		# ILLUMINATED WOODEN & GLASS TROPHY DISPLAY CABINET
		var cab_w: float = 296.0
		var cab_h: float = 292.0
		var cab_x: float = room_cx - cab_w * 0.5
		var cab_y: float = wall_bot - cab_h + 14.0
		# Cabinet shadow & dark walnut outer frame
		draw_rect(Rect2(cab_x - 8.0, cab_y - 12.0, cab_w + 16.0, cab_h + 16.0), Color("#131110"))
		draw_rect(Rect2(cab_x - 14.0, cab_y - 16.0, cab_w + 28.0, 14.0), Color("#382C20"))  # crown molding
		draw_rect(Rect2(cab_x, cab_y, cab_w, cab_h), Color("#4A3B2B"))
		# Interior warm dark oak display back & showcase spotlights
		draw_rect(Rect2(cab_x + 12.0, cab_y + 12.0, cab_w - 24.0, cab_h - 68.0), Color("#3A2B20"))
		for li in range(3):
			var lx: float = cab_x + 56.0 + float(li) * 92.0
			draw_rect(Rect2(lx - 14.0, cab_y + 12.0, 28.0, 5.0), Color("#FEF3C7"))
			var lcone := PackedVector2Array([
				Vector2(lx - 12.0, cab_y + 17.0), Vector2(lx + 12.0, cab_y + 17.0),
				Vector2(lx + 42.0, cab_y + 195.0), Vector2(lx - 42.0, cab_y + 195.0),
			])
			draw_colored_polygon(lcone, Color(1.0, 0.93, 0.72, 0.08))
		# Glass showcase shelf + solid wood lower pedestal
		var shelf_y: float = cab_y + 174.0
		draw_rect(Rect2(cab_x + 10.0, shelf_y, cab_w - 20.0, 9.0), Color("#7A6855"))
		draw_rect(Rect2(cab_x + 10.0, shelf_y + 7.0, cab_w - 20.0, 4.0), Color("#2B2118"))
		draw_rect(Rect2(cab_x + 10.0, cab_y + cab_h - 56.0, cab_w - 20.0, 56.0), Color("#261E18"))

		# Trophies & Golden Star Awards inside the Cabinet Shelf!
		# Slot 0 (Left-Center): NEW Championship Trophy settling onto shelf with golden sparkle!
		var settle_p: float = clampf(st / 0.65, 0.0, 1.0)
		var new_tr_pos := Vector2(cab_x + 68.0, shelf_y - 25.0 - (1.0 - settle_p) * 14.0)
		_draw_championship_trophy(new_tr_pos, 0.92)

		# Slot 1 (Center-Right): Golden Star Plaque Award
		var st_x: float = cab_x + 186.0
		var st_y: float = shelf_y - 22.0
		draw_circle(Vector2(st_x, st_y), 19.0, Color("#D97706"))
		var star_pts := PackedVector2Array()
		for si in range(10):
			var ang: float = -PI * 0.5 + float(si) * PI / 5.0
			var rr: float = 16.0 if (si % 2 == 0) else 7.0
			star_pts.append(Vector2(st_x + cos(ang) * rr, st_y + sin(ang) * rr))
		draw_colored_polygon(star_pts, Color("#FDE047"))
		draw_rect(Rect2(st_x - 10.0, shelf_y - 5.0, 20.0, 5.0), Color("#1E293B"))

		# Slot 2 (Right): Framed Legacy Honor Plaque (matching Video A's right-most framed star plaque!)
		var fr_x: float = cab_x + 232.0
		var fr_y: float = shelf_y - 44.0
		draw_rect(Rect2(fr_x, fr_y, 34.0, 42.0), Color("#E2E8F0"))
		draw_rect(Rect2(fr_x + 3.0, fr_y + 3.0, 28.0, 36.0), Color("#F8FAFC"))
		draw_rect(Rect2(fr_x, fr_y, 34.0, 6.0), Color("#CA8A04"))
		draw_circle(Vector2(fr_x + 17.0, fr_y + 22.0), 7.0, Color("#FACC15"))

		# Subtle glass front vertical reflection glint
		var glint := PackedVector2Array([
			Vector2(cab_x + 26.0, cab_y + 14.0), Vector2(cab_x + 48.0, cab_y + 14.0),
			Vector2(cab_x + 18.0, shelf_y + 30.0), Vector2(cab_x + 12.0, shelf_y + 30.0),
		])
		draw_colored_polygon(glint, Color(1.0, 1.0, 1.0, 0.06))

		# BACK-VIEW HUMAN-PROPORTIONED PLAYER standing on rug admiring their cabinet (with NAME + NUMBER on back!)
		_draw_back_view_player(Vector2(room_cx, wall_bot + 72.0), 3.35)

	func _draw_back_view_player(foot_center: Vector2, ps: float) -> void:
		var ox: float = floorf(foot_center.x - 17.0 * ps)
		var oy: float = floorf(foot_center.y - 56.0 * ps)
		var t: float = _t()
		var breath: int = 1 if sin(t * 2.1) > 0.6 else 0
		var pri: Color = _pri()
		var sec: Color = _sec()
		var pat: String = str(_ctx().get("pattern", "stripes"))
		var skins: Array[Color] = [Color("#F8D8BC"), Color("#E8BC96"), Color("#CE9466"), Color("#AC7248"), Color("#895333"), Color("#5C3723")]
		var hairs: Array[Color] = [Color("#18161C"), Color("#5C3824"), Color("#8E572E"), Color("#D9AC44"), Color("#A23A26"), Color("#9CA3AF"), Color("#E8ECF2"), Color("#2E7AE6"), Color("#D43038"), Color("#D84A90")]
		var skin: Color = skins[clampi(int(_ctx().get("player_skin", 1)), 0, skins.size() - 1)]
		var skin_sh: Color = skin.darkened(0.18)
		var hair: Color = hairs[clampi(int(_ctx().get("player_hair", 0)), 0, hairs.size() - 1)]
		var hair_hi: Color = hair.lightened(0.22)
		var shorts: Color = Color("#18202E") if pri.get_luminance() > 0.55 else sec.darkened(0.10)
		var blk := Color("#0C0F16")

		var px := func(x: int, y: int, w: int, h: int, col: Color):
			draw_rect(Rect2(ox + float(x) * ps, oy + float(y) * ps, float(w) * ps, float(h) * ps), col)

		# Grounded shadow on crimson rug
		px.call(8, 53, 18, 3, Color(0, 0, 0, 0.36))

		# Back of Head, Ears, Neck & Full Hair (facing AWAY from camera!)
		px.call(14, 15 + breath, 6, 4, blk)
		px.call(15, 16 + breath, 4, 3, skin_sh)
		px.call(10, 9 + breath, 2, 4, blk)
		px.call(11, 10 + breath, 1, 2, skin_sh)
		px.call(22, 9 + breath, 2, 4, blk)
		px.call(22, 10 + breath, 1, 2, skin_sh)
		px.call(12, 3 + breath, 10, 1, blk)
		px.call(11, 4 + breath, 12, 11, blk)
		px.call(12, 15 + breath, 10, 1, blk)
		# Skin nape at lower back of head
		px.call(12, 12 + breath, 10, 3, skin)
		px.call(13, 14 + breath, 8, 1, skin_sh)
		# Full back-of-head hair crown with highlight
		px.call(12, 4 + breath, 10, 9, hair)
		px.call(13, 5 + breath, 6, 2, hair_hi)
		px.call(14, 12 + breath, 6, 2, hair.darkened(0.18))

		# Back of Torso / Jersey (x=9..25, y=19..35)
		px.call(8, 18 + breath, 18, 18, blk)
		px.call(9, 19 + breath, 16, 16, pri)
		if pat == "stripes":
			px.call(11, 19 + breath, 3, 16, sec)
			px.call(16, 19 + breath, 3, 16, sec)
			px.call(21, 19 + breath, 3, 16, sec)
		elif pat == "hoops":
			px.call(9, 22 + breath, 16, 4, sec)
			px.call(9, 29 + breath, 16, 4, sec)
		# Clean solid back panel so Player Name + Jersey Number are super crisp!
		px.call(10, 20 + breath, 14, 14, pri.lerp(sec, 0.82) if pri.get_luminance() < 0.25 else Color(sec.r, sec.g, sec.b, 0.92))
		px.call(9, 19 + breath, 16, 2, pri)

		# Sleeves & Detached Arms resting naturally at sides
		px.call(5, 19 + breath, 4, 8, blk)
		px.call(6, 20 + breath, 2, 6, pri)
		px.call(6, 26 + breath, 2, 9, blk)
		px.call(6, 26 + breath, 2, 7, skin)
		px.call(25, 19 + breath, 4, 8, blk)
		px.call(26, 20 + breath, 2, 6, pri)
		px.call(26, 26 + breath, 2, 9, blk)
		px.call(26, 26 + breath, 2, 7, skin_sh)

		# Tailored Shorts, Legs, Socks & Cleats
		px.call(9, 35, 16, 8, blk)
		px.call(10, 36, 6, 6, shorts)
		px.call(18, 36, 6, 6, shorts)
		px.call(16, 36, 2, 4, shorts.darkened(0.15))
		# Calves
		px.call(10, 43, 5, 5, blk)
		px.call(11, 43, 3, 4, skin)
		px.call(19, 43, 5, 5, blk)
		px.call(20, 43, 3, 4, skin_sh)
		# Socks & Cleats
		px.call(10, 47, 5, 6, blk)
		px.call(11, 47, 3, 4, pri)
		px.call(11, 48, 3, 1, sec)
		px.call(10, 51, 5, 3, Color("#111622"))
		px.call(19, 47, 5, 6, blk)
		px.call(20, 47, 3, 4, pri)
		px.call(20, 48, 3, 1, sec)
		px.call(19, 51, 5, 3, Color("#111622"))

		# PRINTED BACK-OF-JERSEY PLAYER NAME + BOLD NUMBER (exact Video A detail!)
		var fdisp: Font = UITheme.get_display_font()
		var p_nm: String = str(_ctx().get("player_name", "BINTANG")).left(7).to_upper()
		var p_num: String = str(int(_ctx().get("player_num", 10)))
		var ink: Color = Color("#0F172A") if (pri.lerp(sec, 0.82).get_luminance() > 0.45) else Color("#FFFFFF")
		var nm_sz: Vector2 = fdisp.get_string_size(p_nm, HORIZONTAL_ALIGNMENT_CENTER, -1, 8)
		draw_string(fdisp, Vector2(ox + 17.0 * ps - nm_sz.x * 0.5, oy + float(23 + breath) * ps), p_nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, ink)
		var num_sz: Vector2 = fdisp.get_string_size(p_num, HORIZONTAL_ALIGNMENT_CENTER, -1, 16)
		draw_string(fdisp, Vector2(ox + 17.0 * ps - num_sz.x * 0.5, oy + float(32 + breath) * ps), p_num, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, pri if pri.get_luminance() < 0.55 else ink)

	# --------------------------------------------------------------------------
	# VIDEO B (ACT 4): JUARA / KELILING LAPANGAN - NIGHT STADIUM PITCH-SIDE BG!
	# --------------------------------------------------------------------------
	func _draw_act4_victory_dedication_bg(w: float, h: float) -> void:
		var t: float = _t()
		var led_y: float = h * 0.305
		var led_h: float = 20.0
		var pitch_y: float = led_y + led_h

		# Soft dark night stadium stands
		draw_rect(Rect2(0.0, 0.0, w, led_y), Color("#11131D"))
		for r in range(7):
			var ry: float = 16.0 + float(r) * ((led_y - 24.0) / 7.0)
			draw_rect(Rect2(0.0, ry, w, 2.0), Color(0.18, 0.21, 0.30, 0.55))
			for si in range(44):
				var sx: float = 10.0 + float(si) * (w / 44.0) + float((r * 7) % 9)
				var alpha: float = 0.20 + 0.14 * float((si + r) % 3)
				var scol: Color = Color(0.75, 0.58, 0.45, alpha) if ((si + r) % 4 == 0) else Color(0.25, 0.30, 0.42, alpha)
				draw_rect(Rect2(sx, ry - 6.0, 5.0, 5.0), scol)

		# Subtle diagonal floodlight beams
		for fi in range(3):
			var fx: float = w * (0.14 + float(fi) * 0.34)
			var sway: float = sin(t * 0.55 + float(fi) * 1.4) * 18.0
			var beam := PackedVector2Array([
				Vector2(fx - 26.0, 0.0),
				Vector2(fx + 26.0, 0.0),
				Vector2(fx + 145.0 + sway, h * 0.65),
				Vector2(fx + 45.0 + sway, h * 0.65),
			])
			draw_colored_polygon(beam, Color(1.0, 0.94, 0.78, 0.048))

		# Glowing Golden LED Perimeter Boards (<TEAM_CODE> | <COMP_TITLE>)
		draw_rect(Rect2(0.0, led_y, w, led_h), Color("#1B170C"))
		draw_rect(Rect2(0.0, led_y + 2.0, w, led_h - 4.0), Color("#A18228"))
		draw_rect(Rect2(0.0, led_y + 2.0, w, 2.0), Color("#FEF08A"))
		var fdisp: Font = UITheme.get_display_font()
		var seg_txt: String = "%s   |   %s   |   " % [str(_ctx().get("team_code", "ELB")), str(_ctx().get("comp_title", "PIALA ELITE"))]
		var seg_w: float = maxf(210.0, fdisp.get_string_size(seg_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x)
		var dx: float = -fmod(t * 24.0, seg_w)
		while dx < w + seg_w:
			draw_string(fdisp, Vector2(dx, led_y + 13.5), seg_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#17130A"))
			dx += seg_w

		# Dark-Emerald Night Pitch Grass with Soft Mowed Bands
		var bands: int = 8
		var bh: float = (h - pitch_y) / float(bands)
		for bi in range(bands):
			var frac: float = float(bi) / float(bands)
			var base_g: Color = Color("#1B431B") if (bi % 2 == 0) else Color("#204F20")
			draw_rect(Rect2(0.0, pitch_y + float(bi) * bh, w, bh + 1.5), base_g.darkened(frac * 0.42))
		draw_line(Vector2(0.0, pitch_y + 16.0), Vector2(w, pitch_y + 16.0), Color(1, 1, 1, 0.22), 2.0)

		# Right-side atmospheric dark gradient veil for ultra-crisp choice cards!
		var veil_steps: int = 10
		var vx0: float = w * 0.36
		var vw_s: float = (w - vx0) / float(veil_steps)
		for vi in range(veil_steps):
			var a: float = lerpf(0.0, 0.72, float(vi + 1) / float(veil_steps))
			draw_rect(Rect2(vx0 + float(vi) * vw_s, 0.0, vw_s + 2.0, h), Color(0.03, 0.05, 0.08, a))

# ==============================================================================
# FOREGROUND DEPTH LAYER (DRAWN IN FRONT OF PIXELAVATAR ACTORS)
# ==============================================================================
class _CeremonyForegroundCanvas extends _CeremonyCanvas:
	func _draw() -> void:
		if owner_modal == null or not is_instance_valid(owner_modal):
			return
		var w: float = maxf(size.x, 960.0)
		var h: float = maxf(size.y, 540.0)
		var t: float = _t()
		var st: float = _st()
		var mode: int = int(owner_modal.get("_mode"))

		if mode == MODE_PRE_FINAL_ARRIVAL:
			var shot: int = int(owner_modal.get("_pre_shot"))
			if shot == 3:
				_draw_cameraman(Vector2(w * 0.27, h * 0.87), 1.35, true)
				_draw_confetti_layer(0.55)
			return

		var act: int = int(owner_modal.get("_act"))
		if act == ACT_PODIUM_LIFT:
			var pcx: float = w * 0.50
			var deck_y: float = h * 0.645
			var hero_hop: float = absf(sin(t * 5.8 + 4.0 * 0.65)) * 8.0
			_draw_championship_trophy(Vector2(pcx, deck_y - 145.0 - hero_hop), 1.32)
			_draw_cameraman(Vector2(w * 0.14, h * 0.94), 1.25, true)
			_draw_steward(Vector2(w * 0.88, h * 0.92), 1.05)
			_draw_confetti_layer(0.95)
		elif act == ACT_LAP_OF_HONOUR:
			var march_p: float = clampf((st - 1.4) / 2.0, 0.0, 1.0)
			var group_shift: float = lerpf(85.0, 0.0, march_p)
			var user_cx: float = 232.0 + group_shift
			var mate_cx: float = 322.0 + group_shift
			var foot_y: float = h * 0.84
			var trophy_pt := Vector2(user_cx, foot_y - 94.0)
			var trophy_sc: float = 1.05
			if st < 1.4:
				var pass_p: float = clampf(st / 1.35, 0.0, 1.0)
				trophy_pt = Vector2(lerpf(mate_cx - 10.0, user_cx + 8.0, pass_p), foot_y - 78.0 - sin(pass_p * PI) * 14.0)
			elif st < 3.4:
				var walk_bob: float = absf(sin(t * 9.0)) * 5.0
				trophy_pt = Vector2(user_cx, foot_y - 84.0 - walk_bob)
			else:
				var lift_p: float = clampf((st - 3.4) / 0.55, 0.0, 1.0)
				var hop: float = absf(sin(t * 6.0 + 2.0 * 0.55)) * 6.0
				trophy_pt = Vector2(user_cx, lerpf(foot_y - 84.0, foot_y - 154.0, lift_p) - hop)
				trophy_sc = lerpf(1.05, 1.36, lift_p)
			_draw_championship_trophy(trophy_pt, trophy_sc)
			_draw_confetti_layer(0.88)
		elif act == ACT_AIRPORT_HOMECOMING:
			# Anchor Championship Trophy directly above User's raised hands!
			var avs: Array = owner_modal.get("_avatars")
			var tr_pt := Vector2(w * 0.465, h * 0.56)
			if not avs.is_empty():
				var u_av: PixelAvatar = avs[0]
				var u_cx: float = u_av.position.x + u_av.size.x * 0.5 * u_av.scale.x
				var u_top: float = u_av.position.y
				tr_pt = Vector2(u_cx, u_top + (34.0 if st < 2.25 else -20.0))
			_draw_championship_trophy(tr_pt, 1.18 if st >= 2.25 else 0.92)
			draw_line(Vector2(0.0, h * 0.80), Vector2(w * 0.62, h * 0.80), Color("#94A3B8"), 3.0)
			_draw_crowd_strip(14.0, w * 0.60, h * 0.83, h - 8.0, 3, true)
			_draw_confetti_layer(0.75)
		elif act == ACT_VICTORY_DEDICATION and bool(owner_modal.get("_dedication_chosen")):
			_draw_confetti_layer(0.45)
