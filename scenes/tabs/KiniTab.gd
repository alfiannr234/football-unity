extends Control

const PixelJerseyIconScript := preload("res://scripts/ui/PixelJerseyIcon.gd")

signal start_match_requested
signal sim_match_requested
signal open_dilemma_requested
signal open_squad_requested
signal open_lineup_requested
signal open_schedule_requested
signal end_season_requested

var _stage_host: Control
var _left_outfield_avs: Array[PixelAvatar] = []
var _right_outfield_avs: Array[PixelAvatar] = []
var _mini_left_av: PixelAvatar
var _mini_right_av: PixelAvatar
var _mini_left_bg: ColorRect
var _mini_right_bg: ColorRect
var _left_kit_panels: Array[PanelContainer] = []
var _right_kit_panels: Array[PanelContainer] = []
var _left_club: Dictionary = {}
var _right_club: Dictionary = {}
var _left_kits: Array[Dictionary] = []
var _right_kits: Array[Dictionary] = []

func _ready() -> void:
	theme = UITheme.build_theme()
	_stage_host = Control.new()
	_stage_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_stage_host)
	CareerState.career_updated.connect(refresh)
	resized.connect(_on_resized)
	refresh()

func _on_resized() -> void:
	if is_inside_tree() and CareerState.has_active_career:
		refresh()

