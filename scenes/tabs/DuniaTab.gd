extends Control

signal transfer_flow_requested(offer: Dictionary)

const CompOverlaysScript := preload("res://scripts/ui/CompOverlays.gd")
const TimnasOverlaysScript := preload("res://scripts/ui/TimnasOverlays.gd")
const RankingOverlaysScript := preload("res://scripts/ui/RankingOverlays.gd")
const MarketSponsorOverlaysScript := preload("res://scripts/ui/MarketSponsorOverlays.gd")

var _subtab: String = "KOMP."
var _comp_mode: String = "LIGA"
var _comp_nat_idx: int = 0
var _comp_div: int = 3
var _comp_initialized: bool = false
var _timnas_peek_group: bool = false
var _rank_tab: String = "PEMAIN"
var _rank_page: int = 0
var _rank_selected_nat_id: int = -1
var _rank_filters: Dictionary = {
	"positions": [],
	"age": "SEMUA",
	"val": "SEMUA",
	"nat_id": -1,
	"league_nat_id": -1,
	"division": 0,
	"club_mode": "SEMUA",
	"query": "",
}
var _rank_filtered_cache: PackedInt32Array = PackedInt32Array()
var _rank_cache_dirty: bool = true
var _xfer_filters: Dictionary = {
	"league_mode": "MINE",
	"nat_id": -1,
	"positions": [],
	"sort": "TERBARU",
}
var _news_channel: String = "KLUB"

var _top_tab_bar: HBoxContainer
var _comp_root: VBoxContainer
var _scroll: ScrollContainer
var _body: VBoxContainer

func _ready() -> void:
	theme = UITheme.build_theme()
	var outer := VBoxContainer.new()
	outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("separation", 6)
	add_child(outer)

	_top_tab_bar = HBoxContainer.new()
	_top_tab_bar.add_theme_constant_override("separation", 5)
	outer.add_child(_top_tab_bar)

	# Non-scrolling crisp container for KOMP. dashboard (matches Gambar 2)
	_comp_root = VBoxContainer.new()
	_comp_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_comp_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_comp_root.add_theme_constant_override("separation", 7)
	outer.add_child(_comp_root)

	# Scrollable container for BUKA / TRANSFER / RANKING
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(_scroll)

	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 8)
	_scroll.add_child(_body)

	CareerState.career_updated.connect(refresh)
	refresh()

func set_subtab(st: String) -> void:
	if st == "JADWAL":
		_subtab = "KOMP."
	else:
		_subtab = st
	refresh()

func _rebuild_top_tabs() -> void:
	for c in _top_tab_bar.get_children():
		_top_tab_bar.remove_child(c)
		c.queue_free()

	var tabs := [
		["KOMP.", Color("#C62834"), Color("#F87171")],
		["TIMNAS", Color("#C62834"), Color("#F87171")],
		["BUKA", Color("#176B45"), Color("#34D399")],
		["TRANSFER", Color("#1A4F8A"), Color("#38BDF8")],
		["RANKING", Color("#1D5CC6"), Color("#93C5FD")],
	]
	for tdef in tabs:
		var st: String = str(tdef[0])
		var act_bg: Color = tdef[1]
		var act_bd: Color = tdef[2]
		var is_act: bool = (_subtab == st)
		var b := Button.new()
		b.text = st
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 34)
		var n := StyleBoxFlat.new()
		n.bg_color = act_bg if is_act else Color("#0C1728")
		n.border_color = act_bd if is_act else Color("#1D314E")
		n.set_border_width_all(1)
		n.border_width_bottom = 3 if is_act else 1
		n.set_corner_radius_all(4)
		var h := n.duplicate()
		h.bg_color = n.bg_color.lightened(0.12)
		h.border_color = UITheme.BORDER_CYAN
		var pr := n.duplicate()
		pr.bg_color = n.bg_color.darkened(0.10)
		b.add_theme_stylebox_override("normal", n)
		b.add_theme_stylebox_override("hover", h)
		b.add_theme_stylebox_override("pressed", pr)
		b.add_theme_stylebox_override("focus", h)
		b.add_theme_font_override("font", UITheme.get_display_font())
		b.add_theme_font_size_override("font_size", 11)
		b.add_theme_color_override("font_color", UITheme.TEXT_WHITE if is_act else Color("#9FB3C8"))
		b.pressed.connect(func():
			AudioSynth.play_click()
			_subtab = st
			refresh()
		)
		_top_tab_bar.add_child(b)

func refresh() -> void:
	if not is_inside_tree() or not CareerState.has_active_career:
		return
	_rebuild_top_tabs()

	for c in _comp_root.get_children():
		_comp_root.remove_child(c)
		c.queue_free()
	for c in _body.get_children():
		_body.remove_child(c)
		c.queue_free()

	var is_fixed_dash: bool = (_subtab == "KOMP." or _subtab == "TIMNAS" or _subtab == "BUKA" or _subtab == "TRANSFER" or _subtab == "RANKING")
	_comp_root.visible = is_fixed_dash
	_scroll.visible = not is_fixed_dash

	match _subtab:
		"KOMP.": _render_comp()
		"TIMNAS": _render_timnas()
		"BUKA": _render_buka()
		"TRANSFER": _render_transfer_feed()
		"RANKING": _render_ranking()
		"BERITA": _render_berita()

# ==============================================================================
# KOMP. DASHBOARD (Gambar 2 -> Overlays Gambar 3, 4, 5, 6, 7)
# ==============================================================================
func _render_comp() -> void:
	var user_club: Dictionary = CareerState.get_current_club()
	if not _comp_initialized:
		_comp_initialized = true
		_comp_nat_idx = clampi(int(user_club.get("nation_id", 0)), 0, GameData.nations.size() - 1)
		_comp_div = clampi(int(user_club.get("division", 3)), 1, 3)

	var nat_dict: Dictionary = GameData.nations[clampi(_comp_nat_idx, 0, GameData.nations.size() - 1)]
	var nat_name: String = str(nat_dict.get("name", "LIGA")).to_upper()

	# Row 1: Sub-competition pill bar + Right League/Nation Filter Button
	var sub_bar := HBoxContainer.new()
	sub_bar.add_theme_constant_override("separation", 5)
	_comp_root.add_child(sub_bar)

	var comp_pills := [
		["LIGA", "flag"],
		["ELITE", "elite"],
		["EUROPA", "europa"],
		["CONF.", "challenge"],
		["PIALA", "podium"],
		["KLUB", "club"],
	]
	for pdef in comp_pills:
		var ck: String = str(pdef[0])
		var ik: String = str(pdef[1])
		var is_act: bool = (_comp_mode == ck)
		var pb := Button.new()
		pb.custom_minimum_size = Vector2(78 if ck != "EUROPA" else 86, 30)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color("#13223A") if is_act else Color("#0A1322")
		sb.border_color = Color("#F5C430") if is_act else Color("#1B2D47")
		sb.set_border_width_all(1)
		sb.border_width_bottom = 2 if is_act else 1
		sb.set_corner_radius_all(4)
		var sbh := sb.duplicate()
		sbh.bg_color = sb.bg_color.lightened(0.14)
		sbh.border_color = UITheme.BORDER_CYAN
		pb.add_theme_stylebox_override("normal", sb)
		pb.add_theme_stylebox_override("hover", sbh)
		pb.add_theme_stylebox_override("pressed", sbh)
		pb.add_theme_stylebox_override("focus", sbh)

		var phb := HBoxContainer.new()
		phb.set_anchors_preset(Control.PRESET_FULL_RECT)
		phb.offset_left = 6
		phb.offset_right = -6
		phb.alignment = BoxContainer.ALIGNMENT_CENTER
		phb.add_theme_constant_override("separation", 5)
		phb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pb.add_child(phb)

		var iw := CenterContainer.new()
		iw.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if ik == "flag":
			iw.add_child(UITheme.make_flag_rect(_comp_nat_idx, Vector2(18, 12)))
		else:
			iw.add_child(CompOverlaysScript.make_icon(ik, UITheme.TEXT_WHITE if is_act else Color("#94A3B8"), Vector2(12, 12)))
		phb.add_child(iw)

		var pl := Label.new()
		pl.text = ck
		pl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		pl.add_theme_font_override("font", UITheme.get_display_font())
		pl.add_theme_font_size_override("font_size", 10)
		pl.add_theme_color_override("font_color", UITheme.TEXT_WHITE if is_act else Color("#8CA0B8"))
		pl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		phb.add_child(pl)

		pb.pressed.connect(func():
			AudioSynth.play_click()
			_comp_mode = ck
			refresh()
		)
		sub_bar.add_child(pb)

	var sub_sp := Control.new()
	sub_sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sub_bar.add_child(sub_sp)

	# Top-right clickable League Selector Button (opens NEGARA Overlay - Gambar 3!)
	var league_btn := Button.new()
	league_btn.custom_minimum_size = Vector2(232, 30)
	var lsb := StyleBoxFlat.new()
	lsb.bg_color = Color("#0A1322")
	lsb.border_color = Color("#2A3E5E")
	lsb.set_border_width_all(1)
	lsb.set_corner_radius_all(4)
	var lsbh := lsb.duplicate()
	lsbh.bg_color = Color("#13233C")
	lsbh.border_color = UITheme.ACCENT_CYAN
	league_btn.add_theme_stylebox_override("normal", lsb)
	league_btn.add_theme_stylebox_override("hover", lsbh)
	league_btn.add_theme_stylebox_override("pressed", lsbh)
	league_btn.add_theme_stylebox_override("focus", lsbh)

	var lhb := HBoxContainer.new()
	lhb.set_anchors_preset(Control.PRESET_FULL_RECT)
	lhb.offset_left = 10
	lhb.offset_right = -10
	lhb.alignment = BoxContainer.ALIGNMENT_CENTER
	lhb.add_theme_constant_override("separation", 8)
	lhb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	league_btn.add_child(lhb)

	var lf_c := CenterContainer.new()
	lf_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lf_c.add_child(UITheme.make_flag_rect(_comp_nat_idx, Vector2(20, 14)))
	lhb.add_child(lf_c)

	var l_txt := Label.new()
	l_txt.text = "LIGA %s  •  KE-%d" % [nat_name, _comp_div]
	l_txt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l_txt.clip_text = true
	l_txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l_txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l_txt.add_theme_font_override("font", UITheme.get_display_font())
	l_txt.add_theme_font_size_override("font_size", 10)
	l_txt.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	l_txt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lhb.add_child(l_txt)

	league_btn.pressed.connect(func():
		AudioSynth.play_click()
		open_nation_filter_overlay()
	)
	sub_bar.add_child(league_btn)

	# Row 2: Main 2-Column Content
	var cols := HBoxContainer.new()
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_theme_constant_override("separation", 10)
	_comp_root.add_child(cols)

	var table_rows: Array[Dictionary] = []
	if _comp_mode == "LIGA":
		table_rows = CareerState.get_live_division_table(_comp_nat_idx, _comp_div)
	else:
		table_rows = CareerState.get_continental_table(_comp_mode, _comp_nat_idx)

	# LEFT COLUMN: Compact Highlighted Standings Card
	var left_card := PanelContainer.new()
	left_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_card.size_flags_stretch_ratio = 1.72
	var lc_sb := StyleBoxFlat.new()
	lc_sb.bg_color = Color("#091220")
	lc_sb.border_color = Color("#1B2D47")
	lc_sb.set_border_width_all(1)
	lc_sb.set_corner_radius_all(6)
	lc_sb.content_margin_left = 10
	lc_sb.content_margin_right = 12
	lc_sb.content_margin_top = 8
	lc_sb.content_margin_bottom = 8
	left_card.add_theme_stylebox_override("panel", lc_sb)
	cols.add_child(left_card)

	var lc_vb := VBoxContainer.new()
	lc_vb.add_theme_constant_override("separation", 3)
	left_card.add_child(lc_vb)

	# Standings Header Row
	var hdr := HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 6)
	lc_vb.add_child(hdr)
	var h_pad := Control.new()
	h_pad.custom_minimum_size = Vector2(44, 14)
	hdr.add_child(h_pad)
	var h_tim := Label.new()
	h_tim.text = "TIM" if _comp_mode == "LIGA" else "%s • KLASEMEN" % _comp_mode
	h_tim.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h_tim.add_theme_font_size_override("font_size", 10)
	h_tim.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	hdr.add_child(h_tim)
	var h_q := Control.new()
	h_q.custom_minimum_size = Vector2(36, 14)
	hdr.add_child(h_q)
	for cdef in [["MN", 28], ["M", 26], ["S", 26], ["K", 26], ["PTS", 34]]:
		var hl := Label.new()
		hl.text = str(cdef[0])
		hl.custom_minimum_size = Vector2(int(cdef[1]), 14)
		hl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hl.add_theme_font_size_override("font_size", 10)
		hl.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
		hdr.add_child(hl)

	var my_cid: int = int(user_club.get("id", -1))
	var preview_indices: Array[int] = _select_preview_indices(table_rows, my_cid)
	var prev_idx: int = -1
	var total_n: int = table_rows.size()

	for idx in preview_indices:
		if prev_idx >= 0 and idx > prev_idx + 1:
			var gap := Control.new()
			gap.custom_minimum_size = Vector2(0, 6)
			lc_vb.add_child(gap)
		prev_idx = idx

		var r: Dictionary = table_rows[idx]
		var rk: int = idx + 1
		var cid: int = int(r["club_id"])
		var is_mine: bool = (cid == my_cid)
		var zone: String = ""
		if _comp_mode == "LIGA":
			zone = CareerState.get_zone_for_rank(_comp_nat_idx, _comp_div, rk, total_n)
		else:
			zone = "ELITE" if rk <= 4 else ("EUROPA" if rk <= 8 else "")

		var row_p := PanelContainer.new()
		row_p.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var rsb := StyleBoxFlat.new()
		rsb.bg_color = Color("#3A1523") if is_mine else Color(0, 0, 0, 0)
		rsb.border_color = Color("#7A2842") if is_mine else Color(0, 0, 0, 0)
		rsb.set_border_width_all(1 if is_mine else 0)
		rsb.set_corner_radius_all(3)
		rsb.content_margin_left = 0
		rsb.content_margin_right = 4
		rsb.content_margin_top = 1
		rsb.content_margin_bottom = 1
		row_p.add_theme_stylebox_override("panel", rsb)
		lc_vb.add_child(row_p)

		var rhb := HBoxContainer.new()
		rhb.add_theme_constant_override("separation", 6)
		row_p.add_child(rhb)

		# Left vertical zone bar (3px)
		var bar := ColorRect.new()
		bar.custom_minimum_size = Vector2(3, 22)
		bar.color = CompOverlaysScript.get_zone_color(zone)
		rhb.add_child(bar)

		var rkl := Label.new()
		rkl.text = str(rk)
		rkl.custom_minimum_size = Vector2(20, 0)
		rkl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		rkl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		rkl.add_theme_font_size_override("font_size", 12)
		rkl.add_theme_color_override("font_color", UITheme.TEXT_WHITE if is_mine else Color("#9FB3C8"))
		rhb.add_child(rkl)

		var cr_c := CenterContainer.new()
		var cr := ClubCrest.new()
		cr.custom_minimum_size = Vector2(16, 16)
		cr.set_club(cid)
		cr_c.add_child(cr)
		rhb.add_child(cr_c)

		var club_d: Dictionary = GameData.clubs[clampi(cid, 0, GameData.clubs.size() - 1)]
		var code_l := Label.new()
		code_l.text = str(club_d.get("code", "CLB")).left(3).to_upper()
		code_l.custom_minimum_size = Vector2(32, 0)
		code_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		code_l.add_theme_font_override("font", UITheme.get_display_font())
		code_l.add_theme_font_size_override("font_size", 11)
		code_l.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
		rhb.add_child(code_l)

		var name_l := Label.new()
		name_l.text = str(r["name"])
		name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_l.clip_text = true
		name_l.add_theme_font_size_override("font_size", 12)
		name_l.add_theme_color_override("font_color", Color("#E2E8F0") if is_mine else Color("#94A7BD"))
		rhb.add_child(name_l)

		# Qualification icon badge slot (Gambar 2: Elite cup, Europa chalice, Challenge + PO, Promo arrow)
		var q_hb := HBoxContainer.new()
		q_hb.custom_minimum_size = Vector2(36, 0)
		q_hb.alignment = BoxContainer.ALIGNMENT_END
		q_hb.add_theme_constant_override("separation", 3)
		if zone == "ELITE":
			var icw := CenterContainer.new()
			icw.add_child(CompOverlaysScript.make_icon("elite", Color("#CBD5E1"), Vector2(12, 12)))
			q_hb.add_child(icw)
		elif zone == "EUROPA":
			var icw := CenterContainer.new()
			icw.add_child(CompOverlaysScript.make_icon("europa", Color("#FDBA74"), Vector2(12, 12)))
			q_hb.add_child(icw)
		elif zone == "CHALLENGE":
			var icw := CenterContainer.new()
			icw.add_child(CompOverlaysScript.make_icon("challenge", Color("#2DD4BF"), Vector2(11, 11)))
			q_hb.add_child(icw)
			var po_l := Label.new()
			po_l.text = "PO"
			po_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			po_l.add_theme_font_override("font", UITheme.get_display_font())
			po_l.add_theme_font_size_override("font_size", 9)
			po_l.add_theme_color_override("font_color", Color("#2DD4BF"))
			q_hb.add_child(po_l)
		elif zone == "PROMO":
			var icw := CenterContainer.new()
			icw.add_child(CompOverlaysScript.make_icon("promo", Color("#4ADE80"), Vector2(11, 11)))
			q_hb.add_child(icw)
		rhb.add_child(q_hb)

		for sdef in [
			[str(int(r.get("p", 0))), 28, false],
			[str(int(r.get("w", 0))), 26, false],
			[str(int(r.get("d", 0))), 26, false],
			[str(int(r.get("l", 0))), 26, false],
			[str(int(r.get("pts", 0))), 34, true],
		]:
			var sl := Label.new()
			sl.text = str(sdef[0])
			sl.custom_minimum_size = Vector2(int(sdef[1]), 0)
			sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			sl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			if bool(sdef[2]):
				sl.add_theme_font_override("font", UITheme.get_display_font())
				sl.add_theme_font_size_override("font_size", 12)
				sl.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
			else:
				sl.add_theme_font_size_override("font_size", 12)
				sl.add_theme_color_override("font_color", Color("#DCE6F2"))
			rhb.add_child(sl)

	# RIGHT COLUMN: LAGA BERIKUTNYA Card + LAIN [N] Button + TOP SKOR Button
	var right_vb := VBoxContainer.new()
	right_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vb.size_flags_stretch_ratio = 1.0
	right_vb.add_theme_constant_override("separation", 8)
	cols.add_child(right_vb)

	_build_next_match_card(right_vb, table_rows, user_club)

	# LAIN [N] Button (opens KLASEMEN Full Standings Overlay - Gambar 4, 5, 6!)
	var lain_btn := _make_right_action_btn("☰  LAIN", str(total_n), "")
	lain_btn.pressed.connect(func():
		AudioSynth.play_click()
		open_full_standings_overlay()
	)
	right_vb.add_child(lain_btn)

	# TOP SKOR Button (opens TOP 10 GOL | ASSIST | RATING Overlay - Gambar 7!)
	var top_btn := _make_right_action_btn("TOP SKOR", "", "podium")
	top_btn.pressed.connect(func():
		AudioSynth.play_click()
		open_top_scorers_overlay()
	)
	right_vb.add_child(top_btn)

