extends Control

# Interactive "KONTROL DAN VOLI" First-Touch & Juggling Timing Minigame matching Video 3!
# Tap/click when the shrinking timing ring aligns around the incoming ball to chain streaks.

signal exited

var _playing: bool = false
var _streak: int = 0
var _best_streak: int = 0
var _judgment_text: String = "KETUK DI LINGKARAN"
var _judgment_col: Color = Color("#F5C542")
var _ball_active: bool = false
var _ball_pos: Vector2 = Vector2(270, 320)
var _ball_start: Vector2 = Vector2(270, 260)
var _ball_target: Vector2 = Vector2(270, 560)
var _ball_t: float = 0.0
var _ball_dur: float = 1.45
var _cooldown: float = 0.7
var _kick_anim_timer: float = 0.0

var _canvas: Control
var _player_av: PixelAvatar
var _server_av: PixelAvatar
var _lbl_status: Label
var _lbl_streak: Label
var _lbl_best: Label
var _start_btn: Button

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UITheme.build_theme()
	_best_streak = int(CareerState.global_profile.get("best_volley_streak", 0))
	if CareerState.has_active_career:
		_best_streak = maxi(_best_streak, int(CareerState.career["stats"].get("bestVolleyStreak", 0)))

	# Stadium Grass Pitch Backdrop
	var sky := ColorRect.new()
	sky.color = Color("#1B2838")
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(sky)

	var grass_bg := Control.new()
	grass_bg.anchor_left = 0.0
	grass_bg.anchor_right = 1.0
	grass_bg.anchor_top = 0.25
	grass_bg.anchor_bottom = 1.0
	grass_bg.draw.connect(func():
		var w: float = grass_bg.size.x
		var h: float = grass_bg.size.y
		var bands := 9
		var band_h := h / float(bands)
		for b in range(bands):
			var col := Color("#194C23") if b % 2 == 0 else Color("#236630")
			grass_bg.draw_rect(Rect2(0.0, float(b) * band_h, w, band_h + 1.0), col)
		# Crisp perspective pitch chalk lines
		var chalk := Color("#EBF4FC", 0.72)
		grass_bg.draw_line(Vector2(0, 6), Vector2(w, 6), chalk, 2.0)
		grass_bg.draw_line(Vector2(44, 6), Vector2(4, h), chalk, 2.0)
		grass_bg.draw_line(Vector2(w - 44, 6), Vector2(w - 4, h), chalk, 2.0)
		grass_bg.draw_line(Vector2(105, 6), Vector2(72, 130), chalk, 2.0)
		grass_bg.draw_line(Vector2(w - 105, 6), Vector2(w - 72, 130), chalk, 2.0)
		grass_bg.draw_line(Vector2(72, 130), Vector2(w - 72, 130), chalk, 2.0)
		grass_bg.draw_arc(Vector2(w * 0.5, 130), 64.0, 0.0, PI, 28, chalk, 2.0)
		# Soft floodlight vignette along upper touchline
		grass_bg.draw_rect(Rect2(0, 0, w, 46), Color(1.0, 0.96, 0.86, 0.07))
	)
	add_child(grass_bg)

	var st_tex := TextureRect.new()
	st_tex.texture = load("res://assets/sprites/pitch/stands_crowd.png")
	st_tex.anchor_left = 0.0
	st_tex.anchor_right = 1.0
	st_tex.anchor_top = 0.0
	st_tex.anchor_bottom = 0.22
	st_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	st_tex.clip_contents = true
	st_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(st_tex)

	# Ad-board stripe
	var ads := TextureRect.new()
	ads.texture = load("res://assets/sprites/pitch/ad_board.png")
	ads.anchor_left = 0.0
	ads.anchor_right = 1.0
	ads.anchor_top = 0.21
	ads.anchor_bottom = 0.27
	ads.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ads.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(ads)

	# Teammate server across pitch (Landscape 960x540)
	_server_av = PixelAvatar.new()
	_server_av.custom_minimum_size = Vector2(44, 66)
	_server_av.position = Vector2(610, 148)
	var club: Dictionary = CareerState.get_current_club() if CareerState.has_active_career else GameData.clubs[0]
	_server_av.configure_from_seed(77, club, 8)
	add_child(_server_av)

	# Foreground player avatar
	_player_av = PixelAvatar.new()
	_player_av.custom_minimum_size = Vector2(104, 156)
	_player_av.position = Vector2(280, 236)
	if CareerState.has_active_career:
		_player_av.configure_from_career()
	else:
		_player_av.configure_from_seed(9, club, 29)
	_player_av.show_number_badge = true
	add_child(_player_av)

	# Interactive Ball + Ring Draw Layer
	_canvas = Control.new()
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.draw.connect(_draw_game)
	_canvas.gui_input.connect(_on_canvas_input)
	add_child(_canvas)

	# Bottom HUD Panel (Landscape compact dock)
	var bot := PanelContainer.new()
	bot.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bot.offset_left = 140
	bot.offset_right = -140
	bot.offset_top = -124
	bot.offset_bottom = -12
	bot.add_theme_stylebox_override("panel", UITheme.make_box(Color("#1A1014", 0.94), Color("#4A2630"), 2, 12))
	add_child(bot)

	var bvb := VBoxContainer.new()
	bvb.add_theme_constant_override("separation", 4)
	bot.add_child(bvb)

	var h := Label.new()
	h.text = "KONTROL DAN VOLI"
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.add_theme_font_override("font", UITheme.get_display_font())
	h.add_theme_font_size_override("font_size", 14)
	bvb.add_child(h)

	_lbl_status = Label.new()
	_lbl_status.text = _judgment_text
	_lbl_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_status.add_theme_font_override("font", UITheme.get_display_font())
	_lbl_status.add_theme_font_size_override("font_size", 15)
	_lbl_status.add_theme_color_override("font_color", _judgment_col)
	bvb.add_child(_lbl_status)

	var score_hb := HBoxContainer.new()
	score_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	score_hb.add_theme_constant_override("separation", 28)
	bvb.add_child(score_hb)

	_lbl_streak = Label.new()
	_lbl_streak.text = "0"
	_lbl_streak.add_theme_font_override("font", UITheme.get_display_font())
	_lbl_streak.add_theme_font_size_override("font_size", 20)
	_lbl_streak.add_theme_color_override("font_color", UITheme.ACCENT_CYAN)
	score_hb.add_child(_lbl_streak)

	_lbl_best = Label.new()
	_lbl_best.text = "★ %d" % _best_streak
	_lbl_best.add_theme_font_override("font", UITheme.get_display_font())
	_lbl_best.add_theme_font_size_override("font_size", 20)
	_lbl_best.add_theme_color_override("font_color", UITheme.ACCENT_GOLD)
	score_hb.add_child(_lbl_best)

	var btn_hb := HBoxContainer.new()
	btn_hb.add_theme_constant_override("separation", 8)
	bvb.add_child(btn_hb)

	_start_btn = Button.new()
	_start_btn.text = "MAIN"
	_start_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_start_btn.custom_minimum_size = Vector2(0, 34)
	UITheme.style_btn(_start_btn, Color("#173B66"), UITheme.ACCENT_CYAN, 13)
	_start_btn.pressed.connect(func():
		AudioSynth.play_click()
		_playing = true
		_streak = 0
		_judgment_text = "KETUK DI LINGKARAN!"
		_judgment_col = UITheme.ACCENT_GOLD
		_start_btn.visible = false
		_spawn_ball()
	)
	btn_hb.add_child(_start_btn)

	var exit_b := Button.new()
	exit_b.text = "SELESAI"
	exit_b.custom_minimum_size = Vector2(110, 34)
	UITheme.style_btn(exit_b, Color("#3A1A20"), UITheme.ACCENT_RED, 13)
	exit_b.pressed.connect(func():
		AudioSynth.play_click()
		CareerState.record_volley_streak(_best_streak)
		exited.emit()
		queue_free()
	)
	btn_hb.add_child(exit_b)