func refresh() -> void:
	if not is_inside_tree() or not CareerState.has_active_career:
		return
	for c in _stage_host.get_children():
		c.queue_free()
	_left_outfield_avs.clear()
	_right_outfield_avs.clear()
	_left_kit_panels.clear()
	_right_kit_panels.clear()
	_mini_left_av = null
	_mini_right_av = null

	var w: float = size.x if size.x > 100.0 else 960.0
	var h: float = size.y if size.y > 100.0 else 442.0
	var half_y: float = h * 0.745

	var my_club: Dictionary = CareerState.get_current_club()
	var fix: Dictionary = CareerState.get_current_fixture()
	var season_pending: bool = bool(CareerState.career.get("careerMeta", {}).get("seasonPendingEnd", false))
	var comp: String = str(fix.get("comp", "LIGA"))
	var is_elite: bool = comp in ["PIALA_ELITE", "PIALA_EUROPA", "PIALA_CONF", "PIALA_DUNIA_KLUB"]
	var is_national: bool = comp in ["TIMNAS", "TURNAMEN_ASIA"]

	var opp_id: int = clampi(int(fix.get("opp_club_id", 0)), 0, maxi(0, GameData.clubs.size() - 1))
	var opp_club: Dictionary = GameData.clubs[opp_id] if opp_id < GameData.clubs.size() else my_club
	var user_is_home: bool = bool(fix.get("is_home", true))

	_left_club = my_club if user_is_home else opp_club
	_right_club = opp_club if user_is_home else my_club
	_left_kits = CareerState.get_club_kits(_left_club)
	_right_kits = CareerState.get_club_kits(_right_club)

	var left_kit_idx: int = CareerState.get_selected_match_kit_idx(true, _left_club, _right_club)
	var right_kit_idx: int = CareerState.get_selected_match_kit_idx(false, _left_club, _right_club)
	var left_kit: Dictionary = _left_kits[left_kit_idx]
	var right_kit: Dictionary = _right_kits[right_kit_idx]

	# 1. FULL-BLEED STADIUM PITCH BACKDROP (Elite Night-Blue vs League Lush Grass)
	var backdrop := StadiumStageBackdrop.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.configure(is_elite, comp, int(my_club.get("division", 3)), half_y)
	_stage_host.add_child(backdrop)

	# 2. BUILD ORDERED STARTING-XI TUNNEL SQUADS (11 Home Left + 11 Away Right)
	var my_sq: Dictionary = CareerState.career.get("clubSquad", {})
	if my_sq.is_empty() or my_sq.get("starters", []).is_empty():
		var prof: Dictionary = CareerState.career.get("playerProfile", {})
		my_sq = CareerState._build_club_squad(int(my_club["id"]), str(prof.get("name", "PEMAIN")), str(prof.get("position", "ST")), prof.get("appearance", {}))
	var opp_sq: Dictionary = _build_ai_squad(opp_club)

	var left_starters: Array = _order_tunnel_xi((my_sq if user_is_home else opp_sq).get("starters", []))
	var right_starters: Array = _order_tunnel_xi((opp_sq if user_is_home else my_sq).get("starters", []))

	# Draw Tunnel Players BACK-TO-FRONT (index 10 down to 0) so front stars overlap cleanly
	var cx: float = w * 0.5
	for i in range(10, -1, -1):
		var t: float = float(i) / 10.0
		var p_curve: float = pow(t, 0.86)
		var ph: float = lerpf(h * 0.315, h * 0.132, p_curve)
		var pw: float = ph * (32.0 / 48.0)
		var foot_y: float = lerpf(half_y + 2.0, h * 0.295, p_curve)
		var lx: float = lerpf(cx - w * 0.088, cx - w * 0.174, p_curve)
		var rx: float = lerpf(cx + w * 0.088, cx + w * 0.174, p_curve)

		if i < left_starters.size():
			var pl_l: Dictionary = left_starters[i]
			var av_l := _spawn_tunnel_avatar(pl_l, _left_club, left_kit, true, i == 0)
			av_l.position = Vector2(lx - pw * 0.5, foot_y - ph)
			av_l.size = Vector2(pw, ph)
			_stage_host.add_child(av_l)
			if str(pl_l.get("pos", "")).to_upper() != "GK":
				_left_outfield_avs.append(av_l)

		if i < right_starters.size():
			var pl_r: Dictionary = right_starters[i]
			var av_r := _spawn_tunnel_avatar(pl_r, _right_club, right_kit, false, i == 0)
			av_r.position = Vector2(rx - pw * 0.5, foot_y - ph)
			av_r.size = Vector2(pw, ph)
			_stage_host.add_child(av_r)
			if str(pl_r.get("pos", "")).to_upper() != "GK":
				_right_outfield_avs.append(av_r)

	# 3. CENTER TROPHY ON PEDESTAL + MATCH BALL
	var trophy := MatchCenterTrophy.new()
	var tr_w: float = 104.0
	var tr_h: float = h * 0.43
	trophy.position = Vector2(cx - tr_w * 0.5, half_y - tr_h + 14.0)
	trophy.size = Vector2(tr_w, tr_h)
	trophy.configure(is_elite, comp, int(my_club.get("nation_id", 0)))
	_stage_host.add_child(trophy)

	# 4. GIANT LEFT & RIGHT CLUB CRESTS + OVR + NAME + RANK + 5-FORM BOXES
	var crest_col_w: float = clampf(w * 0.25, 210.0, 250.0)
	var left_is_flag := is_national and (not user_is_home)
	var right_is_flag := is_national and user_is_home
	var left_panel := _make_crest_column(_left_club, left_is_flag, user_is_home, fix, crest_col_w)
	left_panel.position = Vector2(w * 0.035, h * 0.075)
	left_panel.size = Vector2(crest_col_w, half_y - h * 0.05)
	_stage_host.add_child(left_panel)

	var right_panel := _make_crest_column(_right_club, right_is_flag, not user_is_home, fix, crest_col_w)
	right_panel.position = Vector2(w - w * 0.035 - crest_col_w, h * 0.075)
	right_panel.size = Vector2(crest_col_w, half_y - h * 0.05)
	_stage_host.add_child(right_panel)

	# Season-end badge overlay if waiting for player to hold TAHAN AKHIRI
	if season_pending:
		var fin_p := PanelContainer.new()
		fin_p.add_theme_stylebox_override("panel", UITheme.make_box(Color("#1A1305E6"), UITheme.ACCENT_GOLD, 2, 6))
		var fin_l := Label.new()
		fin_l.text = "MUSIM SELESAI • TAHAN TOMBOL AKHIRI DI KIRI ATAS"
		fin_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fin_l.add_theme_font_override("font", UITheme.get_display_font())
		fin_l.add_theme_font_size_override("font_size", 11)
		fin_l.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
		fin_p.add_child(fin_l)
		fin_p.position = Vector2(cx - 210.0, h * 0.095)
		fin_p.size = Vector2(420.0, 28.0)
		_stage_host.add_child(fin_p)

	# 5. BOTTOM CONTROLS: 3 LEFT JERSEYS | MINI LINE-UP PREVIEW | 3 RIGHT JERSEYS
	var ctrl_y: float = half_y + 12.0
	var kit_row_l := _make_kit_picker_row(_left_kits, left_kit_idx, true)
	kit_row_l.position = Vector2(cx - 252.0, ctrl_y)
	kit_row_l.size = Vector2(162.0, 48.0)
	_stage_host.add_child(kit_row_l)

	var lineup_card := _make_lineup_preview_button(
		left_starters[0] if not left_starters.is_empty() else {},
		right_starters[0] if not right_starters.is_empty() else {},
		left_kit, right_kit
	)
	lineup_card.position = Vector2(cx - 68.0, ctrl_y - 2.0)
	lineup_card.size = Vector2(136.0, 52.0)
	_stage_host.add_child(lineup_card)

	var kit_row_r := _make_kit_picker_row(_right_kits, right_kit_idx, false)
	kit_row_r.position = Vector2(cx + 90.0, ctrl_y)
	kit_row_r.size = Vector2(162.0, 48.0)
	_stage_host.add_child(kit_row_r)

	# 6. SLIM CENTERED M / S / K PROBABILITY BAR
	var diff: int = int(_left_club.get("ovr", 60)) - int(_right_club.get("ovr", 60)) + 2
	var left_win: int = clampi(38 + diff * 3, 12, 74)
	var draw_pct: int = 24
	var right_win: int = maxi(8, 100 - left_win - draw_pct)
	var odds_hb := HBoxContainer.new()
	odds_hb.add_theme_constant_override("separation", 2)
	odds_hb.position = Vector2(cx - 170.0, minf(h - 24.0, ctrl_y + 56.0))
	odds_hb.size = Vector2(340.0, 18.0)
	_stage_host.add_child(odds_hb)

	var l_tag := "M %d%%" % left_win if user_is_home else "K %d%%" % left_win
	var r_tag := "K %d%%" % right_win if user_is_home else "M %d%%" % right_win
	var l_col := Color("#2563EB") if user_is_home else Color("#DC4A4A")
	var r_col := Color("#DC4A4A") if user_is_home else Color("#2563EB")
	for pr in [[l_tag, left_win, l_col], ["S %d%%" % draw_pct, draw_pct, Color("#E2E8F0")], [r_tag, right_win, r_col]]:
		var pb := PanelContainer.new()
		pb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pb.size_flags_stretch_ratio = float(pr[1])
		pb.add_theme_stylebox_override("panel", UITheme.make_box(pr[2], Color.TRANSPARENT, 0, 1))
		var pl := Label.new()
		pl.text = str(pr[0])
		pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		pl.add_theme_color_override("font_color", Color("#0F172A") if pr[2] == Color("#E2E8F0") else Color.WHITE)
		pl.add_theme_font_size_override("font_size", 10)
		pb.add_child(pl)
		odds_hb.add_child(pb)

