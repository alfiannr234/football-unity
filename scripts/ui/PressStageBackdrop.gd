class_name PressStageBackdrop
extends Control

# Landscape (960x540) Pitch-Side Stadium Press Stage matching Gambar 2:
# Shows tiered stadium grandstands (tribun) with cheering fans & floodlights on BOTH left/right wings,
# lush mowed green stadium pitch (lapangan) with touchline & turf shadows across the lower field,
# and a freestanding club-colored checkered sponsor press wall in center-stage!

var club_primary: Color = Color("#B81D24")
var club_secondary: Color = Color("#FFFFFF")
var club_short: String = "KLUB"
var league_label: String = "LIGA KE-3"
var _t: float = 0.0

func configure_from_club(club: Dictionary, comp_lbl: String = "") -> void:
	var pri: Color = UITheme.parse_color(club.get("primary", Color("#B81D24")), Color("#B81D24"))
	# Ensure sponsor tiles stay rich & legible even for very pale primary kits
	if pri.get_luminance() > 0.78:
		pri = UITheme.parse_color(club.get("secondary", Color("#1D4ED8")), Color("#1D4ED8"))
		if pri.get_luminance() > 0.78:
			pri = Color("#1D4ED8")
	club_primary = pri
	club_secondary = UITheme.parse_color(club.get("secondary", Color("#F8FAFC")), Color("#F8FAFC"))
	var raw_nm: String = str(club.get("name", "KLUB")).to_upper()
	var parts: PackedStringArray = raw_nm.split(" ")
	club_short = ("%s %s" % [parts[0], parts[1]] if parts.size() >= 2 else raw_nm).left(11)
	if not comp_lbl.is_empty():
		league_label = comp_lbl.to_upper().left(10)
	else:
		league_label = "LIGA KE-%d" % clampi(int(club.get("division", 3)), 1, 3)
	queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _process(delta: float) -> void:
	_t += minf(delta, 0.1)
	queue_redraw()