func _select_preview_indices(rows: Array[Dictionary], my_cid: int) -> Array[int]:
	var n: int = rows.size()
	var out: Array[int] = []
	if n <= 9:
		for i in range(n):
			out.append(i)
		return out

	if _comp_mode != "LIGA":
		for i in range(mini(8, n)):
			out.append(i)
		return out

	# Group 1: Top 3 (0, 1, 2)
	var picked: Dictionary = {}
	for i in range(mini(3, n)):
		picked[i] = true

	# Group 2: User's neighborhood if in this league, else European/Promotion cutoff neighborhood (like 6,7,8 in Gambar 2!)
	var u_idx: int = -1
	for i in range(n):
		if int(rows[i]["club_id"]) == my_cid:
			u_idx = i
			break

	var mid_center: int = 6
	if u_idx >= 3 and u_idx <= n - 3:
		mid_center = u_idx
	elif _comp_div == 1:
		var rules: Dictionary = CareerState.get_league_zone_rules(_comp_nat_idx, 1, n)
		mid_center = clampi(int(rules["europa_start"]), 4, n - 4)
	else:
		mid_center = clampi(4, 3, n - 4)

	var m_start: int = clampi(mid_center - 1, 3, n - 5)
	for i in range(m_start, mini(m_start + 3, n - 2)):
		picked[i] = true

	# Group 3: Bottom 2 (n-2, n-1)
	if n >= 2:
		picked[n - 2] = true
		picked[n - 1] = true

	for k in picked.keys():
		out.append(int(k))
	out.sort()
	return out

func _build_next_match_card(parent_vb: VBoxContainer, table_rows: Array[Dictionary], user_club: Dictionary) -> void:
	var card := PanelContainer.new()
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var csb := StyleBoxFlat.new()
	csb.bg_color = Color("#091220")
	csb.border_color = Color("#1B2D47")
	csb.set_border_width_all(1)
	csb.set_corner_radius_all(6)
	csb.content_margin_left = 12
	csb.content_margin_right = 12
	csb.content_margin_top = 10
	csb.content_margin_bottom = 10
	card.add_theme_stylebox_override("panel", csb)
	parent_vb.add_child(card)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	card.add_child(vb)

	# Header: Calendar Icon + LAGA BERIKUTNYA
	var h_hb := HBoxContainer.new()
	h_hb.add_theme_constant_override("separation", 6)
	vb.add_child(h_hb)
	var cw := CenterContainer.new()
	cw.add_child(CompOverlaysScript.make_icon("calendar", Color("#F5C430"), Vector2(13, 13)))
	h_hb.add_child(cw)
	var h_lbl := Label.new()
	h_lbl.text = "LAGA BERIKUTNYA"
	h_lbl.add_theme_font_override("font", UITheme.get_display_font())
	h_lbl.add_theme_font_size_override("font_size", 11)
	h_lbl.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	h_hb.add_child(h_lbl)

	# Determine matchup clubs, ranks, and metadata
	var rank_map: Dictionary = {}
	for i in range(table_rows.size()):
		rank_map[int(table_rows[i]["club_id"])] = i + 1

	var my_cid: int = int(user_club.get("id", 0))
	var my_nid: int = int(user_club.get("nation_id", 0))
	var my_div: int = int(user_club.get("division", 3))
	var cur_wk: int = int(CareerState.career["careerMeta"].get("week", 1))
	var months := ["AGU", "SEP", "OKT", "NOV", "DES", "JAN", "FEB", "MAR", "APR", "MEI"]
	var m_txt: String = months[clampi(int((cur_wk - 1) / 4.5), 0, months.size() - 1)]

	var home_cid: int = my_cid
	var away_cid: int = 0
	var venue_txt: String = "KANDANG"
	var day_txt: String = "MIN"
	var match_wk: int = cur_wk

	if _comp_mode == "LIGA" and _comp_nat_idx == my_nid and _comp_div == my_div:
		var next_fx: Dictionary = {}
		for fx in CareerState.career.get("schedule", []):
			if not bool(fx.get("played", false)) and str(fx.get("comp", "")) == "LIGA":
				next_fx = fx
				break
		if next_fx.is_empty():
			next_fx = CareerState.get_current_fixture()
		var opp_cid: int = int(next_fx.get("opp_club_id", 0))
		var is_home: bool = bool(next_fx.get("is_home", true))
		match_wk = int(next_fx.get("week", cur_wk))
		m_txt = months[clampi(int((match_wk - 1) / 4.5), 0, months.size() - 1)]
		venue_txt = "KANDANG" if is_home else "TANDANG"
		home_cid = my_cid if is_home else opp_cid
		away_cid = opp_cid if is_home else my_cid
	elif table_rows.size() >= 2:
		var idx_a: int = 0
		var idx_b: int = mini(1, table_rows.size() - 1)
		if table_rows.size() >= 8:
			idx_a = (cur_wk + _comp_nat_idx) % 4
			idx_b = clampi(idx_a + 1 + (cur_wk % 3), 1, table_rows.size() - 1)
		home_cid = int(table_rows[idx_a]["club_id"])
		away_cid = int(table_rows[idx_b]["club_id"])
		venue_txt = "LIGA" if _comp_mode == "LIGA" else _comp_mode
		day_txt = "SAB" if _comp_mode == "LIGA" else "RAB"

	var hc: Dictionary = GameData.clubs[clampi(home_cid, 0, GameData.clubs.size() - 1)]
	var ac: Dictionary = GameData.clubs[clampi(away_cid, 0, GameData.clubs.size() - 1)]
	var h_rank: int = int(rank_map.get(home_cid, 1))
	var a_rank: int = int(rank_map.get(away_cid, 2))

	# Center Matchup Crests
	var mid_c := CenterContainer.new()
	mid_c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(mid_c)

	var m_hb := HBoxContainer.new()
	m_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	m_hb.add_theme_constant_override("separation", 18)
	mid_c.add_child(m_hb)

	m_hb.add_child(_make_match_team_col(home_cid, str(hc.get("code", "HOM")), h_rank))

	var vs_l := Label.new()
	vs_l.text = "VS"
	vs_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	vs_l.add_theme_font_override("font", UITheme.get_display_font())
	vs_l.add_theme_font_size_override("font_size", 12)
	vs_l.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	m_hb.add_child(vs_l)

	m_hb.add_child(_make_match_team_col(away_cid, str(ac.get("code", "AWY")), a_rank))

	# Bottom info footer
	var foot := Label.new()
	foot.text = "P%d  •  %s  •  %s  •  %s" % [match_wk, day_txt, m_txt, venue_txt]
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	foot.add_theme_font_size_override("font_size", 11)
	foot.add_theme_color_override("font_color", Color("#94A7BD"))
	vb.add_child(foot)

func _make_match_team_col(cid: int, code: String, rk: int) -> VBoxContainer:
	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 3)
	var cr_c := CenterContainer.new()
	var cr := ClubCrest.new()
	cr.custom_minimum_size = Vector2(54, 54)
	cr.set_club(cid)
	cr_c.add_child(cr)
	vb.add_child(cr_c)

	var cl := Label.new()
	cl.text = code.left(3).to_upper()
	cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cl.add_theme_font_override("font", UITheme.get_display_font())
	cl.add_theme_font_size_override("font_size", 14)
	cl.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	vb.add_child(cl)

	var rl := Label.new()
	rl.text = "ke-%d" % rk
	rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rl.add_theme_font_size_override("font_size", 10)
	rl.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	vb.add_child(rl)
	return vb

func _make_right_action_btn(title: String, badge_txt: String, icon_kind: String) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 42)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#0A1322")
	sb.border_color = Color("#1F334F")
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(5)
	var sbh := sb.duplicate()
	sbh.bg_color = Color("#13233C")
	sbh.border_color = UITheme.ACCENT_CYAN
	var sbp := sb.duplicate()
	sbp.bg_color = Color("#08101C")
	sbp.border_color = Color("#F5C430")
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sbh)
	btn.add_theme_stylebox_override("pressed", sbp)
	btn.add_theme_stylebox_override("focus", sbh)

	var hb := HBoxContainer.new()
	hb.set_anchors_preset(Control.PRESET_FULL_RECT)
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 8)
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(hb)

	if icon_kind != "":
		var iw := CenterContainer.new()
		iw.mouse_filter = Control.MOUSE_FILTER_IGNORE
		iw.add_child(CompOverlaysScript.make_icon(icon_kind, UITheme.TEXT_WHITE, Vector2(14, 14)))
		hb.add_child(iw)

	var tl := Label.new()
	tl.text = title
	tl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tl.add_theme_font_override("font", UITheme.get_display_font())
	tl.add_theme_font_size_override("font_size", 12)
	tl.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(tl)

	if badge_txt != "":
		var pill := PanelContainer.new()
		pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var psb := StyleBoxFlat.new()
		psb.bg_color = Color("#E2E8F0")
		psb.set_border_width_all(0)
		psb.set_corner_radius_all(8)
		psb.content_margin_left = 7
		psb.content_margin_right = 7
		psb.content_margin_top = 1
		psb.content_margin_bottom = 1
		pill.add_theme_stylebox_override("panel", psb)
		var bl := Label.new()
		bl.text = badge_txt
		bl.add_theme_font_override("font", UITheme.get_display_font())
		bl.add_theme_font_size_override("font_size", 10)
		bl.add_theme_color_override("font_color", Color("#0A1322"))
		bl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pill.add_child(bl)
		var pw := CenterContainer.new()
		pw.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pw.add_child(pill)
		hb.add_child(pw)

	return btn

func open_nation_filter_overlay() -> CanvasLayer:
	var host: Node = get_tree().root if is_inside_tree() else self
	return CompOverlaysScript.open_nation_filter(host, _comp_nat_idx, _comp_div, func(new_nid: int, new_div: int):
		_comp_nat_idx = clampi(new_nid, 0, GameData.nations.size() - 1)
		_comp_div = clampi(new_div, 1, 3)
		_comp_mode = "LIGA"
		refresh()
	)

func open_full_standings_overlay() -> CanvasLayer:
	var host: Node = get_tree().root if is_inside_tree() else self
	return CompOverlaysScript.open_full_standings(host, _comp_nat_idx, _comp_div, func(new_div: int):
		_comp_div = clampi(new_div, 1, 3)
		refresh()
	)

func open_top_scorers_overlay() -> CanvasLayer:
	var host: Node = get_tree().root if is_inside_tree() else self
	return CompOverlaysScript.open_top_scorers(host, _comp_nat_idx, _comp_div)

func open_timnas_squad_overlay() -> CanvasLayer:
	var host: Node = get_tree().root if is_inside_tree() else self
	return TimnasOverlaysScript.open_squad_25_overlay(host, CareerState.get_timnas_overview())

func open_confederation_hub_overlay() -> CanvasLayer:
	var host: Node = get_tree().root if is_inside_tree() else self
	var ov: Dictionary = CareerState.get_timnas_overview()
	return TimnasOverlaysScript.open_confederation_hub_overlay(host, str(ov.get("confed", "AFC")))