func _build_ai_squad(club: Dictionary) -> Dictionary:
	var cid: int = int(club.get("id", 1))
	var ln: String = GameData.LAST_NAMES[(cid * 11 + 10) % GameData.LAST_NAMES.size()]
	var sq: Dictionary = CareerState._build_club_squad(cid, ln, "ST", {"shirt_num": 10})
	var base_ovr: int = int(club.get("ovr", 60))
	for pl in sq.get("starters", []):
		pl["is_user"] = false
		if str(pl.get("id", "")) == "sq_10":
			pl["ovr"] = clampi(base_ovr + 1, 46, 92)
			pl["seed"] = cid * 100 + 10
	return sq

func _order_tunnel_xi(starters: Array) -> Array:
	if starters.is_empty():
		return []
	var front: Dictionary = {}
	var gk: Dictionary = {}
	var rest: Array = []
	for s in starters:
		var pd: Dictionary = s
		if bool(pd.get("is_user", false)) and front.is_empty():
			front = pd
		elif str(pd.get("pos", "")).to_upper() == "GK" and gk.is_empty():
			gk = pd
		else:
			rest.append(pd)
	if front.is_empty() and not rest.is_empty():
		front = rest.pop_back()
	var out: Array = []
	if not front.is_empty():
		out.append(front)
	if not gk.is_empty():
		out.append(gk)
	for r in rest:
		out.append(r)
	return out

func _spawn_tunnel_avatar(p: Dictionary, club: Dictionary, kit: Dictionary, is_left_side: bool, is_front: bool) -> PixelAvatar:
	var av := PixelAvatar.new()
	av.full_body = true
	av.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var is_user := bool(p.get("is_user", false))
	var is_gk := str(p.get("pos", "")).to_upper() == "GK"
	if is_user:
		av.configure_from_career()
		av.casual_style = 0
		av.apply_kit(kit)
	else:
		av.configure_from_seed(int(p.get("seed", 7)), club, int(p.get("number", 9)))
		if is_gk:
			var gk_kit := {
				"primary": Color("#D93B88") if is_left_side else Color("#14A89E"),
				"secondary": Color("#111827"),
				"shorts": Color("#111827"),
				"pattern": "chest_band",
			}
			av.apply_kit(gk_kit)
			av.long_sleeve = true
			av.glove_color = Color("#F8FAFC")
		else:
			av.apply_kit(kit)
	av.show_shorts_number = is_front
	if is_front:
		av.anim_mode = "IDLE"
		av.anim_phase = 0.0 if is_left_side else 1.4
	return av