func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	if w < 10.0 or h < 10.0:
		return

	var pri_tile: Color = club_primary
	var white_tile := Color("#EFEFEF")
	var sky_top := Color("#0B1424")
	var sky_bot := Color("#1C2C46")

	# =========================================================================
	# 1. EVENING STADIUM SKY & FLOODLIGHT TOWERS (Left & Right Wings)
	# =========================================================================
	draw_rect(Rect2(0, 0, w, 90), sky_top)
	draw_rect(Rect2(0, 38, w, 58), sky_bot)
	for fl_x in [68.0, 152.0, w - 152.0, w - 68.0]:
		# Floodlight mast & glowing lamp bank
		draw_rect(Rect2(fl_x - 3.0, 18, 6, 44), Color("#26344B"))
		draw_rect(Rect2(fl_x - 16.0, 12, 32, 12), Color("#334155"))
		draw_rect(Rect2(fl_x - 13.0, 14, 26, 8), Color("#FEF3C7"))
		# Atmospheric light cone glow
		var beam := PackedVector2Array([
			Vector2(fl_x - 14.0, 22), Vector2(fl_x + 14.0, 22),
			Vector2(fl_x + 76.0, 250), Vector2(fl_x - 76.0, 250),
		])
		draw_colored_polygon(beam, Color(1.0, 0.96, 0.82, 0.055))

	# =========================================================================
	# 2. STADIUM GRANDSTANDS (TRIBUN) VISIBLE ON BOTH LEFT & RIGHT WINGS!
	# =========================================================================
	# Roof canopy overhang
	draw_rect(Rect2(0, 48, w, 16), Color("#151F30"))
	draw_rect(Rect2(0, 62, w, 4), Color("#2B3B54"))
	# Concrete stadium stand bowl (y=66..234)
	draw_rect(Rect2(0, 66, w, 168), Color("#18202C"))
	var fan_skins := [Color("#E2B48D"), Color("#C89066"), Color("#996543")]
	for tier in range(6):
		var ty: float = 72.0 + float(tier) * 24.0
		draw_rect(Rect2(0, ty, w, 3.0), Color("#283447"))
		# Draw lively pixel spectators on left wing (x=8..224) and right wing (x=736..952)
		var fan_xs: Array[float] = []
		var lx: float = 12.0 + float((tier % 2) * 8)
		while lx < 226.0:
			fan_xs.append(lx)
			lx += 17.0
		var rx: float = w - 226.0 + float((tier % 2) * 8)
		while rx < w - 10.0:
			fan_xs.append(rx)
			rx += 17.0
		for fx in fan_xs:
			var seed_v: int = int(fx) * 13 + tier * 37
			var hop: float = absf(sin(_t * 3.8 + float(seed_v) * 0.55)) * 2.5
			var fy: float = ty + 16.0 - hop
			var shirt: Color = pri_tile if (seed_v % 3 != 0) else (club_secondary if (seed_v % 5 == 0) else Color("#39485E"))
			var sk: Color = fan_skins[seed_v % fan_skins.size()]
			# Pixel spectator silhouette
			draw_rect(Rect2(fx - 3.0, fy - 11.0, 6, 5), sk)
			draw_rect(Rect2(fx - 3.0, fy - 12.0, 6, 2), Color("#16181F"))
			draw_rect(Rect2(fx - 5.0, fy - 6.0, 10, 9), shirt)
			if seed_v % 4 == 0:
				draw_rect(Rect2(fx - 7.0, fy - 13.0, 14, 3), club_secondary)
			# Twinkling paparazzi / phone flash in the stands
			if sin(_t * 6.5 + float(seed_v) * 1.9) > 0.985:
				draw_circle(Vector2(fx, fy - 10.0), 4.0, Color(1.0, 1.0, 1.0, 0.80))

	# Pitch-Side Illuminated LED Advertising Ribbon along base of stands (y=214..234)
	draw_rect(Rect2(0, 214, w, 20), Color("#0C1320"))
	draw_rect(Rect2(0, 214, w, 2), Color("#38BDF8", 0.55))
	var led_off: float = fmod(_t * 28.0, 96.0)
	for li in range(-1, 12):
		var bx: float = float(li) * 96.0 - led_off
		var is_alt: bool = (li % 2 == 0)
		draw_rect(Rect2(bx + 2.0, 217, 92, 14), pri_tile.darkened(0.25) if is_alt else Color("#142640"))
		draw_rect(Rect2(bx + 12.0, 222, 42, 4), club_secondary if is_alt else Color("#38BDF8"))
		draw_rect(Rect2(bx + 62.0, 221, 20, 6), Color("#6DB646") if is_alt else Color("#F5C430"))

	# =========================================================================
	# 3. LUSH MOWED GREEN STADIUM PITCH (LAPANGAN) ACROSS FULL LANDSCAPE WIDTH!
	# =========================================================================
	var pitch_top: float = 234.0
	draw_rect(Rect2(0, pitch_top, w, h - pitch_top), Color("#1D5530"))
	# Horizontal perspective mowed grass bands
	var band_ys := [234.0, 250.0, 272.0, 300.0, 336.0, 382.0, 440.0]
	for bi in range(band_ys.size() - 1):
		if bi % 2 == 1:
			draw_rect(Rect2(0, band_ys[bi], w, band_ys[bi + 1] - band_ys[bi]), Color("#236639"))
	# Subtle vertical pitch grass mowing stripes on left & right wings
	for vi in range(12):
		if vi % 2 == 0:
			draw_rect(Rect2(float(vi) * (w / 12.0), pitch_top, w / 12.0, h - pitch_top), Color(1, 1, 1, 0.035))
	# Crisp White Sideline Touchline & Penalty Box Edge on Left/Right Field
	draw_rect(Rect2(0, 248, w, 3.0), Color(0.95, 0.97, 0.95, 0.72))
	draw_line(Vector2(138, 249), Vector2(46, 368), Color(0.95, 0.97, 0.95, 0.48), 3.0)
	draw_line(Vector2(w - 138, 249), Vector2(w - 46, 368), Color(0.95, 0.97, 0.95, 0.48), 3.0)
	# Subtle grass tuft detail on foreground turf
	for gi in range(18):
		var gx: float = 28.0 + float(gi) * 52.0
		var gy: float = 318.0 + float((gi * 17) % 34)
		draw_rect(Rect2(gx, gy, 5, 2), Color("#2D7B46", 0.55))

	# =========================================================================
	# 4. FREESTANDING CHECKERED SPONSOR PRESS WALL (CENTER STAGE, GAMBAR 2!)
	# =========================================================================
	var wall_x: float = 224.0
	var wall_y: float = 52.0
	var wall_w: float = 512.0
	var wall_h: float = 242.0

	# Cast shadow behind & beneath sponsor board on the turf
	draw_rect(Rect2(wall_x - 10, wall_y + wall_h - 4, wall_w + 20, 22), Color(0, 0, 0, 0.34))
	# Steel support legs resting firmly on the pitch
	draw_rect(Rect2(wall_x + 14, wall_y + wall_h, 8, 16), Color("#1E293B"))
	draw_rect(Rect2(wall_x + wall_w - 22, wall_y + wall_h, 8, 16), Color("#1E293B"))
	draw_rect(Rect2(wall_x + 4, wall_y + wall_h + 13, 28, 4), Color("#0F172A"))
	draw_rect(Rect2(wall_x + wall_w - 32, wall_y + wall_h + 13, 28, 4), Color("#0F172A"))

	# Metallic frame border around press backdrop wall
	draw_rect(Rect2(wall_x - 4, wall_y - 4, wall_w + 8, wall_h + 8), Color("#182233"))
	draw_rect(Rect2(wall_x, wall_y, wall_w, wall_h), white_tile)

	var cols: int = 6
	var rows: int = 6
	var tw: float = wall_w / float(cols)
	var th: float = wall_h / float(rows)
	var disp_f: Font = UITheme.get_display_font()

	for r in range(rows):
		for c in range(cols):
			var tx: float = wall_x + float(c) * tw
			var ty: float = wall_y + float(r) * th
			var is_colored: bool = ((r + c) % 2 == 1)
			var tile_bg: Color = pri_tile if is_colored else white_tile
			draw_rect(Rect2(tx, ty, tw + 0.5, th + 0.5), tile_bg)
			draw_rect(Rect2(tx, ty, tw, th), Color(0, 0, 0, 0.06), false, 1.0)

			var motif_i: int = (r * 3 + c) % 3
			if is_colored:
				if motif_i == 0:
					_draw_eco_leaf(Vector2(tx + tw * 0.5, ty + th * 0.52), 1.0)
				elif motif_i == 1:
					draw_string(disp_f, Vector2(tx + 2.0, ty + th * 0.62), league_label, HORIZONTAL_ALIGNMENT_CENTER, tw - 4.0, 9, Color("#F8FAFC"))
				else:
					draw_string(disp_f, Vector2(tx + 2.0, ty + th * 0.62), club_short, HORIZONTAL_ALIGNMENT_CENTER, tw - 4.0, 8, Color("#F8FAFC"))
			else:
				if motif_i == 0:
					draw_string(disp_f, Vector2(tx + 2.0, ty + th * 0.62), club_short, HORIZONTAL_ALIGNMENT_CENTER, tw - 4.0, 8, pri_tile.darkened(0.12))
				elif motif_i == 1:
					_draw_eco_leaf(Vector2(tx + tw * 0.5, ty + th * 0.52), 1.0)
				else:
					draw_string(disp_f, Vector2(tx + 2.0, ty + th * 0.62), league_label, HORIZONTAL_ALIGNMENT_CENTER, tw - 4.0, 9, Color("#1E293B"))

	# Subtle wall vignette gradient at top & bottom edge for physical depth
	draw_rect(Rect2(wall_x, wall_y, wall_w, 10), Color(0, 0, 0, 0.14))
	draw_rect(Rect2(wall_x, wall_y + wall_h - 14, wall_w, 14), Color(0, 0, 0, 0.16))

	# =========================================================================
	# 5. SOFT DARK LOWER TURF SHADE (Makes Bottom Prompt & Choice Cards Pop!)
	# =========================================================================
	draw_rect(Rect2(0, 344, w, 34), Color(0.02, 0.06, 0.05, 0.36))
	draw_rect(Rect2(0, 378, w, h - 378), Color(0.02, 0.05, 0.08, 0.84))

