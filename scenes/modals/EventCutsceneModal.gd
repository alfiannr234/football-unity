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
	TEKEN_JERSEY,
	PREMATCH_PREDIKSI,
	LEMPAKAN_JERSEY,
	GUNTUR_DRUM,
	SCOUT_DOSSIER,
}

var _mode: CutsceneMode = CutsceneMode.TIM_INTI
var _stage: Control

# Global cutscene FX timers
var _fx_time: float = 0.0
var _clap_snap_timer: float = 0.0
var _live_lbl: Label
var _confetti_layer: Control
var _confetti_items: Array[Dictionary] = []

# Signature clapperboard / jersey draw state
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

# New 3: Shirt-throw slingshot & Guntur drum rhythm state
var _throw_canvas: Control
var _throw_dragging: bool = false
var _throw_start: Vector2 = Vector2.ZERO
var _throw_cur: Vector2 = Vector2.ZERO
var _throw_launched: bool = false
var _throw_done: bool = false
var _throw_pos: Vector2 = Vector2.ZERO
var _throw_vel: Vector2 = Vector2.ZERO
var _throw_target: Vector2 = Vector2.ZERO
var _throw_status_lbl: Label
var _throw_next_btn: Button

var _drum_active: bool = false
var _drum_canvas: Control
var _drum_track: Control
var _drum_timer: float = 0.0
var _drum_hits: int = 0
var _drum_pulse: float = 0.0
var _drum_beats: Array[Dictionary] = []
var _drum_dots_lbl: Label
var _drum_next_btn: Button
var _drum_tap_btn: Button

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
	_drum_active = false
	_throw_dragging = false
	_throw_launched = false
	_throw_done = false
	_clap_snap_timer = 0.0
	_live_lbl = null
	_confetti_layer = null
	_confetti_items.clear()
	_sig_pad = null
	_sing_canvas = null
	_sing_avatar = null
	_throw_canvas = null
	_throw_status_lbl = null
	_throw_next_btn = null
	_drum_canvas = null
	_drum_track = null
	_drum_dots_lbl = null
	_drum_next_btn = null
	_drum_tap_btn = null
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
		CutsceneMode.TEKEN_JERSEY:
			_build_teken_jersey()
		CutsceneMode.PREMATCH_PREDIKSI:
			_build_prematch_prediksi()
		CutsceneMode.LEMPAKAN_JERSEY:
			_build_lempakan_jersey()
		CutsceneMode.GUNTUR_DRUM:
			_build_guntur_drum()
		CutsceneMode.SCOUT_DOSSIER:
			_build_scout_dossier()

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
	if is_instance_valid(_throw_canvas):
		if _throw_launched and not _throw_done:
			_throw_vel.y += 420.0 * delta
			_throw_pos += _throw_vel * delta
			if _throw_pos.distance_to(_throw_target) < 42.0 or _throw_pos.y < 145.0 or _throw_pos.x < 10.0 or _throw_pos.x > _throw_canvas.size.x - 10.0 or _throw_pos.y > _throw_canvas.size.y:
				_finish_jersey_throw(_throw_pos.distance_to(_throw_target) < 85.0)
		_throw_canvas.queue_redraw()
	if _drum_active:
		_drum_timer += delta
		_drum_pulse = maxf(0.0, _drum_pulse - delta * 3.5)
		if is_instance_valid(_drum_canvas):
			_drum_canvas.queue_redraw()
		if is_instance_valid(_drum_track):
			_drum_track.queue_redraw()
		if _drum_timer >= 6.8:
			_finish_guntur_drum()
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