# ==============================================================================
# TIMNAS DASHBOARD (Gambar 1 + Live Knockout Bracket + 6 Confederations Hub)
# ==============================================================================
func _render_timnas() -> void:
	var ov: Dictionary = CareerState.get_timnas_overview()
	if ov.is_empty():
		return
	var intl: Dictionary = ov.get("intl", {})
	var camp: Dictionary = intl.get("campaign", {})
	var phase: String = str(intl.get("phase", "GROUP"))
	var ko_data: Dictionary = intl.get("knockout", {})
	var has_active_ko: bool = (phase == "KNOCKOUT" and not ko_data.is_empty())

	var cols := HBoxContainer.new()
	cols.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.add_theme_constant_override("separation", 12)
	_comp_root.add_child(cols)

	# --------------------------------------------------------------------------
	# LEFT COLUMN: Flag + Nation + Status Banner + SYARAT Checklist + PANGGILAN [25]
	# --------------------------------------------------------------------------
	var left_vb := VBoxContainer.new()
	left_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_vb.size_flags_stretch_ratio = 1.05
	left_vb.add_theme_constant_override("separation", 5)
	cols.add_child(left_vb)

	# Nation header + Confed pill
	var nat_hb := HBoxContainer.new()
	nat_hb.add_theme_constant_override("separation", 8)
	left_vb.add_child(nat_hb)
	var fl_c := CenterContainer.new()
	fl_c.add_child(UITheme.make_flag_by_code(str(ov["nation_code"]), [], Vector2(26, 17)))
	nat_hb.add_child(fl_c)
	var nat_l := Label.new()
	nat_l.text = str(ov["nation_name"])
	nat_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nat_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	nat_l.add_theme_font_override("font", UITheme.get_display_font())
	nat_l.add_theme_font_size_override("font_size", 14)
	nat_l.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	nat_hb.add_child(nat_l)

	var cf_pill := PanelContainer.new()
	var cfsb := StyleBoxFlat.new()
	cfsb.bg_color = Color("#13233A")
	cfsb.border_color = Color("#2C456A")
	cfsb.set_border_width_all(1)
	cfsb.set_corner_radius_all(4)
	cfsb.content_margin_left = 7
	cfsb.content_margin_right = 7
	cfsb.content_margin_top = 2
	cfsb.content_margin_bottom = 2
	cf_pill.add_theme_stylebox_override("panel", cfsb)
	var cfl := Label.new()
	cfl.text = str(ov["confed"])
	cfl.add_theme_font_override("font", UITheme.get_display_font())
	cfl.add_theme_font_size_override("font_size", 10)
	cfl.add_theme_color_override("font_color", UITheme.ACCENT_CYAN)
	cf_pill.add_child(cfl)
	nat_hb.add_child(cf_pill)

	# Status banner (INTI in olive-gold matching Gambar 1!)
	var status_str: String = str(ov["status"])
	var st_p := PanelContainer.new()
	st_p.custom_minimum_size = Vector2(0, 32)
	var stsb := StyleBoxFlat.new()
	if status_str == "INTI":
		stsb.bg_color = Color("#463C1D")
		stsb.border_color = Color("#8C7735")
	elif status_str == "CADANGAN":
		stsb.bg_color = Color("#132B45")
		stsb.border_color = UITheme.ACCENT_CYAN
	else:
		stsb.bg_color = Color("#2B1620")
		stsb.border_color = Color("#8C3545")
	stsb.set_border_width_all(1)
	stsb.set_corner_radius_all(5)
	stsb.content_margin_left = 12
	stsb.content_margin_right = 10
	st_p.add_theme_stylebox_override("panel", stsb)
	left_vb.add_child(st_p)

	var st_hb := HBoxContainer.new()
	st_hb.add_theme_constant_override("separation", 8)
	st_p.add_child(st_hb)
	var st_lbl := Label.new()
	st_lbl.text = "▸  %s" % status_str
	st_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	st_lbl.add_theme_font_override("font", UITheme.get_display_font())
	st_lbl.add_theme_font_size_override("font_size", 12)
	st_lbl.add_theme_color_override("font_color", Color("#F5C430") if status_str == "INTI" else (UITheme.ACCENT_CYAN if status_str == "CADANGAN" else Color("#FCA5A5")))
	st_hb.add_child(st_lbl)

	# SYARAT | PUNYAMU | MAU header
	var req_hdr := HBoxContainer.new()
	req_hdr.add_theme_constant_override("separation", 4)
	left_vb.add_child(req_hdr)
	for rhd in [["SYARAT", true, 0], ["PUNYAMU", false, 58], ["MAU", false, 44]]:
		var rl := Label.new()
		rl.text = str(rhd[0])
		if bool(rhd[1]):
			rl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		else:
			rl.custom_minimum_size = Vector2(int(rhd[2]), 0)
			rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		rl.add_theme_font_size_override("font_size", 10)
		rl.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
		req_hdr.add_child(rl)

	# 4 Requirement Pill Rows (Gambar 1: DIVISI, RTG, LEVEL, PENGHARGAAN BENUA)
	var req_rows := [
		[bool(ov["div_ok"]), "elite", "DIVISI", "D%d" % int(ov["div_you"]), "D%d" % int(ov["div_req"])],
		[bool(ov["rtg_ok"]), "star", "RTG", TimnasOverlaysScript.format_num_id(float(ov["rtg_you"])), TimnasOverlaysScript.format_num_id(float(ov["rtg_req"]))],
		[bool(ov["level_ok"]), "podium", "LEVEL", TimnasOverlaysScript.format_num_id(float(ov["level_you"])), str(int(ov["level_req"]))],
		[bool(ov["continental_ok"]), "europa", "PENGHARGAAN BENUA", "", ""],
	]
	for rr in req_rows:
		var ok: bool = bool(rr[0])
		var rp := PanelContainer.new()
		rp.custom_minimum_size = Vector2(0, 28)
		var rsb := StyleBoxFlat.new()
		rsb.bg_color = Color("#091322")
		rsb.border_color = Color("#1B2D47")
		rsb.set_border_width_all(1)
		rsb.set_corner_radius_all(14)
		rsb.content_margin_left = 10
		rsb.content_margin_right = 12
		rsb.content_margin_top = 4
		rsb.content_margin_bottom = 4
		rp.add_theme_stylebox_override("panel", rsb)
		left_vb.add_child(rp)

		var rhb := HBoxContainer.new()
		rhb.add_theme_constant_override("separation", 6)
		rp.add_child(rhb)

		var chk := Label.new()
		chk.text = "✓" if ok else "×"
		chk.custom_minimum_size = Vector2(14, 0)
		chk.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		chk.add_theme_font_size_override("font_size", 12)
		chk.add_theme_color_override("font_color", UITheme.TEXT_WHITE if ok else Color("#F87171"))
		rhb.add_child(chk)

		var iw := CenterContainer.new()
		iw.add_child(CompOverlaysScript.make_icon(str(rr[1]), Color("#CBD5E1") if ok else Color("#64748B"), Vector2(12, 12)))
		rhb.add_child(iw)

		var nm := Label.new()
		nm.text = str(rr[2])
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		nm.clip_text = true
		nm.add_theme_font_override("font", UITheme.get_display_font())
		nm.add_theme_font_size_override("font_size", 10)
		nm.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
		rhb.add_child(nm)

		if str(rr[3]) != "":
			var y_l := Label.new()
			y_l.text = str(rr[3])
			y_l.custom_minimum_size = Vector2(54, 0)
			y_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			y_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			y_l.add_theme_font_override("font", UITheme.get_display_font())
			y_l.add_theme_font_size_override("font_size", 12)
			y_l.add_theme_color_override("font_color", UITheme.TEXT_WHITE if ok else Color("#FCA5A5"))
			rhb.add_child(y_l)

			var m_l := Label.new()
			m_l.text = str(rr[4])
			m_l.custom_minimum_size = Vector2(40, 0)
			m_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			m_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			m_l.add_theme_font_override("font", UITheme.get_display_font())
			m_l.add_theme_font_size_override("font_size", 12)
			m_l.add_theme_color_override("font_color", Color("#9FB3C8"))
			rhb.add_child(m_l)

	var l_sp := Control.new()
	l_sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_vb.add_child(l_sp)

	# Bottom PANGGILAN [25] Button (Gambar 1!)
	var call_btn := _make_right_action_btn("PANGGILAN", "25", "podium")
	call_btn.custom_minimum_size = Vector2(0, 36)
	call_btn.pressed.connect(func():
		AudioSynth.play_click()
		open_timnas_squad_overlay()
	)
	left_vb.add_child(call_btn)

	# --------------------------------------------------------------------------
	# CENTER COLUMN: Vertical Gold Call-Up Gauge + KAMU AMBIL TEMPAT Card (Gambar 1)
	# --------------------------------------------------------------------------
	var mid_vb := VBoxContainer.new()
	mid_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid_vb.size_flags_stretch_ratio = 0.92
	mid_vb.add_theme_constant_override("separation", 5)
	cols.add_child(mid_vb)

	var gauge_p := PanelContainer.new()
	gauge_p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var gsb := StyleBoxFlat.new()
	gsb.bg_color = Color("#08111F")
	gsb.border_color = Color("#1A2B45")
	gsb.set_border_width_all(1)
	gsb.set_corner_radius_all(6)
	gsb.content_margin_left = 4
	gsb.content_margin_right = 4
	gsb.content_margin_top = 4
	gsb.content_margin_bottom = 4
	gauge_p.add_theme_stylebox_override("panel", gsb)
	mid_vb.add_child(gauge_p)
	gauge_p.add_child(TimnasOverlaysScript.make_callup_gauge(float(ov["level_you"]), int(ov["level_req"])))

	var rep_hdr := Label.new()
	rep_hdr.text = "KAMU AMBIL TEMPAT" if status_str != "TIDAK DIPANGGIL" else "TARGET POSISIMU"
	rep_hdr.add_theme_font_size_override("font_size", 10)
	rep_hdr.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	mid_vb.add_child(rep_hdr)

	var rep: Dictionary = ov.get("replaced_player", {})
	var rep_p := PanelContainer.new()
	rep_p.custom_minimum_size = Vector2(0, 36)
	var rpsb := StyleBoxFlat.new()
	rpsb.bg_color = Color("#0A1322")
	rpsb.border_color = Color("#1F334F")
	rpsb.set_border_width_all(1)
	rpsb.set_corner_radius_all(6)
	rpsb.content_margin_left = 8
	rpsb.content_margin_right = 10
	rpsb.content_margin_top = 5
	rpsb.content_margin_bottom = 5
	rep_p.add_theme_stylebox_override("panel", rpsb)
	mid_vb.add_child(rep_p)

	var rephb := HBoxContainer.new()
	rephb.add_theme_constant_override("separation", 7)
	rep_p.add_child(rephb)
	var rh_w := CenterContainer.new()
	rh_w.add_child(TimnasOverlaysScript.make_hex_ovr(int(rep.get("ovr", 61)), Vector2(28, 28)))
	rephb.add_child(rh_w)

	var rpos_p := PanelContainer.new()
	var rpos_sb := StyleBoxFlat.new()
	rpos_sb.bg_color = Color("#3A1A1A")
	rpos_sb.border_color = Color("#C85A32")
	rpos_sb.set_border_width_all(1)
	rpos_sb.set_corner_radius_all(3)
	rpos_sb.content_margin_left = 5
	rpos_sb.content_margin_right = 5
	rpos_p.add_theme_stylebox_override("panel", rpos_sb)
	var rpos_l := Label.new()
	rpos_l.text = str(rep.get("pos", "ST"))
	rpos_l.add_theme_font_override("font", UITheme.get_display_font())
	rpos_l.add_theme_font_size_override("font_size", 10)
	rpos_l.add_theme_color_override("font_color", Color("#FB923C"))
	rpos_p.add_child(rpos_l)
	var rpos_c := CenterContainer.new()
	rpos_c.add_child(rpos_p)
	rephb.add_child(rpos_c)

	var rnm := Label.new()
	rnm.text = str(rep.get("name", "Pemain Timnas"))
	rnm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rnm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rnm.clip_text = true
	rnm.add_theme_font_size_override("font_size", 12)
	rnm.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	rephb.add_child(rnm)

	var rcl := Label.new()
	rcl.text = str(rep.get("club_code", "CLB"))
	rcl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rcl.add_theme_font_size_override("font_size", 11)
	rcl.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	rephb.add_child(rcl)

	# --------------------------------------------------------------------------
	# RIGHT COLUMN: KUALIFIKASI / GRUP TABLE (Gambar 1) OR LIVE KNOCKOUT BRACKET (16 BESAR+)!
	# --------------------------------------------------------------------------
	var right_vb := VBoxContainer.new()
	right_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vb.size_flags_stretch_ratio = 1.18
	right_vb.add_theme_constant_override("separation", 6)
	cols.add_child(right_vb)

	var show_ko: bool = has_active_ko and not _timnas_peek_group

	# Right Header
	var rh := HBoxContainer.new()
	rh.add_theme_constant_override("separation", 6)
	right_vb.add_child(rh)
	var rt_lbl := Label.new()
	if show_ko:
		rt_lbl.text = "%s • %s" % [str(camp.get("short_title", "TURNAMEN")), str(ko_data.get("active_round", "16 BESAR"))]
	else:
		var grp_lbl: String = str(intl.get("group_name", "GRUP A"))
		rt_lbl.text = str(camp.get("short_title", "KUALIFIKASI")) if str(camp.get("kind", "")) == "WCQ" else "%s • %s" % [str(camp.get("short_title", "TIMNAS")), grp_lbl]
	rt_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rt_lbl.clip_text = true
	rt_lbl.add_theme_font_override("font", UITheme.get_display_font())
	rt_lbl.add_theme_font_size_override("font_size", 13)
	rt_lbl.add_theme_color_override("font_color", Color("#F5C430") if show_ko else UITheme.TEXT_WHITE)
	rh.add_child(rt_lbl)

	if has_active_ko:
		var tog_b := Button.new()
		tog_b.text = "GRUP" if show_ko else "BAGAN"
		tog_b.custom_minimum_size = Vector2(62, 24)
		UITheme.style_btn(tog_b, Color("#132540"), UITheme.ACCENT_CYAN, 10)
		tog_b.pressed.connect(func():
			AudioSynth.play_click()
			_timnas_peek_group = not _timnas_peek_group
			refresh()
		)
		rh.add_child(tog_b)
	else:
		for chd in [["MN", 26], ["PTS", 32]]:
			var hl := Label.new()
			hl.text = str(chd[0])
			hl.custom_minimum_size = Vector2(int(chd[1]), 0)
			hl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			hl.add_theme_font_size_override("font_size", 10)
			hl.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
			rh.add_child(hl)

	# Subtitle: Pot + Real-life schedule months
	var sub_l := Label.new()
	sub_l.text = "%s • POT %d • %s" % [str(ov["confed"]), int(intl.get("user_pot", 2)), str(camp.get("months", "FIFA"))]
	sub_l.add_theme_font_size_override("font_size", 10)
	sub_l.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	right_vb.add_child(sub_l)

	if show_ko:
		# LIVE KNOCKOUT BRACKET TREE (16 BESAR -> 8 BESAR -> SEMI FINAL -> FINAL)
		var bk_card := PanelContainer.new()
		bk_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var bsb := StyleBoxFlat.new()
		bsb.bg_color = Color("#08111F")
		bsb.border_color = Color("#243A59")
		bsb.set_border_width_all(1)
		bsb.set_corner_radius_all(6)
		bsb.content_margin_left = 6
		bsb.content_margin_right = 6
		bsb.content_margin_top = 6
		bsb.content_margin_bottom = 6
		bk_card.add_theme_stylebox_override("panel", bsb)
		right_vb.add_child(bk_card)
		bk_card.add_child(TimnasOverlaysScript.make_knockout_bracket(ko_data, str(ov["nation_code"]), true))
	else:
		# GROUP / QUALIFICATION STANDINGS TABLE (exact match to Gambar 1!)
		var g_sc := ScrollContainer.new()
		g_sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		g_sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		right_vb.add_child(g_sc)

		var g_vb := VBoxContainer.new()
		g_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		g_vb.add_theme_constant_override("separation", 4)
		g_sc.add_child(g_vb)

		var g_rows: Array = intl.get("group_table", [])
		var q_top: int = int(camp.get("qualify_top", 2))
		for i in range(g_rows.size()):
			var r: Dictionary = g_rows[i]
			var is_u: bool = bool(r.get("is_user", false))
			var rp := PanelContainer.new()
			rp.custom_minimum_size = Vector2(0, 34 if g_rows.size() <= 6 else 26)
			var rsb := StyleBoxFlat.new()
			rsb.bg_color = Color("#3D361C") if is_u else Color("#0A1322")
			rsb.border_color = Color("#8C7735") if is_u else Color("#152339")
			rsb.set_border_width_all(1)
			rsb.set_corner_radius_all(4)
			rsb.content_margin_left = 8
			rsb.content_margin_right = 10
			rsb.content_margin_top = 3
			rsb.content_margin_bottom = 3
			rp.add_theme_stylebox_override("panel", rsb)
			g_vb.add_child(rp)

			var rhb := HBoxContainer.new()
			rhb.add_theme_constant_override("separation", 7)
			rp.add_child(rhb)

			var rkl := Label.new()
			rkl.text = str(i + 1)
			rkl.custom_minimum_size = Vector2(18, 0)
			rkl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			rkl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			rkl.add_theme_font_size_override("font_size", 12)
			rkl.add_theme_color_override("font_color", Color("#F5C430") if is_u else Color("#7A90AA"))
			rhb.add_child(rkl)

			var fw := CenterContainer.new()
			fw.add_child(UITheme.make_flag_by_code(str(r["code"]), r.get("colors", []), Vector2(20, 14)))
			rhb.add_child(fw)

			var nml := Label.new()
			nml.text = str(r["name"]).to_upper()
			nml.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			nml.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			nml.clip_text = true
			nml.add_theme_font_override("font", UITheme.get_display_font())
			nml.add_theme_font_size_override("font_size", 11)
			nml.add_theme_color_override("font_color", Color("#F5C430") if is_u else UITheme.TEXT_WHITE)
			rhb.add_child(nml)

			var mnl := Label.new()
			mnl.text = str(int(r.get("p", 0)))
			mnl.custom_minimum_size = Vector2(24, 0)
			mnl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			mnl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			mnl.add_theme_font_size_override("font_size", 12)
			mnl.add_theme_color_override("font_color", Color("#CBD5E1"))
			rhb.add_child(mnl)

			var ptsl := Label.new()
			ptsl.text = str(int(r.get("pts", 0)))
			ptsl.custom_minimum_size = Vector2(28, 0)
			ptsl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			ptsl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			ptsl.add_theme_font_override("font", UITheme.get_display_font())
			ptsl.add_theme_font_size_override("font_size", 13)
			ptsl.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
			rhb.add_child(ptsl)

			# Crisp golden cutoff line beneath qualification threshold (Gambar 1!)
			if (i + 1) == q_top and (i + 1) < g_rows.size():
				var gold_cut := ColorRect.new()
				gold_cut.custom_minimum_size = Vector2(0, 2)
				gold_cut.color = Color("#D9A826")
				g_vb.add_child(gold_cut)

	# Bottom button to inspect all 6 Confederations, Pots & Full 16-Team Bracket!
	var conf_btn := _make_right_action_btn("KONFEDERASI & BAGAN", "6", "club")
	conf_btn.custom_minimum_size = Vector2(0, 36)
	conf_btn.pressed.connect(func():
		AudioSynth.play_click()
		open_confederation_hub_overlay()
	)
	right_vb.add_child(conf_btn)

