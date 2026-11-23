extends Control

const SquadPlayerCardScript := preload("res://scripts/ui/SquadPlayerCard.gd")

signal inspect_player_requested(player_dict: Dictionary, club_dict: Dictionary)

var _subtab: String = "SKUAD"  # SKUAD or MANAJEMEN
var _scope: String = "KLUB"     # KLUB or TIMNAS
var _show_ovr: bool = false
var _body: Control

func _ready() -> void:
	theme = UITheme.build_theme()
	_body = Control.new()
	_body.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_body)
	CareerState.career_updated.connect(refresh)
	refresh()

func refresh() -> void:
	if not is_inside_tree() or not CareerState.has_active_career:
		return
	for c in _body.get_children():
		c.queue_free()

	if _subtab == "SKUAD":
		_render_squad()
	else:
		_render_management()

func _compute_squad_roles(starters: Array) -> Dictionary:
	var cap_id := ""
	var best_bm_id := ""
	var best_bm_val := -1
	var best_pen_id := ""
	var best_pen_val := -1
	var u_traits: Array = CareerState.career.get("careerMeta", {}).get("unlockedCoachTraits", [])
	var user_sp_ok := u_traits.has("KORNER_PENALTI")
	var u_attrs: Dictionary = CareerState.career["playerProfile"].get("attributes", {})

	for s in starters:
		var pd: Dictionary = s
		var pid := str(pd.get("id", ""))
		var is_u := bool(pd.get("is_user", false))
		if bool(pd.get("is_captain", false)) and cap_id.is_empty():
			cap_id = pid
		if str(pd.get("pos", "")).to_upper() == "GK":
			continue
		var bm := int(u_attrs.get("bolaMati", 60)) if is_u else int(pd.get("attrs", {}).get("bolaMati", pd.get("ovr", 58)))
		var pn := int(u_attrs.get("penalti", 60)) if is_u else int(pd.get("attrs", {}).get("penalti", pd.get("ovr", 58)))
		if is_u and user_sp_ok:
			bm += 20
			pn += 20
		if bm > best_bm_val:
			best_bm_val = bm
			best_bm_id = pid
		if pn > best_pen_val:
			best_pen_val = pn
			best_pen_id = pid

	if cap_id.is_empty() and starters.size() > 8:
		cap_id = str(starters[8].get("id", ""))

	# Teammates who are friends with the user (scales with ruangGanti relation)
	var rg := int(CareerState.career["playerProfile"].get("relations", {}).get("ruangGanti", 55))
	var friend_quota := 0 if rg < 35 else (1 if rg < 55 else (2 if rg < 70 else (3 if rg < 85 else 4)))
	var friend_ids: Array[String] = []
	for s in starters:
		if friend_ids.size() >= friend_quota:
			break
		var pd: Dictionary = s
		var pid := str(pd.get("id", ""))
		if bool(pd.get("is_user", false)):
			continue
		if pid != cap_id or friend_quota >= 3:
			friend_ids.append(pid)

	var wk := int(CareerState.career["careerMeta"].get("week", 1))
	var pen_goals_map: Dictionary = {}
	for s in starters:
		var pd: Dictionary = s
		var pid := str(pd.get("id", ""))
		if bool(pd.get("is_user", false)):
			pen_goals_map[pid] = int(CareerState.career.get("stats", {}).get("penaltiesScored", 0))
		else:
			pen_goals_map[pid] = int(pd.get("pen_goals", clampi(1 + int(wk / 5) + (abs(int(pd.get("seed", 1))) % 3), 1, 14)))

	return {
		"captain_id": cap_id,
		"corner_id": best_bm_id,
		"penalty_id": best_pen_id,
		"friend_ids": friend_ids,
		"pen_goals": pen_goals_map,
	}