# ---------------------------------------------------------------------------
# 10. NEW 3: TEKEN JERSEY (AIRPORT TERMINAL AUTOGRAPH MINIGAME + SUMMARY)
# ---------------------------------------------------------------------------
func _build_teken_jersey() -> void:
	_sig_strokes.clear()
	_sig_drawing = false
	var club: Dictionary = CareerState.get_current_club()
	var prof: Dictionary = CareerState.career.get("playerProfile", {}) if CareerState.has_active_career else {}
	var pname: String = str(prof.get("name", "PEMAIN")).to_upper()
	var last_n: String = pname.split(" ")[-1].left(10)
	var shirt_num: int = int(prof.get("appearance", {}).get("shirt_num", 9))
	var kit_pri: Color = club.get("kit_primary", Color("#C81D25"))
	var kit_sec: Color = club.get("kit_secondary", Color.WHITE)

	# Stylized Airport Terminal Background (glass windows + red/white airplane tail + departure board)
	var term_bg := Control.new()
	term_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	term_bg.draw.connect(func():
		var sz := term_bg.size
		term_bg.draw_rect(Rect2(Vector2.ZERO, sz), Color("#152030"))
		# Terminal panoramic glass window & sky
		term_bg.draw_rect(Rect2(40, 20, sz.x - 160, sz.y * 0.52), Color("#385678"))
		term_bg.draw_rect(Rect2(40, sz.y * 0.36, sz.x - 160, sz.y * 0.16), Color("#26394D"))
		# Airplane tail outside glass
		var tail_pts := PackedVector2Array([Vector2(sz.x - 240, sz.y * 0.36), Vector2(sz.x - 180, sz.y * 0.14), Vector2(sz.x - 140, sz.y * 0.14), Vector2(sz.x - 165, sz.y * 0.36)])
		term_bg.draw_colored_polygon(tail_pts, Color("#E63946"))
		term_bg.draw_rect(Rect2(sz.x - 320, sz.y * 0.30, 175, 22), Color("#F1F5F9"))
		# Glass mullions
		for mx in [40.0, 260.0, 490.0, 720.0]:
			term_bg.draw_rect(Rect2(mx, 20, 8, sz.y * 0.52), Color("#1C2C3E"))
		# Departure board on right edge
		term_bg.draw_rect(Rect2(sz.x - 108, 22, 92, 130), Color("#0C131F"))
		for r in range(5):
			term_bg.draw_rect(Rect2(sz.x - 98, 36 + r * 20, 72, 9), Color("#F59E0B") if r == 0 else Color("#475569"))
		# Dim overlay
		term_bg.draw_rect(Rect2(Vector2.ZERO, sz), Color(0.03, 0.06, 0.12, 0.55))
	)
	_stage.add_child(term_bg)

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 170
	vb.offset_right = -170
	vb.offset_top = 18
	vb.offset_bottom = -16
	vb.add_theme_constant_override("separation", 8)
	_stage.add_child(vb)

	var t_lbl := Label.new()
	t_lbl.text = "TEKEN JERSEY"
	t_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t_lbl.add_theme_font_override("font", UITheme.get_display_font())
	t_lbl.add_theme_font_size_override("font_size", 22)
	vb.add_child(t_lbl)

	var s_lbl := Label.new()
	s_lbl.text = "Tanda tangan dengan jari atau mouse di atas jersey"
	s_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s_lbl.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	s_lbl.add_theme_font_size_override("font_size", 12)
	vb.add_child(s_lbl)

	# Interactive Pixel Jersey Drawing Canvas
	_sig_pad = Control.new()
	_sig_pad.custom_minimum_size = Vector2(320, 270)
	_sig_pad.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_sig_pad.mouse_filter = Control.MOUSE_FILTER_STOP
	_sig_pad.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
			if ev.pressed:
				_sig_drawing = true
				_sig_strokes.append(PackedVector2Array([ev.position]))
				_sig_pad.queue_redraw()
			else:
				_sig_drawing = false
		elif ev is InputEventMouseMotion and _sig_drawing and not _sig_strokes.is_empty():
			var cur: PackedVector2Array = _sig_strokes[_sig_strokes.size() - 1]
			cur.append(ev.position)
			_sig_strokes[_sig_strokes.size() - 1] = cur
			_sig_pad.queue_redraw()
	)
	_sig_pad.draw.connect(func():
		var sz := _sig_pad.size
		var cx := sz.x * 0.5
		var top_y := 12.0
		var body_w := 176.0
		var body_h := sz.y - 24.0
		# Pixel jersey silhouette (black outline + kit primary + collar + sleeves)
		_sig_pad.draw_rect(Rect2(cx - body_w * 0.5 - 52, top_y + 18, body_w + 104, 82), Color("#0A0D12"))
		_sig_pad.draw_rect(Rect2(cx - body_w * 0.5 - 8, top_y, body_w + 16, body_h), Color("#0A0D12"))
		_sig_pad.draw_rect(Rect2(cx - body_w * 0.5 - 44, top_y + 26, body_w + 88, 66), kit_pri)
		_sig_pad.draw_rect(Rect2(cx - body_w * 0.5, top_y + 8, body_w, body_h - 16), kit_pri)
		# Shading & collar
		_sig_pad.draw_rect(Rect2(cx - body_w * 0.5, top_y + body_h - 32, body_w, 24), kit_pri.darkened(0.22))
		_sig_pad.draw_rect(Rect2(cx - 28, top_y + 8, 56, 14), Color("#111827"))
		_sig_pad.draw_rect(Rect2(cx - body_w * 0.5 - 44, top_y + 82, 44, 10), kit_sec)
		_sig_pad.draw_rect(Rect2(cx + body_w * 0.5, top_y + 82, 44, 10), kit_sec)
		# Back name & big shirt number
		var fnt := UITheme.get_display_font()
		_sig_pad.draw_string(fnt, Vector2(cx - 72, top_y + 62), last_n, HORIZONTAL_ALIGNMENT_CENTER, 144, 22, Color.WHITE)
		_sig_pad.draw_string(fnt, Vector2(cx - 72, top_y + 158), str(shirt_num), HORIZONTAL_ALIGNMENT_CENTER, 144, 78, Color.WHITE)
		# User ink strokes
		for st in _sig_strokes:
			if st.size() >= 2:
				_sig_pad.draw_polyline(st, Color("#F8FAFC"), 4.0, true)
			elif st.size() == 1:
				_sig_pad.draw_circle(st[0], 2.5, Color("#F8FAFC"))
	)
	vb.add_child(_sig_pad)

	var btn_hb := HBoxContainer.new()
	btn_hb.add_theme_constant_override("separation", 10)
	vb.add_child(btn_hb)

	var clear_b := Button.new()
	clear_b.text = "HAPUS TTD"
	clear_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clear_b.custom_minimum_size = Vector2(0, 42)
	UITheme.style_btn(clear_b, Color("#5E2D28"), Color("#B45348"), 13)
	clear_b.pressed.connect(func():
		AudioSynth.play_click()
		_sig_strokes.clear()
		if is_instance_valid(_sig_pad):
			_sig_pad.queue_redraw()
	)
	btn_hb.add_child(clear_b)

	var ok_b := Button.new()
	ok_b.text = "LANJUTKAN (+2 Suporter  -2 Pelatih)"
	ok_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ok_b.custom_minimum_size = Vector2(0, 42)
	UITheme.style_btn(ok_b, Color("#112238"), UITheme.ACCENT_GREEN, 12)
	ok_b.pressed.connect(func():
		AudioSynth.play_achievement()
		CareerState.apply_cutscene_effects({"fans": 2, "pelatih": -2, "followers": 120})
		var total_ttd: int = CareerState.increment_autographs()
		var card_res: Dictionary = CareerState.unlock_album_card("ttd_terminal")
		_build_teken_jersey_summary(total_ttd, card_res)
	)
	btn_hb.add_child(ok_b)

	var rej_b := Button.new()
	rej_b.text = "TOLAK (-2 Suporter)"
	rej_b.custom_minimum_size = Vector2(0, 36)
	UITheme.style_btn(rej_b, Color("#A44038"), Color("#E6675D"), 13)
	rej_b.pressed.connect(func():
		AudioSynth.play_click()
		CareerState.apply_cutscene_effects({"fans": -2})
		finished.emit()
		queue_free()
	)
	vb.add_child(rej_b)

func _build_teken_jersey_summary(total_ttd: int, card_res: Dictionary) -> void:
	_clear_stage()
	var rel: Dictionary = CareerState.career.get("playerProfile", {}).get("relations", {"pelatih": 46, "fans": 34}) if CareerState.has_active_career else {"pelatih": 46, "fans": 34}
	var club: Dictionary = CareerState.get_current_club()

	var bg := ColorRect.new()
	bg.color = Color("#162334")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stage.add_child(bg)

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 150
	vb.offset_right = -150
	vb.offset_top = 18
	vb.offset_bottom = -16
	vb.add_theme_constant_override("separation", 10)
	_stage.add_child(vb)

	# Top Relationship Delta Bars (Pelatih -2, Suporter +2)
	var rel_card := PanelContainer.new()
	rel_card.add_theme_stylebox_override("panel", UITheme.make_box(Color("#121A26", 0.94), UITheme.BORDER_STEEL, 1, 8))
	vb.add_child(rel_card)
	var rvb := VBoxContainer.new()
	rvb.add_theme_constant_override("separation", 6)
	rel_card.add_child(rvb)
	for row_d in [
		{"name": "Pelatih", "delta": "-2", "dcol": UITheme.ACCENT_RED, "val": int(rel.get("pelatih", 46))},
		{"name": "Suporter", "delta": "+2", "dcol": UITheme.ACCENT_GREEN, "val": int(rel.get("fans", 34))},
	]:
		var rhb := HBoxContainer.new()
		rhb.add_theme_constant_override("separation", 10)
		rvb.add_child(rhb)
		var nl := Label.new()
		nl.text = str(row_d["name"])
		nl.custom_minimum_size = Vector2(96, 0)
		rhb.add_child(nl)
		var dl := Label.new()
		dl.text = "%s  (%d)" % [str(row_d["delta"]), int(row_d["val"])]
		dl.custom_minimum_size = Vector2(76, 0)
		dl.add_theme_color_override("font_color", row_d["dcol"])
		rhb.add_child(dl)
		var bar_bg := ColorRect.new()
		bar_bg.color = Color("#243040")
		bar_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar_bg.custom_minimum_size = Vector2(180, 12)
		bar_bg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		rhb.add_child(bar_bg)
		var bar_f := ColorRect.new()
		bar_f.color = UITheme.ACCENT_GREEN if int(row_d["val"]) >= 55 else Color("#D94A4A")
		bar_f.set_anchors_preset(Control.PRESET_LEFT_WIDE)
		bar_f.anchor_right = clampf(float(row_d["val"]) / 100.0, 0.04, 1.0)
		bar_bg.add_child(bar_f)

	# Fan + Signed Mini Jersey + Player in Terminal
	var scene_hb := HBoxContainer.new()
	scene_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	scene_hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scene_hb.add_theme_constant_override("separation", 36)
	vb.add_child(scene_hb)

	var fan_av := PixelAvatar.new()
	fan_av.custom_minimum_size = Vector2(96, 144)
	fan_av.configure_from_seed(77, club, 12)
	fan_av.anim_mode = "CHEER"
	scene_hb.add_child(fan_av)

	var u_av := PixelAvatar.new()
	u_av.custom_minimum_size = Vector2(104, 154)
	u_av.configure_from_career()
	u_av.anim_mode = "TALK"
	scene_hb.add_child(u_av)

	# Bottom Crimson Card: TTD DI TERMINAL
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UITheme.make_box(Color("#241218", 0.96), Color("#D94A4A"), 2, 10))
	vb.add_child(card)
	var cvb := VBoxContainer.new()
	cvb.add_theme_constant_override("separation", 6)
	card.add_child(cvb)

	var h1 := Label.new()
	h1.text = "TTD DI TERMINAL"
	h1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h1.add_theme_font_override("font", UITheme.get_display_font())
	h1.add_theme_font_size_override("font_size", 18)
	cvb.add_child(h1)

	var h2 := Label.new()
	h2.text = "Tim menunggu semenit di gerbang."
	h2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h2.add_theme_color_override("font_color", Color("#E2E8F0"))
	cvb.add_child(h2)

	var h3 := Label.new()
	h3.text = "%d TANDA TANGAN SEPANJANG KARIER" % total_ttd
	h3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h3.add_theme_color_override("font_color", Color("#F87171"))
	h3.add_theme_font_override("font", UITheme.get_display_font())
	cvb.add_child(h3)

	var next_b := Button.new()
	next_b.text = "LANJUTKAN"
	next_b.custom_minimum_size = Vector2(0, 42)
	UITheme.style_btn(next_b, Color("#1A1320"), Color("#D94A4A"), 14)
	next_b.pressed.connect(func():
		AudioSynth.play_click()
		if bool(card_res.get("newly_unlocked", false)):
			_build_kartu_baru_overlay(card_res)
		else:
			finished.emit()
			queue_free()
	)
	cvb.add_child(next_b)

