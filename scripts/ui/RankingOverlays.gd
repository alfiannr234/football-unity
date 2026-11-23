extends RefCounted

const TimnasOverlaysScript := preload("res://scripts/ui/TimnasOverlays.gd")

const BG_DARK := Color("#070F1C")
const BG_DETAIL := Color("#0D1E37")
const BG_TILE := Color("#0A1322")
const BG_SEL := Color("#2B2C52")
const BORDER_TILE := Color("#1E2E48")
const BORDER_SEL := Color("#5B63B8")
const GOLD_TXT := Color("#F5C430")

static func get_pos_color(pos: String) -> Color:
	var p: String = pos.to_upper()
	if p == "GK":
		return Color("#D97706")
	if p in ["CB", "LB", "RB"]:
		return Color("#2563EB")
	if p in ["CDM", "CM", "LM", "RM", "CAM"]:
		return Color("#7C3AED")
	return Color("#DC2626")

static func format_val_m(val_k: int) -> String:
	if val_k >= 1000:
		return ("%.1f M" % (float(val_k) / 1000.0)).replace(".", ",")
	return "%d K" % maxi(0, val_k)

static func format_fee_compact(fee_k: int) -> String:
	if fee_k >= 10000:
		return "%dM" % int(round(float(fee_k) / 1000.0))
	if fee_k >= 1000:
		return ("%.1fM" % (float(fee_k) / 1000.0)).replace(".", ",")
	return "%dK" % maxi(0, fee_k)

static func format_coeff_comma(val: float, decimals: int = 3) -> String:
	var fmt: String = "%." + str(decimals) + "f"
	return (fmt % val).replace(".", ",")

static func format_dots(val: int) -> String:
	var neg: bool = val < 0
	var s: String = str(abs(val))
	var out: String = ""
	var cnt: int = 0
	for i in range(s.length() - 1, -1, -1):
		if cnt > 0 and cnt % 3 == 0:
			out = "." + out
		out = s[i] + out
		cnt += 1
	return ("-" if neg else "") + out

static func make_pos_pill(pos: String, font_sz: int = 9) -> Control:
	var col: Color = get_pos_color(pos)
	var pc := PanelContainer.new()
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = col.darkened(0.62)
	sb.border_color = col
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	sb.content_margin_left = 4
	sb.content_margin_right = 4
	sb.content_margin_top = 1
	sb.content_margin_bottom = 1
	pc.add_theme_stylebox_override("panel", sb)
	var l := Label.new()
	l.text = pos.to_upper()
	l.add_theme_font_override("font", UITheme.get_display_font())
	l.add_theme_font_size_override("font_size", font_sz)
	l.add_theme_color_override("font_color", col.lightened(0.42))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc.add_child(l)
	return pc

static func make_free_agent_shield(sz: Vector2 = Vector2(14, 14)) -> Control:
	var c := ShieldGlyphControl.new()
	c.custom_minimum_size = sz
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

static func _style_modal_btn(btn: Button, bg: Color, border: Color, font_sz: int = 12, text_col: Color = UITheme.TEXT_WHITE, bw: int = 1) -> void:
	var n := StyleBoxFlat.new()
	n.bg_color = bg
	n.border_color = border
	n.set_border_width_all(bw)
	n.set_corner_radius_all(4)
	n.content_margin_left = 10
	n.content_margin_right = 10
	n.content_margin_top = 5
	n.content_margin_bottom = 5
	var h := n.duplicate()
	h.bg_color = bg.lightened(0.14)
	h.border_color = UITheme.BORDER_CYAN
	var pr := n.duplicate()
	pr.bg_color = bg.darkened(0.10)
	pr.border_color = GOLD_TXT
	btn.add_theme_stylebox_override("normal", n)
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_stylebox_override("pressed", pr)
	btn.add_theme_stylebox_override("focus", h)
	btn.add_theme_font_override("font", UITheme.get_display_font())
	btn.add_theme_font_size_override("font_size", font_sz)
	btn.add_theme_color_override("font_color", text_col)
	btn.add_theme_color_override("font_hover_color", UITheme.TEXT_WHITE)
	btn.add_theme_color_override("font_pressed_color", GOLD_TXT)

static func _create_locked_layer(parent: Node, bg_col: Color = Color(0.03, 0.05, 0.10, 0.96)) -> Dictionary:
	var layer := EscCanvasLayer.new()
	layer.layer = 20
	parent.add_child(layer)
	var root := Control.new()
	root.theme = UITheme.build_theme()
	root.clip_contents = true
	layer.add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = bg_col
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return {"layer": layer, "root": root}

