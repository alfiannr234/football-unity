class_name MatchHudWidgets
extends RefCounted

# Custom broadcast HUD & Pause UI widgets matching Gambar 1 & Gambar 3:
# - CompetitionTheme resolver (Liga / Elite / Piala Domestik / Timnas)
# - BroadcastScorebug (Left circular comp emblem, Home crest+code, white score box, Away code+crest, Right circular rating arc, Half+Minute pill, Competition ribbon)
# - ControlledPlayerCard (White shirt number square + human PixelAvatar portrait + real teammate/user name + position)
# - PauseMenuIcon (Play / Cone / Gear / Replay / Exit / Swap-Hand / Joystick / Eye)

static func get_comp_theme(comp: String, comp_label: String = "") -> Dictionary:
	var c_up: String = (comp + " " + comp_label).to_upper()
	if c_up.contains("SUPER EROPA") or c_up.contains("SUPER_EROPA"):
		return {
			"kind": "SUPER_EROPA",
			"accent": Color("#94A3B8"),
			"accent_hi": Color("#E2E8F0"),
			"pill_bg": Color("#334155"),
			"bar_bg": Color("#0F172A"),
			"resume_border": Color("#E2E8F0"),
			"emblem_col": Color("#F8FAFC"),
		}
	if c_up.contains("ELITE") or c_up.contains("KONTINENTAL") or c_up.contains("CHAMPIONS") or c_up.contains("EUROPA") or c_up.contains("CONF") or c_up.contains("DUNIA KLUB"):
		return {
			"kind": "ELITE",
			"accent": Color("#2455F4"),
			"accent_hi": Color("#60A5FA"),
			"pill_bg": Color("#1D46D8"),
			"bar_bg": Color("#10224A"),
			"resume_border": Color("#E11D48"),
			"emblem_col": Color("#F5C430"),
		}
	if c_up.contains("TIMNAS") or c_up.contains("PIALA DUNIA") or c_up.contains("PIALA ASIA") or c_up.contains("EURO") or c_up.contains("COPA") or c_up.contains("AFRIKA"):
		return {
			"kind": "TIMNAS",
			"accent": Color("#C81E3A"),
			"accent_hi": Color("#FB7185"),
			"pill_bg": Color("#A61830"),
			"bar_bg": Color("#2E101A"),
			"resume_border": Color("#F5C430"),
			"emblem_col": Color("#F5C430"),
		}
	if c_up.contains("PIALA") or c_up.contains("CUP") or c_up.contains("DOMESTIK"):
		return {
			"kind": "CUP",
			"accent": Color("#C97A18"),
			"accent_hi": Color("#FBBF24"),
			"pill_bg": Color("#A46110"),
			"bar_bg": Color("#2B1C0B"),
			"resume_border": Color("#F59E0B"),
			"emblem_col": Color("#FDE047"),
		}
	# Default Domestic League broadcast theme (steel sky-blue matching Gambar 1!)
	return {
		"kind": "LIGA",
		"accent": Color("#3878A8"),
		"accent_hi": Color("#7DD3FC"),
		"pill_bg": Color("#265B84"),
		"bar_bg": Color("#193047"),
		"resume_border": Color("#E11D48"),
		"emblem_col": Color("#F5C430"),
	}

class CompEmblemRing extends Control:
	var ring_col: Color = Color("#3878A8")
	var icon_col: Color = Color("#F5C430")
	var kind: String = "LIGA"

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func set_theme_info(th: Dictionary) -> void:
		ring_col = th.get("accent_hi", Color("#7DD3FC"))
		icon_col = th.get("emblem_col", Color("#F5C430"))
		kind = str(th.get("kind", "LIGA"))
		queue_redraw()

	func _draw() -> void:
		var c := size * 0.5
		var r: float = minf(size.x, size.y) * 0.46
		draw_circle(c, r + 2.0, Color("#0A1320"))
		draw_circle(c, r, Color("#13263E"))
		draw_arc(c, r, 0.0, TAU, 32, ring_col, 2.5)
		draw_arc(c, r - 4.0, 0.0, TAU, 24, Color(ring_col.r, ring_col.g, ring_col.b, 0.32), 1.2)
		if kind == "SUPER_EROPA":
			# Sleek Silver European Super Cup Chalice
			var cup := PackedVector2Array([
				c + Vector2(-r * 0.42, -r * 0.44), c + Vector2(r * 0.42, -r * 0.44),
				c + Vector2(r * 0.24, r * 0.14), c + Vector2(-r * 0.24, r * 0.14),
			])
			draw_colored_polygon(cup, icon_col)
			draw_rect(Rect2(c.x - r * 0.10, c.y + r * 0.14, r * 0.20, r * 0.24), icon_col)
			draw_rect(Rect2(c.x - r * 0.30, c.y + r * 0.36, r * 0.60, r * 0.12), icon_col)
		elif kind == "ELITE":
			# 5-point Elite Star
			var pts := PackedVector2Array()
			for i in range(10):
				var ang: float = -PI * 0.5 + float(i) * PI / 5.0
				var rad: float = r * (0.54 if i % 2 == 0 else 0.24)
				pts.append(Vector2(c.x + cos(ang) * rad, c.y + sin(ang) * rad))
			draw_colored_polygon(pts, icon_col)
		else:
			# Crisp Trophy / League Cup Emblem
			draw_circle(Vector2(c.x, c.y - 2.0), r * 0.34, icon_col)
			draw_circle(Vector2(c.x, c.y - 2.0), r * 0.18, Color("#13263E"))
			draw_rect(Rect2(c.x - r * 0.52, c.y - 4.0, r * 0.20, 4.0), icon_col)
			draw_rect(Rect2(c.x + r * 0.32, c.y - 4.0, r * 0.20, 4.0), icon_col)
			draw_rect(Rect2(c.x - 2.0, c.y + 3.0, 4.0, 5.0), icon_col)
			draw_rect(Rect2(c.x - 6.0, c.y + 7.0, 12.0, 2.5), icon_col)

