extends Control

signal back_to_home
signal start_match_requested
signal open_dilemma_requested
signal open_settings_requested
signal open_friends_requested
signal open_cosmetics_shop_requested
signal open_practice_requested
signal inspect_player_requested(player_dict: Dictionary, club_dict: Dictionary)
signal replay_clip_requested(clip: Dictionary)
signal open_city_requested(landmark: String, inside_apt: bool)
signal open_cutscene_requested(mode_idx: int)
signal open_volley_requested

var _active_tab: String = "KINI"
var _ovr_label: Label
var _name_label: Label
var _sub_label: Label
var _cash_label: Label
var _energy_lbl: Label
var _energy_segs: Array[ColorRect] = []
var _cal_label: Label
var _pos_label: Label
var _energy_modal: Control
var _energy_modal_lbl: Label
var _tab_content: Control
var _nav_btns: Dictionary = {}

var _kini_tab: Control
var _pemainku_tab: Control
var _timku_tab: Control
var _dunia_tab: Control
var _warisan_tab: Control

func _ready() -> void:
	theme = UITheme.build_theme()
	_build_shell()
	CareerState.career_updated.connect(refresh_hud)
	refresh_hud()

func _build_shell() -> void:
	var bg := ColorRect.new()
	bg.color = UITheme.BG_DARK
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root_vb := VBoxContainer.new()
	root_vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_vb.add_theme_constant_override("separation", 4)
	add_child(root_vb)

	# 1. PERSISTENT TOP HUD
	var hud_panel := PanelContainer.new()
	hud_panel.add_theme_stylebox_override("panel", UITheme.make_box(Color("#091628"), UITheme.BORDER_STEEL, 1, 0))
	root_vb.add_child(hud_panel)

	var hud_vb := VBoxContainer.new()
	hud_vb.add_theme_constant_override("separation", 3)
	hud_panel.add_child(hud_vb)

	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 8)
	hud_vb.add_child(row1)

	var ovr_box := PanelContainer.new()
	ovr_box.custom_minimum_size = Vector2(40, 38)
	ovr_box.add_theme_stylebox_override("panel", UITheme.make_box(Color("#122640"), Color("#A67C52"), 2, 4))
	row1.add_child(ovr_box)
	_ovr_label = Label.new()
	_ovr_label.text = "60"
	_ovr_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ovr_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_ovr_label.add_theme_font_override("font", UITheme.get_display_font())
	_ovr_label.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	_ovr_label.add_theme_font_size_override("font_size", 16)
	ovr_box.add_child(_ovr_label)

	var id_vb := VBoxContainer.new()
	id_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row1.add_child(id_vb)
	_name_label = Label.new()
	_name_label.text = "ALFIAN"
	_name_label.add_theme_font_override("font", UITheme.get_display_font())
	_name_label.add_theme_font_size_override("font_size", 16)
	_sub_label = Label.new()
	_sub_label.text = "16 THN • LEVEL 1"
	_sub_label.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	_sub_label.add_theme_font_size_override("font_size", 10)
	id_vb.add_child(_name_label)
	id_vb.add_child(_sub_label)

	var cal_vb := VBoxContainer.new()
	cal_vb.alignment = BoxContainer.ALIGNMENT_CENTER
	row1.add_child(cal_vb)
	_cal_label = Label.new()
	_cal_label.text = "THN 1 • MGG 1/45"
	_cal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_cal_label.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	_cal_label.add_theme_font_size_override("font_size", 11)
	_pos_label = Label.new()
	_pos_label.text = "LIGA 1/32"
	_pos_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_pos_label.add_theme_color_override("font_color", UITheme.ACCENT_CYAN)
	_pos_label.add_theme_font_size_override("font_size", 11)
	cal_vb.add_child(_cal_label)
	cal_vb.add_child(_pos_label)

	_cash_label = Label.new()
	_cash_label.text = "$ 5.000"
	_cash_label.add_theme_font_override("font", UITheme.get_display_font())
	_cash_label.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	row1.add_child(_cash_label)

	var set_b := Button.new()
	set_b.text = "⚙"
	set_b.custom_minimum_size = Vector2(32, 32)
	set_b.pressed.connect(func(): AudioSynth.play_click(); open_settings_requested.emit())
	row1.add_child(set_b)

	var home_b := Button.new()
	home_b.text = "☰"
	home_b.custom_minimum_size = Vector2(32, 32)
	home_b.pressed.connect(func(): AudioSynth.play_click(); back_to_home.emit())
	row1.add_child(home_b)

	# Row 2: 20-segment Energy Bar + Status
	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 6)
	hud_vb.add_child(row2)
	var e_tag := Label.new()
	e_tag.text = "⚡"
	e_tag.add_theme_color_override("font_color", UITheme.ACCENT_GREEN)
	row2.add_child(e_tag)

	var seg_hb := HBoxContainer.new()
	seg_hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	seg_hb.add_theme_constant_override("separation", 2)
	row2.add_child(seg_hb)
	for _i in range(20):
		var r := ColorRect.new()
		r.custom_minimum_size = Vector2(10, 10)
		r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.color = UITheme.ACCENT_GREEN
		seg_hb.add_child(r)
		_energy_segs.append(r)

	_energy_lbl = Label.new()
	_energy_lbl.text = "100 SEGAR"
	_energy_lbl.add_theme_color_override("font_color", UITheme.ACCENT_GREEN)
	_energy_lbl.add_theme_font_size_override("font_size", 11)
	row2.add_child(_energy_lbl)

	var e_info_b := Button.new()
	e_info_b.text = "?"
	e_info_b.custom_minimum_size = Vector2(22, 18)
	UITheme.style_btn(e_info_b, Color("#11263F"), UITheme.ACCENT_CYAN, 10)
	e_info_b.pressed.connect(func(): AudioSynth.play_click(); _show_energy_modal())
	row2.add_child(e_info_b)

	# 2. MAIN TAB CONTENT AREA
	_tab_content = Control.new()
	_tab_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vb.add_child(_tab_content)

	var KiniScript := load("res://scenes/tabs/KiniTab.gd")
	_kini_tab = KiniScript.new()
	_kini_tab.start_match_requested.connect(func(): start_match_requested.emit())
	_kini_tab.open_dilemma_requested.connect(func(): open_dilemma_requested.emit())
	_kini_tab.open_squad_requested.connect(func(): open_cutscene_requested.emit(1))

	var PemainkuScript := load("res://scenes/tabs/PemainkuTab.gd")
	_pemainku_tab = PemainkuScript.new()
	_pemainku_tab.open_cosmetics_shop.connect(func(): open_cosmetics_shop_requested.emit())
	_pemainku_tab.open_friends_modal.connect(func(): open_friends_requested.emit())
	_pemainku_tab.open_practice_match.connect(func(): open_practice_requested.emit())
	_pemainku_tab.open_city_requested.connect(func(lm: String, in_apt: bool): open_city_requested.emit(lm, in_apt))
	_pemainku_tab.open_cutscene_requested.connect(func(m_idx: int): open_cutscene_requested.emit(m_idx))
	_pemainku_tab.open_volley_requested.connect(func(): open_volley_requested.emit())

	var TimkuScript := load("res://scenes/tabs/TimkuTab.gd")
	_timku_tab = TimkuScript.new()
	_timku_tab.inspect_player_requested.connect(func(p: Dictionary, c: Dictionary): inspect_player_requested.emit(p, c))

	var DuniaScript := load("res://scenes/tabs/DuniaTab.gd")
	_dunia_tab = DuniaScript.new()

	var WarisanScript := load("res://scenes/tabs/WarisanTab.gd")
	_warisan_tab = WarisanScript.new()
	_warisan_tab.replay_shot_requested.connect(func(clip: Dictionary): replay_clip_requested.emit(clip))

	for tab_ctrl in [_kini_tab, _pemainku_tab, _timku_tab, _dunia_tab, _warisan_tab]:
		tab_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
		tab_ctrl.offset_left = 8
		tab_ctrl.offset_right = -8
		_tab_content.add_child(tab_ctrl)

	# 3. BOTTOM NAVIGATION BAR (5 MAIN TABS)
	var nav_panel := PanelContainer.new()
	nav_panel.custom_minimum_size = Vector2(0, 44)
	nav_panel.add_theme_stylebox_override("panel", UITheme.make_box(Color("#081220"), UITheme.BORDER_STEEL, 1, 0))
	root_vb.add_child(nav_panel)

	var nav_hb := HBoxContainer.new()
	nav_hb.add_theme_constant_override("separation", 3)
	nav_panel.add_child(nav_hb)

	for t_name in ["KINI", "PEMAINKU", "TIMKU", "DUNIA", "WARISAN"]:
		var btn := Button.new()
		btn.text = t_name
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(func(): AudioSynth.play_click(); switch_tab(t_name))
		nav_hb.add_child(btn)
		_nav_btns[t_name] = btn

	_build_energy_modal()
	switch_tab("KINI")

