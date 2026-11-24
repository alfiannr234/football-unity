extends Control

# Modular End-of-Season Cinematic Ceremony Modal (Complete Parts 1-3 + Final Recap Dashboard!)
# Part 1: CH_RECORD (0), CH_PARADE (1), CH_CLUB_GALA (2), CH_COMP_BEST (3)
# Part 2: CH_BEST_GOAL (4), CH_GOLDEN_BOY (5), CH_WORLD_BEST (6)
# Part 3: CH_ELECTION (7), CH_NATIONAL_CALLUP (8: Called / Not Called), CH_CLUB_SUMMIT (9),
#         CH_TV_DEBATE (10), CH_TEAM_OF_SEASON (11), CH_SEASON_RECAP (12)

signal finished

const CH_RECORD := 0
const CH_PARADE := 1
const CH_CLUB_GALA := 2
const CH_COMP_BEST := 3
const CH_BEST_GOAL := 4
const CH_GOLDEN_BOY := 5
const CH_WORLD_BEST := 6
const CH_ELECTION := 7
const CH_NATIONAL_CALLUP := 8
const CH_CLUB_SUMMIT := 9
const CH_TV_DEBATE := 10
const CH_TEAM_OF_SEASON := 11
const CH_SEASON_RECAP := 12

var _ctx: Dictionary = {}
var _chapters: Array[int] = []
var _ch_pos: int = 0
var _cur_ch: int = CH_RECORD
var _t: float = 0.0
var _ch_t: float = 0.0
var _fade_alpha: float = 1.0
var _fade_color: Color = Color(0.02, 0.03, 0.06, 1.0)
var _closing: bool = false
var _prev_bgm: String = ""

# Card & live counter animation state
var _card_revealed: bool = false
var _card_slide: float = 0.0
var _card_target_w: float = 360.0
var _gala_claimed: bool = false
var _comp_best_claimed: bool = false
var _part2_claimed: Dictionary = {}
var _comp_rating_lbl: Label = null
var _comp_rating_t: float = 0.0
var _gala_callout_idx: int = -1
var _theater_countdown_idx: int = -1
var _theater_winner_av: PixelAvatar = null
var _theater_seat_avs: Array[PixelAvatar] = []

# Part 3 interactive & broadcast state
var _timnas_selected_no: int = 9
var _timnas_jersey_confirmed: bool = false
var _timnas_picker_box: Control = null
var _timnas_confirm_lbl: Label = null
var _timnas_big_num_lbl: Label = null
var _tv_pundit_idx: int = -1
var _election_sound_played: bool = false

# UI nodes
var _bg_canvas: Control = null
var _actor_layer: Control = null
var _fg_canvas: Control = null
var _overlay_layer: Control = null
var _top_pill: PanelContainer = null
var _pill_badge_holder: Control = null
var _pill_kicker: Label = null
var _pill_title: Label = null
var _skip_btn: Button = null
var _right_card: PanelContainer = null
var _bottom_bar: PanelContainer = null
var _recap_board: Control = null
var _fade_rect: ColorRect = null

# Active scene actors
var _user_av: PixelAvatar = null
var _npc_av: NpcAvatar = null
var _npc_av2: NpcAvatar = null
var _gala_extra_av: PixelAvatar = null

# Lightweight deterministic particle pools
var _confetti: Array[Dictionary] = []
var _smoke: Array[Dictionary] = []

func configure(ctx: Dictionary = {}) -> void:
	_ctx = ctx.duplicate(true) if not ctx.is_empty() else CareerState.build_season_end_ceremony_context()
	_timnas_selected_no = int(_ctx.get("timnas_jersey_cur", int(_ctx.get("player_num", 9))))
	_chapters.clear()
	if bool(_ctx.get("show_record", true)):
		_chapters.append(CH_RECORD)
	if bool(_ctx.get("show_parade", false)):
		_chapters.append(CH_PARADE)
	_chapters.append(CH_CLUB_GALA)
	if bool(_ctx.get("show_comp_best", true)):
		_chapters.append(CH_COMP_BEST)
	# Part 2 Grand World Gala Chapters: GOL TERBAIK -> ANAK EMAS (U-21) -> PEMAIN TERBAIK DUNIA (Ballon d'Or)
	if not _ctx.get("best_goal_top3", []).is_empty():
		_chapters.append(CH_BEST_GOAL)
	if not _ctx.get("golden_boy_top5", []).is_empty():
		_chapters.append(CH_GOLDEN_BOY)
	if not _ctx.get("world_best_top10", []).is_empty():
		_chapters.append(CH_WORLD_BEST)
	# Part 3 Continuation + Final Recap Dashboard (Video 1 & Video 2!)
	_chapters.append(CH_ELECTION)
	_chapters.append(CH_NATIONAL_CALLUP)
	_chapters.append(CH_CLUB_SUMMIT)
	_chapters.append(CH_TV_DEBATE)
	_chapters.append(CH_TEAM_OF_SEASON)
	_chapters.append(CH_SEASON_RECAP)
	if _chapters.is_empty():
		_chapters.append(CH_SEASON_RECAP)

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UITheme.build_theme()
	clip_contents = true

	if _ctx.is_empty() or _chapters.is_empty():
		configure({})

	_prev_bgm = AudioSynth.bgm_track_override
	AudioSynth.bgm_track_override = "MALAM JUARA"
	_init_particles()
	_build_shell()
	_enter_chapter_at(0, false)

func _exit_tree() -> void:
	AudioSynth.bgm_track_override = _prev_bgm

func _pri() -> Color:
	return UITheme.parse_color(_ctx.get("primary", Color("#C81E2B")), Color("#C81E2B"))

func _sec() -> Color:
	return UITheme.parse_color(_ctx.get("secondary", Color("#F8FAFC")), Color("#F8FAFC"))

func _init_particles() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261835 + int(_ctx.get("club_id", 0)) * 29
	var pri: Color = _pri()
	var sec: Color = _sec()
	var cols: Array[Color] = [pri, sec, Color("#FACC15"), Color("#38BDF8"), Color("#FFFFFF")]
	_confetti.clear()
	for i in range(90):
		_confetti.append({
			"x": rng.randf_range(0.0, 960.0),
			"y": rng.randf_range(-30.0, 540.0),
			"vx": rng.randf_range(-22.0, 22.0),
			"vy": rng.randf_range(34.0, 92.0),
			"sz": rng.randf_range(3.0, 6.2),
			"phase": rng.randf_range(0.0, TAU),
			"col": cols[i % cols.size()],
		})
	_smoke.clear()
	for i in range(28):
		_smoke.append({
			"u": rng.randf_range(0.08, 0.92),
			"off": rng.randf_range(0.0, 1.0),
			"spd": rng.randf_range(0.18, 0.36),
			"rad": rng.randf_range(16.0, 34.0),
		})

func _build_shell() -> void:
	_bg_canvas = _SeasonBgCanvas.new()
	_bg_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg_canvas.set("owner_modal", self)
	add_child(_bg_canvas)

	_actor_layer = Control.new()
	_actor_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_actor_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_actor_layer.clip_contents = true
	add_child(_actor_layer)

	_fg_canvas = _SeasonFgCanvas.new()
	_fg_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fg_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fg_canvas.set("owner_modal", self)
	add_child(_fg_canvas)

	_overlay_layer = Control.new()
	_overlay_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay_layer.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_overlay_layer)

	# Top-Left Broadcast Context Pill
	_top_pill = PanelContainer.new()
	_top_pill.position = Vector2(18, 16)
	var psb: StyleBoxFlat = UITheme.make_box(Color(0.06, 0.07, 0.11, 0.88), Color(1.0, 1.0, 1.0, 0.18), 1, 6)
	psb.content_margin_left = 10
	psb.content_margin_right = 14
	psb.content_margin_top = 6
	psb.content_margin_bottom = 6
	_top_pill.add_theme_stylebox_override("panel", psb)
	_overlay_layer.add_child(_top_pill)

	var phb := HBoxContainer.new()
	phb.add_theme_constant_override("separation", 10)
	_top_pill.add_child(phb)

	_pill_badge_holder = CenterContainer.new()
	_pill_badge_holder.custom_minimum_size = Vector2(28, 28)
	phb.add_child(_pill_badge_holder)

	var pvb := VBoxContainer.new()
	pvb.add_theme_constant_override("separation", 1)
	phb.add_child(pvb)

	_pill_kicker = Label.new()
	_pill_kicker.add_theme_font_size_override("font_size", 10)
	_pill_kicker.add_theme_color_override("font_color", Color("#F87171"))
	pvb.add_child(_pill_kicker)

	_pill_title = Label.new()
	_pill_title.add_theme_font_override("font", UITheme.get_display_font())
	_pill_title.add_theme_font_size_override("font_size", 14)
	_pill_title.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	pvb.add_child(_pill_title)

	# Bottom-Right Quick-Skip for long intro beats (hidden once chapter card is shown)
	_skip_btn = Button.new()
	_skip_btn.text = "LEWATI >>"
	_skip_btn.custom_minimum_size = Vector2(114, 32)
	_skip_btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_skip_btn.offset_left = -132
	_skip_btn.offset_top = -48
	_skip_btn.offset_right = -18
	_skip_btn.offset_bottom = -16
	UITheme.style_btn(_skip_btn, Color(0.07, 0.09, 0.15, 0.86), Color(1.0, 1.0, 1.0, 0.25), 11)
	_skip_btn.pressed.connect(_on_skip_intro_beat)
	_overlay_layer.add_child(_skip_btn)

	_fade_rect = ColorRect.new()
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.color = Color(0.02, 0.03, 0.06, 0.0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade_rect)

func _set_pill_club_badge(use_star_shield: bool = false) -> void:
	for c in _pill_badge_holder.get_children():
		_pill_badge_holder.remove_child(c)
		c.queue_free()
	if use_star_shield:
		var sh := _MiniCompShield.new()
		sh.custom_minimum_size = Vector2(26, 26)
		sh.accent = Color("#3B82F6") if bool(_ctx.get("comp_best_is_elite", true)) else Color("#EAB308")
		_pill_badge_holder.add_child(sh)
	else:
		var cr := ClubCrest.new()
		cr.custom_minimum_size = Vector2(28, 28)
		cr.set_club(int(_ctx.get("club_id", 0)))
		cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_pill_badge_holder.add_child(cr)

func _set_pill_award_badge(kind: String) -> void:
	for c in _pill_badge_holder.get_children():
		_pill_badge_holder.remove_child(c)
		c.queue_free()
	var ico := _MiniAwardBadge.new()
	ico.custom_minimum_size = Vector2(26, 26)
	ico.kind = kind
	_pill_badge_holder.add_child(ico)

func _set_pill_nation_badge() -> void:
	for c in _pill_badge_holder.get_children():
		_pill_badge_holder.remove_child(c)
		c.queue_free()
	var ico := _MiniFlagBadge.new()
	ico.custom_minimum_size = Vector2(26, 26)
	var cols: Array = _ctx.get("timnas_nation_colors", [Color("#CE1126"), Color("#FFFFFF")])
	ico.col_a = UITheme.parse_color(cols[0] if cols.size() > 0 else Color("#CE1126"), Color("#CE1126"))
	ico.col_b = UITheme.parse_color(cols[1] if cols.size() > 1 else Color("#FFFFFF"), Color("#FFFFFF"))
	ico.is_star_flag = (str(_ctx.get("timnas_nation_code", "IDN")).to_upper() in ["VIE", "VNM", "CHN", "MAR", "TUR"])
	_pill_badge_holder.add_child(ico)

func _clear_actors() -> void:
	for c in _actor_layer.get_children():
		_actor_layer.remove_child(c)
		c.queue_free()
	_user_av = null
	_npc_av = null
	_npc_av2 = null
	_gala_extra_av = null
	_theater_winner_av = null
	_theater_seat_avs.clear()

func _clear_right_card() -> void:
	if _right_card != null and is_instance_valid(_right_card):
		if _right_card.get_parent() != null:
			_right_card.get_parent().remove_child(_right_card)
		_right_card.queue_free()
	_right_card = null
	if _bottom_bar != null and is_instance_valid(_bottom_bar):
		if _bottom_bar.get_parent() != null:
			_bottom_bar.get_parent().remove_child(_bottom_bar)
		_bottom_bar.queue_free()
	_bottom_bar = null
	if _recap_board != null and is_instance_valid(_recap_board):
		if _recap_board.get_parent() != null:
			_recap_board.get_parent().remove_child(_recap_board)
		_recap_board.queue_free()
	_recap_board = null
	_comp_rating_lbl = null
	_timnas_picker_box = null
	_timnas_confirm_lbl = null
	_timnas_big_num_lbl = null
	_card_revealed = false
	_card_slide = 0.0

func _make_user_avatar(sz: Vector2, formal_gala: bool, anim: String) -> PixelAvatar:
	var av := PixelAvatar.new()
	av.custom_minimum_size = sz
	av.size = sz
	av.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var kit := {"primary": _pri(), "secondary": _sec(), "pattern": str(_ctx.get("pattern", "stripes"))}
	if CareerState.has_active_career:
		av.configure_from_career()
	else:
		av.configure_from_seed(777, kit, int(_ctx.get("player_num", 10)))
	av.apply_kit(kit)
	av.casual_style = 2 if formal_gala else 0
	av.anim_mode = anim
	return av

# ==============================================================================
# CHAPTER TRANSITIONS (PART 1: CH_RECORD -> CH_PARADE -> CH_CLUB_GALA -> CH_COMP_BEST)
# ==============================================================================
func _enter_chapter_at(pos_idx: int, with_fade: bool = true) -> void:
	if pos_idx >= _chapters.size():
		_finish_ceremony()
		return
	_ch_pos = pos_idx
	_cur_ch = _chapters[pos_idx]
	_ch_t = 0.0
	_gala_callout_idx = -1
	_theater_countdown_idx = -1
	_tv_pundit_idx = -1
	_election_sound_played = false
	_timnas_jersey_confirmed = false
	_comp_rating_t = 0.0
	_clear_actors()
	_clear_right_card()
	_fade_color = Color(0.02, 0.03, 0.06, 1.0)
	_fade_alpha = 0.92 if with_fade else 0.85
	_top_pill.visible = (_cur_ch != CH_SEASON_RECAP)
	_skip_btn.visible = (_cur_ch != CH_SEASON_RECAP)
	if _cur_ch in [CH_TV_DEBATE, CH_TEAM_OF_SEASON]:
		_skip_btn.offset_top = -68
		_skip_btn.offset_bottom = -36
	else:
		_skip_btn.offset_top = -48
		_skip_btn.offset_bottom = -16

	var kit := {"primary": _pri(), "secondary": _sec(), "pattern": str(_ctx.get("pattern", "stripes"))}

	match _cur_ch:
		CH_RECORD:
			_set_pill_club_badge(false)
			_pill_kicker.text = "REKOR"
			_pill_kicker.add_theme_color_override("font_color", Color("#F87171"))
			_pill_title.text = str(_ctx.get("player_name", "BINTANG"))
			_user_av = _make_user_avatar(Vector2(82, 134), false, "IDLE")
			_actor_layer.add_child(_user_av)
			_npc_av = NpcAvatar.new()
			_npc_av.configure_role("SENIOR_COACH", false, kit)
			_npc_av.size = Vector2(82, 134)
			_npc_av.anim_mode = "IDLE"
			_npc_av.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_actor_layer.add_child(_npc_av)
			_build_record_card()
			AudioSynth.play_achievement()

		CH_PARADE:
			_set_pill_club_badge(false)
			_pill_kicker.text = "PARADE"
			_pill_kicker.add_theme_color_override("font_color", Color("#F87171"))
			_pill_title.text = str(_ctx.get("league_short", "PRIMERA"))
			_build_parade_card()
			AudioSynth.play_goal()

		CH_CLUB_GALA:
			_set_pill_club_badge(false)
			_pill_kicker.text = "GALA KLUB"
			_pill_kicker.add_theme_color_override("font_color", Color("#F87171"))
			_pill_title.text = str(_ctx.get("club_name", "KLUB"))
			_user_av = _make_user_avatar(Vector2(96, 156), true, "IDLE")
			_user_av.visible = false
			_actor_layer.add_child(_user_av)
			_npc_av = NpcAvatar.new()
			_npc_av.configure_role("PRESIDENT", false, kit)
			_npc_av.size = Vector2(92, 150)
			_npc_av.anim_mode = "IDLE"
			_npc_av.visible = false
			_npc_av.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_actor_layer.add_child(_npc_av)
			_build_club_gala_card()
			AudioSynth.play_achievement()

		CH_COMP_BEST:
			_set_pill_club_badge(true)
			_pill_kicker.text = "TERBAIK %s" % str(_ctx.get("comp_best_title", "PIALA ELITE"))
			_pill_kicker.add_theme_color_override("font_color", Color("#38BDF8"))
			_pill_title.text = str(_ctx.get("player_name", "BINTANG"))
			_user_av = _make_user_avatar(Vector2(92, 150), false, "IDLE")
			_actor_layer.add_child(_user_av)
			_build_comp_best_card()
			AudioSynth.play_goal()

		CH_BEST_GOAL:
			_set_pill_award_badge("GOAL_FRAME")
			_pill_kicker.text = "GOL TERBAIK"
			_pill_kicker.add_theme_color_override("font_color", Color("#FACC15"))
			_pill_title.text = "GOL TERINDAH"
			_build_theater_award_card(CH_BEST_GOAL)
			AudioSynth.play_achievement()

		CH_GOLDEN_BOY:
			_set_pill_award_badge("WINGED_BALL")
			_pill_kicker.text = "ANAK EMAS"
			_pill_kicker.add_theme_color_override("font_color", Color("#FACC15"))
			_pill_title.text = "BINTANG MUDA TAHUN INI"
			_build_theater_award_card(CH_GOLDEN_BOY)
			AudioSynth.play_achievement()

		CH_WORLD_BEST:
			_set_pill_award_badge("BALLON_DOR")
			_pill_kicker.text = "PEMAIN TERBAIK"
			_pill_kicker.add_theme_color_override("font_color", Color("#FACC15"))
			_pill_title.text = "TERBAIK DUNIA"
			_build_theater_award_card(CH_WORLD_BEST)
			AudioSynth.play_achievement()

		CH_ELECTION:
			_set_pill_club_badge(false)
			_pill_kicker.text = "HASIL PEMILU"
			_pill_kicker.add_theme_color_override("font_color", Color("#F87171"))
			_pill_title.text = str(_ctx.get("club_name", "KLUB"))
			_build_election_bar()
			AudioSynth.play_click()

		CH_NATIONAL_CALLUP:
			var called: bool = bool(_ctx.get("timnas_called", true))
			_set_pill_nation_badge()
			_pill_kicker.text = "DIPANGGIL" if called else "TIDAK DIPANGGIL"
			_pill_kicker.add_theme_color_override("font_color", Color("#FACC15") if called else Color("#F87171"))
			_pill_title.text = str(_ctx.get("timnas_nation_name", "INDONESIA"))
			_timnas_selected_no = int(_ctx.get("timnas_jersey_cur", int(_ctx.get("player_num", 9))))
			_user_av = _make_user_avatar(Vector2(90, 146), false, "IDLE")
			_user_av.casual_style = 1
			_actor_layer.add_child(_user_av)
			_build_timnas_card(called)
			if called:
				AudioSynth.play_achievement()
			else:
				AudioSynth.play_click()

		CH_CLUB_SUMMIT:
			_set_pill_club_badge(false)
			_pill_kicker.text = "DEWAN KLUB"
			_pill_kicker.add_theme_color_override("font_color", Color("#F87171"))
			_pill_title.text = str(_ctx.get("club_name", "KLUB"))
			_npc_av = NpcAvatar.new()
			_npc_av.configure_role("COACH", false, kit)
			_npc_av.size = Vector2(96, 156)
			_npc_av.anim_mode = "IDLE"
			_npc_av.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_actor_layer.add_child(_npc_av)
			_user_av = _make_user_avatar(Vector2(98, 160), false, "IDLE")
			_user_av.casual_style = 1
			_actor_layer.add_child(_user_av)
			_npc_av2 = NpcAvatar.new()
			_npc_av2.configure_role("PRESIDENT", false, kit)
			_npc_av2.size = Vector2(96, 156)
			_npc_av2.anim_mode = "IDLE"
			_npc_av2.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_actor_layer.add_child(_npc_av2)
			_build_club_summit_card()
			AudioSynth.play_click()

		CH_TV_DEBATE:
			_set_pill_club_badge(false)
			_pill_kicker.text = "DEBAT DIMULAI"
			_pill_kicker.add_theme_color_override("font_color", Color("#F87171"))
			var rv_d: Dictionary = _ctx.get("rival", {})
			var rv_last: String = str(rv_d.get("name", "DUNMORE")).split(" ")[-1]
			var u_short: String = str(_ctx.get("player_name", "BINTANG")).split(" ")[0]
			_pill_title.text = "%s • %s" % [u_short, rv_last]
			_build_tv_debate_bar()
			AudioSynth.play_click()

		CH_TEAM_OF_SEASON:
			_set_pill_club_badge(false)
			_pill_kicker.text = "TIM TERBAIK MUSIM"
			_pill_kicker.add_theme_color_override("font_color", Color("#FACC15"))
			_pill_title.text = str(_ctx.get("player_name", "BINTANG"))
			_build_best_xi_bar()
			AudioSynth.play_achievement()

		CH_SEASON_RECAP:
			_open_recap_board()
			AudioSynth.play_achievement()

	_position_actors()

func _next_chapter() -> void:
	AudioSynth.play_click()
	_enter_chapter_at(_ch_pos + 1, true)

func _on_skip_intro_beat() -> void:
	AudioSynth.play_click()
	match _cur_ch:
		CH_RECORD: _ch_t = maxf(_ch_t, 2.8)
		CH_PARADE: _ch_t = maxf(_ch_t, 2.8)
		CH_CLUB_GALA: _ch_t = maxf(_ch_t, 6.8)
		CH_COMP_BEST: _ch_t = maxf(_ch_t, 2.6)
		CH_BEST_GOAL: _ch_t = maxf(_ch_t, 5.2)
		CH_GOLDEN_BOY: _ch_t = maxf(_ch_t, 6.6)
		CH_WORLD_BEST: _ch_t = maxf(_ch_t, 8.8)
		CH_ELECTION: _ch_t = maxf(_ch_t, 4.9)
		CH_NATIONAL_CALLUP: _ch_t = maxf(_ch_t, 3.8)
		CH_CLUB_SUMMIT: _ch_t = maxf(_ch_t, 2.5)
		CH_TV_DEBATE: _ch_t = maxf(_ch_t, 7.4)
		CH_TEAM_OF_SEASON: _ch_t = maxf(_ch_t, 8.4)

