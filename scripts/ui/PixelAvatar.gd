class_name PixelAvatar
extends Control

# High-craft 32x48 pixel-art character renderer supporting sculpted head/ears,
# 16 hairstyles, 8 beard styles, face/arm/leg tattoos, casual & gala outfits,
# portrait vs full-body framing, and built-in procedural animation states.

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
var show_mvp_trophy: bool = false

# Procedural animation state: "NONE", "IDLE", "TALK", "CHEER", "MVP", "SING", "SIGN", "RUN"
var anim_mode: String = "NONE"
var anim_phase: float = 0.0
var _anim_t: float = 0.0

const SKINS := [Color("#F6D4B8"), Color("#E6BA94"), Color("#C98F62"), Color("#A86E44"), Color("#8A5434"), Color("#5C3723")]
const HAIRS := [Color("#1A1718"), Color("#5C3824"), Color("#8A542E"), Color("#D4A842"), Color("#9A3826"), Color("#A0A4AE"), Color("#E8EAEF"), Color("#2E7AE6"), Color("#D43038"), Color("#D84A90")]

func _ready() -> void:
	_anim_t = anim_phase

func _process(delta: float) -> void:
	if anim_mode == "NONE" or not visible:
		return
	_anim_t += delta
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
	shorts_color = secondary_color if primary_color.get_luminance() < 0.7 else Color("#1A2232")
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
	shorts_color = secondary_color if primary_color.get_luminance() < 0.7 else Color("#1A2232")
	kit_pattern = str(club.get("pattern", "stripes"))
	skin_idx = abs(seed_val) % SKINS.size()
	hair_style = abs(seed_val / 3) % CharacterStyleCatalog.HAIR_STYLES.size()
	hair_idx = abs(seed_val / 7) % 6
	tip_color_idx = 0
	beard_style = abs(seed_val / 5) % 4 if (abs(seed_val) % 4) == 0 else 0
	beard = (beard_style > 0)
	long_sleeve = (abs(seed_val) % 4) == 0
	boot_color = Color("#20242C")
	glove_color = Color.TRANSPARENT
	wrist_side = "TAK ADA"
	tattoo_face = 0
	tattoo_arm = 1 if (abs(seed_val) % 7) == 0 else 0
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
		ps = 1.0
	var ox := floorf((size.x - grid_w * ps) * 0.5)
	var oy := floorf((size.y - grid_h * ps) * 0.5)

	# Compute animation offsets
	var t := _anim_t
	var bob_y: int = 0
	var head_y_off: int = 0
	var l_arm_lift: int = 0
	var r_arm_lift: int = 0
	var arm_spread: int = 0
	var leg_step: int = 0
	var mouth_open: int = 0  # 0=closed, 1=talk, 2=wide cheer/sing
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
			l_arm_lift = -4 + int(round(sin(t * 4.2) * 1.0))
			r_arm_lift = -4 - int(round(sin(t * 4.2) * 1.0))
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

	var blk := Color("#0F1218")
	var skin: Color = SKINS[clampi(skin_idx, 0, SKINS.size() - 1)]
	var skin_sh: Color = skin.darkened(0.15)
	var skin_hi: Color = skin.lightened(0.12)
	var hair: Color = HAIRS[clampi(hair_idx, 0, HAIRS.size() - 1)]
	var hair_hi: Color = hair.lightened(0.24)
	var hair_dk: Color = hair.darkened(0.24)
	var tip_info: Dictionary = CharacterStyleCatalog.TIP_COLORS[clampi(tip_color_idx, 0, CharacterStyleCatalog.TIP_COLORS.size() - 1)]
	var tip_col: Color = tip_info["col"]

	var px := func(x: int, y: int, w: int, h: int, col: Color):
		draw_rect(Rect2(ox + float(x) * ps, oy + float(y) * ps, float(w) * ps, float(h) * ps), col)

	if full_body:
		# Elliptical Ground Shadow
		draw_circle(Vector2(ox + 16.0 * ps, oy + 46.5 * ps), 7.6 * ps, Color(0, 0, 0, 0.30))

	var hy := head_y_off + (1 if bob_y > 0 else bob_y)
	var by := bob_y

	# -------------------------------------------------------------------------
	# 1. CONTOURED HEAD, EARS, NECK & JAWLINE (y = 2..20)
	# -------------------------------------------------------------------------
	# Neck + chin shadow
	px.call(13, 17 + hy, 6, 4, blk)
	px.call(14, 17 + hy, 4, 3, skin_sh)

	# Ears (sticking out symmetrically)
	px.call(9, 10 + hy, 2, 4, blk)
	px.call(10, 11 + hy, 1, 2, skin_sh)
	px.call(21, 10 + hy, 2, 4, blk)
	px.call(21, 11 + hy, 1, 2, skin_sh)

	# Contoured Rounded Head Silhouette
	px.call(10, 4 + hy, 12, 12, blk)
	px.call(11, 16 + hy, 10, 1, blk)
	px.call(12, 17 + hy, 8, 1, blk)
	# Inner Skin Fill
	px.call(11, 5 + hy, 10, 10, skin)
	px.call(12, 15 + hy, 8, 2, skin)
	# Forehead highlight & jawline/right cheek contour shading
	px.call(12, 6 + hy, 6, 1, skin_hi)
	px.call(19, 6 + hy, 2, 9, skin_sh)
	px.call(12, 16 + hy, 8, 1, skin_sh)

	# Face Expressive Features
	if blink:
		px.call(12, 11 + hy, 2, 1, blk)
		px.call(18, 11 + hy, 2, 1, blk)
	else:
		# Sclera white + deep pupil/iris
		px.call(12, 10 + hy, 1, 2, Color("#F4F7FC"))
		px.call(13, 10 + hy, 1, 2, Color("#182B4A"))
		px.call(19, 10 + hy, 1, 2, Color("#F4F7FC"))
		px.call(18, 10 + hy, 1, 2, Color("#182B4A"))
	# Eyebrows
	px.call(12, 9 + hy, 3, 1, hair_dk)
	px.call(17, 9 + hy, 3, 1, hair_dk)
	# Sculpted Nose & Nostril shadow
	px.call(15, 11 + hy, 2, 2, skin_sh)
	px.call(15, 13 + hy, 2, 1, skin.darkened(0.26))
	# Animated Mouth
	if mouth_open >= 2:
		px.call(14, 14 + hy, 4, 2, Color("#7A2024"))
		px.call(15, 14 + hy, 2, 1, Color("#F4F4F4"))
	elif mouth_open == 1:
		px.call(14, 15 + hy, 4, 1, Color("#883034"))
	else:
		px.call(15, 15 + hy, 2, 1, Color("#9E5448"))

	# -------------------------------------------------------------------------
	# 2. FACE TATTOOS & BEARD STYLES (8 designs)
	# -------------------------------------------------------------------------
	match clampi(tattoo_face, 0, 5):
		1:
			px.call(12, 13 + hy, 1, 1, Color("#202D3A"))
		2:
			px.call(12, 13 + hy, 1, 1, Color("#202D3A"))
			px.call(19, 13 + hy, 1, 1, Color("#202D3A"))
		3:
			px.call(12, 12 + hy, 1, 2, Color("#1F354D"))
		4:
			px.call(19, 9 + hy, 1, 4, Color("#6A2C2C"))
		5:
			px.call(14, 18 + hy, 4, 2, Color("#1A2634"))

	var eff_beard := beard_style if beard_style > 0 else (1 if beard else 0)
	match clampi(eff_beard, 0, 7):
		1: # 3 Hari Tipis (stubble)
			px.call(11, 14 + hy, 10, 2, Color(hair.r, hair.g, hair.b, 0.55))
			px.call(13, 16 + hy, 6, 1, Color(hair.r, hair.g, hair.b, 0.6))
		2: # Dipangkas (Trimmed full)
			px.call(11, 13 + hy, 1, 3, hair)
			px.call(20, 13 + hy, 1, 3, hair)
			px.call(12, 15 + hy, 8, 2, hair)
			px.call(14, 14 + hy, 4, 1, hair)
		3: # Penuh Tebal (Heavy lumberjack)
			px.call(11, 12 + hy, 2, 4, hair)
			px.call(19, 12 + hy, 2, 4, hair)
			px.call(12, 14 + hy, 8, 4, hair)
			px.call(13, 17 + hy, 6, 1, hair_dk)
		4: # Soul Patch
			px.call(15, 16 + hy, 2, 1, hair)
		5: # Kambing (Goatee)
			px.call(14, 14 + hy, 4, 1, hair)
			px.call(14, 16 + hy, 4, 2, hair)
		6: # Kumis Tebal (Handlebar)
			px.call(13, 14 + hy, 6, 1, hair)
			px.call(12, 15 + hy, 2, 1, hair_dk)
			px.call(18, 15 + hy, 2, 1, hair_dk)
		7: # Cambang Wolverine
			px.call(11, 11 + hy, 2, 5, hair)
			px.call(19, 11 + hy, 2, 5, hair)

	# -------------------------------------------------------------------------
	# 3. 16 SCULPTED HAIRSTYLES WITH TEXTURE CLUSTERS & TIPS
	# -------------------------------------------------------------------------
	var hs := clampi(hair_style, 0, CharacterStyleCatalog.HAIR_STYLES.size() - 1)
	var tip_eff: Color = tip_col if tip_col.a > 0.1 else hair_hi
	match hs:
		0: # BOTAK (smooth scalp glint)
			px.call(13, 5 + hy, 3, 1, skin_hi)
		1: # KLASIK RAPI
			px.call(10, 3 + hy, 12, 4, blk)
			px.call(11, 4 + hy, 10, 3, hair)
			px.call(11, 7 + hy, 1, 3, hair)
			px.call(20, 7 + hy, 1, 3, hair)
			px.call(12, 4 + hy, 5, 1, tip_eff)
		2: # KERITING IKAL (Signature fluffy Alfian curls)
			px.call(9, 2 + hy, 14, 5, blk)
			px.call(10, 3 + hy, 12, 4, hair)
			px.call(11, 2 + hy, 3, 2, hair_hi)
			px.call(16, 2 + hy, 4, 2, tip_eff)
			px.call(12, 5 + hy, 3, 1, hair_dk)
			px.call(17, 5 + hy, 2, 1, hair_dk)
			px.call(10, 7 + hy, 1, 3, hair)
			px.call(21, 7 + hy, 1, 3, hair)
		3: # AFRO BULAT
			px.call(8, 1 + hy, 16, 7, blk)
			px.call(9, 2 + hy, 14, 6, hair)
			px.call(8, 6 + hy, 2, 4, hair)
			px.call(22, 6 + hy, 2, 4, hair)
			px.call(11, 3 + hy, 6, 2, tip_eff)
			px.call(14, 5 + hy, 4, 1, hair_dk)
		4: # MOHAWK PUNK
			px.call(13, 0 + hy, 6, 6, blk)
			px.call(14, 1 + hy, 4, 5, hair)
			px.call(15, 0 + hy, 2, 2, tip_eff)
			px.call(11, 5 + hy, 3, 1, skin_sh)
			px.call(18, 5 + hy, 3, 1, skin_sh)
		5: # HI-TOP FADE
			px.call(10, 1 + hy, 12, 5, blk)
			px.call(11, 2 + hy, 10, 4, hair)
			px.call(12, 2 + hy, 8, 1, tip_eff)
		6: # CURTAIN PENDEK (Center-part K-pop bangs)
			px.call(10, 2 + hy, 12, 5, blk)
			px.call(11, 3 + hy, 10, 3, hair)
			px.call(10, 6 + hy, 4, 3, hair)
			px.call(18, 6 + hy, 4, 3, hair)
			px.call(15, 6 + hy, 2, 2, skin)
			px.call(11, 4 + hy, 4, 1, tip_eff)
			px.call(18, 4 + hy, 3, 1, tip_eff)
		7: # SPIKY FADE
			px.call(10, 2 + hy, 12, 4, blk)
			px.call(11, 3 + hy, 10, 3, hair)
			px.call(12, 1 + hy, 2, 2, tip_eff)
			px.call(15, 1 + hy, 2, 2, hair)
			px.call(18, 1 + hy, 2, 2, tip_eff)
		8: # QUIFF RENDAH
			px.call(10, 2 + hy, 12, 4, blk)
			px.call(12, 1 + hy, 9, 4, hair)
			px.call(14, 1 + hy, 6, 2, tip_eff)
		9: # EDGAR CROP (Sharp straight fringe)
			px.call(10, 2 + hy, 12, 6, blk)
			px.call(11, 3 + hy, 10, 5, hair)
			px.call(12, 4 + hy, 8, 1, tip_eff)
		10: # GONDRONG (Shoulder-length locks)
			px.call(9, 2 + hy, 14, 5, blk)
			px.call(8, 6 + hy, 3, 11, blk)
			px.call(21, 6 + hy, 3, 11, blk)
			px.call(10, 3 + hy, 12, 3, hair)
			px.call(9, 6 + hy, 2, 10, hair)
			px.call(21, 6 + hy, 2, 10, hair)
			px.call(12, 3 + hy, 6, 1, tip_eff)
		11: # DREADLOCK PENDEK
			px.call(9, 2 + hy, 14, 5, blk)
			for dx in [9, 12, 15, 18, 21]:
				px.call(dx, 3 + hy, 2, 6, hair)
				px.call(dx, 8 + hy, 2, 1, tip_eff)
		12: # TWIST KERITING
			px.call(10, 2 + hy, 12, 4, blk)
			for tx in [11, 14, 17, 20]:
				px.call(tx, 1 + hy, 2, 4, hair)
				px.call(tx, 1 + hy, 1, 1, tip_eff)
		13: # CORNROW SISI
			px.call(10, 3 + hy, 12, 3, hair_dk)
			for rx in [11, 15, 19]:
				px.call(rx, 3 + hy, 2, 3, hair)
				px.call(rx + 1, 3 + hy, 1, 3, tip_eff)
		14: # MANGKUK UNDERCUT
			px.call(9, 2 + hy, 14, 5, blk)
			px.call(10, 3 + hy, 12, 4, hair)
			px.call(10, 7 + hy, 12, 1, hair_dk)
			px.call(12, 4 + hy, 7, 1, tip_eff)
		15: # BUZZ CUT
			px.call(11, 4 + hy, 10, 2, hair)
			px.call(13, 4 + hy, 5, 1, tip_eff)

	# -------------------------------------------------------------------------
	# 4. EYEWEAR & HEADWEAR
	# -------------------------------------------------------------------------
	match clampi(eyewear, 0, 3):
		1: # Gold Aviator/VIP
			px.call(11, 9 + hy, 10, 3, Color("#12161E"))
			px.call(12, 10 + hy, 3, 2, Color("#EA9228"))
			px.call(17, 10 + hy, 3, 2, Color("#EA9228"))
			px.call(15, 10 + hy, 2, 1, Color("#D4A842"))
		2: # Cool Dark Shades
			px.call(11, 9 + hy, 10, 3, Color("#0A0D12"))
			px.call(12, 10 + hy, 1, 1, Color("#94A3B8"))
			px.call(17, 10 + hy, 1, 1, Color("#94A3B8"))
		3: # Sport Neon Visor
			px.call(11, 9 + hy, 10, 3, Color("#0E2942"))
			px.call(12, 10 + hy, 8, 2, Color("#38BDF8"))

	match clampi(headwear, 0, 4):
		1: # Topi Bisbol
			px.call(9, 2 + hy, 14, 4, Color("#1B2A40"))
			px.call(11, 3 + hy, 10, 2, Color("#2E5280"))
			px.call(8, 5 + hy, 16, 1, Color("#101824"))
		2: # Kupluk Beanie
			px.call(10, 1 + hy, 12, 5, Color("#88222A"))
			px.call(10, 4 + hy, 12, 2, Color("#B8323E"))
		3: # Ikat Kepala Sport
			px.call(10, 6 + hy, 12, 2, Color("#F0F4F8"))
			px.call(15, 6 + hy, 2, 1, primary_color)
		4: # Durag Sutra
			px.call(10, 2 + hy, 12, 5, Color("#1E2430"))
			px.call(21, 5 + hy, 2, 7, Color("#283448"))

	# -------------------------------------------------------------------------
	# 5. ATHLETIC TORSO, OUTFITS & BADGES (y = 19..33)
	# -------------------------------------------------------------------------
	# Sloped shoulders + chest
	px.call(8, 19 + by, 16, 14, blk)
	if casual_style == 2:
		# 5 Gala Suits!
		var suit_pal := [
			[Color("#191E28"), Color("#EBF1F6"), Color("#B42432")], # Tuxedo
			[Color("#1A355B"), Color("#EBF1F6"), Color("#D4A842")], # Jas Biru
			[Color("#681A28"), Color("#181C24"), Color("#D4A842")], # Beludru Merah
			[Color("#D8D2C2"), Color("#FFFFFF"), Color("#B89436")], # Gading Emas
			[Color("#242B36"), Color("#D8E2EE"), Color("#2E6CA8")], # Diplomat
		]
		var pal: Array = suit_pal[clampi(outfit_variant, 0, suit_pal.size() - 1)]
		px.call(9, 20 + by, 14, 12, pal[0])
		px.call(13, 20 + by, 6, 10, pal[1])
		px.call(15, 20 + by, 2, 8, pal[2])
		px.call(10, 20 + by, 2, 12, (pal[0] as Color).lightened(0.08))
		px.call(20, 20 + by, 2, 12, (pal[0] as Color).darkened(0.18))
	elif casual_style == 1:
		# 5 Casual Streetwear Outfits!
		match clampi(outfit_variant, 0, 4):
			0: # Kaus Polos
				px.call(9, 20 + by, 14, 12, Color("#ECEEE8"))
				px.call(14, 20 + by, 4, 2, Color("#D0D6DE"))
			1: # Kaus Motif
				px.call(9, 20 + by, 14, 12, Color("#223042"))
				px.call(9, 24 + by, 14, 3, Color("#EA7E22"))
				px.call(14, 22 + by, 4, 2, Color("#F8FAFC"))
			2: # Jaket Buka
				px.call(9, 20 + by, 14, 12, Color("#ECEEE8"))
				px.call(9, 20 + by, 4, 12, Color("#8E2832"))
				px.call(19, 20 + by, 4, 12, Color("#8E2832"))
			3: # Jaket Tutup
				px.call(9, 20 + by, 14, 12, Color("#243A5E"))
				px.call(15, 20 + by, 2, 12, Color("#94A3B8"))
			4: # Hoodie Kota
				px.call(9, 20 + by, 14, 12, Color("#2E3848"))
				px.call(12, 27 + by, 8, 4, Color("#1F2632"))
				px.call(14, 21 + by, 1, 4, Color("#E2E8F0"))
				px.call(17, 21 + by, 1, 4, Color("#E2E8F0"))
	else:
		# Football Club Kit with Pattern + Chest Crest + Collar V-neck + Shading!
		px.call(9, 20 + by, 14, 12, primary_color)
		if kit_pattern == "stripes":
			px.call(11, 20 + by, 3, 12, secondary_color)
			px.call(18, 20 + by, 3, 12, secondary_color)
		elif kit_pattern == "hoops":
			px.call(9, 23 + by, 14, 3, secondary_color)
			px.call(9, 28 + by, 14, 3, secondary_color)
		elif kit_pattern == "sash":
			for k in range(11):
				px.call(9 + k, 20 + k + by, 3, 2, secondary_color)
		elif kit_pattern == "halved":
			px.call(16, 20 + by, 7, 12, secondary_color)
		# Crisp V-neck Collar + Side Shadows
		px.call(13, 20 + by, 6, 2, secondary_color)
		px.call(14, 20 + by, 4, 1, skin_sh)
		px.call(9, 20 + by, 2, 12, Color(1, 1, 1, 0.08))
		px.call(21, 20 + by, 2, 12, Color(0, 0, 0, 0.16))
		# Mini Club Crest on right breast (screen right)
		px.call(19, 22 + by, 2, 2, Color.WHITE)
		px.call(19, 22 + by, 1, 1, secondary_color)

	if show_number_badge and casual_style == 0:
		var num_col: Color = blk if primary_color.get_luminance() > 0.6 else Color.WHITE
		px.call(13, 24 + by, 6, 5, Color(primary_color.r, primary_color.g, primary_color.b, 0.78))
		draw_string(UITheme.get_display_font(), Vector2(ox + 12.6 * ps, oy + float(28 + by) * ps), str(shirt_num), HORIZONTAL_ALIGNMENT_CENTER, 7.0 * ps, maxf(8.0, ps * 3.8), num_col)

	# -------------------------------------------------------------------------
	# 6. ARMS, SLEEVES, TATTOOS, WRISTBANDS, GLOVES & MVP TROPHY
	# -------------------------------------------------------------------------
	var sl_h := 10 if (long_sleeve or casual_style == 2 or (casual_style == 1 and outfit_variant >= 2)) else 5
	var sleeve_col := primary_color
	if casual_style == 2:
		sleeve_col = [Color("#191E28"), Color("#1A355B"), Color("#681A28"), Color("#D8D2C2"), Color("#242B36")][clampi(outfit_variant, 0, 4)]
	elif casual_style == 1:
		sleeve_col = [Color("#ECEEE8"), Color("#223042"), Color("#8E2832"), Color("#243A5E"), Color("#2E3848")][clampi(outfit_variant, 0, 4)]

	# Left Arm (screen left)
	var lax := 4 - arm_spread
	var lay := 20 + by + l_arm_lift
	px.call(lax, lay, 4, 12, blk)
	px.call(lax + 1, lay + 1, 2, 10, skin)
	px.call(lax + 1, lay + 1, 2, sl_h, sleeve_col)
	# Right Arm (screen right)
	var rax := 24 + arm_spread
	var ray := 20 + by + r_arm_lift
	px.call(rax, ray, 4, 12, blk)
	px.call(rax + 1, ray + 1, 2, 10, skin)
	px.call(rax + 1, ray + 1, 2, sl_h, sleeve_col)

	# Arm Tattoos (if sleeves don't cover them)
	if tattoo_arm > 0 and sl_h <= 6:
		var tat_c := Color("#1E2C3B")
		for ty in range(6, 10):
			if tattoo_arm >= 1: # Right arm checkerboard / tribal
				px.call(rax + 1 + ((ty + tattoo_arm) % 2), ray + ty, 1, 1, tat_c)
			if tattoo_arm >= 2: # Both arms
				px.call(lax + 1 + (ty % 2), lay + ty, 1, 1, tat_c)
			if tattoo_arm >= 3: # Heavy tribal band
				px.call(rax + 1, ray + ty, 2, 1, Color("#15202B"))
			if tattoo_arm >= 4: # Full dark sleeve
				px.call(lax + 1, lay + ty, 2, 1, Color("#15202B"))

	# Wristbands
	if wrist_side == "LENGAN KIRI" or wrist_side == "KEDUANYA":
		px.call(lax + 1, lay + 8, 2, 2, wrist_color)
	if wrist_side == "LENGAN KANAN" or wrist_side == "KEDUANYA":
		px.call(rax + 1, ray + 8, 2, 2, wrist_color)

	# Gloves
	if glove_color.a > 0.1:
		px.call(lax + 1, lay + 9, 2, 2, glove_color)
		px.call(rax + 1, ray + 9, 2, 2, glove_color)

	# Golden MVP Trophy & Animated Confetti Stars when show_mvp_trophy or MVP anim
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
	# 7. SHORTS / PANTS, LEGS, SOCK CUFFS & CLEATS (y = 32..46)
	# -------------------------------------------------------------------------
	var sh_col := shorts_color
	if casual_style == 2:
		sh_col = Color("#181C24")
	elif casual_style == 1:
		sh_col = Color("#2C3D55")

	px.call(9, 32 + by, 14, 5, blk)
	px.call(10, 32 + by, 12, 4, sh_col)
	px.call(10, 32 + by, 12, 1, sh_col.darkened(0.18))
	px.call(15, 34 + by, 2, 3, blk)
	if casual_style == 0:
		px.call(18, 34 + by, 2, 1, secondary_color)

	var leg_col := skin if tattoo_leg == 0 else Color("#A48A78")
	var sock_c := sh_col if casual_style > 0 else primary_color

	var ll_y := 37 + by + (0 if leg_step <= 0 else -1)
	var rl_y := 37 + by + (0 if leg_step >= 0 else -1)

	# Left Leg
	px.call(10, ll_y, 5, 7, blk)
	px.call(11, ll_y, 3, 3, leg_col)
	px.call(11, ll_y + 3, 3, 3, sock_c)
	if casual_style == 0:
		px.call(11, ll_y + 3, 3, 1, secondary_color)
	px.call(9, ll_y + 6, 6, 3, blk)
	px.call(10, ll_y + 7, 4, 2, boot_color)
	px.call(10, ll_y + 7, 2, 1, boot_color.lightened(0.3))

	# Right Leg
	px.call(17, rl_y, 5, 7, blk)
	px.call(18, rl_y, 3, 3, leg_col)
	px.call(18, rl_y + 3, 3, 3, sock_c)
	if casual_style == 0:
		px.call(18, rl_y + 3, 3, 1, secondary_color)
	px.call(17, rl_y + 6, 6, 3, blk)
	px.call(18, rl_y + 7, 4, 2, boot_color)
	px.call(18, rl_y + 7, 2, 1, boot_color.lightened(0.3))
