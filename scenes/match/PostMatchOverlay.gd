extends Control

signal finished
signal replay_requested(clip: Dictionary)

var report: Dictionary = {}
var _stage: int = 0  # 0 = summary, 1 = moviola, 2 = interview
var _container: Control
var _fx_t: float = 0.0
var _pm_live_lbl: Label
var _mvp_confetti: Control
var _crowd_bg: Control
var _mvp_particles: Array[Dictionary] = []
var _press_flash: ColorRect
var _flash_cd: float = 1.1

func show_report(rep: Dictionary) -> void:
	report = rep
	_stage = 0
	if is_node_ready() and _container != null and is_instance_valid(_container):
		_render_stage()

func _ready() -> void:
	theme = UITheme.build_theme()
	var bg := ColorRect.new()
	bg.color = Color("#060D17")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_container = Control.new()
	_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_container)
	if not report.is_empty():
		_render_stage()

func _clear_container() -> void:
	_pm_live_lbl = null
	_mvp_confetti = null
	_crowd_bg = null
	_mvp_particles.clear()
	_press_flash = null
	if _container == null or not is_instance_valid(_container):
		return
	for c in _container.get_children():
		_container.remove_child(c)
		c.queue_free()

func _process(delta: float) -> void:
	_fx_t += delta
	if is_instance_valid(_pm_live_lbl):
		_pm_live_lbl.modulate.a = 0.45 + 0.55 * sin(_fx_t * 6.5)
	if is_instance_valid(_crowd_bg):
		_crowd_bg.queue_redraw()
	if is_instance_valid(_mvp_confetti):
		_mvp_confetti.queue_redraw()
	if is_instance_valid(_press_flash):
		_flash_cd -= delta
		if _flash_cd <= 0.0:
			_flash_cd = randf_range(1.6, 2.9)
			_press_flash.color = Color(1, 1, 1, 0.55)
			create_tween().tween_property(_press_flash, "color:a", 0.0, 0.24)

func _spawn_mvp_confetti() -> void:
	_mvp_particles.clear()
	var pal := [UITheme.ACCENT_GOLD, UITheme.ACCENT_CYAN, Color("#F472B6"), UITheme.ACCENT_GREEN]
	for i in range(36):
		_mvp_particles.append({
			"x": randf_range(10.0, 950.0),
			"y": randf_range(-20.0, 540.0),
			"vy": randf_range(50.0, 110.0),
			"p": randf() * TAU,
			"c": pal[i % pal.size()],
		})
	_mvp_confetti = Control.new()
	_mvp_confetti.set_anchors_preset(Control.PRESET_FULL_RECT)
	_mvp_confetti.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mvp_confetti.draw.connect(func():
		if _mvp_confetti == null:
			return
		for it in _mvp_particles:
			var px: float = float(it["x"]) + sin(_fx_t * 3.0 + float(it["p"])) * 12.0
			var py: float = fmod(float(it["y"]) + _fx_t * float(it["vy"]), 580.0) - 20.0
			_mvp_confetti.draw_rect(Rect2(px, py, 6, 4), it["c"])
	)
	_container.add_child(_mvp_confetti)

func _render_stage() -> void:
	if _container == null or not is_instance_valid(_container):
		return
	_clear_container()
	if _stage == 0:
		_render_summary()
	elif _stage == 1:
		_render_moviola()
	elif _stage == 2:
		_render_interview()
	else:
		_render_hasil()