func _make_crest_column(club: Dictionary, as_flag: bool, is_user_side: bool, fix: Dictionary, col_w: float) -> Control:
	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 4)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var emblem_wrap := Control.new()
	var esz: float = minf(152.0, col_w * 0.68)
	emblem_wrap.custom_minimum_size = Vector2(esz + 18.0, esz + 4.0)
	emblem_wrap.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	emblem_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(emblem_wrap)

	if as_flag:
		var fl := UITheme.make_flag_rect(int(fix.get("opp_nat_id", 0)), Vector2(esz, esz * 0.68))
		fl.position = Vector2(9.0, esz * 0.16)
		emblem_wrap.add_child(fl)
	else:
		var cr := ClubCrest.new()
		cr.position = Vector2(9.0, 2.0)
		cr.size = Vector2(esz, esz)
		cr.set_club(int(club.get("id", 0)))
		emblem_wrap.add_child(cr)

	# Overlapping OVR box at bottom-right of crest (matching Gambar 2 & 3)
	var ovr_val: int = int(club.get("ovr", 60)) if is_user_side else int(fix.get("opp_ovr", club.get("ovr", 60)))
	var ovr_b := UITheme.make_ovr_badge(ovr_val, "default", Vector2(44, 28))
	ovr_b.position = Vector2(esz - 30.0, esz - 28.0)
	ovr_b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	emblem_wrap.add_child(ovr_b)

	var nm := Label.new()
	nm.text = str(fix.get("opp_name", club.get("name", "KLUB"))).to_upper() if as_flag else str(club.get("name", "KLUB")).to_upper()
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.clip_text = true
	nm.add_theme_font_override("font", UITheme.get_display_font())
	nm.add_theme_font_size_override("font_size", 13)
	nm.add_theme_color_override("font_color", Color.WHITE)
	nm.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	nm.add_theme_constant_override("shadow_offset_x", 1)
	nm.add_theme_constant_override("shadow_offset_y", 2)
	vb.add_child(nm)

	# Rank chip + User star chip (like "ke-14" & "+HANSSON" in Gambar 3)
	var meta_hb := HBoxContainer.new()
	meta_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	meta_hb.add_theme_constant_override("separation", 5)
	vb.add_child(meta_hb)
	if not as_flag:
		var rank_num: int = CareerState.get_user_league_position() if is_user_side else CareerState.get_club_league_position(int(club.get("id", 0)))
		var rk_p := PanelContainer.new()
		rk_p.add_theme_stylebox_override("panel", UITheme.make_box(Color("#122036E0"), UITheme.ACCENT_GOLD, 1, 2))
		var rk_l := Label.new()
		rk_l.text = "ke-%d" % rank_num
		rk_l.add_theme_font_size_override("font_size", 10)
		rk_l.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
		rk_p.add_child(rk_l)
		meta_hb.add_child(rk_p)
	if is_user_side:
		var u_p := PanelContainer.new()
		u_p.add_theme_stylebox_override("panel", UITheme.make_box(Color("#0F243AE0"), UITheme.ACCENT_CYAN, 1, 2))
		var u_l := Label.new()
		u_l.text = "★ %s" % str(CareerState.career["playerProfile"].get("name", "KAMU")).to_upper()
		u_l.add_theme_font_size_override("font_size", 10)
		u_l.add_theme_color_override("font_color", Color.WHITE)
		u_p.add_child(u_l)
		meta_hb.add_child(u_p)

	# 5-match form strip
	var form_hb := HBoxContainer.new()
	form_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	form_hb.add_theme_constant_override("separation", 3)
	vb.add_child(form_hb)
	var form_arr: Array = _recent_form(5) if is_user_side else _ai_form(int(club.get("id", 0)))
	while form_arr.size() < 5:
		form_arr.push_front("-")
	for letter in form_arr:
		var lp := PanelContainer.new()
		lp.custom_minimum_size = Vector2(20, 18)
		var lc := Color("#2F9E57") if letter == "M" else (Color("#D4A738") if letter == "S" else (Color("#C93A3A") if letter == "K" else Color("#1B2A40")))
		lp.add_theme_stylebox_override("panel", UITheme.make_box(lc, Color("#0F172A"), 1, 2))
		var ll := Label.new()
		ll.text = str(letter)
		ll.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ll.add_theme_font_size_override("font_size", 10)
		ll.add_theme_color_override("font_color", Color("#0F172A") if letter == "S" else (Color("#64748B") if letter == "-" else Color.WHITE))
		lp.add_child(ll)
		form_hb.add_child(lp)
	return vb

func _make_kit_picker_row(kits: Array[Dictionary], active_idx: int, is_left_side: bool) -> HBoxContainer:
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 6)
	for k_i in range(mini(3, kits.size())):
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(48, 46)
		var sel := (k_i == active_idx)
		card.add_theme_stylebox_override("panel", _kit_box_style(sel))

		var icon: Control = PixelJerseyIconScript.new()
		icon.custom_minimum_size = Vector2(36, 34)
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.call("configure_kit", kits[k_i])
		card.add_child(icon)

		var hit := Button.new()
		hit.flat = true
		hit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var idx_cap := k_i
		var side_cap := is_left_side
		hit.pressed.connect(func():
			AudioSynth.play_click()
			_select_kit(side_cap, idx_cap)
		)
		card.add_child(hit)
		hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		hb.add_child(card)
		if is_left_side:
			_left_kit_panels.append(card)
		else:
			_right_kit_panels.append(card)
	return hb

