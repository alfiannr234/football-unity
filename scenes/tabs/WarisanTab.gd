extends Control

signal replay_shot_requested(clip: Dictionary)

const WarisanOverlaysScript := preload("res://scripts/ui/WarisanOverlays.gd")

var _subtab: String = "KARIER"         # KARIER, TROFI, KLUB, LEGENDA, PETA
var _karier_tab: String = "WARISAN"    # WARISAN, TOTAL, PER_MUSIM, KOMP
var _peta_mode: String = "SHOT"        # SHOT, UMPAN, DRIBEL
var _peta_season: int = 1
var _klub_scope: String = "DUNIA"      # DUNIA, BENUA, NEGARAMU
var _klub_help_open: bool = false
var _legenda_league_nat: int = -1

var _top_tab_bar: HBoxContainer
var _root_content: VBoxContainer

func _ready() -> void:
	theme = UITheme.build_theme()
	var outer := VBoxContainer.new()
	outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("separation", 6)
	add_child(outer)

	_top_tab_bar = HBoxContainer.new()
	_top_tab_bar.add_theme_constant_override("separation", 5)
	outer.add_child(_top_tab_bar)

	_root_content = VBoxContainer.new()
	_root_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_root_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_root_content.add_theme_constant_override("separation", 6)
	outer.add_child(_root_content)

	CareerState.career_updated.connect(refresh)
	refresh()

func set_subtab(st: String) -> void:
	_subtab = st
	refresh()

func _clear_node(n: Node) -> void:
	for c in n.get_children():
		n.remove_child(c)
		c.queue_free()

func _rebuild_top_tabs() -> void:
	_clear_node(_top_tab_bar)
	var tabs := [
		["KARIER", "bars", "KARIER"],
		["TROFI", "trophy", "TROFI"],
		["KLUB", "shield", "KLUB"],
		["LEGENDA", "medal", "LEGENDA"],
	]
	for td in tabs:
		var key: String = str(td[0])
		var is_act: bool = (_subtab == key)
		var is_peta_parent: bool = (_subtab == "PETA" and key == "KARIER")
		var btn := Button.new()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 34)
		var sb := StyleBoxFlat.new()
		if is_act:
			sb.bg_color = Color("#C62834")
			sb.border_color = Color("#FFFFFF")
			sb.set_border_width_all(0)
			sb.border_width_bottom = 3
		elif is_peta_parent:
			sb.bg_color = Color("#112138")
			sb.border_color = Color("#EA8C24")
			sb.set_border_width_all(1)
			sb.border_width_bottom = 2
		else:
			sb.bg_color = Color("#0A1527")
			sb.border_color = Color("#1B2D48")
			sb.set_border_width_all(1)
		sb.set_corner_radius_all(4)
		var sbh := sb.duplicate()
		sbh.bg_color = sb.bg_color.lightened(0.12)
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("hover", sbh)
		btn.add_theme_stylebox_override("pressed", sbh)
		btn.add_theme_stylebox_override("focus", sbh)

		var hb := HBoxContainer.new()
		hb.set_anchors_preset(Control.PRESET_FULL_RECT)
		hb.alignment = BoxContainer.ALIGNMENT_CENTER
		hb.add_theme_constant_override("separation", 6)
		hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(hb)

		var ic_col: Color = Color.WHITE if is_act else Color("#E59A38")
		var ic_c := CenterContainer.new()
		ic_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ic_c.add_child(WarisanOverlaysScript.make_icon(str(td[1]), ic_col, Vector2(13, 13)))
		hb.add_child(ic_c)

		var lbl := Label.new()
		lbl.text = str(td[2])
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_override("font", UITheme.get_display_font())
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", Color.WHITE if is_act else Color("#E5C07B"))
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hb.add_child(lbl)

		btn.pressed.connect(func():
			AudioSynth.play_click()
			_subtab = key
			refresh()
		)
		_top_tab_bar.add_child(btn)

func refresh() -> void:
	if not is_inside_tree() or not CareerState.has_active_career:
		return
	var cur_yr: int = maxi(1, int(CareerState.career.get("careerMeta", {}).get("year", 1)))
	_peta_season = clampi(_peta_season, 1, cur_yr)

	_rebuild_top_tabs()
	_clear_node(_root_content)

	match _subtab:
		"KARIER": _render_karier()
		"PETA": _render_peta()
		"TROFI": _render_trofi()
		"KLUB": _render_klub()
		"LEGENDA": _render_legenda()
		_: _render_karier()

# ==============================================================================
# PUBLIC MODAL OPENERS
# ==============================================================================
func _modal_host() -> Node:
	return get_tree().root if is_inside_tree() else self

func open_legends_modal() -> CanvasLayer:
	return WarisanOverlaysScript.open_legends_overlay(_modal_host())

func open_world_legends_modal() -> CanvasLayer:
	return WarisanOverlaysScript.open_world_legends_popup(_modal_host())

func open_goals_assists_modal() -> CanvasLayer:
	return WarisanOverlaysScript.open_goals_assists_legends_popup(_modal_host())

func open_club_legends_modal() -> CanvasLayer:
	var cur_cid: int = int(CareerState.get_current_club().get("id", 0))
	var start_nid: int = _legenda_league_nat if _legenda_league_nat >= 0 else int(CareerState.get_current_club().get("nation_id", 1))
	return WarisanOverlaysScript.open_club_legends_popup(_modal_host(), start_nid, cur_cid)

func open_timnas_legends_modal() -> CanvasLayer:
	return WarisanOverlaysScript.open_timnas_legends_popup(_modal_host())

func open_record_book_modal() -> CanvasLayer:
	return WarisanOverlaysScript.open_record_book_popup(_modal_host(), CareerState.get_warisan_karier_summary())

func open_journey_modal() -> CanvasLayer:
	return WarisanOverlaysScript.open_journey_popup(_modal_host(), CareerState.get_warisan_karier_summary())

func open_kemitraan_modal() -> CanvasLayer:
	return WarisanOverlaysScript.open_kemitraan_popup(_modal_host())

func open_bola_modal() -> CanvasLayer:
	return WarisanOverlaysScript.open_bola_gala_popup(_modal_host())

func open_champions_modal() -> CanvasLayer:
	return WarisanOverlaysScript.open_champions_popup(_modal_host())

func open_club_category_modal(cat_key: String) -> CanvasLayer:
	var rdata: Dictionary = CareerState.get_decorated_clubs_ranking(_klub_scope, "tot")
	return WarisanOverlaysScript.open_club_category_popup(_modal_host(), cat_key, rdata)

func _make_card_sb(bg: Color = Color("#091222"), bd: Color = Color("#182840"), rad: int = 6, pad_x: int = 10, pad_y: int = 8) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = bd
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(rad)
	sb.content_margin_left = pad_x
	sb.content_margin_right = pad_x
	sb.content_margin_top = pad_y
	sb.content_margin_bottom = pad_y
	return sb

# ==============================================================================
# 1. KARIER TAB (Gambar 2 WARISAN, Gambar 3 TOTAL, Gambar 4 PER MUSIM, Gambar 5 KOMP., Gambar 6 Right Panel)
# ==============================================================================
func _render_karier() -> void:
	var sum: Dictionary = CareerState.get_warisan_karier_summary()
	var cols := HBoxContainer.new()
	cols.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.add_theme_constant_override("separation", 12)
	_root_content.add_child(cols)

	# LEFT COLUMN: 4 Mini Sub-tabs + Sub-menu content
	var left_vb := VBoxContainer.new()
	left_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_vb.size_flags_stretch_ratio = 1.08
	left_vb.add_theme_constant_override("separation", 7)
	cols.add_child(left_vb)

	var sub_hb := HBoxContainer.new()
	sub_hb.add_theme_constant_override("separation", 4)
	left_vb.add_child(sub_hb)
	for st_def in [
		["WARISAN", "WARISAN"],
		["TOTAL", "TOTAL"],
		["PER_MUSIM", "PER MUSIM"],
		["KOMP", "KOMP."],
	]:
		var sk: String = str(st_def[0])
		var is_s: bool = (_karier_tab == sk)
		var sb_btn := Button.new()
		sb_btn.text = str(st_def[1])
		sb_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sb_btn.custom_minimum_size = Vector2(0, 28)
		var sbs := StyleBoxFlat.new()
		sbs.bg_color = Color("#15253E") if is_s else Color(0, 0, 0, 0)
		sbs.border_color = Color("#E59A38") if is_s else Color.TRANSPARENT
		sbs.set_border_width_all(0)
		sbs.border_width_bottom = 2 if is_s else 0
		sbs.set_corner_radius_all(4)
		var sbsh := sbs.duplicate()
		sbsh.bg_color = Color("#13223A")
		sb_btn.add_theme_stylebox_override("normal", sbs)
		sb_btn.add_theme_stylebox_override("hover", sbsh)
		sb_btn.add_theme_stylebox_override("pressed", sbsh)
		sb_btn.add_theme_stylebox_override("focus", sbsh)
		sb_btn.add_theme_font_override("font", UITheme.get_display_font())
		sb_btn.add_theme_font_size_override("font_size", 9)
		sb_btn.add_theme_color_override("font_color", Color.WHITE if is_s else Color("#8EA3BC"))
		sb_btn.pressed.connect(func():
			AudioSynth.play_click()
			_karier_tab = sk
			refresh()
		)
		sub_hb.add_child(sb_btn)

	match _karier_tab:
		"WARISAN": _render_karier_warisan(left_vb, sum)
		"TOTAL": _render_karier_total(left_vb, sum)
		"PER_MUSIM": _render_karier_per_musim(left_vb, sum)
		_: _render_karier_komp(left_vb, sum)

	# RIGHT COLUMN: PERJALANANMU + Records + Market Value + 2x2 Amber Quick Grid (Gambar 6!)
	var right_vb := VBoxContainer.new()
	right_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vb.size_flags_stretch_ratio = 0.94
	right_vb.add_theme_constant_override("separation", 7)
	cols.add_child(right_vb)
	_render_karier_right_journey(right_vb, sum)

# --- Sub-menu WARISAN (Gambar 2) ---
func _render_karier_warisan(parent_vb: VBoxContainer, sum: Dictionary) -> void:
	var yr: int = int(sum.get("year", 1))
	var yr_tag: String = "M%d" % yr

	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 7)
	parent_vb.add_child(grid)

	# 1. GOL card
	var gpm: float = float(sum.get("g_per_m", 0.0))
	var sgpm: float = float(sum.get("sg_per_m", 0.0))
	grid.add_child(_make_dual_bar_stat_card(
		"goal", str(int(sum.get("goals", 0))), "GOL",
		WarisanOverlaysScript.format_comma(gpm, 2), "PER LAGA", Color("#E2E8F0"),
		"KARIER", gpm, yr_tag, sgpm, maxf(1.5, maxf(gpm, sgpm) * 1.15), 2
	))

	# 2. AST card
	var apm: float = float(sum.get("a_per_m", 0.0))
	var sapm: float = float(sum.get("sa_per_m", 0.0))
	grid.add_child(_make_dual_bar_stat_card(
		"assist", str(int(sum.get("assists", 0))), "AST",
		WarisanOverlaysScript.format_comma(apm, 2), "PER LAGA", Color("#E2E8F0"),
		"KARIER", apm, yr_tag, sapm, maxf(0.8, maxf(apm, sapm) * 1.15), 2
	))

	# 3. LAGA card (with W/D/L bar)
	grid.add_child(_make_matches_wdl_card(sum))

	# 4. RATING card
	var avg_r: float = float(sum.get("avg_rating", 0.0))
	var savg_r: float = float(sum.get("season_avg_rating", 0.0))
	grid.add_child(_make_dual_bar_stat_card(
		"star", WarisanOverlaysScript.format_comma(avg_r, 1), "RATING",
		WarisanOverlaysScript.format_comma(float(sum.get("best_rating", 0.0)), 1), "NILAI TOP", Color("#E59A38"),
		"KARIER", avg_r, yr_tag, savg_r, 10.0, 1
	))

	# Bottom 3 Accuracy Mini-Cards: KE GAWANG | KONVERSI | UMPAN-TEMBAK (Gambar 2!)
	var acc_hb := HBoxContainer.new()
	acc_hb.add_theme_constant_override("separation", 6)
	parent_vb.add_child(acc_hb)
	for ad in [
		["KE GAWANG", int(sum.get("ke_gawang_pct", 0)), int(sum.get("s_ke_gawang_pct", 0))],
		["KONVERSI", int(sum.get("konversi_pct", 0)), int(sum.get("s_konversi_pct", 0))],
		["UMPAN-TEMBAK", int(sum.get("umpan_tembak_pct", 0)), int(sum.get("s_umpan_tembak_pct", 0))],
	]:
		var pc := PanelContainer.new()
		pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pc.add_theme_stylebox_override("panel", _make_card_sb(Color("#091222"), Color("#16253E"), 5, 8, 5))
		acc_hb.add_child(pc)
		var avb := VBoxContainer.new()
		avb.add_theme_constant_override("separation", 3)
		pc.add_child(avb)

		var tl := Label.new()
		tl.text = str(ad[0])
		tl.clip_text = true
		tl.add_theme_font_size_override("font_size", 8)
		tl.add_theme_color_override("font_color", Color("#7C90AB"))
		avb.add_child(tl)

		var rhb := HBoxContainer.new()
		avb.add_child(rhb)
		var p_main := Label.new()
		p_main.text = "%d%%" % int(ad[1])
		p_main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		p_main.add_theme_font_override("font", UITheme.get_display_font())
		p_main.add_theme_font_size_override("font_size", 13)
		p_main.add_theme_color_override("font_color", Color.WHITE)
		rhb.add_child(p_main)
		var p_sub := Label.new()
		p_sub.text = "%s %d%%" % [yr_tag, int(ad[2])]
		p_sub.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		p_sub.add_theme_font_size_override("font_size", 8)
		p_sub.add_theme_color_override("font_color", Color("#94A3B8"))
		rhb.add_child(p_sub)

		var bar_bg := ColorRect.new()
		bar_bg.custom_minimum_size = Vector2(0, 3)
		bar_bg.color = Color("#18253A")
		avb.add_child(bar_bg)
		var bar_fill := ColorRect.new()
		bar_fill.color = Color("#D98C2B")
		bar_fill.set_anchors_preset(Control.PRESET_LEFT_WIDE)
		bar_fill.anchor_right = clampf(float(ad[1]) / 100.0, 0.0, 1.0)
		bar_bg.add_child(bar_fill)

	# Footer Strip: MUSIM TERBAIK   M1
	var best_p := PanelContainer.new()
	best_p.add_theme_stylebox_override("panel", _make_card_sb(Color("#08101E"), Color("#16253E"), 5, 10, 5))
	parent_vb.add_child(best_p)
	var bhb := HBoxContainer.new()
	bhb.add_theme_constant_override("separation", 6)
	best_p.add_child(bhb)
	var bic := CenterContainer.new()
	bic.add_child(WarisanOverlaysScript.make_icon("trophy", Color("#E59A38"), Vector2(12, 12)))
	bhb.add_child(bic)
	var bl1 := Label.new()
	bl1.text = "MUSIM TERBAIK"
	bl1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bl1.add_theme_font_override("font", UITheme.get_display_font())
	bl1.add_theme_font_size_override("font_size", 10)
	bl1.add_theme_color_override("font_color", Color("#CBD5E1"))
	bhb.add_child(bl1)
	var bl2 := Label.new()
	bl2.text = "M%d" % int(sum.get("best_season", 1))
	bl2.add_theme_font_override("font", UITheme.get_display_font())
	bl2.add_theme_font_size_override("font_size", 11)
	bl2.add_theme_color_override("font_color", Color.WHITE)
	bhb.add_child(bl2)

