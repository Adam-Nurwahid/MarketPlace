# NACC Marketplace

Aplikasi marketplace multi-seller berbasis web. Customer bisa mencari dan membeli produk dari beberapa toko sekaligus, seller mengelola toko dan pesanan, dan admin mengelola seluruh platform. Dibangun dengan **Flutter Web** untuk frontend dan **Supabase** (Auth, PostgreSQL, Storage, RPC) untuk backend. Pembayaran berupa simulasi.

## Daftar Isi

1. [Tech Stack](#1-tech-stack)
2. [Arsitektur](#2-arsitektur)
3. [Struktur Folder](#3-struktur-folder)
4. [Fitur per Role](#4-fitur-per-role)
5. [Alur Utama](#5-alur-utama)
6. [Skema Database](#6-skema-database)
7. [Fungsi RPC](#7-fungsi-rpc)
8. [Keamanan & Hak Akses](#8-keamanan--hak-akses)
9. [Cara Menjalankan](#9-cara-menjalankan)
10. [Deployment](#10-deployment)
11. [Catatan Pengembangan](#11-catatan-pengembangan)

---

## 1. Tech Stack

| Layer | Teknologi |
|---|---|
| UI | Flutter (Dart `^3.12.0`), Material 3 |
| Auth | Supabase Auth (email + password, JWT) |
| Database | Supabase PostgreSQL (tabel + RPC) |
| File storage | Supabase Storage, bucket `product-images` |
| Hosting | Firebase Hosting (`build/web`) |

Dependency utama: `supabase_flutter`, `image_picker`, `cupertino_icons`.

## 2. Arsitektur

```
┌────────────────────────────────────────────┐
│ Flutter Web (UI)                            │
│  features/auth · customer · seller · admin  │
├────────────────────────────────────────────┤
│ Service Layer (lib/core/services)           │
│  satu service per domain                    │
├────────────────────────────────────────────┤
│ Supabase                                    │
│  Auth (JWT) · PostgreSQL + RPC · Storage    │
└────────────────────────────────────────────┘
```

- **AuthGate** (`main.dart`): mendengarkan `onAuthStateChange`. Tanpa session menampilkan `LoginPage`, dengan session menampilkan `RoleDashboardPage`.
- **Role routing** (`RoleDashboardPage`): mengarahkan user ke shell sesuai role (`CustomerMainShell`, `SellerMainShell`, `AdminMainShell`).
- **RoleGuard** (`core/widgets/role_guard.dart`): memeriksa `profiles.role` dan `profiles.status == 'ACTIVE'`; jika tidak sesuai tampil halaman "Akses Ditolak".
- **Operasi kritis lewat RPC**: checkout, pembayaran, cancel, update status, review, dan suspend seller dijalankan sebagai function database agar validasi terjadi di server.
- **Konfigurasi** lewat `--dart-define` (`SUPABASE_URL`, `SUPABASE_ANON_KEY`), tidak ada key yang di-hardcode.
- **UI responsif**: navigasi atas untuk web, bottom navigation untuk layar kecil.

## 3. Struktur Folder

```
lib/
├── main.dart
├── core/
│   ├── services/        # akses data per domain
│   ├── theme/           # app_theme.dart
│   ├── utils/           # currency_formatter.dart
│   └── widgets/         # role_guard.dart
└── features/
    ├── auth/            # login, register
    ├── dashboard/       # router berdasarkan role
    ├── customer/        # marketplace, detail, cart, checkout, payment, pesanan
    ├── seller/          # buat toko, produk, pesanan, laporan
    └── admin/           # approval toko, pengguna, produk, transaksi
```

| Service | Tanggung jawab |
|---|---|
| `auth_service` | Register, login, logout |
| `profile_service` | Data profil user |
| `store_service` | Toko milik seller yang login |
| `product_service` | Daftar produk aktif, pencarian, URL gambar |
| `seller_product_service` | CRUD produk + upload/hapus gambar di Storage |
| `cart_service` | Cart item dan checkout |
| `address_service` | Alamat pengiriman |
| `order_service` | Pesanan customer dan cancel |
| `payment_service` | Simulasi pembayaran |
| `review_service` | Review produk |
| `seller_order_service` | Pesanan masuk dan update status |
| `seller_sales_service` | Laporan penjualan |
| `admin_*_service` | Kelola user, seller, toko, produk, transaksi |

## 4. Fitur per Role

### Customer (Marketplace · Keranjang · Pesanan · Akun)

- Register dan login
- Melihat produk aktif beserta nama toko
- Pencarian produk berdasarkan nama produk atau nama toko
- Detail produk dengan pembatasan quantity sesuai stok
- Keranjang multi-seller (item dari beberapa toko dalam satu cart)
- Checkout dengan memilih atau menambah alamat
- Simulasi pembayaran (berhasil / gagal)
- Melihat status pesanan, termasuk status per toko
- Membatalkan pesanan (saat `PENDING` atau `PROCESSING`)
- Review produk setelah pesanan `DELIVERED` (rating 1-5 + komentar)

### Seller (Toko Saya · Produk · Pesanan · Laporan)

- Register sebagai seller dan membuat toko (menunggu approval admin)
- CRUD produk: nama, deskripsi, harga, stok, status, foto produk
- Melihat pesanan masuk yang hanya berisi item dari tokonya
- Update status: `PENDING → PROCESSING → SHIPPED → DELIVERED`
- Laporan penjualan: total penjualan, order selesai, produk terjual, produk terlaris (dari order `DELIVERED`)

### Admin (Persetujuan Toko · Pengguna · Produk · Transaksi)

- Approve / reject toko berstatus `PENDING`
- Melihat dan mengelola customer dan seller
- Suspend / aktifkan kembali seller
- Mengelola produk seluruh toko
- Melihat seluruh transaksi

## 5. Alur Utama

**Order dan pembayaran**

```
Customer: tambah ke cart ─► checkout (pilih alamat)
   └► RPC checkout_cart ─► order dibuat
         └► halaman Simulasi Pembayaran
               ├─ Berhasil ─► simulate_payment(true)  ─► payment PAID
               └─ Gagal    ─► simulate_payment(false) ─► payment FAILED
Seller:   PENDING ─► PROCESSING ─► SHIPPED ─► DELIVERED
Customer: DELIVERED ─► review · PENDING/PROCESSING ─► cancel
```

Status pengiriman dilacak **per toko** (`order_store_status`), sehingga satu order berisi produk dari beberapa seller tetap punya progres berbeda per toko.

**Toko**

```
Seller register ─► buat toko (PENDING) ─► Admin approve/reject
Admin suspend seller ─► akun seller ditandai suspended
```

## 6. Skema Database

Skema ini disusun dari query yang dipakai di kode aplikasi.

| Tabel | Kolom |
|---|---|
| `profiles` | `id` (= `auth.users.id`), `name`, `email`, `role`, `status`, `is_suspended`, `created_at` |
| `stores` | `id`, `seller_id → profiles.id`, `name`, `description`, `status`, `created_at`, `updated_at` |
| `products` | `id`, `store_id → stores.id`, `name`, `description`, `price`, `stock`, `image_path`, `status` |
| `carts` | `id`, `user_id` |
| `cart_items` | `id`, `cart_id`, `product_id`, `quantity` |
| `addresses` | `id`, `user_id`, `recipient_name`, `phone`, `address_line`, `city`, `province`, `postal_code`, `is_default` |
| `orders` | `id`, `user_id`, `shipping_fee`, `total`, `status`, `created_at`, `recipient_name`, `phone`, `shipping_address` |
| `order_items` | `id`, `order_id`, `product_id`, `store_id`, `product_name`, `store_name`, `quantity`, `price`, `line_total` |
| `order_store_status` | `order_id`, `store_id`, `status`, `updated_at` |
| `payments` | `order_id`, `amount`, `status`, `paid_at` |
| `reviews` | `user_id`, `product_id`, `order_id`, `rating`, `comment` |

Storage: bucket publik `product-images`.

Nilai status:

| Entitas | Nilai |
|---|---|
| Role | `CUSTOMER`, `SELLER`, `ADMIN` |
| Order / pengiriman | `PENDING`, `PROCESSING`, `SHIPPED`, `DELIVERED`, `CANCELLED` |
| Payment | `PAID`, `FAILED` |
| Produk | `ACTIVE` tampil di marketplace |
| Toko | `PENDING` menunggu approval, lalu approved / rejected |

## 7. Fungsi RPC

| RPC | Parameter | Fungsi |
|---|---|---|
| `checkout_cart` | `p_address_id`, `p_shipping_fee` | Membuat order dari cart, mengembalikan `order_id` |
| `simulate_payment` | `p_order_id`, `p_success` | Menandai payment `PAID` atau `FAILED` |
| `customer_cancel_order` | `p_order_id` | Membatalkan pesanan milik customer |
| `seller_update_order_status` | `p_order_id`, `p_store_id`, `p_new_status` | Update status pengiriman per toko |
| `create_product_review` | `p_order_id`, `p_product_id`, `p_rating`, `p_comment` | Menyimpan review |
| `admin_toggle_seller_suspension` | `p_seller_id`, `p_is_suspended` | Suspend / aktifkan seller |

## 8. Keamanan & Hak Akses

- **Autentikasi**: JWT dari Supabase Auth. Permintaan tanpa token ditolak oleh Supabase pada tabel yang dilindungi.
- **Otorisasi di client**: `RoleGuard` membatasi halaman berdasarkan role dan status akun.
- **Otorisasi di server**: Row Level Security dan RPC memastikan seller hanya mengakses produk dan order tokonya sendiri, dan customer hanya mengakses data miliknya.
- **Validasi stok**: quantity dibatasi di UI dan divalidasi saat checkout.
- **Seller ter-suspend** dan akun non-`ACTIVE` ditolak oleh `RoleGuard`.

## 9. Cara Menjalankan

**Prasyarat:** Flutter SDK (Dart `^3.12.0`), project Supabase yang sudah berisi tabel, RPC, dan bucket `product-images`, serta Chrome.

```bash
git clone https://github.com/Adam-Nurwahid/MarketPlace.git
cd MarketPlace
flutter pub get

flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<anon-key>
```

**Setup Supabase**

1. Buat project, lalu salin Project URL dan anon key (Settings → API).
2. Buat tabel sesuai [Skema Database](#6-skema-database) dan function sesuai [RPC](#7-fungsi-rpc).
3. Buat trigger yang mengisi `profiles` saat user mendaftar (membaca `name` dan `role` dari `raw_user_meta_data`).
4. Buat bucket Storage `product-images` (public).
5. Aktifkan RLS dan policy per tabel.
6. Isi data awal (akun dan produk) sesuai kebutuhan.

## 10. Deployment

```bash
flutter build web \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...

firebase deploy --only hosting
```

`firebase.json` melayani `build/web` dan me-rewrite semua route ke `/index.html`.

## 11. Catatan Pengembangan

- Simulasi pembayaran dan ongkir sederhana dipakai agar tidak bergantung pada integrasi pihak ketiga.
- Pencarian saat ini berbasis keyword dan diproses di sisi client; filter kategori, rentang harga, dan sorting bisa ditambahkan.
- Dashboard admin berupa menu manajemen; ringkasan statistik bisa ditambahkan.
- Schema SQL, RPC, dan policy RLS sebaiknya disimpan di `supabase/migrations/` agar backend mudah direproduksi.
- `test/widget_test.dart` masih template bawaan Flutter dan perlu diganti dengan test yang relevan.