func _spawn_ball() -> void:
	_ball_active = true
	_ball_t = 0.0
	_ball_dur = maxf(0.85, 1.45 - float(_streak) * 0.03)
	_ball_start = Vector2(randf_range(500.0, 700.0), 148.0)
	_ball_target = Vector2(randf_range(240.0, 480.0), randf_range(245.0, 345.0))
	_ball_pos = _ball_start
	AudioSynth.play_kick(0.5)

func _process(delta: float) -> void:
	if _kick_anim_timer > 0.0:
		_kick_anim_timer -= delta
		_player_av.position.y = 236.0 - sin(_kick_anim_timer * 20.0) * 14.0
	else:
		_player_av.position.y = 236.0

	if _playing:
		if _ball_active:
			_ball_t += delta / _ball_dur
			var arc_y: float = -sin(clampf(_ball_t, 0.0, 1.0) * PI) * 90.0
			_ball_pos = _ball_start.lerp(_ball_target, clampf(_ball_t, 0.0, 1.0)) + Vector2(0, arc_y)
			if _ball_t >= 1.18:
				_handle_miss("JATUH!")
		else:
			_cooldown -= delta
			if _cooldown <= 0.0:
				_spawn_ball()
	_canvas.queue_redraw()
	_sync_labels()

func _sync_labels() -> void:
	_lbl_status.text = _judgment_text
	_lbl_status.add_theme_color_override("font_color", _judgment_col)
	_lbl_streak.text = str(_streak)
	_lbl_best.text = "★ %d" % _best_streak

