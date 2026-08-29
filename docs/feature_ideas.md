# 💡 10 Ide Fitur Pengembangan — Kalo.
**Target User:** Gen Z Indonesia (18–27 tahun) | **Stack:** Flutter + Supabase

---

## Fitur #1 — 📸 Snap & Track (AI Food Recognition)

![AI Snap Feature](/Users/cahyo/.gemini/antigravity/brain/06d0e94d-d898-48c1-b968-941f996095b3/kalo_feature_ai_snap_1787984318819.jpg)

### Konsep
User **foto makanannya**, AI langsung mendeteksi jenis makanan dan memperkirakan kalori. Tidak perlu search, tidak perlu ketik apapun.

### User Flow
1. Tap tombol kamera di dashboard
2. Arahkan ke makanan → scan otomatis
3. AI deteksi: *"Nasi Goreng Spesial — ~485 kcal (94% yakin)"*
4. Tampilkan estimasi makro (Protein, Karbo, Lemak)
5. User bisa edit kalau perlu → tap "Langsung Log"

### Value Prop
> *"Paling males itu ngetik nama makanan. Foto aja langsung keitung."*

Ini adalah **killer feature** — friction terbesar dalam calorie tracking adalah input data. Foto = 1 detik vs search + pilih + atur porsi = 30+ detik.

### Implementasi
| Aspek | Detail |
|---|---|
| Tech | Google ML Kit Food Recognition / Gemini Vision API |
| Backend | Edge Function Supabase untuk proxy AI call |
| Kompleksitas | 🔴 Tinggi (butuh AI API + fine-tuning untuk makanan Indonesia) |
| MVP alternatif | Mulai dengan library food photo recognition yang ada (Logmeal API, Calorie Mama API) |

### Dampak pada Retensi
**⭐⭐⭐⭐⭐** — Fitur differentiator utama vs kompetitor

---

## Fitur #2 — 🔥 Streak Bareng (Social Accountability)

![Social Streak Feature](/Users/cahyo/.gemini/antigravity/brain/06d0e94d-d898-48c1-b968-941f996095b3/kalo_feature_social_streak_1787984332212.jpg)

### Konsep
Tambahkan **dimensi sosial** pada streak. User bisa tambah teman, lihat streak masing-masing, dan ada leaderboard mingguan antar teman.

### User Flow
1. User invite teman via link / username Kalo.
2. Halaman "Streak Bareng" menampilkan leaderboard teman
3. Badge status real-time: *"@dimasfit sudah log makan siang ✅"*
4. Notifikasi: *"@sarahsehat hampir kalah streak, ingatkan dia?"*
5. End-of-week: highlight siapa yang streak terbaik

### Value Prop
> *"Lebih gampang konsisten kalau ada yang lihat. Malu kalau streak-nya kalah sama temen."*

Ini mengeksploitasi **social pressure** yang positif — teman jadi accountability partner secara pasif, tanpa perlu konten/feed seperti Instagram.

### Implementasi
| Aspek | Detail |
|---|---|
| DB Baru | Tabel `friendships` (user_id, friend_id, status) |
| Supabase | Realtime subscription untuk update status teman |
| Notifikasi | `flutter_local_notifications` + Supabase webhooks |
| Kompleksitas | 🟡 Medium (fitur sosial sederhana tanpa feed) |

### Dampak pada Retensi
**⭐⭐⭐⭐⭐** — Social features adalah pendorong retensi terkuat di habit apps

---

## Fitur #3 — 🎴 Kalo. Wrapped (Monthly Recap yang Bisa Di-share)

![Monthly Report Card](/Users/cahyo/.gemini/antigravity/brain/06d0e94d-d898-48c1-b968-941f996095b3/kalo_feature_report_card_1787984378390.jpg)

### Konsep
Setiap akhir bulan, app generate **kartu recap premium** bergaya Spotify Wrapped yang bisa langsung di-share ke Instagram Stories / WhatsApp.

### Konten Kartu
- "26 hari konsisten!" — hero number
- 🔥 Streak terbaik bulan ini
- 🥗 Total makanan yang di-log
- ⚡ Rata-rata kalori harian vs target
- 💧 Rata-rata hidrasi
- Mini chart konsistensi per minggu
- Quote motivasi dari AI berdasarkan progress
- "dibuat dengan Kalo." watermark

### Value Prop
> *"Gue udah 26 hari konsisten! Proud of myself dan langsung share ke Stories."*

Ini adalah **growth loop organik** — setiap share = iklan gratis ke teman-teman si user. Watermark "dibuat dengan Kalo." membantu viral growth.