# ==============================================================================
# 1. DETAIL PEMAIN OVERLAY (Gambar 3)
# ==============================================================================
static func open_player_detail(parent: Node, detail: Dictionary) -> CanvasLayer:
	var built: Dictionary = _create_locked_layer(parent, BG_DETAIL)
	var layer: CanvasLayer = built["layer"]
	var root: Control = built["root"]

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	root.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var cols := HBoxContainer.new()
	cols.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.add_theme_constant_override("separation", 14)
	margin.add_child(cols)

	# --------------------------------------------------------------------------
	# LEFT COLUMN: Collectible Player Card + Meta + 2x5 Attributes Grid
	# --------------------------------------------------------------------------
	var left_vb := VBoxContainer.new()
	left_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_vb.size_flags_stretch_ratio = 1.12
	left_vb.add_theme_constant_override("separation", 12)
	cols.add_child(left_vb)

	var top_hb := HBoxContainer.new()
	top_hb.add_theme_constant_override("separation", 10)
	left_vb.add_child(top_hb)

	# Collectible Avatar Card (tier border + pos + hex OVR + PixelAvatar + short name)
	var ovr: int = int(detail.get("ovr", 70))
	var tier_col: Color = TimnasOverlaysScript.get_ovr_tier_color(ovr)
	var pcard := PanelContainer.new()
	pcard.custom_minimum_size = Vector2(96, 134)
	var pcsb := StyleBoxFlat.new()
	pcsb.bg_color = Color("#162844")
	pcsb.border_color = tier_col
	pcsb.set_border_width_all(2)
	pcsb.set_corner_radius_all(6)
	pcsb.content_margin_left = 4
	pcsb.content_margin_right = 4
	pcsb.content_margin_top = 4
	pcsb.content_margin_bottom = 4
	pcard.add_theme_stylebox_override("panel", pcsb)
	top_hb.add_child(pcard)

	var pcvb := VBoxContainer.new()
	pcvb.add_theme_constant_override("separation", 2)
	pcard.add_child(pcvb)

	var pc_hdr := HBoxContainer.new()
	pcvb.add_child(pc_hdr)
	var pc_pos := make_pos_pill(str(detail.get("primary_pos", "ST")), 8)
	pc_hdr.add_child(pc_pos)
	var pc_sp := Control.new()
	pc_sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pc_hdr.add_child(pc_sp)
	pc_hdr.add_child(TimnasOverlaysScript.make_hex_ovr(ovr, Vector2(24, 24)))

	var av_c := CenterContainer.new()
	av_c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var av := PixelAvatar.new()
	av.custom_minimum_size = Vector2(68, 76)
	var app: Dictionary = detail.get("appearance", {})
	av.skin_idx = int(app.get("skin", 1))
	av.hair_style = int(app.get("hair_style", 2))
	av.hair_idx = int(app.get("hair_color", 1))
	av.beard = bool(app.get("beard", false))
	av.beard_style = int(app.get("beard_style", 0))
	av.long_sleeve = (str(app.get("sleeve", "PENDEK")) == "PANJANG")
	av.shirt_num = int(app.get("shirt_num", 9))
	av.full_body = false
	av.apply_kit({
		"primary": detail.get("club_primary", Color("#1E64D8")),
		"secondary": detail.get("club_secondary", Color("#FFFFFF")),
		"pattern": str(detail.get("club_pattern", "solid")),
	})
	av_c.add_child(av)
	pcvb.add_child(av_c)

	var pc_nm := Label.new()
	pc_nm.text = str(detail.get("short_name", "Pemain"))
	pc_nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pc_nm.clip_text = true
	pc_nm.add_theme_font_override("font", UITheme.get_display_font())
	pc_nm.add_theme_font_size_override("font_size", 10)
	pc_nm.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	pcvb.add_child(pc_nm)

	# Meta info to the right of card (Full name, USIA, KONTRAK, NILAI)
	var meta_vb := VBoxContainer.new()
	meta_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta_vb.add_theme_constant_override("separation", 6)
	top_hb.add_child(meta_vb)

	var fn_hb := HBoxContainer.new()
	fn_hb.add_theme_constant_override("separation", 6)
	meta_vb.add_child(fn_hb)
	var fn_fl := CenterContainer.new()
	fn_fl.add_child(UITheme.make_flag_rect(int(detail.get("nat_id", 0)), Vector2(20, 14)))
	fn_hb.add_child(fn_fl)
	var fn_l := Label.new()
	fn_l.text = str(detail.get("name", "Pemain"))
	fn_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fn_l.clip_text = true
	fn_l.add_theme_font_override("font", UITheme.get_display_font())
	fn_l.add_theme_font_size_override("font_size", 14)
	fn_l.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	fn_hb.add_child(fn_l)

	# Positions pills row
	var pos_hb := HBoxContainer.new()
	pos_hb.add_theme_constant_override("separation", 4)
	for ps in detail.get("positions", ["ST"]):
		pos_hb.add_child(make_pos_pill(str(ps), 9))
	meta_vb.add_child(pos_hb)

	var is_fa: bool = bool(detail.get("is_free_agent", false))
	var contract_txt: String = "BEBAS" if is_fa else "%d THN" % int(detail.get("contract_years", 3))
	for mrow in [
		["USIA", str(int(detail.get("age", 24))), UITheme.TEXT_WHITE],
		["KONTRAK", contract_txt, UITheme.ACCENT_GREEN if is_fa else UITheme.TEXT_WHITE],
		["NILAI", format_dots(int(detail.get("val_full", 1000000))), GOLD_TXT],
	]:
		var mhb := HBoxContainer.new()
		var ml := Label.new()
		ml.text = str(mrow[0])
		ml.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ml.add_theme_font_size_override("font_size", 11)
		ml.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
		var mv := Label.new()
		mv.text = str(mrow[1])
		mv.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		mv.add_theme_font_override("font", UITheme.get_display_font())
		mv.add_theme_font_size_override("font_size", 12)
		mv.add_theme_color_override("font_color", mrow[2])
		mhb.add_child(ml)
		mhb.add_child(mv)
		meta_vb.add_child(mhb)

	# 2x5 Attributes Grid (Gambar 3!)
	var attr_grid := GridContainer.new()
	attr_grid.columns = 2
	attr_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	attr_grid.add_theme_constant_override("h_separation", 14)
	attr_grid.add_theme_constant_override("v_separation", 8)
	left_vb.add_child(attr_grid)

	var attrs: Dictionary = detail.get("attributes", {})
	var attr_order := ["Tendangan", "Penyelesaian", "Lengkung", "Sundulan", "Penalti", "Bola mati", "Kecepatan", "Akselerasi", "Tekel", "Visi"]
	for ak in attr_order:
		var aval: int = int(attrs.get(ak, 70))
		var ahb := HBoxContainer.new()
		ahb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ahb.add_theme_constant_override("separation", 4)
		var al := Label.new()
		al.text = "▸ %s" % ak
		al.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		al.clip_text = true
		al.add_theme_font_size_override("font_size", 11)
		al.add_theme_color_override("font_color", Color("#CBD5E1"))
		var av_l := Label.new()
		av_l.text = str(aval)
		av_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		av_l.add_theme_font_override("font", UITheme.get_display_font())
		av_l.add_theme_font_size_override("font_size", 13)
		av_l.add_theme_color_override("font_color", UITheme.get_stat_color(aval))
		ahb.add_child(al)
		ahb.add_child(av_l)
		attr_grid.add_child(ahb)

	# --------------------------------------------------------------------------
	# CENTER COLUMN: RIWAYAT + M1..M4 Season Tabs + Club History + MINAT Gauge
	# --------------------------------------------------------------------------
	var mid_vb := VBoxContainer.new()
	mid_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid_vb.size_flags_stretch_ratio = 1.0
	mid_vb.add_theme_constant_override("separation", 8)
	cols.add_child(mid_vb)

	var rw_hdr := Label.new()
	rw_hdr.text = "▸ RIWAYAT"
	rw_hdr.add_theme_font_override("font", UITheme.get_display_font())
	rw_hdr.add_theme_font_size_override("font_size", 12)
	rw_hdr.add_theme_color_override("font_color", Color("#9FB3C8"))
	mid_vb.add_child(rw_hdr)

	var m_tabs_hb := HBoxContainer.new()
	m_tabs_hb.add_theme_constant_override("separation", 5)
	mid_vb.add_child(m_tabs_hb)

	var season_stats: Array = detail.get("season_stats", [])
	var stat_summary_l := Label.new()
	stat_summary_l.add_theme_font_size_override("font_size", 11)
	stat_summary_l.add_theme_color_override("font_color", UITheme.ACCENT_CYAN)

	var sel_season := {"idx": maxi(0, season_stats.size() - 1)}
	var m_tab_ref := {}
	m_tab_ref["fn"] = func() -> void:
		for c in m_tabs_hb.get_children():
			m_tabs_hb.remove_child(c)
			c.queue_free()
		for si in range(season_stats.size()):
			var ss: Dictionary = season_stats[si]
			var mb := Button.new()
			mb.text = str(ss.get("label", "M%d" % (si + 1)))
			mb.custom_minimum_size = Vector2(46, 28)
			var act: bool = (int(sel_season["idx"]) == si)
			_style_modal_btn(mb, Color("#1E3658") if act else Color("#0A1424"), UITheme.ACCENT_CYAN if act else Color("#243957"), 11, UITheme.TEXT_WHITE if act else Color("#94A3B8"))
			var si_copy: int = si
			mb.pressed.connect(func():
				AudioSynth.play_click()
				sel_season["idx"] = si_copy
				m_tab_ref["fn"].call()
			)
			m_tabs_hb.add_child(mb)
		if not season_stats.is_empty():
			var cur_s: Dictionary = season_stats[clampi(int(sel_season["idx"]), 0, season_stats.size() - 1)]
			stat_summary_l.text = "%s: %d Laga  •  %d Gol  •  %d Assist  •  ★ %s" % [
				str(cur_s["label"]), int(cur_s["matches"]), int(cur_s["goals"]), int(cur_s["assists"]),
				("%.1f" % float(cur_s["rating"])).replace(".", ",")
			]
	m_tab_ref["fn"].call()
	mid_vb.add_child(stat_summary_l)

	# Club transfer timeline rows
	for ht in detail.get("history_transfers", []):
		var hhb := HBoxContainer.new()
		hhb.add_theme_constant_override("separation", 6)
		mid_vb.add_child(hhb)

		var sp_l := Label.new()
		sp_l.text = str(ht.get("span", "M1"))
		sp_l.custom_minimum_size = Vector2(58, 0)
		sp_l.add_theme_font_size_override("font_size", 10)
		sp_l.add_theme_color_override("font_color", Color("#94A3B8"))
		hhb.add_child(sp_l)

		var hcid: int = int(ht.get("club_id", -1))
		var cr_c := CenterContainer.new()
		if hcid >= 0:
			var cr := ClubCrest.new()
			cr.custom_minimum_size = Vector2(16, 16)
			cr.set_club(hcid)
			cr_c.add_child(cr)
		else:
			cr_c.add_child(make_free_agent_shield(Vector2(15, 15)))
		hhb.add_child(cr_c)

		var fl_c := CenterContainer.new()
		fl_c.add_child(UITheme.make_flag_rect(int(ht.get("nat_id", 0)), Vector2(16, 11)))
		hhb.add_child(fl_c)

		var cnm := Label.new()
		cnm.text = str(ht.get("club_name", "Klub"))
		cnm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cnm.clip_text = true
		cnm.add_theme_font_size_override("font_size", 11)
		cnm.add_theme_color_override("font_color", Color("#F87171") if str(ht.get("tag", "")) == "AKTIF" else UITheme.TEXT_WHITE)
		hhb.add_child(cnm)

		var tag_s: String = str(ht.get("tag", ""))
		if tag_s != "" and tag_s != "AKTIF":
			var tl := Label.new()
			tl.text = tag_s
			tl.add_theme_font_size_override("font_size", 9)
			tl.add_theme_color_override("font_color", GOLD_TXT if tag_s == "TRANSFER" else UITheme.ACCENT_GREEN)
			hhb.add_child(tl)

	# MINAT segmented bar (Gambar 3!)
	var min_hb := HBoxContainer.new()
	min_hb.add_theme_constant_override("separation", 8)
	mid_vb.add_child(min_hb)
	var min_lbl := Label.new()
	min_lbl.text = "MINAT"
	min_lbl.custom_minimum_size = Vector2(54, 0)
	min_lbl.add_theme_font_size_override("font_size", 11)
	min_lbl.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	min_hb.add_child(min_lbl)

	var int_pct: int = int(detail.get("interest_pct", 58))
	var seg_hb := HBoxContainer.new()
	seg_hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	seg_hb.add_theme_constant_override("separation", 2)
	var filled_segs: int = clampi(int(round(float(int_pct) / 10.0)), 1, 10)
	for s_i in range(10):
		var sr := ColorRect.new()
		sr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sr.custom_minimum_size = Vector2(0, 12)
		sr.color = Color("#C8D432") if s_i < filled_segs else Color("#15243A")
		seg_hb.add_child(sr)
	var seg_c := VBoxContainer.new()
	seg_c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	seg_c.alignment = BoxContainer.ALIGNMENT_CENTER
	seg_c.add_child(seg_hb)
	min_hb.add_child(seg_c)

	var pct_l := Label.new()
	pct_l.text = "%d%%" % int_pct
	pct_l.add_theme_font_override("font", UITheme.get_display_font())
	pct_l.add_theme_font_size_override("font_size", 13)
	pct_l.add_theme_color_override("font_color", Color("#C8D432"))
	min_hb.add_child(pct_l)

	var comp_sub := Label.new()
	comp_sub.text = "Tim intimu %d  •  saingan di posisinya %d" % [int(detail.get("my_club_ovr", 65)), int(detail.get("pos_rival_ovr", 64))]
	comp_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	comp_sub.add_theme_font_size_override("font_size", 11)
	comp_sub.add_theme_color_override("font_color", Color("#9FB3C8"))
	mid_vb.add_child(comp_sub)

	var pills_hb := HBoxContainer.new()
	pills_hb.add_theme_constant_override("separation", 6)
	mid_vb.add_child(pills_hb)
	var diff_v: int = int(detail.get("club_diff", 0))
	var d_txt: String = "KLUBMU %+d" % diff_v if diff_v != 0 else "KLUB SETARA"
	for pd in [
		[d_txt, Color("#3B1C28"), Color("#F87171") if diff_v < 0 else Color("#4ADE80")],
		["ke-%d" % int(detail.get("my_pos_rank", 1)), Color("#2A1B33"), Color("#C084FC")],
	]:
		var bp := PanelContainer.new()
		var bsb := StyleBoxFlat.new()
		bsb.bg_color = pd[1]
		bsb.set_corner_radius_all(3)
		bsb.content_margin_left = 6
		bsb.content_margin_right = 6
		bsb.content_margin_top = 2
		bsb.content_margin_bottom = 2
		bp.add_theme_stylebox_override("panel", bsb)
		var bl := Label.new()
		bl.text = str(pd[0])
		bl.add_theme_font_override("font", UITheme.get_display_font())
		bl.add_theme_font_size_override("font_size", 10)
		bl.add_theme_color_override("font_color", pd[2])
		bp.add_child(bl)
		pills_hb.add_child(bp)

	# --------------------------------------------------------------------------
	# RIGHT COLUMN: KLAUSUL + Scout Report Paragraphs + Optional Suggest + TUTUP
	# --------------------------------------------------------------------------
	var right_vb := VBoxContainer.new()
	right_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vb.size_flags_stretch_ratio = 0.95
	right_vb.add_theme_constant_override("separation", 10)
	cols.add_child(right_vb)

	var kl_hb := HBoxContainer.new()
	right_vb.add_child(kl_hb)
	var kl_l := Label.new()
	kl_l.text = "KLAUSUL"
	kl_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kl_l.add_theme_font_override("font", UITheme.get_display_font())
	kl_l.add_theme_font_size_override("font_size", 12)
	kl_l.add_theme_color_override("font_color", Color("#9FB3C8"))
	kl_hb.add_child(kl_l)

	var kl_v := Label.new()
	var cl_m: float = float(detail.get("clause_m", 0.0))
	kl_v.text = "GRATIS (BEBAS)" if is_fa else (("%.1f M" % cl_m).replace(".", ","))
	kl_v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	kl_v.add_theme_font_override("font", UITheme.get_display_font())
	kl_v.add_theme_font_size_override("font_size", 13)
	kl_v.add_theme_color_override("font_color", UITheme.ACCENT_GREEN if is_fa else GOLD_TXT)
	kl_hb.add_child(kl_v)

	for rline in detail.get("report_lines", []):
		var rl := Label.new()
		rl.text = str(rline)
		rl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rl.add_theme_font_size_override("font_size", 11)
		rl.add_theme_color_override("font_color", Color("#CBD5E1"))
		right_vb.add_child(rl)

	if bool(detail.get("can_suggest", false)):
		var sug_b := Button.new()
		sug_b.text = "USULKAN KE KLUB"
		sug_b.custom_minimum_size = Vector2(0, 36)
		_style_modal_btn(sug_b, Color("#1D3E6B"), UITheme.ACCENT_CYAN, 11, UITheme.TEXT_WHITE, 1)
		var wp_i: int = int(detail.get("wp_idx", -1))
		sug_b.pressed.connect(func():
			AudioSynth.play_click()
			CareerState.suggest_world_player_to_club(wp_i)
			sug_b.text = "✓ DIUSULKAN KE MANAJEMEN"
			sug_b.disabled = true
		)
		right_vb.add_child(sug_b)

	var close_b := Button.new()
	close_b.text = "TUTUP"
	close_b.custom_minimum_size = Vector2(0, 44)
	_style_modal_btn(close_b, Color("#0B1424"), Color("#2B3D5B"), 13, UITheme.TEXT_WHITE, 1)
	close_b.pressed.connect(func():
		AudioSynth.play_click()
		layer.queue_free()
	)
	right_vb.add_child(close_b)
	return layer

