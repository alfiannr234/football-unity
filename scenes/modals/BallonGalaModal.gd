extends Control

# Theatrical October Last-Week Gala Ceremony:
# 1st Ceremony: BALLON D'OR
# 2nd Ceremony: PEMAIN MUDA TERBAIK (U-21)
# Both follow identical 4-act broadcast choreography driven purely by _process(delta):
#   ACT_INTRO     -> Gala opening curtains & host introduction
#   ACT_ROLL_CALL -> Host announces bottom-10 nominees sequentially (#10 down to #2)
#   ACT_SUSPENSE  -> Alternating left/right/center stage spotlights + "peraih ... tahun XXXX......"
#   ACT_REVEAL    -> Spotlights snap & lock onto #1 winner + 1-year Stats & Trophies Card

signal finished

const ACT_INTRO: int = 0
const ACT_ROLL_CALL: int = 1
const ACT_SUSPENSE: int = 2
const ACT_REVEAL: int = 3

var _gala_data: Dictionary = {}
var _ceremony_idx: int = 0  # 0 = Ballon d'Or, 1 = Pemain Muda Terbaik (U-21)
var _act: int = ACT_INTRO
var _act_t: float = 0.0
var _global_t: float = 0.0
var _fast_mode: bool = false
var _show_top10_on_reveal: bool = false

var _current_list: Array[Dictionary] = []
var _roll_call_index: int = 9  # Starts at index 9 (#10) down to index 1 (#2)
var _roll_step_t: float = 0.0
var _suspense_beat_idx: int = -1
var _flash_alpha: float = 0.0
var _prev_bgm_override: String = ""

# Stage & UI references
var _stage_canvas: GalaStageCanvas
var _fg_overlay: GalaForegroundOverlay
var _badge_lbl: Label
var _title_lbl: Label
var _sub_lbl: Label
var _speed_btn: Button
var _skip_btn: Button

var _host_avatar: PixelAvatar
var _spotlight_avatar: PixelAvatar
var _spotlight_tag_panel: PanelContainer
var _spotlight_tag_lbl: Label

var _roll_panel: PanelContainer
var _roll_rows_vb: VBoxContainer
var _roll_row_nodes: Array[PanelContainer] = []

var _winner_card: PanelContainer
var _winner_card_vb: VBoxContainer

var _dialogue_panel: PanelContainer
var _speaker_lbl: Label
var _dialogue_lbl: Label
var _toggle_board_btn: Button
var _next_btn: Button

func configure(gala_data: Dictionary) -> void:
	_gala_data = gala_data.duplicate(true)

func _ready() -> void:
	theme = UITheme.build_theme()
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_prev_bgm_override = AudioSynth.bgm_track_override
	AudioSynth.bgm_track_override = "MALAM JUARA"

	if _gala_data.is_empty() and CareerState.has_active_career:
		_gala_data = CareerState.get_ballon_gala_preview_data()

	_build_ui()
	_start_ceremony(0)

func _exit_tree() -> void:
	AudioSynth.bgm_track_override = _prev_bgm_override

func _is_youth_ceremony() -> bool:
	return _ceremony_idx == 1

func _accent_col() -> Color:
	return Color("#38BDF8") if _is_youth_ceremony() else Color("#F5C430")

func _accent_soft() -> Color:
	return Color("#BAE6FD") if _is_youth_ceremony() else Color("#FDE68A")

func _ceremony_title_short() -> String:
	return "PEMAIN MUDA TERBAIK (U-21)" if _is_youth_ceremony() else "BALLON D'OR"