func _make_dual_bar_stat_card(
	icon_k: String, big_val: String, big_sub: String,
	right_val: String, right_sub: String, right_col: Color,
	row1_lbl: String, row1_v: float, row2_lbl: String, row2_v: float,
	max_ref: float, decs: int
) -> PanelContainer:
	var pc := PanelContainer.new()
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pc.add_theme_stylebox_override("panel", _make_card_sb(Color("#091222"), Color("#172640"), 6, 10, 7))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 5)
	pc.add_child(vb)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 6)
	vb.add_child(top)

	var ic_c := CenterContainer.new()
	ic_c.add_child(WarisanOverlaysScript.make_icon(icon_k, Color("#CBD5E1"), Vector2(16, 16)))
	top.add_child(ic_c)

	var l_vb := VBoxContainer.new()
	l_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l_vb.add_theme_constant_override("separation", 0)
	top.add_child(l_vb)
	var lv1 := Label.new()
	lv1.text = big_val
	lv1.add_theme_font_override("font", UITheme.get_display_font())
	lv1.add_theme_font_size_override("font_size", 20)
	lv1.add_theme_color_override("font_color", Color.WHITE)
	var lv2 := Label.new()
	lv2.text = big_sub
	lv2.add_theme_font_size_override("font_size", 8)
	lv2.add_theme_color_override("font_color", Color("#7C90AB"))
	l_vb.add_child(lv1)
	l_vb.add_child(lv2)

	var r_vb := VBoxContainer.new()
	r_vb.add_theme_constant_override("separation", 0)
	top.add_child(r_vb)
	var rv1 := Label.new()
	rv1.text = right_val
	rv1.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rv1.add_theme_font_override("font", UITheme.get_display_font())
	rv1.add_theme_font_size_override("font_size", 12)
	rv1.add_theme_color_override("font_color", right_col)
	var rv2 := Label.new()
	rv2.text = right_sub
	rv2.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rv2.add_theme_font_size_override("font_size", 8)
	rv2.add_theme_color_override("font_color", Color("#7C90AB"))
	r_vb.add_child(rv1)
	r_vb.add_child(rv2)

	for bar_def in [
		[row1_lbl, row1_v, Color("#E0962D"), Color("#E0962D")],
		[row2_lbl, row2_v, Color("#E2E8F0"), Color("#CBD5E1")],
	]:
		var bhb := HBoxContainer.new()
		bhb.add_theme_constant_override("separation", 5)
		vb.add_child(bhb)
		var bl := Label.new()
		bl.text = str(bar_def[0])
		bl.custom_minimum_size = Vector2(40, 0)
		bl.add_theme_font_size_override("font_size", 8)
		bl.add_theme_color_override("font_color", Color("#7C90AB"))
		bhb.add_child(bl)

		var track := ColorRect.new()
		track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		track.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		track.custom_minimum_size = Vector2(0, 5)
		track.color = Color("#162338")
		bhb.add_child(track)
		var fill := ColorRect.new()
		fill.color = bar_def[2]
		fill.set_anchors_preset(Control.PRESET_LEFT_WIDE)
		fill.anchor_right = clampf(float(bar_def[1]) / maxf(0.01, max_ref), 0.0, 1.0)
		track.add_child(fill)

		var vl := Label.new()
		vl.text = WarisanOverlaysScript.format_comma(float(bar_def[1]), decs)
		vl.custom_minimum_size = Vector2(28, 0)
		vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		vl.add_theme_font_override("font", UITheme.get_display_font())
		vl.add_theme_font_size_override("font_size", 9)
		vl.add_theme_color_override("font_color", bar_def[3])
		bhb.add_child(vl)
	return pc

func _make_matches_wdl_card(sum: Dictionary) -> PanelContainer:
	var pc := PanelContainer.new()
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pc.add_theme_stylebox_override("panel", _make_card_sb(Color("#091222"), Color("#172640"), 6, 10, 7))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	pc.add_child(vb)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 6)
	vb.add_child(top)
	var ic_c := CenterContainer.new()
	ic_c.add_child(WarisanOverlaysScript.make_icon("match", Color("#CBD5E1"), Vector2(16, 16)))
	top.add_child(ic_c)

	var l_vb := VBoxContainer.new()
	l_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l_vb.add_theme_constant_override("separation", 0)
	top.add_child(l_vb)
	var lv1 := Label.new()
	lv1.text = str(int(sum.get("matches", 0)))
	lv1.add_theme_font_override("font", UITheme.get_display_font())
	lv1.add_theme_font_size_override("font_size", 20)
	lv1.add_theme_color_override("font_color", Color.WHITE)
	var lv2 := Label.new()
	lv2.text = "LAGA"
	lv2.add_theme_font_size_override("font_size", 8)
	lv2.add_theme_color_override("font_color", Color("#7C90AB"))
	l_vb.add_child(lv1)
	l_vb.add_child(lv2)

	var r_vb := VBoxContainer.new()
	r_vb.add_theme_constant_override("separation", 0)
	top.add_child(r_vb)
	var rv1 := Label.new()
	rv1.text = "%d%%" % int(sum.get("win_pct", 0))
	rv1.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rv1.add_theme_font_override("font", UITheme.get_display_font())
	rv1.add_theme_font_size_override("font_size", 12)
	rv1.add_theme_color_override("font_color", Color.WHITE)
	var rv2 := Label.new()
	rv2.text = "MENANG"
	rv2.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rv2.add_theme_font_size_override("font_size", 8)
	rv2.add_theme_color_override("font_color", Color("#7C90AB"))
	r_vb.add_child(rv1)
	r_vb.add_child(rv2)

	var w_n: int = int(sum.get("wins", 0))
	var d_n: int = int(sum.get("draws", 0))
	var l_n: int = int(sum.get("losses", 0))
	var tot: int = w_n + d_n + l_n

	var bar_hb := HBoxContainer.new()
	bar_hb.custom_minimum_size = Vector2(0, 6)
	bar_hb.add_theme_constant_override("separation", 1)
	vb.add_child(bar_hb)
	if tot <= 0:
		var er := ColorRect.new()
		er.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		er.color = Color("#18253A")
		bar_hb.add_child(er)
	else:
		for sd in [[w_n, Color("#E0962D")], [d_n, Color("#64748B")], [l_n, Color("#E05252")]]:
			if int(sd[0]) > 0:
				var sr := ColorRect.new()
				sr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				sr.size_flags_stretch_ratio = float(sd[0])
				sr.color = sd[1]
				bar_hb.add_child(sr)

	var cnt_hb := HBoxContainer.new()
	vb.add_child(cnt_hb)
	for cd in [[w_n, Color("#E0962D")], [d_n, Color("#94A3B8")], [l_n, Color("#E05252")]]:
		var shb := HBoxContainer.new()
		shb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		shb.add_theme_constant_override("separation", 4)
		var sq := ColorRect.new()
		sq.custom_minimum_size = Vector2(6, 6)
		sq.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		sq.color = cd[1]
		var cl := Label.new()
		cl.text = str(int(cd[0]))
		cl.add_theme_font_override("font", UITheme.get_display_font())
		cl.add_theme_font_size_override("font_size", 9)
		cl.add_theme_color_override("font_color", Color("#CBD5E1"))
		shb.add_child(sq)
		shb.add_child(cl)
		cnt_hb.add_child(shb)
	return pc

# --- Sub-menu TOTAL (Gambar 3) ---
func _render_karier_total(parent_vb: VBoxContainer, sum: Dictionary) -> void:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	parent_vb.add_child(grid)

	var rk: int = int(sum.get("legend_rank", 0))
	var pos_txt: String = "#%d TOP 30" % rk if rk > 0 else "DI LUAR TOP 30"

	for cdef in [
		["trophy", str(sum.get("legacy_tier", "PROSPEK")), "TINGKAT", Color("#E59A38"), 18],
		["bars", str(int(sum.get("legacy_points", 0))), "POIN", Color.WHITE, 22],
		["medal", pos_txt, "POS", Color.WHITE, 13],
		["shield", str(int(sum.get("trophies", 0))), "GELAR", Color.WHITE, 22],
	]:
		var pc := PanelContainer.new()
		pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		pc.add_theme_stylebox_override("panel", _make_card_sb(Color("#091222"), Color("#172640"), 6, 14, 12))
		grid.add_child(pc)

		var hb := HBoxContainer.new()
		hb.alignment = BoxContainer.ALIGNMENT_BEGIN
		hb.add_theme_constant_override("separation", 10)
		pc.add_child(hb)

		var ic_c := CenterContainer.new()
		ic_c.add_child(WarisanOverlaysScript.make_icon(str(cdef[0]), Color("#CBD5E1"), Vector2(18, 18)))
		hb.add_child(ic_c)

		var vb := VBoxContainer.new()
		vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vb.alignment = BoxContainer.ALIGNMENT_CENTER
		vb.add_theme_constant_override("separation", 2)
		hb.add_child(vb)

		var vl := Label.new()
		vl.text = str(cdef[1])
		vl.clip_text = true
		vl.add_theme_font_override("font", UITheme.get_display_font())
		vl.add_theme_font_size_override("font_size", int(cdef[4]))
		vl.add_theme_color_override("font_color", cdef[3])
		var sub := Label.new()
		sub.text = str(cdef[2])
		sub.add_theme_font_size_override("font_size", 9)
		sub.add_theme_color_override("font_color", Color("#7C90AB"))
		vb.add_child(vl)
		vb.add_child(sub)

	# Bottom Progress Bar: [Crown] KE BINTANG DUNIA ---- 308 PTS + Compact Retire Option
	var foot_p := PanelContainer.new()
	foot_p.add_theme_stylebox_override("panel", _make_card_sb(Color("#08101E"), Color("#16253E"), 5, 10, 6))
	parent_vb.add_child(foot_p)
	var fhb := HBoxContainer.new()
	fhb.add_theme_constant_override("separation", 8)
	foot_p.add_child(fhb)

	var cr_c := CenterContainer.new()
	cr_c.add_child(WarisanOverlaysScript.make_icon("crown", Color("#E59A38"), Vector2(13, 13)))
	fhb.add_child(cr_c)

	var nt_l := Label.new()
	nt_l.text = "KE %s" % str(sum.get("next_tier", "ANDALAN"))
	nt_l.add_theme_font_override("font", UITheme.get_display_font())
	nt_l.add_theme_font_size_override("font_size", 10)
	nt_l.add_theme_color_override("font_color", Color("#E2E8F0"))
	fhb.add_child(nt_l)

	var prog_bg := ColorRect.new()
	prog_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prog_bg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	prog_bg.custom_minimum_size = Vector2(0, 5)
	prog_bg.color = Color("#18253A")
	fhb.add_child(prog_bg)
	var prog_fill := ColorRect.new()
	prog_fill.color = Color("#E0962D")
	prog_fill.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	prog_fill.anchor_right = clampf(float(sum.get("tier_prog", 0.0)), 0.04, 1.0)
	prog_bg.add_child(prog_fill)

	var pts_l := Label.new()
	pts_l.text = "%d PTS" % int(sum.get("pts_to_next", 0))
	pts_l.add_theme_font_override("font", UITheme.get_display_font())
	pts_l.add_theme_font_size_override("font_size", 10)
	pts_l.add_theme_color_override("font_color", Color("#E59A38"))
	fhb.add_child(pts_l)

	var m: Dictionary = CareerState.career["careerMeta"]
	var is_ret: bool = bool(m.get("retired", false))
	var ret_b := Button.new()
	ret_b.text = "PENSIUN ✓" if is_ret else "PENSIUN"
	ret_b.custom_minimum_size = Vector2(74, 24)
	ret_b.disabled = is_ret
	UITheme.style_btn(ret_b, Color("#3B1B22"), Color("#A63C4A"), 9)
	ret_b.pressed.connect(func():
		AudioSynth.play_click()
		m["retired"] = true
		CareerState.save_active_career()
		refresh()
	)
	fhb.add_child(ret_b)