func _render_summary() -> void:
	var club: Dictionary = CareerState.get_current_club()
	var fix: Dictionary = report.get("fixture", {})
	var is_home: bool = bool(fix.get("is_home", true))
	var opp_cid: int = clampi(int(fix.get("opp_club_id", 0)), 0, GameData.clubs.size() - 1)
	var opp_club: Dictionary = GameData.clubs[opp_cid]
	var opp_name: String = str(fix.get("opp_name", opp_club.get("name", "LAWAN"))).to_upper()
	var my_name: String = str(club.get("name", "KLUB")).to_upper()
	var sc_us: int = int(report.get("score_us", 0))
	var sc_them: int = int(report.get("score_them", 0))
	var pen_u: int = int(report.get("pen_us", -1))
	var pen_t: int = int(report.get("pen_them", -1))

	# Full-screen animated stadium crowd backdrop (Gambar 2!)
	var crowd_bg := Control.new()
	crowd_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	crowd_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var crowd_pri: Color = UITheme.parse_color(club.get("primary", Color("#2563EB")), Color("#2563EB"))
	var crowd_sec: Color = UITheme.parse_color(club.get("secondary", Color("#FFFFFF")), Color("#FFFFFF"))
	crowd_bg.draw.connect(func():
		var s: Vector2 = crowd_bg.size
		if s.x <= 4.0 or s.y <= 4.0:
			return
		var t_now: float = _fx_t
		# Twilight sky + stadium roof
		crowd_bg.draw_rect(Rect2(0, 0, s.x, s.y * 0.30), Color("#384354"), true)
		crowd_bg.draw_rect(Rect2(0, s.y * 0.28, s.x, s.y * 0.72), Color("#1E242E"), true)
		# Stepped concrete stand tiers
		for tier in range(6):
			var ty: float = s.y * (0.28 + float(tier) * 0.12)
			crowd_bg.draw_rect(Rect2(0, ty, s.x, 3.0), Color("#2D3644"), true)
			var cols_n: int = 13
			for cx_i in range(cols_n):
				var seed_i: int = tier * 31 + cx_i * 17
				var fx: float = (float(cx_i) + 0.5 + (0.22 if tier % 2 == 1 else -0.18)) * (s.x / float(cols_n))
				var bounce: float = absf(sin(t_now * 4.5 + float(seed_i) * 0.7)) * 4.5
				var fy: float = ty + 24.0 - bounce
				var shirt_c: Color = crowd_pri if (seed_i % 3 != 0) else Color("#4E5338")
				var skin_c: Color = [Color("#E2B48D"), Color("#C89066"), Color("#8F5C3B")][seed_i % 3]
				# Head + torso
				crowd_bg.draw_rect(Rect2(fx - 5, fy - 14, 10, 9), skin_c, true)
				crowd_bg.draw_rect(Rect2(fx - 5, fy - 16, 10, 4), Color("#1A1715"), true)
				crowd_bg.draw_rect(Rect2(fx - 7, fy - 4, 14, 14), shirt_c, true)
				# Raised arms & club scarf for cheering fans
				if seed_i % 2 == 0:
					crowd_bg.draw_rect(Rect2(fx - 11, fy - 16, 4, 12), shirt_c, true)
					crowd_bg.draw_rect(Rect2(fx + 7, fy - 16, 4, 12), shirt_c, true)
					crowd_bg.draw_rect(Rect2(fx - 13, fy - 21, 26, 5), crowd_sec, true)
					crowd_bg.draw_rect(Rect2(fx - 10, fy - 20, 20, 3), crowd_pri, true)
		# Soft rain / atmosphere streaks
		for ri in range(22):
			var rx: float = fmod(float(ri) * 57.3 + t_now * 18.0, s.x)
			var ry: float = fmod(float(ri) * 41.7 + t_now * 180.0, s.y)
			crowd_bg.draw_line(Vector2(rx, ry), Vector2(rx - 2.0, ry + 11.0), Color(0.85, 0.92, 1.0, 0.22), 1.2)
		# Subtle dark bottom vignette so cards stay razor crisp
		crowd_bg.draw_rect(Rect2(0, s.y * 0.44, s.x, s.y * 0.56), Color(0.02, 0.05, 0.10, 0.58), true)
	)
	_container.add_child(crowd_bg)
	_crowd_bg = crowd_bg

	var is_motm: bool = bool(report.get("motm", false))
	if is_motm:
		_spawn_mvp_confetti()

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 26
	vb.offset_right = -26
	vb.offset_top = 14
	vb.offset_bottom = -14
	vb.add_theme_constant_override("separation", 10)
	_container.add_child(vb)

	# 1. TOP CRIMSON-BORDERED SCOREBOARD CARD (EXACT GAMBAR 2 STYLE!)
	var top_card := PanelContainer.new()
	var tcsb := StyleBoxFlat.new()
	tcsb.bg_color = Color("#070C17", 0.96)
	tcsb.border_color = Color("#D62848")
	tcsb.set_border_width_all(3)
	tcsb.set_corner_radius_all(6)
	tcsb.content_margin_left = 14
	tcsb.content_margin_right = 14
	tcsb.content_margin_top = 8
	tcsb.content_margin_bottom = 8
	top_card.add_theme_stylebox_override("panel", tcsb)
	vb.add_child(top_card)
	top_card.modulate.a = 0.0
	create_tween().tween_property(top_card, "modulate:a", 1.0, 0.24)

	var tc_vb := VBoxContainer.new()
	tc_vb.add_theme_constant_override("separation", 6)
	top_card.add_child(tc_vb)

	var wk_now: int = int(CareerState.career.get("careerMeta", {}).get("week", 1))
	var max_wk_now: int = int(CareerState.career.get("careerMeta", {}).get("maxWeeks", 45))
	var meta_hb := HBoxContainer.new()
	tc_vb.add_child(meta_hb)
	var m_left := Label.new()
	m_left.text = "●  %s  •  P%d/%d" % [str(fix.get("comp_label", "LIGA")).to_upper(), maxi(1, wk_now - 1), max_wk_now]
	m_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m_left.add_theme_font_override("font", UITheme.get_display_font())
	m_left.add_theme_font_size_override("font_size", 10)
	m_left.add_theme_color_override("font_color", Color("#FB7185"))
	meta_hb.add_child(m_left)
	var m_right := Label.new()
	m_right.text = "LAGA USAI" if pen_u < 0 else "LAGA USAI (PEN %d-%d)" % [pen_u, pen_t]
	m_right.add_theme_font_override("font", UITheme.get_display_font())
	m_right.add_theme_font_size_override("font_size", 11)
	m_right.add_theme_color_override("font_color", Color("#F8FAFC"))
	meta_hb.add_child(m_right)

	var sep_top := ColorRect.new()
	sep_top.custom_minimum_size = Vector2(0, 1)
	sep_top.color = Color("#2C1826")
	tc_vb.add_child(sep_top)

	# Build per-team compact scorer strings from goal_timeline
	var g_tl: Array = report.get("goal_timeline", [])
	var us_scorers_map: Dictionary = {}
	var them_scorers_map: Dictionary = {}
	for ge_item in g_tl:
		var ge: Dictionary = ge_item
		var sc_n: String = str(ge.get("scorer", "GOL")).to_upper()
		var last_n: String = sc_n.split(" ")[sc_n.split(" ").size() - 1]
		var mn_s: String = "%d'" % int(ge.get("minute", 45))
		var target_m: Dictionary = us_scorers_map if bool(ge.get("is_us", true)) else them_scorers_map
		if not target_m.has(last_n):
			target_m[last_n] = []
		target_m[last_n].append(mn_s)

	var us_sc_parts: PackedStringArray = []
	for k in us_scorers_map.keys():
		var mins_arr: Array = us_scorers_map[k]
		us_sc_parts.append("%s %s" % [str(k), " ".join(PackedStringArray(mins_arr))])
	var them_sc_parts: PackedStringArray = []
	for k in them_scorers_map.keys():
		var mins_arr: Array = them_scorers_map[k]
		them_sc_parts.append("%s %s" % [str(k), " ".join(PackedStringArray(mins_arr))])

	var home_row: Dictionary = {
		"cid": int(club["id"]) if is_home else opp_cid,
		"name": my_name if is_home else opp_name,
		"score": sc_us if is_home else sc_them,
		"scorers": "   ".join(us_sc_parts) if is_home else "   ".join(them_sc_parts),
	}
	var away_row: Dictionary = {
		"cid": opp_cid if is_home else int(club["id"]),
		"name": opp_name if is_home else my_name,
		"score": sc_them if is_home else sc_us,
		"scorers": "   ".join(them_sc_parts) if is_home else "   ".join(us_sc_parts),
	}

	for team_r in [home_row, away_row]:
		var rhb := HBoxContainer.new()
		rhb.add_theme_constant_override("separation", 10)
		tc_vb.add_child(rhb)
		var cr_c := CenterContainer.new()
		var cr := ClubCrest.new()
		cr.custom_minimum_size = Vector2(28, 28)
		cr.set_club(int(team_r["cid"]))
		cr_c.add_child(cr)
		rhb.add_child(cr_c)
		var tvb := VBoxContainer.new()
		tvb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tvb.add_theme_constant_override("separation", 1)
		rhb.add_child(tvb)
		var tnm := Label.new()
		tnm.text = str(team_r["name"])
		tnm.add_theme_font_override("font", UITheme.get_display_font())
		tnm.add_theme_font_size_override("font_size", 16)
		tnm.add_theme_color_override("font_color", Color.WHITE)
		tvb.add_child(tnm)
		if not str(team_r["scorers"]).is_empty():
			var tsc := Label.new()
			tsc.text = str(team_r["scorers"])
			tsc.clip_text = true
			tsc.add_theme_font_override("font", UITheme.get_display_font())
			tsc.add_theme_font_size_override("font_size", 9)
			tsc.add_theme_color_override("font_color", Color("#F5C430"))
			tvb.add_child(tsc)
		var scr_l := Label.new()
		scr_l.text = str(int(team_r["score"]))
		scr_l.custom_minimum_size = Vector2(36, 0)
		scr_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		scr_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		scr_l.add_theme_font_override("font", UITheme.get_display_font())
		scr_l.add_theme_font_size_override("font_size", 28)
		scr_l.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
		rhb.add_child(scr_l)

	# Spacer letting the animated cheering stadium crowd peek through!
	var crowd_peek := Control.new()
	crowd_peek.custom_minimum_size = Vector2(0, 26)
	vb.add_child(crowd_peek)

	# 2. MAIN 2-COLUMN CARDS: LEFT = ▸ GOL TIMELINE | RIGHT = ★ PEMAIN TERBAIK LAGA + REWARDS
	var split_hb := HBoxContainer.new()
	split_hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split_hb.add_theme_constant_override("separation", 14)
	vb.add_child(split_hb)

	# LEFT: ▸ GOL Timeline Card (Gambar 2!)
	var tl_card := PanelContainer.new()
	tl_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tl_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var tlsb := StyleBoxFlat.new()
	tlsb.bg_color = Color("#07101E", 0.94)
	tlsb.border_color = Color("#1F3352")
	tlsb.set_border_width_all(1)
	tlsb.set_corner_radius_all(8)
	tlsb.content_margin_left = 14
	tlsb.content_margin_right = 14
	tlsb.content_margin_top = 10
	tlsb.content_margin_bottom = 10
	tl_card.add_theme_stylebox_override("panel", tlsb)
	split_hb.add_child(tl_card)

	var tl_vb := VBoxContainer.new()
	tl_vb.add_theme_constant_override("separation", 6)
	tl_card.add_child(tl_vb)
	var tl_hdr := Label.new()
	tl_hdr.text = "▸ GOL"
	tl_hdr.add_theme_font_override("font", UITheme.get_display_font())
	tl_hdr.add_theme_font_size_override("font_size", 11)
	tl_hdr.add_theme_color_override("font_color", Color("#94ADC8"))
	tl_vb.add_child(tl_hdr)

	var tl_scroll := ScrollContainer.new()
	tl_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tl_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	tl_vb.add_child(tl_scroll)
	var tl_list := VBoxContainer.new()
	tl_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tl_list.add_theme_constant_override("separation", 4)
	tl_scroll.add_child(tl_list)

	if g_tl.is_empty():
		var no_g := Label.new()
		no_g.text = "Tidak ada gol tercipta di laga ini (0 - 0)."
		no_g.add_theme_font_size_override("font_size", 11)
		no_g.add_theme_color_override("font_color", Color("#7C90AB"))
		tl_list.add_child(no_g)
	else:
		for ge_item in g_tl:
			var ge: Dictionary = ge_item
			var is_us_g: bool = bool(ge.get("is_us", true))
			var row_vb := VBoxContainer.new()
			row_vb.add_theme_constant_override("separation", 2)
			tl_list.add_child(row_vb)
			var ghb := HBoxContainer.new()
			ghb.add_theme_constant_override("separation", 8)
			row_vb.add_child(ghb)

			var ml := Label.new()
			ml.text = "%d'" % int(ge.get("minute", 45))
			ml.custom_minimum_size = Vector2(30, 0)
			ml.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			ml.add_theme_font_override("font", UITheme.get_display_font())
			ml.add_theme_font_size_override("font_size", 11)
			ml.add_theme_color_override("font_color", Color("#CBD5E1"))
			ghb.add_child(ml)

			var dot_l := Label.new()
			dot_l.text = "●"
			dot_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			dot_l.add_theme_font_size_override("font_size", 11)
			dot_l.add_theme_color_override("font_color", UITheme.ACCENT_GOLD if is_us_g else Color("#EF4444"))
			ghb.add_child(dot_l)

			var svb := VBoxContainer.new()
			svb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			svb.add_theme_constant_override("separation", 0)
			ghb.add_child(svb)
			var sn := Label.new()
			sn.text = str(ge.get("scorer", "GOL")).to_upper()
			sn.add_theme_font_override("font", UITheme.get_display_font())
			sn.add_theme_font_size_override("font_size", 12)
			sn.add_theme_color_override("font_color", Color.WHITE)
			svb.add_child(sn)
			var ast_s: String = str(ge.get("assist", ""))
			if not ast_s.is_empty():
				var al := Label.new()
				al.text = "AST %s" % ast_s.to_upper()
				al.add_theme_font_size_override("font_size", 8)
				al.add_theme_color_override("font_color", Color("#8FA6C0"))
				svb.add_child(al)

			var clip_d: Dictionary = ge.get("clip", {})
			if bool(ge.get("is_user_involved", false)) and (not clip_d.is_empty() or not CareerState.last_moviola_clip.is_empty()):
				var cek_b := Button.new()
				cek_b.text = "▶ CEK"
				cek_b.custom_minimum_size = Vector2(62, 24)
				cek_b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
				cek_b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
				UITheme.style_btn(cek_b, Color("#A81A3B"), Color("#FB7185"), 10)
				var use_clip: Dictionary = clip_d if not clip_d.is_empty() else CareerState.last_moviola_clip
				cek_b.pressed.connect(func():
					AudioSynth.play_click()
					replay_requested.emit(use_clip)
				)
				ghb.add_child(cek_b)

			var row_sep := ColorRect.new()
			row_sep.custom_minimum_size = Vector2(0, 1)
			row_sep.color = Color("#16253E")
			row_vb.add_child(row_sep)

	# RIGHT COLUMN: ★ PEMAIN TERBAIK LAGA Card + Compact Rewards
	var right_vb := VBoxContainer.new()
	right_vb.custom_minimum_size = Vector2(392, 0)
	right_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vb.add_theme_constant_override("separation", 8)
	split_hb.add_child(right_vb)

	# ★ PEMAIN TERBAIK LAGA Card (EXACT GAMBAR 2 BOTTOM CARD!)
	var motm_p: Dictionary = report.get("motm_player", {})
	var motm_is_user: bool = is_motm or bool(motm_p.get("is_user", false))
	var motm_name: String = str(CareerState.career["playerProfile"].get("name", "PEMAIN")).to_upper() if motm_is_user else str(motm_p.get("name", "BINTANG LAGA")).to_upper()
	var motm_cid: int = int(club["id"]) if motm_is_user else int(motm_p.get("club_id", opp_cid))
	var motm_cname: String = my_name if motm_is_user else str(motm_p.get("club_name", opp_name)).to_upper()
	var motm_goals: int = int(report.get("my_goals", 0)) if motm_is_user else int(motm_p.get("goals", 1))
	var motm_rtg: float = float(report.get("rating", 7.5)) if motm_is_user else float(motm_p.get("rating", 7.8))

	var motm_card := PanelContainer.new()
	motm_card.add_theme_stylebox_override("panel", tlsb.duplicate())
	right_vb.add_child(motm_card)
	var m_vb := VBoxContainer.new()
	m_vb.add_theme_constant_override("separation", 6)
	motm_card.add_child(m_vb)
	var m_hdr := Label.new()
	m_hdr.text = "★ PEMAIN TERBAIK LAGA"
	m_hdr.add_theme_font_override("font", UITheme.get_display_font())
	m_hdr.add_theme_font_size_override("font_size", 10)
	m_hdr.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	m_vb.add_child(m_hdr)

	var m_hb := HBoxContainer.new()
	m_hb.add_theme_constant_override("separation", 12)
	m_vb.add_child(m_hb)
	var av_box := PanelContainer.new()
	av_box.custom_minimum_size = Vector2(68, 76)
	av_box.add_theme_stylebox_override("panel", UITheme.make_box(Color("#12233B"), UITheme.ACCENT_GOLD if motm_is_user else Color("#304A6E"), 1, 5))
	m_hb.add_child(av_box)
	var p_av := PixelAvatar.new()
	p_av.custom_minimum_size = Vector2(60, 70)
	if motm_is_user:
		p_av.configure_from_career()
		p_av.show_mvp_trophy = true
		p_av.anim_mode = "MVP"
	else:
		var m_clb: Dictionary = GameData.clubs[clampi(motm_cid, 0, GameData.clubs.size() - 1)]
		p_av.configure_random_npc(int(motm_p.get("seed", 77)), m_clb, false)
		p_av.anim_mode = "CHEER"
	av_box.add_child(p_av)

	var m_info := VBoxContainer.new()
	m_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	m_info.alignment = BoxContainer.ALIGNMENT_CENTER
	m_info.add_theme_constant_override("separation", 3)
	m_hb.add_child(m_info)
	var m_nm := Label.new()
	m_nm.text = motm_name
	m_nm.add_theme_font_override("font", UITheme.get_display_font())
	m_nm.add_theme_font_size_override("font_size", 15)
	m_nm.add_theme_color_override("font_color", Color.WHITE)
	m_info.add_child(m_nm)
	var mc_hb := HBoxContainer.new()
	mc_hb.add_theme_constant_override("separation", 5)
	m_info.add_child(mc_hb)
	var mcr := ClubCrest.new()
	mcr.custom_minimum_size = Vector2(14, 14)
	mcr.set_club(motm_cid)
	mc_hb.add_child(mcr)
	var mcn := Label.new()
	mcn.text = motm_cname
	mcn.add_theme_font_size_override("font_size", 9)
	mcn.add_theme_color_override("font_color", Color("#94ADC8"))
	mc_hb.add_child(mcn)
	var m_stat := Label.new()
	var g_txt: String = "%d GOL  •  " % motm_goals if motm_goals > 0 else ""
	m_stat.text = "● %sRTG %s" % [g_txt, ("%.1f" % motm_rtg).replace(".", ",")]
	m_stat.add_theme_font_override("font", UITheme.get_display_font())
	m_stat.add_theme_font_size_override("font_size", 10)
	m_stat.add_theme_color_override("font_color", Color("#F5C430"))
	m_info.add_child(m_stat)

	# Compact Career Performance & Rewards Strip
	var rew_card := PanelContainer.new()
	rew_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rew_card.add_theme_stylebox_override("panel", tlsb.duplicate())
	right_vb.add_child(rew_card)
	var rew_vb := VBoxContainer.new()
	rew_vb.add_theme_constant_override("separation", 4)
	rew_card.add_child(rew_vb)

	var r_val: float = float(report.get("rating", 6.2))
	var r_top := HBoxContainer.new()
	rew_vb.add_child(r_top)
	var rl_l := Label.new()
	rl_l.text = "PERFORMAMU • %d G • %d A" % [int(report.get("my_goals", 0)), int(report.get("my_assists", 0))]
	rl_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rl_l.add_theme_font_override("font", UITheme.get_display_font())
	rl_l.add_theme_font_size_override("font_size", 10)
	rl_l.add_theme_color_override("font_color", Color("#CBD5E1"))
	r_top.add_child(rl_l)
	var rl_v := Label.new()
	rl_v.text = "RTG %s" % ("%.1f" % r_val).replace(".", ",")
	rl_v.add_theme_font_override("font", UITheme.get_display_font())
	rl_v.add_theme_font_size_override("font_size", 12)
	rl_v.add_theme_color_override("font_color", UITheme.ACCENT_GOLD if r_val >= 8.0 else UITheme.ACCENT_GREEN)
	r_top.add_child(rl_v)

	var rew_grid := GridContainer.new()
	rew_grid.columns = 2
	rew_grid.add_theme_constant_override("h_separation", 10)
	rew_grid.add_theme_constant_override("v_separation", 2)
	rew_vb.add_child(rew_grid)
	for rw_s in [
		"+%d XP%s" % [int(report.get("xp_gained", 0)), (" (2X DERBY!)" if bool(report.get("won_derby", false)) else "")],
		"+%s" % UITheme.format_cash(int(report.get("cash_earned", 0))),
		"+%d LEGACY" % int(report.get("legacy_add", 0)),
		"+%d PENGIKUT" % int(report.get("follower_gain", 0)),
	]:
		var l := Label.new()
		l.text = str(rw_s)
		l.add_theme_font_size_override("font_size", 10)
		l.add_theme_color_override("font_color", Color("#E2E8F0"))
		rew_grid.add_child(l)
	if bool(report.get("leveled_up", false)):
		var lvl_l := Label.new()
		lvl_l.text = "▲ NAIK LEVEL %d! (+3 SKILL POIN)" % int(report.get("new_level", 2))
		lvl_l.add_theme_font_override("font", UITheme.get_display_font())
		lvl_l.add_theme_font_size_override("font_size", 10)
		lvl_l.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
		rew_vb.add_child(lvl_l)

	if not CareerState.last_moviola_clip.is_empty():
		var mov_btn := Button.new()
		mov_btn.text = "▶ STUDIO MOVIOLA"
		mov_btn.custom_minimum_size = Vector2(0, 28)
		mov_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		UITheme.style_btn(mov_btn, Color("#153B6E"), UITheme.ACCENT_CYAN, 11)
		mov_btn.pressed.connect(func():
			AudioSynth.play_click()
			_stage = 1
			_render_stage()
		)
		rew_vb.add_child(mov_btn)

	# 3. BOTTOM FULL-WIDTH CRIMSON-OUTLINED 'LANJUTKAN' BUTTON (EXACT GAMBAR 2!)
	var next_btn := Button.new()
	next_btn.text = "LANJUTKAN"
	next_btn.custom_minimum_size = Vector2(0, 44)
	next_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var nsb := StyleBoxFlat.new()
	nsb.bg_color = Color("#080D18", 0.96)
	nsb.border_color = Color("#D62848")
	nsb.set_border_width_all(2)
	nsb.set_corner_radius_all(5)
	var nsbh := nsb.duplicate()
	nsbh.bg_color = Color("#1B1020")
	nsbh.border_color = Color("#FB7185")
	next_btn.add_theme_stylebox_override("normal", nsb)
	next_btn.add_theme_stylebox_override("hover", nsbh)
	next_btn.add_theme_stylebox_override("pressed", nsbh)
	next_btn.add_theme_font_override("font", UITheme.get_display_font())
	next_btn.add_theme_font_size_override("font_size", 16)
	next_btn.add_theme_color_override("font_color", Color.WHITE)
	next_btn.pressed.connect(func():
		AudioSynth.play_click()
		if bool(report.get("motm", false)) or int(report.get("my_goals", 0)) > 0:
			_stage = 2
			_render_stage()
		else:
			_stage = 3
			_render_stage()
	)
	vb.add_child(next_btn)

