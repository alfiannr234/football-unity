extends CanvasLayer

const GROUPS: Array[Array] = [
	["KIPER", ["GK"]],
	["BEK", ["CB", "LB", "RB", "LWB", "RWB"]],
	["GELANDANG", ["CM", "CDM", "CAM", "LM", "RM", "MF", "DM", "AM"]],
	["PENYERANG", ["ST", "CF", "LW", "RW", "SS", "FW"]],
]

var _root: Control
var _home_btn: Button
var _away_btn: Button
var _rows_vb: VBoxContainer
var _detail_layer: Control

var _home_club: Dictionary = {}
var _away_club: Dictionary = {}
var _home_sq: Dictionary = {}
var _away_sq: Dictionary = {}
var _sel_side: int = 0

func _init() -> void:
	layer = 20

func _ready() -> void:
	_load_teams()
	_build()
	_render_squad()

func _load_teams() -> void:
	var fix: Dictionary = CareerState.get_current_fixture()
	var my_cid: int = int(CareerState.career.get("playerProfile", {}).get("clubId", 0))
	var opp_cid: int = clampi(int(fix.get("opp_club_id", 1)), 0, maxi(0, GameData.clubs.size() - 1))
	_home_club = CareerState.get_current_club().duplicate()
	_away_club = (GameData.clubs[opp_cid] if opp_cid < GameData.clubs.size() else _home_club).duplicate()
	var user_is_home: bool = bool(fix.get("is_home", true))
	var left_c: Dictionary = _home_club if user_is_home else _away_club
	var right_c: Dictionary = _away_club if user_is_home else _home_club
	var my_kit: Dictionary = CareerState.get_selected_match_kit(user_is_home, left_c, right_c)
	var opp_kit: Dictionary = CareerState.get_selected_match_kit(not user_is_home, left_c, right_c)
	for kk in ["primary", "secondary", "shorts", "pattern"]:
		if my_kit.has(kk):
			_home_club[kk] = my_kit[kk]
		if opp_kit.has(kk):
			_away_club[kk] = opp_kit[kk]

	_home_sq = CareerState.career.get("clubSquad", {})
	if _home_sq.is_empty() or _home_sq.get("starters", []).is_empty():
		var p: Dictionary = CareerState.career.get("playerProfile", {})
		_home_sq = CareerState._build_club_squad(my_cid, str(p.get("name", "PEMAIN")), str(p.get("position", "ST")), p.get("appearance", {}))

	var ai_ln: String = GameData.LAST_NAMES[(opp_cid * 11 + 10) % GameData.LAST_NAMES.size()]
	_away_sq = CareerState._build_club_squad(opp_cid, ai_ln, "ST", {"shirt_num": 9})
	var opp_base_ovr: int = int(_away_club.get("ovr", 60))
	for pl in _away_sq.get("starters", []):
		pl["is_user"] = false
		if str(pl.get("id", "")) == "sq_10":
			pl["ovr"] = clampi(opp_base_ovr + 1, 46, 92)
			pl["age"] = 24
			pl["seed"] = opp_cid * 100 + 10

