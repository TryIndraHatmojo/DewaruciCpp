# Material Database API

Database sederhana untuk mengelola data material linear isotropic. API ini menyediakan fungsi CRUD (Create, Read, Update, Delete) yang mudah digunakan.

## Struktur Data MaterialData

```cpp
struct MaterialData {
    int id;                    // ID unik (auto-generated)
    int matNo;                 // Nomor material
    int eModulus;              // Modulus elastisitas
    int gModulus;              // Modulus geser
    int materialDensity;       // Densitas material
    int yieldStress;           // Tegangan luluh
    int tensileStrength;       // Kekuatan tarik
    QString remark;            // Keterangan
};
```

## Cara Penggunaan

### 1. Inisialisasi Database

```cpp
#include "src/database/MaterialDatabase.h"

// Inisialisasi database
if (!MaterialDatabase::instance().initialize()) {
    qCritical() << "Failed to initialize database:" << MaterialDatabase::instance().lastError();
}
```

### 2. Insert Data (CREATE)

```cpp
// Insert material baru
bool success = MaterialDatabase::instance().insertMaterial(
    1,           // matNo
    206000000,   // eModulus
    79230769,    // gModulus
    8000,        // materialDensity
    235,         // yieldStress
    400,         // tensileStrength
    "NT24"       // remark
);

if (!success) {
    qDebug() << "Insert failed:" << MaterialDatabase::instance().lastError();
}
```

### 3. Update Data (UPDATE)

```cpp
// Update material berdasarkan ID
bool success = MaterialDatabase::instance().updateMaterial(
    5,           // id (dari database)
    1,           // matNo
    206000000,   // eModulus
    79230769,    // gModulus
    8000,        // materialDensity
    250,         // yieldStress (nilai baru)
    420,         // tensileStrength (nilai baru)
    "NT24-Modified" // remark (nilai baru)
);

if (!success) {
    qDebug() << "Update failed:" << MaterialDatabase::instance().lastError();
}
```

### 4. Find Data (READ)

```cpp
// Cari berdasarkan ID
MaterialData material = MaterialDatabase::instance().findMaterialById(5);
if (material.id > 0) {
    qDebug() << "Found material:" << material.matNo << material.remark;
} else {
    qDebug() << "Material not found";
}

// Cari berdasarkan mat_no
MaterialData material2 = MaterialDatabase::instance().findMaterialByMatNo(1);
if (material2.id > 0) {
    qDebug() << "Found material with mat_no 1:" << material2.remark;
}

// Ambil semua data
QList<MaterialData> allMaterials = MaterialDatabase::instance().getAllMaterials();
qDebug() << "Total materials:" << allMaterials.size();

for (const MaterialData& mat : allMaterials) {
    qDebug() << "ID:" << mat.id << "MatNo:" << mat.matNo << "Remark:" << mat.remark;
}
```

### 5. Delete Data (DELETE)

```cpp
// Hapus berdasarkan ID
bool success = MaterialDatabase::instance().deleteMaterial(5);
if (!success) {
    qDebug() << "Delete failed:" << MaterialDatabase::instance().lastError();
}

// Hapus berdasarkan mat_no
bool success2 = MaterialDatabase::instance().deleteMaterialByMatNo(1);
if (!success2) {
    qDebug() << "Delete failed:" << MaterialDatabase::instance().lastError();
}
```

### 6. Utility Functions

```cpp
// Insert sample data (7 material contoh)
MaterialDatabase::instance().insertSampleData();

// Hapus semua data
MaterialDatabase::instance().clearAllMaterials();

// Cek koneksi database
if (MaterialDatabase::instance().isConnected()) {
    qDebug() << "Database connected";
}

// Tutup koneksi
MaterialDatabase::instance().close();
```

### 7. Signal Handling

```cpp
// Connect ke signals untuk notifikasi
QObject::connect(&MaterialDatabase::instance(), &MaterialDatabase::materialInserted,
                [](int id) {
                    qDebug() << "Material inserted with ID:" << id;
                });

QObject::connect(&MaterialDatabase::instance(), &MaterialDatabase::materialUpdated,
                [](int id) {
                    qDebug() << "Material updated, ID:" << id;
                });

QObject::connect(&MaterialDatabase::instance(), &MaterialDatabase::materialDeleted,
                [](int id) {
                    qDebug() << "Material deleted, ID:" << id;
                });

QObject::connect(&MaterialDatabase::instance(), &MaterialDatabase::error,
                [](const QString& message) {
                    qCritical() << "Database error:" << message;
                });
```

## File Database

Database SQLite akan dibuat di: `data/dewaruci.db` (relative to project root)

## Error Handling

Semua fungsi mengembalikan `bool` untuk status sukses/gagal, dan detail error bisa didapat dengan:

```cpp
QString error = MaterialDatabase::instance().lastError();
```

## Logging

Database akan otomatis membuat log untuk setiap operasi dengan level `qDebug()`, `qWarning()`, dan `qCritical()`.