func _handle_miss(reason: String) -> void:
	_ball_active = false
	_streak = 0
	_cooldown = 0.65
	_judgment_text = reason
	_judgment_col = UITheme.ACCENT_RED
	AudioSynth.play_ring_tap(false)

func _on_canvas_input(ev: InputEvent) -> void:
	if not _playing or not _ball_active:
		return
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		var mb: InputEventMouseButton = ev
		if mb.position.y > size.y - 135:
			return
		var dist: float = mb.position.distance_to(_ball_pos)
		var ring_err: float = absf(_ball_t - 0.88)
		if dist <= 135.0 and ring_err <= 0.24:
			_ball_active = false
			_cooldown = 0.45
			_streak += 1
			_kick_anim_timer = 0.25
			_best_streak = maxi(_best_streak, _streak)
			CareerState.record_volley_streak(_best_streak)
			if ring_err <= 0.09:
				_judgment_text = "SEMPURNA!"
				_judgment_col = UITheme.ACCENT_GOLD
				AudioSynth.play_ring_tap(true)
			elif dist <= 65.0:
				_judgment_text = "TEPAT DI KAKI!"
				_judgment_col = UITheme.ACCENT_CYAN
				AudioSynth.play_ring_tap(true)
			else:
				_judgment_text = "TERKONTROL!"
				_judgment_col = Color("#6CE68E")
				AudioSynth.play_kick(0.7)
			_player_av.position.x = clampf(_ball_target.x - 52.0, 160.0, 620.0)
		else:
			_handle_miss("KEJAUHAN!" if dist > 135.0 else "LEPAS!")

func _draw_game() -> void:
	if not _ball_active:
		return
	var r_ball: float = lerpf(8.0, 22.0, clampf(_ball_t, 0.0, 1.0))
	var ring_r: float = lerpf(96.0, 22.0, clampf(_ball_t / 0.90, 0.0, 1.15))
	var ring_col: Color = UITheme.ACCENT_GOLD if absf(_ball_t - 0.88) <= 0.14 else UITheme.ACCENT_CYAN

	# Ground Shadow
	_canvas.draw_circle(_ball_pos + Vector2(0, r_ball * 1.45), r_ball * 0.78, Color(0, 0, 0, 0.42))
	# Neon Timing Ring Halo + Crisp Inner Ring + Reticle Ticks
	var eff_ring := maxf(18.0, ring_r)
	_canvas.draw_arc(_ball_pos, eff_ring, 0, TAU, 40, Color(ring_col.r, ring_col.g, ring_col.b, 0.24), 8.0)
	_canvas.draw_arc(_ball_pos, eff_ring, 0, TAU, 40, ring_col, 2.5)
	for a_idx in range(4):
		var ang := float(a_idx) * (PI * 0.5)
		var p_a := _ball_pos + Vector2(cos(ang), sin(ang)) * (eff_ring - 5.0)
		var p_b := _ball_pos + Vector2(cos(ang), sin(ang)) * (eff_ring + 6.0)
		_canvas.draw_line(p_a, p_b, ring_col, 2.0)
	# Highlighted Shaded Football
	_canvas.draw_circle(_ball_pos, r_ball, Color("#EBEFF5"))
	_canvas.draw_circle(_ball_pos + Vector2(r_ball * 0.16, r_ball * 0.18), r_ball * 0.72, Color("#CFD8E3", 0.55))
	_canvas.draw_circle(_ball_pos, r_ball * 0.42, Color("#B42C36"))
	_canvas.draw_circle(_ball_pos - Vector2(r_ball * 0.34, r_ball * 0.34), r_ball * 0.22, Color("#FFFFFF", 0.78))
	_canvas.draw_arc(_ball_pos, r_ball, 0, TAU, 28, Color("#121820"), 2.0)
