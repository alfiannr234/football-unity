extends Control

signal back_to_home
signal start_match_requested
signal sim_match_requested
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
signal transfer_flow_requested(offer: Dictionary)
signal end_season_requested

const WarisanOverlaysScript := preload("res://scripts/ui/WarisanOverlays.gd")

var _active_tab: String = "KINI"
var _active_nav_key: String = "KINI"
var _ovr_ring: OvrBorderBar
var _ovr_label: Label
var _name_label: Label
var _cash_label: Label
var _energy_lbl: Label
var _energy_segs: Array[ColorRect] = []
var _fans_lbl: Label
var _fans_stars_lbl: Label

# Top-center competition pill (replaces old Gambar 4 box cleanly)
var _comp_pill: PanelContainer
var _comp_badge_icon: CompEmblemIcon
var _comp_title_lbl: Label
var _comp_flag_host: Control
var _comp_sub_lbl: Label
var _comp_month_lbl: Label

# Top action buttons (MAIN LAGA / Hold-to-End-Season + SIM)
var _play_normal_box: HBoxContainer
var _play_hold_wrap: PanelContainer
var _end_season_fill: ColorRect
var _end_season_btn: Button
var _end_season_holding: bool = false
var _end_season_prog: float = 0.0
var _end_season_triggered: bool = false

# Icon navigation strip & hanging transfer sign beneath BURSA
var _nav_tiles: Dictionary = {}
var _nav_underlines: Dictionary = {}
var _nav_badges: Dictionary = {}
var _bursa_tile: Control
var _tw_hang_host: Control
var _tw_hang_sign: Control

var _energy_modal: Control
var _energy_modal_lbl: Label
var _tab_content: Control
var _tw_overlay: Control

var _kini_tab: Control
var _berita_tab: Control
var _pemainku_tab: Control
var _timku_tab: Control
var _dunia_tab: Control
var _warisan_tab: Control

func _ready() -> void:
	theme = UITheme.build_theme()
	_build_shell()
	CareerState.career_updated.connect(refresh_hud)
	refresh_hud()

func _process(delta: float) -> void:
	if _play_hold_wrap != null and _play_hold_wrap.visible and not _end_season_triggered:
		if _end_season_holding:
			_end_season_prog = clampf(_end_season_prog + delta * 1.05, 0.0, 1.0)
			if _end_season_fill != null:
				_end_season_fill.anchor_right = _end_season_prog
			if _end_season_btn != null:
				_end_season_btn.text = "MENUTUP\n%d%%" % int(_end_season_prog * 100.0)
			if _end_season_prog >= 1.0:
				_end_season_triggered = true
				_end_season_holding = false
				AudioSynth.play_achievement()
				end_season_requested.emit()
		elif _end_season_prog > 0.0:
			_end_season_prog = maxf(0.0, _end_season_prog - delta * 2.4)
			if _end_season_fill != null:
				_end_season_fill.anchor_right = _end_season_prog
			if _end_season_btn != null:
				_end_season_btn.text = "TAHAN\nAKHIRI"
	_sync_bursa_sign_pos()

