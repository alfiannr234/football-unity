extends Control

signal career_created(slot_id: int)
signal cancelled

enum WizardStep { CREATE_PLAYER, CHOOSE_CLUB, CHOOSE_MODE, SEASON_INTRO }

var target_slot: int = 1
var _step: WizardStep = WizardStep.CREATE_PLAYER

# Player creation state
var _player_name: String = "ALFIAN"
var _nat_idx: int = 16  # Indonesia default (can switch to any of 55 nations)
var _pos_code: String = "ST"
var _skin_idx: int = 1
var _hair_style: int = 2
var _hair_col: int = 1
var _tip_color: int = 0
var _beard: bool = false
var _beard_style: int = 0
var _boot_id: int = 0
var _sleeve: String = "PENDEK"
var _tattoo_face: int = 0
var _tattoo_arm: int = 0
var _tattoo_leg: int = 0
var _headwear: int = 0
var _eyewear: int = 0
var _casual_style: int = 0
var _outfit_variant: int = 0
var _shirt_num: int = 9
var _custom_tab: String = "KAU"

# Club selection state
var _offers: Array[Dictionary] = []
var _offer_idx: int = 0
var _selected_club: Dictionary = {}
var _browser_nat_idx: int = 18  # Brasil or user-selected nation for PILIH KLUBMU
var _browser_div: int = 3       # Divisi ke-3 default

# Mode selection state
var _selected_mode: String = "NORMAL"

var _root_layer: Control
var _sub_modal_layer: Control
var _avatar_preview: PixelAvatar

func configure(slot_id: int) -> void:
	target_slot = slot_id

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UITheme.build_theme()
	_selected_mode = str(SettingsManager.data.get("difficulty", "NORMAL"))

	var bg := ColorRect.new()
	bg.color = Color("#060D17")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_root_layer = Control.new()
	_root_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_root_layer)

	_sub_modal_layer = Control.new()
	_sub_modal_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_sub_modal_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_sub_modal_layer)

	_offers = CareerState.get_starter_offers(_nat_idx)
	if not _offers.is_empty():
		_selected_club = _offers[0]["club"]
	_render_step()

func _clear_root() -> void:
	for c in _root_layer.get_children():
		c.queue_free()

func _render_step() -> void:
	_clear_root()
	match _step:
		WizardStep.CREATE_PLAYER:
			_render_create_player()
		WizardStep.CHOOSE_CLUB:
			_render_choose_club()
		WizardStep.CHOOSE_MODE:
			_render_choose_mode()
		WizardStep.SEASON_INTRO:
			_render_season_intro()