# --- Sub-menu PER MUSIM (Gambar 4) ---
func _render_karier_per_musim(parent_vb: VBoxContainer, sum: Dictionary) -> void:
	var hdr := HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 6)
	parent_vb.add_child(hdr)
	for hdef in [["MUS", 32, HORIZONTAL_ALIGNMENT_LEFT], ["KLUB", 0, HORIZONTAL_ALIGNMENT_LEFT], ["MN", 28, HORIZONTAL_ALIGNMENT_RIGHT], ["G", 26, HORIZONTAL_ALIGNMENT_RIGHT], ["A", 24, HORIZONTAL_ALIGNMENT_RIGHT], ["RTG", 34, HORIZONTAL_ALIGNMENT_RIGHT]]:
		var hl := Label.new()
		hl.text = str(hdef[0])
		if int(hdef[1]) > 0:
			hl.custom_minimum_size = Vector2(int(hdef[1]), 0)
		else:
			hl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hl.horizontal_alignment = int(hdef[2])
		hl.add_theme_font_size_override("font_size", 9)
		hl.add_theme_color_override("font_color", Color("#7C90AB"))
		hdr.add_child(hl)
	var hic := CenterContainer.new()
	hic.custom_minimum_size = Vector2(28, 12)
	hic.add_child(WarisanOverlaysScript.make_icon("trophy", Color("#7C90AB"), Vector2(11, 11)))
	hdr.add_child(hic)

	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	parent_vb.add_child(sc)
	var lvb := VBoxContainer.new()
	lvb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lvb.add_theme_constant_override("separation", 5)
	sc.add_child(lvb)

	for sr_item in sum.get("season_rows", []):
		var sr: Dictionary = sr_item
		var is_cur: bool = bool(sr.get("is_current", false))
		var row_p := PanelContainer.new()
		var rsb := StyleBoxFlat.new()
		rsb.bg_color = Color("#2C2217") if is_cur else Color("#0A1322")
		rsb.border_color = Color("#D99B38") if is_cur else Color("#182740")
		rsb.set_border_width_all(0)
		rsb.border_width_bottom = 2 if is_cur else 1
		rsb.set_corner_radius_all(3)
		rsb.content_margin_left = 6
		rsb.content_margin_right = 6
		rsb.content_margin_top = 6
		rsb.content_margin_bottom = 6
		row_p.add_theme_stylebox_override("panel", rsb)
		lvb.add_child(row_p)

		var rhb := HBoxContainer.new()
		rhb.add_theme_constant_override("separation", 6)
		row_p.add_child(rhb)

		var ml := Label.new()
		ml.text = "M%d" % int(sr.get("season", 1))
		ml.custom_minimum_size = Vector2(28, 0)
		ml.add_theme_font_override("font", UITheme.get_display_font())
		ml.add_theme_font_size_override("font_size", 11)
		ml.add_theme_color_override("font_color", Color("#E2E8F0"))
		rhb.add_child(ml)

		var cr_c := CenterContainer.new()
		var cr := ClubCrest.new()
		cr.custom_minimum_size = Vector2(16, 16)
		cr.set_club(int(sr.get("club_id", 0)))
		cr_c.add_child(cr)
		rhb.add_child(cr_c)

		var cn := Label.new()
		cn.text = str(sr.get("club_name", "Klub"))
		cn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cn.clip_text = true
		cn.add_theme_font_override("font", UITheme.get_display_font())
		cn.add_theme_font_size_override("font_size", 11)
		cn.add_theme_color_override("font_color", Color.WHITE)
		rhb.add_child(cn)

		for vdef in [
			[str(int(sr.get("matches", 0))), 26],
			[str(int(sr.get("goals", 0))), 26],
			[str(int(sr.get("assists", 0))), 24],
			[WarisanOverlaysScript.format_comma(float(sr.get("avg_rating", 0.0)), 1), 34],
		]:
			var vl := Label.new()
			vl.text = str(vdef[0])
			vl.custom_minimum_size = Vector2(int(vdef[1]), 0)
			vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			vl.add_theme_font_override("font", UITheme.get_display_font())
			vl.add_theme_font_size_override("font_size", 11)
			vl.add_theme_color_override("font_color", Color.WHITE)
			rhb.add_child(vl)

		var aw_hb := HBoxContainer.new()
		aw_hb.custom_minimum_size = Vector2(28, 0)
		aw_hb.alignment = BoxContainer.ALIGNMENT_END
		aw_hb.add_theme_constant_override("separation", 3)
		if bool(sr.get("has_star", false)):
			aw_hb.add_child(WarisanOverlaysScript.make_icon("star", Color("#E59A38"), Vector2(11, 11)))
		if bool(sr.get("has_trophy", false)):
			aw_hb.add_child(WarisanOverlaysScript.make_icon("trophy", Color("#F5C430"), Vector2(11, 11)))
		rhb.add_child(aw_hb)

# --- Sub-menu KOMP. (Gambar 5) ---
func _render_karier_komp(parent_vb: VBoxContainer, sum: Dictionary) -> void:
	# Group Header Row: MUSIM INI | KARIER
	var top_h := HBoxContainer.new()
	top_h.add_theme_constant_override("separation", 8)
	parent_vb.add_child(top_h)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_h.add_child(sp)
	for grp_s in ["MUSIM INI", "KARIER"]:
		var gl := Label.new()
		gl.text = grp_s
		gl.custom_minimum_size = Vector2(74, 0)
		gl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		gl.add_theme_font_size_override("font_size", 8)
		gl.add_theme_color_override("font_color", Color("#7C90AB"))
		top_h.add_child(gl)

	var sub_h := HBoxContainer.new()
	sub_h.add_theme_constant_override("separation", 8)
	parent_vb.add_child(sub_h)
	var k_lbl := Label.new()
	k_lbl.text = "KOMP."
	k_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	k_lbl.add_theme_font_size_override("font_size", 9)
	k_lbl.add_theme_color_override("font_color", Color("#7C90AB"))
	sub_h.add_child(k_lbl)
	for col_s in ["G", "A", "G", "A"]:
		var cl := Label.new()
		cl.text = col_s
		cl.custom_minimum_size = Vector2(33, 0)
		cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		cl.add_theme_font_size_override("font_size", 9)
		cl.add_theme_color_override("font_color", Color("#7C90AB"))
		sub_h.add_child(cl)

	var sep := ColorRect.new()
	sep.custom_minimum_size = Vector2(0, 1)
	sep.color = Color("#1A2A42")
	parent_vb.add_child(sep)

	for cr_item in sum.get("comp_rows", []):
		var cr: Dictionary = cr_item
		var rhb := HBoxContainer.new()
		rhb.custom_minimum_size = Vector2(0, 34)
		rhb.add_theme_constant_override("separation", 8)
		parent_vb.add_child(rhb)

		var nl := Label.new()
		nl.text = str(cr.get("label", "LIGA"))
		nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		nl.add_theme_font_override("font", UITheme.get_display_font())
		nl.add_theme_font_size_override("font_size", 11)
		nl.add_theme_color_override("font_color", Color.WHITE)
		rhb.add_child(nl)

		for v_key in ["season_g", "season_a", "career_g", "career_a"]:
			var iv: int = int(cr.get(v_key, 0))
			var vl := Label.new()
			vl.text = str(iv)
			vl.custom_minimum_size = Vector2(33, 0)
			vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			vl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			vl.add_theme_font_override("font", UITheme.get_display_font())
			vl.add_theme_font_size_override("font_size", 12)
			vl.add_theme_color_override("font_color", Color.WHITE if iv > 0 else Color("#526682"))
			rhb.add_child(vl)

	var fill_sp := Control.new()
	fill_sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent_vb.add_child(fill_sp)

# --- RIGHT COLUMN SHARED BY ALL 4 KARIER SUB-MENUS (Gambar 2..6) ---
func _render_karier_right_journey(right_vb: VBoxContainer, sum: Dictionary) -> void:
	var hdr := Label.new()
	hdr.text = "PERJALANANMU"
	hdr.add_theme_font_override("font", UITheme.get_display_font())
	hdr.add_theme_font_size_override("font_size", 12)
	hdr.add_theme_color_override("font_color", Color.WHITE)
	right_vb.add_child(hdr)

	# LAIN • N Journey History Button
	var other_n: int = maxi(1, int(sum.get("other_journey_count", 0)) + 1)
	var lain_b := Button.new()
	lain_b.custom_minimum_size = Vector2(0, 38)
	lain_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var lsb := _make_card_sb(Color("#0A1322"), Color("#182840"), 5, 10, 6)
	var lsbh := lsb.duplicate()
	lsbh.bg_color = Color("#12223A")
	lsbh.border_color = UITheme.ACCENT_CYAN
	lain_b.add_theme_stylebox_override("normal", lsb)
	lain_b.add_theme_stylebox_override("hover", lsbh)
	lain_b.add_theme_stylebox_override("pressed", lsbh)
	var lhb := HBoxContainer.new()
	lhb.set_anchors_preset(Control.PRESET_FULL_RECT)
	lhb.alignment = BoxContainer.ALIGNMENT_CENTER
	lhb.add_theme_constant_override("separation", 7)
	lhb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lain_b.add_child(lhb)
	lhb.add_child(WarisanOverlaysScript.make_icon("bag", Color("#CBD5E1"), Vector2(13, 13)))
	var ltxt := Label.new()
	ltxt.text = "LAIN  •  %d" % other_n
	ltxt.add_theme_font_override("font", UITheme.get_display_font())
	ltxt.add_theme_font_size_override("font_size", 11)
	ltxt.add_theme_color_override("font_color", Color.WHITE)
	ltxt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lhb.add_child(ltxt)
	lain_b.pressed.connect(func(): AudioSynth.play_click(); open_journey_modal())
	right_vb.add_child(lain_b)

	# Current Club Card
	var club: Dictionary = CareerState.get_current_club()
	var clb_p := PanelContainer.new()
	clb_p.custom_minimum_size = Vector2(0, 46)
	clb_p.add_theme_stylebox_override("panel", _make_card_sb(Color("#0A1322"), Color("#182840"), 5, 10, 6))
	right_vb.add_child(clb_p)
	var chb := HBoxContainer.new()
	chb.add_theme_constant_override("separation", 10)
	clb_p.add_child(chb)
	var cr_c := CenterContainer.new()
	var cr := ClubCrest.new()
	cr.custom_minimum_size = Vector2(26, 26)
	cr.set_club(int(club["id"]))
	cr_c.add_child(cr)
	chb.add_child(cr_c)
	var cvb := VBoxContainer.new()
	cvb.alignment = BoxContainer.ALIGNMENT_CENTER
	cvb.add_theme_constant_override("separation", 1)
	chb.add_child(cvb)
	var cc_l := Label.new()
	cc_l.text = str(club.get("code", "CLB")).to_upper()
	cc_l.add_theme_font_override("font", UITheme.get_display_font())
	cc_l.add_theme_font_size_override("font_size", 12)
	cc_l.add_theme_color_override("font_color", Color.WHITE)
	var cm_l := Label.new()
	cm_l.text = "M%d  •  %s" % [int(sum.get("year", 1)), str(club.get("name", "Klub"))]
	cm_l.add_theme_font_size_override("font_size", 9)
	cm_l.add_theme_color_override("font_color", Color("#7C90AB"))
	cvb.add_child(cc_l)
	cvb.add_child(cm_l)

	# 3-Column Milestone Strip: GOL TERJAUH | UMPAN TERJAUH | KORBAN
	var mile_hb := HBoxContainer.new()
	mile_hb.add_theme_constant_override("separation", 6)
	right_vb.add_child(mile_hb)
	var vic: Dictionary = sum.get("victim", {})
	var lg_str: String = "%d M" % int(round(float(sum.get("longest_goal_m", 0.0))))
	var lp_str: String = "%d M" % int(round(float(sum.get("longest_pass_m", 0.0))))
	var vic_str: String = "%s • %d" % [str(vic.get("code", "---")), int(vic.get("goals", 0))]

	for mdef in [
		["goal", lg_str, "GOL TERJAUH", -1],
		["assist", lp_str, "UMPAN TERJAUH", -1],
		["", vic_str, "KORBAN", int(vic.get("club_id", 0))],
	]:
		var mp := PanelContainer.new()
		mp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mp.add_theme_stylebox_override("panel", _make_card_sb(Color("#0A1322"), Color("#16253E"), 5, 7, 6))
		mile_hb.add_child(mp)
		var mhb := HBoxContainer.new()
		mhb.add_theme_constant_override("separation", 5)
		mp.add_child(mhb)
		var mic := CenterContainer.new()
		if int(mdef[3]) >= 0:
			var vcr := ClubCrest.new()
			vcr.custom_minimum_size = Vector2(16, 16)
			vcr.set_club(int(mdef[3]))
			mic.add_child(vcr)
		else:
			mic.add_child(WarisanOverlaysScript.make_icon(str(mdef[0]), Color("#E59A38"), Vector2(13, 13)))
		mhb.add_child(mic)
		var mvb := VBoxContainer.new()
		mvb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mvb.add_theme_constant_override("separation", 0)
		mhb.add_child(mvb)
		var mv1 := Label.new()
		mv1.text = str(mdef[1])
		mv1.clip_text = true
		mv1.add_theme_font_override("font", UITheme.get_display_font())
		mv1.add_theme_font_size_override("font_size", 11)
		mv1.add_theme_color_override("font_color", Color.WHITE)
		var mv2 := Label.new()
		mv2.text = str(mdef[2])
		mv2.clip_text = true
		mv2.add_theme_font_size_override("font_size", 7)
		mv2.add_theme_color_override("font_color", Color("#7C90AB"))
		mvb.add_child(mv1)
		mvb.add_child(mv2)

	# NILAI PASAR Strip
	var mv_p := PanelContainer.new()
	mv_p.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mv_p.add_theme_stylebox_override("panel", _make_card_sb(Color("#0A1322"), Color("#172640"), 5, 10, 7))
	right_vb.add_child(mv_p)
	var mvhb := HBoxContainer.new()
	mvhb.add_theme_constant_override("separation", 10)
	mv_p.add_child(mvhb)
	var mv_vb := VBoxContainer.new()
	mv_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mv_vb.alignment = BoxContainer.ALIGNMENT_CENTER
	mv_vb.add_theme_constant_override("separation", 2)
	mvhb.add_child(mv_vb)
	var mvl1 := Label.new()
	mvl1.text = "NILAI PASAR"
	mvl1.add_theme_font_size_override("font_size", 8)
	mvl1.add_theme_color_override("font_color", Color("#7C90AB"))
	var mvl2 := Label.new()
	mvl2.text = WarisanOverlaysScript.format_mv_short(int(sum.get("market_value", 1000000)))
	mvl2.add_theme_font_override("font", UITheme.get_display_font())
	mvl2.add_theme_font_size_override("font_size", 16)
	mvl2.add_theme_color_override("font_color", Color("#F5C430"))
	mv_vb.add_child(mvl1)
	mv_vb.add_child(mvl2)

	var trend_bar := ColorRect.new()
	trend_bar.custom_minimum_size = Vector2(72, 4)
	trend_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	trend_bar.color = Color("#E5B332")
	mvhb.add_child(trend_bar)

	# Bottom 2x2 Amber-Gold Action Grid (EXACT match to Gambar 6!)
	var act_grid := GridContainer.new()
	act_grid.columns = 2
	act_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	act_grid.add_theme_constant_override("h_separation", 8)
	act_grid.add_theme_constant_override("v_separation", 7)
	right_vb.add_child(act_grid)

	var actions := [
		["medal", "LEGENDA", func(): open_legends_modal()],
		["mic", "KEMITRAAN", func(): open_kemitraan_modal()],
		["ball", "PETA", func(): _subtab = "PETA"; refresh()],
		["crown", "BOLA", func(): open_bola_modal()],
	]
	for ad in actions:
		var ab := Button.new()
		ab.custom_minimum_size = Vector2(0, 40)
		ab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var asb := StyleBoxFlat.new()
		asb.bg_color = Color("#5A3B14")
		asb.border_color = Color("#A86F23")
		asb.set_border_width_all(1)
		asb.border_width_bottom = 3
		asb.set_corner_radius_all(4)
		var asbh := asb.duplicate()
		asbh.bg_color = Color("#724C1B")
		asbh.border_color = Color("#F5C430")
		ab.add_theme_stylebox_override("normal", asb)
		ab.add_theme_stylebox_override("hover", asbh)
		ab.add_theme_stylebox_override("pressed", asbh)
		ab.add_theme_stylebox_override("focus", asbh)

		var ahb := HBoxContainer.new()
		ahb.set_anchors_preset(Control.PRESET_FULL_RECT)
		ahb.offset_left = 12
		ahb.offset_right = -10
		ahb.add_theme_constant_override("separation", 8)
		ahb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ab.add_child(ahb)

		var aic := CenterContainer.new()
		aic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		aic.add_child(WarisanOverlaysScript.make_icon(str(ad[0]), Color("#F3CFA0"), Vector2(14, 14)))
		ahb.add_child(aic)

		var al := Label.new()
		al.text = str(ad[1])
		al.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		al.add_theme_font_override("font", UITheme.get_display_font())
		al.add_theme_font_size_override("font_size", 11)
		al.add_theme_color_override("font_color", Color("#FBE5C4"))
		al.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ahb.add_child(al)

		var cb: Callable = ad[2]
		ab.pressed.connect(func():
			AudioSynth.play_click()
			cb.call()
		)
		act_grid.add_child(ab)

