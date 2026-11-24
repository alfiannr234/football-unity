extends Control

# End-of-Season Final Recap Dashboard (Video 2 exact 2-column layout: MUSIM N / TAHUNMU)
signal continue_pressed

var _ctx: Dictionary = {}
var _t: float = 0.0

func configure(ctx: Dictionary) -> void:
	_ctx = ctx.duplicate(true)

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UITheme.build_theme()
	clip_contents = true
	if _ctx.is_empty():
		_ctx = CareerState.build_season_end_ceremony_context()
	_build_ui()

func _process(delta: float) -> void:
	_t += minf(delta, 0.05)

func _draw() -> void:
	var w: float = maxf(size.x, 960.0)
	var h: float = maxf(size.y, 540.0)
	# Sleek deep midnight navy base with subtle geometric stadium-light angle sheen
	draw_rect(Rect2(0.0, 0.0, w, h), Color("#0B121E"))
	var sheen := PackedVector2Array([
		Vector2(w * 0.56, 0.0), Vector2(w, 0.0),
		Vector2(w, h), Vector2(w * 0.34, h),
	])
	draw_colored_polygon(sheen, Color(0.11, 0.17, 0.28, 0.28))
	var pri: Color = UITheme.parse_color(_ctx.get("primary", Color("#C81E2B")), Color("#C81E2B"))
	draw_rect(Rect2(0.0, 0.0, w, 3.0), Color(pri.r, pri.g, pri.b, 0.72))

func _fmt_comma(val: float) -> String:
	return ("%.1f" % val).replace(".", ",")

func _pos_chip_color(pos_s: String) -> Color:
	var p: String = pos_s.to_upper()
	if p == "GK":
		return Color("#D97706")
	if p in ["CB", "LB", "RB", "LWB", "RWB"]:
		return Color("#059669")
	if p in ["CM", "CDM", "CAM", "LM", "RM"]:
		return Color("#2563EB")
	return Color("#DC2626")