func _build_energy_modal() -> void:
	_energy_modal = Control.new()
	_energy_modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	_energy_modal.visible = false
	add_child(_energy_modal)

	var dim := ColorRect.new()
	dim.color = Color(0.01, 0.03, 0.06, 0.80)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_energy_modal.add_child(dim)

	var card := PanelContainer.new()
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.custom_minimum_size = Vector2(500, 260)
	card.offset_left = -250
	card.offset_right = 250
	card.offset_top = -130
	card.offset_bottom = 130
	card.add_theme_stylebox_override("panel", UITheme.make_box(Color("#0E1D33"), UITheme.ACCENT_GOLD, 2, 12))
	_energy_modal.add_child(card)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	card.add_child(vb)

	var ttl := Label.new()
	ttl.text = "ENERGI"
	ttl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ttl.add_theme_font_override("font", UITheme.get_display_font())
	ttl.add_theme_font_size_override("font_size", 20)
	ttl.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	vb.add_child(ttl)

	_energy_modal_lbl = Label.new()
	_energy_modal_lbl.text = "100 SEGAR • SIAP MAIN"
	_energy_modal_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_energy_modal_lbl.add_theme_color_override("font_color", UITheme.ACCENT_GREEN)
	vb.add_child(_energy_modal_lbl)

	var bar_hb := HBoxContainer.new()
	bar_hb.add_theme_constant_override("separation", 4)
	vb.add_child(bar_hb)
	for zone in [
		["ABSEN\n< 30", UITheme.ACCENT_RED],
		["CADANGAN\n30 - 44", UITheme.ACCENT_GOLD],
		["INTI\n45 - 100", UITheme.ACCENT_GREEN],
	]:
		var z_box := PanelContainer.new()
		z_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var z_col: Color = zone[1]
		z_box.add_theme_stylebox_override("panel", UITheme.make_box(Color(z_col.r * 0.2, z_col.g * 0.2, z_col.b * 0.2, 1.0), z_col, 2, 6))
		bar_hb.add_child(z_box)
		var z_lbl := Label.new()
		z_lbl.text = str(zone[0])
		z_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		z_lbl.add_theme_font_size_override("font_size", 11)
		z_lbl.add_theme_color_override("font_color", z_col)
		z_box.add_child(z_lbl)

	var rules_lbl := Label.new()
	rules_lbl.text = "DI BAWAH 30 KAMU TAK DIPANGGIL KE SKUAD.\nDI BAWAH 45 KAMU MULAI DI BANGKU CADANGAN.\nMINUM ENERGI ATAU ISTIRAHAT UNTUK PULIH."
	rules_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rules_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	rules_lbl.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	rules_lbl.add_theme_font_size_override("font_size", 11)
	vb.add_child(rules_lbl)

	var close_b := Button.new()
	close_b.text = "MENGERTI"
	close_b.custom_minimum_size = Vector2(0, 40)
	UITheme.style_btn(close_b, UITheme.ACCENT_GREEN, Color.WHITE, 14)
	close_b.pressed.connect(func(): AudioSynth.play_click(); _energy_modal.visible = false)
	vb.add_child(close_b)