func _render_squad() -> void:
	var club := CareerState.get_current_club()
	var squad: Dictionary = CareerState.career["clubSquad"]
	var starters: Array = squad["starters"]
	var bench: Array = squad["bench"]
	var roles := _compute_squad_roles(starters)

	# 3-Column Landscape Hub matching Gambar 2 (Left Sidebar | Center Pitch | Right Bench + Manager)
	var split_hb := HBoxContainer.new()
	split_hb.set_anchors_preset(Control.PRESET_FULL_RECT)
	split_hb.add_theme_constant_override("separation", 10)
	_body.add_child(split_hb)

	# =========================================================================
	# COLUMN 1: LEFT SIDEBAR (KLUB/TIMNAS, TIM INTI, POSISI/OVR, MANAJEMEN, KAPTEN)
	# =========================================================================
	var left_col := VBoxContainer.new()
	left_col.custom_minimum_size = Vector2(188, 0)
	left_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_col.add_theme_constant_override("separation", 7)
	split_hb.add_child(left_col)

	# KLUB | TIMNAS toggle
	var sc_hb := HBoxContainer.new()
	sc_hb.add_theme_constant_override("separation", 4)
	left_col.add_child(sc_hb)
	for s in ["KLUB", "TIMNAS"]:
		var b := Button.new()
		b.text = str(s)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 30)
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var cap_s: String = str(s)
		var act: bool = (_scope == cap_s)
		UITheme.style_btn(b, Color("#121D30") if act else Color("#091322"), Color("#E11D48") if act else Color("#243A56"), 11)
		b.pressed.connect(func(): AudioSynth.play_click(); _scope = cap_s; refresh())
		sc_hb.add_child(b)

	# TIM INTI + formation pill
	var ti_panel := PanelContainer.new()
	ti_panel.add_theme_stylebox_override("panel", UITheme.make_box(Color("#0D1C34"), Color("#1E3A5F"), 1, 5))
	left_col.add_child(ti_panel)
	var ti_hb := HBoxContainer.new()
	ti_panel.add_child(ti_hb)
	var ti_l := Label.new()
	ti_l.text = "● TIM INTI"
	ti_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ti_l.add_theme_font_override("font", UITheme.get_display_font())
	ti_l.add_theme_font_size_override("font_size", 11)
	ti_l.add_theme_color_override("font_color", Color.WHITE)
	ti_hb.add_child(ti_l)
	var fm_p := PanelContainer.new()
	fm_p.add_theme_stylebox_override("panel", UITheme.make_box(Color("#0A1324"), Color("#38BDF8"), 1, 3))
	var fm_l := Label.new()
	fm_l.text = str(squad.get("formation", "5-3-2"))
	fm_l.add_theme_font_size_override("font_size", 10)
	fm_l.add_theme_color_override("font_color", UITheme.ACCENT_CYAN)
	fm_p.add_child(fm_l)
	ti_hb.add_child(fm_p)

	# POSISI | OVR toggle
	var mode_hb := HBoxContainer.new()
	mode_hb.add_theme_constant_override("separation", 4)
	left_col.add_child(mode_hb)
	for m in [["POSISI", false], ["OVR", true]]:
		var mb := Button.new()
		mb.text = str(m[0])
		mb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mb.custom_minimum_size = Vector2(0, 30)
		mb.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var cap_m: bool = bool(m[1])
		var act: bool = (_show_ovr == cap_m)
		UITheme.style_btn(mb, Color("#121D30") if act else Color("#091322"), Color("#E11D48") if act else Color("#243A56"), 11)
		mb.pressed.connect(func(): AudioSynth.play_click(); _show_ovr = cap_m; refresh())
		mode_hb.add_child(mb)

	# MANAJEMEN shortcut button
	var man_btn := Button.new()
	man_btn.text = "☰  MANAJEMEN"
	man_btn.custom_minimum_size = Vector2(0, 34)
	man_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	UITheme.style_btn(man_btn, Color("#3B4D66"), Color("#94A3B8"), 11)
	man_btn.pressed.connect(func(): AudioSynth.play_click(); _subtab = "MANAJEMEN"; refresh())
	left_col.add_child(man_btn)

	# KAPTEN Spotlight Card at Bottom-Left (exact match to Gambar 2!)
	var cap_dict: Dictionary = starters[0] if not starters.is_empty() else {}
	for s in starters:
		if str(s.get("id", "")) == str(roles["captain_id"]):
			cap_dict = s
			break
	var cap_card := PanelContainer.new()
	cap_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cap_card.add_theme_stylebox_override("panel", UITheme.make_box(Color("#091426"), Color("#1E3350"), 1, 6))
	left_col.add_child(cap_card)
	var cvb := VBoxContainer.new()
	cvb.alignment = BoxContainer.ALIGNMENT_CENTER
	cvb.add_theme_constant_override("separation", 5)
	cap_card.add_child(cvb)

	var c_badge := CaptainCircleIcon.new()
	c_badge.custom_minimum_size = Vector2(30, 30)
	c_badge.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cvb.add_child(c_badge)

	var c_sub := Label.new()
	c_sub.text = "KAPTEN"
	c_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c_sub.add_theme_font_size_override("font_size", 10)
	c_sub.add_theme_color_override("font_color", Color("#94A3B8"))
	cvb.add_child(c_sub)

	var c_nm := Label.new()
	c_nm.text = str(cap_dict.get("name", "KAPTEN")).to_upper()
	c_nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c_nm.add_theme_font_override("font", UITheme.get_display_font())
	c_nm.add_theme_font_size_override("font_size", 15)
	c_nm.add_theme_color_override("font_color", Color.WHITE)
	cvb.add_child(c_nm)

	var c_meta := HBoxContainer.new()
	c_meta.alignment = BoxContainer.ALIGNMENT_CENTER
	c_meta.add_theme_constant_override("separation", 6)
	cvb.add_child(c_meta)
	var cap_ovr := int(cap_dict.get("ovr", 60))
	var cap_hex := MiniOvrHex.new()
	cap_hex.custom_minimum_size = Vector2(22, 22)
	cap_hex.configure(cap_ovr)
	c_meta.add_child(cap_hex)
	var c_pos := PanelContainer.new()
	c_pos.add_theme_stylebox_override("panel", UITheme.make_box(Color("#1A1828"), Color("#E11D48"), 1, 2))
	var c_pos_l := Label.new()
	c_pos_l.text = str(cap_dict.get("pos", "CM"))
	c_pos_l.add_theme_font_size_override("font_size", 9)
	c_pos_l.add_theme_color_override("font_color", Color("#FDA4AF"))
	c_pos.add_child(c_pos_l)
	c_meta.add_child(c_pos)

	var req_lvl := clampi(int(CareerState.career["contract"].get("clubRequestsLevel", 1)), 1, 4)
	var lvl_big := Label.new()
	lvl_big.text = "%d/4" % req_lvl
	lvl_big.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lvl_big.add_theme_font_override("font", UITheme.get_display_font())
	lvl_big.add_theme_font_size_override("font_size", 24)
	lvl_big.add_theme_color_override("font_color", Color.WHITE)
	cvb.add_child(lvl_big)

	var lvl_sub := Label.new()
	lvl_sub.text = "LEVEL"
	lvl_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lvl_sub.add_theme_font_size_override("font_size", 10)
	lvl_sub.add_theme_color_override("font_color", Color("#94A3B8"))
	cvb.add_child(lvl_sub)

	if _scope == "TIMNAS" and int(CareerState.career["playerProfile"]["ovr"]) < 68:
		var lock_p := PanelContainer.new()
		lock_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lock_p.size_flags_vertical = Control.SIZE_EXPAND_FILL
		lock_p.add_theme_stylebox_override("panel", UITheme.make_box(Color("#0A1628"), UITheme.BORDER_CYAN, 1, 6))
		split_hb.add_child(lock_p)
		var l := Label.new()
		l.text = "PANGGILAN TIMNAS (%s)\nTerbuka setelah OVR mencapai 68+ dan performa konsisten!" % GameData.nations[int(CareerState.career["playerProfile"]["nationId"])]["name"].to_upper()
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.add_theme_font_override("font", UITheme.get_display_font())
		l.add_theme_font_size_override("font_size", 14)
		lock_p.add_child(l)
		return

	# =========================================================================
	# COLUMN 2: CENTER MARKED GREEN PITCH WITH 11 COLLECTIBLE STARTER CARDS
	# =========================================================================
	var pitch_wrap := TacticalPitchCanvas.new()
	pitch_wrap.custom_minimum_size = Vector2(368, 0)
	pitch_wrap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split_hb.add_child(pitch_wrap)

	var pvb := VBoxContainer.new()
	pvb.set_anchors_preset(Control.PRESET_FULL_RECT)
	pvb.offset_left = 6
	pvb.offset_right = -6
	pvb.offset_top = 6
	pvb.offset_bottom = -6
	pvb.alignment = BoxContainer.ALIGNMENT_CENTER
	pvb.add_theme_constant_override("separation", 6)
	pitch_wrap.add_child(pvb)

	var rows := [
		[10, 9],
		[6, 7, 8],
		[1, 2, 3, 4, 5],
		[0],
	]
	for r_indices in rows:
		var rhb := HBoxContainer.new()
		rhb.alignment = BoxContainer.ALIGNMENT_CENTER
		rhb.add_theme_constant_override("separation", 5)
		pvb.add_child(rhb)
		for idx in r_indices:
			if idx < starters.size():
				rhb.add_child(_spawn_player_card(starters[idx], club, roles, Vector2(66, 94)))

	# =========================================================================
	# COLUMN 3: RIGHT BENCH GRID + TAK DIPANGGIL + MANAGER PERCAYA BAR
	# =========================================================================
	var right_col := VBoxContainer.new()
	right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_col.add_theme_constant_override("separation", 8)
	split_hb.add_child(right_col)

	var bn_hdr := HBoxContainer.new()
	right_col.add_child(bn_hdr)
	var bn_lbl := Label.new()
	bn_lbl.text = "▸ BANGKU CADANGAN"
	bn_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bn_lbl.add_theme_font_override("font", UITheme.get_display_font())
	bn_lbl.add_theme_font_size_override("font_size", 13)
	bn_lbl.add_theme_color_override("font_color", Color.WHITE)
	bn_hdr.add_child(bn_lbl)
	var club_ovr_hex := MiniOvrHex.new()
	club_ovr_hex.custom_minimum_size = Vector2(26, 26)
	club_ovr_hex.configure(int(club.get("ovr", 60)))
	bn_hdr.add_child(club_ovr_hex)

	var b_grid := GridContainer.new()
	b_grid.columns = 4
	b_grid.add_theme_constant_override("h_separation", 8)
	b_grid.add_theme_constant_override("v_separation", 8)
	right_col.add_child(b_grid)
	for bp in bench:
		b_grid.add_child(_spawn_player_card(bp, club, roles, Vector2(78, 100)))

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_col.add_child(spacer)

	# TAK DIPANGGIL Strip (matching Gambar 2)
	var res_panel := PanelContainer.new()
	res_panel.add_theme_stylebox_override("panel", UITheme.make_box(Color("#091426"), Color("#1E3350"), 1, 5))
	right_col.add_child(res_panel)
	var res_hb := HBoxContainer.new()
	res_panel.add_child(res_hb)
	var res_l := Label.new()
	res_l.text = "● TAK DIPANGGIL"
	res_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	res_l.add_theme_font_override("font", UITheme.get_display_font())
	res_l.add_theme_font_size_override("font_size", 11)
	res_l.add_theme_color_override("font_color", Color("#CBD5E1"))
	res_hb.add_child(res_l)
	var res_cnt := Label.new()
	var eng_now := int(CareerState.career["playerProfile"].get("energy", 80))
	res_cnt.text = "KAMU ABSEN (<30 ENERGI)" if eng_now < 30 else "0 PEMAIN"
	res_cnt.add_theme_font_size_override("font_size", 10)
	res_cnt.add_theme_color_override("font_color", UITheme.ACCENT_RED if eng_now < 30 else UITheme.TEXT_MUTED)
	res_hb.add_child(res_cnt)

	# MANAGER TRUST BAR (PERCAYA, matching bottom-right of Gambar 2!)
	var mgr_panel := PanelContainer.new()
	mgr_panel.add_theme_stylebox_override("panel", UITheme.make_box(Color("#091426"), Color("#1E3350"), 1, 5))
	right_col.add_child(mgr_panel)
	var mgr_vb := VBoxContainer.new()
	mgr_vb.add_theme_constant_override("separation", 4)
	mgr_panel.add_child(mgr_vb)
	var coach_names := ["Diego Salazar", "Erik Lindqvist", "Bambang Santoso", "Marco Rossi", "Carlos Mendez", "Hendra Wijaya"]
	var coach_nm: String = coach_names[int(club.get("id", 0)) % coach_names.size()]
	var m_top := Label.new()
	m_top.text = "● PELATIH: %s" % coach_nm.to_upper()
	m_top.add_theme_font_override("font", UITheme.get_display_font())
	m_top.add_theme_font_size_override("font_size", 12)
	m_top.add_theme_color_override("font_color", Color.WHITE)
	mgr_vb.add_child(m_top)

	var trust_hb := HBoxContainer.new()
	trust_hb.add_theme_constant_override("separation", 8)
	mgr_vb.add_child(trust_hb)
	var tr_l := Label.new()
	tr_l.text = "PERCAYA"
	tr_l.add_theme_font_size_override("font_size", 10)
	tr_l.add_theme_color_override("font_color", Color("#94A3B8"))
	trust_hb.add_child(tr_l)
	var trust_val := int(CareerState.career["playerProfile"].get("relations", {}).get("pelatih", 60))
	var pb_bg := PanelContainer.new()
	pb_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pb_bg.custom_minimum_size = Vector2(0, 12)
	pb_bg.add_theme_stylebox_override("panel", UITheme.make_box(Color("#13233A"), Color("#334F73"), 1, 2))
	trust_hb.add_child(pb_bg)
	var pb_fill := ColorRect.new()
	pb_fill.color = Color("#5CC8F2") if trust_val >= 45 else UITheme.ACCENT_RED
	pb_fill.anchor_right = clampf(float(trust_val) / 100.0, 0.0, 1.0)
	pb_fill.anchor_bottom = 1.0
	pb_bg.add_child(pb_fill)
	var tr_num := Label.new()
	tr_num.text = "%d%%" % trust_val
	tr_num.add_theme_font_size_override("font_size", 10)
	tr_num.add_theme_color_override("font_color", Color("#5CC8F2"))
	trust_hb.add_child(tr_num)