# ==============================================================================
# 2. PETA INTERACTIVE TELEMETRY VIEW (Gambar 8 SHOT, Gambar 9 UMPAN, Gambar 10+11 DRIBEL Inline!)
# ==============================================================================
func _render_peta() -> void:
	# Top Bar: [ < BALIK ]  PETA
	var top_hb := HBoxContainer.new()
	top_hb.add_theme_constant_override("separation", 10)
	_root_content.add_child(top_hb)

	var back_b := Button.new()
	back_b.text = "<  BALIK"
	back_b.custom_minimum_size = Vector2(92, 28)
	UITheme.style_btn(back_b, Color("#182436"), Color("#334763"), 10)
	back_b.pressed.connect(func():
		AudioSynth.play_click()
		_subtab = "KARIER"
		refresh()
	)
	top_hb.add_child(back_b)

	var p_ttl := Label.new()
	p_ttl.text = "PETA"
	p_ttl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	p_ttl.add_theme_font_override("font", UITheme.get_display_font())
	p_ttl.add_theme_font_size_override("font_size", 14)
	p_ttl.add_theme_color_override("font_color", Color.WHITE)
	top_hb.add_child(p_ttl)

	var pdata: Dictionary = CareerState.get_peta_season_data(_peta_mode, _peta_season)
	var body := HBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	_root_content.add_child(body)

	# LEFT PANEL: Mode selector (SHOT | UMPAN | DRIBEL) + Per-Season Switcher + Stats!
	var left_vb := VBoxContainer.new()
	left_vb.custom_minimum_size = Vector2(276, 0)
	left_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_vb.add_theme_constant_override("separation", 6)
	body.add_child(left_vb)

	# SHOT | UMPAN | DRIBEL selector with crimson bottom underline
	var m_hb := HBoxContainer.new()
	m_hb.add_theme_constant_override("separation", 5)
	left_vb.add_child(m_hb)
	for pm in ["SHOT", "UMPAN", "DRIBEL"]:
		var is_m: bool = (_peta_mode == pm)
		var mb := Button.new()
		mb.text = pm
		mb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mb.custom_minimum_size = Vector2(0, 30)
		var msb := StyleBoxFlat.new()
		msb.bg_color = Color("#0D182A") if is_m else Color("#070F1C")
		msb.border_color = Color("#E11D48") if is_m else Color("#1D2E48")
		msb.set_border_width_all(1)
		msb.border_width_bottom = 3 if is_m else 1
		msb.set_corner_radius_all(4)
		var msbh := msb.duplicate()
		msbh.border_color = Color("#FB7185")
		mb.add_theme_stylebox_override("normal", msb)
		mb.add_theme_stylebox_override("hover", msbh)
		mb.add_theme_stylebox_override("pressed", msbh)
		mb.add_theme_font_override("font", UITheme.get_display_font())
		mb.add_theme_font_size_override("font_size", 10)
		mb.add_theme_color_override("font_color", Color.WHITE if is_m else Color("#94A3B8"))
		mb.pressed.connect(func():
			AudioSynth.play_click()
			_peta_mode = pm
			refresh()
		)
		m_hb.add_child(mb)

	# Section label + Per-Season Switcher (< MUSIM X >) inline for ALL 3 modes (Gambar 9 style!)
	var sec_map := {"SHOT": "PETA TEMBAKAN", "UMPAN": "PETA UMPAN", "DRIBEL": "PETA DRIBEL"}
	left_vb.add_child(_make_red_flag_hdr(str(sec_map.get(_peta_mode, "PETA"))))
	_add_peta_season_switcher(left_vb, int(pdata.get("season", 1)), int(pdata.get("max_season", 1)))

	if _peta_mode == "SHOT":
		_render_peta_shot_body(left_vb, body, pdata)
	elif _peta_mode == "UMPAN":
		_render_peta_umpan_body(left_vb, body, pdata)
	else:
		_render_peta_dribel_body(left_vb, body, pdata)

func _make_red_flag_hdr(txt: String) -> HBoxContainer:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 5)
	var fl := ColorRect.new()
	fl.custom_minimum_size = Vector2(6, 9)
	fl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fl.color = Color("#E11D48")
	hb.add_child(fl)
	var l := Label.new()
	l.text = txt
	l.add_theme_font_override("font", UITheme.get_display_font())
	l.add_theme_font_size_override("font_size", 10)
	l.add_theme_color_override("font_color", Color.WHITE)
	hb.add_child(l)
	return hb

func _add_peta_season_switcher(parent_vb: VBoxContainer, cur_s: int, max_s: int) -> void:
	var shb := HBoxContainer.new()
	shb.add_theme_constant_override("separation", 8)
	parent_vb.add_child(shb)

	var prev_b := Button.new()
	prev_b.text = "<"
	prev_b.custom_minimum_size = Vector2(30, 26)
	prev_b.disabled = (cur_s <= 1)
	UITheme.style_btn(prev_b, Color("#112138"), Color("#294166"), 11)
	prev_b.pressed.connect(func(): AudioSynth.play_click(); _peta_season = maxi(1, _peta_season - 1); refresh())
	shb.add_child(prev_b)

	var sl := Label.new()
	sl.text = "MUSIM %d" % cur_s
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sl.add_theme_font_override("font", UITheme.get_display_font())
	sl.add_theme_font_size_override("font_size", 11)
	sl.add_theme_color_override("font_color", Color("#F5C430"))
	shb.add_child(sl)

	var next_b := Button.new()
	next_b.text = ">"
	next_b.custom_minimum_size = Vector2(30, 26)
	next_b.disabled = (cur_s >= max_s)
	UITheme.style_btn(next_b, Color("#2D1828"), Color("#BE123C"), 11)
	next_b.pressed.connect(func(): AudioSynth.play_click(); _peta_season = mini(max_s, _peta_season + 1); refresh())
	shb.add_child(next_b)

func _make_peta_stat_pill(top_cap: String, val_txt: String, val_col: Color) -> PanelContainer:
	var pc := PanelContainer.new()
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pc.add_theme_stylebox_override("panel", _make_card_sb(Color("#0A1424"), Color("#243957"), 6, 7, 4))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 1)
	pc.add_child(vb)
	var l1 := Label.new()
	l1.text = top_cap
	l1.clip_text = true
	l1.add_theme_font_size_override("font_size", 7)
	l1.add_theme_color_override("font_color", Color("#8EA3BC"))
	var l2 := Label.new()
	l2.text = val_txt
	l2.add_theme_font_override("font", UITheme.get_display_font())
	l2.add_theme_font_size_override("font_size", 11)
	l2.add_theme_color_override("font_color", val_col)
	vb.add_child(l1)
	vb.add_child(l2)
	return pc

func _render_peta_shot_body(left_vb: VBoxContainer, body: HBoxContainer, pdata: Dictionary) -> void:
	# Left season stat pills
	var sp_hb := HBoxContainer.new()
	sp_hb.add_theme_constant_override("separation", 5)
	left_vb.add_child(sp_hb)
	sp_hb.add_child(_make_peta_stat_pill("KE GAWANG", "%d%%" % int(pdata.get("season_on_pct", 0)), Color.WHITE))
	sp_hb.add_child(_make_peta_stat_pill("MELEBAR", "%d%%" % int(pdata.get("season_wide_pct", 0)), Color("#F87171")))
	sp_hb.add_child(_make_peta_stat_pill("GOL", "%d%%" % int(pdata.get("season_goal_pct", 0)), Color("#F5C430")))

	var s_note := Label.new()
	s_note.text = "Dari %d tembakan terukur di Musim %d.\n● Gol  ○ Tepat sasaran  ● Melebar" % [int(pdata.get("season_total", 0)), int(pdata.get("season", 1))]
	s_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	s_note.add_theme_font_size_override("font_size", 9)
	s_note.add_theme_color_override("font_color", Color("#94A3B8"))
	left_vb.add_child(s_note)

	# Mini Goal-Face impact preview inside left column bottom
	var goal_map := ShotMapCanvas.new()
	goal_map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	goal_map.custom_minimum_size = Vector2(0, 118)
	goal_map.set_shots(pdata.get("points", []), "SHOT", true)
	left_vb.add_child(goal_map)

	# Center Interactive Perspective Pitch Shot Map
	var mid_vb := VBoxContainer.new()
	mid_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid_vb.add_theme_constant_override("separation", 4)
	body.add_child(mid_vb)

	var cap_m := Label.new()
	cap_m.text = "LAPANGAN - posisi tembakanmu"
	cap_m.add_theme_font_size_override("font_size", 9)
	cap_m.add_theme_color_override("font_color", Color("#94A3B8"))
	mid_vb.add_child(cap_m)

	var pmap := WarisanOverlaysScript.PitchTelemetryCanvas.new()
	pmap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pmap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pmap.configure("SHOT", pdata.get("points", []))
	mid_vb.add_child(pmap)

	var on_tap := func(_pt: Dictionary):
		AudioSynth.play_click()
		var clips: Array = CareerState.career.get("moviolaClips", [])
		if not clips.is_empty():
			replay_shot_requested.emit(clips[clips.size() - 1])
	pmap.point_selected.connect(on_tap)
	goal_map.shot_selected.connect(on_tap)

	# Right Column (EXACT match to Gambar 8: JARAK TERJAUH + SELURUH KARIERMU!)
	var right_vb := VBoxContainer.new()
	right_vb.custom_minimum_size = Vector2(262, 0)
	right_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vb.add_theme_constant_override("separation", 8)
	body.add_child(right_vb)

	right_vb.add_child(_make_red_flag_hdr("JARAK TERJAUH"))
	var dist_box := PanelContainer.new()
	dist_box.add_theme_stylebox_override("panel", _make_card_sb(Color("#08101E"), Color("#223450"), 5, 10, 7))
	right_vb.add_child(dist_box)
	var dhb := HBoxContainer.new()
	dhb.add_theme_constant_override("separation", 6)
	dist_box.add_child(dhb)
	var dvb := VBoxContainer.new()
	dvb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dvb.add_theme_constant_override("separation", 1)
	dhb.add_child(dvb)
	var dl1 := Label.new()
	dl1.text = "GOL TERJAUHMU"
	dl1.add_theme_font_override("font", UITheme.get_display_font())
	dl1.add_theme_font_size_override("font_size", 10)
	var dl2 := Label.new()
	dl2.text = "M%d • %s" % [int(pdata.get("career_max_season", 1)), str(pdata.get("career_max_club", "Klub"))]
	dl2.clip_text = true
	dl2.add_theme_font_size_override("font_size", 8)
	dl2.add_theme_color_override("font_color", Color("#7C90AB"))
	dvb.add_child(dl1)
	dvb.add_child(dl2)

	var dm_l := Label.new()
	dm_l.text = "%s m" % WarisanOverlaysScript.format_comma(float(pdata.get("career_max_m", 0.0)), 1)
	dm_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dm_l.add_theme_font_override("font", UITheme.get_display_font())
	dm_l.add_theme_font_size_override("font_size", 15)
	dm_l.add_theme_color_override("font_color", Color("#F5C430"))
	dhb.add_child(dm_l)

	var sm_sub := Label.new()
	sm_sub.text = "Musim ini: gol dari %s m" % WarisanOverlaysScript.format_comma(float(pdata.get("season_max_m", 0.0)), 1)
	sm_sub.add_theme_font_size_override("font_size", 9)
	sm_sub.add_theme_color_override("font_color", Color("#94A3B8"))
	right_vb.add_child(sm_sub)

	right_vb.add_child(_make_red_flag_hdr("SELURUH KARIERMU"))
	var cp_hb := HBoxContainer.new()
	cp_hb.add_theme_constant_override("separation", 5)
	right_vb.add_child(cp_hb)
	cp_hb.add_child(_make_peta_stat_pill("KE GAWANG", "%d%%" % int(pdata.get("career_on_pct", 0)), Color.WHITE))
	cp_hb.add_child(_make_peta_stat_pill("MELEBAR", "%d%%" % int(pdata.get("career_wide_pct", 0)), Color("#F87171")))
	cp_hb.add_child(_make_peta_stat_pill("GOL", "%d%%" % int(pdata.get("career_goal_pct", 0)), Color("#F5C430")))

	var c_sub := Label.new()
	c_sub.text = "Dari %d tembakan terukur" % int(pdata.get("career_total", 0))
	c_sub.add_theme_font_size_override("font_size", 9)
	c_sub.add_theme_color_override("font_color", Color("#94A3B8"))
	right_vb.add_child(c_sub)