func _build_ui() -> void:
	# 1. Procedural Theatre Stage Canvas (curtains, spotlights, stage floor, pedestal, audience, confetti)
	_stage_canvas = GalaStageCanvas.new()
	_stage_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stage_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stage_canvas)

	# 2. Tuxedo Host PixelAvatar at stage-left podium (x=60..146, y=198..326)
	_host_avatar = PixelAvatar.new()
	_host_avatar.full_body = true
	_host_avatar.position = Vector2(56, 194)
	_host_avatar.size = Vector2(88, 132)
	_host_avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var host_club: Dictionary = {
		"primary": Color("#111827"),
		"secondary": Color("#F8FAFC"),
		"shorts": Color("#0B101B"),
		"pattern": "solid",
	}
	_host_avatar.configure_from_seed(4219, host_club, 1)
	_host_avatar.casual_style = 2  # Gala tuxedo
	_host_avatar.hair_style = 2
	_host_avatar.hair_idx = 5  # Distinguished silver-gray host hair
	_host_avatar.anim_mode = "TALK"
	add_child(_host_avatar)

	# 3. Center-Stage Spotlighted Nominee / Winner Avatar (x=196..328, y=156..340)
	_spotlight_avatar = PixelAvatar.new()
	_spotlight_avatar.full_body = true
	_spotlight_avatar.position = Vector2(198, 152)
	_spotlight_avatar.size = Vector2(126, 186)
	_spotlight_avatar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_spotlight_avatar.visible = false
	add_child(_spotlight_avatar)

	# 3b. Foreground Stage FX (Host Lectern in front of host torso, front spotlight sheen, confetti, flash)
	_fg_overlay = GalaForegroundOverlay.new()
	_fg_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fg_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fg_overlay)

	# Stage nameplate underneath spotlighted player
	_spotlight_tag_panel = PanelContainer.new()
	_spotlight_tag_panel.position = Vector2(150, 342)
	_spotlight_tag_panel.size = Vector2(224, 34)
	_spotlight_tag_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_spotlight_tag_panel.visible = false
	add_child(_spotlight_tag_panel)

	_spotlight_tag_lbl = Label.new()
	_spotlight_tag_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_spotlight_tag_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_spotlight_tag_lbl.clip_text = true
	_spotlight_tag_lbl.add_theme_font_override("font", UITheme.get_display_font())
	_spotlight_tag_lbl.add_theme_font_size_override("font_size", 11)
	_spotlight_tag_panel.add_child(_spotlight_tag_lbl)

	# 4. Top Broadcast Bar (y=8..54)
	var top_bar := PanelContainer.new()
	top_bar.position = Vector2(16, 8)
	top_bar.size = Vector2(928, 48)
	var top_sb := UITheme.make_box(Color(0.03, 0.06, 0.13, 0.88), Color("#385075"), 1, 6)
	top_sb.content_margin_left = 12
	top_sb.content_margin_right = 12
	top_sb.content_margin_top = 4
	top_sb.content_margin_bottom = 4
	top_bar.add_theme_stylebox_override("panel", top_sb)
	add_child(top_bar)

	var top_hb := HBoxContainer.new()
	top_hb.add_theme_constant_override("separation", 10)
	top_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	top_bar.add_child(top_hb)

	var badge_box := PanelContainer.new()
	badge_box.custom_minimum_size = Vector2(162, 28)
	badge_box.add_theme_stylebox_override("panel", UITheme.make_box(Color("#1A263D"), Color("#F5C430"), 1, 4))
	_badge_lbl = Label.new()
	_badge_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_badge_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_badge_lbl.add_theme_font_override("font", UITheme.get_display_font())
	_badge_lbl.add_theme_font_size_override("font_size", 10)
	badge_box.add_child(_badge_lbl)
	top_hb.add_child(badge_box)

	var ttl_vb := VBoxContainer.new()
	ttl_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ttl_vb.alignment = BoxContainer.ALIGNMENT_CENTER
	ttl_vb.add_theme_constant_override("separation", 0)
	top_hb.add_child(ttl_vb)

	_title_lbl = Label.new()
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_lbl.add_theme_font_override("font", UITheme.get_display_font())
	_title_lbl.add_theme_font_size_override("font_size", 14)
	ttl_vb.add_child(_title_lbl)

	_sub_lbl = Label.new()
	_sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sub_lbl.add_theme_font_size_override("font_size", 10)
	_sub_lbl.add_theme_color_override("font_color", Color("#94A3B8"))
	ttl_vb.add_child(_sub_lbl)

	_speed_btn = Button.new()
	_speed_btn.text = "KECEPATAN 1x"
	_speed_btn.custom_minimum_size = Vector2(114, 30)
	_style_gala_btn(_speed_btn, Color("#132642"), Color("#3A5885"), 10, Color("#E2E8F0"))
	_speed_btn.pressed.connect(_on_toggle_speed)
	top_hb.add_child(_speed_btn)

	_skip_btn = Button.new()
	_skip_btn.text = "LEWATI >>"
	_skip_btn.custom_minimum_size = Vector2(92, 30)
	_style_gala_btn(_skip_btn, Color("#241E14"), Color("#A17B24"), 10, Color("#FDE68A"))
	_skip_btn.pressed.connect(_on_skip_to_suspense_or_reveal)
	top_hb.add_child(_skip_btn)

	# 5. Right-Side On-Stage Top-10 Nominees Roll-Call Board (x=392..938, y=64..378)
	_roll_panel = PanelContainer.new()
	_roll_panel.position = Vector2(392, 64)
	_roll_panel.size = Vector2(546, 314)
	var rp_sb := UITheme.make_box(Color(0.04, 0.08, 0.16, 0.90), Color("#344D73"), 1, 6)
	rp_sb.content_margin_left = 10
	rp_sb.content_margin_right = 10
	rp_sb.content_margin_top = 6
	rp_sb.content_margin_bottom = 6
	_roll_panel.add_theme_stylebox_override("panel", rp_sb)
	add_child(_roll_panel)

	var roll_outer := VBoxContainer.new()
	roll_outer.add_theme_constant_override("separation", 3)
	_roll_panel.add_child(roll_outer)

	var roll_hdr := HBoxContainer.new()
	roll_hdr.add_theme_constant_override("separation", 6)
	roll_outer.add_child(roll_hdr)

	var rh_l := Label.new()
	rh_l.text = "DAFTAR 10 NOMINASI RESMI (DIPANGGIL #10 -> #1)"
	rh_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rh_l.add_theme_font_override("font", UITheme.get_display_font())
	rh_l.add_theme_font_size_override("font_size", 10)
	rh_l.add_theme_color_override("font_color", Color("#94A3B8"))
	roll_hdr.add_child(rh_l)

	var rh_r := Label.new()
	rh_r.text = "G/A  |  POIN"
	rh_r.add_theme_font_override("font", UITheme.get_display_font())
	rh_r.add_theme_font_size_override("font_size", 10)
	rh_r.add_theme_color_override("font_color", Color("#94A3B8"))
	roll_hdr.add_child(rh_r)

	_roll_rows_vb = VBoxContainer.new()
	_roll_rows_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_roll_rows_vb.add_theme_constant_override("separation", 2)
	roll_outer.add_child(_roll_rows_vb)

	# 6. Right-Side Winner 1-Year Statistics & Trophies Card (x=392..938, y=64..378)
	_winner_card = PanelContainer.new()
	_winner_card.position = Vector2(392, 64)
	_winner_card.size = Vector2(546, 314)
	_winner_card.visible = false
	add_child(_winner_card)

	_winner_card_vb = VBoxContainer.new()
	_winner_card_vb.add_theme_constant_override("separation", 8)
	_winner_card.add_child(_winner_card_vb)

	# 7. Bottom Broadcast Host Dialogue & Control Bar (x=16..944, y=388..528)
	_dialogue_panel = PanelContainer.new()
	_dialogue_panel.position = Vector2(16, 388)
	_dialogue_panel.size = Vector2(928, 140)
	var dp_sb := UITheme.make_box(Color(0.03, 0.07, 0.14, 0.94), Color("#F5C430"), 2, 8)
	dp_sb.content_margin_left = 16
	dp_sb.content_margin_right = 16
	dp_sb.content_margin_top = 10
	dp_sb.content_margin_bottom = 10
	_dialogue_panel.add_theme_stylebox_override("panel", dp_sb)
	add_child(_dialogue_panel)

	var dlg_hb := HBoxContainer.new()
	dlg_hb.add_theme_constant_override("separation", 14)
	_dialogue_panel.add_child(dlg_hb)

	var dlg_left := VBoxContainer.new()
	dlg_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dlg_left.add_theme_constant_override("separation", 5)
	dlg_hb.add_child(dlg_left)

	_speaker_lbl = Label.new()
	_speaker_lbl.text = "PEMBAWA ACARA GALA  •  PANGGUNG UTAMA"
	_speaker_lbl.add_theme_font_override("font", UITheme.get_display_font())
	_speaker_lbl.add_theme_font_size_override("font_size", 11)
	dlg_left.add_child(_speaker_lbl)

	_dialogue_lbl = Label.new()
	_dialogue_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_dialogue_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogue_lbl.add_theme_font_override("font", UITheme.get_display_font())
	_dialogue_lbl.add_theme_font_size_override("font_size", 13)
	_dialogue_lbl.add_theme_color_override("font_color", Color("#F8FAFC"))
	dlg_left.add_child(_dialogue_lbl)

	var dlg_right := VBoxContainer.new()
	dlg_right.custom_minimum_size = Vector2(238, 0)
	dlg_right.alignment = BoxContainer.ALIGNMENT_CENTER
	dlg_right.add_theme_constant_override("separation", 8)
	dlg_hb.add_child(dlg_right)

	_toggle_board_btn = Button.new()
	_toggle_board_btn.text = "LIHAT TOP 10"
	_toggle_board_btn.custom_minimum_size = Vector2(236, 36)
	_toggle_board_btn.visible = false
	_style_gala_btn(_toggle_board_btn, Color("#132540"), Color("#3B6396"), 11, Color("#E2E8F0"))
	_toggle_board_btn.pressed.connect(_on_toggle_reveal_view)
	dlg_right.add_child(_toggle_board_btn)

	_next_btn = Button.new()
	_next_btn.text = "LANJUT >>"
	_next_btn.custom_minimum_size = Vector2(236, 48)
	_next_btn.visible = false
	_next_btn.pressed.connect(_on_next_pressed)
	dlg_right.add_child(_next_btn)

func _style_gala_btn(btn: Button, bg: Color, border: Color, font_sz: int, txt_col: Color) -> void:
	var n := StyleBoxFlat.new()
	n.bg_color = bg
	n.border_color = border
	n.set_border_width_all(1)
	n.border_width_bottom = 3
	n.set_corner_radius_all(5)
	n.content_margin_left = 10
	n.content_margin_right = 10
	n.content_margin_top = 6
	n.content_margin_bottom = 6
	var h: StyleBoxFlat = n.duplicate()
	h.bg_color = bg.lightened(0.14)
	h.border_color = Color("#F8FAFC")
	var pr: StyleBoxFlat = n.duplicate()
	pr.bg_color = bg.darkened(0.08)
	btn.add_theme_stylebox_override("normal", n)
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_stylebox_override("pressed", pr)
	btn.add_theme_stylebox_override("focus", h)
	btn.add_theme_font_override("font", UITheme.get_display_font())
	btn.add_theme_font_size_override("font_size", font_sz)
	btn.add_theme_color_override("font_color", txt_col)
	btn.add_theme_color_override("font_hover_color", Color("#FFFFFF"))