### Implementasi
| Aspek | Detail |
|---|---|
| Tech | `RepaintBoundary` + `RenderRepaintBoundary.toImage()` untuk export kartu |
| Share | `share_plus` package untuk share ke berbagai platform |
| Kompleksitas | 🟢 Rendah-Medium (mostly UI + image export) |
| Trigger | Notifikasi tiap tanggal 1 bulan baru |

### Dampak pada Retensi
**⭐⭐⭐⭐** — Viral loop + sense of achievement yang kuat

---

## Fitur #4 — 💡 Smart Meal Suggestion

![Smart Suggestion Feature](/Users/cahyo/.gemini/antigravity/brain/06d0e94d-d898-48c1-b968-941f996095b3/kalo_feature_smart_suggest_1787984429605.jpg)

### Konsep
App secara cerdas **merekomendasikan makanan apa yang cocok dimakan** berdasarkan sisa kalori hari ini, histori makanan favorit user, dan waktu makan.

### Logika Saran
```
Sisa Kalori = Target - Sudah Dikonsumsi
Waktu = deteksi jam (Sarapan / Makan Siang / Makan Malam)
Filter = dari makanan yang pernah user log sebelumnya (top 20)
Sort = kalori paling dekat dengan sisa kalori
```

### Value Prop
> *"Tinggal 520 kcal lagi, bisa makan apa ya? Kalo. langsung kasih saran."*

Mengurangi *decision fatigue* — salah satu alasan user berhenti tracking adalah karena bingung harus makan apa yang masuk dalam target.

### Implementasi
| Aspek | Detail |
|---|---|
| DB Query | `SELECT food_id, COUNT(*) FROM food_logs GROUP BY food_id ORDER BY COUNT DESC LIMIT 20` |
| Logic | Dart: filter berdasarkan sisa kalori (±100 kcal) |
| Kompleksitas | 🟢 Rendah (murni query + logic Dart, tidak butuh AI) |
| Placement | Widget card di bawah progress ring jika sisa kalori > 200 |

### Dampak pada Retensi
**⭐⭐⭐⭐** — Langsung reduce friction untuk log makan berikutnya

---

## Fitur #5 — 🏃 Catat Olahraga & Kalori Terbakar

![Exercise and Other Features](/Users/cahyo/.gemini/antigravity/brain/06d0e94d-d898-48c1-b968-941f996095b3/kalo_feature_remaining_ideas_1787984429605.jpg)

### Konsep
Lengkapi persamaan kalori dengan **sisi output**: user bisa log olahraga, dan kalori yang terbakar dikurangkan dari target harian (*net calories*).

### User Flow
1. Tap "Catat Olahraga" (ikon lari di dashboard)
2. Pilih jenis olahraga: Lari / Bersepeda / Renang / Yoga / Angkat Beban / Jalan Kaki / dll.
3. Input durasi (menit)
4. App hitung kalori terbakar berdasarkan berat badan + jenis olahraga (MET formula)
5. Dashboard update: *"Net kalori: 1.010 / 2.000 kcal (sudah olahraga 240 kcal)"*

### Value Prop
> *"Habis lari 30 menit, akhirnya boleh makan dikit lebih banyak!"*

Membuat app lebih **complete** sebagai health companion, bukan hanya food tracker.

### Implementasi
| Aspek | Detail |
|---|---|
| DB Baru | Tabel `exercise_logs` (user_id, exercise_type, duration_min, calories_burned, log_date) |
| Formula | MET × berat (kg) × durasi (jam) = kalori terbakar |
| Kompleksitas | 🟡 Medium (DB baru + formula + update dashboard calculation) |
| Data | Tabel MET values untuk ~20 jenis olahraga umum |

### Dampak pada Retensi
**⭐⭐⭐⭐** — Melengkapi value proposition app secara signifikan

---

## Fitur #6 — 📱 Home Screen Widget

### Konsep
Widget Android di home screen yang menampilkan progress kalori hari ini, streak, dan status air — **tanpa perlu buka app**.

### Konten Widget
```
┌─────────────────────────┐
│  Kalo.      🔥 12 hari  │
│                         │
│    ◕  1.250 kcal        │
│      / 2.000 kcal       │
│  💧 65%  ████████░░     │
│                         │
│  [Tambah Log]           │
└─────────────────────────┘
```

### Value Prop
> *"Tiap kali buka HP langsung keliatan progress kalori. Jadi inget terus buat log."*

Widget = passive engagement yang paling powerful. Mengingatkan user **tanpa notifikasi push** yang mengganggu.

### Implementasi
| Aspek | Detail |
|---|---|
| Tech | `home_widget` package (Flutter) |
| Update | Background fetch setiap kali app dibuka / log baru |
| Size | 2 varian: 2×2 (mini) dan 4×2 (medium) |
| Kompleksitas | 🟡 Medium (perlu konfigurasi Android native widget + home_widget package) |

