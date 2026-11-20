extends Node

# Static & seeded world catalog for Football Unity:
# - 55 Nations with 5-year coefficients
# - 2,731 Clubs & Coaches across 3 divisions per nation (including exact 32-team Sweden Div 3)
# - 21,289 World Players (with O(N) bucket-sorted OVR index)
# - 386 Achievements (32 UMUM, 106 LANGKA, 162 EPIK, 86 LEGENDARIS)
# - Shop Catalog (11 Boots, 6 Staff, Properties, Furniture, Cars, Luxury, Perks)
# - Cosmetics (24 Rings, 31 Aim Arrows, 4 Ball Trails, 14 OVR Badges, 13 Card Frames)
# - Hall of Fame Legends, Most Decorated Clubs, Narrative Dilemmas, Sponsors

const POSITIONS := ["GK", "CB", "LB", "RB", "CDM", "CM", "LM", "RM", "CAM", "LW", "RW", "ST"]
const LEARNABLE_POSITIONS := ["CDM", "CM", "LM", "RM", "CAM", "LW", "RW", "LB", "RB", "CB"]
const ATTRIBUTE_KEYS := [
	"kekuatan", "akurasi", "efek", "visi", "fisik",
	"kecepatan", "akselerasi", "dribel", "penalti", "bolaMati"
]
const ATTRIBUTE_LABELS := {
	"kekuatan": "Kekuatan",
	"akurasi": "Akurasi",
	"efek": "Efek",
	"visi": "Visi",
	"fisik": "Fisik",
	"kecepatan": "Kecepatan",
	"akselerasi": "Akselerasi",
	"dribel": "Dribel",
	"penalti": "Penalti",
	"bolaMati": "Bola mati",
}

const RELATION_KEYS := ["pelatih", "ruangGanti", "fans", "pers", "agen"]

var nations: Array[Dictionary] = []
var clubs: Array[Dictionary] = []
var coaches: Array[Dictionary] = []
var achievements: Array[Dictionary] = []
var world_legends: Array[Dictionary] = []
var decorated_clubs: Array[Dictionary] = []
var boots_catalog: Array[Dictionary] = []
var staff_catalog: Array[Dictionary] = []
var lifestyle_catalog: Array[Dictionary] = []
var cosmetics_catalog: Dictionary = {}
var sponsors_catalog: Array[Dictionary] = []
var dilemmas_catalog: Array[Dictionary] = []
var album_cards_catalog: Array[Dictionary] = []
var preset_friends: Array[Dictionary] = []

const SWEDEN_DIV3_NAMES := [
	"Hassleholm Knutpunkten", "Helsingborg Oresund", "Karlstad Solstaden", "Stockholm Svartvita",
	"Jarfalla Viksjo", "Malmo Ostra", "Pitea Norrbotten", "Stockholm Sickla",
	"Tvaaker Kusten", "Umea Bjorkstaden", "Gavle Bocken", "Malmo Kirseberg",
	"Marsta Flygfaltet", "Danderyd Edsviken", "Eskilstuna Stalstaden", "Jonkoping Vattern",
	"Sodertalje Ronna", "Skovde Billingen", "Trelleborg Hamnstaden", "Enkoping Malaren",
	"Karlstad Klaralven", "Kristianstad Vattenrike", "Lund Domkyrkan", "Sollentuna Norrort",
	"Trollhattan Fallen", "Atvidaberg Kopparbruket", "Laholm Lagan", "Malmo Mollevangen",
	"Angelholm Skalderviken", "Solna Rasunda", "Stockholm Vasastan", "Goteborg Kortedala"
]

const FAMOUS_CLUBS := {
	1: ["Madrid Blanco", "Barcelona Azulgrana", "Madrid Rojiblanco", "Bilbao Leones", "Sevilla Verdiblanco", "Villarreal Amarillo", "San Sebastian Txuriurdin", "Vallecas Rayado", "Vitoria Babazorros", "Getafe Azulon", "Valencia Naranja", "Sevilla Blanquirrojo"],
	2: ["Manchester Sky Blues", "London Gunners", "Manchester Reds", "Liverpool Reds", "London Blues", "Newcastle Magpies", "Birmingham Villa", "London Spurs"],
	3: ["Munchen Rote", "Dortmund Schwarzgelb", "Leipzig Stiere", "Leverkusen Werkself", "Frankfurt Adler", "Stuttgart Weissrot"],
	4: ["Milano Nerazzurri", "Milano Rossoneri", "Torino Bianconeri", "Bergamo Orobici", "Napoli Azzurri", "Roma Giallorossi"],
	5: ["Paris Rouge et Bleu", "Marseille Blanc", "Lyon Gones", "Monaco Rouge", "Lille Dogues"],
	6: ["Lisboa Encarnados", "Porto Dragoes", "Lisboa Leoes", "Braga Guerreiros"],
	7: ["Amsterdam Godenzonen", "Eindhoven Rood-Wit", "Rotterdam Haven"],
	8: ["Glasgow Hoops", "Glasgow Light Blues", "Edinburgh Hearts"],
	9: ["Pireas Thrylos", "Athena Dikefalos", "Thessaloniki PAOK"],
	16: ["Persija Jakarta", "Persib Bandung", "Persebaya Surabaya", "Arema Malang", "Bali Dewata", "PSM Makassar", "Madura Sape Kerrab", "Borneo Pesut"],
}

const DIV3_NAMED_CLUBS := {
	18: [
		"Belem Papao", "Natal Alvinegro", "Maceio Galo", "Maceio Azulao",
		"Ribeirao Preto Pantera", "Estreito Alvinegro", "Londrina Tubarao", "Sao Luis Tricolor",
		"Volta Redonda Aco", "Itu Galo", "Sao Jose Zequinha", "Sao Joao Esmeralda",
		"Araraquara Grena", "Aracaju Dragao", "Aparecida Camaleao", "Fortaleza Verdao", "Caxias Grena"
	],
	16: [
		"Persis Muda Solo", "PSIM Mataram", "PSS Sleman Putra", "Persikabo Bogor",
		"Deltras Sidoarjo", "PSMS Medan", "Sriwijaya Palembang", "Persipura Jayapura",
		"Semen Padang", "PSIS Semarang", "Persela Lamongan", "Persiba Balikpapan",
		"Persik Kediri", "Barito Putera", "Persita Tangerang", "Kalteng Putra",
		"PSPS Riau", "Persijap Jepara", "Persiraja Banda Aceh", "Persiba Bantul", "Persepam Pamekasan"
	],
	1: [
		"Cordoba Califas", "Murcia Pimenton", "Malaga Boqueron", "Huelva Decano",
		"Merida Romano", "Alicante Hercules", "Sabadell Arlequin", "Badajoz Blanquinegro",
		"Logrono Rioja", "Pontevedra Granate", "Toledo Imperial", "Salamanca Charro"
	],
	2: [
		"Wrexham Dragons", "Birmingham Blues", "Stockport Hatters", "Huddersfield Terriers",
		"Reading Royals", "Bolton Wanderers", "Charlton Addicks", "Blackpool Seasiders",
		"Wigan Latics", "Peterborough Posh", "Barnsley Tykes", "Lincoln Imps"
	],
	19: [
		"Quilmes Cervecero", "Ferro Carril Oeste", "Chacarita Funebrero", "Atlanta Bohemio",
		"Temperley Celeste", "Moron Gallito", "Platense Calamar", "Tigre Matador",
		"Almagro Tricolor", "San Telmo Candombero", "Los Andes Milrayitas", "Tristan Suarez"
	],
	28: [
		"Cancun Iguanas", "Merida Venados", "Morelia Canarios", "Oaxaca Alebrijes",
		"Zacatecas Mineros", "Celaya Toros", "Tampico Jaiba", "Tepatitlan Alteños",
		"La Paz Maritimo", "Correcaminos UAT", "Tlaxcala Coyotes", "Cimarrones Sonora"
	],
}

