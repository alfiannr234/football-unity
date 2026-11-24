extends Control

signal closed

var _pitch_side_panel: PanelContainer = null
var _pitch_side_av: PixelAvatar = null
var _pitch_side_dilemma: Dictionary = {}
var _pitch_side_chosen: bool = false
var _rel_anim_t: float = 0.0
var _rel_anim_rows: Array[Dictionary] = []

func _process(delta: float) -> void:
	if _pitch_side_panel != null and is_instance_valid(_pitch_side_panel):
		var vw: float = maxf(size.x, 960.0)
		var vh: float = maxf(size.y, 540.0)
		var card_w: float = 446.0
		var card_h: float = minf(_pitch_side_panel.get_combined_minimum_size().y, vh - 96.0)
		_pitch_side_panel.size = Vector2(card_w, card_h)
		_pitch_side_panel.position = Vector2(vw - card_w - 22.0, clampf((vh - card_h) * 0.64, 62.0, vh - card_h - 24.0))
	if _pitch_side_chosen and not _rel_anim_rows.is_empty() and _rel_anim_t < 1.0:
		_rel_anim_t = minf(1.0, _rel_anim_t + minf(delta, 0.05) * 1.65)
		_sync_rel_anim_labels()

func _sync_rel_anim_labels() -> void:
	var rp: float = 1.0 - pow(1.0 - clampf(_rel_anim_t, 0.0, 1.0), 3.0)
	for row in _rel_anim_rows:
		var rl: Label = row["lbl"]
		if is_instance_valid(rl):
			rl.text = str(int(round(lerpf(float(row["from"]), float(row["to"]), rp))))