func _render_peta_umpan_body(left_vb: VBoxContainer, body: HBoxContainer, pdata: Dictionary) -> void:
	# Left Column (EXACT match to Gambar 9!)
	var r1 := HBoxContainer.new()
	r1.add_theme_constant_override("separation", 5)
	left_vb.add_child(r1)
	r1.add_child(_make_peta_stat_pill("PERMAINAN TERBUKA", "%d/%d" % [int(pdata.get("open_ast", 0)), int(pdata.get("open_tot", 0))], Color.WHITE))
	r1.add_child(_make_peta_stat_pill("KORNER", "%d/%d" % [int(pdata.get("cor_ast", 0)), int(pdata.get("cor_tot", 0))], Color.WHITE))

	var r2 := HBoxContainer.new()
	r2.add_theme_constant_override("separation", 5)
	left_vb.add_child(r2)
	r2.add_child(_make_peta_stat_pill("JADI SHOT", "%d%%" % int(pdata.get("jadi_shot_pct", 0)), Color.WHITE))
	r2.add_child(_make_peta_stat_pill("TANPA SHOT", "%d%%" % int(pdata.get("tanpa_shot_pct", 0)), Color.WHITE))
	r2.add_child(_make_peta_stat_pill("ASSIST", "%d%%" % int(pdata.get("assist_pct", 0)), Color("#F5C430")))

	var sum1 := Label.new()
	sum1.text = "Dari %d umpan yang sampai • %d umpan kunci." % [int(pdata.get("open_tot", 0)) + int(pdata.get("cor_tot", 0)), int(pdata.get("key_passes", 0))]
	sum1.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sum1.add_theme_font_size_override("font_size", 9)
	sum1.add_theme_color_override("font_color", Color("#CBD5E1"))
	left_vb.add_child(sum1)

	var sum2 := Label.new()
	sum2.text = str(pdata.get("side_note", ""))
	sum2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sum2.add_theme_font_size_override("font_size", 9)
	sum2.add_theme_color_override("font_color", Color("#94A3B8"))
	left_vb.add_child(sum2)

	# Center Pitch Pass Map
	var mid_vb := VBoxContainer.new()
	mid_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid_vb.add_theme_constant_override("separation", 4)
	body.add_child(mid_vb)

	var cap_m := Label.new()
	cap_m.text = "LAPANGAN - dari mana ke mana kamu mengumpan"
	cap_m.add_theme_font_size_override("font_size", 9)
	cap_m.add_theme_color_override("font_color", Color("#94A3B8"))
	mid_vb.add_child(cap_m)

	var pmap := WarisanOverlaysScript.PitchTelemetryCanvas.new()
	pmap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pmap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pmap.configure("UMPAN", pdata.get("points", []))
	mid_vb.add_child(pmap)

	# Right Column (JARAK + AKSI + TERJAUH + SELURUH KARIERMU — Gambar 9!)
	var right_vb := VBoxContainer.new()
	right_vb.custom_minimum_size = Vector2(268, 0)
	right_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vb.add_theme_constant_override("separation", 5)
	body.add_child(right_vb)

	var hint_l := Label.new()
	hint_l.text = "Ketuk tanda di lapangan untuk melihat aksinya."
	hint_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_l.add_theme_font_size_override("font_size", 8)
	hint_l.add_theme_color_override("font_color", Color("#94A3B8"))
	right_vb.add_child(hint_l)
	pmap.point_selected.connect(func(pt: Dictionary):
		AudioSynth.play_click()
		hint_l.text = "Umpan %s m (%s) • %s" % [WarisanOverlaysScript.format_comma(float(pt.get("distanceMeters", 18.0)), 1), str(pt.get("action", "OPEN")), str(pt.get("outcome", "SHOT"))]
		hint_l.add_theme_color_override("font_color", Color("#F5C430"))
	)

	# JARAK Table
	_add_peta_mini_table_row(right_vb, "JARAK", "U", "A", true)
	var ds: Array = pdata.get("dist_short", [0, 0])
	var dm: Array = pdata.get("dist_med", [0, 0])
	var dl: Array = pdata.get("dist_long", [0, 0])
	_add_peta_mini_table_row(right_vb, "PENDEK", str(int(ds[0])), str(int(ds[1])), false)
	_add_peta_mini_table_row(right_vb, "SEDANG", str(int(dm[0])), str(int(dm[1])), false)
	_add_peta_mini_table_row(right_vb, "PANJANG", str(int(dl[0])), str(int(dl[1])), false)

	# AKSI Table
	_add_peta_mini_table_row(right_vb, "AKSI", "JADI SHOT", "ASSIST", true)
	_add_peta_mini_table_row(right_vb, "PERMAINAN TERBUKA", "%d%%" % int(pdata.get("open_shot_pct", 0)), "%d%%" % int(pdata.get("open_ast_pct", 0)), false)
	_add_peta_mini_table_row(right_vb, "KORNER", "%d%%" % int(pdata.get("cor_shot_pct", 0)), "%d%%" % int(pdata.get("cor_ast_pct", 0)), false)

	# TERJAUH
	right_vb.add_child(_make_red_flag_hdr("TERJAUH"))
	var t_box := PanelContainer.new()
	t_box.add_theme_stylebox_override("panel", _make_card_sb(Color("#08101E"), Color("#223450"), 5, 8, 5))
	right_vb.add_child(t_box)
	var thb := HBoxContainer.new()
	t_box.add_child(thb)
	var tvb := VBoxContainer.new()
	tvb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	thb.add_child(tvb)
	var tl1 := Label.new()
	tl1.text = "UMPAN TERJAUHMU"
	tl1.add_theme_font_override("font", UITheme.get_display_font())
	tl1.add_theme_font_size_override("font_size", 9)
	var tl2 := Label.new()
	tl2.text = "M%d • %s" % [int(pdata.get("career_max_season", 1)), str(pdata.get("career_max_club", "Klub"))]
	tl2.clip_text = true
	tl2.add_theme_font_size_override("font_size", 8)
	tl2.add_theme_color_override("font_color", Color("#7C90AB"))
	tvb.add_child(tl1)
	tvb.add_child(tl2)
	var tm_v := Label.new()
	tm_v.text = "%s m" % WarisanOverlaysScript.format_comma(float(pdata.get("career_max_m", 0.0)), 1)
	tm_v.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tm_v.add_theme_font_override("font", UITheme.get_display_font())
	tm_v.add_theme_font_size_override("font_size", 14)
	tm_v.add_theme_color_override("font_color", Color("#F5C430"))
	thb.add_child(tm_v)

	# SELURUH KARIERMU
	right_vb.add_child(_make_red_flag_hdr("SELURUH KARIERMU"))
	var cr_hb := HBoxContainer.new()
	cr_hb.add_theme_constant_override("separation", 4)
	right_vb.add_child(cr_hb)
	cr_hb.add_child(_make_peta_stat_pill("JADI SHOT", "%d%%" % int(pdata.get("career_shot_pct", 0)), Color.WHITE))
	cr_hb.add_child(_make_peta_stat_pill("TANPA SHOT", "%d%%" % int(pdata.get("career_no_shot_pct", 0)), Color.WHITE))
	cr_hb.add_child(_make_peta_stat_pill("ASSIST", "%d%%" % int(pdata.get("career_ast_pct", 0)), Color("#F5C430")))

	var cfoot := Label.new()
	cfoot.text = "Dari %d umpan yang sampai • %d umpan kunci" % [int(pdata.get("career_total", 0)), int(pdata.get("career_key_passes", 0))]
	cfoot.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cfoot.add_theme_font_size_override("font_size", 8)
	cfoot.add_theme_color_override("font_color", Color("#94A3B8"))
	right_vb.add_child(cfoot)

func _add_peta_mini_table_row(parent_vb: VBoxContainer, c1: String, c2: String, c3: String, is_hdr: bool) -> void:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	parent_vb.add_child(hb)
	var l1 := Label.new()
	l1.text = c1
	l1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l1.clip_text = true
	l1.add_theme_font_override("font", UITheme.get_display_font())
	l1.add_theme_font_size_override("font_size", 8 if is_hdr else 9)
	l1.add_theme_color_override("font_color", Color("#7C90AB") if is_hdr else Color.WHITE)
	hb.add_child(l1)
	for v_s in [c2, c3]:
		var vl := Label.new()
		vl.text = str(v_s)
		vl.custom_minimum_size = Vector2(54, 0)
		vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		vl.add_theme_font_override("font", UITheme.get_display_font())
		vl.add_theme_font_size_override("font_size", 8 if is_hdr else 9)
		vl.add_theme_color_override("font_color", Color("#7C90AB") if is_hdr else Color.WHITE)
		hb.add_child(vl)

func _render_peta_dribel_body(left_vb: VBoxContainer, body: HBoxContainer, pdata: Dictionary) -> void:
	# Per-Season Inline Stats (replacing Gambar 11 popup cleanly per Gambar 9!)
	var sp_hb := HBoxContainer.new()
	sp_hb.add_theme_constant_override("separation", 5)
	left_vb.add_child(sp_hb)
	sp_hb.add_child(_make_peta_stat_pill("BOLA HILANG", str(int(pdata.get("season_lost", 0))), Color("#F87171")))
	sp_hb.add_child(_make_peta_stat_pill("DILANGGAR", str(int(pdata.get("season_fouled", 0))), Color.WHITE))
	sp_hb.add_child(_make_peta_stat_pill("PENALTI", str(int(pdata.get("season_pen", 0))), Color("#F5C430")))

	var ins := Label.new()
	ins.text = str(pdata.get("insight", ""))
	ins.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ins.add_theme_font_size_override("font_size", 9)
	ins.add_theme_color_override("font_color", Color("#CBD5E1"))
	left_vb.add_child(ins)

	var leg_l := Label.new()
	leg_l.text = "■ Zona Dribel Aktif   × Bola Direbut Lawan"
	leg_l.add_theme_font_size_override("font_size", 8)
	leg_l.add_theme_color_override("font_color", Color("#7C90AB"))
	left_vb.add_child(leg_l)

	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_vb.add_child(sp)

	# Career totals right below in Left Column (Gambar 10!)
	left_vb.add_child(_make_red_flag_hdr("SELURUH KARIERMU"))
	var cr_hb := HBoxContainer.new()
	cr_hb.add_theme_constant_override("separation", 5)
	left_vb.add_child(cr_hb)
	cr_hb.add_child(_make_peta_stat_pill("BOLA HILANG", str(int(pdata.get("career_lost", 0))), Color("#F87171")))
	cr_hb.add_child(_make_peta_stat_pill("DILANGGAR", str(int(pdata.get("career_fouled", 0))), Color.WHITE))
	cr_hb.add_child(_make_peta_stat_pill("PENALTI", str(int(pdata.get("career_pen", 0))), Color("#F5C430")))

	# Right Main Area: Full Horizontal Pitch Dribble Heatmap + Red x Markers (Gambar 10 + 11!)
	var right_vb := VBoxContainer.new()
	right_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vb.add_theme_constant_override("separation", 4)
	body.add_child(right_vb)

	var cap_r := Label.new()
	cap_r.text = "LAPANGAN - kamu menyerang ke kanan  (Musim %d)" % int(pdata.get("season", 1))
	cap_r.add_theme_font_size_override("font_size", 9)
	cap_r.add_theme_color_override("font_color", Color("#94A3B8"))
	right_vb.add_child(cap_r)

	var hmap := WarisanOverlaysScript.DribbleHeatmapCanvas.new()
	hmap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hmap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hmap.configure(pdata.get("heat", []), int(pdata.get("grid_w", 16)), int(pdata.get("grid_h", 10)), pdata.get("lost_pts", []))
	right_vb.add_child(hmap)