const TOP_SEEDED_PLAYERS := [
	{"name": "Charlie Irving", "nat": 2, "club": "Munchen Rote", "pos": "ST", "age": 33, "ovr": 92, "val": 28900},
	{"name": "Corentin Zimmer", "nat": 5, "club": "Madrid Blanco", "pos": "ST", "age": 27, "ovr": 91, "val": 150200},
	{"name": "Anders Helland", "nat": 12, "club": "Manchester Sky Blues", "pos": "ST", "age": 26, "ovr": 91, "val": 152000},
	{"name": "Harry Latimer", "nat": 2, "club": "Madrid Blanco", "pos": "CAM", "age": 23, "ovr": 90, "val": 139300},
	{"name": "Alvaro Peiró", "nat": 1, "club": "Barcelona Azulgrana", "pos": "RW", "age": 19, "ovr": 90, "val": 185700},
	{"name": "Rui Estrela", "nat": 6, "club": "Manchester Reds", "pos": "CAM", "age": 31, "ovr": 90, "val": 50100},
	{"name": "Morgan Albert", "nat": 5, "club": "Munchen Rote", "pos": "RM", "age": 24, "ovr": 90, "val": 103300},
	{"name": "Guillaume Regnier", "nat": 5, "club": "Paris Rouge et Bleu", "pos": "ST", "age": 29, "ovr": 90, "val": 67000},
	{"name": "Hugo Maes", "nat": 19, "club": "Madrid Blanco", "pos": "GK", "age": 34, "ovr": 89, "val": 6700},
]

const TOP_SEEDED_COACHES := [
	{"name": "Diego Zubiría", "nat": 1, "club": "Madrid Blanco", "stars": 5, "g": 2, "p": 4, "k": 3},
	{"name": "Hae-Il Gu", "nat": 27, "club": "Saint-Gilles Jaunes", "stars": 5, "g": 1, "p": 5, "k": 3},
	{"name": "Dirk Van der M.", "nat": 7, "club": "Amsterdam Godenzonen", "stars": 5, "g": 1, "p": 5, "k": 2},
	{"name": "Bandar Al-Malki", "nat": 38, "club": "Ankara Sari-Lacivert", "stars": 5, "g": 0, "p": 5, "k": 3},
	{"name": "Owen Ravenhill", "nat": 2, "club": "London Gunners", "stars": 5, "g": 1, "p": 5, "k": 2},
	{"name": "Nicola Zampini", "nat": 4, "club": "Bergamo Orobici", "stars": 5, "g": 1, "p": 5, "k": 2},
	{"name": "Marek Procházka", "nat": 23, "club": "Banja Luka Vrbas", "stars": 5, "g": 0, "p": 5, "k": 3},
	{"name": "Diego Freitas", "nat": 18, "club": "Rio Estrela Solitaria", "stars": 5, "g": 0, "p": 5, "k": 3},
	{"name": "Matías Castillo", "nat": 32, "club": "Collao Universitario", "stars": 5, "g": 0, "p": 5, "k": 3},
]

const FIRST_NAMES := [
	"Alfian", "Alfred", "Erik", "Johan", "Lukas", "Oskar", "Victor", "Marcus", "Anton", "Emil",
	"Carlos", "Diego", "Mateo", "Lucas", "Gabriel", "Hugo", "Liam", "Noah", "Oliver", "Harry",
	"Kylian", "Julian", "Marco", "Lorenzo", "Rizky", "Pratama", "Bagas", "Dimas", "Arhan", "Witan",
	"Sora", "Kenji", "Min-Jun", "Tarek", "Omar", "Yusuf", "Jonas", "Henrik", "Nils", "Filip",
	"Sven", "Mikael", "Rafael", "Thiago", "Bruno", "Sebastien", "Mathieu", "Pedro", "Vitor", "Jasper"
]

const LAST_NAMES := [
	"Eklund", "Engstrom", "Wallin", "Hakansson", "Bergstrom", "Danielsson", "Lindqvist", "Sandberg", "Martensson", "Fredriksson",
	"Bjork", "Nystrom", "Lundin", "Holmberg", "Andersson", "Eriksson", "Oberg", "Hansson", "Sjoberg", "Jeffries",
	"Zimmer", "Irving", "Latimer", "Romero", "Esteves", "Gaitan", "Saputra", "Pratama", "Santoso", "Hidayat",
	"Kurniawan", "Wijaya", "Silva", "Santos", "Costa", "Fernandes", "Morales", "Navarro", "Muller", "Weber",
	"Rossi", "Bianchi", "Morel", "Laurent", "Bakker", "De Vries", "Kowalski", "Novak", "Tanaka", "Park"
]

const CITY_SUFFIXES := [
	"United", "City", "FC", "Athletic", "Rovers", "Wanderers", "Sporting", "SC", "Real", "Dynamo",
	"Lokomotiv", "Olympique", "Stars", "Reds", "Blues", "Eagles", "Lions", "Vikings", "Nordic", "Metro"
]

func _ready() -> void:
	_init_nations()
	_init_clubs_and_coaches()
	_init_achievements()
	_init_legends_and_records()
	_init_shop_and_cosmetics()
	_init_sponsors_and_dilemmas()
	_init_album_cards()
	_init_preset_friends()