# ---------------------------------------------------------------------------
# STEP 1: BUAT PEMAINMU (Character Creation matching screenshots)
# ---------------------------------------------------------------------------
func _render_create_player() -> void:
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 14
	vb.offset_right = -14
	vb.offset_top = 10
	vb.offset_bottom = -10
	vb.add_theme_constant_override("separation", 8)
	_root_layer.add_child(vb)

	# Header: <- BUAT PEMAINMU  1/2
	var hdr := HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 8)
	vb.add_child(hdr)

	var back_b := Button.new()
	back_b.text = "←"
	back_b.custom_minimum_size = Vector2(38, 34)
	back_b.pressed.connect(func(): AudioSynth.play_click(); cancelled.emit(); queue_free())
	hdr.add_child(back_b)

	var ttl := Label.new()
	ttl.text = "BUAT PEMAINMU"
	ttl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ttl.add_theme_font_override("font", UITheme.get_display_font())
	ttl.add_theme_font_size_override("font_size", 20)
	hdr.add_child(ttl)

	var prog := Label.new()
	prog.text = "1/2"
	prog.add_theme_color_override("font_color", UITheme.ACCENT_CYAN)
	hdr.add_child(prog)

	# Landscape 2-Column Split: Left = Preview + Name + Actions | Right = Tabs + Options
	var split_hb := HBoxContainer.new()
	split_hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split_hb.add_theme_constant_override("separation", 12)
	vb.add_child(split_hb)

	var left_vb := VBoxContainer.new()
	left_vb.custom_minimum_size = Vector2(335, 0)
	left_vb.add_theme_constant_override("separation", 8)
	split_hb.add_child(left_vb)

	var right_vb := VBoxContainer.new()
	right_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vb.add_theme_constant_override("separation", 8)
	split_hb.add_child(right_vb)

	# Locker Room Visual Stage with live PixelAvatar
	var stage := PanelContainer.new()
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_vb.add_child(stage)

	var lr_bg := TextureRect.new()
	lr_bg.texture = load("res://assets/sprites/backgrounds/locker_room.png")
	lr_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lr_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	stage.add_child(lr_bg)

	var stage_ctr := CenterContainer.new()
	stage.add_child(stage_ctr)
	_avatar_preview = PixelAvatar.new()
	_avatar_preview.custom_minimum_size = Vector2(124, 182)
	_avatar_preview.anim_mode = "IDLE"
	_sync_avatar_preview()
	stage_ctr.add_child(_avatar_preview)

	# Identity Row: [60] [ST] [NAMAMU LineEdit] [Flag Button]
	var id_hb := HBoxContainer.new()
	id_hb.add_theme_constant_override("separation", 6)
	left_vb.add_child(id_hb)

	id_hb.add_child(UITheme.make_ovr_badge(60, "default", Vector2(38, 38)))

	var pos_badge := PanelContainer.new()
	pos_badge.custom_minimum_size = Vector2(46, 38)
	pos_badge.add_theme_stylebox_override("panel", UITheme.make_box(Color("#D8725A"), Color("#F4A48E"), 1, 3))
	var pos_l := Label.new()
	pos_l.text = _pos_code
	pos_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pos_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pos_l.add_theme_font_override("font", UITheme.get_display_font())
	pos_badge.add_child(pos_l)
	id_hb.add_child(pos_badge)

	var name_ed := LineEdit.new()
	name_ed.text = _player_name
	name_ed.placeholder_text = "NAMAMU"
	name_ed.max_length = 16
	name_ed.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_ed.alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_ed.text_changed.connect(func(txt: String): _player_name = txt)
	id_hb.add_child(name_ed)

	var nat_btn := Button.new()
	nat_btn.custom_minimum_size = Vector2(52, 38)
	nat_btn.text = str(GameData.nations[_nat_idx]["code"])
	UITheme.style_btn(nat_btn, Color("#112642"), UITheme.BORDER_CYAN, 12)
	nat_btn.pressed.connect(func(): AudioSynth.play_click(); _open_nation_picker(true))
	id_hb.add_child(nat_btn)

	# Left Bottom Row: [Acak] [LANJUT >]
	var bot_hb := HBoxContainer.new()
	bot_hb.add_theme_constant_override("separation", 6)
	left_vb.add_child(bot_hb)

	var rand_b := Button.new()
	rand_b.text = "ACAK"
	rand_b.custom_minimum_size = Vector2(76, 44)
	rand_b.pressed.connect(func():
		AudioSynth.play_click()
		_skin_idx = randi_range(0, CharacterStyleCatalog.SKIN_TONES.size() - 1)
		_hair_style = randi_range(0, CharacterStyleCatalog.HAIR_STYLES.size() - 1)
		_hair_col = randi_range(0, CharacterStyleCatalog.HAIR_COLORS.size() - 1)
		_tip_color = randi_range(0, CharacterStyleCatalog.TIP_COLORS.size() - 1) if randf() < 0.35 else 0
		_beard_style = randi_range(0, CharacterStyleCatalog.BEARD_STYLES.size() - 1) if randf() < 0.4 else 0
		_beard = (_beard_style > 0)
		_sync_avatar_preview()
		_render_step()
	)
	bot_hb.add_child(rand_b)

	var next_b := Button.new()
	next_b.text = "LANJUT  >"
	next_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	next_b.custom_minimum_size = Vector2(0, 44)
	UITheme.style_btn(next_b, Color("#122B4A"), UITheme.BORDER_CYAN, 16)
	next_b.pressed.connect(func():
		AudioSynth.play_click()
		if _player_name.strip_edges().is_empty():
			_player_name = "ALFIAN"
		_offers = CareerState.get_starter_offers(_nat_idx)
		_offer_idx = 0
		if not _offers.is_empty():
			_selected_club = _offers[0]["club"]
		_browser_nat_idx = _nat_idx
		_step = WizardStep.CHOOSE_CLUB
		_render_step()
	)
	bot_hb.add_child(next_b)

	# Right: 9 Customization Category Tabs
	var c_scroll := ScrollContainer.new()
	c_scroll.custom_minimum_size = Vector2(0, 42)
	c_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right_vb.add_child(c_scroll)
	var c_hb := HBoxContainer.new()
	c_hb.add_theme_constant_override("separation", 4)
	c_scroll.add_child(c_hb)

	for ct in ["KAU", "POTONGAN", "WARNA", "WAJAH", "JENGGOT", "TATO", "BOOT", "KASUAL", "GALA"]:
		var cb := Button.new()
		cb.text = ct
		cb.custom_minimum_size = Vector2(56, 34)
		var act: bool = (_custom_tab == ct)
		UITheme.style_btn(cb, Color("#173B66") if act else Color("#0B1626"), UITheme.BORDER_CYAN if act else UITheme.BORDER_STEEL, 9)
		cb.pressed.connect(func():
			AudioSynth.play_click()
			_custom_tab = ct
			if ct == "KASUAL":
				_casual_style = 1
			elif ct == "GALA":
				_casual_style = 2
			elif ct == "BOOT" or ct == "KAU":
				_casual_style = 0
			_sync_avatar_preview()
			_render_step()
		)
		c_hb.add_child(cb)

	# Dynamic Sub-Panel Area
	var body_scroll := ScrollContainer.new()
	body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vb.add_child(body_scroll)
	var body_vb := VBoxContainer.new()
	body_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_vb.add_theme_constant_override("separation", 8)
	body_scroll.add_child(body_vb)

	if _custom_tab == "KAU":
		# TEMPATMU: Interactive 2D Green Pitch Position Picker
		var t_lbl := Label.new()
		t_lbl.text = "TEMPATMU (PILIH POSISI UTAMA)"
		t_lbl.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
		t_lbl.add_theme_font_size_override("font_size", 11)
		body_vb.add_child(t_lbl)

		var pitch := PanelContainer.new()
		pitch.custom_minimum_size = Vector2(0, 185)
		pitch.add_theme_stylebox_override("panel", UITheme.make_box(Color("#1D7A32"), Color("#D2E8D6"), 2, 2))
		body_vb.add_child(pitch)
		var pvb := VBoxContainer.new()
		pvb.alignment = BoxContainer.ALIGNMENT_CENTER
		pvb.add_theme_constant_override("separation", 10)
		pitch.add_child(pvb)

		var pos_rows := [
			["LW", "ST", "RW"],
			["", "CAM", ""],
			["LM", "CM", "RM"],
			["", "CDM", ""],
		]
		for pr in pos_rows:
			var rhb := HBoxContainer.new()
			rhb.alignment = BoxContainer.ALIGNMENT_CENTER
			rhb.add_theme_constant_override("separation", 28)
			pvb.add_child(rhb)
			for code in pr:
				if code == "":
					var sp := Control.new()
					sp.custom_minimum_size = Vector2(68, 28)
					rhb.add_child(sp)
				else:
					var pb := Button.new()
					pb.text = code
					pb.custom_minimum_size = Vector2(68, 30)
					var sel: bool = (_pos_code == code)
					UITheme.style_btn(pb, Color("#D8725A") if sel else Color("#152B48"), Color.WHITE if sel else UITheme.BORDER_STEEL, 12)
					pb.pressed.connect(func(): AudioSynth.play_click(); _pos_code = code; _render_step())
					rhb.add_child(pb)

		var req_l := Label.new()
		var role_hint := "MEREKA MINTA GOL" if _pos_code in ["ST", "LW", "RW"] else ("MEREKA MINTA UMPAN & KREASI" if _pos_code in ["CAM", "LM", "RM", "CM"] else "MEREKA MINTA PENJAGAAN LINI")
		req_l.text = "● %s" % role_hint
		req_l.add_theme_color_override("font_color", UITheme.ACCENT_CYAN)
		req_l.add_theme_font_size_override("font_size", 11)
		body_vb.add_child(req_l)

		# NEGARAMU Quick Picker (5 featured flags + LAIN)
		var n_hdr := HBoxContainer.new()
		body_vb.add_child(n_hdr)
		var nl1 := Label.new()
		nl1.text = "NEGARAMU: %s" % str(GameData.nations[_nat_idx]["name"]).to_upper()
		nl1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nl1.add_theme_font_size_override("font_size", 11)
		n_hdr.add_child(nl1)

		var q_flags := HBoxContainer.new()
		q_flags.add_theme_constant_override("separation", 4)
		body_vb.add_child(q_flags)
		# Indonesia(16), Brasil(18), Spanyol(1), Swedia(0) + LAIN
		for nid in [16, 18, 1, 0]:
			var fb := Button.new()
			fb.text = str(GameData.nations[nid]["name"]).to_upper()
			fb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			fb.custom_minimum_size = Vector2(0, 42)
			var is_n: bool = (_nat_idx == nid)
			UITheme.style_btn(fb, Color("#173B66") if is_n else Color("#0B1626"), UITheme.ACCENT_GOLD if is_n else UITheme.BORDER_STEEL, 10)
			fb.pressed.connect(func(): AudioSynth.play_click(); _nat_idx = nid; _offers = CareerState.get_starter_offers(_nat_idx); if not _offers.is_empty(): _selected_club = _offers[0]["club"]; _render_step())
			q_flags.add_child(fb)
		var lain_b := Button.new()
		lain_b.text = "LAIN\n(55)"
		lain_b.custom_minimum_size = Vector2(56, 42)
		UITheme.style_btn(lain_b, Color("#1B2D48"), UITheme.BORDER_CYAN, 10)
		lain_b.pressed.connect(func(): AudioSynth.play_click(); _open_nation_picker(true))
		q_flags.add_child(lain_b)

	elif _custom_tab == "POTONGAN":
		var base_app := _make_wizard_base_app()
		body_vb.add_child(UITheme.make_section_header("GAYA RAMBUT (%d DESAIN)" % CharacterStyleCatalog.HAIR_STYLES.size()))
		var grid := GridContainer.new()
		grid.columns = 5
		grid.add_theme_constant_override("h_separation", 6)
		grid.add_theme_constant_override("v_separation", 6)
		body_vb.add_child(grid)
		for i in range(CharacterStyleCatalog.HAIR_STYLES.size()):
			var idx: int = i
			var tile := CharacterStyleCatalog.build_avatar_preview_tile(
				CharacterStyleCatalog.HAIR_STYLES[idx],
				base_app,
				{"hair_style": idx, "headwear": 0, "casual_style": 0},
				false,
				_hair_style == idx,
				func():
					_hair_style = idx
					_headwear = 0
					_sync_avatar_preview()
					_render_step(),
				88.0
			)
			grid.add_child(tile)

	elif _custom_tab == "WARNA":
		var base_app := _make_wizard_base_app()
		body_vb.add_child(UITheme.make_section_header("WARNA RAMBUT"))
		var h_grid := GridContainer.new()
		h_grid.columns = 5
		h_grid.add_theme_constant_override("h_separation", 6)
		h_grid.add_theme_constant_override("v_separation", 6)
		body_vb.add_child(h_grid)
		for i in range(CharacterStyleCatalog.HAIR_COLORS.size()):
			var idx: int = i
			var hc: Dictionary = CharacterStyleCatalog.HAIR_COLORS[idx]
			h_grid.add_child(CharacterStyleCatalog.build_color_swatch_tile(
				str(hc["name"]),
				hc["col"],
				_hair_col == idx,
				func(): _hair_col = idx; _sync_avatar_preview(); _render_step(),
				42.0,
				34.0
			))

		body_vb.add_child(UITheme.make_section_header("UJUNG RAMBUT (HIGHLIGHT)"))
		var tip_grid := GridContainer.new()
		tip_grid.columns = 4
		tip_grid.add_theme_constant_override("h_separation", 6)
		body_vb.add_child(tip_grid)
		for i in range(CharacterStyleCatalog.TIP_COLORS.size()):
			var idx: int = i
			var tc: Dictionary = CharacterStyleCatalog.TIP_COLORS[idx]
			tip_grid.add_child(CharacterStyleCatalog.build_avatar_preview_tile(
				str(tc["name"]),
				base_app,
				{"tip_color": idx, "headwear": 0},
				false,
				_tip_color == idx,
				func(): _tip_color = idx; _sync_avatar_preview(); _render_step(),
				84.0
			))

		body_vb.add_child(UITheme.make_section_header("WARNA KULIT"))
		var s_grid := GridContainer.new()
		s_grid.columns = 6
		s_grid.add_theme_constant_override("h_separation", 6)
		body_vb.add_child(s_grid)
		for i in range(CharacterStyleCatalog.SKIN_TONES.size()):
			var idx: int = i
			var sk: Dictionary = CharacterStyleCatalog.SKIN_TONES[idx]
			s_grid.add_child(CharacterStyleCatalog.build_color_swatch_tile(
				str(sk["name"]),
				sk["col"],
				_skin_idx == idx,
				func(): _skin_idx = idx; _sync_avatar_preview(); _render_step(),
				38.0,
				36.0
			))

	elif _custom_tab == "WAJAH":
		var base_app := _make_wizard_base_app()
		body_vb.add_child(UITheme.make_section_header("WARNA KULIT"))
		var sk_grid := GridContainer.new()
		sk_grid.columns = 3
		sk_grid.add_theme_constant_override("h_separation", 6)
		sk_grid.add_theme_constant_override("v_separation", 6)
		body_vb.add_child(sk_grid)
		for i in range(CharacterStyleCatalog.SKIN_TONES.size()):
			var idx: int = i
			var sk: Dictionary = CharacterStyleCatalog.SKIN_TONES[idx]
			sk_grid.add_child(CharacterStyleCatalog.build_avatar_preview_tile(
				str(sk["name"]),
				base_app,
				{"skin": idx},
				false,
				_skin_idx == idx,
				func(): _skin_idx = idx; _sync_avatar_preview(); _render_step(),
				82.0
			))

		body_vb.add_child(UITheme.make_section_header("TOPI & IKAT KEPALA"))
		var hw_grid := GridContainer.new()
		hw_grid.columns = 5
		hw_grid.add_theme_constant_override("h_separation", 6)
		hw_grid.add_theme_constant_override("v_separation", 6)
		body_vb.add_child(hw_grid)
		for i in range(CharacterStyleCatalog.HEADWEAR_STYLES.size()):
			var idx: int = i
			hw_grid.add_child(CharacterStyleCatalog.build_avatar_preview_tile(
				CharacterStyleCatalog.HEADWEAR_STYLES[idx],
				base_app,
				{"headwear": idx},
				false,
				_headwear == idx,
				func(): _headwear = idx; _sync_avatar_preview(); _render_step(),
				84.0
			))

		body_vb.add_child(UITheme.make_section_header("KACAMATA"))
		var ew_grid := GridContainer.new()
		ew_grid.columns = 4
		ew_grid.add_theme_constant_override("h_separation", 6)
		body_vb.add_child(ew_grid)
		for i in range(CharacterStyleCatalog.EYEWEAR_STYLES.size()):
			var idx: int = i
			ew_grid.add_child(CharacterStyleCatalog.build_avatar_preview_tile(
				CharacterStyleCatalog.EYEWEAR_STYLES[idx],
				base_app,
				{"eyewear": idx},
				false,
				_eyewear == idx,
				func(): _eyewear = idx; _sync_avatar_preview(); _render_step(),
				82.0
			))

	elif _custom_tab == "JENGGOT":
		var base_app := _make_wizard_base_app()
		body_vb.add_child(UITheme.make_section_header("MODEL JENGGOT & KUMIS (%d)" % CharacterStyleCatalog.BEARD_STYLES.size()))
		var b_grid := GridContainer.new()
		b_grid.columns = 5
		b_grid.add_theme_constant_override("h_separation", 6)
		b_grid.add_theme_constant_override("v_separation", 6)
		body_vb.add_child(b_grid)
		for i in range(CharacterStyleCatalog.BEARD_STYLES.size()):
			var idx: int = i
			b_grid.add_child(CharacterStyleCatalog.build_avatar_preview_tile(
				CharacterStyleCatalog.BEARD_STYLES[idx],
				base_app,
				{"beard_style": idx, "beard": idx > 0},
				false,
				_beard_style == idx,
				func():
					_beard_style = idx
					_beard = (idx > 0)
					_sync_avatar_preview()
					_render_step(),
				88.0
			))

	elif _custom_tab == "TATO":
		var base_app := _make_wizard_base_app()
		body_vb.add_child(UITheme.make_section_header("TATO WAJAH"))
		var tf_grid := GridContainer.new()
		tf_grid.columns = 3
		tf_grid.add_theme_constant_override("h_separation", 6)
		tf_grid.add_theme_constant_override("v_separation", 6)
		body_vb.add_child(tf_grid)
		for i in range(CharacterStyleCatalog.FACE_TATTOOS.size()):
			var idx: int = i
			tf_grid.add_child(CharacterStyleCatalog.build_avatar_preview_tile(
				CharacterStyleCatalog.FACE_TATTOOS[idx],
				base_app,
				{"tattoo_face": idx},
				false,
				_tattoo_face == idx,
				func(): _tattoo_face = idx; _sync_avatar_preview(); _render_step(),
				82.0
			))

		body_vb.add_child(UITheme.make_section_header("TATO LENGAN"))
		var ta_grid := GridContainer.new()
		ta_grid.columns = 3
		ta_grid.add_theme_constant_override("h_separation", 6)
		ta_grid.add_theme_constant_override("v_separation", 6)
		body_vb.add_child(ta_grid)
		for i in range(CharacterStyleCatalog.ARM_TATTOOS.size()):
			var idx: int = i
			ta_grid.add_child(CharacterStyleCatalog.build_avatar_preview_tile(
				CharacterStyleCatalog.ARM_TATTOOS[idx],
				base_app,
				{"tattoo_arm": idx, "sleeve": "PENDEK", "casual_style": 0},
				true,
				_tattoo_arm == idx,
				func(): _tattoo_arm = idx; _sleeve = "PENDEK"; _sync_avatar_preview(); _render_step(),
				90.0
			))

		body_vb.add_child(UITheme.make_section_header("TATO KAKI"))
		var tl_grid := GridContainer.new()
		tl_grid.columns = 3
		tl_grid.add_theme_constant_override("h_separation", 6)
		body_vb.add_child(tl_grid)
		for i in range(CharacterStyleCatalog.LEG_TATTOOS.size()):
			var idx: int = i
			tl_grid.add_child(CharacterStyleCatalog.build_avatar_preview_tile(
				CharacterStyleCatalog.LEG_TATTOOS[idx],
				base_app,
				{"tattoo_leg": idx, "casual_style": 0},
				true,
				_tattoo_leg == idx,
				func(): _tattoo_leg = idx; _sync_avatar_preview(); _render_step(),
				90.0
			))

	elif _custom_tab == "BOOT":
		var num_hb := HBoxContainer.new()
		num_hb.add_theme_constant_override("separation", 6)
		body_vb.add_child(num_hb)
		var nl := Label.new()
		nl.text = "NO. PUNGGUNG: #%d" % _shirt_num
		nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		num_hb.add_child(nl)
		var bm := Button.new()
		bm.text = "-"
		bm.custom_minimum_size = Vector2(38, 34)
		bm.pressed.connect(func(): AudioSynth.play_click(); _shirt_num = maxi(1, _shirt_num - 1); _sync_avatar_preview(); _render_step())
		var bp := Button.new()
		bp.text = "+"
		bp.custom_minimum_size = Vector2(38, 34)
		bp.pressed.connect(func(): AudioSynth.play_click(); _shirt_num = mini(99, _shirt_num + 1); _sync_avatar_preview(); _render_step())
		num_hb.add_child(bm)
		num_hb.add_child(bp)

		var sl_hb := HBoxContainer.new()
		sl_hb.add_theme_constant_override("separation", 6)
		body_vb.add_child(sl_hb)
		for sl_t in ["PENDEK", "PANJANG"]:
			var sb := Button.new()
			sb.text = "LENGAN " + sl_t
			sb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			sb.custom_minimum_size = Vector2(0, 34)
			UITheme.style_btn(sb, Color("#173B66") if _sleeve == sl_t else Color("#0B1626"), UITheme.BORDER_CYAN if _sleeve == sl_t else UITheme.BORDER_STEEL, 10)
			sb.pressed.connect(func(): AudioSynth.play_click(); _sleeve = sl_t; _casual_style = 0; _sync_avatar_preview(); _render_step())
			sl_hb.add_child(sb)

		body_vb.add_child(UITheme.make_section_header("PILIH SEPATU PEMULA"))
		var b_hb := GridContainer.new()
		b_hb.columns = 3
		b_hb.add_theme_constant_override("h_separation", 6)
		b_hb.add_theme_constant_override("v_separation", 6)
		body_vb.add_child(b_hb)
		var boot_sheet: Texture2D = load("res://assets/sprites/ui/boots_strip.png")
		for i in range(6):
			var idx: int = i
			var bt: Dictionary = GameData.boots_catalog[idx]
			var b := Button.new()
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.custom_minimum_size = Vector2(0, 74)
			var is_sel_b: bool = (_boot_id == idx)
			UITheme.style_btn(b, Color("#15365E") if is_sel_b else Color("#0A1320"), UITheme.ACCENT_GOLD if is_sel_b else UITheme.BORDER_STEEL, 10)
			b.pressed.connect(func(): AudioSynth.play_click(); _boot_id = idx; _sync_avatar_preview(); _render_step())
			var bvb := VBoxContainer.new()
			bvb.set_anchors_preset(Control.PRESET_FULL_RECT)
			bvb.alignment = BoxContainer.ALIGNMENT_CENTER
			bvb.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(bvb)
			var btex := TextureRect.new()
			var bat := AtlasTexture.new()
			bat.atlas = boot_sheet
			bat.region = Rect2(idx * 32, 0, 32, 32)
			btex.texture = bat
			btex.custom_minimum_size = Vector2(38, 38)
			btex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			btex.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			btex.mouse_filter = Control.MOUSE_FILTER_IGNORE
			bvb.add_child(btex)
			var bl := Label.new()
			bl.text = str(bt["name"])
			bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			bl.clip_text = true
			bl.add_theme_font_size_override("font_size", 9)
			bl.add_theme_color_override("font_color", UITheme.ACCENT_GOLD if is_sel_b else Color("#CBD5E1"))
			bl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			bvb.add_child(bl)
			b_hb.add_child(b)

	elif _custom_tab == "KASUAL":
		var base_app := _make_wizard_base_app()
		var rst_b := Button.new()
		rst_b.text = "PAKAI JERSEY KLUB" if _casual_style != 0 else "* SEDANG PAKAI JERSEY"
		rst_b.custom_minimum_size = Vector2(0, 34)
		UITheme.style_btn(rst_b, Color("#173B66") if _casual_style == 0 else Color("#0E1D34"), UITheme.BORDER_CYAN, 11)
		rst_b.pressed.connect(func(): AudioSynth.play_click(); _casual_style = 0; _sync_avatar_preview(); _render_step())
		body_vb.add_child(rst_b)

		body_vb.add_child(UITheme.make_section_header("GAYA KASUAL HARIAN"))
		var cas_grid := GridContainer.new()
		cas_grid.columns = 5
		cas_grid.add_theme_constant_override("h_separation", 6)
		cas_grid.add_theme_constant_override("v_separation", 6)
		body_vb.add_child(cas_grid)
		for i in range(CharacterStyleCatalog.CASUAL_STYLES.size()):
			var idx: int = i
			var cs: Dictionary = CharacterStyleCatalog.CASUAL_STYLES[idx]
			cas_grid.add_child(CharacterStyleCatalog.build_avatar_preview_tile(
				str(cs["name"]),
				base_app,
				{"casual_style": 1, "outfit_variant": idx},
				true,
				_casual_style == 1 and _outfit_variant == idx,
				func(): _casual_style = 1; _outfit_variant = idx; _sync_avatar_preview(); _render_step(),
				96.0
			))

	elif _custom_tab == "GALA":
		var base_app := _make_wizard_base_app()
		body_vb.add_child(UITheme.make_section_header("SETELAN GALA & AWARD"))
		var gala_grid := GridContainer.new()
		gala_grid.columns = 5
		gala_grid.add_theme_constant_override("h_separation", 6)
		gala_grid.add_theme_constant_override("v_separation", 6)
		body_vb.add_child(gala_grid)
		for i in range(CharacterStyleCatalog.GALA_STYLES.size()):
			var idx: int = i
			var gs: Dictionary = CharacterStyleCatalog.GALA_STYLES[idx]
			gala_grid.add_child(CharacterStyleCatalog.build_avatar_preview_tile(
				str(gs["name"]),
				base_app,
				{"casual_style": 2, "outfit_variant": idx},
				true,
				_casual_style == 2 and _outfit_variant == idx,
				func(): _casual_style = 2; _outfit_variant = idx; _sync_avatar_preview(); _render_step(),
				96.0
			))

