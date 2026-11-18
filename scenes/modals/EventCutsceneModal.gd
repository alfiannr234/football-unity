extends Control

# Interactive Pixel Narrative & Minigame Cutscenes matching New 2 reference videos:
# - BURSA_CARDS: Studio TV desk showing DIJUAL / DILINDUNGI squad players
# - TIM_INTI: Locker room whiteboard listing Starting 11 & CADANGAN + status callout
# - PIDATO_SKUAD: First-day locker room speech choices with relation bar delta preview
# - MAKAN_NYANYI: Squad dinner initiation (JOGET or NYANYI LA/NA/DO rhythm minigame)
# - SPONSOR_SHOOT: Film set -> TEKEN CLAPPER signature draw pad -> SELFIE Polaroid frame
# - COACH_TRAIT: Unlockable coach trait modal (e.g. KORNER = PENALTI)

signal finished
signal launch_volley_training

enum CutsceneMode {
	BURSA_CARDS,
	TIM_INTI,
	PIDATO_SKUAD,
	MAKAN_NYANYI,
	SPONSOR_SHOOT,
	COACH_TRAIT,
	COACH_REJECT,
	PREMATCH_TUNNEL,
	MVP_SHOWCASE,
}

var _mode: CutsceneMode = CutsceneMode.TIM_INTI
var _stage: Control

# Global cutscene FX timers
var _fx_time: float = 0.0
var _clap_snap_timer: float = 0.0
var _live_lbl: Label
var _confetti_layer: Control
var _confetti_items: Array[Dictionary] = []

# Signature clapperboard draw state
var _sig_strokes: Array[PackedVector2Array] = []
var _sig_drawing: bool = false
var _sig_pad: Control

# Nyanyi rhythm state
var _singing_active: bool = false
var _sing_song: String = "REGUETON MUDA"
var _sing_timer: float = 0.0
var _sing_score: int = 0
var _sing_hits: int = 0
var _sing_notes: Array[Dictionary] = []
var _sing_canvas: Control
var _sing_status_lbl: Label
var _sing_avatar: PixelAvatar

func configure(m: CutsceneMode) -> void:
	_mode = m

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UITheme.build_theme()

	var bg := ColorRect.new()
	bg.color = Color("#070E18")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_stage = Control.new()
	_stage.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_stage)

	_render_mode()

func _clear_stage() -> void:
	_singing_active = false
	_clap_snap_timer = 0.0
	_live_lbl = null
	_confetti_layer = null
	_confetti_items.clear()
	_sig_pad = null
	_sing_canvas = null
	_sing_avatar = null
	for c in _stage.get_children():
		c.queue_free()

func _render_mode() -> void:
	_clear_stage()
	match _mode:
		CutsceneMode.BURSA_CARDS:
			_build_bursa_cards()
		CutsceneMode.TIM_INTI:
			_build_tim_inti()
		CutsceneMode.PIDATO_SKUAD:
			_build_pidato_skuad()
		CutsceneMode.MAKAN_NYANYI:
			_build_makan_nyanyi_intro()
		CutsceneMode.SPONSOR_SHOOT:
			_build_sponsor_set()
		CutsceneMode.COACH_TRAIT:
			_build_coach_trait()
		CutsceneMode.COACH_REJECT:
			_build_coach_reject()
		CutsceneMode.PREMATCH_TUNNEL:
			_build_prematch_tunnel()
		CutsceneMode.MVP_SHOWCASE:
			_build_mvp_showcase()

func _add_backdrop(tex_path: String) -> void:
	var bg := TextureRect.new()
	bg.texture = load(tex_path)
	bg.anchor_left = 0.0
	bg.anchor_right = 1.0
	bg.anchor_top = 0.0
	bg.anchor_bottom = 0.36
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_stage.add_child(bg)

	var sep := ColorRect.new()
	sep.color = Color("#1B2D48")
	sep.anchor_left = 0.0
	sep.anchor_right = 1.0
	sep.anchor_top = 0.36
	sep.anchor_bottom = 0.36
	sep.offset_bottom = 2
	_stage.add_child(sep)

# ---------------------------------------------------------------------------
# 1. STUDIO BURSA DIBUKA: DIJUAL / DILINDUNGI CARDS
# ---------------------------------------------------------------------------
func _build_bursa_cards() -> void:
	_add_backdrop("res://assets/sprites/backgrounds/studio_desk.png")
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 110
	vb.offset_right = -110
	vb.offset_top = 24
	vb.offset_bottom = -18
	vb.add_theme_constant_override("separation", 12)
	_stage.add_child(vb)

	var club: Dictionary = CareerState.get_current_club()
	var hdr := PanelContainer.new()
	hdr.add_theme_stylebox_override("panel", UITheme.make_box(Color("#102236"), UITheme.ACCENT_GOLD, 1, 6))
	vb.add_child(hdr)
	var hhb := HBoxContainer.new()
	hhb.add_theme_constant_override("separation", 10)
	hdr.add_child(hhb)
	var cr := ClubCrest.new()
	cr.custom_minimum_size = Vector2(36, 36)
	cr.set_club(int(club["id"]))
	hhb.add_child(cr)
	var hl := Label.new()
	hl.text = "BURSA DIBUKA\n%s" % str(club["name"]).to_upper()
	hl.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	hhb.add_child(hl)

	var board := PanelContainer.new()
	board.add_theme_stylebox_override("panel", UITheme.make_box(Color("#0A1728"), UITheme.ACCENT_RED, 2, 10))
	vb.add_child(board)
	var bvb := VBoxContainer.new()
	bvb.add_theme_constant_override("separation", 8)
	board.add_child(bvb)

	var bn := Label.new()
	bn.text = "● BREAKING NEWS • LAPORAN SKUAD"
	bn.add_theme_color_override("font_color", UITheme.ACCENT_RED)
	bvb.add_child(bn)
	_live_lbl = bn

	var starters: Array = CareerState.career.get("clubSquad", {}).get("starters", [])
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	bvb.add_child(row)

	var show_cnt: int = mini(3, starters.size())
	for i in range(show_cnt):
		var sp: Dictionary = starters[i]
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var tag_col: Color = UITheme.ACCENT_RED if i == 0 else UITheme.ACCENT_CYAN
		card.add_theme_stylebox_override("panel", UITheme.make_box(Color("#12263C"), tag_col, 2, 6))
		row.add_child(card)
		card.modulate.a = 0.0
		var ctw := create_tween()
		ctw.tween_interval(float(i) * 0.12)
		ctw.tween_property(card, "modulate:a", 1.0, 0.25)
		var cv := VBoxContainer.new()
		cv.alignment = BoxContainer.ALIGNMENT_CENTER
		card.add_child(cv)
		var st_lbl := Label.new()
		st_lbl.text = "DIJUAL" if i == 0 else "DILINDUNGI"
		st_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		st_lbl.add_theme_color_override("font_color", tag_col)
		st_lbl.add_theme_font_size_override("font_size", 10)
		cv.add_child(st_lbl)
		var av := PixelAvatar.new()
		av.full_body = false
		av.custom_minimum_size = Vector2(60, 60)
		av.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		av.configure_from_seed(i * 19 + int(club["id"]), club, int(sp.get("number", 10)))
		av.anim_mode = "TALK" if i == 0 else "IDLE"
		av.anim_phase = float(i) * 0.9
		cv.add_child(av)
		var nl := Label.new()
		nl.text = str(sp.get("name", "PEMAIN")).to_upper()
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nl.add_theme_font_size_override("font_size", 10)
		cv.add_child(nl)

	var note := Label.new()
	note.text = "Bursa transfer musim panas resmi dibuka.\nBersainglah untuk mengamankan tempat utama!"
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	bvb.add_child(note)

	var sp_ctr := Control.new()
	sp_ctr.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(sp_ctr)

	var ok_b := Button.new()
	ok_b.text = "LANJUT"
	ok_b.custom_minimum_size = Vector2(0, 50)
	UITheme.style_btn(ok_b, Color("#0E1D30"), UITheme.ACCENT_GOLD, 18)
	ok_b.pressed.connect(func(): AudioSynth.play_click(); finished.emit(); queue_free())
	vb.add_child(ok_b)