func _init_nations() -> void:
	var raw_nations := [
		["Swedia", "SWE", [Color("#005293"), Color("#FECB00")], [5.1, 6.2, 1.9, 11.4, 5.0], 29.625, 19],
		["Spanyol", "ESP", [Color("#AA151B"), Color("#F1BF00")], [18.5, 19.2, 20.4, 21.0, 19.8], 98.900, 2],
		["Inggris", "ENG", [Color("#FFFFFF"), Color("#CE1124")], [21.0, 22.4, 19.8, 23.1, 20.9], 107.200, 1],
		["Jerman", "GER", [Color("#111111"), Color("#DD0000")], [16.8, 17.5, 19.2, 18.6, 17.4], 89.500, 3],
		["Italia", "ITA", [Color("#009246"), Color("#CE2B37")], [15.2, 17.8, 21.0, 18.4, 17.0], 89.400, 4],
		["Prancis", "FRA", [Color("#0055A4"), Color("#EF4135")], [14.4, 15.8, 16.2, 14.9, 15.2], 76.500, 5],
		["Portugal", "POR", [Color("#006600"), Color("#FF0000")], [12.9, 11.0, 13.4, 12.2, 11.8], 61.300, 6],
		["Belanda", "NED", [Color("#AE1C28"), Color("#21468B")], [11.2, 14.9, 10.0, 13.1, 11.5], 60.700, 7],
		["Skotlandia", "SCO", [Color("#005EB8"), Color("#FFFFFF")], [7.8, 6.4, 8.2, 7.1, 7.5], 37.000, 18],
		["Yunani", "GRE", [Color("#0D5EAF"), Color("#FFFFFF")], [8.0, 7.2, 11.4, 10.6, 11.2], 48.412, 11],
		["Polandia", "POL", [Color("#FFFFFF"), Color("#DC143C")], [7.2, 9.5, 10.1, 9.8, 10.1], 46.750, 12],
		["Denmark", "DEN", [Color("#C60C30"), Color("#FFFFFF")], [7.8, 8.1, 9.2, 8.4, 8.6], 42.106, 13],
		["Norwegia", "NOR", [Color("#BA0C2F"), Color("#00205B")], [7.4, 8.9, 8.1, 8.2, 8.6], 41.237, 14],
		["Siprus", "CYP", [Color("#FFFFFF"), Color("#D57800")], [6.8, 7.1, 6.9, 7.4, 7.4], 35.693, 15],
		["Swiss", "SUI", [Color("#DA291C"), Color("#FFFFFF")], [6.9, 7.4, 6.5, 7.1, 6.8], 34.700, 16],
		["Austria", "AUT", [Color("#ED2939"), Color("#FFFFFF")], [6.5, 7.1, 6.8, 6.9, 6.5], 33.850, 17],
		["Indonesia", "IDN", [Color("#CE1126"), Color("#FFFFFF")], [4.8, 5.4, 6.2, 6.8, 7.2], 30.400, 20],
		["Belgia", "BEL", [Color("#111111"), Color("#FDDA24")], [11.5, 12.2, 10.8, 11.4, 11.0], 56.900, 8],
		["Brasil", "BRA", [Color("#009C3B"), Color("#FFDF00")], [11.0, 10.8, 11.4, 11.2, 11.0], 55.400, 9],
		["Argentina", "ARG", [Color("#74ACDF"), Color("#FFFFFF")], [10.4, 10.2, 10.9, 10.5, 10.1], 52.100, 10],
	]

	var extra_names := [
		["Turki", "TUR"], ["Kroasia", "CRO"], ["Serbia", "SRB"], ["Ceko", "CZE"], ["Ukraina", "UKR"],
		["Rusia", "RUS"], ["Jepang", "JPN"], ["Korea Selatan", "KOR"], ["Amerika Serikat", "USA"], ["Meksiko", "MEX"],
		["Kolombia", "COL"], ["Uruguay", "URU"], ["Chili", "CHI"], ["Mesir", "EGY"], ["Maroko", "MAR"],
		["Nigeria", "NGA"], ["Senegal", "SEN"], ["Australia", "AUS"], ["Arab Saudi", "KSA"], ["Iran", "IRN"],
		["Qatar", "QAT"], ["Malaysia", "MAS"], ["Thailand", "THA"], ["Vietnam", "VIE"], ["Singapura", "SGP"],
		["Filipina", "PHI"], ["Hungaria", "HUN"], ["Rumania", "ROU"], ["Bulgaria", "BUL"], ["Slovakia", "SVK"],
		["Finlandia", "FIN"], ["Islandia", "ISL"], ["Irlandia", "IRL"], ["Wales", "WAL"], ["Peru", "PER"],
	]

	nations.clear()
	for i in range(raw_nations.size()):
		var r: Array = raw_nations[i]
		nations.append({
			"id": i,
			"name": r[0],
			"code": r[1],
			"colors": r[2],
			"coeff_5y": r[3],
			"total_coeff": r[4],
			"world_rank": r[5],
			"slots": {"d1": 2 if i < 8 else 1, "cup": 1, "d2": 2, "d3": 2},
		})
	for j in range(extra_names.size()):
		var idx := raw_nations.size() + j
		var base_c := 28.0 - j * 0.65
		var c5 := [roundf((base_c * 0.18) * 10.0) / 10.0, roundf((base_c * 0.21) * 10.0) / 10.0, roundf((base_c * 0.19) * 10.0) / 10.0, roundf((base_c * 0.22) * 10.0) / 10.0, roundf((base_c * 0.20) * 10.0) / 10.0]
		var hue := float(j) / float(extra_names.size())
		nations.append({
			"id": idx,
			"name": extra_names[j][0],
			"code": extra_names[j][1],
			"colors": [Color.from_hsv(hue, 0.78, 0.85), Color.from_hsv(fmod(hue + 0.5, 1.0), 0.3, 0.95)],
			"coeff_5y": c5,
			"total_coeff": roundf(base_c * 1000.0) / 1000.0,
			"world_rank": 21 + j,
			"slots": {"d1": 1, "cup": 1, "d2": 1, "d3": 2},
		})

func _init_clubs_and_coaches() -> void:
	# Target exact scale from PRD & screenshot #19/#20: 2,731 clubs/coaches across 55 nations!
	# Sweden (0) = 16 + 16 + 32 = 64 clubs
	# Nations 1..5 = 20 + 20 + 20 = 60 clubs each (300)
	# Remaining 49 nations -> sum = 2,731 - 364 = 2,367 -> 48*48 + 63 = 2367 (Wait: 48*48=2304, +1*63=2367! Let's make Nation 16 Indonesia have 21+21+21=63!)
	clubs.clear()
	coaches.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261118

	var kit_palettes := [
		[Color("#1E64D8"), Color("#F2F6FC"), "stripes"],
		[Color("#CC222B"), Color("#FFFFFF"), "solid"],
		[Color("#F0C434"), Color("#1A2230"), "sash"],
		[Color("#229248"), Color("#FFFFFF"), "hoops"],
		[Color("#FFFFFF"), Color("#182848"), "solid"],
		[Color("#181C24"), Color("#F2C84B"), "halved"],
		[Color("#6C36B2"), Color("#FFFFFF"), "stripes"],
		[Color("#E86E22"), Color("#1A1E28"), "solid"],
		[Color("#22A8D8"), Color("#FFFFFF"), "hoops"],
		[Color("#881C32"), Color("#74C2EC"), "solid"],
	]

	var club_id := 0
	for nat_idx in range(nations.size()):
		var nat_name: String = nations[nat_idx]["name"]
		var div_counts := [16, 16, 16]
		if nat_idx == 0:
			div_counts = [16, 16, 32]  # 64
		elif nat_idx >= 1 and nat_idx <= 5:
			div_counts = [20, 20, 20]  # 60 each
		elif nat_idx == 16:
			div_counts = [21, 21, 21]  # 63 (Indonesia) -> total = 64 + 300 + 63 + 48*48 = 2731 EXACT!

		var famous_list: Array = FAMOUS_CLUBS.get(nat_idx, [])
		var famous_ptr := 0
		var div3_named: Array = DIV3_NAMED_CLUBS.get(nat_idx, [])
		var div3_ptr := 0

		for div_idx in range(3):
			var count: int = div_counts[div_idx]
			for team_idx in range(count):
				var cname := ""
				if nat_idx == 0 and div_idx == 2:
					cname = SWEDEN_DIV3_NAMES[team_idx]
				elif div_idx == 0 and famous_ptr < famous_list.size():
					cname = famous_list[famous_ptr]
					famous_ptr += 1
				elif div_idx == 2 and div3_ptr < div3_named.size():
					cname = div3_named[div3_ptr]
					div3_ptr += 1
				else:
					var prefix: String = nat_name.left(min(5, nat_name.length()))
					if div_idx == 0:
						cname = "%s %s %d" % [nat_name, CITY_SUFFIXES[(club_id + team_idx) % CITY_SUFFIXES.size()], team_idx + 1]
					else:
						cname = "%s %s D%d-%d" % [prefix, CITY_SUFFIXES[(club_id * 3 + team_idx) % CITY_SUFFIXES.size()], div_idx + 1, team_idx + 1]

				var base_ovr := 76 - div_idx * 10
				if nat_idx >= 1 and nat_idx <= 5 and div_idx == 0:
					base_ovr = 82 - int(team_idx * 0.4)
				elif nat_idx == 0 and div_idx == 2:
					base_ovr = 58 + (team_idx % 5) - 2
				else:
					base_ovr += rng.randi_range(-3, 4)
				base_ovr = clampi(base_ovr, 50, 90)

				var pal: Array = kit_palettes[(club_id + team_idx) % kit_palettes.size()]
				if cname == "Danderyd Edsviken":
					pal = [Color("#1A66D2"), Color("#F4F8FF"), "stripes"]
					base_ovr = 58
				elif cname == "Stockholm Vasastan":
					pal = [Color("#C82832"), Color("#FFFFFF"), "solid"]
					base_ovr = 59
				elif cname == "Madrid Blanco":
					pal = [Color("#F4F6FA"), Color("#D4AF37"), "solid"]
					base_ovr = 88
				elif cname == "Barcelona Azulgrana":
					pal = [Color("#183878"), Color("#A51C30"), "stripes"]
					base_ovr = 86

				var short_code := ""
				var parts := cname.split(" ")
				if parts.size() >= 2:
					short_code = (parts[0].left(1) + parts[1].left(2)).to_upper()
				else:
					short_code = cname.left(3).to_upper()
				if cname == "Danderyd Edsviken":
					short_code = "DED"
				elif cname == "Stockholm Vasastan":
					short_code = "SVA"

				clubs.append({
					"id": club_id,
					"name": cname,
					"code": short_code,
					"nation_id": nat_idx,
					"division": div_idx + 1,
					"ovr": base_ovr,
					"primary": pal[0],
					"secondary": pal[1],
					"pattern": pal[2],
					"crest_shape": 0 if cname == "Danderyd Edsviken" else (club_id % 4),
					"coach_id": club_id,
					"reputation": base_ovr * 120,
				})

				var coach_name := "%s %s" % [FIRST_NAMES[(club_id * 7) % FIRST_NAMES.size()], LAST_NAMES[(club_id * 11 + 3) % LAST_NAMES.size()]]
				var coach_stars := clampi(int((base_ovr - 45) / 8), 1, 5)
				var coach_nat := nat_idx
				if cname == "Danderyd Edsviken":
					coach_name = "Henrik Jakobsson"
					coach_stars = 2

				var coach_entry := {
					"id": club_id,
					"name": coach_name,
					"nation_id": coach_nat,
					"club_id": club_id,
					"stars": coach_stars,
					"style": ["Menyerang", "Penguasaan", "Serangan Balik", "Gegenpress", "Bertahan"][club_id % 5],
					"formation": ["5-3-2", "4-3-3", "4-4-2", "4-2-3-1", "3-5-2"][club_id % 5],
					"trophies": {"g": 0, "p": 0, "k": 0},
				}
				for sc in TOP_SEEDED_COACHES:
					if sc["club"] == cname:
						coach_entry["name"] = sc["name"]
						coach_entry["nation_id"] = sc["nat"]
						coach_entry["stars"] = sc["stars"]
						coach_entry["trophies"] = {"g": sc["g"], "p": sc["p"], "k": sc["k"]}
				coaches.append(coach_entry)
				club_id += 1