# ---------------------------------------------------------------------------
# 11. NEW 3: PRE-MATCH PREDIKSI SPLIT-SCREEN + TOP SKOR SPOTLIGHT
# ---------------------------------------------------------------------------
func _build_prematch_prediksi() -> void:
	var club: Dictionary = CareerState.get_current_club()
	var fix: Dictionary = CareerState.get_current_fixture()
	var meta: Dictionary = CareerState.career.get("careerMeta", {}) if CareerState.has_active_career else {}
	var st: Dictionary = CareerState.career.get("stats", {}) if CareerState.has_active_career else {}
	var prof: Dictionary = CareerState.career.get("playerProfile", {}) if CareerState.has_active_career else {}
	var wk: int = int(meta.get("week", 1))
	var opp_id: int = int(fix.get("opp_club_id", int(club["id"]) + 1))
	var opp_club: Dictionary = GameData.clubs[clampi(opp_id, 0, GameData.clubs.size() - 1)]
	var u_ovr: int = int(club.get("ovr", 62))
	var o_ovr: int = int(fix.get("opp_ovr", opp_club.get("ovr", 62)))
	var diff: float = clampf(float(o_ovr - u_ovr) * 0.03, -0.28, 0.28)
	var draw_pct: int = clampi(24 - int(absf(diff) * 20.0), 16, 28)
	var opp_pct: int = clampi(int(round((0.5 + diff) * float(100 - draw_pct))), 14, 72)
	var us_pct: int = 100 - draw_pct - opp_pct
	var leaders: Dictionary = CareerState.get_division_leaders()

	# Dusk Pitch Backdrop
	var dusk := ColorRect.new()
	dusk.color = Color("#1F171A")
	dusk.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stage.add_child(dusk)

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 24
	vb.offset_right = -24
	vb.offset_top = 14
	vb.offset_bottom = -14
	vb.add_theme_constant_override("separation", 10)
	_stage.add_child(vb)

	# Header Pill
	var hdr := PanelContainer.new()
	hdr.add_theme_stylebox_override("panel", UITheme.make_box(Color("#9F1239"), Color("#FB7185"), 2, 6))
	vb.add_child(hdr)
	var hl := Label.new()
	hl.text = "PREDIKSI  •  %s  •  PEKAN %d" % [str(fix.get("comp_label", "LIGA")).to_upper(), wk]
	hl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hl.add_theme_font_override("font", UITheme.get_display_font())
	hl.add_theme_font_size_override("font_size", 16)
	hdr.add_child(hl)

	# Main Split: Left Opponent Pitch | Center Prediction Card | Right User Pitch
	var mid_hb := HBoxContainer.new()
	mid_hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid_hb.add_theme_constant_override("separation", 12)
	vb.add_child(mid_hb)

	# Opponent Side Panel
	var opp_p := PanelContainer.new()
	opp_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opp_p.add_theme_stylebox_override("panel", UITheme.make_box(Color("#2D2218"), Color("#F97316"), 2, 8))
	mid_hb.add_child(opp_p)
	var ovb := VBoxContainer.new()
	ovb.alignment = BoxContainer.ALIGNMENT_CENTER
	ovb.add_theme_constant_override("separation", 6)
	opp_p.add_child(ovb)
	var o_av := PixelAvatar.new()
	o_av.custom_minimum_size = Vector2(96, 140)
	o_av.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	o_av.configure_from_seed(opp_id * 7 + 5, opp_club, 5)
	o_av.anim_mode = "IDLE"
	ovb.add_child(o_av)
	var o_lbl := Label.new()
	o_lbl.text = "%s\nOVR %d  •  %d%% %s" % [str(fix.get("opp_code", "OPP")).to_upper(), o_ovr, opp_pct, ("FAVORIT" if opp_pct > us_pct else "")]
	o_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	o_lbl.add_theme_font_override("font", UITheme.get_display_font())
	o_lbl.add_theme_color_override("font_color", Color("#FDBA74"))
	ovb.add_child(o_lbl)

	# Center Crimson Prediction Card
	var pred := PanelContainer.new()
	pred.custom_minimum_size = Vector2(360, 0)
	pred.add_theme_stylebox_override("panel", UITheme.make_box(Color("#7A0F28"), Color("#F43F5E"), 2, 10))
	mid_hb.add_child(pred)
	var pvb := VBoxContainer.new()
	pvb.alignment = BoxContainer.ALIGNMENT_CENTER
	pvb.add_theme_constant_override("separation", 8)
	pred.add_child(pvb)

	var crest_hb := HBoxContainer.new()
	crest_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	crest_hb.add_theme_constant_override("separation", 18)
	pvb.add_child(crest_hb)
	var oc := ClubCrest.new()
	oc.custom_minimum_size = Vector2(44, 44)
	oc.set_club(opp_id)
	crest_hb.add_child(oc)
	var vs_l := Label.new()
	vs_l.text = "VS"
	vs_l.add_theme_font_override("font", UITheme.get_display_font())
	vs_l.add_theme_font_size_override("font_size", 20)
	crest_hb.add_child(vs_l)
	var uc := ClubCrest.new()
	uc.custom_minimum_size = Vector2(44, 44)
	uc.set_club(int(club["id"]))
	crest_hb.add_child(uc)

	var pct_hb := HBoxContainer.new()
	pct_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	pct_hb.add_theme_constant_override("separation", 16)
	pvb.add_child(pct_hb)
	for pt_d in [
		{"t": "%d%%\n%s" % [opp_pct, str(fix.get("opp_code", "OPP"))], "c": Color("#FB923C")},
		{"t": "%d%%\nSERI" % draw_pct, "c": Color("#E2E8F0")},
		{"t": "%d%%\n%s" % [us_pct, str(club.get("code", "TIM"))], "c": UITheme.ACCENT_GOLD},
	]:
		var pl := Label.new()
		pl.text = str(pt_d["t"])
		pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pl.add_theme_font_override("font", UITheme.get_display_font())
		pl.add_theme_font_size_override("font_size", 16)
		pl.add_theme_color_override("font_color", pt_d["c"])
		pct_hb.add_child(pl)

	# Stacked 3-segment probability bar
	var prob_bar := HBoxContainer.new()
	prob_bar.custom_minimum_size = Vector2(0, 14)
	prob_bar.add_theme_constant_override("separation", 2)
	pvb.add_child(prob_bar)
	for seg_d in [
		{"w": float(opp_pct), "c": Color("#F97316")},
		{"w": float(draw_pct), "c": Color("#CBD5E1")},
		{"w": float(us_pct), "c": Color("#DC2626")},
	]:
		var seg := ColorRect.new()
		seg.color = seg_d["c"]
		seg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		seg.size_flags_stretch_ratio = maxf(0.1, float(seg_d["w"]))
		prob_bar.add_child(seg)

	var form_l := Label.new()
	form_l.text = "FORM:  K M M S M   |   M S K M M\n★ %s %d GOL" % [str(prof.get("name", "PEMAIN")).to_upper(), int(st.get("goals", 0))]
	form_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	form_l.add_theme_font_size_override("font_size", 11)
	pvb.add_child(form_l)

	# User Side Panel
	var us_p := PanelContainer.new()
	us_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	us_p.add_theme_stylebox_override("panel", UITheme.make_box(Color("#1A2436"), UITheme.ACCENT_GOLD, 2, 8))
	mid_hb.add_child(us_p)
	var uvb := VBoxContainer.new()
	uvb.alignment = BoxContainer.ALIGNMENT_CENTER
	uvb.add_theme_constant_override("separation", 6)
	us_p.add_child(uvb)
	var u_av := PixelAvatar.new()
	u_av.custom_minimum_size = Vector2(96, 140)
	u_av.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	u_av.configure_from_career()
	u_av.show_number_badge = true
	u_av.anim_mode = "CHEER"
	uvb.add_child(u_av)
	var u_lbl := Label.new()
	u_lbl.text = "%s\nOVR %d  •  %d%% %s" % [str(club.get("code", "TIM")).to_upper(), u_ovr, us_pct, ("FAVORIT" if us_pct >= opp_pct else "")]
	u_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	u_lbl.add_theme_font_override("font", UITheme.get_display_font())
	u_lbl.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	uvb.add_child(u_lbl)

	# Bottom Row: TOP SKOR Spotlight Card (Screenshot 6) + Launch Button
	var bot_hb := HBoxContainer.new()
	bot_hb.add_theme_constant_override("separation", 12)
	vb.add_child(bot_hb)

	var spot := PanelContainer.new()
	spot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spot.add_theme_stylebox_override("panel", UITheme.make_box(Color("#6A0D27"), Color("#F43F5E"), 2, 8))
	bot_hb.add_child(spot)
	var svb := VBoxContainer.new()
	svb.add_theme_constant_override("separation", 4)
	spot.add_child(svb)
	var u_g: int = int(st.get("goals", 0))
	var u_a: int = int(st.get("assists", 0))
	var u_m: int = int(st.get("matches", 0))
	var u_r: float = snappedf(float(st.get("totalRating", 6.5)) / float(maxi(1, u_m)), 0.1) if u_m > 0 else 6.5
	var top_g: int = int(leaders.get("top_goals", maxi(1, u_g)))
	var g_rank: int = int(leaders.get("user_goal_rank", 1))
	var sl1 := Label.new()
	sl1.text = "TOP SKOR ke-%d  •  %s  (%d GOL / PUNCAK %d)" % [g_rank, str(prof.get("name", "PEMAIN")).to_upper(), u_g, top_g]
	sl1.add_theme_font_override("font", UITheme.get_display_font())
	sl1.add_theme_font_size_override("font_size", 13)
	svb.add_child(sl1)
	var sl2 := Label.new()
	sl2.text = "ASSIST %d   •   MAIN %d   •   RATING %.1f" % [u_a, u_m, u_r]
	sl2.add_theme_color_override("font_color", Color("#FECDD3"))
	sl2.add_theme_font_size_override("font_size", 11)
	svb.add_child(sl2)

	var go_b := Button.new()
	go_b.text = "MASUK LAPANGAN >"
	go_b.custom_minimum_size = Vector2(220, 52)
	UITheme.style_btn(go_b, Color("#0E5A38"), UITheme.ACCENT_GREEN, 15)
	go_b.pressed.connect(func():
		AudioSynth.play_whistle(false)
		finished.emit()
		queue_free()
	)
	bot_hb.add_child(go_b)