func _build_ui() -> void:
	var mc := MarginContainer.new()
	mc.set_anchors_preset(Control.PRESET_FULL_RECT)
	mc.add_theme_constant_override("margin_left", 28)
	mc.add_theme_constant_override("margin_right", 28)
	mc.add_theme_constant_override("margin_top", 14)
	mc.add_theme_constant_override("margin_bottom", 14)
	add_child(mc)

	var root_vb := VBoxContainer.new()
	root_vb.add_theme_constant_override("separation", 10)
	mc.add_child(root_vb)

	# --------------------------------------------------------------------------
	# 1. HEADER: MUSIM N / TAHUNMU
	# --------------------------------------------------------------------------
	var hdr_vb := VBoxContainer.new()
	hdr_vb.add_theme_constant_override("separation", 2)
	root_vb.add_child(hdr_vb)

	var title_lbl := Label.new()
	title_lbl.text = "MUSIM %d" % int(_ctx.get("season_num", 1))
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_override("font", UITheme.get_display_font())
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	hdr_vb.add_child(title_lbl)

	var sub_lbl := Label.new()
	sub_lbl.text = "TAHUNMU"
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_font_size_override("font_size", 10)
	sub_lbl.add_theme_color_override("font_color", Color("#64748B"))
	hdr_vb.add_child(sub_lbl)

	var div_line := ColorRect.new()
	div_line.custom_minimum_size = Vector2(0, 1)
	div_line.color = Color(1.0, 1.0, 1.0, 0.14)
	hdr_vb.add_child(div_line)

	# --------------------------------------------------------------------------
	# 2. TWO-COLUMN MAIN DASHBOARD BODY
	# --------------------------------------------------------------------------
	var body_hb := HBoxContainer.new()
	body_hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_hb.add_theme_constant_override("separation", 16)
	root_vb.add_child(body_hb)

	# === LEFT COLUMN: HERO TROPHY CARD + 4 METRICS + BEST MATCH ===
	var left_vb := VBoxContainer.new()
	left_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_vb.size_flags_stretch_ratio = 0.88
	left_vb.add_theme_constant_override("separation", 10)
	body_hb.add_child(left_vb)

	# 2A. Hero Trophy / Club Showcase Panel
	var hero_pc := PanelContainer.new()
	hero_pc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var hero_sb: StyleBoxFlat = UITheme.make_box(Color("#121B2B"), Color("#24334C"), 1, 8)
	hero_sb.content_margin_left = 14
	hero_sb.content_margin_right = 14
	hero_sb.content_margin_top = 12
	hero_sb.content_margin_bottom = 12
	hero_pc.add_theme_stylebox_override("panel", hero_sb)
	left_vb.add_child(hero_pc)

	var hero_vb := VBoxContainer.new()
	hero_vb.alignment = BoxContainer.ALIGNMENT_CENTER
	hero_vb.add_theme_constant_override("separation", 4)
	hero_pc.add_child(hero_vb)

	var emblem_cc := CenterContainer.new()
	hero_vb.add_child(emblem_cc)
	var emblem_hb := HBoxContainer.new()
	emblem_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	emblem_hb.add_theme_constant_override("separation", 10)
	emblem_cc.add_child(emblem_hb)

	var crest := ClubCrest.new()
	crest.custom_minimum_size = Vector2(48, 48)
	crest.set_club(int(_ctx.get("club_id", 0)))
	emblem_hb.add_child(crest)

	if bool(_ctx.get("recap_has_trophy", false)):
		var cup_ico := _RecapTrophyIcon.new()
		cup_ico.custom_minimum_size = Vector2(52, 52)
		emblem_hb.add_child(cup_ico)

	var cl_lbl := Label.new()
	cl_lbl.text = str(_ctx.get("club_name", "KLUB")).to_upper()
	cl_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cl_lbl.add_theme_font_size_override("font_size", 11)
	cl_lbl.add_theme_color_override("font_color", Color("#94A3B8"))
	hero_vb.add_child(cl_lbl)

	var big_res := Label.new()
	big_res.text = str(_ctx.get("recap_hero_title", "JUARA"))
	big_res.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	big_res.add_theme_font_override("font", UITheme.get_display_font())
	big_res.add_theme_font_size_override("font_size", 26)
	big_res.add_theme_color_override("font_color", Color("#FACC15") if bool(_ctx.get("recap_has_trophy", false)) else UITheme.TEXT_WHITE)
	hero_vb.add_child(big_res)

	var comp_lbl := Label.new()
	comp_lbl.text = str(_ctx.get("recap_hero_comp", "LIGA UTAMA"))
	comp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	comp_lbl.add_theme_font_override("font", UITheme.get_display_font())
	comp_lbl.add_theme_font_size_override("font_size", 11)
	comp_lbl.add_theme_color_override("font_color", Color("#E2E8F0"))
	hero_vb.add_child(comp_lbl)

	# 2B. 4-Metric Row (LIGA, GOL, ASSIST, RATING + vs. tahun lalu)
	var stat_pc := PanelContainer.new()
	var stat_sb: StyleBoxFlat = UITheme.make_box(Color("#111927"), Color("#223047"), 1, 8)
	stat_sb.content_margin_left = 10
	stat_sb.content_margin_right = 10
	stat_sb.content_margin_top = 10
	stat_sb.content_margin_bottom = 8
	stat_pc.add_theme_stylebox_override("panel", stat_sb)
	left_vb.add_child(stat_pc)

	var stat_outer := VBoxContainer.new()
	stat_outer.add_theme_constant_override("separation", 6)
	stat_pc.add_child(stat_outer)

	var stat_hb := HBoxContainer.new()
	stat_hb.add_theme_constant_override("separation", 6)
	stat_outer.add_child(stat_hb)

	var deltas: Dictionary = _ctx.get("recap_deltas", {"matches": 0, "goals": 0, "assists": 0, "rating": 0.0})
	var dm: int = int(deltas.get("matches", 0))
	var dg: int = int(deltas.get("goals", 0))
	var da: int = int(deltas.get("assists", 0))
	var dr: float = float(deltas.get("rating", 0.0))

	var metrics: Array[Dictionary] = [
		{"k": "LIGA", "v": str(int(_ctx.get("season_matches", 24))), "d": ("%+d" % dm), "ok": dm >= 0, "kc": Color("#38BDF8"), "vc": UITheme.TEXT_WHITE},
		{"k": "GOL", "v": str(int(_ctx.get("season_goals", 18))), "d": ("%+d" % dg), "ok": dg >= 0, "kc": Color("#F87171"), "vc": UITheme.TEXT_WHITE},
		{"k": "ASSIST", "v": str(int(_ctx.get("season_assists", 6))), "d": ("%+d" % da), "ok": da >= 0, "kc": Color("#60A5FA"), "vc": UITheme.TEXT_WHITE},
		{"k": "RATING", "v": _fmt_comma(float(_ctx.get("avg_rating", 7.8))), "d": (("+%s" % _fmt_comma(dr)) if dr >= 0.0 else _fmt_comma(dr)), "ok": dr >= 0.0, "kc": Color("#FACC15"), "vc": Color("#FACC15")},
	]
	for m in metrics:
		var cv := VBoxContainer.new()
		cv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cv.add_theme_constant_override("separation", 1)
		stat_hb.add_child(cv)

		var kl := Label.new()
		kl.text = str(m["k"])
		kl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		kl.add_theme_font_size_override("font_size", 9)
		kl.add_theme_color_override("font_color", m["kc"])
		cv.add_child(kl)

		var vl := Label.new()
		vl.text = str(m["v"])
		vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vl.add_theme_font_override("font", UITheme.get_display_font())
		vl.add_theme_font_size_override("font_size", 21)
		vl.add_theme_color_override("font_color", m["vc"])
		cv.add_child(vl)

		var dl := Label.new()
		dl.text = str(m["d"])
		dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dl.add_theme_font_size_override("font_size", 10)
		dl.add_theme_color_override("font_color", Color("#22C55E") if bool(m["ok"]) else Color("#F87171"))
		cv.add_child(dl)

	var vs_lbl := Label.new()
	vs_lbl.text = "vs. tahun lalu"
	vs_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vs_lbl.add_theme_font_size_override("font_size", 9)
	vs_lbl.add_theme_color_override("font_color", Color("#64748B"))
	stat_outer.add_child(vs_lbl)

	# 2C. Best Match Strip (LAGA TERBAIKMU)
	var bm_pc := PanelContainer.new()
	var bm_sb: StyleBoxFlat = UITheme.make_box(Color("#111927"), Color("#223047"), 1, 8)
	bm_sb.content_margin_left = 12
	bm_sb.content_margin_right = 12
	bm_sb.content_margin_top = 8
	bm_sb.content_margin_bottom = 8
	bm_pc.add_theme_stylebox_override("panel", bm_sb)
	left_vb.add_child(bm_pc)

	var bm_hb := HBoxContainer.new()
	bm_hb.add_theme_constant_override("separation", 8)
	bm_pc.add_child(bm_hb)

	var bm_d: Dictionary = _ctx.get("best_match", {})
	var bm_lv := VBoxContainer.new()
	bm_lv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bm_lv.add_theme_constant_override("separation", 1)
	bm_hb.add_child(bm_lv)

	var bm_k := Label.new()
	bm_k.text = "LAGA TERBAIKMU"
	bm_k.add_theme_font_size_override("font_size", 9)
	bm_k.add_theme_color_override("font_color", Color("#64748B"))
	bm_lv.add_child(bm_k)

	var bm_v := Label.new()
	bm_v.text = "vs %s  •  %dG %dA" % [str(bm_d.get("opp_name", "Rival")).left(22), int(bm_d.get("goals", 2)), int(bm_d.get("assists", 0))]
	bm_v.clip_text = true
	bm_v.add_theme_font_override("font", UITheme.get_display_font())
	bm_v.add_theme_font_size_override("font_size", 11)
	bm_v.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	bm_lv.add_child(bm_v)

	var bm_sc := Label.new()
	bm_sc.text = _fmt_comma(float(bm_d.get("rating", 9.6)))
	bm_sc.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bm_sc.add_theme_font_override("font", UITheme.get_display_font())
	bm_sc.add_theme_font_size_override("font_size", 20)
	bm_sc.add_theme_color_override("font_color", Color("#FACC15"))
	bm_hb.add_child(bm_sc)

	# === RIGHT COLUMN: KAMU & REKAN SETIM TABLE + TARGETMU + MUSIM KLUB ===
	var right_vb := VBoxContainer.new()
	right_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vb.size_flags_stretch_ratio = 1.12
	right_vb.add_theme_constant_override("separation", 10)
	body_hb.add_child(right_vb)

	# 2D. Teammates Table Card
	var tm_pc := PanelContainer.new()
	tm_pc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var tm_sb: StyleBoxFlat = UITheme.make_box(Color("#111927"), Color("#223047"), 1, 8)
	tm_sb.content_margin_left = 12
	tm_sb.content_margin_right = 12
	tm_sb.content_margin_top = 10
	tm_sb.content_margin_bottom = 8
	tm_pc.add_theme_stylebox_override("panel", tm_sb)
	right_vb.add_child(tm_pc)

	var tm_vb := VBoxContainer.new()
	tm_vb.add_theme_constant_override("separation", 4)
	tm_pc.add_child(tm_vb)

	var tm_hdr := Label.new()
	tm_hdr.text = "• KAMU & REKAN SETIM •"
	tm_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tm_hdr.add_theme_font_override("font", UITheme.get_display_font())
	tm_hdr.add_theme_font_size_override("font_size", 11)
	tm_hdr.add_theme_color_override("font_color", Color("#CBD5E1"))
	tm_vb.add_child(tm_hdr)

	# Compact column legend header
	var col_hb := HBoxContainer.new()
	col_hb.add_theme_constant_override("separation", 6)
	tm_vb.add_child(col_hb)
	for hdr_pair in [["POS", 34, HORIZONTAL_ALIGNMENT_CENTER], ["PEMAIN", 0, HORIZONTAL_ALIGNMENT_LEFT], ["DIFF", 38, HORIZONTAL_ALIGNMENT_RIGHT], ["G", 30, HORIZONTAL_ALIGNMENT_RIGHT], ["A", 28, HORIZONTAL_ALIGNMENT_RIGHT], ["RTG", 42, HORIZONTAL_ALIGNMENT_RIGHT]]:
		var hl := Label.new()
		hl.text = str(hdr_pair[0])
		hl.horizontal_alignment = int(hdr_pair[2])
		if int(hdr_pair[1]) == 0:
			hl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		else:
			hl.custom_minimum_size = Vector2(float(hdr_pair[1]), 0)
		hl.add_theme_font_size_override("font_size", 9)
		hl.add_theme_color_override("font_color", Color("#64748B"))
		col_hb.add_child(hl)

	var tm_rows: Array = _ctx.get("teammates_table", [])
	for ri in range(mini(6, tm_rows.size())):
		var rd: Dictionary = tm_rows[ri]
		var is_u: bool = bool(rd.get("is_user", false))
		var row_pc := PanelContainer.new()
		var rsb: StyleBoxFlat = UITheme.make_box(Color(0.98, 0.80, 0.08, 0.12) if is_u else Color(1.0, 1.0, 1.0, 0.02), Color("#EAB308") if is_u else Color(0, 0, 0, 0), 1 if is_u else 0, 4)
		rsb.content_margin_left = 6
		rsb.content_margin_right = 6
		rsb.content_margin_top = 3
		rsb.content_margin_bottom = 3
		row_pc.add_theme_stylebox_override("panel", rsb)
		tm_vb.add_child(row_pc)

		var rhb := HBoxContainer.new()
		rhb.add_theme_constant_override("separation", 6)
		row_pc.add_child(rhb)

		var pos_s: String = str(rd.get("pos", "ST")).left(3)
		var pos_bg := PanelContainer.new()
		pos_bg.custom_minimum_size = Vector2(34, 18)
		var psb: StyleBoxFlat = UITheme.make_box(_pos_chip_color(pos_s), Color(0, 0, 0, 0), 0, 3)
		psb.content_margin_left = 2
		psb.content_margin_right = 2
		psb.content_margin_top = 1
		psb.content_margin_bottom = 1
		pos_bg.add_theme_stylebox_override("panel", psb)
		rhb.add_child(pos_bg)
		var pos_l := Label.new()
		pos_l.text = pos_s
		pos_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pos_l.add_theme_font_override("font", UITheme.get_display_font())
		pos_l.add_theme_font_size_override("font_size", 9)
		pos_l.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
		pos_bg.add_child(pos_l)

		var nm_l := Label.new()
		nm_l.text = str(rd.get("name", "Pemain"))
		nm_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nm_l.clip_text = true
		if is_u:
			nm_l.add_theme_font_override("font", UITheme.get_display_font())
		nm_l.add_theme_font_size_override("font_size", 11)
		nm_l.add_theme_color_override("font_color", Color("#FEF08A") if is_u else Color("#E2E8F0"))
		rhb.add_child(nm_l)

		var diff_l := Label.new()
		diff_l.text = str(rd.get("delta", ""))
		diff_l.custom_minimum_size = Vector2(38, 0)
		diff_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		diff_l.add_theme_font_size_override("font_size", 10)
		diff_l.add_theme_color_override("font_color", Color("#64748B"))
		rhb.add_child(diff_l)

		var gl := Label.new()
		gl.text = str(int(rd.get("goals", 0)))
		gl.custom_minimum_size = Vector2(30, 0)
		gl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		gl.add_theme_font_override("font", UITheme.get_display_font())
		gl.add_theme_font_size_override("font_size", 11)
		gl.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
		rhb.add_child(gl)

		var al := Label.new()
		al.text = str(int(rd.get("assists", 0)))
		al.custom_minimum_size = Vector2(28, 0)
		al.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		al.add_theme_font_size_override("font_size", 11)
		al.add_theme_color_override("font_color", Color("#94A3B8"))
		rhb.add_child(al)

		var rl := Label.new()
		rl.text = _fmt_comma(float(rd.get("rating", 7.0)))
		rl.custom_minimum_size = Vector2(42, 0)
		rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		rl.add_theme_font_override("font", UITheme.get_display_font())
		rl.add_theme_font_size_override("font_size", 11)
		rl.add_theme_color_override("font_color", Color("#FACC15") if is_u else UITheme.TEXT_WHITE)
		rhb.add_child(rl)

	# 2E. Personal Goal Target Box (TARGETMU -> TERCAPAI / BELUM TERCAPAI)
	var t_ok: bool = bool(_ctx.get("target_reached", true))
	var tg_pc := PanelContainer.new()
	var tg_sb: StyleBoxFlat = UITheme.make_box(Color("#111927"), Color("#22C55E") if t_ok else Color("#EF4444"), 1, 8)
	tg_sb.content_margin_left = 12
	tg_sb.content_margin_right = 12
	tg_sb.content_margin_top = 8
	tg_sb.content_margin_bottom = 8
	tg_pc.add_theme_stylebox_override("panel", tg_sb)
	right_vb.add_child(tg_pc)

	var tg_hb := HBoxContainer.new()
	tg_hb.add_theme_constant_override("separation", 8)
	tg_pc.add_child(tg_hb)

	var tg_lv := VBoxContainer.new()
	tg_lv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tg_lv.add_theme_constant_override("separation", 1)
	tg_hb.add_child(tg_lv)

	var tg_k := Label.new()
	tg_k.text = "TARGETMU"
	tg_k.add_theme_font_size_override("font_size", 9)
	tg_k.add_theme_color_override("font_color", Color("#64748B"))
	tg_lv.add_child(tg_k)

	var tg_v := Label.new()
	tg_v.text = "%d gol, kamu cetak %d" % [int(_ctx.get("goal_target", 11)), int(_ctx.get("season_goals", 18))]
	tg_v.add_theme_font_override("font", UITheme.get_display_font())
	tg_v.add_theme_font_size_override("font_size", 11)
	tg_v.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	tg_lv.add_child(tg_v)

	var tg_st := Label.new()
	tg_st.text = "TERCAPAI" if t_ok else "BELUM"
	tg_st.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tg_st.add_theme_font_override("font", UITheme.get_display_font())
	tg_st.add_theme_font_size_override("font_size", 14)
	tg_st.add_theme_color_override("font_color", Color("#22C55E") if t_ok else Color("#F87171"))
	tg_hb.add_child(tg_st)

	# 2F. Club Season Objectives Strip (MUSIM KLUB: ✓ LIGA / ✗ PIALA / ✓ PIALA ELITE | 2/3)
	var co_pc := PanelContainer.new()
	var co_sb: StyleBoxFlat = UITheme.make_box(Color("#111927"), Color("#223047"), 1, 8)
	co_sb.content_margin_left = 12
	co_sb.content_margin_right = 12
	co_sb.content_margin_top = 8
	co_sb.content_margin_bottom = 8
	co_pc.add_theme_stylebox_override("panel", co_sb)
	right_vb.add_child(co_pc)

	var co_hb := HBoxContainer.new()
	co_hb.add_theme_constant_override("separation", 10)
	co_pc.add_child(co_hb)

	var co_k := Label.new()
	co_k.text = "MUSIM KLUB"
	co_k.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	co_k.add_theme_font_size_override("font_size", 9)
	co_k.add_theme_color_override("font_color", Color("#64748B"))
	co_hb.add_child(co_k)

	var objs: Array = _ctx.get("club_objectives", [])
	for ob in objs:
		var obd: Dictionary = ob
		var ok: bool = bool(obd.get("ok", false))
		var ol := Label.new()
		ol.text = ("%s %s" % ["✓" if ok else "X", str(obd.get("label", "LIGA"))])
		ol.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		ol.add_theme_font_override("font", UITheme.get_display_font())
		ol.add_theme_font_size_override("font_size", 10)
		ol.add_theme_color_override("font_color", Color("#22C55E") if ok else Color("#64748B"))
		co_hb.add_child(ol)

	var co_sp := Control.new()
	co_sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	co_hb.add_child(co_sp)

	var obj_done: int = int(_ctx.get("club_obj_done", 2))
	var obj_tot: int = int(_ctx.get("club_obj_total", 3))
	var ratio_l := Label.new()
	ratio_l.text = "%d/%d" % [obj_done, obj_tot]
	ratio_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ratio_l.add_theme_font_override("font", UITheme.get_display_font())
	ratio_l.add_theme_font_size_override("font_size", 14)
	ratio_l.add_theme_color_override("font_color", Color("#FACC15") if obj_done >= 2 else UITheme.TEXT_WHITE)
	co_hb.add_child(ratio_l)

	# --------------------------------------------------------------------------
	# 3. BOTTOM CENTER ACTION BUTTON: LANJUTKAN
	# --------------------------------------------------------------------------
	var btn_cc := CenterContainer.new()
	root_vb.add_child(btn_cc)

	var go_btn := Button.new()
	go_btn.text = "LANJUTKAN"
	go_btn.custom_minimum_size = Vector2(248, 38)
	UITheme.style_btn(go_btn, Color("#111B2E"), Color("#E2E8F0"), 14)
	go_btn.pressed.connect(func():
		AudioSynth.play_click()
		continue_pressed.emit()
	)
	btn_cc.add_child(go_btn)