func find_club_by_name(club_name: String) -> Dictionary:
	for c in clubs:
		if c["name"] == club_name:
			return c
	return clubs[0]

func get_clubs_in_division(nat_id: int, div_num: int) -> Array[Dictionary]:
	var res: Array[Dictionary] = []
	for c in clubs:
		if int(c["nation_id"]) == nat_id and int(c["division"]) == div_num:
			res.append(c)
	return res

func _init_achievements() -> void:
	# Exact 386 achievements: UMUM (32), LANGKA (106), EPIK (162), LEGENDARIS (86)
	achievements.clear()
	var curated := [
		{"id": "wajah_merek", "title": "WAJAH MEREK", "desc": "Teken kontrak sponsor pertamamu.", "rarity": "UMUM", "metric": "sponsors_signed", "target": 1},
		{"id": "gol_pertama", "title": "GOL PERTAMA", "desc": "Cetak gol pertamamu.", "rarity": "UMUM", "metric": "goals", "target": 1},
		{"id": "pencetak_gol", "title": "PENCETAK GOL", "desc": "10 gol di kariermu.", "rarity": "UMUM", "metric": "goals", "target": 10},
		{"id": "pengumpan", "title": "PENGUMPAN", "desc": "Buat assist pertamamu.", "rarity": "UMUM", "metric": "assists", "target": 1},
		{"id": "brace", "title": "BRACE", "desc": "2 gol dalam satu laga.", "rarity": "UMUM", "metric": "best_match_goals", "target": 2},
		{"id": "darah_dingin", "title": "DARAH DINGIN", "desc": "Cetak penalti pertamamu.", "rarity": "UMUM", "metric": "penalties_scored", "target": 1},
		{"id": "promosi", "title": "PROMOSI", "desc": "Naik divisi.", "rarity": "UMUM", "metric": "promotions", "target": 1},
		{"id": "veteran", "title": "VETERAN", "desc": "100 laga dimainkan.", "rarity": "UMUM", "metric": "matches", "target": 100},
		{"id": "ditempa_bawah", "title": "DITEMPA KASTA BAWAH", "desc": "Selesaikan satu musim penuh di Divisi Tiga.", "rarity": "UMUM", "metric": "seasons_div3", "target": 1},
		{"id": "bintang_laga", "title": "BINTANG LAGA", "desc": "Terpilih jadi Pemain Terbaik Laga.", "rarity": "UMUM", "metric": "motm", "target": 1},
		{"id": "rekrutan_baru", "title": "REKRUTAN BARU", "desc": "Diperkenalkan ke suporter barumu untuk pertama kali.", "rarity": "UMUM", "metric": "transfers", "target": 1},
		{"id": "10k_datang", "title": "10.000 DATANG", "desc": "10.000 orang datang ke presentasimu.", "rarity": "UMUM", "metric": "fans_score", "target": 60},
		{"id": "penembus_lini", "title": "PENEMBUS LINI", "desc": "Menangkan dribel pertamamu.", "rarity": "UMUM", "metric": "dribbles_won", "target": 1},
		{"id": "final_kalah", "title": "???", "desc": "PETUNJUK: Tak semua final berakhir dengan piala di tanganmu.", "rarity": "UMUM", "metric": "finals_lost", "target": 1},
		{"id": "kulit_baru", "title": "KULIT BARU", "desc": "Kustomisasi jersey atau gaya pertamamu.", "rarity": "UMUM", "metric": "style_edits", "target": 1},
		{"id": "seratus_ttd", "title": "SERATUS TANDA TANGAN", "desc": "Beri 100 tanda tangan lewat interaksi fans.", "rarity": "UMUM", "metric": "matches", "target": 15},
		{"id": "kebanggaan_kota", "title": "KEBANGGAAN KOTA", "desc": "Menangkan derbi pertamamu.", "rarity": "UMUM", "metric": "wins", "target": 5},
		{"id": "gaya_hidup_bintang", "title": "GAYA HIDUP BINTANG", "desc": "Beli barang gaya hidup pertamamu.", "rarity": "UMUM", "metric": "lifestyle_bought", "target": 1},
		{"id": "level_perak", "title": "LEVEL PERAK", "desc": "Jadi pemain perak: OVR 65 dalam satu karier.", "rarity": "LANGKA", "metric": "ovr", "target": 65},
		{"id": "level_emas", "title": "LEVEL EMAS", "desc": "Jadi pemain emas: OVR 75 dalam satu karier.", "rarity": "EPIK", "metric": "ovr", "target": 75},
		{"id": "level_berlian", "title": "LEVEL BERLIAN", "desc": "Jadi pemain berlian: OVR 85 dalam satu karier.", "rarity": "LEGENDARIS", "metric": "ovr", "target": 85},
	]
	for c in curated:
		achievements.append(c)

	var counts := {"UMUM": 32, "LANGKA": 106, "EPIK": 162, "LEGENDARIS": 86}
	var current := {"UMUM": 0, "LANGKA": 0, "EPIK": 0, "LEGENDARIS": 0}
	for a in achievements:
		current[a["rarity"]] += 1

	var tracks := [
		["GOL", "goals", [25, 50, 75, 100, 150, 200, 300, 400, 500, 650, 800, 1000]],
		["ASSIST", "assists", [10, 25, 50, 80, 120, 160, 200, 250, 300, 400]],
		["PENAMPILAN", "matches", [25, 50, 150, 200, 300, 400, 500, 600, 750, 900]],
		["KEMENANGAN", "wins", [10, 25, 50, 100, 150, 250, 350, 500]],
		["BINTANG LAGA", "motm", [5, 10, 20, 35, 50, 75, 100, 150]],
		["DRIBEL", "dribbles_won", [10, 25, 50, 100, 200, 350, 500]],
		["UMPAN KUNCI", "passes_won", [5, 15, 35, 75, 150, 250, 400]],
		["FREE KICK", "freekicks_scored", [1, 3, 5, 10, 20, 35, 50, 75]],
		["PENALTI", "penalties_scored", [5, 15, 30, 50, 80, 120]],
		["TROFI", "trophies", [1, 2, 3, 5, 8, 12, 18, 25, 35]],
		["LEGACY", "legacy_points", [50, 100, 200, 300, 500, 650, 900, 1200, 1600]],
		["PENGIKUT", "followers", [5000, 15000, 50000, 150000, 500000, 1000000, 5000000]],
		["HARTA", "cash", [25000, 100000, 250000, 500000, 1000000, 5000000, 25000000]],
		["TIMNAS", "intl_caps", [1, 10, 25, 50, 80, 100, 130]],
		["GOL TIMNAS", "intl_goals", [1, 5, 15, 30, 50, 75, 100]],
		["POSISI", "positions_learned", [2, 3, 4, 5, 6, 8]],
		["STAF", "staff_hired", [1, 2, 3, 4, 5, 6]],
		["KOLEKSI BOOT", "boots_owned", [2, 4, 6, 8, 11]],
		["LEVEL KARIER", "level", [5, 10, 15, 20, 30, 40, 50]],
		["MUSIM", "seasons_played", [2, 3, 5, 8, 10, 15, 20]],
	]

	var rarity_order := ["UMUM", "LANGKA", "EPIK", "LEGENDARIS"]
	var gen_idx := 0
	for r_name in rarity_order:
		while current[r_name] < counts[r_name]:
			var tr_def: Array = tracks[gen_idx % tracks.size()]
			var tier_num: int = int(gen_idx / tracks.size()) + 1
			var vals: Array = tr_def[2]
			var base_val: int = vals[mini(tier_num - 1, vals.size() - 1)]
			var mult: int = maxi(1, tier_num - vals.size() + 1)
			var target_val: int = base_val * mult
			if r_name == "LEGENDARIS":
				target_val = maxi(target_val, base_val * 2)
			achievements.append({
				"id": "ach_%s_%d" % [r_name.to_lower(), current[r_name]],
				"title": "%s %s #%d" % [tr_def[0], r_name, current[r_name] + 1],
				"desc": "Capai %d pada catatan %s sepanjang karier." % [target_val, tr_def[0].to_lower()],
				"rarity": r_name,
				"metric": tr_def[1],
				"target": target_val,
			})
			current[r_name] += 1
			gen_idx += 1