class RatingRingGauge extends Control:
	var rating_val: float = 6.2
	var accent_col: Color = Color("#7DD3FC")

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func set_rating(r: float, acc: Color = Color("#7DD3FC")) -> void:
		rating_val = clampf(r, 4.0, 10.0)
		accent_col = acc
		queue_redraw()

	func _draw() -> void:
		var c := size * 0.5
		var r: float = minf(size.x, size.y) * 0.46
		draw_circle(c, r + 2.0, Color("#0A1320"))
		draw_circle(c, r, Color("#122236"))
		draw_arc(c, r, 0.0, TAU, 32, Color("#263C57"), 2.5)
		var pct: float = clampf((rating_val - 4.0) / 6.0, 0.05, 1.0)
		var arc_c: Color = Color("#F5C430") if rating_val >= 8.2 else (Color("#4ADE80") if rating_val >= 7.0 else (Color("#F87171") if rating_val < 5.6 else accent_col))
		draw_arc(c, r, -PI * 0.5, -PI * 0.5 + TAU * pct, 32, arc_c, 3.0)
		var r_txt: String = ("%.1f" % rating_val).replace(".", ",")
		var fnt: Font = UITheme.get_display_font()
		draw_string(fnt, Vector2(0, c.y + 4.5), r_txt, HORIZONTAL_ALIGNMENT_CENTER, size.x, 12, Color("#F8FAFC"))

class PauseMenuIcon extends Control:
	var kind: String = "PLAY"
	var col: Color = Color("#F8FAFC")

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		var cx: float = w * 0.5
		var cy: float = h * 0.5
		match kind:
			"PLAY":
				var pts := PackedVector2Array([Vector2(cx - 5, cy - 6), Vector2(cx + 6, cy), Vector2(cx - 5, cy + 6)])
				draw_colored_polygon(pts, col)
			"CONE":
				var cpts := PackedVector2Array([Vector2(cx, cy - 7), Vector2(cx + 6, cy + 6), Vector2(cx - 6, cy + 6)])
				draw_colored_polygon(cpts, col)
				draw_rect(Rect2(cx - 8, cy + 5, 16, 2.5), col)
				draw_rect(Rect2(cx - 3, cy - 1, 6, 2), Color("#0B1018"))
			"GEAR":
				draw_circle(Vector2(cx, cy), 6.0, col)
				draw_circle(Vector2(cx, cy), 2.8, Color("#0B1018"))
				for i in range(8):
					var ang: float = float(i) * PI * 0.25
					draw_rect(Rect2(cx + cos(ang) * 6.5 - 1.5, cy + sin(ang) * 6.5 - 1.5, 3, 3), col)
			"REPLAY":
				draw_arc(Vector2(cx, cy), 6.0, 0.3, TAU - 0.5, 18, col, 2.2)
				var arr := PackedVector2Array([Vector2(cx + 7, cy - 5), Vector2(cx + 8, cy + 1), Vector2(cx + 2, cy - 1)])
				draw_colored_polygon(arr, col)
			"EXIT":
				draw_rect(Rect2(cx - 6, cy - 7, 10, 14), col, false, 2.0)
				draw_rect(Rect2(cx - 4, cy - 5, 6, 10), col)
				draw_rect(Rect2(cx + 2, cy - 2, 5, 4), Color("#0B1018"))
				draw_circle(Vector2(cx - 1, cy), 1.5, Color("#0B1018"))
			"SWAP":
				draw_circle(Vector2(cx, cy + 2), 5.0, col, false, 2.0)
				draw_circle(Vector2(cx, cy + 2), 2.0, col)
				draw_line(Vector2(cx - 7, cy - 5), Vector2(cx + 7, cy - 5), col, 2.0)
				draw_rect(Rect2(cx - 7, cy - 7, 2.5, 4), col)
				draw_rect(Rect2(cx + 5, cy - 7, 2.5, 4), col)
			"JOY":
				draw_circle(Vector2(cx, cy), 7.0, Color(col.r, col.g, col.b, 0.35))
				draw_arc(Vector2(cx, cy), 7.0, 0.0, TAU, 20, col, 2.0)
				draw_circle(Vector2(cx, cy), 3.2, col)
			"EYE":
				draw_arc(Vector2(cx, cy + 3), 8.0, PI * 1.15, PI * 1.85, 16, col, 2.0)
				draw_arc(Vector2(cx, cy - 3), 8.0, PI * 0.15, PI * 0.85, 16, col, 2.0)
				draw_circle(Vector2(cx, cy), 2.8, col)

static func style_cyan_slider(sl: HSlider, fill_col: Color) -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("#132032")
	bg.set_corner_radius_all(3)
	bg.content_margin_top = 4
	bg.content_margin_bottom = 4
	var fg := StyleBoxFlat.new()
	fg.bg_color = fill_col
	fg.set_corner_radius_all(3)
	fg.content_margin_top = 4
	fg.content_margin_bottom = 4
	sl.add_theme_stylebox_override("slider", bg)
	sl.add_theme_stylebox_override("grabber_area", fg)
	sl.add_theme_stylebox_override("grabber_area_highlight", fg)
