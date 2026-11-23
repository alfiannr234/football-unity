class_name PixelJerseyIcon
extends Control

# Crisp 20x18 pixel-art miniature football jersey renderer for the 3-kit matchday selector.

var primary_color: Color = Color("#1A66D2")
var secondary_color: Color = Color("#F4F8FF")
var kit_pattern: String = "stripes"

func configure_kit(kit: Dictionary) -> void:
	primary_color = kit.get("primary", Color("#1A66D2"))
	secondary_color = kit.get("secondary", Color("#F4F8FF"))
	kit_pattern = str(kit.get("pattern", "stripes"))
	queue_redraw()

func _draw() -> void:
	var gw := 20.0
	var gh := 18.0
	var ps := floorf(minf(size.x / gw, size.y / gh))
	if ps < 1.0:
		ps = 1.0
	var ox := floorf((size.x - gw * ps) * 0.5)
	var oy := floorf((size.y - gh * ps) * 0.5)
	var blk := Color("#0D1017")
	var px := func(x: int, y: int, w: int, h: int, col: Color):
		draw_rect(Rect2(ox + float(x) * ps, oy + float(y) * ps, float(w) * ps, float(h) * ps), col)

	# Outer silhouette (sleeves + torso)
	px.call(4, 1, 12, 16, blk)
	px.call(1, 3, 4, 6, blk)
	px.call(15, 3, 4, 6, blk)
	px.call(2, 2, 3, 2, blk)
	px.call(15, 2, 3, 2, blk)

	# Sleeves fill
	var r_sl := secondary_color if kit_pattern == "halved" else primary_color
	px.call(2, 3, 3, 5, primary_color)
	px.call(2, 7, 3, 1, secondary_color)
	px.call(15, 3, 3, 5, r_sl)
	px.call(15, 7, 3, 1, secondary_color)

	# Torso fill + pattern
	px.call(5, 2, 10, 14, primary_color)
	match kit_pattern:
		"stripes":
			px.call(6, 2, 2, 14, secondary_color)
			px.call(12, 2, 2, 14, secondary_color)
		"hoops":
			px.call(5, 5, 10, 3, secondary_color)
			px.call(5, 11, 10, 3, secondary_color)
		"sash":
			for k in range(10):
				px.call(5 + k, 2 + k, 2, 3, secondary_color)
		"halved":
			px.call(10, 2, 5, 14, secondary_color)
		"chest_band":
			px.call(5, 6, 10, 4, secondary_color)
			px.call(5, 5, 10, 1, secondary_color.darkened(0.25))
		"gradient":
			px.call(5, 7, 10, 3, primary_color.lerp(secondary_color, 0.35))
			px.call(5, 10, 10, 3, primary_color.lerp(secondary_color, 0.72))
			px.call(5, 13, 10, 3, secondary_color)
		"checkered":
			for cy in range(2, 16, 2):
				for cx in range(5, 15, 2):
					if ((cx + cy) / 2) % 2 == 0:
						px.call(cx, cy, 2, 2, secondary_color)

	# Collar cutout & rim + shading + mini crest
	px.call(7, 2, 6, 2, secondary_color)
	px.call(8, 1, 4, 2, Color("#162338"))
	px.call(5, 2, 1, 14, Color(1, 1, 1, 0.12))
	px.call(14, 2, 1, 14, Color(0, 0, 0, 0.20))
	px.call(11, 5, 2, 2, Color.WHITE)
	px.call(7, 5, 1, 1, secondary_color.lightened(0.25))
