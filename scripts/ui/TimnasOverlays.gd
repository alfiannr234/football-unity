extends RefCounted

const ConfederationDataScript := preload("res://scripts/data/ConfederationData.gd")
const CompOverlaysScript := preload("res://scripts/ui/CompOverlays.gd")

const BG_OVERLAY := Color("#070F1C")
const BG_CARD := Color("#0B1626")
const BORDER_SUBTLE := Color("#1F334F")
const GOLD_ACCENT := Color("#EAB308")
const GOLD_BRIGHT := Color("#FACC15")

static func format_num_id(val: float) -> String:
	return ("%.1f" % val).replace(".", ",")

static func get_ovr_tier_color(ovr: int) -> Color:
	if ovr >= 91:
		return Color("#A855F7")
	if ovr >= 85:
		return Color("#38BDF8")
	if ovr >= 76:
		return Color("#EAB308")
	if ovr >= 70:
		return Color("#CBD5E1")
	return Color("#B47B48")

static func make_callup_gauge(level_you: float, level_req: int) -> Control:
	var g := CallupGaugeControl.new()
	g.level_you = level_you
	g.level_req = level_req
	g.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return g

static func make_hex_ovr(ovr: int, sz: Vector2 = Vector2(28, 28)) -> Control:
	var h := HexOvrBadgeControl.new()
	h.ovr_val = ovr
	h.tier_color = get_ovr_tier_color(ovr)
	h.custom_minimum_size = sz
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return h

static func make_knockout_bracket(ko_data: Dictionary, user_code: String, compact: bool = true) -> Control:
	var bk := KnockoutBracketControl.new()
	bk.ko_data = ko_data
	bk.user_code = user_code.to_upper()
	bk.compact_mode = compact
	bk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bk.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return bk

static func _style_btn(btn: Button, bg: Color, border: Color, font_sz: int = 12, text_col: Color = UITheme.TEXT_WHITE) -> void:
	var n := StyleBoxFlat.new()
	n.bg_color = bg
	n.border_color = border
	n.set_border_width_all(1)
	n.set_corner_radius_all(4)
	n.content_margin_left = 8
	n.content_margin_right = 8
	n.content_margin_top = 4
	n.content_margin_bottom = 4
	var h := n.duplicate()
	h.bg_color = bg.lightened(0.14)
	h.border_color = UITheme.BORDER_CYAN
	var pr := n.duplicate()
	pr.bg_color = bg.darkened(0.10)
	pr.border_color = GOLD_BRIGHT
	btn.add_theme_stylebox_override("normal", n)
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_stylebox_override("pressed", pr)
	btn.add_theme_stylebox_override("focus", h)
	btn.add_theme_font_size_override("font_size", font_sz)
	btn.add_theme_color_override("font_color", text_col)
	btn.add_theme_color_override("font_hover_color", UITheme.TEXT_WHITE)
	btn.add_theme_color_override("font_pressed_color", GOLD_BRIGHT)

static func _create_layer(parent: Node, layer_idx: int = 20) -> Dictionary:
	var layer := EscCanvasLayer.new()
	layer.layer = layer_idx
	parent.add_child(layer)
	var root := Control.new()
	root.theme = UITheme.build_theme()
	root.clip_contents = true
	layer.add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = BG_OVERLAY
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return {"layer": layer, "root": root}

# ==============================================================================
# 1. PANGGILAN 25-MAN NATIONAL SQUAD OVERLAY
# ==============================================================================
static func open_squad_25_overlay(parent: Node, overview: Dictionary) -> CanvasLayer:
	var built: Dictionary = _create_layer(parent, 20)
	var layer: CanvasLayer = built["layer"]
	var root: Control = built["root"]

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	root.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 8)
	margin.add_child(outer)

	var top_hb := HBoxContainer.new()
	top_hb.add_theme_constant_override("separation", 10)
	outer.add_child(top_hb)

	var fl_w := CenterContainer.new()
	fl_w.add_child(UITheme.make_flag_by_code(str(overview.get("nation_code", "IDN")), [], Vector2(26, 18)))
	top_hb.add_child(fl_w)

	var title := Label.new()
	title.text = "SKUAD TIMNAS %s  •  PANGGILAN 25 PEMAIN (%s)" % [str(overview.get("nation_name", "TIMNAS")), str(overview.get("confed", "AFC"))]
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.clip_text = true
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", UITheme.get_display_font())
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", GOLD_BRIGHT)
	top_hb.add_child(title)

	var close_top := Button.new()
	close_top.text = "TUTUP"
	close_top.custom_minimum_size = Vector2(92, 32)
	_style_btn(close_top, Color("#121D2F"), Color("#273A56"), 12)
	close_top.pressed.connect(func():
		AudioSynth.play_click()
		layer.queue_free()
	)
	top_hb.add_child(close_top)

	var cols := HBoxContainer.new()
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.add_theme_constant_override("separation", 12)
	outer.add_child(cols)

	var squad: Array = overview.get("squad_25", [])
	for grp_idx in range(2):
		var col_p := PanelContainer.new()
		col_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col_p.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var csb := StyleBoxFlat.new()
		csb.bg_color = BG_CARD
		csb.border_color = GOLD_ACCENT if grp_idx == 0 else BORDER_SUBTLE
		csb.set_border_width_all(1)
		csb.set_corner_radius_all(6)
		csb.content_margin_left = 10
		csb.content_margin_right = 10
		csb.content_margin_top = 8
		csb.content_margin_bottom = 8
		col_p.add_theme_stylebox_override("panel", csb)
		cols.add_child(col_p)

		var cvb := VBoxContainer.new()
		cvb.add_theme_constant_override("separation", 5)
		col_p.add_child(cvb)

		var chdr := Label.new()
		chdr.text = "TIM INTI (11)" if grp_idx == 0 else "CADANGAN (14)"
		chdr.add_theme_font_override("font", UITheme.get_display_font())
		chdr.add_theme_font_size_override("font_size", 12)
		chdr.add_theme_color_override("font_color", GOLD_BRIGHT if grp_idx == 0 else UITheme.ACCENT_CYAN)
		cvb.add_child(chdr)

		var sc := ScrollContainer.new()
		sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		cvb.add_child(sc)

		var list_vb := VBoxContainer.new()
		list_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		list_vb.add_theme_constant_override("separation", 3)
		sc.add_child(list_vb)

		var start_i: int = 0 if grp_idx == 0 else 11
		var end_i: int = mini(11, squad.size()) if grp_idx == 0 else squad.size()
		for i in range(start_i, end_i):
			var p: Dictionary = squad[i]
			var is_u: bool = bool(p.get("is_user", false))
			var rp := PanelContainer.new()
			var rsb := StyleBoxFlat.new()
			rsb.bg_color = Color("#2C2612") if is_u else Color("#091220")
			rsb.border_color = GOLD_BRIGHT if is_u else Color("#18283F")
			rsb.set_border_width_all(1)
			rsb.set_corner_radius_all(4)
			rsb.content_margin_left = 6
			rsb.content_margin_right = 8
			rsb.content_margin_top = 3
			rsb.content_margin_bottom = 3
			rp.add_theme_stylebox_override("panel", rsb)
			list_vb.add_child(rp)

			var rhb := HBoxContainer.new()
			rhb.add_theme_constant_override("separation", 8)
			rp.add_child(rhb)

			var hw := CenterContainer.new()
			hw.add_child(make_hex_ovr(int(p.get("ovr", 65)), Vector2(24, 24)))
			rhb.add_child(hw)

			var pos_l := Label.new()
			pos_l.text = str(p.get("pos", "ST"))
			pos_l.custom_minimum_size = Vector2(32, 0)
			pos_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			pos_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			pos_l.add_theme_font_override("font", UITheme.get_display_font())
			pos_l.add_theme_font_size_override("font_size", 10)
			pos_l.add_theme_color_override("font_color", Color("#FB923C"))
			rhb.add_child(pos_l)

			var nm_l := Label.new()
			nm_l.text = "%s%s" % [str(p.get("name", "Pemain")), " (KAMU)" if is_u else ""]
			nm_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			nm_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			nm_l.clip_text = true
			nm_l.add_theme_font_size_override("font_size", 12)
			nm_l.add_theme_color_override("font_color", GOLD_BRIGHT if is_u else UITheme.TEXT_WHITE)
			rhb.add_child(nm_l)

			var cl_l := Label.new()
			cl_l.text = str(p.get("club_code", "CLB"))
			cl_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			cl_l.add_theme_font_size_override("font_size", 11)
			cl_l.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
			rhb.add_child(cl_l)

	return layer