func _ready() -> void:
	theme = UITheme.build_theme()
	var dilemma: Dictionary = CareerState.career["careerMeta"].get("currentDilemma", GameData.dilemmas_catalog[0])
	var club := CareerState.get_current_club()
	var scene_key: String = str(dilemma.get("scene", "dinner"))

	# Video C (SETELAH LAGA — DITUNGGU DI LORONG): Night stadium pitch-side with left player & right choice cards!
	if scene_key == "pitch_side":
		_build_pitch_side_dilemma(dilemma, club)
		return

	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.05, 0.09, 1.0)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	# Scene backdrop (press/pitch uses Landscape Pitch-Side PressStageBackdrop matching Gambar 2!)
	var is_press_stage: bool = (scene_key == "press" or scene_key == "pitch")

	if is_press_stage:
		var stage_bg := PressStageBackdrop.new()
		stage_bg.configure_from_club(club, str(dilemma.get("title", "")))
		add_child(stage_bg)

		var top_pill: PanelContainer = PressStageBackdrop.build_top_club_pill(club, str(dilemma.get("title", "PEKAN INI")))
		top_pill.position = Vector2(16, 6)
		add_child(top_pill)

		var av_p := PixelAvatar.new()
		av_p.position = Vector2(332, 108)
		av_p.size = Vector2(142, 236)
		av_p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		av_p.configure_from_career()
		av_p.anim_mode = "INTERVIEW"
		add_child(av_p)

		var mic_stand := PressStageBackdrop.BroadcastMicStand.new()
		mic_stand.accent_col = stage_bg.club_primary
		mic_stand.position = Vector2(288, 178)
		mic_stand.size = Vector2(58, 182)
		add_child(mic_stand)

		var rep_p := NpcAvatar.new()
		rep_p.configure_role("REPORTER", true, club)
		rep_p.anim_mode = "TALK"
		rep_p.position = Vector2(436, 108)
		rep_p.size = Vector2(178, 236)
		rep_p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(rep_p)
	else:
		var bg_path: String = "res://assets/sprites/backgrounds/dinner_room.png"
		if scene_key == "locker":
			bg_path = "res://assets/sprites/backgrounds/locker_room.png"
		elif scene_key == "office":
			bg_path = "res://assets/sprites/backgrounds/manager_office.png"

		var scene_fill := ColorRect.new()
		scene_fill.color = Color("#130E0A") if scene_key in ["dinner", "home"] else Color("#0A1320")
		scene_fill.anchor_left = 0.0
		scene_fill.anchor_right = 1.0
		scene_fill.anchor_top = 0.0
		scene_fill.anchor_bottom = 0.68
		add_child(scene_fill)

		var tex_bg := TextureRect.new()
		tex_bg.texture = load(bg_path)
		tex_bg.anchor_left = 0.0
		tex_bg.anchor_right = 1.0
		tex_bg.anchor_top = 0.0
		tex_bg.anchor_bottom = 0.68
		tex_bg.offset_top = 0
		tex_bg.offset_bottom = 0
		tex_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		add_child(tex_bg)

		var top_pill: PanelContainer = PressStageBackdrop.build_top_club_pill(club, str(dilemma.get("title", "PEKAN INI")))
		top_pill.position = Vector2(16, 6)
		add_child(top_pill)

		# Human-Proportioned NPC & Player in scene (zero looping tween risk!)
		var chars := HBoxContainer.new()
		chars.set_anchors_preset(Control.PRESET_CENTER)
		chars.offset_left = -190
		chars.offset_right = 190
		chars.offset_top = -188
		chars.offset_bottom = 14
		chars.alignment = BoxContainer.ALIGNMENT_CENTER
		chars.add_theme_constant_override("separation", 44)
		add_child(chars)

		var npc_role: String = "PARTNER" if scene_key == "dinner" else ("COACH" if scene_key in ["locker", "office"] else "REPORTER")
		var npc := NpcAvatar.new()
		npc.configure_role(npc_role, false, club)
		npc.anim_mode = "TALK"
		npc.custom_minimum_size = Vector2(122, 198)
		chars.add_child(npc)

		var av := PixelAvatar.new()
		av.custom_minimum_size = Vector2(122, 198)
		av.configure_from_career()
		av.anim_mode = "IDLE"
		chars.add_child(av)

	# Bottom Narrative & Choices (framed opaque panel + wrapped buttons so zero overflow/clipping!)
	var bot_panel := PanelContainer.new()
	bot_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bot_panel.offset_left = 18
	bot_panel.offset_right = -18
	bot_panel.offset_top = -186
	bot_panel.offset_bottom = -10
	bot_panel.add_theme_stylebox_override("panel", UITheme.make_box(Color("#08101C", 0.98), UITheme.BORDER_CYAN, 2, 8))
	add_child(bot_panel)

	var bot := VBoxContainer.new()
	bot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bot.add_theme_constant_override("separation", 8)
	bot_panel.add_child(bot)
	bot_panel.modulate.a = 0.0
	create_tween().tween_property(bot_panel, "modulate:a", 1.0, 0.25)

	var raw_msg: String = str(dilemma.get("text", "")).replace("±", "+/-")
	var msg := Label.new()
	msg.text = raw_msg
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	msg.custom_minimum_size = Vector2(0, 0)
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.add_theme_font_size_override("font_size", 13)
	msg.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	bot.add_child(msg)

	var choices: Array = dilemma.get("choices", [])
	var row_hb := HBoxContainer.new()
	row_hb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_hb.add_theme_constant_override("separation", 10)
	bot.add_child(row_hb)

	var default_pal := [Color("#7B521D"), Color("#4C3D7A"), Color("#6F324D")]
	var default_icons := ["JERSEY", "MIC", "FANS"]
	for i in range(mini(3, choices.size())):
		var ch: Dictionary = choices[i]
		var base_c: Color = Color(str(ch.get("color", ""))) if not str(ch.get("color", "")).is_empty() else default_pal[i % default_pal.size()]
		var sub_raw: String = str(ch.get("sub", "")).replace("±", "+/-")
		var chips: Array = []
		if not sub_raw.is_empty():
			for part in sub_raw.split("•"):
				var pt: String = part.strip_edges()
				if not pt.is_empty():
					chips.append([pt, pt.begins_with("-")])
		var btn: Button = PressStageBackdrop.build_gambar2_choice_button(
			str(ch.get("label", "")).replace("±", "+/-"),
			default_icons[i % default_icons.size()],
			base_c,
			chips
		)
		btn.pressed.connect(func():
			AudioSynth.play_click()
			var res: Dictionary = CareerState.apply_dilemma_choice_with_result(ch)
			var out_msg: String = str(res.get("outcome_text", ""))
			var deltas: Dictionary = res.get("deltas", {})
			if not out_msg.is_empty() or not deltas.is_empty():
				_show_relasi_feedback(bot, raw_msg, out_msg, deltas)
			else:
				closed.emit()
				queue_free()
		)
		row_hb.add_child(btn)