# ---------------------------------------------------------------------------
# 12. NEW 3: LEMPAKAN JERSEY (POST-MATCH SHIRT-THROW SLINGSHOT INTO STANDS)
# ---------------------------------------------------------------------------
func _build_lempakan_jersey() -> void:
	_throw_dragging = false
	_throw_launched = false
	_throw_done = false
	var club: Dictionary = CareerState.get_current_club()
	var prof: Dictionary = CareerState.career.get("playerProfile", {}) if CareerState.has_active_career else {}
	var last_n: String = str(prof.get("name", "PEMAIN")).to_upper().split(" ")[-1].left(8)
	var shirt_num: int = int(prof.get("appearance", {}).get("shirt_num", 9))
	var kit_pri: Color = club.get("kit_primary", Color("#C81D25"))
	var kit_sec: Color = club.get("kit_secondary", Color.WHITE)
	var lm: Dictionary = CareerState.last_match_report

	_throw_canvas = Control.new()
	_throw_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_throw_canvas.mouse_filter = Control.MOUSE_FILTER_STOP
	_throw_pos = Vector2(240.0, 355.0)
	_throw_target = Vector2(730.0, 175.0)
	_throw_canvas.gui_input.connect(func(ev: InputEvent):
		if _throw_launched or _throw_done:
			return
		if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
			if ev.pressed:
				_throw_dragging = true
				_throw_start = ev.position
				_throw_cur = ev.position
			elif _throw_dragging:
				_throw_dragging = false
				var d := _throw_start - _throw_cur
				if d.length() > 18.0:
					_throw_launched = true
					_throw_vel = d * 3.8
					_throw_vel.y = minf(_throw_vel.y, -280.0)
					AudioSynth.play_kick(0.7)
		elif ev is InputEventMouseMotion and _throw_dragging:
			_throw_cur = ev.position
	)
	_throw_canvas.draw.connect(func():
		var sz := _throw_canvas.size
		_throw_target = Vector2(sz.x * 0.76, sz.y * 0.36)
		if not _throw_launched:
			_throw_pos = Vector2(sz.x * 0.14, sz.y * 0.59)
		# Sky + Stadium Stands + Wall + Ad Board + Pitch Grass
		_throw_canvas.draw_rect(Rect2(0, 0, sz.x, sz.y * 0.50), Color("#363A48"))
		for r in range(5):
			var fy := 42.0 + float(r) * 40.0
			_throw_canvas.draw_rect(Rect2(0, fy + 20, sz.x, 8), Color("#252936"))
			for c in range(18):
				var fx := 26.0 + float(c) * 52.0 + float(r % 2) * 14.0
				var bob := sin(_fx_time * 5.0 + float(c + r)) * 3.0
				var shirt_c := kit_pri if (c + r) % 3 == 0 else (Color("#334155") if c % 2 == 0 else Color("#64748B"))
				_throw_canvas.draw_rect(Rect2(fx - 10, fy + bob, 20, 18), shirt_c)
				_throw_canvas.draw_rect(Rect2(fx - 7, fy - 12 + bob, 14, 12), Color("#D6A77A") if c % 3 != 0 else Color("#8D5524"))
		# Supporter holding [JERSEY #XX ?] sign at target
		var tx := _throw_target.x
		var ty := _throw_target.y
		var pulse := 1.0 + 0.08 * sin(_fx_time * 6.0)
		_throw_canvas.draw_rect(Rect2(tx - 44 * pulse, ty - 26 * pulse, 88 * pulse, 52 * pulse), Color("#F8FAFC"))
		_throw_canvas.draw_rect(Rect2(tx - 44 * pulse, ty - 26 * pulse, 88 * pulse, 52 * pulse), UITheme.ACCENT_GOLD, false, 3.0)
		_throw_canvas.draw_rect(Rect2(tx - 32, ty - 16, 36, 32), kit_pri)
		var fnt := UITheme.get_display_font()
		_throw_canvas.draw_string(fnt, Vector2(tx - 32, ty + 6), str(shirt_num), HORIZONTAL_ALIGNMENT_CENTER, 36, 16, Color.WHITE)
		_throw_canvas.draw_string(fnt, Vector2(tx + 12, ty + 10), "?", HORIZONTAL_ALIGNMENT_LEFT, 32, 28, Color("#DC2626"))
		# Concrete wall + Ad board + Green Pitch
		_throw_canvas.draw_rect(Rect2(0, sz.y * 0.50, sz.x, 48), Color("#646978"))
		_throw_canvas.draw_rect(Rect2(0, sz.y * 0.50 + 48, sz.x, 36), kit_pri.darkened(0.25))
		_throw_canvas.draw_rect(Rect2(0, sz.y * 0.50 + 84, sz.x, sz.y), Color("#2E8B57"))
		# Shirtless player seen from behind holding jersey overhead (positioned left clear of prompt text)
		var px := sz.x * 0.14
		var py := sz.y * 0.67
		_throw_canvas.draw_rect(Rect2(px - 22, py - 10, 44, 52), Color("#E2B48C"))  # torso
		_throw_canvas.draw_rect(Rect2(px - 24, py + 42, 48, 24), kit_sec)  # shorts
		_throw_canvas.draw_rect(Rect2(px - 14, py - 34, 28, 26), Color("#1E1B18"))  # hair/head
		# Aiming preview dots while dragging
		if _throw_dragging:
			var d := _throw_start - _throw_cur
			if d.length() > 14.0:
				var p0 := _throw_pos
				var v0 := d * 3.8
				v0.y = minf(v0.y, -280.0)
				for s in range(1, 14):
					var tt := float(s) * 0.06
					var pt := p0 + v0 * tt + Vector2(0.0, 210.0 * tt * tt)
					_throw_canvas.draw_circle(pt, 4.0, UITheme.ACCENT_GOLD)
		# Pixel Jersey (held overhead or flying in air!)
		var jp := _throw_pos
		_throw_canvas.draw_rect(Rect2(jp.x - 32, jp.y - 26, 64, 50), Color("#0B0F17"))
		_throw_canvas.draw_rect(Rect2(jp.x - 28, jp.y - 22, 56, 42), kit_pri)
		_throw_canvas.draw_string(fnt, Vector2(jp.x - 26, jp.y - 4), last_n, HORIZONTAL_ALIGNMENT_CENTER, 52, 9, Color.WHITE)
		_throw_canvas.draw_string(fnt, Vector2(jp.x - 26, jp.y + 15), str(shirt_num), HORIZONTAL_ALIGNMENT_CENTER, 52, 18, Color.WHITE)
	)
	_stage.add_child(_throw_canvas)

	# Header pill: LAGA USAI
	var tag := PanelContainer.new()
	tag.set_anchors_preset(Control.PRESET_TOP_LEFT)
	tag.offset_left = 18
	tag.offset_top = 14
	tag.offset_right = 380
	tag.offset_bottom = 68
	tag.add_theme_stylebox_override("panel", UITheme.make_box(Color("#2D1018", 0.92), Color("#F43F5E"), 2, 6))
	_stage.add_child(tag)
	var thb := HBoxContainer.new()
	thb.add_theme_constant_override("separation", 10)
	tag.add_child(thb)
	var cr := ClubCrest.new()
	cr.custom_minimum_size = Vector2(36, 36)
	cr.set_club(int(club["id"]))
	thb.add_child(cr)
	var tl := Label.new()
	tl.text = "LAGA USAI  •  %s\n%d - %d" % [str(club["name"]).to_upper(), int(lm.get("score_us", 2)), int(lm.get("score_them", 0))]
	tl.add_theme_font_override("font", UITheme.get_display_font())
	tl.add_theme_font_size_override("font_size", 12)
	thb.add_child(tl)

	# Bottom Prompt & Continue Button
	var bot := VBoxContainer.new()
	bot.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bot.offset_left = 220
	bot.offset_right = -120
	bot.offset_top = -86
	bot.offset_bottom = -14
	bot.add_theme_constant_override("separation", 6)
	_stage.add_child(bot)

	_throw_status_lbl = Label.new()
	_throw_status_lbl.text = "Tarik ke belakang lalu lepas — lempar jersey ke suporter berpapan tanda!"
	_throw_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_throw_status_lbl.add_theme_color_override("font_color", Color.WHITE)
	bot.add_child(_throw_status_lbl)

	var h_btns := HBoxContainer.new()
	h_btns.alignment = BoxContainer.ALIGNMENT_CENTER
	h_btns.add_theme_constant_override("separation", 10)
	bot.add_child(h_btns)

	var quick_b := Button.new()
	quick_b.text = "LEMPAR CEPAT"
	quick_b.custom_minimum_size = Vector2(180, 38)
	UITheme.style_btn(quick_b, Color("#7A1A28"), UITheme.ACCENT_GOLD, 13)
	quick_b.pressed.connect(func():
		if not _throw_launched and not _throw_done:
			_throw_launched = true
			_throw_vel = Vector2(490.0, -340.0)
			AudioSynth.play_kick(0.75)
	)
	h_btns.add_child(quick_b)

	_throw_next_btn = Button.new()
	_throw_next_btn.text = "LANJUTKAN"
	_throw_next_btn.custom_minimum_size = Vector2(180, 38)
	_throw_next_btn.visible = false
	UITheme.style_btn(_throw_next_btn, Color("#0E5A38"), UITheme.ACCENT_GREEN, 14)
	h_btns.add_child(_throw_next_btn)

