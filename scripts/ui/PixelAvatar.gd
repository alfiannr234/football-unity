class_name PixelAvatar
extends Control

# Sculpted 34x56 human-proportioned 16-bit pixel-art footballer renderer:
# Athletic adult proportions (1:4.2 head-to-body ratio), tapered jawline, ears, neck,
# sloped shoulders, fitted club jersey with collar/crest/sponsor detail, detached natural arms,
# sleeve tattoos, tailored shorts, muscular knees/calves, tall striped socks, cleats,
# 16 hairstyles, 8 beard styles, 8 jersey patterns, casual/gala outfits, and procedural anims.

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
var show_sponsor_motif: bool = true

# Procedural animation state: "NONE", "IDLE", "INTERVIEW", "TALK", "CHEER", "MVP", "SING", "SIGN", "RUN"
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
	primary_color = UITheme.parse_color(kit.get("primary", primary_color), primary_color)
	secondary_color = UITheme.parse_color(kit.get("secondary", secondary_color), secondary_color)
	shorts_color = UITheme.parse_color(kit.get("shorts", secondary_color if primary_color.get_luminance() < 0.68 else Color("#18202E")), Color("#F4F8FF"))
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
	primary_color = UITheme.parse_color(club.get("primary", Color("#1A66D2")), Color("#1A66D2"))
	secondary_color = UITheme.parse_color(club.get("secondary", Color("#F4F8FF")), Color("#F4F8FF"))
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
	primary_color = UITheme.parse_color(club.get("primary", Color("#1A66D2")), Color("#1A66D2"))
	secondary_color = UITheme.parse_color(club.get("secondary", Color("#F4F8FF")), Color("#F4F8FF"))
	shorts_color = UITheme.parse_color(club.get("shorts", secondary_color if primary_color.get_luminance() < 0.68 else Color("#18202E")), Color("#F4F8FF"))
	kit_pattern = str(club.get("pattern", "stripes"))
	skin_idx = absi(seed_val) % SKINS.size()
	hair_style = absi(seed_val / 3) % CharacterStyleCatalog.HAIR_STYLES.size()
	hair_idx = absi(seed_val / 7) % 6
	tip_color_idx = 0
	beard_style = absi(seed_val / 5) % 4 if (absi(seed_val) % 4) == 0 else 0
	beard = (beard_style > 0)
	long_sleeve = (absi(seed_val) % 4) == 0
	var ai_boots := [Color("#1D2430"), Color("#E2E8F0"), Color("#DC2626"), Color("#22C55E"), Color("#EAB308"), Color("#2563EB")]
	boot_color = ai_boots[absi(seed_val / 2) % ai_boots.size()]
	glove_color = Color.TRANSPARENT
	wrist_side = "TAK ADA"
	tattoo_face = 0
	tattoo_arm = 1 if (absi(seed_val) % 5) == 0 else 0
	tattoo_leg = 0
	headwear = 0
	eyewear = 0
	casual_style = 0
	outfit_variant = 0
	shirt_num = num
	queue_redraw()

func configure_random_npc(seed_val: int, club: Dictionary, is_gk: bool = false) -> void:
	configure_from_seed(seed_val, club, 1 if is_gk else (2 + (absi(seed_val) % 21)))
	if is_gk:
		glove_color = Color("#F5C542")
		long_sleeve = true
		queue_redraw()

