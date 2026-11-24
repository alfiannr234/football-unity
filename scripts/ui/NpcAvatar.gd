class_name NpcAvatar
extends Control

# Human-proportioned 16-bit pixel-art NPC renderer matching PixelAvatar's adult anatomy (34x56 front / 42x56 side-profile).
# Roles: "REPORTER", "SUPPORTER", "COACH", "SENIOR_COACH", "AGENT", "TEAMMATE", "PARTNER", "PRESIDENT"
# Supports Gambar 2's iconic side-profile TV Reporter holding an outstretched broadcast microphone!

var role: String = "REPORTER"
var side_profile: bool = false
var anim_mode: String = "IDLE"  # "NONE", "IDLE", "TALK", "CHEER"
var anim_phase: float = 0.0
var club_primary: Color = Color("#1A66D2")
var club_secondary: Color = Color("#F4F8FF")
var _anim_t: float = 0.0

static func from_legacy_index(idx: int, club: Dictionary = {}, use_side_profile: bool = false) -> NpcAvatar:
	var av := NpcAvatar.new()
	match idx:
		0: av.role = "REPORTER"
		1: av.role = "SUPPORTER"
		2: av.role = "COACH"
		3: av.role = "SENIOR_COACH"
		4: av.role = "AGENT"
		5: av.role = "TEAMMATE"
		6: av.role = "PARTNER"
		7: av.role = "PRESIDENT"
		_: av.role = "REPORTER"
	av.side_profile = use_side_profile
	if not club.is_empty():
		av.club_primary = UITheme.parse_color(club.get("primary", Color("#1A66D2")), Color("#1A66D2"))
		av.club_secondary = UITheme.parse_color(club.get("secondary", Color("#F4F8FF")), Color("#F4F8FF"))
	return av

func configure_role(r: String, use_side_profile: bool = false, club: Dictionary = {}) -> void:
	role = r.to_upper()
	side_profile = use_side_profile
	if not club.is_empty():
		club_primary = UITheme.parse_color(club.get("primary", Color("#1A66D2")), Color("#1A66D2"))
		club_secondary = UITheme.parse_color(club.get("secondary", Color("#F4F8FF")), Color("#F4F8FF"))
	queue_redraw()

func _ready() -> void:
	_anim_t = anim_phase

func _process(delta: float) -> void:
	if anim_mode == "NONE" or not visible:
		return
	_anim_t += delta
	queue_redraw()

func _draw() -> void:
	if side_profile and role == "REPORTER":
		_draw_side_profile_reporter()
	else:
		_draw_front_human_npc()

func _compute_ps(grid_w: float, grid_h: float) -> Vector3:
	var raw_ps: float = minf(size.x / grid_w, size.y / grid_h)
	var ps: float = floorf(raw_ps) if raw_ps >= 3.0 else (floorf(raw_ps * 2.0) * 0.5 if raw_ps >= 1.25 else maxf(0.5, raw_ps))
	var ox: float = floorf((size.x - grid_w * ps) * 0.5)
	var oy: float = floorf((size.y - grid_h * ps) * 0.5)
	return Vector3(ps, ox, oy)