func _finish_jersey_throw(bullseye: bool) -> void:
	_throw_done = true
	_throw_launched = false
	var fan_gain: int = 6 if bullseye else 3
	CareerState.apply_cutscene_effects({"fans": fan_gain, "followers": 240 if bullseye else 100})
	var card_res: Dictionary = CareerState.unlock_album_card("lemparan_jersey")
	if bullseye:
		AudioSynth.play_goal()
		_spawn_confetti(UITheme.ACCENT_GOLD)
	else:
		AudioSynth.play_click()
	if is_instance_valid(_throw_status_lbl):
		_throw_status_lbl.text = "TEPAT SASARAN! Suporter menangkap jerseymu! (+%d Suporter)" % fan_gain if bullseye else "Tribun bersorak menerima jerseymu! (+%d Suporter)" % fan_gain
		_throw_status_lbl.add_theme_color_override("font_color", UITheme.ACCENT_GOLD if bullseye else UITheme.ACCENT_GREEN)
	if is_instance_valid(_throw_next_btn):
		_throw_next_btn.visible = true
		_throw_next_btn.pressed.connect(func():
			AudioSynth.play_click()
			if bool(card_res.get("newly_unlocked", false)):
				_build_kartu_baru_overlay(card_res)
			else:
				finished.emit()
				queue_free()
		)