func _draw() -> void:
	var grid_w: float = 34.0
	var grid_h: float = 56.0 if full_body else 33.0
	var raw_ps: float = minf(size.x / grid_w, size.y / grid_h)
	var ps: float = floorf(raw_ps) if raw_ps >= 3.0 else (floorf(raw_ps * 2.0) * 0.5 if raw_ps >= 1.25 else maxf(0.5, raw_ps))
	var ox: float = floorf((size.x - grid_w * ps) * 0.5)
	var oy: float = floorf((size.y - grid_h * ps) * 0.5)

	var t: float = _anim_t
	var bob_y: int = 0
	var head_y_off: int = 0
	var l_arm_lift: int = 0
	var r_arm_lift: int = 0
	var arm_spread: int = 0
	var leg_step: int = 0
	var mouth_open: int = 0
	var blink: bool = false

	match anim_mode:
		"IDLE":
			bob_y = 1 if sin(t * 2.4) > 0.55 else 0
			blink = fmod(t, 3.8) > 3.64
		"INTERVIEW":
			# Calm, lifelike pitch-side interview stance: gentle breath, natural blink, periodic speech
			bob_y = 1 if sin(t * 2.1) > 0.62 else 0
			head_y_off = 1 if sin(t * 1.45) > 0.72 else 0
			blink = fmod(t, 3.9) > 3.74
			var speak_burst: bool = fmod(t, 4.2) < 2.1
			mouth_open = 1 if (speak_burst and sin(t * 11.5) > 0.15) else 0
		"TALK":
			bob_y = 1 if sin(t * 3.8) > 0.45 else 0
			blink = fmod(t, 4.1) > 3.95
			mouth_open = 1 if sin(t * 10.5) > 0.1 else 0
			r_arm_lift = -2 if sin(t * 4.4) > 0.35 else 0
		"CHEER", "MVP":
			var hop: float = absf(sin(t * 6.0))
			bob_y = -2 if hop > 0.6 else (-1 if hop > 0.25 else 0)
			head_y_off = -1 if hop > 0.72 else 0
			l_arm_lift = -8 if sin(t * 6.0) > -0.55 else -5
			r_arm_lift = -8 if cos(t * 6.0) > -0.55 else -5
			arm_spread = 1
			mouth_open = 2
		"SING":
			bob_y = 1 if sin(t * 4.0) > 0.35 else 0
			l_arm_lift = -5 + int(round(sin(t * 4.0)))
			r_arm_lift = -5 - int(round(sin(t * 4.0)))
			arm_spread = 1
			mouth_open = 2 if sin(t * 8.5) > -0.2 else 1
		"SIGN":
			bob_y = 1 if sin(t * 3.2) > 0.55 else 0
			r_arm_lift = 1 if sin(t * 8.5) > 0.0 else -1
			mouth_open = 1 if sin(t * 3.8) > 0.65 else 0
		"RUN":
			var ph: float = sin(t * 10.0)
			bob_y = -1 if absf(ph) > 0.65 else 0
			leg_step = 1 if ph > 0.2 else (-1 if ph < -0.2 else 0)
			l_arm_lift = -2 if ph > 0.2 else 1
			r_arm_lift = -2 if ph < -0.2 else 1

	var blk := Color("#0C0F16")
	var skin: Color = SKINS[clampi(skin_idx, 0, SKINS.size() - 1)]
	var skin_sh: Color = skin.darkened(0.16)
	var skin_dk: Color = skin.darkened(0.28)
	var skin_hi: Color = skin.lightened(0.13)
	var cheek: Color = skin.lerp(Color("#D96B62"), 0.16)
	var hair: Color = HAIRS[clampi(hair_idx, 0, HAIRS.size() - 1)]
	var hair_hi: Color = hair.lightened(0.24)
	var hair_dk: Color = hair.darkened(0.32)
	var tip_info: Dictionary = CharacterStyleCatalog.TIP_COLORS[clampi(tip_color_idx, 0, CharacterStyleCatalog.TIP_COLORS.size() - 1)]
	var tip_col: Color = tip_info["col"]

	var px := func(x: int, y: int, w: int, h: int, col: Color):
		draw_rect(Rect2(ox + float(x) * ps, oy + float(y) * ps, float(w) * ps, float(h) * ps), col)

	if full_body:
		# Soft grounded shadow ellipse beneath cleats
		px.call(8, 53, 18, 2, Color(0, 0, 0, 0.30))
		px.call(10, 52, 14, 4, Color(0, 0, 0, 0.20))

	var hy: int = head_y_off + (1 if bob_y > 0 else bob_y)
	var by: int = bob_y

	# =========================================================================
	# 1. SCULPTED HUMAN HEAD, EARS, TAPERED JAWLINE & NECK (x center = 17, y=3..19)
	# =========================================================================
	# Athletic Neck + Chin Shadow (flows smoothly into jersey collar)
	px.call(14, 15 + hy, 6, 4, blk)
	px.call(15, 16 + hy, 4, 4, skin_sh)
	px.call(15, 16 + hy, 4, 1, skin_dk)
	px.call(16, 17 + hy, 2, 3, skin)

	# Contoured Ears (tucked cleanly at temples)
	px.call(10, 9 + hy, 2, 4, blk)
	px.call(11, 10 + hy, 1, 2, skin)
	px.call(11, 11 + hy, 1, 1, skin_sh)
	px.call(22, 9 + hy, 2, 4, blk)
	px.call(22, 10 + hy, 1, 2, skin_sh)
	px.call(22, 11 + hy, 1, 1, skin_dk)

	# Tapered Human Oval Head Silhouette (narrower athletic cranium + sculpted chin!)
	px.call(13, 3 + hy, 8, 1, blk)
	px.call(12, 4 + hy, 10, 1, blk)
	px.call(11, 5 + hy, 12, 9, blk)
	px.call(12, 14 + hy, 10, 1, blk)
	px.call(13, 15 + hy, 8, 1, blk)
	px.call(14, 16 + hy, 6, 1, blk)
	# Base Skin Fill
	px.call(13, 4 + hy, 8, 1, skin)
	px.call(12, 5 + hy, 10, 9, skin)
	px.call(13, 14 + hy, 8, 1, skin)
	px.call(14, 15 + hy, 6, 1, skin_sh)
	# Facial Plane Modeling (forehead light, cheek shadow, jawline contour)
	px.call(13, 5 + hy, 5, 1, skin_hi)
	px.call(12, 6 + hy, 1, 7, skin_hi)
	px.call(20, 6 + hy, 2, 7, skin_sh)
	px.call(19, 13 + hy, 2, 1, skin_sh)
	px.call(13, 12 + hy, 2, 1, cheek)
	px.call(19, 12 + hy, 2, 1, cheek)

	# Expressive Human Eyes & Natural Eyebrows (balanced human spacing!)
	if blink:
		px.call(13, 10 + hy, 3, 1, blk)
		px.call(18, 10 + hy, 3, 1, blk)
	else:
		# Left eye (white sclera + dark iris)
		px.call(13, 9 + hy, 3, 2, Color("#F4F7FC"))
		px.call(14, 9 + hy, 1, 2, Color("#152036"))
		px.call(13, 11 + hy, 3, 1, skin_sh)
		# Right eye (white sclera + dark iris)
		px.call(18, 9 + hy, 3, 2, Color("#F4F7FC"))
		px.call(19, 9 + hy, 1, 2, Color("#152036"))
		px.call(18, 11 + hy, 3, 1, skin_sh)
	# Contoured Brows
	px.call(13, 8 + hy, 3, 1, hair_dk)
	px.call(18, 8 + hy, 3, 1, hair_dk)
	# Subtle Sculpted Nose
	px.call(16, 10 + hy, 2, 2, skin_sh)
	px.call(16, 12 + hy, 2, 1, skin_dk)
	# Natural Expressive Mouth
	if mouth_open >= 2:
		px.call(14, 13 + hy, 6, 2, Color("#6A1D24"))
		px.call(15, 13 + hy, 4, 1, Color("#F8FAFC"))
	elif mouth_open == 1:
		px.call(15, 13 + hy, 4, 2, Color("#7A2B31"))
		px.call(16, 13 + hy, 2, 1, Color("#E8DCE0"))
	else:
		px.call(15, 13 + hy, 4, 1, Color("#96574C"))
		px.call(16, 14 + hy, 2, 1, skin_sh)

	# =========================================================================
	# 2. FACE TATTOOS & 8 SCULPTED BEARD STYLES
	# =========================================================================
	match clampi(tattoo_face, 0, 5):
		1: px.call(13, 12 + hy, 1, 1, Color("#202D3A"))
		2:
			px.call(13, 12 + hy, 1, 1, Color("#202D3A"))
			px.call(20, 12 + hy, 1, 1, Color("#202D3A"))
		3: px.call(13, 11 + hy, 1, 2, Color("#1F354D"))
		4: px.call(20, 8 + hy, 1, 4, Color("#6A2C2C"))
		5: px.call(15, 16 + hy, 4, 2, Color("#1A2634"))

	var eff_beard: int = beard_style if beard_style > 0 else (1 if beard else 0)
	match clampi(eff_beard, 0, 7):
		1: # Stubble shadow
			px.call(12, 13 + hy, 10, 2, Color(hair.r, hair.g, hair.b, 0.48))
			px.call(14, 15 + hy, 6, 1, Color(hair.r, hair.g, hair.b, 0.56))
		2: # Trimmed full beard
			px.call(12, 12 + hy, 1, 2, hair)
			px.call(21, 12 + hy, 1, 2, hair)
			px.call(13, 14 + hy, 8, 2, hair)
			px.call(14, 15 + hy, 6, 1, hair_dk)
			px.call(15, 12 + hy, 4, 1, hair)
		3: # Thick athletic beard
			px.call(12, 11 + hy, 2, 3, hair)
			px.call(20, 11 + hy, 2, 3, hair)
			px.call(13, 13 + hy, 8, 3, hair)
			px.call(14, 15 + hy, 6, 2, hair_dk)
		4: # Soul patch
			px.call(16, 14 + hy, 2, 2, hair)
		5: # Goatee
			px.call(15, 12 + hy, 4, 1, hair)
			px.call(14, 14 + hy, 6, 2, hair)
		6: # Handlebar mustache
			px.call(14, 12 + hy, 6, 1, hair)
			px.call(13, 13 + hy, 2, 1, hair_dk)
			px.call(19, 13 + hy, 2, 1, hair_dk)
		7: # Sideburns
			px.call(12, 10 + hy, 1, 4, hair)
			px.call(21, 10 + hy, 1, 4, hair)

	# =========================================================================
	# 3. 16 TEXTURED LAYERED HAIRSTYLES (Sculpted Crown & Hairline)
	# =========================================================================
	var hs: int = clampi(hair_style, 0, CharacterStyleCatalog.HAIR_STYLES.size() - 1)
	var tip_eff: Color = tip_col if tip_col.a > 0.1 else hair_hi
	match hs:
		0: # BOTAK
			px.call(14, 4 + hy, 4, 1, skin_hi)
		1: # KLASIK RAPI
			px.call(12, 2 + hy, 10, 1, blk)
			px.call(11, 3 + hy, 12, 4, blk)
			px.call(12, 3 + hy, 10, 3, hair)
			px.call(12, 6 + hy, 10, 1, hair_dk)
			px.call(11, 6 + hy, 1, 3, hair)
			px.call(22, 6 + hy, 1, 3, hair)
			px.call(13, 3 + hy, 5, 1, tip_eff)
		2: # KERITING IKAL (Textured layered crop like Gambar 2!)
			px.call(12, 1 + hy, 10, 1, blk)
			px.call(10, 2 + hy, 14, 5, blk)
			px.call(11, 2 + hy, 12, 4, hair)
			px.call(12, 2 + hy, 3, 1, hair_hi)
			px.call(17, 2 + hy, 4, 1, tip_eff)
			px.call(13, 4 + hy, 2, 1, hair_dk)
			px.call(18, 4 + hy, 2, 1, hair_dk)
			px.call(12, 6 + hy, 3, 1, hair)
			px.call(17, 6 + hy, 4, 1, hair)
			px.call(11, 6 + hy, 1, 3, hair)
			px.call(22, 6 + hy, 1, 3, hair)
		3: # AFRO BULAT
			px.call(10, 0 + hy, 14, 1, blk)
			px.call(9, 1 + hy, 16, 7, blk)
			px.call(10, 1 + hy, 14, 6, hair)
			px.call(9, 5 + hy, 2, 4, hair)
			px.call(23, 5 + hy, 2, 4, hair)
			px.call(12, 2 + hy, 6, 2, tip_eff)
			px.call(15, 5 + hy, 4, 1, hair_dk)
		4: # MOHAWK PUNK
			px.call(14, 0 + hy, 6, 6, blk)
			px.call(15, 1 + hy, 4, 5, hair)
			px.call(16, 0 + hy, 2, 2, tip_eff)
			px.call(12, 5 + hy, 2, 1, skin_sh)
			px.call(20, 5 + hy, 2, 1, skin_sh)
		5: # HI-TOP FADE
			px.call(11, 1 + hy, 12, 5, blk)
			px.call(12, 2 + hy, 10, 4, hair)
			px.call(13, 2 + hy, 8, 1, tip_eff)
			px.call(12, 5 + hy, 10, 1, hair_dk)
		6: # CURTAIN PENDEK
			px.call(11, 2 + hy, 12, 4, blk)
			px.call(12, 3 + hy, 10, 3, hair)
			px.call(11, 6 + hy, 4, 2, hair)
			px.call(19, 6 + hy, 4, 2, hair)
			px.call(16, 6 + hy, 2, 1, skin)
			px.call(13, 3 + hy, 3, 1, tip_eff)
			px.call(19, 3 + hy, 2, 1, tip_eff)
		7: # SPIKY FADE
			px.call(11, 2 + hy, 12, 4, blk)
			px.call(12, 3 + hy, 10, 3, hair)
			px.call(12, 0 + hy, 2, 3, tip_eff)
			px.call(16, 0 + hy, 2, 3, hair)
			px.call(20, 0 + hy, 2, 3, tip_eff)
		8: # QUIFF RENDAH
			px.call(11, 2 + hy, 12, 4, blk)
			px.call(13, 1 + hy, 8, 4, hair)
			px.call(14, 1 + hy, 6, 2, tip_eff)
		9: # EDGAR CROP
			px.call(11, 2 + hy, 12, 5, blk)
			px.call(12, 3 + hy, 10, 4, hair)
			px.call(13, 4 + hy, 8, 1, tip_eff)
		10: # GONDRONG
			px.call(10, 2 + hy, 14, 4, blk)
			px.call(9, 5 + hy, 3, 12, blk)
			px.call(22, 5 + hy, 3, 12, blk)
			px.call(11, 3 + hy, 12, 3, hair)
			px.call(10, 5 + hy, 2, 11, hair)
			px.call(22, 5 + hy, 2, 11, hair)
			px.call(13, 3 + hy, 6, 1, tip_eff)
		11: # DREADLOCK PENDEK
			px.call(10, 2 + hy, 14, 4, blk)
			for dx in [10, 13, 16, 19, 22]:
				px.call(dx, 3 + hy, 2, 5, hair)
				px.call(dx, 7 + hy, 2, 1, tip_eff)
		12: # TWIST KERITING
			px.call(11, 2 + hy, 12, 4, blk)
			for tx in [12, 15, 18, 20]:
				px.call(tx, 1 + hy, 2, 4, hair)
				px.call(tx, 1 + hy, 1, 1, tip_eff)
		13: # CORNROW SISI
			px.call(11, 3 + hy, 12, 3, hair_dk)
			for rx in [12, 16, 20]:
				px.call(rx, 3 + hy, 2, 3, hair)
				px.call(rx + 1, 3 + hy, 1, 3, tip_eff)
		14: # MANGKUK UNDERCUT
			px.call(10, 2 + hy, 14, 5, blk)
			px.call(11, 3 + hy, 12, 3, hair)
			px.call(11, 6 + hy, 12, 1, hair_dk)
			px.call(13, 3 + hy, 7, 1, tip_eff)
		15: # BUZZ CUT
			px.call(12, 4 + hy, 10, 2, hair)
			px.call(14, 4 + hy, 5, 1, tip_eff)

	# =========================================================================
	# 4. EYEWEAR & HEADWEAR
	# =========================================================================
	match clampi(eyewear, 0, 3):
		1:
			px.call(12, 8 + hy, 10, 3, Color("#12161E"))
			px.call(13, 9 + hy, 3, 2, Color("#EA9228"))
			px.call(18, 9 + hy, 3, 2, Color("#EA9228"))
			px.call(16, 9 + hy, 2, 1, Color("#D4A842"))
		2:
			px.call(12, 8 + hy, 10, 3, Color("#0A0D12"))
			px.call(13, 9 + hy, 1, 1, Color("#94A3B8"))
			px.call(19, 9 + hy, 1, 1, Color("#94A3B8"))
		3:
			px.call(12, 8 + hy, 10, 3, Color("#0E2942"))
			px.call(13, 9 + hy, 8, 2, Color("#38BDF8"))

	match clampi(headwear, 0, 4):
		1:
			px.call(10, 2 + hy, 14, 4, Color("#1B2A40"))
			px.call(12, 3 + hy, 10, 2, Color("#2E5280"))
			px.call(9, 5 + hy, 16, 1, Color("#101824"))
		2:
			px.call(11, 1 + hy, 12, 5, Color("#88222A"))
			px.call(11, 4 + hy, 12, 2, Color("#B8323E"))
		3:
			px.call(11, 6 + hy, 12, 2, Color("#F0F4F8"))
			px.call(16, 6 + hy, 2, 1, primary_color)
		4:
			px.call(11, 2 + hy, 12, 4, Color("#1E2430"))
			px.call(22, 5 + hy, 2, 6, Color("#283448"))

	# =========================================================================
	# 5. ATHLETIC SLOPED SHOULDERS & TAPERED HUMAN TORSO (y = 19..36)
	# =========================================================================
	# Sloped adult shoulder contour + athletic V-taper silhouette
	px.call(11, 19 + by, 12, 1, blk)
	px.call(9, 20 + by, 16, 12, blk)
	px.call(10, 32 + by, 14, 5, blk)

	if casual_style == 2:
		var suit_pal := [
			[Color("#191E28"), Color("#EBF1F6"), Color("#B42432")],
			[Color("#1A355B"), Color("#EBF1F6"), Color("#D4A842")],
			[Color("#681A28"), Color("#181C24"), Color("#D4A842")],
			[Color("#D8D2C2"), Color("#FFFFFF"), Color("#B89436")],
			[Color("#242B36"), Color("#D8E2EE"), Color("#2E6CA8")],
		]
		var pal: Array = suit_pal[clampi(outfit_variant, 0, suit_pal.size() - 1)]
		var sj: Color = pal[0]
		px.call(11, 20 + by, 12, 16, sj)
		px.call(10, 21 + by, 14, 11, sj)
		# Crisp dress shirt V + tailored tie
		px.call(14, 20 + by, 6, 8, pal[1])
		px.call(15, 28 + by, 4, 3, pal[1])
		px.call(16, 20 + by, 2, 10, pal[2])
		# Jacket lapels & shading
		px.call(11, 21 + by, 2, 14, sj.lightened(0.10))
		px.call(21, 21 + by, 2, 14, sj.darkened(0.20))
		px.call(16, 32 + by, 2, 1, Color("#94A3B8"))  # Suit button
	elif casual_style == 1:
		match clampi(outfit_variant, 0, 4):
			0:
				px.call(10, 21 + by, 14, 11, Color("#ECEEE8"))
				px.call(11, 20 + by, 12, 16, Color("#ECEEE8"))
				px.call(15, 20 + by, 4, 2, Color("#CBD5E1"))
			1:
				px.call(10, 21 + by, 14, 11, Color("#223042"))
				px.call(11, 20 + by, 12, 16, Color("#223042"))
				px.call(10, 25 + by, 14, 3, Color("#EA7E22"))
				px.call(15, 22 + by, 4, 2, Color("#F8FAFC"))
			2:
				px.call(10, 21 + by, 14, 11, Color("#ECEEE8"))
				px.call(11, 20 + by, 12, 16, Color("#ECEEE8"))
				px.call(10, 21 + by, 3, 14, Color("#8E2832"))
				px.call(21, 21 + by, 3, 14, Color("#8E2832"))
			3:
				px.call(10, 21 + by, 14, 11, Color("#243A5E"))
				px.call(11, 20 + by, 12, 16, Color("#243A5E"))
				px.call(16, 20 + by, 2, 16, Color("#94A3B8"))
			4:
				px.call(10, 21 + by, 14, 11, Color("#2E3848"))
				px.call(11, 20 + by, 12, 16, Color("#2E3848"))
				px.call(13, 30 + by, 8, 4, Color("#1F2632"))
				px.call(15, 21 + by, 1, 5, Color("#E2E8F0"))
				px.call(18, 21 + by, 1, 5, Color("#E2E8F0"))
	else:
		# Pro Football Kit Body (Sloped chest + athletic waist taper)
		px.call(11, 20 + by, 12, 16, primary_color)
		px.call(10, 21 + by, 14, 11, primary_color)
		match kit_pattern:
			"stripes":
				px.call(11, 20 + by, 2, 16, secondary_color)
				px.call(16, 20 + by, 2, 16, secondary_color)
				px.call(21, 20 + by, 2, 16, secondary_color)
			"hoops":
				px.call(10, 23 + by, 14, 3, secondary_color)
				px.call(10, 29 + by, 14, 3, secondary_color)
			"sash":
				for k in range(12):
					px.call(11 + mini(k, 9), 20 + k + by, 3, 2, secondary_color)
			"halved":
				px.call(17, 20 + by, 6, 16, secondary_color)
				px.call(23, 21 + by, 1, 11, secondary_color)
			"chest_band":
				px.call(10, 24 + by, 14, 4, secondary_color)
				px.call(10, 23 + by, 14, 1, secondary_color.darkened(0.25))
			"gradient":
				px.call(10, 25 + by, 14, 4, primary_color.lerp(secondary_color, 0.32))
				px.call(11, 29 + by, 12, 4, primary_color.lerp(secondary_color, 0.65))
				px.call(11, 33 + by, 12, 3, secondary_color)
			"checkered":
				for cy in range(20, 36, 2):
					for cx in range(11, 23, 2):
						if ((cx + cy) / 2) % 2 == 0:
							px.call(cx, cy + by, 2, 2, secondary_color)
			_:
				px.call(11, 20 + by, 3, 1, secondary_color)
				px.call(20, 20 + by, 3, 1, secondary_color)

		# Sculpted Crew/V-Neck Collar Trim + Fabric Depth Shading
		px.call(13, 20 + by, 8, 2, secondary_color)
		px.call(15, 20 + by, 4, 1, skin_sh)
		px.call(16, 21 + by, 2, 1, skin_dk)
		px.call(10, 21 + by, 2, 11, Color(1, 1, 1, 0.11))
		px.call(22, 21 + by, 2, 11, Color(0, 0, 0, 0.22))
		px.call(11, 35 + by, 12, 1, Color(0, 0, 0, 0.18))

		# Left-Chest Club Shield Emblem + Right-Chest Kit Maker Tick
		px.call(19, 23 + by, 3, 3, blk)
		px.call(20, 23 + by, 2, 2, Color.WHITE)
		px.call(20, 24 + by, 1, 1, secondary_color)
		px.call(12, 24 + by, 2, 1, secondary_color.lightened(0.22))

		# Center-Chest Stylized Sponsor Leaf/Emblem (matches Gambar 2 jersey detail!)
		if show_sponsor_motif and not show_number_badge and kit_pattern in ["solid", "sash", "chest_band", "gradient"]:
			var leaf_c: Color = Color("#74C365") if primary_color.r > 0.45 else secondary_color.lightened(0.15)
			px.call(16, 27 + by, 3, 2, leaf_c)
			px.call(15, 28 + by, 3, 2, leaf_c.darkened(0.16))
			px.call(15, 30 + by, 2, 1, leaf_c.darkened(0.30))

	if show_number_badge and casual_style == 0:
		var num_col: Color = blk if primary_color.get_luminance() > 0.6 else Color.WHITE
		px.call(13, 26 + by, 8, 6, Color(primary_color.r, primary_color.g, primary_color.b, 0.78))
		draw_string(UITheme.get_display_font(), Vector2(ox + 13.0 * ps, oy + float(31 + by) * ps), str(shirt_num), HORIZONTAL_ALIGNMENT_CENTER, 8.0 * ps, maxf(8.0, ps * 3.8), num_col)

	# =========================================================================
	# 6. DETACHED NATURAL HUMAN ARMS, SLEEVES, TATTOOS, WRISTBANDS & GK GLOVES
	# =========================================================================
	var sl_h: int = 12 if (long_sleeve or casual_style == 2 or (casual_style == 1 and outfit_variant >= 2)) else 6
	var sleeve_col: Color = primary_color
	var sleeve_r_col: Color = secondary_color if (casual_style == 0 and kit_pattern == "halved") else primary_color
	if casual_style == 2:
		sleeve_col = [Color("#191E28"), Color("#1A355B"), Color("#681A28"), Color("#D8D2C2"), Color("#242B36")][clampi(outfit_variant, 0, 4)]
		sleeve_r_col = sleeve_col
	elif casual_style == 1:
		sleeve_col = [Color("#ECEEE8"), Color("#223042"), Color("#8E2832"), Color("#243A5E"), Color("#2E3848")][clampi(outfit_variant, 0, 4)]
		sleeve_r_col = sleeve_col

	# Left Arm (x=6..9, natural hang with shoulder deltoid curve & detached waist contour!)
	var lax: int = 6 - arm_spread
	var lay: int = 20 + by + l_arm_lift
	px.call(lax + 1, lay, 3, 2, blk)
	px.call(lax, lay + 1, 4, 15, blk)
	px.call(lax + 1, lay + 1, 2, 14, skin)
	px.call(lax + 2, lay + 2, 1, 13, skin_sh)
	px.call(lax + 1, lay + 1, 2, sl_h, sleeve_col)
	if casual_style == 0:
		px.call(lax + 1, lay + sl_h, 2, 1, secondary_color)
	# Sculpted Left Hand
	px.call(lax + 1, lay + 15, 2, 2, blk)
	px.call(lax + 1, lay + 14, 2, 2, skin)
	px.call(lax + 2, lay + 15, 1, 1, skin_sh)

	# Right Arm (x=24..27, natural hang)
	var rax: int = 24 + arm_spread
	var ray: int = 20 + by + r_arm_lift
	px.call(rax, ray, 3, 2, blk)
	px.call(rax, ray + 1, 4, 15, blk)
	px.call(rax + 1, ray + 1, 2, 14, skin)
	px.call(rax + 2, ray + 2, 1, 13, skin_sh)
	px.call(rax + 1, ray + 1, 2, sl_h, sleeve_r_col)
	if casual_style == 0:
		px.call(rax + 1, ray + sl_h, 2, 1, secondary_color)
	# Sculpted Right Hand
	px.call(rax + 1, ray + 15, 2, 2, blk)
	px.call(rax + 1, ray + 14, 2, 2, skin)
	px.call(rax + 1, ray + 15, 1, 1, skin_sh)

	# Detailed Forearm Tattoos (checkerboard / tribal sleeve like Gambar 2!)
	if tattoo_arm > 0 and sl_h <= 7:
		var tat_c := Color("#1B2430")
		for ty in range(7, 14):
			if tattoo_arm >= 1:
				px.call(rax + 1 + ((ty + tattoo_arm) % 2), ray + ty, 1, 1, tat_c)
			if tattoo_arm >= 2:
				px.call(lax + 1 + (ty % 2), lay + ty, 1, 1, tat_c)
			if tattoo_arm >= 3:
				px.call(rax + 1, ray + ty, 2, 1, Color("#18212C") if ty % 2 == 0 else Color("#2C3B4E"))
			if tattoo_arm >= 4:
				px.call(lax + 1, lay + ty, 2, 1, Color("#18212C") if ty % 2 == 0 else Color("#2C3B4E"))

	# Wristbands
	if wrist_side == "LENGAN KIRI" or wrist_side == "KEDUANYA":
		px.call(lax + 1, lay + 12, 2, 2, wrist_color)
	if wrist_side == "LENGAN KANAN" or wrist_side == "KEDUANYA":
		px.call(rax + 1, ray + 12, 2, 2, wrist_color)

	# Padded GK Gloves
	if glove_color.a > 0.1:
		px.call(lax - 1, lay + 12, 4, 5, blk)
		px.call(lax, lay + 13, 3, 3, glove_color)
		px.call(lax, lay + 13, 2, 1, glove_color.lightened(0.22))
		px.call(rax + 1, ray + 12, 4, 5, blk)
		px.call(rax + 1, ray + 13, 3, 3, glove_color)
		px.call(rax + 2, ray + 13, 2, 1, glove_color.lightened(0.22))

	# MVP / Award Trophy (only shown when arms are raised in MVP/CHEER pose, never floating on shoulder in calm INTERVIEW)
	if (show_mvp_trophy and anim_mode != "INTERVIEW") or anim_mode == "MVP":
		var ty_t: int = ray - 6
		px.call(rax - 1, ty_t, 5, 5, Color("#D49B24"))
		px.call(rax, ty_t, 3, 3, Color("#FFF394"))
		px.call(rax + 1, ty_t + 5, 1, 2, Color("#D49B24"))
		px.call(rax, ty_t + 7, 3, 1, Color("#A87314"))
		if anim_mode == "MVP" or anim_mode == "CHEER":
			for st_i in range(4):
				var sx_s: int = int(17.0 + cos(t * 3.5 + float(st_i) * 1.57) * 13.0)
				var sy_s: int = int(6.0 + sin(t * 4.2 + float(st_i) * 1.9) * 5.0)
				px.call(sx_s, sy_s, 2, 2, UITheme.ACCENT_GOLD if st_i % 2 == 0 else UITheme.ACCENT_CYAN)

	if not full_body:
		return

	# =========================================================================
	# 7. ATHLETIC SHORTS, MUSCULAR THIGHS/KNEES, TALL SOCKS & CLEATS (y=36..55)
	# =========================================================================
	var sh_col: Color = shorts_color
	if casual_style == 2:
		sh_col = Color("#181C24")
	elif casual_style == 1:
		sh_col = Color("#2C3D55")

	# Tailored Shorts / Trousers top
	px.call(10, 36 + by, 14, 7, blk)
	px.call(11, 36 + by, 12, 6, sh_col)
	px.call(11, 36 + by, 12, 1, sh_col.darkened(0.22))
	# Clean inner-leg division notch
	px.call(16, 40 + by, 2, 3, blk)
	if casual_style == 0:
		px.call(11, 37 + by, 1, 5, secondary_color)
		px.call(22, 37 + by, 1, 5, secondary_color)
		if show_shorts_number and ps >= 2.0:
			var sn_col: Color = blk if sh_col.get_luminance() > 0.55 else Color.WHITE
			draw_string(UITheme.get_ui_font(), Vector2(ox + 18.0 * ps, oy + float(41.0 + by) * ps), str(shirt_num), HORIZONTAL_ALIGNMENT_CENTER, 5.0 * ps, maxf(7.0, ps * 2.4), sn_col)

	var leg_col: Color = skin if tattoo_leg == 0 else Color("#A48A78")
	var leg_sh: Color = leg_col.darkened(0.18)
	var leg_hi: Color = leg_col.lightened(0.10)
	var sock_c: Color = primary_color if casual_style == 0 else sh_col
	var sock_dk: Color = sock_c.darkened(0.20)
	var pants_full: bool = (casual_style == 2 or casual_style == 1)

	var ll_y: int = 43 + by + (0 if leg_step <= 0 else -1)
	var rl_y: int = 43 + by + (0 if leg_step >= 0 else -1)

	# Left Athletic Leg (x=10..15, tall thigh+knee+sock+cleat)
	px.call(10, ll_y, 6, 9, blk)
	if pants_full:
		px.call(11, ll_y, 4, 9, sh_col)
		px.call(14, ll_y, 1, 9, sh_col.darkened(0.22))
	else:
		px.call(11, ll_y, 4, 4, leg_col)
		px.call(11, ll_y, 1, 3, leg_hi)
		px.call(14, ll_y, 1, 4, leg_sh)
		px.call(12, ll_y + 2, 2, 1, leg_sh)  # Subtle kneecap contour
		px.call(11, ll_y + 4, 4, 5, sock_c)
		px.call(14, ll_y + 4, 1, 5, sock_dk)
		px.call(11, ll_y + 4, 4, 1, secondary_color)
	# Left Sculpted Cleat / Dress Shoe
	var l_shoe_c: Color = Color("#181C24") if casual_style == 2 else boot_color
	px.call(9, ll_y + 9, 7, 3, blk)
	px.call(10, ll_y + 10, 5, 2, l_shoe_c)
	px.call(10, ll_y + 10, 2, 1, l_shoe_c.lightened(0.32))
	px.call(10, ll_y + 11, 5, 1, l_shoe_c.darkened(0.28))

	# Right Athletic Leg (x=18..23, separated human stance)
	px.call(18, rl_y, 6, 9, blk)
	if pants_full:
		px.call(19, rl_y, 4, 9, sh_col)
		px.call(22, rl_y, 1, 9, sh_col.darkened(0.22))
	else:
		px.call(19, rl_y, 4, 4, leg_col)
		px.call(19, rl_y, 1, 3, leg_hi)
		px.call(22, rl_y, 1, 4, leg_sh)
		px.call(20, rl_y + 2, 2, 1, leg_sh)
		px.call(19, rl_y + 4, 4, 5, sock_c)
		px.call(22, rl_y + 4, 1, 5, sock_dk)
		px.call(19, rl_y + 4, 4, 1, secondary_color)
	# Right Sculpted Cleat / Dress Shoe
	px.call(18, rl_y + 9, 7, 3, blk)
	px.call(19, rl_y + 10, 5, 2, l_shoe_c)
	px.call(19, rl_y + 10, 2, 1, l_shoe_c.lightened(0.32))
	px.call(19, rl_y + 11, 5, 1, l_shoe_c.darkened(0.28))