# ==============================================================================
# ICONIC SIDE-PROFILE TV REPORTER (GAMBAR 2: Facing Left, Red Dress-Blazer,
# Wavy Blonde Hair, Outstretched Arm Holding Orange-Flagged TV Microphone!)
# ==============================================================================
func _draw_side_profile_reporter() -> void:
	var m: Vector3 = _compute_ps(42.0, 56.0)
	var ps: float = m.x
	var ox: float = m.y
	var oy: float = m.z

	var t: float = _anim_t
	var breath: int = 1 if (anim_mode != "NONE" and sin(t * 2.3) > 0.62) else 0
	var head_nod: int = 1 if (anim_mode == "TALK" and sin(t * 3.1) > 0.65) else 0
	var mic_bob: int = -1 if (anim_mode == "TALK" and sin(t * 4.2) > 0.35) else 0
	var hair_sway: int = 1 if (anim_mode != "NONE" and sin(t * 2.0) > 0.45) else 0
	var blink: bool = anim_mode != "NONE" and fmod(t, 4.1) > 3.94
	var mouth_open: bool = anim_mode == "TALK" and sin(t * 10.2) > 0.18

	var blk := Color("#0C0F16")
	var skin := Color("#DFA984")
	var skin_hi := Color("#F0C29F")
	var skin_sh := Color("#BD825D")
	var skin_dk := Color("#9A6344")
	var hair := Color("#C9964C")
	var hair_hi := Color("#ECC778")
	var hair_sh := Color("#946328")
	var dress := Color("#B81D2C")
	var dress_hi := Color("#DE3546")
	var dress_sh := Color("#7E101B")
	var shoe := Color("#1B1E28")

	var px := func(x: int, y: int, w: int, h: int, col: Color):
		draw_rect(Rect2(ox + float(x) * ps, oy + float(y) * ps, float(w) * ps, float(h) * ps), col)

	# Grounded diagonal turf cast shadow stretching left-back
	px.call(11, 52, 22, 2, Color(0, 0, 0, 0.28))
	px.call(15, 51, 18, 4, Color(0, 0, 0, 0.20))

	var hy: int = head_nod + breath
	var by: int = breath

	# 1. BACK FLOWING WAVY BLONDE HAIR (cascades behind shoulders with sunlit streaks!)
	px.call(22, 3 + hy, 11, 1, blk)
	px.call(20, 4 + hy, 15, 2, blk)
	px.call(24, 6 + hy, 12, 10, blk)
	px.call(26 + hair_sway, 15 + by, 11, 16, blk)
	px.call(28 + hair_sway, 30 + by, 9, 4, blk)
	# Hair base fill & layered wave streaks
	px.call(22, 4 + hy, 11, 2, hair)
	px.call(24, 6 + hy, 11, 10, hair)
	px.call(27 + hair_sway, 15 + by, 9, 15, hair)
	px.call(29 + hair_sway, 29 + by, 7, 4, hair_sh)
	# Golden crown & wavy vertical sheen lines
	px.call(23, 4 + hy, 7, 1, hair_hi)
	px.call(27, 7 + hy, 4, 2, hair_hi)
	px.call(30 + hair_sway, 11 + hy, 3, 6, hair_hi)
	px.call(32 + hair_sway, 18 + by, 2, 10, hair_hi)
	px.call(29 + hair_sway, 16 + by, 2, 12, hair_sh)
	px.call(34 + hair_sway, 17 + by, 1, 12, hair_sh)

	# 2. SCULPTED SIDE-PROFILE FACE & NECK (Graceful human side-profile facing LEFT!)
	# Slender neck
	px.call(20, 15 + hy, 6, 4, blk)
	px.call(21, 16 + hy, 4, 4, skin_sh)
	px.call(22, 16 + hy, 2, 4, skin)
	# Refined Profile Head Silhouette (smooth forehead, delicate 1px human nose, soft chin)
	px.call(18, 5 + hy, 8, 1, blk)
	px.call(17, 6 + hy, 9, 4, blk)
	px.call(15, 10 + hy, 11, 2, blk)  # Delicate 1px nose tip at x=15
	px.call(16, 12 + hy, 10, 3, blk)  # Lips & jawline
	px.call(18, 15 + hy, 8, 2, blk)   # Tapered chin
	# Skin Fill
	px.call(18, 6 + hy, 7, 4, skin)
	px.call(16, 10 + hy, 9, 2, skin)
	px.call(17, 12 + hy, 8, 3, skin)
	px.call(19, 15 + hy, 6, 1, skin_sh)
	# Subtle cheek highlight & jaw shading
	px.call(18, 7 + hy, 3, 2, skin_hi)
	px.call(17, 10 + hy, 2, 1, skin_hi)
	px.call(22, 12 + hy, 3, 3, skin_sh)
	px.call(17, 12 + hy, 1, 1, skin_dk)  # Delicate under-nose contour
	# Front hair fringe sweeping forehead & temple
	px.call(18, 4 + hy, 6, 2, blk)
	px.call(19, 5 + hy, 6, 2, hair)
	px.call(20, 5 + hy, 3, 1, hair_hi)
	px.call(23, 7 + hy, 3, 6, hair)
	px.call(24, 9 + hy, 1, 3, hair_sh)
	# Side-Profile Eye, Eyelash & Brow
	px.call(17, 8 + hy, 4, 1, hair_sh)
	if blink:
		px.call(17, 10 + hy, 3, 1, blk)
	else:
		px.call(17, 9 + hy, 3, 2, Color("#F8FAFC"))
		px.call(17, 9 + hy, 2, 2, Color("#181D2B"))
		px.call(18, 9 + hy, 1, 1, Color("#FFFFFF"))
		px.call(16, 9 + hy, 1, 1, blk)
	# Warm Natural Smile / Speaking Mouth
	if mouth_open:
		px.call(17, 13 + hy, 3, 2, Color("#8D2C34"))
		px.call(17, 13 + hy, 2, 1, Color("#F8FAFC"))
	else:
		px.call(17, 13 + hy, 3, 1, Color("#A44E46"))
		px.call(20, 12 + hy, 1, 1, Color("#A44E46"))

	# 3. TAILORED CRIMSON BROADCAST BLAZER-DRESS (Feminine Human Silhouette!)
	px.call(19, 19 + by, 10, 2, blk)
	px.call(17, 21 + by, 13, 8, blk)  # Bust / upper blazer contour
	px.call(19, 29 + by, 10, 4, blk)  # Cinched waist
	px.call(19, 33 + by, 12, 9, blk)  # Tailored knee-length skirt
	# Red Dress Fill
	px.call(20, 20 + by, 8, 2, dress)
	px.call(18, 21 + by, 11, 8, dress)
	px.call(20, 29 + by, 8, 4, dress)
	px.call(20, 33 + by, 10, 8, dress)
	# Dress Lighting, Lapel & Seam Shading
	px.call(18, 22 + by, 2, 6, dress_hi)
	px.call(20, 34 + by, 2, 7, dress_hi)
	px.call(27, 22 + by, 2, 10, dress_sh)
	px.call(28, 33 + by, 2, 8, dress_sh)
	px.call(21, 20 + by, 3, 4, dress_sh)  # V-neck blazer lapel
	px.call(21, 20 + by, 2, 2, skin)      # Neckline V skin peek
	px.call(20, 31 + by, 8, 1, dress_sh)  # Waist belt seam

	# 4. OUTSTRETCHED ARM HOLDING BROADCAST HANDHELD MICROPHONE (Reaching LEFT!)
	var my: int = 21 + by + mic_bob
	# Extended Red Blazer Sleeve (x=9..21)
	px.call(9, my, 12, 5, blk)
	px.call(9, my + 1, 12, 3, dress)
	px.call(10, my + 1, 10, 1, dress_hi)
	px.call(10, my + 3, 10, 1, dress_sh)
	# Sculpted Hand Gripping Microphone (x=6..9)
	px.call(5, my, 5, 5, blk)
	px.call(6, my + 1, 3, 3, skin)
	px.call(6, my + 1, 2, 1, skin_hi)
	# Broadcast Handheld Microphone (Dark Grille + Iconic Orange Flag Cube + Handle!)
	px.call(5, my - 6, 5, 7, blk)
	px.call(6, my - 5, 3, 2, Color("#263042"))  # Mesh mic head
	px.call(6, my - 5, 1, 1, Color("#64748B"))  # Metallic glint
	px.call(6, my - 3, 3, 3, Color("#EA761C"))  # Iconic orange broadcast cube!
	px.call(6, my - 3, 2, 1, Color("#FDBA74"))  # Top orange highlight
	px.call(6, my + 4, 3, 3, blk)               # Lower mic handle & cable nub
	px.call(7, my + 4, 1, 2, Color("#334155"))

	# 5. RELAXED RIGHT ARM AT HER SIDE (x=23..28, y=22..38)
	px.call(23, 22 + by, 5, 13, blk)
	px.call(24, 23 + by, 3, 11, dress)
	px.call(24, 23 + by, 1, 10, dress_hi)
	px.call(26, 24 + by, 1, 9, dress_sh)
	# Right Hand resting near hip
	px.call(23, 35 + by, 5, 4, blk)
	px.call(24, 35 + by, 3, 3, skin)
	px.call(26, 36 + by, 1, 2, skin_sh)

	# 6. SLENDER SHADED HUMAN LEGS & DARK BROADCAST HEELS (y=42..55)
	# Front stepping leg (x=21..25) & trailing leg (x=25..29)
	px.call(21, 42 + by, 5, 10, blk)
	px.call(22, 42 + by, 3, 9, skin)
	px.call(22, 42 + by, 1, 8, skin_hi)
	px.call(24, 42 + by, 1, 9, skin_sh)
	px.call(25, 42 + by, 5, 10, blk)
	px.call(26, 42 + by, 3, 9, skin_sh)
	px.call(28, 42 + by, 1, 9, skin_dk)
	# Sleek Heels
	px.call(19, 51 + by, 7, 3, blk)
	px.call(20, 52 + by, 5, 1, shoe)
	px.call(20, 52 + by, 2, 1, Color("#475569"))
	px.call(24, 51 + by, 6, 3, blk)
	px.call(25, 52 + by, 4, 1, shoe)