# ==============================================================================
# 3. TROFI TAB (Gambar 12: BUKU REKOR + INDIVIDU Grouped Stamps + Team Titles)
# ==============================================================================
func _render_trofi() -> void:
	var sum: Dictionary = CareerState.get_warisan_karier_summary()
	var st: Dictionary = CareerState.career.get("stats", {})
	var m: Dictionary = CareerState.career.get("careerMeta", {})
	var club: Dictionary = CareerState.get_current_club()
	var nat_id: int = clampi(int(CareerState.career.get("playerProfile", {}).get("nationId", 16)), 0, GameData.nations.size() - 1)
	var nat_name: String = str(GameData.nations[nat_id].get("name", "INDONESIA")).to_upper()

	var cols := HBoxContainer.new()
	cols.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.add_theme_constant_override("separation", 12)
	_root_content.add_child(cols)

	# LEFT COLUMN: BUKU REKOR Card (Gambar 12!) + Team Trophies
	var left_vb := VBoxContainer.new()
	left_vb.custom_minimum_size = Vector2(262, 0)
	left_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_vb.add_theme_constant_override("separation", 10)
	cols.add_child(left_vb)

	var rb_p := PanelContainer.new()
	var rbsb := StyleBoxFlat.new()
	rbsb.bg_color = Color("#08101E")
	rbsb.border_color = Color("#E11D48")
	rbsb.set_border_width_all(1)
	rbsb.border_width_bottom = 3
	rbsb.set_corner_radius_all(4)
	rbsb.content_margin_left = 10
	rbsb.content_margin_right = 10
	rbsb.content_margin_top = 10
	rbsb.content_margin_bottom = 10
	rb_p.add_theme_stylebox_override("panel", rbsb)
	left_vb.add_child(rb_p)

	var rbhb := HBoxContainer.new()
	rbhb.add_theme_constant_override("separation", 8)
	rb_p.add_child(rbhb)
	var rbic := CenterContainer.new()
	rbic.add_child(WarisanOverlaysScript.make_icon("bars", Color("#E2E8F0"), Vector2(14, 14)))
	rbhb.add_child(rbic)
	var rbvb := VBoxContainer.new()
	rbvb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rbvb.add_theme_constant_override("separation", 1)
	rbhb.add_child(rbvb)
	var rbl1 := Label.new()
	rbl1.text = "BUKU REKOR"
	rbl1.add_theme_font_override("font", UITheme.get_display_font())
	rbl1.add_theme_font_size_override("font_size", 11)
	rbl1.add_theme_color_override("font_color", Color.WHITE)
	var rbl2 := Label.new()
	rbl2.text = "LIGA • KLUB • DUNIA"
	rbl2.add_theme_font_size_override("font_size", 8)
	rbl2.add_theme_color_override("font_color", Color("#7C90AB"))
	rbvb.add_child(rbl1)
	rbvb.add_child(rbl2)

	var buka_b := Button.new()
	buka_b.text = "BUKA"
	buka_b.custom_minimum_size = Vector2(56, 26)
	UITheme.style_btn(buka_b, Color("#0E1A2D"), Color("#2D4366"), 10)
	buka_b.pressed.connect(func(): AudioSynth.play_click(); open_record_book_modal())
	rbhb.add_child(buka_b)

	# Team Trophies section (if any won)
	var tlist: Array = CareerState.career.get("trophiesList", [])
	left_vb.add_child(_make_red_flag_hdr("GELAR TIM  •  %d" % tlist.size()))
	if tlist.is_empty():
		var empty_t := Label.new()
		empty_t.text = "Belum ada trofi tim.\nMenangkan liga, piala domestik, atau turnamen timnas!"
		empty_t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_t.add_theme_font_size_override("font_size", 9)
		empty_t.add_theme_color_override("font_color", Color("#7C90AB"))
		left_vb.add_child(empty_t)
	else:
		var t_sc := ScrollContainer.new()
		t_sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		t_sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		left_vb.add_child(t_sc)
		var tvb := VBoxContainer.new()
		tvb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tvb.add_theme_constant_override("separation", 4)
		t_sc.add_child(tvb)
		for tr_item in tlist:
			var tp := PanelContainer.new()
			tp.add_theme_stylebox_override("panel", _make_card_sb(Color("#091222"), Color("#273A58"), 5, 8, 5))
			var tl := Label.new()
			tl.text = "M%d • %s" % [int(tr_item.get("season", 1)), str(tr_item.get("name", "Trofi"))]
			tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			tl.add_theme_font_size_override("font_size", 9)
			tl.add_theme_color_override("font_color", Color("#F5C430"))
			tp.add_child(tl)
			tvb.add_child(tp)

	# CENTER COLUMN: INDIVIDU Grouped Stamp Cards (EXACT match to Gambar 12!)
	var mid_vb := VBoxContainer.new()
	mid_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid_vb.size_flags_stretch_ratio = 1.25
	mid_vb.add_theme_constant_override("separation", 8)
	cols.add_child(mid_vb)

	var motm_cnt: int = int(st.get("motm", 0))
	var potm_hist: Array = m.get("potmHistory", [])
	var potm_won: Array = []
	for ph in potm_hist:
		if bool(ph.get("won", false)):
			potm_won.append(ph)
	var poty_hist: Array = m.get("potyHistory", [])
	var poty_won: Array = []
	for py in poty_hist:
		if bool(py.get("won", false)):
			poty_won.append(py)
	var has_boot: bool = (int(st.get("goals", 0)) >= 12)
	var indiv_tot: int = motm_cnt + potm_won.size() + poty_won.size() + (1 if has_boot else 0)

	mid_vb.add_child(_make_red_flag_hdr("INDIVIDU  •  %d" % indiv_tot))

	var m_sc := ScrollContainer.new()
	m_sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	m_sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	mid_vb.add_child(m_sc)
	var ind_vb := VBoxContainer.new()
	ind_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ind_vb.add_theme_constant_override("separation", 8)
	m_sc.add_child(ind_vb)

	var cur_yr: int = int(sum.get("year", 1))
	var c_cid: int = int(club["id"])
	var c_code: String = str(club.get("code", "CLB")).left(3).to_upper()

	# 1. SEPATU (BENUA / LIGA)
	if has_boot:
		ind_vb.add_child(_make_trophy_group_card("boot", "SEPATU EMAS", 1, [
			{"season": cur_yr, "is_flag": true, "id": nat_id, "code": nat_name}
		]))

	# 2. PEMAIN TERBAIK LAGA (MOTM)
	var motm_stamps: Array[Dictionary] = []
	var sh_rows: Array = sum.get("season_rows", [])
	for mi in range(motm_cnt):
		var sr_use: Dictionary = sh_rows[mi % sh_rows.size()] if not sh_rows.is_empty() else {"season": cur_yr, "club_id": c_cid, "club_code": c_code}
		motm_stamps.append({
			"season": int(sr_use.get("season", cur_yr)),
			"is_flag": false,
			"id": int(sr_use.get("club_id", c_cid)),
			"code": str(sr_use.get("club_code", c_code)).left(3).to_upper(),
		})
	ind_vb.add_child(_make_trophy_group_card("star", "PEMAIN TERBAIK LAGA", motm_cnt, motm_stamps))

	# 3. PEMAIN TERBAIK BULAN INI (POTM)
	var potm_stamps: Array[Dictionary] = []
	for ph in potm_won:
		potm_stamps.append({"season": int(ph.get("year", cur_yr)), "is_flag": false, "id": c_cid, "code": c_code})
	ind_vb.add_child(_make_trophy_group_card("cal_star", "PEMAIN TERBAIK BULAN INI", potm_won.size(), potm_stamps))

	# 4. PEMAIN TERBAIK TAHUN INI (POTY)
	if not poty_won.is_empty():
		var poty_stamps: Array[Dictionary] = []
		for py in poty_won:
			poty_stamps.append({"season": int(py.get("year", cur_yr)), "is_flag": false, "id": c_cid, "code": c_code})
		ind_vb.add_child(_make_trophy_group_card("trophy", "PEMAIN TERBAIK TAHUN INI", poty_won.size(), poty_stamps))

	# RIGHT COLUMN: Helper note + Contested Trophies Preview (Gambar 12!)
	var right_vb := VBoxContainer.new()
	right_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vb.size_flags_stretch_ratio = 0.85
	right_vb.add_theme_constant_override("separation", 10)
	cols.add_child(right_vb)

	var note_l := Label.new()
	note_l.text = "Tiap cap adalah satu gelar: musim • klub • divisi."
	note_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note_l.add_theme_font_size_override("font_size", 10)
	note_l.add_theme_color_override("font_color", Color("#94A3B8"))
	right_vb.add_child(note_l)

	right_vb.add_child(_make_red_flag_hdr("YANG DIPEREBUTKAN"))
	var cgrid := GridContainer.new()
	cgrid.columns = 2
	cgrid.add_theme_constant_override("h_separation", 6)
	cgrid.add_theme_constant_override("v_separation", 6)
	right_vb.add_child(cgrid)
	for ct in [
		["liga", "JUARA LIGA", Color("#F5C430")],
		["piala", "PIALA NASIONAL", Color("#22D3EE")],
		["kont", "PIALA ELITE", Color("#60A5FA")],
		["dunia", "PIALA DUNIA", Color("#E59A38")],
	]:
		var cpc := PanelContainer.new()
		cpc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cpc.add_theme_stylebox_override("panel", _make_card_sb(Color("#091222"), Color("#182840"), 5, 8, 6))
		var chb := HBoxContainer.new()
		chb.add_theme_constant_override("separation", 6)
		cpc.add_child(chb)
		chb.add_child(WarisanOverlaysScript.make_icon(str(ct[0]), ct[2], Vector2(14, 14)))
		var cl := Label.new()
		cl.text = str(ct[1])
		cl.clip_text = true
		cl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cl.add_theme_font_override("font", UITheme.get_display_font())
		cl.add_theme_font_size_override("font_size", 9)
		cl.add_theme_color_override("font_color", Color("#CBD5E1"))
		chb.add_child(cl)
		cgrid.add_child(cpc)

func _make_trophy_group_card(icon_k: String, title_txt: String, count_n: int, stamps: Array) -> PanelContainer:
	var pc := PanelContainer.new()
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pc.add_theme_stylebox_override("panel", _make_card_sb(Color("#08101E"), Color("#1E2F4A"), 6, 10, 8))

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	pc.add_child(hb)

	# Left: Big icon + optional red xN badge (Gambar 12!)
	var ic_box := Control.new()
	ic_box.custom_minimum_size = Vector2(40, 40)
	hb.add_child(ic_box)
	var ic_col: Color = Color("#F5C430") if icon_k in ["star", "trophy"] else Color("#E2E8F0")
	var ic_ctrl: Control = WarisanOverlaysScript.make_icon(icon_k, ic_col, Vector2(30, 30))
	ic_ctrl.position = Vector2(4, 6)
	ic_box.add_child(ic_ctrl)

	if count_n > 1:
		var bdg := PanelContainer.new()
		bdg.position = Vector2(14, 0)
		var bsb := StyleBoxFlat.new()
		bsb.bg_color = Color("#DC2626")
		bsb.set_corner_radius_all(3)
		bsb.content_margin_left = 4
		bsb.content_margin_right = 4
		bsb.content_margin_top = 0
		bsb.content_margin_bottom = 0
		bdg.add_theme_stylebox_override("panel", bsb)
		var bl := Label.new()
		bl.text = "x%d" % count_n
		bl.add_theme_font_override("font", UITheme.get_display_font())
		bl.add_theme_font_size_override("font_size", 8)
		bl.add_theme_color_override("font_color", Color.WHITE)
		bdg.add_child(bl)
		ic_box.add_child(bdg)

	# Right: Title + 3-column stamp chips
	var rvb := VBoxContainer.new()
	rvb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rvb.add_theme_constant_override("separation", 5)
	hb.add_child(rvb)

	var tl := Label.new()
	tl.text = title_txt
	tl.add_theme_font_override("font", UITheme.get_display_font())
	tl.add_theme_font_size_override("font_size", 11)
	tl.add_theme_color_override("font_color", Color.WHITE)
	rvb.add_child(tl)

	if stamps.is_empty():
		var el := Label.new()
		el.text = "Belum diraih"
		el.add_theme_font_size_override("font_size", 9)
		el.add_theme_color_override("font_color", Color("#64748B"))
		rvb.add_child(el)
	else:
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 4)
		flow.add_theme_constant_override("v_separation", 4)
		rvb.add_child(flow)
		var cap_n: int = mini(11, stamps.size())
		for si in range(cap_n):
			var st_d: Dictionary = stamps[si]
			var spc := PanelContainer.new()
			spc.add_theme_stylebox_override("panel", _make_card_sb(Color("#132238"), Color("#243957"), 3, 5, 2))
			var shb := HBoxContainer.new()
			shb.add_theme_constant_override("separation", 4)
			spc.add_child(shb)
			var ml := Label.new()
			ml.text = "M%d" % int(st_d.get("season", 1))
			ml.add_theme_font_size_override("font_size", 8)
			ml.add_theme_color_override("font_color", Color("#94A3B8"))
			shb.add_child(ml)
			if bool(st_d.get("is_flag", false)):
				shb.add_child(UITheme.make_flag_rect(int(st_d.get("id", 0)), Vector2(14, 9)))
			else:
				var cr := ClubCrest.new()
				cr.custom_minimum_size = Vector2(12, 12)
				cr.set_club(int(st_d.get("id", 0)))
				shb.add_child(cr)
			var cl := Label.new()
			cl.text = str(st_d.get("code", "CLB"))
			cl.add_theme_font_override("font", UITheme.get_display_font())
			cl.add_theme_font_size_override("font_size", 8)
			cl.add_theme_color_override("font_color", Color.WHITE)
			shb.add_child(cl)
			flow.add_child(spc)
		if stamps.size() > cap_n:
			var ov_p := PanelContainer.new()
			ov_p.add_theme_stylebox_override("panel", _make_card_sb(Color("#1A2D4A"), Color("#38BDF8"), 3, 6, 2))
			var ov_l := Label.new()
			ov_l.text = "+%d" % (stamps.size() - cap_n)
			ov_l.add_theme_font_override("font", UITheme.get_display_font())
			ov_l.add_theme_font_size_override("font_size", 8)
			ov_l.add_theme_color_override("font_color", Color.WHITE)
			ov_p.add_child(ov_l)
			flow.add_child(ov_p)
	return pc

