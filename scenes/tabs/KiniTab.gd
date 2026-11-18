extends Control

signal start_match_requested
signal open_dilemma_requested
signal open_squad_requested

var _container: VBoxContainer

func _ready() -> void:
	theme = UITheme.build_theme()
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)

	_container = VBoxContainer.new()
	_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_container.add_theme_constant_override("separation", 10)
	scroll.add_child(_container)
	CareerState.career_updated.connect(refresh)
	refresh()

func refresh() -> void:
	if not is_inside_tree() or not CareerState.has_active_career:
		return
	for c in _container.get_children():
		c.queue_free()

	var club := CareerState.get_current_club()
	var fix := CareerState.get_current_fixture()
	var week := int(CareerState.career["careerMeta"]["week"])
	var months := ["AGUSTUS", "SEPTEMBER", "OKTOBER", "NOVEMBER", "DESEMBER", "JANUARI", "FEBRUARI", "MARET", "APRIL", "MEI"]
	var month_name: String = months[clampi(int((week - 1) / 4.5), 0, months.size() - 1)]
	var pos := CareerState.get_user_league_position()
	var total_teams: int = CareerState.career["leagueTable"].size()
	var tw := int(CareerState.career["careerMeta"].get("transferWindowWeeksLeft", 0))

	# Top Match Competition Strip (matching Screenshot #4)
	var comp_panel := PanelContainer.new()
	comp_panel.add_theme_stylebox_override("panel", UITheme.make_box(Color("#0D1B30"), UITheme.BORDER_STEEL, 1, 3))
	_container.add_child(comp_panel)
	var chb := HBoxContainer.new()
	chb.add_theme_constant_override("separation", 10)
	comp_panel.add_child(chb)

	chb.add_child(UITheme.make_flag_rect(int(club["nation_id"]), Vector2(28, 20)))
	var cvb := VBoxContainer.new()
	cvb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chb.add_child(cvb)
	var ct1 := Label.new()
	ct1.text = str(fix.get("comp_label", "LIGA ke-3"))
	ct1.add_theme_font_override("font", UITheme.get_display_font())
	ct1.add_theme_font_size_override("font_size", 16)
	var ct2 := Label.new()
	ct2.text = "%s  •  P %d/%d  •  %s" % [month_name, pos, total_teams, "KANDANG" if fix.get("is_home", true) else "TANDANG"]
	ct2.add_theme_color_override("font_color", UITheme.ACCENT_CYAN)
	cvb.add_child(ct1)
	cvb.add_child(ct2)

	if tw > 0:
		var tw_badge := PanelContainer.new()
		tw_badge.add_theme_stylebox_override("panel", UITheme.make_box(Color("#2D5B34"), UITheme.ACCENT_GREEN, 1, 3))
		var tw_l := Label.new()
		tw_l.text = "BUKA\n%d P" % tw
		tw_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tw_l.add_theme_font_size_override("font_size", 11)
		tw_badge.add_child(tw_l)
		chb.add_child(tw_badge)

	# Landscape 2-Column Body: Left = Matchday Stage + Prob | Right = Actions + Fixtures
	var split_hb := HBoxContainer.new()
	split_hb.add_theme_constant_override("separation", 12)
	_container.add_child(split_hb)

	var left_col := VBoxContainer.new()
	left_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_col.size_flags_stretch_ratio = 1.25
	left_col.add_theme_constant_override("separation", 6)
	split_hb.add_child(left_col)

	var right_col := VBoxContainer.new()
	right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_col.size_flags_stretch_ratio = 0.95
	right_col.add_theme_constant_override("separation", 8)
	split_hb.add_child(right_col)

	# Matchday Stadium Face-Off Card (Crests + OVR + Lined-up Pixel Squads + Trophy)
	var stage := PanelContainer.new()
	stage.custom_minimum_size = Vector2(0, 240)
	stage.add_theme_stylebox_override("panel", UITheme.make_box(Color("#1A4224"), UITheme.BORDER_STEEL, 1, 6))
	left_col.add_child(stage)
	var svb := VBoxContainer.new()
	svb.alignment = BoxContainer.ALIGNMENT_CENTER
	svb.add_theme_constant_override("separation", 4)
	stage.add_child(svb)

	# Crests Row
	var opp_id := int(fix.get("opp_club_id", 0))
	var opp_club: Dictionary = GameData.clubs[opp_id]
	var home_c := club if fix.get("is_home", true) else opp_club
	var away_c := opp_club if fix.get("is_home", true) else club

	var crests_hb := HBoxContainer.new()
	crests_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	crests_hb.add_theme_constant_override("separation", 38)
	svb.add_child(crests_hb)

	for side_c in [home_c, away_c]:
		var side_vb := VBoxContainer.new()
		side_vb.alignment = BoxContainer.ALIGNMENT_CENTER
		crests_hb.add_child(side_vb)
		var cr := ClubCrest.new()
		cr.custom_minimum_size = Vector2(68, 68)
		cr.set_club(int(side_c["id"]))
		side_vb.add_child(cr)
		var nm_hb := HBoxContainer.new()
		nm_hb.alignment = BoxContainer.ALIGNMENT_CENTER
		side_vb.add_child(nm_hb)
		nm_hb.add_child(UITheme.make_ovr_badge(int(side_c["ovr"]), "default", Vector2(28, 24)))
		var nl := Label.new()
		nl.text = " " + str(side_c["name"]).left(16).to_upper()
		nl.add_theme_font_size_override("font_size", 10)
		nm_hb.add_child(nl)

	# Lineup Face-off Row: Staggered 11v11 Tunnel Formation flanking Trophy
	var pitch_hb := HBoxContainer.new()
	pitch_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	pitch_hb.add_theme_constant_override("separation", 6)
	svb.add_child(pitch_hb)

	var left_vb := VBoxContainer.new()
	left_vb.add_theme_constant_override("separation", 2)
	pitch_hb.add_child(left_vb)
	for r_cnt in [6, 5]:
		var row_l := HBoxContainer.new()
		row_l.alignment = BoxContainer.ALIGNMENT_CENTER
		row_l.add_theme_constant_override("separation", -14)
		left_vb.add_child(row_l)
		for i in range(r_cnt):
			var av := PixelAvatar.new()
			av.custom_minimum_size = Vector2(32, 44)
			if i == 0 and r_cnt == 5 and int(home_c["id"]) == int(club["id"]):
				av.configure_from_career()
			else:
				av.configure_from_seed(int(home_c["id"]) * 13 + r_cnt * 7 + i, home_c)
			row_l.add_child(av)

	var mid_trophy := TextureRect.new()
	var tat := AtlasTexture.new()
	tat.atlas = load("res://assets/sprites/ui/trophies_strip.png")
	tat.region = Rect2(6 * 32, 0, 32, 32)
	mid_trophy.texture = tat
	mid_trophy.custom_minimum_size = Vector2(40, 40)
	mid_trophy.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pitch_hb.add_child(mid_trophy)

	var right_vb := VBoxContainer.new()
	right_vb.add_theme_constant_override("separation", 2)
	pitch_hb.add_child(right_vb)
	for r_cnt in [6, 5]:
		var row_r := HBoxContainer.new()
		row_r.alignment = BoxContainer.ALIGNMENT_CENTER
		row_r.add_theme_constant_override("separation", -14)
		right_vb.add_child(row_r)
		for i in range(r_cnt):
			var av := PixelAvatar.new()
			av.custom_minimum_size = Vector2(32, 44)
			if i == 0 and r_cnt == 5 and int(away_c["id"]) == int(club["id"]):
				av.configure_from_career()
			else:
				av.configure_from_seed(int(away_c["id"]) * 17 + r_cnt * 11 + i, away_c)
			row_r.add_child(av)

	# LINE-UP Shortcut button
	var lineup_btn := Button.new()
	lineup_btn.text = "▸ LINE-UP (%s • %s)" % [CareerState.career["clubSquad"]["formation"], CareerState.get_player_role_status()]
	lineup_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	UITheme.style_btn(lineup_btn, Color("#0C192C"), UITheme.BORDER_CYAN, 11)
	lineup_btn.pressed.connect(func(): AudioSynth.play_click(); open_squad_requested.emit())
	svb.add_child(lineup_btn)

	# Win/Draw/Loss Probability Bar
	var diff := int(club["ovr"]) - int(opp_club["ovr"]) + (2 if fix.get("is_home", true) else -1)
	var win_pct := clampi(38 + diff * 3, 12, 78)
	var draw_pct := 25
	var loss_pct := 100 - win_pct - draw_pct
	var prob_hb := HBoxContainer.new()
	prob_hb.add_theme_constant_override("separation", 2)
	left_col.add_child(prob_hb)
	for pr in [
		["M %d%%" % win_pct, win_pct, Color("#1D5CA8")],
		["S %d%%" % draw_pct, draw_pct, Color("#CBD5E1")],
		["K %d%%" % loss_pct, loss_pct, Color("#B93838")],
	]:
		var pb := PanelContainer.new()
		pb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pb.size_flags_stretch_ratio = float(pr[1])
		pb.add_theme_stylebox_override("panel", UITheme.make_box(pr[2], Color.TRANSPARENT, 0, 1))
		var pl := Label.new()
		pl.text = pr[0]
		pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pl.add_theme_color_override("font_color", Color.BLACK if pr[2] == Color("#CBD5E1") else Color.WHITE)
		pl.add_theme_font_size_override("font_size", 11)
		pb.add_child(pl)
		prob_hb.add_child(pb)

	# MAIN LAGA + SIMULASI CEPAT Row
	var play_hb := HBoxContainer.new()
	play_hb.add_theme_constant_override("separation", 8)
	right_col.add_child(play_hb)

	var main_btn := Button.new()
	main_btn.text = "MAIN LAGA"
	main_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_btn.custom_minimum_size = Vector2(0, 50)
	UITheme.style_btn(main_btn, UITheme.ACCENT_AMBER, UITheme.ACCENT_GOLD, 20)
	main_btn.pressed.connect(func(): AudioSynth.play_click(); start_match_requested.emit())
	play_hb.add_child(main_btn)

	var sim_btn := Button.new()
	sim_btn.text = "⚡ SIM"
	sim_btn.custom_minimum_size = Vector2(82, 50)
	UITheme.style_btn(sim_btn, Color("#1C3454"), UITheme.BORDER_CYAN, 14)
	sim_btn.pressed.connect(func():
		AudioSynth.play_click()
		CareerState.sim_current_match()
	)
	play_hb.add_child(sim_btn)

	# Weekly Dilemma Card (PEKAN INI)
	var dilemma_done := int(CareerState.career["careerMeta"].get("dilemmaDoneWeek", 0)) == week
	var dil_btn := Button.new()
	if dilemma_done:
		dil_btn.text = "✓ EVENT PEKAN INI SELESAI"
		dil_btn.disabled = true
	else:
		dil_btn.text = "★ EVENT PEKAN INI: KETUK UNTUK SELESAIKAN DILEMA"
		UITheme.style_btn(dil_btn, UITheme.ACCENT_PURPLE, Color("#A78BFA"), 12)
	dil_btn.custom_minimum_size = Vector2(0, 40)
	dil_btn.pressed.connect(func(): AudioSynth.play_click(); open_dilemma_requested.emit())
	right_col.add_child(dil_btn)

	# Next 3 Upcoming Fixtures strip
	right_col.add_child(UITheme.make_section_header("JADWAL BERIKUTNYA"))
	var sched: Array = CareerState.career["schedule"]
	for w_off in range(1, 4):
		var idx := (week - 1) + w_off
		if idx < sched.size():
			var fx: Dictionary = sched[idx]
			var row := PanelContainer.new()
			right_col.add_child(row)
			var rhb := HBoxContainer.new()
			row.add_child(rhb)
			var l1 := Label.new()
			l1.text = "MGG %d • %s vs %s" % [int(fx["week"]), fx["comp"], fx["opp_name"]]
			l1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			l1.clip_text = true
			l1.add_theme_font_size_override("font_size", 11)
			var l2 := Label.new()
			l2.text = "KANDANG" if fx["is_home"] else "TANDANG"
			l2.add_theme_color_override("font_color", UITheme.ACCENT_CYAN)
			l2.add_theme_font_size_override("font_size", 11)
			rhb.add_child(l1)
			rhb.add_child(l2)
