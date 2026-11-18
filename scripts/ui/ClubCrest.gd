class_name ClubCrest
extends Control

@export var club_id: int = 0:
	set(value):
		club_id = value
		queue_redraw()

func set_club(cid: int) -> void:
	club_id = cid
	queue_redraw()

func _draw() -> void:
	if GameData.clubs.is_empty():
		return
	var c: Dictionary = GameData.clubs[clampi(club_id, 0, GameData.clubs.size() - 1)]
	var p_col: Color = c.get("primary", Color("#1E64D8"))
	var s_col: Color = c.get("secondary", Color.WHITE)
	var shape: int = int(c.get("crest_shape", 0))
	var code: String = str(c.get("code", "FC"))

	var w := size.x
	var h := size.y
	var cx := w * 0.5
	var cy := h * 0.5
	var r := minf(w, h) * 0.44
	var pat: String = str(c.get("pattern", "stripes"))
	var shadow_col := Color(0.0, 0.0, 0.0, 0.42)

	if shape == 1:  # Circle crest with double metallic rim & internal accent band
		draw_circle(Vector2(cx + 1.5, cy + 2.5), r, shadow_col)
		draw_circle(Vector2(cx, cy), r, p_col)
		draw_arc(Vector2(cx, cy), r * 0.72, 0, TAU, 24, Color(s_col.r, s_col.g, s_col.b, 0.45), 1.5)
		draw_arc(Vector2(cx, cy), r, 0, TAU, 28, s_col, 3.0)
	elif shape == 2:  # Diamond crest with beveled gloss
		var pts := PackedVector2Array([
			Vector2(cx, cy - r), Vector2(cx + r, cy),
			Vector2(cx, cy + r), Vector2(cx - r, cy)
		])
		var sh := PackedVector2Array([pts[0] + Vector2(1.5, 2.5), pts[1] + Vector2(1.5, 2.5), pts[2] + Vector2(1.5, 2.5), pts[3] + Vector2(1.5, 2.5)])
		draw_colored_polygon(sh, shadow_col)
		draw_colored_polygon(pts, p_col)
		draw_colored_polygon(PackedVector2Array([Vector2(cx, cy - r * 0.92), Vector2(cx + r * 0.92, cy), Vector2(cx, cy)]), Color(1, 1, 1, 0.14))
		draw_polyline(pts + PackedVector2Array([pts[0]]), s_col, 2.5)
	else:  # Classic Heraldic Shield crest with split sash/rim & gloss
		var pts := PackedVector2Array([
			Vector2(cx - r * 0.85, cy - r * 0.9),
			Vector2(cx + r * 0.85, cy - r * 0.9),
			Vector2(cx + r * 0.85, cy + r * 0.15),
			Vector2(cx, cy + r * 0.98),
			Vector2(cx - r * 0.85, cy + r * 0.15),
		])
		var sh := PackedVector2Array()
		for pt in pts:
			sh.append(pt + Vector2(2.0, 3.0))
		draw_colored_polygon(sh, shadow_col)
		var base_c := s_col if c["name"] == "Danderyd Edsviken" else p_col
		draw_colored_polygon(pts, base_c)
		if pat == "halved" or pat == "sash":
			draw_colored_polygon(PackedVector2Array([Vector2(cx, cy - r * 0.88), Vector2(cx + r * 0.82, cy - r * 0.88), Vector2(cx + r * 0.82, cy + r * 0.12), Vector2(cx, cy + r * 0.94)]), Color(s_col.r, s_col.g, s_col.b, 0.22))
		# Top glass highlight bevel
		draw_colored_polygon(PackedVector2Array([Vector2(cx - r * 0.82, cy - r * 0.86), Vector2(cx + r * 0.82, cy - r * 0.86), Vector2(cx + r * 0.82, cy - r * 0.3), Vector2(cx - r * 0.82, cy - r * 0.1)]), Color(1, 1, 1, 0.16))
		draw_polyline(pts + PackedVector2Array([pts[0]]), Color("#D4B050") if c["name"] == "Danderyd Edsviken" else s_col, 2.8)

	# Inner emblem (star or stripe or text with shadow)
	if c["name"] == "Danderyd Edsviken":
		_draw_star(Vector2(cx, cy - r * 0.05), r * 0.42, Color("#1A66D2"))
	elif w >= 28:
		var font := UITheme.get_display_font()
		var fsz := int(clampf(w * 0.24, 8, 22))
		var t_size := font.get_string_size(code, HORIZONTAL_ALIGNMENT_CENTER, -1, fsz)
		draw_string(font, Vector2(cx - t_size.x * 0.5 + 1.0, cy + t_size.y * 0.3 + 1.5), code, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, Color(0, 0, 0, 0.55))
		draw_string(font, Vector2(cx - t_size.x * 0.5, cy + t_size.y * 0.3), code, HORIZONTAL_ALIGNMENT_LEFT, -1, fsz, s_col)
	else:
		draw_rect(Rect2(cx - r * 0.28, cy - r * 0.14, r * 0.56, r * 0.28), s_col)

func _draw_star(center: Vector2, rad: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in range(10):
		var ang := -PI * 0.5 + float(i) * PI / 5.0
		var rr := rad if i % 2 == 0 else rad * 0.45
		pts.append(center + Vector2(cos(ang), sin(ang)) * rr)
	draw_colored_polygon(pts, col)