func _show_energy_modal() -> void:
	if CareerState.has_active_career:
		var eng: int = int(CareerState.career["playerProfile"]["energy"])
		var role_txt: String = CareerState.get_player_role_status()
		var state_txt: String = "SEGAR" if eng >= 60 else ("LELAH" if eng >= 30 else "KRITIS")
		_energy_modal_lbl.text = "%d %s • STATUS: %s" % [eng, state_txt, role_txt]
		var eng_col: Color = UITheme.ACCENT_GREEN if eng >= 45 else (UITheme.ACCENT_GOLD if eng >= 30 else UITheme.ACCENT_RED)
		_energy_modal_lbl.add_theme_color_override("font_color", eng_col)
	_energy_modal.visible = true

func switch_tab(t_name: String) -> void:
	_active_tab = t_name
	_kini_tab.visible = (t_name == "KINI")
	_pemainku_tab.visible = (t_name == "PEMAINKU")
	_timku_tab.visible = (t_name == "TIMKU")
	_dunia_tab.visible = (t_name == "DUNIA")
	_warisan_tab.visible = (t_name == "WARISAN")
	refresh_hud()

func refresh_hud() -> void:
	if not is_inside_tree() or not CareerState.has_active_career:
		return
	var p: Dictionary = CareerState.career["playerProfile"]
	var m: Dictionary = CareerState.career["careerMeta"]

	_ovr_label.text = str(int(p["ovr"]))
	_name_label.text = str(p["name"])
	_sub_label.text = "%d THN • LEVEL %d" % [int(p["age"]), int(p["level"])]
	_cash_label.text = UITheme.format_cash(int(p["cash"]))

	var eng := int(p["energy"])
	var filled := int(round(float(eng) / 5.0))
	var eng_col := UITheme.ACCENT_GREEN if eng >= 60 else (UITheme.ACCENT_GOLD if eng >= 30 else UITheme.ACCENT_RED)
	for i in range(_energy_segs.size()):
		_energy_segs[i].color = eng_col if i < filled else Color("#18283C")
	_energy_lbl.text = "%d %s" % [eng, "SEGAR" if eng >= 60 else ("LELAH" if eng >= 30 else "KRITIS")]
	_energy_lbl.add_theme_color_override("font_color", eng_col)

	_cal_label.text = "THN %d • MGG %d/%d" % [int(m["year"]), int(m["week"]), int(m["maxWeeks"])]
	_pos_label.text = "LIGA %d/%d" % [CareerState.get_user_league_position(), CareerState.career["leagueTable"].size()]

	var sp := int(p["skillPoints"])
	var tw := int(m.get("transferWindowWeeksLeft", 0))
	for k in _nav_btns.keys():
		var b: Button = _nav_btns[k]
		var act: bool = (str(k) == _active_tab)
		var col: Color = UITheme.TAB_COLORS.get(k, UITheme.BORDER_CYAN)
		UITheme.style_btn(b, col if act else Color("#0B1626"), Color.WHITE if act else UITheme.BORDER_STEEL, 11)
		if k == "PEMAINKU" and sp > 0:
			b.text = "PEMAINKU\n%d POIN" % sp
		elif k == "DUNIA" and tw > 0:
			b.text = "DUNIA\nBUKA • %dP" % tw
		else:
			b.text = k