# ---------------------------------------------------------------------------
# 13. NEW 3: GUNTUR (POST-MATCH FAN-CHANT DRUM RHYTHM MINIGAME)
# ---------------------------------------------------------------------------
func _build_guntur_drum() -> void:
	_drum_active = true
	_drum_timer = 0.0
	_drum_hits = 0
	_drum_pulse = 0.0
	_drum_beats = [
		{"t": 1.6, "hit": false},
		{"t": 3.2, "hit": false},
		{"t": 4.8, "hit": false},
	]
	var club: Dictionary = CareerState.get_current_club()
	var prof: Dictionary = CareerState.career.get("playerProfile", {}) if CareerState.has_active_career else {}
	var last_n: String = str(prof.get("name", "PEMAIN")).to_upper().split(" ")[-1].left(8)
	var shirt_num: int = int(prof.get("appearance", {}).get("shirt_num", 9))
	var kit_pri: Color = club.get("kit_primary", Color("#C81D25"))
	var kit_sec: Color = club.get("kit_secondary", Color.WHITE)

	# Upper Stage: Packed Stands + 3 Players Facing Crowd (SILALAHI, USER, PRATAMA)
	_drum_canvas = Control.new()
	_drum_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_drum_canvas.draw.connect(func():
		var sz := _drum_canvas.size
		_drum_canvas.draw_rect(Rect2(0, 0, sz.x, sz.y * 0.62), Color("#1E283A"))
		for r in range(5):
			var fy := 30.0 + float(r) * 34.0
			for c in range(18):
				var fx := 24.0 + float(c) * 52.0
				var jump := _drum_pulse * 12.0 + sin(_fx_time * 6.0 + float(c)) * 2.5
				_drum_canvas.draw_rect(Rect2(fx - 9, fy - jump, 18, 16), kit_pri if (c + r) % 2 == 0 else Color("#475569"))
				_drum_canvas.draw_rect(Rect2(fx - 6, fy - 11 - jump, 12, 11), Color("#D6A77A"))
		_drum_canvas.draw_rect(Rect2(0, sz.y * 0.56, sz.x, sz.y * 0.44), Color("#2B6E48"))
		# 3 Players from behind raising hands to ears
		var trio := [
			{"x": sz.x * 0.30, "n": "SILALAHI", "num": "21"},
			{"x": sz.x * 0.50, "n": last_n, "num": str(shirt_num)},
			{"x": sz.x * 0.70, "n": "PRATAMA", "num": "19"},
		]
		var fnt := UITheme.get_display_font()
		for pl in trio:
			var px: float = float(pl["x"])
			var py: float = sz.y * 0.50 - _drum_pulse * 8.0
			_drum_canvas.draw_rect(Rect2(px - 42, py - 10, 84, 68), Color("#0B0F17"))
			_drum_canvas.draw_rect(Rect2(px - 38, py - 6, 76, 60), kit_pri)
			_drum_canvas.draw_rect(Rect2(px - 28, py + 54, 56, 26), kit_sec)
			_drum_canvas.draw_rect(Rect2(px - 16, py - 34, 32, 28), Color("#1E1B18"))
			_drum_canvas.draw_string(fnt, Vector2(px - 38, py + 12), str(pl["n"]), HORIZONTAL_ALIGNMENT_CENTER, 76, 9, Color.WHITE)
			_drum_canvas.draw_string(fnt, Vector2(px - 38, py + 42), str(pl["num"]), HORIZONTAL_ALIGNMENT_CENTER, 76, 24, Color.WHITE)
	)
	_stage.add_child(_drum_canvas)

	# Bottom Rhythm Panel (GUNTUR • IKUTI DRUM! • HUH!)
	var pan := PanelContainer.new()
	pan.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	pan.offset_left = 180
	pan.offset_right = -180
	pan.offset_top = -188
	pan.offset_bottom = -14
	pan.add_theme_stylebox_override("panel", UITheme.make_box(Color("#1A0F14", 0.94), Color("#DC2626"), 2, 10))
	_stage.add_child(pan)

	var pvb := VBoxContainer.new()
	pvb.add_theme_constant_override("separation", 6)
	pan.add_child(pvb)

	var h1 := Label.new()
	h1.text = "GUNTUR"
	h1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h1.add_theme_font_override("font", UITheme.get_display_font())
	h1.add_theme_font_size_override("font_size", 18)
	pvb.add_child(h1)

	_drum_dots_lbl = Label.new()
	_drum_dots_lbl.text = "○  ○  ○   •   IKUTI DRUM!"
	_drum_dots_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_drum_dots_lbl.add_theme_color_override("font_color", UITheme.ACCENT_CYAN)
	pvb.add_child(_drum_dots_lbl)

	# Horizontal Drum Beat Track
	_drum_track = Control.new()
	_drum_track.custom_minimum_size = Vector2(0, 34)
	_drum_track.draw.connect(func():
		var s := _drum_track.size
		var cy := s.y * 0.5
		var ring_x := 46.0
		_drum_track.draw_line(Vector2(12, cy), Vector2(s.x - 12, cy), Color("#3B4D64"), 2.0)
		_drum_track.draw_arc(Vector2(ring_x, cy), 13.0 + _drum_pulse * 4.0, 0.0, TAU, 24, UITheme.ACCENT_CYAN, 3.0)
		for b in _drum_beats:
			if bool(b["hit"]):
				continue
			var dt_b: float = float(b["t"]) - _drum_timer
			var bx: float = ring_x + dt_b * 135.0
			if bx > 10.0 and bx < s.x - 10.0:
				_drum_track.draw_circle(Vector2(bx, cy), 8.0, Color.WHITE)
	)
	pvb.add_child(_drum_track)

	_drum_tap_btn = Button.new()
	_drum_tap_btn.text = "HUH!"
	_drum_tap_btn.custom_minimum_size = Vector2(0, 42)
	UITheme.style_btn(_drum_tap_btn, Color("#110A0E"), Color("#DC2626"), 18)
	_drum_tap_btn.pressed.connect(func(): _tap_guntur_beat())
	pvb.add_child(_drum_tap_btn)

	_drum_next_btn = Button.new()
	_drum_next_btn.text = "LANJUT"
	_drum_next_btn.disabled = true
	_drum_next_btn.custom_minimum_size = Vector2(0, 30)
	UITheme.style_btn(_drum_next_btn, Color("#1C1A22"), Color("#475569"), 12)
	pvb.add_child(_drum_next_btn)