# ---------------------------------------------------------------------------
# 2. PAPAN TIM INTI (STARTING 11 + CADANGAN WHITEBOARD)
# ---------------------------------------------------------------------------
func _build_tim_inti() -> void:
	_add_backdrop("res://assets/sprites/backgrounds/locker_room.png")
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 18
	vb.offset_right = -18
	vb.offset_top = 24
	vb.offset_bottom = -18
	vb.add_theme_constant_override("separation", 8)
	_stage.add_child(vb)

	var club: Dictionary = CareerState.get_current_club()
	var board := PanelContainer.new()
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board.add_theme_stylebox_override("panel", UITheme.make_box(Color("#D8DDD6"), Color("#8E9690"), 3, 10))
	vb.add_child(board)

	var bvb := VBoxContainer.new()
	bvb.add_theme_constant_override("separation", 4)
	board.add_child(bvb)

	var title := Label.new()
	title.text = "TIM INTI • %s" % str(club["name"]).to_upper()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", UITheme.get_display_font())
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color("#1C222A"))
	bvb.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bvb.add_child(scroll)
	var list_vb := VBoxContainer.new()
	list_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_vb.add_theme_constant_override("separation", 2)
	scroll.add_child(list_vb)

	var role: String = CareerState.get_player_role_status()
	var user_starter: bool = (role == "INTI")
	var squad: Dictionary = CareerState.career.get("clubSquad", {})
	var starters: Array = squad.get("starters", [])
	var bench: Array = squad.get("bench", [])

	var s_hdr := Label.new()
	s_hdr.text = "INTI (11)"
	s_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s_hdr.add_theme_color_override("font_color", Color("#3C4650"))
	s_hdr.add_theme_font_size_override("font_size", 12)
	list_vb.add_child(s_hdr)

	for s_p in starters:
		if not user_starter and s_p.get("is_user", false):
			continue
		list_vb.add_child(_make_whiteboard_row(s_p))

	var b_hdr := Label.new()
	b_hdr.text = "CADANGAN"
	b_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b_hdr.add_theme_color_override("font_color", Color("#3C4650"))
	b_hdr.add_theme_font_size_override("font_size", 12)
	list_vb.add_child(b_hdr)

	if not user_starter:
		for s_p in starters:
			if s_p.get("is_user", false):
				list_vb.add_child(_make_whiteboard_row(s_p))
	for b_p in bench:
		list_vb.add_child(_make_whiteboard_row(b_p))

	# Bottom callout box with animated user avatar + pop-in tween
	var callout := PanelContainer.new()
	var c_col: Color = UITheme.ACCENT_GREEN if user_starter else UITheme.ACCENT_RED
	callout.add_theme_stylebox_override("panel", UITheme.make_box(Color("#1A1216"), c_col, 2, 10))
	vb.add_child(callout)
	callout.modulate.a = 0.0
	create_tween().tween_property(callout, "modulate:a", 1.0, 0.28)
	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 6)
	callout.add_child(cv)

	var c_top_hb := HBoxContainer.new()
	c_top_hb.add_theme_constant_override("separation", 10)
	c_top_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	cv.add_child(c_top_hb)
	var mini_av := PixelAvatar.new()
	mini_av.custom_minimum_size = Vector2(46, 68)
	mini_av.configure_from_career()
	mini_av.anim_mode = "CHEER" if user_starter else "IDLE"
	c_top_hb.add_child(mini_av)
	var c_txt_vb := VBoxContainer.new()
	c_txt_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c_top_hb.add_child(c_txt_vb)

	var status_ttl := Label.new()
	status_ttl.text = "KAMU MASUK INTI" if user_starter else "KAMU TAK MASUK INTI"
	status_ttl.add_theme_font_override("font", UITheme.get_display_font())
	status_ttl.add_theme_font_size_override("font_size", 17)
	status_ttl.add_theme_color_override("font_color", c_col)
	c_txt_vb.add_child(status_ttl)

	var msg_l := Label.new()
	msg_l.text = "Pelatih menurunkanmu sejak awal. Pertahankan posisimu!" if user_starter else "Kamu mulai dari bangku cadangan. Rebut tempat inti lewat latihan!"
	msg_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg_l.add_theme_color_override("font_color", Color("#E2E8F0"))
	msg_l.add_theme_font_size_override("font_size", 11)
	c_txt_vb.add_child(msg_l)

	var btn_hb := HBoxContainer.new()
	btn_hb.add_theme_constant_override("separation", 8)
	cv.add_child(btn_hb)

	var lat_b := Button.new()
	lat_b.text = "LATIHAN VOLI"
	lat_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lat_b.custom_minimum_size = Vector2(0, 44)
	UITheme.style_btn(lat_b, Color("#173B66"), UITheme.ACCENT_CYAN, 13)
	lat_b.pressed.connect(func(): AudioSynth.play_click(); launch_volley_training.emit(); queue_free())
	btn_hb.add_child(lat_b)

	var ok_b := Button.new()
	ok_b.text = "LANJUT"
	ok_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ok_b.custom_minimum_size = Vector2(0, 44)
	UITheme.style_btn(ok_b, Color("#0E1D30"), c_col, 14)
	ok_b.pressed.connect(func(): AudioSynth.play_click(); finished.emit(); queue_free())
	btn_hb.add_child(ok_b)

func _make_whiteboard_row(p: Dictionary) -> Control:
	var is_u: bool = bool(p.get("is_user", false))
	var pc := PanelContainer.new()
	var bg_col := Color("#C23A3A") if is_u else Color(0.82, 0.85, 0.80, 0.7)
	pc.add_theme_stylebox_override("panel", UITheme.make_box(bg_col, Color("#101418") if is_u else Color(0, 0, 0, 0), 1 if is_u else 0, 2))
	var hb := HBoxContainer.new()
	pc.add_child(hb)
	var num_l := Label.new()
	num_l.text = "%2d" % int(p.get("number", 9))
	num_l.custom_minimum_size = Vector2(28, 0)
	num_l.add_theme_color_override("font_color", Color.WHITE if is_u else Color("#20262E"))
	hb.add_child(num_l)
	var nm_l := Label.new()
	nm_l.text = str(p.get("name", "PEMAIN")).to_upper()
	nm_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nm_l.add_theme_color_override("font_color", Color.WHITE if is_u else Color("#182028"))
	hb.add_child(nm_l)
	var pos_l := Label.new()
	pos_l.text = str(p.get("pos", "CM"))
	pos_l.add_theme_color_override("font_color", Color.WHITE if is_u else Color("#36424E"))
	hb.add_child(pos_l)
	return pc