func _clear_container(c: Node) -> void:
	while c.get_child_count() > 0:
		var ch: Node = c.get_child(0)
		c.remove_child(ch)
		ch.queue_free()

func _start_ceremony(idx: int) -> void:
	_ceremony_idx = clampi(idx, 0, 1)
	_act = ACT_INTRO
	_act_t = 0.0
	_roll_step_t = 0.0
	_suspense_beat_idx = -1
	_flash_alpha = 0.0
	_show_top10_on_reveal = false

	var raw_arr: Array = _gala_data.get("youth_top10" if _is_youth_ceremony() else "ballon_top10", [])
	_current_list.clear()
	for item in raw_arr:
		if item is Dictionary:
			_current_list.append((item as Dictionary).duplicate(true))

	_roll_call_index = maxi(1, _current_list.size() - 1)  # Starts from #10 (idx 9) down to #2 (idx 1)

	var cal_yr: int = int(_gala_data.get("year", 2026))
	var acc: Color = _accent_col()
	var soft: Color = _accent_soft()

	_badge_lbl.text = "SESI 2/2 • U-21" if _is_youth_ceremony() else "SESI 1/2 • BALLON D'OR"
	_badge_lbl.add_theme_color_override("font_color", acc)

	_title_lbl.text = "MALAM GALA PEMAIN MUDA TERBAIK (U-21) %d" % cal_yr if _is_youth_ceremony() else "MALAM GALA BALLON D'OR %d" % cal_yr
	_title_lbl.add_theme_color_override("font_color", acc)

	_sub_lbl.text = str(_gala_data.get("month_label", "OKTOBER %d • MINGGU TERAKHIR" % cal_yr))
	_speaker_lbl.add_theme_color_override("font_color", soft)

	var dp_sb := UITheme.make_box(Color(0.03, 0.07, 0.14, 0.94), acc, 2, 8)
	dp_sb.content_margin_left = 16
	dp_sb.content_margin_right = 16
	dp_sb.content_margin_top = 10
	dp_sb.content_margin_bottom = 10
	_dialogue_panel.add_theme_stylebox_override("panel", dp_sb)

	_spotlight_avatar.visible = false
	_spotlight_tag_panel.visible = false
	_winner_card.visible = false
	_roll_panel.visible = true
	_toggle_board_btn.visible = false
	_next_btn.visible = false
	_skip_btn.visible = true
	_host_avatar.anim_mode = "TALK"

	_stage_canvas.set_theme_mode(_is_youth_ceremony())
	_stage_canvas.set_stage_mode(ACT_INTRO, 0.0)
	_fg_overlay.set_theme_mode(_is_youth_ceremony())
	_fg_overlay.reset_confetti()
	_fg_overlay.set_fx_state(ACT_INTRO, 0.0, 0.0)

	_rebuild_roll_call_slots()
	_dialogue_lbl.text = "Selamat datang di Malam Gala Oktober %d! Pembawa acara akan memanggil 10 nominasi %s secara berurutan dari peringkat ke-10 hingga sang pemenang." % [cal_yr, _ceremony_title_short()]
	AudioSynth.play_note(440.0 if _is_youth_ceremony() else 392.0, 0.22)

func _rebuild_roll_call_slots() -> void:
	_clear_container(_roll_rows_vb)
	_roll_row_nodes.clear()
	var total: int = mini(10, _current_list.size())
	for rank_i in range(total):
		var slot := PanelContainer.new()
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.size_flags_vertical = Control.SIZE_EXPAND_FILL
		slot.custom_minimum_size = Vector2(0, 26)
		var sb := UITheme.make_box(Color("#0A1324"), Color("#1E3352"), 1, 4)
		sb.content_margin_left = 8
		sb.content_margin_right = 8
		sb.content_margin_top = 2
		sb.content_margin_bottom = 2
		slot.add_theme_stylebox_override("panel", sb)

		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 6)
		slot.add_child(hb)

		var rk := Label.new()
		rk.text = "#%d" % (rank_i + 1)
		rk.custom_minimum_size = Vector2(30, 0)
		rk.add_theme_font_override("font", UITheme.get_display_font())
		rk.add_theme_font_size_override("font_size", 11)
		rk.add_theme_color_override("font_color", _accent_col() if rank_i == 0 else Color("#475569"))
		hb.add_child(rk)

		var ph := Label.new()
		ph.text = "??? PERAIH %s ???" % _ceremony_title_short() if rank_i == 0 else "MENUNGGU PEMANGGILAN..."
		ph.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ph.add_theme_font_override("font", UITheme.get_display_font())
		ph.add_theme_font_size_override("font_size", 10)
		ph.add_theme_color_override("font_color", _accent_soft() if rank_i == 0 else Color("#334155"))
		hb.add_child(ph)

		_roll_rows_vb.add_child(slot)
		_roll_row_nodes.append(slot)

func _populate_roll_row(idx: int, highlight_active: bool) -> void:
	if idx < 0 or idx >= _roll_row_nodes.size() or idx >= _current_list.size():
		return
	var entry: Dictionary = _current_list[idx]
	var slot: PanelContainer = _roll_row_nodes[idx]
	_clear_container(slot)

	var is_u: bool = bool(entry.get("is_user", false))
	var is_first: bool = (idx == 0)
	var acc: Color = _accent_col()
	var bg_col: Color = Color("#13233C")
	var bd_col: Color = Color("#2C486E")
	if is_first:
		bg_col = Color("#17344E") if _is_youth_ceremony() else Color("#3B2D0E")
		bd_col = acc
	elif highlight_active:
		bg_col = Color("#1A3554")
		bd_col = acc
	elif is_u:
		bg_col = Color("#12312B")
		bd_col = Color("#3AD656")

	var sb := UITheme.make_box(bg_col, bd_col, 2 if (highlight_active or is_first) else 1, 4)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	slot.add_theme_stylebox_override("panel", sb)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	slot.add_child(hb)

	var rk := Label.new()
	rk.text = "#%d" % (idx + 1)
	rk.custom_minimum_size = Vector2(30, 0)
	rk.add_theme_font_override("font", UITheme.get_display_font())
	rk.add_theme_font_size_override("font_size", 11)
	rk.add_theme_color_override("font_color", acc if (is_first or highlight_active) else (Color("#3AD656") if is_u else Color("#CBD5E1")))
	hb.add_child(rk)

	hb.add_child(UITheme.make_flag_rect(int(entry.get("nat", 1)), Vector2(18, 12)))

	var cr := ClubCrest.new()
	cr.custom_minimum_size = Vector2(16, 16)
	cr.set_club(int(entry.get("club_id", 0)))
	cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(cr)

	var nm := Label.new()
	var base_nm: String = str(entry.get("name", "Pemain"))
	nm.text = ("%s [KAMU]" % base_nm) if is_u else base_nm
	nm.custom_minimum_size = Vector2(158, 0)
	nm.clip_text = true
	nm.add_theme_font_override("font", UITheme.get_display_font())
	nm.add_theme_font_size_override("font_size", 11)
	nm.add_theme_color_override("font_color", acc if is_first else (Color("#4ADE80") if is_u else Color("#F8FAFC")))
	hb.add_child(nm)

	var cl := Label.new()
	cl.text = "%s (%dth)" % [str(entry.get("club_name", "Klub")), int(entry.get("age", 20))]
	cl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cl.clip_text = true
	cl.add_theme_font_size_override("font_size", 10)
	cl.add_theme_color_override("font_color", Color("#94A3B8"))
	hb.add_child(cl)

	var ga := Label.new()
	ga.text = "%dG/%dA" % [int(entry.get("goals", 0)), int(entry.get("assists", 0))]
	ga.custom_minimum_size = Vector2(58, 0)
	ga.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ga.add_theme_font_size_override("font_size", 10)
	ga.add_theme_color_override("font_color", Color("#CBD5E1"))
	hb.add_child(ga)

	var pts := Label.new()
	pts.text = "%d" % int(entry.get("points", 0))
	pts.custom_minimum_size = Vector2(36, 0)
	pts.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pts.add_theme_font_override("font", UITheme.get_display_font())
	pts.add_theme_font_size_override("font_size", 11)
	pts.add_theme_color_override("font_color", acc if (is_first or highlight_active) else Color("#E2E8F0"))
	hb.add_child(pts)