func _draw_eco_leaf(c: Vector2, sc: float) -> void:
	# Iconic green pixel leaf sponsor motif matching Gambar 2's sponsor board!
	var s: float = 3.0 * sc
	draw_rect(Rect2(c.x - 1 * s, c.y - 3 * s, 3 * s, 2 * s), Color("#65B741"))
	draw_rect(Rect2(c.x - 2 * s, c.y - 1 * s, 4 * s, 2 * s), Color("#4D9A32"))
	draw_rect(Rect2(c.x - 2 * s, c.y + 1 * s, 3 * s, 1 * s), Color("#387824"))
	draw_rect(Rect2(c.x - 3 * s, c.y + 2 * s, 2 * s, 1 * s), Color("#2E641D"))
	draw_rect(Rect2(c.x, c.y - 2 * s, 1 * s, 2 * s), Color("#A3E635"))

# ==============================================================================
# FOREGROUND STANDING BROADCAST 'TV' FLOOR MICROPHONE (Placed in front of player!)
# ==============================================================================
class BroadcastMicStand extends Control:
	var accent_col: Color = Color("#DC2626")

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var cx: float = size.x * 0.5
		var bot_y: float = size.y - 8.0
		# Ground shadow & weighted circular mic stand base
		draw_circle(Vector2(cx + 3.0, bot_y + 2.0), 22.0, Color(0, 0, 0, 0.32))
		draw_rect(Rect2(cx - 22.0, bot_y - 4.0, 44.0, 9.0), Color("#0C1018"))
		draw_rect(Rect2(cx - 18.0, bot_y - 2.0, 36.0, 5.0), Color("#1E2636"))
		# Vertical steel pole
		draw_rect(Rect2(cx - 4.0, 42.0, 8.0, bot_y - 44.0), Color("#0C1018"))
		draw_rect(Rect2(cx - 2.0, 42.0, 4.0, bot_y - 44.0), Color("#334155"))
		draw_rect(Rect2(cx - 2.0, 42.0, 1.5, bot_y - 44.0), Color("#64748B"))
		# Microphone foam head
		draw_rect(Rect2(cx - 10.0, 4.0, 20.0, 14.0), Color("#0B0F17"))
		draw_rect(Rect2(cx - 8.0, 6.0, 16.0, 10.0), Color("#252F42"))
		draw_rect(Rect2(cx - 6.0, 7.0, 5.0, 3.0), Color("#475569"))
		# Square Broadcast 'TV' Mic Flag Cube (EXACT Gambar 2!)
		draw_rect(Rect2(cx - 22.0, 16.0, 44.0, 32.0), Color("#0B0E16"))
		draw_rect(Rect2(cx - 19.0, 19.0, 38.0, 26.0), Color("#171C28"))
		draw_rect(Rect2(cx - 19.0, 41.0, 38.0, 4.0), accent_col)
		# Crisp pixel 'T' and 'V' letters in pure white
		var w_c := Color("#F8FAFC")
		# Letter T
		draw_rect(Rect2(cx - 14.0, 23.0, 12.0, 3.0), w_c)
		draw_rect(Rect2(cx - 9.5, 26.0, 3.0, 12.0), w_c)
		# Letter V
		draw_rect(Rect2(cx + 2.0, 23.0, 3.0, 9.0), w_c)
		draw_rect(Rect2(cx + 11.0, 23.0, 3.0, 9.0), w_c)
		draw_rect(Rect2(cx + 4.5, 32.0, 3.0, 4.0), w_c)
		draw_rect(Rect2(cx + 8.5, 32.0, 3.0, 4.0), w_c)
		draw_rect(Rect2(cx + 6.5, 35.0, 3.0, 3.0), w_c)