func _make_wizard_base_app() -> Dictionary:
	return {
		"primary_color": Color("#1A90E0"),
		"secondary_color": Color("#FFFFFF"),
		"kit_pattern": "solid",
		"skin": _skin_idx,
		"hair_style": _hair_style,
		"hair_color": _hair_col,
		"tip_color": _tip_color,
		"beard": _beard,
		"beard_style": _beard_style,
		"boot_id": _boot_id,
		"sleeve": _sleeve,
		"tattoo_face": _tattoo_face,
		"tattoo_arm": _tattoo_arm,
		"tattoo_leg": _tattoo_leg,
		"headwear": _headwear,
		"eyewear": _eyewear,
		"casual_style": _casual_style,
		"outfit_variant": _outfit_variant,
		"shirt_num": _shirt_num,
	}

func _sync_avatar_preview() -> void:
	if _avatar_preview == null:
		return
	CharacterStyleCatalog.apply_config_to_avatar(_avatar_preview, _make_wizard_base_app(), {})
	_avatar_preview.show_number_badge = true
	_avatar_preview.queue_redraw()

# ---------------------------------------------------------------------------
# STEP 2: TAWARANMU & PILIH KLUBMU (Division 3 Clubs from Any Country!)
# ---------------------------------------------------------------------------
func _render_choose_club() -> void:
	if _offers.is_empty():
		_offers = CareerState.get_starter_offers(_nat_idx)
	if _selected_club.is_empty() and not _offers.is_empty():
		_selected_club = _offers[0]["club"]

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 18
	vb.offset_right = -18
	vb.offset_top = 12
	vb.offset_bottom = -12
	vb.add_theme_constant_override("separation", 8)
	_root_layer.add_child(vb)

	var top_hb := HBoxContainer.new()
	top_hb.add_theme_constant_override("separation", 12)
	vb.add_child(top_hb)
	var hdr := Label.new()
	hdr.text = "TAWARANMU"
	hdr.add_theme_font_override("font", UITheme.get_display_font())
	hdr.add_theme_font_size_override("font_size", 22)
	top_hb.add_child(hdr)
	var sub := Label.new()
	sub.text = "LANGKAH 2 DARI 2 • SIAPA & DI MANA"
	sub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sub.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	sub.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	sub.add_theme_font_size_override("font_size", 11)
	top_hb.add_child(sub)

	vb.add_child(UITheme.make_section_header("TAWARANMU • 3 LOKAL • 2 ASING • BEBAS PILIH DIVISI 3"))

	# Landscape 2-Column Split: Left = Showcase Card | Right = Pager + Actions
	var split_hb := HBoxContainer.new()
	split_hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split_hb.add_theme_constant_override("separation", 14)
	vb.add_child(split_hb)

	# Featured Club Showcase Card (Left)
	var c_col: Color = _selected_club.get("primary", Color("#1A66D2"))
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", UITheme.make_box(c_col.darkened(0.65), UITheme.BORDER_CYAN, 2, 8))
	split_hb.add_child(card)

	var cvb := VBoxContainer.new()
	cvb.alignment = BoxContainer.ALIGNMENT_CENTER
	cvb.add_theme_constant_override("separation", 10)
	card.add_child(cvb)

	var crest := ClubCrest.new()
	crest.custom_minimum_size = Vector2(96, 96)
	crest.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	crest.set_club(int(_selected_club["id"]))
	cvb.add_child(crest)

	var c_name := Label.new()
	c_name.text = str(_selected_club["name"]).to_upper()
	c_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c_name.add_theme_font_override("font", UITheme.get_display_font())
	c_name.add_theme_font_size_override("font_size", 22)
	c_name.add_theme_color_override("font_color", Color("#7CC4FF"))
	cvb.add_child(c_name)

	var nat_d: Dictionary = GameData.nations[int(_selected_club["nation_id"])]
	var c_nat_hb := HBoxContainer.new()
	c_nat_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	c_nat_hb.add_theme_constant_override("separation", 8)
	cvb.add_child(c_nat_hb)
	c_nat_hb.add_child(UITheme.make_flag_rect(int(nat_d["id"]), Vector2(24, 16)))
	var nat_lbl := Label.new()
	nat_lbl.text = "%s  •  OVR KLUB %d" % [str(nat_d["name"]).to_upper(), int(_selected_club["ovr"])]
	c_nat_hb.add_child(nat_lbl)

	var div_lbl := Label.new()
	div_lbl.text = "MULAI: ROTASI  •  DIVISI KE-%d" % int(_selected_club["division"])
	div_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	div_lbl.add_theme_color_override("font_color", Color("#F08C48"))
	cvb.add_child(div_lbl)

	var leg_lbl := Label.new()
	leg_lbl.text = "LEGENDA KLUB: BELUM ADA LEGENDA"
	leg_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	leg_lbl.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	leg_lbl.add_theme_font_size_override("font_size", 11)
	cvb.add_child(leg_lbl)

	# Right Column: Offer Pager & Action Buttons
	var right_vb := VBoxContainer.new()
	right_vb.custom_minimum_size = Vector2(360, 0)
	right_vb.add_theme_constant_override("separation", 10)
	split_hb.add_child(right_vb)

	var nav_hb := HBoxContainer.new()
	right_vb.add_child(nav_hb)
	var prev_o := Button.new()
	prev_o.text = "<"
	prev_o.custom_minimum_size = Vector2(54, 38)
	prev_o.pressed.connect(func():
		AudioSynth.play_click()
		_offer_idx = posmod(_offer_idx - 1, _offers.size())
		_selected_club = _offers[_offer_idx]["club"]
		_render_step()
	)
	var idx_lbl := Label.new()
	var is_custom_pick: bool = (_selected_club != _offers[_offer_idx]["club"]) if not _offers.is_empty() else true
	idx_lbl.text = "KLUB PILIHAN" if is_custom_pick else "%d / %d" % [_offer_idx + 1, _offers.size()]
	idx_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	idx_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var next_o := Button.new()
	next_o.text = ">"
	next_o.custom_minimum_size = Vector2(54, 38)
	next_o.pressed.connect(func():
		AudioSynth.play_click()
		_offer_idx = posmod(_offer_idx + 1, _offers.size())
		_selected_club = _offers[_offer_idx]["club"]
		_render_step()
	)
	nav_hb.add_child(prev_o)
	nav_hb.add_child(idx_lbl)
	nav_hb.add_child(next_o)

	var list_btn := Button.new()
	list_btn.text = "LIHAT 5 TAWARAN (MULAI DARI BAWAH)"
	list_btn.custom_minimum_size = Vector2(0, 44)
	UITheme.style_btn(list_btn, Color("#142840"), UITheme.BORDER_STEEL, 12)
	list_btn.pressed.connect(func(): AudioSynth.play_click(); _open_five_offers_popup())
	right_vb.add_child(list_btn)

	var pick_btn := Button.new()
	pick_btn.text = "PILIH KLUBMU (DIVISI 3 NEGARA LAIN)"
	pick_btn.custom_minimum_size = Vector2(0, 46)
	UITheme.style_btn(pick_btn, Color("#4E2C66"), Color("#B878E8"), 12)
	pick_btn.pressed.connect(func(): AudioSynth.play_click(); _open_club_browser_popup())
	right_vb.add_child(pick_btn)

	var sp_r := Control.new()
	sp_r.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vb.add_child(sp_r)

	var start_b := Button.new()
	start_b.text = "MULAI KARIER"
	start_b.custom_minimum_size = Vector2(0, 52)
	UITheme.style_btn(start_b, Color("#0A1320"), Color("#FFFFFF"), 18)
	start_b.pressed.connect(func():
		AudioSynth.play_click()
		_step = WizardStep.CHOOSE_MODE
		_render_step()
	)
	right_vb.add_child(start_b)

	var back_b := Button.new()
	back_b.text = "< BALIK"
	back_b.custom_minimum_size = Vector2(120, 38)
	back_b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	UITheme.style_btn(back_b, Color("#18332B"), Color("#2E6454"))
	back_b.pressed.connect(func(): AudioSynth.play_click(); _step = WizardStep.CREATE_PLAYER; _render_step())
	right_vb.add_child(back_b)