func _configure_stage_avatar(entry: Dictionary, is_winner: bool) -> void:
	var is_u: bool = bool(entry.get("is_user", false))
	var cid: int = int(entry.get("club_id", 0))
	var c_dict: Dictionary = GameData.clubs[cid] if (cid >= 0 and cid < GameData.clubs.size()) else GameData.clubs[0]
	if is_u:
		_spotlight_avatar.configure_from_career()
	else:
		_spotlight_avatar.configure_from_seed(int(entry.get("seed", 101)), c_dict, 10)
	_spotlight_avatar.casual_style = 2  # Formal Gala Tuxedo on stage
	_spotlight_avatar.show_mvp_trophy = is_winner
	_spotlight_avatar.anim_mode = "MVP" if is_winner else "CHEER"
	_spotlight_avatar.visible = true

	var acc: Color = _accent_col()
	var tag_sb := UITheme.make_box(Color(0.05, 0.09, 0.18, 0.94), acc, 2 if is_winner else 1, 5)
	tag_sb.content_margin_left = 8
	tag_sb.content_margin_right = 8
	tag_sb.content_margin_top = 4
	tag_sb.content_margin_bottom = 4
	_spotlight_tag_panel.add_theme_stylebox_override("panel", tag_sb)
	var rk: int = int(entry.get("rank", 1))
	_spotlight_tag_lbl.text = "#%d  %s" % [rk, str(entry.get("name", "Pemain")).to_upper()]
	_spotlight_tag_lbl.add_theme_color_override("font_color", acc if is_winner else Color("#F8FAFC"))
	_spotlight_tag_panel.visible = true

func _build_winner_stats_card(winner: Dictionary) -> void:
	_clear_container(_winner_card_vb)
	var cal_yr: int = int(_gala_data.get("year", 2026))
	var acc: Color = _accent_col()
	var soft: Color = _accent_soft()
	var is_u: bool = bool(winner.get("is_user", false))

	var card_bg: Color = Color(0.04, 0.11, 0.21, 0.95) if _is_youth_ceremony() else Color(0.11, 0.09, 0.04, 0.95)
	var wc_sb := UITheme.make_box(card_bg, acc, 2, 8)
	wc_sb.content_margin_left = 14
	wc_sb.content_margin_right = 14
	wc_sb.content_margin_top = 10
	wc_sb.content_margin_bottom = 10
	_winner_card.add_theme_stylebox_override("panel", wc_sb)

	# 1. Crown Ribbon Header
	var hdr := HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 8)
	_winner_card_vb.add_child(hdr)

	var ribbon := Label.new()
	ribbon.text = "PERAIH %s %d" % [_ceremony_title_short(), cal_yr]
	ribbon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ribbon.add_theme_font_override("font", UITheme.get_display_font())
	ribbon.add_theme_font_size_override("font_size", 12)
	ribbon.add_theme_color_override("font_color", acc)
	hdr.add_child(ribbon)

	var pts_pill := PanelContainer.new()
	pts_pill.add_theme_stylebox_override("panel", UITheme.make_box(Color("#132033"), acc, 1, 4))
	var pts_l := Label.new()
	pts_l.text = " %d POIN " % int(winner.get("points", 0))
	pts_l.add_theme_font_override("font", UITheme.get_display_font())
	pts_l.add_theme_font_size_override("font_size", 11)
	pts_l.add_theme_color_override("font_color", soft)
	pts_pill.add_child(pts_l)
	hdr.add_child(pts_pill)

	# 2. Winner Identity Box
	var id_box := PanelContainer.new()
	var id_sb := UITheme.make_box(Color(0.05, 0.09, 0.17, 0.90), Color("#2C466D"), 1, 6)
	id_sb.content_margin_left = 10
	id_sb.content_margin_right = 10
	id_sb.content_margin_top = 7
	id_sb.content_margin_bottom = 7
	id_box.add_theme_stylebox_override("panel", id_sb)
	_winner_card_vb.add_child(id_box)

	var id_hb := HBoxContainer.new()
	id_hb.add_theme_constant_override("separation", 10)
	id_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	id_box.add_child(id_hb)

	var cr := ClubCrest.new()
	cr.custom_minimum_size = Vector2(36, 36)
	cr.set_club(int(winner.get("club_id", 0)))
	cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	id_hb.add_child(cr)

	var name_vb := VBoxContainer.new()
	name_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_vb.add_theme_constant_override("separation", 2)
	id_hb.add_child(name_vb)

	var nm_row := HBoxContainer.new()
	nm_row.add_theme_constant_override("separation", 6)
	name_vb.add_child(nm_row)

	nm_row.add_child(UITheme.make_flag_rect(int(winner.get("nat", 1)), Vector2(22, 14)))

	var w_nm := Label.new()
	w_nm.text = ("%s  [KAMU!]" % str(winner.get("name", "Pemain")).to_upper()) if is_u else str(winner.get("name", "Pemain")).to_upper()
	w_nm.add_theme_font_override("font", UITheme.get_display_font())
	w_nm.add_theme_font_size_override("font_size", 15)
	w_nm.add_theme_color_override("font_color", Color("#4ADE80") if is_u else Color("#FFFFFF"))
	nm_row.add_child(w_nm)

	var meta_l := Label.new()
	meta_l.text = "%s  •  POS %s  •  USIA %d TH  •  OVR %d" % [
		str(winner.get("club_name", "Klub")).to_upper(),
		str(winner.get("pos", "ST")),
		int(winner.get("age", 20)),
		int(winner.get("ovr", 85)),
	]
	meta_l.add_theme_font_size_override("font_size", 11)
	meta_l.add_theme_color_override("font_color", Color("#CBD5E1"))
	name_vb.add_child(meta_l)

	# 3. 1-Year Rolling Stats Section (Goals, Assists, Matches since previous October Gala)
	var st_title := Label.new()
	st_title.text = "STATISTIK 1 TAHUN TERAKHIR (SEJAK NOMINASI OKTOBER LALU)"
	st_title.add_theme_font_override("font", UITheme.get_display_font())
	st_title.add_theme_font_size_override("font_size", 10)
	st_title.add_theme_color_override("font_color", soft)
	_winner_card_vb.add_child(st_title)

	var stats_hb := HBoxContainer.new()
	stats_hb.add_theme_constant_override("separation", 10)
	_winner_card_vb.add_child(stats_hb)

	var stat_defs: Array = [
		["PERTANDINGAN", str(int(winner.get("matches", 0))), Color("#38BDF8")],
		["GOL", str(int(winner.get("goals", 0))), Color("#F5C430")],
		["ASSIST", str(int(winner.get("assists", 0))), Color("#4ADE80")],
	]
	for sd in stat_defs:
		var tile := PanelContainer.new()
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tile.custom_minimum_size = Vector2(0, 64)
		var t_col: Color = sd[2]
		var t_sb := UITheme.make_box(Color("#0B1628"), t_col, 1, 6)
		t_sb.border_width_top = 3
		t_sb.content_margin_top = 6
		t_sb.content_margin_bottom = 6
		tile.add_theme_stylebox_override("panel", t_sb)

		var tvb := VBoxContainer.new()
		tvb.alignment = BoxContainer.ALIGNMENT_CENTER
		tvb.add_theme_constant_override("separation", 2)
		tile.add_child(tvb)

		var v_lbl := Label.new()
		v_lbl.text = str(sd[1])
		v_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v_lbl.add_theme_font_override("font", UITheme.get_display_font())
		v_lbl.add_theme_font_size_override("font_size", 22)
		v_lbl.add_theme_color_override("font_color", t_col)
		tvb.add_child(v_lbl)

		var k_lbl := Label.new()
		k_lbl.text = str(sd[0])
		k_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		k_lbl.add_theme_font_override("font", UITheme.get_display_font())
		k_lbl.add_theme_font_size_override("font_size", 10)
		k_lbl.add_theme_color_override("font_color", Color("#94A3B8"))
		tvb.add_child(k_lbl)

		stats_hb.add_child(tile)

	# 4. Trophies Won in Past 1 Year
	var tr_hdr := Label.new()
	var tr_arr: Array = winner.get("trophies", [])
	tr_hdr.text = "PIALA DIRAIH DALAM 1 TAHUN TERAKHIR (%d GELAR)" % tr_arr.size()
	tr_hdr.add_theme_font_override("font", UITheme.get_display_font())
	tr_hdr.add_theme_font_size_override("font_size", 10)
	tr_hdr.add_theme_color_override("font_color", soft)
	_winner_card_vb.add_child(tr_hdr)

	var tr_box := PanelContainer.new()
	tr_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var tr_sb := UITheme.make_box(Color("#091222"), Color("#294164"), 1, 6)
	tr_sb.content_margin_left = 10
	tr_sb.content_margin_right = 10
	tr_sb.content_margin_top = 8
	tr_sb.content_margin_bottom = 8
	tr_box.add_theme_stylebox_override("panel", tr_sb)
	_winner_card_vb.add_child(tr_box)

	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 6)
	flow.add_theme_constant_override("v_separation", 6)
	tr_box.add_child(flow)

	if tr_arr.is_empty():
		var empty_l := Label.new()
		empty_l.text = "Belum ada gelar tim resmi dalam 1 tahun terakhir (menang lewat performa individu)."
		empty_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_l.add_theme_font_size_override("font_size", 11)
		empty_l.add_theme_color_override("font_color", Color("#94A3B8"))
		flow.add_child(empty_l)
	else:
		var shown_cap: int = mini(6, tr_arr.size())
		for ti in range(shown_cap):
			var pill := PanelContainer.new()
			var p_sb := UITheme.make_box(Color("#2D220D"), Color("#EAB308"), 1, 4)
			p_sb.content_margin_left = 8
			p_sb.content_margin_right = 8
			p_sb.content_margin_top = 4
			p_sb.content_margin_bottom = 4
			pill.add_theme_stylebox_override("panel", p_sb)

			var phb := HBoxContainer.new()
			phb.add_theme_constant_override("separation", 5)
			pill.add_child(phb)

			var ico := GalaTrophyMiniIcon.new()
			ico.custom_minimum_size = Vector2(12, 12)
			ico.mouse_filter = Control.MOUSE_FILTER_IGNORE
			phb.add_child(ico)

			var pl := Label.new()
			pl.text = str(tr_arr[ti]).to_upper()
			pl.add_theme_font_override("font", UITheme.get_display_font())
			pl.add_theme_font_size_override("font_size", 10)
			pl.add_theme_color_override("font_color", Color("#FDE68A"))
			phb.add_child(pl)

			flow.add_child(pill)

		if tr_arr.size() > shown_cap:
			var more_l := Label.new()
			more_l.text = "+%d GELAR LAINNYA" % (tr_arr.size() - shown_cap)
			more_l.add_theme_font_override("font", UITheme.get_display_font())
			more_l.add_theme_font_size_override("font_size", 10)
			more_l.add_theme_color_override("font_color", Color("#94A3B8"))
			flow.add_child(more_l)