func _unhandled_input(event: InputEvent) -> void:
	if _drum_active and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			_tap_guntur_beat()

func _tap_guntur_beat() -> void:
	if not _drum_active:
		return
	_drum_pulse = 1.0
	AudioSynth.play_kick(0.95)
	for b in _drum_beats:
		if not bool(b["hit"]) and absf(float(b["t"]) - _drum_timer) <= 0.65:
			b["hit"] = true
			_drum_hits += 1
			AudioSynth.play_ring_tap(true)
			break
	var dots: String = ""
	for i in range(3):
		dots += ("●  " if i < _drum_hits else "○  ")
	if is_instance_valid(_drum_dots_lbl):
		_drum_dots_lbl.text = "%s •   %s" % [dots.strip_edges(), ("GUNTUR SEMPURNA!" if _drum_hits >= 3 else "IKUTI DRUM!")]
	if _drum_hits >= 3:
		_finish_guntur_drum()

func _finish_guntur_drum() -> void:
	if not _drum_active:
		return
	_drum_active = false
	var fan_gain: int = 2 + _drum_hits * 2
	CareerState.apply_cutscene_effects({"fans": fan_gain, "ruangGanti": 3, "followers": 280})
	var card_res: Dictionary = CareerState.unlock_album_card("guntur_tribun")
	if _drum_hits >= 2:
		AudioSynth.play_goal()
		_spawn_confetti(UITheme.ACCENT_CYAN)
	if is_instance_valid(_drum_tap_btn):
		_drum_tap_btn.disabled = true
	if is_instance_valid(_drum_dots_lbl):
		_drum_dots_lbl.text = "SORAK TRIBUN! (+%d Suporter • +3 Ruang Ganti)" % fan_gain
		_drum_dots_lbl.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	if is_instance_valid(_drum_next_btn):
		_drum_next_btn.disabled = false
		UITheme.style_btn(_drum_next_btn, Color("#0E5A38"), UITheme.ACCENT_GREEN, 13)
		_drum_next_btn.pressed.connect(func():
			AudioSynth.play_click()
			if bool(card_res.get("newly_unlocked", false)):
				_build_kartu_baru_overlay(card_res)
			else:
				finished.emit()
				queue_free()
		)

# ---------------------------------------------------------------------------
# 14. NEW 3: SCOUT DOSSIER + KARTU BARU! COLLECTIBLE ALBUM OVERLAY
# ---------------------------------------------------------------------------
func _build_scout_dossier() -> void:
	var prof: Dictionary = CareerState.career.get("playerProfile", {}) if CareerState.has_active_career else {}
	var pname: String = str(prof.get("name", "PEMAIN")).to_upper().split(" ")[-1].left(10)
	var pos_c: String = str(prof.get("naturalPosition", "ST"))
	var age_n: int = int(prof.get("age", 16))
	var scout_club: Dictionary = GameData.clubs[mini(GameData.clubs.size() - 1, maxi(0, int(prof.get("clubId", 0)) + 17))]
	var card_res: Dictionary = CareerState.unlock_album_card("scout_pantau")
	if CareerState.has_active_career:
		CareerState.career["careerMeta"]["scoutedByClubId"] = int(scout_club["id"])
		CareerState.save_active_career()

	# Dark atmospheric room with custom pixel Scout holding dossier
	var room := Control.new()
	room.set_anchors_preset(Control.PRESET_FULL_RECT)
	room.draw.connect(func():
		var sz := room.size
		room.draw_rect(Rect2(Vector2.ZERO, sz), Color("#0A0E17"))
		var cx := sz.x * 0.5
		var cy := sz.y * 0.44
		# Trench coat & shoulders
		room.draw_rect(Rect2(cx - 86, cy - 18, 172, 180), Color("#090B10"))
		room.draw_rect(Rect2(cx - 78, cy - 12, 156, 170), Color("#9E8A63"))
		room.draw_rect(Rect2(cx - 24, cy - 12, 48, 170), Color("#4A3B31"))
		# Head, brown flat cap, glasses & grey beard
		room.draw_rect(Rect2(cx - 48, cy - 118, 96, 30), Color("#5E4332"))  # flat cap
		room.draw_rect(Rect2(cx - 38, cy - 88, 76, 68), Color("#F0B89C"))   # face
		room.draw_rect(Rect2(cx - 34, cy - 66, 28, 18), Color("#2B1F19"))   # left glass
		room.draw_rect(Rect2(cx + 6, cy - 66, 28, 18), Color("#2B1F19"))    # right glass
		room.draw_rect(Rect2(cx - 6, cy - 60, 12, 5), Color("#2B1F19"))     # bridge
		room.draw_rect(Rect2(cx - 32, cy - 40, 64, 24), Color("#94A3B8"))   # grey beard
		# Open scouting dossier held in front of chest
		room.draw_rect(Rect2(cx - 140, cy + 28, 280, 96), Color("#181410"))
		room.draw_rect(Rect2(cx - 134, cy + 34, 128, 84), Color("#D8CEBC"))
		room.draw_rect(Rect2(cx + 6, cy + 34, 128, 84), Color("#E6DEC8"))
		# Crest emblem on left dossier page
		room.draw_circle(Vector2(cx - 70, cy + 76), 30.0, Color("#EAB308"))
		room.draw_circle(Vector2(cx - 70, cy + 76), 14.0, Color("#111827"))
		# Scout notes on right dossier page (NAME / POS AGE / red-underlined PANTAU)
		var fnt := UITheme.get_display_font()
		room.draw_string(fnt, Vector2(cx + 16, cy + 58), pname, HORIZONTAL_ALIGNMENT_LEFT, 114, 13, Color("#1E293B"))
		room.draw_string(fnt, Vector2(cx + 16, cy + 80), "%s  %d" % [pos_c, age_n], HORIZONTAL_ALIGNMENT_LEFT, 114, 13, Color("#334155"))
		room.draw_string(fnt, Vector2(cx + 16, cy + 104), "PANTAU", HORIZONTAL_ALIGNMENT_LEFT, 114, 14, Color("#B91C1C"))
		room.draw_line(Vector2(cx + 16, cy + 109), Vector2(cx + 88, cy + 109), Color("#B91C1C"), 2.5)
	)
	_stage.add_child(room)

	# Top-Left Header Pill: SCOUT + Club Name
	var tag := PanelContainer.new()
	tag.set_anchors_preset(Control.PRESET_TOP_LEFT)
	tag.offset_left = 20
	tag.offset_top = 18
	tag.offset_right = 380
	tag.offset_bottom = 70
	tag.add_theme_stylebox_override("panel", UITheme.make_box(Color("#1F1B12", 0.94), UITheme.ACCENT_GOLD, 2, 6))
	_stage.add_child(tag)
	var thb := HBoxContainer.new()
	thb.add_theme_constant_override("separation", 10)
	tag.add_child(thb)
	var cr := ClubCrest.new()
	cr.custom_minimum_size = Vector2(36, 36)
	cr.set_club(int(scout_club["id"]))
	thb.add_child(cr)
	var tl := Label.new()
	tl.text = "SCOUT\n%s" % str(scout_club["name"]).to_upper()
	tl.add_theme_font_override("font", UITheme.get_display_font())
	tl.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	tl.add_theme_font_size_override("font_size", 12)
	thb.add_child(tl)

	var next_b := Button.new()
	next_b.text = "LANJUTKAN >"
	next_b.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	next_b.offset_left = 300
	next_b.offset_right = -300
	next_b.offset_top = -64
	next_b.offset_bottom = -18
	UITheme.style_btn(next_b, Color("#4E320E"), UITheme.ACCENT_GOLD, 15)
	next_b.pressed.connect(func():
		AudioSynth.play_achievement()
		_build_kartu_baru_overlay(card_res)
	)
	_stage.add_child(next_b)