# ==============================================================================
# 4. KLUB TAB (Gambar 13 + Popups Gambar 14 LIGA, Gambar 15 PIALA & KONTINENTAL!)
# ==============================================================================
func _render_klub() -> void:
	var rdata: Dictionary = CareerState.get_decorated_clubs_ranking(_klub_scope, "tot")
	var entries: Array = rdata.get("list", [])
	var my_entry: Dictionary = rdata.get("my_entry", {})
	var my_rank: int = int(rdata.get("my_rank", 51))
	var leaders: Dictionary = rdata.get("leaders", {})

	var cols := HBoxContainer.new()
	cols.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.add_theme_constant_override("separation", 14)
	_root_content.add_child(cols)

	# LEFT COLUMN: Scope Dropdown + ? + Trophy Ranking Table + Sticky Bottom User Club Row
	var left_vb := VBoxContainer.new()
	left_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_vb.size_flags_stretch_ratio = 1.32
	left_vb.add_theme_constant_override("separation", 5)
	cols.add_child(left_vb)

	var top_hb := HBoxContainer.new()
	top_hb.add_theme_constant_override("separation", 6)
	left_vb.add_child(top_hb)

	var scope_b := Button.new()
	scope_b.custom_minimum_size = Vector2(210, 30)
	var ssb := _make_card_sb(Color("#08101E"), Color("#1E314E"), 4, 10, 4)
	var ssbh := ssb.duplicate()
	ssbh.border_color = UITheme.ACCENT_CYAN
	scope_b.add_theme_stylebox_override("normal", ssb)
	scope_b.add_theme_stylebox_override("hover", ssbh)
	scope_b.add_theme_stylebox_override("pressed", ssbh)
	var sc_hb := HBoxContainer.new()
	sc_hb.set_anchors_preset(Control.PRESET_FULL_RECT)
	sc_hb.offset_left = 10
	sc_hb.offset_right = -10
	sc_hb.add_theme_constant_override("separation", 7)
	sc_hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scope_b.add_child(sc_hb)
	sc_hb.add_child(WarisanOverlaysScript.make_icon("globe", Color("#8EA3BC"), Vector2(12, 12)))
	var sc_l := Label.new()
	sc_l.text = _klub_scope
	sc_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sc_l.add_theme_font_override("font", UITheme.get_display_font())
	sc_l.add_theme_font_size_override("font_size", 10)
	sc_l.add_theme_color_override("font_color", Color.WHITE)
	sc_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sc_hb.add_child(sc_l)
	var caret := Label.new()
	caret.text = "v"
	caret.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caret.add_theme_font_size_override("font_size", 10)
	caret.add_theme_color_override("font_color", Color("#94A3B8"))
	caret.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sc_hb.add_child(caret)
	scope_b.pressed.connect(func():
		AudioSynth.play_click()
		var order := ["DUNIA", "BENUA", "NEGARAMU"]
		var idx: int = (order.find(_klub_scope) + 1) % order.size()
		_klub_scope = order[idx]
		refresh()
	)
	top_hb.add_child(scope_b)

	var help_b := Button.new()
	help_b.text = "?"
	help_b.custom_minimum_size = Vector2(30, 30)
	UITheme.style_btn(help_b, Color("#0E1A2D"), Color("#2D4366"), 12)
	help_b.pressed.connect(func():
		AudioSynth.play_click()
		_klub_help_open = not _klub_help_open
		refresh()
	)
	top_hb.add_child(help_b)

	if _klub_help_open:
		var h_note := Label.new()
		h_note.text = "Total gelar = Liga Domestik + Piala Nasional + Piala Kontinental + Piala Dunia Klub."
		h_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		h_note.add_theme_font_size_override("font_size", 9)
		h_note.add_theme_color_override("font_color", UITheme.ACCENT_CYAN)
		left_vb.add_child(h_note)

	# Table Column Icons Header: (Club) | Liga | Piala | Kont | Dunia | TOT
	var thb := HBoxContainer.new()
	thb.add_theme_constant_override("separation", 6)
	left_vb.add_child(thb)
	var sp_h := Control.new()
	sp_h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	thb.add_child(sp_h)
	for ic_def in [["liga", Color("#94A3B8")], ["piala", Color("#F5C430")], ["kont", Color("#60A5FA")], ["dunia", Color("#94A3B8")]]:
		var ic_w := CenterContainer.new()
		ic_w.custom_minimum_size = Vector2(24, 14)
		ic_w.add_child(WarisanOverlaysScript.make_icon(str(ic_def[0]), ic_def[1], Vector2(12, 12)))
		thb.add_child(ic_w)
	var tot_h := Label.new()
	tot_h.text = "TOT"
	tot_h.custom_minimum_size = Vector2(32, 0)
	tot_h.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tot_h.add_theme_font_size_override("font_size", 9)
	tot_h.add_theme_color_override("font_color", Color("#7C90AB"))
	thb.add_child(tot_h)

	# Scrollable Top Decorated Clubs List
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left_vb.add_child(sc)
	var lvb := VBoxContainer.new()
	lvb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lvb.add_theme_constant_override("separation", 2)
	sc.add_child(lvb)

	var user_in_top := false
	var disp_n: int = mini(16, entries.size())
	var prev_tot: int = -1
	var disp_rk: int = 1
	for i in range(disp_n):
		var e: Dictionary = entries[i]
		var tv: int = int(e.get("tot", 0))
		if i > 0 and tv != prev_tot:
			disp_rk = i + 1
		prev_tot = tv
		var is_me: bool = bool(e.get("is_user_club", false))
		if is_me:
			user_in_top = true
		lvb.add_child(_make_klub_table_row(disp_rk, e, is_me))

	if not user_in_top and not my_entry.is_empty():
		var dots := Label.new()
		dots.text = "      . . ."
		dots.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dots.add_theme_font_size_override("font_size", 9)
		dots.add_theme_color_override("font_color", Color("#64748B"))
		left_vb.add_child(dots)
		left_vb.add_child(_make_klub_table_row(my_rank, my_entry, true))

	# RIGHT COLUMN: User Club Rank + Trophy Breakdown + 3 Clickable Record Cards (LIGA / PIALA / KONTINENTAL) + JUARA Button
	var right_vb := VBoxContainer.new()
	right_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vb.size_flags_stretch_ratio = 0.92
	right_vb.add_theme_constant_override("separation", 7)
	cols.add_child(right_vb)

	var rk_big := Label.new()
	rk_big.text = "ke-%d" % my_rank
	rk_big.add_theme_font_override("font", UITheme.get_display_font())
	rk_big.add_theme_font_size_override("font_size", 24)
	rk_big.add_theme_color_override("font_color", Color.WHITE)
	right_vb.add_child(rk_big)

	var rk_sub := Label.new()
	rk_sub.text = "%d GELAR  •  -%d DARI KE-%d" % [int(my_entry.get("tot", 0)), int(rdata.get("gap_to_next", 1)), int(rdata.get("next_rank", maxi(1, my_rank - 1)))]
	rk_sub.add_theme_font_size_override("font_size", 9)
	rk_sub.add_theme_color_override("font_color", Color("#94A3B8"))
	right_vb.add_child(rk_sub)

	# User Club Crest + 2x2 Trophy Breakdown
	var br_hb := HBoxContainer.new()
	br_hb.add_theme_constant_override("separation", 12)
	right_vb.add_child(br_hb)
	var bcr_c := CenterContainer.new()
	bcr_c.add_child(WarisanOverlaysScript.make_club_mini_crest(my_entry, Vector2(44, 44)))
	br_hb.add_child(bcr_c)

	var br_grid := GridContainer.new()
	br_grid.columns = 2
	br_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	br_grid.add_theme_constant_override("h_separation", 14)
	br_grid.add_theme_constant_override("v_separation", 6)
	br_hb.add_child(br_grid)
	for bd in [
		["liga", int(my_entry.get("liga", 0)), Color("#CBD5E1")],
		["piala", int(my_entry.get("piala", 0)), Color("#F5C430")],
		["kont", int(my_entry.get("kont", 0)), Color("#60A5FA")],
		["dunia", int(my_entry.get("dunia", 0)), Color("#94A3B8")],
	]:
		var ihb := HBoxContainer.new()
		ihb.add_theme_constant_override("separation", 6)
		ihb.add_child(WarisanOverlaysScript.make_icon(str(bd[0]), bd[2], Vector2(14, 14)))
		var ivl := Label.new()
		ivl.text = str(int(bd[1]))
		ivl.add_theme_font_override("font", UITheme.get_display_font())
		ivl.add_theme_font_size_override("font_size", 14)
		ivl.add_theme_color_override("font_color", Color.WHITE if int(bd[1]) > 0 else Color("#64748B"))
		ihb.add_child(ivl)
		br_grid.add_child(ihb)

	# 3 Clickable Category Cards: LIGA (Gambar 14), PIALA (Gambar 15), KONTINENTAL
	for cat_def in [
		["liga", "LIGA", "liga", Color("#CBD5E1")],
		["piala", "PIALA", "piala", Color("#F5C430")],
		["kont", "KONTINENTAL", "kont", Color("#60A5FA")],
	]:
		var ck: String = str(cat_def[0])
		var ld: Dictionary = leaders.get(ck, {})
		var top_c: Dictionary = ld.get("top", {})
		var top_v: int = int(top_c.get(ck, 0))
		var my_c_rk: int = int(ld.get("my_rank", 1))
		right_vb.add_child(_make_klub_category_btn(ck, str(cat_def[1]), str(cat_def[2]), cat_def[3], top_c, top_v, my_c_rk))

	var sp_r := Control.new()
	sp_r.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vb.add_child(sp_r)

	# Bottom Amber-Gold JUARA Button (Gambar 13!)
	var j_btn := Button.new()
	j_btn.custom_minimum_size = Vector2(0, 38)
	j_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var jsb := StyleBoxFlat.new()
	jsb.bg_color = Color("#5A3B14")
	jsb.border_color = Color("#A86F23")
	jsb.set_border_width_all(1)
	jsb.border_width_bottom = 3
	jsb.set_corner_radius_all(4)
	var jsbh := jsb.duplicate()
	jsbh.bg_color = Color("#724C1B")
	jsbh.border_color = Color("#F5C430")
	j_btn.add_theme_stylebox_override("normal", jsb)
	j_btn.add_theme_stylebox_override("hover", jsbh)
	j_btn.add_theme_stylebox_override("pressed", jsbh)
	var jhb := HBoxContainer.new()
	jhb.set_anchors_preset(Control.PRESET_FULL_RECT)
	jhb.offset_left = 12
	jhb.offset_right = -10
	jhb.add_theme_constant_override("separation", 8)
	jhb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	j_btn.add_child(jhb)
	jhb.add_child(WarisanOverlaysScript.make_icon("shield", Color("#F3CFA0"), Vector2(14, 14)))
	var jl := Label.new()
	jl.text = "JUARA"
	jl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	jl.add_theme_font_override("font", UITheme.get_display_font())
	jl.add_theme_font_size_override("font_size", 11)
	jl.add_theme_color_override("font_color", Color("#FBE5C4"))
	jl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	jhb.add_child(jl)
	j_btn.pressed.connect(func(): AudioSynth.play_click(); open_champions_modal())
	right_vb.add_child(j_btn)

func _make_klub_table_row(rank_num: int, entry: Dictionary, is_me: bool) -> PanelContainer:
	var pc := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#2C261A") if is_me else Color(0, 0, 0, 0)
	sb.border_color = Color("#735C2B") if is_me else Color.TRANSPARENT
	sb.set_border_width_all(1 if is_me else 0)
	sb.set_corner_radius_all(3)
	sb.content_margin_left = 4
	sb.content_margin_right = 4
	sb.content_margin_top = 1
	sb.content_margin_bottom = 1
	pc.add_theme_stylebox_override("panel", sb)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	pc.add_child(hb)

	var rl := Label.new()
	rl.text = str(rank_num)
	rl.custom_minimum_size = Vector2(22, 0)
	rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	rl.add_theme_font_override("font", UITheme.get_display_font())
	rl.add_theme_font_size_override("font_size", 10)
	rl.add_theme_color_override("font_color", Color("#E5C07B") if is_me else Color("#7C90AB"))
	hb.add_child(rl)

	var cc := CenterContainer.new()
	cc.add_child(WarisanOverlaysScript.make_club_mini_crest(entry, Vector2(14, 14)))
	hb.add_child(cc)

	var nl := Label.new()
	nl.text = str(entry.get("name", "Klub"))
	nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nl.clip_text = true
	nl.add_theme_font_override("font", UITheme.get_display_font())
	nl.add_theme_font_size_override("font_size", 10)
	nl.add_theme_color_override("font_color", Color("#F8FAFC"))
	hb.add_child(nl)

	for ck in ["liga", "piala", "kont", "dunia"]:
		var iv: int = int(entry.get(ck, 0))
		var vl := Label.new()
		vl.text = str(iv)
		vl.custom_minimum_size = Vector2(24, 0)
		vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		vl.add_theme_font_override("font", UITheme.get_display_font())
		vl.add_theme_font_size_override("font_size", 10)
		vl.add_theme_color_override("font_color", Color("#CBD5E1") if iv > 0 else Color("#475B75"))
		hb.add_child(vl)

	var tot_l := Label.new()
	tot_l.text = str(int(entry.get("tot", 0)))
	tot_l.custom_minimum_size = Vector2(32, 0)
	tot_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tot_l.add_theme_font_override("font", UITheme.get_display_font())
	tot_l.add_theme_font_size_override("font_size", 11)
	tot_l.add_theme_color_override("font_color", Color.WHITE)
	hb.add_child(tot_l)
	return pc

func _make_klub_category_btn(cat_key: String, title_txt: String, icon_k: String, icon_col: Color, top_club: Dictionary, top_val: int, my_cat_rank: int) -> Button:
	var btn := Button.new()
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, 48)
	var sb := _make_card_sb(Color("#08101E"), Color("#182840"), 5, 10, 6)
	var sbh := sb.duplicate()
	sbh.bg_color = Color("#112138")
	sbh.border_color = UITheme.ACCENT_CYAN
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sbh)
	btn.add_theme_stylebox_override("pressed", sbh)
	btn.add_theme_stylebox_override("focus", sbh)

	var hb := HBoxContainer.new()
	hb.set_anchors_preset(Control.PRESET_FULL_RECT)
	hb.offset_left = 10
	hb.offset_right = -12
	hb.add_theme_constant_override("separation", 8)
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(hb)

	var ic_c := CenterContainer.new()
	ic_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ic_c.add_child(WarisanOverlaysScript.make_icon(icon_k, icon_col, Vector2(15, 15)))
	hb.add_child(ic_c)

	var cr_c := CenterContainer.new()
	cr_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cr_c.add_child(WarisanOverlaysScript.make_club_mini_crest(top_club, Vector2(20, 20)))
	hb.add_child(cr_c)

	var mvb := VBoxContainer.new()
	mvb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mvb.alignment = BoxContainer.ALIGNMENT_CENTER
	mvb.add_theme_constant_override("separation", 0)
	mvb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(mvb)

	var l1 := Label.new()
	l1.text = title_txt
	l1.add_theme_font_size_override("font_size", 8)
	l1.add_theme_color_override("font_color", Color("#7C90AB"))
	l1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l2 := Label.new()
	l2.text = str(top_club.get("name", "KLUB")).to_upper()
	l2.clip_text = true
	l2.add_theme_font_override("font", UITheme.get_display_font())
	l2.add_theme_font_size_override("font_size", 10)
	l2.add_theme_color_override("font_color", Color.WHITE)
	l2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l3 := Label.new()
	l3.text = "KAMU KE-%d" % my_cat_rank
	l3.add_theme_font_size_override("font_size", 8)
	l3.add_theme_color_override("font_color", Color("#94A3B8"))
	l3.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mvb.add_child(l1)
	mvb.add_child(l2)
	mvb.add_child(l3)

	var vl := Label.new()
	vl.text = str(top_val)
	vl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	vl.add_theme_font_override("font", UITheme.get_display_font())
	vl.add_theme_font_size_override("font_size", 15)
	vl.add_theme_color_override("font_color", Color("#E59A38"))
	vl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(vl)

	btn.pressed.connect(func():
		AudioSynth.play_click()
		open_club_category_modal(cat_key)
	)
	return btn

