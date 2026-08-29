# 📋 Laporan Audit Project — Kalo.
**Tanggal Audit:** 29 Agustus 2026  
**Versi App:** 1.1.0+4  
**Platform:** Android (Flutter/Dart)  
**Backend:** Supabase (PostgreSQL + Auth)  
**Auditor:** Antigravity AI

---

## 1. 🔭 Ringkasan Eksekutif

**Kalo.** adalah aplikasi pelacak kalori berbasis Flutter untuk target pengguna Gen Z. Aplikasi ini dibangun menggunakan Flutter + Riverpod + Supabase dengan arsitektur feature-first. Proyek sudah memiliki fondasi yang solid dan MVP sebagian besar sudah terimplementasi, namun terdapat beberapa bug kritis, isu keamanan, dan fitur yang belum lengkap yang perlu diselesaikan sebelum siap untuk rilis produksi.

### Skor Audit Keseluruhan

| Kategori | Skor | Status |
|---|---|---|
| Arsitektur & Struktur Kode | 7/10 | 🟡 Baik dengan catatan |
| Fitur vs PRD | 6/10 | 🟡 60% dari PRD selesai |
| Keamanan | 4/10 | 🔴 Perlu perhatian segera |
| Kualitas Kode | 6/10 | 🟡 Perlu perbaikan |
| Performa | 7/10 | 🟡 Cukup baik |
| UX/UI | 7/10 | 🟢 Desain bersih & konsisten |
| **TOTAL** | **6.2/10** | **🟡 Layak Dilanjutkan** |

---

## 2. 🏗️ Arsitektur & Struktur Project

### Struktur Direktori

```
lib/
├── core/
│   ├── constants/        ✅ AppStrings, SupabaseConstants
│   ├── providers/        ✅ profileProvider
│   └── services/         ✅ StreakService
├── features/
│   ├── auth/             ✅ Login, Register, Onboarding
│   ├── home/             ✅ Dashboard + Widgets
│   ├── logging/          ✅ Add Food, Create Food
│   ├── history/          ✅ Food History
│   ├── profile/          ✅ Profile Management
│   └── water/            ✅ Water Tracking
└── main.dart             ✅ App Entry + AuthGate
```

### Arsitektur Pattern

- **Pattern:** Feature-first dengan pemisahan `data/` dan `presentation/` layer — ✅ Tepat
- **State Management:** Riverpod (`FutureProvider`, `Provider`, `ConsumerWidget`) — ✅ Pilihan yang baik
- **Navigation:** `Navigator.push()` langsung, belum menggunakan `go_router` — ⚠️ Inkonsistensi dengan dependency yang dideclare
- **Repository Pattern:** Setiap fitur memiliki repository — ✅ Baik

### Temuan Arsitektur

> [!WARNING]
> **go_router** sudah terdaftar di `pubspec.yaml` tapi **tidak digunakan sama sekali**. Semua navigasi masih menggunakan `Navigator.push()` manual, termasuk deep linking yang tidak bisa berfungsi dengan baik.

> [!NOTE]
> **flutter_dotenv** terdaftar di pubspec tapi tidak diimplementasikan. Supabase URL dan Anon Key ditulis hardcoded langsung di `main.dart` sebagai plain text.

---

## 3. 🔐 Keamanan — KRITIS

### ❌ BUG KRITIS #1: API Key Terekspos di Source Code