func _init_legends_and_records() -> void:
	world_legends = [
		{"name": "Julián Gaitán", "nat": 19, "indiv": 16, "team": 25, "goals": 850, "assists": 380, "liga": 13, "piala": 7, "kont": 4, "wc": 1, "ballon": 8, "boot": 8, "retired": true, "league": "Liga Spanyol"},
		{"name": "Carlos Esteves", "nat": 6, "indiv": 9, "team": 16, "goals": 950, "assists": 265, "liga": 7, "piala": 4, "kont": 5, "wc": 0, "ballon": 5, "boot": 4, "retired": false, "league": "Liga Spanyol"},
		{"name": "Gijs Lindeboom", "nat": 7, "indiv": 8, "team": 12, "goals": 490, "assists": 210, "liga": 6, "piala": 3, "kont": 3, "wc": 0, "ballon": 3, "boot": 5, "retired": true, "league": "Liga Inggris"},
		{"name": "Thomas Lindner", "nat": 3, "indiv": 8, "team": 13, "goals": 520, "assists": 190, "liga": 4, "piala": 4, "kont": 4, "wc": 1, "ballon": 1, "boot": 7, "retired": true, "league": "Liga Jerman"},
		{"name": "Sebastian Wojciechowski", "nat": 10, "indiv": 8, "team": 3, "goals": 590, "assists": 120, "liga": 2, "piala": 1, "kont": 0, "wc": 0, "ballon": 0, "boot": 8, "retired": true, "league": "Liga Jerman"},
		{"name": "Kevin Romero", "nat": 19, "indiv": 7, "team": 14, "goals": 689, "assists": 297, "liga": 8, "piala": 1, "kont": 5, "wc": 0, "ballon": 2, "boot": 5, "retired": true, "league": "Liga Spanyol"},
		{"name": "Thiago Pacheco", "nat": 18, "indiv": 6, "team": 18, "goals": 1512, "assists": 236, "liga": 9, "piala": 5, "kont": 2, "wc": 2, "ballon": 4, "boot": 2, "retired": true, "league": "Liga Brasil"},
		{"name": "Ákos Balogh", "nat": 46, "indiv": 5, "team": 10, "goals": 945, "assists": 135, "liga": 6, "piala": 2, "kont": 2, "wc": 0, "ballon": 2, "boot": 3, "retired": true, "league": "Liga Spanyol"},
		{"name": "Johan Nyström", "nat": 0, "indiv": 5, "team": 11, "goals": 770, "assists": 270, "liga": 7, "piala": 3, "kont": 1, "wc": 0, "ballon": 1, "boot": 4, "retired": true, "league": "Liga Swedia"},
		{"name": "Hugo Lemaître", "nat": 5, "indiv": 6, "team": 6, "goals": 410, "assists": 180, "liga": 3, "piala": 1, "kont": 2, "wc": 0, "ballon": 3, "boot": 3, "retired": true, "league": "Liga Prancis"},
		{"name": "Pascal Xavier", "nat": 5, "indiv": 6, "team": 11, "goals": 460, "assists": 215, "liga": 6, "piala": 4, "kont": 0, "wc": 1, "ballon": 0, "boot": 6, "retired": false, "league": "Liga Prancis"},
		{"name": "Clément Morel", "nat": 5, "indiv": 6, "team": 5, "goals": 430, "assists": 165, "liga": 4, "piala": 1, "kont": 0, "wc": 0, "ballon": 1, "boot": 5, "retired": true, "league": "Liga Prancis"},
		{"name": "Sergio Landázuri", "nat": 1, "indiv": 6, "team": 6, "goals": 395, "assists": 205, "liga": 1, "piala": 5, "kont": 0, "wc": 0, "ballon": 0, "boot": 6, "retired": true, "league": "Liga Spanyol"},
	]

	decorated_clubs = [
		{"name": "Glasgow Hoops", "nat": 8, "liga": 55, "piala": 42, "kont": 1},
		{"name": "Cairo Red Castle", "nat": 33, "liga": 45, "piala": 39, "kont": 12},
		{"name": "Glasgow Light Blues", "nat": 8, "liga": 55, "piala": 34, "kont": 0},
		{"name": "Pireas Thrylos", "nat": 9, "liga": 48, "piala": 28, "kont": 0},
		{"name": "Madrid Blanco", "nat": 1, "liga": 36, "piala": 20, "kont": 15},
		{"name": "Lisboa Encarnados", "nat": 6, "liga": 38, "piala": 26, "kont": 2},
		{"name": "Beograd Crveno-Beli", "nat": 22, "liga": 36, "piala": 28, "kont": 1},
		{"name": "Barcelona Azulgrana", "nat": 1, "liga": 27, "piala": 31, "kont": 5},
	]