func _render_moviola() -> void:
	# Matching Screenshot #2: Purple broadcast studio desk with 3 pundits + MOVIOLA card!
	var studio := TextureRect.new()
	studio.texture = load("res://assets/sprites/backgrounds/studio_desk.png")
	studio.set_anchors_preset(Control.PRESET_FULL_RECT)
	studio.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_container.add_child(studio)

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 120
	vb.offset_right = -120
	vb.offset_top = 34
	vb.offset_bottom = -16
	vb.add_theme_constant_override("separation", 8)
	_container.add_child(vb)

	var club := CareerState.get_current_club()
	var fix: Dictionary = report.get("fixture", {})
	var clip := CareerState.last_moviola_clip

	# Broadcast Card
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UITheme.make_box(Color("#0E4A7B"), UITheme.ACCENT_CYAN, 2, 2))
	vb.add_child(card)
	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 8)
	card.add_child(cv)

	var top_strip := HBoxContainer.new()
	cv.add_child(top_strip)
	var live_lbl := Label.new()
	live_lbl.text = "● LANGSUNG "
	live_lbl.add_theme_color_override("font_color", Color("#FF8888"))
	_pm_live_lbl = live_lbl
	top_strip.add_child(live_lbl)
	var spc := Control.new()
	spc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_strip.add_child(spc)
	var mov_lbl := Label.new()
	mov_lbl.text = "MOVIOLA ●"
	mov_lbl.add_theme_font_override("font", UITheme.get_display_font())
	mov_lbl.add_theme_color_override("font_color", UITheme.ACCENT_CYAN)
	top_strip.add_child(mov_lbl)

	var cap_lbl := Label.new()
	cap_lbl.text = "%s  %s" % [str(clip.get("caption", "SOROTAN")), CareerState.career["playerProfile"]["name"]]
	cap_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap_lbl.add_theme_font_override("font", UITheme.get_display_font())
	cap_lbl.add_theme_color_override("font_color", Color.WHITE)
	cv.add_child(cap_lbl)

	var mid_hb := HBoxContainer.new()
	mid_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	mid_hb.add_theme_constant_override("separation", 12)
	cv.add_child(mid_hb)
	var cr1 := ClubCrest.new()
	cr1.custom_minimum_size = Vector2(38, 38)
	cr1.set_club(int(club["id"]))
	mid_hb.add_child(cr1)
	var sc := Label.new()
	sc.text = "%d - %d" % [int(report.get("score_us", 0)), int(report.get("score_them", 0))]
	sc.add_theme_font_override("font", UITheme.get_display_font())
	sc.add_theme_font_size_override("font_size", 26)
	mid_hb.add_child(sc)
	var cr2 := ClubCrest.new()
	cr2.custom_minimum_size = Vector2(38, 38)
	cr2.set_club(int(fix.get("opp_club_id", 0)))
	mid_hb.add_child(cr2)
	var opp_l := Label.new()
	opp_l.text = str(fix.get("opp_name", "LAWAN"))
	mid_hb.add_child(opp_l)

	var watch_btn := Button.new()
	watch_btn.text = "▶ PUTAR REKAMAN 3D"
	UITheme.style_btn(watch_btn, Color("#183E6B"), UITheme.ACCENT_GOLD)
	watch_btn.pressed.connect(func():
		AudioSynth.play_click()
		replay_requested.emit(clip)
	)
	cv.add_child(watch_btn)

	# 3 Human-Proportioned Studio Pundits standing behind desk
	var pundits_hb := HBoxContainer.new()
	pundits_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	pundits_hb.add_theme_constant_override("separation", 24)
	pundits_hb.custom_minimum_size = Vector2(0, 118)
	vb.add_child(pundits_hb)
	var pi: int = 0
	for p_role in ["SENIOR_COACH", "REPORTER", "COACH"]:
		var npc := NpcAvatar.new()
		npc.configure_role(p_role, false, club)
		npc.anim_mode = "TALK" if pi == 1 else "IDLE"
		npc.anim_phase = float(pi) * 0.8
		npc.custom_minimum_size = Vector2(72, 114)
		pundits_hb.add_child(npc)
		pi += 1

	var sp2 := Control.new()
	sp2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(sp2)

	var bottom_box := PanelContainer.new()
	bottom_box.add_theme_stylebox_override("panel", UITheme.make_box(Color("#0E1A2B"), UITheme.ACCENT_RED, 2, 2))
	vb.add_child(bottom_box)
	var bvb := VBoxContainer.new()
	bottom_box.add_child(bvb)
	var bl1 := Label.new()
	bl1.text = str(clip.get("caption", "SOROTAN LAGA"))
	bl1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bl1.add_theme_font_override("font", UITheme.get_display_font())
	bvb.add_child(bl1)
	var bl2 := Label.new()
	bl2.text = "%s • MUSIM %d\nTV memutarnya berulang kali." % [club["name"].to_upper(), int(CareerState.career["careerMeta"]["year"])]
	bl2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bvb.add_child(bl2)
	var cont := Button.new()
	cont.text = "LANJUT"
	cont.custom_minimum_size = Vector2(0, 42)
	UITheme.style_btn(cont, Color("#121D2E"), UITheme.ACCENT_RED, 16)
	cont.pressed.connect(func():
		AudioSynth.play_click()
		_stage = 2
		_render_stage()
	)
	bvb.add_child(cont)