func _build_shell() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#081222")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root_vb := VBoxContainer.new()
	root_vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_vb.add_theme_constant_override("separation", 0)
	add_child(root_vb)

	# =========================================================================
	# BAND 1: COMPACT SINGLE-ROW TOP HUD (Gambar 2 & 3 style)
	# =========================================================================
	var hud_panel := PanelContainer.new()
	hud_panel.custom_minimum_size = Vector2(0, 44)
	var hud_sb := StyleBoxFlat.new()
	hud_sb.bg_color = Color("#0A162B")
	hud_sb.border_color = Color("#1F3557")
	hud_sb.border_width_bottom = 1
	hud_sb.content_margin_left = 8
	hud_sb.content_margin_right = 8
	hud_sb.content_margin_top = 4
	hud_sb.content_margin_bottom = 4
	hud_panel.add_theme_stylebox_override("panel", hud_sb)
	root_vb.add_child(hud_panel)

	var hud_hb := HBoxContainer.new()
	hud_hb.add_theme_constant_override("separation", 10)
	hud_panel.add_child(hud_hb)

	# 1A. Player OVR Shield + Name (clickable -> PEMAINKU > SKILL)
	var id_btn := Button.new()
	id_btn.flat = true
	id_btn.custom_minimum_size = Vector2(126, 34)
	id_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	id_btn.pressed.connect(func(): AudioSynth.play_click(); _open_nav("ORANG"))
	hud_hb.add_child(id_btn)

	var id_hb := HBoxContainer.new()
	id_hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	id_hb.add_theme_constant_override("separation", 6)
	id_btn.add_child(id_hb)
	id_hb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_ovr_ring = OvrBorderBar.new()
	_ovr_ring.custom_minimum_size = Vector2(34, 34)
	_ovr_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	id_hb.add_child(_ovr_ring)

	var ovr_box := PanelContainer.new()
	ovr_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	ovr_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ovr_box.offset_left = 3
	ovr_box.offset_top = 3
	ovr_box.offset_right = -3
	ovr_box.offset_bottom = -3
	ovr_box.add_theme_stylebox_override("panel", UITheme.make_box(Color("#122640"), Color("#4B6484"), 1, 5))
	_ovr_ring.add_child(ovr_box)

	_ovr_label = Label.new()
	_ovr_label.text = "60"
	_ovr_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ovr_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_ovr_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ovr_label.add_theme_font_override("font", UITheme.get_display_font())
	_ovr_label.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	_ovr_label.add_theme_font_size_override("font_size", 13)
	ovr_box.add_child(_ovr_label)

	_name_label = Label.new()
	_name_label.text = "ALFIAN"
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_name_label.clip_text = true
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_name_label.add_theme_font_override("font", UITheme.get_display_font())
	_name_label.add_theme_font_size_override("font_size", 12)
	id_hb.add_child(_name_label)

	# 1B. Compact Energy Gauge (clickable -> Energy modal)
	var eng_btn := Button.new()
	eng_btn.flat = true
	eng_btn.custom_minimum_size = Vector2(138, 34)
	eng_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	eng_btn.pressed.connect(func(): AudioSynth.play_click(); _show_energy_modal())
	hud_hb.add_child(eng_btn)

	var eng_hb := HBoxContainer.new()
	eng_hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	eng_hb.add_theme_constant_override("separation", 5)
	eng_btn.add_child(eng_hb)
	eng_hb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var e_tag := Label.new()
	e_tag.text = "⚡"
	e_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	e_tag.add_theme_color_override("font_color", UITheme.ACCENT_GREEN)
	e_tag.add_theme_font_size_override("font_size", 14)
	eng_hb.add_child(e_tag)

	var seg_hb := HBoxContainer.new()
	seg_hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	seg_hb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	seg_hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	seg_hb.add_theme_constant_override("separation", 2)
	eng_hb.add_child(seg_hb)
	for _i in range(10):
		var r := ColorRect.new()
		r.custom_minimum_size = Vector2(6, 12)
		r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.color = UITheme.ACCENT_GREEN
		seg_hb.add_child(r)
		_energy_segs.append(r)

	_energy_lbl = Label.new()
	_energy_lbl.text = "90"
	_energy_lbl.custom_minimum_size = Vector2(28, 0)
	_energy_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_energy_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_energy_lbl.add_theme_font_override("font", UITheme.get_display_font())
	_energy_lbl.add_theme_font_size_override("font_size", 15)
	_energy_lbl.add_theme_color_override("font_color", UITheme.ACCENT_GREEN)
	eng_hb.add_child(_energy_lbl)

	# 1C. Center Competition Pill (Flag + Liga ke-X / Divisi / Bulan — fixes Gambar 4!)
	_comp_pill = PanelContainer.new()
	_comp_pill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_comp_pill.custom_minimum_size = Vector2(260, 34)
	_comp_pill.add_theme_stylebox_override("panel", UITheme.make_box(Color("#0E1F3A"), Color("#294770"), 1, 6))
	hud_hb.add_child(_comp_pill)

	var cp_hb := HBoxContainer.new()
	cp_hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cp_hb.add_theme_constant_override("separation", 8)
	_comp_pill.add_child(cp_hb)

	_comp_badge_icon = CompEmblemIcon.new()
	_comp_badge_icon.custom_minimum_size = Vector2(24, 24)
	_comp_badge_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_comp_badge_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cp_hb.add_child(_comp_badge_icon)

	var cp_vb := VBoxContainer.new()
	cp_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cp_vb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cp_vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cp_vb.add_theme_constant_override("separation", 1)
	cp_hb.add_child(cp_vb)

	_comp_title_lbl = Label.new()
	_comp_title_lbl.text = "LIGA • ke-1"
	_comp_title_lbl.clip_text = true
	_comp_title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_comp_title_lbl.add_theme_font_override("font", UITheme.get_display_font())
	_comp_title_lbl.add_theme_font_size_override("font_size", 12)
	_comp_title_lbl.add_theme_color_override("font_color", Color.WHITE)
	cp_vb.add_child(_comp_title_lbl)

	var cp_sub_hb := HBoxContainer.new()
	cp_sub_hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cp_sub_hb.add_theme_constant_override("separation", 5)
	cp_vb.add_child(cp_sub_hb)

	_comp_flag_host = HBoxContainer.new()
	_comp_flag_host.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_comp_flag_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cp_sub_hb.add_child(_comp_flag_host)

	_comp_sub_lbl = Label.new()
	_comp_sub_lbl.text = "KE-3 DIVISI • P 1/21"
	_comp_sub_lbl.clip_text = true
	_comp_sub_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_comp_sub_lbl.add_theme_font_size_override("font_size", 9)
	_comp_sub_lbl.add_theme_color_override("font_color", Color("#93C5FD"))
	cp_sub_hb.add_child(_comp_sub_lbl)

	var m_box := PanelContainer.new()
	m_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var msb := StyleBoxFlat.new()
	msb.bg_color = Color("#091426")
	msb.border_color = Color("#475569")
	msb.set_border_width_all(1)
	msb.set_corner_radius_all(3)
	msb.content_margin_left = 4
	msb.content_margin_right = 4
	msb.content_margin_top = 0
	msb.content_margin_bottom = 0
	m_box.add_theme_stylebox_override("panel", msb)
	cp_sub_hb.add_child(m_box)

	_comp_month_lbl = Label.new()
	_comp_month_lbl.text = "DESEMBER"
	_comp_month_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_comp_month_lbl.add_theme_font_size_override("font_size", 9)
	_comp_month_lbl.add_theme_color_override("font_color", Color("#E2E8F0"))
	m_box.add_child(_comp_month_lbl)

	var cp_hit := Button.new()
	cp_hit.flat = true
	cp_hit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	cp_hit.pressed.connect(func():
		AudioSynth.play_click()
		_dunia_tab.call("set_subtab", "KOMP.")
		switch_tab("DUNIA")
		_set_active_nav("BURSA")
	)
	_comp_pill.add_child(cp_hit)
	cp_hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# 1D. Fans / Fame rating + mini stars (Clickable -> opens KETENARAN popup!)
	var fame_btn := Button.new()
	fame_btn.custom_minimum_size = Vector2(62, 34)
	fame_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fame_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var f_norm := StyleBoxFlat.new()
	f_norm.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	f_norm.set_corner_radius_all(5)
	var f_hov := StyleBoxFlat.new()
	f_hov.bg_color = Color(0.84, 0.30, 0.55, 0.18)
	f_hov.border_color = Color("#E0649E")
	f_hov.set_border_width_all(1)
	f_hov.set_corner_radius_all(5)
	fame_btn.add_theme_stylebox_override("normal", f_norm)
	fame_btn.add_theme_stylebox_override("hover", f_hov)
	fame_btn.add_theme_stylebox_override("pressed", f_hov)
	fame_btn.add_theme_stylebox_override("focus", f_hov)
	fame_btn.pressed.connect(func():
		AudioSynth.play_click()
		open_fame_modal()
	)
	hud_hb.add_child(fame_btn)

	var fame_vb := VBoxContainer.new()
	fame_vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	fame_vb.alignment = BoxContainer.ALIGNMENT_CENTER
	fame_vb.add_theme_constant_override("separation", 0)
	fame_vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fame_btn.add_child(fame_vb)
	_fans_lbl = Label.new()
	_fans_lbl.text = "★ 60"
	_fans_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fans_lbl.add_theme_font_override("font", UITheme.get_display_font())
	_fans_lbl.add_theme_font_size_override("font_size", 13)
	_fans_lbl.add_theme_color_override("font_color", Color.WHITE)
	_fans_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fame_vb.add_child(_fans_lbl)
	_fans_stars_lbl = Label.new()
	_fans_stars_lbl.text = "★★★"
	_fans_stars_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fans_stars_lbl.add_theme_font_size_override("font_size", 8)
	_fans_stars_lbl.add_theme_color_override("font_color", Color("#F472B6"))
	_fans_stars_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fame_vb.add_child(_fans_stars_lbl)

	# 1E. Cash + Quick Shop [+] button
	var cash_hb := HBoxContainer.new()
	cash_hb.add_theme_constant_override("separation", 5)
	hud_hb.add_child(cash_hb)
	_cash_label = Label.new()
	_cash_label.text = "$ 5.000"
	_cash_label.add_theme_font_override("font", UITheme.get_display_font())
	_cash_label.add_theme_font_size_override("font_size", 14)
	_cash_label.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	cash_hb.add_child(_cash_label)

	var plus_b := Button.new()
	plus_b.text = "+"
	plus_b.custom_minimum_size = Vector2(24, 24)
	plus_b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	plus_b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	UITheme.style_btn(plus_b, Color("#D99A1E"), Color("#FEF08A"), 14)
	plus_b.add_theme_color_override("font_color", Color("#1C1404"))
	plus_b.pressed.connect(func(): AudioSynth.play_click(); _open_nav("TOKO"))
	cash_hb.add_child(plus_b)

	# 1F. Settings & Home buttons
	var set_b := Button.new()
	set_b.text = "⚙"
	set_b.custom_minimum_size = Vector2(30, 30)
	set_b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	set_b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	UITheme.style_btn(set_b, Color("#11223B"), Color("#334F73"), 13)
	set_b.pressed.connect(func(): AudioSynth.play_click(); open_settings_requested.emit())
	hud_hb.add_child(set_b)

	var home_b := Button.new()
	home_b.text = "☰"
	home_b.custom_minimum_size = Vector2(30, 30)
	home_b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	home_b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	UITheme.style_btn(home_b, Color("#11223B"), Color("#334F73"), 13)
	home_b.pressed.connect(func(): AudioSynth.play_click(); back_to_home.emit())
	hud_hb.add_child(home_b)

	# =========================================================================
	# BAND 2: QUICK-ACTION + ICON NAVIGATION BAR (Gambar 2 & 3 menu + icon)
	# =========================================================================
	var nav_bar := PanelContainer.new()
	nav_bar.custom_minimum_size = Vector2(0, 54)
	var nbsb := StyleBoxFlat.new()
	nbsb.bg_color = Color("#0D1C34")
	nbsb.border_color = Color("#1E385C")
	nbsb.border_width_bottom = 2
	nbsb.content_margin_left = 8
	nbsb.content_margin_right = 8
	nbsb.content_margin_top = 4
	nbsb.content_margin_bottom = 4
	nav_bar.add_theme_stylebox_override("panel", nbsb)
	root_vb.add_child(nav_bar)

	var nav_hb := HBoxContainer.new()
	nav_hb.add_theme_constant_override("separation", 6)
	nav_bar.add_child(nav_hb)

	# 2A. MAIN LAGA + SIM split button (or Hold-to-End-Season at end of season)
	_play_normal_box = HBoxContainer.new()
	_play_normal_box.custom_minimum_size = Vector2(146, 44)
	_play_normal_box.add_theme_constant_override("separation", 2)
	nav_hb.add_child(_play_normal_box)

	var main_btn := Button.new()
	main_btn.text = "MAIN\nLAGA"
	main_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	UITheme.style_btn(main_btn, Color("#C46D24"), Color("#F5B865"), 13)
	main_btn.pressed.connect(func(): AudioSynth.play_click(); start_match_requested.emit())
	_play_normal_box.add_child(main_btn)

	var sim_btn := Button.new()
	sim_btn.text = "⚡\nSIM"
	sim_btn.custom_minimum_size = Vector2(40, 44)
	sim_btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sim_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	UITheme.style_btn(sim_btn, Color("#3B6496"), Color("#93C5FD"), 10)
	sim_btn.pressed.connect(func(): AudioSynth.play_click(); sim_match_requested.emit())
	_play_normal_box.add_child(sim_btn)

	_play_hold_wrap = PanelContainer.new()
	_play_hold_wrap.custom_minimum_size = Vector2(146, 44)
	_play_hold_wrap.visible = false
	_play_hold_wrap.add_theme_stylebox_override("panel", UITheme.make_box(Color("#3B2908"), UITheme.ACCENT_GOLD, 2, 4))
	nav_hb.add_child(_play_hold_wrap)
	_end_season_fill = ColorRect.new()
	_end_season_fill.color = Color("#EAB308", 0.55)
	_end_season_fill.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	_end_season_fill.anchor_right = 0.0
	_end_season_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_play_hold_wrap.add_child(_end_season_fill)
	_end_season_btn = Button.new()
	_end_season_btn.text = "TAHAN\nAKHIRI"
	_end_season_btn.flat = true
	_end_season_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_end_season_btn.add_theme_font_override("font", UITheme.get_display_font())
	_end_season_btn.add_theme_font_size_override("font_size", 11)
	_end_season_btn.add_theme_color_override("font_color", Color.WHITE)
	_end_season_btn.button_down.connect(func(): _end_season_holding = true; AudioSynth.play_click())
	_end_season_btn.button_up.connect(func(): _end_season_holding = false)
	_play_hold_wrap.add_child(_end_season_btn)
	_end_season_btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# 2B. KINI Tile
	nav_hb.add_child(_make_nav_tile("KINI", "KINI", Color("#2563EB"), "HOME", 76))

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(16, 0)
	nav_hb.add_child(gap)

	# 2C. 7 Iconic Menu Tiles matching Gambar 2 & 3
	var tile_defs := [
		["BERITA", "BERITA", Color("#9333EA"), "NEWS"],
		["JADWAL", "JADWAL", Color("#EA8C24"), "CAL"],
		["SKUAD", "SKUAD", Color("#38BDF8"), "SQUAD"],
		["BURSA", "BURSA", Color("#22C55E"), "BAG"],
		["ORANG", "ORANG", Color("#EC4899"), "PERSON"],
		["WARISAN", "WARISAN", Color("#EA8C24"), "TROPHY"],
		["TOKO", "TOKO", Color("#EAB308"), "SHOP"],
	]
	for td in tile_defs:
		var tile := _make_nav_tile(str(td[0]), str(td[1]), td[2] as Color, str(td[3]), 0)
		nav_hb.add_child(tile)
		if str(td[0]) == "BURSA":
			_bursa_tile = tile

	# =========================================================================
	# BAND 3: FULL-HEIGHT TAB CONTENT AREA
	# =========================================================================
	_tab_content = Control.new()
	_tab_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vb.add_child(_tab_content)

	var KiniScript := load("res://scenes/tabs/KiniTab.gd")
	_kini_tab = KiniScript.new()
	_kini_tab.start_match_requested.connect(func(): start_match_requested.emit())
	_kini_tab.sim_match_requested.connect(func(): sim_match_requested.emit())
	_kini_tab.open_dilemma_requested.connect(func(): open_dilemma_requested.emit())
	_kini_tab.open_squad_requested.connect(func(): open_cutscene_requested.emit(1))
	_kini_tab.open_lineup_requested.connect(func(): _open_screen("res://scenes/modals/LineupScreen.gd"))
	_kini_tab.open_schedule_requested.connect(func(): _open_screen("res://scenes/modals/ScheduleScreen.gd"))
	_kini_tab.end_season_requested.connect(func(): end_season_requested.emit())

	var BeritaScript := load("res://scenes/tabs/BeritaTab.gd")
	_berita_tab = BeritaScript.new()

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
	_dunia_tab.transfer_flow_requested.connect(func(offer: Dictionary): transfer_flow_requested.emit(offer))

	var WarisanScript := load("res://scenes/tabs/WarisanTab.gd")
	_warisan_tab = WarisanScript.new()
	_warisan_tab.replay_shot_requested.connect(func(clip: Dictionary): replay_clip_requested.emit(clip))

	for tab_ctrl in [_kini_tab, _berita_tab, _pemainku_tab, _timku_tab, _dunia_tab, _warisan_tab]:
		tab_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
		if tab_ctrl != _kini_tab and tab_ctrl != _berita_tab:
			tab_ctrl.offset_left = 8
			tab_ctrl.offset_right = -8
			tab_ctrl.offset_top = 6
			tab_ctrl.offset_bottom = -6
		_tab_content.add_child(tab_ctrl)

	# Floating Transfer Window Hanging Sign suspended below BURSA tile (visible on KINI)
	_tw_hang_host = Control.new()
	_tw_hang_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tw_hang_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_tw_hang_host)

	_build_energy_modal()
	switch_tab("KINI")

