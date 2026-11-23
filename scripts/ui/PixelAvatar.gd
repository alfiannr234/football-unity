class_name PixelAvatar
extends Control

# Sculpted 32x48 pixel-art footballer renderer supporting 16 layered hairstyles,
# 8 beard styles, 8 club jersey patterns, GK padded gloves, shorts numbers,
# tattoos, casual/gala outfits, portrait/full-body framing, and procedural anims.

var full_body: bool = true
var primary_color: Color = Color("#1A66D2")
var secondary_color: Color = Color("#F4F8FF")
var shorts_color: Color = Color("#F4F8FF")
var kit_pattern: String = "stripes"
var skin_idx: int = 1
var hair_style: int = 2
var hair_idx: int = 1
var tip_color_idx: int = 0
var beard: bool = false
var beard_style: int = 0
var long_sleeve: bool = false
var boot_color: Color = Color("#2D73DC")
var glove_color: Color = Color.TRANSPARENT
var wrist_side: String = "TAK ADA"
var wrist_color: Color = Color("#FFFFFF")
var shirt_num: int = 9
var tattoo_face: int = 0
var tattoo_arm: int = 0
var tattoo_leg: int = 0
var headwear: int = 0
var eyewear: int = 0
var casual_style: int = 0  # 0=Jersey, 1=Kasual, 2=Gala
var outfit_variant: int = 0
var show_number_badge: bool = false
var show_shorts_number: bool = false
var show_mvp_trophy: bool = false

# Procedural animation state: "NONE", "IDLE", "TALK", "CHEER", "MVP", "SING", "SIGN", "RUN"
var anim_mode: String = "NONE"
var anim_phase: float = 0.0
var _anim_t: float = 0.0

const SKINS := [Color("#F8D8BC"), Color("#E8BC96"), Color("#CE9466"), Color("#AC7248"), Color("#895333"), Color("#5C3723")]
const HAIRS := [Color("#18161C"), Color("#5C3824"), Color("#8E572E"), Color("#D9AC44"), Color("#A23A26"), Color("#9CA3AF"), Color("#E8ECF2"), Color("#2E7AE6"), Color("#D43038"), Color("#D84A90")]

func _ready() -> void:
	_anim_t = anim_phase

func _process(delta: float) -> void:
	if anim_mode == "NONE" or not visible:
		return
	_anim_t += delta
	queue_redraw()

func apply_kit(kit: Dictionary) -> void:
	if kit.is_empty():
		return
	primary_color = kit.get("primary", primary_color)
	secondary_color = kit.get("secondary", secondary_color)
	shorts_color = kit.get("shorts", secondary_color if primary_color.get_luminance() < 0.68 else Color("#18202E"))
	kit_pattern = str(kit.get("pattern", kit_pattern))
	queue_redraw()

func configure_from_career() -> void:
	var st: SceneTree = Engine.get_main_loop() as SceneTree
	var cs: Node = st.root.get_node_or_null("CareerState") if st != null else null
	if cs == null or not bool(cs.get("has_active_career")):
		return
	var car: Dictionary = cs.get("career")
	var p: Dictionary = car.get("playerProfile", {})
	if p.is_empty():
		return
	var club: Dictionary = cs.call("get_current_club")
	var app: Dictionary = p.get("appearance", {})
	primary_color = club.get("primary", Color("#1A66D2"))
	secondary_color = club.get("secondary", Color("#F4F8FF"))
	shorts_color = secondary_color if primary_color.get_luminance() < 0.68 else Color("#18202E")
	kit_pattern = str(club.get("pattern", "stripes"))
	skin_idx = int(app.get("skin", 1))
	hair_style = int(app.get("hair_style", 2))
	hair_idx = int(app.get("hair_color", 1))
	tip_color_idx = int(app.get("tip_color", 0))
	beard_style = int(app.get("beard_style", 1 if bool(app.get("beard", false)) else 0))
	beard = (beard_style > 0)
	long_sleeve = str(app.get("sleeve", "PENDEK")) == "PANJANG"
	shirt_num = int(app.get("shirt_num", 9))

	var boot_id := int(app.get("boot_id", 0))
	var boot_cols := [
		Color("#20242C"), Color("#E8ECF2"), Color("#D72A30"), Color("#2A7CE4"),
		Color("#F2C638"), Color("#DA4898"), Color("#40D45C"), Color("#EE7624"),
		Color("#2AEBD2"), Color("#843ED2"), Color("#F5CD48")
	]
	boot_color = boot_cols[clampi(boot_id, 0, boot_cols.size() - 1)]

	var gc_idx := int(app.get("glove_color", -1))
	var glove_cols := [Color("#181C24"), Color("#F2F4F8"), Color("#C82832"), Color("#1E54B8"), Color("#F5C542"), Color("#EE7624")]
	glove_color = glove_cols[clampi(gc_idx, 0, glove_cols.size() - 1)] if gc_idx >= 0 else Color.TRANSPARENT

	wrist_side = str(app.get("wrist_side", "TAK ADA"))
	var wc_idx := int(app.get("wrist_color", 0))
	var wc_cols := [Color("#94A3B8"), Color("#1E3A8A"), Color("#DC2626"), Color("#EAB308"), Color("#16A34A"), Color("#9333EA"), Color("#EA580C")]
	wrist_color = wc_cols[clampi(wc_idx, 0, wc_cols.size() - 1)]
	tattoo_face = int(app.get("tattoo_face", 0))
	tattoo_arm = int(app.get("tattoo_arm", 0))
	tattoo_leg = int(app.get("tattoo_leg", 0))
	headwear = int(app.get("headwear", 0))
	eyewear = int(app.get("eyewear", 0))
	casual_style = int(app.get("casual_style", 0))
	outfit_variant = int(app.get("outfit_variant", 0))
	queue_redraw()