# ---------------------------------------------------------------------------
# 3. PIDATO PEMAIN BARU (DAY 1 LOCKER ROOM SPEECH)
# ---------------------------------------------------------------------------
func _build_pidato_skuad() -> void:
	_add_backdrop("res://assets/sprites/backgrounds/locker_room.png")
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 90
	vb.offset_right = -90
	vb.offset_top = 20
	vb.offset_bottom = -16
	vb.add_theme_constant_override("separation", 8)
	_stage.add_child(vb)

	var hdr := Label.new()
	hdr.text = "PIDATO PEMAIN BARU"
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr.add_theme_font_override("font", UITheme.get_display_font())
	hdr.add_theme_font_size_override("font_size", 20)
	hdr.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	vb.add_child(hdr)

	# 3 characters in locker room (teammate left, USER center, teammate right)
	var av_hb := HBoxContainer.new()
	av_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	av_hb.add_theme_constant_override("separation", 24)
	vb.add_child(av_hb)

	var club: Dictionary = CareerState.get_current_club()
	for i in range(3):
		var av := PixelAvatar.new()
		av.custom_minimum_size = Vector2(90, 134)
		if i == 1:
			av.configure_from_career()
			av.show_number_badge = true
			av.anim_mode = "TALK"
		else:
			av.configure_from_seed(42 + i * 17, club, 13 + i * 7)
			av.anim_mode = "IDLE"
			av.anim_phase = float(i) * 1.1
		av_hb.add_child(av)

	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(sp)

	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UITheme.make_box(Color("#0D1522", 0.94), UITheme.BORDER_CYAN, 2, 10))
	vb.add_child(box)
	var bvb := VBoxContainer.new()
	bvb.add_theme_constant_override("separation", 8)
	box.add_child(bvb)

	var prompt := Label.new()
	prompt.text = "Hari pertama, seluruh tim duduk dan pelatih memberimu giliran bicara.\nSeisi ruang ganti menilaimu!"
	prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bvb.add_child(prompt)

	var ch_hb := HBoxContainer.new()
	ch_hb.add_theme_constant_override("separation", 8)
	bvb.add_child(ch_hb)

	var choices: Array[Dictionary] = [
		{"title": "JANJIKAN TROFI", "hint": "+8 FANS\n+5 PERS\n-4 PELATIH", "col": Color("#4C204C"), "eff": {"fans": 8, "pers": 5, "pelatih": -4, "ruangGanti": -3}},
		{"title": "AKU MAU BELAJAR", "hint": "+10 PELATIH\n+5 R.GANTI\n-2 PERS", "col": Color("#1C486B"), "eff": {"pelatih": 10, "ruangGanti": 5, "pers": -2}},
		{"title": "CUKUP SAPA DUDUK", "hint": "+7 R.GANTI\n+1 PELATIH\n-2 FANS", "col": Color("#634C1A"), "eff": {"ruangGanti": 7, "pelatih": 1, "fans": -2}},
	]
	for ch in choices:
		var btn := Button.new()
		btn.text = "%s\n(%s)" % [ch["title"], ch["hint"]]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 74)
		UITheme.style_btn(btn, ch["col"], UITheme.ACCENT_GOLD, 11)
		btn.pressed.connect(func():
			AudioSynth.play_achievement()
			CareerState.career["careerMeta"]["firstSpeechDone"] = true
			CareerState.apply_cutscene_effects(ch["eff"])
			_show_pidato_result(str(ch["title"]), ch["eff"])
		)
		ch_hb.add_child(btn)

func _show_pidato_result(label_txt: String, eff: Dictionary) -> void:
	_clear_stage()
	_add_backdrop("res://assets/sprites/backgrounds/locker_room.png")
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_CENTER)
	vb.custom_minimum_size = Vector2(440, 260)
	vb.offset_left = -220
	vb.offset_right = 220
	vb.offset_top = -130
	vb.offset_bottom = 130
	_stage.add_child(vb)

	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", UITheme.make_box(Color("#0C1624", 0.95), UITheme.ACCENT_GOLD, 2, 12))
	vb.add_child(pc)
	pc.modulate.a = 0.0
	create_tween().tween_property(pc, "modulate:a", 1.0, 0.25)
	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", 8)
	pc.add_child(cv)

	var av_res := PixelAvatar.new()
	av_res.custom_minimum_size = Vector2(72, 108)
	av_res.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	av_res.configure_from_career()
	av_res.anim_mode = "CHEER"
	cv.add_child(av_res)

	var h := Label.new()
	h.text = "PIDATO: %s" % label_txt.replace("\n", " ")
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	cv.add_child(h)

	var rel: Dictionary = CareerState.career["playerProfile"]["relations"]
	for rk in ["pelatih", "ruangGanti", "fans", "pers"]:
		var d: int = int(eff.get(rk, 0))
		var r_lbl := Label.new()
		r_lbl.text = "%s: %d (%s%d)" % [rk.to_upper(), int(rel[rk]), "+" if d >= 0 else "", d]
		r_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		r_lbl.add_theme_color_override("font_color", UITheme.ACCENT_GREEN if d > 0 else (UITheme.ACCENT_RED if d < 0 else UITheme.TEXT_MUTED))
		cv.add_child(r_lbl)

	var ok_b := Button.new()
	ok_b.text = "LANJUTKAN"
	ok_b.custom_minimum_size = Vector2(0, 44)
	UITheme.style_btn(ok_b, Color("#0E1D30"), UITheme.ACCENT_GOLD, 16)
	ok_b.pressed.connect(func(): AudioSynth.play_click(); finished.emit(); queue_free())
	cv.add_child(ok_b)

# ---------------------------------------------------------------------------
# 4. MAKAN PERTAMA BERSAMA SKUAD & NYANYI PITCH MINIGAME
# ---------------------------------------------------------------------------
func _build_makan_nyanyi_intro() -> void:
	# Pixel Dining Hall Backdrop
	var hall := ColorRect.new()
	hall.color = Color("#20242A")
	hall.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stage.add_child(hall)

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 110
	vb.offset_right = -110
	vb.offset_top = 24
	vb.offset_bottom = -18
	vb.add_theme_constant_override("separation", 10)
	_stage.add_child(vb)

	var hdr := Label.new()
	hdr.text = "MAKAN PERTAMA BERSAMA SKUAD"
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr.add_theme_font_override("font", UITheme.get_display_font())
	hdr.add_theme_font_size_override("font_size", 18)
	hdr.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	vb.add_child(hdr)

	# Stylized Dining Hall Scene with Player standing & Red-White Checkered Table
	var scene_box := PanelContainer.new()
	scene_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scene_box.add_theme_stylebox_override("panel", UITheme.make_box(Color("#2A3038"), Color("#565E68"), 2, 4))
	vb.add_child(scene_box)

	var table_vb := VBoxContainer.new()
	table_vb.alignment = BoxContainer.ALIGNMENT_CENTER
	scene_box.add_child(table_vb)

	var av := PixelAvatar.new()
	av.custom_minimum_size = Vector2(92, 134)
	av.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	av.configure_from_career()
	av.casual_style = 2
	av.anim_mode = "SING"
	table_vb.add_child(av)

	var cloth := ColorRect.new()
	cloth.color = Color("#B83238")
	cloth.custom_minimum_size = Vector2(280, 36)
	cloth.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	table_vb.add_child(cloth)

	var desc := Label.new()
	desc.text = "Makan pertama bersama skuad! Saatnya ritual pemain baru: naik ke kursi untuk bernyanyi atau berjoget!"
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(desc)

	var ch_hb := HBoxContainer.new()
	ch_hb.add_theme_constant_override("separation", 10)
	vb.add_child(ch_hb)

	var sing_b := Button.new()
	sing_b.text = "NYANYI (MINIGAME)\n+6 R.GANTI • +7 FANS"
	sing_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sing_b.custom_minimum_size = Vector2(0, 62)
	UITheme.style_btn(sing_b, Color("#24245C"), UITheme.ACCENT_CYAN, 12)
	sing_b.pressed.connect(func(): AudioSynth.play_click(); _build_song_picker())
	ch_hb.add_child(sing_b)

	var dance_b := Button.new()
	dance_b.text = "JOGET\n+8 R.GANTI • +4 FANS • -4 PERS"
	dance_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dance_b.custom_minimum_size = Vector2(0, 62)
	UITheme.style_btn(dance_b, Color("#562828"), UITheme.ACCENT_GOLD, 12)
	dance_b.pressed.connect(func():
		AudioSynth.play_achievement()
		av.anim_mode = "MVP"
		_spawn_confetti(UITheme.ACCENT_GOLD)
		dance_b.disabled = true
		sing_b.disabled = true
		CareerState.career["careerMeta"]["initiationDone"] = true
		CareerState.apply_cutscene_effects({"ruangGanti": 8, "fans": 4, "pers": -4})
		var dt := create_tween()
		dt.tween_property(av, "position:y", -14.0, 0.16).as_relative()
		dt.tween_property(av, "position:y", 14.0, 0.16).as_relative()
		dt.tween_callback(func(): finished.emit(); queue_free())
	)
	ch_hb.add_child(dance_b)