# ==============================================================================
# 2. 6-CONFEDERATION HUB, POTS & FULL KNOCKOUT BRACKET OVERLAY (Gambar 2)
# ==============================================================================
static func open_confederation_hub_overlay(parent: Node, initial_confed: String = "AFC") -> CanvasLayer:
	var built: Dictionary = _create_layer(parent, 20)
	var layer: CanvasLayer = built["layer"]
	var root: Control = built["root"]

	var state := {
		"confed": initial_confed if ConfederationDataScript.CONFED_META.has(initial_confed) else "AFC",
		"view": "GRUP",  # "GRUP" or "BAGAN"
	}

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	root.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var outer := VBoxContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("separation", 8)
	margin.add_child(outer)

	var top_hb := HBoxContainer.new()
	top_hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hb.add_theme_constant_override("separation", 6)
	outer.add_child(top_hb)

	var confed_bar := HBoxContainer.new()
	confed_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confed_bar.add_theme_constant_override("separation", 4)
	top_hb.add_child(confed_bar)

	var close_b := Button.new()
	close_b.text = "TUTUP"
	close_b.custom_minimum_size = Vector2(78, 32)
	_style_btn(close_b, Color("#121D2F"), Color("#273A56"), 11)
	close_b.pressed.connect(func():
		AudioSynth.play_click()
		layer.queue_free()
	)
	top_hb.add_child(close_b)

	var body_vb := VBoxContainer.new()
	body_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_vb.add_theme_constant_override("separation", 8)
	outer.add_child(body_vb)

	var render_ref := {}
	render_ref["fn"] = func() -> void:
		for c in confed_bar.get_children():
			confed_bar.remove_child(c)
			c.queue_free()
		for cid in ConfederationDataScript.CONFED_ORDER:
			var meta: Dictionary = ConfederationDataScript.CONFED_META[cid]
			var acc: Color = meta["accent"]
			var is_act: bool = (str(state["confed"]) == cid)
			var cb := Button.new()
			cb.text = cid
			cb.clip_text = true
			cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			cb.custom_minimum_size = Vector2(0, 32)
			_style_btn(cb, acc.darkened(0.55) if is_act else Color("#0B1424"), acc if is_act else Color("#1D2E48"), 11, UITheme.TEXT_WHITE if is_act else UITheme.TEXT_MUTED)
			var cid_copy: String = cid
			cb.pressed.connect(func():
				AudioSynth.play_click()
				state["confed"] = cid_copy
				render_ref["fn"].call()
			)
			confed_bar.add_child(cb)

		for c in body_vb.get_children():
			body_vb.remove_child(c)
			c.queue_free()

		var data: Dictionary = CareerState.build_confed_explorer_data(str(state["confed"]))
		var meta: Dictionary = data["meta"]
		var camp: Dictionary = data["campaign"]
		var acc: Color = meta["accent"]

		# Confederation banner + view toggle (GRUP & POT | BAGAN)
		var info_p := PanelContainer.new()
		info_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var isb := StyleBoxFlat.new()
		isb.bg_color = BG_CARD
		isb.border_color = acc
		isb.set_border_width_all(1)
		isb.set_corner_radius_all(6)
		isb.content_margin_left = 10
		isb.content_margin_right = 10
		isb.content_margin_top = 7
		isb.content_margin_bottom = 7
		info_p.add_theme_stylebox_override("panel", isb)
		body_vb.add_child(info_p)

		var ihb := HBoxContainer.new()
		ihb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ihb.add_theme_constant_override("separation", 8)
		info_p.add_child(ihb)

		var ivb := VBoxContainer.new()
		ivb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ivb.custom_minimum_size = Vector2(10, 0)
		ivb.add_theme_constant_override("separation", 2)
		ihb.add_child(ivb)

		var t1 := Label.new()
		t1.text = "%s • %s (%s)" % [str(meta["id"]), str(meta["main_tournament"]), str(meta["region"])]
		t1.clip_text = true
		t1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		t1.add_theme_font_override("font", UITheme.get_display_font())
		t1.add_theme_font_size_override("font_size", 12)
		t1.add_theme_color_override("font_color", acc.lightened(0.15))
		ivb.add_child(t1)

		var t2 := Label.new()
		t2.text = "%s • %s • %s" % [str(camp.get("title", "")), str(camp.get("months", meta["months"])), str(camp.get("format_note", ""))]
		t2.clip_text = true
		t2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		t2.add_theme_font_size_override("font_size", 10)
		t2.add_theme_color_override("font_color", Color("#CBD5E1"))
		ivb.add_child(t2)

		for v_opt in [["GRUP", "GRUP & POT"], ["BAGAN", "BAGAN"]]:
			var vk: String = str(v_opt[0])
			var vb_btn := Button.new()
			vb_btn.text = str(v_opt[1])
			vb_btn.custom_minimum_size = Vector2(96 if vk == "GRUP" else 76, 32)
			var act_v: bool = (str(state["view"]) == vk)
			_style_btn(vb_btn, Color("#19375F") if act_v else Color("#0A1322"), GOLD_BRIGHT if act_v else Color("#223450"), 10, GOLD_BRIGHT if act_v else UITheme.TEXT_MUTED)
			vb_btn.pressed.connect(func():
				AudioSynth.play_click()
				state["view"] = vk
				render_ref["fn"].call()
			)
			ihb.add_child(vb_btn)

		if str(state["view"]) == "GRUP":
			var split := HBoxContainer.new()
			split.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			split.size_flags_vertical = Control.SIZE_EXPAND_FILL
			split.add_theme_constant_override("separation", 10)
			body_vb.add_child(split)

			# Left: Group Standings Card
			var gp := PanelContainer.new()
			gp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			gp.size_flags_vertical = Control.SIZE_EXPAND_FILL
			gp.size_flags_stretch_ratio = 0.95
			gp.clip_contents = true
			var gsb := StyleBoxFlat.new()
			gsb.bg_color = Color("#091220")
			gsb.border_color = BORDER_SUBTLE
			gsb.set_border_width_all(1)
			gsb.set_corner_radius_all(6)
			gsb.content_margin_left = 10
			gsb.content_margin_right = 10
			gsb.content_margin_top = 8
			gsb.content_margin_bottom = 8
			gp.add_theme_stylebox_override("panel", gsb)
			split.add_child(gp)

			var gvb := VBoxContainer.new()
			gvb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			gvb.add_theme_constant_override("separation", 3)
			gp.add_child(gvb)

			var ghdr := HBoxContainer.new()
			gvb.add_child(ghdr)
			var gtl := Label.new()
			gtl.text = "%s • %s" % [str(camp.get("short_title", "GRUP")), str(data["group_name"])]
			gtl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			gtl.clip_text = true
			gtl.add_theme_font_override("font", UITheme.get_display_font())
			gtl.add_theme_font_size_override("font_size", 12)
			gtl.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
			ghdr.add_child(gtl)
			for ch in [["POT", 34], ["MN", 28], ["PTS", 34]]:
				var cl := Label.new()
				cl.text = str(ch[0])
				cl.custom_minimum_size = Vector2(int(ch[1]), 0)
				cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				cl.add_theme_font_size_override("font_size", 10)
				cl.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
				ghdr.add_child(cl)

			var gsc := ScrollContainer.new()
			gsc.size_flags_vertical = Control.SIZE_EXPAND_FILL
			gsc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
			gvb.add_child(gsc)

			var gr_vb := VBoxContainer.new()
			gr_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			gr_vb.add_theme_constant_override("separation", 3)
			gsc.add_child(gr_vb)

			var q_top: int = int(camp.get("qualify_top", 2))
			var g_rows: Array = data["group_rows"]
			for i in range(g_rows.size()):
				var r: Dictionary = g_rows[i]
				var is_u: bool = bool(r.get("is_user", false))
				var rp := PanelContainer.new()
				var rsb := StyleBoxFlat.new()
				rsb.bg_color = Color("#3A3219") if is_u else Color("#0D182A")
				rsb.border_color = GOLD_ACCENT if is_u else Color(0, 0, 0, 0)
				rsb.set_border_width_all(1 if is_u else 0)
				rsb.set_corner_radius_all(3)
				rsb.content_margin_left = 6
				rsb.content_margin_right = 6
				rsb.content_margin_top = 4
				rsb.content_margin_bottom = 4
				rp.add_theme_stylebox_override("panel", rsb)
				gr_vb.add_child(rp)

				var rhb := HBoxContainer.new()
				rhb.add_theme_constant_override("separation", 6)
				rp.add_child(rhb)

				var rkl := Label.new()
				rkl.text = str(i + 1)
				rkl.custom_minimum_size = Vector2(18, 0)
				rkl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				rkl.add_theme_font_size_override("font_size", 12)
				rkl.add_theme_color_override("font_color", GOLD_BRIGHT if is_u else UITheme.TEXT_MUTED)
				rhb.add_child(rkl)

				var fw := CenterContainer.new()
				fw.add_child(UITheme.make_flag_by_code(str(r["code"]), r.get("colors", []), Vector2(20, 14)))
				rhb.add_child(fw)

				var nl := Label.new()
				nl.text = str(r["name"]).to_upper()
				nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				nl.clip_text = true
				nl.add_theme_font_size_override("font_size", 12)
				nl.add_theme_color_override("font_color", GOLD_BRIGHT if is_u else UITheme.TEXT_WHITE)
				rhb.add_child(nl)

				var potl := Label.new()
				potl.text = "P%d" % int(r.get("pot", 1))
				potl.custom_minimum_size = Vector2(34, 0)
				potl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				potl.add_theme_font_size_override("font_size", 11)
				potl.add_theme_color_override("font_color", UITheme.ACCENT_CYAN)
				rhb.add_child(potl)

				var mnl := Label.new()
				mnl.text = str(int(r.get("p", 0)))
				mnl.custom_minimum_size = Vector2(28, 0)
				mnl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				mnl.add_theme_font_size_override("font_size", 12)
				rhb.add_child(mnl)

				var ptsl := Label.new()
				ptsl.text = str(int(r.get("pts", 0)))
				ptsl.custom_minimum_size = Vector2(34, 0)
				ptsl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				ptsl.add_theme_font_override("font", UITheme.get_display_font())
				ptsl.add_theme_font_size_override("font_size", 12)
				ptsl.add_theme_color_override("font_color", GOLD_BRIGHT if is_u else UITheme.TEXT_WHITE)
				rhb.add_child(ptsl)

				if (i + 1) == q_top and (i + 1) < g_rows.size():
					var cut_line := ColorRect.new()
					cut_line.custom_minimum_size = Vector2(0, 2)
					cut_line.color = GOLD_ACCENT
					gr_vb.add_child(cut_line)

			# Right: Pot Seeding Breakdown Card
			var pp := PanelContainer.new()
			pp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			pp.size_flags_vertical = Control.SIZE_EXPAND_FILL
			pp.size_flags_stretch_ratio = 1.35
			pp.clip_contents = true
			var psb := StyleBoxFlat.new()
			psb.bg_color = Color("#091220")
			psb.border_color = BORDER_SUBTLE
			psb.set_border_width_all(1)
			psb.set_corner_radius_all(6)
			psb.content_margin_left = 10
			psb.content_margin_right = 10
			psb.content_margin_top = 8
			psb.content_margin_bottom = 8
			pp.add_theme_stylebox_override("panel", psb)
			split.add_child(pp)

			var pvb := VBoxContainer.new()
			pvb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			pvb.add_theme_constant_override("separation", 6)
			pp.add_child(pvb)

			var ptl := Label.new()
			ptl.text = "PEMBAGIAN POT UNDIAN (%s)" % str(meta["id"])
			ptl.clip_text = true
			ptl.add_theme_font_override("font", UITheme.get_display_font())
			ptl.add_theme_font_size_override("font_size", 12)
			ptl.add_theme_color_override("font_color", GOLD_BRIGHT)
			pvb.add_child(ptl)

			var psc := ScrollContainer.new()
			psc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			psc.size_flags_vertical = Control.SIZE_EXPAND_FILL
			psc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
			pvb.add_child(psc)

			var pgrid := GridContainer.new()
			pgrid.columns = 2
			pgrid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			pgrid.add_theme_constant_override("h_separation", 8)
			pgrid.add_theme_constant_override("v_separation", 8)
			psc.add_child(pgrid)

			for pot_d in data["pots"]:
				var pot_card := PanelContainer.new()
				pot_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				pot_card.clip_contents = true
				var pcsb := StyleBoxFlat.new()
				pcsb.bg_color = Color("#0E1A2E")
				pcsb.border_color = Color("#203554")
				pcsb.set_border_width_all(1)
				pcsb.set_corner_radius_all(4)
				pcsb.content_margin_left = 7
				pcsb.content_margin_right = 7
				pcsb.content_margin_top = 5
				pcsb.content_margin_bottom = 5
				pot_card.add_theme_stylebox_override("panel", pcsb)
				pgrid.add_child(pot_card)

				var pot_vb := VBoxContainer.new()
				pot_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				pot_vb.add_theme_constant_override("separation", 3)
				pot_card.add_child(pot_vb)

				var pl_h := Label.new()
				pl_h.text = "POT %d" % int(pot_d["pot"])
				pl_h.add_theme_font_override("font", UITheme.get_display_font())
				pl_h.add_theme_font_size_override("font_size", 11)
				pl_h.add_theme_color_override("font_color", acc.lightened(0.15))
				pot_vb.add_child(pl_h)

				for tm in pot_d["teams"]:
					var thb := HBoxContainer.new()
					thb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					thb.add_theme_constant_override("separation", 5)
					var tfw := CenterContainer.new()
					tfw.add_child(UITheme.make_flag_by_code(str(tm["code"]), tm.get("colors", []), Vector2(15, 10)))
					thb.add_child(tfw)
					var tnl := Label.new()
					tnl.text = "%s (%d)" % [str(tm["name"]), int(tm["ovr"])]
					tnl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					tnl.custom_minimum_size = Vector2(10, 0)
					tnl.clip_text = true
					tnl.add_theme_font_size_override("font_size", 10)
					tnl.add_theme_color_override("font_color", Color("#E2E8F0"))
					thb.add_child(tnl)
					pot_vb.add_child(thb)
		else:
			# Full visual knockout bracket view (live or preview for selected confederation!)
			var ko_show: Dictionary = data["knockout"]
			var my_code: String = str(CareerState.ensure_intl_state().get("nation_code", "")) if CareerState.has_active_career else ""
			if ko_show.is_empty():
				# Generate deterministic preview bracket for this confederation's main tournament!
				var cid_s: String = str(state["confed"])
				var c_info: Dictionary = meta["continental"]
				var prev_camp := {"kind": "CONTINENTAL", "knockout_start": str(c_info.get("knockout_start", "16 BESAR"))}
				var prev_intl := {"confed": cid_s, "nation_code": "__PREVIEW__", "campaign": prev_camp, "group_table": []}
				var rng := RandomNumberGenerator.new()
				rng.seed = cid_s.hash() + 2026
				ko_show = CareerState._build_intl_knockout_bracket(prev_intl, false, rng)

			var b_card := PanelContainer.new()
			b_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
			var bsb := StyleBoxFlat.new()
			bsb.bg_color = Color("#091220")
			bsb.border_color = BORDER_SUBTLE
			bsb.set_border_width_all(1)
			bsb.set_corner_radius_all(6)
			bsb.content_margin_left = 10
			bsb.content_margin_right = 10
			bsb.content_margin_top = 8
			bsb.content_margin_bottom = 8
			b_card.add_theme_stylebox_override("panel", bsb)
			body_vb.add_child(b_card)

			var b_inner := VBoxContainer.new()
			b_inner.add_theme_constant_override("separation", 4)
			b_card.add_child(b_inner)

			var b_leg := Label.new()
			b_leg.text = "BAGAN %s  •  Garis Putih Menyala = Lolos  |  Garis Putih Memudar = Gagal" % str(meta["main_tournament"])
			b_leg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			b_leg.add_theme_font_size_override("font_size", 11)
			b_leg.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
			b_inner.add_child(b_leg)

			b_inner.add_child(make_knockout_bracket(ko_show, my_code if bool(data["is_my_confed"]) else "", false))

	render_ref["fn"].call()
	return layer