# ==============================================================================
# RIGHT-SIDE CHAPTER CARDS (STRICTLY SHRINK-WRAPPED, ZERO OVERFLOW)
# ==============================================================================
func _build_record_card() -> void:
	_clear_right_card()
	_card_target_w = 378.0
	_right_card = PanelContainer.new()
	_right_card.custom_minimum_size = Vector2(378, 0)
	var sb: StyleBoxFlat = UITheme.make_box(Color(0.08, 0.08, 0.10, 0.92), Color("#EAB308"), 1, 8)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 16
	sb.content_margin_bottom = 16
	_right_card.add_theme_stylebox_override("panel", sb)
	_overlay_layer.add_child(_right_card)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 5)
	_right_card.add_child(vb)

	var nm := Label.new()
	nm.text = str(_ctx.get("player_name", "BINTANG"))
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.add_theme_font_override("font", UITheme.get_display_font())
	nm.add_theme_font_size_override("font_size", 18)
	nm.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	vb.add_child(nm)

	var sub := Label.new()
	sub.text = str(_ctx.get("record_title", "RATING TERBAIK DALAM SATU MUSIM"))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_override("font", UITheme.get_display_font())
	sub.add_theme_font_size_override("font_size", 11)
	sub.add_theme_color_override("font_color", Color("#FACC15"))
	vb.add_child(sub)

	var big := Label.new()
	big.text = str(int(_ctx.get("record_val", 88)))
	big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	big.add_theme_font_override("font", UITheme.get_display_font())
	big.add_theme_font_size_override("font_size", 34)
	big.add_theme_color_override("font_color", Color("#FDE047"))
	vb.add_child(big)

	var lg := Label.new()
	lg.text = str(_ctx.get("league_name", "LIGA UTAMA"))
	lg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lg.add_theme_font_size_override("font_size", 10)
	lg.add_theme_color_override("font_color", Color("#94A3B8"))
	vb.add_child(lg)

	# Previous record holder comparison row (exact Video 1 00:07!)
	var prev_hb := HBoxContainer.new()
	prev_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	prev_hb.add_theme_constant_override("separation", 18)
	vb.add_child(prev_hb)
	for pair in [
		[str(_ctx.get("prev_legend", "Tino Roldan")), Color("#FACC15")],
		[str(int(_ctx.get("prev_val", 87))), Color("#E2E8F0")],
		[str(int(_ctx.get("prev_year", 1987))), Color("#94A3B8")],
	]:
		var pl := Label.new()
		pl.text = str(pair[0])
		pl.add_theme_font_override("font", UITheme.get_display_font())
		pl.add_theme_font_size_override("font_size", 12)
		pl.add_theme_color_override("font_color", pair[1])
		prev_hb.add_child(pl)

	var quote := Label.new()
	quote.text = "Namamu masuk buku rekor. Rekor itu sekarang milikmu."
	quote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quote.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quote.add_theme_font_size_override("font_size", 11)
	quote.add_theme_color_override("font_color", Color("#CBD5E1"))
	vb.add_child(quote)

	var btn: Button = _make_gold_or_crimson_btn("LANJUT", Color("#EAB308"))
	btn.pressed.connect(_next_chapter)
	vb.add_child(btn)

	_right_card.visible = false
	_right_card.size = Vector2(378.0, 220.0)

func _build_parade_card() -> void:
	_clear_right_card()
	_card_target_w = 370.0
	_right_card = PanelContainer.new()
	_right_card.custom_minimum_size = Vector2(370, 0)
	var sb: StyleBoxFlat = UITheme.make_box(Color(0.08, 0.08, 0.11, 0.92), Color(1.0, 1.0, 1.0, 0.16), 1, 8)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 16
	sb.content_margin_bottom = 16
	_right_card.add_theme_stylebox_override("panel", sb)
	_overlay_layer.add_child(_right_card)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 5)
	_right_card.add_child(vb)

	var title := Label.new()
	title.text = "KOTA MILIK KALIAN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", UITheme.get_display_font())
	title.add_theme_font_size_override("font_size", 19)
	title.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	vb.add_child(title)

	var club_l := Label.new()
	club_l.text = str(_ctx.get("club_name", "KLUB"))
	club_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	club_l.add_theme_font_override("font", UITheme.get_display_font())
	club_l.add_theme_font_size_override("font_size", 12)
	club_l.add_theme_color_override("font_color", Color("#F87171"))
	vb.add_child(club_l)

	var cnt := Label.new()
	cnt.text = str(maxi(1, int(_ctx.get("parade_count", 1))))
	cnt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cnt.add_theme_font_override("font", UITheme.get_display_font())
	cnt.add_theme_font_size_override("font_size", 34)
	cnt.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	vb.add_child(cnt)

	var cap := Label.new()
	cap.text = "GELAR DI ATAS BUS"
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.add_theme_font_size_override("font_size", 10)
	cap.add_theme_color_override("font_color", Color("#94A3B8"))
	vb.add_child(cap)

	var tr_list: Array = _ctx.get("parade_trophies", [])
	var tr_summary: Array[String] = []
	for ti in range(mini(3, tr_list.size())):
		tr_summary.append(str(tr_list[ti]))
	var tr_l := Label.new()
	tr_l.text = "  •  ".join(tr_summary) if not tr_summary.is_empty() else "JUARA MUSIM INI"
	tr_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tr_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tr_l.add_theme_font_size_override("font_size", 10)
	tr_l.add_theme_color_override("font_color", Color("#FACC15"))
	vb.add_child(tr_l)

	var quote := Label.new()
	quote.text = "Satu musim penuh muat di jalan ini, dan semua orang ini datang untuk melihatnya."
	quote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quote.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quote.add_theme_font_size_override("font_size", 11)
	quote.add_theme_color_override("font_color", Color("#E2E8F0"))
	vb.add_child(quote)

	var btn: Button = PressStageBackdrop.build_crimson_cta_button("LANJUT")
	btn.pressed.connect(_next_chapter)
	vb.add_child(btn)

	_right_card.visible = false
	_right_card.size = Vector2(370.0, 236.0)

func _build_club_gala_card() -> void:
	_clear_right_card()
	_card_target_w = 408.0
	_right_card = PanelContainer.new()
	_right_card.custom_minimum_size = Vector2(408, 0)
	var sb: StyleBoxFlat = UITheme.make_box(Color(0.08, 0.08, 0.11, 0.93), Color(1.0, 1.0, 1.0, 0.16), 1, 8)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	_right_card.add_theme_stylebox_override("panel", sb)
	_overlay_layer.add_child(_right_card)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	_right_card.add_child(vb)

	var nm := Label.new()
	nm.text = str(_ctx.get("player_name", "BINTANG"))
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.add_theme_font_override("font", UITheme.get_display_font())
	nm.add_theme_font_size_override("font_size", 18)
	nm.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	vb.add_child(nm)

	var sub := Label.new()
	sub.text = "PEMAIN TERBAIK MUSIM"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_override("font", UITheme.get_display_font())
	sub.add_theme_font_size_override("font_size", 11)
	sub.add_theme_color_override("font_color", Color("#F87171"))
	vb.add_child(sub)

	# 4-Column Season Stats Strip (RATA-RATA | GOL | ASSIST | LAGA)
	var stat_hb := HBoxContainer.new()
	stat_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	stat_hb.add_theme_constant_override("separation", 18)
	vb.add_child(stat_hb)
	var rtg_str: String = ("%.1f" % float(_ctx.get("avg_rating", 8.0))).replace(".", ",")
	for item in [
		[rtg_str, "RATA-RATA", Color("#F87171")],
		[str(int(_ctx.get("season_goals", 18))), "GOL", UITheme.TEXT_WHITE],
		[str(int(_ctx.get("season_assists", 5))), "ASSIST", UITheme.TEXT_WHITE],
		[str(int(_ctx.get("season_matches", 24))), "LAGA", UITheme.TEXT_WHITE],
	]:
		var svb := VBoxContainer.new()
		svb.add_theme_constant_override("separation", 1)
		stat_hb.add_child(svb)
		var vl := Label.new()
		vl.text = str(item[0])
		vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vl.add_theme_font_override("font", UITheme.get_display_font())
		vl.add_theme_font_size_override("font_size", 16)
		vl.add_theme_color_override("font_color", item[2])
		svb.add_child(vl)
		var kl := Label.new()
		kl.text = str(item[1])
		kl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		kl.add_theme_font_size_override("font_size", 8)
		kl.add_theme_color_override("font_color", Color("#94A3B8"))
		svb.add_child(kl)

	var sep := ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 1)
	sep.color = Color(1.0, 1.0, 1.0, 0.14)
	vb.add_child(sep)

	# 3-Row Positional Awards Mini-Table (BEK TOP | GELANDANG TOP | PENYERANG TOP)
	var top_d: Dictionary = _ctx.get("top_def", {})
	var top_m: Dictionary = _ctx.get("top_mid", {})
	var top_f: Dictionary = _ctx.get("top_fwd", {})
	for prow in [
		["BEK TOP", top_d, Color("#2563EB")],
		["GELANDANG TOP", top_m, Color("#16A34A")],
		["PENYERANG TOP", top_f, Color("#DC2626")],
	]:
		var pd: Dictionary = prow[1]
		var rhb := HBoxContainer.new()
		rhb.add_theme_constant_override("separation", 6)
		vb.add_child(rhb)

		var cat_l := Label.new()
		cat_l.text = str(prow[0])
		cat_l.custom_minimum_size = Vector2(96, 0)
		cat_l.add_theme_font_size_override("font_size", 9)
		cat_l.add_theme_color_override("font_color", Color("#94A3B8"))
		rhb.add_child(cat_l)

		var pos_badge := PanelContainer.new()
		var pbsb := StyleBoxFlat.new()
		pbsb.bg_color = prow[2]
		pbsb.set_corner_radius_all(3)
		pbsb.content_margin_left = 4
		pbsb.content_margin_right = 4
		pbsb.content_margin_top = 1
		pbsb.content_margin_bottom = 1
		pos_badge.add_theme_stylebox_override("panel", pbsb)
		var pbl := Label.new()
		pbl.text = str(pd.get("pos", "ST"))
		pbl.add_theme_font_override("font", UITheme.get_display_font())
		pbl.add_theme_font_size_override("font_size", 8)
		pbl.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
		pos_badge.add_child(pbl)
		rhb.add_child(pos_badge)

		var pnm := Label.new()
		pnm.text = str(pd.get("name", "PEMAIN"))
		pnm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pnm.clip_text = true
		pnm.add_theme_font_override("font", UITheme.get_display_font())
		pnm.add_theme_font_size_override("font_size", 10)
		pnm.add_theme_color_override("font_color", Color("#FACC15") if bool(pd.get("is_user", false)) else UITheme.TEXT_WHITE)
		rhb.add_child(pnm)

		var prt := Label.new()
		prt.text = ("%.1f" % float(pd.get("rating", 7.0))).replace(".", ",")
		prt.add_theme_font_override("font", UITheme.get_display_font())
		prt.add_theme_font_size_override("font_size", 10)
		prt.add_theme_color_override("font_color", Color("#F87171"))
		rhb.add_child(prt)

	# Skill Points + Cash Bonus
	var rew_l := Label.new()
	rew_l.text = "+%d PTS SKILL   •   +%s BONUS" % [
		int(_ctx.get("gala_skill_pts", 2)),
		UITheme.format_cash(int(_ctx.get("gala_bonus_cash", 27000))),
	]
	rew_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rew_l.add_theme_font_override("font", UITheme.get_display_font())
	rew_l.add_theme_font_size_override("font_size", 11)
	rew_l.add_theme_color_override("font_color", Color("#38BDF8"))
	vb.add_child(rew_l)

	var quote := Label.new()
	quote.text = "Ruang ganti memilihmu sebagai yang terbaik musim ini."
	quote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quote.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quote.add_theme_font_size_override("font_size", 10)
	quote.add_theme_color_override("font_color", Color("#CBD5E1"))
	vb.add_child(quote)

	var btn: Button = PressStageBackdrop.build_crimson_cta_button("LANJUT")
	btn.pressed.connect(func():
		if not _gala_claimed:
			_gala_claimed = true
			CareerState.claim_season_end_award_bonus(int(_ctx.get("gala_skill_pts", 2)), int(_ctx.get("gala_bonus_cash", 27000)))
		_next_chapter()
	)
	vb.add_child(btn)

	_right_card.visible = false
	_right_card.size = Vector2(408.0, 290.0)

func _build_comp_best_card() -> void:
	_clear_right_card()
	_card_target_w = 378.0
	var is_el: bool = bool(_ctx.get("comp_best_is_elite", true))
	var acc: Color = Color("#3B82F6") if is_el else Color("#EAB308")
	_right_card = PanelContainer.new()
	_right_card.custom_minimum_size = Vector2(378, 0)
	var sb: StyleBoxFlat = UITheme.make_box(Color(0.05, 0.08, 0.16, 0.93), acc, 1, 8)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 15
	sb.content_margin_bottom = 15
	_right_card.add_theme_stylebox_override("panel", sb)
	_overlay_layer.add_child(_right_card)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 5)
	_right_card.add_child(vb)

	var nm := Label.new()
	nm.text = str(_ctx.get("player_name", "BINTANG"))
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.add_theme_font_override("font", UITheme.get_display_font())
	nm.add_theme_font_size_override("font_size", 18)
	nm.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	vb.add_child(nm)

	var sub := Label.new()
	sub.text = "TERBAIK %s" % str(_ctx.get("comp_best_title", "PIALA ELITE"))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_override("font", UITheme.get_display_font())
	sub.add_theme_font_size_override("font_size", 11)
	sub.add_theme_color_override("font_color", Color("#60A5FA") if is_el else Color("#FACC15"))
	vb.add_child(sub)

	_comp_rating_lbl = Label.new()
	var start_v: int = maxi(50, int(_ctx.get("rating_x10", 89)) - 12)
	_comp_rating_lbl.text = str(start_v)
	_comp_rating_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_comp_rating_lbl.add_theme_font_override("font", UITheme.get_display_font())
	_comp_rating_lbl.add_theme_font_size_override("font_size", 36)
	_comp_rating_lbl.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	vb.add_child(_comp_rating_lbl)

	var cap := Label.new()
	cap.text = "RATING MUSIMMU (x10)"
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.add_theme_font_size_override("font_size", 9)
	cap.add_theme_color_override("font_color", Color("#94A3B8"))
	vb.add_child(cap)

	# 3-Col Competition Stats Row (GOL | ASSIST | LAGA)
	var stat_hb := HBoxContainer.new()
	stat_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	stat_hb.add_theme_constant_override("separation", 34)
	vb.add_child(stat_hb)
	for item in [
		[str(int(_ctx.get("comp_goals", 8))), "GOL", Color("#60A5FA")],
		[str(int(_ctx.get("comp_assists", 5))), "ASSIST", Color("#34D399")],
		[str(int(_ctx.get("comp_matches", 9))), "LAGA", Color("#C084FC")],
	]:
		var svb := VBoxContainer.new()
		svb.add_theme_constant_override("separation", 1)
		stat_hb.add_child(svb)
		var vl := Label.new()
		vl.text = str(item[0])
		vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vl.add_theme_font_override("font", UITheme.get_display_font())
		vl.add_theme_font_size_override("font_size", 16)
		vl.add_theme_color_override("font_color", item[2])
		svb.add_child(vl)
		var kl := Label.new()
		kl.text = str(item[1])
		kl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		kl.add_theme_font_size_override("font_size", 8)
		kl.add_theme_color_override("font_color", Color("#94A3B8"))
		svb.add_child(kl)

	var rew_l := Label.new()
	rew_l.text = "+%d PTS SKILL   •   +%s BONUS" % [
		int(_ctx.get("comp_skill_pts", 3)),
		UITheme.format_cash(int(_ctx.get("comp_bonus_cash", 108000))),
	]
	rew_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rew_l.add_theme_font_override("font", UITheme.get_display_font())
	rew_l.add_theme_font_size_override("font_size", 11)
	rew_l.add_theme_color_override("font_color", Color("#FACC15"))
	vb.add_child(rew_l)

	var quote := Label.new()
	quote.text = "Terbaik di kompetisi yang ditonton semua orang."
	quote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quote.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quote.add_theme_font_size_override("font_size", 10)
	quote.add_theme_color_override("font_color", Color("#CBD5E1"))
	vb.add_child(quote)

	var btn: Button = _make_gold_or_crimson_btn("LANJUT", acc)
	btn.pressed.connect(func():
		if not _comp_best_claimed:
			_comp_best_claimed = true
			CareerState.claim_season_end_award_bonus(int(_ctx.get("comp_skill_pts", 3)), int(_ctx.get("comp_bonus_cash", 108000)))
		_next_chapter()
	)
	vb.add_child(btn)

	_right_card.visible = false
	_right_card.size = Vector2(378.0, 260.0)

# ==============================================================================
# PART 2 GRAND THEATER GALA CARDS (GOL TERBAIK, ANAK EMAS U-21, PEMAIN TERBAIK DUNIA)
# ==============================================================================
func _get_theater_nominees(ch_id: int) -> Array:
	match ch_id:
		CH_BEST_GOAL: return _ctx.get("best_goal_top3", [])
		CH_GOLDEN_BOY: return _ctx.get("golden_boy_top5", [])
		_: return _ctx.get("world_best_top10", [])

func _get_theater_reveal_time(ch_id: int) -> float:
	match ch_id:
		CH_BEST_GOAL: return 4.8
		CH_GOLDEN_BOY: return 6.2
		_: return 8.4

func _claim_part2_trophy_if_won(ch_id: int) -> void:
	if bool(_part2_claimed.get(ch_id, false)):
		return
	_part2_claimed[ch_id] = true
	var cal_yr: int = int(_ctx.get("calendar_year", 2026))
	if ch_id == CH_BEST_GOAL and int(_ctx.get("best_goal_user_rank", -1)) == 1:
		CareerState.claim_season_end_trophy("GOL TERBAIK DUNIA %d" % cal_yr, 40, 2)
	elif ch_id == CH_GOLDEN_BOY and int(_ctx.get("golden_boy_user_rank", -1)) == 1:
		CareerState.claim_season_end_trophy("ANAK EMAS U-21 %d" % cal_yr, 35, 2)
	elif ch_id == CH_WORLD_BEST and int(_ctx.get("world_best_user_rank", -1)) == 1:
		CareerState.claim_season_end_trophy("BALLON D'OR DUNIA %d" % cal_yr, 60, 3)

func _build_theater_award_card(ch_id: int) -> void:
	_clear_right_card()
	_card_target_w = 384.0
	var noms: Array = _get_theater_nominees(ch_id)
	var winner: Dictionary = noms[0] if not noms.is_empty() else {"name": str(_ctx.get("player_name", "BINTANG")), "club": str(_ctx.get("club_name", "KLUB")), "style": "SALTO", "minute": 78, "goals": 32, "assists": 10, "rating": 8.6, "trophies": 2, "is_user": true}
	var is_u_win: bool = bool(winner.get("is_user", false))

	_right_card = PanelContainer.new()
	_right_card.custom_minimum_size = Vector2(384, 0)
	var sb: StyleBoxFlat = UITheme.make_box(Color(0.08, 0.08, 0.10, 0.93), Color("#EAB308"), 1, 8)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 15
	sb.content_margin_bottom = 15
	_right_card.add_theme_stylebox_override("panel", sb)
	_overlay_layer.add_child(_right_card)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	_right_card.add_child(vb)

	var nm := Label.new()
	nm.text = str(winner.get("name", "JUARA")).to_upper()
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.add_theme_font_override("font", UITheme.get_display_font())
	nm.add_theme_font_size_override("font_size", 19)
	nm.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	vb.add_child(nm)

	var sub := Label.new()
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_override("font", UITheme.get_display_font())
	sub.add_theme_font_size_override("font_size", 11)
	sub.add_theme_color_override("font_color", Color("#FACC15"))
	if ch_id == CH_BEST_GOAL:
		sub.text = "GOL TERINDAH  •  %s" % str(winner.get("club", "KLUB"))
	elif ch_id == CH_GOLDEN_BOY:
		if is_u_win:
			var w_cnt: int = int(_ctx.get("golden_boy_prev_wins", 0)) + 1
			sub.text = "ANAK EMAS PERTAMAMU" if w_cnt == 1 else "ANAK EMAS KE-%d" % w_cnt
		else:
			sub.text = "BINTANG MUDA  •  %s" % str(winner.get("club", "KLUB"))
	else:
		sub.text = "TERBAIK DUNIA  •  %s" % str(winner.get("club", "KLUB"))
	vb.add_child(sub)

	if ch_id == CH_BEST_GOAL:
		var detail := Label.new()
		detail.text = "%s   •   %d'" % [str(winner.get("style", "VOLI")), int(winner.get("minute", 16))]
		detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		detail.add_theme_font_override("font", UITheme.get_display_font())
		detail.add_theme_font_size_override("font_size", 15)
		detail.add_theme_color_override("font_color", Color("#E2E8F0"))
		vb.add_child(detail)
	else:
		var stats_l := Label.new()
		var r_txt: String = ("%.1f" % float(winner.get("rating", 8.5))).replace(".", ",")
		stats_l.text = "%d GOL  •  %d AST  •  %s RTG" % [
			int(winner.get("goals", 30)),
			int(winner.get("assists", 10)),
			r_txt,
		]
		stats_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stats_l.add_theme_font_override("font", UITheme.get_display_font())
		stats_l.add_theme_font_size_override("font_size", 12)
		stats_l.add_theme_color_override("font_color", Color("#F8FAFC"))
		vb.add_child(stats_l)

		var tr_n: int = maxi(0, int(winner.get("trophies", 1)))
		var tr_badge := Label.new()
		tr_badge.text = "%d TROFI MUSIM INI   •   %d PTS" % [tr_n, int(winner.get("pts", 150))]
		tr_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tr_badge.add_theme_font_size_override("font_size", 10)
		tr_badge.add_theme_color_override("font_color", Color("#FDE047"))
		vb.add_child(tr_badge)

	var quote := Label.new()
	quote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quote.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quote.add_theme_font_size_override("font_size", 11)
	quote.add_theme_color_override("font_color", Color("#CBD5E1"))
	if ch_id == CH_BEST_GOAL:
		var ur_bg: int = int(_ctx.get("best_goal_user_rank", -1))
		if is_u_win:
			quote.text = "Gol terindah dunia musim ini resmi milikmu! (+40 Warisan • +2 Pts Skill)"
		elif ur_bg > 0:
			quote.text = "Kamu finis ke-%d dalam nominasi Gol Terbaik tahun ini." % ur_bg
		else:
			quote.text = "Cetak gol SALTO atau VOLI saat serangan balik untuk menembus nominasi!"
	elif ch_id == CH_GOLDEN_BOY:
		var ur_gb: int = int(_ctx.get("golden_boy_user_rank", -1))
		if is_u_win:
			quote.text = "Tak ada tim yang mengangkat ini untukmu. Ini dimenangkan sendirian. (+35 Warisan • +2 Pts Skill)"
		elif ur_gb > 0:
			quote.text = "Kamu finis ke-%d, di belakang %s." % [ur_gb, str(winner.get("name", "Juara"))]
		else:
			quote.text = "Penghargaan khusus bintang muda dunia di bawah usia 21 tahun."
	else:
		var ur_wb: int = int(_ctx.get("world_best_user_rank", -1))
		if is_u_win:
			quote.text = "Puncak tertinggi sepak bola dunia kini di tanganmu! (+60 Warisan • +3 Pts Skill)"
		elif ur_wb > 0:
			quote.text = "Kamu finis ke-%d, di belakang %s." % [ur_wb, str(winner.get("name", "Juara"))]
		else:
			quote.text = "Terus kumpulkan gol, trofi, dan rating untuk menembus 10 besar dunia."
	vb.add_child(quote)

	var ch_copy: int = ch_id
	var btn: Button = _make_gold_or_crimson_btn("LANJUT", Color("#EAB308"))
	btn.pressed.connect(func():
		_claim_part2_trophy_if_won(ch_copy)
		_next_chapter()
	)
	vb.add_child(btn)

	_right_card.visible = false
	_right_card.size = Vector2(384.0, 215.0)