func _kit_box_style(selected: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.10, 0.18, 0.85) if selected else Color(0.05, 0.10, 0.18, 0.35)
	sb.border_color = Color("#F8FAFC") if selected else Color(1.0, 1.0, 1.0, 0.22)
	sb.set_border_width_all(2 if selected else 1)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 2
	sb.content_margin_right = 2
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	return sb

func _select_kit(is_left_side: bool, kit_idx: int) -> void:
	CareerState.set_selected_match_kit(is_left_side, kit_idx)
	var kits := _left_kits if is_left_side else _right_kits
	if kit_idx < 0 or kit_idx >= kits.size():
		return
	var chosen: Dictionary = kits[kit_idx]
	var panels := _left_kit_panels if is_left_side else _right_kit_panels
	for i in range(panels.size()):
		panels[i].add_theme_stylebox_override("panel", _kit_box_style(i == kit_idx))
	var avs := _left_outfield_avs if is_left_side else _right_outfield_avs
	for av in avs:
		if is_instance_valid(av):
			av.apply_kit(chosen)
	if is_left_side:
		if _mini_left_av != null and is_instance_valid(_mini_left_av):
			_mini_left_av.apply_kit(chosen)
		if _mini_left_bg != null and is_instance_valid(_mini_left_bg):
			_mini_left_bg.color = chosen.get("primary", Color("#C82832"))
	else:
		if _mini_right_av != null and is_instance_valid(_mini_right_av):
			_mini_right_av.apply_kit(chosen)
		if _mini_right_bg != null and is_instance_valid(_mini_right_bg):
			_mini_right_bg.color = chosen.get("primary", Color("#1D5CA8"))

func _make_lineup_preview_button(left_p: Dictionary, right_p: Dictionary, left_kit: Dictionary, right_kit: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UITheme.make_box(Color("#0A1526"), Color("#94A3B8"), 2, 4))

	var vb := VBoxContainer.new()
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_theme_constant_override("separation", 0)
	panel.add_child(vb)

	var top := Control.new()
	top.size_flags_vertical = Control.SIZE_EXPAND_FILL
	top.custom_minimum_size = Vector2(0, 30)
	top.clip_contents = true
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(top)

	_mini_left_bg = ColorRect.new()
	_mini_left_bg.color = left_kit.get("primary", Color("#C82832"))
	_mini_left_bg.anchor_right = 0.5
	_mini_left_bg.anchor_bottom = 1.0
	_mini_left_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(_mini_left_bg)

	_mini_right_bg = ColorRect.new()
	_mini_right_bg.color = right_kit.get("primary", Color("#1D5CA8"))
	_mini_right_bg.anchor_left = 0.5
	_mini_right_bg.anchor_right = 1.0
	_mini_right_bg.anchor_bottom = 1.0
	_mini_right_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(_mini_right_bg)

	_mini_left_av = PixelAvatar.new()
	_mini_left_av.full_body = false
	_mini_left_av.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if bool(left_p.get("is_user", false)):
		_mini_left_av.configure_from_career()
	else:
		_mini_left_av.configure_from_seed(int(left_p.get("seed", 1)), _left_club, int(left_p.get("number", 9)))
	_mini_left_av.apply_kit(left_kit)
	_mini_left_av.position = Vector2(6, 0)
	_mini_left_av.size = Vector2(36, 32)
	top.add_child(_mini_left_av)

	_mini_right_av = PixelAvatar.new()
	_mini_right_av.full_body = false
	_mini_right_av.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if bool(right_p.get("is_user", false)):
		_mini_right_av.configure_from_career()
	else:
		_mini_right_av.configure_from_seed(int(right_p.get("seed", 2)), _right_club, int(right_p.get("number", 10)))
	_mini_right_av.apply_kit(right_kit)
	_mini_right_av.position = Vector2(90, 0)
	_mini_right_av.size = Vector2(36, 32)
	top.add_child(_mini_right_av)

	var vs_badge := PanelContainer.new()
	vs_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vs_badge.add_theme_stylebox_override("panel", UITheme.make_box(Color("#0A1320"), Color.WHITE, 1, 8))
	vs_badge.position = Vector2(54, 6)
	vs_badge.size = Vector2(24, 18)
	var vsl := Label.new()
	vsl.text = "VS"
	vsl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vsl.add_theme_font_size_override("font_size", 8)
	vsl.add_theme_color_override("font_color", Color.WHITE)
	vs_badge.add_child(vsl)
	top.add_child(vs_badge)

	var bot := ColorRect.new()
	bot.color = Color("#0D1B2E")
	bot.custom_minimum_size = Vector2(0, 18)
	bot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(bot)

	var bl := Label.new()
	bl.text = "LINE-UP"
	bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bl.add_theme_font_override("font", UITheme.get_display_font())
	bl.add_theme_font_size_override("font_size", 10)
	bl.add_theme_color_override("font_color", Color.WHITE)
	bot.add_child(bl)
	bl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var hit := Button.new()
	hit.flat = true
	hit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	hit.pressed.connect(func(): AudioSynth.play_click(); open_lineup_requested.emit())
	panel.add_child(hit)
	hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return panel

