# Football Unity

Technical and design documentation for **Football Unity**, an offline-first single-player football career simulation game built with **Godot Engine 4.7** (`GL Compatibility`) that combines a deep global football database with 2.5D/3D match action featuring slingshot shooting, dynamic passing, and a circular analog dribble control scheme.

## Project Information

| Attribute | Details |
| --- | --- |
| **Title** | Football Unity |
| **Genre** | Single-Player Offline Football Career Simulation & 2.5D Action |
| **Engine** | Godot Engine 4.7 (`GL Compatibility`) |
| **Target Display** | Landscape `960x540` (`canvas_items`, aspect `keep`, orientation locked to landscape) |
| **Platforms** | PC (Windows) & Mobile (Android / iOS Landscape) |
| **Storage Model** | Offline-First, compressed binary save slots (`< 5 MB` per slot) |

---

## 1. Vision & Core Gameplay Loop

### 1.1 Core Concept

Football Unity pairs a multi-division career progression system with hands-on key moments inside a stylized pixel-art 3D stadium. You start at age 16 (`OVR 60`, Level 1, initial balance `$5,000`) at a lower-division club, manage training, energy, relationships, lifestyle, and sponsors, and directly decide matches during pivotal on-pitch moments.

### 1.2 Weekly Loop

1. **Career Creation (`NewCareerModal`)**: Customize your player's position, appearance (hairstyles, beards, casual/gala outfits, tattoos, boots, accessories), choose from starter offers or browse Division 3 clubs across 55 nations, and select one of 4 difficulty modes (`MUDAH`, `NORMAL`, `SULIT`, `EKSTREM`).
2. **Weekly Preparation (`KINI` & `PEMAINKU`)**: Review upcoming fixtures and win/draw/loss odds, allocate earned skill points across attributes or learn secondary positions, resolve weekly dilemmas, and train in side modes (`VolleyMinigame`, `CityScene`, Practice).
3. **Match Engine (`MatchScene`)**: Watch matches unfold on the 2D live commentary board with tactics and speed controls, seamlessly cutting into the 3D stadium for key moments: open-play shooting (`TEMBAK`), movement-aware passing (`UMPAN`), 1v1 circular analog dribbling (`DRIBEL`), free kicks, penalties, teammate penalties (`TEAMMATE_PENALTY_WAIT`), and live rebound scrambles (`REBOUND_SCRAMBLE`).
4. **Post-Match Review (`PostMatchOverlay`)**: Inspect final scores, Man of the Match spotlight, match ratings, XP/cash rewards, broadcast studio replay highlights (`Moviola`), post-match press interviews, and full matchday league results (`HASIL`).
5. **World Progression (`TIMKU`, `DUNIA`, `WARISAN`)**: Climb leagues and cups across seasons, track global player/coach/country rankings, unlock achievements, and view shot telemetry maps (`PETA TEMBAKAN`).

---

## 2. UI Architecture & Navigation

### 2.1 Home Screen (`HomeScreen`)

Displayed on a `960x540` two-column landscape layout:
- **Left Column**: 3-slot career carousel (`Slot 1..3`) with player summary cards, `LANJUTKAN` / `RUMAH` shortcuts, or `+ KARIER BARU`.
- **Right Column**: Quick launchers (`LATIHAN` practice picker, `TEMAN` social comparison, `KOLEKSI` achievement browser), plus the `TOKO KOSMETIK & PERK` preview card, language toggle (`ID`/`EN`), settings, and club database editor.

### 2.2 Persistent Career HUD (`CareerShell`)

Top status bar across career tabs:
- **Identity & Progress**: OVR badge, player name, age, career level, current year/week (`THN 1 - MGG 1/45`), league position, and cash balance.
- **20-Segment Energy Bar**: Tracks fitness status (`SEGAR` / `LELAH` / `KRITIS`) with an info popup explaining squad thresholds (`< 30` unavailable, `< 45` bench, `45-100` starter).
- **Bottom Navigation Bar**: Switches between `KINI`, `PEMAINKU`, `TIMKU`, `DUNIA`, and `WARISAN`.

---

## 3. Functional Systems

### FR-01: Match Engine, Slingshot Physics & Dribble Controls (`MatchScene`, `SlingshotPhysics`)

- **3D Pixel-Art Stadium**: Nearest-filtered textures (`default_texture_filter=0`), striped grass turf, goals/nets, LED perimeter boards, crowd stands, billboarded pixel sprites, and dynamic stadium camera modes.
- **Slingshot Shooting & Spin (`TEMBAK`, Free Kicks, Penalties)**:
  - Drag-and-release vector from the pitch controls initial shot speed and loft bounded by `Kekuatan` and `Akurasi`.
  - Bottom-right `EFEK` ball pad applies Magnus curve to bend shots around defenders and walls:
    $$\vec{F}_{\text{magnus}} = S(\text{Efek}) \cdot (\vec{\omega} \times \vec{v})$$
- **Circular Analog Dribble Cursor (`DRIBEL` / `DribbleJoystickPad`)**:
  - Bottom-left translucent circular joystick pad with directional ticks, active glow ring, directional arc, and thumbstick puck for 360-degree touch/mouse dribbling (also supports keyboard `WASD`/Arrow keys).
  - Bottom-right `LARI / TRIK` button triggers a burst/evasion move, and `TEMBAK!` switches directly into the slingshot shot state (auto-converting when beating the primary defender).
