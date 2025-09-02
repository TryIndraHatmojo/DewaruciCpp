# ProfileController

Controller untuk mengelola operasi CRUD pada tabel `structure_seagoing_ship_section0_profile_table`.

## Fitur Utama

### 1. **CRUD Operations**

- `createProfile()` - Membuat profil baru dengan validasi
- `updateProfile()` - Update profil berdasarkan ID
- `deleteProfile()` - Hapus profil berdasarkan ID
- `deleteProfileByName()` - Hapus profil berdasarkan nama

### 2. **Query Operations**

- `getProfileById()` - Ambil profil berdasarkan ID
- `getProfileByName()` - Ambil profil berdasarkan nama
- `refreshProfiles()` - Refresh data dari database

### 3. **Batch Operations**

- `clearAllProfiles()` - Hapus semua profil
- `loadSampleData()` - Load data contoh

### 4. **Search & Filter**

- `searchProfiles()` - Cari profil berdasarkan nama/tipe
- `filterProfilesByType()` - Filter berdasarkan tipe profil
- `getAvailableTypes()` - Ambil daftar tipe yang tersedia

### 5. **Validation**

- Validasi input data (nama tidak kosong, nilai numerik valid)
- Validasi format nama (alphanumeric + simbol umum)
- Validasi rentang nilai (tidak negatif, tidak terlalu besar)
- Cek duplikasi nama profil

### 6. **Properties & Signals**

- `profiles` - Daftar profil yang dapat diakses dari QML
- `lastError` - Error terakhir
- `isLoading` - Status loading
- Signals: `profilesChanged`, `operationCompleted`, dll.

## Penggunaan di QML

### Basic Usage

```qml
// Membuat profil baru
profileController.createProfile(
    "I-Beam",           // type
    "IPE200",           // name
    200.0,              // hw
    5.6,                // tw
    100.0,              // bfProfiles
    8.5,                // tf
    28.5,               // area
    19.4,               // e
    22.4,               // w
    19.4,               // upperI
    10.0,               // lowerL
    0.0,                // tb
    0.0,                // bfBrackets
    0.0                 // tbf
)

// Update profil
profileController.updateProfile(id, type, name, hw, tw, ...)

// Hapus profil
profileController.deleteProfile(profileId)

// Cari profil
var results = profileController.searchProfiles("IPE")

// Filter berdasarkan tipe
var iBeams = profileController.filterProfilesByType("I-Beam")
```

### Properties Binding

```qml
ListView {
    model: profileController.profiles

    delegate: Item {
        Text { text: modelData.name }
        Text { text: "Type: " + modelData.type }
        Text { text: "HW: " + modelData.hw }
    }
}

Text {
    text: "Total profiles: " + profileController.getProfileCount()
}

Text {
    text: profileController.lastError
    visible: profileController.lastError !== ""
    color: "red"
}

BusyIndicator {
    running: profileController.isLoading
}
```

### Signals Handling

```qml
Connections {
    target: profileController

    function onProfilesChanged() {
        console.log("Profiles updated")
    }

    function onOperationCompleted(success, message) {
        statusText.text = message
        statusText.color = success ? "green" : "red"
    }
}
```

## Integrasi di main.cpp

```cpp
#include "src/controllers/ProfileController.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    // Initialize database
    DatabaseConnection::instance().initialize();

    // Create controller
    ProfileController* profileController = new ProfileController(&app);
    profileController->initialize();

    // Register to QML
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("profileController", profileController);

    engine.loadFromModule("DewaruciCpp", "Main");
    return app.exec();
}
```

## Validasi Data

Controller melakukan validasi komprehensif:

1. **Required Fields**: Type dan name tidak boleh kosong
2. **Numeric Values**: Semua nilai numerik harus >= 0
3. **Minimum Values**: Dimensi kritis (hw, tw, tf) harus >= nilai minimum
4. **Maximum Values**: Nilai tidak boleh > 10000 (unreasonable)
5. **Name Format**: Hanya alphanumeric, space, hyphen, underscore, dot
6. **Uniqueness**: Nama profil harus unik

## Error Handling

- Semua operasi mengembalikan boolean (success/failure)
- Error detail tersedia di `lastError` property
- Signals `operationCompleted` memberikan feedback untuk UI
- Logging otomatis untuk debugging

## Contoh Lengkap

Lihat file `qml/examples/ProfileManagementExample.qml` untuk contoh implementasi UI lengkap yang menggunakan semua fitur controller.