# ==============================================================================
# BUKA (BURSA TRANSFER HUB — Gambar 6 -> Pop-Ups Gambar 7 & Gambar 8)
# ==============================================================================
func open_bursa_watched_modal() -> CanvasLayer:
	var host: Node = get_tree().root if is_inside_tree() else self
	var watched: Array[Dictionary] = CareerState.get_watched_clubs()
	return MarketSponsorOverlaysScript.open_watched_list_popup(host, watched, func(entry: Dictionary):
		open_bursa_gossip_modal(entry)
	)

func open_bursa_gossip_modal(club_entry: Dictionary) -> CanvasLayer:
	var host: Node = get_tree().root if is_inside_tree() else self
	return MarketSponsorOverlaysScript.open_gossip_popup(host, club_entry, func():
		refresh()
	, func(off: Dictionary):
		transfer_flow_requested.emit(off)
	)

func open_bursa_status_modal() -> CanvasLayer:
	var host: Node = get_tree().root if is_inside_tree() else self
	return MarketSponsorOverlaysScript.open_status_popup(host)

func open_bursa_offers_modal() -> CanvasLayer:
	var host: Node = get_tree().root if is_inside_tree() else self
	return MarketSponsorOverlaysScript.open_offers_popup(host, func(off: Dictionary):
		transfer_flow_requested.emit(off)
	)

func _render_buka() -> void:
	var p: Dictionary = CareerState.career["playerProfile"]
	var meta: Dictionary = CareerState.career["careerMeta"]
	var st: Dictionary = CareerState.career["stats"]
	var tw_info: Dictionary = CareerState.get_transfer_window_status()
	var tw_open: bool = bool(tw_info.get("is_open", false))
	var tw_wks: int = int(tw_info.get("weeks", 4))
	var watched: Array[Dictionary] = CareerState.get_watched_clubs()
	var agent_left: int = int(meta.get("agentPitchesLeft", 3))
	var agent_rel: int = int(p["relations"].get("agen", 50))
	var costs: Dictionary = CareerState.get_agent_pitch_costs()

	var cols := HBoxContainer.new()
	cols.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.add_theme_constant_override("separation", 12)
	_comp_root.add_child(cols)

	# --------------------------------------------------------------------------
	# LEFT COLUMN (Gambar 6): BURSA TUTUP/BUKA + 3-Tile Strip + AGENMU 3 Purple Cards
	# --------------------------------------------------------------------------
	var left_vb := VBoxContainer.new()
	left_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_vb.size_flags_stretch_ratio = 0.94
	left_vb.add_theme_constant_override("separation", 8)
	cols.add_child(left_vb)

	# 1. Top Window Status Banner
	var top_p := PanelContainer.new()
	top_p.custom_minimum_size = Vector2(0, 48)
	var tpsb := StyleBoxFlat.new()
	tpsb.bg_color = Color("#0D261A") if tw_open else Color("#0A1220")
	tpsb.border_color = UITheme.ACCENT_GREEN if tw_open else Color("#1D2E48")
	tpsb.set_border_width_all(1)
	tpsb.set_corner_radius_all(6)
	tpsb.content_margin_left = 14
	tpsb.content_margin_right = 14
	top_p.add_theme_stylebox_override("panel", tpsb)
	left_vb.add_child(top_p)

	var top_hb := HBoxContainer.new()
	top_hb.add_theme_constant_override("separation", 10)
	top_p.add_child(top_hb)
	var lk_c := CenterContainer.new()
	lk_c.add_child(MarketSponsorOverlaysScript.make_icon("unlock" if tw_open else "lock", UITheme.ACCENT_GREEN if tw_open else Color("#CBD5E1"), Vector2(15, 15)))
	top_hb.add_child(lk_c)
	var tw_title := Label.new()
	tw_title.text = "BURSA BUKA" if tw_open else "BURSA TUTUP"
	tw_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tw_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tw_title.add_theme_font_override("font", UITheme.get_display_font())
	tw_title.add_theme_font_size_override("font_size", 14)
	tw_title.add_theme_color_override("font_color", UITheme.ACCENT_GREEN if tw_open else UITheme.TEXT_WHITE)
	top_hb.add_child(tw_title)
	var tw_sub := Label.new()
	tw_sub.text = ("SISA %d PEKAN" % tw_wks) if tw_open else ("BUKA %d PEKAN" % tw_wks if tw_wks <= 12 else "TAHUN DEPAN")
	tw_sub.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tw_sub.add_theme_font_size_override("font_size", 10)
	tw_sub.add_theme_color_override("font_color", UITheme.ACCENT_GREEN if tw_open else Color("#8EA3BC"))
	top_hb.add_child(tw_sub)

	# 2. Middle 3-Tile Row: NILAIMU | PERGI | STATUSMU (Gambar 6!)
	var mid_hb := HBoxContainer.new()
	mid_hb.custom_minimum_size = Vector2(0, 62)
	mid_hb.add_theme_constant_override("separation", 8)
	left_vb.add_child(mid_hb)

	# Tile 1: NILAIMU
	var val_p := PanelContainer.new()
	val_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	val_p.size_flags_stretch_ratio = 1.25
	var vsb := StyleBoxFlat.new()
	vsb.bg_color = Color("#09111E")
	vsb.border_color = Color("#1B2D47")
	vsb.set_border_width_all(1)
	vsb.set_corner_radius_all(6)
	vsb.content_margin_left = 10
	vsb.content_margin_right = 10
	vsb.content_margin_top = 6
	vsb.content_margin_bottom = 6
	val_p.add_theme_stylebox_override("panel", vsb)
	mid_hb.add_child(val_p)
	var val_vb := VBoxContainer.new()
	val_vb.alignment = BoxContainer.ALIGNMENT_CENTER
	val_vb.add_theme_constant_override("separation", 2)
	val_p.add_child(val_vb)
	var vl1 := Label.new()
	vl1.text = "NILAIMU"
	vl1.add_theme_font_size_override("font_size", 9)
	vl1.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	var vl2 := Label.new()
	vl2.text = "● %s" % UITheme.format_short_cash(int(p["marketValue"])).replace(" ", "")
	vl2.add_theme_font_override("font", UITheme.get_display_font())
	vl2.add_theme_font_size_override("font_size", 16)
	vl2.add_theme_color_override("font_color", Color("#F5C430"))
	val_vb.add_child(vl1)
	val_vb.add_child(vl2)

	# Tile 2: PERGI
	var prg_p := PanelContainer.new()
	prg_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prg_p.size_flags_stretch_ratio = 0.72
	prg_p.add_theme_stylebox_override("panel", vsb.duplicate())
	mid_hb.add_child(prg_p)
	var prg_vb := VBoxContainer.new()
	prg_vb.alignment = BoxContainer.ALIGNMENT_CENTER
	prg_vb.add_theme_constant_override("separation", 2)
	prg_p.add_child(prg_vb)
	var pl1 := Label.new()
	pl1.text = "PERGI"
	pl1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pl1.add_theme_font_size_override("font_size", 9)
	pl1.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	var pl2 := Label.new()
	pl2.text = str(int(st.get("transfers", 0)))
	pl2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pl2.add_theme_font_override("font", UITheme.get_display_font())
	pl2.add_theme_font_size_override("font_size", 18)
	pl2.add_theme_color_override("font_color", Color("#94A7BD"))
	prg_vb.add_child(pl1)
	prg_vb.add_child(pl2)

	# Tile 3: STATUSMU Teal Button
	var stat_b := Button.new()
	stat_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stat_b.size_flags_stretch_ratio = 1.25
	var st_sb := StyleBoxFlat.new()
	st_sb.bg_color = Color("#1B4F62")
	st_sb.border_color = Color("#5CC8DF")
	st_sb.set_border_width_all(1)
	st_sb.border_width_bottom = 3
	st_sb.set_corner_radius_all(6)
	var st_sbh := st_sb.duplicate()
	st_sbh.bg_color = Color("#24657C")
	stat_b.add_theme_stylebox_override("normal", st_sb)
	stat_b.add_theme_stylebox_override("hover", st_sbh)
	stat_b.add_theme_stylebox_override("pressed", st_sbh)
	stat_b.add_theme_stylebox_override("focus", st_sbh)
	var shb := HBoxContainer.new()
	shb.set_anchors_preset(Control.PRESET_FULL_RECT)
	shb.alignment = BoxContainer.ALIGNMENT_CENTER
	shb.add_theme_constant_override("separation", 7)
	shb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stat_b.add_child(shb)
	var dic := CenterContainer.new()
	dic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dic.add_child(MarketSponsorOverlaysScript.make_icon("doc", Color("#E2E8F0"), Vector2(14, 14)))
	shb.add_child(dic)
	var slbl := Label.new()
	slbl.text = "STATUSMU"
	slbl.add_theme_font_override("font", UITheme.get_display_font())
	slbl.add_theme_font_size_override("font_size", 11)
	slbl.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	slbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shb.add_child(slbl)
	stat_b.pressed.connect(func(): AudioSynth.play_click(); open_bursa_status_modal())
	mid_hb.add_child(stat_b)

	# 3. Bottom AGENMU Card (PERCAYA bar + SISA + 3 Tall Purple Action Cards — Gambar 6!)
	var ag_p := PanelContainer.new()
	ag_p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var agsb := StyleBoxFlat.new()
	agsb.bg_color = Color("#0A1322")
	agsb.border_color = Color("#1B2D47")
	agsb.set_border_width_all(1)
	agsb.set_corner_radius_all(6)
	agsb.content_margin_left = 10
	agsb.content_margin_right = 10
	agsb.content_margin_top = 8
	agsb.content_margin_bottom = 10
	ag_p.add_theme_stylebox_override("panel", agsb)
	left_vb.add_child(ag_p)

	var ag_vb := VBoxContainer.new()
	ag_vb.add_theme_constant_override("separation", 8)
	ag_p.add_child(ag_vb)

	# AGENMU header + PERCAYA segmented bar + SISA count
	var ag_hdr := HBoxContainer.new()
	ag_hdr.add_theme_constant_override("separation", 8)
	ag_vb.add_child(ag_hdr)
	var ah_ic := CenterContainer.new()
	ah_ic.add_child(MarketSponsorOverlaysScript.make_icon("headset", Color("#E05A5A"), Vector2(15, 15)))
	ag_hdr.add_child(ah_ic)

	var ah_vb := VBoxContainer.new()
	ah_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ah_vb.add_theme_constant_override("separation", 2)
	ag_hdr.add_child(ah_vb)
	var ah_t := Label.new()
	ah_t.text = "AGENMU"
	ah_t.add_theme_font_override("font", UITheme.get_display_font())
	ah_t.add_theme_font_size_override("font_size", 11)
	ah_t.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	ah_vb.add_child(ah_t)

	var pr_hb := HBoxContainer.new()
	pr_hb.add_theme_constant_override("separation", 6)
	ah_vb.add_child(pr_hb)
	var pr_cap := Label.new()
	pr_cap.text = "PERCAYA"
	pr_cap.add_theme_font_size_override("font_size", 9)
	pr_cap.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	pr_hb.add_child(pr_cap)
	var pr_seg := HBoxContainer.new()
	pr_seg.custom_minimum_size = Vector2(78, 8)
	pr_seg.add_theme_constant_override("separation", 2)
	var filled_ag: int = clampi(int(round(float(agent_rel) / 10.0)), 1, 10)
	for s_i in range(10):
		var sr := ColorRect.new()
		sr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sr.custom_minimum_size = Vector2(0, 8)
		sr.color = Color("#DC5B57") if s_i < filled_ag else Color("#18273E")
		pr_seg.add_child(sr)
	var pr_seg_c := VBoxContainer.new()
	pr_seg_c.alignment = BoxContainer.ALIGNMENT_CENTER
	pr_seg_c.add_child(pr_seg)
	pr_hb.add_child(pr_seg_c)
	var pr_num := Label.new()
	pr_num.text = str(agent_rel)
	pr_num.add_theme_font_override("font", UITheme.get_display_font())
	pr_num.add_theme_font_size_override("font_size", 11)
	pr_num.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	pr_hb.add_child(pr_num)

	var sisa_l := Label.new()
	sisa_l.text = "SISA %d" % agent_left
	sisa_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sisa_l.add_theme_font_size_override("font_size", 10)
	sisa_l.add_theme_color_override("font_color", Color("#94A7BD"))
	ag_hdr.add_child(sisa_l)

	# 3 Tall Purple Action Cards side-by-side (TAWARKAN | SATU LIGA | SATU KLUB)
	var ag_cards := HBoxContainer.new()
	ag_cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ag_cards.add_theme_constant_override("separation", 8)
	ag_vb.add_child(ag_cards)

	var cash_now: int = int(p.get("cash", 0))
	for a_opt in [
		["TAWARKAN", "TAWARKAN", "target", int(costs["TAWARKAN"])],
		["SATU_LIGA", "SATU LIGA", "globe", int(costs["SATU_LIGA"])],
		["SATU_KLUB", "SATU KLUB", "door", int(costs["SATU_KLUB"])],
	]:
		var mode_k: String = str(a_opt[0])
		var lbl_s: String = str(a_opt[1])
		var ico_s: String = str(a_opt[2])
		var fee_v: int = int(a_opt[3])
		var can_aff: bool = (agent_left > 0 and cash_now >= fee_v)

		var ab := Button.new()
		ab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ab.size_flags_vertical = Control.SIZE_EXPAND_FILL
		ab.disabled = not can_aff
		var asb := StyleBoxFlat.new()
		asb.bg_color = Color("#2C214A") if can_aff else Color("#181529")
		asb.border_color = Color("#8C6CE6") if can_aff else Color("#332D4A")
		asb.set_border_width_all(1)
		asb.border_width_bottom = 3
		asb.set_corner_radius_all(4)
		var asbh := asb.duplicate()
		asbh.bg_color = Color("#3B2D63")
		asbh.border_color = UITheme.ACCENT_CYAN
		ab.add_theme_stylebox_override("normal", asb)
		ab.add_theme_stylebox_override("hover", asbh)
		ab.add_theme_stylebox_override("pressed", asbh)
		ab.add_theme_stylebox_override("focus", asbh)
		ab.add_theme_stylebox_override("disabled", asb)

		var avb := VBoxContainer.new()
		avb.set_anchors_preset(Control.PRESET_FULL_RECT)
		avb.offset_left = 8
		avb.offset_right = -8
		avb.offset_top = 10
		avb.offset_bottom = -10
		avb.alignment = BoxContainer.ALIGNMENT_END
		avb.add_theme_constant_override("separation", 6)
		avb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ab.add_child(avb)

		var ic_row := HBoxContainer.new()
		ic_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ic_row.add_child(MarketSponsorOverlaysScript.make_icon(ico_s, Color("#C4B5FD") if can_aff else Color("#64748B"), Vector2(20, 20)))
		avb.add_child(ic_row)

		var sp_in := Control.new()
		sp_in.custom_minimum_size = Vector2(0, 4)
		sp_in.mouse_filter = Control.MOUSE_FILTER_IGNORE
		avb.add_child(sp_in)

		var ttl := Label.new()
		ttl.text = lbl_s
		ttl.clip_text = true
		ttl.add_theme_font_override("font", UITheme.get_display_font())
		ttl.add_theme_font_size_override("font_size", 10)
		ttl.add_theme_color_override("font_color", UITheme.TEXT_WHITE if can_aff else Color("#64748B"))
		ttl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		avb.add_child(ttl)

		var prl := Label.new()
		prl.text = MarketSponsorOverlaysScript.format_cash_dots(fee_v)
		prl.clip_text = true
		prl.add_theme_font_override("font", UITheme.get_display_font())
		prl.add_theme_font_size_override("font_size", 11)
		prl.add_theme_color_override("font_color", Color("#F5C430") if can_aff else Color("#64748B"))
		prl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		avb.add_child(prl)

		ab.pressed.connect(func():
			AudioSynth.play_click()
			CareerState.use_agent_pitch(mode_k)
			refresh()
		)
		ag_cards.add_child(ab)

	# --------------------------------------------------------------------------
	# RIGHT COLUMN (Gambar 6): DIPANTAU [N] + 2 Club Cards (CEK -> Gbr 8) + LAIN • N (-> Gbr 7) + Bottom Bar
	# --------------------------------------------------------------------------
	var right_vb := VBoxContainer.new()
	right_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vb.size_flags_stretch_ratio = 1.06
	right_vb.add_theme_constant_override("separation", 8)
	cols.add_child(right_vb)

	# DIPANTAU [N] Header
	var dip_hb := HBoxContainer.new()
	dip_hb.add_theme_constant_override("separation", 8)
	right_vb.add_child(dip_hb)
	var dip_l := Label.new()
	dip_l.text = "DIPANTAU"
	dip_l.add_theme_font_override("font", UITheme.get_display_font())
	dip_l.add_theme_font_size_override("font_size", 12)
	dip_l.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	dip_hb.add_child(dip_l)

	var cnt_p := PanelContainer.new()
	var cnt_sb := StyleBoxFlat.new()
	cnt_sb.bg_color = Color("#0D261A")
	cnt_sb.border_color = UITheme.ACCENT_GREEN
	cnt_sb.set_border_width_all(1)
	cnt_sb.set_corner_radius_all(3)
	cnt_sb.content_margin_left = 5
	cnt_sb.content_margin_right = 5
	cnt_p.add_theme_stylebox_override("panel", cnt_sb)
	var cnt_txt := Label.new()
	cnt_txt.text = str(watched.size())
	cnt_txt.add_theme_font_override("font", UITheme.get_display_font())
	cnt_txt.add_theme_font_size_override("font_size", 10)
	cnt_txt.add_theme_color_override("font_color", UITheme.ACCENT_GREEN)
	cnt_p.add_child(cnt_txt)
	dip_hb.add_child(cnt_p)

	# Top 2 Watched Club Cards (Gambar 6!)
	var show_top: int = mini(2, watched.size())
	for i in range(show_top):
		var w_club: Dictionary = watched[i]
		var w_card := PanelContainer.new()
		w_card.custom_minimum_size = Vector2(0, 74)
		var wcsb := StyleBoxFlat.new()
		wcsb.bg_color = Color("#0A1322")
		wcsb.border_color = Color("#1B2D47")
		wcsb.set_border_width_all(1)
		wcsb.set_corner_radius_all(6)
		wcsb.content_margin_left = 12
		wcsb.content_margin_right = 12
		wcsb.content_margin_top = 8
		wcsb.content_margin_bottom = 8
		w_card.add_theme_stylebox_override("panel", wcsb)
		right_vb.add_child(w_card)

		var whb := HBoxContainer.new()
		whb.add_theme_constant_override("separation", 10)
		w_card.add_child(whb)

		var cr_c := CenterContainer.new()
		var cr := ClubCrest.new()
		cr.custom_minimum_size = Vector2(40, 40)
		cr.set_club(int(w_club["club_id"]))
		cr_c.add_child(cr)
		whb.add_child(cr_c)

		var wvb := VBoxContainer.new()
		wvb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		wvb.alignment = BoxContainer.ALIGNMENT_CENTER
		wvb.add_theme_constant_override("separation", 2)
		whb.add_child(wvb)

		var w_nm := Label.new()
		w_nm.text = str(w_club["name"]).to_upper()
		w_nm.clip_text = true
		w_nm.add_theme_font_override("font", UITheme.get_display_font())
		w_nm.add_theme_font_size_override("font_size", 11)
		w_nm.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
		wvb.add_child(w_nm)

		var w_sub := Label.new()
		w_sub.text = "KE-%d • ke-%d/%d" % [int(w_club["division"]), int(w_club["rank"]), int(w_club["total_teams"])]
		w_sub.add_theme_font_size_override("font_size", 10)
		w_sub.add_theme_color_override("font_color", Color("#8EA3BC"))
		wvb.add_child(w_sub)

		var w_st := Label.new()
		var st_s: String = str(w_club.get("status", "DEKAT"))
		w_st.text = st_s
		w_st.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		w_st.add_theme_font_override("font", UITheme.get_display_font())
		w_st.add_theme_font_size_override("font_size", 11)
		w_st.add_theme_color_override("font_color", UITheme.ACCENT_GREEN if st_s == "LAMPU HIJAU" else (Color("#64748B") if st_s == "DITOLAK" else UITheme.TEXT_WHITE))
		whb.add_child(w_st)

		# Crimson red CEK button (opens Gambar 8 ! GOSIP popup!)
		var cek_b := Button.new()
		cek_b.text = "CEK"
		cek_b.custom_minimum_size = Vector2(76, 42)
		var ckb_sb := StyleBoxFlat.new()
		ckb_sb.bg_color = Color("#C82834")
		ckb_sb.border_color = Color("#EF5350")
		ckb_sb.set_border_width_all(1)
		ckb_sb.border_width_bottom = 3
		ckb_sb.set_corner_radius_all(3)
		var ckb_sbh := ckb_sb.duplicate()
		ckb_sbh.bg_color = Color("#DC3545")
		cek_b.add_theme_stylebox_override("normal", ckb_sb)
		cek_b.add_theme_stylebox_override("hover", ckb_sbh)
		cek_b.add_theme_stylebox_override("pressed", ckb_sbh)
		cek_b.add_theme_stylebox_override("focus", ckb_sbh)
		cek_b.add_theme_font_override("font", UITheme.get_display_font())
		cek_b.add_theme_font_size_override("font_size", 12)
		cek_b.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
		var w_copy: Dictionary = w_club
		cek_b.pressed.connect(func():
			AudioSynth.play_click()
			open_bursa_gossip_modal(w_copy)
		)
		var cek_c := CenterContainer.new()
		cek_c.add_child(cek_b)
		whb.add_child(cek_c)

	# LAIN • N Bar Button (opens Gambar 7 DIPANTAU Full Popup!)
	var rem_w: int = maxi(0, watched.size() - show_top)
	var lain_disp: int = rem_w if rem_w > 0 else watched.size()
	var lain_b := Button.new()
	lain_b.custom_minimum_size = Vector2(0, 40)
	lain_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var lnsb := StyleBoxFlat.new()
	lnsb.bg_color = Color("#0A1322")
	lnsb.border_color = Color("#2C244A")
	lnsb.set_border_width_all(1)
	lnsb.border_width_bottom = 2
	lnsb.set_corner_radius_all(4)
	var lnsbh := lnsb.duplicate()
	lnsbh.bg_color = Color("#14213A")
	lnsbh.border_color = UITheme.ACCENT_CYAN
	lain_b.add_theme_stylebox_override("normal", lnsb)
	lain_b.add_theme_stylebox_override("hover", lnsbh)
	lain_b.add_theme_stylebox_override("pressed", lnsbh)
	lain_b.add_theme_stylebox_override("focus", lnsbh)
	var lhb := HBoxContainer.new()
	lhb.set_anchors_preset(Control.PRESET_FULL_RECT)
	lhb.offset_left = 12
	lhb.offset_right = -12
	lhb.add_theme_constant_override("separation", 8)
	lhb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lain_b.add_child(lhb)
	var bg_c := CenterContainer.new()
	bg_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_c.add_child(MarketSponsorOverlaysScript.make_icon("bag", Color("#8B74E8"), Vector2(14, 14)))
	lhb.add_child(bg_c)
	var llbl := Label.new()
	llbl.text = "LAIN  •  %d" % lain_disp
	llbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	llbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	llbl.add_theme_font_override("font", UITheme.get_display_font())
	llbl.add_theme_font_size_override("font_size", 11)
	llbl.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	llbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lhb.add_child(llbl)
	var lp_box := PanelContainer.new()
	lp_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lpsb := StyleBoxFlat.new()
	lpsb.bg_color = Color("#1B1633")
	lpsb.border_color = Color("#6E58B8")
	lpsb.set_border_width_all(1)
	lpsb.set_corner_radius_all(3)
	lpsb.content_margin_left = 6
	lpsb.content_margin_right = 6
	lp_box.add_theme_stylebox_override("panel", lpsb)
	var lp_txt := Label.new()
	lp_txt.text = str(lain_disp)
	lp_txt.add_theme_font_override("font", UITheme.get_display_font())
	lp_txt.add_theme_font_size_override("font_size", 10)
	lp_txt.add_theme_color_override("font_color", Color("#A78BFA"))
	lp_txt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lp_box.add_child(lp_txt)
	var lp_c := CenterContainer.new()
	lp_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lp_c.add_child(lp_box)
	lhb.add_child(lp_c)
	lain_b.pressed.connect(func(): AudioSynth.play_click(); open_bursa_watched_modal())
	right_vb.add_child(lain_b)

	var r_sp := Control.new()
	r_sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vb.add_child(r_sp)

	# Bottom Bar: BURSA TUTUP (or BURSA BUKA • LIHAT TAWARAN when open!)
	var bot_b := Button.new()
	bot_b.custom_minimum_size = Vector2(0, 42)
	bot_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bot_b.disabled = not tw_open
	var btsb := StyleBoxFlat.new()
	btsb.bg_color = Color("#123624") if tw_open else Color("#0A1220")
	btsb.border_color = UITheme.ACCENT_GREEN if tw_open else Color("#1D2E48")
	btsb.set_border_width_all(1)
	btsb.set_corner_radius_all(4)
	var btsbh := btsb.duplicate()
	btsbh.bg_color = Color("#1A4A32")
	bot_b.add_theme_stylebox_override("normal", btsb)
	bot_b.add_theme_stylebox_override("hover", btsbh)
	bot_b.add_theme_stylebox_override("pressed", btsbh)
	bot_b.add_theme_stylebox_override("disabled", btsb)
	var bthb := HBoxContainer.new()
	bthb.set_anchors_preset(Control.PRESET_FULL_RECT)
	bthb.offset_left = 12
	bthb.offset_right = -12
	bthb.add_theme_constant_override("separation", 8)
	bthb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bot_b.add_child(bthb)
	var bcal := CenterContainer.new()
	bcal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bcal.add_child(MarketSponsorOverlaysScript.make_icon("calendar", UITheme.ACCENT_GREEN if tw_open else Color("#8EA3BC"), Vector2(14, 14)))
	bthb.add_child(bcal)
	var btl := Label.new()
	if tw_open:
		var off_cnt: int = CareerState.career.get("transferOffers", []).size()
		btl.text = "BURSA BUKA • LIHAT TAWARAN MASUK (%d)" % maxi(off_cnt, 1)
	else:
		btl.text = "BURSA TUTUP"
	btl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	btl.add_theme_font_override("font", UITheme.get_display_font())
	btl.add_theme_font_size_override("font_size", 11)
	btl.add_theme_color_override("font_color", UITheme.ACCENT_GREEN if tw_open else Color("#CBD5E1"))
	btl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bthb.add_child(btl)
	bot_b.pressed.connect(func(): AudioSynth.play_click(); open_bursa_offers_modal())
	right_vb.add_child(bot_b)

