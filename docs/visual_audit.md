# 🎨 Laporan Audit Visual & UX — Kalo.
**Tanggal:** 29 Agustus 2026 | **Platform:** Android (Flutter) | **Target User:** Gen Z Indonesia

---

## Ringkasan Eksekutif

App **Kalo.** sudah punya fondasi visual yang bersih — namun terasa **terlalu steril dan impersonal** untuk target Gen Z. Saat ini desainnya fungsional tapi tidak *memorable*. Perlu penyegaran yang mempertahankan kesederhanaan sekaligus menambah karakter dan kehangatan.

> [!IMPORTANT]
> Tujuan redesign bukan ganti total — cukup **evolusi**: ganti palet warna ke yang lebih warm, perbaiki tipografi, dan tingkatkan konsistensi komponen. Codebase yang ada bisa tetap dipakai dengan perubahan tema saja.

---

## Kondisi Visual Saat Ini

![Current UI State](/Users/cahyo/.gemini/antigravity/brain/06d0e94d-d898-48c1-b968-941f996095b3/kalo_current_ui_audit_1787983726073.jpg)

### Masalah Utama yang Ditemukan

| # | Masalah | Layar | Dampak |
|---|---------|-------|--------|
| V1 | Background putih murni `#FFFFFF` — terasa klinis/dingin | Semua | Tinggi |
| V2 | Font Poppins tidak ter-apply (bug kode) — sistem fallback | Semua | Tinggi |
| V3 | Input field pakai `OutlineInputBorder` default — terasa kaku | Login, Onboarding | Medium |
| V4 | Warna biru di Water Sheet `Colors.blue` tidak konsisten dengan tema monochrome | Water Sheet | Medium |
| V5 | Macro rings pakai `CircularProgressIndicator` bawaan — tidak ada animasi/polish | Dashboard | Medium |
| V6 | FAB teks "Log Food" — bahasa Inggris, target user Indonesia | Dashboard | Medium |
| V7 | AppBar style default Material — tidak ada karakter | Semua | Medium |
| V8 | Food log cards terasa flat, tidak ada hierarchy visual | Dashboard, History | Low |
| V9 | Error/empty state generik (icon abu + teks kecil) | Add Food, History | Low |
| V10 | Tidak ada onboarding illustration / visual welcome | Login, Onboarding | Low |

---

## Analisis Per Layar

### 1. 🔐 Login Page

**Kondisi Saat Ini:**
- Title "Kalo." menggunakan `displayLarge` — ukuran tergantung sistem, tidak terkontrol
- Subtitle hardcoded bahasa Inggris ("Hello, welcome back!")
- Input field pakai `OutlineInputBorder` dengan border abu — terasa form pajak
- Tidak ada visual interest apapun — pure white + black text
- Tidak ada toggle show/hide password
- Tidak ada ilustrasi atau elemen brand

**Yang Diusulkan:**
- Background `#FAFAF8` (warm off-white)
- Blob/shape dekoratif subtle di bagian atas (sage green transparan)
- "Kalo." wordmark dengan Poppins Black, period berwarna accent green
- Tagline Indonesia: *"Track bareng, konsisten bareng."*
- Input field dengan `filled: true`, rounded corner `16`, tanpa border, shadow tipis
- CTA button pill-shape, full width, `borderRadius: 100`

---

### 2. 📊 Dashboard / Home

**Kondisi Saat Ini:**
- AppBar dengan title "Kalo. / Dashboard" — terasa kaku
- Greeting tidak personal (tidak ada nama user)
- Macro rings menggunakan `CircularProgressIndicator` — tidak ada animasi masuk
- Water ring terlihat terpisah/tidak connected dengan macro
- Weekly Insights card terasa seperti tabel, kurang visual
- Food log list flat, tidak ada grouping per meal type
- FAB "Log Food" — bahasa Inggris

