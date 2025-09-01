# Testing Database Path Configuration

## Perubahan yang Dilakukan

1. **Konfigurasi Database**: Path database di `config/database.json` diubah dari path absolut ke relative menggunakan tilde notation (`~/DewaruciCpp/app/dewarucidb`)

2. **DatabaseConfig**: Ditambahkan fungsi `expandPath()` untuk mengexpand tilde (`~`) ke home directory user

3. **PathUtils**: Utilitas baru untuk menangani path sistem dengan berbagai fungsi helper

## Lokasi Database Baru

Database sekarang akan dibuat di:

- **Windows**: `C:\Users\[USERNAME]\DewaruciCpp\app\dewarucidb\dewaruci.db`
- **Linux**: `/home/[USERNAME]/DewaruciCpp/app/dewarucidb/dewaruci.db`
- **macOS**: `/Users/[USERNAME]/DewaruciCpp/app/dewarucidb/dewaruci.db`

## Cara Testing

### 1. Manual Testing

Jalankan aplikasi utama dan periksa log output untuk melihat path database yang digunakan.

### 2. Automated Testing

```bash
# Jalankan script testing (Windows)
test_database_path.bat

# Atau build dan run manual
cmake -S . -B build-test
cmake --build build-test --config Debug
build-test/Debug/testDatabasePath.exe
```

### 3. Verifikasi Manual

1. Jalankan aplikasi
2. Periksa apakah direktori `~/DewaruciCpp/app/dewarucidb/` dibuat di home directory
3. Periksa apakah file `dewaruci.db` ada di direktori tersebut
4. Cek log aplikasi untuk memastikan database terkoneksi

## Files yang Dimodifikasi

- `config/database.json` - Path diubah ke tilde notation
- `src/database/DatabaseConfig.h` - Tambah fungsi expandPath dan expandedDatabasePath
- `src/database/DatabaseConfig.cpp` - Implementasi ekspansi tilde
- `src/utils/PathUtils.h` - Utilitas path baru
- `src/database/DatabaseExample.cpp` - Tambah info path dalam testing
- `main.cpp` - Sudah ada inisialisasi database
- `DATABASE_README.md` - Update dokumentasi

## Keuntungan Perubahan

1. **Portabilitas**: Database otomatis mengikuti home directory user
2. **Multi-user**: Setiap user memiliki database terpisah
3. **Konsistensi**: Path sama di semua platform (Windows/Linux/Mac)
4. **Keamanan**: Database di area user, bukan system directory

## Troubleshooting

Jika ada masalah:

1. Periksa apakah home directory dapat diakses
2. Pastikan user memiliki permission write ke home directory
3. Cek log aplikasi untuk error path expansion
4. Verifikasi path dengan `PathUtils::getPathInfo()`