func _build() -> void:
	_root = Control.new()
	_root.theme = UITheme.build_theme()
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var backdrop := ColorRect.new()
	backdrop.color = Color(0.02, 0.05, 0.11, 0.90)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	_root.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var frame := PanelContainer.new()
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.add_theme_stylebox_override("panel", UITheme.make_box(Color("#081529"), Color("#38BDF8"), 2, 8))
	margin.add_child(frame)

	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 8)
	frame.add_child(vb)

	# Header bar
	var hdr := HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 10)
	vb.add_child(hdr)

	var back_btn := Button.new()
	back_btn.text = "<- BALIK"
	back_btn.custom_minimum_size = Vector2(104, 34)
	UITheme.style_btn(back_btn, Color("#13263E"), Color("#64748B"), 12)
	back_btn.pressed.connect(queue_free)
	hdr.add_child(back_btn)

	var title := Label.new()
	title.text = "LINE-UP PERTANDINGAN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_override("font", UITheme.get_display_font())
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color.WHITE)
	hdr.add_child(title)

	var close_x := Button.new()
	close_x.text = "TUTUP"
	close_x.custom_minimum_size = Vector2(104, 34)
	UITheme.style_btn(close_x, Color("#2A1520"), Color("#FB7185"), 12)
	close_x.pressed.connect(queue_free)
	hdr.add_child(close_x)

	# Team switcher strip
	var vs_hb := HBoxContainer.new()
	vs_hb.add_theme_constant_override("separation", 10)
	vb.add_child(vs_hb)

	_home_btn = _make_team_tab(_home_club, _home_sq, 0, true)
	vs_hb.add_child(_home_btn)

	var vs_lbl := Label.new()
	vs_lbl.text = "VS"
	vs_lbl.custom_minimum_size = Vector2(36, 0)
	vs_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vs_lbl.add_theme_font_override("font", UITheme.get_display_font())
	vs_lbl.add_theme_font_size_override("font_size", 15)
	vs_lbl.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	vs_hb.add_child(vs_lbl)

	_away_btn = _make_team_tab(_away_club, _away_sq, 1, false)
	vs_hb.add_child(_away_btn)

	# Positional rows scroll canvas
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(scroll)

	_rows_vb = VBoxContainer.new()
	_rows_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_rows_vb.add_theme_constant_override("separation", 4)
	scroll.add_child(_rows_vb)

	_detail_layer = Control.new()
	_detail_layer.visible = false
	_detail_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_detail_layer)
	_detail_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _make_team_tab(club: Dictionary, sq: Dictionary, side: int, left_align: bool) -> Button:
	var btn := Button.new()
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, 40)
	btn.pressed.connect(func():
		_sel_side = side
		_render_squad()
	)

	var hb := HBoxContainer.new()
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_theme_constant_override("separation", 10)
	btn.add_child(hb)
	hb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hb.offset_left = 10
	hb.offset_right = -10
	hb.offset_top = 4
	hb.offset_bottom = -4

	var cr := ClubCrest.new()
	cr.custom_minimum_size = Vector2(32, 32)
	cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cr.set_club(int(club.get("id", 0)))

	var tvb := VBoxContainer.new()
	tvb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tvb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tvb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tvb.add_theme_constant_override("separation", 1)

	var n_lbl := Label.new()
	n_lbl.text = "%s  (%s)" % [str(club.get("name", "KLUB")).to_upper(), str(sq.get("formation", "5-3-2"))]
	n_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if left_align else HORIZONTAL_ALIGNMENT_RIGHT
	n_lbl.clip_text = true
	n_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	n_lbl.add_theme_font_override("font", UITheme.get_display_font())
	n_lbl.add_theme_font_size_override("font_size", 13)

	var s_lbl := Label.new()
	s_lbl.text = "SKUAD INTI & CADANGAN"
	s_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if left_align else HORIZONTAL_ALIGNMENT_RIGHT
	s_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	s_lbl.add_theme_font_size_override("font_size", 10)
	s_lbl.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	tvb.add_child(n_lbl)
	tvb.add_child(s_lbl)

	var ovr_box := UITheme.make_ovr_badge(int(club.get("ovr", 60)), "default", Vector2(40, 32))
	ovr_box.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if left_align:
		hb.add_child(cr)
		hb.add_child(tvb)
		hb.add_child(ovr_box)
	else:
		hb.add_child(ovr_box)
		hb.add_child(tvb)
		hb.add_child(cr)
	return btn