**Yang Diusulkan:**
- Ganti AppBar dengan custom header: "Selamat pagi, [nama] 👋"
- Streak badge tetap di kanan tapi lebih premium (pill orange dengan flame emoji)
- Ganti macro rings → **horizontal pill progress bars** (lebih mudah dibaca, lebih modern)
- Grouping food log by meal type (Sarapan / Makan Siang / Makan Malam / Camilan)
- FAB → "➕ Tambah Makanan" (Indonesia)

---

### 3. 🔍 Add Food Page

**Kondisi Saat Ini:**
- Search bar ada di AppBar (Material default) — tidak prominent
- List hasil: `ListTile` standard dengan `CircleAvatar` biru/hijau — tidak informatif
- Tombol barcode scanner tidak ada di UI (fitur belum diintegrasikan)
- Empty state campuran — ketika belum search, pesan sama dengan "makanan tidak ketemu"
- Tidak ada pemisahan visual antara hasil lokal vs OpenFoodFacts

**Yang Diusulkan:**
- Search bar sebagai komponen besar di bawah header, bukan di AppBar
- Tombol **scan barcode** yang prominent (icon besar di kanan search bar)
- Dua section jelas: "📦 Dari Database Kita" dan "🌐 Dari OpenFoodFacts"
- Food result cards dengan emoji/icon makanan, kalori + makro preview
- "Tidak ketemu?" section di bawah dengan CTA "Buat Makanan Baru"

---

### 4. 📅 History Page

**Kondisi Saat Ini:**
- Date navigator dengan chevron kiri/kanan di dalam `Container(color: Colors.grey[50])` — terasa kurang terintegrasi
- Summary card hitam polos — kontras ok tapi makro data kecil dan padat
- Log list: waktu + nama makanan + kalori — tidak ada visual cue untuk meal type
- Tidak ada warna pembeda antar meal type

**Yang Diusulkan:**
- Date navigator pill-shaped, centered, lebih elegan
- Summary card dark charcoal dengan macro pills berwarna (bukan teks putih biasa)
- Log list dengan left border color per meal type:
  - 🌅 Sarapan → Orange `#F4832A`
  - ☀️ Makan Siang → Blue `#5BA3D5`
  - 🌙 Makan Malam → Purple `#7B6CA8`
  - ☕ Camilan → Pink `#D4849B`

---

### 5. 👤 Profile Page

**Kondisi Saat Ini:**
- `CircleAvatar` hitam dengan icon `Icons.person` — sangat generic
- Tidak menampilkan nama user (hanya email)
- Input fields sama dengan onboarding — tidak ada feel "settings" yang berbeda
- Tombol logout merah — ok, tapi posisi di bawah terasa afterthought

**Yang Diusulkan:**
- Avatar dengan initial huruf nama user atau avatar placeholder yang lebih friendly
- Header card dengan gradient subtle, tampilkan nama + email
- Kelompokkan settings dalam section cards (Data Fisik / Target / Akun)
- Tambahkan streak stats mini di profile header

---

### 6. 💧 Water Bottom Sheet

**Kondisi Saat Ini:**
- Tombol quick add menggunakan `Colors.blue[300]` border — warna biru tidak match dengan tema monochrome keseluruhan
- Save button untuk custom amount biru, save button untuk target hitam — **2 warna berbeda untuk fungsi yang mirip**
- Section target ada divider di tengah — terasa seperti 2 sheet yang digabung paksa

**Yang Diusulkan:**
- Quick add buttons: pill shape dengan background `Colors.blue[50]` dan teks biru (lebih subtle)
- Unifikasi semua button ke 1 style
- Pisahkan "Set Target" ke dalam pengaturan profile, bukan di bottom sheet yang sama

---

## 🎨 Design System yang Diusulkan

![Design System](/Users/cahyo/.gemini/antigravity/brain/06d0e94d-d898-48c1-b968-941f996095b3/kalo_design_tokens_1787983909168.jpg)

### Palet Warna