func configure_from_seed(seed_val: int, club: Dictionary, num: int = 10) -> void:
	primary_color = club.get("primary", Color("#1A66D2"))
	secondary_color = club.get("secondary", Color("#F4F8FF"))
	shorts_color = club.get("shorts", secondary_color if primary_color.get_luminance() < 0.68 else Color("#18202E"))
	kit_pattern = str(club.get("pattern", "stripes"))
	skin_idx = abs(seed_val) % SKINS.size()
	hair_style = abs(seed_val / 3) % CharacterStyleCatalog.HAIR_STYLES.size()
	hair_idx = abs(seed_val / 7) % 6
	tip_color_idx = 0
	beard_style = abs(seed_val / 5) % 4 if (abs(seed_val) % 4) == 0 else 0
	beard = (beard_style > 0)
	long_sleeve = (abs(seed_val) % 4) == 0
	var ai_boots := [Color("#1D2430"), Color("#E2E8F0"), Color("#DC2626"), Color("#22C55E"), Color("#EAB308"), Color("#2563EB")]
	boot_color = ai_boots[abs(seed_val / 2) % ai_boots.size()]
	glove_color = Color.TRANSPARENT
	wrist_side = "TAK ADA"
	tattoo_face = 0
	tattoo_arm = 1 if (abs(seed_val) % 6) == 0 else 0
	tattoo_leg = 0
	headwear = 0
	eyewear = 0
	casual_style = 0
	outfit_variant = 0
	shirt_num = num
	queue_redraw()