# ---------------------------------------------------------------------------
# STEP 3: KESULITAN / MODE SELECTION (2x2 Landscape Grid!)
# ---------------------------------------------------------------------------
func _render_choose_mode() -> void:
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 18
	vb.offset_right = -18
	vb.offset_top = 12
	vb.offset_bottom = -12
	vb.add_theme_constant_override("separation", 8)
	_root_layer.add_child(vb)

	var hdr_hb := HBoxContainer.new()
	hdr_hb.add_theme_constant_override("separation", 14)
	vb.add_child(hdr_hb)

	var ttl := Label.new()
	ttl.text = "KESULITAN"
	ttl.add_theme_font_override("font", UITheme.get_display_font())
	ttl.add_theme_font_size_override("font_size", 24)
	hdr_hb.add_child(ttl)

	var sub := Label.new()
	sub.text = "Seberapa keras lawan akan menyulitkanmu • Pilihan ini tidak permanen."
	sub.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	sub.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	hdr_hb.add_child(sub)

	var mode_grid := GridContainer.new()
	mode_grid.columns = 2
	mode_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mode_grid.add_theme_constant_override("h_separation", 12)
	mode_grid.add_theme_constant_override("v_separation", 10)
	vb.add_child(mode_grid)

	var modes := [
		["MUDAH", Color("#255736"), Color("#6EE7B7"), "Lawan berhenti saat kamu membidik dan tak pernah merebut bola. Kiper lebih sering salah."],
		["NORMAL", Color("#6B5F1C"), Color("#FDE047"), "Lawan lebih lambat saat kamu membidik dan merebut bola dari jarak lebih dekat. Kiper agak lebih sering salah."],
		["SULIT", Color("#5C201E"), Color("#FCA5A5"), "Permainan utuh. Kamu ditekan saat membidik, bola bisa direbut dan kiper tak memberi celah."],
		["EKSTREM", Color("#58163A"), Color("#F472B6"), "Bintang dijaga ketat, peluang berkurang satu, lelah tendangan melenceng, lebih banyak blok, direbut tanpa peringatan, semua menuntut lebih."],
	]

	var sel_bg := Color("#173B66")
	var sel_bd := UITheme.BORDER_CYAN
	for m in modes:
		var m_id: String = m[0]
		var is_sel: bool = (_selected_mode == m_id)
		if is_sel:
			sel_bg = m[1]
			sel_bd = m[2]
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.size_flags_vertical = Control.SIZE_EXPAND_FILL
		card.custom_minimum_size = Vector2(0, 128)
		card.clip_contents = true
		var sb_card := UITheme.make_box(m[1], m[2] if is_sel else (m[2] as Color).darkened(0.45), 3 if is_sel else 1, 8)
		sb_card.content_margin_left = 0
		sb_card.content_margin_right = 0
		sb_card.content_margin_top = 0
		sb_card.content_margin_bottom = 0
		card.add_theme_stylebox_override("panel", sb_card)
		mode_grid.add_child(card)

		var layer := Control.new()
		layer.set_anchors_preset(Control.PRESET_FULL_RECT)
		card.add_child(layer)

		var art := ModeArtBanner.new()
		art.mode_id = m_id
		art.is_selected = is_sel
		art.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		art.offset_top = -34
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(art)

		var mv := VBoxContainer.new()
		mv.set_anchors_preset(Control.PRESET_FULL_RECT)
		mv.offset_left = 12
		mv.offset_right = -12
		mv.offset_top = 8
		mv.offset_bottom = -20
		mv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mv.add_theme_constant_override("separation", 3)
		layer.add_child(mv)

		var hdr_m := HBoxContainer.new()
		hdr_m.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mv.add_child(hdr_m)
		var ml1 := Label.new()
		ml1.text = m_id
		ml1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ml1.add_theme_font_override("font", UITheme.get_display_font())
		ml1.add_theme_color_override("font_color", Color.WHITE if is_sel else Color("#E2E8F0"))
		ml1.add_theme_font_size_override("font_size", 18)
		ml1.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hdr_m.add_child(ml1)

		if is_sel:
			var pick_p := PanelContainer.new()
			pick_p.add_theme_stylebox_override("panel", UITheme.make_box(Color(0, 0, 0, 0.45), m[2], 1, 4))
			pick_p.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var pick_l := Label.new()
			pick_l.text = "* DIPILIH"
			pick_l.add_theme_font_size_override("font_size", 10)
			pick_l.add_theme_color_override("font_color", m[2])
			pick_p.add_child(pick_l)
			hdr_m.add_child(pick_p)

		var ml2 := Label.new()
		ml2.text = m[3]
		ml2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ml2.add_theme_font_size_override("font_size", 11)
		ml2.add_theme_color_override("font_color", Color("#F8FAFC") if is_sel else Color("#CBD5E1"))
		ml2.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mv.add_child(ml2)

		var btn := Button.new()
		btn.flat = true
		btn.set_anchors_preset(Control.PRESET_FULL_RECT)
		btn.pressed.connect(func():
			AudioSynth.play_click()
			_selected_mode = m_id
			_render_step()
		)
		layer.add_child(btn)

	var foot := Label.new()
	foot.text = "Bisa kamu ganti kapan saja lewat JEDA > SETELAN, tanpa keluar dari laga."
	foot.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	foot.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	foot.add_theme_font_size_override("font_size", 11)
	vb.add_child(foot)

	var act_hb := HBoxContainer.new()
	act_hb.add_theme_constant_override("separation", 8)
	vb.add_child(act_hb)

	var back_b := Button.new()
	back_b.text = "< BALIK"
	back_b.custom_minimum_size = Vector2(110, 48)
	back_b.pressed.connect(func(): AudioSynth.play_click(); _step = WizardStep.CHOOSE_CLUB; _render_step())
	act_hb.add_child(back_b)

	var go_b := Button.new()
	go_b.text = "MULAI  (%s)" % _selected_mode
	go_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	go_b.custom_minimum_size = Vector2(0, 48)
	UITheme.style_btn(go_b, sel_bg, sel_bd, 18)
	go_b.pressed.connect(func():
		AudioSynth.play_click()
		SettingsManager.set_setting("difficulty", _selected_mode)
		CareerState.start_new_career(
			target_slot,
			_player_name,
			_nat_idx,
			_pos_code,
			str(_selected_club["name"]),
			{
				"skin": _skin_idx,
				"hair_style": _hair_style,
				"hair_color": _hair_col,
				"tip_color": _tip_color,
				"beard": _beard_style > 0,
				"beard_style": _beard_style,
				"boot_id": _boot_id,
				"sleeve": _sleeve,
				"tattoo_face": _tattoo_face,
				"tattoo_arm": _tattoo_arm,
				"tattoo_leg": _tattoo_leg,
				"headwear": _headwear,
				"eyewear": _eyewear,
				"casual_style": _casual_style,
				"outfit_variant": _outfit_variant,
				"shirt_num": _shirt_num,
			}
		)
		_step = WizardStep.SEASON_INTRO
		_render_step()
	)
	act_hb.add_child(go_b)