func _enter_act_roll_call() -> void:
	_act = ACT_ROLL_CALL
	_act_t = 0.0
	_roll_step_t = 0.0
	_announce_next_bottom_nominee()

func _announce_next_bottom_nominee() -> void:
	if _roll_call_index < 1 or _current_list.is_empty():
		_enter_act_suspense()
		return
	var idx: int = _roll_call_index
	if idx < _current_list.size():
		# Demote highlight of previously called slot
		if idx + 1 < _current_list.size():
			_populate_roll_row(idx + 1, false)
		_populate_roll_row(idx, true)
		var entry: Dictionary = _current_list[idx]
		_configure_stage_avatar(entry, false)
		var rk: int = idx + 1
		var extra: String = " Wakil kita masuk 10 besar dunia!" if bool(entry.get("is_user", false)) else ""
		_dialogue_lbl.text = "Peringkat ke-%d: %s (%s) - %d Gol, %d Assist, %d Poin!%s" % [
			rk,
			str(entry.get("name", "Pemain")),
			str(entry.get("club_name", "Klub")),
			int(entry.get("goals", 0)),
			int(entry.get("assists", 0)),
			int(entry.get("points", 0)),
			extra,
		]
		var pitch: float = 330.0 + float(10 - rk) * 32.0
		AudioSynth.play_note(pitch, 0.14)
	_roll_call_index -= 1

func _enter_act_suspense() -> void:
	_act = ACT_SUSPENSE
	_act_t = 0.0
	_suspense_beat_idx = -1
	if _current_list.size() > 1:
		_populate_roll_row(1, false)
	_spotlight_avatar.visible = false
	_spotlight_tag_panel.visible = true
	var acc: Color = _accent_col()
	var tag_sb := UITheme.make_box(Color(0.06, 0.09, 0.18, 0.94), acc, 2, 5)
	tag_sb.content_margin_left = 8
	tag_sb.content_margin_right = 8
	tag_sb.content_margin_top = 4
	tag_sb.content_margin_bottom = 4
	_spotlight_tag_panel.add_theme_stylebox_override("panel", tag_sb)
	_spotlight_tag_lbl.add_theme_color_override("font_color", acc)
	_host_avatar.anim_mode = "TALK"
	_update_suspense_dialogue(0.0)

func _update_suspense_dialogue(t: float) -> void:
	var cal_yr: int = int(_gala_data.get("year", 2026))
	var dot_cnt: int = clampi(1 + int(floor(t * 2.6)), 1, 6)
	var dots: String = ".".repeat(dot_cnt)
	if _is_youth_ceremony():
		_dialogue_lbl.text = "Lampu panggung menyorot... Dan pemain muda terbaik (U-21) tahun %d adalah%s" % [cal_yr, dots]
	else:
		_dialogue_lbl.text = "Lampu panggung menyorot... Dan pemain peraih Ballon d'Or tahun %d adalah%s" % [cal_yr, dots]

	# Cycle top finalists on stage marquee while spotlights sweep alternately
	if not _current_list.is_empty():
		var pool_n: int = mini(3, _current_list.size())
		var pick_i: int = int(floor(t * 7.5)) % pool_n
		_spotlight_tag_lbl.text = "?  %s  ?" % str(_current_list[pick_i].get("name", "FINALIS")).to_upper()