# ==============================================================================
# 3. ANIMATED CHAMPIONSHIP TROPHY CELEBRATION OVERLAY (Winning Asian Cup / Continental / World Cup!)
# ==============================================================================
static func open_championship_celebration(parent: Node, trophy_info: Dictionary, on_done: Callable = Callable()) -> CanvasLayer:
	var layer := EscCanvasLayer.new()
	layer.layer = 22
	parent.add_child(layer)

	var cel := ChampionshipCelebrationView.new()
	cel.trophy_info = trophy_info
	cel.on_done_cb = func():
		layer.queue_free()
		if on_done.is_valid():
			on_done.call()
	layer.add_child(cel)
	cel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	AudioSynth.play_achievement()
	AudioSynth.play_level_up()
	return layer

# ==============================================================================
# INNER WIDGETS
# ==============================================================================
class EscCanvasLayer extends CanvasLayer:
	func _unhandled_input(event: InputEvent) -> void:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_ESCAPE:
				AudioSynth.play_click()
				get_viewport().set_input_as_handled()
				queue_free()

class HexOvrBadgeControl extends Control:
	var ovr_val: int = 65
	var tier_color: Color = Color("#B47B48")

	func _draw() -> void:
		var cx: float = size.x * 0.5
		var cy: float = size.y * 0.5
		var rad: float = minf(size.x, size.y) * 0.46
		var pts := PackedVector2Array()
		for i in range(6):
			var ang: float = -PI * 0.5 + float(i) * PI / 3.0
			pts.append(Vector2(cx + cos(ang) * rad, cy + sin(ang) * rad))
		draw_colored_polygon(pts, Color("#141C2B"))
		var closed := pts.duplicate()
		closed.append(pts[0])
		draw_polyline(closed, tier_color, 2.0, true)
		var f: Font = UITheme.get_display_font()
		var txt: String = str(ovr_val)
		var fsz: int = clampi(int(size.y * 0.44), 9, 14)
		var tsz: Vector2 = f.get_string_size(txt, HORIZONTAL_ALIGNMENT_CENTER, -1, fsz)
		draw_string(f, Vector2(cx - tsz.x * 0.5, cy + tsz.y * 0.30), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, tier_color.lightened(0.2))