# ==============================================================================
# 2. FILTER POSISI OVERLAY (Gambar 4 — Multi-Select + TUTUP / OKE)
# ==============================================================================
static func open_pos_filter(parent: Node, active_positions: Array, on_apply: Callable) -> CanvasLayer:
	var built: Dictionary = _create_locked_layer(parent)
	var layer: CanvasLayer = built["layer"]
	var root: Control = built["root"]

	var picked: Dictionary = {}
	for p in active_positions:
		picked[str(p)] = true

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	root.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 14)
	margin.add_child(outer)

	var title := Label.new()
	title.text = "FILTER POSISI"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", UITheme.get_display_font())
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	outer.add_child(title)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	outer.add_child(grid)

	var pos_order := ["GK", "CB", "LB", "RB", "CDM", "CM", "LM", "RM", "LW", "RW", "CAM", "ST"]
	var render_ref := {}
	render_ref["fn"] = func() -> void:
		for c in grid.get_children():
			grid.remove_child(c)
			c.queue_free()
		for ps in pos_order:
			var is_sel: bool = picked.has(ps)
			var pcol: Color = get_pos_color(ps)
			var b := Button.new()
			b.custom_minimum_size = Vector2(0, 52)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_style_modal_btn(b, BG_SEL if is_sel else BG_TILE, pcol if is_sel else BORDER_TILE, 12, UITheme.TEXT_WHITE, 2 if is_sel else 1)

			var hb := HBoxContainer.new()
			hb.set_anchors_preset(Control.PRESET_FULL_RECT)
			hb.offset_left = 14
			hb.offset_right = -10
			hb.add_theme_constant_override("separation", 10)
			hb.alignment = BoxContainer.ALIGNMENT_BEGIN
			hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(hb)

			var ic_c := CenterContainer.new()
			ic_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var sq := ColorRect.new()
			sq.custom_minimum_size = Vector2(14, 14)
			sq.color = pcol
			sq.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ic_c.add_child(sq)
			hb.add_child(ic_c)

			var lbl := Label.new()
			lbl.text = ps
			lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lbl.add_theme_font_override("font", UITheme.get_display_font())
			lbl.add_theme_font_size_override("font_size", 13)
			lbl.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
			lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			hb.add_child(lbl)

			var ps_copy: String = ps
			b.pressed.connect(func():
				AudioSynth.play_click()
				if picked.has(ps_copy):
					picked.erase(ps_copy)
				else:
					picked[ps_copy] = true
				render_ref["fn"].call()
			)
			grid.add_child(b)
	render_ref["fn"].call()

	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(sp)

	# Bottom TUTUP | OKE bar (Gambar 4!)
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 12)
	outer.add_child(foot)

	var cancel_b := Button.new()
	cancel_b.text = "TUTUP"
	cancel_b.custom_minimum_size = Vector2(0, 44)
	cancel_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_modal_btn(cancel_b, Color("#0E182A"), Color("#223450"), 13, Color("#CBD5E1"))
	cancel_b.pressed.connect(func():
		AudioSynth.play_click()
		layer.queue_free()
	)
	foot.add_child(cancel_b)

	var ok_b := Button.new()
	ok_b.text = "OKE"
	ok_b.custom_minimum_size = Vector2(0, 44)
	ok_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_modal_btn(ok_b, Color("#0D1C32"), UITheme.ACCENT_CYAN, 13, UITheme.TEXT_WHITE, 2)
	ok_b.pressed.connect(func():
		AudioSynth.play_click()
		var out_list: Array[String] = []
		for ps in pos_order:
			if picked.has(ps):
				out_list.append(ps)
		on_apply.call(out_list)
		layer.queue_free()
	)
	foot.add_child(ok_b)
	return layer