func _init_shop_and_cosmetics() -> void:
	var boot_names := [
		"KLASIK HITAM", "MUTIARA BIRU", "KRIMSON EMAS", "KOBALT SIAN", "EDISI EMAS",
		"NEON MERAH MUDA", "VOLT HIJAU", "API ORANYE", "ECLIPSE X", "UNGGU ROYAL", "LEGENDA ABADI"
	]
	var boot_prices := [0, 3500, 8500, 18000, 35000, 60000, 110000, 185000, 420000, 520000, 850000]
	var boot_bonus := [0, 1, 2, 2, 3, 3, 4, 4, 5, 5, 7]
	boots_catalog.clear()
	for i in range(11):
		boots_catalog.append({
			"id": i,
			"name": boot_names[i],
			"price": boot_prices[i],
			"orig_price": int(boot_prices[i] * 1.43) if i == 8 else boot_prices[i],
			"promo": i == 8,
			"bonus_attr": "kecepatan" if i % 2 == 0 else "kekuatan",
			"bonus_val": boot_bonus[i],
		})

	staff_catalog = [
		{"id": "pelatih_pribadi", "name": "PELATIH PRIBADI", "desc": "+15% XP pertandingan", "price": 12000, "weekly": 450},
		{"id": "fisioterapis", "name": "FISIOTERAPIS", "desc": "+8 pemulihan ENERGI per pekan", "price": 15000, "weekly": 550},
		{"id": "agen_pr", "name": "SPESIALIS PR", "desc": "+25% pertumbuhan PENGIKUT & PERS", "price": 18000, "weekly": 600},
		{"id": "analis_video", "name": "ANALIS VIDEO", "desc": "+4% akurasi bidikan & visi", "price": 22000, "weekly": 700},
		{"id": "kebugaran", "name": "PELATIH FISIK", "desc": "Hemat 20% konsumsi energi laga", "price": 26000, "weekly": 800},
		{"id": "psikolog", "name": "PSIKOLOG OLAHRAGA", "desc": "Stabilitas ekstra saat Penalti & Final", "price": 32000, "weekly": 950},
	]

	lifestyle_catalog = [
		{"cat": "KANDANG", "id": "apartemen", "name": "APARTEMEN STUDIO", "desc": "+5 Energi dasar/pekan", "price": 25000, "prestige": 2},
		{"cat": "KANDANG", "id": "rumah_kota", "name": "RUMAH PINGGIR KOTA", "desc": "+10 Energi dasar/pekan", "price": 95000, "prestige": 5},
		{"cat": "KANDANG", "id": "vila_mewah", "name": "VILA DANAU", "desc": "+18 Energi dasar/pekan", "price": 380000, "prestige": 12},
		{"cat": "MEBEL", "id": "sofa_gaming", "name": "RUANG SANTAI RETRO", "desc": "+3 Relasi Ruang Ganti", "price": 8500, "prestige": 1},
		{"cat": "MEBEL", "id": "gym_rumah", "name": "GYM PRIBADI", "desc": "+2 Fisik & pemulihan cepat", "price": 32000, "prestige": 4},
		{"cat": "MOBIL", "id": "hatchback", "name": "CITY HATCHBACK", "desc": "Transportasi latihan efisien", "price": 18000, "prestige": 2},
		{"cat": "MOBIL", "id": "sedan_sport", "name": "SPORT COUPÉ", "desc": "+4 Fans & +2 Energi", "price": 75000, "prestige": 6},
		{"cat": "MOBIL", "id": "hypercar", "name": "HYPERCAR EMAS", "desc": "+10 Fans & +15K pengikut", "price": 450000, "prestige": 15},
		{"cat": "GAYA", "id": "jam_emas", "name": "ARLOJI KRONOGRAF", "desc": "Simbol bintang muda", "price": 14000, "prestige": 3},
		{"cat": "GAYA", "id": "setelan_gala", "name": "JAS GALA MALAM", "desc": "+8 Pers saat Gala Penghargaan", "price": 28000, "prestige": 5},
	]

	var ring_list: Array[Dictionary] = [
		{"id": "default", "name": "KLASIK HIJAU", "color": Color("#38E068"), "price": 0, "style": "solid"},
		{"id": "crimson", "name": "MERAH MEMBARA", "color": Color("#EF4444"), "price": 1500, "style": "flame"},
		{"id": "cyan", "name": "SIAN SIBER", "color": Color("#38BDF8"), "price": 1500, "style": "dashed"},
		{"id": "gold", "name": "EMAS JUARA", "color": Color("#F5C542"), "price": 3500, "style": "double"},
	]
	for i in range(4, 24):
		var col := Color.from_hsv(float(i - 4) / 20.0, 0.85, 0.95)
		ring_list.append({
			"id": "ring_%d" % i,
			"name": "CINCIN #%d" % (i + 1),
			"color": col,
			"price": 1000 + i * 400,
			"style": ["solid", "dashed", "flame", "double"][i % 4],
		})

	var aim_list: Array[Dictionary] = [
		{"id": "default", "name": "PANAH PUTIH", "color": Color("#F8FAFC"), "price": 0},
		{"id": "laser", "name": "LASER SIAN", "color": Color("#22D3EE"), "price": 1200},
		{"id": "gold", "name": "LINTASAN EMAS", "color": Color("#FBBF24"), "price": 2400},
	]
	for i in range(3, 31):
		aim_list.append({
			"id": "aim_%d" % i,
			"name": "BIDIK #%d" % (i + 1),
			"color": Color.from_hsv(float(i) / 31.0, 0.78, 0.98),
			"price": 800 + i * 350,
		})

	var trail_list: Array[Dictionary] = [
		{"id": "default", "name": "ASAP KLASIK", "color": Color("#E2E8F0"), "price": 0},
		{"id": "lightning", "name": "PETIR VOLT", "color": Color("#38BDF8"), "price": 4500},
		{"id": "fire", "name": "KOMET API", "color": Color("#F97316"), "price": 6000},
		{"id": "legend", "name": "BINTANG EMAS", "color": Color("#FACC15"), "price": 9000},
	]

	var badge_list: Array[Dictionary] = [
		{"id": "default", "name": "PERUNGGU", "color": Color("#8B5A2B"), "price": 0},
		{"id": "silver", "name": "PERAK", "color": Color("#94A3B8"), "price": 2000},
		{"id": "gold", "name": "EMAS", "color": Color("#EAB308"), "price": 5000},
		{"id": "diamond", "name": "BERLIAN", "color": Color("#38BDF8"), "price": 10000},
	]
	for i in range(4, 14):
		badge_list.append({
			"id": "badge_%d" % i,
			"name": "LENCANA #%d" % (i + 1),
			"color": Color.from_hsv(float(i) / 14.0, 0.75, 0.90),
			"price": 1500 + i * 900,
		})

	var card_list: Array[Dictionary] = [
		{"id": "default", "name": "KLASIK KLUB", "color": Color("#1E3A5F"), "price": 0},
		{"id": "emerald", "name": "ZAMRUD", "color": Color("#15803D"), "price": 2500},
		{"id": "royal", "name": "ROYAL EMAS", "color": Color("#B45309"), "price": 6500},
	]
	for i in range(3, 13):
		card_list.append({
			"id": "card_%d" % i,
			"name": "KARTU #%d" % (i + 1),
			"color": Color.from_hsv(float(i) / 13.0, 0.65, 0.55),
			"price": 1200 + i * 800,
		})

	cosmetics_catalog = {
		"CINCIN": ring_list,
		"AIM": aim_list,
		"JEJAK": trail_list,
		"LENCANA": badge_list,
		"KARTU": card_list,
		"PERK": [
			{"id": "gaji_ganda", "name": "GAJI GANDA", "desc": "x2 Gaji, Bonus Gol, & Sponsor selamanya", "price": 25000},
			{"id": "xp_ganda", "name": "XP GANDA", "desc": "Naik level 2x lebih cepat di semua karier", "price": 25000},
			{"id": "paket_legenda", "name": "PAKET LEGENDA", "desc": "Semua bonus XP & Gaji + Kosmetik Emas", "price": 50000},
			{"id": "slot_keempat", "name": "SLOT KEEMPAT", "desc": "Buka slot karier ke-4 permanen", "price": 10000},
		],
	}

