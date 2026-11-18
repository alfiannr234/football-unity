# Football Unity

Dokumentasi spesifikasi teknis dan desain game (**Product Requirements Document**) untuk proyek **Football Unity** — sebuah game simulasi karier pesepak bola tunggal (*offline-first*) yang memadukan manajemen database mendalam dengan aksi pertandingan 2.5D berbasis fisika ketapel (*slingshot mechanics*).

## Informasi Proyek

| Atribut Dokumen | Detail | 
| ----- | ----- | 
| **Judul Proyek** | *Football Unity* | 
| **Genre** | Single-Player Offline Football Career Simulation & 2.5D Slingshot Physics | 
| **Platform Target** | Mobile (Android / iOS — Portrait) & PC (Windows) | 
| **Rekomendasi Engine** | Unity (C#) atau Godot 4 (GDScript / C#) | 
| **Target Performa** | 60 FPS (Match Scene), 30 FPS Idle (*Battery Saver*), Offline-First ($< 5\text{ MB}$/Save Slot) | 

## 1. Visi Produk & Core Gameplay Loop

### 1.1 Konsep Utama

Membangun ulang pengalaman simulasi karier pesepak bola tunggal yang mendalam (*deep database simulation*) dipadukan dengan eksekusi aksi lapangan berbasis fisika ketapel (*slingshot mechanics*). Pemain memulai karier sebagai pemain muda (usia 16 tahun, OVR \~60) di klub divisi bawah, mengelola energi, relasi, gaya hidup, dan kontrak, serta menentukan hasil pertandingan melalui momen-momen kunci di lapangan 2.5D.

### 1.2 Core Loop Mingguan

1. **Persiapan Mingguan (`KINI` & `PEMAINKU`):** Memantau jadwal pertandingan, hari istirahat (*recovery*), alokasi *Skill Points*, manajemen sponsor, dan menyelesaikan *event* dilema naratif mingguan.

2. **Simulasi Pertandingan (`Match Engine`):** Laga berjalan menit ke-1 hingga $90+$ dalam mode teks/taktik cepat dan beralih otomatis ke kamera 3D saat memicu *Key Moment* (tembakan, umpan kunci, dribel 1v1, penalti, atau tendangan bebas).

3. **Evaluasi Pasca-Laga & `MOVIOLA`:** Menerima *Match Rating* ($1.0 - 10.0$), XP/Level, uang pertandingan, sorotan *Man of the Match*, serta tayangan ulang TV (*Moviola*) untuk momen krusial.

4. **Progresi Musiman & Warisan (`DUNIA` & `WARISAN`):** Bersaing di klasemen liga/piala, bursa transfer antar-klub, panggilan tim nasional, penghargaan tahunan (*Pemain Terbaik* & *Anak Emas*), hingga pensiun sebagai *Legenda*.

## 2. Arsitektur UI & Navigasi Global

### 2.1 Persistent Top HUD

Tampil konsisten di seluruh layar manajemen karier:

* **Identitas & Level:** Badge OVR (`60`), Nama Pemain, Usia (`16 THN`), dan Level Karier (`LEVEL 1`).

* **Status Kondisi & Finansial:** Bar Energi (`ENERGI SEGAR 90/100`) dan Saldo Uang (`$6.976`).

* **Kalender & Posisi:** Tahun & Minggu berjalan (`THN 1 • MGG 2/45`) serta peringkat liga saat ini (`LIGA 2/31`).

### 2.2 Bottom Navigation Bar (5 Tab Utama)

1. **`KINI`:** Hub pertandingan berikutnya, kalender bulanan, dan kartu *event* mingguan.

2. **`PEMAINKU`:** Atribut (`SKILL`), penguasaan posisi (`POSISIMU`), `RELASI` & sponsor (`MEREKMU`), kustomisasi seragam (`GAYA`), belanja karier (`TOKO`), dan fitur sosial (`KOTA` $\rightarrow$ `TEMAN`).

3. **`TIMKU`:** Formasi taktik (`SKUAD`), info `KLUB`, `MANAJEMEN`, dan status `TIMNAS`.

4. **`DUNIA`:** Klasemen kompetisi (`KOMP.`), bursa `TRANSFER`, `JADWAL`, `RANKING` global, dan feed `BERITA`.

5. **`WARISAN`:** Peta karier (`PETA`), lemari `TROFI`, rekor `KLUB`, *Hall of Fame* (`LEGENDA`), gala penghargaan (`BOLA`), dan `PETA TEMBAKAN`.

## 3. Spesifikasi Fungsional (Functional Requirements)

### FR-01: Match Engine & Fisika Ketapel 2.5D

* **Arsitektur Visual:** Lapangan, jaring gawang, papan iklan LED, dan tribun dirender dalam ruang 3D *low-poly* bertekstur *pixel-art* (*point-filtered*, tanpa anti-aliasing), dipadukan dengan *sprite* pemain dan bola 2D *billboard* menghadap kamera.

* **Sistem Kamera Dinamis:**

  * *Tactical High-Angle Camera:* Sudut pandang vertikal saat membangun serangan, melihat pergerakan rekan setim, dan celah pertahanan.

  * *Low-Angle Action Camera:* Transisi kamera rendah tepat di belakang pemain saat eksekusi peluang tembakan, penalti, atau tendangan bebas.

* **Mekanik Input Ketapel (*Slingshot Physics*):**

  * **Vektor Tarikan (*Drag-and-Release*):** Selisih posisi sentuh awal dan titik lepas ($\Delta x, \Delta y$) dari lingkaran kaki pemain (`CINCIN`) menentukan kecepatan awal bola ($v_0$) dan sudut elevasi (*loft*), dibatasi oleh atribut `Kekuatan`.

  * **Efek Lengkungan (*Magnus Force*):** Gesekan horizontal atau titik perkenaan pada bola menghasilkan kecepatan sudut ($\vec{\omega}$) yang membelokkan lintasan bola di udara:
    

    $$
    \vec{F}_{\text{magnus}} = S(\text{Efek}) \cdot (\vec{\omega} \times \vec{v})
    $$

  * **Bantuan Bidikan (`AIM`):** Menampilkan garis/panah pratinjau arah dan kekuatan yang panjang serta tingkat presisinya dipengaruhi oleh atribut `Akurasi`, `Penalti`, dan `Bola mati`.

* **Pasca-Laga & `MOVIOLA`:**

  * Menampilkan kartu *Pemain Terbaik Laga* (*Man of the Match*) lengkap dengan statistik gol/assist.

  * Fitur `LANGSUNG MOVIOLA` memutar ulang rekaman aksi penting (seperti gol penentu atau penalti yang gagal) dalam bingkai tayangan siaran TV.

### FR-02: Hub Mingguan & Event Naratif (`KINI`)

* **Kartu Laga Berikutnya:** Menampilkan status kandang/tandang (`KANDANG` / `TANDANG`), nama kompetisi, jumlah hari istirahat (`7h`), tingkat energi, dan status peran (`INTI` / `CADANGAN`).

* **Kalender Bulanan:** Tampilan grid tanggal per bulan yang menandai jadwal pertandingan berdasarkan kode warna (`LIGA`, `PIALA`, `TIMNAS`).

* **Sistem Dilema Mingguan (`PEKAN INI`):** Kartu narasi acak tiap pekan (contoh: makan malam tim, interaksi sosial/asmara, konferensi pers, atau tawaran investasi) dengan 2–3 pilihan aksi (`DEKATI`, `PIKIR DULU`, `BIARKAN`) yang mengubah nilai relasi, energi, atau poin aksi.

### FR-03: Progresi Pemain & Penguasaan Posisi (`PEMAINKU`)

* **10 Atribut Inti (Skala** $1 - 99$**, ditingkatkan dengan *Skill Points*):**

| Kategori | Nama Atribut | Dampak Langsung pada Gameplay | 
| ----- | ----- | ----- | 
| **Tembakan & Teknik** | `Kekuatan` | Kecepatan maksimal bola saat ketapel ditarik penuh. | 
|  | `Akurasi` | Memperkecil radius penyimpangan acak (*spread*) tembakan/umpan. | 
|  | `Efek` | Besarnya gaya lengkung (*curve*) saat bola diputar. | 
|  | `Visi` | Probabilitas munculnya *key event* umpan terobosan dalam simulasi menit. | 
| **Fisik & Mobilitas** | `Fisik` | Ketahanan duel badan dan efisiensi pengurangan `ENERGI` per laga. | 
|  | `Kecepatan` | Kecepatan lari maksimal pemain mengejar bola terobosan. | 
|  | `Akselerasi` | Respons ledakan lari awal saat menerima umpan. | 
|  | `Dribel` | Peluang sukses melewati bek lawan pada skenario 1v1. | 
| **Spesialis** | `Penalti` | Stabilitas bidikan dan ketenangan saat eksekusi penalti. | 
|  | `Bola mati` | Panjang garis bantu *trajectory* pada tendangan bebas dan sudut. | 

* **Position Mastery:** Pemain memiliki posisi natural (`ST ASLI • PERFORMA 100%`) dan satu posisi `FAVORIT` (menentukan prioritas tawaran transfer dan posisi bermain). Posisi sekunder (`CDM`, `CM`, `LM`, `RM`, `CAM`, `LW`, `RW`, dll.) dapat dibuka dengan biaya `6 POIN` (`BISA DIPELAJARI`), dan tingkat kemahirannya naik seiring jam terbang bermain di posisi tersebut.

* Skill point didapatkan dari naik level yang setiap kenaikkan level mendapatkan 3 POIN

### FR-04: Relasi, Sponsor, Gaya & Toko (`PEMAINKU`)

* **5 Parameter Relasi (Skala** $0 - 100$ **dengan tier status: `RUSAK`, `BEKU`, `NETRAL`, `AKRAB`, `IDOLA`):**

  1. `Pelatih`: Menentukan status masuk *Starting XI* (`INTI`) atau cadangan (`BANGKU`).

  2. `Ruang Ganti`: Memengaruhi frekuensi umpan dari rekan setim di lapangan.

  3. `Fans`: Meningkatkan dukungan stadion dan nilai komersial.

  4. `Pers`: Memengaruhi nada pemberitaan media dan peluang penghargaan individu.

  5. `Agen`: Membuka bonus persentase negosiasi gaji (misal `+5% GAJI`).

* **Kontrak Sponsor (`MEREKMU`):** Pemain dapat menandatangani kontrak sponsor aktif yang memberikan bayaran per laga (misal `$1.442/laga`), bonus per gol (`$1.442/gol`), dan bonus target akhir musim (misal `3 GOL` $\rightarrow$ `$32.174`).

* **Kustomisasi Tampilan (`GAYA`):** Mengatur nama punggung (`NAMAMU`), nomor punggung (dipilih saat teken/perpanjang kontrak), model sepatu, panjang lengan jersey (`PENDEK` / `PANJANG`), sarung tangan, serta gelang tangan (kiri/kanan/keduanya beserta palet warna).

* **Toko Karier (`TOKO`):**

  * *In-Game Currency:* `BOOT` (11 model sepatu dengan diskon harian), `STAF` (hingga 6 slot staf pendukung), `KANDANG` (properti), `MEBEL`, `MOBIL`, dan `GAYA & MEWAH` (item gaya hidup untuk pemulihan energi & prestise).

  * *Kosmetik Ketapel & Perk (`TOKO`* $\rightarrow$ *`GAYA / PERK`):* Kustomisasi modular untuk **`CINCIN`** (24 item lingkaran ketapel), **`AIM`** (31 item panah bidik), **`JEJAK`** (4 efek *trail* bola), **`LENCANA`** (14 bingkai OVR), dan **`KARTU`** (13 bingkai kartu profil), serta *perk* permanen (`GAJI GANDA`, `XP GANDA`, `SLOT KEEMPAT`).

* **Sistem Sosial Asinkron (`KOTA`** $\rightarrow$ **`TEMAN`):** Pertukaran kode teman (`KODEMU`), sistem `MENTOR 0/1`, tantangan `DUEL` skor bergiliran, `TABEL` klasemen teman, lini masa aktivitas teman (`YANG BARU`), dan statistik komparasi `TATAP MUKA`.

### FR-05: Manajemen Skuad & Klub (`TIMKU`)

* **Layar Taktik (`SKUAD`):** Visualisasi formasi lapangan 2D (misal `5-3-2`), OVR rata-rata tim (`58`), penunjukan `KAPTEN`, susunan 11 pemain inti (`TIM INTI`), dan daftar cadangan (`BANGKU`).

* **Inspector Pemain:** Mengetuk pemain mana pun membuka *bottom-sheet* berisi usia, sisa kontrak, nilai pasar, rata-rata rating musim, seluruh 10 atribut, dan riwayat klub (`RIWAYAT`).

### FR-06: Simulasi Ekosistem Dunia (`DUNIA`)

* **Skala Database:** Menyimulasikan $\approx 21.289$ pemain, $\approx 2.731$ pelatih, dan $55$ negara dengan sistem koefisien liga.

* **Sub-Modul Dunia:**

  * `KOMP.`: Klasemen divisi (hingga 32 tim per liga dengan zona promosi `NAIK`), daftar `TOP 10 GOL`, serta piala domestik dan kontinental (`LIGA`, `ELITE`, `EUROPA`, `CONF.`, `PIALA`, `KLUB`, `KONT.`).

  * `TRANSFER`: Daftar pemain bebas transfer (`BOSMAN / TANPA KLUB`), riwayat transfer, dan bursa masuk/keluar.

  * `RANKING`: Tabel peringkat global `PEMAIN`, `PELATIH`, dan `NEGARA` dengan filter posisi, usia, OVR, negara, dan divisi.

  * `BERITA`: 5 kanal informasi (`KLUB`, `LIGA`, `DUNIA`, `SOSMED` untuk pertumbuhan pengikut, dan `PESAN`).

### FR-07: Rekor, Legenda & Peta Tembakan (`WARISAN`)

* **Jalur Legenda (`PETA`):** Akumulasi `Poin Legacy` dari gol, assist, trofi, dan laga timnas untuk naik jenjang: `100 PROFESIONAL` $\rightarrow$ `300 ANDALAN` $\rightarrow$ `650 BINTANG DUNIA` $\rightarrow$ `LEGENDA` (syarat 45 prestise dunia atau 8 gelar kasta tertinggi), dilengkapi statistik per musim dan tombol `PENSIUN`.

* **Buku Rekor & Gala (`TROFI`, `KLUB`, `LEGENDA`, `BOLA`):** Lemari trofi pribadi, daftar klub tersukses dunia, rekor alumni klub (`ANDALAN` $10+$ musim), *Hall of Fame* (`TROFI INDIVIDU TERBANYAK` & `GOL + ASSIST` sepanjang masa), serta malam penganugerahan `PEMAIN TERBAIK TAHUN INI` dan `ANAK EMAS` (U-21).

* **Interactive Shot Map (`PETA TEMBAKAN`):**

  * Visualisasi 2D lapangan dan penampang gawang yang memetakan setiap percobaan (`SHOT`, `UMPAN`, `DRIBEL`).

  * Kode warna status tembakan: **Gol**, **Tepat sasaran**, **Melebar**, dan **Diblok**, dilengkapi statistik konversi *Open Play* vs *Penalti* serta jarak gol terjauh (`JARAK TERJAUH`). Mengetuk titik tembakan di lapangan memutar ulang aksi tersebut.

### FR-08: Setelan & Koleksi Prestasi

* **`SETELAN`:** Kontrol `SUARA` (slider `MUSIK`, `EFEK`, `GETARAN`, dan pemutar `RADIO` in-game), `LAYAR` (shader `EFEK CRT`, `MODE RINGAN`, `SANGAT RINGAN`, `HEMAT BATERAI` 30 FPS saat *idle*, rotasi layar), `KARIER` (3 slot save + `EDITOR` database), dan `PONSEL` (notifikasi & reset total *hold-to-confirm*).

* **`KOLEKSI / PRESTASI`:** 386 pencapaian (*achievements*) dalam 4 tingkat kelangkaan: `UMUM` (32), `LANGKA` (106), `EPIK` (162), dan `LEGENDARIS` (86).

## 4. Arsitektur Data Inti (Save Schema)

Untuk mendukung performa offline dengan puluhan ribu entitas pemain/pelatih tanpa membebani memori, data penyimpanan disusun ke dalam skema berikut:

```
{
  "saveSlotId": 1,
  "careerMeta": {
    "year": 1,
    "week": 2,
    "maxWeeks": 45,
    "legacyPoints": 0,
    "legacyTier": "PROSPEK"
  },
  "playerProfile": {
    "name": "ALFIAN",
    "age": 16,
    "level": 2,
    "ovr": 60,
    "energy": 90,
    "cash": 6976,
    "skillPoints": 3,
    "naturalPosition": "ST",
    "favoritePosition": "ST",
    "learnedPositions": { "ST": 100 },
    "attributes": {
      "kekuatan": 60, "akurasi": 60, "efek": 60, "visi": 60, "fisik": 60,
      "kecepatan": 60, "akselerasi": 60, "dribel": 60, "penalti": 60, "bolaMati": 60
    },
    "relations": {
      "pelatih": 45, "ruangGanti": 33, "fans": 27, "pers": 18, "agen": 33
    },
    "cosmetics": {
      "ringId": "default", "aimId": "default", "trailId": "default",
      "cardFrameId": "default", "badgeId": "default"
    }
  },
  "shotTelemetry": [
    {
      "season": 1,
      "matchId": "L3_M02",
      "type": "OPEN_PLAY",
      "outcome": "ON_TARGET",
      "pitchCoord": { "x": 0.48, "y": 0.84 },
      "goalCoord": { "x": 0.35, "y": 0.62 },
      "distanceMeters": 16.5
    }
  ]
}

```

## 5. Roadmap Pengembangan (MVP ke Full Release)

| Fase | Fokus Pengembangan | Deliverable Utama | 
| ----- | ----- | ----- | 
| **Fase 1: Core Physics & Scene 2.5D** | Membangun *match scene* 2.5D, fisika ketapel (*drag*, *loft*, *Magnus curve*), AI kiper/bek dasar, dan kamera aksi. | *Playable prototype* skenario tendangan bebas, penalti, dan *open play*. | 
| **Fase 2: Career Loop & Progression** | Mengimplementasikan `KINI`, sistem energi, 10 atribut, *Position Mastery*, relasi, dan *state machine* mingguan. | *Loop* 1 musim penuh (45 minggu) yang dapat dimainkan dan disimpan ke 3 slot. | 
| **Fase 3: World Database & UI Ecosystem** | Mengintegrasikan database liga, klasemen 32 tim, bursa transfer, sistem berita, dan `TIMKU`. | Simulasi dunia multi-divisi, promosi/degradasi, dan kontrak sponsor. | 
| **Fase 4: Legacy, Shot Map & Polish** | Membangun `PETA TEMBAKAN`, *Moviola replay*, 386 prestasi, shader `EFEK CRT`, dan optimasi *Mode Ringan*. | Build siap rilis dengan *UI polish* dan *battery saver*. |

## 6. Implementasi Godot 4 & Cara Menjalankan

Proyek ini diimplementasikan menggunakan **Godot Engine 4.7 (`GL Compatibility`)** dengan konfigurasi layar default **Landscape `960x540`** (`project.godot`).

### Struktur Direktori

* `scenes/main/`: Root aplikasi (`AppRoot.tscn`), layar awal 3 slot save (`HomeScreen.gd`), dan shell HUD karier (`CareerShell.gd`).
* `scenes/tabs/`: 5 tab karier utama (`KiniTab.gd`, `PemainkuTab.gd`, `TimkuTab.gd`, `DuniaTab.gd`, `WarisanTab.gd`).
* `scenes/match/`: Simulasi laga 2D & aksi 2.5D ketapel + kontrol analog dribel lingkaran (`MatchScene.tscn`, `MatchScene.gd`) serta laporan pasca-laga & Moviola (`PostMatchOverlay.tscn`).
* `scenes/modals/`: Wizard karier baru & pemilihan klub Divisi 3 lintas negara (`NewCareerModal.gd`), cutscene pra/pasca-laga (`EventCutsceneModal.gd`), dilema mingguan, setelan, editor, koleksi, teman, dan toko kosmetik.
* `scenes/minigames/` & `scenes/city/`: Minigame kontrol & voli (`VolleyMinigame.gd`) serta eksplorasi kota 3D (`CityScene.gd`).
* `scripts/autoload/`: Data dunia (`GameData.gd`), state karier (`CareerState.gd`), audio prosedural (`AudioSynth.gd`), dan preferensi (`SettingsManager.gd`).
* `tools/`: Generator aset pixel (`generate_assets.py`), suite verifikasi headless (`verify_project.gd`), dan capture render visual (`capture_visuals.gd`).

### Menjalankan Game & Verifikasi

1. **Buka di Godot Editor**: Impor `project.godot` di Godot 4.7+, lalu tekan `F5` (`Main Scene: res://scenes/main/AppRoot.tscn`).
2. **Verifikasi Headless (CLI)**:
   ```bash
   godot --headless -s "res://tools/verify_project.gd"
   ```
3. **Regenerasi Aset Pixel-Art (Opsional)**:
   ```bash
   python tools/generate_assets.py
   ```
 