# ==============================================================================
# 5. LEGENDA TAB HUB (Gambar 2 + Gambar 6 Mod: No 'Pernah Di Sini' -> LEGENDA TIMNAS)
# ==============================================================================
func _make_crimson_hub_btn(title_txt: String, cb: Callable, sub_txt: String = "") -> Button:
	var b := Button.new()
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, 46 if sub_txt.is_empty() else 52)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.clip_contents = true
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#060D1A")
	sb.border_color = Color("#1B2D48")
	sb.set_border_width_all(1)
	sb.border_width_bottom = 2
	sb.set_corner_radius_all(4)
	var sbh := sb.duplicate()
	sbh.bg_color = Color("#121F35")
	sbh.border_color = Color("#DC2E44")
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_stylebox_override("hover", sbh)
	b.add_theme_stylebox_override("pressed", sbh)
	b.add_theme_stylebox_override("focus", sbh)

	var accent_bar := ColorRect.new()
	accent_bar.color = Color("#DC2E44")
	accent_bar.anchor_left = 0.0
	accent_bar.anchor_top = 0.0
	accent_bar.anchor_right = 0.0
	accent_bar.anchor_bottom = 1.0
	accent_bar.offset_right = 4.0
	accent_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(accent_bar)

	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 14)
	m.add_theme_constant_override("margin_right", 10)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(m)

	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 2)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	m.add_child(vb)

	var l1 := Label.new()
	l1.text = title_txt
	l1.add_theme_font_override("font", UITheme.get_display_font())
	l1.add_theme_font_size_override("font_size", 12)
	l1.add_theme_color_override("font_color", Color.WHITE)
	l1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(l1)

	if not sub_txt.is_empty():
		var l2 := Label.new()
		l2.text = sub_txt
		l2.add_theme_font_size_override("font_size", 8)
		l2.add_theme_color_override("font_color", Color("#94ADC8"))
		l2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vb.add_child(l2)

	b.pressed.connect(func():
		AudioSynth.play_click()
		cb.call()
	)
	return b

func _render_legenda() -> void:
	var club: Dictionary = CareerState.get_current_club()
	var club_nid: int = clampi(int(club.get("nation_id", 1)), 0, GameData.nations.size() - 1)
	if _legenda_league_nat < 0 or _legenda_league_nat >= GameData.nations.size():
		_legenda_league_nat = club_nid

	var nat_ids: Array[int] = []
	for ni in range(GameData.nations.size()):
		if not GameData.get_clubs_in_nation(ni).is_empty():
			nat_ids.append(ni)
	if nat_ids.is_empty():
		nat_ids.append(0)
	if nat_ids.find(_legenda_league_nat) < 0:
		_legenda_league_nat = nat_ids[0]

	var cols := HBoxContainer.new()
	cols.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.add_theme_constant_override("separation", 14)
	_root_content.add_child(cols)

	# ------------------------------------------------------------------
	# COLUMN 1 (LEFT): Micro Legend Guide + LEGENDA DUNIA + GOL+ASSIST + PRODUKSIMU
	# ------------------------------------------------------------------
	var left_vb := VBoxContainer.new()
	left_vb.custom_minimum_size = Vector2(244, 0)
	left_vb.add_theme_constant_override("separation", 8)
	cols.add_child(left_vb)

	# 6-Icon Legend Key (Gambar 2 top-left)
	var key_grid := GridContainer.new()
	key_grid.columns = 2
	key_grid.add_theme_constant_override("h_separation", 8)
	key_grid.add_theme_constant_override("v_separation", 3)
	left_vb.add_child(key_grid)
	for kd in [
		["ballon", Color("#F5C430"), "Pemain Terbaik"],
		["boot", Color("#EAB308"), "Sepatu Emas"],
		["liga", Color("#CBD5E1"), "Liga"],
		["piala", Color("#E59A38"), "Piala"],
		["kont", Color("#93C5FD"), "Kontinental"],
		["dunia", Color("#FACC15"), "Kejuaraan Dunia"],
	]:
		var khb := HBoxContainer.new()
		khb.add_theme_constant_override("separation", 4)
		var kic := CenterContainer.new()
		kic.add_child(WarisanOverlaysScript.make_icon(str(kd[0]), kd[1], Vector2(10, 10)))
		khb.add_child(kic)
		var kl := Label.new()
		kl.text = str(kd[2])
		kl.add_theme_font_size_override("font_size", 8)
		kl.add_theme_color_override("font_color", Color("#A7BCD4"))
		khb.add_child(kl)
		key_grid.add_child(khb)

	left_vb.add_child(_make_crimson_hub_btn("LEGENDA DUNIA", func(): open_world_legends_modal()))
	left_vb.add_child(_make_crimson_hub_btn("GOL + ASSIST", func(): open_goals_assists_modal()))

	var sp_l := Control.new()
	sp_l.custom_minimum_size = Vector2(0, 4)
	left_vb.add_child(sp_l)

	# PRODUKSIMU • PER KATEGORI
	left_vb.add_child(WarisanOverlaysScript.make_flag_section_header("PRODUKSIMU • PER KATEGORI", 10))
	var prod: Dictionary = CareerState.get_user_elite_production()
	for prow in [
		["ELIT (D1 +\nTIMNAS)", int(prod["elite_g"]), int(prod["elite_a"]), int(prod["elite_ga"])],
		["TOTAL (SEMUA\nKATEGORI)", int(prod["total_g"]), int(prod["total_a"]), int(prod["total_ga"])],
	]:
		var rhb := HBoxContainer.new()
		rhb.add_theme_constant_override("separation", 6)
		left_vb.add_child(rhb)
		var rl := Label.new()
		rl.text = str(prow[0])
		rl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rl.add_theme_font_override("font", UITheme.get_display_font())
		rl.add_theme_font_size_override("font_size", 9)
		rl.add_theme_color_override("font_color", Color.WHITE)
		rhb.add_child(rl)
		rhb.add_child(WarisanOverlaysScript._make_stacked_stat("G", str(int(prow[1])), 30, Color.WHITE, 11))
		rhb.add_child(WarisanOverlaysScript._make_stacked_stat("A", str(int(prow[2])), 26, Color.WHITE, 11))
		rhb.add_child(WarisanOverlaysScript._make_stacked_stat("G+A", str(int(prow[3])), 34, Color.WHITE, 11))

	var diff_g: int = int(prod["diff_g"])
	var diff_a: int = int(prod["diff_a"])
	var fn_lbl := Label.new()
	if diff_g > 0 or diff_a > 0:
		fn_lbl.text = "Selisihnya (%d G • %d A) diraih di divisi dua dan tiga." % [diff_g, diff_a]
	else:
		fn_lbl.text = "Semua gol & assist diraih di kasta tertinggi dan timnas."
	fn_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fn_lbl.add_theme_font_size_override("font_size", 8)
	fn_lbl.add_theme_color_override("font_color", Color("#7C90AB"))
	left_vb.add_child(fn_lbl)

	# ------------------------------------------------------------------
	# COLUMN 2 (CENTER): LEGENDA PER LIGA (< [Flag] LIGA ... >) + LEGENDA PER KLUB
	# ------------------------------------------------------------------
	var mid_vb := VBoxContainer.new()
	mid_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid_vb.custom_minimum_size = Vector2(360, 0)
	mid_vb.add_theme_constant_override("separation", 6)
	cols.add_child(mid_vb)

	mid_vb.add_child(WarisanOverlaysScript.make_flag_section_header("LEGENDA PER LIGA", 12))

	var ldata: Dictionary = CareerState.get_legends_by_league(_legenda_league_nat)
	var nav_bar := PanelContainer.new()
	nav_bar.add_theme_stylebox_override("panel", _make_card_sb(Color("#0A1527"), Color("#1F3352"), 4, 4, 3))
	mid_vb.add_child(nav_bar)
	var nhb := HBoxContainer.new()
	nhb.add_theme_constant_override("separation", 6)
	nav_bar.add_child(nhb)

	var prev_lg := WarisanOverlaysScript._make_crimson_nav_btn("<")
	prev_lg.pressed.connect(func():
		AudioSynth.play_click()
		var idx: int = nat_ids.find(_legenda_league_nat)
		_legenda_league_nat = nat_ids[(idx - 1 + nat_ids.size()) % nat_ids.size()]
		refresh()
	)
	nhb.add_child(prev_lg)

	var lg_mid := HBoxContainer.new()
	lg_mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lg_mid.alignment = BoxContainer.ALIGNMENT_CENTER
	lg_mid.add_theme_constant_override("separation", 7)
	nhb.add_child(lg_mid)
	var lfc := CenterContainer.new()
	lfc.add_child(UITheme.make_flag_rect(_legenda_league_nat, Vector2(16, 11)))
	lg_mid.add_child(lfc)
	var l_lbl := Label.new()
	l_lbl.text = str(ldata.get("league_name", "LIGA SPANYOL"))
	l_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l_lbl.add_theme_font_override("font", UITheme.get_display_font())
	l_lbl.add_theme_font_size_override("font_size", 11)
	l_lbl.add_theme_color_override("font_color", Color.WHITE)
	lg_mid.add_child(l_lbl)

	var next_lg := WarisanOverlaysScript._make_crimson_nav_btn(">")
	next_lg.pressed.connect(func():
		AudioSynth.play_click()
		var idx: int = nat_ids.find(_legenda_league_nat)
		_legenda_league_nat = nat_ids[(idx + 1) % nat_ids.size()]
		refresh()
	)
	nhb.add_child(next_lg)

	var lg_rows_vb := VBoxContainer.new()
	lg_rows_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lg_rows_vb.add_theme_constant_override("separation", 7)
	mid_vb.add_child(lg_rows_vb)
	for lg_item in ldata.get("legends", []):
		var lg: Dictionary = lg_item
		lg_rows_vb.add_child(WarisanOverlaysScript._make_legend_entry_block(0, lg, true))

	mid_vb.add_child(_make_crimson_hub_btn("LEGENDA PER KLUB", func(): open_club_legends_modal()))

	# ------------------------------------------------------------------
	# COLUMN 3 (RIGHT): ANDALAN + LEGENDA TIMNAS (Replaces 'PERNAH DI SINI' per User Request!)
	# ------------------------------------------------------------------
	var right_vb := VBoxContainer.new()
	right_vb.custom_minimum_size = Vector2(268, 0)
	right_vb.add_theme_constant_override("separation", 8)
	cols.add_child(right_vb)

	right_vb.add_child(WarisanOverlaysScript.make_flag_section_header("ANDALAN", 12))
	var and_desc := Label.new()
	and_desc.text = "Sepuluh musim berturut-turut atau lebih di klub. Pinjaman tidak memutus catatan itu."
	and_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	and_desc.add_theme_font_size_override("font_size", 9)
	and_desc.add_theme_color_override("font_color", Color("#94ADC8"))
	right_vb.add_child(and_desc)

	var stalwarts: Array[Dictionary] = CareerState.get_club_andalan_stalwarts(int(club.get("id", 0)))
	for sw in stalwarts:
		var shb := HBoxContainer.new()
		shb.custom_minimum_size = Vector2(0, 28)
		shb.add_theme_constant_override("separation", 6)
		right_vb.add_child(shb)

		var sfc := CenterContainer.new()
		sfc.add_child(UITheme.make_flag_rect(int(sw.get("nat", 1)), Vector2(15, 10)))
		shb.add_child(sfc)

		var snm := Label.new()
		snm.text = str(sw.get("name", "Pemain"))
		snm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		snm.clip_text = true
		snm.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		snm.add_theme_font_override("font", UITheme.get_display_font())
		snm.add_theme_font_size_override("font_size", 10)
		snm.add_theme_color_override("font_color", Color.WHITE)
		shb.add_child(snm)

		var s_since := Label.new()
		s_since.text = str(sw.get("since", "SEJAK M1"))
		s_since.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		s_since.add_theme_font_size_override("font_size", 8)
		s_since.add_theme_color_override("font_color", Color("#7C90AB"))
		shb.add_child(s_since)

		shb.add_child(WarisanOverlaysScript._make_stacked_stat("MUSIM", str(int(sw.get("seasons", 10))), 34, Color.WHITE, 12))

	var sp_r := Control.new()
	sp_r.custom_minimum_size = Vector2(0, 6)
	right_vb.add_child(sp_r)

	# LEGENDA TIMNAS section (explicitly replacing 'PERNAH DI SINI'!)
	right_vb.add_child(WarisanOverlaysScript.make_flag_section_header("TIMNAS", 12))
	var tn_desc := Label.new()
	tn_desc.text = "Lihat daftar legenda tim nasional berdasarkan koleksi piala internasional dan catatan gol + assist."
	tn_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tn_desc.add_theme_font_size_override("font_size", 9)
	tn_desc.add_theme_color_override("font_color", Color("#94ADC8"))
	right_vb.add_child(tn_desc)

	var u_nat: int = int(prod["nat"])
	var u_nat_name: String = str(GameData.nations[u_nat].get("name", "Indonesia")).to_upper()
	var u_tn_card := PanelContainer.new()
	u_tn_card.add_theme_stylebox_override("panel", _make_card_sb(Color("#0A1527"), Color("#1E3352"), 5, 10, 7))
	right_vb.add_child(u_tn_card)
	var uthb := HBoxContainer.new()
	uthb.add_theme_constant_override("separation", 8)
	u_tn_card.add_child(uthb)
	var ufc := CenterContainer.new()
	ufc.add_child(UITheme.make_flag_rect(u_nat, Vector2(20, 14)))
	uthb.add_child(ufc)
	var utvb := VBoxContainer.new()
	utvb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	utvb.add_theme_constant_override("separation", 1)
	uthb.add_child(utvb)
	var ut1 := Label.new()
	ut1.text = u_nat_name
	ut1.add_theme_font_override("font", UITheme.get_display_font())
	ut1.add_theme_font_size_override("font_size", 11)
	ut1.add_theme_color_override("font_color", Color.WHITE)
	var ut2 := Label.new()
	ut2.text = "%d CAPS • %d G • %d A" % [int(prod["intl_caps"]), int(prod["intl_g"]), int(prod["intl_a"])]
	ut2.add_theme_font_size_override("font_size", 9)
	ut2.add_theme_color_override("font_color", Color("#94ADC8"))
	utvb.add_child(ut1)
	utvb.add_child(ut2)

	var sp_rb := Control.new()
	sp_rb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vb.add_child(sp_rb)

	right_vb.add_child(_make_crimson_hub_btn("LEGENDA TIMNAS", func(): open_timnas_legends_modal(), "PIALA & GOL + ASSIST TIMNAS"))