func _show_relasi_feedback(bot: VBoxContainer, base_txt: String, out_txt: String, deltas: Dictionary) -> void:
	var panel_host := bot.get_parent() as Control
	if panel_host != null:
		panel_host.offset_top = -248
	while bot.get_child_count() > 0:
		var c: Node = bot.get_child(0)
		bot.remove_child(c)
		c.queue_free()
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UITheme.make_box(Color("#121A26", 0.96), Color("#D94A4A"), 2, 10))
	bot.add_child(card)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	card.add_child(vb)

	var story := Label.new()
	story.text = (base_txt + " " + out_txt).strip_edges() if not out_txt.is_empty() else "Keputusanmu tercatat oleh klub & media."
	story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	story.add_theme_font_size_override("font_size", 12)
	vb.add_child(story)

	var hdr := Label.new()
	hdr.text = "RELASIMU"
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr.add_theme_font_override("font", UITheme.get_display_font())
	hdr.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	vb.add_child(hdr)

	var rel: Dictionary = CareerState.career.get("playerProfile", {}).get("relations", {})
	var labels_map := {"pelatih": "Pelatih", "ruangGanti": "Ruang ganti", "fans": "Suporter", "pers": "Pers", "agen": "Agen", "kekasih": "Kekasih"}
	for rk in deltas.keys():
		var dv: int = int(deltas[rk])
		if dv == 0:
			continue
		var rhb := HBoxContainer.new()
		rhb.add_theme_constant_override("separation", 8)
		vb.add_child(rhb)
		var nl := Label.new()
		nl.text = str(labels_map.get(rk, rk.capitalize()))
		nl.custom_minimum_size = Vector2(105, 0)
		rhb.add_child(nl)
		var cur_v: int = int(CareerState.career["playerProfile"].get("energy", 80)) if rk == "energy" else int(rel.get(rk, 50))
		var dl := Label.new()
		dl.text = "%s%d  (%d)" % [("+" if dv > 0 else ""), dv, cur_v]
		dl.custom_minimum_size = Vector2(82, 0)
		dl.add_theme_color_override("font_color", UITheme.ACCENT_GREEN if dv > 0 else UITheme.ACCENT_RED)
		rhb.add_child(dl)
		var bar_bg := ColorRect.new()
		bar_bg.color = Color("#243040")
		bar_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar_bg.custom_minimum_size = Vector2(120, 10)
		bar_bg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		rhb.add_child(bar_bg)
		var bf := ColorRect.new()
		bf.color = UITheme.ACCENT_GREEN if dv > 0 else Color("#D94A4A")
		bf.set_anchors_preset(Control.PRESET_LEFT_WIDE)
		bf.anchor_right = clampf(float(cur_v) / 100.0, 0.04, 1.0)
		bar_bg.add_child(bf)

	var ok_b := Button.new()
	ok_b.text = "LANJUTKAN"
	ok_b.custom_minimum_size = Vector2(0, 38)
	UITheme.style_btn(ok_b, Color("#1A1320"), Color("#D94A4A"), 14)
	ok_b.pressed.connect(func():
		AudioSynth.play_click()
		closed.emit()
		queue_free()
	)
	vb.add_child(ok_b)