func _xfer_league_label() -> String:
	var lm: String = str(_xfer_filters.get("league_mode", "MINE"))
	if lm == "MINE":
		return "LIGAMU"
	if lm == "NAT":
		var nid: int = int(_xfer_filters.get("nat_id", -1))
		if nid >= 0 and nid < GameData.nations.size():
			return str(GameData.nations[nid]["name"]).to_upper()
	return "SEMUA"

func _xfer_pos_label() -> String:
	var pl: Array = _xfer_filters.get("positions", [])
	if pl.is_empty():
		return "SEMUA"
	if pl.size() <= 2:
		return ", ".join(PackedStringArray(pl))
	return "%s +%d" % [str(pl[0]), pl.size() - 1]

func _xfer_sort_label() -> String:
	var sm: String = str(_xfer_filters.get("sort", "TERBARU"))
	if sm == "NILAI":
		return "NILAI"
	if sm == "OVR":
		return "OVR"
	return "TERBARU"

func open_transfer_filter_modal(kind: String) -> CanvasLayer:
	var host: Node = get_tree().root if is_inside_tree() else self
	match kind:
		"LIGA":
			return RankingOverlaysScript.open_transfer_league_filter(host, str(_xfer_filters["league_mode"]), int(_xfer_filters["nat_id"]), func(new_mode: String, new_nid: int):
				_xfer_filters["league_mode"] = new_mode
				_xfer_filters["nat_id"] = new_nid
				refresh()
			)
		"POS":
			return RankingOverlaysScript.open_pos_filter(host, _xfer_filters.get("positions", []), func(new_pos: Array):
				_xfer_filters["positions"] = new_pos
				refresh()
			)
		_:
			return RankingOverlaysScript.open_transfer_sort_filter(host, str(_xfer_filters["sort"]), func(new_sort):
				_xfer_filters["sort"] = str(new_sort)
				refresh()
			)

func open_all_transfers_modal() -> CanvasLayer:
	var host: Node = get_tree().root if is_inside_tree() else self
	var rows: Array[Dictionary] = CareerState.get_world_transfers(_xfer_filters)
	return RankingOverlaysScript.open_all_transfers_overlay(host, _xfer_league_label(), rows, func(wp_i: int):
		open_rank_player_detail(wp_i)
	)

func _make_xfer_filter_pill(prefix_txt: String, val_txt: String, val_col: Color) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(114, 30)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#0A1322")
	sb.border_color = Color("#1F334F")
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(4)
	var sbh := sb.duplicate()
	sbh.bg_color = Color("#13233C")
	sbh.border_color = UITheme.ACCENT_CYAN
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sbh)
	btn.add_theme_stylebox_override("pressed", sbh)
	btn.add_theme_stylebox_override("focus", sbh)

	var hb := HBoxContainer.new()
	hb.set_anchors_preset(Control.PRESET_FULL_RECT)
	hb.offset_left = 10
	hb.offset_right = -10
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 6)
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(hb)

	var p_l := Label.new()
	p_l.text = prefix_txt
	p_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p_l.add_theme_font_size_override("font_size", 10)
	p_l.add_theme_color_override("font_color", Color("#7B91AC"))
	p_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(p_l)

	var v_l := Label.new()
	v_l.text = val_txt
	v_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	v_l.add_theme_font_override("font", UITheme.get_display_font())
	v_l.add_theme_font_size_override("font_size", 10)
	v_l.add_theme_color_override("font_color", val_col)
	v_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(v_l)
	return btn

