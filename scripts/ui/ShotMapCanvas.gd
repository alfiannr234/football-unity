class_name ShotMapCanvas
extends Control

signal shot_selected(shot: Dictionary)

var shots: Array = []
var mode_filter: String = "SHOT"  # SHOT, UMPAN, DRIBEL
var selected_idx: int = -1
var is_goal_face: bool = false

var _pitch_tex: Texture2D

func _ready() -> void:
	_pitch_tex = load("res://assets/sprites/pitch/pitch_turf.png")

func set_shots(shot_list: Array, mode: String, goal_face: bool) -> void:
	shots = []
	mode_filter = mode
	is_goal_face = goal_face
	for s in shot_list:
		var t := str(s.get("type", "OPEN_PLAY"))
		if mode == "UMPAN" and t == "PASS":
			shots.append(s)
		elif mode == "DRIBEL" and t == "DRIBBLE":
			shots.append(s)
		elif mode == "SHOT" and t != "PASS" and t != "DRIBBLE":
			shots.append(s)
	selected_idx = -1
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var best_i := -1
		var best_d := 18.0
		for i in range(shots.size()):
			var pt := _shot_to_screen(shots[i])
			var d := pt.distance_to(event.position)
			if d < best_d:
				best_d = d
				best_i = i
		if best_i >= 0:
			selected_idx = best_i
			queue_redraw()
			shot_selected.emit(shots[best_i])

func _shot_to_screen(s: Dictionary) -> Vector2:
	if is_goal_face:
		var gc: Dictionary = s.get("goalCoord", {"x": 0.5, "y": 0.5})
		var gx := clampf(float(gc.get("x", 0.5)), 0.05, 0.95)
		var gy := clampf(float(gc.get("y", 0.5)), 0.05, 0.95)
		return Vector2(size.x * (0.14 + gx * 0.72), size.y * (0.20 + (1.0 - gy) * 0.62))
	else:
		var pc: Dictionary = s.get("pitchCoord", {"x": 0.5, "y": 0.8})
		var px := clampf(float(pc.get("x", 0.5)), 0.05, 0.95)
		var py := clampf(float(pc.get("y", 0.8)), 0.05, 0.95)
		return Vector2(size.x * px, size.y * (1.0 - py * 0.85))

func _draw() -> void:
	if is_goal_face:
		# Sky + Stadium background + Goal frame matching screenshot #25!
		draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, size.y * 0.68)), Color("#3B6496"))
		draw_rect(Rect2(0, size.y * 0.68, size.x, size.y * 0.32), Color("#246C34"))
		# Ad boards behind goal
		draw_rect(Rect2(0, size.y * 0.60, size.x, size.y * 0.10), Color("#143B7C"))
		draw_string(UITheme.get_display_font(), Vector2(size.x * 0.38, size.y * 0.67), "LIGA KE-3", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
		# Goal frame
		var g_rect := Rect2(size.x * 0.14, size.y * 0.20, size.x * 0.72, size.y * 0.62)
		# Net grid
		for x in range(int(g_rect.position.x), int(g_rect.end.x), 10):
			draw_line(Vector2(x, g_rect.position.y), Vector2(x, g_rect.end.y), Color(0.9, 0.94, 0.98, 0.35), 1.0)
		for y in range(int(g_rect.position.y), int(g_rect.end.y), 10):
			draw_line(Vector2(g_rect.position.x, y), Vector2(g_rect.end.x, y), Color(0.9, 0.94, 0.98, 0.35), 1.0)
		draw_polyline(PackedVector2Array([
			Vector2(g_rect.position.x, g_rect.end.y),
			Vector2(g_rect.position.x, g_rect.position.y),
			Vector2(g_rect.end.x, g_rect.position.y),
			Vector2(g_rect.end.x, g_rect.end.y),
		]), Color("#F2F6FC"), 4.0)
	else:
		# Top-half pitch view
		if _pitch_tex != null:
			draw_texture_rect_region(_pitch_tex, Rect2(Vector2.ZERO, size), Rect2(0, 0, 512, 460))
		else:
			draw_rect(Rect2(Vector2.ZERO, size), Color("#266B36"))

	# Plot shot dots
	for i in range(shots.size()):
		var s: Dictionary = shots[i]
		var pt := _shot_to_screen(s)
		var out := str(s.get("outcome", "ON_TARGET"))
		var col := Color("#E2E8F0")  # Tepat sasaran = white
		if out == "GOAL":
			col = Color("#F5C542")   # Gol = gold
		elif out == "WIDE":
			col = Color("#EF6C32")   # Melebar = orange
		elif out == "BLOCKED":
			col = Color("#64748B")   # Diblok = grey
		var rad := 7.0 if i == selected_idx else 5.0
		draw_circle(pt, rad + 1.5, Color("#0A1220"))
		draw_circle(pt, rad, col)
		if i == selected_idx:
			draw_arc(pt, rad + 4.0, 0, TAU, 16, Color("#38BDF8"), 2.0)