func _render_squad() -> void:
	UITheme.style_btn(_home_btn, Color("#3B2D0E") if _sel_side == 0 else Color("#0D1C32"), UITheme.ACCENT_GOLD if _sel_side == 0 else UITheme.BORDER_STEEL, 12)
	UITheme.style_btn(_away_btn, Color("#3B2D0E") if _sel_side == 1 else Color("#0D1C32"), UITheme.ACCENT_GOLD if _sel_side == 1 else UITheme.BORDER_STEEL, 12)

	for c in _rows_vb.get_children():
		c.queue_free()

	var club: Dictionary = _home_club if _sel_side == 0 else _away_club
	var sq: Dictionary = _home_sq if _sel_side == 0 else _away_sq
	var starters: Array = sq.get("starters", [])
	var bench: Array = sq.get("bench", [])

	var grouped: Dictionary = {}
	for g in GROUPS:
		grouped[str(g[0])] = []

	for p in starters:
		var pos: String = str(p.get("pos", "")).to_upper()
		var placed := false
		for g in GROUPS:
			if pos in g[1]:
				grouped[str(g[0])].append(p)
				placed = true
				break
		if not placed:
			grouped["GELANDANG"].append(p)

	for g in GROUPS:
		var g_name: String = str(g[0])
		_rows_vb.add_child(_make_row(g_name, grouped[g_name], club, false))
	_rows_vb.add_child(_make_row("BANGKU", bench, club, true))

func _make_row(group_name: String, players: Array, club: Dictionary, is_bench: bool) -> Control:
	var row_panel := PanelContainer.new()
	row_panel.custom_minimum_size = Vector2(0, 74)
	row_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var bg_col := Color("#0B1A30") if not is_bench else Color("#091527")
	var bd_col := Color("#1E3A5F") if not is_bench else Color("#334155")
	row_panel.add_theme_stylebox_override("panel", UITheme.make_box(bg_col, bd_col, 1, 5))

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	row_panel.add_child(hb)

	var lbl_box := VBoxContainer.new()
	lbl_box.custom_minimum_size = Vector2(86, 0)
	lbl_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(lbl_box)

	var gl := Label.new()
	gl.text = group_name
	gl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gl.add_theme_font_override("font", UITheme.get_display_font())
	gl.add_theme_font_size_override("font_size", 11)
	gl.add_theme_color_override("font_color", UITheme.ACCENT_GOLD if is_bench else UITheme.ACCENT_CYAN)
	lbl_box.add_child(gl)

	var cnt_l := Label.new()
	cnt_l.text = "%d PEMAIN" % players.size()
	cnt_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cnt_l.add_theme_font_size_override("font_size", 9)
	cnt_l.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	lbl_box.add_child(cnt_l)

	var cards_hb := HBoxContainer.new()
	cards_hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards_hb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cards_hb.add_theme_constant_override("separation", 5)
	hb.add_child(cards_hb)

	if players.is_empty():
		var empty_l := Label.new()
		empty_l.text = "TIDAK ADA PEMAIN"
		empty_l.add_theme_font_size_override("font_size", 11)
		empty_l.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
		cards_hb.add_child(empty_l)
	else:
		for p in players:
			cards_hb.add_child(_make_cell(p, club))
	return row_panel