func _build_song_picker() -> void:
	_clear_stage()
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_CENTER)
	vb.custom_minimum_size = Vector2(560, 290)
	vb.offset_left = -280
	vb.offset_right = 280
	vb.offset_top = -145
	vb.offset_bottom = 145
	vb.add_theme_constant_override("separation", 12)
	_stage.add_child(vb)

	var ttl := Label.new()
	ttl.text = "PILIH LAGU INISIASI"
	ttl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ttl.add_theme_font_override("font", UITheme.get_display_font())
	ttl.add_theme_font_size_override("font_size", 20)
	vb.add_child(ttl)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	vb.add_child(row)
	for s_name in ["HIMNE SENIOR", "REGUETON MUDA", "DAERAH SERANGGA"]:
		var b := Button.new()
		b.text = s_name.replace(" ", "\n")
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 96)
		var sel: bool = (_sing_song == s_name)
		UITheme.style_btn(b, Color("#5A1D24") if sel else Color("#121E32"), UITheme.ACCENT_GOLD if sel else UITheme.BORDER_STEEL, 12)
		b.pressed.connect(func(): AudioSynth.play_click(); _sing_song = s_name; _build_song_picker())
		row.add_child(b)

	var go_b := Button.new()
	go_b.text = "NYANYI!"
	go_b.custom_minimum_size = Vector2(0, 52)
	UITheme.style_btn(go_b, Color("#401820"), UITheme.ACCENT_RED, 18)
	go_b.pressed.connect(func(): AudioSynth.play_click(); _start_singing_minigame())
	vb.add_child(go_b)

func _start_singing_minigame() -> void:
	_clear_stage()
	_singing_active = true
	_sing_timer = 0.0
	_sing_score = 0
	_sing_hits = 0
	_sing_notes.clear()
	var syls := ["LA", "NA", "DO", "MI"]
	var freqs := [329.63, 392.00, 440.00, 523.25]
	for i in range(10):
		var lane := (i * 3 + 1) % 3
		_sing_notes.append({
			"time": 1.0 + float(i) * 0.95,
			"lane": lane,
			"syl": syls[i % syls.size()],
			"freq": freqs[lane],
			"hit": false,
		})

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 60
	vb.offset_right = -60
	vb.offset_top = 14
	vb.offset_bottom = -14
	vb.add_theme_constant_override("separation", 6)
	_stage.add_child(vb)

	# Staff Note Track Canvas at top (matching Video 3 sheet 14!)
	_sing_canvas = Control.new()
	_sing_canvas.custom_minimum_size = Vector2(0, 108)
	_sing_canvas.draw.connect(_draw_sing_staff)
	vb.add_child(_sing_canvas)

	_sing_status_lbl = Label.new()
	_sing_status_lbl.text = "KETUK TOMBOL NADA SAAT MENYENTUH GARIS KIRI! • SKOR: 0"
	_sing_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sing_status_lbl.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	vb.add_child(_sing_status_lbl)

	# Standing Singer on Chair
	var mid := CenterContainer.new()
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(mid)
	_sing_avatar = PixelAvatar.new()
	_sing_avatar.custom_minimum_size = Vector2(120, 174)
	_sing_avatar.configure_from_career()
	_sing_avatar.casual_style = 2
	_sing_avatar.anim_mode = "SING"
	mid.add_child(_sing_avatar)

	# 3 Singing Pitch Pads (RENDAH LA | TENGAH NA | TINGGI DO) + TURUN early exit
	var pad_hb := HBoxContainer.new()
	pad_hb.add_theme_constant_override("separation", 8)
	vb.add_child(pad_hb)
	for lane_idx in range(3):
		var lane_names := ["LA (RENDAH)", "NA (TENGAH)", "DO (TINGGI)"]
		var pb := Button.new()
		pb.text = lane_names[lane_idx]
		pb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pb.custom_minimum_size = Vector2(0, 56)
		UITheme.style_btn(pb, Color("#173B66"), UITheme.ACCENT_CYAN, 12)
		pb.pressed.connect(func(): _tap_sing_lane(lane_idx))
		pad_hb.add_child(pb)

	var bot := HBoxContainer.new()
	vb.add_child(bot)
	var lbl := Label.new()
	lbl.text = "♪ %s" % _sing_song
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bot.add_child(lbl)
	var stop_b := Button.new()
	stop_b.text = "TURUN"
	stop_b.custom_minimum_size = Vector2(110, 40)
	stop_b.pressed.connect(func(): AudioSynth.play_click(); _finish_singing_minigame())
	bot.add_child(stop_b)

func _spawn_confetti(base_col: Color) -> void:
	if _confetti_layer == null:
		_confetti_layer = Control.new()
		_confetti_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
		_confetti_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_confetti_layer.draw.connect(_draw_confetti)
		_stage.add_child(_confetti_layer)
	_confetti_items.clear()
	var pal := [base_col, UITheme.ACCENT_GOLD, UITheme.ACCENT_CYAN, UITheme.ACCENT_GREEN, Color("#F472B6")]
	for i in range(44):
		_confetti_items.append({
			"x": randf_range(12.0, 948.0),
			"y": randf_range(-40.0, 540.0),
			"vy": randf_range(55.0, 125.0),
			"phase": randf() * TAU,
			"sz": randf_range(5.0, 9.0),
			"col": pal[i % pal.size()],
		})

func _draw_confetti() -> void:
	if _confetti_layer == null:
		return
	for it in _confetti_items:
		var px: float = float(it["x"]) + sin(_fx_time * 3.4 + float(it["phase"])) * 14.0
		var py: float = fmod(float(it["y"]) + _fx_time * float(it["vy"]), 580.0) - 20.0
		var sz: float = float(it["sz"])
		_confetti_layer.draw_rect(Rect2(px, py, sz, sz * 0.6), it["col"])

func _process(delta: float) -> void:
	_fx_time += delta
	if is_instance_valid(_live_lbl):
		_live_lbl.modulate.a = 0.5 + 0.5 * sin(_fx_time * 6.0)
	if _clap_snap_timer > 0.0:
		_clap_snap_timer = maxf(0.0, _clap_snap_timer - delta)
	if is_instance_valid(_sig_pad):
		_sig_pad.queue_redraw()
	if is_instance_valid(_confetti_layer):
		_confetti_layer.queue_redraw()
	if not _singing_active:
		return
	_sing_timer += delta
	if _sing_canvas != null:
		_sing_canvas.queue_redraw()
	if _sing_timer >= 11.5:
		_finish_singing_minigame()

