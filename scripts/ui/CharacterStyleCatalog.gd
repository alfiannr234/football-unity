class_name CharacterStyleCatalog
extends Object

# Shared catalog of expanded pixel-art player customization designs + thumbnail builders.
# Used by both BUAT PEMAINMU (NewCareerModal) and PEMAINKU -> GAYA (PemainkuTab).

const SKIN_TONES := [
	{"name": "CERAH", "col": Color("#F6D4B8")},
	{"name": "SAWO", "col": Color("#E6BA94")},
	{"name": "HANGAT", "col": Color("#C98F62")},
	{"name": "TAN", "col": Color("#A86E44")},
	{"name": "COKELAT", "col": Color("#8A5434")},
	{"name": "GELAP", "col": Color("#5C3723")},
]

const HAIR_STYLES := [
	"BOTAK",
	"KLASIK RAPI",
	"KERITING IKAL",
	"AFRO BULAT",
	"MOHAWK PUNK",
	"HI-TOP FADE",
	"CURTAIN PENDEK",
	"SPIKY FADE",
	"QUIFF RENDAH",
	"EDGAR CROP",
	"GONDRONG",
	"DREADLOCK",
	"TWIST KERITING",
	"CORNROW SISI",
	"MANGKUK",
	"BUZZ CUT",
]

const HAIR_COLORS := [
	{"name": "HITAM", "col": Color("#1A1718")},
	{"name": "COKELAT", "col": Color("#5C3824")},
	{"name": "MADU", "col": Color("#8A542E")},
	{"name": "PIRANG", "col": Color("#D4A842")},
	{"name": "JAHE", "col": Color("#9A3826")},
	{"name": "ABU PERAK", "col": Color("#A0A4AE")},
	{"name": "PLATINUM", "col": Color("#E8EAEF")},
	{"name": "BIRU NEON", "col": Color("#2E7AE6")},
	{"name": "MERAH NEON", "col": Color("#D43038")},
	{"name": "PINK", "col": Color("#D84A90")},
]

const TIP_COLORS := [
	{"name": "POLOS", "col": Color.TRANSPARENT},
	{"name": "UJUNG PERAK", "col": Color("#EAECEF")},
	{"name": "UJUNG EMAS", "col": Color("#F2C94C")},
	{"name": "UJUNG MERAH", "col": Color("#DF3B3B")},
]

const BEARD_STYLES := [
	"TAK ADA",
	"3 HARI TIPIS",
	"DIPANGKAS",
	"PENUH TEBAL",
	"SOUL PATCH",
	"KAMBING",
	"KUMIS TEBAL",
	"WOLVERINE",
]

const FACE_TATTOOS := [
	"TAK ADA",
	"TITIK PIPI",
	"DUA TITIK",
	"AIR MATA",
	"GARIS LUKA",
	"TATO LEHER",
]

const ARM_TATTOOS := [
	"TAK ADA",
	"LENGAN KANAN",
	"KEDUANYA",
	"TRIBAL NAGA",
	"FULL SLEEVE",
]

const LEG_TATTOOS := [
	"TAK ADA",
	"BETIS TRIBAL",
	"RING KAKI",
]

const HEADWEAR_STYLES := [
	"TAK ADA",
	"TOPI BISBOL",
	"KUPLUK",
	"IKAT KEPALA",
	"DURAG",
]

const EYEWEAR_STYLES := [
	"TAK ADA",
	"KACAMATA EMAS",
	"KACAMATA HITAM",
	"KACAMATA SPORT",
]

const CASUAL_STYLES := [
	{"name": "KAUS POLOS", "mode": 1, "variant": 0},
	{"name": "KAUS MOTIF", "mode": 1, "variant": 1},
	{"name": "JAKET BUKA", "mode": 1, "variant": 2},
	{"name": "JAKET TUTUP", "mode": 1, "variant": 3},
	{"name": "HOODIE KOTA", "mode": 1, "variant": 4},
]

const GALA_STYLES := [
	{"name": "TUKSEDO", "mode": 2, "variant": 0},
	{"name": "JAS BIRU", "mode": 2, "variant": 1},
	{"name": "BELUDRU MERAH", "mode": 2, "variant": 2},
	{"name": "GADING EMAS", "mode": 2, "variant": 3},
	{"name": "DIPLOMAT", "mode": 2, "variant": 4},
]