- **Dynamic Passing & Living AI**:
  - Moving teammates create dynamic `UMPAN` target rings based on their runs and openness; teammate penalties (`TEAMMATE_PENALTY_WAIT`) and deflected shots trigger active `REBOUND_SCRAMBLE` sequences with attacking teammates and defending markers.
- **Mid-Match Pause & Settings (`II` -> `JEDA > SETELAN`)**: Switch difficulty or camera mode without leaving the active match.

### FR-02: Weekly Hub, Dilemmas & Cutscenes (`KiniTab`, `DilemmaModal`, `EventCutsceneModal`)

- **`KINI` Hub**: Two-column matchday view featuring club crests, 11v11 squad preview, probability bar, `MAIN LAGA` / `SIM` actions, weekly dilemma trigger, and upcoming 3-week fixtures.
- **Cutscene System (`EventCutsceneModal`, Modes `0..8`)**: Includes transfer window reports, starting XI whiteboard (`TIM INTI`), new-player locker speech (`PIDATO`), first team dinner & singing timing minigame (`MAKAN_NYANYI`), `SPONSOR TAKE 7` clapperboard signing & selfie Polaroid, coach trait/rejection events, pre-match stadium tunnel hype, and animated MVP celebration.

### FR-03: Player Progression & Style (`PemainkuTab`, `CharacterStyleCatalog`)

- **10 Core Attributes (1-99)**: `Kekuatan`, `Akurasi`, `Efek`, `Visi`, `Fisik`, `Kecepatan`, `Akselerasi`, `Dribel`, `Penalti`, `Bola mati`. Earning levels grants 3 Skill Points (`+3 SP` per level); learning secondary positions costs `6 SP`.
- **Visual Customization**: 16 hairstyles, 8 beard styles, multiple skin tones & hair highlights, eyewear, headwear, face/arm/leg tattoos, sleeve lengths, boots, 5 casual outfits, and 5 gala suits rendered live via `PixelAvatar`.

### FR-04: Squad, World Database, City 3D & Legacy

- **World Scale (`GameData`)**: Procedurally generates and simulates **55 nations**, **2,731 clubs**, **2,731 coaches**, and **21,289 players**, plus **386 achievements** across 4 rarity tiers (`UMUM`: 32, `LANGKA`: 106, `EPIK`: 162, `LEGENDARIS`: 86).
- **Cosmetics & Shop (`CosmeticsShopModal`)**: `11` boot models, `24` ground rings, `31` aim arrows, `4` ball trails, `14` badge frames, and `13` profile card frames.
- **Side Modes**: `VolleyMinigame` (`KONTROL DAN VOLI` timing challenge) and `CityScene` (3D neighborhood exploration between `SNEAKERS`, `APARTEMEN`, and `STADION`).
- **Records & Telemetry (`WarisanTab`)**: Trophy cabinet, club records, awards, legend progression, and interactive 2D goal/pitch `PETA TEMBAKAN` replay triggers.

---

## 4. Save Data Architecture (`CareerState`)

Career progress is stored locally in `user://saves/slot_<1..3>.dat` as compressed data (`< 5 MB` per slot) containing career metadata (`year`, `week`, `maxWeeks`, `legacyPoints`), player profile (position mastery, 10 attributes, 5 relation metrics, appearance & cosmetics), squad rosters, world tables, schedules, achievements, and `shotTelemetry` records.

---

## 5. Project Structure & Setup (Godot 4.7)

```text
Football Unity/
|-- project.godot             # Godot 4.7 config (GL Compatibility, 960x540 Landscape)
|-- assets/                   # Pixel fonts (.fnt), CRT shader, procedural sprites (.png)
|-- scenes/
|   |-- main/                 # AppRoot, HomeScreen, CareerShell
|   |-- tabs/                 # KiniTab, PemainkuTab, TimkuTab, DuniaTab, WarisanTab
|   |-- match/                # MatchScene (2D board + 3D pitch), PostMatchOverlay
|   |-- modals/               # NewCareerModal, EventCutsceneModal, DilemmaModal, SettingsModal, etc.
|   |-- minigames/            # VolleyMinigame
|   |-- city/                 # CityScene (3D street, shop, apartment)
|-- scripts/
|   |-- autoload/             # GameData, CareerState, AudioSynth, SettingsManager
|   |-- match/                # SlingshotPhysics
|   |-- ui/                   # CharacterStyleCatalog, PixelAvatar, ClubCrest, ShotMapCanvas, UITheme
|-- tools/
    |-- verify_project.gd     # Headless verification test suite (86 checks)
    |-- capture_visuals.gd    # OpenGL visual screenshot capture script
    |-- generate_assets.py    # Python (Pillow) pixel-art & BMFont asset generator
```

### Running & Verifying

1. **Run in Godot Editor**:
   Open `project.godot` with **Godot Engine 4.7+** and press `F5` (Main Scene: `res://scenes/main/AppRoot.tscn`).
2. **Run Headless Verification Suite**:
   ```bash
   godot --headless -s "res://tools/verify_project.gd"
   ```
3. **Capture Landscape Screenshots (Optional, requires OpenGL)**:
   ```bash
   godot -s "res://tools/capture_visuals.gd"
   ```
   Saves screenshots to `user://visual_captures/` (or override via `CAPTURE_OUT_DIR`).
4. **Regenerate Procedural Pixel Assets (Optional)**:
   ```bash
   python tools/generate_assets.py
   ```