func _draw_sing_staff() -> void:
	if _sing_canvas == null:
		return
	var s := _sing_canvas.size
	_sing_canvas.draw_rect(Rect2(Vector2.ZERO, s), Color("#101620"))
	_sing_canvas.draw_rect(Rect2(Vector2.ZERO, s), UITheme.BORDER_STEEL, false, 2.0)
	var hit_x: float = 64.0
	_sing_canvas.draw_line(Vector2(hit_x, 8), Vector2(hit_x, s.y - 8), UITheme.ACCENT_CYAN, 3.0)
	for lane in range(3):
		var ly: float = 28.0 + float(2 - lane) * 32.0
		_sing_canvas.draw_line(Vector2(10, ly), Vector2(s.x - 10, ly), Color("#2A3646"), 1.0)
	for n in _sing_notes:
		if bool(n["hit"]):
			continue
		var dt: float = float(n["time"]) - _sing_timer
		var nx: float = hit_x + dt * 130.0
		if nx >= 16.0 and nx <= s.x - 24.0:
			var ny: float = 28.0 + float(2 - int(n["lane"])) * 32.0
			_sing_canvas.draw_rect(Rect2(nx - 16, ny - 10, 32, 20), Color("#B42C36"))
			_sing_canvas.draw_rect(Rect2(nx - 16, ny - 10, 32, 20), UITheme.ACCENT_GOLD, false, 1.5)
			_sing_canvas.draw_string(UITheme.get_display_font(), Vector2(nx - 10, ny + 5), str(n["syl"]), HORIZONTAL_ALIGNMENT_CENTER, 20, 12, Color.WHITE)

func _tap_sing_lane(lane_idx: int) -> void:
	var best_idx: int = -1
	var best_dt: float = 0.55
	for i in range(_sing_notes.size()):
		var n: Dictionary = _sing_notes[i]
		if bool(n["hit"]) or int(n["lane"]) != lane_idx:
			continue
		var dt: float = absf(float(n["time"]) - _sing_timer)
		if dt < best_dt:
			best_dt = dt
			best_idx = i
	if best_idx >= 0:
		_sing_notes[best_idx]["hit"] = true
		_sing_hits += 1
		_sing_score += 2 if best_dt < 0.25 else 1
		AudioSynth.play_note(float(_sing_notes[best_idx]["freq"]), 0.22)
		_sing_status_lbl.text = "SUARA MANTAP! (%d/10 HIT) • SKOR: %d" % [_sing_hits, _sing_score]
	else:
		AudioSynth.play_ring_tap(false)

func _finish_singing_minigame() -> void:
	_singing_active = false
	var bonus_rg: int = 4 + mini(6, _sing_hits)
	CareerState.career["careerMeta"]["initiationDone"] = true
	CareerState.apply_cutscene_effects({"ruangGanti": bonus_rg, "fans": 5, "xp": 35})
	finished.emit()
	queue_free()

# ---------------------------------------------------------------------------
# 5. SPONSOR COMMERCIAL SHOOT: TEKEN CLAPPER SIGNATURE PAD & SELFIE (TAKE 7!)
# ---------------------------------------------------------------------------
func _build_sponsor_set() -> void:
	_clear_stage()
	_sig_strokes.clear()
	_clap_snap_timer = 0.72
	var sp_name: String = "TOKO ROTI LOKAL"
	var sp_id: String = str(CareerState.career.get("sponsor", {}).get("activeId", "roti_lokal"))
	for item in GameData.sponsors_catalog:
		if item["id"] == sp_id:
			sp_name = str(item["name"]).to_upper()

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 24
	vb.offset_right = -24
	vb.offset_top = 18
	vb.offset_bottom = -16
	vb.add_theme_constant_override("separation", 8)
	_stage.add_child(vb)

	var marquee := PanelContainer.new()
	marquee.add_theme_stylebox_override("panel", UITheme.make_box(Color("#1A1308"), UITheme.ACCENT_GOLD, 2, 6))
	vb.add_child(marquee)
	var mq_hb := HBoxContainer.new()
	marquee.add_child(mq_hb)
	var live_tag := Label.new()
	live_tag.text = "* REC"
	live_tag.add_theme_color_override("font_color", UITheme.ACCENT_RED)
	live_tag.add_theme_font_size_override("font_size", 11)
	_live_lbl = live_tag
	mq_hb.add_child(live_tag)
	var top := Label.new()
	top.text = "SPONSOR: %s • TAKE 7" % sp_name
	top.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.clip_text = true
	top.add_theme_font_override("font", UITheme.get_display_font())
	top.add_theme_font_size_override("font_size", 13)
	top.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	mq_hb.add_child(top)

	# Landscape 2-Column Split: Left = Fans + Player Signing | Right = Clapper Drawing Canvas
	var split_hb := HBoxContainer.new()
	split_hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split_hb.add_theme_constant_override("separation", 14)
	vb.add_child(split_hb)

	var stage_box := PanelContainer.new()
	stage_box.custom_minimum_size = Vector2(360, 0)
	stage_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage_box.add_theme_stylebox_override("panel", UITheme.make_box(Color("#121A24"), Color("#D09040"), 2, 6))
	split_hb.add_child(stage_box)
	var st_vb := VBoxContainer.new()
	st_vb.alignment = BoxContainer.ALIGNMENT_CENTER
	stage_box.add_child(st_vb)
	var shb := HBoxContainer.new()
	shb.alignment = BoxContainer.ALIGNMENT_CENTER
	shb.add_theme_constant_override("separation", 14)
	st_vb.add_child(shb)

	var club := CareerState.get_current_club()
	var fan1 := PixelAvatar.new()
	fan1.custom_minimum_size = Vector2(60, 90)
	fan1.configure_from_seed(301, club, 7)
	fan1.casual_style = 1
	fan1.anim_mode = "CHEER"
	shb.add_child(fan1)

	var av := PixelAvatar.new()
	av.custom_minimum_size = Vector2(88, 130)
	av.configure_from_career()
	av.casual_style = 1
	av.anim_mode = "SIGN"
	shb.add_child(av)

	var fan2 := PixelAvatar.new()
	fan2.custom_minimum_size = Vector2(60, 90)
	fan2.configure_from_seed(709, club, 11)
	fan2.casual_style = 1
	fan2.anim_mode = "CHEER"
	fan2.anim_phase = 1.6
	shb.add_child(fan2)

	var info := Label.new()
	info.text = "Fans bersorak 'TAKE 7!' - Tanda tangani papan untuk lanjut selfie."
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_color_override("font_color", Color("#FDE68A"))
	info.add_theme_font_size_override("font_size", 11)
	st_vb.add_child(info)

	# Right Column: TEKEN CLAPPERBoard Canvas
	var right_vb := VBoxContainer.new()
	right_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vb.add_theme_constant_override("separation", 8)
	split_hb.add_child(right_vb)

	var hdr2 := Label.new()
	hdr2.text = "TEKEN CLAPPER (TARIK TANDA TANGAN DI PAPAN)"
	hdr2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hdr2.add_theme_color_override("font_color", UITheme.ACCENT_CYAN)
	hdr2.add_theme_font_size_override("font_size", 11)
	right_vb.add_child(hdr2)

	var clapper := PanelContainer.new()
	clapper.size_flags_vertical = Control.SIZE_EXPAND_FILL
	clapper.clip_contents = true
	clapper.add_theme_stylebox_override("panel", UITheme.make_box(Color("#14181E"), Color("#FFFFFF"), 3, 4))
	right_vb.add_child(clapper)

	_sig_pad = Control.new()
	_sig_pad.set_anchors_preset(Control.PRESET_FULL_RECT)
	_sig_pad.draw.connect(_draw_clapper_pad)
	_sig_pad.gui_input.connect(_on_sig_input)
	clapper.add_child(_sig_pad)

	var btn_hb := HBoxContainer.new()
	btn_hb.add_theme_constant_override("separation", 6)
	right_vb.add_child(btn_hb)

	var clr_b := Button.new()
	clr_b.text = "HAPUS"
	clr_b.custom_minimum_size = Vector2(78, 44)
	UITheme.style_btn(clr_b, Color("#562828"), UITheme.ACCENT_RED, 12)
	clr_b.pressed.connect(func(): AudioSynth.play_click(); _sig_strokes.clear(); _sig_pad.queue_redraw())
	btn_hb.add_child(clr_b)

	var clap_b := Button.new()
	clap_b.text = "CLAP TAKE 7"
	clap_b.custom_minimum_size = Vector2(114, 44)
	UITheme.style_btn(clap_b, Color("#4E320E"), UITheme.ACCENT_GOLD, 12)
	clap_b.pressed.connect(func(): AudioSynth.play_click(); _clap_snap_timer = 0.72)
	btn_hb.add_child(clap_b)

	var next_b := Button.new()
	next_b.text = "LANJUT -> SELFIE"
	next_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	next_b.custom_minimum_size = Vector2(0, 44)
	UITheme.style_btn(next_b, Color("#173B66"), UITheme.ACCENT_GREEN, 13)
	next_b.pressed.connect(func(): AudioSynth.play_click(); _build_sponsor_selfie(sp_name))
	btn_hb.add_child(next_b)