func _spawn_theater_seat_row(focus_nom: Dictionary, seed_salt: int) -> void:
	_clear_actors()
	var kit := {"primary": _pri(), "secondary": _sec(), "pattern": str(_ctx.get("pattern", "stripes"))}
	# 5 suited tuxedo gala attendees seated in crimson velvet chairs (center idx 2 = spotlighted nominee!)
	for i in range(5):
		var av: PixelAvatar
		if i == 2 and bool(focus_nom.get("is_user", false)):
			av = _make_user_avatar(Vector2(98, 160), true, "IDLE")
		else:
			av = PixelAvatar.new()
			av.size = Vector2(98, 160) if i == 2 else Vector2(90, 146)
			var sd: int = int(focus_nom.get("seed", 511)) if i == 2 else (seed_salt + i * 97)
			av.configure_from_seed(sd, kit, 10)
			av.casual_style = 2
			av.anim_mode = "IDLE" if i == 2 else "CHEER"
			av.anim_phase = float(i) * 0.45
			av.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_actor_layer.add_child(av)
		_theater_seat_avs.append(av)

func _spawn_theater_winner_actor(winner: Dictionary) -> void:
	_clear_actors()
	var kit := {"primary": _pri(), "secondary": _sec(), "pattern": str(_ctx.get("pattern", "stripes"))}
	if bool(winner.get("is_user", false)):
		_theater_winner_av = _make_user_avatar(Vector2(106, 174), true, "CHEER")
	else:
		_theater_winner_av = PixelAvatar.new()
		_theater_winner_av.size = Vector2(106, 174)
		_theater_winner_av.configure_from_seed(int(winner.get("seed", 811)), kit, 10)
		_theater_winner_av.casual_style = 2
		_theater_winner_av.anim_mode = "CHEER"
		_theater_winner_av.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_actor_layer.add_child(_theater_winner_av)

# ==============================================================================
# PART 3 CARDS, BROADCAST BARS & SEASON RECAP LAUNCHER (CHAPTERS 7..12)
# ==============================================================================
func _make_bottom_broadcast_bar(border_col: Color) -> HBoxContainer:
	_clear_right_card()
	_bottom_bar = PanelContainer.new()
	var sb: StyleBoxFlat = UITheme.make_box(Color(0.06, 0.07, 0.11, 0.94), border_col, 1, 6)
	sb.border_width_top = 2
	sb.content_margin_left = 18
	sb.content_margin_right = 16
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	_bottom_bar.add_theme_stylebox_override("panel", sb)
	_bottom_bar.visible = false
	_overlay_layer.add_child(_bottom_bar)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 18)
	_bottom_bar.add_child(hb)
	return hb

func _build_election_bar() -> void:
	var inc_won: bool = bool(_ctx.get("election_incumbent_won", true))
	var pres_p: int = int(_ctx.get("president_pct", 61))
	var chal_p: int = int(_ctx.get("challenger_pct", 39))
	var hb: HBoxContainer = _make_bottom_broadcast_bar(Color("#EAB308") if inc_won else Color("#EF4444"))

	var lv := VBoxContainer.new()
	lv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lv.add_theme_constant_override("separation", 2)
	hb.add_child(lv)

	var t1 := Label.new()
	t1.text = "PRESIDEN TERPILIH KEMBALI" if inc_won else "PRESIDEN BARU TERPILIH"
	t1.add_theme_font_override("font", UITheme.get_display_font())
	t1.add_theme_font_size_override("font_size", 15)
	t1.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	lv.add_child(t1)

	var t2 := Label.new()
	t2.text = "%s  •  PRESIDEN %d%% vs CALON %d%%  •  %s" % [
		str(_ctx.get("club_name", "KLUB")), pres_p, chal_p,
		"KAMU DISORAKI SUPORTER" if inc_won else "ARAH BARU MANAJEMEN KLUB",
	]
	t2.add_theme_font_size_override("font_size", 11)
	t2.add_theme_color_override("font_color", Color("#CBD5E1"))
	lv.add_child(t2)

	var btn: Button = _make_gold_or_crimson_btn("LANJUT", Color("#EAB308"))
	btn.custom_minimum_size = Vector2(146, 40)
	btn.pressed.connect(_next_chapter)
	hb.add_child(btn)

func _select_timnas_jersey(num: int) -> void:
	_timnas_selected_no = num
	_timnas_jersey_confirmed = true
	CareerState.set_intl_jersey_number(num)
	AudioSynth.play_achievement()
	if _timnas_big_num_lbl != null and is_instance_valid(_timnas_big_num_lbl):
		_timnas_big_num_lbl.text = str(num)
	if _timnas_picker_box != null and is_instance_valid(_timnas_picker_box):
		_timnas_picker_box.visible = false
	if _timnas_confirm_lbl != null and is_instance_valid(_timnas_confirm_lbl):
		_timnas_confirm_lbl.text = "NO. %d MILIKMU SAMPAI TURNAMEN LAGI" % num
		_timnas_confirm_lbl.visible = true

func _build_timnas_card(called: bool) -> void:
	_clear_right_card()
	_card_target_w = 392.0
	_right_card = PanelContainer.new()
	_right_card.custom_minimum_size = Vector2(392, 0)
	var b_col: Color = Color("#EAB308") if called else Color("#64748B")
	var sb: StyleBoxFlat = UITheme.make_box(Color(0.08, 0.08, 0.10, 0.93), b_col, 1, 8)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	_right_card.add_theme_stylebox_override("panel", sb)
	_overlay_layer.add_child(_right_card)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	_right_card.add_child(vb)

	var hdr := Label.new()
	hdr.text = str(_ctx.get("timnas_tournament", "MUNDIAL")) if called else ("TIMNAS %s" % str(_ctx.get("timnas_nation_name", "INDONESIA")))
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr.add_theme_font_override("font", UITheme.get_display_font())
	hdr.add_theme_font_size_override("font_size", 18)
	hdr.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	vb.add_child(hdr)

	var sub := Label.new()
	sub.text = str(_ctx.get("timnas_status", "INTI DI TIMNASMU")) if called else "TIDAK DIPANGGIL TIMNAS"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_override("font", UITheme.get_display_font())
	sub.add_theme_font_size_override("font_size", 11)
	sub.add_theme_color_override("font_color", Color("#FACC15") if called else Color("#F87171"))
	vb.add_child(sub)

	if called:
		_timnas_big_num_lbl = Label.new()
		_timnas_big_num_lbl.text = str(_timnas_selected_no)
		_timnas_big_num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_timnas_big_num_lbl.add_theme_font_override("font", UITheme.get_display_font())
		_timnas_big_num_lbl.add_theme_font_size_override("font_size", 32)
		_timnas_big_num_lbl.add_theme_color_override("font_color", Color("#FDE047"))
		vb.add_child(_timnas_big_num_lbl)

		var q := Label.new()
		q.text = "Satu karier hanya muat tiga atau empat. Ini salah satunya."
		q.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		q.add_theme_font_size_override("font_size", 11)
		q.add_theme_color_override("font_color", Color("#CBD5E1"))
		vb.add_child(q)

		# Interactive Jersey Number Picker (PILIH NOMOR: 3 options + AKU TETAP X)
		var pvb := VBoxContainer.new()
		pvb.add_theme_constant_override("separation", 6)
		vb.add_child(pvb)
		_timnas_picker_box = pvb

		var pk_lbl := Label.new()
		pk_lbl.text = "PILIH NOMOR PUNGGUNG TIMNAS"
		pk_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pk_lbl.add_theme_font_size_override("font_size", 9)
		pk_lbl.add_theme_color_override("font_color", Color("#94A3B8"))
		pvb.add_child(pk_lbl)

		var num_hb := HBoxContainer.new()
		num_hb.add_theme_constant_override("separation", 8)
		pvb.add_child(num_hb)
		var choices: Array = _ctx.get("timnas_jersey_choices", [7, 11, 19])
		for cn in choices:
			var n_val: int = int(cn)
			var nb := Button.new()
			nb.text = str(n_val)
			nb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			nb.custom_minimum_size = Vector2(0, 32)
			UITheme.style_btn(nb, Color("#131A29"), Color("#64748B"), 13)
			nb.pressed.connect(func(): _select_timnas_jersey(n_val))
			num_hb.add_child(nb)

		var keep_no: int = _timnas_selected_no
		var keep_btn := Button.new()
		keep_btn.text = "AKU TETAP NO. %d" % keep_no
		keep_btn.custom_minimum_size = Vector2(0, 32)
		UITheme.style_btn(keep_btn, Color("#0C253A"), Color("#38BDF8"), 11)
		keep_btn.pressed.connect(func(): _select_timnas_jersey(keep_no))
		pvb.add_child(keep_btn)

		_timnas_confirm_lbl = Label.new()
		_timnas_confirm_lbl.text = "NO. %d MILIKMU SAMPAI TURNAMEN LAGI" % keep_no
		_timnas_confirm_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_timnas_confirm_lbl.add_theme_font_override("font", UITheme.get_display_font())
		_timnas_confirm_lbl.add_theme_font_size_override("font_size", 11)
		_timnas_confirm_lbl.add_theme_color_override("font_color", Color("#FACC15"))
		_timnas_confirm_lbl.visible = false
		vb.add_child(_timnas_confirm_lbl)
	else:
		# Branch B: TIDAK DIPANGGIL TIMNAS — Clear OVR/Rating requirement comparison!
		var req_hb := HBoxContainer.new()
		req_hb.alignment = BoxContainer.ALIGNMENT_CENTER
		req_hb.add_theme_constant_override("separation", 24)
		vb.add_child(req_hb)
		var r_you_s: String = ("%.1f" % float(_ctx.get("timnas_rtg_you", 6.4))).replace(".", ",")
		var r_req_s: String = ("%.1f" % float(_ctx.get("timnas_rtg_req", 7.0))).replace(".", ",")
		for pair in [
			[r_you_s, "RATINGMU (SYARAT %s)" % r_req_s, Color("#F87171")],
			["%d" % int(round(float(_ctx.get("timnas_level_you", 58.0)))), "LEVEL (TARGET %d)" % int(_ctx.get("timnas_level_req", 66)), Color("#94A3B8")],
		]:
			var sv := VBoxContainer.new()
			sv.add_theme_constant_override("separation", 1)
			req_hb.add_child(sv)
			var vl := Label.new()
			vl.text = str(pair[0])
			vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			vl.add_theme_font_override("font", UITheme.get_display_font())
			vl.add_theme_font_size_override("font_size", 22)
			vl.add_theme_color_override("font_color", pair[2])
			sv.add_child(vl)
			var kl := Label.new()
			kl.text = str(pair[1])
			kl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			kl.add_theme_font_size_override("font_size", 9)
			kl.add_theme_color_override("font_color", Color("#94A3B8"))
			sv.add_child(kl)

		var q_no := Label.new()
		q_no.text = "Pelatih timnas memilih pemain lain untuk turnamen ini. Tingkatkan rating dan OVR musim depan agar namamu tak bisa diabaikan."
		q_no.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		q_no.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		q_no.add_theme_font_size_override("font_size", 11)
		q_no.add_theme_color_override("font_color", Color("#CBD5E1"))
		vb.add_child(q_no)

	var btn: Button = _make_gold_or_crimson_btn("LANJUT", Color("#EAB308") if called else Color("#94A3B8"))
	btn.pressed.connect(_next_chapter)
	vb.add_child(btn)

	_right_card.visible = false
	_right_card.size = Vector2(392.0, 270.0)

func _build_club_summit_card() -> void:
	_clear_right_card()
	_card_target_w = 342.0
	_right_card = PanelContainer.new()
	_right_card.custom_minimum_size = Vector2(342, 0)
	var pri: Color = _pri()
	var sb: StyleBoxFlat = UITheme.make_box(Color(pri.r * 0.25 + 0.06, pri.g * 0.14 + 0.05, pri.b * 0.16 + 0.07, 0.90), Color(1.0, 1.0, 1.0, 0.20), 1, 8)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	_right_card.add_theme_stylebox_override("panel", sb)
	_overlay_layer.add_child(_right_card)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	_right_card.add_child(vb)

	var hdr := Label.new()
	hdr.text = "SUARA"
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr.add_theme_font_override("font", UITheme.get_display_font())
	hdr.add_theme_font_size_override("font_size", 18)
	hdr.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	vb.add_child(hdr)

	var cl := Label.new()
	cl.text = str(_ctx.get("club_name", "KLUB"))
	cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cl.add_theme_font_size_override("font_size", 10)
	cl.add_theme_color_override("font_color", Color("#CBD5E1"))
	vb.add_child(cl)

	var stat_hb := HBoxContainer.new()
	stat_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	stat_hb.add_theme_constant_override("separation", 24)
	vb.add_child(stat_hb)
	for pair in [
		[str(int(_ctx.get("coach_relation", 81))), "HUBUNGAN", 15, Color("#E2E8F0")],
		["%d/6" % int(_ctx.get("suara_level", 2)), "STATUS", 24, Color("#FFFFFF")],
		["ke-%d" % int(_ctx.get("club_seasons", 2)), "MUSIM", 15, Color("#E2E8F0")],
	]:
		var sv := VBoxContainer.new()
		sv.alignment = BoxContainer.ALIGNMENT_CENTER
		sv.add_theme_constant_override("separation", 1)
		stat_hb.add_child(sv)
		var vl := Label.new()
		vl.text = str(pair[0])
		vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vl.add_theme_font_override("font", UITheme.get_display_font())
		vl.add_theme_font_size_override("font_size", int(pair[2]))
		vl.add_theme_color_override("font_color", pair[3])
		sv.add_child(vl)
		var kl := Label.new()
		kl.text = str(pair[1])
		kl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		kl.add_theme_font_size_override("font_size", 8)
		kl.add_theme_color_override("font_color", Color("#94A3B8"))
		sv.add_child(kl)

	var unlocked: bool = bool(_ctx.get("usul_transfer_unlocked", true))
	var perk := Label.new()
	perk.text = "✓  USUL TRANSFER AKTIF" if unlocked else "X  USUL TRANSFER (BUTUH STATUS 2/6)"
	perk.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	perk.add_theme_font_override("font", UITheme.get_display_font())
	perk.add_theme_font_size_override("font_size", 10)
	perk.add_theme_color_override("font_color", Color("#FACC15") if unlocked else Color("#94A3B8"))
	vb.add_child(perk)

	var btn: Button = _make_gold_or_crimson_btn("LANJUT", pri.lightened(0.25))
	btn.pressed.connect(_next_chapter)
	vb.add_child(btn)

	_right_card.visible = false
	_right_card.size = Vector2(342.0, 200.0)

func _build_tv_debate_bar() -> void:
	var rv: Dictionary = _ctx.get("rival", {})
	var rv_nm: String = str(rv.get("name", "FREDDIE DUNMORE")).to_upper()
	var u_pct: int = int(_ctx.get("debate_user_pct", 78))
	var u_g: int = int(_ctx.get("season_goals", 24))
	var r_g: int = int(rv.get("goals", 16))
	var hb: HBoxContainer = _make_bottom_broadcast_bar(Color("#EF4444"))

	var lv := VBoxContainer.new()
	lv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lv.add_theme_constant_override("separation", 2)
	hb.add_child(lv)

	var t1 := Label.new()
	t1.text = "DEBAT DIMULAI"
	t1.add_theme_font_override("font", UITheme.get_display_font())
	t1.add_theme_font_size_override("font_size", 16)
	t1.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	lv.add_child(t1)

	var t2 := Label.new()
	t2.text = "%s  •  Di TV mereka tak sepakat: bukan kamu, bukan dia." % rv_nm
	t2.add_theme_font_size_override("font_size", 10)
	t2.add_theme_color_override("font_color", Color("#CBD5E1"))
	lv.add_child(t2)

	for pair in [["%d%%" % u_pct, "KAMU DI DEBAT", Color("#F87171")], ["%d-%d" % [u_g, r_g], "GOL TAHUN INI", Color("#F8FAFC")]]:
		var sv := VBoxContainer.new()
		sv.alignment = BoxContainer.ALIGNMENT_CENTER
		sv.add_theme_constant_override("separation", 0)
		hb.add_child(sv)
		var vl := Label.new()
		vl.text = str(pair[0])
		vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vl.add_theme_font_override("font", UITheme.get_display_font())
		vl.add_theme_font_size_override("font_size", 16)
		vl.add_theme_color_override("font_color", pair[2])
		sv.add_child(vl)
		var kl := Label.new()
		kl.text = str(pair[1])
		kl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		kl.add_theme_font_size_override("font_size", 8)
		kl.add_theme_color_override("font_color", Color("#94A3B8"))
		sv.add_child(kl)

	var btn: Button = _make_gold_or_crimson_btn("LANJUT", Color("#EF4444"))
	btn.custom_minimum_size = Vector2(138, 40)
	btn.pressed.connect(_next_chapter)
	hb.add_child(btn)

func _build_best_xi_bar() -> void:
	var in_xi: bool = bool(_ctx.get("in_best_xi", true))
	var hb: HBoxContainer = _make_bottom_broadcast_bar(Color("#FACC15") if in_xi else Color("#60A5FA"))

	var lv := VBoxContainer.new()
	lv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lv.add_theme_constant_override("separation", 2)
	hb.add_child(lv)

	var t1 := Label.new()
	t1.text = "KAMU MASUK INTI" if in_xi else "TIM TERBAIK MUSIM"
	t1.add_theme_font_override("font", UITheme.get_display_font())
	t1.add_theme_font_size_override("font_size", 16)
	t1.add_theme_color_override("font_color", Color("#FACC15") if in_xi else UITheme.TEXT_WHITE)
	lv.add_child(t1)

	var t2 := Label.new()
	t2.text = "%s • MUSIM %d  •  %s" % [
		str(_ctx.get("club_name", "KLUB")), int(_ctx.get("season_num", 1)),
		"Masuk sebelas terbaik liga. TV menjadikanmu contoh." if in_xi else "Sebelas bintang terbaik liga musim ini telah diumumkan.",
	]
	t2.add_theme_font_size_override("font_size", 10)
	t2.add_theme_color_override("font_color", Color("#CBD5E1"))
	lv.add_child(t2)

	var btn: Button = _make_gold_or_crimson_btn("LANJUT", Color("#FACC15"))
	btn.custom_minimum_size = Vector2(138, 40)
	btn.pressed.connect(_next_chapter)
	hb.add_child(btn)

func _open_recap_board() -> void:
	_clear_right_card()
	var scr: GDScript = load("res://scenes/modals/SeasonRecapBoard.gd") as GDScript
	if scr == null or not scr.can_instantiate():
		_finish_ceremony()
		return
	_recap_board = scr.new()
	_recap_board.call("configure", _ctx)
	_recap_board.set_anchors_preset(Control.PRESET_FULL_RECT)
	_recap_board.connect("continue_pressed", _finish_ceremony)
	_overlay_layer.add_child(_recap_board)
	_card_revealed = true

func _make_gold_or_crimson_btn(txt: String, border_col: Color) -> Button:
	var btn := Button.new()
	btn.text = txt.to_upper()
	btn.custom_minimum_size = Vector2(0, 40)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var n := StyleBoxFlat.new()
	n.bg_color = Color("#0C0F18")
	n.border_color = border_col
	n.set_border_width_all(1)
	n.border_width_bottom = 4
	n.set_corner_radius_all(4)
	var h: StyleBoxFlat = n.duplicate()
	h.bg_color = Color("#181E30")
	h.border_color = border_col.lightened(0.25)
	var pr: StyleBoxFlat = n.duplicate()
	pr.bg_color = Color("#080A10")
	btn.add_theme_stylebox_override("normal", n)
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_stylebox_override("pressed", pr)
	btn.add_theme_stylebox_override("focus", h)
	btn.add_theme_font_override("font", UITheme.get_display_font())
	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	return btn

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
			if _card_revealed:
				if _cur_ch == CH_CLUB_GALA and not _gala_claimed:
					_gala_claimed = true
					CareerState.claim_season_end_award_bonus(int(_ctx.get("gala_skill_pts", 2)), int(_ctx.get("gala_bonus_cash", 27000)))
				elif _cur_ch == CH_COMP_BEST and not _comp_best_claimed:
					_comp_best_claimed = true
					CareerState.claim_season_end_award_bonus(int(_ctx.get("comp_skill_pts", 3)), int(_ctx.get("comp_bonus_cash", 108000)))
				elif _cur_ch in [CH_BEST_GOAL, CH_GOLDEN_BOY, CH_WORLD_BEST]:
					_claim_part2_trophy_if_won(_cur_ch)
				_next_chapter()
			else:
				_on_skip_intro_beat()
			get_viewport().set_input_as_handled()