func _enter_act_reveal() -> void:
	_act = ACT_REVEAL
	_act_t = 0.0
	_flash_alpha = 0.72
	_show_top10_on_reveal = false
	_skip_btn.visible = false

	if not _current_list.is_empty():
		# Populate all remaining slots so toggling "LIHAT TOP 10" shows complete #1..#10
		for i in range(mini(10, _current_list.size())):
			_populate_roll_row(i, i == 0)
		var winner: Dictionary = _current_list[0]
		_configure_stage_avatar(winner, true)
		_build_winner_stats_card(winner)

		var cal_yr: int = int(_gala_data.get("year", 2026))
		if bool(winner.get("is_user", false)):
			_dialogue_lbl.text = "SEJARAH TERCIPTA! KAMU, %s (%s), RESMI DINOBATKAN SEBAGAI PERAIH %s %d!" % [
				str(winner.get("name", "Pemain")).to_upper(),
				str(winner.get("club_name", "Klub")),
				_ceremony_title_short(),
				cal_yr,
			]
		else:
			_dialogue_lbl.text = "SELAMAT! %s (%s) RESMI MERAIH %s %d! Lihat catatan gol, assist, laga, dan piala selama 1 tahun terakhir." % [
				str(winner.get("name", "Pemain")).to_upper(),
				str(winner.get("club_name", "Klub")),
				_ceremony_title_short(),
				cal_yr,
			]

	_roll_panel.visible = false
	_winner_card.visible = true
	_host_avatar.anim_mode = "CHEER"
	_fg_overlay.spawn_confetti_burst()

	_toggle_board_btn.visible = true
	_toggle_board_btn.text = "LIHAT TOP 10"
	_next_btn.visible = true
	if not _is_youth_ceremony():
		_next_btn.text = "LANJUT: PEMAIN MUDA U-21 >>"
		_style_gala_btn(_next_btn, Color("#15406B"), Color("#38BDF8"), 11, Color("#E0F2FE"))
	else:
		_next_btn.text = "SELESAI • TUTUP GALA"
		_style_gala_btn(_next_btn, Color("#523C10"), Color("#F5C430"), 12, Color("#FEF08A"))

	AudioSynth.play_goal()
	AudioSynth.play_achievement()

func _process(delta: float) -> void:
	var dt: float = minf(delta, 0.1)
	_global_t += dt
	_act_t += dt
	if _flash_alpha > 0.0:
		_flash_alpha = maxf(0.0, _flash_alpha - dt * 1.8)

	var speed_mult: float = 2.8 if _fast_mode else 1.0

	match _act:
		ACT_INTRO:
			var intro_dur: float = 1.45 / speed_mult
			if _act_t >= intro_dur:
				_enter_act_roll_call()
		ACT_ROLL_CALL:
			_roll_step_t += dt * speed_mult
			var step_dur: float = 0.72
			if _roll_step_t >= step_dur:
				_roll_step_t -= step_dur
				_announce_next_bottom_nominee()
		ACT_SUSPENSE:
			var susp_dur: float = 3.1 / (1.8 if _fast_mode else 1.0)
			_update_suspense_dialogue(_act_t)
			# Rhythmic alternating spotlight pulse tones
			var beat_i: int = int(floor(_act_t * 3.2))
			if beat_i != _suspense_beat_idx and _act_t < susp_dur - 0.15:
				_suspense_beat_idx = beat_i
				var f: float = 260.0 + float(beat_i % 2) * 70.0 + float(beat_i) * 14.0
				AudioSynth.play_note(f, 0.09)
			if _act_t >= susp_dur:
				_enter_act_reveal()
		ACT_REVEAL:
			pass

	_stage_canvas.set_stage_mode(_act, _global_t)
	_fg_overlay.set_fx_state(_act, _global_t, _flash_alpha)
	_fg_overlay.step_fx(dt)

func _on_toggle_speed() -> void:
	AudioSynth.play_click()
	_fast_mode = not _fast_mode
	_speed_btn.text = "KECEPATAN 3x" if _fast_mode else "KECEPATAN 1x"
	if _fast_mode:
		_style_gala_btn(_speed_btn, Color("#1E466E"), Color("#38BDF8"), 10, Color("#FFFFFF"))
	else:
		_style_gala_btn(_speed_btn, Color("#132642"), Color("#3A5885"), 10, Color("#E2E8F0"))

func _on_skip_to_suspense_or_reveal() -> void:
	AudioSynth.play_click()
	if _act == ACT_INTRO or _act == ACT_ROLL_CALL:
		# Reveal #10..#2 immediately and jump into the iconic alternating spotlight suspense!
		for i in range(1, mini(10, _current_list.size())):
			_populate_roll_row(i, false)
		_roll_call_index = 0
		_enter_act_suspense()
	elif _act == ACT_SUSPENSE:
		_enter_act_reveal()

func _on_toggle_reveal_view() -> void:
	AudioSynth.play_click()
	_show_top10_on_reveal = not _show_top10_on_reveal
	_roll_panel.visible = _show_top10_on_reveal
	_winner_card.visible = not _show_top10_on_reveal
	_toggle_board_btn.text = "KARTU PEMENANG" if _show_top10_on_reveal else "LIHAT TOP 10"

func _on_next_pressed() -> void:
	AudioSynth.play_click()
	if not _is_youth_ceremony():
		_start_ceremony(1)
	else:
		finished.emit()
		queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var kc: int = (event as InputEventKey).keycode
		if kc == KEY_SPACE or kc == KEY_ENTER:
			if _act == ACT_REVEAL and _next_btn.visible:
				_on_next_pressed()
				get_viewport().set_input_as_handled()
		elif kc == KEY_ESCAPE:
			if _act == ACT_REVEAL and _is_youth_ceremony():
				_on_next_pressed()
				get_viewport().set_input_as_handled()

# Public inspection helper for automated smoke testing
func get_gala_state() -> Dictionary:
	return {
		"ceremony_idx": _ceremony_idx,
		"act": _act,
		"nominee_count": _current_list.size(),
		"roll_call_index": _roll_call_index,
		"winner_card_visible": _winner_card != null and _winner_card.visible,
		"spotlight_avatar_visible": _spotlight_avatar != null and _spotlight_avatar.visible,
		"spotlight_locked": _act == ACT_REVEAL,
		"next_btn_visible": _next_btn != null and _next_btn.visible,
	}

func advance_step_for_test() -> void:
	if _act == ACT_INTRO:
		_enter_act_roll_call()
	elif _act == ACT_ROLL_CALL:
		if _roll_call_index >= 1:
			_announce_next_bottom_nominee()
		else:
			_enter_act_suspense()
	elif _act == ACT_SUSPENSE:
		_enter_act_reveal()
	elif _act == ACT_REVEAL:
		_on_next_pressed()