# ==============================================================================
# PIXEL ICON FOR GAMBAR 2 CHOICE CARDS (Jersey / Mic / Fans / Star)
# ==============================================================================
class ChoicePixelIcon extends Control:
	var kind: String = "JERSEY"

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		var cx: float = w * 0.5
		var cy: float = h * 0.5
		var col := Color("#F8FAFC")
		var sh := Color("#CBD5E1")
		match kind:
			"JERSEY":
				draw_rect(Rect2(cx - 10, cy - 8, 20, 6), col)
				draw_rect(Rect2(cx - 6, cy - 8, 12, 16), col)
				draw_rect(Rect2(cx - 3, cy - 8, 6, 3), Color(0, 0, 0, 0.35))
				draw_rect(Rect2(cx + 2, cy - 2, 4, 10), sh)
			"MIC":
				draw_rect(Rect2(cx - 4, cy - 9, 8, 9), col)
				draw_rect(Rect2(cx - 6, cy - 2, 12, 4), sh)
				draw_rect(Rect2(cx - 1.5, cy + 2, 3, 6), col)
				draw_rect(Rect2(cx - 5, cy + 7, 10, 2), col)
			"FANS":
				draw_circle(Vector2(cx, cy - 4), 4.0, col)
				draw_rect(Rect2(cx - 6, cy + 1, 12, 7), col)
				draw_circle(Vector2(cx - 8, cy - 2), 3.0, sh)
				draw_rect(Rect2(cx - 11, cy + 2, 6, 5), sh)
				draw_circle(Vector2(cx + 8, cy - 2), 3.0, sh)
				draw_rect(Rect2(cx + 5, cy + 2, 6, 5), sh)
			"COACH":
				# Tactical whistle / coach silhouette icon
				draw_circle(Vector2(cx - 4, cy + 1), 6.0, col)
				draw_circle(Vector2(cx - 4, cy + 1), 2.5, Color(0, 0, 0, 0.35))
				draw_rect(Rect2(cx + 1, cy - 5, 10, 6), col)
				draw_rect(Rect2(cx + 3, cy - 5, 4, 2), sh)
				draw_rect(Rect2(cx - 8, cy - 8, 5, 3), sh)
			"CHECK":
				# Crisp bold checkmark icon
				draw_line(Vector2(cx - 8, cy + 1), Vector2(cx - 2, cy + 7), col, 3.2)
				draw_line(Vector2(cx - 2, cy + 7), Vector2(cx + 9, cy - 6), col, 3.2)
			_:
				draw_circle(Vector2(cx, cy), 6.0, col)