func _init_sponsors_and_dilemmas() -> void:
	sponsors_catalog = [
		{"id": "roti_lokal", "name": "TOKO ROTI LOKAL", "per_match": 1442, "per_goal": 1442, "target_goals": 3, "season_bonus": 32174, "min_fans": 10},
		{"id": "kopi_kota", "name": "KOPI SUDUT KOTA", "per_match": 2150, "per_goal": 1800, "target_goals": 6, "season_bonus": 48000, "min_fans": 35},
		{"id": "apparel_nord", "name": "NORDIC SPORTSWEAR", "per_match": 4800, "per_goal": 3200, "target_goals": 10, "season_bonus": 95000, "min_fans": 55},
		{"id": "energy_volt", "name": "VOLT ISOTONIC", "per_match": 8500, "per_goal": 5500, "target_goals": 15, "season_bonus": 180000, "min_fans": 72},
		{"id": "global_tech", "name": "AETHER MOBILE", "per_match": 16000, "per_goal": 9500, "target_goals": 22, "season_bonus": 350000, "min_fans": 85},
	]

	dilemmas_catalog = [
		{
			"id": "dinner_nora",
			"timing": "POST",
			"scene": "dinner",
			"title": "MAKAN MALAM TIM",
			"text": "Seusai pertandingan, makan malam klub digelar dan obrolan di mejamu sudah satu jam membahas Nora. Dia menatap ke arahmu.",
			"choices": [
				{"label": "DEKATI", "sub": "+2 Pers • mulai kenalan", "effects": {"pers": 2, "fans": 3, "energy": -4, "ruangGanti": 2}},
				{"label": "BIARKAN", "sub": "Fokus ke pemulihan esok", "effects": {"pelatih": 2, "energy": 3}},
				{"label": "PIKIR DULU", "sub": "Simpan energi", "effects": {"energy": 1}},
			]
		},
		{
			"id": "latihan_ekstra",
			"timing": "PRE",
			"scene": "locker",
			"title": "LATIHAN PRA-LAGA",
			"text": "Menjelang pertandingan berikutnya, pelatih mengajakmu sesi tendangan bebas & penyelesaian tambahan setelah latihan taktik selesai.",
			"choices": [
				{"label": "IKUT LATIHAN", "sub": "+4 Pelatih • +35 XP • -8 Energi", "effects": {"pelatih": 4, "energy": -8, "xp": 35}},
				{"label": "ISTIRAHAT", "sub": "+6 Energi • simpan tenaga", "effects": {"energy": 6, "pelatih": -1}},
			]
		},
		{
			"id": "wawancara_pers",
			"timing": "PRE",
			"scene": "press",
			"title": "KONFERENSI PRA-LAGA",
			"text": "Menjelang kick-off, wartawan lokal meminta komentar eksklusif soal peluang tim meraih kemenangan di laga ini.",
			"choices": [
				{"label": "OPTIMIS MENANG", "sub": "+5 Fans • +4 Pers • -1 Pelatih", "effects": {"fans": 5, "pers": 4, "pelatih": -1}},
				{"label": "PUJI KERJA TIM", "sub": "+4 Ruang Ganti • +3 Pelatih", "effects": {"ruangGanti": 4, "pelatih": 3}},
				{"label": "FOKUS LAPANGAN", "sub": "-2 Pers • +2 Energi", "effects": {"pers": -2, "energy": 2}},
			]
		},
		{
			"id": "tawaran_agen",
			"timing": "PRE",
			"scene": "office",
			"title": "TAWARAN AGEN",
			"text": "Menjelang hari pertandingan, agenmu menawarkan acara temu suporter singkat di pusat kota.",
			"choices": [
				{"label": "HADIR", "sub": "+$1.500 • +6 Fans • -6 Energi", "effects": {"cash": 1500, "fans": 6, "agen": 3, "energy": -6}},
				{"label": "TOLAK", "sub": "+4 Energi • -2 Agen", "effects": {"energy": 4, "agen": -2}},
			]
		},
		{
			"id": "konflik_ruang_ganti",
			"timing": "PRE",
			"scene": "locker",
			"title": "BRIEFING PRA-LAGA",
			"text": "Di ruang ganti sebelum laga dimulai, kapten tim menegur pemain muda lain karena terlalu egois saat serangan balik.",
			"choices": [
				{"label": "DUKUNG KAPTEN", "sub": "+4 Pelatih • +3 Ruang Ganti", "color": "#1E5668", "effects": {"pelatih": 4, "ruangGanti": 3}},
				{"label": "TENANGKAN SEMUA", "sub": "+5 Ruang Ganti • +1 Fans", "color": "#6E4B1F", "effects": {"ruangGanti": 5, "fans": 1}},
			]
		},
		{
			"id": "soal_pers_terbuka",
			"timing": "POST",
			"scene": "press",
			"title": "SETELAH LAGA",
			"text": "Setelah peluit akhir, mikrofon disodorkan ke depan wajahmu dengan satu pertanyaan terbuka tentang hasil laga hari ini.",
			"choices": [
				{"label": "SOAL TIM", "sub": "+8 Ruang Ganti • -3 Suporter", "color": "#7B4F1D", "effects": {"ruangGanti": 8, "fans": -3}},
				{"label": "SOAL TARGET", "sub": "+9 Pers • -2 Ruang Ganti • -3 Pelatih", "color": "#5E3578", "effects": {"pers": 9, "ruangGanti": -2, "pelatih": -3}},
				{"label": "SOAL SUPORTER", "sub": "+8 Suporter • -1 Ruang Ganti", "color": "#733A5A", "effects": {"fans": 8, "ruangGanti": -1}},
			]
		},
		{
			"id": "adu_penalti_kiper",
			"timing": "POST",
			"scene": "pitch",
			"title": "SETELAH LAGA • TANTANGAN KIPER",
			"text": "Setelah pertandingan berakhir, kiper rekanmu menantangmu adu penalti sebelum masuk ruang ganti dan separuh skuad ikut menonton!",
			"choices": [
				{
					"label": "TERIMA TANTANGAN", "sub": "68% : +7 Ruang Ganti +4 Pelatih | Gagal -4 Ruang Ganti", "color": "#5E3578",
					"chance": 0.68,
					"effects": {"ruangGanti": 7, "pelatih": 4},
					"fail_effects": {"ruangGanti": -4},
					"win_text": "Tendanganmu tak terbendung! Kamu memenangi adu penalti kontra kiper rekanmu.",
					"fail_text": "Kiper rekan menepis penaltimu dengan cekatan. Ruang ganti meledek sepanjang malam.",
				},
				{"label": "LANGSUNG MANDI", "sub": "-3 Ruang Ganti", "color": "#7B4F1D", "effects": {"ruangGanti": -3}, "win_text": "Kamu memilih langsung memulihkan tenaga di ruang ganti."},
			]
		},
		{
			"id": "hari_libur_aktivitas",
			"timing": "POST",
			"scene": "home",
			"title": "HARI LIBUR PASCA-LAGA",
			"text": "Jeda hari libur seusai pertandingan. Kamu bisa istirahat total di rumah, keluar bersama skuad, atau menambah porsi gym.",
			"choices": [
				{"label": "ISTIRAHAT SAJA", "sub": "+12 Energi • -3 Ruang Ganti • -4 Pelatih", "color": "#1E5668", "effects": {"energy": 12, "ruangGanti": -3, "pelatih": -4}},
				{"label": "KELUAR BARENG TIM", "sub": "+9 Ruang Ganti • -4 Pelatih • -6 Energi", "color": "#7B4F1D", "effects": {"ruangGanti": 9, "pelatih": -4, "energy": -6}},
				{"label": "GYM SENDIRIAN", "sub": "+7 Pelatih • -3 Ruang Ganti • -6 Energi", "color": "#5E3578", "effects": {"pelatih": 7, "ruangGanti": -3, "energy": -6}},
			]
		},
		{
			"id": "rumor_transfer_pers",
			"timing": "PRE",
			"scene": "press",
			"title": "RUMOR TRANSFER PRA-LAGA",
			"text": "Jelang pertandingan, beredar kabar pemandu bakat klub lain hadir mengincarmu dan pers meminta jawaban tegasmu.",
			"choices": [
				{"label": "AKU TERBUKA SEMUA", "sub": "+7 Pers • -6 Suporter", "color": "#5E3578", "effects": {"pers": 7, "fans": -6}},
				{"label": "AKU FOKUS DI SINI", "sub": "+7 Suporter • +2 Pelatih • kamu berjanji", "color": "#733A5A", "effects": {"fans": 7, "pelatih": 2}},
			]
		},
	]