# ---------------------------------------------------------------------------
# STEP 4: BURSA DIBUKA WELCOME NEWS (matching step_55_shot_6.png!)
# ---------------------------------------------------------------------------
func _render_season_intro() -> void:
	if _selected_club.is_empty():
		if _offers.is_empty():
			_offers = CareerState.get_starter_offers(_nat_idx)
		if not _offers.is_empty():
			_selected_club = _offers[0]["club"]
	var studio_bg := ColorRect.new()
	studio_bg.color = Color("#0D0F24")
	studio_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root_layer.add_child(studio_bg)

	var studio := TextureRect.new()
	studio.texture = load("res://assets/sprites/backgrounds/studio_desk.png")
	studio.anchor_left = 0.0
	studio.anchor_right = 1.0
	studio.anchor_top = 0.25
	studio.anchor_bottom = 0.65
	studio.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_root_layer.add_child(studio)

	var desk_line_top := ColorRect.new()
	desk_line_top.color = UITheme.ACCENT_GOLD
	desk_line_top.anchor_left = 0.0
	desk_line_top.anchor_right = 1.0
	desk_line_top.anchor_top = 0.25
	desk_line_top.anchor_bottom = 0.25
	desk_line_top.offset_bottom = 2
	_root_layer.add_child(desk_line_top)

	var desk_line_bot := ColorRect.new()
	desk_line_bot.color = UITheme.ACCENT_CYAN
	desk_line_bot.anchor_left = 0.0
	desk_line_bot.anchor_right = 1.0
	desk_line_bot.anchor_top = 0.65
	desk_line_bot.anchor_bottom = 0.65
	desk_line_bot.offset_bottom = 2
	_root_layer.add_child(desk_line_bot)

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 150
	vb.offset_right = -150
	vb.offset_top = 28
	vb.offset_bottom = -20
	vb.add_theme_constant_override("separation", 12)
	_root_layer.add_child(vb)

	var tag := PanelContainer.new()
	tag.add_theme_stylebox_override("panel", UITheme.make_box(Color("#12263C"), UITheme.ACCENT_GOLD, 1, 3))
	vb.add_child(tag)
	var thb := HBoxContainer.new()
	thb.add_theme_constant_override("separation", 10)
	tag.add_child(thb)
	var cr := ClubCrest.new()
	cr.custom_minimum_size = Vector2(36, 36)
	cr.set_club(int(_selected_club["id"]))
	thb.add_child(cr)
	var tl := Label.new()
	tl.text = "BURSA DIBUKA\n%s" % str(_selected_club["name"]).to_upper()
	thb.add_child(tl)

	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UITheme.make_box(Color("#0A1728"), UITheme.ACCENT_GOLD, 2, 4))
	vb.add_child(box)
	var bvb := VBoxContainer.new()
	bvb.add_theme_constant_override("separation", 8)
	box.add_child(bvb)
	var bn_hdr := Label.new()
	bn_hdr.text = "● BREAKING NEWS • BURSA DIBUKA"
	bn_hdr.add_theme_color_override("font_color", UITheme.ACCENT_RED)
	bvb.add_child(bn_hdr)
	var msg := Label.new()
	msg.text = "%s resmi bergabung ke %s!\nLevel 1 • Uang Awal $ 5.000 • Mode %s" % [_player_name.to_upper(), str(_selected_club["name"]), _selected_mode]
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bvb.add_child(msg)

	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(sp)

	var cont_b := Button.new()
	cont_b.text = "LANJUT"
	cont_b.custom_minimum_size = Vector2(0, 50)
	UITheme.style_btn(cont_b, Color("#0C192C"), UITheme.ACCENT_GOLD, 18)
	cont_b.pressed.connect(func():
		AudioSynth.play_click()
		career_created.emit(target_slot)
		queue_free()
	)
	vb.add_child(cont_b)