func _render_interview() -> void:
	# Landscape Pitch-Side TV Interview Stage matching Gambar 2:
	# Stadium Grandstands (tribun) + Green Pitch (lapangan) + Club Sponsor Press Wall +
	# Human-Proportioned Player + Standing 'TV' Floor Mic + Side-Profile Human TV Reporter!
	var club: Dictionary = CareerState.get_current_club()
	var fix: Dictionary = report.get("fixture", {})
	var is_motm: bool = bool(report.get("motm", false))
	var g: int = int(report.get("my_goals", 0))
	var a: int = int(report.get("my_assists", 0))
	var r_v: float = float(report.get("rating", 6.8))

	var stage_bg := PressStageBackdrop.new()
	stage_bg.configure_from_club(club, str(fix.get("comp_label", "")))
	_container.add_child(stage_bg)

	if is_motm:
		_spawn_mvp_confetti()

	# Top-Left Broadcast Context Pill (SETELAH LAGA + ClubCrest + Club Name + Match Stats)
	var stat_str: String = "%s • %d GOL • %d AST" % [("%.1f" % r_v).replace(".", ","), g, a]
	var top_pill: PanelContainer = PressStageBackdrop.build_top_club_pill(
		club,
		"SETELAH LAGA • MIKROFON PADAMU" if is_motm else "SETELAH LAGA",
		stat_str
	)
	top_pill.position = Vector2(16, 6)
	_container.add_child(top_pill)

	# Center-Left Human-Proportioned Player Standing Pitch-Side (4x crisp pixel scale!)
	var av := PixelAvatar.new()
	av.position = Vector2(332, 108)
	av.size = Vector2(142, 236)
	av.mouse_filter = Control.MOUSE_FILTER_IGNORE
	av.configure_from_career()
	av.show_mvp_trophy = is_motm
	av.anim_mode = "INTERVIEW"
	_container.add_child(av)

	# Standing 'TV' Floor Microphone positioned naturally in front of player's left shoulder
	var mic_stand := PressStageBackdrop.BroadcastMicStand.new()
	mic_stand.accent_col = stage_bg.club_primary
	mic_stand.position = Vector2(288, 178)
	mic_stand.size = Vector2(58, 182)
	_container.add_child(mic_stand)

	# Center-Right Side-Profile Human TV Reporter facing LEFT extending handheld mic to player!
	var rep := NpcAvatar.new()
	rep.configure_role("REPORTER", true, club)
	rep.anim_mode = "TALK"
	rep.position = Vector2(436, 108)
	rep.size = Vector2(178, 236)
	rep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.add_child(rep)

	# Subtle camera flash overlay
	_press_flash = ColorRect.new()
	_press_flash.color = Color(1, 1, 1, 0.0)
	_press_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_press_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.add_child(_press_flash)

	# Bottom Narrative Prompt & 3 Gambar 2 Icon-Topped Choice Cards (x=54..906, y=354..528)
	var bot_vb := VBoxContainer.new()
	bot_vb.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bot_vb.offset_left = 54
	bot_vb.offset_right = -54
	bot_vb.offset_top = -178
	bot_vb.offset_bottom = -10
	bot_vb.alignment = BoxContainer.ALIGNMENT_END
	bot_vb.add_theme_constant_override("separation", 6)
	_container.add_child(bot_vb)

	var sc_id_cur: int = int(CareerState.career.get("careerMeta", {}).get("scoutedByClubId", -1)) if CareerState.has_active_career else -1
	if sc_id_cur >= 0 and sc_id_cur < GameData.clubs.size():
		var sc_cl: Dictionary = GameData.clubs[sc_id_cur]
		var sc_wrap := CenterContainer.new()
		bot_vb.add_child(sc_wrap)
		var sc_box := PanelContainer.new()
		var sc_sb := UITheme.make_box(Color("#1A170B", 0.92), UITheme.ACCENT_GOLD, 1, 5)
		sc_sb.content_margin_left = 10
		sc_sb.content_margin_right = 12
		sc_sb.content_margin_top = 3
		sc_sb.content_margin_bottom = 3
		sc_box.add_theme_stylebox_override("panel", sc_sb)
		sc_wrap.add_child(sc_box)
		var sc_hb := HBoxContainer.new()
		sc_hb.alignment = BoxContainer.ALIGNMENT_CENTER
		sc_hb.add_theme_constant_override("separation", 7)
		sc_box.add_child(sc_hb)
		var sc_cr := ClubCrest.new()
		sc_cr.custom_minimum_size = Vector2(20, 20)
		sc_cr.set_club(sc_id_cur)
		sc_hb.add_child(sc_cr)
		var sc_lbl := Label.new()
		sc_lbl.text = "SCOUT MENGINCARMU: %s (DIV %d • OVR %d)" % [str(sc_cl.get("name", "KLUB")).to_upper(), int(sc_cl.get("division", 2)), int(sc_cl.get("ovr", 68))]
		sc_lbl.add_theme_font_override("font", UITheme.get_display_font())
		sc_lbl.add_theme_font_size_override("font_size", 10)
		sc_lbl.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
		sc_hb.add_child(sc_lbl)

	var prompt_lbl := Label.new()
	if is_motm:
		prompt_lbl.text = "Mikrofon di depan wajah dan satu pertanyaan terbuka usai menjadi Pemain Terbaik Laga. Apa pun jawabanmu, itu menggambarkanmu."
	else:
		prompt_lbl.text = "Mikrofon di depan wajah dan satu pertanyaan terbuka. Apa pun jawabanmu, itu menggambarkanmu."
	prompt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt_lbl.add_theme_font_override("font", UITheme.get_display_font())
	prompt_lbl.add_theme_font_size_override("font_size", 12)
	prompt_lbl.add_theme_color_override("font_color", Color("#F8FAFC"))
	prompt_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	prompt_lbl.add_theme_constant_override("shadow_offset_y", 2)
	bot_vb.add_child(prompt_lbl)

	var ch_hb := HBoxContainer.new()
	ch_hb.add_theme_constant_override("separation", 12)
	bot_vb.add_child(ch_hb)

	var tv_choices: Array = [
		{
			"title": "JASA TIM",
			"icon": "JERSEY",
			"col": Color("#7B521D"),
			"chips": [["+3 PELATIH", false], ["+8 SUPORTER", false]],
			"note": "",
			"eff": {"pelatih": 3, "fans": 8},
		},
		{
			"title": "BICARA FORMAMU",
			"icon": "MIC",
			"col": Color("#4C3D7A"),
			"chips": [["+11 PERS", false], ["+5 SCOUT", false], ["-7 TIM", true]],
			"note": "scout akan mengincarmu",
			"eff": {"pers": 11, "ruangGanti": -7, "followers": 420},
		},
		{
			"title": "UNTUK SUPORTER",
			"icon": "FANS",
			"col": Color("#6F324D"),
			"chips": [["+11 SUPORTER", false], ["+3 PERS", false], ["-3 PELATIH", true]],
			"note": "",
			"eff": {"fans": 11, "pers": 3, "pelatih": -3},
		},
	]
	for tvc in tv_choices:
		var cb: Button = PressStageBackdrop.build_gambar2_choice_button(
			str(tvc["title"]),
			str(tvc["icon"]),
			tvc["col"],
			tvc["chips"],
			str(tvc["note"])
		)
		cb.pressed.connect(func():
			AudioSynth.play_click()
			CareerState.apply_cutscene_effects(tvc["eff"])
			if str(tvc["title"]) == "BICARA FORMAMU" and CareerState.has_active_career:
				CareerState.ensure_scout_target_club()
				CareerState.career["careerMeta"]["scoutInterest"] = clampi(int(CareerState.career["careerMeta"].get("scoutInterest", 0)) + 5, 0, 100)
				CareerState.save_active_career()
			_stage = 3
			_render_stage()
		)
		ch_hb.add_child(cb)