func _make_cell(p: Dictionary, club: Dictionary) -> Control:
	var is_user := bool(p.get("is_user", false))
	var cell := PanelContainer.new()
	cell.custom_minimum_size = Vector2(98, 68)
	var bg_col := Color("#1E293B") if not is_user else Color("#2C240D")
	var bd_col := UITheme.ACCENT_GOLD if is_user else Color("#2B486B")
	cell.add_theme_stylebox_override("panel", UITheme.make_box(bg_col, bd_col, 2 if is_user else 1, 5))

	var vb := VBoxContainer.new()
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_theme_constant_override("separation", 1)
	cell.add_child(vb)

	var top_hb := HBoxContainer.new()
	top_hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	top_hb.add_theme_constant_override("separation", 4)
	vb.add_child(top_hb)

	var av := PixelAvatar.new()
	av.custom_minimum_size = Vector2(26, 38)
	av.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	av.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var p_num := int(p.get("number", 9))
	if is_user:
		av.configure_from_career()
		av.apply_kit(club)
	else:
		av.configure_from_seed(int(p.get("seed", 0)), club, p_num)
		if str(p.get("pos", "")) == "GK":
			av.glove_color = Color("#F8FAFC")
	top_hb.add_child(av)

	var meta_vb := VBoxContainer.new()
	meta_vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meta_vb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	meta_vb.add_theme_constant_override("separation", 1)
	top_hb.add_child(meta_vb)

	var ovr_l := Label.new()
	ovr_l.text = "%d" % int(p.get("ovr", 60))
	ovr_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ovr_l.add_theme_font_override("font", UITheme.get_display_font())
	ovr_l.add_theme_font_size_override("font_size", 14)
	ovr_l.add_theme_color_override("font_color", UITheme.ACCENT_GOLD if is_user else UITheme.ACCENT_GREEN)
	meta_vb.add_child(ovr_l)

	var pos_l := Label.new()
	pos_l.text = str(p.get("pos", "ST"))
	pos_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pos_l.add_theme_font_size_override("font_size", 10)
	pos_l.add_theme_color_override("font_color", UITheme.ACCENT_CYAN)
	meta_vb.add_child(pos_l)

	var num_prefix := "#%d " % p_num
	var cap_mark := " [C]" if bool(p.get("is_captain", false)) else ""
	var nm_l := Label.new()
	nm_l.text = "%s%s%s" % [num_prefix, str(p.get("name", "PEMAIN")).to_upper(), cap_mark]
	nm_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm_l.clip_text = true
	nm_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nm_l.add_theme_font_size_override("font_size", 10)
	nm_l.add_theme_color_override("font_color", UITheme.ACCENT_GOLD if is_user else Color.WHITE)
	vb.add_child(nm_l)

	var hit := Button.new()
	hit.flat = true
	hit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var hover_sb := StyleBoxFlat.new()
	hover_sb.bg_color = Color(0.22, 0.74, 0.97, 0.14)
	hover_sb.set_corner_radius_all(5)
	var normal_sb := StyleBoxEmpty.new()
	hit.add_theme_stylebox_override("normal", normal_sb)
	hit.add_theme_stylebox_override("hover", hover_sb)
	hit.add_theme_stylebox_override("pressed", hover_sb)
	hit.add_theme_stylebox_override("focus", normal_sb)
	hit.pressed.connect(func(): _show_player(p, club))
	cell.add_child(hit)
	hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return cell