# ==============================================================================
# MINI GOLDEN TROPHY CUP ICON FOR HERO SHOWCASE CARD
# ==============================================================================
class _RecapTrophyIcon extends Control:
	func _draw() -> void:
		var cx: float = size.x * 0.5
		var cy: float = size.y * 0.5
		draw_circle(Vector2(cx, cy - 2.0), 22.0, Color(1.0, 0.85, 0.25, 0.16))
		var gold := Color("#EAB308")
		var hi := Color("#FEF08A")
		var cup := PackedVector2Array([
			Vector2(cx - 14.0, cy - 16.0), Vector2(cx + 14.0, cy - 16.0),
			Vector2(cx + 9.0, cy + 4.0), Vector2(cx - 9.0, cy + 4.0),
		])
		draw_colored_polygon(cup, gold)
		draw_rect(Rect2(cx - 10.0, cy - 14.0, 4.0, 12.0), hi)
		# Handles
		draw_arc(Vector2(cx - 13.0, cy - 8.0), 5.0, PI * 0.5, PI * 1.5, 10, gold, 2.5)
		draw_arc(Vector2(cx + 13.0, cy - 8.0), 5.0, -PI * 0.5, PI * 0.5, 10, gold, 2.5)
		# Stem & base
		draw_rect(Rect2(cx - 3.0, cy + 4.0, 6.0, 10.0), gold)
		draw_rect(Rect2(cx - 12.0, cy + 14.0, 24.0, 5.0), Color("#92400E"))
		draw_rect(Rect2(cx - 10.0, cy + 12.0, 20.0, 3.0), hi)