| Token | Warna | Hex | Penggunaan |
|-------|-------|-----|------------|
| `background` | Warm Off-White | `#FAFAF8` | Background semua layar |
| `surface` | White | `#FFFFFF` | Cards, bottom sheets |
| `onBackground` | Charcoal | `#1A1A1A` | Teks utama, CTA button |
| `textSecondary` | Grey | `#9B9B9B` | Label, subtitle |
| `protein` | Sage Green | `#6B9E6B` | Protein progress, sukses |
| `carbs` | Warm Amber | `#E8A87C` | Karbo progress, warning |
| `fat` | Coral Red | `#E07070` | Lemak progress, danger |
| `water` | Sky Blue | `#5BA3D5` | Water tracking |
| `streak` | Vibrant Orange | `#F4832A` | Streak badge, gamifikasi |
| `border` | Light Grey | `#EBEBEB` | Border cards, dividers |

### Tipografi — Poppins (Perlu diperbaiki di code dulu!)

```dart
// Cara yang benar menerapkan Poppins di Flutter:
import 'package:google_fonts/google_fonts.dart';

ThemeData get appTheme => ThemeData(
  textTheme: GoogleFonts.poppinsTextTheme(),
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6B9E6B)),
  useMaterial3: true,
  scaffoldBackgroundColor: const Color(0xFFFAFAF8),
);
```

| Style | Size | Weight | Line Height |
|-------|------|--------|-------------|
| Display | 48sp | 900 | 1.0 |
| H1 | 24sp | 700 | 1.3 |
| H2 | 18sp | 600 | 1.4 |
| Body | 14sp | 400 | 1.5 |
| Caption | 12sp | 400 | 1.4 |

### Border Radius (Design Language: "Rounded Everything")

```dart
// AppTheme constants
static const double radiusSmall   = 8.0;   // Tags, chips kecil
static const double radiusMedium  = 12.0;  // Cards, buttons
static const double radiusLarge   = 16.0;  // Bottom sheets, modals
static const double radiusXLarge  = 20.0;  // Hero cards
static const double radiusPill    = 100.0; // FAB, pill buttons, input fields
```

### Spacing (8px Grid System)

```dart
static const double sp4  = 4.0;
static const double sp8  = 8.0;
static const double sp12 = 12.0;
static const double sp16 = 16.0;
static const double sp24 = 24.0;
static const double sp32 = 32.0;
static const double sp48 = 48.0;
```

---

## Mockup Redesign

### Login + Dashboard

![Redesign Login & Dashboard](/Users/cahyo/.gemini/antigravity/brain/06d0e94d-d898-48c1-b968-941f996095b3/kalo_redesign_login_dashboard_1787983760510.jpg)

### Add Food + History

![Redesign Add Food & History](/Users/cahyo/.gemini/antigravity/brain/06d0e94d-d898-48c1-b968-941f996095b3/kalo_redesign_food_history_1787983794513.jpg)

---

## 🧩 Komponen Baru yang Diusulkan

### A. `AppTheme` — Tema Terpusat
Buat file `lib/core/theme/app_theme.dart` yang mendefinisikan semua warna, typography, dan komponen sebagai sumber kebenaran tunggal.

### B. Macro Progress Bar (Ganti dari Circular Ring)
```dart
// Ganti MacroProgressRings → MacroProgressBars
// Lebih readable, lebih modern, lebih space-efficient
Widget _buildMacroBar(String label, int current, int target, Color color) {
  return Row(children: [
    Container(width: 10, height: 10, decoration: BoxDecoration(
      color: color, borderRadius: BorderRadius.circular(3)
    )),
    Gap(8),
    Text(label), // "Protein"
    Spacer(),
    Text("$current / $target g"),
    Gap(12),
    // Progress bar
    SizedBox(width: 80, child: LinearProgressIndicator(
      value: (current / target).clamp(0, 1),
      color: color,
      backgroundColor: color.withValues(alpha: 0.1),
    )),
  ]);
}
```