# ==============================================================================
# PURE _process FRAME STATE MACHINE
# ==============================================================================
func _process(delta: float) -> void:
	if _closing:
		return
	var dt: float = minf(delta, 0.05)
	_t += dt
	_ch_t += dt

	if _fade_alpha > 0.0:
		_fade_alpha = maxf(0.0, _fade_alpha - dt * 2.1)
	_fade_rect.color = Color(_fade_color.r, _fade_color.g, _fade_color.b, _fade_alpha)

	var vw: float = maxf(size.x, 960.0)
	var vh: float = maxf(size.y, 540.0)

	# Update confetti
	for c in _confetti:
		var ny: float = float(c["y"]) + float(c["vy"]) * dt
		var nx: float = float(c["x"]) + (float(c["vx"]) + sin(_t * 3.0 + float(c["phase"])) * 18.0) * dt
		if ny > vh + 14.0:
			ny = -12.0
			nx = fmod(nx + vw * 1.41, vw)
		c["x"] = nx
		c["y"] = ny

	# Reveal logic per chapter
	match _cur_ch:
		CH_RECORD:
			if _ch_t >= 2.6 and not _card_revealed:
				_card_revealed = true
				_skip_btn.visible = false
				if _right_card != null:
					_right_card.visible = true
				if _user_av != null:
					_user_av.anim_mode = "CHEER"
				AudioSynth.play_goal()

		CH_PARADE:
			if _ch_t >= 2.6 and not _card_revealed:
				_card_revealed = true
				_skip_btn.visible = false
				if _right_card != null:
					_right_card.visible = true

		CH_CLUB_GALA:
			# Beat A (0..2.6): ANGGARAN banner | Beat B (2.6..6.6): 3 positional callouts | Beat C (6.6+): On-Stage + Card
			if _ch_t >= 2.6 and _ch_t < 6.6:
				var c_idx: int = clampi(int((_ch_t - 2.6) / 1.33), 0, 2)
				if c_idx != _gala_callout_idx:
					_gala_callout_idx = c_idx
					AudioSynth.play_click()
					_spawn_gala_callout_actor(c_idx)
			elif _ch_t >= 6.6 and not _card_revealed:
				_card_revealed = true
				_skip_btn.visible = false
				if _gala_extra_av != null and is_instance_valid(_gala_extra_av):
					_gala_extra_av.visible = false
				if _user_av != null:
					_user_av.visible = true
					_user_av.anim_mode = "CHEER"
				if _npc_av != null:
					_npc_av.visible = true
					_npc_av.anim_mode = "TALK"
				if _right_card != null:
					_right_card.visible = true
				AudioSynth.play_goal()

		CH_COMP_BEST:
			if _ch_t >= 2.4 and not _card_revealed:
				_card_revealed = true
				_skip_btn.visible = false
				if _right_card != null:
					_right_card.visible = true
				if _user_av != null:
					_user_av.anim_mode = "CHEER"
				AudioSynth.play_goal()
			if _card_revealed and _comp_rating_lbl != null:
				_comp_rating_t = minf(1.0, _comp_rating_t + dt * 1.3)
				var rp: float = 1.0 - pow(1.0 - _comp_rating_t, 3.0)
				var target_r: int = int(_ctx.get("rating_x10", 89))
				var start_r: int = maxi(50, target_r - 12)
				_comp_rating_lbl.text = str(int(round(lerpf(float(start_r), float(target_r), rp))))

		CH_BEST_GOAL, CH_GOLDEN_BOY, CH_WORLD_BEST:
			var rev_t: float = _get_theater_reveal_time(_cur_ch)
			var noms: Array = _get_theater_nominees(_cur_ch)
			var cd_count: int = maxi(0, noms.size() - 1)
			if _ch_t >= 2.0 and _ch_t < rev_t and cd_count > 0:
				var span: float = maxf(0.5, rev_t - 2.0)
				var step_f: float = clampf((_ch_t - 2.0) / span, 0.0, 0.999)
				var step_i: int = int(floor(step_f * float(cd_count)))
				var nom_idx: int = clampi(noms.size() - 1 - step_i, 1, noms.size() - 1)
				if nom_idx != _theater_countdown_idx:
					_theater_countdown_idx = nom_idx
					AudioSynth.play_click()
					_spawn_theater_seat_row(noms[nom_idx], 311 + _cur_ch * 83 + nom_idx * 37)
			elif _ch_t >= rev_t and not _card_revealed:
				_card_revealed = true
				_skip_btn.visible = false
				var win_d: Dictionary = noms[0] if not noms.is_empty() else {"name": str(_ctx.get("player_name", "BINTANG")), "is_user": true}
				_spawn_theater_winner_actor(win_d)
				if _right_card != null:
					_right_card.visible = true
				AudioSynth.play_goal()

		CH_ELECTION:
			if _ch_t >= 4.6 and not _card_revealed:
				_card_revealed = true
				_skip_btn.visible = false
				if _bottom_bar != null:
					_bottom_bar.visible = true
				if not _election_sound_played:
					_election_sound_played = true
					AudioSynth.play_goal()

		CH_NATIONAL_CALLUP:
			var called: bool = bool(_ctx.get("timnas_called", true))
			if _user_av != null:
				_user_av.visible = (_ch_t < 1.15 or _ch_t >= 3.4)
			if _ch_t >= 3.6 and not _card_revealed:
				_card_revealed = true
				_skip_btn.visible = false
				if _right_card != null:
					_right_card.visible = true
				if _user_av != null:
					_user_av.anim_mode = "CHEER" if called else "IDLE"
				if called:
					AudioSynth.play_goal()
				else:
					AudioSynth.play_click()

		CH_CLUB_SUMMIT:
			if _ch_t >= 2.2 and not _card_revealed:
				_card_revealed = true
				_skip_btn.visible = false
				if _right_card != null:
					_right_card.visible = true
				AudioSynth.play_click()

		CH_TV_DEBATE:
			if _ch_t >= 1.8 and _ch_t < 7.2:
				var p_idx: int = clampi(int((_ch_t - 1.8) / 1.8), 0, 2)
				if p_idx != _tv_pundit_idx:
					_tv_pundit_idx = p_idx
					AudioSynth.play_click()
			elif _ch_t >= 7.2 and not _card_revealed:
				_card_revealed = true
				_skip_btn.visible = false
				if _bottom_bar != null:
					_bottom_bar.visible = true
				AudioSynth.play_achievement()

		CH_TEAM_OF_SEASON:
			if _ch_t >= 4.2 and _ch_t < 8.1:
				var p_idx: int = clampi(int((_ch_t - 4.2) / 1.3), 0, 2)
				if p_idx != _tv_pundit_idx:
					_tv_pundit_idx = p_idx
					AudioSynth.play_click()
			elif _ch_t >= 8.1 and not _card_revealed:
				_card_revealed = true
				_skip_btn.visible = false
				if _bottom_bar != null:
					_bottom_bar.visible = true
				AudioSynth.play_goal()

	# Smooth card slide-in on the right side (shrink-wrapped cleanly, NEVER clips viewport!)
	if _card_revealed and _right_card != null:
		_card_slide = minf(1.0, _card_slide + dt * 3.6)
		var ease_s: float = 1.0 - pow(1.0 - _card_slide, 3.0)
		var min_sz: Vector2 = _right_card.get_combined_minimum_size()
		var card_w: float = minf(maxf(_card_target_w, min_sz.x), vw - 44.0)
		var card_h: float = minf(min_sz.y, vh - 86.0)
		_right_card.size = Vector2(card_w, card_h)
		var target_x: float = vw - card_w - 22.0
		var start_x: float = vw + 26.0
		_right_card.position = Vector2(lerpf(start_x, target_x, ease_s), clampf((vh - card_h) * 0.52, 58.0, vh - card_h - 18.0))

	# Smooth bottom broadcast bar slide-up (CH_ELECTION, CH_TV_DEBATE, CH_TEAM_OF_SEASON!)
	if _card_revealed and _bottom_bar != null:
		_card_slide = minf(1.0, _card_slide + dt * 3.8)
		var ease_b: float = 1.0 - pow(1.0 - _card_slide, 3.0)
		var bar_w: float = vw - 56.0
		var bar_h: float = maxf(64.0, _bottom_bar.get_combined_minimum_size().y)
		_bottom_bar.size = Vector2(bar_w, bar_h)
		var ticker_pad: float = 34.0 if _cur_ch in [CH_TV_DEBATE, CH_TEAM_OF_SEASON] else 14.0
		var target_y: float = vh - bar_h - ticker_pad
		_bottom_bar.position = Vector2(28.0, lerpf(vh + 16.0, target_y, ease_b))

	_position_actors()
	if _bg_canvas != null:
		_bg_canvas.queue_redraw()
	if _fg_canvas != null:
		_fg_canvas.queue_redraw()

func _spawn_gala_callout_actor(callout_idx: int) -> void:
	if _gala_extra_av != null and is_instance_valid(_gala_extra_av):
		_actor_layer.remove_child(_gala_extra_av)
		_gala_extra_av.queue_free()
		_gala_extra_av = null
	var kit := {"primary": _pri(), "secondary": _sec(), "pattern": str(_ctx.get("pattern", "stripes"))}
	if callout_idx == 2:
		_gala_extra_av = _make_user_avatar(Vector2(88, 144), true, "CHEER")
	else:
		var pd: Dictionary = _ctx.get("top_def", {}) if callout_idx == 0 else _ctx.get("top_mid", {})
		_gala_extra_av = PixelAvatar.new()
		_gala_extra_av.size = Vector2(88, 144)
		_gala_extra_av.configure_from_seed(int(pd.get("seed", 411)), kit, 4 + callout_idx * 4)
		_gala_extra_av.casual_style = 2
		_gala_extra_av.anim_mode = "CHEER"
		_gala_extra_av.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_actor_layer.add_child(_gala_extra_av)

func _position_actors() -> void:
	var vw: float = maxf(size.x, 960.0)
	var vh: float = maxf(size.y, 540.0)

	if _cur_ch == CH_RECORD:
		var pan_p: float = clampf((_ch_t - 1.5) / 1.0, 0.0, 1.0)
		var ease_p: float = pan_p * pan_p * (3.0 - 2.0 * pan_p)
		var stage_cx: float = lerpf(vw * 0.50, vw * 0.29, ease_p)
		var foot_y: float = vh * 0.785
		if _user_av != null:
			_user_av.position = Vector2(stage_cx - 108.0 - _user_av.size.x * 0.5, foot_y - _user_av.size.y)
		if _npc_av != null:
			_npc_av.position = Vector2(stage_cx + 108.0 - _npc_av.size.x * 0.5, foot_y - _npc_av.size.y)

	elif _cur_ch == CH_CLUB_GALA:
		if _ch_t >= 2.6 and _ch_t < 6.6:
			if _gala_extra_av != null and is_instance_valid(_gala_extra_av):
				_gala_extra_av.visible = true
				_gala_extra_av.position = Vector2(vw * 0.50 - _gala_extra_av.size.x * 0.5, vh * 0.73 - _gala_extra_av.size.y)
		elif _ch_t >= 6.6:
			var stage_cx: float = vw * 0.26
			var foot_y: float = vh * 0.76
			if _npc_av != null:
				_npc_av.position = Vector2(stage_cx - 64.0 - _npc_av.size.x * 0.5, foot_y - _npc_av.size.y)
			if _user_av != null:
				_user_av.position = Vector2(stage_cx + 38.0 - _user_av.size.x * 0.5, foot_y - _user_av.size.y)

	elif _cur_ch == CH_COMP_BEST:
		var zoom_p: float = clampf(_ch_t / 2.2, 0.0, 1.0)
		var ease_z: float = 1.0 - pow(1.0 - zoom_p, 3.0)
		var pan_p: float = clampf((_ch_t - 2.0) / 0.6, 0.0, 1.0)
		var cx: float = lerpf(vw * 0.45, vw * 0.23, pan_p)
		var sc: float = lerpf(0.32, 1.0, ease_z)
		var foot_y: float = lerpf(vh * 0.56, vh * 0.83, ease_z)
		if _user_av != null:
			_user_av.scale = Vector2(sc, sc)
			_user_av.position = Vector2(cx - _user_av.size.x * 0.5 * sc, foot_y - _user_av.size.y * sc)

	elif _cur_ch in [CH_BEST_GOAL, CH_GOLDEN_BOY, CH_WORLD_BEST]:
		var rev_t: float = _get_theater_reveal_time(_cur_ch)
		if _ch_t >= 2.0 and _ch_t < rev_t:
			var seat_xs: Array[float] = [vw * 0.14, vw * 0.32, vw * 0.50, vw * 0.68, vw * 0.86]
			for i in range(mini(seat_xs.size(), _theater_seat_avs.size())):
				var av: PixelAvatar = _theater_seat_avs[i]
				var y_base: float = vh * (0.78 if i == 2 else 0.76)
				av.position = Vector2(seat_xs[i] - av.size.x * 0.5, y_base - av.size.y)
		elif _ch_t >= rev_t and _theater_winner_av != null:
			var walk_p: float = clampf((_ch_t - rev_t) / 0.55, 0.0, 1.0)
			var wy: float = lerpf(vh * 0.86, vh * 0.78, walk_p)
			_theater_winner_av.position = Vector2(vw * 0.28 - _theater_winner_av.size.x * 0.5, wy - _theater_winner_av.size.y)

	elif _cur_ch == CH_NATIONAL_CALLUP:
		var pan_p: float = clampf((_ch_t - 3.4) / 0.65, 0.0, 1.0)
		var ease_p: float = 1.0 - pow(1.0 - pan_p, 3.0)
		var ux: float = lerpf(vw * 0.56, vw * 0.36, ease_p)
		if _user_av != null:
			_user_av.position = Vector2(ux - _user_av.size.x * 0.5, vh * 0.85 - _user_av.size.y)

	elif _cur_ch == CH_CLUB_SUMMIT:
		var pan_p: float = clampf((_ch_t - 1.7) / 0.65, 0.0, 1.0)
		var ease_p: float = pan_p * pan_p * (3.0 - 2.0 * pan_p)
		var cx: float = lerpf(vw * 0.50, vw * 0.31, ease_p)
		var foot_y: float = vh * 0.90
		if _npc_av != null:
			_npc_av.position = Vector2(cx - 122.0 - _npc_av.size.x * 0.5, foot_y - _npc_av.size.y)
		if _user_av != null:
			_user_av.position = Vector2(cx - _user_av.size.x * 0.5, foot_y - _user_av.size.y)
		if _npc_av2 != null:
			_npc_av2.position = Vector2(cx + 122.0 - _npc_av2.size.x * 0.5, foot_y - _npc_av2.size.y)

# ==============================================================================
# TEST & PREVIEW HOOKS
# ==============================================================================
func get_ceremony_state() -> Dictionary:
	return {
		"chapter": _cur_ch,
		"chapter_pos": _ch_pos,
		"total_chapters": _chapters.size(),
		"ch_t": _ch_t,
		"card_revealed": _card_revealed,
	}

func advance_step_for_test() -> void:
	_enter_chapter_at(_ch_pos + 1, false)

func jump_to_chapter_for_preview(ch_id: int, t_sec: float) -> void:
	var idx: int = _chapters.find(ch_id)
	if idx < 0:
		_chapters.append(ch_id)
		idx = _chapters.size() - 1
	_enter_chapter_at(idx, false)
	_fade_alpha = 0.0
	_fade_rect.color.a = 0.0
	_t = t_sec
	_ch_t = t_sec
	if ch_id == CH_CLUB_GALA and t_sec >= 2.6 and t_sec < 6.6:
		_gala_callout_idx = clampi(int((t_sec - 2.6) / 1.33), 0, 2)
		_spawn_gala_callout_actor(_gala_callout_idx)
	_process(0.016)
	if _card_revealed:
		_card_slide = 1.0
		_comp_rating_t = 1.0
		_process(0.016)

# ==============================================================================
# MINI NATION FLAG BADGE FOR TIMNAS TOP-LEFT PILL
# ==============================================================================
class _MiniFlagBadge extends Control:
	var col_a: Color = Color("#CE1126")
	var col_b: Color = Color("#FFFFFF")
	var is_star_flag: bool = false

	func _draw() -> void:
		var r := Rect2(2.0, 5.0, size.x - 4.0, size.y - 10.0)
		if is_star_flag:
			draw_rect(r, col_a)
			var cx: float = r.position.x + r.size.x * 0.5
			var cy: float = r.position.y + r.size.y * 0.5
			var st := PackedVector2Array()
			for i in range(10):
				var a: float = -PI * 0.5 + float(i) * PI / 5.0
				var rr: float = 5.5 if i % 2 == 0 else 2.4
				st.append(Vector2(cx + cos(a) * rr, cy + sin(a) * rr))
			draw_colored_polygon(st, col_b)
		else:
			draw_rect(Rect2(r.position.x, r.position.y, r.size.x, r.size.y * 0.5), col_a)
			draw_rect(Rect2(r.position.x, r.position.y + r.size.y * 0.5, r.size.x, r.size.y * 0.5), col_b)
		draw_rect(r, Color(1.0, 1.0, 1.0, 0.35), false, 1.0)

# ==============================================================================
# MINI AWARD BADGE FOR PART 2 TOP-LEFT PILL (GOAL FRAME / WINGED BALL / BALLON D'OR)
# ==============================================================================
class _MiniAwardBadge extends Control:
	var kind: String = "BALLON_DOR"

	func _draw() -> void:
		var cx: float = size.x * 0.5
		var cy: float = size.y * 0.5
		var gold := Color("#FACC15")
		if kind == "GOAL_FRAME":
			draw_rect(Rect2(cx - 10.0, cy - 8.0, 20.0, 16.0), gold, false, 2.2)
			draw_circle(Vector2(cx + 3.0, cy - 1.0), 4.0, Color("#FFFFFF"))
		elif kind == "WINGED_BALL":
			var wl := PackedVector2Array([Vector2(cx - 4, cy), Vector2(cx - 12, cy - 6), Vector2(cx - 10, cy + 4)])
			var wr := PackedVector2Array([Vector2(cx + 4, cy), Vector2(cx + 12, cy - 6), Vector2(cx + 10, cy + 4)])
			draw_colored_polygon(wl, gold)
			draw_colored_polygon(wr, gold)
			draw_circle(Vector2(cx, cy), 6.0, Color("#FDE047"))
		else:
			draw_circle(Vector2(cx, cy), 8.5, gold)
			draw_circle(Vector2(cx - 2.5, cy - 2.5), 3.0, Color("#FEF9C3"))

# ==============================================================================
# MINI COMPETITION SHIELD FOR TOP-LEFT PILL
# ==============================================================================
class _MiniCompShield extends Control:
	var accent: Color = Color("#3B82F6")

	func _draw() -> void:
		var cx: float = size.x * 0.5
		var cy: float = size.y * 0.5
		var r: float = minf(size.x, size.y) * 0.44
		var pts := PackedVector2Array([
			Vector2(cx - r * 0.85, cy - r * 0.9), Vector2(cx + r * 0.85, cy - r * 0.9),
			Vector2(cx + r * 0.85, cy + r * 0.15), Vector2(cx, cy + r * 0.95),
			Vector2(cx - r * 0.85, cy + r * 0.15),
		])
		draw_colored_polygon(pts, accent)
		var star := PackedVector2Array()
		for i in range(10):
			var a: float = -PI * 0.5 + float(i) * PI / 5.0
			var rr: float = r * (0.48 if i % 2 == 0 else 0.22)
			star.append(Vector2(cx + cos(a) * rr, cy - 1.0 + sin(a) * rr))
		draw_colored_polygon(star, Color("#0A1324"))