# ==============================================================================
# 3. SIMPLE GRID OPTION FILTERS: USIA (Gbr 5), NILAI (Gbr 6), DIVISI (Gbr 9), KLUB (Gbr 10)
# ==============================================================================
static func open_option_grid_filter(parent: Node, title_txt: String, options: Array, active_key, columns_n: int, on_select: Callable) -> CanvasLayer:
	var built: Dictionary = _create_locked_layer(parent)
	var layer: CanvasLayer = built["layer"]
	var root: Control = built["root"]

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	root.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 14)
	margin.add_child(outer)

	var title := Label.new()
	title.text = title_txt
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", UITheme.get_display_font())
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	outer.add_child(title)

	var grid := GridContainer.new()
	grid.columns = columns_n
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	outer.add_child(grid)

	for opt in options:
		var opt_key = opt[0]
		var opt_lbl: String = str(opt[1])
		var is_sel: bool = (opt_key == active_key)
		var b := Button.new()
		b.text = opt_lbl
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(0, 56)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_style_modal_btn(b, BG_SEL if is_sel else BG_TILE, BORDER_SEL if is_sel else BORDER_TILE, 13, UITheme.TEXT_WHITE, 2 if is_sel else 1)
		b.pressed.connect(func():
			AudioSynth.play_click()
			on_select.call(opt_key)
			layer.queue_free()
		)
		grid.add_child(b)

	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(sp)

	var close_b := Button.new()
	close_b.text = "TUTUP"
	close_b.custom_minimum_size = Vector2(0, 42)
	close_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_modal_btn(close_b, Color("#0E182A"), Color("#223450"), 13, Color("#CBD5E1"))
	close_b.pressed.connect(func():
		AudioSynth.play_click()
		layer.queue_free()
	)
	outer.add_child(close_b)
	return layer

# ==============================================================================
# 4. FILTER NEGARA (Gambar 7) & FILTER LIGA (Gambar 8) — Alphabet + SEMUA + Flag Grid
# ==============================================================================
static func open_nation_or_league_filter(parent: Node, title_txt: String, active_nid: int, on_select: Callable) -> CanvasLayer:
	var built: Dictionary = _create_locked_layer(parent)
	var layer: CanvasLayer = built["layer"]
	var root: Control = built["root"]

	var letter_map: Dictionary = {}
	for nat in GameData.nations:
		var nm: String = str(nat.get("name", "")).to_upper()
		if nm.length() > 0:
			letter_map[nm.left(1)] = true
	var letters: Array[String] = []
	for k in letter_map.keys():
		letters.append(str(k))
	letters.sort()

	var init_letter: String = letters[0] if not letters.is_empty() else "A"
	if active_nid >= 0 and active_nid < GameData.nations.size():
		init_letter = str(GameData.nations[active_nid].get("name", "A")).to_upper().left(1)
	var state := {"letter": init_letter}

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	root.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	margin.add_child(outer)

	var title := Label.new()
	title.text = title_txt
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", UITheme.get_display_font())
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	outer.add_child(title)

	# Wrapped Alphabet Grid (max 18 per row -> fits cleanly inside 912px!)
	var alpha_grid := GridContainer.new()
	alpha_grid.columns = 18
	alpha_grid.add_theme_constant_override("h_separation", 4)
	alpha_grid.add_theme_constant_override("v_separation", 4)
	outer.add_child(alpha_grid)

	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(sc)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	sc.add_child(grid)

	var render_ref := {}
	render_ref["fn"] = func() -> void:
		for c in alpha_grid.get_children():
			alpha_grid.remove_child(c)
			c.queue_free()
		for lt in letters:
			var is_act: bool = (str(state["letter"]) == lt)
			var ab := Button.new()
			ab.text = lt
			ab.custom_minimum_size = Vector2(44, 30)
			_style_modal_btn(ab, BG_SEL if is_act else BG_TILE, UITheme.ACCENT_CYAN if is_act else BORDER_TILE, 11, UITheme.TEXT_WHITE if is_act else Color("#CBD5E1"))
			var lt_copy: String = lt
			ab.pressed.connect(func():
				AudioSynth.play_click()
				state["letter"] = lt_copy
				render_ref["fn"].call()
			)
			alpha_grid.add_child(ab)

		for c in grid.get_children():
			grid.remove_child(c)
			c.queue_free()

		# Slot 1: SEMUA card (exact match to Gambar 7 & Gambar 8!)
		var all_b := Button.new()
		all_b.text = "SEMUA"
		all_b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		all_b.custom_minimum_size = Vector2(0, 48)
		all_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var is_all: bool = (active_nid < 0)
		_style_modal_btn(all_b, BG_SEL if is_all else BG_TILE, BORDER_SEL if is_all else BORDER_TILE, 12, UITheme.TEXT_WHITE, 2 if is_all else 1)
		all_b.pressed.connect(func():
			AudioSynth.play_click()
			on_select.call(-1)
			layer.queue_free()
		)
		grid.add_child(all_b)

		var matched: Array[Dictionary] = []
		var active_l: String = str(state["letter"])
		for nat in GameData.nations:
			if str(nat.get("name", "")).to_upper().begins_with(active_l):
				matched.append(nat)
		matched.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return str(a.get("name", "")) < str(b.get("name", ""))
		)
		for nat in matched:
			var nid: int = int(nat["id"])
			var is_sel: bool = (nid == active_nid)
			var cb := Button.new()
			cb.custom_minimum_size = Vector2(0, 48)
			cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_style_modal_btn(cb, BG_SEL if is_sel else BG_TILE, BORDER_SEL if is_sel else BORDER_TILE, 11, UITheme.TEXT_WHITE, 2 if is_sel else 1)

			var ihb := HBoxContainer.new()
			ihb.set_anchors_preset(Control.PRESET_FULL_RECT)
			ihb.offset_left = 10
			ihb.offset_right = -8
			ihb.add_theme_constant_override("separation", 8)
			ihb.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cb.add_child(ihb)

			var fc := CenterContainer.new()
			fc.mouse_filter = Control.MOUSE_FILTER_IGNORE
			fc.add_child(UITheme.make_flag_rect(nid, Vector2(24, 16)))
			ihb.add_child(fc)

			var nl := Label.new()
			nl.text = str(nat.get("name", "NEGARA")).to_upper()
			nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			nl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			nl.clip_text = true
			nl.add_theme_font_override("font", UITheme.get_display_font())
			nl.add_theme_font_size_override("font_size", 11)
			nl.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
			nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ihb.add_child(nl)

			cb.pressed.connect(func():
				AudioSynth.play_click()
				on_select.call(nid)
				layer.queue_free()
			)
			grid.add_child(cb)

	render_ref["fn"].call()

	var close_b := Button.new()
	close_b.text = "TUTUP"
	close_b.custom_minimum_size = Vector2(0, 40)
	close_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_modal_btn(close_b, Color("#0E182A"), Color("#223450"), 13, Color("#CBD5E1"))
	close_b.pressed.connect(func():
		AudioSynth.play_click()
		layer.queue_free()
	)
	outer.add_child(close_b)
	return layer

# ==============================================================================
# 5. CARI NAMA PEMAIN OVERLAY (Gambar 2 Bottom-Left CARI Button)
# ==============================================================================
static func open_search_name_overlay(parent: Node, cur_query: String, on_apply: Callable) -> CanvasLayer:
	var built: Dictionary = _create_locked_layer(parent)
	var layer: CanvasLayer = built["layer"]
	var root: Control = built["root"]

	var center := CenterContainer.new()
	root.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var box := PanelContainer.new()
	box.custom_minimum_size = Vector2(520, 190)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#0B1626")
	sb.border_color = Color("#5B63B8")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 18
	sb.content_margin_bottom = 18
	box.add_theme_stylebox_override("panel", sb)
	center.add_child(box)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	box.add_child(vb)

	var title := Label.new()
	title.text = "CARI NAMA PEMAIN"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", UITheme.get_display_font())
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	vb.add_child(title)

	var le := LineEdit.new()
	le.text = cur_query
	le.placeholder_text = "Ketik nama pemain (misal: Helland, Zimmer)..."
	le.custom_minimum_size = Vector2(0, 42)
	vb.add_child(le)
	le.call_deferred("grab_focus")

	var submit := func():
		AudioSynth.play_click()
		on_apply.call(le.text.strip_edges())
		layer.queue_free()

	le.text_submitted.connect(func(_t: String): submit.call())

	var bhb := HBoxContainer.new()
	bhb.add_theme_constant_override("separation", 10)
	vb.add_child(bhb)

	var clr_b := Button.new()
	clr_b.text = "HAPUS"
	clr_b.custom_minimum_size = Vector2(0, 40)
	clr_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_modal_btn(clr_b, Color("#241522"), Color("#8C3545"), 12, Color("#FCA5A5"))
	clr_b.pressed.connect(func():
		AudioSynth.play_click()
		on_apply.call("")
		layer.queue_free()
	)
	bhb.add_child(clr_b)

	var cls_b := Button.new()
	cls_b.text = "TUTUP"
	cls_b.custom_minimum_size = Vector2(0, 40)
	cls_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_modal_btn(cls_b, Color("#0E182A"), Color("#223450"), 12, Color("#CBD5E1"))
	cls_b.pressed.connect(func():
		AudioSynth.play_click()
		layer.queue_free()
	)
	bhb.add_child(cls_b)

	var go_b := Button.new()
	go_b.text = "CARI"
	go_b.custom_minimum_size = Vector2(0, 40)
	go_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_modal_btn(go_b, Color("#3E2E68"), UITheme.ACCENT_CYAN, 12, UITheme.TEXT_WHITE, 2)
	go_b.pressed.connect(submit)
	bhb.add_child(go_b)
	return layer