# ==============================================================================
# FRONT-FACING SCULPTED HUMAN-PROPORTIONED NPCS (34x56, Matching PixelAvatar!)
# ==============================================================================
func _draw_front_human_npc() -> void:
	var m: Vector3 = _compute_ps(34.0, 56.0)
	var ps: float = m.x
	var ox: float = m.y
	var oy: float = m.z

	var t: float = _anim_t
	var bob_y: int = 1 if (anim_mode != "NONE" and sin(t * 2.6) > 0.55) else 0
	var blink: bool = anim_mode != "NONE" and fmod(t, 4.0) > 3.84
	var mouth_open: bool = anim_mode == "TALK" and sin(t * 9.8) > 0.15

	var blk := Color("#0C0F16")
	var skin := Color("#E8BC96")
	var hair := Color("#5C3824")
	var suit_a := Color("#1B2434")
	var suit_b := Color("#F1F5F9")
	var tie_c := Color("#C93A3A")
	var pants_c := Color("#161D2A")
	var shoe_c := Color("#151922")
	var is_female: bool = false
	var has_beard: bool = false
	var has_mic: bool = false
	var has_scarf: bool = false
	var is_kit: bool = false

	match role:
		"REPORTER":
			is_female = true
			has_mic = true
			skin = Color("#E4B18C")
			hair = Color("#C9964C")
			suit_a = Color("#B81D2C")
			suit_b = Color("#F8FAFC")
			tie_c = Color("#7E101B")
			pants_c = Color("#B81D2C")
		"SUPPORTER":
			has_scarf = true
			skin = Color("#DFB08A")
			hair = Color("#4B2E1E")
			suit_a = club_primary
			suit_b = club_secondary
			pants_c = Color("#24354D")
			shoe_c = Color("#E2E8F0")
		"COACH":
			has_beard = true
			skin = Color("#E0B28C")
			hair = Color("#4A2F1D")
			suit_a = Color("#18202C")
			suit_b = Color("#F8FAFC")
			tie_c = Color("#94A3B8")
			pants_c = Color("#161C26")
		"SENIOR_COACH", "PUNDIT":
			has_beard = true
			skin = Color("#E6BE9C")
			hair = Color("#B8C2CE")
			suit_a = Color("#1C2F4C")
			suit_b = Color("#F8FAFC")
			tie_c = Color("#D4A842")
			pants_c = Color("#17243A")
		"AGENT":
			skin = Color("#F0C8A4")
			hair = Color("#D4A948")
			suit_a = Color("#1F2633")
			suit_b = Color("#F8FAFC")
			tie_c = Color("#C82834")
			pants_c = Color("#181E29")
		"TEAMMATE":
			is_kit = true
			skin = Color("#E6BA92")
			hair = Color("#C99A3B")
			suit_a = club_primary
			suit_b = club_secondary
			pants_c = club_secondary if club_primary.get_luminance() < 0.65 else Color("#18202E")
			shoe_c = Color("#2563EB")
		"PARTNER":
			is_female = true
			skin = Color("#E8BC96")
			hair = Color("#3D2418")
			suit_a = Color("#C9284D")
			suit_b = Color("#FCE7F3")
			tie_c = Color("#9E1C3B")
			pants_c = Color("#1E293B")
		"PRESIDENT":
			has_beard = true
			skin = Color("#E2B794")
			hair = Color("#9CA3AF")
			suit_a = Color("#132542")
			suit_b = Color("#FFFFFF")
			tie_c = Color("#EAB308")
			pants_c = Color("#0F1D33")

	var skin_sh: Color = skin.darkened(0.16)
	var skin_dk: Color = skin.darkened(0.28)
	var skin_hi: Color = skin.lightened(0.13)
	var hair_hi: Color = hair.lightened(0.24)
	var hair_dk: Color = hair.darkened(0.30)

	var px := func(x: int, y: int, w: int, h: int, col: Color):
		draw_rect(Rect2(ox + float(x) * ps, oy + float(y) * ps, float(w) * ps, float(h) * ps), col)

	# Ground Shadow
	px.call(8, 53, 18, 2, Color(0, 0, 0, 0.28))
	px.call(10, 52, 14, 4, Color(0, 0, 0, 0.18))

	var hy: int = bob_y
	var by: int = bob_y

	# Long back hair layer for female NPCs
	if is_female:
		px.call(9, 4 + hy, 16, 17, blk)
		px.call(10, 5 + hy, 14, 15, hair)
		px.call(10, 12 + hy, 2, 12, blk)
		px.call(22, 12 + hy, 2, 12, blk)
		px.call(10, 12 + hy, 2, 11, hair_dk)
		px.call(22, 12 + hy, 2, 11, hair_dk)

	# 1. Sculpted Human Head & Neck (identical 1:4.2 ratio to PixelAvatar!)
	px.call(14, 15 + hy, 6, 4, blk)
	px.call(15, 16 + hy, 4, 4, skin_sh)
	px.call(16, 17 + hy, 2, 3, skin)

	if not is_female:
		px.call(10, 9 + hy, 2, 4, blk)
		px.call(11, 10 + hy, 1, 2, skin)
		px.call(22, 9 + hy, 2, 4, blk)
		px.call(22, 10 + hy, 1, 2, skin_sh)

	px.call(13, 3 + hy, 8, 1, blk)
	px.call(12, 4 + hy, 10, 1, blk)
	px.call(11, 5 + hy, 12, 9, blk)
	px.call(12, 14 + hy, 10, 1, blk)
	px.call(13, 15 + hy, 8, 1, blk)
	px.call(14, 16 + hy, 6, 1, blk)
	px.call(13, 4 + hy, 8, 1, skin)
	px.call(12, 5 + hy, 10, 9, skin)
	px.call(13, 14 + hy, 8, 1, skin)
	px.call(14, 15 + hy, 6, 1, skin_sh)
	px.call(12, 6 + hy, 1, 7, skin_hi)
	px.call(20, 6 + hy, 2, 7, skin_sh)

	# Eyes, Brows, Nose & Mouth
	if blink:
		px.call(13, 10 + hy, 3, 1, blk)
		px.call(18, 10 + hy, 3, 1, blk)
	else:
		px.call(13, 9 + hy, 3, 2, Color("#F6F8FC"))
		px.call(14, 9 + hy, 1, 2, Color("#152036"))
		px.call(18, 9 + hy, 3, 2, Color("#F6F8FC"))
		px.call(19, 9 + hy, 1, 2, Color("#152036"))
	px.call(13, 8 + hy, 3, 1, hair_dk)
	px.call(18, 8 + hy, 3, 1, hair_dk)
	px.call(16, 10 + hy, 2, 2, skin_sh)
	px.call(16, 12 + hy, 2, 1, skin_dk)
	if mouth_open:
		px.call(15, 13 + hy, 4, 2, Color("#7A2B31"))
		px.call(16, 13 + hy, 2, 1, Color("#F8FAFC"))
	else:
		px.call(15, 13 + hy, 4, 1, Color("#B4545A") if is_female else Color("#945549"))

	if has_beard:
		px.call(12, 12 + hy, 1, 2, hair)
		px.call(21, 12 + hy, 1, 2, hair)
		px.call(13, 14 + hy, 8, 2, hair)
		px.call(14, 15 + hy, 6, 1, hair_dk)
		px.call(15, 12 + hy, 4, 1, hair)

	# Sculpted Hair Crown
	if is_female:
		px.call(11, 2 + hy, 12, 4, blk)
		px.call(12, 3 + hy, 10, 3, hair)
		px.call(11, 6 + hy, 2, 14, hair)
		px.call(21, 6 + hy, 2, 14, hair)
		px.call(13, 3 + hy, 6, 1, hair_hi)
		px.call(11, 10 + hy, 1, 8, hair_hi)
	else:
		px.call(12, 2 + hy, 10, 1, blk)
		px.call(11, 3 + hy, 12, 4, blk)
		px.call(12, 3 + hy, 10, 3, hair)
		px.call(12, 6 + hy, 10, 1, hair_dk)
		px.call(11, 6 + hy, 1, 3, hair)
		px.call(22, 6 + hy, 1, 3, hair)
		px.call(13, 3 + hy, 5, 1, hair_hi)

	# 2. Sloped Human Torso & Outfit (y=19..36)
	px.call(11, 19 + by, 12, 1, blk)
	px.call(9, 20 + by, 16, 12, blk)
	px.call(10, 32 + by, 14, 5, blk)
	px.call(11, 20 + by, 12, 16, suit_a)
	px.call(10, 21 + by, 14, 11, suit_a)

	if is_kit:
		px.call(11, 20 + by, 2, 16, suit_b)
		px.call(16, 20 + by, 2, 16, suit_b)
		px.call(21, 20 + by, 2, 16, suit_b)
		px.call(13, 20 + by, 8, 2, suit_b)
		px.call(15, 20 + by, 4, 1, skin_sh)
	elif has_scarf:
		px.call(10, 21 + by, 2, 11, suit_a.lightened(0.12))
		px.call(22, 21 + by, 2, 11, suit_a.darkened(0.20))
		# Draped Supporter Club Scarf!
		px.call(12, 19 + by, 10, 4, blk)
		px.call(13, 20 + by, 8, 2, suit_b)
		px.call(14, 20 + by, 2, 2, suit_a)
		px.call(18, 20 + by, 2, 2, suit_a)
		px.call(13, 22 + by, 3, 9, suit_b)
		px.call(14, 24 + by, 2, 2, suit_a)
		px.call(14, 28 + by, 2, 2, suit_a)
	elif is_female:
		px.call(15, 20 + by, 4, 3, skin)
		px.call(14, 20 + by, 1, 4, tie_c)
		px.call(19, 20 + by, 1, 4, tie_c)
		px.call(11, 21 + by, 2, 14, suit_a.lightened(0.14))
		px.call(21, 21 + by, 2, 14, suit_a.darkened(0.22))
		px.call(11, 31 + by, 12, 1, tie_c)
	else:
		# Tailored Suit / Coach Coat + Dress Shirt + Tie / Whistle
		px.call(14, 20 + by, 6, 9, suit_b)
		px.call(15, 29 + by, 4, 2, suit_b)
		px.call(16, 20 + by, 2, 10, tie_c)
		px.call(11, 21 + by, 2, 14, suit_a.lightened(0.12))
		px.call(21, 21 + by, 2, 14, suit_a.darkened(0.22))
		if role == "COACH":
			# Silver whistle resting on chest
			px.call(16, 28 + by, 2, 2, Color("#E2E8F0"))

	# 3. Detached Human Arms
	var sl_h: int = 6 if is_kit else 12
	# Left Arm
	px.call(7, 20 + by, 3, 2, blk)
	px.call(6, 21 + by, 4, 15, blk)
	px.call(7, 21 + by, 2, 14, skin)
	px.call(7, 21 + by, 2, sl_h, suit_a)
	px.call(7, 35 + by, 2, 2, blk)
	px.call(7, 34 + by, 2, 2, skin)
	# Right Arm (lifted holding broadcast mic for front Reporter!)
	var r_off: int = -4 if has_mic else 0
	px.call(24, 20 + by + r_off, 3, 2, blk)
	px.call(24, 21 + by + r_off, 4, 15, blk)
	px.call(25, 21 + by + r_off, 2, 14, skin)
	px.call(25, 21 + by + r_off, 2, sl_h, suit_a)
	px.call(25, 35 + by + r_off, 2, 2, blk)
	px.call(25, 34 + by + r_off, 2, 2, skin)
	if has_mic:
		px.call(24, 25 + by + r_off, 4, 6, blk)
		px.call(25, 26 + by + r_off, 2, 2, Color("#263042"))
		px.call(25, 28 + by + r_off, 2, 2, Color("#EA761C"))

	# 4. Lower Body & Legs (y=36..55)
	px.call(10, 36 + by, 14, 7, blk)
	px.call(11, 36 + by, 12, 6, pants_c)
	if not (is_female and role == "REPORTER"):
		px.call(16, 40 + by, 2, 3, blk)
	if is_kit:
		px.call(10, 43 + by, 6, 9, blk)
		px.call(11, 43 + by, 4, 4, skin)
		px.call(11, 47 + by, 4, 5, suit_a)
		px.call(11, 47 + by, 4, 1, suit_b)
		px.call(18, 43 + by, 6, 9, blk)
		px.call(19, 43 + by, 4, 4, skin)
		px.call(19, 47 + by, 4, 5, suit_a)
		px.call(19, 47 + by, 4, 1, suit_b)
	elif is_female and role == "REPORTER":
		px.call(11, 43 + by, 5, 9, blk)
		px.call(12, 43 + by, 3, 9, skin)
		px.call(18, 43 + by, 5, 9, blk)
		px.call(19, 43 + by, 3, 9, skin)
	else:
		px.call(10, 43 + by, 6, 9, blk)
		px.call(11, 43 + by, 4, 9, pants_c)
		px.call(14, 43 + by, 1, 9, pants_c.darkened(0.22))
		px.call(18, 43 + by, 6, 9, blk)
		px.call(19, 43 + by, 4, 9, pants_c)
		px.call(22, 43 + by, 1, 9, pants_c.darkened(0.22))

	# Sculpted Shoes / Cleats
	px.call(9, 52 + by, 7, 3, blk)
	px.call(10, 53 + by, 5, 2, shoe_c)
	px.call(10, 53 + by, 2, 1, shoe_c.lightened(0.28))
	px.call(18, 52 + by, 7, 3, blk)
	px.call(19, 53 + by, 5, 2, shoe_c)
	px.call(19, 53 + by, 2, 1, shoe_c.lightened(0.28))
