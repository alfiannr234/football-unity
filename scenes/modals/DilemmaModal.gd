extends Control

signal closed

func _ready() -> void:
	theme = UITheme.build_theme()
	var dilemma: Dictionary = CareerState.career["careerMeta"].get("currentDilemma", GameData.dilemmas_catalog[0])
	var club := CareerState.get_current_club()

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.06, 0.94)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	# Scene backdrop (dinner_room / locker_room / press_wall / manager_office)
	var scene_key := str(dilemma.get("scene", "dinner"))
	var bg_path := "res://assets/sprites/backgrounds/dinner_room.png"
	if scene_key == "locker":
		bg_path = "res://assets/sprites/backgrounds/locker_room.png"
	elif scene_key == "press":
		bg_path = "res://assets/sprites/backgrounds/press_wall.png"
	elif scene_key == "office":
		bg_path = "res://assets/sprites/backgrounds/manager_office.png"

	var tex_bg := TextureRect.new()
	tex_bg.texture = load(bg_path)
	tex_bg.anchor_left = 0.0
	tex_bg.anchor_right = 1.0
	tex_bg.anchor_top = 0.0
	tex_bg.anchor_bottom = 0.65
	tex_bg.offset_top = 0
	tex_bg.offset_bottom = 0
	tex_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(tex_bg)

	# Header tag (PEKAN INI • CLUB)
	var tag := PanelContainer.new()
	tag.set_anchors_preset(Control.PRESET_TOP_LEFT)
	tag.offset_left = 18
	tag.offset_top = 16
	tag.offset_right = 330
	tag.offset_bottom = 68
	tag.add_theme_stylebox_override("panel", UITheme.make_box(Color("#13233A"), UITheme.BORDER_CYAN, 1, 3))
	add_child(tag)

	var tag_hb := HBoxContainer.new()
	tag_hb.add_theme_constant_override("separation", 10)
	tag.add_child(tag_hb)
	var crest := ClubCrest.new()
	crest.custom_minimum_size = Vector2(36, 36)
	crest.set_club(int(club["id"]))
	tag_hb.add_child(crest)
	var tag_vb := VBoxContainer.new()
	tag_hb.add_child(tag_vb)
	var t1 := Label.new()
	t1.text = "PEKAN INI"
	t1.add_theme_color_override("font_color", UITheme.ACCENT_CYAN)
	t1.add_theme_font_size_override("font_size", 11)
	var t2 := Label.new()
	t2.text = club["name"].to_upper()
	t2.add_theme_font_override("font", UITheme.get_display_font())
	tag_vb.add_child(t1)
	tag_vb.add_child(t2)

	# Characters in scene
	var chars := HBoxContainer.new()
	chars.set_anchors_preset(Control.PRESET_CENTER)
	chars.offset_left = -180
	chars.offset_right = 180
	chars.offset_top = -158
	chars.offset_bottom = 24
	chars.alignment = BoxContainer.ALIGNMENT_CENTER
	chars.add_theme_constant_override("separation", 56)
	add_child(chars)

	var npc := TextureRect.new()
	var at := AtlasTexture.new()
	at.atlas = load("res://assets/sprites/characters/npcs_sheet.png")
	var npc_idx := 1 if scene_key == "dinner" else (2 if scene_key in ["locker", "office"] else 0)
	at.region = Rect2(npc_idx * 24, 0, 24, 36)
	npc.texture = at
	npc.custom_minimum_size = Vector2(96, 144)
	npc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	chars.add_child(npc)
	var npc_tw := create_tween().set_loops()
	npc_tw.tween_property(npc, "position:y", -5.0, 0.75).as_relative().set_trans(Tween.TRANS_SINE)
	npc_tw.tween_property(npc, "position:y", 5.0, 0.75).as_relative().set_trans(Tween.TRANS_SINE)

	var av := PixelAvatar.new()
	av.custom_minimum_size = Vector2(96, 144)
	av.configure_from_career()
	av.anim_mode = "TALK"
	chars.add_child(av)

	# Bottom Narrative & Choices
	var bot := VBoxContainer.new()
	bot.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bot.offset_left = 100
	bot.offset_right = -100
	bot.offset_top = -195
	bot.offset_bottom = -14
	bot.add_theme_constant_override("separation", 8)
	add_child(bot)
	bot.modulate.a = 0.0
	create_tween().tween_property(bot, "modulate:a", 1.0, 0.25)

	var msg := Label.new()
	msg.text = str(dilemma.get("text", ""))
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.add_theme_font_size_override("font_size", 14)
	bot.add_child(msg)

	var choices: Array = dilemma.get("choices", [])
	var row_hb := HBoxContainer.new()
	row_hb.add_theme_constant_override("separation", 10)
	bot.add_child(row_hb)

	for i in range(mini(2, choices.size())):
		var ch: Dictionary = choices[i]
		var btn := Button.new()
		btn.text = "%s\n%s" % [ch["label"], ch["sub"]]
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 68)
		UITheme.style_btn(btn, UITheme.ACCENT_PURPLE, Color("#9F85E0"), 13)
		btn.pressed.connect(func():
			AudioSynth.play_click()
			CareerState.apply_dilemma_choice(ch)
			closed.emit()
			queue_free()
		)
		row_hb.add_child(btn)

	if choices.size() >= 3:
		var ch3: Dictionary = choices[2]
		var btn3 := Button.new()
		btn3.text = "%s (%s)" % [ch3["label"], ch3["sub"]]
		btn3.custom_minimum_size = Vector2(0, 36)
		UITheme.style_btn(btn3, Color("#111D2E"), UITheme.BORDER_STEEL, 13)
		btn3.pressed.connect(func():
			AudioSynth.play_click()
			CareerState.apply_dilemma_choice(ch3)
			closed.emit()
			queue_free()
		)
		bot.add_child(btn3)