# ==============================================================================
# 6. TRANSFER OVERLAYS: FILTER LIGA, URUTAN & LAINNYA (Gambar 2 & Gambar 3)
# ==============================================================================
static func make_transfer_kind_pill(kind: String, fee_k: int = 0, min_w: float = 82.0) -> Control:
	var pc := PanelContainer.new()
	pc.custom_minimum_size = Vector2(min_w, 22)
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	var txt_col := Color("#A78BFA")
	var label_txt: String = "BOSMAN"
	if kind == "TRANSFER":
		sb.bg_color = Color("#2C2412")
		sb.border_color = Color("#C99B2C")
		txt_col = Color("#F5C430")
		label_txt = format_val_m(fee_k) if fee_k > 0 else "TRANSFER"
	elif kind == "PINJAMAN":
		sb.bg_color = Color("#122B3B")
		sb.border_color = Color("#38BDF8")
		txt_col = Color("#7DD3FC")
		label_txt = "PINJAMAN"
	else:
		sb.bg_color = Color("#1E1838")
		sb.border_color = Color("#6352A8")
		txt_col = Color("#A78BFA")
		label_txt = "BOSMAN"
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	pc.add_theme_stylebox_override("panel", sb)

	var l := Label.new()
	l.text = label_txt
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", UITheme.get_display_font())
	l.add_theme_font_size_override("font_size", 9)
	l.add_theme_color_override("font_color", txt_col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pc.add_child(l)
	return pc

static func open_transfer_league_filter(parent: Node, cur_mode: String, cur_nid: int, on_select: Callable) -> CanvasLayer:
	var built: Dictionary = _create_locked_layer(parent)
	var layer: CanvasLayer = built["layer"]
	var root: Control = built["root"]

	var letter_map: Dictionary = {}
	for nat in GameData.nations:
		var nm: String = str(nat.get("name", "")).to_upper()
		if nm.length() > 0:
			letter_map[nm.left(1)] = true
	var letters: Array[String] = []
	for k in letter_map.keys():
		letters.append(str(k))
	letters.sort()

	var init_letter: String = letters[0] if not letters.is_empty() else "A"
	if cur_mode == "NAT" and cur_nid >= 0 and cur_nid < GameData.nations.size():
		init_letter = str(GameData.nations[cur_nid].get("name", "A")).to_upper().left(1)
	var state := {"letter": init_letter}

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	root.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	margin.add_child(outer)

	var title := Label.new()
	title.text = "FILTER LIGA TRANSFER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", UITheme.get_display_font())
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	outer.add_child(title)

	var alpha_grid := GridContainer.new()
	alpha_grid.columns = 18
	alpha_grid.add_theme_constant_override("h_separation", 4)
	alpha_grid.add_theme_constant_override("v_separation", 4)
	outer.add_child(alpha_grid)

	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(sc)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	sc.add_child(grid)

	var render_ref := {}
	render_ref["fn"] = func() -> void:
		for c in alpha_grid.get_children():
			alpha_grid.remove_child(c)
			c.queue_free()
		for lt in letters:
			var is_act: bool = (str(state["letter"]) == lt)
			var ab := Button.new()
			ab.text = lt
			ab.custom_minimum_size = Vector2(44, 30)
			_style_modal_btn(ab, BG_SEL if is_act else BG_TILE, UITheme.ACCENT_CYAN if is_act else BORDER_TILE, 11, UITheme.TEXT_WHITE if is_act else Color("#CBD5E1"))
			var lt_copy: String = lt
			ab.pressed.connect(func():
				AudioSynth.play_click()
				state["letter"] = lt_copy
				render_ref["fn"].call()
			)
			alpha_grid.add_child(ab)

		for c in grid.get_children():
			grid.remove_child(c)
			c.queue_free()

		# Slot 1: LIGAMU
		var mine_b := Button.new()
		mine_b.text = "LIGAMU"
		mine_b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		mine_b.custom_minimum_size = Vector2(0, 48)
		mine_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var is_mine: bool = (cur_mode == "MINE")
		_style_modal_btn(mine_b, BG_SEL if is_mine else BG_TILE, Color("#8B74E8") if is_mine else BORDER_TILE, 12, Color("#C4B5FD") if is_mine else UITheme.TEXT_WHITE, 2 if is_mine else 1)
		mine_b.pressed.connect(func():
			AudioSynth.play_click()
			on_select.call("MINE", -1)
			layer.queue_free()
		)
		grid.add_child(mine_b)

		# Slot 2: SEMUA LIGA
		var all_b := Button.new()
		all_b.text = "SEMUA LIGA"
		all_b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		all_b.custom_minimum_size = Vector2(0, 48)
		all_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var is_all: bool = (cur_mode == "ALL")
		_style_modal_btn(all_b, BG_SEL if is_all else BG_TILE, BORDER_SEL if is_all else BORDER_TILE, 12, UITheme.TEXT_WHITE, 2 if is_all else 1)
		all_b.pressed.connect(func():
			AudioSynth.play_click()
			on_select.call("ALL", -1)
			layer.queue_free()
		)
		grid.add_child(all_b)

		var matched: Array[Dictionary] = []
		var active_l: String = str(state["letter"])
		for nat in GameData.nations:
			if str(nat.get("name", "")).to_upper().begins_with(active_l):
				matched.append(nat)
		matched.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return str(a.get("name", "")) < str(b.get("name", ""))
		)
		for nat in matched:
			var nid: int = int(nat["id"])
			var is_sel: bool = (cur_mode == "NAT" and nid == cur_nid)
			var cb := Button.new()
			cb.custom_minimum_size = Vector2(0, 48)
			cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_style_modal_btn(cb, BG_SEL if is_sel else BG_TILE, BORDER_SEL if is_sel else BORDER_TILE, 11, UITheme.TEXT_WHITE, 2 if is_sel else 1)

			var ihb := HBoxContainer.new()
			ihb.set_anchors_preset(Control.PRESET_FULL_RECT)
			ihb.offset_left = 10
			ihb.offset_right = -8
			ihb.add_theme_constant_override("separation", 8)
			ihb.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cb.add_child(ihb)

			var fc := CenterContainer.new()
			fc.mouse_filter = Control.MOUSE_FILTER_IGNORE
			fc.add_child(UITheme.make_flag_rect(nid, Vector2(24, 16)))
			ihb.add_child(fc)

			var nl := Label.new()
			nl.text = str(nat.get("name", "LIGA")).to_upper()
			nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			nl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			nl.clip_text = true
			nl.add_theme_font_override("font", UITheme.get_display_font())
			nl.add_theme_font_size_override("font_size", 11)
			nl.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
			nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ihb.add_child(nl)

			cb.pressed.connect(func():
				AudioSynth.play_click()
				on_select.call("NAT", nid)
				layer.queue_free()
			)
			grid.add_child(cb)

	render_ref["fn"].call()

	var close_b := Button.new()
	close_b.text = "TUTUP"
	close_b.custom_minimum_size = Vector2(0, 40)
	close_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_modal_btn(close_b, Color("#0E182A"), Color("#223450"), 13, Color("#CBD5E1"))
	close_b.pressed.connect(func():
		AudioSynth.play_click()
		layer.queue_free()
	)
	outer.add_child(close_b)
	return layer

static func open_transfer_sort_filter(parent: Node, cur_sort: String, on_select: Callable) -> CanvasLayer:
	var opts := [
		["TERBARU", "TERBARU"],
		["NILAI", "NILAI TERTINGGI"],
		["OVR", "OVR TERTINGGI"],
	]
	return open_option_grid_filter(parent, "URUTKAN TRANSFER", opts, cur_sort, 3, on_select)

