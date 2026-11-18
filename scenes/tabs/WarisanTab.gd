extends Control

signal replay_shot_requested(clip: Dictionary)

var _subtab: String = "KARIER"
var _peta_mode: String = "SHOT"
var _body: VBoxContainer

func _ready() -> void:
	theme = UITheme.build_theme()
	var outer := VBoxContainer.new()
	outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("separation", 6)
	add_child(outer)

	var thb := HBoxContainer.new()
	thb.add_theme_constant_override("separation", 4)
	outer.add_child(thb)
	for st in ["KARIER", "PETA", "TROFI", "KLUB", "LEGENDA", "BOLA"]:
		var b := Button.new()
		b.text = st
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 38)
		UITheme.style_btn(b, Color("#0E2036"), UITheme.BORDER_STEEL, 10)
		b.pressed.connect(func(): AudioSynth.play_click(); _subtab = st; refresh())
		thb.add_child(b)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer.add_child(scroll)
	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 8)
	scroll.add_child(_body)

	CareerState.career_updated.connect(refresh)
	refresh()

func refresh() -> void:
	if not is_inside_tree() or not CareerState.has_active_career:
		return
	for c in _body.get_children():
		c.queue_free()

	match _subtab:
		"KARIER": _render_karier()
		"PETA": _render_peta()
		"TROFI": _render_trofi()
		"KLUB": _render_klub()
		"LEGENDA": _render_legenda()
		"BOLA": _render_bola()

func _render_karier() -> void:
	var m: Dictionary = CareerState.career["careerMeta"]
	var st: Dictionary = CareerState.career["stats"]
	var pts := int(m["legacyPoints"])

	_body.add_child(UITheme.make_section_header("WARISAN • %s" % m["legacyTier"]))
	var lp_lbl := Label.new()
	lp_lbl.text = "Poin legacy: %d — naik lewat gol, gelar & laga timnas.\n100 PROFESIONAL • 300 ANDALAN • 650 BINTANG DUNIA • LEGENDA" % pts
	lp_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lp_lbl.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	_body.add_child(lp_lbl)

	var pb := ProgressBar.new()
	pb.max_value = 650
	pb.value = mini(pts, 650)
	pb.custom_minimum_size = Vector2(0, 14)
	_body.add_child(pb)

	_body.add_child(UITheme.make_section_header("TOTAL KARIER"))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	_body.add_child(grid)
	var avg_r := float(st["totalRating"]) / maxf(1.0, float(st["matches"])) if int(st["matches"]) > 0 else 0.0
	for card_d in [
		["LAGA", "%d (%dM • %dS • %dK)" % [int(st["matches"]), int(st["wins"]), int(st["draws"]), int(st["losses"])]],
		["GOL", str(st["goals"])],
		["ASSIST", str(st["assists"])],
		["RATING", "%.1f (Terbaik: %.1f)" % [avg_r, float(st["bestRating"])]],
		["MUSIM", "%d di karier" % int(m["year"])],
		["INTERNASIONAL", "%d caps • %d gol" % [int(st["intlCaps"]), int(st["intlGoals"])]],
	]:
		var pc := PanelContainer.new()
		pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(pc)
		var vb := VBoxContainer.new()
		pc.add_child(vb)
		var l1 := Label.new()
		l1.text = card_d[0]
		l1.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
		l1.add_theme_font_size_override("font_size", 11)
		var l2 := Label.new()
		l2.text = card_d[1]
		l2.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
		vb.add_child(l1)
		vb.add_child(l2)

	_body.add_child(UITheme.make_section_header("PER MUSIM"))
	for sh in CareerState.career.get("seasonHistory", []):
		var row := PanelContainer.new()
		_body.add_child(row)
		var l := Label.new()
		l.text = "M%d  •  %s  |  MN: %d  G: %d  A: %d  RTG: %.1f" % [int(sh["season"]), sh["clubCode"], int(sh["matches"]), int(sh["goals"]), int(sh["assists"]), float(sh["avgRating"])]
		row.add_child(l)

	var ret := Button.new()
	ret.text = "PENSIUN SEBAGAI %s" % m["legacyTier"]
	UITheme.style_btn(ret, Color("#4E2424"), UITheme.ACCENT_RED)
	ret.pressed.connect(func():
		AudioSynth.play_click()
		m["retired"] = true
		CareerState.save_active_career()
		ret.text = "✓ KARIER PENSIUN TERSIMPAN"
	)
	_body.add_child(ret)