func _render_transfer_feed() -> void:
	var transfers: Array[Dictionary] = CareerState.get_world_transfers(_xfer_filters)
	var tw_info: Dictionary = CareerState.get_transfer_window_status()
	var tw_open: bool = bool(tw_info.get("is_open", false))
	var tw_wks: int = int(tw_info.get("weeks", 4))

	# Row 1: Filter Bar (LIGA | POS | URUTAN) + Right Transfer Window Status Pill (Gambar 2!)
	var top_bar := HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 6)
	_comp_root.add_child(top_bar)

	var liga_lbl: String = _xfer_league_label()
	var b_liga: Button = _make_xfer_filter_pill("LIGA", liga_lbl, Color("#A78BFA") if liga_lbl != "SEMUA" else UITheme.TEXT_WHITE)
	b_liga.custom_minimum_size = Vector2(132, 30)
	b_liga.pressed.connect(func(): AudioSynth.play_click(); open_transfer_filter_modal("LIGA"))
	top_bar.add_child(b_liga)

	var pos_lbl: String = _xfer_pos_label()
	var b_pos: Button = _make_xfer_filter_pill("POS", pos_lbl, UITheme.ACCENT_CYAN if pos_lbl != "SEMUA" else UITheme.TEXT_WHITE)
	b_pos.custom_minimum_size = Vector2(118, 30)
	b_pos.pressed.connect(func(): AudioSynth.play_click(); open_transfer_filter_modal("POS"))
	top_bar.add_child(b_pos)

	var sort_lbl: String = _xfer_sort_label()
	var b_sort: Button = _make_xfer_filter_pill("URUTAN", sort_lbl, Color("#F5C430") if sort_lbl != "TERBARU" else UITheme.TEXT_WHITE)
	b_sort.custom_minimum_size = Vector2(144, 30)
	b_sort.pressed.connect(func(): AudioSynth.play_click(); open_transfer_filter_modal("URUTAN"))
	top_bar.add_child(b_sort)

	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(sp)

	if tw_open:
		var offers: Array = CareerState.career.get("transferOffers", [])
		var offer_b := Button.new()
		offer_b.text = "TAWARAN (%d)" % offers.size() if not offers.is_empty() else "BURSA BUKA"
		offer_b.custom_minimum_size = Vector2(116, 30)
		UITheme.style_btn(offer_b, Color("#133D29"), UITheme.ACCENT_GREEN, 10)
		offer_b.pressed.connect(func(): AudioSynth.play_click(); _subtab = "BUKA"; refresh())
		top_bar.add_child(offer_b)

	# Right Window Pill: JENDELA • TUTUP 4 P (or BUKA 4 P)
	var win_p := PanelContainer.new()
	win_p.custom_minimum_size = Vector2(190, 30)
	var wsb := StyleBoxFlat.new()
	wsb.bg_color = Color("#0E281C") if tw_open else Color("#0A1322")
	wsb.border_color = UITheme.ACCENT_GREEN if tw_open else Color("#24354F")
	wsb.set_border_width_all(1)
	wsb.set_corner_radius_all(14)
	wsb.content_margin_left = 12
	wsb.content_margin_right = 12
	wsb.content_margin_top = 4
	wsb.content_margin_bottom = 4
	win_p.add_theme_stylebox_override("panel", wsb)
	top_bar.add_child(win_p)

	var whb := HBoxContainer.new()
	whb.alignment = BoxContainer.ALIGNMENT_CENTER
	whb.add_theme_constant_override("separation", 6)
	win_p.add_child(whb)
	var dot := Label.new()
	dot.text = "●"
	dot.add_theme_font_size_override("font_size", 10)
	dot.add_theme_color_override("font_color", UITheme.ACCENT_GREEN if tw_open else Color("#CBD5E1"))
	whb.add_child(dot)
	var w_txt := Label.new()
	w_txt.text = "JENDELA • %s %d P" % ["BUKA" if tw_open else "TUTUP", tw_wks]
	w_txt.add_theme_font_override("font", UITheme.get_display_font())
	w_txt.add_theme_font_size_override("font_size", 10)
	w_txt.add_theme_color_override("font_color", UITheme.ACCENT_GREEN if tw_open else Color("#CBD5E1"))
	whb.add_child(w_txt)

	# Row 2: Rich 2-Club Themed Transfer Player Cards Grid (Gambar 1!)
	var show_cnt: int = mini(6, transfers.size())
	if show_cnt == 0:
		var ec := CenterContainer.new()
		ec.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var el := Label.new()
		el.text = "Tidak ada transfer yang cocok dengan filter posisi/liga saat ini."
		el.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
		ec.add_child(el)
		_comp_root.add_child(ec)
	else:
		var t_sc := ScrollContainer.new()
		t_sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		t_sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		t_sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		_comp_root.add_child(t_sc)

		var t_grid := GridContainer.new()
		t_grid.columns = 2
		t_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		t_grid.add_theme_constant_override("h_separation", 8)
		t_grid.add_theme_constant_override("v_separation", 6)
		t_sc.add_child(t_grid)

		for i in range(show_cnt):
			var tr_d: Dictionary = transfers[i]
			t_grid.add_child(RankingOverlaysScript.make_transfer_player_card(tr_d, func(wp_i: int):
				open_rank_player_detail(wp_i)
			))

	# Row 3: Bottom Wide "☰  LAIN  •  <N>" Button (opens Full Transfers Overlay)
	var rem_cnt: int = maxi(0, transfers.size() - show_cnt)
	var disp_cnt: int = rem_cnt if rem_cnt > 0 else transfers.size()
	var lain_btn := _make_right_action_btn("☰  LAIN  •  %d" % disp_cnt, "", "")
	lain_btn.custom_minimum_size = Vector2(0, 36)
	lain_btn.pressed.connect(func():
		AudioSynth.play_click()
		open_all_transfers_modal()
	)
	_comp_root.add_child(lain_btn)

func _reset_rank_filters() -> void:
	_rank_filters = {
		"positions": [],
		"age": "SEMUA",
		"val": "SEMUA",
		"nat_id": -1,
		"league_nat_id": -1,
		"division": 0,
		"club_mode": "SEMUA",
		"query": "",
	}
	_rank_page = 0
	_rank_cache_dirty = true

func _has_any_rank_filter() -> bool:
	if not (_rank_filters.get("positions", []) as Array).is_empty():
		return true
	if str(_rank_filters.get("age", "SEMUA")) != "SEMUA":
		return true
	if str(_rank_filters.get("val", "SEMUA")) != "SEMUA":
		return true
	if int(_rank_filters.get("nat_id", -1)) >= 0:
		return true
	if int(_rank_filters.get("league_nat_id", -1)) >= 0:
		return true
	if int(_rank_filters.get("division", 0)) > 0:
		return true
	if str(_rank_filters.get("club_mode", "SEMUA")) != "SEMUA":
		return true
	if str(_rank_filters.get("query", "")) != "":
		return true
	return false

func _get_filtered_rank_indices() -> PackedInt32Array:
	if _rank_cache_dirty or _rank_filtered_cache.is_empty():
		_rank_filtered_cache = CareerState.filter_world_players(_rank_filters)
		_rank_cache_dirty = false
	return _rank_filtered_cache

func open_rank_player_detail(wp_idx: int) -> CanvasLayer:
	var host: Node = get_tree().root if is_inside_tree() else self
	return RankingOverlaysScript.open_player_detail(host, CareerState.get_world_player_detail(wp_idx))

func open_rank_filter_modal(kind: String) -> CanvasLayer:
	var host: Node = get_tree().root if is_inside_tree() else self
	match kind:
		"POS":
			return RankingOverlaysScript.open_pos_filter(host, _rank_filters.get("positions", []), func(new_pos: Array):
				_rank_filters["positions"] = new_pos
				_rank_page = 0
				_rank_cache_dirty = true
				refresh()
			)
		"USIA":
			var age_opts := [
				["SEMUA", "SEMUA"], ["U21", "<=21 TAHUN"], ["22_25", "22-25 TAHUN"],
				["26_29", "26-29 TAHUN"], ["30_33", "30-33 TAHUN"], ["34P", "34+ TAHUN"],
			]
			return RankingOverlaysScript.open_option_grid_filter(host, "FILTER USIA", age_opts, str(_rank_filters["age"]), 4, func(k):
				_rank_filters["age"] = str(k)
				_rank_page = 0
				_rank_cache_dirty = true
				refresh()
			)
		"NILAI":
			var val_opts := [
				["SEMUA", "SEMUA"], ["LT2", "<2 M"], ["2_6", "2-6 M"], ["6_15", "6-15 M"],
				["15_40", "15-40 M"], ["40_80", "40-80 M"], ["80P", "80 M+"],
			]
			return RankingOverlaysScript.open_option_grid_filter(host, "FILTER NILAI", val_opts, str(_rank_filters["val"]), 4, func(k):
				_rank_filters["val"] = str(k)
				_rank_page = 0
				_rank_cache_dirty = true
				refresh()
			)
		"NEGARA":
			return RankingOverlaysScript.open_nation_or_league_filter(host, "FILTER NEGARA", int(_rank_filters["nat_id"]), func(nid: int):
				_rank_filters["nat_id"] = nid
				_rank_page = 0
				_rank_cache_dirty = true
				refresh()
			)
		"LIGA":
			return RankingOverlaysScript.open_nation_or_league_filter(host, "FILTER LIGA", int(_rank_filters["league_nat_id"]), func(nid: int):
				_rank_filters["league_nat_id"] = nid
				_rank_page = 0
				_rank_cache_dirty = true
				refresh()
			)
		"DIVISI":
			var div_opts := [[0, "SEMUA"], [1, "PERTAMA"], [2, "KEDUA"], [3, "KETIGA"]]
			return RankingOverlaysScript.open_option_grid_filter(host, "FILTER DIVISI", div_opts, int(_rank_filters["division"]), 4, func(d):
				_rank_filters["division"] = int(d)
				_rank_page = 0
				_rank_cache_dirty = true
				refresh()
			)
		"KLUB":
			var clb_opts := [["SEMUA", "SEMUA"], ["FREE", "TANPA KLUB"], ["MINE", "KLUB SAYA"]]
			return RankingOverlaysScript.open_option_grid_filter(host, "FILTER KLUB", clb_opts, str(_rank_filters["club_mode"]), 3, func(cm):
				_rank_filters["club_mode"] = str(cm)
				_rank_page = 0
				_rank_cache_dirty = true
				refresh()
			)
		_:
			return RankingOverlaysScript.open_search_name_overlay(host, str(_rank_filters.get("query", "")), func(q: String):
				_rank_filters["query"] = q
				_rank_page = 0
				_rank_cache_dirty = true
				refresh()
			)

func _filter_val_label(kind: String) -> String:
	match kind:
		"POS":
			var pl: Array = _rank_filters.get("positions", [])
			if pl.is_empty():
				return "SEMUA"
			if pl.size() <= 2:
				return ", ".join(PackedStringArray(pl))
			return "%s +%d" % [str(pl[0]), pl.size() - 1]
		"USIA":
			match str(_rank_filters.get("age", "SEMUA")):
				"U21": return "<=21 THN"
				"22_25": return "22-25 THN"
				"26_29": return "26-29 THN"
				"30_33": return "30-33 THN"
				"34P": return "34+ THN"
			return "SEMUA"
		"NILAI":
			match str(_rank_filters.get("val", "SEMUA")):
				"LT2": return "<2 M"
				"2_6": return "2-6 M"
				"6_15": return "6-15 M"
				"15_40": return "15-40 M"
				"40_80": return "40-80 M"
				"80P": return "80 M+"
			return "SEMUA"
		"NEGARA":
			var nid: int = int(_rank_filters.get("nat_id", -1))
			if nid >= 0 and nid < GameData.nations.size():
				return str(GameData.nations[nid]["name"]).to_upper()
			return "SEMUA"
		"LIGA":
			var lid: int = int(_rank_filters.get("league_nat_id", -1))
			if lid >= 0 and lid < GameData.nations.size():
				return str(GameData.nations[lid]["name"]).to_upper()
			return "SEMUA"
		"DIVISI":
			var dv: int = int(_rank_filters.get("division", 0))
			return ["SEMUA", "PERTAMA", "KEDUA", "KETIGA"][clampi(dv, 0, 3)]
		"KLUB":
			var cm: String = str(_rank_filters.get("club_mode", "SEMUA"))
			if cm == "FREE":
				return "TANPA KLUB"
			if cm == "MINE":
				return "KLUB SAYA"
			return "SEMUA"
	return "SEMUA"

func _make_rank_filter_tile(label_top: String, value_bot: String, is_active: bool, is_purple_accent: bool = false) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 42)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#131E34") if is_active else Color("#09111E")
	sb.border_color = Color("#7C5BD6") if (is_active and is_purple_accent) else (UITheme.ACCENT_CYAN if is_active else Color("#1A2A42"))
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(4)
	var sbh := sb.duplicate()
	sbh.bg_color = sb.bg_color.lightened(0.14)
	sbh.border_color = UITheme.BORDER_CYAN
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sbh)
	btn.add_theme_stylebox_override("pressed", sbh)
	btn.add_theme_stylebox_override("focus", sbh)

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 7
	vb.offset_right = -6
	vb.offset_top = 4
	vb.offset_bottom = -4
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 1)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(vb)

	var t_l := Label.new()
	t_l.text = label_top
	t_l.clip_text = true
	t_l.add_theme_font_size_override("font_size", 9)
	t_l.add_theme_color_override("font_color", Color("#7B91AC"))
	t_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(t_l)

	var v_l := Label.new()
	v_l.text = value_bot
	v_l.clip_text = true
	v_l.add_theme_font_override("font", UITheme.get_display_font())
	v_l.add_theme_font_size_override("font_size", 10)
	v_l.add_theme_color_override("font_color", Color("#C084FC") if (is_active and is_purple_accent) else (UITheme.ACCENT_CYAN if is_active else UITheme.TEXT_WHITE))
	v_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(v_l)
	return btn

func _get_sorted_nations_by_rank() -> Array[Dictionary]:
	var arr: Array[Dictionary] = []
	for nat in GameData.nations:
		arr.append(nat)
	arr.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var ra: int = int(a.get("world_rank", 99))
		var rb: int = int(b.get("world_rank", 99))
		if ra != rb:
			return ra < rb
		return float(a.get("total_coeff", 0.0)) > float(b.get("total_coeff", 0.0))
	)
	return arr

func _get_nation_euro_slot_breakdown(nat_id: int) -> Dictionary:
	var rules: Dictionary = CareerState.get_league_zone_rules(nat_id, 1, 20)
	var elite_end: int = int(rules.get("elite_end", 2))
	var eu_s: int = int(rules.get("europa_start", 3))
	var eu_e: int = int(rules.get("europa_end", 3))
	var ch_s: int = int(rules.get("challenge_start", 4))
	var ch_e: int = int(rules.get("challenge_end", 4))

	var elite_pills: Array[String] = []
	for r in range(1, elite_end + 1):
		elite_pills.append("ke-%d FL" % r)

	var europa_pills: Array[String] = ["PIALA FL"]
	if eu_s > 0 and eu_e >= eu_s:
		for r in range(eu_s, eu_e + 1):
			europa_pills.append("ke-%d FL" % r)

	var challenge_pills: Array[String] = []
	if ch_s > 0 and ch_e >= ch_s:
		for r in range(ch_s, ch_e + 1):
			challenge_pills.append("ke-%d PO" % r)

	return {
		"elite_count": elite_pills.size(),
		"europa_count": europa_pills.size(),
		"challenge_count": challenge_pills.size(),
		"elite_pills": elite_pills,
		"europa_pills": europa_pills,
		"challenge_pills": challenge_pills,
	}

func _make_euro_slot_pill(txt: String, bg_col: Color, bd_col: Color, txt_col: Color, bw: int = 0) -> PanelContainer:
	var pc := PanelContainer.new()
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = bd_col
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(3)
	sb.content_margin_left = 4
	sb.content_margin_right = 4
	sb.content_margin_top = 1
	sb.content_margin_bottom = 1
	pc.add_theme_stylebox_override("panel", sb)
	var l := Label.new()
	l.text = txt
	l.add_theme_font_override("font", UITheme.get_display_font())
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", txt_col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc.add_child(l)
	return pc