static func build_top_club_pill(club: Dictionary, eyebrow: String, stat_right: String = "") -> PanelContainer:
	var pill := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.05, 0.07, 0.86)
	sb.border_color = Color(1.0, 1.0, 1.0, 0.16)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 10
	sb.content_margin_right = 12
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	pill.add_theme_stylebox_override("panel", sb)

	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	pill.add_child(hb)

	var cr := ClubCrest.new()
	cr.custom_minimum_size = Vector2(28, 28)
	cr.set_club(int(club.get("id", 0)))
	cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(cr)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 0)
	hb.add_child(vb)

	var l1 := Label.new()
	l1.text = eyebrow.to_upper()
	l1.add_theme_font_override("font", UITheme.get_display_font())
	l1.add_theme_font_size_override("font_size", 9)
	l1.add_theme_color_override("font_color", Color("#FB7185"))
	vb.add_child(l1)

	var l2 := Label.new()
	l2.text = str(club.get("name", "KLUB")).to_upper()
	l2.add_theme_font_override("font", UITheme.get_display_font())
	l2.add_theme_font_size_override("font_size", 14)
	l2.add_theme_color_override("font_color", Color("#FFFFFF"))
	vb.add_child(l2)

	if not stat_right.is_empty():
		var sep := ColorRect.new()
		sep.custom_minimum_size = Vector2(1, 24)
		sep.color = Color(1, 1, 1, 0.22)
		hb.add_child(sep)
		var rs := Label.new()
		rs.text = stat_right
		rs.add_theme_font_override("font", UITheme.get_display_font())
		rs.add_theme_font_size_override("font_size", 11)
		rs.add_theme_color_override("font_color", Color("#F5C430"))
		hb.add_child(rs)

	return pill