### Dampak pada Retensi
**⭐⭐⭐⭐** — Passive reminder terbaik, menaikkan DAU secara organik

---

## Fitur #7 — ⏰ Intermittent Fasting Timer

### Konsep
Timer countdown untuk **Intermittent Fasting (IF)** — trend diet yang sangat populer di Gen Z. User bisa set jadwal puasa (16:8, 18:6, 5:2, dll.) dan app akan track kapan boleh makan.

### User Flow
1. Pilih mode IF: 16:8 / 18:6 / 20:4 / Custom
2. Set waktu mulai puasa (atau "Mulai sekarang")
3. Timer besar menghitung mundur: *"08:23:15 tersisa"*
4. Status: "Jendela Makan: 12:00 – 20:00"
5. Notifikasi: *"Jendela makan dibuka! Saatnya sarapan 🍳"*
6. Kalori harian hanya dihitung dalam jendela makan

### Value Prop
> *"Lagi IF nih, tapi bingung kapan boleh makan. Kalo. yang ingetin."*

IF adalah salah satu metode diet paling tren — integrasi native akan membuat Kalo. jauh lebih relevan untuk segment yang lebih luas.

### Implementasi
| Aspek | Detail |
|---|---|
| Storage | `SharedPreferences` untuk menyimpan jadwal IF |
| UI | Countdown timer dengan `AnimatedBuilder` |
| Notif | `flutter_local_notifications` dengan scheduled alarm |
| Kompleksitas | 🟢 Rendah-Medium (mostly local, tidak butuh backend baru) |

### Dampak pada Retensi
**⭐⭐⭐** — Fitur niche tapi sangat sticky untuk yang menggunakannya

---

## Fitur #8 — 🏆 Weekly Challenge

### Konsep
Setiap minggu ada **challenge komunitas** yang bisa diikuti user. Challenge-nya tematis dan variatif — dari challenge kalori, hidrasi, sampai challenge jenis makanan.

### Contoh Challenge
| Challenge | Deskripsi | Reward |
|---|---|---|
| 🥗 "Makan Sayur 7 Hari" | Log minimal 1 sayuran per hari selama seminggu | Badge Herbivore |
| 💧 "Hydrasi Hero" | Capai 2L air per hari selama 5 hari | Badge Drop King |
| 🎯 "On Target Streak" | Kalori dalam ±10% target selama 5 hari | Badge Precision |
| 🚫 "Clean Eating Week" | Tanpa log makanan gorengan 7 hari | Badge Squeaky Clean |

### Value Prop
> *"312 orang lagi challenge bareng. Masa gue nyerah duluan?"*

Challenge + komunitas + badge = **trifecta gamifikasi** yang terbukti ampuh di apps seperti Duolingo, Nike Run Club, dan Strava.

### Implementasi
| Aspek | Detail |
|---|---|
| DB Baru | Tabel `challenges` + `challenge_participants` |
| Admin | Tabel admin untuk define challenge baru tiap minggu |
| Kompleksitas | 🟡 Medium (DB + logic validasi per challenge berbeda-beda) |
| MVP | Mulai dengan 3 challenge hardcoded, evaluasi engagement dulu |

### Dampak pada Retensi
**⭐⭐⭐⭐** — Gamifikasi berbasis komunitas = retention driver terkuat kedua setelah social

---

## Fitur #9 — 📊 Body Progress Tracker

### Konsep
Tracker berat badan harian dengan **grafik progress**, kalkulasi BMI otomatis, dan (opsional) log foto body progress — semuanya private dan terenkripsi.

### Fitur Lengkap
- Log berat badan harian (input simple)
- Grafik progress berat 1 bulan / 3 bulan / 6 bulan
- BMI calculator otomatis + kategori (Kurus / Normal / Overweight)
- Target berat badan dengan estimasi waktu capai target berdasarkan deficit/surplus kalori
- Photo log (optional, tersimpan lokal di device, tidak ke server)

### Value Prop
> *"Angka di timbangan naik-turun, tapi kalau lihat grafik seminggu ke belakang tetap turun. Lebih tenang."*

Menghubungkan **food tracking dengan hasil nyata** — ini adalah motivator terkuat untuk user terus menggunakan app.

### Implementasi
| Aspek | Detail |
|---|---|
| DB Baru | Kolom `weight_logs` (user_id, weight_kg, log_date) |
| Chart | `fl_chart` package untuk line chart yang smooth |
| BMI | Formula: weight / (height/100)² — data sudah ada di profiles |
| Foto | Simpan lokal dengan `path_provider`, enkripsi dengan `flutter_secure_storage` |
| Kompleksitas | 🟡 Medium (chart + DB baru, foto adalah opsional) |

### Dampak pada Retensi
**⭐⭐⭐⭐** — Menghubungkan effort (log makanan) dengan outcome (perubahan berat) = motivasi kuat