# ==============================================================================
# PROCEDURAL GALA THEATRE STAGE CANVAS (Spotlights, Curtains, Pedestal, Confetti)
# ==============================================================================
class GalaStageCanvas extends Control:
	var _is_youth: bool = false
	var _act: int = ACT_INTRO
	var _t: float = 0.0

	func set_theme_mode(youth: bool) -> void:
		_is_youth = youth
		queue_redraw()

	func set_stage_mode(act: int, t_val: float) -> void:
		_act = act
		_t = t_val
		queue_redraw()

	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		var acc: Color = Color("#38BDF8") if _is_youth else Color("#F5C430")
		var bg_top: Color = Color("#040B1A") if _is_youth else Color("#0A0812")
		var bg_mid: Color = Color("#08172E") if _is_youth else Color("#151120")

		# 1. Deep Gala Auditorium Backdrop
		draw_rect(Rect2(0, 0, w, h), bg_top)
		draw_rect(Rect2(0, 56, w, 248), bg_mid)

		# Subtle illuminated gala backdrop ribs / gold-cyan deco arches
		for i in range(9):
			var ax: float = 84.0 + float(i) * 98.0
			draw_line(Vector2(ax, 58), Vector2(ax, 298), Color(acc.r, acc.g, acc.b, 0.08), 1.5)
		draw_arc(Vector2(260.0, 220.0), 118.0, PI, TAU, 36, Color(acc.r, acc.g, acc.b, 0.14), 2.0)
		draw_arc(Vector2(260.0, 220.0), 92.0, PI, TAU, 32, Color(acc.r, acc.g, acc.b, 0.10), 1.5)

		# 2. Glossy Gala Stage Floor & Award Carpet
		var stage_top: float = 296.0
		var stage_bot: float = 384.0
		draw_rect(Rect2(0, stage_top, w, stage_bot - stage_top), Color("#0C1322"))
		draw_rect(Rect2(0, stage_top, w, 3.0), Color(acc.r, acc.g, acc.b, 0.55))
		for si in range(7):
			var sy: float = stage_top + 10.0 + float(si) * 11.0
			draw_line(Vector2(44, sy), Vector2(w - 44, sy), Color(1, 1, 1, 0.035), 1.0)

		# Center Award Pedestal Circle under spotlight player (x=261, y=336)
		var ped_c := Vector2(261.0, 336.0)
		draw_colored_polygon(_ellipse_pts(ped_c, 82.0, 18.0), Color("#18253C"))
		draw_polyline(_ellipse_pts(ped_c, 82.0, 18.0, true), Color(acc.r, acc.g, acc.b, 0.85 if _act == ACT_REVEAL else 0.45), 2.5)
		draw_colored_polygon(_ellipse_pts(ped_c, 58.0, 12.0), Color(acc.r, acc.g, acc.b, 0.22 if _act == ACT_REVEAL else 0.08))

		# 3. Overhead Lighting Truss & 3 Physical Lamps
		var rigs: Array[Vector2] = [Vector2(150, 58), Vector2(261, 58), Vector2(372, 58)]
		draw_line(Vector2(48, 56), Vector2(w - 48, 56), Color("#24334C"), 4.0)
		for rp in rigs:
			draw_rect(Rect2(rp.x - 10, rp.y - 4, 20, 9), Color("#334155"))
			draw_circle(Vector2(rp.x, rp.y + 6), 4.0, acc)

		# 4. Rear Volumetric Spotlights (behind avatars for depth)
		if _act == ACT_SUSPENSE:
			draw_rect(Rect2(0, 56, w, h - 56), Color(0.0, 0.01, 0.04, 0.42))
			var sweep_a: float = sin(_t * 5.6)
			var sweep_b: float = sin(_t * 5.6 + PI)  # Counter-phase (selang-seling)
			var alt_left_a: float = 0.14 + 0.26 * maxf(0.0, sin(_t * 7.2))
			var alt_right_a: float = 0.14 + 0.26 * maxf(0.0, -sin(_t * 7.2))
			var alt_mid_a: float = 0.10 + 0.16 * maxf(0.0, cos(_t * 7.2))

			var target_l := Vector2(261.0 + sweep_a * 145.0, 342.0)
			var target_r := Vector2(261.0 + sweep_b * 145.0, 342.0)
			var target_c := Vector2(261.0 + sin(_t * 8.4) * 95.0, 338.0)

			_draw_spotlight_beam(Vector2(150, 60), target_l, 56.0, Color(acc.r, acc.g, acc.b, alt_left_a))
			_draw_spotlight_beam(Vector2(372, 60), target_r, 56.0, Color(1.0, 0.96, 0.80, alt_right_a))
			_draw_spotlight_beam(Vector2(261, 60), target_c, 48.0, Color(acc.r, acc.g, acc.b, alt_mid_a))

			draw_colored_polygon(_ellipse_pts(target_l, 48.0, 12.0), Color(acc.r, acc.g, acc.b, alt_left_a * 1.15))
			draw_colored_polygon(_ellipse_pts(target_r, 48.0, 12.0), Color(1.0, 0.96, 0.80, alt_right_a * 1.15))

			var bg_tx: float = 640.0 + sin(_t * 4.8) * 190.0
			_draw_spotlight_beam(Vector2(540, 60), Vector2(bg_tx, 360.0), 64.0, Color(acc.r, acc.g, acc.b, 0.12))
			_draw_spotlight_beam(Vector2(820, 60), Vector2(640.0 - sin(_t * 4.8) * 190.0, 360.0), 64.0, Color(1.0, 0.94, 0.78, 0.11))

		elif _act == ACT_REVEAL:
			# ALL 3 SPOTLIGHTS CONVERGE & LOCK ONTO WINNER AT (261, 338)
			var pulse: float = 0.92 + 0.08 * sin(_t * 4.2)
			var lock_pt := Vector2(261.0, 338.0)
			_draw_spotlight_beam(Vector2(150, 60), lock_pt, 62.0, Color(acc.r, acc.g, acc.b, 0.22 * pulse))
			_draw_spotlight_beam(Vector2(261, 60), lock_pt, 74.0, Color(1.0, 0.98, 0.88, 0.28 * pulse))
			_draw_spotlight_beam(Vector2(372, 60), lock_pt, 62.0, Color(acc.r, acc.g, acc.b, 0.22 * pulse))
			draw_colored_polygon(_ellipse_pts(lock_pt, 78.0, 18.0), Color(acc.r, acc.g, acc.b, 0.36 * pulse))
			draw_colored_polygon(_ellipse_pts(lock_pt, 46.0, 10.0), Color(1.0, 1.0, 0.92, 0.45 * pulse))
			draw_circle(Vector2(261.0, 232.0), 70.0, Color(acc.r, acc.g, acc.b, 0.14 * pulse))
		else:
			var sway: float = sin(_t * 1.6) * 28.0
			_draw_spotlight_beam(Vector2(150, 60), Vector2(102.0, 336.0), 42.0, Color(1.0, 0.96, 0.84, 0.12))
			_draw_spotlight_beam(Vector2(261, 60), Vector2(261.0 + sway * 0.4, 336.0), 58.0, Color(acc.r, acc.g, acc.b, 0.15))
			_draw_spotlight_beam(Vector2(372, 60), Vector2(261.0 - sway * 0.4, 336.0), 46.0, Color(acc.r, acc.g, acc.b, 0.10))

		# 5. Velvet Side Stage Curtains
		var curt_col: Color = Color("#102247") if _is_youth else Color("#4C101B")
		var curt_hi: Color = Color("#1B366B") if _is_youth else Color("#6E1828")
		var open_px: float = 0.0 if _act != ACT_INTRO else clampf((0.6 - _t) * 26.0, 0.0, 18.0)
		var cw: float = 42.0 + open_px
		draw_rect(Rect2(0, 54, cw, h - 54), curt_col)
		draw_rect(Rect2(w - cw, 54, cw, h - 54), curt_col)
		for fi in range(3):
			draw_rect(Rect2(float(fi) * 12.0 + 4.0, 54, 5.0, h - 54), curt_hi)
			draw_rect(Rect2(w - cw + float(fi) * 12.0 + 4.0, 54, 5.0, h - 54), curt_hi)
		draw_line(Vector2(cw, 54), Vector2(cw, h), Color(acc.r, acc.g, acc.b, 0.6), 2.0)
		draw_line(Vector2(w - cw, 54), Vector2(w - cw, h), Color(acc.r, acc.g, acc.b, 0.6), 2.0)

		# 6. Audience Silhouettes & Paparazzi Camera Flashes along stage lip
		for ai in range(34):
			var ax: float = 46.0 + float(ai) * 26.5
			var ah: float = 16.0 + float((ai * 7) % 7)
			draw_circle(Vector2(ax, 386.0 - ah), 6.5, Color("#050912"))
			draw_rect(Rect2(ax - 9.0, 386.0 - ah + 5.0, 18.0, ah), Color("#050912"))
			if _act == ACT_SUSPENSE or _act == ACT_REVEAL:
				var f_wave: float = sin(_t * 9.0 + float(ai) * 2.37)
				if f_wave > 0.965:
					draw_circle(Vector2(ax, 382.0 - ah), 5.0, Color(1.0, 1.0, 1.0, 0.85))
					draw_circle(Vector2(ax, 382.0 - ah), 11.0, Color(acc.r, acc.g, acc.b, 0.32))

	func _draw_spotlight_beam(origin: Vector2, target: Vector2, spread: float, col: Color) -> void:
		var poly := PackedVector2Array([
			Vector2(origin.x - 7.0, origin.y),
			Vector2(origin.x + 7.0, origin.y),
			Vector2(target.x + spread, target.y),
			Vector2(target.x - spread, target.y),
		])
		draw_colored_polygon(poly, col)

	func _ellipse_pts(center: Vector2, rx: float, ry: float, close_loop: bool = false) -> PackedVector2Array:
		var pts := PackedVector2Array()
		var segs: int = 28
		for i in range(segs + (1 if close_loop else 0)):
			var a: float = (float(i) / float(segs)) * TAU
			pts.append(Vector2(center.x + cos(a) * rx, center.y + sin(a) * ry))
		return pts

