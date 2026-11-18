extends Control

func show_player(player_dict: Dictionary, club_dict: Dictionary) -> void:
	theme = UITheme.build_theme()
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.04, 0.08, 0.85)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -310
	panel.offset_right = 310
	panel.offset_top = -220
	panel.offset_bottom = 220
	panel.add_theme_stylebox_override("panel", UITheme.make_box(Color("#0A182D"), UITheme.BORDER_CYAN, 2, 4))
	add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	panel.add_child(vb)

	# Top Card + Bio (matching Screenshot #48)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	vb.add_child(top)

	var card_box := PanelContainer.new()
	card_box.custom_minimum_size = Vector2(105, 130)
	card_box.add_theme_stylebox_override("panel", UITheme.make_box(Color("#122640"), UITheme.ACCENT_GOLD, 2, 4))
	top.add_child(card_box)
	var av := PixelAvatar.new()
	av.custom_minimum_size = Vector2(90, 108)
	if player_dict.get("is_user", false):
		av.configure_from_career()
	else:
		av.configure_from_seed(int(player_dict.get("seed", 1)), club_dict, int(player_dict.get("number", 9)))
	card_box.add_child(av)

	var bio := VBoxContainer.new()
	bio.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(bio)
	var nm := Label.new()
	nm.text = "%s (%s • OVR %d)" % [player_dict["name"], player_dict["pos"], int(player_dict["ovr"])]
	nm.add_theme_font_override("font", UITheme.get_display_font())
	nm.add_theme_font_size_override("font_size", 16)
	bio.add_child(nm)
	var role_l := Label.new()
	role_l.text = "INTI" if int(player_dict.get("ovr", 60)) >= 55 else "CADANGAN"
	role_l.add_theme_color_override("font_color", UITheme.ACCENT_CYAN)
	bio.add_child(role_l)
	for r in [
		["USIA", str(player_dict.get("age", 20))],
		["KONTRAK", "%d THN" % int(player_dict.get("contract", 2))],
		["NILAI", UITheme.format_cash(int(player_dict.get("value", 500000)))],
	]:
		var rhb := HBoxContainer.new()
		bio.add_child(rhb)
		var rl := Label.new()
		rl.text = r[0]
		rl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rl.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
		var rv := Label.new()
		rv.text = r[1]
		rv.add_theme_color_override("font_color", UITheme.ACCENT_GOLD if r[0] == "NILAI" else UITheme.TEXT_WHITE)
		rhb.add_child(rl)
		rhb.add_child(rv)

	# Quick stats
	var stat_hb := HBoxContainer.new()
	stat_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	stat_hb.add_theme_constant_override("separation", 24)
	vb.add_child(stat_hb)
	for st_t in [
		"LAGA %d" % int(player_dict.get("matches", 0)),
		"★ %.1f" % float(player_dict.get("rating", 6.0)),
		"GOL %d" % int(player_dict.get("goals", 0)),
		"AST %d" % int(player_dict.get("assists", 0)),
	]:
		var l := Label.new()
		l.text = st_t
		stat_hb.add_child(l)

	# 10 Attributes Grid
	var attrs: Dictionary = player_dict.get("attrs", {})
	if player_dict.get("is_user", false) and CareerState.has_active_career:
		attrs = CareerState.career["playerProfile"]["attributes"]
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 4)
	vb.add_child(grid)
	for ak in GameData.ATTRIBUTE_KEYS:
		var ahb := HBoxContainer.new()
		ahb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(ahb)
		var al := Label.new()
		al.text = GameData.ATTRIBUTE_LABELS[ak]
		al.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var av_l := Label.new()
		av_l.text = str(int(attrs.get(ak, 60)))
		av_l.add_theme_color_override("font_color", UITheme.ACCENT_CYAN)
		ahb.add_child(al)
		ahb.add_child(av_l)

	vb.add_child(UITheme.make_section_header("RIWAYAT"))
	var hist := Label.new()
	hist.text = "SEJAK M1  •  %s" % club_dict["name"]
	hist.add_theme_color_override("font_color", UITheme.ACCENT_CYAN)
	vb.add_child(hist)

	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(sp)

	var close_b := Button.new()
	close_b.text = "TUTUP"
	close_b.custom_minimum_size = Vector2(0, 42)
	UITheme.style_btn(close_b, Color("#0C192C"), UITheme.BORDER_CYAN)
	close_b.pressed.connect(func(): AudioSynth.play_click(); queue_free())
	vb.add_child(close_b)