# ---------------------------------------------------------------------------
# SUB-POPUPS: NEGARAMU (55 Countries), LIHAT 5 TAWARAN, & PILIH KLUBMU (Div 3)
# ---------------------------------------------------------------------------
func _clear_sub_modals() -> void:
	for c in _sub_modal_layer.get_children():
		c.queue_free()
	_sub_modal_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _open_nation_picker(for_player: bool) -> void:
	_clear_sub_modals()
	_sub_modal_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Color("#060D17")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_sub_modal_layer.add_child(bg)

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 14
	vb.offset_right = -14
	vb.offset_top = 18
	vb.offset_bottom = -16
	vb.add_theme_constant_override("separation", 8)
	_sub_modal_layer.add_child(vb)

	var hdr := Label.new()
	hdr.text = "NEGARAMU" if for_player else "PILIH NEGARA LIGA"
	hdr.add_theme_font_override("font", UITheme.get_display_font())
	hdr.add_theme_font_size_override("font_size", 20)
	vb.add_child(hdr)

	var search := LineEdit.new()
	search.placeholder_text = "CARI NEGARA..."
	vb.add_child(search)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	scroll.add_child(grid)

	var populate := func(filter_q: String):
		for c in grid.get_children():
			c.queue_free()
		var q := filter_q.strip_edges().to_lower()
		for nat in GameData.nations:
			if not q.is_empty() and not str(nat["name"]).to_lower().contains(q):
				continue
			var nb := Button.new()
			nb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			nb.custom_minimum_size = Vector2(0, 62)
			var nid := int(nat["id"])
			UITheme.style_btn(nb, Color("#122640"), UITheme.BORDER_CYAN if (_nat_idx == nid) else UITheme.BORDER_STEEL, 10)
			nb.pressed.connect(func():
				AudioSynth.play_click()
				if for_player:
					_nat_idx = nid
				else:
					_browser_nat_idx = nid
				_clear_sub_modals()
				if for_player:
					_render_step()
				else:
					_open_club_browser_popup()
			)
			grid.add_child(nb)

			var nvb := VBoxContainer.new()
			nvb.set_anchors_preset(Control.PRESET_FULL_RECT)
			nvb.alignment = BoxContainer.ALIGNMENT_CENTER
			nvb.mouse_filter = Control.MOUSE_FILTER_IGNORE
			nb.add_child(nvb)
			var fl := UITheme.make_flag_rect(nid, Vector2(28, 18))
			fl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			fl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			nvb.add_child(fl)
			var nl := Label.new()
			nl.text = str(nat["name"]).to_upper()
			nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			nl.add_theme_font_size_override("font_size", 10)
			nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			nvb.add_child(nl)

	search.text_changed.connect(func(t: String): populate.call(t))
	populate.call("")

	var cancel := Button.new()
	cancel.text = "BATAL"
	cancel.custom_minimum_size = Vector2(0, 42)
	cancel.pressed.connect(func(): AudioSynth.play_click(); _clear_sub_modals())
	vb.add_child(cancel)

