# DewaruciCpp Database Configuration

Proyek ini telah dikonfigurasi dengan sistem database SQLite yang lengkap untuk koneksi ke database di home directory user: `~/DewaruciCpp/app/dewarucidb`

## Path Database

Database akan otomatis menggunakan home directory user dengan struktur:

- **Windows**: `C:\Users\[USERNAME]\DewaruciCpp\app\dewarucidb\dewaruci.db`
- **Linux/Mac**: `/home/[USERNAME]/DewaruciCpp/app/dewarucidb/dewaruci.db`

Path ini dikonfigurasi menggunakan tilde notation (`~`) yang akan otomatis di-expand ke home directory user yang sedang aktif.

## Struktur Database

### File Konfigurasi

- `config/database.json` - Konfigurasi database utama
- `src/database/DatabaseConfig.h/cpp` - Kelas untuk membaca konfigurasi
- `src/database/DatabaseManager.h/cpp` - Pengelola koneksi database
- `src/database/Database.h` - Header utama untuk kemudahan penggunaan
- `src/utils/PathUtils.h` - Utilitas untuk menangani path sistem

### Model Database

- `src/database/models/BaseModel.h/cpp` - Model dasar untuk semua entitas
- `src/database/models/UserModel.h/cpp` - Contoh model User

## Penggunaan

### 1. Inisialisasi Database

Database akan otomatis diinisialisasi saat aplikasi dimulai melalui `main.cpp`. Anda juga bisa melakukannya secara manual:

```cpp
#include "src/database/Database.h"

// Inisialisasi dengan konfigurasi default
if (Database::initialize()) {
    qDebug() << "Database berhasil diinisialisasi";
}

// Atau dengan file konfigurasi custom
if (Database::initialize("path/to/custom/config.json")) {
    qDebug() << "Database berhasil diinisialisasi dengan konfigurasi custom";
}
```

### 2. Membuat Tabel

```cpp
if (Database::createTables()) {
    qDebug() << "Tabel database berhasil dibuat";
}
```

### 3. Menggunakan Model User

```cpp
#include "src/database/models/UserModel.h"

// Membuat user baru
UserModel* user = new UserModel();
user->setUsername("john_doe");
user->setEmail("john@example.com");
user->setPasswordHash("hashed_password");

if (user->save()) {
    qDebug() << "User berhasil disimpan dengan ID:" << user->id();
}

// Mencari user berdasarkan username
UserModel* foundUser = UserModel::findByUsername("john_doe");
if (foundUser) {
    qDebug() << "User ditemukan:" << foundUser->email();
    delete foundUser;
}

// Mendapatkan semua user
QList<UserModel*> users = UserModel::getAllUsers();
for (UserModel* u : users) {
    qDebug() << "User:" << u->username() << u->email();
    delete u;
}
```

### 4. Query Manual

```cpp
DatabaseManager& db = Database::manager();

// Query dengan parameter
QSqlQuery query = db.executeQuery("SELECT * FROM users WHERE email = ?", {"test@example.com"});
while (query.next()) {
    qDebug() << "Username:" << query.value("username").toString();
}

// Transaction
if (db.beginTransaction()) {
    bool success = db.executeNonQuery("INSERT INTO users (username, email) VALUES (?, ?)",
                                      {"test_user", "test@test.com"});
    if (success) {
        db.commitTransaction();
    } else {
        db.rollbackTransaction();
    }
}
```

## Konfigurasi Database

File `config/database.json` berisi:

```json
{
  "database": {
    "type": "sqlite",
    "path": "~/DewaruciCpp/app/dewarucidb",
    "name": "dewaruci.db",
    "connectionName": "DewaruciConnection",
    "options": {
      "timeout": 30000,
      "synchronous": "NORMAL",
      "journal_mode": "WAL",
      "foreign_keys": true
    }
  },
  "logging": {
    "enabled": true,
    "level": "INFO",
    "logQueries": false
  }
}
```

### Parameter Konfigurasi

- **type**: Jenis database (sqlite)
- **path**: Path direktori database (mendukung tilde notation `~` untuk home directory)
- **name**: Nama file database
- **connectionName**: Nama koneksi unik
- **timeout**: Timeout koneksi dalam milliseconds
- **synchronous**: Mode sinkronisasi SQLite (OFF, NORMAL, FULL)
- **journal_mode**: Mode journal SQLite (DELETE, TRUNCATE, PERSIST, MEMORY, WAL, OFF)
- **foreign_keys**: Aktifkan foreign key constraints

## Membuat Model Baru

Untuk membuat model database baru, extend dari `BaseModel`:

```cpp
// UserModel.h
class MyModel : public BaseModel
{
    Q_OBJECT
    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)

public:
    explicit MyModel(QObject* parent = nullptr);

    QString name() const { return m_name; }
    void setName(const QString& name);

    // Implementasi BaseModel
    QString tableName() const override { return "my_table"; }
    QStringList fieldNames() const override { return {"name"}; }
    QVariantMap toVariantMap() const override;
    void fromVariantMap(const QVariantMap& map) override;

signals:
    void nameChanged();

private:
    QString m_name;
};
```

## Build Project

Pastikan Qt6 Sql module tersedia, kemudian build seperti biasa:

```bash
mkdir build
cd build
cmake ..
cmake --build .
```

## Path Management

Proyek ini menyertakan utilitas untuk menangani path sistem:

```cpp
#include "src/utils/PathUtils.h"

// Dapatkan home directory
QString homeDir = PathUtils::getHomeDirectory();

// Expand tilde notation
QString expanded = PathUtils::expandTilde("~/DewaruciCpp/data");

// Dapatkan path default aplikasi
QString appDir = PathUtils::getAppDataDirectory();

// Pastikan direktori exists
if (PathUtils::ensureDirectoryExists("~/DewaruciCpp/logs")) {
    qDebug() << "Directory created successfully";
}

// Debug informasi path
qDebug().noquote() << PathUtils::getPathInfo();
```

## Troubleshooting

1. **Database tidak terhubung**: Periksa path database dan pastikan direktori ada
2. **Permission error**: Pastikan aplikasi memiliki izin write ke direktori database
3. **Qt Sql module not found**: Install Qt6 dengan Sql component

## Schema Database Default

Sistem akan membuat tabel berikut secara otomatis:

### users

- id (INTEGER PRIMARY KEY AUTOINCREMENT)
- username (TEXT NOT NULL UNIQUE)
- email (TEXT NOT NULL UNIQUE)
- password_hash (TEXT NOT NULL)
- created_at (DATETIME DEFAULT CURRENT_TIMESTAMP)
- updated_at (DATETIME DEFAULT CURRENT_TIMESTAMP)

### settings

- key (TEXT PRIMARY KEY)
- value (TEXT NOT NULL)
- created_at (DATETIME DEFAULT CURRENT_TIMESTAMP)
- updated_at (DATETIME DEFAULT CURRENT_TIMESTAMP)