func _draw_clapper_pad() -> void:
	if _sig_pad == null:
		return
	var s := _sig_pad.size
	var bar_w: float = maxf(60.0, s.x - 16.0)
	# Lower fixed striped bar inset cleanly inside clapper frame
	for i in range(6):
		var col := Color.WHITE if i % 2 == 0 else Color("#14181E")
		_sig_pad.draw_rect(Rect2(8.0 + float(i) * (bar_w / 6.0), 30.0, bar_w / 6.0, 11.0), col)
	# Animated hinged top clapper bar!
	var open_amt: float = 0.0
	if _clap_snap_timer > 0.12:
		open_amt = sin(((_clap_snap_timer - 0.12) / 0.60) * PI)
	var hinge := Vector2(10.0, 30.0)
	_sig_pad.draw_set_transform(hinge, -0.14 * open_amt, Vector2.ONE)
	for i in range(6):
		var col2 := Color("#14181E") if i % 2 == 0 else Color.WHITE
		_sig_pad.draw_rect(Rect2(float(i) * (bar_w / 6.0), -11.0, bar_w / 6.0, 11.0), col2)
	_sig_pad.draw_circle(Vector2(3.0, -3.0), 3.0, UITheme.ACCENT_GOLD)
	_sig_pad.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	if _clap_snap_timer > 0.02 and _clap_snap_timer < 0.22:
		_sig_pad.draw_string(UITheme.get_display_font(), Vector2(16, 62), "* ACTION! TAKE 7! *", HORIZONTAL_ALIGNMENT_CENTER, s.x - 32, 16, UITheme.ACCENT_GOLD)
	var pname: String = str(CareerState.career.get("playerProfile", {}).get("name", "PEMAIN")).to_upper()
	_sig_pad.draw_string(UITheme.get_display_font(), Vector2(18, 86), "%s  -  TAKE 7" % pname, HORIZONTAL_ALIGNMENT_CENTER, s.x - 36, 18, UITheme.ACCENT_GOLD)
	for stroke in _sig_strokes:
		if stroke.size() >= 2:
			_sig_pad.draw_polyline(stroke, Color(0.25, 0.85, 1.0, 0.25), 8.0)
			_sig_pad.draw_polyline(stroke, Color.WHITE, 4.0)

func _on_sig_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
		var mb: InputEventMouseButton = ev
		if mb.pressed:
			_sig_drawing = true
			_sig_strokes.append(PackedVector2Array([mb.position]))
		else:
			if _sig_drawing and not _sig_strokes.is_empty() and _sig_strokes[_sig_strokes.size() - 1].size() >= 3:
				_clap_snap_timer = 0.50
				AudioSynth.play_click()
			_sig_drawing = false
		_sig_pad.queue_redraw()
	elif ev is InputEventMouseMotion and _sig_drawing:
		if not _sig_strokes.is_empty():
			_sig_strokes[_sig_strokes.size() - 1].append(ev.position)
			_sig_pad.queue_redraw()