# ==============================================================================
# NIGHT PITCH-SIDE SIDE-BY-SIDE EVENT UI (VIDEO C: DITUNGGU DI LORONG, ANY MATCH!)
# ==============================================================================
func _build_pitch_side_dilemma(dilemma: Dictionary, club: Dictionary) -> void:
	_pitch_side_dilemma = dilemma
	_pitch_side_chosen = false
	_rel_anim_rows.clear()

	var bg := PressStageBackdrop.NightPitchBackdrop.new()
	bg.team_code = str(club.get("code", "CLB")).left(3).to_upper()
	var fx: Dictionary = CareerState.get_current_fixture() if CareerState.has_active_career else {}
	bg.comp_label = str(fx.get("comp_label", "LIGA")).to_upper().left(20)
	add_child(bg)

	# Top-Left Broadcast Context Pill (SETELAH LAGA + Club Name)
	var top_pill: PanelContainer = PressStageBackdrop.build_top_club_pill(club, str(dilemma.get("title", "SETELAH LAGA")))
	top_pill.position = Vector2(18, 16)
	add_child(top_pill)

	# Left-Center Human-Proportioned User PixelAvatar standing on emerald night pitch
	_pitch_side_av = PixelAvatar.new()
	_pitch_side_av.size = Vector2(126, 206)
	_pitch_side_av.position = Vector2(168, 164)
	_pitch_side_av.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pitch_side_av.configure_from_career()
	_pitch_side_av.anim_mode = "IDLE"
	add_child(_pitch_side_av)

	# Right-Side Story & Choice Panel (strictly shrink-wrapped, zero overflow!)
	_pitch_side_panel = PanelContainer.new()
	_pitch_side_panel.custom_minimum_size = Vector2(430, 0)
	_pitch_side_panel.position = Vector2(506, 232)
	var psb: StyleBoxFlat = UITheme.make_box(Color(0.05, 0.07, 0.11, 0.78), Color(1.0, 1.0, 1.0, 0.10), 1, 8)
	psb.content_margin_left = 18
	psb.content_margin_right = 18
	psb.content_margin_top = 16
	psb.content_margin_bottom = 14
	_pitch_side_panel.add_theme_stylebox_override("panel", psb)
	add_child(_pitch_side_panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	_pitch_side_panel.add_child(vb)

	var story := Label.new()
	story.text = str(dilemma.get("text", "")).replace("±", "+/-")
	story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	story.add_theme_font_size_override("font_size", 12)
	story.add_theme_color_override("font_color", Color("#F1F5F9"))
	vb.add_child(story)

	var choices: Array = dilemma.get("choices", [])
	var row_hb := HBoxContainer.new()
	row_hb.add_theme_constant_override("separation", 10)
	vb.add_child(row_hb)

	var fallback_cols := [Color("#554B8E"), Color("#4C5E80"), Color("#1E6A73")]
	var fallback_icons := ["FANS", "CHECK", "COACH"]
	for ci in range(mini(3, choices.size())):
		var ch: Dictionary = choices[ci]
		var col_s: String = str(ch.get("color", ""))
		var base_c: Color = UITheme.parse_color(col_s, fallback_cols[ci % fallback_cols.size()]) if not col_s.is_empty() else fallback_cols[ci % fallback_cols.size()]
		var icon_k: String = str(ch.get("icon", fallback_icons[ci % fallback_icons.size()]))
		var eff: Dictionary = ch.get("effects", {})
		var chips: Array = _format_compact_effect_chips(eff)
		var btn: Button = PressStageBackdrop.build_square_event_choice_button(
			str(ch.get("label", "")),
			icon_k,
			base_c,
			chips
		)
		var idx_copy: int = ci
		btn.pressed.connect(func(): _on_pitch_side_choice(idx_copy))
		row_hb.add_child(btn)

	if bool(dilemma.get("allow_think", false)):
		var think_b := Button.new()
		think_b.text = "PIKIR DULU"
		think_b.flat = true
		think_b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		think_b.add_theme_font_override("font", UITheme.get_display_font())
		think_b.add_theme_font_size_override("font_size", 10)
		think_b.add_theme_color_override("font_color", Color("#94A3B8"))
		think_b.add_theme_color_override("font_hover_color", Color("#FFFFFF"))
		think_b.pressed.connect(func():
			AudioSynth.play_click()
			closed.emit()
			queue_free()
		)
		vb.add_child(think_b)

	_pitch_side_panel.size = Vector2(430.0, _pitch_side_panel.get_combined_minimum_size().y)

func _format_compact_effect_chips(eff: Dictionary) -> Array:
	var chips: Array = []
	var short_names := {"fans": "Fans", "pers": "Pers", "ruangGanti": "Tim", "pelatih": "Pelatih", "energy": "Energi"}
	for k in ["fans", "pers", "ruangGanti", "pelatih", "energy"]:
		if eff.has(k):
			var dv: int = int(eff[k])
			if dv != 0:
				var sign_s: String = "+" if dv > 0 else ""
				chips.append(["%s%d %s" % [sign_s, dv, str(short_names[k])], dv < 0])
	return chips

func _on_pitch_side_choice(choice_idx: int) -> void:
	if _pitch_side_chosen:
		return
	var choices: Array = _pitch_side_dilemma.get("choices", [])
	if choices.is_empty():
		closed.emit()
		queue_free()
		return
	var ch: Dictionary = choices[clampi(choice_idx, 0, choices.size() - 1)]
	AudioSynth.play_click()
	_pitch_side_chosen = true
	_rel_anim_t = 0.0
	_rel_anim_rows.clear()

	if _pitch_side_av != null and is_instance_valid(_pitch_side_av):
		_pitch_side_av.anim_mode = "CHEER"

	# Snapshot before-values so we animate the counting number cleanly!
	var before_map: Dictionary = {}
	var rel_ref: Dictionary = CareerState.career.get("playerProfile", {}).get("relations", {})
	for rk in GameData.RELATION_KEYS:
		before_map[rk] = int(rel_ref.get(rk, 50))
	before_map["energy"] = int(CareerState.career.get("playerProfile", {}).get("energy", 80))

	var res: Dictionary = CareerState.apply_dilemma_choice_with_result(ch)
	var deltas: Dictionary = res.get("deltas", {})
	if deltas.is_empty():
		deltas = (ch.get("effects", {}) as Dictionary).duplicate(true)

	if _pitch_side_panel == null or not is_instance_valid(_pitch_side_panel):
		return
	for c in _pitch_side_panel.get_children():
		_pitch_side_panel.remove_child(c)
		c.queue_free()

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	_pitch_side_panel.add_child(vb)

	var story := Label.new()
	story.text = str(_pitch_side_dilemma.get("text", ""))
	story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	story.add_theme_font_size_override("font_size", 11)
	story.add_theme_color_override("font_color", Color("#CBD5E1"))
	vb.add_child(story)

	var recap_prefix: String = str(_pitch_side_dilemma.get("recap_title", str(_pitch_side_dilemma.get("title", "KEPUTUSAN"))))
	var ch_nice: String = str(ch.get("label", "")).to_lower().capitalize()
	var recap := Label.new()
	recap.text = "%s: %s" % [recap_prefix, ch_nice]
	recap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	recap.add_theme_font_override("font", UITheme.get_display_font())
	recap.add_theme_font_size_override("font_size", 13)
	recap.add_theme_color_override("font_color", UITheme.TEXT_WHITE)
	vb.add_child(recap)

	var hdr_hb := HBoxContainer.new()
	hdr_hb.add_theme_constant_override("separation", 6)
	vb.add_child(hdr_hb)
	var flag_sq := ColorRect.new()
	flag_sq.custom_minimum_size = Vector2(10, 12)
	flag_sq.color = Color("#E11D48")
	flag_sq.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hdr_hb.add_child(flag_sq)
	var rel_hdr := Label.new()
	rel_hdr.text = "RELASIMU"
	rel_hdr.add_theme_font_override("font", UITheme.get_display_font())
	rel_hdr.add_theme_font_size_override("font_size", 11)
	rel_hdr.add_theme_color_override("font_color", Color("#E2E8F0"))
	hdr_hb.add_child(rel_hdr)

	var rel_grid := HBoxContainer.new()
	rel_grid.add_theme_constant_override("separation", 10)
	vb.add_child(rel_grid)

	var rel_now: Dictionary = CareerState.career.get("playerProfile", {}).get("relations", {})
	var labels_map := {"pelatih": "Pelatih", "ruangGanti": "Ruang ganti", "fans": "Suporter", "pers": "Pers", "agen": "Agen", "kekasih": "Kekasih"}
	var energy_delta: int = int(deltas.get("energy", 0))
	for rk in deltas.keys():
		if rk == "energy" or rk == "cash" or rk == "xp":
			continue
		var dv: int = int(deltas[rk])
		if dv == 0:
			continue
		var r_box := PanelContainer.new()
		r_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var rsb: StyleBoxFlat = UITheme.make_box(Color(0.08, 0.11, 0.18, 0.90), Color(1.0, 1.0, 1.0, 0.14), 1, 5)
		rsb.content_margin_left = 10
		rsb.content_margin_right = 10
		rsb.content_margin_top = 7
		rsb.content_margin_bottom = 7
		r_box.add_theme_stylebox_override("panel", rsb)
		rel_grid.add_child(r_box)

		var rhb := HBoxContainer.new()
		rhb.add_theme_constant_override("separation", 6)
		r_box.add_child(rhb)

		var nm_l := Label.new()
		nm_l.text = str(labels_map.get(rk, rk.capitalize()))
		nm_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nm_l.add_theme_font_size_override("font_size", 11)
		nm_l.add_theme_color_override("font_color", Color("#E2E8F0"))
		rhb.add_child(nm_l)

		var dl_l := Label.new()
		dl_l.text = "%s%d" % [("+" if dv > 0 else ""), dv]
		dl_l.add_theme_font_override("font", UITheme.get_display_font())
		dl_l.add_theme_font_size_override("font_size", 12)
		dl_l.add_theme_color_override("font_color", Color("#4ADE80") if dv > 0 else Color("#F87171"))
		rhb.add_child(dl_l)

		var bv: int = int(before_map.get(rk, 50))
		var av_v: int = int(rel_now.get(rk, clampi(bv + dv, 0, 100)))
		var val_l := Label.new()
		val_l.text = str(bv)
		val_l.add_theme_font_override("font", UITheme.get_display_font())
		val_l.add_theme_font_size_override("font_size", 13)
		val_l.add_theme_color_override("font_color", Color("#FCA5A5"))
		rhb.add_child(val_l)
		_rel_anim_rows.append({"lbl": val_l, "from": bv, "to": av_v})

	if energy_delta != 0:
		var en_l := Label.new()
		en_l.text = "%s%d energi" % [("+" if energy_delta > 0 else ""), energy_delta]
		en_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		en_l.add_theme_font_size_override("font_size", 11)
		en_l.add_theme_color_override("font_color", Color("#4ADE80") if energy_delta > 0 else Color("#94A3B8"))
		vb.add_child(en_l)

	var ok_b: Button = PressStageBackdrop.build_crimson_cta_button("LANJUTKAN")
	ok_b.pressed.connect(func():
		AudioSynth.play_click()
		closed.emit()
		queue_free()
	)
	vb.add_child(ok_b)

	_pitch_side_panel.size = Vector2(430.0, _pitch_side_panel.get_combined_minimum_size().y)

func select_choice_for_test(choice_idx: int = 0) -> void:
	if _pitch_side_panel != null and not _pitch_side_chosen:
		_on_pitch_side_choice(choice_idx)
		_rel_anim_t = 1.0
		_sync_rel_anim_labels()
		_process(0.016)