func _build_rank_nation_stats_sidebar(side_vb: VBoxContainer, sorted_nations: Array[Dictionary]) -> void:
	var my_club: Dictionary = CareerState.get_current_club()
	var my_nat_id: int = clampi(int(my_club.get("nation_id", 0)), 0, GameData.nations.size() - 1)
	if _rank_selected_nat_id < 0 or _rank_selected_nat_id >= GameData.nations.size():
		_rank_selected_nat_id = my_nat_id

	var sel_idx: int = 0
	for i in range(sorted_nations.size()):
		if int(sorted_nations[i]["id"]) == _rank_selected_nat_id:
			sel_idx = i
			break
	var nat: Dictionary = sorted_nations[sel_idx]
	var sel_nid: int = int(nat["id"])
	var disp_rank: int = sel_idx + 1
	var tot_nations: int = sorted_nations.size()
	var is_my_league: bool = (sel_nid == my_nat_id)
	var total_coeff: float = float(nat.get("total_coeff", 30.0))

	var card := PanelContainer.new()
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var csb := StyleBoxFlat.new()
	csb.bg_color = Color("#08101E")
	csb.border_color = Color("#182840")
	csb.set_border_width_all(1)
	csb.set_corner_radius_all(6)
	csb.content_margin_left = 10
	csb.content_margin_right = 10
	csb.content_margin_top = 8
	csb.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", csb)
	side_vb.add_child(card)

	var cvb := VBoxContainer.new()
	cvb.add_theme_constant_override("separation", 6)
	card.add_child(cvb)

	# Header: LIGAMU / NEGARA TERPILIH + Flag & Nation Name (Gambar 6!)
	var top_tag := Label.new()
	top_tag.text = "LIGAMU" if is_my_league else "NEGARA TERPILIH"
	top_tag.add_theme_font_size_override("font_size", 9)
	top_tag.add_theme_color_override("font_color", Color("#7B91AC"))
	cvb.add_child(top_tag)

	var nhb := HBoxContainer.new()
	nhb.add_theme_constant_override("separation", 7)
	cvb.add_child(nhb)
	var fl_c := CenterContainer.new()
	fl_c.add_child(UITheme.make_flag_rect(sel_nid, Vector2(24, 16)))
	nhb.add_child(fl_c)
	var n_lbl := Label.new()
	n_lbl.text = str(nat.get("name", "NEGARA")).to_upper()
	n_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	n_lbl.clip_text = true
	n_lbl.add_theme_font_override("font", UITheme.get_display_font())
	n_lbl.add_theme_font_size_override("font_size", 14)
	n_lbl.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	nhb.add_child(n_lbl)

	# Big Cyan Rank + DARI 55 on left | Big White Comma Coefficient on right
	var rk_hb := HBoxContainer.new()
	rk_hb.add_theme_constant_override("separation", 6)
	cvb.add_child(rk_hb)

	var rk_big := Label.new()
	rk_big.text = str(disp_rank)
	rk_big.add_theme_font_override("font", UITheme.get_display_font())
	rk_big.add_theme_font_size_override("font_size", 24)
	rk_big.add_theme_color_override("font_color", Color("#38BDF8"))
	rk_hb.add_child(rk_big)

	var dari_l := Label.new()
	dari_l.text = "DARI %d" % tot_nations
	dari_l.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	dari_l.add_theme_font_size_override("font_size", 9)
	dari_l.add_theme_color_override("font_color", Color("#7B91AC"))
	rk_hb.add_child(dari_l)

	var cf_big := Label.new()
	cf_big.text = RankingOverlaysScript.format_coeff_comma(total_coeff, 3)
	cf_big.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cf_big.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cf_big.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cf_big.add_theme_font_override("font", UITheme.get_display_font())
	cf_big.add_theme_font_size_override("font_size", 17)
	cf_big.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	rk_hb.add_child(cf_big)

	# 5-Year Coefficient Vertical Purple Bar Chart (Gambar 6!)
	var cal_yr: int = int(CareerState.career.get("careerMeta", {}).get("seasonCalendarYear", 2026)) if CareerState.has_active_career else 2026
	var chart: Control = RankingOverlaysScript.make_nation_coeff_chart(nat.get("coeff_5y", []), cal_yr - 4, cal_yr)
	cvb.add_child(chart)

	# SLOT Qualification Breakdown (Blue Elite / Orange Europa / Cyan Challenge)
	var slot_hdr := Label.new()
	slot_hdr.text = "SLOT %02d/%02d" % [(cal_yr + 1) % 100, (cal_yr + 2) % 100]
	slot_hdr.add_theme_font_size_override("font_size", 9)
	slot_hdr.add_theme_color_override("font_color", Color("#7B91AC"))
	cvb.add_child(slot_hdr)

	var sb_data: Dictionary = _get_nation_euro_slot_breakdown(sel_nid)
	for row_def in [
		["ELITE", sb_data["elite_pills"], Color("#2563EB"), Color.TRANSPARENT, UITheme.TEXT_WHITE, 0],
		["EUROPA", sb_data["europa_pills"], Color("#D97706"), Color.TRANSPARENT, Color("#0F172A"), 0],
		["CHALLENGE", sb_data["challenge_pills"], Color("#0B2630"), Color("#22D3EE"), Color("#5EEAD4"), 1],
	]:
		var pills_arr: Array = row_def[1]
		if pills_arr.is_empty():
			continue
		var srhb := HBoxContainer.new()
		srhb.add_theme_constant_override("separation", 5)
		cvb.add_child(srhb)
		var ic_c := CenterContainer.new()
		ic_c.custom_minimum_size = Vector2(15, 15)
		ic_c.add_child(RankingOverlaysScript.make_cup_micro_icon(str(row_def[0]), Vector2(14, 14)))
		srhb.add_child(ic_c)

		var flow := HFlowContainer.new()
		flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		flow.add_theme_constant_override("h_separation", 3)
		flow.add_theme_constant_override("v_separation", 3)
		srhb.add_child(flow)
		for ptxt in pills_arr:
			flow.add_child(_make_euro_slot_pill(str(ptxt), row_def[2], row_def[3], row_def[4], int(row_def[5])))

	# Point Gap Line (e.g. "8,300 KE ke-1 • 9,400 KE ke-3")
	var gap_parts: Array[String] = []
	if sel_idx > 0:
		var above_c: float = float(sorted_nations[sel_idx - 1].get("total_coeff", total_coeff))
		var diff_up: float = maxf(0.0, above_c - total_coeff)
		gap_parts.append("%s KE ke-%d" % [RankingOverlaysScript.format_coeff_comma(diff_up, 3), disp_rank - 1])
	if sel_idx + 1 < tot_nations:
		var below_c: float = float(sorted_nations[sel_idx + 1].get("total_coeff", total_coeff))
		var diff_dn: float = maxf(0.0, total_coeff - below_c)
		gap_parts.append("%s KE ke-%d" % [RankingOverlaysScript.format_coeff_comma(diff_dn, 3), disp_rank + 1])

	var gap_l := Label.new()
	gap_l.text = "  •  ".join(PackedStringArray(gap_parts))
	gap_l.clip_text = true
	gap_l.add_theme_font_size_override("font_size", 9)
	gap_l.add_theme_color_override("font_color", Color("#7B91AC"))
	cvb.add_child(gap_l)

	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cvb.add_child(sp)

	# Bottom Club Card: User's club if own nation, else Top Div 1 club of selected nation
	var feat_club: Dictionary = my_club
	if not is_my_league:
		var d1_clubs: Array[Dictionary] = GameData.get_clubs_in_division(sel_nid, 1)
		if not d1_clubs.is_empty():
			feat_club = d1_clubs[0]
			for dc in d1_clubs:
				if int(dc.get("ovr", 0)) > int(feat_club.get("ovr", 0)):
					feat_club = dc

	var club_box := PanelContainer.new()
	var clb_sb := StyleBoxFlat.new()
	clb_sb.bg_color = Color("#050A14")
	clb_sb.border_color = Color("#1B2D48")
	clb_sb.set_border_width_all(1)
	clb_sb.set_corner_radius_all(4)
	clb_sb.content_margin_left = 8
	clb_sb.content_margin_right = 8
	clb_sb.content_margin_top = 5
	clb_sb.content_margin_bottom = 5
	club_box.add_theme_stylebox_override("panel", clb_sb)
	cvb.add_child(club_box)

	var chb := HBoxContainer.new()
	chb.add_theme_constant_override("separation", 8)
	club_box.add_child(chb)

	var cr_c := CenterContainer.new()
	var cr := ClubCrest.new()
	cr.custom_minimum_size = Vector2(22, 22)
	cr.set_club(int(feat_club.get("id", 0)))
	cr_c.add_child(cr)
	chb.add_child(cr_c)

	var cinfo := VBoxContainer.new()
	cinfo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cinfo.add_theme_constant_override("separation", 1)
	chb.add_child(cinfo)

	var cnm := Label.new()
	cnm.text = str(feat_club.get("name", "KLUB")).to_upper()
	cnm.clip_text = true
	cnm.add_theme_font_override("font", UITheme.get_display_font())
	cnm.add_theme_font_size_override("font_size", 10)
	cnm.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	cinfo.add_child(cnm)

	var club_ovr: float = float(feat_club.get("ovr", 62))
	var club_div: int = int(feat_club.get("division", 3))
	var club_coeff: float = maxf(2.500, snappedf(total_coeff * (0.28 + (club_ovr - 52.0) / 85.0) * (1.0 if club_div == 1 else (0.55 if club_div == 2 else 0.30)), 0.001))
	var ccf := Label.new()
	ccf.text = RankingOverlaysScript.format_coeff_comma(club_coeff, 3)
	ccf.add_theme_font_override("font", UITheme.get_display_font())
	ccf.add_theme_font_size_override("font_size", 11)
	ccf.add_theme_color_override("font_color", Color("#38BDF8"))
	cinfo.add_child(ccf)

func _make_rank_nation_row(rank_num: int, nat: Dictionary, is_selected: bool, is_my_nat: bool, max_yr_val: float) -> Button:
	var nid: int = int(nat["id"])
	var btn := Button.new()
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, 48)
	var sb := StyleBoxFlat.new()
	if is_selected:
		sb.bg_color = Color("#1A1F3E")
		sb.border_color = Color("#5C66B8")
	elif is_my_nat:
		sb.bg_color = Color("#0F1A30")
		sb.border_color = Color("#2A4369")
	else:
		sb.bg_color = Color("#09111F")
		sb.border_color = Color("#152338")
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	var sbh := sb.duplicate()
	sbh.bg_color = sb.bg_color.lightened(0.12)
	sbh.border_color = UITheme.ACCENT_CYAN
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sbh)
	btn.add_theme_stylebox_override("pressed", sbh)
	btn.add_theme_stylebox_override("focus", sbh)

	var hb := HBoxContainer.new()
	hb.set_anchors_preset(Control.PRESET_FULL_RECT)
	hb.offset_left = 10
	hb.offset_right = -12
	hb.add_theme_constant_override("separation", 10)
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(hb)

	# 1. Rank Number
	var rkl := Label.new()
	rkl.text = str(rank_num)
	rkl.custom_minimum_size = Vector2(22, 0)
	rkl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rkl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rkl.add_theme_font_override("font", UITheme.get_display_font())
	rkl.add_theme_font_size_override("font_size", 12)
	rkl.add_theme_color_override("font_color", Color("#93C5FD") if is_selected else Color("#CBD5E1"))
	rkl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(rkl)

	# 2. Nation Flag
	var fc := CenterContainer.new()
	fc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fc.add_child(UITheme.make_flag_rect(nid, Vector2(24, 16)))
	hb.add_child(fc)

	# 3. Nation Name + Compact Euro Slot Counts (Elite blue, Europa orange, Challenge cyan — Gambar 7!)
	var mid_vb := VBoxContainer.new()
	mid_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid_vb.alignment = BoxContainer.ALIGNMENT_CENTER
	mid_vb.add_theme_constant_override("separation", 2)
	mid_vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(mid_vb)

	var nl := Label.new()
	nl.text = str(nat.get("name", "NEGARA")).to_upper()
	nl.clip_text = true
	nl.add_theme_font_override("font", UITheme.get_display_font())
	nl.add_theme_font_size_override("font_size", 12)
	nl.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mid_vb.add_child(nl)

	var sb_d: Dictionary = _get_nation_euro_slot_breakdown(nid)
	var slots_hb := HBoxContainer.new()
	slots_hb.add_theme_constant_override("separation", 8)
	slots_hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mid_vb.add_child(slots_hb)
	for sd in [
		["ELITE", int(sb_d["elite_count"]), Color("#4F86FF")],
		["EUROPA", int(sb_d["europa_count"]), Color("#F59E0B")],
		["CHALLENGE", int(sb_d["challenge_count"]), Color("#22D3EE")],
	]:
		var shb := HBoxContainer.new()
		shb.add_theme_constant_override("separation", 3)
		shb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ic := CenterContainer.new()
		ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ic.add_child(RankingOverlaysScript.make_cup_micro_icon(str(sd[0]), Vector2(11, 11)))
		shb.add_child(ic)
		var vl := Label.new()
		vl.text = str(int(sd[1]))
		vl.add_theme_font_override("font", UITheme.get_display_font())
		vl.add_theme_font_size_override("font_size", 10)
		vl.add_theme_color_override("font_color", sd[2])
		vl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shb.add_child(vl)
		slots_hb.add_child(shb)

	# 4. 5-Year Mini Purple Sparkline (Gambar 7!)
	var sp_c := CenterContainer.new()
	sp_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sp_c.add_child(RankingOverlaysScript.make_nation_mini_sparkline(nat.get("coeff_5y", []), max_yr_val))
	hb.add_child(sp_c)

	# 5. Bold White Comma Total Coefficient (Gambar 7!)
	var cl := Label.new()
	cl.text = RankingOverlaysScript.format_coeff_comma(float(nat.get("total_coeff", 0.0)), 3)
	cl.custom_minimum_size = Vector2(78, 0)
	cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cl.add_theme_font_override("font", UITheme.get_display_font())
	cl.add_theme_font_size_override("font_size", 13)
	cl.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	cl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(cl)

	btn.pressed.connect(func():
		AudioSynth.play_click()
		_rank_selected_nat_id = nid
		refresh()
	)
	return btn