func _recent_form(count: int) -> Array:
	var out: Array = []
	var sched: Array = CareerState.career.get("schedule", [])
	for i in range(sched.size() - 1, -1, -1):
		var fx: Dictionary = sched[i]
		if not bool(fx.get("played", false)):
			continue
		var us: int = int(fx.get("score_us", 0))
		var them: int = int(fx.get("score_them", 0))
		out.append("M" if us > them else ("S" if us == them else "K"))
		if out.size() >= count:
			break
	out.reverse()
	return out

func _ai_form(cid: int) -> Array:
	var pool := ["M", "S", "K", "M", "M"]
	var out: Array = []
	for i in range(5):
		out.append(pool[(cid + i * 2) % pool.size()])
	return out

# =============================================================================
# CUSTOM PROCEDURAL STADIUM BACKDROP (ELITE BLUE NIGHT vs LEAGUE GREEN GRASS)
# =============================================================================
class StadiumStageBackdrop extends Control:
	var _is_elite: bool = false
	var _comp: String = "LIGA"
	var _div: int = 3
	var _half_y: float = 328.0

	func configure(is_elite: bool, comp: String, div_num: int, half_y: float) -> void:
		_is_elite = is_elite
		_comp = comp
		_div = div_num
		_half_y = half_y
		queue_redraw()

	func _draw() -> void:
		var w := size.x
		var h := size.y
		if w <= 10.0 or h <= 10.0:
			return
		var stands_h := h * 0.085
		var board_h := h * 0.042
		var pitch_top := stands_h + board_h

		if _is_elite:
			# Night-blue elite stands & LED perimeter boards (Gambar 2)
			draw_rect(Rect2(0, 0, w, stands_h), Color("#0A1A36"))
			for i in range(36):
				var sx := float(i) * (w / 36.0)
				draw_rect(Rect2(sx + 4, 4, 6, 4), Color(0.28, 0.55, 0.92, 0.25))
				draw_rect(Rect2(sx + 10, 14, 5, 4), Color(0.85, 0.92, 1.0, 0.16))
			# Illuminated UEFA-style blue LED ad boards
			draw_rect(Rect2(0, stands_h, w, board_h), Color("#154596"))
			var seg_w := w / 8.0
			for s in range(8):
				if s % 2 == 0:
					draw_rect(Rect2(float(s) * seg_w, stands_h, seg_w, board_h), Color("#1E63C6"))
				draw_rect(Rect2(float(s) * seg_w, stands_h, 2, board_h), Color("#7DD3FC", 0.45))
			draw_rect(Rect2(0, pitch_top - 2, w, 2), Color("#93C5FD", 0.55))

			# Night-blue/teal striped elite stadium pitch
			var g1 := Color("#163D55")
			var g2 := Color("#1B4962")
			var stripes := 10
			var sh := (h - pitch_top) / float(stripes)
			for i in range(stripes):
				draw_rect(Rect2(0, pitch_top + float(i) * sh, w, sh + 1.0), g1 if i % 2 == 0 else g2)
			# Subtle blue pitch floodlight vignette at bottom
			draw_rect(Rect2(0, _half_y, w, h - _half_y), Color(0.04, 0.14, 0.22, 0.30))
		else:
			# Daylight/dusk natural league stands & colorful boards (Gambar 3)
			draw_rect(Rect2(0, 0, w, stands_h), Color("#2B3447"))
			for i in range(44):
				var sx := float(i) * (w / 44.0)
				var cc := Color("#B93838", 0.45) if i % 3 == 0 else (Color("#3B82F6", 0.42) if i % 3 == 1 else Color("#CBD5E1", 0.30))
				draw_rect(Rect2(sx + 3, 6, 5, 4), cc)
				draw_rect(Rect2(sx + 8, 16, 4, 4), cc)
			# Classic league pitchside ad boards
			draw_rect(Rect2(0, stands_h, w, board_h), Color("#1E3A63"))
			var seg_w := w / 6.0
			for s in range(6):
				var bc := Color("#A6343A") if s % 3 == 0 else (Color("#1D4E89") if s % 3 == 1 else Color("#E2E8F0"))
				draw_rect(Rect2(float(s) * seg_w, stands_h, seg_w - 2.0, board_h), bc)
			draw_rect(Rect2(0, pitch_top - 2, w, 2), Color("#0F172A", 0.65))

			# Lush green horizontal mowed grass bands
			var g1 := Color("#2C5D3E")
			var g2 := Color("#346C49")
			var stripes := 10
			var sh := (h - pitch_top) / float(stripes)
			for i in range(stripes):
				draw_rect(Rect2(0, pitch_top + float(i) * sh, w, sh + 1.0), g1 if i % 2 == 0 else g2)
			draw_rect(Rect2(0, _half_y, w, h - _half_y), Color(0.05, 0.16, 0.10, 0.26))

		# Distant goal posts & crisp white net at top center
		var gx1 := w * 0.425
		var gx2 := w * 0.575
		var gy_bot := pitch_top + 4.0
		var gy_top := maxf(2.0, stands_h - 14.0)
		draw_rect(Rect2(gx1, gy_top, gx2 - gx1, gy_bot - gy_top), Color(1, 1, 1, 0.10))
		for nx in range(int(gx1), int(gx2), 9):
			draw_line(Vector2(float(nx), gy_top), Vector2(float(nx), gy_bot), Color(1, 1, 1, 0.22), 1.0)
		for ny in range(int(gy_top), int(gy_bot), 6):
			draw_line(Vector2(gx1, float(ny)), Vector2(gx2, float(ny)), Color(1, 1, 1, 0.20), 1.0)
		draw_line(Vector2(gx1, gy_bot), Vector2(gx1, gy_top), Color("#F8FAFC"), 2.5)
		draw_line(Vector2(gx2, gy_bot), Vector2(gx2, gy_top), Color("#F8FAFC"), 2.5)
		draw_line(Vector2(gx1, gy_top), Vector2(gx2, gy_top), Color("#F8FAFC"), 2.5)

		# Crisp perspective pitch markings
		var line_c := Color(0.85, 0.94, 1.0, 0.55) if _is_elite else Color(0.95, 0.98, 0.95, 0.58)
		# Upper goal line & perspective penalty box
		draw_line(Vector2(0, pitch_top + 4), Vector2(w, pitch_top + 4), line_c, 2.0)
		draw_line(Vector2(w * 0.28, pitch_top + 4), Vector2(w * 0.22, pitch_top + h * 0.15), line_c, 2.0)
		draw_line(Vector2(w * 0.72, pitch_top + 4), Vector2(w * 0.78, pitch_top + h * 0.15), line_c, 2.0)
		draw_line(Vector2(w * 0.22, pitch_top + h * 0.15), Vector2(w * 0.78, pitch_top + h * 0.15), line_c, 2.0)
		# Perspective outer touchlines
		draw_line(Vector2(w * 0.08, pitch_top + 4), Vector2(-w * 0.04, h), line_c, 2.0)
		draw_line(Vector2(w * 0.92, pitch_top + 4), Vector2(w * 1.04, h), line_c, 2.0)

		# Sweeping center circle ellipse in perspective around halfway line
		var rx := w * 0.31
		var ry := h * 0.25
		var cpts := PackedVector2Array()
		for k in range(49):
			var ang := float(k) * TAU / 48.0
			var py := _half_y + sin(ang) * ry
			if py <= _half_y + 2.0:
				cpts.append(Vector2(w * 0.5 + cos(ang) * rx, py))
		if cpts.size() >= 2:
			draw_polyline(cpts, line_c, 2.2)

		# Main foreground halfway line
		draw_line(Vector2(0, _half_y), Vector2(w, _half_y), Color(1, 1, 1, 0.72), 3.0)

