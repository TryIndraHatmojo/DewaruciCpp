#include "Database.h"
#include "models/UserModel.h"
#include "../utils/PathUtils.h"
#include <QDebug>
#include <QCryptographicHash>

/**
 * Contoh penggunaan database dalam aplikasi DewaruciCpp
 * File ini berisi berbagai contoh operasi database yang bisa digunakan
 */

namespace DatabaseExample {

    /**
     * Test koneksi database
     */
    bool testConnection()
    {
        qDebug() << "=== Testing Database Connection ===";
        
        // Tampilkan informasi path sistem
        qDebug() << "Path Information:";
        qDebug().noquote() << PathUtils::getPathInfo();
        
        qDebug() << "Database Configuration:";
        qDebug() << "- Type:" << Database::config().databaseType();
        qDebug() << "- Raw Path:" << Database::config().databasePath();
        qDebug() << "- Full Path:" << Database::config().fullDatabasePath();
        qDebug() << "- Database Name:" << Database::config().databaseName();
        
        if (!Database::testConnection()) {
            qCritical() << "Database connection test failed!";
            qCritical() << "Error:" << Database::manager().lastError();
            return false;
        }
        
        qDebug() << "Database connection test passed!";
        return true;
    }

    /**
     * Membuat hash password sederhana
     */
    QString hashPassword(const QString& password)
    {
        QCryptographicHash hash(QCryptographicHash::Sha256);
        hash.addData(password.toUtf8());
        return hash.result().toHex();
    }

    /**
     * Contoh operasi CRUD dengan UserModel
     */
    void demonstrateUserOperations()
    {
        qDebug() << "\n=== User CRUD Operations Demo ===";

        // 1. Membuat user baru
        qDebug() << "1. Creating new users...";
        
        UserModel* user1 = new UserModel();
        user1->setUsername("admin");
        user1->setEmail("admin@dewaruci.com");
        user1->setPasswordHash(hashPassword("admin123"));
        
        if (user1->save()) {
            qDebug() << "User admin created with ID:" << user1->id();
        } else {
            qWarning() << "Failed to create admin user";
        }

        UserModel* user2 = new UserModel();
        user2->setUsername("john_doe");
        user2->setEmail("john@example.com");
        user2->setPasswordHash(hashPassword("password123"));
        
        if (user2->save()) {
            qDebug() << "User john_doe created with ID:" << user2->id();
        } else {
            qWarning() << "Failed to create john_doe user";
        }

        // 2. Mencari user berdasarkan username
        qDebug() << "\n2. Finding user by username...";
        UserModel* foundUser = UserModel::findByUsername("admin");
        if (foundUser) {
            qDebug() << "Found user:" << foundUser->username() 
                    << "Email:" << foundUser->email()
                    << "Created at:" << foundUser->createdAt().toString();
            delete foundUser;
        } else {
            qDebug() << "User not found";
        }

        // 3. Update user
        qDebug() << "\n3. Updating user...";
        user1->setEmail("admin@dewaruci.app");
        if (user1->save()) {
            qDebug() << "User updated successfully. New email:" << user1->email();
        }

        // 4. Mendapatkan semua user
        qDebug() << "\n4. Getting all users...";
        QList<UserModel*> users = UserModel::getAllUsers();
        qDebug() << "Total users:" << users.size();
        
        for (UserModel* user : users) {
            qDebug() << "- ID:" << user->id() 
                    << "Username:" << user->username() 
                    << "Email:" << user->email();
            delete user;
        }

        // 5. Validasi data
        qDebug() << "\n5. Validating user data...";
        UserModel testUser;
        testUser.setUsername("ab"); // Too short
        testUser.setEmail("invalid-email"); // Invalid format
        
        qDebug() << "Username 'ab' valid:" << testUser.validateUsername();
        qDebug() << "Email 'invalid-email' valid:" << testUser.validateEmail();
        
        testUser.setUsername("valid_user123");
        testUser.setEmail("valid@email.com");
        qDebug() << "Username 'valid_user123' valid:" << testUser.validateUsername();
        qDebug() << "Email 'valid@email.com' valid:" << testUser.validateEmail();

        // Cleanup
        delete user1;
        delete user2;
    }

    /**
     * Contoh query manual menggunakan DatabaseManager
     */
    void demonstrateManualQueries()
    {
        qDebug() << "\n=== Manual Query Demo ===";
        
        DatabaseManager& db = Database::manager();

        // 1. Query dengan parameter
        qDebug() << "1. Parameterized query...";
        QSqlQuery query = db.executeQuery(
            "SELECT COUNT(*) as user_count FROM users WHERE email LIKE ?", 
            {"%dewaruci%"}
        );
        
        if (query.next()) {
            qDebug() << "Users with 'dewaruci' in email:" << query.value("user_count").toInt();
        }

        // 2. Transaction example
        qDebug() << "\n2. Transaction demo...";
        if (db.beginTransaction()) {
            bool success1 = db.executeNonQuery(
                "INSERT INTO settings (key, value) VALUES (?, ?)", 
                {"app_version", "1.0.0"}
            );
            
            bool success2 = db.executeNonQuery(
                "INSERT INTO settings (key, value) VALUES (?, ?)", 
                {"theme", "dark"}
            );

            if (success1 && success2) {
                db.commitTransaction();
                qDebug() << "Transaction committed successfully";
            } else {
                db.rollbackTransaction();
                qDebug() << "Transaction rolled back due to error";
            }
        }

        // 3. Membaca settings
        qDebug() << "\n3. Reading settings...";
        QSqlQuery settingsQuery = db.executeQuery("SELECT * FROM settings");
        while (settingsQuery.next()) {
            qDebug() << "Setting:" << settingsQuery.value("key").toString() 
                    << "=" << settingsQuery.value("value").toString();
        }
    }

    /**
     * Menjalankan semua contoh
     */
    void runAllExamples()
    {
        qDebug() << "Starting Database Examples for DewaruciCpp...";
        
        if (!testConnection()) {
            qCritical() << "Cannot proceed without database connection";
            return;
        }

        demonstrateUserOperations();
        demonstrateManualQueries();
        
        qDebug() << "\nDatabase examples completed!";
    }
}

// Uncomment baris berikut jika ingin menjalankan contoh saat startup
// Atau panggil DatabaseExample::runAllExamples() dari tempat lain dalam aplikasi
/*
#include <QTimer>

// Tambahkan di main.cpp setelah database initialization:
QTimer::singleShot(1000, []() {
    DatabaseExample::runAllExamples();
});
*/