func _spawn_player_card(pd: Dictionary, club: Dictionary, roles: Dictionary, card_sz: Vector2) -> Control:
	var pid := str(pd.get("id", ""))
	var card: Control = SquadPlayerCardScript.new()
	card.custom_minimum_size = card_sz
	var friend_ids: Array = roles.get("friend_ids", [])
	var pen_map: Dictionary = roles.get("pen_goals", {})
	card.call("configure", pd, club, {
		"ovr_focus": _show_ovr,
		"is_friend": friend_ids.has(pid),
		"is_captain": pid == str(roles.get("captain_id", "")),
		"is_corner": pid == str(roles.get("corner_id", "")),
		"is_penalty": pid == str(roles.get("penalty_id", "")),
		"pen_goals": int(pen_map.get(pid, 0)),
	})
	card.connect("card_clicked", func(p: Dictionary): inspect_player_requested.emit(p, club))
	return card

func _render_management() -> void:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_body.add_child(scroll)

	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 8)
	scroll.add_child(vb)

	var top_hb := HBoxContainer.new()
	vb.add_child(top_hb)
	var back_b := Button.new()
	back_b.text = "<- KEMBALI KE SKUAD"
	back_b.custom_minimum_size = Vector2(180, 34)
	back_b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	UITheme.style_btn(back_b, Color("#122640"), UITheme.ACCENT_CYAN, 11)
	back_b.pressed.connect(func(): AudioSynth.play_click(); _subtab = "SKUAD"; refresh())
	top_hb.add_child(back_b)

	var office := PanelContainer.new()
	office.custom_minimum_size = Vector2(0, 145)
	vb.add_child(office)
	var bg := TextureRect.new()
	bg.texture = load("res://assets/sprites/backgrounds/manager_office.png")
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	office.add_child(bg)
	var npc := TextureRect.new()
	var at := AtlasTexture.new()
	at.atlas = load("res://assets/sprites/characters/npcs_sheet.png")
	at.region = Rect2(2 * 24, 0, 24, 36)
	npc.texture = at
	npc.custom_minimum_size = Vector2(84, 110)
	npc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	office.add_child(npc)

	var lvl := int(CareerState.career["contract"].get("clubRequestsLevel", 1))
	var pts := int(CareerState.career["contract"].get("clubPoints", 33))
	vb.add_child(UITheme.make_section_header("LEVELMU DI KLUB • LEVEL %d (POIN %d)" % [lvl, pts]))

	var pb := ProgressBar.new()
	pb.max_value = 200
	pb.value = pts
	pb.custom_minimum_size = Vector2(0, 14)
	vb.add_child(pb)

	var reqs := [
		["LIHAT DAFTAR", 1, "Lihat daftar pemain incaran klub"],
		["USUL TRANSFER", 2, "Rekomendasikan pemain untuk dibeli"],
		["BELI & JUAL", 3, "Beri masukan posisi yang butuh penguatan"],
		["JANGAN JUAL", 3, "Minta klub mempertahankan rekan favorit"],
		["PERPANJANG DIA", 3, "Dorong kontrak baru untuk pemain kunci"],
		["NOMOR BARU", 3, "Ajukan ganti nomor punggungmu"],
		["NEGO ULANG", 3, "Minta kenaikan gaji lebih awal"],
		["KAPTEN", 4, "Ajukan diri menjadi Kapten tim"],
		["PELATIH BARU", 5, "Berikan masukan evaluasi pelatih"],
		["KONTRAKMU", 5, "Perpanjangan kontrak istimewa"],
		["BONUS LOYALITAS", 6, "Bonus loyalitas khusus legenda klub"],
		["FANS SETIA", 6, "Koreo & acara apresiasi suporter"],
		["LEBIH LUANG", 6, "Atur beban rotasi laga"],
	]
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	vb.add_child(grid)

	for r in reqs:
		var unlocked := lvl >= int(r[1])
		var rb := Button.new()
		rb.text = "%s\n[LV %d]" % [r[0], int(r[1])]
		rb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rb.custom_minimum_size = Vector2(0, 52)
		rb.disabled = not unlocked
		UITheme.style_btn(rb, Color("#1B365C") if unlocked else Color("#0D1522"), UITheme.BORDER_CYAN if unlocked else UITheme.BORDER_STEEL, 10)
		rb.pressed.connect(func():
			AudioSynth.play_click()
			if r[0] == "NOMOR BARU":
				var cur_n := int(CareerState.career["playerProfile"]["appearance"].get("shirt_num", 9))
				CareerState.career["playerProfile"]["appearance"]["shirt_num"] = 10 if cur_n != 10 else 7
				CareerState.recalculate_ovr()
				CareerState.save_active_career()
				refresh()
			elif r[0] == "KAPTEN":
				CareerState.career["playerProfile"]["relations"]["pelatih"] = mini(100, int(CareerState.career["playerProfile"]["relations"]["pelatih"]) + 3)
				CareerState.save_active_career()
				refresh()
		)
		grid.add_child(rb)