static func build_avatar_preview_tile(
	label_txt: String,
	base_profile: Dictionary,
	overrides: Dictionary,
	show_full_body: bool,
	is_selected: bool,
	on_select: Callable,
	tile_h: float = 96.0
) -> Button:
	var btn := Button.new()
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, tile_h)
	UITheme.style_btn(
		btn,
		Color("#15365E") if is_selected else Color("#0A1320"),
		UITheme.ACCENT_GOLD if is_selected else Color("#24364E"),
		9
	)
	btn.pressed.connect(func():
		var st: SceneTree = Engine.get_main_loop() as SceneTree
		var aud: Node = st.root.get_node_or_null("AudioSynth") if st != null else null
		if aud != null:
			aud.call("play_click")
		on_select.call()
	)

	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 3
	vb.offset_right = -3
	vb.offset_top = 4
	vb.offset_bottom = -4
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 2)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(vb)

	var av := PixelAvatar.new()
	av.full_body = show_full_body
	av.custom_minimum_size = Vector2(54, 62 if show_full_body else 52)
	av.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	av.mouse_filter = Control.MOUSE_FILTER_IGNORE
	apply_config_to_avatar(av, base_profile, overrides)
	vb.add_child(av)

	var lbl := Label.new()
	lbl.text = label_txt
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.clip_text = true
	lbl.add_theme_font_size_override("font_size", 8)
	lbl.add_theme_color_override("font_color", UITheme.ACCENT_GOLD if is_selected else Color("#CBD5E1"))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(lbl)

	return btn

static func build_color_swatch_tile(
	label_txt: String,
	col: Color,
	is_selected: bool,
	on_select: Callable,
	w_min: float = 42.0,
	h_min: float = 36.0
) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(w_min, h_min)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.text = "*" if (is_selected and col == Color.TRANSPARENT) else ("" if col != Color.TRANSPARENT else "-")
	var fill := col if col.a > 0.1 else Color("#162336")
	UITheme.style_btn(
		btn,
		fill,
		UITheme.ACCENT_CYAN if is_selected else Color("#28394F"),
		10
	)
	if is_selected and col.a > 0.1:
		btn.text = "*"
		btn.add_theme_color_override("font_color", Color.BLACK if col.get_luminance() > 0.6 else Color.WHITE)
	btn.tooltip_text = label_txt
	btn.pressed.connect(func():
		var st: SceneTree = Engine.get_main_loop() as SceneTree
		var aud: Node = st.root.get_node_or_null("AudioSynth") if st != null else null
		if aud != null:
			aud.call("play_click")
		on_select.call()
	)
	return btn

static func apply_config_to_avatar(av: PixelAvatar, base_app: Dictionary, overrides: Dictionary) -> void:
	var merged := base_app.duplicate()
	for k in overrides.keys():
		merged[k] = overrides[k]

	av.primary_color = merged.get("primary_color", Color("#1A90E0"))
	av.secondary_color = merged.get("secondary_color", Color("#FFFFFF"))
	av.kit_pattern = str(merged.get("kit_pattern", "solid"))
	av.shorts_color = merged.get("shorts_color", Color("#F4F8FF"))

	av.skin_idx = int(merged.get("skin", 1))
	av.hair_style = int(merged.get("hair_style", 2))
	av.hair_idx = int(merged.get("hair_color", 1))
	av.tip_color_idx = int(merged.get("tip_color", 0))
	av.beard_style = int(merged.get("beard_style", 1 if bool(merged.get("beard", false)) else 0))
	av.beard = (av.beard_style > 0)
	av.long_sleeve = str(merged.get("sleeve", "PENDEK")) == "PANJANG"
	av.tattoo_face = int(merged.get("tattoo_face", 0))
	av.tattoo_arm = int(merged.get("tattoo_arm", 0))
	av.tattoo_leg = int(merged.get("tattoo_leg", 0))
	av.headwear = int(merged.get("headwear", 0))
	av.eyewear = int(merged.get("eyewear", 0))
	av.casual_style = int(merged.get("casual_style", 0))
	av.outfit_variant = int(merged.get("outfit_variant", 0))
	av.shirt_num = int(merged.get("shirt_num", 9))

	var boot_id := int(merged.get("boot_id", 0))
	var boot_cols := [
		Color("#20242C"), Color("#E8ECF2"), Color("#D72A30"), Color("#2A7CE4"),
		Color("#F2C638"), Color("#DA4898"), Color("#40D45C"), Color("#EE7624"),
		Color("#2AEBD2"), Color("#843ED2"), Color("#F5CD48")
	]
	av.boot_color = boot_cols[clampi(boot_id, 0, boot_cols.size() - 1)]
	var gc_idx := int(merged.get("glove_color", -1))
	var glove_cols := [Color("#181C24"), Color("#F2F4F8"), Color("#C82832"), Color("#1E54B8"), Color("#F5C542"), Color("#EE7624")]
	av.glove_color = glove_cols[clampi(gc_idx, 0, glove_cols.size() - 1)] if gc_idx >= 0 else Color.TRANSPARENT
	av.wrist_side = str(merged.get("wrist_side", "TAK ADA"))
	var wc_idx := int(merged.get("wrist_color", 0))
	var wc_cols := [Color("#94A3B8"), Color("#1E3A8A"), Color("#DC2626"), Color("#EAB308"), Color("#16A34A"), Color("#9333EA"), Color("#EA580C")]
	av.wrist_color = wc_cols[clampi(wc_idx, 0, wc_cols.size() - 1)]
	av.queue_redraw()