### C. Meal Type Color System
```dart
// lib/core/constants/meal_colors.dart
static Color getMealColor(String mealType) {
  switch (mealType) {
    case 'Breakfast': return const Color(0xFFF4832A); // Orange
    case 'Lunch':     return const Color(0xFF5BA3D5); // Blue
    case 'Dinner':    return const Color(0xFF7B6CA8); // Purple
    case 'Snack':     return const Color(0xFFD4849B); // Pink
    default:          return Colors.grey;
  }
}
```

### D. `KaloCard` — Base Card Widget
```dart
// Komponen card yang konsisten digunakan di seluruh app
class KaloCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  
  const KaloCard({super.key, required this.child, this.padding, this.color});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
```

---

## 📋 Prioritas Implementasi

### 🔴 Phase 1 — Quick Wins (1-2 hari)
Perubahan yang **tidak butuh desain ulang besar**, dampak langsung terasa:

1. **Fix font Poppins** — satu baris di `ThemeData` (bug kode, bukan masalah desain)
2. **Ganti `scaffoldBackgroundColor`** dari `#FFFFFF` ke `#FAFAF8` — langsung terasa lebih warm
3. **Ganti FAB label** dari "Log Food" → "Tambah Makanan"
4. **Unifikasi warna button** di `WaterBottomSheet` (hapus `Colors.blue` raw)
5. **Tambahkan `filled: true`** pada semua TextField + set `fillColor: Color(0xFFF2F2EF)`

```dart
// Satu perubahan di ThemeData, langsung affect semua input:
inputDecorationTheme: InputDecorationTheme(
  filled: true,
  fillColor: const Color(0xFFF2F2EF),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide.none,
  ),
),
```

### 🟡 Phase 2 — Component Refresh (3-5 hari)
Redesain komponen per layar tanpa mengubah arsitektur:

6. Login page: tambah visual blob + tagline Indonesia
7. Dashboard: ganti greeting + tambah nama user
8. Macro rings → horizontal bars
9. History: tambah meal type color system (left border)
10. Add Food: pindah search bar dari AppBar ke body, tambah barcode button

### 🟢 Phase 3 — Polish & Delight (5-7 hari)
Detail yang membuat user merasa "wow":

11. Animasi masuk pada calorie ring (`AnimatedBuilder` / `Tween`)
12. Micro-interaction pada food log card (swipe to delete dengan feedback)
13. Streak milestone dialog yang lebih premium (Lottie animation atau custom painter)
14. Empty states yang menarik dengan ilustrasi mini
15. Dark mode support (opsional)

---

## ✅ Checklist Visual Audit

### Segera Diperbaiki
- [ ] Fix `fontFamily: 'GoogleFonts.poppins'` → implementasi benar via `GoogleFonts.poppinsTextTheme()`
- [ ] Ganti `scaffoldBackgroundColor` → `#FAFAF8`
- [ ] Hapus `Colors.blue` raw di `water_bottom_sheet.dart`
- [ ] Buat `AppTheme` class terpusat
- [ ] Ganti semua label bahasa Inggris ke Bahasa Indonesia

### Perbaikan Medium
- [ ] Buat `KaloCard` widget terpusat
- [ ] Implementasi `MealColorSystem` 
- [ ] Redesain input fields (filled, rounded, no border)
- [ ] Tambah barcode scan button di Add Food page
- [ ] Tambah greeting personal di Dashboard ("Selamat pagi, [nama]")
- [ ] Ganti macro circular rings → horizontal pill bars

### Perbaikan Jangka Panjang
- [ ] Animasi calorie ring
- [ ] Swipe-to-delete dengan haptic feedback
- [ ] Ilustrasi empty state
- [ ] Streak celebration yang lebih engaging (Lottie)
- [ ] Pertimbangkan Bottom Navigation Bar (Home / History / Profile)

---

*Audit visual ini berdasarkan analisis kode sumber. Screenshot aktual perlu diverifikasi dengan menjalankan app di device.*