class TacticalPitchCanvas extends Control:
	func _draw() -> void:
		var w := size.x
		var h := size.y
		if w <= 10.0 or h <= 10.0:
			return
		# Striped stadium grass pitch (matching Gambar 2)
		var g1 := Color("#237836")
		var g2 := Color("#2A873F")
		var bands := 8
		var bh := h / float(bands)
		for i in range(bands):
			draw_rect(Rect2(0, float(i) * bh, w, bh + 1.0), g1 if i % 2 == 0 else g2)
		var lc := Color(0.88, 0.96, 0.90, 0.65)
		var m := 6.0
		draw_rect(Rect2(m, m, w - m * 2.0, h - m * 2.0), lc, false, 2.0)
		# Center circle arc at top + penalty box & 6-yard box at bottom
		draw_arc(Vector2(w * 0.5, m), w * 0.16, 0.0, PI, 24, lc, 2.0)
		draw_rect(Rect2(w * 0.24, h - m - h * 0.20, w * 0.52, h * 0.20), lc, false, 2.0)
		draw_rect(Rect2(w * 0.36, h - m - h * 0.09, w * 0.28, h * 0.09), lc, false, 1.8)
		draw_arc(Vector2(w * 0.5, h - m - h * 0.20), w * 0.10, PI, TAU, 20, lc, 1.8)