static func make_transfer_player_card(tr: Dictionary, on_inspect_player: Callable) -> Button:
	var btn := Button.new()
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, 96)
	btn.clip_contents = true
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#09111F")
	sb.border_color = Color("#1A2A42")
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	var sbh := sb.duplicate()
	sbh.bg_color = Color("#101F36")
	sbh.border_color = UITheme.ACCENT_CYAN
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sbh)
	btn.add_theme_stylebox_override("pressed", sbh)
	btn.add_theme_stylebox_override("focus", sbh)

	var main_hb := HBoxContainer.new()
	main_hb.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_hb.offset_left = 6
	main_hb.offset_right = -6
	main_hb.offset_top = 5
	main_hb.offset_bottom = -5
	main_hb.add_theme_constant_override("separation", 8)
	main_hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(main_hb)

	# --------------------------------------------------------------------------
	# LEFT: Collectible Mini Player Card (Tier Border + Pos Stack + Hex OVR + Avatar + Surname)
	# --------------------------------------------------------------------------
	var ovr: int = int(tr.get("ovr", 70))
	var tier_col: Color = TimnasOverlaysScript.get_ovr_tier_color(ovr)
	var d_pri: Color = UITheme.parse_color(tr.get("dest_primary", Color("#1E64D8")), Color("#1E64D8"))
	var d_sec: Color = UITheme.parse_color(tr.get("dest_secondary", Color("#F8FAFC")), Color("#F8FAFC"))
	var d_pat: String = str(tr.get("dest_pattern", "solid"))

	var card_wrap := PanelContainer.new()
	card_wrap.custom_minimum_size = Vector2(68, 84)
	card_wrap.clip_contents = true
	card_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var csb := StyleBoxFlat.new()
	csb.bg_color = Color("#132238")
	csb.border_color = tier_col
	csb.set_border_width_all(2)
	csb.set_corner_radius_all(5)
	csb.content_margin_left = 0
	csb.content_margin_right = 0
	csb.content_margin_top = 0
	csb.content_margin_bottom = 0
	card_wrap.add_theme_stylebox_override("panel", csb)
	main_hb.add_child(card_wrap)

	var card_inner := Control.new()
	card_inner.clip_contents = true
	card_inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_wrap.add_child(card_inner)

	var card_bg := MiniCardBackdropControl.new()
	card_bg.tier_col = tier_col
	card_bg.club_pri = d_pri
	card_bg.club_sec = d_sec
	card_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	card_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_inner.add_child(card_bg)

	# Avatar portrait wearing new destination club kit
	var av := PixelAvatar.new()
	av.full_body = false
	av.custom_minimum_size = Vector2(46, 48)
	av.set_anchors_preset(Control.PRESET_CENTER)
	av.offset_left = -22
	av.offset_right = 24
	av.offset_top = -18
	av.offset_bottom = 30
	av.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var p_seed: int = int(tr.get("seed", int(tr.get("wp_idx", 1)) * 17 + 7))
	av.configure_from_seed(p_seed, {"primary": d_pri, "secondary": d_sec, "pattern": d_pat}, 1 + (abs(p_seed) % 29))
	card_inner.add_child(av)

	# Top-left stacked position tags (up to 3 positions like Gambar 1)
	var pos_vb := VBoxContainer.new()
	pos_vb.set_anchors_preset(Control.PRESET_TOP_LEFT)
	pos_vb.offset_left = 2
	pos_vb.offset_top = 2
	pos_vb.add_theme_constant_override("separation", 1)
	pos_vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_inner.add_child(pos_vb)
	var pos_arr: Array = tr.get("positions", [str(tr.get("pos", "CM"))])
	for pi in range(mini(3, pos_arr.size())):
		var ps_s: String = str(pos_arr[pi]).to_upper()
		var pcol: Color = get_pos_color(ps_s)
		var pp := PanelContainer.new()
		pp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var psb := StyleBoxFlat.new()
		psb.bg_color = pcol.darkened(0.45) if pi == 0 else Color("#0B1424D8")
		psb.border_color = pcol if pi == 0 else pcol.darkened(0.25)
		psb.set_border_width_all(1)
		psb.set_corner_radius_all(2)
		psb.content_margin_left = 2
		psb.content_margin_right = 2
		psb.content_margin_top = 0
		psb.content_margin_bottom = 0
		pp.add_theme_stylebox_override("panel", psb)
		var pl := Label.new()
		pl.text = ps_s
		pl.add_theme_font_override("font", UITheme.get_display_font())
		pl.add_theme_font_size_override("font_size", 6)
		pl.add_theme_color_override("font_color", UITheme.TEXT_WHITE if pi == 0 else pcol.lightened(0.45))
		pl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pp.add_child(pl)
		pos_vb.add_child(pp)

	# Top-right Hexagon OVR badge
	var hex := TimnasOverlaysScript.make_hex_ovr(ovr, Vector2(22, 22))
	hex.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	hex.offset_left = -23
	hex.offset_right = -1
	hex.offset_top = 1
	hex.offset_bottom = 23
	hex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card_inner.add_child(hex)

	# Bottom dark surname bar
	var sn_bar := PanelContainer.new()
	sn_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	sn_bar.offset_top = -15
	sn_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var snsb := StyleBoxFlat.new()
	snsb.bg_color = Color(0.04, 0.08, 0.16, 0.90)
	snsb.content_margin_left = 2
	snsb.content_margin_right = 2
	snsb.content_margin_top = 0
	snsb.content_margin_bottom = 1
	sn_bar.add_theme_stylebox_override("panel", snsb)
	card_inner.add_child(sn_bar)

	var sn_l := Label.new()
	sn_l.text = str(tr.get("short_name", str(tr.get("name", "Pemain")).split(" ")[-1]))
	sn_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sn_l.clip_text = true
	sn_l.add_theme_font_override("font", UITheme.get_display_font())
	sn_l.add_theme_font_size_override("font_size", 8)
	sn_l.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	sn_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sn_bar.add_child(sn_l)

	# --------------------------------------------------------------------------
	# RIGHT: Header (● REKRUT + Fee) + 2-Club Themed Split Banner + Full Name
	# --------------------------------------------------------------------------
	var right_vb := VBoxContainer.new()
	right_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vb.add_theme_constant_override("separation", 3)
	right_vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_hb.add_child(right_vb)

	# Top row: Status dot + Label on left | Fee on right
	var hdr_hb := HBoxContainer.new()
	hdr_hb.add_theme_constant_override("separation", 5)
	hdr_hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right_vb.add_child(hdr_hb)

	var kind_s: String = str(tr.get("kind", "TRANSFER"))
	var fee_k: int = int(tr.get("fee_k", 0))
	var dot_col: Color = GOLD_TXT
	var kind_txt: String = "REKRUT"
	var right_val_txt: String = format_fee_compact(fee_k) if fee_k > 0 else "BEBAS"
	var right_val_col: Color = GOLD_TXT
	if kind_s == "BOSMAN":
		dot_col = Color("#A78BFA")
		kind_txt = "BOSMAN"
		right_val_txt = "BEBAS • %s" % str(tr.get("date_str", ""))
		right_val_col = Color("#C4B5FD")
	elif kind_s == "PINJAMAN":
		dot_col = Color("#38BDF8")
		kind_txt = "PINJAMAN"
		right_val_txt = "PINJAM • %s" % str(tr.get("date_str", ""))
		right_val_col = Color("#7DD3FC")

	var dot_l := Label.new()
	dot_l.text = "●"
	dot_l.add_theme_font_size_override("font_size", 10)
	dot_l.add_theme_color_override("font_color", dot_col)
	dot_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hdr_hb.add_child(dot_l)

	var kind_l := Label.new()
	kind_l.text = kind_txt
	kind_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kind_l.add_theme_font_override("font", UITheme.get_display_font())
	kind_l.add_theme_font_size_override("font_size", 11)
	kind_l.add_theme_color_override("font_color", dot_col)
	kind_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hdr_hb.add_child(kind_l)

	var fee_l := Label.new()
	fee_l.text = right_val_txt
	fee_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	fee_l.add_theme_font_override("font", UITheme.get_display_font())
	fee_l.add_theme_font_size_override("font_size", 11)
	fee_l.add_theme_color_override("font_color", right_val_col)
	fee_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hdr_hb.add_child(fee_l)

	# Center: 2-Club Diagonal-Split Themed Banner (Origin Club -> New Club)
	var from_cid: int = int(tr.get("from_club_id", -1))
	var dest_cid: int = int(tr.get("dest_club_id", 0))
	var f_pri: Color = UITheme.parse_color(tr.get("from_primary", Color("#3A4556")), Color("#3A4556"))
	var f_sec: Color = UITheme.parse_color(tr.get("from_secondary", Color("#5A687D")), Color("#5A687D"))
	var f_pat: String = str(tr.get("from_pattern", "solid"))

	var banner := TransferClubSplitBanner.new()
	banner.custom_minimum_size = Vector2(0, 46)
	banner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	banner.size_flags_vertical = Control.SIZE_EXPAND_FILL
	banner.clip_contents = true
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.from_primary = f_pri
	banner.from_secondary = f_sec
	banner.from_pattern = f_pat
	banner.dest_primary = d_pri
	banner.dest_secondary = d_sec
	banner.dest_pattern = d_pat
	right_vb.add_child(banner)

	var clubs_hb := HBoxContainer.new()
	clubs_hb.set_anchors_preset(Control.PRESET_FULL_RECT)
	clubs_hb.offset_left = 4
	clubs_hb.offset_right = -4
	clubs_hb.offset_top = 3
	clubs_hb.offset_bottom = -2
	clubs_hb.add_theme_constant_override("separation", 10)
	clubs_hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(clubs_hb)

	# Left half: Origin club crest + name
	var left_club_vb := VBoxContainer.new()
	left_club_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_club_vb.alignment = BoxContainer.ALIGNMENT_CENTER
	left_club_vb.add_theme_constant_override("separation", 2)
	left_club_vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clubs_hb.add_child(left_club_vb)

	var l_cr_c := CenterContainer.new()
	l_cr_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if from_cid >= 0 and from_cid < GameData.clubs.size():
		var lcr := ClubCrest.new()
		lcr.custom_minimum_size = Vector2(22, 22)
		lcr.set_club(from_cid)
		lcr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l_cr_c.add_child(lcr)
	else:
		l_cr_c.add_child(make_free_agent_shield(Vector2(20, 20)))
	left_club_vb.add_child(l_cr_c)

	var l_nm := Label.new()
	l_nm.text = str(tr.get("from_name", "TANPA KLUB"))
	l_nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l_nm.clip_text = true
	l_nm.add_theme_font_override("font", UITheme.get_display_font())
	l_nm.add_theme_font_size_override("font_size", 8)
	l_nm.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	l_nm.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.08, 0.95))
	l_nm.add_theme_constant_override("outline_size", 3)
	l_nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_club_vb.add_child(l_nm)

	# Right half: New destination club crest + name
	var right_club_vb := VBoxContainer.new()
	right_club_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_club_vb.alignment = BoxContainer.ALIGNMENT_CENTER
	right_club_vb.add_theme_constant_override("separation", 2)
	right_club_vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clubs_hb.add_child(right_club_vb)

	var r_cr_c := CenterContainer.new()
	r_cr_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rcr := ClubCrest.new()
	rcr.custom_minimum_size = Vector2(22, 22)
	rcr.set_club(dest_cid)
	rcr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r_cr_c.add_child(rcr)
	right_club_vb.add_child(r_cr_c)

	var r_nm := Label.new()
	r_nm.text = str(tr.get("dest_name", "Klub Baru"))
	r_nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	r_nm.clip_text = true
	r_nm.add_theme_font_override("font", UITheme.get_display_font())
	r_nm.add_theme_font_size_override("font_size", 8)
	r_nm.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	r_nm.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.08, 0.95))
	r_nm.add_theme_constant_override("outline_size", 3)
	r_nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right_club_vb.add_child(r_nm)

	# Bottom: Centered full player name
	var full_l := Label.new()
	full_l.text = str(tr.get("name", "Pemain"))
	full_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	full_l.clip_text = true
	full_l.add_theme_font_override("font", UITheme.get_display_font())
	full_l.add_theme_font_size_override("font_size", 10)
	full_l.add_theme_color_override("font_color", Color("#E2E8F0"))
	full_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right_vb.add_child(full_l)

	var wp_i: int = int(tr.get("wp_idx", -1))
	btn.pressed.connect(func():
		AudioSynth.play_click()
		if wp_i >= 0 and on_inspect_player.is_valid():
			on_inspect_player.call(wp_i)
	)
	return btn