# ==============================================================================
# PROCEDURAL 16-BIT STAGE BACKDROP RENDERER (ALL 4 PART-1 CHAPTERS)
# ==============================================================================
class _SeasonBgCanvas extends Control:
	var owner_modal: Control = null

	func _draw() -> void:
		if owner_modal == null or not is_instance_valid(owner_modal):
			return
		var w: float = maxf(size.x, 960.0)
		var h: float = maxf(size.y, 540.0)
		var ch: int = int(owner_modal.get("_cur_ch"))
		match ch:
			CH_RECORD: _draw_ch0_record_stadium(w, h)
			CH_PARADE: _draw_ch1_city_parade(w, h)
			CH_CLUB_GALA: _draw_ch2_club_gala(w, h)
			CH_COMP_BEST: _draw_ch3_comp_best_pitch(w, h)
			CH_BEST_GOAL, CH_GOLDEN_BOY, CH_WORLD_BEST: _draw_part2_theater_gala(w, h, ch)
			CH_ELECTION: _draw_ch7_election(w, h)
			CH_NATIONAL_CALLUP: _draw_ch8_national_apartment(w, h)
			CH_CLUB_SUMMIT: _draw_ch9_club_summit(w, h)
			CH_TV_DEBATE: _draw_ch10_tv_debate(w, h)
			CH_TEAM_OF_SEASON: _draw_ch11_best_xi(w, h)
			_: draw_rect(Rect2(0.0, 0.0, w, h), Color("#0B121E"))

	func _pri() -> Color:
		return owner_modal.call("_pri")

	func _sec() -> Color:
		return owner_modal.call("_sec")

	func _ctx() -> Dictionary:
		return owner_modal.get("_ctx")

	func _t() -> float:
		return float(owner_modal.get("_t"))

	func _ct() -> float:
		return float(owner_modal.get("_ch_t"))

	func _draw_grad(w: float, y0: float, y1: float, c0: Color, c1: Color, bands: int = 8) -> void:
		var bh: float = (y1 - y0) / float(bands)
		for i in range(bands):
			draw_rect(Rect2(0.0, y0 + float(i) * bh, w, bh + 1.5), c0.lerp(c1, float(i) / float(maxi(1, bands - 1))))

	func _draw_stadium_red_stands(w: float, h: float, led_y: float) -> void:
		var t: float = _t()
		var pri: Color = _pri()
		var sec: Color = _sec()
		_draw_grad(w, 0.0, led_y, Color("#120A0C"), pri.darkened(0.68), 8)
		# Packed glowing supporter dots + club banners (<CLUB_CODE>)
		for r in range(9):
			var ry: float = 20.0 + float(r) * ((led_y - 28.0) / 9.0)
			draw_rect(Rect2(0.0, ry, w, 2.0), Color(0, 0, 0, 0.35))
			for si in range(56):
				var sx: float = 8.0 + float(si) * (w / 56.0) + float((r * 11) % 7)
				var blink: float = 0.45 + 0.35 * sin(t * 4.5 + float(si * 3 + r))
				var col: Color = pri if ((si + r) % 3 != 0) else (sec if (si % 4 == 0) else Color("#FACC15"))
				draw_rect(Rect2(sx, ry - 7.0, 5.0, 6.0), Color(col.r, col.g, col.b, blink * 0.78))
		# Rising soft stadium smoke wisps
		var smoke: Array = owner_modal.get("_smoke")
		for sm in smoke:
			var life: float = fmod(float(sm["off"]) + t * float(sm["spd"]), 1.0)
			var sx: float = float(sm["u"]) * w + sin(t * 1.5 + float(sm["off"]) * 7.0) * 14.0
			var sy: float = led_y - life * 185.0
			draw_circle(Vector2(sx, sy), float(sm["rad"]) * (0.6 + life), Color(0.95, 0.88, 0.82, (1.0 - life) * 0.14))
		# Floating <CLUB_CODE> banners in the stands
		var fdisp: Font = UITheme.get_display_font()
		var code: String = str(_ctx().get("club_code", "BIL"))
		for bi in range(3):
			draw_string(fdisp, Vector2(w * (0.18 + float(bi) * 0.30), led_y * (0.58 - float(bi % 2) * 0.14)), code, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 1, 0.72))

		# Glowing Golden Perimeter LED Boards
		draw_rect(Rect2(0.0, led_y, w, 18.0), Color("#1A140A"))
		draw_rect(Rect2(0.0, led_y + 2.0, w, 14.0), Color("#B89830"))
		var ticker: String = "%s   |   %s   |   " % [str(_ctx().get("league_name", "LIGA UTAMA")), code]
		var tw: float = maxf(240.0, fdisp.get_string_size(ticker, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x)
		var dx: float = -fmod(t * 28.0, tw)
		while dx < w + tw:
			draw_string(fdisp, Vector2(dx, led_y + 12.0), ticker, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("#151108"))
			dx += tw

	# --------------------------------------------------------------------------
	# CHAPTER 0: REKOR (PITCH + FRAMED JERSEY ON EASEL + LEGEND NAMEPLATE)
	# --------------------------------------------------------------------------
	func _draw_ch0_record_stadium(w: float, h: float) -> void:
		var pan_p: float = clampf((_ct() - 1.5) / 1.0, 0.0, 1.0)
		var ease_p: float = pan_p * pan_p * (3.0 - 2.0 * pan_p)
		var cx: float = lerpf(w * 0.50, w * 0.29, ease_p)
		var led_y: float = h * 0.525
		var pitch_y: float = led_y + 18.0

		_draw_stadium_red_stands(w, h, led_y)

		# Night emerald pitch turf
		for si in range(7):
			var sy: float = pitch_y + float(si) * ((h - pitch_y) / 7.0)
			var sh: float = (h - pitch_y) / 7.0 + 1.5
			draw_rect(Rect2(0.0, sy, w, sh), Color("#1D3E1C") if (si % 2 == 0) else Color("#244A22"))
		draw_line(Vector2(0.0, pitch_y + 20.0), Vector2(w, pitch_y + 20.0), Color(1, 1, 1, 0.22), 2.0)

		# Large Framed Commemorative Club Jersey on Golden Easel between Player & Legend!
		var fy: float = h * 0.77
		# Wooden easel tripod legs
		draw_line(Vector2(cx - 26.0, fy - 4.0), Vector2(cx - 12.0, fy - 108.0), Color("#78522D"), 4.0)
		draw_line(Vector2(cx + 26.0, fy - 4.0), Vector2(cx + 12.0, fy - 108.0), Color("#78522D"), 4.0)
		# Golden-rimmed museum display frame
		draw_rect(Rect2(cx - 42.0, fy - 118.0, 84.0, 102.0), Color("#CA8A04"))
		draw_rect(Rect2(cx - 38.0, fy - 114.0, 76.0, 94.0), Color("#F8FAFC"))
		# Commemorative Club Jersey inside frame with Giant Record Number!
		var pri: Color = _pri()
		var sec: Color = _sec()
		draw_rect(Rect2(cx - 26.0, fy - 96.0, 52.0, 56.0), pri)
		draw_rect(Rect2(cx - 34.0, fy - 96.0, 10.0, 22.0), pri)
		draw_rect(Rect2(cx + 24.0, fy - 96.0, 10.0, 22.0), pri)
		draw_rect(Rect2(cx - 14.0, fy - 96.0, 10.0, 56.0), sec)
		draw_rect(Rect2(cx + 4.0, fy - 96.0, 10.0, 56.0), sec)
		draw_rect(Rect2(cx - 18.0, fy - 82.0, 36.0, 26.0), Color("#FFFFFF"))
		var fdisp: Font = UITheme.get_display_font()
		var rec_s: String = str(int(_ctx().get("record_val", 88)))
		var rsz: Vector2 = fdisp.get_string_size(rec_s, HORIZONTAL_ALIGNMENT_CENTER, -1, 16)
		draw_string(fdisp, Vector2(cx - rsz.x * 0.5, fy - 63.0), rec_s, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("#0F172A"))
		# Miniature gold plaque beneath easel
		draw_rect(Rect2(cx - 18.0, fy - 10.0, 36.0, 12.0), Color("#EAB308"))

		# Floating Legend Nameplate above Legend NPC's head (exact Video 1 00:01!)
		var leg_nm: String = str(_ctx().get("prev_legend", "TINO ROLDAN")).to_upper()
		var lsz: Vector2 = fdisp.get_string_size(leg_nm, HORIZONTAL_ALIGNMENT_CENTER, -1, 9)
		var lbx: float = cx + 108.0 - (lsz.x + 14.0) * 0.5
		var lby: float = h * 0.785 - 156.0
		draw_rect(Rect2(lbx, lby, lsz.x + 14.0, 16.0), Color(0.10, 0.14, 0.24, 0.90))
		draw_rect(Rect2(lbx, lby + 15.0, lsz.x + 14.0, 2.0), Color("#38BDF8"))
		draw_string(fdisp, Vector2(lbx + 7.0, lby + 11.5), leg_nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("#FFFFFF"))

	# --------------------------------------------------------------------------
	# CHAPTER 1: PARADE (ILLUMINATED CITY AVENUE + BALCONIES + POLICE + OPEN-TOP BUS)
	# --------------------------------------------------------------------------
	func _draw_ch1_city_parade(w: float, h: float) -> void:
		var t: float = _t()
		var ct: float = _ct()
		var pri: Color = _pri()
		var sec: Color = _sec()
		var street_y: float = h * 0.72

		# Twilight city backdrop + towering apartment facades packed with glowing windows!
		draw_rect(Rect2(0.0, 0.0, w, street_y), Color("#252328"))
		# Multi-story urban building blocks
		for bld in range(6):
			var bx: float = float(bld) * (w / 6.0)
			var bw: float = w / 6.0 - 4.0
			var col_b: Color = Color("#3D3739") if (bld % 2 == 0) else Color("#312C30")
			draw_rect(Rect2(bx, 0.0, bw, street_y), col_b)
			# Lit & balcony windows grid
			for wy in range(7):
				for wx in range(3):
					var rx: float = bx + 12.0 + float(wx) * 46.0
					var ry: float = 16.0 + float(wy) * 50.0
					var lit: bool = ((bld * 13 + wy * 7 + wx * 5) % 3 != 0)
					var wcol: Color = Color("#F8EFE0") if lit else Color("#1D1A20")
					draw_rect(Rect2(rx, ry, 28.0, 32.0), wcol)
					# Supporters cheering from open balconies with club banners!
					if (wy >= 3 and (wx + bld) % 2 == 0):
						draw_rect(Rect2(rx - 3.0, ry + 18.0, 34.0, 14.0), Color("#18151B"))
						draw_circle(Vector2(rx + 9.0, ry + 13.0), 4.0, Color("#E5B793"))
						draw_circle(Vector2(rx + 20.0, ry + 14.0), 4.0, Color("#C9916B"))
						draw_rect(Rect2(rx + 2.0, ry + 20.0, 24.0, 10.0), pri if (wy % 2 == 0) else sec)

		# Giant hanging club & national flags draped down building facades!
		for fi in range(3):
			var fx: float = w * (0.08 + float(fi) * 0.34)
			var fy: float = h * (0.28 + float(fi % 2) * 0.14)
			draw_rect(Rect2(fx, fy, 74.0, 44.0), pri)
			draw_rect(Rect2(fx, fy + 14.0, 74.0, 16.0), sec)
			draw_rect(Rect2(fx, fy, 74.0, 44.0), Color(0, 0, 0, 0.12))

		# Celebratory City Fireworks bursting over the street!
		for fwi in range(3):
			var fwx: float = w * (0.24 + float(fwi) * 0.24)
			var fwy: float = h * (0.22 + float(fwi % 2) * 0.14)
			var fp: float = fmod(t * 0.85 + float(fwi) * 0.34, 1.0)
			var rad: float = fp * 58.0
			var fa: float = maxf(0.0, 1.0 - fp) * 0.85
			for sp in range(14):
				var ang: float = float(sp) * TAU / 14.0
				draw_circle(Vector2(fwx + cos(ang) * rad, fwy + sin(ang) * rad), 2.6, Color(1.0, 0.88, 0.42, fa))

		# Asphalt Parade Avenue
		draw_rect(Rect2(0.0, street_y, w, h - street_y), Color("#1A1C24"))
		draw_line(Vector2(0.0, street_y + 42.0), Vector2(w, street_y + 42.0), Color(1, 1, 1, 0.22), 2.0)

		# ROLLING PARADE CONVOY (smooth slow roll left-to-right then holds nicely on left-center!)
		var roll_p: float = clampf(ct / 2.6, 0.0, 1.0)
		var ease_r: float = 1.0 - pow(1.0 - roll_p, 2.0)
		var bus_x: float = lerpf(w * 0.56, w * 0.30, ease_r)
		var bus_y: float = street_y + 22.0

		# 2 Police Escort Cars leading to the left of the Bus (flashing red & blue sirens!)
		for pi in range(2):
			var px: float = bus_x - 210.0 - float(pi) * 104.0
			var py: float = bus_y + 18.0
			var red_on: bool = sin(t * 16.0 + float(pi) * PI) > 0.0
			draw_rect(Rect2(px - 36.0, py - 14.0, 72.0, 22.0), Color("#E2E8F0"))
			draw_rect(Rect2(px - 36.0, py - 2.0, 72.0, 7.0), Color("#1D4ED8"))
			draw_rect(Rect2(px - 22.0, py - 26.0, 42.0, 14.0), Color("#F8FAFC"))
			draw_rect(Rect2(px - 18.0, py - 24.0, 34.0, 9.0), Color("#0F1D36"))
			draw_circle(Vector2(px - 22.0, py + 10.0), 7.0, Color("#090D16"))
			draw_circle(Vector2(px + 22.0, py + 10.0), 7.0, Color("#090D16"))
			# Flashing Siren Lightbar
			draw_rect(Rect2(px - 8.0, py - 31.0, 8.0, 5.0), Color("#EF4444") if red_on else Color("#7F1D1D"))
			draw_rect(Rect2(px, py - 31.0, 8.0, 5.0), Color("#1D4ED8") if red_on else Color("#38BDF8"))
			draw_circle(Vector2(px + (-4.0 if red_on else 4.0), py - 28.0), 18.0, Color(1.0, 0.2, 0.2, 0.32) if red_on else Color(0.2, 0.72, 1.0, 0.32))

		# GIANT OPEN-TOP DOUBLE-DECKER CHAMPIONSHIP PARADE BUS!
		var bw_bus: float = 252.0
		var bh_bus: float = 92.0
		var bx0: float = bus_x - bw_bus * 0.5
		var by0: float = bus_y - bh_bus + 26.0
		# Lower deck white/club hull & windows
		draw_rect(Rect2(bx0, by0 + 36.0, bw_bus, 54.0), Color("#F1F5F9"))
		draw_rect(Rect2(bx0, by0 + 66.0, bw_bus, 24.0), pri)
		for bwi in range(6):
			draw_rect(Rect2(bx0 + 14.0 + float(bwi) * 38.0, by0 + 42.0, 28.0, 18.0), Color("#1E293B"))
		# Club Name printed boldly along bus side!
		var fdisp: Font = UITheme.get_display_font()
		draw_string(fdisp, Vector2(bx0 + 18.0, by0 + 83.0), str(_ctx().get("club_name", "KLUB")).left(16), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, sec)
		# Tires
		draw_circle(Vector2(bx0 + 46.0, by0 + 92.0), 14.0, Color("#090D16"))
		draw_circle(Vector2(bx0 + bw_bus - 46.0, by0 + 92.0), 14.0, Color("#090D16"))
		# Cheering Squad Players standing along the open upper deck!
		for sqi in range(10):
			var sx: float = bx0 + 22.0 + float(sqi) * 23.0
			var hop: float = absf(sin(t * 6.0 + float(sqi) * 0.7)) * 5.0
			draw_rect(Rect2(sx - 5.0, by0 + 10.0 - hop, 10.0, 18.0), pri if (sqi % 2 == 0) else sec)
			draw_rect(Rect2(sx - 3.5, by0 + 2.0 - hop, 7.0, 8.0), Color("#E5B793"))
			# Golden Trophy hoisted by center player!
			if sqi == 4:
				draw_rect(Rect2(sx - 7.0, by0 - 16.0 - hop, 14.0, 14.0), Color("#FACC15"))
				draw_circle(Vector2(sx, by0 - 10.0 - hop), 11.0, Color(1.0, 0.88, 0.30, 0.25))
		# Open-top bus railing in club primary color with gold trim
		draw_rect(Rect2(bx0, by0 + 18.0, bw_bus, 20.0), pri)
		draw_rect(Rect2(bx0, by0 + 18.0, bw_bus, 3.0), Color("#FACC15"))

		# Dense Packed Street Crowd cheering in front of the parade!
		for ci in range(52):
			var cx_f: float = 8.0 + float(ci) * (w / 52.0)
			var hop: float = absf(sin(t * 5.4 + float(ci) * 0.6)) * 4.5
			var fy: float = h - 22.0 - float(ci % 3) * 14.0 - hop
			draw_rect(Rect2(cx_f - 5.0, fy - 12.0, 10.0, 14.0), pri if (ci % 2 == 0) else sec)
			draw_rect(Rect2(cx_f - 3.5, fy - 19.0, 7.0, 7.0), Color("#DFB08C"))
			if ci % 5 == 0:
				draw_line(Vector2(cx_f + 4.0, fy - 10.0), Vector2(cx_f + 10.0, fy - 34.0), Color("#CBD5E1"), 1.5)
				draw_rect(Rect2(cx_f + 10.0, fy - 34.0, 16.0, 10.0), pri if (ci % 2 == 0) else Color("#FACC15"))

	# --------------------------------------------------------------------------
	# CHAPTER 2: GALA KLUB (BALLROOM -> ANGGARAN BANNER -> 3 CALLOUTS -> ON-STAGE)
	# --------------------------------------------------------------------------
	func _draw_ch2_club_gala(w: float, h: float) -> void:
		var ct: float = _ct()
		var t: float = _t()
		var pri: Color = _pri()
		var sec: Color = _sec()
		var stage_y: float = h * 0.62

		# Grand Crimson-Gold Gala Ballroom walls & ceiling chandeliers
		_draw_grad(w, 0.0, stage_y, Color("#140B0E"), Color("#2E1418"), 8)
		# Ornate golden chandeliers overhead
		for chi in range(3):
			var chx: float = w * (0.20 + float(chi) * 0.30)
			draw_line(Vector2(chx, 0.0), Vector2(chx, 34.0), Color("#CA8A04"), 2.0)
			draw_circle(Vector2(chx, 38.0), 18.0, Color(1.0, 0.90, 0.55, 0.25))
			draw_rect(Rect2(chx - 20.0, 32.0, 40.0, 8.0), Color("#FACC15"))

		# Center Gala Stage Curtain Backdrop (Club Primary + Gold Columns)
		var sx0: float = w * 0.16 if ct < 6.6 else w * 0.05
		var sw: float = w * 0.68 if ct < 6.6 else w * 0.44
		draw_rect(Rect2(sx0, 56.0, sw, stage_y - 56.0), pri.darkened(0.45))
		draw_rect(Rect2(sx0, 56.0, sw, 10.0), Color("#CA8A04"))
		draw_rect(Rect2(sx0, 56.0, 10.0, stage_y - 56.0), Color("#9A6A1F"))
		draw_rect(Rect2(sx0 + sw - 10.0, 56.0, 10.0, stage_y - 56.0), Color("#9A6A1F"))

		# Stage Deck & Grand Ballroom Carpet Floor
		draw_rect(Rect2(0.0, stage_y, w, h - stage_y), Color("#171418"))
		var aisle := PackedVector2Array([
			Vector2(w * 0.44, stage_y), Vector2(w * 0.56, stage_y),
			Vector2(w * 0.64, h), Vector2(w * 0.36, h),
		])
		draw_colored_polygon(aisle, Color("#7F1D1D"))

		var fdisp: Font = UITheme.get_display_font()

		if ct < 2.6:
			# BEAT A: Seated Banquet Tables + Animated ANGGARAN +0% -> +XX% Banner (Video 1 00:41!)
			for ti in range(4):
				var tx: float = w * (0.15 + float(ti) * 0.23)
				var ty: float = h * 0.80
				draw_circle(Vector2(tx, ty), 36.0, Color("#E2E8F0"))
				for gi in range(3):
					var gx: float = tx - 26.0 + float(gi) * 26.0
					draw_rect(Rect2(gx - 7.0, ty - 28.0, 14.0, 22.0), Color("#111622"))
					draw_rect(Rect2(gx - 2.0, ty - 26.0, 4.0, 10.0), Color("#FFFFFF"))
					draw_rect(Rect2(gx - 5.0, ty - 38.0, 10.0, 10.0), Color("#E3B48F"))
			# Center Glowing ANGGARAN Banner with rolling percentage!
			var bx: float = w * 0.50 - 150.0
			var by: float = h * 0.22
			draw_rect(Rect2(bx, by, 300.0, 142.0), Color("#0A0D14"))
			draw_rect(Rect2(bx, by, 300.0, 142.0), Color("#EAB308"), false, 3.0)
			var lbl_a := "ANGGARAN"
			var asz: Vector2 = fdisp.get_string_size(lbl_a, HORIZONTAL_ALIGNMENT_CENTER, -1, 14)
			draw_string(fdisp, Vector2(w * 0.50 - asz.x * 0.5, by + 30.0), lbl_a, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#CBD5E1"))
			var pct_p: float = 1.0 - pow(1.0 - clampf(ct / 1.8, 0.0, 1.0), 3.0)
			var pct_now: int = int(round(float(int(_ctx().get("budget_pct", 16))) * pct_p))
			var pct_s: String = "+%d%%" % pct_now
			var psz: Vector2 = fdisp.get_string_size(pct_s, HORIZONTAL_ALIGNMENT_CENTER, -1, 42)
			draw_string(fdisp, Vector2(w * 0.50 - psz.x * 0.5, by + 90.0), pct_s, HORIZONTAL_ALIGNMENT_LEFT, -1, 42, Color("#FACC15"))
			var pos_s: String = "ke-%d" % int(_ctx().get("league_pos", 4))
			var posz: Vector2 = fdisp.get_string_size(pos_s, HORIZONTAL_ALIGNMENT_CENTER, -1, 14)
			draw_string(fdisp, Vector2(w * 0.50 - posz.x * 0.5, by + 124.0), pos_s, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#E2E8F0"))

		elif ct < 6.6:
			# BEAT B: Giant Stage Screen Calling Out BEK TOP -> GELANDANG TOP -> PENYERANG TOP!
			var c_idx: int = clampi(int((ct - 2.6) / 1.33), 0, 2)
			var cats: Array[String] = ["BEK TOP", "GELANDANG TOP", "PEMAIN TERBAIK MUSIM"]
			var pds: Array[Dictionary] = [_ctx().get("top_def", {}), _ctx().get("top_mid", {}), _ctx().get("top_fwd", {})]
			var pd: Dictionary = pds[c_idx]
			# Giant Stage Projection Screen behind spotlighted player
			var scr_x: float = w * 0.50 - 180.0
			var scr_y: float = 78.0
			draw_rect(Rect2(scr_x, scr_y, 360.0, 152.0), Color("#0B1622"))
			draw_rect(Rect2(scr_x, scr_y, 360.0, 152.0), Color("#22C55E") if c_idx < 2 else Color("#FACC15"), false, 2.5)
			var cat_s: String = cats[c_idx]
			var csz: Vector2 = fdisp.get_string_size(cat_s, HORIZONTAL_ALIGNMENT_CENTER, -1, 12)
			draw_string(fdisp, Vector2(w * 0.50 - csz.x * 0.5, scr_y + 32.0), cat_s, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#FACC15"))
			var pnm: String = str(pd.get("name", "PEMAIN"))
			var nsz: Vector2 = fdisp.get_string_size(pnm, HORIZONTAL_ALIGNMENT_CENTER, -1, 22)
			draw_string(fdisp, Vector2(w * 0.50 - nsz.x * 0.5, scr_y + 76.0), pnm, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, UITheme.TEXT_WHITE)
			var r_s: String = "%s  •  OVR %d  •  rata-rata %s" % [
				str(pd.get("pos", "ST")),
				int(pd.get("ovr", 78)),
				("%.1f" % float(pd.get("rating", 7.5))).replace(".", ","),
			]
			var rsz: Vector2 = fdisp.get_string_size(r_s, HORIZONTAL_ALIGNMENT_CENTER, -1, 12)
			draw_string(fdisp, Vector2(w * 0.50 - rsz.x * 0.5, scr_y + 114.0), r_s, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#93C5FD"))
			# Spotlight beam onto player rising from banquet table!
			var spot := PackedVector2Array([
				Vector2(w * 0.50 - 30.0, 40.0), Vector2(w * 0.50 + 30.0, 40.0),
				Vector2(w * 0.50 + 95.0, h * 0.85), Vector2(w * 0.50 - 95.0, h * 0.85),
			])
			draw_colored_polygon(spot, Color(1.0, 0.94, 0.72, 0.14))

		else:
			# BEAT C: On-Stage Presentation with Club Crest Backdrop, Spotlights & Golden Star Pedestal!
			var scx: float = w * 0.27
			var spot := PackedVector2Array([
				Vector2(scx - 28.0, 40.0), Vector2(scx + 28.0, 40.0),
				Vector2(scx + 125.0, h * 0.86), Vector2(scx - 125.0, h * 0.86),
			])
			draw_colored_polygon(spot, Color(1.0, 0.94, 0.78, 0.14))
			# Golden Star Trophy on wooden stage pedestal to the right of User
			var ped_x: float = scx + 122.0
			var ped_y: float = h * 0.76
			draw_rect(Rect2(ped_x - 20.0, ped_y - 64.0, 40.0, 64.0), Color("#3F2E21"))
			draw_rect(Rect2(ped_x - 22.0, ped_y - 68.0, 44.0, 6.0), Color("#EAB308"))
			var st_pts := PackedVector2Array()
			for si in range(10):
				var ang: float = -PI * 0.5 + float(si) * PI / 5.0
				var rr: float = 20.0 if (si % 2 == 0) else 9.0
				st_pts.append(Vector2(ped_x + cos(ang) * rr, ped_y - 90.0 + sin(ang) * rr))
			draw_colored_polygon(st_pts, Color("#FACC15"))
			draw_circle(Vector2(ped_x, ped_y - 90.0), 26.0 + sin(t * 4.0) * 3.0, Color(1.0, 0.86, 0.28, 0.20))

	# --------------------------------------------------------------------------
	# CHAPTER 3: TERBAIK PIALA ELITE / LIGA (CENTER-CIRCLE ZOOM + PEDESTAL & SHIELD!)
	# --------------------------------------------------------------------------
	func _draw_ch3_comp_best_pitch(w: float, h: float) -> void:
		var ct: float = _ct()
		var t: float = _t()
		var zoom_p: float = clampf(ct / 2.2, 0.0, 1.0)
		var ease_z: float = 1.0 - pow(1.0 - zoom_p, 3.0)
		var pan_p: float = clampf((ct - 2.0) / 0.6, 0.0, 1.0)
		var led_y: float = lerpf(h * 0.24, h * 0.56, ease_z)
		var pitch_y: float = led_y + 18.0

		_draw_stadium_red_stands(w, h, led_y)

		# Emerald Striped Pitch + White Center Circle
		var bands: int = 8
		for si in range(bands):
			var sy: float = pitch_y + float(si) * ((h - pitch_y) / float(bands))
			var sh: float = (h - pitch_y) / float(bands) + 1.5
			draw_rect(Rect2(0.0, sy, w, sh), Color("#165028") if (si % 2 == 0) else Color("#1D6232"))
		var cx: float = lerpf(w * 0.50, w * 0.30, pan_p)
		var foot_y: float = lerpf(h * 0.56, h * 0.83, ease_z)
		draw_arc(Vector2(cx, foot_y - 4.0), lerpf(78.0, 145.0, ease_z), 0.0, TAU, 36, Color(1, 1, 1, 0.25), 2.5)

		# Sleek Black Award Pedestal beside User + Giant Glowing Competition Star Shield Above!
		var is_el: bool = bool(_ctx().get("comp_best_is_elite", true))
		var sh_col: Color = Color("#3B82F6") if is_el else Color("#EAB308")
		var ped_x: float = cx + lerpf(32.0, 82.0, ease_z)
		var psc: float = lerpf(0.36, 1.0, ease_z)
		draw_rect(Rect2(ped_x - 24.0 * psc, foot_y - 74.0 * psc, 48.0 * psc, 74.0 * psc), Color("#111827"))
		draw_rect(Rect2(ped_x - 26.0 * psc, foot_y - 78.0 * psc, 52.0 * psc, 5.0 * psc), sh_col)
		# Golden star award sitting atop pedestal
		draw_circle(Vector2(ped_x, foot_y - 94.0 * psc), 14.0 * psc, Color("#EAB308"))
		draw_circle(Vector2(ped_x, foot_y - 94.0 * psc), 8.0 * psc, Color("#FEF08A"))

		# Giant Floating Glowing Competition Shield Hologram above Pedestal (Video 1 01:22!)
		if ease_z > 0.55:
			var hs: float = clampf((ease_z - 0.55) / 0.45, 0.0, 1.0)
			var sy_h: float = foot_y - 186.0 + sin(t * 3.0) * 5.0
			var sr: float = 48.0 * hs
			var sh_pts := PackedVector2Array([
				Vector2(ped_x - sr * 0.85, sy_h - sr * 0.90),
				Vector2(ped_x + sr * 0.85, sy_h - sr * 0.90),
				Vector2(ped_x + sr * 0.85, sy_h + sr * 0.12),
				Vector2(ped_x, sy_h + sr * 0.98),
				Vector2(ped_x - sr * 0.85, sy_h + sr * 0.12),
			])
			draw_circle(Vector2(ped_x, sy_h), sr * 1.25, Color(sh_col.r, sh_col.g, sh_col.b, 0.22 * hs))
			draw_colored_polygon(sh_pts, Color(sh_col.r, sh_col.g, sh_col.b, 0.88 * hs))
			var st_p := PackedVector2Array()
			for si in range(10):
				var ang: float = -PI * 0.5 + float(si) * PI / 5.0
				var rr: float = sr * (0.48 if si % 2 == 0 else 0.22)
				st_p.append(Vector2(ped_x + cos(ang) * rr, sy_h - 4.0 + sin(ang) * rr))
			draw_colored_polygon(st_p, Color("#0A1324"))

	# --------------------------------------------------------------------------
	# PART 2 GRAND THEATER GALA RENDERER (GOL TERBAIK, ANAK EMAS U-21, BALLON D'OR)
	# --------------------------------------------------------------------------
	func _draw_award_trophy_art(center: Vector2, ch_id: int, sc: float) -> void:
		var t: float = _t()
		var glow: float = 28.0 + sin(t * 4.2) * 4.0
		draw_circle(center, glow * sc, Color(1.0, 0.85, 0.28, 0.22))
		var gold := Color("#EAB308")
		var hi := Color("#FEF08A")
		var dark := Color("#92400E")
		if ch_id == CH_BEST_GOAL:
			# Iconic Golden Goal-Frame & Soccer Ball Trophy (Video 2 00:08 & 00:21!)
			draw_rect(Rect2(center.x - 20.0 * sc, center.y - 18.0 * sc, 40.0 * sc, 30.0 * sc), Color(0.95, 0.95, 1.0, 0.14))
			draw_rect(Rect2(center.x - 20.0 * sc, center.y - 18.0 * sc, 40.0 * sc, 30.0 * sc), gold, false, 3.2 * sc)
			for ni in range(4):
				var nx: float = center.x - 14.0 * sc + float(ni) * 9.0 * sc
				draw_line(Vector2(nx, center.y - 16.0 * sc), Vector2(nx, center.y + 10.0 * sc), Color(1, 1, 1, 0.20), 1.0)
			draw_circle(center + Vector2(6.0 * sc, -4.0 * sc), 7.5 * sc, Color("#F8FAFC"))
			draw_circle(center + Vector2(6.0 * sc, -4.0 * sc), 3.0 * sc, Color("#0F172A"))
			draw_rect(Rect2(center.x - 24.0 * sc, center.y + 12.0 * sc, 48.0 * sc, 6.0 * sc), dark)
		elif ch_id == CH_GOLDEN_BOY:
			# Iconic Winged Golden Ball Trophy (Video 2 00:53!)
			var wl := PackedVector2Array([
				center + Vector2(-8.0 * sc, 2.0 * sc),
				center + Vector2(-34.0 * sc, -16.0 * sc),
				center + Vector2(-28.0 * sc, 6.0 * sc),
				center + Vector2(-12.0 * sc, 10.0 * sc),
			])
			var wr := PackedVector2Array([
				center + Vector2(8.0 * sc, 2.0 * sc),
				center + Vector2(34.0 * sc, -16.0 * sc),
				center + Vector2(28.0 * sc, 6.0 * sc),
				center + Vector2(12.0 * sc, 10.0 * sc),
			])
			draw_colored_polygon(wl, gold)
			draw_colored_polygon(wr, gold)
			draw_circle(center, 15.0 * sc, Color("#F5C430"))
			draw_circle(center + Vector2(-4.0 * sc, -5.0 * sc), 5.0 * sc, hi)
			draw_circle(center, 5.0 * sc, dark)
		else:
			# Iconic Golden Ballon d'Or Globe Trophy (Video 2 01:28!)
			draw_circle(center, 18.0 * sc, Color("#F5C430"))
			draw_circle(center + Vector2(-5.0 * sc, -6.0 * sc), 6.0 * sc, hi)
			for pi in range(5):
				var ang: float = float(pi) * TAU / 5.0 + 0.3
				draw_circle(center + Vector2(cos(ang) * 9.0 * sc, sin(ang) * 9.0 * sc), 2.5 * sc, dark)
			draw_rect(Rect2(center.x - 10.0 * sc, center.y + 16.0 * sc, 20.0 * sc, 6.0 * sc), dark)

	func _draw_part2_theater_gala(w: float, h: float, ch_id: int) -> void:
		var ct: float = _ct()
		var t: float = _t()
		var rev_t: float = float(owner_modal.call("_get_theater_reveal_time", ch_id))
		var noms: Array = owner_modal.call("_get_theater_nominees", ch_id)
		var fdisp: Font = UITheme.get_display_font()

		if ct < 2.0:
			# BEAT A: Grand Dark Theater Auditorium Intro + Sweeping Blue Spotlights + Stage Screen!
			draw_rect(Rect2(0.0, 0.0, w, h), Color("#120A0A"))
			# Warm golden side theater wall sconces
			for si in range(3):
				var sy: float = h * (0.28 + float(si) * 0.14)
				draw_rect(Rect2(24.0 + float(si) * 44.0, sy, 10.0, 18.0), Color("#FEF08A"))
				draw_rect(Rect2(w - 34.0 - float(si) * 44.0, sy, 10.0, 18.0), Color("#FEF08A"))
			# Crimson stage velvet curtains left & right
			draw_rect(Rect2(w * 0.17, 26.0, 74.0, h * 0.62), Color("#580E16"))
			draw_rect(Rect2(w * 0.83 - 74.0, 26.0, 74.0, h * 0.62), Color("#580E16"))
			# Illuminated Golden Backdrop Wall & Award Title Screen
			draw_rect(Rect2(w * 0.25, 36.0, w * 0.50, h * 0.56), Color("#1C1510"))
			draw_rect(Rect2(w * 0.33, 52.0, w * 0.34, 150.0), Color("#14110D"))
			draw_rect(Rect2(w * 0.33, 52.0, w * 0.34, 150.0), Color("#EAB308"), false, 2.5)
			_draw_award_trophy_art(Vector2(w * 0.50, 108.0), ch_id, 1.05)
			var screen_lbl: String = "GOL TERBAIK" if ch_id == CH_BEST_GOAL else ("ANAK EMAS" if ch_id == CH_GOLDEN_BOY else "PEMAIN TERBAIK")
			var ssz: Vector2 = fdisp.get_string_size(screen_lbl, HORIZONTAL_ALIGNMENT_CENTER, -1, 18)
			draw_string(fdisp, Vector2(w * 0.50 - ssz.x * 0.5, 182.0), screen_lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#FDE047"))
			# Sweeping vertical blue/indigo theater spotlights
			for bi in range(4):
				var bx: float = w * (0.20 + float(bi) * 0.20)
				var swp: float = sin(t * 1.8 + float(bi) * 1.4) * 55.0
				var cone := PackedVector2Array([
					Vector2(bx - 16.0, 0.0), Vector2(bx + 16.0, 0.0),
					Vector2(bx + swp + 70.0, h * 0.86), Vector2(bx + swp - 70.0, h * 0.86),
				])
				draw_colored_polygon(cone, Color(0.28, 0.44, 0.96, 0.14))
			# Crimson Stage & Center Golden Pedestal with Trophy
			draw_rect(Rect2(w * 0.20, h * 0.66, w * 0.60, h * 0.34), Color("#4A0F14"))
			draw_rect(Rect2(w * 0.50 - 24.0, h * 0.63, 48.0, 74.0), Color("#926B24"))
			draw_rect(Rect2(w * 0.50 - 28.0, h * 0.61, 56.0, 8.0), Color("#FACC15"))
			_draw_award_trophy_art(Vector2(w * 0.50, h * 0.58), ch_id, 0.80)
			# Dark foreground audience silhouette heads
			for ai in range(9):
				draw_circle(Vector2(w * 0.14 + float(ai) * (w * 0.09), h * 0.90), 22.0, Color("#070609"))

		elif ct < rev_t:
			# BEAT B: Crimson Velvet Theater Seats Countdown (ke-3..2 / ke-5..2 / ke-10..2) with Flashing Cameras!
			_draw_grad(w, 0.0, h, Color("#0E0B10"), Color("#1B141A"), 8)
			# Back audience rows (dimmer tuxedo silhouettes + bright camera flash pops!)
			for row_i in range(2):
				var ry: float = h * (0.28 + float(row_i) * 0.14)
				for si in range(11):
					var sx: float = 42.0 + float(si) * ((w - 84.0) / 10.0)
					draw_rect(Rect2(sx - 18.0, ry - 8.0, 36.0, 32.0), Color("#58121A"))
					draw_rect(Rect2(sx - 12.0, ry - 4.0, 24.0, 28.0), Color("#151923"))
					draw_circle(Vector2(sx, ry - 12.0), 8.0, Color("#B48464"))
					if fmod(t * 3.1 + float(si * 7 + row_i * 3), 1.0) < 0.09:
						draw_circle(Vector2(sx + 10.0, ry - 8.0), 11.0, Color(1.0, 1.0, 1.0, 0.90))
			# Front 5 Crimson Velvet Theater Chairs behind the 5 seated PixelAvatars!
			var seat_xs: Array[float] = [w * 0.14, w * 0.32, w * 0.50, w * 0.68, w * 0.86]
			for i in range(5):
				var sx: float = seat_xs[i]
				draw_rect(Rect2(sx - 44.0, h * 0.46, 88.0, 156.0), Color("#7F1D27"))
				draw_rect(Rect2(sx - 48.0, h * 0.62, 14.0, 74.0), Color("#CA8A04"))
				draw_rect(Rect2(sx + 34.0, h * 0.62, 14.0, 74.0), Color("#CA8A04"))
			# Golden center spotlight beam onto the highlighted nominee!
			var beam := PackedVector2Array([
				Vector2(w * 0.50 - 38.0, 0.0), Vector2(w * 0.50 + 38.0, 0.0),
				Vector2(w * 0.50 + 108.0, h), Vector2(w * 0.50 - 108.0, h),
			])
			draw_colored_polygon(beam, Color(1.0, 0.92, 0.60, 0.14))

		else:
			# BEAT C: Winner On Crimson Stage + Illuminated Giant Winner Name Marquee + Crisscross Gold Spotlights!
			draw_rect(Rect2(0.0, 0.0, w, h), Color("#100B0B"))
			var win_d: Dictionary = noms[0] if not noms.is_empty() else {"name": str(_ctx().get("player_name", "BINTANG"))}
			var win_nm: String = str(win_d.get("name", "JUARA")).to_upper()
			# Golden stage backdrop panel with giant WINNER NAME header (clear of top-left pill!)
			draw_rect(Rect2(w * 0.07, 66.0, w * 0.44, h * 0.54), Color("#1A140E"))
			draw_rect(Rect2(w * 0.07, 66.0, w * 0.44, 48.0), Color("#2B2114"))
			draw_rect(Rect2(w * 0.07, 66.0, w * 0.44, 48.0), Color("#EAB308"), false, 2.0)
			var wnsz: Vector2 = fdisp.get_string_size(win_nm, HORIZONTAL_ALIGNMENT_CENTER, -1, 20)
			draw_string(fdisp, Vector2(w * 0.29 - wnsz.x * 0.5, 98.0), win_nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#FDE047"))
			# Crimson stage carpet
			draw_rect(Rect2(0.0, h * 0.64, w, h * 0.36), Color("#581219"))
			# Crisscross golden celebratory spotlights on stage!
			for side in [-1.0, 1.0]:
				var s_beam := PackedVector2Array([
					Vector2(w * 0.28 + side * 125.0, 0.0), Vector2(w * 0.28 + side * 75.0, 0.0),
					Vector2(w * 0.28 - side * 40.0, h * 0.90), Vector2(w * 0.28 + side * 65.0, h * 0.90),
				])
				draw_colored_polygon(s_beam, Color(1.0, 0.86, 0.32, 0.14))

	# --------------------------------------------------------------------------
	# SHARED HELPER: NATIONAL FLAG DRAWING (HORIZONTAL STRIPES OR STAR FLAG)
	# --------------------------------------------------------------------------
	func _draw_nation_flag_rect(r: Rect2) -> void:
		var cols: Array = _ctx().get("timnas_nation_colors", [Color("#CE1126"), Color("#FFFFFF")])
		var ca: Color = UITheme.parse_color(cols[0] if cols.size() > 0 else Color("#CE1126"), Color("#CE1126"))
		var cb: Color = UITheme.parse_color(cols[1] if cols.size() > 1 else Color("#FFFFFF"), Color("#FFFFFF"))
		var code: String = str(_ctx().get("timnas_nation_code", "IDN")).to_upper()
		if code in ["VIE", "VNM", "CHN", "MAR", "TUR"]:
			draw_rect(r, ca)
			var cx: float = r.position.x + r.size.x * 0.5
			var cy: float = r.position.y + r.size.y * 0.5
			var rad_o: float = minf(r.size.x, r.size.y) * 0.34
			var st := PackedVector2Array()
			for i in range(10):
				var ang: float = -PI * 0.5 + float(i) * PI / 5.0
				var rr: float = rad_o if (i % 2 == 0) else rad_o * 0.44
				st.append(Vector2(cx + cos(ang) * rr, cy + sin(ang) * rr))
			draw_colored_polygon(st, cb)
		else:
			draw_rect(Rect2(r.position.x, r.position.y, r.size.x, r.size.y * 0.5), ca)
			draw_rect(Rect2(r.position.x, r.position.y + r.size.y * 0.5, r.size.x, r.size.y * 0.5), cb)
		draw_rect(r, Color(0.10, 0.12, 0.18, 0.65), false, 1.5)

	# --------------------------------------------------------------------------
	# CHAPTER 7: HASIL PEMILU PRESIDEN KLUB (NIGHT STADIUM -> ZOOM VIP BOX!)
	# --------------------------------------------------------------------------
	func _draw_ch7_election(w: float, h: float) -> void:
		var ct: float = _ct()
		var t: float = _t()
		var pri: Color = _pri()
		var sec: Color = _sec()
		var fdisp: Font = UITheme.get_display_font()

		var zoom_p: float = clampf(ct / 2.2, 0.0, 1.0)
		var ease_z: float = 1.0 - pow(1.0 - zoom_p, 3.0)

		# Night stadium grandstands behind the Presidential VIP Box
		_draw_grad(w, 0.0, h, Color("#060812"), Color("#121320"), 8)
		# Stadium roof steel beams
		var beam_y: float = lerpf(28.0, -40.0, ease_z)
		draw_rect(Rect2(0.0, beam_y, w, 14.0), Color("#1E293B"))
		# Packed supporters flanking the VIP Box (fade gently as camera zooms tight into box)
		var crowd_a: float = lerpf(0.85, 0.25, ease_z)
		for row_i in range(9):
			var ry: float = 52.0 + float(row_i) * 44.0
			draw_rect(Rect2(0.0, ry + 10.0, w, 2.0), Color(0, 0, 0, 0.45 * crowd_a))
			for si in range(44):
				var sx: float = 12.0 + float(si) * (w / 44.0)
				if absf(sx - w * 0.50) < lerpf(70.0, 175.0, ease_z) and ry > h * 0.22 and ry < h * 0.72:
					continue
				var col: Color = pri if ((si + row_i) % 3 != 0) else (sec if (si % 4 == 0) else Color("#E5B793"))
				var hop: float = absf(sin(t * 4.5 + float(si + row_i))) * 2.5
				draw_rect(Rect2(sx, ry - hop, 7.0, 9.0), Color(col.r, col.g, col.b, crowd_a))

		# VIP Presidential Box smoothly zooming into center screen!
		var bw: float = lerpf(116.0, 344.0, ease_z)
		var bh: float = lerpf(64.0, 212.0, ease_z)
		var bx: float = w * 0.50 - bw * 0.5
		var by: float = lerpf(h * 0.24, h * 0.24, ease_z)

		# VIP Box outer architecture & roof frame
		draw_rect(Rect2(bx - 10.0, by - 10.0, bw + 20.0, bh + 18.0), Color("#080B14"))
		draw_rect(Rect2(bx, by, bw, bh), Color("#151A28"))
		draw_rect(Rect2(bx, by, bw, bh), Color("#475569"), false, 2.5)

		# Top LED Scoreboard Screen inside VIP Box: PRESIDEN vs CALON!
		var sw: float = bw - 20.0
		var sh: float = bh * 0.46
		var sx0: float = bx + 10.0
		var sy0: float = by + 10.0
		draw_rect(Rect2(sx0, sy0, sw, sh), Color("#090C14"))
		draw_rect(Rect2(sx0, sy0, sw, sh), Color("#94A3B8"), false, 1.5)

		var pres_final: int = int(_ctx().get("president_pct", 61))
		var vote_p: float = clampf((ct - 2.1) / 2.2, 0.0, 1.0)
		var ease_v: float = 1.0 - pow(1.0 - vote_p, 2.5)
		var cur_pres: int = int(round(lerpf(50.0, float(pres_final), ease_v)))
		var cur_chal: int = 100 - cur_pres
		var inc_won: bool = bool(_ctx().get("election_incumbent_won", true))

		if ease_z > 0.55:
			var sc_f: float = clampf((ease_z - 0.55) / 0.45, 0.0, 1.0)
			var a_t: Color = Color(1.0, 1.0, 1.0, sc_f)
			draw_string(fdisp, Vector2(sx0 + 10.0, sy0 + 18.0), "PRESIDEN", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.82, 0.86, 0.94, sc_f))
			var cal_sz: Vector2 = fdisp.get_string_size("CALON", HORIZONTAL_ALIGNMENT_RIGHT, -1, 10)
			draw_string(fdisp, Vector2(sx0 + sw - cal_sz.x - 10.0, sy0 + 18.0), "CALON", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.82, 0.86, 0.94, sc_f))
			if ct >= 2.0:
				var p_txt: String = "%d%%" % cur_pres
				var c_txt: String = "%d%%" % cur_chal
				draw_string(fdisp, Vector2(sx0 + 10.0, sy0 + 50.0), p_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("#FDE047") if (ct >= 4.6 and inc_won) else a_t)
				var csz: Vector2 = fdisp.get_string_size(c_txt, HORIZONTAL_ALIGNMENT_RIGHT, -1, 24)
				draw_string(fdisp, Vector2(sx0 + sw - csz.x - 10.0, sy0 + 50.0), c_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("#FDE047") if (ct >= 4.6 and not inc_won) else a_t)
			# Live Sliding Horizontal Vote Percentage Bar!
			var bar_y: float = sy0 + sh - 18.0
			var bar_w: float = sw - 20.0
			draw_rect(Rect2(sx0 + 10.0, bar_y, bar_w, 10.0), Color("#334155"))
			var split_w: float = bar_w * (float(cur_pres) / 100.0)
			draw_rect(Rect2(sx0 + 10.0, bar_y, split_w, 10.0), Color("#E2E8F0"))
			draw_rect(Rect2(sx0 + 10.0 + split_w, bar_y, bar_w - split_w, 10.0), Color("#DC2626"))
			draw_line(Vector2(sx0 + 10.0 + bar_w * 0.5, bar_y - 3.0), Vector2(sx0 + 10.0 + bar_w * 0.5, bar_y + 13.0), Color("#FACC15"), 2.0)

		# 3 Suited VIP Figures seated below the LED board (Incumbent President | Secretary | Challenger)
		var fig_y: float = by + bh - 12.0
		var fig_sc: float = lerpf(0.35, 1.0, ease_z)
		var vip_specs: Array[Dictionary] = [
			{"u": 0.24, "skin": Color("#E3B48F"), "hair": Color("#CBD5E1"), "tie": pri},
			{"u": 0.54, "skin": Color("#8D5A3B"), "hair": Color("#111319"), "tie": Color("#94A3B8")},
			{"u": 0.78, "skin": Color("#E0AF89"), "hair": Color("#4B2E1E"), "tie": Color("#DC2626")},
		]
		for vp in vip_specs:
			var fx: float = bx + bw * float(vp["u"])
			# Dark suit torso + white shirt V + tie
			draw_rect(Rect2(fx - 18.0 * fig_sc, fig_y - 44.0 * fig_sc, 36.0 * fig_sc, 44.0 * fig_sc), Color("#111622"))
			draw_rect(Rect2(fx - 6.0 * fig_sc, fig_y - 44.0 * fig_sc, 12.0 * fig_sc, 24.0 * fig_sc), Color("#F8FAFC"))
			draw_rect(Rect2(fx - 2.0 * fig_sc, fig_y - 40.0 * fig_sc, 4.0 * fig_sc, 20.0 * fig_sc), vp["tie"])
			# Head & hair
			draw_rect(Rect2(fx - 12.0 * fig_sc, fig_y - 72.0 * fig_sc, 24.0 * fig_sc, 26.0 * fig_sc), vp["skin"])
			draw_rect(Rect2(fx - 13.0 * fig_sc, fig_y - 78.0 * fig_sc, 26.0 * fig_sc, 10.0 * fig_sc), vp["hair"])
			draw_rect(Rect2(fx - 6.0 * fig_sc, fig_y - 62.0 * fig_sc, 3.5 * fig_sc, 3.5 * fig_sc), Color("#0F172A"))
			draw_rect(Rect2(fx + 3.0 * fig_sc, fig_y - 62.0 * fig_sc, 3.5 * fig_sc, 3.5 * fig_sc), Color("#0F172A"))

		# Dramatic White Spotlight Cone on Winner when votes lock in (4.6s+)!
		if ct >= 4.6:
			var win_u: float = 0.24 if inc_won else 0.78
			var wx: float = bx + bw * win_u
			var spot := PackedVector2Array([
				Vector2(wx - 22.0, by + sh + 10.0), Vector2(wx + 22.0, by + sh + 10.0),
				Vector2(wx + 56.0, by + bh), Vector2(wx - 56.0, by + bh),
			])
			draw_colored_polygon(spot, Color(1.0, 0.98, 0.85, 0.24 + 0.05 * sin(t * 6.0)))

		# Dark wooden VIP Box balcony ledge
		draw_rect(Rect2(bx - 12.0, by + bh, bw + 24.0, 14.0), Color("#1E2436"))

	# --------------------------------------------------------------------------
	# CHAPTER 8: PANGGILAN TIMNAS — BRANCH A (DIPANGGIL) & BRANCH B (TIDAK DIPANGGIL)
	# --------------------------------------------------------------------------
	func _draw_ch8_national_apartment(w: float, h: float) -> void:
		var ct: float = _ct()
		var t: float = _t()
		var called: bool = bool(_ctx().get("timnas_called", true))
		var fdisp: Font = UITheme.get_display_font()
		var cols: Array = _ctx().get("timnas_nation_colors", [Color("#CE1126"), Color("#FFFFFF")])
		var na_col: Color = UITheme.parse_color(cols[0] if cols.size() > 0 else Color("#CE1126"), Color("#CE1126"))
		var nb_col: Color = UITheme.parse_color(cols[1] if cols.size() > 1 else Color("#FFFFFF"), Color("#FFFFFF"))
		var sel_no: int = int(owner_modal.get("_timnas_selected_no"))

		# BEAT B (1.1s..3.4s): Dramatic Close-Up onto the Wooden Desk & Official Call-Up Letter!
		if ct >= 1.1 and ct < 3.4:
			var wall_c: Color = Color("#2C292A") if called else Color("#192030")
			draw_rect(Rect2(0.0, 0.0, w, h * 0.62), wall_c)
			# Large National Flag hanging on wall upper-left (clear of top-left broadcast pill!)
			_draw_nation_flag_rect(Rect2(w * 0.12, h * 0.15, 190.0, 110.0))
			# Night window on upper-right
			draw_rect(Rect2(w * 0.66, h * 0.04, 240.0, 180.0), Color("#0B101B"))
			draw_rect(Rect2(w * 0.66, h * 0.04, 240.0, 180.0), Color("#334155"), false, 3.0)
			for li in range(8):
				draw_rect(Rect2(w * 0.69 + float(li % 4) * 52.0, h * 0.10 + float(li / 4) * 58.0, 14.0, 18.0), Color("#FEF3C7"))
			# Close-up Wooden Desk surface
			draw_rect(Rect2(0.0, h * 0.56, w, h * 0.44), Color("#4A3425"))
			draw_rect(Rect2(0.0, h * 0.56, w, 10.0), Color("#634733"))
			# Glowing warm desk lamp on right
			draw_circle(Vector2(w * 0.86, h * 0.54), 68.0, Color(1.0, 0.90, 0.62, 0.22 if called else 0.10))
			draw_rect(Rect2(w * 0.81, h * 0.47, 74.0, 56.0), Color("#FEF3C7") if called else Color("#CBD5E1"))

			# Official Vertical Document popping upright at desk center!
			var pop: float = clampf((ct - 1.25) / 0.45, 0.0, 1.0)
			var ease_pop: float = 1.0 - pow(1.0 - pop, 3.0)
			var lw: float = 208.0
			var lh: float = 258.0 * ease_pop
			var lx: float = w * 0.50 - lw * 0.5
			var ly: float = h * 0.78 - lh
			draw_rect(Rect2(lx - 4.0, ly + lh - 4.0, lw + 8.0, 10.0), Color(0, 0, 0, 0.38))
			draw_rect(Rect2(lx, ly, lw, lh), Color("#F8FAFC") if called else Color("#E2E8F0"))
			draw_rect(Rect2(lx, ly, lw, lh), Color("#CBD5E1"), false, 2.0)

			if ease_pop > 0.72:
				_draw_nation_flag_rect(Rect2(lx + 44.0, ly + 18.0, 120.0, 62.0))
				var nat_s: String = str(_ctx().get("timnas_nation_name", "INDONESIA"))
				var nsz: Vector2 = fdisp.get_string_size(nat_s, HORIZONTAL_ALIGNMENT_CENTER, -1, 11)
				draw_string(fdisp, Vector2(w * 0.50 - nsz.x * 0.5, ly + 104.0), nat_s, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#1E293B"))
				var l2: String = "PANGGILAN RESMI" if called else "PENGUMUMAN SKUAD"
				var l2s: Vector2 = fdisp.get_string_size(l2, HORIZONTAL_ALIGNMENT_CENTER, -1, 10)
				draw_string(fdisp, Vector2(w * 0.50 - l2s.x * 0.5, ly + 124.0), l2, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#475569"))
				var pnm: String = str(_ctx().get("player_name", "PEMAIN")).left(14)
				var pns: Vector2 = fdisp.get_string_size(pnm, HORIZONTAL_ALIGNMENT_CENTER, -1, 12)
				draw_string(fdisp, Vector2(w * 0.50 - pns.x * 0.5, ly + 146.0), pnm, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#0F172A"))
				var trn: String = str(_ctx().get("timnas_tournament", "MUNDIAL")).left(14)
				var trs: Vector2 = fdisp.get_string_size(trn, HORIZONTAL_ALIGNMENT_CENTER, -1, 18)
				draw_string(fdisp, Vector2(w * 0.50 - trs.x * 0.5, ly + 184.0), trn, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#0F172A"))
				if called:
					var ok_s := "KAMU DIPANGGIL"
					var oks: Vector2 = fdisp.get_string_size(ok_s, HORIZONTAL_ALIGNMENT_CENTER, -1, 12)
					draw_string(fdisp, Vector2(w * 0.50 - oks.x * 0.5, ly + 226.0), ok_s, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#15803D"))
				else:
					draw_rect(Rect2(lx + 18.0, ly + 200.0, lw - 36.0, 34.0), Color("#DC2626"), false, 3.0)
					var no_s := "TIDAK DIPANGGIL"
					var nos: Vector2 = fdisp.get_string_size(no_s, HORIZONTAL_ALIGNMENT_CENTER, -1, 12)
					draw_string(fdisp, Vector2(w * 0.50 - nos.x * 0.5, ly + 222.0), no_s, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#DC2626"))
			return

		# WIDE APARTMENT SHOT (0..1.1s & 3.4s+ with gentle left pan for card!)
		var pan_p: float = clampf((ct - 3.4) / 0.65, 0.0, 1.0)
		var ease_p: float = 1.0 - pow(1.0 - pan_p, 3.0)
		var shift_x: float = lerpf(0.0, -140.0, ease_p)

		# Apartment walls & warm/cool floor
		draw_rect(Rect2(0.0, 0.0, w, h * 0.64), Color("#262426") if called else Color("#181E2B"))
		draw_rect(Rect2(0.0, h * 0.64, w, h * 0.36), Color("#1A181B") if called else Color("#111520"))
		# Night city skyline window
		var wx0: float = 510.0 + shift_x
		draw_rect(Rect2(wx0, 74.0, 210.0, 170.0), Color("#0A0F1A"))
		draw_rect(Rect2(wx0, 74.0, 210.0, 170.0), Color("#3F3F46"), false, 4.0)
		draw_line(Vector2(wx0 + 105.0, 74.0), Vector2(wx0 + 105.0, 244.0), Color("#3F3F46"), 3.0)
		draw_line(Vector2(wx0, 158.0), Vector2(wx0 + 210.0, 158.0), Color("#3F3F46"), 3.0)
		var city_pts: Array[Vector2] = [
			Vector2(18, 22), Vector2(44, 58), Vector2(72, 34), Vector2(88, 112), Vector2(28, 128),
			Vector2(120, 26), Vector2(154, 46), Vector2(180, 28), Vector2(132, 98), Vector2(166, 118),
			Vector2(56, 102), Vector2(188, 134), Vector2(142, 68), Vector2(24, 86),
		]
		for ci in range(city_pts.size()):
			var cp: Vector2 = city_pts[ci]
			draw_rect(Rect2(wx0 + cp.x, 74.0 + cp.y, 9.0, 11.0), Color("#FEF3C7") if (ci % 3 != 0) else Color("#93C5FD"))

		# National Flag framed on back wall!
		var fl_x: float = 330.0 + shift_x
		draw_rect(Rect2(fl_x - 4.0, 122.0, 118.0, 74.0), Color("#111319"))
		_draw_nation_flag_rect(Rect2(fl_x, 126.0, 110.0, 66.0))

		# Left wooden sideboard & wall art
		draw_rect(Rect2(44.0 + shift_x, 294.0, 154.0, 90.0), Color("#4A3525"))
		draw_rect(Rect2(60.0 + shift_x, 144.0, 56.0, 62.0), Color("#1E293B"))
		draw_rect(Rect2(60.0 + shift_x, 144.0, 56.0, 62.0), Color("#CA8A04"), false, 2.0)

		# Wooden Desk + Lamp + Mini Upright Letter + Framed National Jersey (live-updated number!)
		var dx0: float = 284.0 + shift_x
		draw_rect(Rect2(dx0, 292.0, 324.0, 18.0), Color("#5E422E"))
		draw_rect(Rect2(dx0 + 8.0, 310.0, 16.0, 74.0), Color("#3B281B"))
		draw_rect(Rect2(dx0 + 300.0, 310.0, 16.0, 74.0), Color("#3B281B"))
		# Glowing square desk lamp
		draw_circle(Vector2(dx0 + 278.0, 276.0), 42.0, Color(1.0, 0.90, 0.62, 0.20 if called else 0.08))
		draw_rect(Rect2(dx0 + 258.0, 260.0, 38.0, 32.0), Color("#FEF3C7") if called else Color("#94A3B8"))
		# Small upright call-up letter visible on desk after 3.4s
		if ct >= 3.4:
			draw_rect(Rect2(dx0 + 114.0, 244.0, 44.0, 48.0), Color("#F8FAFC") if called else Color("#94A3B8"))
			draw_rect(Rect2(dx0 + 122.0, 250.0, 28.0, 14.0), na_col)

		# Framed National Jersey standing in front of desk (shows surname + LIVE _timnas_selected_no!)
		var jx: float = dx0 + 48.0
		var jy: float = 310.0
		draw_rect(Rect2(jx - 38.0, jy, 76.0, 90.0), Color("#0B0D13"))
		draw_rect(Rect2(jx - 38.0, jy, 76.0, 90.0), Color("#475569"), false, 2.0)
		var j_body: Color = na_col if called else na_col.darkened(0.45)
		draw_rect(Rect2(jx - 22.0, jy + 16.0, 44.0, 56.0), j_body)
		draw_rect(Rect2(jx - 32.0, jy + 16.0, 11.0, 22.0), j_body)
		draw_rect(Rect2(jx + 21.0, jy + 16.0, 11.0, 22.0), j_body)
		var short_nm: String = str(_ctx().get("player_name", "PEMAIN")).split(" ")[0].left(8)
		var snsz: Vector2 = fdisp.get_string_size(short_nm, HORIZONTAL_ALIGNMENT_CENTER, -1, 8)
		draw_string(fdisp, Vector2(jx - snsz.x * 0.5, jy + 32.0), short_nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, nb_col)
		var n_txt: String = str(sel_no)
		var nsz2: Vector2 = fdisp.get_string_size(n_txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 18)
		draw_string(fdisp, Vector2(jx - nsz2.x * 0.5, jy + 58.0), n_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, nb_col)

		# Disappointed "..." sigh bubble above Player when NOT CALLED!
		if not called and ct >= 3.4:
			var bx_s: float = lerpf(w * 0.56, w * 0.36, ease_p) + 40.0
			var by_s: float = h * 0.54 + sin(t * 2.5) * 3.0
			draw_rect(Rect2(bx_s - 22.0, by_s - 14.0, 44.0, 24.0), Color(0.10, 0.14, 0.22, 0.90))
			draw_rect(Rect2(bx_s - 22.0, by_s - 14.0, 44.0, 24.0), Color("#64748B"), false, 1.5)
			draw_string(fdisp, Vector2(bx_s - 12.0, by_s + 3.0), "...", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#94A3B8"))

	# --------------------------------------------------------------------------
	# CHAPTER 9: DEWAN KLUB / PUSAT LATIHAN (SUARA)
	# --------------------------------------------------------------------------
	func _draw_ch9_club_summit(w: float, h: float) -> void:
		var ct: float = _ct()
		var pri: Color = _pri()
		var fdisp: Font = UITheme.get_display_font()
		var pan_p: float = clampf((ct - 1.7) / 0.65, 0.0, 1.0)
		var ease_p: float = pan_p * pan_p * (3.0 - 2.0 * pan_p)
		var cx: float = lerpf(w * 0.50, w * 0.31, ease_p)

		# Rich club-colored boardroom press gradient
		_draw_grad(w, 0.0, h, pri.darkened(0.28), pri.darkened(0.72), 10)
		# Translucent golden club emblem top-center behind the header
		var sr: float = 52.0
		var sy: float = 62.0
		var sh_pts := PackedVector2Array([
			Vector2(cx - sr * 0.80, sy - sr * 0.85), Vector2(cx + sr * 0.80, sy - sr * 0.85),
			Vector2(cx + sr * 0.80, sy + sr * 0.15), Vector2(cx, sy + sr * 0.95),
			Vector2(cx - sr * 0.80, sy + sr * 0.15),
		])
		draw_colored_polygon(sh_pts, Color(0.95, 0.82, 0.35, 0.35))
		draw_polyline(sh_pts, Color(1.0, 0.90, 0.45, 0.55), 2.5)

		# Club Name & PUSAT LATIHAN boardroom wall signage!
		var cnm: String = str(_ctx().get("club_name", "KLUB"))
		var csz: Vector2 = fdisp.get_string_size(cnm, HORIZONTAL_ALIGNMENT_CENTER, -1, 20)
		draw_string(fdisp, Vector2(cx - csz.x * 0.5, 166.0), cnm, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#FEF9C3"))
		var pl_s := "PUSAT LATIHAN"
		var psz: Vector2 = fdisp.get_string_size(pl_s, HORIZONTAL_ALIGNMENT_CENTER, -1, 13)
		draw_string(fdisp, Vector2(cx - psz.x * 0.5, 190.0), pl_s, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#E2E8F0"))

	# --------------------------------------------------------------------------
	# SHARED TV SPORTS STUDIO SHELL & 3 SEATED PUNDITS (CH_TV_DEBATE & CH_TEAM_OF_SEASON)
	# --------------------------------------------------------------------------
	func _draw_tv_studio_shell(w: float, h: float, bug_tag: String, bug_time: String) -> void:
		var fdisp: Font = UITheme.get_display_font()
		draw_rect(Rect2(0.0, 0.0, w, h), Color("#17143A"))
		# Vibrant alternating purple-indigo studio wall ribs + glowing cyan light tubes
		var rib_w: float = w / 16.0
		for ri in range(16):
			var rx: float = float(ri) * rib_w
			draw_rect(Rect2(rx, 0.0, rib_w - 6.0, h * 0.66), Color("#241F5C") if (ri % 2 == 0) else Color("#1D194D"))
			draw_rect(Rect2(rx + rib_w - 6.0, 0.0, 4.0, h * 0.66), Color("#6366F1") if (ri % 2 == 0) else Color("#A855F7"))
		# Horizontal bright cyan neon bar behind desk + vivid royal-blue & crimson lower paneling
		draw_rect(Rect2(0.0, h * 0.56, w, 6.0), Color("#38BDF8"))
		draw_rect(Rect2(0.0, h * 0.58, w, h * 0.24), Color("#2563EB"))
		draw_rect(Rect2(0.0, h * 0.64, w, 8.0), Color("#DC2626"))
		draw_rect(Rect2(0.0, h * 0.80, w, h * 0.20), Color("#0C101C"))

		# Top-Right Broadcast LIVE Bug (LANGSUNG 12:58 / DEBAT or TIM INTI)
		var bx: float = w - 122.0
		draw_rect(Rect2(bx, 14.0, 106.0, 38.0), Color(0.06, 0.08, 0.14, 0.90))
		draw_rect(Rect2(bx, 14.0, 106.0, 14.0), Color("#DC2626"))
		draw_string(fdisp, Vector2(bx + 6.0, 24.5), "LANGSUNG %s" % bug_time, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, UITheme.TEXT_WHITE)
		var bsz: Vector2 = fdisp.get_string_size(bug_tag, HORIZONTAL_ALIGNMENT_CENTER, -1, 11)
		draw_string(fdisp, Vector2(bx + 53.0 - bsz.x * 0.5, 44.0), bug_tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#FDE047"))

	func _draw_tv_pundits(w: float, h: float, active_idx: int) -> void:
		var t: float = _t()
		# Sleek dark broadcast desk
		var desk_y: float = h * 0.78
		var specs: Array[Dictionary] = [
			{"x": w * 0.36, "skin": Color("#E0B18D"), "hair": Color("#261B16"), "suit": Color("#1E293B"), "tie": Color("#EF4444"), "is_f": false},
			{"x": w * 0.50, "skin": Color("#D9A682"), "hair": Color("#171212"), "suit": Color("#334155"), "tie": Color("#38BDF8"), "is_f": true},
			{"x": w * 0.64, "skin": Color("#E8BF9E"), "hair": Color("#CBD5E1"), "suit": Color("#1E2434"), "tie": Color("#FACC15"), "is_f": false},
		]
		# Active pundit mapping: 0=left(EKS PEMAIN), 1=right(KRITIKUS), 2=center(SANG WARTAWAN)
		var talk_slot: int = 0 if active_idx == 0 else (2 if active_idx == 1 else (1 if active_idx == 2 else -1))
		for i in range(3):
			var sp: Dictionary = specs[i]
			var px: float = float(sp["x"])
			var talk_bob: float = absf(sin(t * 14.0)) * 2.5 if i == talk_slot else 0.0
			# Shoulders & suit
			draw_rect(Rect2(px - 28.0, desk_y - 44.0, 56.0, 44.0), sp["suit"])
			draw_rect(Rect2(px - 8.0, desk_y - 44.0, 16.0, 26.0), Color("#F8FAFC"))
			draw_rect(Rect2(px - 3.0, desk_y - 38.0, 6.0, 20.0), sp["tie"])
			# Head & hair
			draw_rect(Rect2(px - 16.0, desk_y - 82.0 - talk_bob, 32.0, 36.0), sp["skin"])
			draw_rect(Rect2(px - 17.0, desk_y - 88.0 - talk_bob, 34.0, 12.0), sp["hair"])
			if bool(sp["is_f"]):
				draw_rect(Rect2(px - 8.0, desk_y - 96.0 - talk_bob, 16.0, 9.0), sp["hair"])
			# Eyes & animated speaking mouth
			draw_rect(Rect2(px - 8.0, desk_y - 68.0 - talk_bob, 4.0, 4.0), Color("#0F172A"))
			draw_rect(Rect2(px + 4.0, desk_y - 68.0 - talk_bob, 4.0, 4.0), Color("#0F172A"))
			var m_h: float = 5.0 if (i == talk_slot and sin(t * 18.0) > 0.0) else 2.0
			draw_rect(Rect2(px - 5.0, desk_y - 55.0 - talk_bob, 10.0, m_h), Color("#7C2D12"))
		# Foreground Studio Broadcast Desk
		draw_rect(Rect2(w * 0.22, desk_y, w * 0.56, 12.0), Color("#94A3B8"))
		draw_rect(Rect2(w * 0.24, desk_y + 12.0, w * 0.52, h - desk_y), Color("#1E2434"))
		draw_rect(Rect2(w * 0.24, desk_y + 12.0, w * 0.52, 4.0), Color("#38BDF8"))

	# --------------------------------------------------------------------------
	# CHAPTER 10: DEBAT TV — SIAPA TERBAIK? (USER vs RIVAL FACE-OFF!)
	# --------------------------------------------------------------------------
	func _draw_ch10_tv_debate(w: float, h: float) -> void:
		var ct: float = _ct()
		var fdisp: Font = UITheme.get_display_font()
		_draw_tv_studio_shell(w, h, "DEBAT", "12:58")

		# Giant Studio Monitor Screen (slightly zoomed during 0.5..1.8s, framed above pundits otherwise!)
		var mw: float = 420.0
		var mh: float = 226.0
		var mx: float = w * 0.50 - mw * 0.5
		var my: float = 38.0
		draw_rect(Rect2(mx - 6.0, my - 6.0, mw + 12.0, mh + 12.0), Color("#0B0F1A"))
		draw_rect(Rect2(mx, my, mw, mh), Color("#2B1122"))
		draw_rect(Rect2(mx, my, mw, mh), Color("#FACC15"), false, 2.5)
		# Monitor Top Bar: LANGSUNG | DEBAT
		draw_rect(Rect2(mx, my, mw, 26.0), Color("#7F1D1D"))
		draw_string(fdisp, Vector2(mx + 14.0, my + 17.0), "LANGSUNG", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#FCA5A5"))
		var dsz: Vector2 = fdisp.get_string_size("DEBAT", HORIZONTAL_ALIGNMENT_RIGHT, -1, 12)
		draw_string(fdisp, Vector2(mx + mw - dsz.x - 14.0, my + 18.0), "DEBAT", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#FDE047"))

		var rv: Dictionary = _ctx().get("rival", {})
		var u_nm: String = str(_ctx().get("player_name", "BINTANG")).split(" ")[0].left(10)
		var r_nm: String = str(rv.get("name", "DUNMORE")).split(" ")[-1].left(10)
		var u_g: int = int(_ctx().get("season_goals", 24))
		var r_g: int = int(rv.get("goals", 16))
		var u_ovr: int = int(_ctx().get("player_ovr", 76))
		var r_ovr: int = int(rv.get("ovr", 74))
		var u_pos: String = str(_ctx().get("player_pos", "ST"))
		var r_pos: String = str(rv.get("pos", "CM"))

		# Left Side (USER) & Right Side (RIVAL) Goals + Pixel Portrait Badges!
		var sides: Array[Dictionary] = [
			{"cx": mx + mw * 0.26, "nm": u_nm, "g": u_g, "ovr": u_ovr, "pos": u_pos, "pri": _pri(), "sec": _sec(), "skin": Color("#E3B48F")},
			{"cx": mx + mw * 0.74, "nm": r_nm, "g": r_g, "ovr": r_ovr, "pos": r_pos, "pri": UITheme.parse_color(rv.get("primary", Color("#1D4ED8")), Color("#1D4ED8")), "sec": Color("#F8FAFC"), "skin": Color("#8B5A3C")},
		]
		for sd in sides:
			var scx: float = float(sd["cx"])
			var g_lbl := "GOL TAHUN INI"
			var glsz: Vector2 = fdisp.get_string_size(g_lbl, HORIZONTAL_ALIGNMENT_CENTER, -1, 8)
			draw_string(fdisp, Vector2(scx - glsz.x * 0.5, my + 44.0), g_lbl, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("#FCA5A5"))
			var g_s: String = str(int(sd["g"]))
			var gsz: Vector2 = fdisp.get_string_size(g_s, HORIZONTAL_ALIGNMENT_CENTER, -1, 28)
			draw_string(fdisp, Vector2(scx - gsz.x * 0.5, my + 74.0), g_s, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, UITheme.TEXT_WHITE)
			var nsz: Vector2 = fdisp.get_string_size(str(sd["nm"]), HORIZONTAL_ALIGNMENT_CENTER, -1, 11)
			draw_string(fdisp, Vector2(scx - nsz.x * 0.5, my + 92.0), str(sd["nm"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#FDE047"))
			var ovr_s: String = "%d %s" % [int(sd["ovr"]), str(sd["pos"])]
			var osz: Vector2 = fdisp.get_string_size(ovr_s, HORIZONTAL_ALIGNMENT_CENTER, -1, 9)
			draw_string(fdisp, Vector2(scx - osz.x * 0.5, my + 106.0), ovr_s, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("#CBD5E1"))
			# Crisp pixel-art mini bust portrait
			var py0: float = my + 114.0
			draw_rect(Rect2(scx - 22.0, py0 + 26.0, 44.0, 28.0), sd["pri"])
			draw_rect(Rect2(scx - 8.0, py0 + 26.0, 16.0, 28.0), sd["sec"])
			draw_rect(Rect2(scx - 13.0, py0 + 2.0, 26.0, 24.0), sd["skin"])
			draw_rect(Rect2(scx - 14.0, py0 - 2.0, 28.0, 8.0), Color("#111319"))
			draw_rect(Rect2(scx - 6.0, py0 + 10.0, 3.0, 3.0), Color("#0F172A"))
			draw_rect(Rect2(scx + 3.0, py0 + 10.0, 3.0, 3.0), Color("#0F172A"))

		# Live Tug-of-War Vote Bar at bottom of Giant Studio Monitor!
		var vp: float = clampf(ct / 1.6, 0.0, 1.0)
		var u_pct: int = int(round(lerpf(50.0, float(int(_ctx().get("debate_user_pct", 78))), vp)))
		var r_pct: int = 100 - u_pct
		var bar_x: float = mx + 24.0
		var bar_y: float = my + mh - 36.0
		var bar_w: float = mw - 48.0
		draw_rect(Rect2(bar_x, bar_y, bar_w, 10.0), Color("#334155"))
		draw_rect(Rect2(bar_x, bar_y, bar_w * (float(u_pct) / 100.0), 10.0), Color("#EF4444"))
		draw_string(fdisp, Vector2(bar_x, bar_y - 4.0), "%d%%" % u_pct, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#FCA5A5"))
		var rps: String = "%d%%" % r_pct
		var rpsz: Vector2 = fdisp.get_string_size(rps, HORIZONTAL_ALIGNMENT_RIGHT, -1, 10)
		draw_string(fdisp, Vector2(bar_x + bar_w - rpsz.x, bar_y - 4.0), rps, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#94A3B8"))
		var q_s := "SIAPA TERBAIK?"
		var qsz: Vector2 = fdisp.get_string_size(q_s, HORIZONTAL_ALIGNMENT_CENTER, -1, 10)
		draw_string(fdisp, Vector2(w * 0.50 - qsz.x * 0.5, my + mh - 8.0), q_s, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#FDE047"))

		var active_p: int = int(owner_modal.get("_tv_pundit_idx")) if (ct >= 1.8 and ct < 7.2) else -1
		_draw_tv_pundits(w, h, active_p)

	# --------------------------------------------------------------------------
	# CHAPTER 11: TIM INTI / TIM TERBAIK MUSIM (4-3-3 LEAGUE BEST XI!)
	# --------------------------------------------------------------------------
	func _draw_best_xi_board(r: Rect2, full_detail: bool) -> void:
		var fdisp: Font = UITheme.get_display_font()
		draw_rect(r, Color("#1A1314"))
		draw_rect(r, Color("#EAB308"), false, 2.5 if full_detail else 1.5)
		var side_w: float = r.size.x * 0.24
		# Left Dark League Shield Panel
		draw_rect(Rect2(r.position.x + 4.0, r.position.y + 4.0, side_w - 8.0, r.size.y - 8.0), Color("#261B16"))
		var lcx: float = r.position.x + side_w * 0.5
		var lcy: float = r.position.y + r.size.y * 0.34
		var sr: float = 26.0 if full_detail else 14.0
		var sh := PackedVector2Array([
			Vector2(lcx - sr * 0.8, lcy - sr * 0.9), Vector2(lcx + sr * 0.8, lcy - sr * 0.9),
			Vector2(lcx + sr * 0.8, lcy + sr * 0.1), Vector2(lcx, lcy + sr * 0.95),
			Vector2(lcx - sr * 0.8, lcy + sr * 0.1),
		])
		draw_colored_polygon(sh, Color("#D97706"))
		var ln: String = str(_ctx().get("league_name", "LIGA UTAMA")).left(15)
		var lnsz: Vector2 = fdisp.get_string_size(ln, HORIZONTAL_ALIGNMENT_CENTER, -1, 11 if full_detail else 7)
		draw_string(fdisp, Vector2(lcx - lnsz.x * 0.5, lcy + sr + (24.0 if full_detail else 12.0)), ln, HORIZONTAL_ALIGNMENT_LEFT, -1, 11 if full_detail else 7, Color("#FEF08A"))
		var fm_s := "4-3-3"
		var fsz: Vector2 = fdisp.get_string_size(fm_s, HORIZONTAL_ALIGNMENT_CENTER, -1, 12 if full_detail else 8)
		draw_string(fdisp, Vector2(lcx - fsz.x * 0.5, lcy + sr + (48.0 if full_detail else 24.0)), fm_s, HORIZONTAL_ALIGNMENT_LEFT, -1, 12 if full_detail else 8, Color("#E2E8F0"))

		# Right Horizontal Light-Sage Tactics Pitch (exact Video 1 01:32 orientation!)
		var px0: float = r.position.x + side_w + 4.0
		var py0: float = r.position.y + 8.0
		var pw: float = r.size.x - side_w - 12.0
		var ph: float = r.size.y - 16.0
		draw_rect(Rect2(px0, py0, pw, ph), Color("#C2CCC0"))
		# Subtle horizontal turf bands + white pitch markings
		for bi in range(6):
			if bi % 2 == 0:
				draw_rect(Rect2(px0 + float(bi) * (pw / 6.0), py0, pw / 6.0, ph), Color(1.0, 1.0, 1.0, 0.08))
		draw_rect(Rect2(px0 + 6.0, py0 + 6.0, pw - 12.0, ph - 12.0), Color(1, 1, 1, 0.72), false, 2.0)
		draw_line(Vector2(px0 + pw * 0.5, py0 + 6.0), Vector2(px0 + pw * 0.5, py0 + ph - 6.0), Color(1, 1, 1, 0.72), 2.0)
		draw_arc(Vector2(px0 + pw * 0.5, py0 + ph * 0.5), minf(pw, ph) * 0.16, 0.0, TAU, 24, Color(1, 1, 1, 0.72), 2.0)
		draw_rect(Rect2(px0 + 6.0, py0 + ph * 0.25, pw * 0.13, ph * 0.50), Color(1, 1, 1, 0.65), false, 2.0)
		draw_rect(Rect2(px0 + pw - 6.0 - pw * 0.13, py0 + ph * 0.25, pw * 0.13, ph * 0.50), Color(1, 1, 1, 0.65), false, 2.0)

		# 11 Players in exact 4-3-3 normalized coordinates (GK left -> DEF -> MID -> FWD right)
		var coords: Array[Vector2] = [
			Vector2(0.11, 0.50),
			Vector2(0.27, 0.84), Vector2(0.27, 0.36), Vector2(0.37, 0.64), Vector2(0.37, 0.16),
			Vector2(0.56, 0.50), Vector2(0.66, 0.78), Vector2(0.66, 0.22),
			Vector2(0.86, 0.82), Vector2(0.86, 0.50), Vector2(0.86, 0.18),
		]
		var xi_list: Array = _ctx().get("best_xi_list", [])
		var sc: float = 1.0 if full_detail else 0.48
		for i in range(mini(11, xi_list.size())):
			var pd: Dictionary = xi_list[i]
			var uv: Vector2 = coords[i]
			var cx_p: float = px0 + pw * uv.x
			var cy_p: float = py0 + ph * uv.y
			var is_u: bool = bool(pd.get("is_user", false))
			var pcol: Color = UITheme.parse_color(pd.get("primary", Color("#1D4ED8")), Color("#1D4ED8"))
			var scol: Color = UITheme.parse_color(pd.get("secondary", Color("#F8FAFC")), Color("#F8FAFC"))

			if is_u:
				draw_circle(Vector2(cx_p, cy_p - 4.0 * sc), 24.0 * sc, Color(1.0, 0.84, 0.18, 0.38))
			# Mini pixel-art player sprite (torso + head)
			draw_rect(Rect2(cx_p - 10.0 * sc, cy_p - 6.0 * sc, 20.0 * sc, 20.0 * sc), pcol)
			draw_rect(Rect2(cx_p - 3.5 * sc, cy_p - 6.0 * sc, 7.0 * sc, 20.0 * sc), scol)
			draw_rect(Rect2(cx_p - 7.0 * sc, cy_p - 20.0 * sc, 14.0 * sc, 14.0 * sc), Color("#E3B48F"))
			draw_rect(Rect2(cx_p - 8.0 * sc, cy_p - 23.0 * sc, 16.0 * sc, 5.0 * sc), Color("#1E1916"))
			# Nameplate pill underneath player
			if full_detail:
				var pnm: String = "%d %s" % [int(pd.get("num", 10)), str(pd.get("name", "PEMAIN")).left(9)]
				var psz: Vector2 = fdisp.get_string_size(pnm, HORIZONTAL_ALIGNMENT_CENTER, -1, 8)
				var bw_p: float = maxf(60.0, psz.x + 10.0)
				draw_rect(Rect2(cx_p - bw_p * 0.5, cy_p + 15.0, bw_p, 15.0), Color("#CA8A04") if is_u else Color(0.08, 0.10, 0.16, 0.88))
				draw_string(fdisp, Vector2(cx_p - psz.x * 0.5, cy_p + 26.0), pnm, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("#0F172A") if is_u else UITheme.TEXT_WHITE)

	func _draw_ch11_best_xi(w: float, h: float) -> void:
		var ct: float = _ct()
		_draw_tv_studio_shell(w, h, "TIM INTI", "12:59")
		if ct < 4.2:
			# Full-screen zoomed 4-3-3 Best XI Board!
			var board_r := Rect2(26.0, 62.0, w - 52.0, h - 106.0)
			_draw_best_xi_board(board_r, true)
		else:
			# Pulled back to TV Studio with mini Best XI screen behind 3 Pundits!
			var mini_r := Rect2(w * 0.50 - 200.0, 38.0, 400.0, 212.0)
			_draw_best_xi_board(mini_r, false)
			var active_p: int = int(owner_modal.get("_tv_pundit_idx")) if (ct >= 4.2 and ct < 8.1) else -1
			_draw_tv_pundits(w, h, active_p)

# ==============================================================================
# FOREGROUND OVERLAY (CONFETTI + COUNTDOWN BANNERS + SUMMIT TABLE + TV QUOTES & TICKER)
# ==============================================================================
class _SeasonFgCanvas extends _SeasonBgCanvas:
	func _draw() -> void:
		if owner_modal == null or not is_instance_valid(owner_modal):
			return
		var w: float = maxf(size.x, 960.0)
		var h: float = maxf(size.y, 540.0)
		var ch: int = int(owner_modal.get("_cur_ch"))
		var ct: float = float(owner_modal.get("_ch_t"))
		var t: float = float(owner_modal.get("_t"))
		var fdisp: Font = UITheme.get_display_font()

		# Part 2 Theater Countdown Caption Banner & Foreground Stage Pedestal Trophy!
		if ch in [CH_BEST_GOAL, CH_GOLDEN_BOY, CH_WORLD_BEST]:
			var rev_t: float = float(owner_modal.call("_get_theater_reveal_time", ch))
			var noms: Array = owner_modal.call("_get_theater_nominees", ch)
			if ct >= 2.0 and ct < rev_t and not noms.is_empty():
				var idx: int = clampi(int(owner_modal.get("_theater_countdown_idx")), 1, noms.size() - 1)
				var nd: Dictionary = noms[idx]
				var bx: float = w * 0.50 - 175.0
				var by: float = h * 0.78
				draw_rect(Rect2(bx, by, 350.0, 58.0), Color(0.06, 0.07, 0.11, 0.92))
				draw_rect(Rect2(bx, by, 350.0, 58.0), Color("#EAB308"), false, 2.0)
				var rk_s: String = "ke-%d" % int(nd.get("rank", idx + 1))
				draw_string(fdisp, Vector2(bx + 14.0, by + 36.0), rk_s, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#FACC15"))
				draw_string(fdisp, Vector2(bx + 114.0, by + 24.0), str(nd.get("name", "NOMINE")).left(16), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, UITheme.TEXT_WHITE)
				var sub_t: String = ("%s • %d'" % [str(nd.get("style", "VOLI")), int(nd.get("minute", 54))]) if ch == CH_BEST_GOAL else ("%d PTS  •  %d TROFI" % [int(nd.get("pts", 100)), int(nd.get("trophies", 1))])
				draw_string(fdisp, Vector2(bx + 114.0, by + 44.0), sub_t, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#94A3B8"))
			elif ct >= rev_t:
				# Foreground Golden Pedestal & Iconic Trophy directly in front of Winner!
				var px: float = w * 0.28
				var py: float = h * 0.78
				draw_rect(Rect2(px - 28.0, py - 56.0, 56.0, 68.0), Color("#78521B"))
				draw_rect(Rect2(px - 32.0, py - 62.0, 64.0, 9.0), Color("#FACC15"))
				_draw_award_trophy_art(Vector2(px, py - 84.0), ch, 1.12)

		# Part 3 Chapter 9: Foreground Conference Table, Contract Folder & Coach 5-Star Nameplate!
		elif ch == CH_CLUB_SUMMIT:
			var pan_p: float = clampf((ct - 1.7) / 0.65, 0.0, 1.0)
			var ease_p: float = pan_p * pan_p * (3.0 - 2.0 * pan_p)
			var cx: float = lerpf(w * 0.50, w * 0.31, ease_p)
			# Floating Coach 5-Star Nameplate above Coach's head
			var coach_x: float = cx - 122.0
			var coach_y: float = h * 0.90 - 196.0
			var stars_n: int = clampi(int(_ctx().get("coach_stars", 5)), 1, 5)
			var star_s: String = "★".repeat(stars_n)
			var c_nm: String = str(_ctx().get("coach_name", "DIEGO SALAZAR"))
			draw_rect(Rect2(coach_x - 62.0, coach_y, 124.0, 34.0), Color(0.08, 0.14, 0.28, 0.92))
			draw_rect(Rect2(coach_x - 62.0, coach_y, 124.0, 34.0), Color("#38BDF8"), false, 1.5)
			var ssz: Vector2 = fdisp.get_string_size(star_s, HORIZONTAL_ALIGNMENT_CENTER, -1, 10)
			draw_string(fdisp, Vector2(coach_x - ssz.x * 0.5, coach_y + 14.0), star_s, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#FACC15"))
			var nsz: Vector2 = fdisp.get_string_size(c_nm, HORIZONTAL_ALIGNMENT_CENTER, -1, 8)
			draw_string(fdisp, Vector2(coach_x - nsz.x * 0.5, coach_y + 28.0), c_nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, UITheme.TEXT_WHITE)
			# Foreground dark wooden conference table across lower torso of seated trio!
			var tbl_y: float = h * 0.79
			draw_rect(Rect2(0.0, tbl_y, w, 10.0), Color("#6B4C35"))
			draw_rect(Rect2(0.0, tbl_y + 10.0, w, h - tbl_y), Color("#3D2A1C"))
			# Club dossier folder & pen sitting directly in front of the Player!
			draw_rect(Rect2(cx - 28.0, tbl_y - 10.0, 28.0, 18.0), Color("#E2E8F0"))
			draw_rect(Rect2(cx, tbl_y - 10.0, 28.0, 18.0), _pri())

		# Part 3 Chapters 10 & 11: Live TV Pundit Quote Boxes + Continuous Scrolling BREAKING NEWS Ticker!
		elif ch in [CH_TV_DEBATE, CH_TEAM_OF_SEASON]:
			# Timed TV Pundit Quotes!
			var show_q: bool = (ch == CH_TV_DEBATE and ct >= 1.8 and ct < 7.2) or (ch == CH_TEAM_OF_SEASON and ct >= 4.2 and ct < 8.1)
			if show_q:
				var p_idx: int = clampi(int(owner_modal.get("_tv_pundit_idx")), 0, 2)
				var u_nm: String = str(_ctx().get("player_name", "BINTANG")).split(" ")[0]
				var rv_nm: String = str(_ctx().get("rival", {}).get("name", "FREDDIE DUNMORE"))
				var rv_first: String = rv_nm.split(" ")[0]
				var roles: Array[String] = ["EKS PEMAIN", "KRITIKUS", "SANG WARTAWAN"]
				var quotes_deb: Array[String] = [
					"\"Usianya sebaya dengan %s dan tampil konsisten sepanjang musim.\"" % u_nm,
					"\"%s sudah bermain seperti bintang besar. %s masih harus membuktikan diri.\"" % [rv_nm, u_nm],
					"\"Mulai hari ini, setiap akhir pekan pertanyaannya sama: %s atau %s?\"" % [u_nm, rv_first],
				]
				var quotes_xi: Array[String] = [
					"\"Dia layak mendapatkannya, tampil gemilang laga demi laga.\"",
					"\"Masuk sebelas terbaik liga musim ini. Benar-benar bukan main.\"",
					"\"Tak terbantahkan di tim terbaik musim ini. Contoh bagi semua.\"",
				]
				var q_txt: String = quotes_deb[p_idx] if ch == CH_TV_DEBATE else quotes_xi[p_idx]
				var qx: float = w * 0.50 - 220.0
				var qy: float = h * 0.72
				draw_rect(Rect2(qx, qy, 440.0, 74.0), Color(0.06, 0.08, 0.14, 0.94))
				draw_rect(Rect2(qx, qy, 440.0, 74.0), Color("#EAB308"), false, 2.0)
				draw_rect(Rect2(qx + 12.0, qy - 10.0, 126.0, 18.0), Color("#B45309"))
				draw_string(fdisp, Vector2(qx + 18.0, qy + 3.0), roles[p_idx], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("#FEF9C3"))
				draw_string(fdisp, Vector2(qx + 14.0, qy + 34.0), q_txt.left(54), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, UITheme.TEXT_WHITE)
				if q_txt.length() > 54:
					draw_string(fdisp, Vector2(qx + 14.0, qy + 54.0), q_txt.substr(54).strip_edges(), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, UITheme.TEXT_WHITE)

			# Continuous Scrolling Bottom BREAKING NEWS Ticker!
			var tick_y: float = h - 26.0
			draw_rect(Rect2(0.0, tick_y, w, 26.0), Color("#0A0D16"))
			draw_rect(Rect2(0.0, tick_y, w, 2.0), Color("#EF4444"))
			var crawl: String
			if ch == CH_TV_DEBATE:
				crawl = "AKU %d%%  •  %s %d%%  •  SIAPA TERBAIK?  •  DEBAT DIMULAI   |   " % [
					int(_ctx().get("debate_user_pct", 78)),
					str(_ctx().get("rival", {}).get("name", "DUNMORE")),
					int(_ctx().get("debate_rival_pct", 22)),
				]
			else:
				crawl = "KAMU MASUK INTI  •  %s  •  TIM TERBAIK MUSIM %d  •  %s   |   " % [
					str(_ctx().get("player_name", "BINTANG")),
					int(_ctx().get("season_num", 1)),
					str(_ctx().get("league_name", "LIGA UTAMA")),
				]
			var cw: float = maxf(420.0, fdisp.get_string_size(crawl, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x)
			var dx: float = 128.0 - fmod(t * 58.0, cw)
			while dx < w + cw:
				draw_string(fdisp, Vector2(dx, tick_y + 17.0), crawl, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#FDE047"))
				dx += cw
			# Fixed Left Red BREAKING NEWS Pill (drawn over ticker start cleanly)
			draw_rect(Rect2(0.0, tick_y, 124.0, 26.0), Color("#DC2626"))
			draw_string(fdisp, Vector2(10.0, tick_y + 17.0), "BREAKING NEWS", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, UITheme.TEXT_WHITE)

		var show_conf: bool = (ch == CH_PARADE) or (ch == CH_RECORD and ct >= 2.2) or (ch == CH_CLUB_GALA and ct >= 6.6) or (ch == CH_COMP_BEST and ct >= 2.2) or (ch in [CH_BEST_GOAL, CH_GOLDEN_BOY, CH_WORLD_BEST] and ct >= float(owner_modal.call("_get_theater_reveal_time", ch))) or (ch == CH_NATIONAL_CALLUP and bool(_ctx().get("timnas_called", true)) and ct >= 3.4)
		if not show_conf:
			return
		var conf: Array = owner_modal.get("_confetti")
		var alpha_m: float = 0.92 if ch == CH_PARADE else 0.75
		for c in conf:
			var col: Color = c["col"]
			var sz: float = float(c["sz"])
			var spin: float = absf(cos(t * 5.0 + float(c["phase"])))
			draw_rect(Rect2(float(c["x"]), float(c["y"]), sz, maxf(1.8, sz * spin)), Color(col.r, col.g, col.b, col.a * alpha_m))