static func build_gambar2_choice_button(title: String, icon_kind: String, base_col: Color, delta_chips: Array, extra_note: String = "") -> Button:
	var btn := Button.new()
	btn.text = ""
	btn.clip_contents = true
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, 94)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var n := StyleBoxFlat.new()
	n.bg_color = base_col
	n.border_color = base_col.lightened(0.35)
	n.set_border_width_all(2)
	n.border_width_bottom = 4
	n.set_corner_radius_all(6)
	var h: StyleBoxFlat = n.duplicate()
	h.bg_color = base_col.lightened(0.14)
	h.border_color = Color("#FFFFFF")
	var pr: StyleBoxFlat = n.duplicate()
	pr.bg_color = base_col.darkened(0.12)
	btn.add_theme_stylebox_override("normal", n)
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_stylebox_override("pressed", pr)
	btn.add_theme_stylebox_override("focus", h)

	var mc := MarginContainer.new()
	mc.set_anchors_preset(Control.PRESET_FULL_RECT)
	mc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mc.add_theme_constant_override("margin_left", 8)
	mc.add_theme_constant_override("margin_right", 8)
	mc.add_theme_constant_override("margin_top", 6)
	mc.add_theme_constant_override("margin_bottom", 6)
	btn.add_child(mc)

	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_theme_constant_override("separation", 3)
	mc.add_child(vb)

	var ico_c := CenterContainer.new()
	ico_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ico := ChoicePixelIcon.new()
	ico.kind = icon_kind
	ico.custom_minimum_size = Vector2(24, 20)
	ico_c.add_child(ico)
	vb.add_child(ico_c)

	var tl := Label.new()
	tl.text = title.to_upper()
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tl.add_theme_font_override("font", UITheme.get_display_font())
	tl.add_theme_font_size_override("font_size", 12)
	tl.add_theme_color_override("font_color", Color("#FFFFFF"))
	vb.add_child(tl)

	var chips_hb := HBoxContainer.new()
	chips_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	chips_hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chips_hb.add_theme_constant_override("separation", 5)
	vb.add_child(chips_hb)

	for ch in delta_chips:
		var txt: String = str(ch[0])
		var is_neg: bool = bool(ch[1])
		var pill := PanelContainer.new()
		pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var psb := StyleBoxFlat.new()
		psb.bg_color = Color("#B91C1C") if is_neg else Color(0.05, 0.08, 0.14, 0.55)
		psb.border_color = Color("#F87171") if is_neg else Color(1, 1, 1, 0.25)
		psb.set_border_width_all(1)
		psb.set_corner_radius_all(3)
		psb.content_margin_left = 5
		psb.content_margin_right = 5
		psb.content_margin_top = 1
		psb.content_margin_bottom = 1
		pill.add_theme_stylebox_override("panel", psb)
		var cl := Label.new()
		cl.text = txt
		cl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cl.add_theme_font_override("font", UITheme.get_display_font())
		cl.add_theme_font_size_override("font_size", 9)
		cl.add_theme_color_override("font_color", Color("#FFFFFF") if is_neg else Color("#E2F8E8"))
		pill.add_child(cl)
		chips_hb.add_child(pill)

	if not extra_note.is_empty():
		var nl := Label.new()
		nl.text = extra_note
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		nl.add_theme_font_size_override("font_size", 9)
		nl.add_theme_color_override("font_color", Color("#FDE68A"))
		vb.add_child(nl)

	return btn