func _make_nav_tile(key: String, label_txt: String, col: Color, icon_kind: String, fixed_w: int) -> Control:
	var panel := PanelContainer.new()
	if fixed_w > 0:
		panel.custom_minimum_size = Vector2(fixed_w, 44)
	else:
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.custom_minimum_size = Vector2(72, 44)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#081322")
	sb.border_color = Color("#1B3252")
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	sb.content_margin_left = 3
	sb.content_margin_right = 3
	sb.content_margin_top = 3
	sb.content_margin_bottom = 2
	panel.add_theme_stylebox_override("panel", sb)

	var vb := VBoxContainer.new()
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 2)
	panel.add_child(vb)

	var ic := MenuIconCircle.new()
	ic.custom_minimum_size = Vector2(20, 20)
	ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ic.configure(col, icon_kind)
	vb.add_child(ic)

	var lbl := Label.new()
	lbl.text = label_txt
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_override("font", UITheme.get_display_font())
	lbl.add_theme_font_size_override("font_size", 9)
	lbl.add_theme_color_override("font_color", Color("#E2E8F0"))
	vb.add_child(lbl)

	# Bottom active accent stripe
	var ul := ColorRect.new()
	ul.color = col
	ul.custom_minimum_size = Vector2(0, 2)
	ul.visible = (key == "KINI")
	ul.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(ul)
	_nav_underlines[key] = ul

	# Corner badge (e.g. SP count, LV X, transfer offers)
	var badge := Label.new()
	badge.visible = false
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	badge.add_theme_font_size_override("font_size", 8)
	badge.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	panel.add_child(badge)
	badge.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	badge.offset_left = -38
	badge.offset_right = -3
	badge.offset_top = 1
	badge.offset_bottom = 14
	_nav_badges[key] = badge

	var hit := Button.new()
	hit.flat = true
	hit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var hov := StyleBoxFlat.new()
	hov.bg_color = Color(1.0, 1.0, 1.0, 0.08)
	hov.set_corner_radius_all(3)
	var emp := StyleBoxEmpty.new()
	hit.add_theme_stylebox_override("normal", emp)
	hit.add_theme_stylebox_override("hover", hov)
	hit.add_theme_stylebox_override("pressed", hov)
	hit.add_theme_stylebox_override("focus", emp)
	hit.pressed.connect(func(): AudioSynth.play_click(); _open_nav(key))
	panel.add_child(hit)
	hit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_nav_tiles[key] = panel
	return panel

