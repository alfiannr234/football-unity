extends Control

signal finished
signal replay_requested(clip: Dictionary)

var report: Dictionary = {}
var _stage: int = 0  # 0 = summary, 1 = moviola, 2 = interview
var _container: Control
var _fx_t: float = 0.0
var _pm_live_lbl: Label
var _mvp_confetti: Control
var _mvp_particles: Array[Dictionary] = []
var _press_flash: ColorRect
var _flash_cd: float = 1.1

func show_report(rep: Dictionary) -> void:
	report = rep
	_stage = 0
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
	_mvp_particles.clear()
	_press_flash = null
	for c in _container.get_children():
		c.queue_free()

func _process(delta: float) -> void:
	_fx_t += delta
	if is_instance_valid(_pm_live_lbl):
		_pm_live_lbl.modulate.a = 0.45 + 0.55 * sin(_fx_t * 6.5)
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
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 24
	vb.offset_right = -24
	vb.offset_top = 16
	vb.offset_bottom = -16
	vb.add_theme_constant_override("separation", 10)
	_container.add_child(vb)

	var club := CareerState.get_current_club()
	var fix: Dictionary = report.get("fixture", {})
	var hdr := Label.new()
	hdr.text = "LAGA USAI  •  %s" % str(fix.get("comp_label", "LIGA")).to_upper()
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr.add_theme_font_override("font", UITheme.get_display_font())
	hdr.add_theme_color_override("font_color", Color("#FB7185"))
	hdr.add_theme_font_size_override("font_size", 18)
	vb.add_child(hdr)

	# Landscape 2-Column Summary: Left = Scoreboard + MVP Spotlight | Right = Stats & Buttons
	var split_hb := HBoxContainer.new()
	split_hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split_hb.add_theme_constant_override("separation", 14)
	vb.add_child(split_hb)

	var left_vb := VBoxContainer.new()
	left_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_vb.add_theme_constant_override("separation", 10)
	split_hb.add_child(left_vb)

	var right_vb := VBoxContainer.new()
	right_vb.custom_minimum_size = Vector2(360, 0)
	right_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vb.add_theme_constant_override("separation", 10)
	split_hb.add_child(right_vb)

	# Scoreboard Card
	var sc_panel := PanelContainer.new()
	sc_panel.add_theme_stylebox_override("panel", UITheme.make_box(UITheme.BG_CARD, UITheme.BORDER_CYAN, 2, 6))
	left_vb.add_child(sc_panel)
	sc_panel.modulate.a = 0.0
	create_tween().tween_property(sc_panel, "modulate:a", 1.0, 0.25)
	var sc_hb := HBoxContainer.new()
	sc_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	sc_hb.add_theme_constant_override("separation", 18)
	sc_panel.add_child(sc_hb)

	var c1 := ClubCrest.new()
	c1.custom_minimum_size = Vector2(56, 56)
	c1.set_club(int(club["id"]))
	sc_hb.add_child(c1)

	var score_txt := Label.new()
	score_txt.text = "%d - %d" % [int(report.get("score_us", 0)), int(report.get("score_them", 0))]
	score_txt.add_theme_font_override("font", UITheme.get_display_font())
	score_txt.add_theme_font_size_override("font_size", 32)
	score_txt.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	sc_hb.add_child(score_txt)

	var c2 := ClubCrest.new()
	c2.custom_minimum_size = Vector2(56, 56)
	c2.set_club(int(fix.get("opp_club_id", 0)))
	sc_hb.add_child(c2)

	# Chronological GOL Timeline with [CEK] Moviola replay button (New 3 Screenshot 7)
	var g_tl: Array = report.get("goal_timeline", [])
	if not g_tl.is_empty():
		var tl_card := PanelContainer.new()
		tl_card.add_theme_stylebox_override("panel", UITheme.make_box(Color("#12101A"), Color("#E11D48"), 1, 6))
		left_vb.add_child(tl_card)
		var tl_vb := VBoxContainer.new()
		tl_vb.add_theme_constant_override("separation", 3)
		tl_card.add_child(tl_vb)
		var tl_hdr := Label.new()
		tl_hdr.text = "GOL"
		tl_hdr.add_theme_font_override("font", UITheme.get_display_font())
		tl_hdr.add_theme_color_override("font_color", Color("#FB7185"))
		tl_hdr.add_theme_font_size_override("font_size", 11)
		tl_vb.add_child(tl_hdr)
		for gi in range(mini(5, g_tl.size())):
			var ge: Dictionary = g_tl[gi]
			var ghb := HBoxContainer.new()
			ghb.add_theme_constant_override("separation", 8)
			tl_vb.add_child(ghb)
			var ml := Label.new()
			ml.text = "%d'" % int(ge.get("minute", 45))
			ml.custom_minimum_size = Vector2(30, 0)
			ml.add_theme_color_override("font_color", UITheme.ACCENT_GOLD if bool(ge.get("is_us", true)) else UITheme.TEXT_MUTED)
			ml.add_theme_font_size_override("font_size", 11)
			ghb.add_child(ml)
			var ast_s: String = str(ge.get("assist", ""))
			var sl := Label.new()
			sl.text = "%s%s" % [str(ge.get("scorer", "GOL")), ("  (AST %s)" % ast_s if not ast_s.is_empty() else "")]
			sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			sl.add_theme_color_override("font_color", Color.WHITE if bool(ge.get("is_us", true)) else Color("#94A3B8"))
			sl.add_theme_font_size_override("font_size", 11)
			ghb.add_child(sl)
			var clip_d: Dictionary = ge.get("clip", {})
			if bool(ge.get("is_user_involved", false)) and (not clip_d.is_empty() or not CareerState.last_moviola_clip.is_empty()):
				var cek_b := Button.new()
				cek_b.text = "CEK"
				cek_b.custom_minimum_size = Vector2(46, 22)
				UITheme.style_btn(cek_b, Color("#9F1239"), Color("#FB7185"), 10)
				var use_clip: Dictionary = clip_d if not clip_d.is_empty() else CareerState.last_moviola_clip
				cek_b.pressed.connect(func():
					AudioSynth.play_click()
					replay_requested.emit(use_clip)
				)
				ghb.add_child(cek_b)

	# Animated MVP / Post-Match Player Spotlight
	var is_motm: bool = bool(report.get("motm", false))
	var my_g: int = int(report.get("my_goals", 0))
	if is_motm:
		_spawn_mvp_confetti()
	var spot_card := PanelContainer.new()
	spot_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spot_card.add_theme_stylebox_override("panel", UITheme.make_box(Color("#1A1A0E") if is_motm else Color("#0A1524"), UITheme.ACCENT_GOLD if is_motm else UITheme.BORDER_STEEL, 2 if is_motm else 1, 6))
	left_vb.add_child(spot_card)
	var sp_hb := HBoxContainer.new()
	sp_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	sp_hb.add_theme_constant_override("separation", 14)
	spot_card.add_child(sp_hb)
	var p_av := PixelAvatar.new()
	p_av.custom_minimum_size = Vector2(82, 120)
	p_av.configure_from_career()
	p_av.show_number_badge = true
	p_av.show_mvp_trophy = is_motm
	p_av.anim_mode = "MVP" if is_motm else ("CHEER" if my_g >= 1 else "IDLE")
	sp_hb.add_child(p_av)
	var sp_vb := VBoxContainer.new()
	sp_vb.alignment = BoxContainer.ALIGNMENT_CENTER
	sp_hb.add_child(sp_vb)
	var mvp_lbl := Label.new()
	mvp_lbl.text = "* PEMAIN TERBAIK LAGA *" if is_motm else ("PERFORMA SOLID!" if my_g >= 1 else "RINGKASAN LAGA")
	mvp_lbl.add_theme_font_override("font", UITheme.get_display_font())
	mvp_lbl.add_theme_font_size_override("font_size", 15)
	mvp_lbl.add_theme_color_override("font_color", UITheme.ACCENT_GOLD if is_motm else UITheme.ACCENT_CYAN)
	sp_vb.add_child(mvp_lbl)
	var sub_sp := Label.new()
	sub_sp.text = "Trofi MVP & sorotan kamera!" if is_motm else "Siap ke analisis Moviola & pers."
	sub_sp.add_theme_font_size_override("font_size", 11)
	sub_sp.add_theme_color_override("font_color", Color("#CBD5E1"))
	sp_vb.add_child(sub_sp)

	# Match Rating + Rewards (Right Column)
	var stats_panel := PanelContainer.new()
	right_vb.add_child(stats_panel)
	var st_vb := VBoxContainer.new()
	st_vb.add_theme_constant_override("separation", 6)
	stats_panel.add_child(st_vb)

	var r_val := float(report.get("rating", 6.2))
	var motm_tag := "  ★ PEMAIN TERBAIK LAGA" if bool(report.get("motm", false)) else ""
	var r_lbl := Label.new()
	r_lbl.text = "RATING LAGA: %.1f%s" % [r_val, motm_tag]
	r_lbl.add_theme_font_override("font", UITheme.get_display_font())
	r_lbl.add_theme_color_override("font_color", UITheme.ACCENT_GOLD if r_val >= 8.0 else UITheme.ACCENT_GREEN)
	st_vb.add_child(r_lbl)

	var lines := [
		"Gol: %d   •   Assist: %d" % [int(report.get("my_goals", 0)), int(report.get("my_assists", 0))],
		"XP Didapat: +%d XP" % int(report.get("xp_gained", 0)),
		"Uang Laga & Sponsor: +%s" % UITheme.format_cash(int(report.get("cash_earned", 0))),
		"Poin Legacy: +%d" % int(report.get("legacy_add", 0)),
		"Pengikut Sosmed: +%d" % int(report.get("follower_gain", 0)),
	]
	if bool(report.get("leveled_up", false)):
		lines.append("NAIK LEVEL KE %d! (+3 SKILL POIN)" % int(report.get("new_level", 2)))
	for ln in lines:
		var l := Label.new()
		l.text = ln
		st_vb.add_child(l)

	if bool(report.get("season_ended", false)):
		var ss: Dictionary = report.get("season_summary", {})
		var s_panel := PanelContainer.new()
		s_panel.add_theme_stylebox_override("panel", UITheme.make_box(Color("#1A2D18"), UITheme.ACCENT_GOLD, 2, 4))
		right_vb.add_child(s_panel)
		var sv := VBoxContainer.new()
		s_panel.add_child(sv)
		var sl1 := Label.new()
		sl1.text = "AKHIR MUSIM! Peringkat Akhir: #%d" % int(ss.get("league_pos", 1))
		sl1.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
		sv.add_child(sl1)
		var tr_list: Array = ss.get("trophies", [])
		if not tr_list.is_empty():
			var tl := Label.new()
			tl.text = "Trofi: %s" % ", ".join(tr_list)
			sv.add_child(tl)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vb.add_child(spacer)

	if not CareerState.last_moviola_clip.is_empty():
		var mov_btn := Button.new()
		mov_btn.text = "▶ LANGSUNG MOVIOLA"
		mov_btn.custom_minimum_size = Vector2(0, 44)
		UITheme.style_btn(mov_btn, Color("#153B6E"), UITheme.ACCENT_CYAN, 15)
		mov_btn.pressed.connect(func():
			AudioSynth.play_click()
			_stage = 1
			_render_stage()
		)
		right_vb.add_child(mov_btn)

	var next_btn := Button.new()
	next_btn.text = "LANJUT"
	next_btn.custom_minimum_size = Vector2(0, 48)
	UITheme.style_btn(next_btn, UITheme.ACCENT_AMBER, UITheme.ACCENT_GOLD, 18)
	next_btn.pressed.connect(func():
		AudioSynth.play_click()
		if bool(report.get("motm", false)) or int(report.get("my_goals", 0)) > 0:
			_stage = 2
			_render_stage()
		else:
			_stage = 3
			_render_stage()
	)
	right_vb.add_child(next_btn)

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

	# 3 Pundits standing behind desk
	var pundits_hb := HBoxContainer.new()
	pundits_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	pundits_hb.add_theme_constant_override("separation", 28)
	pundits_hb.custom_minimum_size = Vector2(0, 114)
	vb.add_child(pundits_hb)
	var pi: int = 0
	for idx in [3, 0, 2]:
		var npc := TextureRect.new()
		var at := AtlasTexture.new()
		at.atlas = load("res://assets/sprites/characters/npcs_sheet.png")
		at.region = Rect2(idx * 24, 0, 24, 36)
		npc.texture = at
		npc.custom_minimum_size = Vector2(68, 102)
		npc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pundits_hb.add_child(npc)
		var ptw := create_tween().set_loops()
		ptw.tween_interval(float(pi) * 0.22)
		ptw.tween_property(npc, "position:y", -5.0, 0.45).as_relative()
		ptw.tween_property(npc, "position:y", 5.0, 0.45).as_relative()
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
	# Matching Screenshot #1: Checkered press backdrop + Player & Reporter with Mic!
	var wall := TextureRect.new()
	wall.texture = load("res://assets/sprites/backgrounds/press_wall.png")
	wall.set_anchors_preset(Control.PRESET_FULL_RECT)
	wall.stretch_mode = TextureRect.STRETCH_TILE
	_container.add_child(wall)

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 120
	vb.offset_right = -120
	vb.offset_top = 24
	vb.offset_bottom = -16
	vb.add_theme_constant_override("separation", 0)
	_container.add_child(vb)

	var sp_top := Control.new()
	sp_top.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(sp_top)

	# Player + Reporter standing side-by-side
	var chars := HBoxContainer.new()
	chars.alignment = BoxContainer.ALIGNMENT_CENTER
	chars.add_theme_constant_override("separation", 24)
	vb.add_child(chars)

	var is_motm: bool = bool(report.get("motm", false))
	if is_motm:
		_spawn_mvp_confetti()

	var av := PixelAvatar.new()
	av.custom_minimum_size = Vector2(126, 188)
	av.configure_from_career()
	av.show_mvp_trophy = is_motm
	av.anim_mode = "MVP" if is_motm else "TALK"
	chars.add_child(av)

	var rep := TextureRect.new()
	var at := AtlasTexture.new()
	at.atlas = load("res://assets/sprites/characters/npcs_sheet.png")
	at.region = Rect2(0, 0, 24, 36)
	rep.texture = at
	rep.custom_minimum_size = Vector2(118, 176)
	rep.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	chars.add_child(rep)
	var rtw := create_tween().set_loops()
	rtw.tween_property(rep, "position:y", -4.0, 0.5).as_relative()
	rtw.tween_property(rep, "position:y", 4.0, 0.5).as_relative()

	_press_flash = ColorRect.new()
	_press_flash.color = Color(1, 1, 1, 0.0)
	_press_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_press_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.add_child(_press_flash)

	# Interactive MIKROFON PADAMU Live TV Interview Card (New 3 Screenshot 17)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UITheme.make_box(Color("#0C121D", 0.96), Color("#FB7185") if is_motm else UITheme.BORDER_CYAN, 2, 8))
	vb.add_child(card)
	var iv := VBoxContainer.new()
	iv.add_theme_constant_override("separation", 6)
	card.add_child(iv)

	var pname := str(CareerState.career["playerProfile"]["name"]).to_upper()
	var g := int(report.get("my_goals", 0))
	var a := int(report.get("my_assists", 0))
	var r_v := float(report.get("rating", 6.8))
	var l1 := Label.new()
	l1.text = "%.1f  •  %d GOL  •  %d AST" % [r_v, g, a]
	l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l1.add_theme_color_override("font_color", Color("#FB7185"))
	l1.add_theme_font_size_override("font_size", 12)
	iv.add_child(l1)

	var l2 := Label.new()
	l2.text = "MIKROFON PADAMU" if is_motm else "WAWANCARA PASCA-LAGA • %s" % pname
	l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l2.add_theme_font_override("font", UITheme.get_display_font())
	l2.add_theme_font_size_override("font_size", 18)
	iv.add_child(l2)

	var l3 := Label.new()
	l3.text = "Pemain terbaik laga. Stasiun TV menahanmu sebelum ruang ganti; 30 detik siaran langsung diputar ulang sepekan penuh." if is_motm else "Mikrofon pers menyapa setelah peluit panjang. Pilih pernyataanmu di depan kamera."
	l3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l3.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l3.add_theme_font_size_override("font_size", 11)
	iv.add_child(l3)

	var ch_hb := HBoxContainer.new()
	ch_hb.add_theme_constant_override("separation", 8)
	iv.add_child(ch_hb)
	var tv_choices := [
		{"title": "JASA TIM", "sub": "+3 Pelatih • +8 Suporter", "col": Color("#1E5668"), "eff": {"pelatih": 3, "fans": 8}},
		{"title": "BICARA FORMAMU", "sub": "+11 Pers • +5 Scout • -7 Tim\nmereka akan mengincarmu", "col": Color("#5E3578"), "eff": {"pers": 11, "ruangGanti": -7, "followers": 420}},
		{"title": "UNTUK SUPORTER", "sub": "+11 Suporter • +3 Pers • -3 Pelatih", "col": Color("#733A5A"), "eff": {"fans": 11, "pers": 3, "pelatih": -3}},
	]
	for tvc in tv_choices:
		var cb := Button.new()
		cb.text = "%s\n%s" % [str(tvc["title"]), str(tvc["sub"])]
		cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cb.custom_minimum_size = Vector2(0, 62)
		var bc: Color = tvc["col"]
		UITheme.style_btn(cb, bc, bc.lightened(0.32), 11)
		cb.pressed.connect(func():
			AudioSynth.play_click()
			CareerState.apply_cutscene_effects(tvc["eff"])
			if str(tvc["title"]) == "BICARA FORMAMU" and CareerState.has_active_career:
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