**File:** [`main.dart` L14-16](file:///Users/cahyo/Developer/Mobile/Kalo./lib/main.dart#L14-L16)

```dart
await Supabase.initialize(
  url: 'https://raygnspffroqtgcxcuma.supabase.co',  // ❌ HARDCODED
  anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',  // ❌ HARDCODED
);
```

**Risiko:** Credential Supabase (URL + Anon Key) terekspos langsung di source code. Jika repository ini publik, siapapun bisa mengakses database Anda. Meskipun `flutter_dotenv` sudah di-install, tidak digunakan.

**Perbaikan yang Harus Dilakukan:**
```dart
// Di .env file (sudah dikecualikan dari git via .gitignore)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key

// Di main.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
await dotenv.load();
await Supabase.initialize(
  url: dotenv.env['SUPABASE_URL']!,
  anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
);
```

> [!CAUTION]
> **Action Immediate:** Rotate/regenerate Supabase Anon Key sekarang jika repo ini sudah pernah di-push ke git public. Cek `.gitignore` apakah `.env` sudah dikecualikan.

### ⚠️ Potensi Keamanan Lainnya

| Isu | File | Severity |
|---|---|---|
| `profileProvider` menggunakan `user!.id` tanpa null check aman | `profile_provider.dart` L9 | Medium |
| Error dari Supabase di-expose ke user melalui SnackBar | Semua file | Low |
| Tidak ada validasi input angka untuk weight/height | `onboarding_page.dart` | Medium |
| `print("API Error: $e")` di production code | `food_repository.dart` L54 | Low |

---

## 4. 🐛 Bug & Masalah Kode

### ❌ BUG #2: Dead Code di `profile_page.dart`

**File:** [`profile_page.dart` L56-61](file:///Users/cahyo/Developer/Mobile/Kalo./lib/features/profile/presentation/profile_page.dart#L56-L61)

```dart
if (_isManualTarget) {
  newTarget = int.parse(_manualCalController.text);
} else {
  newTarget = int.parse(_manualCalController.text);  // ❌ SAMA PERSIS!
}
```

Kedua branch `if/else` melakukan hal yang identik. Toggle `_isManualTarget` ada di code tapi tidak pernah diubah dari UI (tidak ada Switch di ProfilePage seperti di OnboardingPage). Logika re-kalkulasi TDEE seharusnya ada di sini jika user mengubah berat/tinggi, tapi tidak diimplementasikan.

### ❌ BUG #3: Streak Tidak Pernah Diperbarui

**File:** [`food_repository.dart`](file:///Users/cahyo/Developer/Mobile/Kalo./lib/features/logging/data/food_repository.dart), [`auth_repository.dart`](file:///Users/cahyo/Developer/Mobile/Kalo./lib/features/auth/data/auth_repository.dart)

PRD mendefinisikan aturan streak yang jelas:
- Streak +1 jika user log makanan hari ini DAN kemarin
- Streak reset ke 1 jika kemarin tidak log
- Streak reset ke 0 jika tidak ada log sama sekali

**Masalah:** Tidak ada kode yang memperbarui `current_streak` di tabel `profiles` saat user melakukan food log. `StreakService` hanya menghandle milestone celebration (menggunakan SharedPreferences), bukan logika kalkulasi streak itu sendiri. Kolom `last_log_date` yang disebutkan di PRD juga tidak ada di schema README maupun migration.

### ⚠️ MASALAH #4: Minimum Search 3 Karakter (Inkonsistensi)

**File:** [`add_food_page.dart` L25](file:///Users/cahyo/Developer/Mobile/Kalo./lib/features/logging/presentation/add_food_page.dart#L25)

```dart
if (query.length < 3) return;
```

Tapi UI hint menampilkan: `"Type at least 3 characters to search"`. PRD mendefinisikan autocomplete minimum **2 karakter**, kode menggunakan **3 karakter**. Tidak konsisten dengan PRD.

### ⚠️ MASALAH #5: Tidak Ada Fitur Delete Food Log

User tidak bisa menghapus log makanan yang sudah dibuat. Tidak ada swipe-to-delete atau tombol hapus di `home_page.dart` maupun `history_page.dart`. Ini sangat menghambat UX.

### ⚠️ MASALAH #6: `fontFamily` Salah

**File:** [`main.dart` L33](file:///Users/cahyo/Developer/Mobile/Kalo./lib/main.dart#L33)

```dart
fontFamily: 'GoogleFonts.poppins',  // ❌ Ini bukan cara yang benar!
```

Ini bukan cara yang benar untuk menerapkan Google Fonts. String `'GoogleFonts.poppins'` tidak akan menghasilkan font apapun. Cara yang benar:

```dart
import 'package:google_fonts/google_fonts.dart';
// ...
theme: GoogleFonts.poppinsTextTheme().copyWith(...),
// atau
textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
```

### ⚠️ MASALAH #7: Age Calculation Tidak Akurat

**File:** [`onboarding_page.dart` L73](file:///Users/cahyo/Developer/Mobile/Kalo./lib/features/auth/presentation/onboarding_page.dart#L73)

```dart
final age = DateTime.now().year - _birthDate!.year;
```

Kalkulasi umur ini tidak memperhitungkan apakah ulang tahun user di tahun ini sudah lewat atau belum. Contoh: User lahir 31 Desember 2000, saat diakses di Januari 2026, umur dihitung 26 tapi seharusnya 25.

**Perbaikan:**
```dart
final now = DateTime.now();
int age = now.year - _birthDate!.year;
if (now.month < _birthDate!.month || 
    (now.month == _birthDate!.month && now.day < _birthDate!.day)) {
  age--;
}
```

### ⚠️ MASALAH #8: `withOpacity()` Deprecated

**File:** Banyak file (home_page.dart, macro_progress_rings.dart, dll)

```dart
Colors.black.withOpacity(0.02)  // ⚠️ Deprecated di Flutter 3.x terbaru
```

Gunakan `Colors.black.withValues(alpha: 0.02)` atau `Color.fromRGBO()`.

### ⚠️ MASALAH #9: Tidak Ada Barcode Scanner Integration

**File:** [`add_food_page.dart`](file:///Users/cahyo/Developer/Mobile/Kalo./lib/features/logging/presentation/add_food_page.dart)

`mobile_scanner: ^7.1.4` sudah di-install tapi tidak diintegrasikan ke UI sama sekali. README pun mencatat: `'mobile_scanner' (Pending integration)`. Barcode scanner adalah fitur utama PRD (6.2.2) yang belum selesai.

### 🔴 BUG #10: Format Tanggal Tidak Konsisten saat Log Makanan

**File:** [`food_repository.dart` L123](file:///Users/cahyo/Developer/Mobile/Kalo./lib/features/logging/data/food_repository.dart#L123)

```dart
'log_date': DateTime.now().toIso8601String(),  // ❌ Menyimpan DATETIME penuh
```

Query di `history_repository.dart` dan `home_repository.dart` memfilter dengan format `yyyy-MM-dd`, tapi log disimpan dengan format ISO penuh (`2026-08-29T13:00:00.000`). Jika kolom `log_date` bertipe `timestamptz`, query `.eq('log_date', '2026-08-29')` tidak akan match → **log tidak muncul di dashboard/history**.

**Perbaikan:**
```dart
'log_date': DateTime.now().toIso8601String().split('T')[0],  // '2026-08-29'
```

### 🔴 BUG #11: Bug Statistik Rata-Rata Makro di Weekly Insights

**File:** [`insights_repository.dart` L67-69](file:///Users/cahyo/Developer/Mobile/Kalo./lib/features/home/data/insights_repository.dart#L67-L69)

```dart
'avgProtein': (totalP / 7).round(),  // ❌ Selalu dibagi 7
'avgCarbs':   (totalC / 7).round(),  // ❌ Bukan daysLogged!
'avgFats':    (totalF / 7).round(),
```

Jika user hanya log 3 hari, rata-rata makro dihitung 2.3x lebih rendah dari yang seharusnya. Seharusnya dibagi `daysLogged` (dengan guard `daysLogged > 0`).

### 🔴 BUG #12: Streak Milestone Dialog Muncul Berulang saat Pull-to-Refresh

**File:** [`home_page.dart` L121-136](file:///Users/cahyo/Developer/Mobile/Kalo./lib/features/home/presentation/home_page.dart#L121-L136)

`addPostFrameCallback` dipanggil setiap kali widget rebuild (termasuk pull-to-refresh). Setiap refresh → milestone check dipanggil lagi → dialog bisa muncul berlapis sebelum `markCelebrated()` sempat dipanggil.

### 🔴 BUG #13: Memory Leak di `WaterBottomSheet`

**File:** [`water_bottom_sheet.dart`](file:///Users/cahyo/Developer/Mobile/Kalo./lib/features/water/presentation/water_bottom_sheet.dart)

`TextEditingController` untuk input target air dibuat di dalam `Consumer` builder — setiap kali provider refresh, controller baru dibuat tanpa `dispose()` controller lama → **memory leak**.

### ⚠️ MASALAH #14: Bug Navigasi Hari di `history_page.dart`

**File:** [`history_page.dart`](file:///Users/cahyo/Developer/Mobile/Kalo./lib/features/history/presentation/history_page.dart)

```dart
// ❌ Hanya cek .day, tidak cek .month dan .year!
onPressed: _selectedDate.day == DateTime.now().day ? null : ...
```

Tanggal 15 Agustus dan 15 September akan dianggap sama → user bisa navigate ke masa depan (bulan yang berbeda tapi tanggal sama tidak dikunci).

### ⚠️ MASALAH #15: `FutureProvider.family` dengan `DateTime` Key Tidak di-normalize

**File:** [`history_repository.dart` L9-13](file:///Users/cahyo/Developer/Mobile/Kalo./lib/features/history/data/history_repository.dart#L9-L13)

`DateTime` include jam/menit/detik sebagai key — setiap instance `DateTime` yang berbeda meski date-nya sama dianggap key berbeda oleh Riverpod. Provider juga tidak menggunakan `autoDispose` → semua history yang pernah dibuka tetap di memory. Gunakan `String` (`'yyyy-MM-dd'`) sebagai key + tambahkan `autoDispose`.

---

## 5. 📊 Status Implementasi Fitur vs PRD

### Fitur MVP (dari PRD Section 3.1)

| Fitur | Status | Catatan |
|---|---|---|
| Authentication (Register/Login) | ✅ Selesai | Berfungsi baik |
| Onboarding (TDEE Calculator) | ✅ Selesai | Ada bug kalkulasi umur |
| Database Makanan (Local Search) | ✅ Selesai | Menggunakan pg_trgm |
| Barcode Scanner | ❌ Belum | Package installed, tidak diintegrasikan |
| Daily Food Logging | ✅ Selesai | Tidak ada fitur delete |
| Daily Streak | ⚠️ Partial | UI ada, logika update tidak ada |
| Dashboard | ✅ Selesai | Lengkap dengan macro rings |

### Fitur Tambahan (Beyond PRD)

| Fitur | Status | Catatan |
|---|---|---|
| Water Tracking | ✅ Selesai | Feature yang baik! |
| Weekly Insights | ✅ Selesai | Rata-rata 7 hari |
| Streak Milestones & Dialog | ✅ Selesai | Confetti + Dialog |
| History by Date | ✅ Selesai | Navigation per hari |
| External API (OpenFoodFacts) | ✅ Selesai | Hybrid search |
| Macro Tracking | ✅ Selesai | Protein/Carbs/Fat rings |

### Persentase Implementasi PRD
```
MVP Features:     5/7 = 71% selesai
Total Features:   12/14 = 86% (termasuk bonus features)
```

---

## 6. 🗄️ Database & Backend

### Schema yang Ada (dari README + Migrations)

```sql
-- Tabel Utama
profiles          -- Data user + target kalori + streak
foods             -- Database makanan (public shared)
food_logs         -- Jurnal harian user
water_logs        -- Log minum air (dari migration 001)
```

### Kolom Tambahan (Migration 001)
```sql
profiles.protein_target_gram   -- Target protein (default 150g)
profiles.carbs_target_gram     -- Target carbs (default 200g)
profiles.fats_target_gram      -- Target fats (default 67g)
profiles.water_target_ml       -- Target air (default 2000ml)
```

### Isu Database

> [!WARNING]
> **`last_log_date`** tidak ada di schema. PRD mendefinisikan kolom ini untuk logika streak, tapi kolom ini belum dibuat. Ini adalah root cause mengapa streak tidak bisa berfungsi.

> [!NOTE]
> **Performa:** Migration `002` sudah menambahkan index `gin_trgm` untuk pencarian makanan — bagus! Tapi query di `home_repository.dart` tidak menggunakan select yang optimal (seharusnya hanya select kolom yang diperlukan saja).

### RLS (Row Level Security)

Berdasarkan PRD dan migration:
- ✅ `water_logs`: RLS sudah aktif
- ❓ `profiles`, `foods`, `food_logs`: Tidak terlihat di file migration (diasumsikan sudah diset manual di Supabase dashboard)

---

## 7. ⚡ Performa

### Yang Sudah Baik
- `FutureProvider.autoDispose` digunakan — provider dibersihkan saat tidak digunakan ✅
- Debounce 500ms pada search input ✅
- `shrinkWrap: true` dengan `NeverScrollableScrollPhysics` untuk list di dalam scroll ✅
- Index database untuk query yang sering (`idx_food_logs_user_date`, `idx_foods_name_trgm`) ✅

### Yang Perlu Diperbaiki

| Isu | Impact | File |
|---|---|---|
| Dashboard melakukan 2 query terpisah ke Supabase (profile + logs) | Medium | `home_repository.dart` |
| Water tracking melakukan 3 query terpisah (getTodayWater + getWaterTarget via profileProvider) | Medium | `water_providers.dart` |
| OpenFoodFacts API dipanggil setiap keystroke (hanya ada debounce, tidak ada caching) | High | `food_repository.dart` |
| `WidgetsBinding.instance.addPostFrameCallback` dipanggil setiap build cycle di HomePage | Medium | `home_page.dart` L121 |

---

## 8. 🎨 UX/UI

### Yang Sudah Baik
- ✅ Tema monochrome hitam-putih yang konsisten dan clean
- ✅ Circular progress indicator untuk kalori harian — visual yang kuat
- ✅ Macro rings (protein/carbs/fat) yang informatif
- ✅ Water progress ring yang intuitif
- ✅ Streak milestone dialog dengan efek visual
- ✅ Debounced search dengan loading indicator
- ✅ Pull-to-refresh di dashboard

### Yang Perlu Diperbaiki

| Isu | Prioritas |
|---|---|
| Tidak ada hapus food log (swipe-to-delete atau long-press) | Tinggi |
| Portion slider (0.1x - 5.0x) ambigu — user tidak tahu ini multiplier per 100g | Tinggi |
| Tidak ada tombol scan barcode di Add Food page | Tinggi |
| History page tidak bisa navigate ke hari-hari sebelumnya secara intuitif (tidak ada date picker) | Medium |
| `AppStrings` semuanya dalam bahasa Inggris, tapi PRD menyebut target user adalah Gen Z Indonesia | Medium |
| Tidak ada empty state yang baik di History page | Low |
| Streak counter di AppBar selalu rebuild saat dashboard refresh | Low |

---

## 9. 🧪 Testing

**Tidak ada satupun unit test atau widget test** yang ditulis. Folder `test/` hanya berisi file boilerplate default Flutter.

> [!IMPORTANT]
> Sebelum melanjutkan fitur baru, sangat disarankan untuk menulis minimal:
> - Unit test untuk `_calculateTDEE()` di `onboarding_page.dart`
> - Unit test untuk logika streak kalkulasi
> - Unit test untuk `_parseNutrient()` di `food_repository.dart`

---

## 10. 📦 Dependencies

### Status Dependencies

| Package | Versi | Digunakan | Catatan |
|---|---|---|---|
| `flutter_riverpod` | ^3.2.0 | ✅ | State management utama |
| `supabase_flutter` | ^2.12.0 | ✅ | Backend |
| `go_router` | ^17.0.1 | ❌ **Tidak digunakan** | Waste, atau belum dimigrasi |
| `google_fonts` | ^8.0.0 | ⚠️ Salah implementasi | Font tidak ter-apply benar |
| `mobile_scanner` | ^7.1.4 | ❌ **Tidak digunakan** | Belum diintegrasikan |
| `flutter_dotenv` | ^6.0.0 | ❌ **Tidak digunakan** | Harusnya untuk env vars |
| `confetti` | ^0.7.0 | ✅ | Milestone dialog |
| `http` | ^1.6.0 | ✅ | OpenFoodFacts API |
| `intl` | ^0.20.2 | ✅ | Formatting tanggal |
| `gap` | ^3.0.1 | ✅ | Spacing widget |
| `shared_preferences` | ^2.5.4 | ✅ | Streak celebration tracking |
| `flutter_native_splash` | ^2.4.7 | ✅ | Splash screen |
| `flutter_launcher_icons` | ^0.14.4 | ✅ (dev) | App icon |

**3 package diinstall tapi tidak digunakan** — membesar ukuran APK tanpa manfaat.

---

## 11. 🗺️ Roadmap Perbaikan yang Disarankan

### 🔴 Prioritas Segera (Sebelum Melanjutkan Fitur Baru)

1. **Pindahkan credentials ke `.env`** — Keamanan kritis
2. **Perbaiki logika update streak** — Fitur utama gamifikasi tidak berfungsi
3. **Integrasikan Barcode Scanner** — Fitur MVP yang sudah di-install tapi belum jalan
4. **Tambah fitur Delete Food Log** — UX blocker

### 🟡 Prioritas Menengah (Dalam 2 Sprint)

5. **Perbaiki implementasi Google Fonts** — Font sekarang tidak ter-apply
6. **Perbaiki kalkulasi umur** untuk TDEE yang akurat
7. **Migrasi navigasi ke go_router** atau hapus dependency jika tidak diperlukan
8. **Tambahkan kolom `last_log_date`** ke tabel `profiles`
9. **Perbaiki ProfilePage** — logika update target kalori dengan re-kalkulasi TDEE

### 🟢 Prioritas Rendah / Nice-to-Have

10. Tambah unit tests untuk logika bisnis kritis
11. Implementasikan caching untuk hasil search OpenFoodFacts
12. Tambah date picker di History page
13. Ganti `withOpacity()` deprecated dengan `withValues()`
14. Tambah validasi input yang lebih ketat (angka positif, range logis)
15. Pertimbangkan offline support (cache last state)

---

## 12. 💡 Arsitektur yang Disarankan ke Depan

Untuk proyek yang lebih besar dan maintainable, pertimbangkan:

```
lib/
├── core/
│   ├── constants/
│   ├── errors/           ← [NEW] Custom exceptions & error handling
│   ├── extensions/       ← [NEW] DateTime extensions, dll
│   ├── providers/
│   ├── services/
│   └── utils/            ← [NEW] Validators, formatters
├── features/
│   └── [feature]/
│       ├── data/
│       │   ├── models/   ← [NEW] Data classes / DTO
│       │   └── [feature]_repository.dart
│       └── presentation/
│           ├── [feature]_page.dart
│           ├── providers/ ← [NEW] Feature-specific providers
│           └── widgets/
└── router.dart           ← [NEW] go_router centralized routing
```

---

## 13. ✅ Checklist Sebelum Melanjutkan

- [ ] Rotate Supabase credentials jika repo pernah public
- [ ] Implementasikan `flutter_dotenv` untuk env vars
- [ ] Tambahkan kolom `last_log_date` ke tabel `profiles` via migration
- [ ] Implementasikan logika update streak di `food_repository.dart`
- [ ] Integrasikan `mobile_scanner` ke `add_food_page.dart`
- [ ] Tambahkan swipe-to-delete di food log
- [ ] Perbaiki implementasi `GoogleFonts.poppins`
- [ ] Perbaiki kalkulasi umur di `onboarding_page.dart`
- [ ] Perbaiki dead code di `profile_page.dart`
- [ ] Verifikasi RLS policy untuk semua tabel di Supabase dashboard

---

*Laporan ini dibuat berdasarkan analisis source code statis. Beberapa isu runtime mungkin berbeda dengan kondisi aktual deployment.*