func _render_hasil() -> void:
	# New 3 Screenshot 5: Full League Matchday Results + GOL / ASSIST / RATING Leaderboards!
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 20
	vb.offset_right = -20
	vb.offset_top = 14
	vb.offset_bottom = -12
	vb.add_theme_constant_override("separation", 8)
	_container.add_child(vb)

	var fix: Dictionary = report.get("fixture", {})
	var wk: int = int(CareerState.career.get("careerMeta", {}).get("week", 1))
	var max_wk: int = int(CareerState.career.get("careerMeta", {}).get("maxWeeks", 45))
	var hdr := Label.new()
	hdr.text = "● HASIL  •  %s  ·  P%d/%d" % [str(fix.get("comp_label", "LIGA")).to_upper(), wk, max_wk]
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr.add_theme_font_override("font", UITheme.get_display_font())
	hdr.add_theme_font_size_override("font_size", 18)
	hdr.add_theme_color_override("font_color", Color("#FB7185"))
	vb.add_child(hdr)

	var cols := HBoxContainer.new()
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.add_theme_constant_override("separation", 12)
	vb.add_child(cols)

	# Left Column: Division Matchday Scores
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.add_child(scroll)
	var list_vb := VBoxContainer.new()
	list_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_vb.add_theme_constant_override("separation", 4)
	scroll.add_child(list_vb)

	var res_list: Array = CareerState.career.get("careerMeta", {}).get("lastMatchdayResults", [])
	for r in res_list:
		var is_u: bool = bool(r.get("is_user", false))
		var row := PanelContainer.new()
		row.add_theme_stylebox_override("panel", UITheme.make_box(Color("#4A1220") if is_u else Color("#0B1422"), Color("#FB7185") if is_u else UITheme.BORDER_STEEL, 1, 2))
		list_vb.add_child(row)
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 6)
		row.add_child(hb)
		var hl := Label.new()
		hl.text = str(r.get("home_name", "KLUB")).left(18).to_upper()
		hl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hl.add_theme_font_size_override("font_size", 11)
		hb.add_child(hl)
		var sl := Label.new()
		sl.text = "%d - %d" % [int(r.get("home_g", 0)), int(r.get("away_g", 0))]
		sl.custom_minimum_size = Vector2(46, 0)
		sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sl.add_theme_font_override("font", UITheme.get_display_font())
		sl.add_theme_color_override("font_color", UITheme.ACCENT_GOLD if is_u else Color.WHITE)
		hb.add_child(sl)
		var al := Label.new()
		al.text = str(r.get("away_name", "LAWAN")).left(18).to_upper()
		al.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		al.add_theme_font_size_override("font_size", 11)
		hb.add_child(al)

	# Right Column: GOL / ASSIST / RATING League Leaders (New 3 Screenshot 5)
	var lead_scroll := ScrollContainer.new()
	lead_scroll.custom_minimum_size = Vector2(360, 0)
	lead_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.add_child(lead_scroll)
	var lead_vb := VBoxContainer.new()
	lead_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lead_vb.add_theme_constant_override("separation", 6)
	lead_scroll.add_child(lead_vb)

	var leaders: Dictionary = CareerState.get_division_leaders()
	for cat_d in [
		{"title": "GOL", "key": "goals", "is_float": false},
		{"title": "ASSIST", "key": "assists", "is_float": false},
		{"title": "RATING", "key": "rating", "is_float": true},
	]:
		var cat_p := PanelContainer.new()
		cat_p.add_theme_stylebox_override("panel", UITheme.make_box(Color("#0B1422"), UITheme.BORDER_STEEL, 1, 5))
		lead_vb.add_child(cat_p)
		var cvb := VBoxContainer.new()
		cvb.add_theme_constant_override("separation", 2)
		cat_p.add_child(cvb)
		var ch := Label.new()
		ch.text = str(cat_d["title"])
		ch.add_theme_font_override("font", UITheme.get_display_font())
		ch.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
		ch.add_theme_font_size_override("font_size", 11)
		cvb.add_child(ch)
		var rows_arr: Array = leaders.get(str(cat_d["key"]), [])
		var user_shown := false
		for idx in range(mini(4, rows_arr.size())):
			var entry: Dictionary = rows_arr[idx]
			if bool(entry.get("is_user", false)):
				user_shown = true
			_add_leader_row(cvb, idx + 1, entry, bool(cat_d["is_float"]))
		if not user_shown:
			for idx in range(rows_arr.size()):
				if bool(rows_arr[idx].get("is_user", false)):
					_add_leader_row(cvb, idx + 1, rows_arr[idx], bool(cat_d["is_float"]))
					break

	var ok_b := Button.new()
	ok_b.text = "LANJUTKAN"
	ok_b.custom_minimum_size = Vector2(0, 44)
	UITheme.style_btn(ok_b, Color("#0E1D30"), Color("#FB7185"), 16)
	ok_b.pressed.connect(func(): AudioSynth.play_click(); finished.emit())
	vb.add_child(ok_b)