# ==============================================================================
# SQUARE EVENT CHOICE TILE & CRIMSON CTA BUTTON (MATCHING VIDEOS B & C!)
# ==============================================================================
static func build_square_event_choice_button(title: String, icon_kind: String, base_col: Color, delta_chips: Array) -> Button:
	var btn := Button.new()
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(128, 128)
	btn.clip_contents = true
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var n := StyleBoxFlat.new()
	n.bg_color = base_col
	n.border_color = base_col.lightened(0.28)
	n.set_border_width_all(2)
	n.border_width_bottom = 4
	n.set_corner_radius_all(6)
	var h: StyleBoxFlat = n.duplicate()
	h.bg_color = base_col.lightened(0.14)
	h.border_color = Color("#FFFFFF")
	var pr: StyleBoxFlat = n.duplicate()
	pr.bg_color = base_col.darkened(0.12)
	btn.add_theme_stylebox_override("normal", n)
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_stylebox_override("pressed", pr)
	btn.add_theme_stylebox_override("focus", h)

	var mc := MarginContainer.new()
	mc.set_anchors_preset(Control.PRESET_FULL_RECT)
	mc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mc.add_theme_constant_override("margin_left", 6)
	mc.add_theme_constant_override("margin_right", 6)
	mc.add_theme_constant_override("margin_top", 8)
	mc.add_theme_constant_override("margin_bottom", 8)
	btn.add_child(mc)

	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_theme_constant_override("separation", 5)
	mc.add_child(vb)

	var ico_c := CenterContainer.new()
	ico_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ico := ChoicePixelIcon.new()
	ico.kind = icon_kind
	ico.custom_minimum_size = Vector2(26, 22)
	ico_c.add_child(ico)
	vb.add_child(ico_c)

	var tl := Label.new()
	tl.text = title.to_upper()
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tl.add_theme_font_override("font", UITheme.get_display_font())
	tl.add_theme_font_size_override("font_size", 10)
	tl.add_theme_color_override("font_color", Color("#FFFFFF"))
	vb.add_child(tl)

	var chips_flow := HFlowContainer.new()
	chips_flow.alignment = FlowContainer.ALIGNMENT_CENTER
	chips_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chips_flow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chips_flow.add_theme_constant_override("h_separation", 4)
	chips_flow.add_theme_constant_override("v_separation", 3)
	vb.add_child(chips_flow)

	for ch in delta_chips:
		var txt: String = str(ch[0])
		var is_neg: bool = bool(ch[1])
		var pill := PanelContainer.new()
		pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var psb := StyleBoxFlat.new()
		psb.bg_color = Color("#991B1B") if is_neg else Color(0.04, 0.08, 0.14, 0.56)
		psb.border_color = Color("#F87171") if is_neg else Color(1, 1, 1, 0.24)
		psb.set_border_width_all(1)
		psb.set_corner_radius_all(3)
		psb.content_margin_left = 4
		psb.content_margin_right = 4
		psb.content_margin_top = 1
		psb.content_margin_bottom = 1
		pill.add_theme_stylebox_override("panel", psb)
		var cl := Label.new()
		cl.text = txt
		cl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cl.add_theme_font_override("font", UITheme.get_display_font())
		cl.add_theme_font_size_override("font_size", 8)
		cl.add_theme_color_override("font_color", Color("#FEE2E2") if is_neg else Color("#E2F8E8"))
		pill.add_child(cl)
		chips_flow.add_child(pill)

	return btn

static func build_crimson_cta_button(label_text: String) -> Button:
	var btn := Button.new()
	btn.text = label_text.to_upper()
	btn.custom_minimum_size = Vector2(0, 42)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var n := StyleBoxFlat.new()
	n.bg_color = Color("#0C0F18")
	n.border_color = Color("#334155")
	n.set_border_width_all(1)
	n.border_width_bottom = 4
	n.border_color = Color("#E11D48")
	n.set_corner_radius_all(4)
	n.content_margin_left = 14
	n.content_margin_right = 14
	n.content_margin_top = 8
	n.content_margin_bottom = 8
	var h: StyleBoxFlat = n.duplicate()
	h.bg_color = Color("#181E30")
	h.border_color = Color("#FB7185")
	var pr: StyleBoxFlat = n.duplicate()
	pr.bg_color = Color("#080A10")
	pr.border_color = Color("#FACC15")
	btn.add_theme_stylebox_override("normal", n)
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_stylebox_override("pressed", pr)
	btn.add_theme_stylebox_override("focus", h)
	btn.add_theme_font_override("font", UITheme.get_display_font())
	btn.add_theme_font_size_override("font_size", 15)
	btn.add_theme_color_override("font_color", Color("#FFFFFF"))
	btn.add_theme_color_override("font_hover_color", Color("#FFFFFF"))
	btn.add_theme_color_override("font_pressed_color", Color("#FACC15"))
	return btn