class CaptainCircleIcon extends Control:
	func _draw() -> void:
		var c := size * 0.5
		var r := minf(c.x, c.y) - 1.0
		draw_circle(c, r, Color("#94A3B8"))
		draw_circle(c, r - 2.0, Color("#475569"))
		draw_string(UITheme.get_display_font(), Vector2(c.x - r, c.y + 5.0), "C", HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, 14, Color("#0F172A"))

class MiniOvrHex extends Control:
	var _ovr: int = 60
	var _tier: Dictionary = {}

	func configure(ovr: int) -> void:
		_ovr = ovr
		_tier = SquadPlayerCardScript.get_ovr_tier(ovr)
		queue_redraw()

	func _draw() -> void:
		if _tier.is_empty():
			return
		var c := size * 0.5
		var r := minf(c.x, c.y) - 1.0
		var pts := PackedVector2Array()
		for k in range(6):
			var ang := -PI * 0.5 + float(k) * PI / 3.0
			pts.append(c + Vector2(cos(ang), sin(ang)) * r)
		draw_colored_polygon(pts, _tier["hex_fill"])
		draw_polyline(pts + PackedVector2Array([pts[0]]), _tier["hex_rim"], 1.8)
		draw_string(UITheme.get_display_font(), Vector2(c.x - r, c.y + 3.5), str(_ovr), HORIZONTAL_ALIGNMENT_CENTER, r * 2.0, 9, _tier["hex_txt"])