static func make_cup_micro_icon(kind: String, sz: Vector2 = Vector2(14, 14)) -> Control:
	var c := EuroCupMicroIcon.new()
	c.cup_kind = kind
	c.custom_minimum_size = sz
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

static func make_nation_coeff_chart(coeff_5y: Array, start_yr: int, end_yr: int) -> Control:
	var c := NationCoeffBarChart.new()
	c.values = coeff_5y.duplicate()
	c.start_label = "%02d/%02d" % [start_yr % 100, (start_yr + 1) % 100]
	c.end_label = "%02d/%02d" % [end_yr % 100, (end_yr + 1) % 100]
	c.custom_minimum_size = Vector2(0, 74)
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

static func make_nation_mini_sparkline(coeff_5y: Array, max_ref: float = 25.0) -> Control:
	var c := NationCoeffSparkline.new()
	c.values = coeff_5y.duplicate()
	c.max_ref = max_ref
	c.custom_minimum_size = Vector2(36, 22)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c

static func open_all_transfers_overlay(parent: Node, league_title: String, transfers: Array, on_inspect_player: Callable) -> CanvasLayer:
	var built: Dictionary = _create_locked_layer(parent, BG_DARK)
	var layer: CanvasLayer = built["layer"]
	var root: Control = built["root"]

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	root.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	margin.add_child(outer)

	var top_hb := HBoxContainer.new()
	top_hb.add_theme_constant_override("separation", 10)
	outer.add_child(top_hb)

	var title := Label.new()
	title.text = "TRANSFER  •  %s (%d)" % [league_title.to_upper(), transfers.size()]
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.clip_text = true
	title.add_theme_font_override("font", UITheme.get_display_font())
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color("#8B74E8"))
	top_hb.add_child(title)

	var close_b := Button.new()
	close_b.text = "TUTUP"
	close_b.custom_minimum_size = Vector2(96, 36)
	_style_modal_btn(close_b, Color("#111D30"), Color("#263856"), 12, Color("#E2E8F0"))
	close_b.pressed.connect(func():
		AudioSynth.play_click()
		layer.queue_free()
	)
	top_hb.add_child(close_b)

	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(sc)

	if transfers.is_empty():
		var el := Label.new()
		el.text = "Belum ada catatan transfer pada filter ini."
		el.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
		sc.add_child(el)
		return layer

	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 8)
	sc.add_child(grid)

	for tr_item in transfers:
		var tr: Dictionary = tr_item
		grid.add_child(make_transfer_player_card(tr, on_inspect_player))

	return layer

# ==============================================================================
# INNER HELPERS
# ==============================================================================
class EscCanvasLayer extends CanvasLayer:
	func _unhandled_input(event: InputEvent) -> void:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_ESCAPE:
				AudioSynth.play_click()
				get_viewport().set_input_as_handled()
				queue_free()

class ShieldGlyphControl extends Control:
	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		var pts := PackedVector2Array([
			Vector2(w * 0.16, h * 0.12), Vector2(w * 0.84, h * 0.12),
			Vector2(w * 0.80, h * 0.62), Vector2(w * 0.50, h * 0.90),
			Vector2(w * 0.20, h * 0.62),
		])
		draw_colored_polygon(pts, Color("#64748B"))
		draw_polyline(pts, Color("#94A3B8"), 1.0, true)

class MiniCardBackdropControl extends Control:
	var tier_col: Color = Color("#F5C430")
	var club_pri: Color = Color("#1E64D8")
	var club_sec: Color = Color("#F8FAFC")
	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		var base_c: Color = tier_col.darkened(0.62).lerp(club_pri.darkened(0.45), 0.35)
		draw_rect(Rect2(0, 0, w, h), base_c, true)
		var stripe_c: Color = tier_col.lerp(club_sec, 0.35)
		stripe_c.a = 0.22
		for i in range(-1, 5):
			var x0: float = float(i) * 18.0
			draw_colored_polygon(PackedVector2Array([
				Vector2(x0, 0), Vector2(x0 + 8.0, 0),
				Vector2(x0 - 16.0, h), Vector2(x0 - 24.0, h),
			]), stripe_c)
		draw_rect(Rect2(0, 0, w, h * 0.24), Color(1, 1, 1, 0.08), true)