func _open_nav(key: String) -> void:
	match key:
		"KINI":
			_set_active_nav("KINI")
			switch_tab("KINI")
		"BERITA":
			_set_active_nav("BERITA")
			switch_tab("BERITA")
		"JADWAL":
			_open_screen("res://scenes/modals/ScheduleScreen.gd")
		"SKUAD":
			_set_active_nav("SKUAD")
			switch_tab("TIMKU")
		"BURSA":
			_set_active_nav("BURSA")
			var tw: int = int(CareerState.career.get("careerMeta", {}).get("transferWindowWeeksLeft", 0)) if CareerState.has_active_career else 0
			_dunia_tab.call("set_subtab", "TRANSFER" if tw > 0 else "KOMP.")
			switch_tab("DUNIA")
		"ORANG":
			_set_active_nav("ORANG")
			_pemainku_tab.call("set_subtab", "SKILL")
			switch_tab("PEMAINKU")
		"WARISAN", "RUMAH":
			_set_active_nav("WARISAN")
			switch_tab("WARISAN")
		"TOKO":
			_set_active_nav("TOKO")
			_pemainku_tab.call("set_subtab", "TOKO")
			switch_tab("PEMAINKU")

func _set_active_nav(key: String) -> void:
	_active_nav_key = key
	for k in _nav_underlines.keys():
		(_nav_underlines[k] as ColorRect).visible = (str(k) == key)

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