func _render_peta() -> void:
	# Interactive Shot Map matching Screenshot #25!
	var thb := HBoxContainer.new()
	thb.add_theme_constant_override("separation", 6)
	_body.add_child(thb)
	for pm in ["SHOT", "UMPAN", "DRIBEL"]:
		var b := Button.new()
		b.text = pm
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 34)
		UITheme.style_btn(b, Color("#173B66") if _peta_mode == pm else Color("#0B1626"), UITheme.BORDER_CYAN, 11)
		b.pressed.connect(func(): AudioSynth.play_click(); _peta_mode = pm; refresh())
		thb.add_child(b)

	_body.add_child(UITheme.make_section_header("PETA TEMBAKAN"))
	var shots: Array = CareerState.career.get("shotTelemetry", [])
	var tot := 0
	var goals := 0
	var on_t := 0
	for s in shots:
		var t := str(s.get("type", "OPEN_PLAY"))
		var match_m := (_peta_mode == "UMPAN" and t == "PASS") or (_peta_mode == "DRIBEL" and t == "DRIBBLE") or (_peta_mode == "SHOT" and t != "PASS" and t != "DRIBBLE")
		if match_m:
			tot += 1
			if s.get("outcome") == "GOAL":
				goals += 1
				on_t += 1
			elif s.get("outcome") == "ON_TARGET":
				on_t += 1

	var leg := Label.new()
	leg.text = "● Gol (%d)   ○ Tepat sasaran (%d)   ● Total (%d)\nJarak Gol Terjauh: %.1f m" % [goals, on_t, tot, float(CareerState.career["stats"].get("longestGoalMeters", 0.0))]
	_body.add_child(leg)

	var maps_hb := HBoxContainer.new()
	maps_hb.add_theme_constant_override("separation", 10)
	_body.add_child(maps_hb)

	var goal_map := ShotMapCanvas.new()
	goal_map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	goal_map.custom_minimum_size = Vector2(0, 210)
	goal_map.set_shots(shots, _peta_mode, true)
	maps_hb.add_child(goal_map)

	var pitch_map := ShotMapCanvas.new()
	pitch_map.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pitch_map.custom_minimum_size = Vector2(0, 210)
	pitch_map.set_shots(shots, _peta_mode, false)
	maps_hb.add_child(pitch_map)

	var hint := Label.new()
	hint.text = "Ketuk tanda di lapangan untuk melihat rekaman Moviola aksinya."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
	_body.add_child(hint)

	var on_tap := func(_s: Dictionary):
		AudioSynth.play_click()
		var clips: Array = CareerState.career.get("moviolaClips", [])
		if not clips.is_empty():
			replay_shot_requested.emit(clips[clips.size() - 1])
	goal_map.shot_selected.connect(on_tap)
	pitch_map.shot_selected.connect(on_tap)

func _render_trofi() -> void:
	_body.add_child(UITheme.make_section_header("LEMARI TROFI"))
	var tlist: Array = CareerState.career.get("trophiesList", [])
	if tlist.is_empty():
		var e := Label.new()
		e.text = "Masih kosong. Menangkan liga, piala, atau sepatu emas pertamamu!"
		e.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_body.add_child(e)
	else:
		for t in tlist:
			var card := PanelContainer.new()
			_body.add_child(card)
			var l := Label.new()
			l.text = "★ Musim %d — %s" % [int(t["season"]), t["name"]]
			l.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
			card.add_child(l)

	_body.add_child(UITheme.make_section_header("YANG DIPEREBUTKAN"))
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	_body.add_child(grid)
	var names := ["TERBAIK", "PIALA DUNIA", "DUNIA KLUB", "ANTARBENUA", "PIALA ELITE", "KEJAYAAN", "PIALA UTARA", "PIALA TIMUR"]
	for i in range(8):
		var vb := VBoxContainer.new()
		vb.alignment = BoxContainer.ALIGNMENT_CENTER
		grid.add_child(vb)
		var tr := TextureRect.new()
		var at := AtlasTexture.new()
		at.atlas = load("res://assets/sprites/ui/trophies_strip.png")
		at.region = Rect2(i * 32, 0, 32, 32)
		tr.texture = at
		tr.custom_minimum_size = Vector2(48, 48)
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		vb.add_child(tr)
		var lb := Label.new()
		lb.text = names[i]
		lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lb.add_theme_font_size_override("font_size", 9)
		vb.add_child(lb)