func _draw() -> void:
	var grid_w := 32.0
	var grid_h := 48.0 if full_body else 28.0
	var ps := floorf(minf(size.x / grid_w, size.y / grid_h))
	if ps < 1.0:
		ps = maxf(0.5, minf(size.x / grid_w, size.y / grid_h))
	var ox := floorf((size.x - grid_w * ps) * 0.5)
	var oy := floorf((size.y - grid_h * ps) * 0.5)

	var t := _anim_t
	var bob_y: int = 0
	var head_y_off: int = 0
	var l_arm_lift: int = 0
	var r_arm_lift: int = 0
	var arm_spread: int = 0
	var leg_step: int = 0
	var mouth_open: int = 0
	var blink := false

	match anim_mode:
		"IDLE":
			bob_y = 1 if sin(t * 2.8) > 0.45 else 0
			blink = fmod(t, 3.6) > 3.44
		"TALK":
			bob_y = 1 if sin(t * 4.5) > 0.35 else 0
			mouth_open = 1 if sin(t * 11.0) > 0.1 else 0
			r_arm_lift = -2 if sin(t * 5.2) > 0.2 else 0
		"CHEER", "MVP":
			var hop := absf(sin(t * 6.5))
			bob_y = -2 if hop > 0.55 else (-1 if hop > 0.25 else 0)
			head_y_off = -1 if hop > 0.7 else 0
			l_arm_lift = -7 if sin(t * 6.5) > -0.6 else -4
			r_arm_lift = -7 if cos(t * 6.5) > -0.6 else -4
			arm_spread = 1
			mouth_open = 2
		"SING":
			bob_y = 1 if sin(t * 4.2) > 0.3 else 0
			l_arm_lift = -4 + int(round(sin(t * 4.2)))
			r_arm_lift = -4 - int(round(sin(t * 4.2)))
			arm_spread = 2
			mouth_open = 2 if sin(t * 9.0) > -0.25 else 1
		"SIGN":
			bob_y = 1 if sin(t * 3.5) > 0.5 else 0
			r_arm_lift = 1 if sin(t * 9.0) > 0.0 else -1
			mouth_open = 1 if sin(t * 4.0) > 0.6 else 0
		"RUN":
			var ph := sin(t * 10.0)
			bob_y = -1 if absf(ph) > 0.65 else 0
			leg_step = 1 if ph > 0.2 else (-1 if ph < -0.2 else 0)
			l_arm_lift = -2 if ph > 0.2 else 1
			r_arm_lift = -2 if ph < -0.2 else 1

	var blk := Color("#0D1017")
	var skin: Color = SKINS[clampi(skin_idx, 0, SKINS.size() - 1)]
	var skin_sh: Color = skin.darkened(0.18)
	var skin_dk: Color = skin.darkened(0.30)
	var skin_hi: Color = skin.lightened(0.14)
	var cheek: Color = skin.lerp(Color("#DF6A62"), 0.18)
	var hair: Color = HAIRS[clampi(hair_idx, 0, HAIRS.size() - 1)]
	var hair_hi: Color = hair.lightened(0.26)
	var hair_dk: Color = hair.darkened(0.28)
	var tip_info: Dictionary = CharacterStyleCatalog.TIP_COLORS[clampi(tip_color_idx, 0, CharacterStyleCatalog.TIP_COLORS.size() - 1)]
	var tip_col: Color = tip_info["col"]

	var px := func(x: int, y: int, w: int, h: int, col: Color):
		draw_rect(Rect2(ox + float(x) * ps, oy + float(y) * ps, float(w) * ps, float(h) * ps), col)

	if full_body:
		# Flat grounded pixel shadow ellipse
		px.call(8, 45, 16, 2, Color(0, 0, 0, 0.28))
		px.call(10, 44, 12, 4, Color(0, 0, 0, 0.20))

	var hy := head_y_off + (1 if bob_y > 0 else bob_y)
	var by := bob_y

	# -------------------------------------------------------------------------
	# 1. SCULPTED HEAD, EARS, NECK & JAWLINE (beveled retro outline)
	# -------------------------------------------------------------------------
	# Neck + collar shadow
	px.call(13, 17 + hy, 6, 4, blk)
	px.call(14, 17 + hy, 4, 3, skin_sh)
	px.call(14, 17 + hy, 4, 1, skin_dk)

	# Contoured Ears
	px.call(8, 10 + hy, 2, 4, blk)
	px.call(9, 11 + hy, 1, 2, skin)
	px.call(9, 12 + hy, 1, 1, skin_sh)
	px.call(22, 10 + hy, 2, 4, blk)
	px.call(22, 11 + hy, 1, 2, skin_sh)
	px.call(22, 12 + hy, 1, 1, skin_dk)

	# Beveled Head Silhouette (rounded cranium & tapered chin)
	px.call(10, 4 + hy, 12, 1, blk)
	px.call(9, 5 + hy, 14, 11, blk)
	px.call(10, 16 + hy, 12, 1, blk)
	px.call(11, 17 + hy, 10, 1, blk)
	px.call(12, 18 + hy, 8, 1, blk)
	# Skin Base Fill
	px.call(10, 5 + hy, 12, 10, skin)
	px.call(11, 15 + hy, 10, 2, skin)
	px.call(12, 17 + hy, 8, 1, skin_sh)
	# Forehead highlight, side contour & warm cheek shading
	px.call(11, 6 + hy, 6, 1, skin_hi)
	px.call(10, 6 + hy, 1, 9, skin_hi)
	px.call(20, 6 + hy, 2, 9, skin_sh)
	px.call(19, 15 + hy, 2, 1, skin_sh)
	px.call(11, 13 + hy, 2, 1, cheek)
	px.call(19, 13 + hy, 2, 1, cheek)

	# Expressive Eyes & Contoured Eyebrows
	if blink:
		px.call(11, 11 + hy, 3, 1, blk)
		px.call(18, 11 + hy, 3, 1, blk)
	else:
		# Left eye
		px.call(11, 10 + hy, 3, 2, Color("#F6F8FC"))
		px.call(12, 10 + hy, 2, 2, Color("#15233C"))
		px.call(12, 10 + hy, 1, 1, Color("#FFFFFF"))
		px.call(11, 12 + hy, 3, 1, skin_sh)
		# Right eye
		px.call(18, 10 + hy, 3, 2, Color("#F6F8FC"))
		px.call(18, 10 + hy, 2, 2, Color("#15233C"))
		px.call(18, 10 + hy, 1, 1, Color("#FFFFFF"))
		px.call(18, 12 + hy, 3, 1, skin_sh)
	# Brows
	px.call(11, 8 + hy, 3, 1, hair_dk)
	px.call(14, 9 + hy, 1, 1, hair_dk)
	px.call(18, 8 + hy, 3, 1, hair_dk)
	px.call(17, 9 + hy, 1, 1, hair_dk)
	# Sculpted Nose
	px.call(15, 11 + hy, 2, 2, skin_sh)
	px.call(15, 13 + hy, 2, 1, skin_dk)
	# Expressive Mouth
	if mouth_open >= 2:
		px.call(13, 14 + hy, 6, 2, Color("#6F1D24"))
		px.call(14, 14 + hy, 4, 1, Color("#F8FAFC"))
	elif mouth_open == 1:
		px.call(14, 15 + hy, 4, 1, Color("#7D2A30"))
	else:
		px.call(14, 15 + hy, 4, 1, Color("#8A453B"))
		px.call(15, 16 + hy, 2, 1, skin_sh)

	# -------------------------------------------------------------------------
	# 2. FACE TATTOOS & BEARD STYLES
	# -------------------------------------------------------------------------
	match clampi(tattoo_face, 0, 5):
		1: px.call(11, 13 + hy, 1, 1, Color("#202D3A"))
		2:
			px.call(11, 13 + hy, 1, 1, Color("#202D3A"))
			px.call(20, 13 + hy, 1, 1, Color("#202D3A"))
		3: px.call(11, 12 + hy, 1, 2, Color("#1F354D"))
		4: px.call(20, 9 + hy, 1, 4, Color("#6A2C2C"))
		5: px.call(14, 18 + hy, 4, 2, Color("#1A2634"))

	var eff_beard := beard_style if beard_style > 0 else (1 if beard else 0)
	match clampi(eff_beard, 0, 7):
		1:
			px.call(10, 14 + hy, 12, 2, Color(hair.r, hair.g, hair.b, 0.50))
			px.call(12, 16 + hy, 8, 2, Color(hair.r, hair.g, hair.b, 0.58))
		2:
			px.call(10, 13 + hy, 1, 3, hair)
			px.call(21, 13 + hy, 1, 3, hair)
			px.call(11, 15 + hy, 10, 2, hair)
			px.call(12, 17 + hy, 8, 1, hair_dk)
			px.call(14, 14 + hy, 4, 1, hair)
		3:
			px.call(10, 12 + hy, 2, 4, hair)
			px.call(20, 12 + hy, 2, 4, hair)
			px.call(11, 14 + hy, 10, 4, hair)
			px.call(12, 17 + hy, 8, 2, hair_dk)
		4:
			px.call(15, 16 + hy, 2, 2, hair)
		5:
			px.call(14, 14 + hy, 4, 1, hair)
			px.call(13, 16 + hy, 6, 2, hair)
		6:
			px.call(13, 14 + hy, 6, 1, hair)
			px.call(12, 15 + hy, 2, 1, hair_dk)
			px.call(18, 15 + hy, 2, 1, hair_dk)
		7:
			px.call(10, 11 + hy, 2, 5, hair)
			px.call(20, 11 + hy, 2, 5, hair)

	# -------------------------------------------------------------------------
	# 3. 16 LAYERED HAIRSTYLES WITH CROWN HIGHLIGHTS & SHADOWS
	# -------------------------------------------------------------------------
	var hs := clampi(hair_style, 0, CharacterStyleCatalog.HAIR_STYLES.size() - 1)
	var tip_eff: Color = tip_col if tip_col.a > 0.1 else hair_hi
	match hs:
		0: # BOTAK
			px.call(12, 5 + hy, 4, 1, skin_hi)
		1: # KLASIK RAPI
			px.call(9, 2 + hy, 14, 5, blk)
			px.call(10, 3 + hy, 12, 4, hair)
			px.call(10, 7 + hy, 1, 3, hair)
			px.call(21, 7 + hy, 1, 3, hair)
			px.call(11, 3 + hy, 6, 1, tip_eff)
			px.call(10, 6 + hy, 12, 1, hair_dk)
		2: # KERITING IKAL (Signature fluffy curls like Gambar 3)
			px.call(8, 1 + hy, 16, 6, blk)
			px.call(9, 2 + hy, 14, 5, hair)
			px.call(10, 1 + hy, 4, 2, hair_hi)
			px.call(16, 1 + hy, 5, 2, tip_eff)
			px.call(11, 5 + hy, 3, 1, hair_dk)
			px.call(16, 5 + hy, 3, 1, hair_dk)
			px.call(9, 7 + hy, 2, 3, hair)
			px.call(21, 7 + hy, 2, 3, hair)
		3: # AFRO BULAT
			px.call(7, 0 + hy, 18, 8, blk)
			px.call(8, 1 + hy, 16, 7, hair)
			px.call(7, 6 + hy, 2, 4, hair)
			px.call(23, 6 + hy, 2, 4, hair)
			px.call(10, 2 + hy, 7, 2, tip_eff)
			px.call(14, 5 + hy, 5, 1, hair_dk)
		4: # MOHAWK PUNK
			px.call(13, 0 + hy, 6, 6, blk)
			px.call(14, 1 + hy, 4, 5, hair)
			px.call(15, 0 + hy, 2, 2, tip_eff)
			px.call(10, 5 + hy, 3, 1, skin_sh)
			px.call(19, 5 + hy, 3, 1, skin_sh)
		5: # HI-TOP FADE
			px.call(9, 1 + hy, 14, 5, blk)
			px.call(10, 2 + hy, 12, 4, hair)
			px.call(11, 2 + hy, 10, 1, tip_eff)
			px.call(10, 5 + hy, 12, 1, hair_dk)
		6: # CURTAIN PENDEK
			px.call(9, 2 + hy, 14, 5, blk)
			px.call(10, 3 + hy, 12, 3, hair)
			px.call(9, 6 + hy, 5, 3, hair)
			px.call(18, 6 + hy, 5, 3, hair)
			px.call(15, 6 + hy, 2, 2, skin)
			px.call(11, 3 + hy, 4, 1, tip_eff)
			px.call(18, 3 + hy, 3, 1, tip_eff)
		7: # SPIKY FADE
			px.call(9, 2 + hy, 14, 4, blk)
			px.call(10, 3 + hy, 12, 3, hair)
			px.call(11, 0 + hy, 2, 3, tip_eff)
			px.call(15, 0 + hy, 2, 3, hair)
			px.call(19, 0 + hy, 2, 3, tip_eff)
		8: # QUIFF RENDAH
			px.call(9, 2 + hy, 14, 4, blk)
			px.call(11, 1 + hy, 10, 4, hair)
			px.call(13, 1 + hy, 7, 2, tip_eff)
		9: # EDGAR CROP
			px.call(9, 2 + hy, 14, 6, blk)
			px.call(10, 3 + hy, 12, 5, hair)
			px.call(11, 4 + hy, 10, 1, tip_eff)
		10: # GONDRONG
			px.call(8, 2 + hy, 16, 5, blk)
			px.call(7, 6 + hy, 3, 11, blk)
			px.call(22, 6 + hy, 3, 11, blk)
			px.call(9, 3 + hy, 14, 3, hair)
			px.call(8, 6 + hy, 2, 10, hair)
			px.call(22, 6 + hy, 2, 10, hair)
			px.call(11, 3 + hy, 7, 1, tip_eff)
		11: # DREADLOCK PENDEK
			px.call(8, 2 + hy, 16, 5, blk)
			for dx in [8, 11, 14, 17, 20]:
				px.call(dx, 3 + hy, 2, 6, hair)
				px.call(dx, 8 + hy, 2, 1, tip_eff)
		12: # TWIST KERITING
			px.call(9, 2 + hy, 14, 4, blk)
			for tx in [10, 13, 16, 19]:
				px.call(tx, 1 + hy, 2, 4, hair)
				px.call(tx, 1 + hy, 1, 1, tip_eff)
		13: # CORNROW SISI
			px.call(9, 3 + hy, 14, 3, hair_dk)
			for rx in [10, 14, 18]:
				px.call(rx, 3 + hy, 2, 3, hair)
				px.call(rx + 1, 3 + hy, 1, 3, tip_eff)
		14: # MANGKUK UNDERCUT
			px.call(8, 2 + hy, 16, 5, blk)
			px.call(9, 3 + hy, 14, 4, hair)
			px.call(9, 7 + hy, 14, 1, hair_dk)
			px.call(11, 4 + hy, 8, 1, tip_eff)
		15: # BUZZ CUT
			px.call(10, 4 + hy, 12, 2, hair)
			px.call(12, 4 + hy, 6, 1, tip_eff)

	# -------------------------------------------------------------------------
	# 4. EYEWEAR & HEADWEAR
	# -------------------------------------------------------------------------
	match clampi(eyewear, 0, 3):
		1:
			px.call(10, 9 + hy, 12, 3, Color("#12161E"))
			px.call(11, 10 + hy, 4, 2, Color("#EA9228"))
			px.call(17, 10 + hy, 4, 2, Color("#EA9228"))
			px.call(15, 10 + hy, 2, 1, Color("#D4A842"))
		2:
			px.call(10, 9 + hy, 12, 3, Color("#0A0D12"))
			px.call(11, 10 + hy, 1, 1, Color("#94A3B8"))
			px.call(18, 10 + hy, 1, 1, Color("#94A3B8"))
		3:
			px.call(10, 9 + hy, 12, 3, Color("#0E2942"))
			px.call(11, 10 + hy, 10, 2, Color("#38BDF8"))

	match clampi(headwear, 0, 4):
		1:
			px.call(8, 2 + hy, 16, 4, Color("#1B2A40"))
			px.call(10, 3 + hy, 12, 2, Color("#2E5280"))
			px.call(7, 5 + hy, 18, 1, Color("#101824"))
		2:
			px.call(9, 1 + hy, 14, 5, Color("#88222A"))
			px.call(9, 4 + hy, 14, 2, Color("#B8323E"))
		3:
			px.call(9, 6 + hy, 14, 2, Color("#F0F4F8"))
			px.call(15, 6 + hy, 2, 1, primary_color)
		4:
			px.call(9, 2 + hy, 14, 5, Color("#1E2430"))
			px.call(22, 5 + hy, 2, 7, Color("#283448"))

	# -------------------------------------------------------------------------
	# 5. ATHLETIC TORSO & 8 PRO CLUB JERSEY PATTERNS (y = 19..33)
	# -------------------------------------------------------------------------
	px.call(8, 19 + by, 16, 14, blk)
	if casual_style == 2:
		var suit_pal := [
			[Color("#191E28"), Color("#EBF1F6"), Color("#B42432")],
			[Color("#1A355B"), Color("#EBF1F6"), Color("#D4A842")],
			[Color("#681A28"), Color("#181C24"), Color("#D4A842")],
			[Color("#D8D2C2"), Color("#FFFFFF"), Color("#B89436")],
			[Color("#242B36"), Color("#D8E2EE"), Color("#2E6CA8")],
		]
		var pal: Array = suit_pal[clampi(outfit_variant, 0, suit_pal.size() - 1)]
		px.call(9, 20 + by, 14, 12, pal[0])
		px.call(13, 20 + by, 6, 10, pal[1])
		px.call(15, 20 + by, 2, 8, pal[2])
		px.call(10, 20 + by, 2, 12, (pal[0] as Color).lightened(0.08))
		px.call(20, 20 + by, 2, 12, (pal[0] as Color).darkened(0.18))
	elif casual_style == 1:
		match clampi(outfit_variant, 0, 4):
			0:
				px.call(9, 20 + by, 14, 12, Color("#ECEEE8"))
				px.call(14, 20 + by, 4, 2, Color("#D0D6DE"))
			1:
				px.call(9, 20 + by, 14, 12, Color("#223042"))
				px.call(9, 24 + by, 14, 3, Color("#EA7E22"))
				px.call(14, 22 + by, 4, 2, Color("#F8FAFC"))
			2:
				px.call(9, 20 + by, 14, 12, Color("#ECEEE8"))
				px.call(9, 20 + by, 4, 12, Color("#8E2832"))
				px.call(19, 20 + by, 4, 12, Color("#8E2832"))
			3:
				px.call(9, 20 + by, 14, 12, Color("#243A5E"))
				px.call(15, 20 + by, 2, 12, Color("#94A3B8"))
			4:
				px.call(9, 20 + by, 14, 12, Color("#2E3848"))
				px.call(12, 27 + by, 8, 4, Color("#1F2632"))
				px.call(14, 21 + by, 1, 4, Color("#E2E8F0"))
				px.call(17, 21 + by, 1, 4, Color("#E2E8F0"))
	else:
		# Pro Football Kit Body
		px.call(9, 20 + by, 14, 12, primary_color)
		match kit_pattern:
			"stripes":
				px.call(10, 20 + by, 2, 12, secondary_color)
				px.call(15, 20 + by, 2, 12, secondary_color)
				px.call(20, 20 + by, 2, 12, secondary_color)
			"hoops":
				px.call(9, 22 + by, 14, 3, secondary_color)
				px.call(9, 27 + by, 14, 3, secondary_color)
			"sash":
				for k in range(11):
					px.call(9 + k, 20 + k + by, 3, 2, secondary_color)
			"halved":
				px.call(16, 20 + by, 7, 12, secondary_color)
			"chest_band":
				px.call(9, 23 + by, 14, 4, secondary_color)
				px.call(9, 22 + by, 14, 1, secondary_color.darkened(0.25))
			"gradient":
				px.call(9, 24 + by, 14, 3, primary_color.lerp(secondary_color, 0.35))
				px.call(9, 27 + by, 14, 3, primary_color.lerp(secondary_color, 0.7))
				px.call(9, 30 + by, 14, 2, secondary_color)
			"checkered":
				for cy in range(20, 32, 2):
					for cx in range(9, 23, 2):
						if ((cx + cy) / 2) % 2 == 0:
							px.call(cx, cy + by, 2, 2, secondary_color)
			_:
				# Solid with sharp shoulder accent
				px.call(9, 20 + by, 3, 1, secondary_color)
				px.call(20, 20 + by, 3, 1, secondary_color)

		# Sculpted V-Neck Collar + Fabric Shading Folds
		px.call(13, 20 + by, 6, 2, secondary_color)
		px.call(14, 20 + by, 4, 1, skin_sh)
		px.call(15, 21 + by, 2, 1, skin_dk)
		px.call(9, 20 + by, 2, 12, Color(1, 1, 1, 0.10))
		px.call(21, 20 + by, 2, 12, Color(0, 0, 0, 0.20))
		px.call(9, 31 + by, 14, 1, Color(0, 0, 0, 0.16))
		# Mini Club Shield on left chest + maker dot on right
		px.call(18, 22 + by, 3, 3, blk)
		px.call(19, 22 + by, 2, 2, Color.WHITE)
		px.call(19, 23 + by, 1, 1, secondary_color)
		px.call(11, 23 + by, 1, 1, secondary_color.lightened(0.25))

	if show_number_badge and casual_style == 0:
		var num_col: Color = blk if primary_color.get_luminance() > 0.6 else Color.WHITE
		px.call(13, 25 + by, 6, 5, Color(primary_color.r, primary_color.g, primary_color.b, 0.78))
		draw_string(UITheme.get_display_font(), Vector2(ox + 12.6 * ps, oy + float(29 + by) * ps), str(shirt_num), HORIZONTAL_ALIGNMENT_CENTER, 7.0 * ps, maxf(8.0, ps * 3.8), num_col)

	# -------------------------------------------------------------------------
	# 6. CONNECTED ATHLETIC ARMS, CUFFS, TATTOOS, WRISTBANDS & PADDED GK GLOVES
	# -------------------------------------------------------------------------
	var sl_h := 10 if (long_sleeve or casual_style == 2 or (casual_style == 1 and outfit_variant >= 2)) else 5
	var sleeve_col := primary_color
	var sleeve_r_col := secondary_color if (casual_style == 0 and kit_pattern == "halved") else primary_color
	if casual_style == 2:
		sleeve_col = [Color("#191E28"), Color("#1A355B"), Color("#681A28"), Color("#D8D2C2"), Color("#242B36")][clampi(outfit_variant, 0, 4)]
		sleeve_r_col = sleeve_col
	elif casual_style == 1:
		sleeve_col = [Color("#ECEEE8"), Color("#223042"), Color("#8E2832"), Color("#243A5E"), Color("#2E3848")][clampi(outfit_variant, 0, 4)]
		sleeve_r_col = sleeve_col

	# Left Arm (connected shoulder cap at x=5..8)
	var lax := 5 - arm_spread
	var lay := 19 + by + l_arm_lift
	px.call(lax, lay + 1, 4, 12, blk)
	px.call(lax + 1, lay, 3, 2, blk)
	px.call(lax + 1, lay + 1, 2, 11, skin)
	px.call(lax + 2, lay + 1, 1, 11, skin_sh)
	px.call(lax + 1, lay + 1, 2, sl_h, sleeve_col)
	if casual_style == 0:
		px.call(lax + 1, lay + sl_h, 2, 1, secondary_color)

	# Right Arm (connected shoulder cap at x=23..26)
	var rax := 23 + arm_spread
	var ray := 19 + by + r_arm_lift
	px.call(rax, ray + 1, 4, 12, blk)
	px.call(rax, ray, 3, 2, blk)
	px.call(rax + 1, ray + 1, 2, 11, skin)
	px.call(rax + 2, ray + 1, 1, 11, skin_sh)
	px.call(rax + 1, ray + 1, 2, sl_h, sleeve_r_col)
	if casual_style == 0:
		px.call(rax + 1, ray + sl_h, 2, 1, secondary_color)

	# Arm Tattoos
	if tattoo_arm > 0 and sl_h <= 6:
		var tat_c := Color("#1E2C3B")
		for ty in range(6, 11):
			if tattoo_arm >= 1:
				px.call(rax + 1 + ((ty + tattoo_arm) % 2), ray + ty, 1, 1, tat_c)
			if tattoo_arm >= 2:
				px.call(lax + 1 + (ty % 2), lay + ty, 1, 1, tat_c)
			if tattoo_arm >= 3:
				px.call(rax + 1, ray + ty, 2, 1, Color("#15202B"))
			if tattoo_arm >= 4:
				px.call(lax + 1, lay + ty, 2, 1, Color("#15202B"))

	# Wristbands
	if wrist_side == "LENGAN KIRI" or wrist_side == "KEDUANYA":
		px.call(lax + 1, lay + 9, 2, 2, wrist_color)
	if wrist_side == "LENGAN KANAN" or wrist_side == "KEDUANYA":
		px.call(rax + 1, ray + 9, 2, 2, wrist_color)

	# Padded GK / Field Gloves
	if glove_color.a > 0.1:
		px.call(lax - 1, lay + 9, 4, 4, blk)
		px.call(lax, lay + 10, 3, 2, glove_color)
		px.call(lax, lay + 10, 2, 1, glove_color.lightened(0.2))
		px.call(rax + 1, ray + 9, 4, 4, blk)
		px.call(rax + 1, ray + 10, 3, 2, glove_color)
		px.call(rax + 2, ray + 10, 2, 1, glove_color.lightened(0.2))

	if show_mvp_trophy or anim_mode == "MVP":
		var ty_t := ray - 6
		px.call(rax - 1, ty_t, 5, 5, Color("#D49B24"))
		px.call(rax, ty_t, 3, 3, Color("#FFF394"))
		px.call(rax + 1, ty_t + 5, 1, 2, Color("#D49B24"))
		px.call(rax, ty_t + 7, 3, 1, Color("#A87314"))
		if anim_mode == "MVP" or anim_mode == "CHEER":
			for st_i in range(4):
				var sx_s := int(16.0 + cos(t * 3.5 + float(st_i) * 1.57) * 13.0)
				var sy_s := int(6.0 + sin(t * 4.2 + float(st_i) * 1.9) * 5.0)
				px.call(sx_s, sy_s, 2, 2, UITheme.ACCENT_GOLD if st_i % 2 == 0 else UITheme.ACCENT_CYAN)

	if not full_body:
		return

	# -------------------------------------------------------------------------
	# 7. TAILORED SHORTS, CALVES, STRIPED TALL SOCKS & SHADED CLEATS (y=32..46)
	# -------------------------------------------------------------------------
	var sh_col := shorts_color
	if casual_style == 2:
		sh_col = Color("#181C24")
	elif casual_style == 1:
		sh_col = Color("#2C3D55")

	px.call(9, 32 + by, 14, 6, blk)
	px.call(10, 32 + by, 12, 5, sh_col)
	px.call(10, 32 + by, 12, 1, sh_col.darkened(0.20))
	px.call(15, 35 + by, 2, 3, blk)
	if casual_style == 0:
		px.call(10, 33 + by, 1, 4, secondary_color)
		px.call(21, 33 + by, 1, 4, secondary_color)
		if show_shorts_number and ps >= 2.0:
			var sn_col := blk if sh_col.get_luminance() > 0.55 else Color.WHITE
			draw_string(UITheme.get_ui_font(), Vector2(ox + 17.5 * ps, oy + float(36.5 + by) * ps), str(shirt_num), HORIZONTAL_ALIGNMENT_CENTER, 5.0 * ps, maxf(7.0, ps * 2.5), sn_col)

	var leg_col := skin if tattoo_leg == 0 else Color("#A48A78")
	var leg_sh := leg_col.darkened(0.18)
	var sock_c := primary_color if casual_style == 0 else sh_col

	var ll_y := 38 + by + (0 if leg_step <= 0 else -1)
	var rl_y := 38 + by + (0 if leg_step >= 0 else -1)

	# Left Leg + Tall Double-Striped Sock + Cleat
	px.call(10, ll_y, 5, 6, blk)
	px.call(11, ll_y, 2, 2, leg_col)
	px.call(13, ll_y, 1, 2, leg_sh)
	px.call(11, ll_y + 2, 3, 4, sock_c)
	if casual_style == 0:
		px.call(11, ll_y + 2, 3, 1, secondary_color)
	px.call(9, ll_y + 5, 6, 3, blk)
	px.call(10, ll_y + 6, 4, 2, boot_color)
	px.call(10, ll_y + 6, 2, 1, boot_color.lightened(0.32))
	px.call(10, ll_y + 7, 4, 1, boot_color.darkened(0.24))

	# Right Leg + Tall Double-Striped Sock + Cleat
	px.call(17, rl_y, 5, 6, blk)
	px.call(18, rl_y, 2, 2, leg_col)
	px.call(20, rl_y, 1, 2, leg_sh)
	px.call(18, rl_y + 2, 3, 4, sock_c)
	if casual_style == 0:
		px.call(18, rl_y + 2, 3, 1, secondary_color)
	px.call(17, rl_y + 5, 6, 3, blk)
	px.call(18, rl_y + 6, 4, 2, boot_color)
	px.call(18, rl_y + 6, 2, 1, boot_color.lightened(0.32))
	px.call(18, rl_y + 7, 4, 1, boot_color.darkened(0.24))