class GalaForegroundOverlay extends Control:
	var _is_youth: bool = false
	var _act: int = ACT_INTRO
	var _t: float = 0.0
	var _flash_alpha: float = 0.0
	var _confetti: Array[Dictionary] = []

	func set_theme_mode(youth: bool) -> void:
		_is_youth = youth
		queue_redraw()

	func set_fx_state(act: int, t_val: float, flash_a: float) -> void:
		_act = act
		_t = t_val
		_flash_alpha = flash_a
		queue_redraw()

	func reset_confetti() -> void:
		_confetti.clear()

	func spawn_confetti_burst() -> void:
		_confetti.clear()
		var cols: Array[Color] = []
		if _is_youth:
			cols = [Color("#38BDF8"), Color("#F5C430"), Color("#E0F2FE"), Color("#4ADE80"), Color("#FDE68A")]
		else:
			cols = [Color("#F5C430"), Color("#FDE68A"), Color("#FFFFFF"), Color("#FB923C"), Color("#38BDF8")]
		for i in range(68):
			_confetti.append({
				"x": randf_range(64.0, 896.0),
				"y": randf_range(-160.0, 60.0),
				"vx": randf_range(-28.0, 28.0),
				"vy": randf_range(58.0, 145.0),
				"w": randf_range(4.0, 8.0),
				"h": randf_range(3.0, 6.0),
				"col": cols[i % cols.size()],
				"phase": randf_range(0.0, TAU),
			})

	func step_fx(dt: float) -> void:
		if _confetti.is_empty():
			return
		for c in _confetti:
			c["x"] = float(c["x"]) + (float(c["vx"]) + sin(_t * 3.5 + float(c["phase"])) * 18.0) * dt
			c["y"] = float(c["y"]) + float(c["vy"]) * dt
			if float(c["y"]) > 530.0:
				c["y"] = randf_range(-40.0, -6.0)
				c["x"] = randf_range(64.0, 896.0)

	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		var acc: Color = Color("#38BDF8") if _is_youth else Color("#F5C430")

		# 1. Host Gala Lectern drawn IN FRONT of host's lower torso/legs
		draw_rect(Rect2(76, 272, 48, 66), Color("#151D2E"))
		draw_rect(Rect2(76, 272, 48, 66), Color(acc.r, acc.g, acc.b, 0.78), false, 2.0)
		draw_rect(Rect2(70, 266, 60, 8), Color("#26324A"))
		draw_rect(Rect2(70, 266, 60, 8), acc, false, 1.5)
		draw_circle(Vector2(100, 302), 10.0, Color(acc.r, acc.g, acc.b, 0.28))
		draw_circle(Vector2(100, 302), 5.0, acc)
		draw_line(Vector2(114, 266), Vector2(107, 250), Color("#CBD5E1"), 2.0)
		draw_circle(Vector2(106, 249), 3.0, Color("#F8FAFC"))

		# Trophy Pedestal beside host while winner has not yet received it
		if _act != ACT_REVEAL:
			draw_rect(Rect2(140, 294, 30, 44), Color("#162033"))
			draw_rect(Rect2(140, 294, 30, 44), Color(acc.r, acc.g, acc.b, 0.58), false, 1.5)
			_draw_stage_trophy(Vector2(155, 280), 1.0, acc)

		# 2. Translucent Front Spotlight Wash over winner / stage during Suspense & Reveal
		if _act == ACT_REVEAL:
			var pulse: float = 0.90 + 0.10 * sin(_t * 4.2)
			var beam := PackedVector2Array([
				Vector2(252.0, 60.0),
				Vector2(270.0, 60.0),
				Vector2(328.0, 340.0),
				Vector2(194.0, 340.0),
			])
			draw_colored_polygon(beam, Color(acc.r, acc.g, acc.b, 0.10 * pulse))

		# 3. Falling Gala Confetti in front of stage
		for c in _confetti:
			draw_rect(Rect2(float(c["x"]), float(c["y"]), float(c["w"]), float(c["h"])), c["col"])

		# 4. Peak Reveal Camera Flash Overlay
		if _flash_alpha > 0.005:
			draw_rect(Rect2(0, 0, w, h), Color(1.0, 0.98, 0.90, _flash_alpha))

	func _draw_stage_trophy(pos: Vector2, sc: float, col: Color) -> void:
		draw_rect(Rect2(pos.x - 8 * sc, pos.y + 6 * sc, 16 * sc, 8 * sc), Color("#1E293B"))
		draw_rect(Rect2(pos.x - 6 * sc, pos.y + 2 * sc, 12 * sc, 5 * sc), Color("#92400E"))
		if _is_youth:
			var star := PackedVector2Array()
			for i in range(10):
				var ang: float = -PI * 0.5 + float(i) * PI / 5.0
				var r: float = (12.0 if i % 2 == 0 else 5.2) * sc
				star.append(Vector2(pos.x + cos(ang) * r, pos.y - 8.0 * sc + sin(ang) * r))
			draw_colored_polygon(star, col)
			draw_circle(Vector2(pos.x, pos.y - 8.0 * sc), 3.5 * sc, Color("#F5C430"))
		else:
			draw_circle(Vector2(pos.x, pos.y - 8.0 * sc), 10.5 * sc, Color("#D99B16"))
			draw_circle(Vector2(pos.x - 2.0 * sc, pos.y - 10.0 * sc), 7.5 * sc, Color("#FDE047"))
			draw_arc(Vector2(pos.x, pos.y - 8.0 * sc), 10.5 * sc, 0.0, TAU, 20, Color("#FEF9C3"), 1.5)

class GalaTrophyMiniIcon extends Control:
	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		draw_rect(Rect2(w * 0.25, h * 0.78, w * 0.50, h * 0.18), Color("#F59E0B"))
		draw_rect(Rect2(w * 0.42, h * 0.56, w * 0.16, h * 0.24), Color("#FBBF24"))
		draw_circle(Vector2(w * 0.50, h * 0.36), minf(w, h) * 0.32, Color("#FDE047"))