class CallupGaugeControl extends Control:
	var level_you: float = 65.9
	var level_req: int = 53

	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		if w < 20.0 or h < 40.0:
			return
		var bar_x: float = 18.0
		var bar_w: float = 10.0
		var top_y: float = 18.0
		var bot_y: float = h - 18.0
		var span: float = maxf(20.0, bot_y - top_y)

		var min_v: float = minf(float(level_req) - 10.0, level_you - 10.0)
		var max_v: float = maxf(float(level_req) + 14.0, level_you + 8.0)
		var rng_v: float = maxf(10.0, max_v - min_v)

		var y_you: float = bot_y - clampf((level_you - min_v) / rng_v, 0.08, 0.92) * span
		var y_req: float = bot_y - clampf((float(level_req) - min_v) / rng_v, 0.08, 0.92) * span
		# Prevent label overlap when values are very close
		if absf(y_you - y_req) < 24.0:
			if level_you >= float(level_req):
				y_you = maxf(top_y + 8.0, y_req - 26.0)
			else:
				y_you = minf(bot_y - 8.0, y_req + 26.0)

		# Track background
		draw_rect(Rect2(bar_x, top_y, bar_w, span), Color("#17253B"))
		# Gold fill from bottom up to y_you
		var fill_col: Color = Color("#D9A826") if level_you >= float(level_req) else Color("#E06C3A")
		draw_rect(Rect2(bar_x, y_you, bar_w, bot_y - y_you), fill_col)

		var f_ui: Font = UITheme.get_ui_font()
		var f_disp: Font = UITheme.get_display_font()

		# KAU tick & value (Gold)
		draw_line(Vector2(bar_x - 6.0, y_you), Vector2(bar_x + bar_w + 10.0, y_you), Color("#F5C430"), 2.0)
		draw_string(f_ui, Vector2(bar_x + bar_w + 16.0, y_you + 4.0), "KAU", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#F5C430"))
		var you_str: String = ("%.1f" % level_you).replace(".", ",")
		var you_sz: Vector2 = f_disp.get_string_size(you_str, HORIZONTAL_ALIGNMENT_RIGHT, -1, 15)
		draw_string(f_disp, Vector2(w - 14.0 - you_sz.x, y_you + 5.0), you_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#F5C430"))

		# UNTUK MASUK tick & value (White)
		draw_line(Vector2(bar_x - 6.0, y_req), Vector2(bar_x + bar_w + 10.0, y_req), Color("#E2E8F0"), 2.0)
		draw_string(f_ui, Vector2(bar_x + bar_w + 16.0, y_req + 4.0), "UNTUK MASUK", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#CBD5E1"))
		var req_str: String = str(level_req)
		var req_sz: Vector2 = f_disp.get_string_size(req_str, HORIZONTAL_ALIGNMENT_RIGHT, -1, 14)
		draw_string(f_disp, Vector2(w - 14.0 - req_sz.x, y_req + 5.0), req_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#EDF4FC"))

class KnockoutBracketControl extends Control:
	var ko_data: Dictionary = {}
	var user_code: String = ""
	var compact_mode: bool = true

	func _draw() -> void:
		var rounds: Array = ko_data.get("rounds", [])
		if rounds.is_empty():
			return
		var w: float = size.x
		var h: float = size.y
		if w < 60.0 or h < 60.0:
			return

		var f_ui: Font = UITheme.get_ui_font()
		var f_disp: Font = UITheme.get_display_font()
		var n_rounds: int = rounds.size()
		var header_h: float = 20.0
		var usable_h: float = maxf(40.0, h - header_h - 8.0)

		# In compact mode (TIMNAS right panel), focus on user's quadrant (max 4 matches in first round) so every node & line is sharp!
		var slice_counts: Array[int] = []
		var slice_offsets: Array[int] = []
		var user_r0_idx: int = 0
		if compact_mode and n_rounds > 0:
			var r0_matches: Array = rounds[0].get("matches", [])
			for mi in range(r0_matches.size()):
				if bool(r0_matches[mi].get("is_user_match", false)):
					user_r0_idx = mi
					break
		var cur_m_idx: int = user_r0_idx
		for ri in range(n_rounds):
			var total_m: int = rounds[ri].get("matches", []).size()
			if compact_mode and total_m > 4:
				var quad_start: int = int(cur_m_idx / 4) * 4
				quad_start = clampi(quad_start, 0, maxi(0, total_m - 4))
				slice_offsets.append(quad_start)
				slice_counts.append(mini(4, total_m - quad_start))
			elif compact_mode and ri == 1 and rounds[0].get("matches", []).size() > 4:
				var semi_start: int = int(cur_m_idx / 2) * 2
				semi_start = clampi(semi_start, 0, maxi(0, total_m - 2))
				slice_offsets.append(semi_start)
				slice_counts.append(mini(2, total_m - semi_start))
			elif compact_mode and ri == 2 and rounds[0].get("matches", []).size() > 4:
				slice_offsets.append(clampi(cur_m_idx, 0, maxi(0, total_m - 1)))
				slice_counts.append(1)
			else:
				slice_offsets.append(0)
				slice_counts.append(total_m)
			cur_m_idx = int(cur_m_idx / 2)

		var col_w: float = w / float(n_rounds)
		var box_w: float = clampf(col_w * 0.78, 52.0, 148.0)
		var box_h: float = clampf(usable_h / float(maxi(1, slice_counts[0])) * 0.72, 26.0, 42.0)

		# Precompute node positions for each visible match
		var centers: Array = []
		for ri in range(n_rounds):
			var cnt: int = slice_counts[ri]
			var col_x: float = col_w * float(ri) + (col_w - box_w) * 0.5
			var r_name: String = str(rounds[ri].get("name", ""))
			var h_txt: String = r_name.replace("SEMI FINAL", "SEMI").replace("16 BESAR", "16B").replace("8 BESAR", "8B") if compact_mode else r_name
			draw_string(f_disp, Vector2(col_x, 13.0), h_txt, HORIZONTAL_ALIGNMENT_LEFT, int(box_w + 16.0), 9 if compact_mode else 10, Color("#94A3B8"))

			var r_centers: Array[Vector2] = []
			for local_i in range(cnt):
				var cy: float = header_h + usable_h * (float(local_i) + 0.5) / float(maxi(1, cnt))
				r_centers.append(Vector2(col_x + box_w * 0.5, cy))
			centers.append(r_centers)

		# 1. Draw orthogonal bracket connector lines FIRST (bright glowing white if passed, faded white if failed!)
		for ri in range(n_rounds - 1):
			var cnt: int = slice_counts[ri]
			var off: int = slice_offsets[ri]
			var next_cnt: int = slice_counts[ri + 1]
			var matches: Array = rounds[ri].get("matches", [])
			for local_i in range(cnt):
				var global_i: int = off + local_i
				if global_i >= matches.size():
					continue
				var m: Dictionary = matches[global_i]
				var p1: Vector2 = centers[ri][local_i]
				var target_local: int = clampi(int(local_i / 2), 0, maxi(0, next_cnt - 1))
				var p2: Vector2 = centers[ri + 1][target_local]
				var x_start: float = p1.x + box_w * 0.5
				var x_end: float = p2.x - box_w * 0.5
				var x_mid: float = (x_start + x_end) * 0.5

				var played: bool = bool(m.get("played", false))
				var is_user_m: bool = bool(m.get("is_user_match", false))
				var u_passed: bool = bool(m.get("user_passed", false))
				var u_failed: bool = bool(m.get("user_failed", false))

				var segs := PackedVector2Array([
					Vector2(x_start, p1.y),
					Vector2(x_mid, p1.y),
					Vector2(x_mid, p2.y),
					Vector2(x_end, p2.y),
				])

				if u_failed:
					# Eliminated path: faded dim white!
					draw_polyline(segs, Color(1.0, 1.0, 1.0, 0.16), 1.3, true)
				elif u_passed or (played and not is_user_m and str(m.get("winner_code", "")) != ""):
					if u_passed:
						# Qualified user path: bright glowing white!
						draw_polyline(segs, Color(1.0, 1.0, 1.0, 0.24), 6.0, true)
						draw_polyline(segs, Color(1.0, 1.0, 1.0, 0.52), 3.2, true)
						draw_polyline(segs, Color("#FFFFFF"), 1.9, true)
					else:
						# Other completed match advancing winner
						draw_polyline(segs, Color(1.0, 1.0, 1.0, 0.20), 3.4, true)
						draw_polyline(segs, Color(1.0, 1.0, 1.0, 0.72), 1.5, true)
				else:
					# Unplayed upcoming connector
					draw_polyline(segs, Color(1.0, 1.0, 1.0, 0.34), 1.4, true)

		# 2. Draw match boxes
		for ri in range(n_rounds):
			var cnt: int = slice_counts[ri]
			var off: int = slice_offsets[ri]
			var matches: Array = rounds[ri].get("matches", [])
			for local_i in range(cnt):
				var global_i: int = off + local_i
				if global_i >= matches.size():
					continue
				var m: Dictionary = matches[global_i]
				var ctr: Vector2 = centers[ri][local_i]
				var rect := Rect2(ctr.x - box_w * 0.5, ctr.y - box_h * 0.5, box_w, box_h)
				var is_um: bool = bool(m.get("is_user_match", false))
				var u_pass: bool = bool(m.get("user_passed", false))
				var u_fail: bool = bool(m.get("user_failed", false))
				var played: bool = bool(m.get("played", false))
				var win_c: String = str(m.get("winner_code", "")).to_upper()

				var bg_c: Color = Color("#12233B") if is_um else Color("#0B1626")
				var bd_c: Color = Color("#FFFFFF") if u_pass else (Color(1.0, 1.0, 1.0, 0.20) if u_fail else (GOLD_ACCENT if is_um else Color("#233754")))
				if u_pass:
					draw_rect(rect.grow(1.5), Color(1.0, 1.0, 1.0, 0.22), false, 2.5)
				draw_rect(rect, bg_c)
				draw_rect(rect, bd_c, false, 1.4 if (u_pass or is_um) else 1.0)
				draw_line(Vector2(rect.position.x + 2.0, ctr.y), Vector2(rect.end.x - 2.0, ctr.y), Color(1, 1, 1, 0.12), 1.0)

				var half_h: float = box_h * 0.5
				for side in range(2):
					var s_code: String = str(m["a_code"] if side == 0 else m["b_code"]).to_upper()
					var s_cols: Array = m.get("a_colors" if side == 0 else "b_colors", [Color("#3B82F6"), Color("#FFFFFF")])
					var s_sc: int = int(m["score_a"] if side == 0 else m["score_b"])
					var is_u_team: bool = (user_code != "" and s_code == user_code)
					var lost_side: bool = played and win_c != "" and s_code != win_c
					var y_top: float = rect.position.y + (0.0 if side == 0 else half_h)

					# Mini 2-color flag swatch
					var fc1: Color = UITheme.parse_color(s_cols[0], Color("#475569")) if s_cols.size() > 0 else Color("#475569")
					var fc2: Color = UITheme.parse_color(s_cols[1], Color("#F8FAFC")) if s_cols.size() > 1 else Color("#F8FAFC")
					var fa: float = 0.35 if lost_side else 1.0
					draw_rect(Rect2(rect.position.x + 4.0, y_top + half_h * 0.25, 10.0, half_h * 0.25), Color(fc1.r, fc1.g, fc1.b, fa))
					draw_rect(Rect2(rect.position.x + 4.0, y_top + half_h * 0.50, 10.0, half_h * 0.25), Color(fc2.r, fc2.g, fc2.b, fa))

					var t_col: Color = Color(0.75, 0.80, 0.88, 0.34) if lost_side else (GOLD_BRIGHT if is_u_team else Color("#F1F5F9"))
					var fsz: int = 9 if compact_mode else 10
					draw_string(f_disp, Vector2(rect.position.x + 17.0, y_top + half_h * 0.72), s_code.left(3), HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, t_col)
					if played and s_sc >= 0:
						draw_string(f_ui, Vector2(rect.end.x - 13.0, y_top + half_h * 0.72), str(s_sc), HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, Color("#FFFFFF") if not lost_side else Color(1, 1, 1, 0.32))

class ChampionshipCelebrationView extends Control:
	var trophy_info: Dictionary = {}
	var on_done_cb: Callable = Callable()
	var _t: float = 0.0
	var _confetti: Array[Dictionary] = []

	func _ready() -> void:
		theme = UITheme.build_theme()
		var rng := RandomNumberGenerator.new()
		rng.seed = 20261122
		var palette := [Color("#FACC15"), Color("#F59E0B"), Color("#FFFFFF"), Color("#38BDF8"), Color("#EF4444"), Color("#22C55E")]
		for i in range(90):
			_confetti.append({
				"x": rng.randf_range(0.0, 960.0),
				"y": rng.randf_range(-540.0, 540.0),
				"vy": rng.randf_range(65.0, 165.0),
				"vx": rng.randf_range(-28.0, 28.0),
				"sz": rng.randf_range(4.0, 8.0),
				"col": palette[i % palette.size()],
				"phase": rng.randf_range(0.0, TAU),
			})

		var margin := MarginContainer.new()
		margin.set_anchors_preset(Control.PRESET_FULL_RECT)
		margin.add_theme_constant_override("margin_left", 40)
		margin.add_theme_constant_override("margin_right", 40)
		margin.add_theme_constant_override("margin_top", 26)
		margin.add_theme_constant_override("margin_bottom", 24)
		add_child(margin)

		var vb := VBoxContainer.new()
		vb.alignment = BoxContainer.ALIGNMENT_CENTER
		vb.add_theme_constant_override("separation", 10)
		margin.add_child(vb)

		var badge_l := Label.new()
		badge_l.text = "★  SANG JUARA INTERNASIONAL  ★"
		badge_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge_l.add_theme_font_override("font", UITheme.get_display_font())
		badge_l.add_theme_font_size_override("font_size", 14)
		badge_l.add_theme_color_override("font_color", Color("#FACC15"))
		vb.add_child(badge_l)

		var title_l := Label.new()
		title_l.text = "JUARA %s!" % str(trophy_info.get("title", "PIALA ASIA AFC")).to_upper()
		title_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_l.add_theme_font_override("font", UITheme.get_display_font())
		title_l.add_theme_font_size_override("font_size", 24)
		title_l.add_theme_color_override("font_color", Color("#FFFFFF"))
		vb.add_child(title_l)

		var sub_hb := HBoxContainer.new()
		sub_hb.alignment = BoxContainer.ALIGNMENT_CENTER
		sub_hb.add_theme_constant_override("separation", 10)
		vb.add_child(sub_hb)
		var fw := CenterContainer.new()
		fw.add_child(UITheme.make_flag_by_code(str(trophy_info.get("nation_code", "IDN")), [], Vector2(30, 20)))
		sub_hb.add_child(fw)
		var sc_l := Label.new()
		sc_l.text = "%s  %d - %d  %s" % [
			str(trophy_info.get("nation_name", "TIMNAS")),
			int(trophy_info.get("score_us", 2)),
			int(trophy_info.get("score_them", 1)),
			str(trophy_info.get("opp_name", "FINALIS")),
		]
		sc_l.add_theme_font_override("font", UITheme.get_display_font())
		sc_l.add_theme_font_size_override("font_size", 15)
		sc_l.add_theme_color_override("font_color", Color("#38BDF8"))
		sub_hb.add_child(sc_l)

		# Center stage spacer where _draw paints the animated golden trophy & rays + PixelAvatar
		var stage_sp := CenterContainer.new()
		stage_sp.custom_minimum_size = Vector2(0, 220)
		stage_sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
		vb.add_child(stage_sp)

		if CareerState.has_active_career:
			var av := PixelAvatar.new()
			av.custom_minimum_size = Vector2(110, 140)
			var prof: Dictionary = CareerState.career["playerProfile"]
			var nid: int = int(trophy_info.get("nation_id", int(prof.get("nationId", 16))))
			var nat_cols: Array = GameData.nations[clampi(nid, 0, GameData.nations.size() - 1)].get("colors", [Color("#CE1126"), Color("#FFFFFF")])
			av.configure_from_career()
			av.apply_kit({"primary": nat_cols[0], "secondary": nat_cols[1] if nat_cols.size() > 1 else Color.WHITE, "pattern": "solid"})
			av.anim_mode = "CHEER"
			av.show_mvp_trophy = true
			stage_sp.add_child(av)

		var bonus_l := Label.new()
		bonus_l.text = "+60 POIN WARISAN  •  +25.000 PENGIKUT  •  TROFI TERSIMPAN DI LEMARI"
		bonus_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bonus_l.add_theme_font_size_override("font_size", 12)
		bonus_l.add_theme_color_override("font_color", Color("#FACC15"))
		vb.add_child(bonus_l)

		var note_l := Label.new()
		note_l.text = "(Event perayaan lanjutan pasca-juara akan hadir pada pembaruan berikutnya)"
		note_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		note_l.add_theme_font_size_override("font_size", 11)
		note_l.add_theme_color_override("font_color", Color("#94A3B8"))
		vb.add_child(note_l)

		var btn_c := CenterContainer.new()
		vb.add_child(btn_c)
		var cont_b := Button.new()
		cont_b.text = "ANGKAT TROFI & LANJUTKAN"
		cont_b.custom_minimum_size = Vector2(280, 44)
		UITheme.style_btn(cont_b, Color("#B47A12"), Color("#FACC15"), 13)
		cont_b.pressed.connect(func():
			AudioSynth.play_click()
			if on_done_cb.is_valid():
				on_done_cb.call()
		)
		btn_c.add_child(cont_b)

	func _process(delta: float) -> void:
		_t += delta
		for c in _confetti:
			c["y"] = float(c["y"]) + float(c["vy"]) * delta
			c["x"] = float(c["x"]) + (float(c["vx"]) + sin(_t * 3.0 + float(c["phase"])) * 18.0) * delta
			if float(c["y"]) > size.y + 12.0:
				c["y"] = -10.0
		queue_redraw()

	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		draw_rect(Rect2(0, 0, w, h), Color("#050B16"))

		# Rotating golden spotlight beams behind trophy/player
		var cx: float = w * 0.5
		var cy: float = h * 0.50
		for i in range(10):
			var a0: float = _t * 0.45 + float(i) * TAU / 10.0
			var a1: float = a0 + 0.18
			var pts := PackedVector2Array([
				Vector2(cx, cy),
				Vector2(cx + cos(a0) * 620.0, cy + sin(a0) * 620.0),
				Vector2(cx + cos(a1) * 620.0, cy + sin(a1) * 620.0),
			])
			draw_colored_polygon(pts, Color(0.98, 0.80, 0.15, 0.08))

		# Glowing Pixel-Art Championship Trophy rising beside avatar
		var bob: float = sin(_t * 3.2) * 6.0
		var tx: float = cx + 115.0
		var ty: float = cy + bob
		draw_circle(Vector2(tx, ty), 56.0 + sin(_t * 4.0) * 5.0, Color(0.98, 0.80, 0.15, 0.14))
		# Cup bowl
		var bowl := PackedVector2Array([
			Vector2(tx - 26, ty - 34), Vector2(tx + 26, ty - 34),
			Vector2(tx + 18, ty + 6), Vector2(tx - 18, ty + 6),
		])
		draw_colored_polygon(bowl, Color("#F5C430"))
		draw_rect(Rect2(tx - 18, ty - 30, 8, 28), Color("#FEF08A"))
		# Handles
		draw_arc(Vector2(tx - 24, ty - 16), 12.0, PI * 0.5, PI * 1.5, 10, Color("#EAB308"), 4.0)
		draw_arc(Vector2(tx + 24, ty - 16), 12.0, -PI * 0.5, PI * 0.5, 10, Color("#EAB308"), 4.0)
		# Stem & pedestal
		draw_rect(Rect2(tx - 6, ty + 6, 12, 18), Color("#D97706"))
		draw_rect(Rect2(tx - 20, ty + 24, 40, 10), Color("#F5C430"))
		draw_rect(Rect2(tx - 24, ty + 34, 48, 12), Color("#78350F"))

		# Fireworks starbursts
		for fw_i in range(3):
			var fx: float = w * (0.20 + float(fw_i) * 0.30)
			var fy: float = h * (0.22 + float(fw_i % 2) * 0.14)
			var p: float = fmod(_t * 0.9 + float(fw_i) * 0.37, 1.0)
			var frad: float = p * 68.0
			var falpha: float = maxf(0.0, 1.0 - p) * 0.7
			for sp in range(12):
				var ang: float = float(sp) * TAU / 12.0
				draw_circle(Vector2(fx + cos(ang) * frad, fy + sin(ang) * frad), 2.5, Color(1.0, 0.88, 0.35, falpha))

		# Falling confetti
		for c in _confetti:
			var col: Color = c["col"]
			var sz: float = float(c["sz"])
			draw_rect(Rect2(float(c["x"]), float(c["y"]), sz, sz * 0.65), col)