# =============================================================================
# CENTER TROPHY PEDESTAL (ELITE SILVER CUP vs GOLD LEAGUE CUP + NATION FLAG)
# =============================================================================
class MatchCenterTrophy extends Control:
	var _is_elite: bool = false
	var _comp: String = "LIGA"
	var _nat_id: int = 0

	func configure(is_elite: bool, comp: String, nat_id: int) -> void:
		_is_elite = is_elite
		_comp = comp
		_nat_id = nat_id
		queue_redraw()

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var cx := w * 0.5
		var base_y := h - 14.0

		# Ground shadow + dark tapered trapezoid plinth
		draw_circle(Vector2(cx, base_y + 2.0), 22.0, Color(0, 0, 0, 0.34))
		var plinth := PackedVector2Array([
			Vector2(cx - 17, base_y - 68), Vector2(cx + 17, base_y - 68),
			Vector2(cx + 22, base_y), Vector2(cx - 22, base_y)
		])
		draw_colored_polygon(plinth, Color("#142138"))
		var plinth_hi := PackedVector2Array([
			Vector2(cx - 15, base_y - 68), Vector2(cx - 5, base_y - 68),
			Vector2(cx - 6, base_y), Vector2(cx - 19, base_y)
		])
		draw_colored_polygon(plinth_hi, Color("#24395C"))
		draw_line(Vector2(cx - 18, base_y - 68), Vector2(cx + 18, base_y - 68), Color("#475569"), 2.0)

		var cup_y := base_y - 70.0
		if _is_elite:
			# Sculpted Silver Winged European Elite Cup (Gambar 2)
			var sil := Color("#D8E2EE")
			var sil_hi := Color("#FFFFFF")
			var sil_dk := Color("#7A8FA8")
			# Base stem
			draw_rect(Rect2(cx - 12, cup_y - 8, 24, 8), sil_dk)
			draw_rect(Rect2(cx - 6, cup_y - 20, 12, 12), sil)
			# Tapered chalice body
			var chalice := PackedVector2Array([
				Vector2(cx - 19, cup_y - 62), Vector2(cx + 19, cup_y - 62),
				Vector2(cx + 11, cup_y - 20), Vector2(cx - 11, cup_y - 20)
			])
			draw_colored_polygon(chalice, sil)
			draw_colored_polygon(PackedVector2Array([
				Vector2(cx - 14, cup_y - 60), Vector2(cx - 5, cup_y - 60),
				Vector2(cx - 3, cup_y - 22), Vector2(cx - 9, cup_y - 22)
			]), sil_hi)
			draw_colored_polygon(PackedVector2Array([
				Vector2(cx + 7, cup_y - 60), Vector2(cx + 16, cup_y - 60),
				Vector2(cx + 9, cup_y - 22), Vector2(cx + 4, cup_y - 22)
			]), sil_dk)
			# Iconic big curved handles
			draw_polyline(PackedVector2Array([
				Vector2(cx - 18, cup_y - 55), Vector2(cx - 32, cup_y - 44),
				Vector2(cx - 26, cup_y - 28), Vector2(cx - 11, cup_y - 24)
			]), sil, 4.5)
			draw_polyline(PackedVector2Array([
				Vector2(cx + 18, cup_y - 55), Vector2(cx + 32, cup_y - 44),
				Vector2(cx + 26, cup_y - 28), Vector2(cx + 11, cup_y - 24)
			]), sil, 4.5)
		else:
			# Ornate Gold League Cup with Nation Flag Medallion (Gambar 3)
			var gld := Color("#E8B429")
			var gld_hi := Color("#FEF08A")
			var gld_dk := Color("#9E6A12")
			draw_rect(Rect2(cx - 11, cup_y - 8, 22, 8), gld_dk)
			draw_rect(Rect2(cx - 5, cup_y - 16, 10, 8), gld)
			# Handles
			draw_arc(Vector2(cx - 22, cup_y - 36), 9.0, PI * 0.45, PI * 1.55, 12, gld, 4.0)
			draw_arc(Vector2(cx + 22, cup_y - 36), 9.0, -PI * 0.55, PI * 0.55, 12, gld, 4.0)
			# Round gold medallion cup
			draw_circle(Vector2(cx, cup_y - 36), 22.0, gld_dk)
			draw_circle(Vector2(cx, cup_y - 36), 19.5, gld)
			draw_arc(Vector2(cx, cup_y - 36), 19.0, -PI * 0.85, -PI * 0.15, 14, gld_hi, 3.0)
			# Inner navy disc + mini nation flag emblem (matching Gambar 3)
			draw_circle(Vector2(cx, cup_y - 36), 12.5, Color("#122640"))
			var n_dict: Dictionary = GameData.nations[clampi(_nat_id, 0, maxi(0, GameData.nations.size() - 1))] if not GameData.nations.is_empty() else {}
			var cols: Array = n_dict.get("colors", [Color("#DC2626"), Color("#FFFFFF")])
			var f1: Color = cols[0] if cols.size() > 0 else Color("#DC2626")
			var f2: Color = cols[1] if cols.size() > 1 else Color("#FFFFFF")
			draw_rect(Rect2(cx - 9, cup_y - 42, 18, 12), f1)
			if _nat_id == 0:
				draw_rect(Rect2(cx - 4, cup_y - 42, 3, 12), f2)
				draw_rect(Rect2(cx - 9, cup_y - 37.5, 18, 3), f2)
			else:
				draw_rect(Rect2(cx - 9, cup_y - 36, 18, 6), f2)
			draw_rect(Rect2(cx - 9, cup_y - 42, 18, 12), gld, false, 1.5)

		# Pixel Football resting right in front of the plinth on halfway line
		var bx := cx
		var by := base_y + 3.0
		draw_circle(Vector2(bx, by + 3.0), 10.0, Color(0, 0, 0, 0.35))
		draw_circle(Vector2(bx, by), 10.5, Color("#0F172A"))
		draw_circle(Vector2(bx, by), 9.0, Color("#F8FAFC"))
		var p_col := Color("#1E3A8A") if _is_elite else Color("#1E293B")
		draw_rect(Rect2(bx - 2.5, by - 2.5, 5.0, 5.0), p_col)
		draw_rect(Rect2(bx - 7.5, by - 4.0, 3.0, 3.0), p_col)
		draw_rect(Rect2(bx + 4.5, by - 4.0, 3.0, 3.0), p_col)
		draw_rect(Rect2(bx - 5.0, by + 4.0, 3.5, 2.5), p_col)
		draw_rect(Rect2(bx + 2.0, by + 4.0, 3.5, 2.5), p_col)