func _build_sponsor_selfie(sp_name: String) -> void:
	_clear_stage()
	var phone_bg := PanelContainer.new()
	phone_bg.set_anchors_preset(Control.PRESET_CENTER)
	phone_bg.custom_minimum_size = Vector2(580, 360)
	phone_bg.offset_left = -290
	phone_bg.offset_right = 290
	phone_bg.offset_top = -180
	phone_bg.offset_bottom = 180
	phone_bg.add_theme_stylebox_override("panel", UITheme.make_box(Color("#12141E"), Color("#EC4899"), 3, 12))
	_stage.add_child(phone_bg)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	phone_bg.add_child(vb)

	var hdr := Label.new()
	hdr.text = "● SELFIE • %s • TAKE 7" % sp_name
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr.add_theme_font_override("font", UITheme.get_display_font())
	hdr.add_theme_font_size_override("font_size", 16)
	hdr.add_theme_color_override("font_color", Color("#F472B6"))
	_live_lbl = hdr
	vb.add_child(hdr)

	# Polaroid Card Frame with pop-in scale animation
	var polaroid := PanelContainer.new()
	polaroid.custom_minimum_size = Vector2(300, 224)
	polaroid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	polaroid.pivot_offset = Vector2(150, 112)
	polaroid.add_theme_stylebox_override("panel", UITheme.make_box(Color("#EBECEF"), Color("#FFFFFF"), 4, 12))
	vb.add_child(polaroid)
	polaroid.scale = Vector2(0.84, 0.84)
	create_tween().tween_property(polaroid, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var pvb := VBoxContainer.new()
	pvb.alignment = BoxContainer.ALIGNMENT_CENTER
	polaroid.add_child(pvb)
	var photo := ColorRect.new()
	photo.color = Color("#182C42")
	photo.custom_minimum_size = Vector2(260, 158)
	pvb.add_child(photo)
	var phb := HBoxContainer.new()
	phb.set_anchors_preset(Control.PRESET_FULL_RECT)
	phb.alignment = BoxContainer.ALIGNMENT_CENTER
	phb.add_theme_constant_override("separation", 14)
	photo.add_child(phb)
	var fan := PixelAvatar.new()
	fan.custom_minimum_size = Vector2(72, 108)
	fan.configure_from_seed(99, CareerState.get_current_club(), 7)
	fan.casual_style = 1
	fan.anim_mode = "CHEER"
	var you := PixelAvatar.new()
	you.custom_minimum_size = Vector2(84, 124)
	you.configure_from_career()
	you.casual_style = 1
	you.anim_mode = "MVP"
	phb.add_child(fan)
	phb.add_child(you)
	var cap := Label.new()
	cap.text = "★ ★ ★  TANDA TANGAN SET • 10/10"
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.add_theme_color_override("font_color", Color("#222630"))
	pvb.add_child(cap)

	var done_b := Button.new()
	done_b.text = "JEPRET & SIMPAN (+$1.500 • +4 FANS)"
	done_b.custom_minimum_size = Vector2(0, 48)
	UITheme.style_btn(done_b, Color("#17462E"), UITheme.ACCENT_GREEN, 13)
	done_b.pressed.connect(func():
		done_b.disabled = true
		AudioSynth.play_achievement()
		var flash := ColorRect.new()
		flash.color = Color(1, 1, 1, 0.94)
		flash.set_anchors_preset(Control.PRESET_FULL_RECT)
		_stage.add_child(flash)
		var ftw := create_tween()
		ftw.tween_property(flash, "color:a", 0.0, 0.28)
		ftw.tween_callback(func():
			CareerState.career["careerMeta"]["clapperDoneSeason"] = int(CareerState.career["careerMeta"]["year"])
			CareerState.apply_cutscene_effects({"cash": 1500, "fans": 4, "followers": 420, "xp": 30})
			finished.emit()
			queue_free()
		)
	)
	vb.add_child(done_b)

# ---------------------------------------------------------------------------
# 6. SIFAT PELATIH TERBUKA (COACH TRAIT CARD)
# ---------------------------------------------------------------------------
func _build_coach_trait() -> void:
	_add_backdrop("res://assets/sprites/backgrounds/locker_room.png")
	_spawn_confetti(UITheme.ACCENT_CYAN)
	var card := PanelContainer.new()
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.custom_minimum_size = Vector2(430, 380)
	card.offset_left = -215
	card.offset_right = 215
	card.offset_top = -190
	card.offset_bottom = 190
	card.pivot_offset = Vector2(215, 190)
	card.add_theme_stylebox_override("panel", UITheme.make_box(Color("#122436", 0.96), UITheme.ACCENT_CYAN, 2, 14))
	_stage.add_child(card)
	card.scale = Vector2(0.86, 0.86)
	create_tween().tween_property(card, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	card.add_child(vb)

	var av := PixelAvatar.new()
	av.custom_minimum_size = Vector2(72, 108)
	av.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	av.configure_from_career()
	av.anim_mode = "CHEER"
	vb.add_child(av)

	var tag := Label.new()
	tag.text = "● SIFAT PELATIH TERBUKA"
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.add_theme_color_override("font_color", UITheme.ACCENT_CYAN)
	vb.add_child(tag)

	var ttl := Label.new()
	ttl.text = "KORNER = PENALTI"
	ttl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ttl.add_theme_font_override("font", UITheme.get_display_font())
	ttl.add_theme_font_size_override("font_size", 22)
	ttl.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	vb.add_child(ttl)

	var desc := Label.new()
	desc.text = "Melatih tendangan sudut! Jika kamu eksekutornya, peluang mencetak gol dari situasi korner dan bola mati meningkat tajam."
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(desc)

	var stat := Label.new()
	stat.text = "x1,8 KORNER   •   KOLEKSI 3/30"
	stat.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stat.add_theme_color_override("font_color", UITheme.ACCENT_GREEN)
	vb.add_child(stat)

	var ok_b := Button.new()
	ok_b.text = "KETUK UNTUK LANJUT"
	ok_b.custom_minimum_size = Vector2(0, 46)
	UITheme.style_btn(ok_b, Color("#0E2036"), UITheme.ACCENT_CYAN, 14)
	ok_b.pressed.connect(func(): AudioSynth.play_click(); finished.emit(); queue_free())
	vb.add_child(ok_b)

# ---------------------------------------------------------------------------
# 7. PRE-MATCH: PELATIH BILANG TIDAK (COACH REJECT DRAMA)
# ---------------------------------------------------------------------------
func _build_coach_reject() -> void:
	_add_backdrop("res://assets/sprites/backgrounds/manager_office.png")
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 110
	vb.offset_right = -110
	vb.offset_top = 24
	vb.offset_bottom = -18
	vb.add_theme_constant_override("separation", 10)
	_stage.add_child(vb)

	var stamp := PanelContainer.new()
	stamp.pivot_offset = Vector2(220, 28)
	stamp.add_theme_stylebox_override("panel", UITheme.make_box(Color("#4A1216"), UITheme.ACCENT_RED, 3, 10))
	vb.add_child(stamp)
	stamp.scale = Vector2(0.82, 0.82)
	create_tween().tween_property(stamp, "scale", Vector2.ONE, 0.30).set_trans(Tween.TRANS_BACK)
	var st_l := Label.new()
	st_l.text = "PELATIH BILANG TIDAK!"
	st_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	st_l.add_theme_font_override("font", UITheme.get_display_font())
	st_l.add_theme_font_size_override("font_size", 22)
	st_l.add_theme_color_override("font_color", UITheme.ACCENT_RED)
	stamp.add_child(st_l)

	var av_hb := HBoxContainer.new()
	av_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	av_hb.add_theme_constant_override("separation", 36)
	vb.add_child(av_hb)

	var coach := TextureRect.new()
	var at := AtlasTexture.new()
	at.atlas = load("res://assets/sprites/characters/npcs_sheet.png")
	at.region = Rect2(2 * 24, 0, 24, 36)
	coach.texture = at
	coach.custom_minimum_size = Vector2(90, 134)
	coach.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	av_hb.add_child(coach)
	var ctw := create_tween().set_loops()
	ctw.tween_property(coach, "position:y", -5.0, 0.45).as_relative()
	ctw.tween_property(coach, "position:y", 5.0, 0.45).as_relative()

	var you := PixelAvatar.new()
	you.custom_minimum_size = Vector2(90, 134)
	you.configure_from_career()
	you.anim_mode = "IDLE"
	av_hb.add_child(you)

	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(sp)

	var p: Dictionary = CareerState.career.get("playerProfile", {})
	var en := int(p.get("energy", 80))
	var coach_rel := int(p.get("relations", {}).get("pelatih", 60))
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UITheme.make_box(Color("#0D1522", 0.95), UITheme.ACCENT_RED, 2, 10))
	vb.add_child(box)
	var bvb := VBoxContainer.new()
	bvb.add_theme_constant_override("separation", 10)
	box.add_child(bvb)

	var msg := Label.new()
	msg.text = "Menjelang kick-off, pelatih menegur kondisi fisik & sikapmu (Energi %d%% • Relasi Pelatih %d). Bagaimana tanggapanmu sebelum masuk lapangan?" % [en, coach_rel]
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bvb.add_child(msg)

	var btn_hb := HBoxContainer.new()
	btn_hb.add_theme_constant_override("separation", 8)
	bvb.add_child(btn_hb)

	var b1 := Button.new()
	b1.text = "TERIMA & FOKUS\n(+6 PELATIH)"
	b1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b1.custom_minimum_size = Vector2(0, 52)
	UITheme.style_btn(b1, Color("#173B66"), UITheme.ACCENT_CYAN, 12)
	b1.pressed.connect(func():
		AudioSynth.play_click()
		CareerState.apply_cutscene_effects({"pelatih": 6, "ruangGanti": 2})
		finished.emit()
		queue_free()
	)
	btn_hb.add_child(b1)

	var b2 := Button.new()
	b2.text = "JANJIKAN GOL!\n(+4 FANS • -3 PELATIH)"
	b2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b2.custom_minimum_size = Vector2(0, 52)
	UITheme.style_btn(b2, Color("#5A1D24"), UITheme.ACCENT_GOLD, 12)
	b2.pressed.connect(func():
		AudioSynth.play_click()
		CareerState.apply_cutscene_effects({"fans": 4, "pelatih": -3, "energy": 6})
		finished.emit()
		queue_free()
	)
	btn_hb.add_child(b2)

# ---------------------------------------------------------------------------
# 8. PRE-MATCH: LORONG STADION (PREMATCH TUNNEL HYPE BEFORE KICKOFF)
# ---------------------------------------------------------------------------
func _build_prematch_tunnel() -> void:
	_add_backdrop("res://assets/sprites/backgrounds/locker_room.png")
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 110
	vb.offset_right = -110
	vb.offset_top = 24
	vb.offset_bottom = -18
	vb.add_theme_constant_override("separation", 10)
	_stage.add_child(vb)

	var club: Dictionary = CareerState.get_current_club()
	var fx: Dictionary = CareerState.get_current_fixture()
	var opp_id: int = int(fx.get("opp_club_id", 0))

	var banner := PanelContainer.new()
	banner.add_theme_stylebox_override("panel", UITheme.make_box(Color("#102236"), UITheme.ACCENT_GOLD, 2, 10))
	vb.add_child(banner)
	var vs_hb := HBoxContainer.new()
	vs_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	vs_hb.add_theme_constant_override("separation", 16)
	banner.add_child(vs_hb)
	var cr_h := ClubCrest.new()
	cr_h.custom_minimum_size = Vector2(42, 42)
	cr_h.set_club(int(club["id"]))
	vs_hb.add_child(cr_h)
	var vs_l := Label.new()
	vs_l.text = "PEKAN %d • %s\n%s  VS  %s" % [
		int(CareerState.career.get("careerMeta", {}).get("week", 1)),
		str(fx.get("comp_label", "LIGA")).to_upper(),
		str(club["code"]),
		str(fx.get("opp_code", "OPP")),
	]
	vs_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vs_l.add_theme_font_override("font", UITheme.get_display_font())
	vs_l.add_theme_font_size_override("font_size", 14)
	vs_l.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	vs_hb.add_child(vs_l)
	var cr_a := ClubCrest.new()
	cr_a.custom_minimum_size = Vector2(42, 42)
	cr_a.set_club(opp_id)
	vs_hb.add_child(cr_a)

	var av_hb := HBoxContainer.new()
	av_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	av_hb.add_theme_constant_override("separation", 24)
	vb.add_child(av_hb)

	var cap_av := PixelAvatar.new()
	cap_av.custom_minimum_size = Vector2(92, 138)
	cap_av.configure_from_seed(55 + int(club["id"]), club, 4)
	cap_av.anim_mode = "TALK"
	av_hb.add_child(cap_av)

	var you_av := PixelAvatar.new()
	you_av.custom_minimum_size = Vector2(108, 160)
	you_av.configure_from_career()
	you_av.show_number_badge = true
	you_av.anim_mode = "CHEER"
	av_hb.add_child(you_av)

	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(sp)

	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UITheme.make_box(Color("#0D1522", 0.95), UITheme.BORDER_CYAN, 2, 10))
	vb.add_child(box)
	var bvb := VBoxContainer.new()
	bvb.add_theme_constant_override("separation", 8)
	box.add_child(bvb)

	var tl := Label.new()
	tl.text = "LORONG STADION • MENJELANG KICK-OFF\nKapten menepuk pundakmu sebelum keluar terowongan. Pilih mentalitas tim!"
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bvb.add_child(tl)

	var c_hb := HBoxContainer.new()
	c_hb.add_theme_constant_override("separation", 8)
	bvb.add_child(c_hb)

	var atk_b := Button.new()
	atk_b.text = "GAS MENYERANG!\n(+4 ENERGI • +3 FANS)"
	atk_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	atk_b.custom_minimum_size = Vector2(0, 58)
	UITheme.style_btn(atk_b, Color("#17462E"), UITheme.ACCENT_GREEN, 12)
	atk_b.pressed.connect(func():
		AudioSynth.play_click()
		CareerState.apply_cutscene_effects({"energy": 4, "fans": 3})
		finished.emit()
		queue_free()
	)
	c_hb.add_child(atk_b)

	var ctrl_b := Button.new()
	ctrl_b.text = "MAIN DISIPLIN\n(+4 PELATIH • +15 XP)"
	ctrl_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ctrl_b.custom_minimum_size = Vector2(0, 58)
	UITheme.style_btn(ctrl_b, Color("#173B66"), UITheme.ACCENT_CYAN, 12)
	ctrl_b.pressed.connect(func():
		AudioSynth.play_click()
		CareerState.apply_cutscene_effects({"pelatih": 4, "xp": 15})
		finished.emit()
		queue_free()
	)
	c_hb.add_child(ctrl_b)