---

## Fitur #10 — 🍽️ Restoran Mode

### Konsep
User bisa **search restoran atau warung makan**, lalu lihat menu dengan estimasi kalori. Cocok saat makan di luar dan tidak tahu harus log apa.

### User Flow
1. Tap "Makan di Luar" atau mode restoran
2. Search nama restoran (McD / KFC / Warung Pak Budi)
3. Lihat menu dengan kalori: *"McD Big Mac — 563 kcal"*
4. Tap item → langsung log ke jurnal harian
5. Crowd-sourced: user bisa tambah restoran / menu baru ke database

### Database Strategy
- **Restoran besar (franchise)**: data kalori sudah tersedia publik di OpenFoodFacts / website resmi → scrape / manual input sekali
- **Warung lokal**: crowd-sourced sama seperti food database yang sudah ada
- Tabel baru: `restaurants` + `menu_items` (dengan referensi ke tabel `foods`)

### Value Prop
> *"Lagi di KFC, bingung mau order apa yang masuk kalori. Scan aja menu-nya di Kalo."*

Salah satu use case terbesar calorie tracking adalah **saat makan di luar** — di mana saat ini tidak ada solusi yang bagus untuk konteks Indonesia.

### Implementasi
| Aspek | Detail |
|---|---|
| DB Baru | Tabel `restaurants` (name, location, verified) + `menu_items` |
| MVP | Mulai dengan 10-20 restoran franchise populer (McD, KFC, A&W, dll.) |
| Crowd | Sama seperti food database — user authenticated bisa tambah menu |
| Kompleksitas | 🟡 Medium (DB baru + UI baru, logic sama dengan food search yang ada) |

### Dampak pada Retensi
**⭐⭐⭐** — High-value untuk urban user, butuh initial data seeding yang signifikan

---

## 📊 Rangkuman & Prioritas

![Feature Overview](/Users/cahyo/.gemini/antigravity/brain/06d0e94d-d898-48c1-b968-941f996095b3/kalo_feature_remaining_ideas_1787984429605.jpg)

### Matriks Prioritas

| Fitur | Dampak User | Kompleksitas Dev | ROI | Saran Urutan |
|---|---|---|---|---|
| 🍽️ Restoran Mode | ⭐⭐⭐ | 🟡 Medium | Baik | Fase 2 |
| 💡 Smart Suggestion | ⭐⭐⭐⭐ | 🟢 Rendah | **Terbaik** | **Fase 1** |
| 🎴 Kalo. Wrapped | ⭐⭐⭐⭐ | 🟢 Rendah | **Terbaik** | **Fase 1** |
| 🔥 Streak Bareng | ⭐⭐⭐⭐⭐ | 🟡 Medium | Sangat Baik | **Fase 1** |
| 📊 Body Progress | ⭐⭐⭐⭐ | 🟡 Medium | Sangat Baik | Fase 2 |
| ⏰ IF Timer | ⭐⭐⭐ | 🟢 Rendah | Baik | Fase 2 |
| 📱 Home Widget | ⭐⭐⭐⭐ | 🟡 Medium | Sangat Baik | Fase 2 |
| 🏃 Catat Olahraga | ⭐⭐⭐⭐ | 🟡 Medium | Sangat Baik | Fase 2 |
| 🏆 Weekly Challenge | ⭐⭐⭐⭐ | 🟡 Medium | Baik | Fase 3 |
| 📸 AI Snap & Track | ⭐⭐⭐⭐⭐ | 🔴 Tinggi | Potensial | Fase 3 |

### Rekomendasi Urutan Pengerjaan

**🔴 Selesaikan Bug Dulu** → Fix 5 bug kritis dari audit kode

**🟡 Fase 1 — Low-hanging fruit (1-2 minggu)**
1. Smart Meal Suggestion — dampak tinggi, implementasi rendah
2. Kalo. Wrapped — viral potential, mostly UI work
3. Streak Bareng (versi beta: hanya leaderboard tanpa realtime) 

**🟢 Fase 2 — Feature Expansion (1-2 bulan)**
4. Body Progress Tracker + Grafik
5. Home Screen Widget
6. Catat Olahraga
7. IF Timer

**🔵 Fase 3 — Advanced (3-6 bulan)**
8. Restoran Mode (butuh initial data seeding)
9. Weekly Challenge (butuh sistem admin)
10. AI Snap & Track (butuh AI API + training)

---

> [!TIP]
> **Quick win terbesar:** Mulai dengan **Smart Suggestion** + **Kalo. Wrapped**. Keduanya low-effort, high-impact, dan bisa selesai dalam 1 sprint. Smart Suggestion langsung meningkatkan engagement harian, Wrapped langsung generate viral growth.