func _open_five_offers_popup() -> void:
	_clear_sub_modals()
	_sub_modal_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Color("#060D17")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_sub_modal_layer.add_child(bg)

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 14
	vb.offset_right = -14
	vb.offset_top = 18
	vb.offset_bottom = -16
	vb.add_theme_constant_override("separation", 10)
	_sub_modal_layer.add_child(vb)

	var hdr := Label.new()
	hdr.text = "TAWARANMU (5 KLUB DIVISI 3)"
	hdr.add_theme_font_override("font", UITheme.get_display_font())
	hdr.add_theme_font_size_override("font_size", 18)
	vb.add_child(hdr)

	var grid := GridContainer.new()
	grid.columns = 5
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	vb.add_child(grid)

	for i in range(_offers.size()):
		var cl: Dictionary = _offers[i]["club"]
		grid.add_child(_make_club_tile(cl, func():
			_offer_idx = i
			_selected_club = cl
			_clear_sub_modals()
			_render_step()
		))

	var cancel := Button.new()
	cancel.text = "BATAL"
	cancel.custom_minimum_size = Vector2(0, 42)
	cancel.pressed.connect(func(): AudioSynth.play_click(); _clear_sub_modals())
	vb.add_child(cancel)

func _open_club_browser_popup() -> void:
	_clear_sub_modals()
	_sub_modal_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.color = Color("#060D17")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_sub_modal_layer.add_child(bg)

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 14
	vb.offset_right = -14
	vb.offset_top = 18
	vb.offset_bottom = -16
	vb.add_theme_constant_override("separation", 8)
	_sub_modal_layer.add_child(vb)

	var hdr := Label.new()
	hdr.text = "PILIH KLUBMU"
	hdr.add_theme_font_override("font", UITheme.get_display_font())
	hdr.add_theme_font_size_override("font_size", 22)
	vb.add_child(hdr)

	# Country bar with GANTI
	var c_bar := PanelContainer.new()
	vb.add_child(c_bar)
	var chb := HBoxContainer.new()
	chb.add_theme_constant_override("separation", 8)
	c_bar.add_child(chb)
	chb.add_child(UITheme.make_flag_rect(_browser_nat_idx, Vector2(26, 18)))
	var cnl := Label.new()
	cnl.text = str(GameData.nations[_browser_nat_idx]["name"]).to_upper()
	cnl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chb.add_child(cnl)
	var chg_b := Button.new()
	chg_b.text = "GANTI NEGARA"
	UITheme.style_btn(chg_b, Color("#173B66"), UITheme.BORDER_CYAN, 11)
	chg_b.pressed.connect(func(): AudioSynth.play_click(); _open_nation_picker(false))
	chb.add_child(chg_b)

	# Division Selector (DIVISI KE-3 highlighted & default for starting Div 3 clubs across nations!)
	var dhb := HBoxContainer.new()
	dhb.add_theme_constant_override("separation", 4)
	vb.add_child(dhb)
	for d in [1, 2, 3]:
		var db := Button.new()
		db.text = "DIVISI KE-%d" % d
		db.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var is_d: bool = (_browser_div == d)
		UITheme.style_btn(db, Color("#88521E") if is_d else Color("#111B2B"), UITheme.ACCENT_GOLD if is_d else UITheme.BORDER_STEEL, 11)
		db.pressed.connect(func(): AudioSynth.play_click(); _browser_div = d; _open_club_browser_popup())
		dhb.add_child(db)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	scroll.add_child(grid)

	for cl in GameData.get_clubs_in_division(_browser_nat_idx, _browser_div):
		grid.add_child(_make_club_tile(cl, func():
			_selected_club = cl
			_clear_sub_modals()
			_render_step()
		))

	var cancel := Button.new()
	cancel.text = "BATAL"
	cancel.custom_minimum_size = Vector2(0, 42)
	cancel.pressed.connect(func(): AudioSynth.play_click(); _clear_sub_modals())
	vb.add_child(cancel)