class TransferClubSplitBanner extends Control:
	var from_primary: Color = Color("#3A4556")
	var from_secondary: Color = Color("#5A687D")
	var from_pattern: String = "solid"
	var dest_primary: Color = Color("#1E64D8")
	var dest_secondary: Color = Color("#F8FAFC")
	var dest_pattern: String = "stripes"

	func _clip_halfplane(poly: PackedVector2Array, a: Vector2, b: Vector2, keep_left: bool) -> PackedVector2Array:
		var out: PackedVector2Array = PackedVector2Array()
		var n: int = poly.size()
		if n < 3:
			return out
		var dx: float = b.x - a.x
		var dy: float = b.y - a.y
		for i in range(n):
			var cur: Vector2 = poly[i]
			var nxt: Vector2 = poly[(i + 1) % n]
			var s_cur: float = dx * (cur.y - a.y) - dy * (cur.x - a.x)
			var s_nxt: float = dx * (nxt.y - a.y) - dy * (nxt.x - a.x)
			var in_cur: bool = (s_cur >= 0.0) if keep_left else (s_cur <= 0.0)
			var in_nxt: bool = (s_nxt >= 0.0) if keep_left else (s_nxt <= 0.0)
			if in_cur != in_nxt:
				var denom: float = s_cur - s_nxt
				var t: float = s_cur / denom if absf(denom) > 0.0001 else 0.5
				out.append(cur.lerp(nxt, clampf(t, 0.0, 1.0)))
			if in_nxt:
				out.append(nxt)
		return out

	func _draw_themed_half(keep_left: bool, pri: Color, sec: Color, pat: String, da: Vector2, db: Vector2) -> void:
		var w: float = size.x
		var h: float = size.y
		var full_rect := PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)])
		var half_poly: PackedVector2Array = _clip_halfplane(full_rect, da, db, keep_left)
		if half_poly.size() < 3:
			return

		var dark_pri: Color = pri.darkened(0.40) if pri.get_luminance() > 0.45 else pri.darkened(0.24)
		var accent_sec: Color = sec.darkened(0.32) if sec.get_luminance() > 0.50 else sec.darkened(0.18)
		draw_colored_polygon(half_poly, dark_pri)

		if pat == "stripes":
			var stripe_w: float = 10.0
			var x_pos: float = 0.0
			var idx: int = 0
			while x_pos < w:
				if idx % 2 == 1:
					var sp := PackedVector2Array([
						Vector2(x_pos, 0), Vector2(minf(w, x_pos + stripe_w), 0),
						Vector2(minf(w, x_pos + stripe_w), h), Vector2(x_pos, h),
					])
					var clipped: PackedVector2Array = _clip_halfplane(sp, da, db, keep_left)
					if clipped.size() >= 3:
						draw_colored_polygon(clipped, accent_sec)
				x_pos += stripe_w
				idx += 1
		elif pat == "hoops":
			var band_h: float = 9.0
			var y_pos: float = 0.0
			var idx: int = 0
			while y_pos < h:
				if idx % 2 == 1:
					var bp := PackedVector2Array([
						Vector2(0, y_pos), Vector2(w, y_pos),
						Vector2(w, minf(h, y_pos + band_h)), Vector2(0, minf(h, y_pos + band_h)),
					])
					var clipped: PackedVector2Array = _clip_halfplane(bp, da, db, keep_left)
					if clipped.size() >= 3:
						draw_colored_polygon(clipped, accent_sec)
				y_pos += band_h
				idx += 1
		elif pat == "sash":
			var cx: float = w * (0.25 if keep_left else 0.75)
			var sash_p := PackedVector2Array([
				Vector2(cx - 26.0, 0), Vector2(cx - 8.0, 0),
				Vector2(cx + 24.0, h), Vector2(cx + 6.0, h),
			])
			var clipped: PackedVector2Array = _clip_halfplane(sash_p, da, db, keep_left)
			if clipped.size() >= 3:
				draw_colored_polygon(clipped, accent_sec)
		elif pat == "halved":
			var split_x: float = w * (0.25 if keep_left else 0.75)
			var hp := PackedVector2Array([
				Vector2(split_x, 0), Vector2(w if not keep_left else da.x + 12.0, 0),
				Vector2(w if not keep_left else da.x + 12.0, h), Vector2(split_x, h),
			])
			var clipped: PackedVector2Array = _clip_halfplane(hp, da, db, keep_left)
			if clipped.size() >= 3:
				draw_colored_polygon(clipped, accent_sec)
		else:
			# Solid signature theme with subtle top/side club-secondary sheen
			var sheen := PackedVector2Array([
				Vector2(0, 0), Vector2(w, 0), Vector2(w, h * 0.36), Vector2(0, h * 0.36),
			])
			var clipped: PackedVector2Array = _clip_halfplane(sheen, da, db, keep_left)
			if clipped.size() >= 3:
				var sc: Color = accent_sec
				sc.a = 0.20
				draw_colored_polygon(clipped, sc)

	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		if w <= 2.0 or h <= 2.0:
			return
		var da := Vector2(w * 0.54, 0.0)
		var db := Vector2(w * 0.46, h)
		_draw_themed_half(true, from_primary, from_secondary, from_pattern, da, db)
		_draw_themed_half(false, dest_primary, dest_secondary, dest_pattern, da, db)
		# Soft bottom scrim for crisp club name contrast
		draw_rect(Rect2(0, h - 16.0, w, 16.0), Color(0.03, 0.06, 0.12, 0.48), true)
		# Crisp diagonal divider slash
		draw_line(da, db, Color(0.85, 0.90, 0.98, 0.65), 1.5, true)
		# Outer subtle border
		draw_rect(Rect2(0.5, 0.5, w - 1.0, h - 1.0), Color(0.75, 0.84, 0.96, 0.16), false, 1.0)

class EuroCupMicroIcon extends Control:
	var cup_kind: String = "ELITE"
	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		if cup_kind == "ELITE":
			# Classic twin-handle big-eared trophy
			var col := Color("#CBD5E1")
			var acc := Color("#60A5FA")
			draw_arc(Vector2(w * 0.26, h * 0.36), w * 0.18, PI * 0.5, PI * 1.5, 8, col, 1.4)
			draw_arc(Vector2(w * 0.74, h * 0.36), w * 0.18, -PI * 0.5, PI * 0.5, 8, col, 1.4)
			draw_colored_polygon(PackedVector2Array([
				Vector2(w * 0.30, h * 0.18), Vector2(w * 0.70, h * 0.18),
				Vector2(w * 0.62, h * 0.58), Vector2(w * 0.38, h * 0.58),
			]), col)
			draw_rect(Rect2(w * 0.44, h * 0.58, w * 0.12, h * 0.18), acc, true)
			draw_rect(Rect2(w * 0.30, h * 0.76, w * 0.40, h * 0.12), col, true)
		elif cup_kind == "EUROPA":
			# Classic Europa V-chalice cup
			var col := Color("#E2E8F0")
			var acc := Color("#F59E0B")
			draw_colored_polygon(PackedVector2Array([
				Vector2(w * 0.22, h * 0.16), Vector2(w * 0.78, h * 0.16),
				Vector2(w * 0.60, h * 0.62), Vector2(w * 0.40, h * 0.62),
			]), col)
			draw_rect(Rect2(w * 0.42, h * 0.62, w * 0.16, h * 0.14), acc, true)
			draw_rect(Rect2(w * 0.28, h * 0.76, w * 0.44, h * 0.12), acc, true)
		else:
			# Slender Challenge trophy
			var col := Color("#CBD5E1")
			var acc := Color("#22D3EE")
			draw_colored_polygon(PackedVector2Array([
				Vector2(w * 0.34, h * 0.14), Vector2(w * 0.66, h * 0.14),
				Vector2(w * 0.58, h * 0.68), Vector2(w * 0.42, h * 0.68),
			]), col)
			draw_rect(Rect2(w * 0.34, h * 0.72, w * 0.32, h * 0.14), acc, true)

class NationCoeffBarChart extends Control:
	var values: Array = [16.0, 17.0, 20.0, 21.0, 19.0]
	var start_label: String = "22/23"
	var end_label: String = "26/27"
	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		if values.is_empty() or w <= 10.0:
			return
		var max_v: float = 4.0
		for v in values:
			max_v = maxf(max_v, float(v))
		var top_pad: float = 16.0
		var bot_pad: float = 16.0
		var bar_area_h: float = maxf(16.0, h - top_pad - bot_pad)
		var count: int = values.size()
		var slot_w: float = w / float(count)
		var bar_w: float = clampf(slot_w * 0.42, 12.0, 20.0)
		var font: Font = UITheme.get_display_font()
		var bar_colors := [
			Color("#574394"), Color("#634DA6"), Color("#755AC2"), Color("#8668D9"), Color("#A280F5")
		]
		for i in range(count):
			var v: float = float(values[i])
			var bh: float = maxf(5.0, (v / max_v) * bar_area_h)
			var cx: float = slot_w * (float(i) + 0.5)
			var bx: float = cx - bar_w * 0.5
			var by: float = top_pad + (bar_area_h - bh)
			var col: Color = bar_colors[clampi(i, 0, bar_colors.size() - 1)]
			draw_rect(Rect2(bx, by, bar_w, bh), col, true)
			draw_rect(Rect2(bx, by, bar_w, 2.0), col.lightened(0.25), true)
			var vtxt: String = ("%.1f" % v).replace(".", ",")
			var tsz: Vector2 = font.get_string_size(vtxt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8)
			draw_string(font, Vector2(cx - tsz.x * 0.5, by - 4.0), vtxt, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("#CBD5E1"))

		# Subtle baseline & left/right season span labels (22/23 ... 26/27)
		var base_y: float = top_pad + bar_area_h + 1.0
		draw_line(Vector2(0, base_y), Vector2(w, base_y), Color("#1A2B45"), 1.0)
		draw_string(font, Vector2(2.0, h - 2.0), start_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("#6E829E"))
		var esz: Vector2 = font.get_string_size(end_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8)
		draw_string(font, Vector2(w - esz.x - 2.0, h - 2.0), end_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("#6E829E"))

class NationCoeffSparkline extends Control:
	var values: Array = [10.0, 12.0, 11.0, 13.0, 12.0]
	var max_ref: float = 24.0
	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		if values.is_empty():
			return
		var count: int = mini(5, values.size())
		var gap: float = 2.0
		var bw: float = maxf(3.0, (w - gap * float(count - 1)) / float(count))
		var cols := [Color("#54408F"), Color("#634CA6"), Color("#755AC2"), Color("#8769DA"), Color("#A280F5")]
		for i in range(count):
			var v: float = float(values[i])
			var ratio: float = clampf(v / maxf(1.0, max_ref), 0.14, 1.0)
			var bh: float = maxf(3.0, ratio * (h - 2.0))
			var x: float = float(i) * (bw + gap)
			draw_rect(Rect2(x, h - bh, bw, bh), cols[i], true)