func _play_transfer_window_open(weeks: int) -> void:
	if is_instance_valid(_tw_overlay):
		_tw_overlay.queue_free()
	var vp: Vector2 = size
	if vp.x < 10.0 or vp.y < 10.0:
		vp = Vector2(960, 540)
	_tw_overlay = Control.new()
	_tw_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tw_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_tw_overlay)
	var ov: Control = _tw_overlay

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.04, 0.08, 0.0)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ov.add_child(dim)

	var door_l := ColorRect.new()
	door_l.color = Color("#0B1626")
	door_l.position = Vector2(0, 0)
	door_l.size = Vector2(vp.x * 0.5, vp.y)
	door_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ov.add_child(door_l)
	var door_r := ColorRect.new()
	door_r.color = Color("#0B1626")
	door_r.position = Vector2(vp.x * 0.5, 0)
	door_r.size = Vector2(vp.x * 0.5, vp.y)
	door_r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ov.add_child(door_r)

	var banner := PanelContainer.new()
	banner.add_theme_stylebox_override("panel", UITheme.make_box(Color("#122B20"), UITheme.ACCENT_GREEN, 3, 10))
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bvb := VBoxContainer.new()
	bvb.add_theme_constant_override("separation", 4)
	banner.add_child(bvb)
	var b1 := Label.new()
	b1.text = "★ BURSA TRANSFER DIBUKA ★"
	b1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b1.add_theme_font_override("font", UITheme.get_display_font())
	b1.add_theme_font_size_override("font_size", 22)
	b1.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	bvb.add_child(b1)
	var b2 := Label.new()
	b2.text = "%d PEKAN • Tawaran klub masuk di BURSA" % weeks
	b2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b2.add_theme_font_size_override("font_size", 12)
	b2.add_theme_color_override("font_color", UITheme.ACCENT_GREEN)
	bvb.add_child(b2)
	ov.add_child(banner)
	var bsz: Vector2 = banner.get_combined_minimum_size() + Vector2(48, 28)
	banner.custom_minimum_size = bsz
	banner.size = bsz
	banner.position = Vector2((vp.x - bsz.x) * 0.5, (vp.y - bsz.y) * 0.5)
	banner.pivot_offset = bsz * 0.5
	banner.scale = Vector2(0.4, 0.4)
	banner.modulate.a = 0.0

	AudioSynth.play_achievement()
	var t := ov.create_tween()
	t.tween_property(dim, "color:a", 0.55, 0.25)
	t.parallel().tween_property(door_l, "position:x", -vp.x * 0.5, 0.75).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	t.parallel().tween_property(door_r, "position:x", vp.x, 0.75).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(banner, "modulate:a", 1.0, 0.18)
	t.parallel().tween_property(banner, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_interval(1.6)
	t.tween_property(ov, "modulate:a", 0.0, 0.4)
	t.tween_callback(ov.queue_free)

func _open_screen(path: String) -> void:
	var scr: GDScript = load(path) as GDScript
	if scr == null or not scr.can_instantiate():
		return
	var ov: Node = scr.new()
	if ov is Control:
		(ov as Control).set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if ov.has_signal("play_requested"):
		ov.connect("play_requested", func(): start_match_requested.emit())
	add_child(ov)

func open_fame_modal() -> CanvasLayer:
	var host: Node = get_tree().root if is_inside_tree() else self
	return WarisanOverlaysScript.open_fame_popup(host)

func switch_tab(t_name: String) -> void:
	_active_tab = t_name
	_kini_tab.visible = (t_name == "KINI")
	_berita_tab.visible = (t_name == "BERITA")
	_pemainku_tab.visible = (t_name == "PEMAINKU")
	_timku_tab.visible = (t_name == "TIMKU")
	_dunia_tab.visible = (t_name == "DUNIA")
	_warisan_tab.visible = (t_name == "WARISAN")
	if _tw_hang_host != null:
		_tw_hang_host.visible = (t_name == "KINI")
	if t_name == "KINI":
		_set_active_nav("KINI")
	elif t_name == "BERITA":
		_set_active_nav("BERITA")
		_berita_tab.call("refresh")
	elif t_name == "TIMKU":
		_set_active_nav("SKUAD")
	elif t_name == "WARISAN":
		_set_active_nav("WARISAN")
	refresh_hud()

func refresh_hud() -> void:
	if not is_inside_tree() or not CareerState.has_active_career:
		return
	var p: Dictionary = CareerState.career["playerProfile"]
	var m: Dictionary = CareerState.career["careerMeta"]
	var club: Dictionary = CareerState.get_current_club()
	var fix: Dictionary = CareerState.get_current_fixture()
	var season_pending: bool = bool(m.get("seasonPendingEnd", false))

	_ovr_label.text = str(int(p["ovr"]))
	var xp: float = float(p.get("xp", 0))
	var xp_next: float = maxf(1.0, float(p.get("xpToNext", 100)))
	var sp := int(p["skillPoints"])
	_ovr_ring.configure(clampf(xp / xp_next, 0.0, 1.0), sp > 0)
	_name_label.text = str(p["name"]).to_upper()
	_cash_label.text = UITheme.format_cash(int(p["cash"]))

	# Energy compact 10-pip bar
	var eng := int(p["energy"])
	var filled := int(round(float(eng) / 10.0))
	var eng_col := UITheme.ACCENT_GREEN if eng >= 60 else (UITheme.ACCENT_GOLD if eng >= 30 else UITheme.ACCENT_RED)
	for i in range(_energy_segs.size()):
		_energy_segs[i].color = eng_col if i < filled else Color("#18283C")
	_energy_lbl.text = "%d" % eng
	_energy_lbl.add_theme_color_override("font_color", eng_col)

	# Fans / Fame (synced with KETENARAN tier star rating)
	var fame_ov: Dictionary = CareerState.get_fame_overview()
	var fans_val: int = int(fame_ov.get("score", 50))
	_fans_lbl.text = "★ %d" % fans_val
	var star_cnt: int = clampi(int(fame_ov.get("stars", 3)), 1, 5)
	_fans_stars_lbl.text = "★".repeat(star_cnt)

	# Center Competition Pill (Elite vs Liga layout matching Gambar 2, 3 & 4)
	var week := int(m.get("week", 1))
	var max_wks := int(m.get("maxWeeks", 45))
	var pos := CareerState.get_user_league_position()
	var total_teams: int = maxi(1, CareerState.career["leagueTable"].size())
	var comp := str(fix.get("comp", "LIGA"))
	var is_elite := comp in ["PIALA_ELITE", "PIALA_EUROPA", "PIALA_CONF", "PIALA_DUNIA_KLUB"]
	var div_num := clampi(int(club.get("division", 3)), 1, 3)
	var month_name := CareerState.get_season_month_name(week)

	_comp_badge_icon.configure(is_elite, comp)
	_comp_pill.add_theme_stylebox_override("panel", UITheme.make_box(Color("#0E2040") if is_elite else Color("#0D1D33"), Color("#38BDF8") if is_elite else Color("#2E4A70"), 1, 6))
	for fc in _comp_flag_host.get_children():
		fc.queue_free()

	if season_pending:
		_comp_title_lbl.text = "AKHIR MUSIM %d" % int(m.get("year", 1))
		_comp_title_lbl.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
		_comp_sub_lbl.text = "POSISI AKHIR ke-%d/%d" % [pos, total_teams]
		_comp_month_lbl.text = "SELESAI"
	elif is_elite:
		var elite_titles := {
			"PIALA_ELITE": "PIALA ELITE",
			"PIALA_EUROPA": "PIALA EUROPA",
			"PIALA_CONF": "PIALA CONF.",
			"PIALA_DUNIA_KLUB": "DUNIA KLUB",
		}
		_comp_title_lbl.text = str(elite_titles.get(comp, "PIALA ELITE"))
		_comp_title_lbl.add_theme_color_override("font_color", Color.WHITE)
		var stg := str(fix.get("stage", "FASE LIGA"))
		_comp_sub_lbl.text = "%s • %s" % [stg, "KDG" if bool(fix.get("is_home", true)) else "TDG"]
		_comp_month_lbl.text = month_name
	elif comp == "LIGA":
		var is_derby := CareerState.is_fixture_derby(fix)
		_comp_title_lbl.text = "LIGA  •  ke-%d%s" % [pos, " ★ DERBY" if is_derby else ""]
		_comp_title_lbl.add_theme_color_override("font_color", Color("#FB7185") if is_derby else Color.WHITE)
		_comp_flag_host.add_child(UITheme.make_flag_rect(int(club["nation_id"]), Vector2(18, 12)))
		_comp_sub_lbl.text = "KE-%d DIVISI  P %d/%d" % [div_num, week, max_wks]
		_comp_month_lbl.text = month_name
	else:
		_comp_title_lbl.text = str(fix.get("comp_label", comp)).to_upper()
		_comp_title_lbl.add_theme_color_override("font_color", Color.WHITE)
		_comp_flag_host.add_child(UITheme.make_flag_rect(int(club["nation_id"]), Vector2(18, 12)))
		_comp_sub_lbl.text = "%s • P %d/%d" % ["KANDANG" if bool(fix.get("is_home", true)) else "TANDANG", week, max_wks]
		_comp_month_lbl.text = month_name

	# Main Play button vs Hold-to-End-Season button
	_play_normal_box.visible = not season_pending
	_play_hold_wrap.visible = season_pending
	if not season_pending:
		_end_season_holding = false
		_end_season_prog = 0.0
		_end_season_triggered = false

	# Nav badges + Hanging Transfer Sign beneath BURSA
	var tw := int(m.get("transferWindowWeeksLeft", 0))
	if bool(m.get("transferWindowAnimPending", false)):
		m["transferWindowAnimPending"] = false
		_play_transfer_window_open(tw)

	var berita_b: Label = _nav_badges.get("BERITA")
	if berita_b != null:
		var unread_tot: int = int(CareerState.get_unread_berita_counts().get("total", 0))
		berita_b.visible = unread_tot > 0
		berita_b.text = "%d" % unread_tot
		berita_b.add_theme_color_override("font_color", Color("#FB7185"))

	var orang_b: Label = _nav_badges.get("ORANG")
	if orang_b != null:
		orang_b.visible = sp > 0
		orang_b.text = "%dP" % sp

	var warisan_b: Label = _nav_badges.get("WARISAN")
	if warisan_b != null:
		warisan_b.visible = false
		warisan_b.text = ""

	var bursa_b: Label = _nav_badges.get("BURSA")
	if bursa_b != null:
		var offers_cnt: int = CareerState.career.get("transferOffers", []).size()
		bursa_b.visible = (tw > 0 and offers_cnt > 0)
		bursa_b.text = "%d" % offers_cnt
		bursa_b.add_theme_color_override("font_color", UITheme.ACCENT_GREEN)

	_rebuild_bursa_hanging_sign(tw, week, max_wks, season_pending)

func _rebuild_bursa_hanging_sign(tw: int, week: int, max_wks: int, season_pending: bool) -> void:
	for c in _tw_hang_host.get_children():
		c.queue_free()
	var is_open := tw > 0
	var wrap := VBoxContainer.new()
	wrap.add_theme_constant_override("separation", 0)
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.custom_minimum_size = Vector2(88, 44)
	wrap.pivot_offset = Vector2(44, 0)
	wrap.rotation_degrees = -2.0

	var hanger := SignRopeHanger.new()
	hanger.custom_minimum_size = Vector2(88, 8)
	hanger.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(hanger)

	var board := PanelContainer.new()
	board.custom_minimum_size = Vector2(88, 36)
	board.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#48D158") if is_open else Color("#E56555")
	sb.border_color = Color("#B7F7BC") if is_open else Color("#FDB4A8")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(5)
	sb.content_margin_left = 4
	sb.content_margin_right = 4
	sb.content_margin_top = 2
	sb.content_margin_bottom = 3
	board.add_theme_stylebox_override("panel", sb)
	wrap.add_child(board)

	var bvb := VBoxContainer.new()
	bvb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bvb.add_theme_constant_override("separation", 1)
	board.add_child(bvb)

	var top_l := Label.new()
	top_l.text = "BUKA" if is_open else "TUTUP"
	top_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_l.add_theme_font_override("font", UITheme.get_display_font())
	top_l.add_theme_font_size_override("font_size", 10)
	top_l.add_theme_color_override("font_color", Color("#07220D") if is_open else Color("#280806"))
	bvb.add_child(top_l)

	var pill := PanelContainer.new()
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color("#0D2A15") if is_open else Color("#33100D")
	psb.set_corner_radius_all(3)
	psb.content_margin_left = 3
	psb.content_margin_right = 3
	psb.content_margin_top = 1
	psb.content_margin_bottom = 1
	pill.add_theme_stylebox_override("panel", psb)
	bvb.add_child(pill)

	var sub_l := Label.new()
	if is_open:
		sub_l.text = "TUTUP %d P" % tw
	elif season_pending:
		sub_l.text = "AKHIR MUSIM"
	else:
		sub_l.text = "BUKA %d P" % maxi(1, max_wks + 1 - week)
	sub_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sub_l.add_theme_font_size_override("font_size", 8)
	sub_l.add_theme_color_override("font_color", Color("#D1FAE5") if is_open else Color("#FEE2E2"))
	pill.add_child(sub_l)

	_tw_hang_sign = wrap
	_tw_hang_host.add_child(wrap)
	_tw_hang_host.visible = (_active_tab == "KINI")
	_sync_bursa_sign_pos()

func _sync_bursa_sign_pos() -> void:
	if _tw_hang_sign == null or _bursa_tile == null or not is_instance_valid(_tw_hang_sign):
		return
	var tile_pos := _bursa_tile.global_position - global_position
	var cx := tile_pos.x + _bursa_tile.size.x * 0.5
	var by := tile_pos.y + _bursa_tile.size.y - 1.0
	if _bursa_tile.size.x < 10.0:
		cx = 610.0
		by = 96.0
	_tw_hang_sign.position = Vector2(cx - 44.0, by)

class SignRopeHanger extends Control:
	func _draw() -> void:
		var cx := size.x * 0.5
		draw_line(Vector2(18.0, size.y), Vector2(cx, 1.0), Color("#94A3B8"), 1.8)
		draw_line(Vector2(size.x - 18.0, size.y), Vector2(cx, 1.0), Color("#94A3B8"), 1.8)
		draw_circle(Vector2(cx, 1.8), 2.2, Color("#E2E8F0"))

class CompEmblemIcon extends Control:
	var _is_elite: bool = false
	var _comp: String = "LIGA"

	func configure(is_elite: bool, comp: String) -> void:
		_is_elite = is_elite
		_comp = comp
		queue_redraw()

	func _draw() -> void:
		var cx := size.x * 0.5
		var cy := size.y * 0.5
		if _is_elite:
			var pts := PackedVector2Array([
				Vector2(cx - 9, cy - 10), Vector2(cx + 9, cy - 10),
				Vector2(cx + 9, cy + 2), Vector2(cx, cy + 11), Vector2(cx - 9, cy + 2)
			])
			draw_colored_polygon(pts, Color("#1E4E8C"))
			draw_polyline(pts + PackedVector2Array([pts[0]]), Color("#93C5FD"), 1.6)
			draw_circle(Vector2(cx, cy - 1), 3.6, Color("#E2E8F0"))
		else:
			# Gold League Trophy Cup
			draw_rect(Rect2(cx - 6, cy - 8, 12, 9), Color("#EAB308"))
			draw_rect(Rect2(cx - 4, cy - 6, 4, 5), Color("#FEF08A"))
			draw_arc(Vector2(cx - 6, cy - 4), 3.5, PI * 0.5, PI * 1.5, 8, Color("#EAB308"), 1.6)
			draw_arc(Vector2(cx + 6, cy - 4), 3.5, -PI * 0.5, PI * 0.5, 8, Color("#EAB308"), 1.6)
			draw_rect(Rect2(cx - 2, cy + 1, 4, 5), Color("#CA8A04"))
			draw_rect(Rect2(cx - 6, cy + 6, 12, 3), Color("#92400E"))

class MenuIconCircle extends Control:
	var _col: Color = Color("#38BDF8")
	var _kind: String = "HOME"

	func configure(col: Color, kind: String) -> void:
		_col = col
		_kind = kind
		queue_redraw()

	func _draw() -> void:
		var cx := size.x * 0.5
		var cy := size.y * 0.5
		var r := minf(size.x, size.y) * 0.48
		draw_circle(Vector2(cx, cy), r, _col)
		var fg := Color("#0A1320")
		match _kind:
			"HOME":
				var roof := PackedVector2Array([Vector2(cx, cy - 5), Vector2(cx + 5, cy), Vector2(cx - 5, cy)])
				draw_colored_polygon(roof, fg)
				draw_rect(Rect2(cx - 3.5, cy, 7, 4.5), fg)
			"NEWS":
				draw_rect(Rect2(cx - 1.2, cy - 5, 2.4, 6), fg)
				draw_rect(Rect2(cx - 1.2, cy + 2.5, 2.4, 2.4), fg)
			"CAL":
				draw_rect(Rect2(cx - 4.5, cy - 3.5, 9, 8), fg)
				draw_rect(Rect2(cx - 3.2, cy - 1, 6.4, 4.2), _col)
				draw_rect(Rect2(cx - 2, cy + 0.5, 1.5, 1.5), fg)
				draw_rect(Rect2(cx + 0.5, cy + 0.5, 1.5, 1.5), fg)
			"SQUAD":
				draw_rect(Rect2(cx - 3.5, cy - 4, 7, 8), fg)
				draw_rect(Rect2(cx - 5.5, cy - 3.5, 2, 3.5), fg)
				draw_rect(Rect2(cx + 3.5, cy - 3.5, 2, 3.5), fg)
			"BAG":
				draw_arc(Vector2(cx, cy - 3), 2.5, PI, TAU, 8, fg, 1.5)
				draw_rect(Rect2(cx - 4.5, cy - 2.5, 9, 7), fg)
				draw_rect(Rect2(cx - 1, cy - 0.5, 2, 3), _col)
			"PERSON":
				draw_circle(Vector2(cx, cy - 2.6), 2.4, fg)
				draw_rect(Rect2(cx - 4.2, cy + 0.8, 8.4, 3.8), fg)
			"HOUSE":
				var rf := PackedVector2Array([Vector2(cx, cy - 5), Vector2(cx + 5, cy - 0.5), Vector2(cx - 5, cy - 0.5)])
				draw_colored_polygon(rf, fg)
				draw_rect(Rect2(cx - 3.5, cy - 0.5, 7, 5), fg)
				draw_rect(Rect2(cx - 1, cy + 1.5, 2, 3), _col)
			"TROPHY":
				draw_colored_polygon(PackedVector2Array([
					Vector2(cx - 4.2, cy - 4.6), Vector2(cx + 4.2, cy - 4.6),
					Vector2(cx + 3.0, cy + 0.6), Vector2(cx - 3.0, cy + 0.6),
				]), fg)
				draw_rect(Rect2(cx - 1.2, cy + 0.6, 2.4, 2.2), fg)
				draw_rect(Rect2(cx - 3.2, cy + 2.8, 6.4, 1.8), fg)
			"SHOP":
				draw_circle(Vector2(cx, cy), 4.5, fg)
				draw_circle(Vector2(cx, cy), 2.6, _col)
				draw_rect(Rect2(cx - 0.8, cy - 2, 1.6, 4), fg)

class OvrBorderBar extends Control:
	var _progress: float = 0.0
	var _ready_up: bool = false

	func configure(progress: float, ready_up: bool) -> void:
		_progress = clampf(progress, 0.0, 1.0)
		_ready_up = ready_up
		queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2(1.5, 1.5), size - Vector2(3.0, 3.0))
		if r.size.x <= 2.0 or r.size.y <= 2.0:
			return
		draw_rect(r, Color("#243A56"), false, 2.0)
		var fill_col := UITheme.ACCENT_GOLD if _ready_up else UITheme.ACCENT_GREEN
		var prog := 1.0 if _ready_up else _progress
		if prog <= 0.0:
			return
		var perim := 2.0 * (r.size.x + r.size.y)
		var rem := perim * prog
		var tl := r.position
		var tr := Vector2(r.end.x, r.position.y)
		var br := r.end
		var bl := Vector2(r.position.x, r.end.y)
		for seg in [[tl, tr, r.size.x], [tr, br, r.size.y], [br, bl, r.size.x], [bl, tl, r.size.y]]:
			if rem <= 0.0:
				break
			var a: Vector2 = seg[0]
			var b: Vector2 = seg[1]
			var slen: float = seg[2]
			var f := clampf(rem / slen, 0.0, 1.0)
			draw_line(a, a.lerp(b, f), fill_col, 2.5)
			rem -= slen