func _show_player(p: Dictionary, club: Dictionary) -> void:
	for c in _detail_layer.get_children():
		c.queue_free()
	_detail_layer.visible = true

	var bg := ColorRect.new()
	bg.color = Color(0.01, 0.03, 0.08, 0.88)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_detail_layer.add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	_detail_layer.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var modal := PanelContainer.new()
	modal.custom_minimum_size = Vector2(780, 470)
	modal.add_theme_stylebox_override("panel", UITheme.make_box(Color("#081529"), UITheme.ACCENT_GOLD if bool(p.get("is_user", false)) else Color("#38BDF8"), 2, 8))
	center.add_child(modal)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	modal.add_child(vb)

	var hdr := HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 10)
	vb.add_child(hdr)

	var cr := ClubCrest.new()
	cr.custom_minimum_size = Vector2(32, 32)
	cr.set_club(int(club.get("id", 0)))
	hdr.add_child(cr)

	var p_num := int(p.get("number", 9))
	var t_lbl := Label.new()
	t_lbl.text = "#%d %s  •  %s  •  OVR %d" % [p_num, str(p.get("name", "PEMAIN")).to_upper(), str(p.get("pos", "ST")), int(p.get("ovr", 60))]
	t_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t_lbl.add_theme_font_override("font", UITheme.get_display_font())
	t_lbl.add_theme_font_size_override("font_size", 17)
	t_lbl.add_theme_color_override("font_color", Color.WHITE)
	hdr.add_child(t_lbl)

	var close_btn := Button.new()
	close_btn.text = "TUTUP"
	close_btn.custom_minimum_size = Vector2(96, 32)
	UITheme.style_btn(close_btn, Color("#2A1520"), Color("#FB7185"), 12)
	close_btn.pressed.connect(func(): _detail_layer.visible = false)
	hdr.add_child(close_btn)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 16)
	vb.add_child(body)

	# Left card: large avatar + career snapshot
	var left := PanelContainer.new()
	left.custom_minimum_size = Vector2(230, 0)
	left.add_theme_stylebox_override("panel", UITheme.make_box(Color("#0D1E36"), UITheme.BORDER_STEEL, 1, 6))
	body.add_child(left)

	var lvb := VBoxContainer.new()
	lvb.alignment = BoxContainer.ALIGNMENT_CENTER
	lvb.add_theme_constant_override("separation", 8)
	left.add_child(lvb)

	var av := PixelAvatar.new()
	av.custom_minimum_size = Vector2(76, 108)
	av.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if bool(p.get("is_user", false)):
		av.configure_from_career()
	else:
		av.configure_from_seed(int(p.get("seed", 0)), club, p_num)
		if str(p.get("pos", "")) == "GK":
			av.glove_color = Color("#F8FAFC")
	lvb.add_child(av)

	var bio_items := [
		["KLUB", str(club.get("name", "KLUB")).to_upper()],
		["USIA", "%d THN" % int(p.get("age", 22))],
		["KONTRAK", "%d MUSIM" % int(p.get("contract", 2))],
		["NILAI", UITheme.format_cash(int(p.get("value", 250000)))],
		["STAT LAGA", "%d M  •  %d G  •  %d A" % [int(p.get("matches", 0)), int(p.get("goals", 0)), int(p.get("assists", 0))]],
		["RATING", "%.1f" % float(p.get("rating", 6.0))],
	]
	for b in bio_items:
		var bh := HBoxContainer.new()
		lvb.add_child(bh)
		var bk := Label.new()
		bk.text = str(b[0])
		bk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bk.add_theme_font_size_override("font_size", 11)
		bk.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
		bh.add_child(bk)
		var bv := Label.new()
		bv.text = str(b[1])
		bv.add_theme_font_size_override("font_size", 11)
		bv.add_theme_color_override("font_color", Color.WHITE)
		bh.add_child(bv)

	# Right grid: attributes
	var right := PanelContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_stylebox_override("panel", UITheme.make_box(Color("#0D1E36"), UITheme.BORDER_STEEL, 1, 6))
	body.add_child(right)

	var rvb := VBoxContainer.new()
	rvb.add_theme_constant_override("separation", 8)
	right.add_child(rvb)

	var attr_title := Label.new()
	attr_title.text = "ATRIBUT TEKNIK & FISIK"
	attr_title.add_theme_font_override("font", UITheme.get_display_font())
	attr_title.add_theme_font_size_override("font_size", 14)
	attr_title.add_theme_color_override("font_color", UITheme.ACCENT_CYAN)
	rvb.add_child(attr_title)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 10)
	rvb.add_child(grid)

	var attrs: Dictionary = CareerState.career["playerProfile"]["attributes"] if bool(p.get("is_user", false)) else p.get("attrs", {})
	for ak in GameData.ATTRIBUTE_KEYS:
		var val: int = int(attrs.get(ak, int(p.get("ovr", 58))))
		var cell_vb := VBoxContainer.new()
		cell_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell_vb.add_theme_constant_override("separation", 3)
		grid.add_child(cell_vb)

		var row_hb := HBoxContainer.new()
		cell_vb.add_child(row_hb)
		var kl := Label.new()
		kl.text = str(GameData.ATTRIBUTE_LABELS.get(ak, ak.to_upper())).to_upper()
		kl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		kl.add_theme_font_size_override("font_size", 11)
		row_hb.add_child(kl)

		var vl := Label.new()
		vl.text = "%d" % val
		vl.add_theme_font_override("font", UITheme.get_display_font())
		vl.add_theme_font_size_override("font_size", 13)
		var vcol := UITheme.ACCENT_GREEN if val >= 75 else (UITheme.ACCENT_GOLD if val >= 60 else UITheme.TEXT_MUTED)
		vl.add_theme_color_override("font_color", vcol)
		row_hb.add_child(vl)

		var bar := ProgressBar.new()
		bar.min_value = 0
		bar.max_value = 100
		bar.value = val
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0, 7)
		cell_vb.add_child(bar)