func _render_klub() -> void:
	var c := CareerState.get_current_club()
	_body.add_child(UITheme.make_section_header("KLUBMU: %s" % c["name"].to_upper()))
	_body.add_child(UITheme.make_section_header("PALING BERGELAR DI DUNIA"))
	for dc in GameData.decorated_clubs:
		var row := PanelContainer.new()
		_body.add_child(row)
		var hb := HBoxContainer.new()
		row.add_child(hb)
		hb.add_child(UITheme.make_flag_rect(int(dc["nat"]), Vector2(20, 14)))
		var nl := Label.new()
		nl.text = "  %s" % dc["name"]
		nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(nl)
		var tot := int(dc["liga"]) + int(dc["piala"]) + int(dc["kont"])
		var tl := Label.new()
		tl.text = "L:%d  P:%d  K:%d  = %d" % [int(dc["liga"]), int(dc["piala"]), int(dc["kont"]), tot]
		tl.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
		hb.add_child(tl)

func _render_legenda() -> void:
	_body.add_child(UITheme.make_section_header("LEGENDA DUNIA • TROFI INDIVIDU"))
	for i in range(mini(10, GameData.world_legends.size())):
		var lg: Dictionary = GameData.world_legends[i]
		var row := PanelContainer.new()
		_body.add_child(row)
		var hb := HBoxContainer.new()
		row.add_child(hb)
		hb.add_child(UITheme.make_flag_rect(int(lg["nat"]), Vector2(20, 14)))
		var l1 := Label.new()
		l1.text = " %d. %s (%s)" % [i + 1, lg["name"], "PENSIUN" if lg["retired"] else "AKTIF"]
		l1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var l2 := Label.new()
		l2.text = "IND:%d  TIM:%d  G+A:%d" % [int(lg["indiv"]), int(lg["team"]), int(lg["goals"]) + int(lg["assists"])]
		l2.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
		hb.add_child(l1)
		hb.add_child(l2)

func _render_bola() -> void:
	_body.add_child(UITheme.make_section_header("GALA • PEMAIN TERBAIK TAHUN INI"))
	var pod := HBoxContainer.new()
	pod.alignment = BoxContainer.ALIGNMENT_CENTER
	pod.add_theme_constant_override("separation", 12)
	_body.add_child(pod)
	for item in [["#2 Charlie Irving", "39 PTS", Color("#475569")], ["#1 Corentin Zimmer", "39 PTS", Color("#92741E")], ["#3 Pedro Resende", "38 PTS", Color("#7C4E2E")]]:
		var pc := PanelContainer.new()
		pc.custom_minimum_size = Vector2(145, 92)
		pc.add_theme_stylebox_override("panel", UITheme.make_box(item[2], UITheme.ACCENT_GOLD))
		pod.add_child(pc)
		var l := Label.new()
		l.text = "%s\n%s" % [item[0], item[1]]
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		pc.add_child(l)

	_body.add_child(UITheme.make_section_header("ANAK EMAS (U-21)"))
	var note := Label.new()
	note.text = "1. Mathieu Sauvage (30)  •  2. Landry Gnahore (29)  •  3. Martin Bustos (26)\nBerikan penampilan memukau sebelum usia 21 untuk masuk nominasi!"
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.add_child(note)