func _add_leader_row(parent: VBoxContainer, rank_n: int, entry: Dictionary, is_float: bool) -> void:
	var is_u: bool = bool(entry.get("is_user", false))
	var d_n: int = int(entry.get("delta", 0))
	var arrow: String = ("▲%d" % d_n) if d_n > 0 else (("▼%d" % abs(d_n)) if d_n < 0 else "-")
	var val_s: String = ("%.1f" % float(entry.get("val", 0.0))) if is_float else str(int(entry.get("val", 0)))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	var bg := PanelContainer.new()
	bg.add_theme_stylebox_override("panel", UITheme.make_box(Color("#4A1220") if is_u else Color(0, 0, 0, 0), Color("#FB7185") if is_u else Color(0, 0, 0, 0), 1 if is_u else 0, 2))
	bg.add_child(hb)
	parent.add_child(bg)
	var rl := Label.new()
	rl.text = "%d" % rank_n
	rl.custom_minimum_size = Vector2(22, 0)
	rl.add_theme_font_size_override("font_size", 10)
	hb.add_child(rl)
	var al := Label.new()
	al.text = arrow
	al.custom_minimum_size = Vector2(28, 0)
	al.add_theme_color_override("font_color", UITheme.ACCENT_GREEN if d_n > 0 else (UITheme.ACCENT_RED if d_n < 0 else UITheme.TEXT_MUTED))
	al.add_theme_font_size_override("font_size", 10)
	hb.add_child(al)
	var nl := Label.new()
	nl.text = str(entry.get("name", "PEMAIN")).left(18)
	nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nl.add_theme_color_override("font_color", UITheme.ACCENT_GOLD if is_u else Color.WHITE)
	nl.add_theme_font_size_override("font_size", 10)
	hb.add_child(nl)
	var vl := Label.new()
	vl.text = val_s
	vl.add_theme_font_override("font", UITheme.get_display_font())
	vl.add_theme_font_size_override("font_size", 11)
	hb.add_child(vl)