# ---------------------------------------------------------------------------
# 9. POST-MATCH: ANIMATED MVP SHOWCASE
# ---------------------------------------------------------------------------
func _build_mvp_showcase() -> void:
	_add_backdrop("res://assets/sprites/backgrounds/press_wall.png")
	_spawn_confetti(UITheme.ACCENT_GOLD)

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 110
	vb.offset_right = -110
	vb.offset_top = 24
	vb.offset_bottom = -18
	vb.add_theme_constant_override("separation", 10)
	_stage.add_child(vb)

	var hdr := PanelContainer.new()
	hdr.pivot_offset = Vector2(220, 26)
	hdr.add_theme_stylebox_override("panel", UITheme.make_box(Color("#4E320E"), UITheme.ACCENT_GOLD, 2, 10))
	vb.add_child(hdr)
	hdr.scale = Vector2(0.85, 0.85)
	create_tween().tween_property(hdr, "scale", Vector2.ONE, 0.30).set_trans(Tween.TRANS_BACK)
	var hl := Label.new()
	hl.text = "* BINTANG LAGA  -  PEMAIN TERBAIK *"
	hl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hl.add_theme_font_override("font", UITheme.get_display_font())
	hl.add_theme_font_size_override("font_size", 16)
	hl.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	hdr.add_child(hl)

	var av_hb := HBoxContainer.new()
	av_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	av_hb.add_theme_constant_override("separation", 16)
	vb.add_child(av_hb)

	var club := CareerState.get_current_club()
	var mate1 := PixelAvatar.new()
	mate1.custom_minimum_size = Vector2(72, 108)
	mate1.configure_from_seed(11 + int(club["id"]), club, 6)
	mate1.anim_mode = "CHEER"
	av_hb.add_child(mate1)

	var mvp_av := PixelAvatar.new()
	mvp_av.custom_minimum_size = Vector2(124, 184)
	mvp_av.configure_from_career()
	mvp_av.show_number_badge = true
	mvp_av.show_mvp_trophy = true
	mvp_av.anim_mode = "MVP"
	av_hb.add_child(mvp_av)

	var mate2 := PixelAvatar.new()
	mate2.custom_minimum_size = Vector2(74, 112)
	mate2.configure_from_seed(33 + int(club["id"]), club, 18)
	mate2.anim_mode = "CHEER"
	mate2.anim_phase = 1.4
	av_hb.add_child(mate2)

	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(sp)

	var lm: Dictionary = CareerState.career.get("lastMatch", {})
	var rating := float(lm.get("rating", 8.2))
	var mg := int(lm.get("my_goals", 1))
	var ma := int(lm.get("my_assists", 0))

	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UITheme.make_box(Color("#0D1828", 0.96), UITheme.ACCENT_GOLD, 2, 12))
	vb.add_child(box)
	var bvb := VBoxContainer.new()
	bvb.add_theme_constant_override("separation", 8)
	box.add_child(bvb)

	var sl := Label.new()
	sl.text = "%s DINOBATKAN MVP!\nRATING %.1f  |  %d GOL  |  %d ASSIST" % [
		str(CareerState.career.get("playerProfile", {}).get("name", "PEMAIN")).to_upper(),
		rating,
		mg,
		ma,
	]
	sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sl.add_theme_color_override("font_color", Color.WHITE)
	bvb.add_child(sl)

	var claim_b := Button.new()
	claim_b.text = "TERIMA TROFI MVP (+4 FANS • +45 XP)"
	claim_b.custom_minimum_size = Vector2(0, 48)
	UITheme.style_btn(claim_b, Color("#4E320E"), UITheme.ACCENT_GOLD, 14)
	claim_b.pressed.connect(func():
		AudioSynth.play_achievement()
		CareerState.apply_cutscene_effects({"fans": 4, "xp": 45, "followers": 380})
		finished.emit()
		queue_free()
	)
	bvb.add_child(claim_b)