func _build_kartu_baru_overlay(card_res: Dictionary) -> void:
	_clear_stage()
	_spawn_confetti(UITheme.ACCENT_GOLD)
	var card: Dictionary = card_res.get("card", {"num": 15, "title": "SCOUT", "tier": "PERAK", "quote": "«AKU SUDAH MENGIKUTIMU.»"})
	var owned_n: int = int(card_res.get("owned_count", 1))
	var total_n: int = maxi(1, int(card_res.get("total", 19)))
	var yr: int = int(CareerState.career.get("careerMeta", {}).get("year", 1)) if CareerState.has_active_career else 1
	var tier_s: String = str(card.get("tier", "PERAK"))
	var tier_col: Color = Color("#CBD5E1") if tier_s == "PERAK" else (UITheme.ACCENT_GOLD if tier_s == "EMAS" else (Color("#C084FC") if tier_s == "LEGENDARIS" else Color("#D97706")))

	# Radial Sunburst Rays Canvas
	var rays := Control.new()
	rays.set_anchors_preset(Control.PRESET_FULL_RECT)
	rays.draw.connect(func():
		var sz := rays.size
		rays.draw_rect(Rect2(Vector2.ZERO, sz), Color("#0C1628"))
		var center := sz * 0.5
		var rad := sz.length()
		for i in range(16):
			var a0 := float(i) / 16.0 * TAU + _fx_time * 0.15
			var a1 := a0 + TAU / 32.0
			var pts := PackedVector2Array([center, center + Vector2(cos(a0), sin(a0)) * rad, center + Vector2(cos(a1), sin(a1)) * rad])
			rays.draw_colored_polygon(pts, Color(0.95, 0.78, 0.25, 0.08))
	)
	_stage.add_child(rays)

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 240
	vb.offset_right = -240
	vb.offset_top = 20
	vb.offset_bottom = -18
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 8)
	_stage.add_child(vb)

	var sub_h := Label.new()
	sub_h.text = "TRIBUN  •  MUSIM %d" % yr
	sub_h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_h.add_theme_color_override("font_color", Color("#94A3B8"))
	sub_h.add_theme_font_size_override("font_size", 11)
	vb.add_child(sub_h)

	var title_l := Label.new()
	title_l.text = "KARTU BARU!"
	title_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_l.add_theme_font_override("font", UITheme.get_display_font())
	title_l.add_theme_font_size_override("font_size", 26)
	title_l.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	vb.add_child(title_l)

	# Silver/Gold Framed Collectible Card (#15 SCOUT etc.)
	var c_pan := PanelContainer.new()
	c_pan.custom_minimum_size = Vector2(210, 230)
	c_pan.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	c_pan.add_theme_stylebox_override("panel", UITheme.make_box(Color("#121D2E"), tier_col, 4, 8))
	vb.add_child(c_pan)
	c_pan.pivot_offset = Vector2(105, 115)
	c_pan.scale = Vector2(0.75, 0.75)
	create_tween().tween_property(c_pan, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK)

	var cvb := VBoxContainer.new()
	cvb.add_theme_constant_override("separation", 6)
	c_pan.add_child(cvb)

	var num_l := Label.new()
	num_l.text = "#%d" % int(card.get("num", 15))
	num_l.add_theme_font_override("font", UITheme.get_display_font())
	num_l.add_theme_color_override("font_color", tier_col)
	cvb.add_child(num_l)

	var av_c := PixelAvatar.new()
	av_c.custom_minimum_size = Vector2(104, 134)
	av_c.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	av_c.configure_from_career()
	av_c.anim_mode = "MVP"
	cvb.add_child(av_c)

	var cname := Label.new()
	cname.text = str(card.get("title", "SCOUT"))
	cname.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cname.add_theme_font_override("font", UITheme.get_display_font())
	cname.add_theme_font_size_override("font_size", 16)
	cvb.add_child(cname)

	var tier_l := Label.new()
	tier_l.text = "◆ %s  •  %s" % [tier_s, str(card.get("quote", ""))]
	tier_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tier_l.add_theme_color_override("font_color", tier_col)
	tier_l.add_theme_font_size_override("font_size", 12)
	vb.add_child(tier_l)

	var prog_l := Label.new()
	prog_l.text = "ALBUM  %d / %d" % [owned_n, total_n]
	prog_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prog_l.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	vb.add_child(prog_l)

	var p_bg := ColorRect.new()
	p_bg.color = Color("#1E293B")
	p_bg.custom_minimum_size = Vector2(260, 8)
	p_bg.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(p_bg)
	var p_fill := ColorRect.new()
	p_fill.color = UITheme.ACCENT_GOLD
	p_fill.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	p_fill.anchor_right = clampf(float(owned_n) / float(total_n), 0.05, 1.0)
	p_bg.add_child(p_fill)

	var ok_b := Button.new()
	ok_b.text = "→ LANJUT"
	ok_b.custom_minimum_size = Vector2(260, 42)
	ok_b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	UITheme.style_btn(ok_b, Color("#7A5C1A"), UITheme.ACCENT_GOLD, 15)
	ok_b.pressed.connect(func():
		AudioSynth.play_click()
		finished.emit()
		queue_free()
	)
	vb.add_child(ok_b)
