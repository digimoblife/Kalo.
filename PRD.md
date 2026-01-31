# Product Requirements Document (PRD)

**Project Name:** Kalo.
**Platform:** Android (Flutter)
**Version:** 1.0 (MVP)
**Date:** 31 Januari 2026
**Owner:** Digimob

---

## 1. Latar Belakang & Visi Produk

### 1.1 Latar Belakang

Banyak aplikasi pelacak kalori terasa kompleks, penuh iklan, dan tidak relevan dengan gaya hidup Gen Z. Database makanan sering tidak lokal, sulit dicari, atau terkunci di balik paywall. Di sisi lain, konsistensi adalah tantangan utama dalam habit tracking.

### 1.2 Visi Produk

**Kalo.** bertujuan menjadi aplikasi pelacak kalori yang:

* Cepat dan simpel digunakan (low friction)
* Relevan secara lokal melalui database crowdsource bersama
* Mendorong konsistensi lewat elemen komunitas dan gamifikasi ringan

Tagline internal: *“Track bareng, konsisten bareng.”*

### 1.3 Target User

* **Utama:** Gen Z (18–27 tahun)
* **Sekunder:** Milenial awal yang peduli kesehatan

Karakteristik user:

* Mobile-first
* Tidak sabar dengan input yang ribet
* Termotivasi oleh visual, streak, dan feedback instan

---

## 2. Tujuan & Key Success Metrics (MVP)

### 2.1 Tujuan Produk

* Memungkinkan user mencatat asupan kalori harian dengan cepat
* Menyediakan database makanan yang terus tumbuh secara organik
* Meningkatkan retensi harian melalui streak

### 2.2 Key Metrics

* D1 Retention ≥ 35%
* D7 Retention ≥ 15%
* Avg. food log per user per hari ≥ 3
* % user dengan streak ≥ 3 hari ≥ 40%

---

## 3. Scope Produk

### 3.1 In-Scope (MVP)

* Authentication & onboarding
* Kalkulator TDEE
* Database makanan global (crowdsource)
* Barcode scanner
* Daily food logging
* Daily streak
* Dashboard sederhana

### 3.2 Out-of-Scope (Future)

* Meal planning otomatis
* Social feed / follow user
* Subscription & monetization
* iOS version

---

## 4. Tech Stack

* **Frontend:** Flutter (Dart)
* **Backend:** Supabase

  * PostgreSQL
  * Auth
  * Row Level Security (RLS)
  * Edge Functions (opsional)
* **External API:** OpenFoodFacts
* **Tools:** Cursor (IDE), Vercel (Admin/Web Landing – opsional)

---

## 5. User Journey (High Level)

1. User install & buka aplikasi
2. Register / Login
3. Onboarding: input data tubuh & aktivitas
4. Lihat dashboard (target kalori & sisa hari ini)
5. Tambah makanan (search / scan / manual)
6. Lihat streak bertambah 🔥

---

## 6. Fitur & Requirements Detail

### 6.1 Authentication & Onboarding

**Deskripsi:**
User harus memiliki akun untuk menyimpan data personal dan log harian.

**Functional Requirements:**

* Register dengan email & password
* Login & logout
* Validasi email (optional di MVP)

**Onboarding – TDEE Calculator:**
User mengisi:

* Berat badan (kg)
* Tinggi badan (cm)
* Tanggal lahir
* Gender (Male / Female)
* Activity level:

  * Sedentary
  * Light
  * Moderate
  * Active

**Logic:**

* Gunakan rumus **Mifflin-St Jeor**
* Activity multiplier diterapkan
* Hasil disimpan sebagai `daily_calorie_target`

---

### 6.2 Food Database (Hybrid & Crowdsource)

#### 6.2.1 Search Lokal (Prioritas Utama)

* Search by nama makanan
* Autocomplete (min. 2 karakter)
* Sorting by relevance

#### 6.2.2 Barcode Scanner (Smart Input)

**Flow:**

1. User scan barcode
2. Sistem cek tabel `foods` (by barcode)
3. Jika tidak ditemukan → fetch OpenFoodFacts API
4. Jika ada data valid:

   * Normalisasi field
   * Simpan ke Supabase
   * Langsung bisa dipakai user

Fallback: jika API gagal → tampilkan manual input form

#### 6.2.3 Manual Input Makanan

Field wajib:

* Nama makanan
* Kalori per serving
* Serving size & unit

Field opsional:

* Protein, carbs, fats
* Barcode

Catatan:

* Semua data bersifat **public shared**
* `created_by` disimpan untuk audit & hak edit

---

### 6.3 Logging & Gamification

#### 6.3.1 Daily Food Log

* Meal type:

  * Breakfast
  * Lunch
  * Dinner
  * Snack

* User memilih makanan dari database

* Input porsi (multiplier)

* Sistem hitung `total_calories`

#### 6.3.2 Daily Streak 🔥

**Deskripsi:**
Streak menjadi elemen motivasi utama untuk konsistensi.

**Rules:**

* Streak +1 jika:

  * User log makanan hari ini
  * Dan user juga log makanan kemarin
* Jika hari ini log tapi kemarin tidak → streak reset ke 1
* Jika user tidak log sama sekali → streak reset ke 0

**Visual:**

* Icon api 🔥 + angka
* Ditampilkan di dashboard

Future extensibility:

* Badge streak (7 hari, 30 hari, dll)

---

### 6.4 Dashboard

**Komponen Utama:**

* Progress bar / circular indicator:

  * Konsumsi vs target kalori harian
* Sisa kalori hari ini
* Streak 🔥
* List makanan hari ini (grouped by meal)

**UX Principles:**

* One-glance insight
* Minim teks
* Fokus visual

---

## 7. Database Schema (Supabase)

### 7.1 profiles

* id (uuid, PK)
* username (text)
* daily_calorie_target (int)
* current_weight (float)
* height (float)
* birth_date (date)
* gender (text)
* activity_level (text)
* current_streak (int, default 0)
* last_log_date (date)

### 7.2 foods (Global)

* id (bigint, PK)
* name (text, indexed)
* calories (int)
* protein (float)
* carbs (float)
* fats (float)
* serving_size (float)
* serving_unit (text)
* barcode (text, unique, nullable)
* created_by (uuid)

### 7.3 food_logs

* id (uuid, PK)
* user_id (uuid)
* food_id (bigint)
* log_date (date)
* meal_type (text)
* portion (float)
* total_calories (int)

---

## 8. Security & Access Control (RLS)

### Profiles & Food Logs

* SELECT / INSERT / UPDATE / DELETE:

  * Hanya pemilik data

### Foods

* SELECT: Public
* INSERT: Authenticated users
* UPDATE / DELETE:

  * created_by = auth.uid()
  * atau role Admin

---

## 9. Non-Functional Requirements

* App launch < 3 detik
* Search response < 500 ms
* Offline tolerance (cache last search & foods)
* Scalable untuk ≥ 100k user

---

## 10. Risiko & Mitigasi

| Risiko                    | Mitigasi                        |
| ------------------------- | ------------------------------- |
| Data makanan tidak akurat | Flag & future moderation system |
| User malas input          | Barcode & quick-add             |
| Streak fatigue            | Visual ringan, tanpa pressure   |

---

## 11. Future Ideas (Post-MVP)

* Leaderboard komunitas
* Teman & shared streak
* Insight mingguan
* AI food suggestion

---

**End of PRD – Kalo. v1.0**