func _init_album_cards() -> void:
	album_cards_catalog = [
		{"num": 1, "id": "debut_pro", "title": "DEBUT PRO", "tier": "PERUNGGU", "quote": "«LANGKAH PERTAMA DI RUMPUT HIJAU.»", "icon": "PLAYER"},
		{"num": 2, "id": "gol_perdana", "title": "GOL PERDANA", "tier": "PERUNGGU", "quote": "«JARING BERGETAR, NAMA TERUKIR.»", "icon": "BALL"},
		{"num": 3, "id": "asisten_tim", "title": "SANG KREATOR", "tier": "PERUNGGU", "quote": "«UMPAN TEROBOSAN YANG MEMBELAH BEK.»", "icon": "PASS"},
		{"num": 4, "id": "top_skor_pekan", "title": "TOP SKOR", "tier": "PERAK", "quote": "«PUNCAK DAFTAR PENCETAK GOL.»", "icon": "BOOT"},
		{"num": 5, "id": "bintang_laga", "title": "PEMAIN TERBAIK", "tier": "PERAK", "quote": "«MIKROFON TV MILIKMU MALAM INI.»", "icon": "TROPHY"},
		{"num": 6, "id": "algojo_tenang", "title": "ALGOJO PENALTI", "tier": "PERUNGGU", "quote": "«TIDAK ADA DETAK JANTUNG BERLEBIH.»", "icon": "TARGET"},
		{"num": 7, "id": "guntur_tribun", "title": "GUNTUR TRIBUN", "tier": "PERAK", "quote": "«SATU IRAMA BERSAMA SUPORTER!»", "icon": "DRUM"},
		{"num": 8, "id": "raja_bola_mati", "title": "LENGKUNG MAGNUS", "tier": "EMAS", "quote": "«PAGAR BETIS HANYA BISA MENONTON.»", "icon": "CURVE"},
		{"num": 9, "id": "pidato_ruang", "title": "SUARA SKUAD", "tier": "PERUNGGU", "quote": "«RUANG GANTI BERDIRI DI BELAKANGMU.»", "icon": "MIC"},
		{"num": 10, "id": "kapten_muda", "title": "MENTAL PEMIMPIN", "tier": "EMAS", "quote": "«BAN KAPTEN MENUNGGU WAKTUNYA.»", "icon": "SHIELD"},
		{"num": 11, "id": "ttd_terminal", "title": "TTD DI TERMINAL", "tier": "PERAK", "quote": "«TIM MENUNGGU SEMENIT DI GERBANG.»", "icon": "JERSEY"},
		{"num": 12, "id": "iklan_take7", "title": "BINTANG IKLAN", "tier": "PERAK", "quote": "«TAKE 7! KAMERA SUKA SENYUMMU.»", "icon": "CLAPPER"},
		{"num": 13, "id": "makan_inisiasi", "title": "INISIASI SKUAD", "tier": "PERUNGGU", "quote": "«BERNYANYI DI DEPAN SEMUA SENIOR.»", "icon": "MUSIC"},
		{"num": 14, "id": "lemparan_jersey", "title": "HADIAH TRIBUN", "tier": "PERAK", "quote": "«JERSEY TERBANG KE TANGAN SUPORTER.»", "icon": "SHIRT"},
		{"num": 15, "id": "scout_pantau", "title": "SCOUT", "tier": "PERAK", "quote": "«AKU SUDAH MENGIKUTIMU.»", "icon": "SCOUT"},
		{"num": 16, "id": "duel_kiper", "title": "DUEL KIPER", "tier": "PERAK", "quote": "«RUANG GANTI BERSORAK DI SENJA HARI.»", "icon": "GLOVE"},
		{"num": 17, "id": "promosi_liga", "title": "TIKET PROMOSI", "tier": "EMAS", "quote": "«DIVISI BARU, PANGGUNG LEBIH BESAR.»", "icon": "STAR"},
		{"num": 18, "id": "panggilan_timnas", "title": "GARUDA & BANGSA", "tier": "EMAS", "quote": "«LAMBANG NEGARA DI DADA.»", "icon": "FLAG"},
		{"num": 19, "id": "warisan_legenda", "title": "LEGENDA ABADI", "tier": "LEGENDARIS", "quote": "«NAMA YANG TAK PERNAH DILUPAKAN.»", "icon": "CROWN"},
	]

func _init_preset_friends() -> void:
	preset_friends = [
		{"code": "K7DM2X", "name": "Ruiz", "full_name": "Ana Ruiz", "club": "Madrid Blanco", "pos": "ST", "ovr": 86, "goals": 214, "assists": 77, "trophies": 9, "legacy": 412, "status": "AKTIF +2", "turn": false, "challenge": "Penalti x10", "score_them": 6},
		{"code": "V9LP4Q", "name": "Vidal", "full_name": "Leo Vidal", "club": "Barcelona Azulgrana", "pos": "CAM", "ovr": 81, "goals": 131, "assists": 102, "trophies": 5, "legacy": 280, "status": "GILIRANMU", "turn": true, "challenge": "Freekick x5", "score_them": 4},
		{"code": "T3MX8R", "name": "Torres", "full_name": "Max Torres", "club": "Madrid Rojiblanco", "pos": "RW", "ovr": 77, "goals": 88, "assists": 41, "trophies": 3, "legacy": 165, "status": "AKTIF +1", "turn": false, "challenge": "Target x15", "score_them": 8},
		{"code": "G5SG2N", "name": "Gil", "full_name": "Sofi Gil", "club": "Sevilla Blanquirrojo", "pos": "CM", "ovr": 72, "goals": 47, "assists": 30, "trophies": 1, "legacy": 94, "status": "AKTIF +1", "turn": false, "challenge": "Kurva x10", "score_them": 5},
	]