func _make_club_tile(cl: Dictionary, on_pick: Callable) -> Button:
	var btn := Button.new()
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, 102)
	var p_col: Color = cl.get("primary", Color("#1A66D2"))
	UITheme.style_btn(btn, p_col.darkened(0.55), UITheme.BORDER_CYAN if _selected_club.get("id", -1) == cl["id"] else UITheme.BORDER_STEEL, 10)
	btn.pressed.connect(func(): AudioSynth.play_click(); on_pick.call())

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 4
	vb.offset_right = -4
	vb.offset_top = 4
	vb.offset_bottom = -4
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(vb)

	var cr := ClubCrest.new()
	cr.custom_minimum_size = Vector2(46, 46)
	cr.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cr.set_club(int(cl["id"]))
	vb.add_child(cr)

	var nl := Label.new()
	nl.text = str(cl["name"]).to_upper()
	nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nl.add_theme_font_size_override("font_size", 9)
	nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(nl)
	return btn

class ModeArtBanner extends Control:
	var mode_id: String = "NORMAL"
	var is_selected: bool = false
	var _t: float = 0.0

	func _process(delta: float) -> void:
		if not visible:
			return
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var w := size.x
		var h := size.y
		if w <= 2 or h <= 2:
			return
		var speed: float = 2.8 if is_selected else 1.4
		if mode_id == "MUDAH":
			draw_rect(Rect2(0, h - 10, w, 10), Color("#1E462A"))
			var x: float = 0.0
			var idx: int = 0
			while x < w:
				var sway: float = sin(_t * speed + float(idx) * 0.7) * 2.0
				var bh: float = 10.0 + float(idx % 3) * 4.0
				draw_rect(Rect2(x + sway, h - bh, 5, bh), Color("#4ADE80") if idx % 2 == 0 else Color("#22C55E"))
				if idx % 7 == 0:
					draw_rect(Rect2(x + sway + 1, h - bh - 3, 3, 3), Color("#FFFBEB"))
				x += 9.0
				idx += 1
		elif mode_id == "NORMAL":
			draw_rect(Rect2(0, h - 10, w, 10), Color("#4D4210"))
			var x2: float = 0.0
			var idx2: int = 0
			while x2 < w:
				var sway2: float = sin(_t * speed + float(idx2) * 0.8) * 1.8
				var bh2: float = 9.0 + float((idx2 * 2) % 4) * 3.0
				draw_rect(Rect2(x2 + sway2, h - bh2, 5, bh2), Color("#FACC15") if idx2 % 2 == 0 else Color("#CA8A04"))
				if idx2 % 6 == 0:
					var my: float = fmod(_t * 14.0 + float(idx2) * 5.0, 22.0)
					draw_rect(Rect2(x2 + 2, h - 10 - my, 2, 2), Color("#FEF08A", 0.75))
				x2 += 10.0
				idx2 += 1
		elif mode_id == "SULIT":
			draw_rect(Rect2(0, h - 11, w, 11), Color("#381210"))
			var x3: float = 0.0
			var idx3: int = 0
			while x3 < w:
				var rock_h: float = 7.0 + float(idx3 % 3) * 4.0
				draw_rect(Rect2(x3, h - rock_h, 8, rock_h), Color("#7F1D1D") if idx3 % 2 == 0 else Color("#991B1B"))
				if idx3 % 3 == 0:
					var rise: float = fmod(_t * 18.0 + float(idx3) * 7.0, 26.0)
					draw_rect(Rect2(x3 + sin(_t * 3.0 + float(idx3)) * 2.0, h - 8 - rise, 3, 3), Color("#FB923C"))
				x3 += 11.0
				idx3 += 1
		else:
			# EKSTREM: Dynamic pixel-art multi-layered flames rising across the bottom!
			draw_rect(Rect2(0, h - 8, w, 8), Color("#7C131C"))
			var x4: float = 0.0
			var idx4: int = 0
			while x4 < w:
				var pulse: float = sin(_t * (5.2 if is_selected else 3.2) + float(idx4) * 0.9)
				var fh: float = 16.0 + pulse * 7.0 + float((idx4 * 3) % 9)
				draw_rect(Rect2(x4, h - fh, 8, fh), Color("#DC2626"))
				draw_rect(Rect2(x4 + 2, h - fh * 0.78, 5, fh * 0.78), Color("#F97316"))
				draw_rect(Rect2(x4 + 3, h - fh * 0.48, 3, fh * 0.48), Color("#FDE047"))
				if idx4 % 2 == 0 and pulse > 0.2:
					draw_rect(Rect2(x4 + 3, h - fh - 5, 2, 3), Color("#FEF08A"))
				x4 += 8.0
				idx4 += 1