func _render_ranking() -> void:
	var cols := HBoxContainer.new()
	cols.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.add_theme_constant_override("separation", 12)
	_comp_root.add_child(cols)

	# --------------------------------------------------------------------------
	# LEFT SIDEBAR:
	# - PEMAIN/PELATIH: Mini sub-tabs + TEMPATMU + 7 Filters + CARI
	# - NEGARA (Gambar 6): Mini sub-tabs + Nation Coefficient & Slot Stats Card (NO TEMPATMU/FILTERS!)
	# --------------------------------------------------------------------------
	var side_vb := VBoxContainer.new()
	side_vb.custom_minimum_size = Vector2(276 if _rank_tab == "NEGARA" else 236, 0)
	side_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side_vb.add_theme_constant_override("separation", 6)
	cols.add_child(side_vb)

	# Mini sub-tabs
	var thb := HBoxContainer.new()
	thb.add_theme_constant_override("separation", 4)
	side_vb.add_child(thb)
	for rt in ["PEMAIN", "PELATIH", "NEGARA"]:
		var is_rt: bool = (_rank_tab == rt)
		var b := Button.new()
		b.text = rt
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 28)
		var rsb := StyleBoxFlat.new()
		rsb.bg_color = Color("#13233C") if is_rt else Color("#0A1322")
		rsb.border_color = UITheme.ACCENT_CYAN if is_rt else Color("#182840")
		rsb.set_border_width_all(1)
		rsb.border_width_bottom = 2 if is_rt else 1
		rsb.set_corner_radius_all(4)
		var rsbh := rsb.duplicate()
		rsbh.bg_color = rsb.bg_color.lightened(0.12)
		b.add_theme_stylebox_override("normal", rsb)
		b.add_theme_stylebox_override("hover", rsbh)
		b.add_theme_stylebox_override("pressed", rsbh)
		b.add_theme_stylebox_override("focus", rsbh)
		b.add_theme_font_override("font", UITheme.get_display_font())
		b.add_theme_font_size_override("font_size", 9)
		b.add_theme_color_override("font_color", UITheme.TEXT_WHITE if is_rt else Color("#8EA3BC"))
		b.pressed.connect(func():
			AudioSynth.play_click()
			_rank_tab = rt
			_rank_page = 0
			refresh()
		)
		thb.add_child(b)

	var sorted_nations: Array[Dictionary] = []
	if _rank_tab == "NEGARA":
		sorted_nations = _get_sorted_nations_by_rank()
		_build_rank_nation_stats_sidebar(side_vb, sorted_nations)
	else:
		# TEMPATMU Card (Hex OVR + ke-XXXXX + DARI 21.289)
		var my_ovr: int = int(CareerState.career["playerProfile"]["ovr"])
		var my_rank: int = CareerState.get_player_global_rank(my_ovr)
		var me_card := PanelContainer.new()
		me_card.custom_minimum_size = Vector2(0, 58)
		var msb := StyleBoxFlat.new()
		msb.bg_color = Color("#091322")
		msb.border_color = Color("#1A2D48")
		msb.set_border_width_all(1)
		msb.set_corner_radius_all(6)
		msb.content_margin_left = 10
		msb.content_margin_right = 10
		msb.content_margin_top = 6
		msb.content_margin_bottom = 6
		me_card.add_theme_stylebox_override("panel", msb)
		side_vb.add_child(me_card)

		var me_hb := HBoxContainer.new()
		me_hb.add_theme_constant_override("separation", 10)
		me_card.add_child(me_hb)
		var hex_c := CenterContainer.new()
		hex_c.add_child(TimnasOverlaysScript.make_hex_ovr(my_ovr, Vector2(36, 36)))
		me_hb.add_child(hex_c)

		var me_vb := VBoxContainer.new()
		me_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		me_vb.alignment = BoxContainer.ALIGNMENT_CENTER
		me_vb.add_theme_constant_override("separation", 0)
		me_hb.add_child(me_vb)
		var ml1 := Label.new()
		ml1.text = "TEMPATMU"
		ml1.add_theme_font_size_override("font_size", 9)
		ml1.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
		var ml2 := Label.new()
		ml2.text = "ke-%d" % my_rank
		ml2.add_theme_font_override("font", UITheme.get_display_font())
		ml2.add_theme_font_size_override("font_size", 16)
		ml2.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
		var ml3 := Label.new()
		ml3.text = "DARI %s" % RankingOverlaysScript.format_dots(CareerState.TOTAL_WORLD_PLAYERS)
		ml3.add_theme_font_size_override("font_size", 9)
		ml3.add_theme_color_override("font_color", Color("#7B91AC"))
		me_vb.add_child(ml1)
		me_vb.add_child(ml2)
		me_vb.add_child(ml3)

		# 2-Column Filter Tile Grid (POS, USIA, NILAI, NEGARA, LIGA, DIVISI, KLUB, SEMUA reset!)
		var fgrid := GridContainer.new()
		fgrid.columns = 2
		fgrid.add_theme_constant_override("h_separation", 6)
		fgrid.add_theme_constant_override("v_separation", 5)
		side_vb.add_child(fgrid)

		var filter_defs := [
			["POS", "POS", not (_rank_filters.get("positions", []) as Array).is_empty(), false],
			["USIA", "USIA", str(_rank_filters.get("age", "SEMUA")) != "SEMUA", false],
			["NILAI", "NILAI", str(_rank_filters.get("val", "SEMUA")) != "SEMUA", false],
			["NEGARA", "NEGARA", int(_rank_filters.get("nat_id", -1)) >= 0, false],
			["LIGA", "LIGA", int(_rank_filters.get("league_nat_id", -1)) >= 0, false],
			["DIVISI", "DIVISI", int(_rank_filters.get("division", 0)) > 0, false],
			["KLUB", "KLUB", str(_rank_filters.get("club_mode", "SEMUA")) != "SEMUA", true],
		]
		for fd in filter_defs:
			var fk: String = str(fd[0])
			var tile: Button = _make_rank_filter_tile(str(fd[1]), _filter_val_label(fk), bool(fd[2]), bool(fd[3]))
			tile.disabled = (_rank_tab != "PEMAIN")
			tile.pressed.connect(func():
				AudioSynth.play_click()
				open_rank_filter_modal(fk)
			)
			fgrid.add_child(tile)

		# Slot 8: SEMUA Reset Filter Button
		var has_flt: bool = _has_any_rank_filter()
		var rst_b := Button.new()
		rst_b.text = "SEMUA"
		rst_b.custom_minimum_size = Vector2(0, 42)
		rst_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rst_b.disabled = (not has_flt or _rank_tab != "PEMAIN")
		var rst_sb := StyleBoxFlat.new()
		rst_sb.bg_color = Color("#1B243C") if has_flt else Color("#08101C")
		rst_sb.border_color = UITheme.ACCENT_CYAN if has_flt else Color("#152236")
		rst_sb.set_border_width_all(1)
		rst_sb.set_corner_radius_all(4)
		rst_b.add_theme_stylebox_override("normal", rst_sb)
		rst_b.add_theme_stylebox_override("hover", rst_sb)
		rst_b.add_theme_font_override("font", UITheme.get_display_font())
		rst_b.add_theme_font_size_override("font_size", 10)
		rst_b.add_theme_color_override("font_color", UITheme.TEXT_WHITE if has_flt else Color("#475B75"))
		rst_b.pressed.connect(func():
			AudioSynth.play_click()
			_reset_rank_filters()
			refresh()
		)
		fgrid.add_child(rst_b)

		var side_sp := Control.new()
		side_sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
		side_vb.add_child(side_sp)

		# Bottom Purple CARI Button
		var cur_q: String = str(_rank_filters.get("query", ""))
		var cari_b := Button.new()
		cari_b.text = ("◎  CARI: %s" % cur_q.left(10).to_upper()) if cur_q != "" else "◎  CARI"
		cari_b.custom_minimum_size = Vector2(0, 38)
		cari_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cari_b.disabled = (_rank_tab != "PEMAIN")
		var csb := StyleBoxFlat.new()
		csb.bg_color = Color("#4B3675")
		csb.border_color = Color("#8869C6")
		csb.set_border_width_all(1)
		csb.set_corner_radius_all(5)
		var csbh := csb.duplicate()
		csbh.bg_color = Color("#5D4490")
		csbh.border_color = UITheme.ACCENT_CYAN
		cari_b.add_theme_stylebox_override("normal", csb)
		cari_b.add_theme_stylebox_override("hover", csbh)
		cari_b.add_theme_stylebox_override("pressed", csbh)
		cari_b.add_theme_stylebox_override("focus", csbh)
		cari_b.add_theme_font_override("font", UITheme.get_display_font())
		cari_b.add_theme_font_size_override("font_size", 11)
		cari_b.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
		cari_b.pressed.connect(func():
			AudioSynth.play_click()
			open_rank_filter_modal("CARI")
		)
		side_vb.add_child(cari_b)

	# --------------------------------------------------------------------------
	# RIGHT AREA: 2x5 Player Cards (PEMAIN) OR PELATIH List OR Upgraded NEGARA List (Gambar 7)
	# --------------------------------------------------------------------------
	var right_vb := VBoxContainer.new()
	right_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vb.add_theme_constant_override("separation", 6)
	cols.add_child(right_vb)

	if _rank_tab == "PEMAIN":
		var indices: PackedInt32Array = _get_filtered_rank_indices()
		var total_n: int = indices.size()
		var page_sz: int = 10
		var max_page: int = maxi(0, int((maxi(1, total_n) - 1) / page_sz))
		_rank_page = clampi(_rank_page, 0, max_page)
		var start_i: int = _rank_page * page_sz
		var end_i: int = mini(start_i + page_sz, total_n)

		# Header strip: "1-10/21.289" + compact < > pager
		var hdr_hb := HBoxContainer.new()
		hdr_hb.add_theme_constant_override("separation", 6)
		right_vb.add_child(hdr_hb)
		var cnt_l := Label.new()
		cnt_l.text = ("%d-%d/%s" % [start_i + 1, end_i, RankingOverlaysScript.format_dots(total_n)]) if total_n > 0 else "0/0 (TIDAK ADA HASIL)"
		cnt_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cnt_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cnt_l.add_theme_font_size_override("font_size", 11)
		cnt_l.add_theme_color_override("font_color", Color("#9FB3C8"))
		hdr_hb.add_child(cnt_l)

		var prev_b := Button.new()
		prev_b.text = "<"
		prev_b.custom_minimum_size = Vector2(34, 24)
		prev_b.disabled = (_rank_page <= 0)
		UITheme.style_btn(prev_b, Color("#0E1A2E"), Color("#243957"), 11)
		prev_b.pressed.connect(func(): AudioSynth.play_click(); _rank_page = maxi(0, _rank_page - 1); refresh())
		var next_b := Button.new()
		next_b.text = ">"
		next_b.custom_minimum_size = Vector2(34, 24)
		next_b.disabled = (end_i >= total_n)
		UITheme.style_btn(next_b, Color("#0E1A2E"), Color("#243957"), 11)
		next_b.pressed.connect(func(): AudioSynth.play_click(); _rank_page += 1; refresh())
		hdr_hb.add_child(prev_b)
		hdr_hb.add_child(next_b)

		if total_n == 0:
			var empty_c := CenterContainer.new()
			empty_c.size_flags_vertical = Control.SIZE_EXPAND_FILL
			var el := Label.new()
			el.text = "Tidak ada pemain yang cocok dengan kombinasi filter saat ini.\nTekan SEMUA untuk reset filter."
			el.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			el.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
			empty_c.add_child(el)
			right_vb.add_child(empty_c)
			return

		var pgrid := GridContainer.new()
		pgrid.columns = 2
		pgrid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pgrid.size_flags_vertical = Control.SIZE_EXPAND_FILL
		pgrid.add_theme_constant_override("h_separation", 8)
		pgrid.add_theme_constant_override("v_separation", 6)
		right_vb.add_child(pgrid)

		for r in range(start_i, end_i):
			var idx: int = indices[r]
			pgrid.add_child(_make_rank_player_card(r + 1, idx))

	elif _rank_tab == "PELATIH":
		var tot_c: int = GameData.coaches.size()
		var page_sz: int = 16
		var start_i: int = _rank_page * page_sz
		var end_i: int = mini(start_i + page_sz, tot_c)
		_add_compact_rank_pager(right_vb, start_i, end_i, tot_c)
		var sc := ScrollContainer.new()
		sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		right_vb.add_child(sc)
		var lvb := VBoxContainer.new()
		lvb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lvb.add_theme_constant_override("separation", 4)
		sc.add_child(lvb)
		for r in range(start_i, end_i):
			var ch: Dictionary = GameData.coaches[r]
			var row := PanelContainer.new()
			row.add_theme_stylebox_override("panel", UITheme.make_box(Color("#0A1322"), Color("#1A2B45"), 1, 4))
			lvb.add_child(row)
			var hb := HBoxContainer.new()
			hb.add_theme_constant_override("separation", 8)
			row.add_child(hb)
			var rl := Label.new()
			rl.text = "%d. %s (%s) • %s" % [r + 1, str(ch["name"]), "★".repeat(int(ch["stars"])), str(GameData.clubs[int(ch["club_id"])]["name"])]
			rl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			rl.clip_text = true
			rl.add_theme_font_size_override("font_size", 12)
			hb.add_child(rl)

	else:
		# Sorted 1..55 Nations List with Euro Slot Counts + 5-Bar Mini Sparkline + Comma Coeff (Gambar 7!)
		var my_nat_id: int = int(CareerState.get_current_club().get("nation_id", 0))
		var max_yr_v: float = 24.0
		for nat in sorted_nations:
			for yv in nat.get("coeff_5y", []):
				max_yr_v = maxf(max_yr_v, float(yv))

		var sc := ScrollContainer.new()
		sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		right_vb.add_child(sc)
		var lvb := VBoxContainer.new()
		lvb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lvb.add_theme_constant_override("separation", 5)
		sc.add_child(lvb)
		for ni in range(sorted_nations.size()):
			var nat: Dictionary = sorted_nations[ni]
			var nid: int = int(nat["id"])
			lvb.add_child(_make_rank_nation_row(ni + 1, nat, nid == _rank_selected_nat_id, nid == my_nat_id, max_yr_v))

func _add_compact_rank_pager(parent_vb: VBoxContainer, start_i: int, end_i: int, total_n: int) -> void:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	parent_vb.add_child(hb)
	var lbl := Label.new()
	lbl.text = "%d-%d/%s" % [start_i + 1, end_i, RankingOverlaysScript.format_dots(total_n)]
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color("#9FB3C8"))
	hb.add_child(lbl)
	var pb := Button.new()
	pb.text = "<"
	pb.custom_minimum_size = Vector2(34, 24)
	pb.disabled = (_rank_page <= 0)
	UITheme.style_btn(pb, Color("#0E1A2E"), Color("#243957"), 11)
	pb.pressed.connect(func(): AudioSynth.play_click(); _rank_page = maxi(0, _rank_page - 1); refresh())
	var nb := Button.new()
	nb.text = ">"
	nb.custom_minimum_size = Vector2(34, 24)
	nb.disabled = (end_i >= total_n)
	UITheme.style_btn(nb, Color("#0E1A2E"), Color("#243957"), 11)
	nb.pressed.connect(func(): AudioSynth.play_click(); _rank_page += 1; refresh())
	hb.add_child(pb)
	hb.add_child(nb)

func _make_rank_player_card(display_rank: int, wp_idx: int) -> Button:
	var btn := Button.new()
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, 62)
	btn.clip_contents = true
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#0A1322")
	sb.border_color = Color("#1A2A42")
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	var sbh := sb.duplicate()
	sbh.bg_color = Color("#12233B")
	sbh.border_color = UITheme.ACCENT_CYAN
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sbh)
	btn.add_theme_stylebox_override("pressed", sbh)
	btn.add_theme_stylebox_override("focus", sbh)

	var hb := HBoxContainer.new()
	hb.set_anchors_preset(Control.PRESET_FULL_RECT)
	hb.offset_left = 8
	hb.offset_right = -8
	hb.offset_top = 4
	hb.offset_bottom = -4
	hb.add_theme_constant_override("separation", 7)
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(hb)

	# Rank number
	var rkl := Label.new()
	rkl.text = str(display_rank)
	rkl.custom_minimum_size = Vector2(24, 0)
	rkl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rkl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	rkl.add_theme_font_override("font", UITheme.get_display_font())
	rkl.add_theme_font_size_override("font_size", 12)
	rkl.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	rkl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(rkl)

	# Flag
	var fl_c := CenterContainer.new()
	fl_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fl_c.add_child(UITheme.make_flag_rect(int(CareerState.wp_nat[wp_idx]), Vector2(20, 14)))
	hb.add_child(fl_c)

	# Middle-left: Name + Colored Position Pills + Gold Value
	var info_vb := VBoxContainer.new()
	info_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vb.alignment = BoxContainer.ALIGNMENT_CENTER
	info_vb.add_theme_constant_override("separation", 2)
	info_vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(info_vb)

	var nm_l := Label.new()
	nm_l.text = CareerState.wp_name[wp_idx]
	nm_l.clip_text = true
	nm_l.add_theme_font_override("font", UITheme.get_display_font())
	nm_l.add_theme_font_size_override("font_size", 11)
	nm_l.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	nm_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_vb.add_child(nm_l)

	var pos_hb := HBoxContainer.new()
	pos_hb.add_theme_constant_override("separation", 3)
	pos_hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for ps in CareerState.get_world_player_positions(wp_idx):
		pos_hb.add_child(RankingOverlaysScript.make_pos_pill(ps, 8))
	info_vb.add_child(pos_hb)

	var val_l := Label.new()
	val_l.text = RankingOverlaysScript.format_val_m(int(CareerState.wp_val[wp_idx]))
	val_l.add_theme_font_override("font", UITheme.get_display_font())
	val_l.add_theme_font_size_override("font_size", 10)
	val_l.add_theme_color_override("font_color", Color("#E8B931"))
	val_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_vb.add_child(val_l)

	# Middle-right: Club Crest + Code (or gray shield TAN for free agents!) + Age
	var meta_vb := VBoxContainer.new()
	meta_vb.custom_minimum_size = Vector2(64, 0)
	meta_vb.alignment = BoxContainer.ALIGNMENT_CENTER
	meta_vb.add_theme_constant_override("separation", 4)
	meta_vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(meta_vb)

	var clb_hb := HBoxContainer.new()
	clb_hb.alignment = BoxContainer.ALIGNMENT_END
	clb_hb.add_theme_constant_override("separation", 4)
	clb_hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cid: int = int(CareerState.wp_club[wp_idx])
	var is_fa: bool = (cid < 0 or cid >= GameData.clubs.size())
	var cr_c := CenterContainer.new()
	cr_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if is_fa:
		cr_c.add_child(RankingOverlaysScript.make_free_agent_shield(Vector2(14, 14)))
	else:
		var cr := ClubCrest.new()
		cr.custom_minimum_size = Vector2(14, 14)
		cr.set_club(cid)
		cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cr_c.add_child(cr)
	clb_hb.add_child(cr_c)
	var cc_l := Label.new()
	cc_l.text = "TAN" if is_fa else str(GameData.clubs[cid].get("code", "CLB")).left(3).to_upper()
	cc_l.add_theme_font_size_override("font_size", 10)
	cc_l.add_theme_color_override("font_color", Color("#94A7BD"))
	cc_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clb_hb.add_child(cc_l)
	meta_vb.add_child(clb_hb)

	var age_l := Label.new()
	age_l.text = "%d TAHUN" % int(CareerState.wp_age[wp_idx])
	age_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	age_l.add_theme_font_size_override("font_size", 9)
	age_l.add_theme_color_override("font_color", Color("#7B91AC"))
	age_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meta_vb.add_child(age_l)

	# Far Right: 5-Tier Hexagon OVR Badge
	var ovr_c := CenterContainer.new()
	ovr_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ovr_c.add_child(TimnasOverlaysScript.make_hex_ovr(int(CareerState.wp_ovr[wp_idx]), Vector2(34, 34)))
	hb.add_child(ovr_c)

	var target_idx: int = wp_idx
	btn.pressed.connect(func():
		AudioSynth.play_click()
		open_rank_player_detail(target_idx)
	)
	return btn

func _render_berita() -> void:
	var ch_hb := HBoxContainer.new()
	ch_hb.add_theme_constant_override("separation", 4)
	_body.add_child(ch_hb)
	for ch in ["KLUB", "LIGA", "DUNIA", "SOSMED", "PESAN"]:
		var b := Button.new()
		b.text = ch
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UITheme.style_btn(b, Color("#173B66") if _news_channel == ch else Color("#0B1626"), UITheme.BORDER_CYAN if _news_channel == ch else UITheme.BORDER_STEEL, 10)
		b.pressed.connect(func(): AudioSynth.play_click(); _news_channel = ch; refresh())
		ch_hb.add_child(b)

	var fol := Label.new()
	fol.text = "▸ MEDSOS • PENGIKUT: %s" % UITheme.format_cash(int(CareerState.career["stats"]["followers"])).replace("$ ", "")
	fol.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	_body.add_child(fol)

	for item in CareerState.career.get("news", []):
		if _news_channel != "PESAN" and item["channel"] != _news_channel and _news_channel != "DUNIA":
			continue
		var card := PanelContainer.new()
		_body.add_child(card)
		var l := Label.new()
		l.text = "[MUSIM %d • %s] %s" % [int(item["season"]), item["channel"], item["text"]]
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_child(l)