# ==============================================================================
# NIGHT STADIUM PITCH-SIDE BACKDROP (SHARED BY VICTORY DEDICATION & POST-MATCH!)
# ==============================================================================
class NightPitchBackdrop extends Control:
	var team_code: String = "ELB"
	var comp_label: String = "LIGA"
	var accent_col: Color = Color("#EAB308")
	var _t: float = 0.0

	func _ready() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		_t += minf(delta, 0.05)
		queue_redraw()

	func _draw() -> void:
		var w: float = maxf(size.x, 960.0)
		var h: float = maxf(size.y, 540.0)
		var led_y: float = h * 0.305
		var led_h: float = 20.0
		var pitch_y: float = led_y + led_h

		# Deep twilight-night stadium stands upper third
		draw_rect(Rect2(0.0, 0.0, w, led_y), Color("#11131D"))
		for r in range(7):
			var ry: float = 16.0 + float(r) * ((led_y - 24.0) / 7.0)
			draw_rect(Rect2(0.0, ry, w, 2.0), Color(0.18, 0.21, 0.30, 0.55))
			for si in range(44):
				var sx: float = 10.0 + float(si) * (w / 44.0) + float((r * 7) % 9)
				var alpha: float = 0.18 + 0.14 * float((si + r) % 3)
				var scol: Color = Color(0.75, 0.58, 0.45, alpha) if ((si + r) % 4 == 0) else Color(0.25, 0.30, 0.42, alpha)
				draw_rect(Rect2(sx, ry - 6.0, 5.0, 5.0), scol)

		# Subtle diagonal stadium floodlight rays cutting down across stands & pitch
		for fi in range(3):
			var fx: float = w * (0.14 + float(fi) * 0.34)
			var sway: float = sin(_t * 0.55 + float(fi) * 1.4) * 18.0
			var beam := PackedVector2Array([
				Vector2(fx - 26.0, 0.0),
				Vector2(fx + 26.0, 0.0),
				Vector2(fx + 145.0 + sway, h * 0.65),
				Vector2(fx + 45.0 + sway, h * 0.65),
			])
			draw_colored_polygon(beam, Color(1.0, 0.94, 0.78, 0.045))

		# Glowing Golden Perimeter LED Advertising Boards (exact Video B & Video C signature!)
		draw_rect(Rect2(0.0, led_y, w, led_h), Color("#1B170C"))
		draw_rect(Rect2(0.0, led_y + 2.0, w, led_h - 4.0), Color("#A18228"))
		draw_rect(Rect2(0.0, led_y + 2.0, w, 2.0), Color("#FEF08A"))
		var fdisp: Font = UITheme.get_display_font()
		var seg_txt: String = "%s   |   %s   |   " % [team_code, comp_label]
		var seg_w: float = maxf(210.0, fdisp.get_string_size(seg_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x)
		var dx: float = -fmod(_t * 24.0, seg_w)
		while dx < w + seg_w:
			draw_string(fdisp, Vector2(dx, led_y + 13.5), seg_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#17130A"))
			dx += seg_w

		# Lush Dark-Emerald Night Pitch Grass with Soft Mowed Bands
		var bands: int = 8
		var bh: float = (h - pitch_y) / float(bands)
		for bi in range(bands):
			var frac: float = float(bi) / float(bands)
			var base_g: Color = Color("#1B431B") if (bi % 2 == 0) else Color("#204F20")
			var lit_g: Color = base_g.darkened(frac * 0.42)
			draw_rect(Rect2(0.0, pitch_y + float(bi) * bh, w, bh + 1.5), lit_g)
		# Crisp perspective pitch touchline
		draw_line(Vector2(0.0, pitch_y + 16.0), Vector2(w, pitch_y + 16.0), Color(1, 1, 1, 0.22), 2.0)

		# Right-side atmospheric dark gradient veil so right-side story & cards read effortlessly!
		var veil_steps: int = 10
		var vx0: float = w * 0.36
		var vw_s: float = (w - vx0) / float(veil_steps)
		for vi in range(veil_steps):
			var a: float = lerpf(0.0, 0.72, float(vi + 1) / float(veil_steps))
			draw_rect(Rect2(vx0 + float(vi) * vw_s, 0.0, vw_s + 2.0, h), Color(0.03, 0.05, 0.08, a))
