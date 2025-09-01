#ifndef PATHUTILS_H
#define PATHUTILS_H

#include <QString>
#include <QDir>
#include <QStandardPaths>

/**
 * Utilitas untuk menangani path dalam aplikasi DewaruciCpp
 */
namespace PathUtils {
    
    /**
     * Expand tilde (~) dalam path ke home directory
     * @param path Path yang mungkin mengandung tilde
     * @return Path yang sudah di-expand
     */
    inline QString expandTilde(const QString& path)
    {
        QString expandedPath = path;
        
        if (expandedPath.startsWith("~/") || expandedPath == "~") {
            QString homeDir = QStandardPaths::writableLocation(QStandardPaths::HomeLocation);
            if (expandedPath == "~") {
                expandedPath = homeDir;
            } else {
                expandedPath.replace(0, 1, homeDir);
            }
        }
        
        return QDir::toNativeSeparators(expandedPath);
    }
    
    /**
     * Dapatkan path home directory user
     * @return Path ke home directory
     */
    inline QString getHomeDirectory()
    {
        return QStandardPaths::writableLocation(QStandardPaths::HomeLocation);
    }
    
    /**
     * Dapatkan path default untuk aplikasi DewaruciCpp
     * @return Path ke direktori aplikasi di home user
     */
    inline QString getAppDataDirectory()
    {
        return expandTilde("~/DewaruciCpp");
    }
    
    /**
     * Dapatkan path default untuk database
     * @return Path ke direktori database
     */
    inline QString getDefaultDatabaseDirectory()
    {
        return expandTilde("~/DewaruciCpp/app/dewarucidb");
    }
    
    /**
     * Pastikan direktori exists, buat jika belum ada
     * @param path Path direktori
     * @return true jika direktori ada atau berhasil dibuat
     */
    inline bool ensureDirectoryExists(const QString& path)
    {
        QDir dir;
        if (!dir.exists(path)) {
            return dir.mkpath(path);
        }
        return true;
    }
    
    /**
     * Dapatkan informasi path yang digunakan untuk debugging
     * @return QString dengan informasi path sistem
     */
    inline QString getPathInfo()
    {
        QString info;
        info += QString("Home Directory: %1\n").arg(getHomeDirectory());
        info += QString("App Data Directory: %1\n").arg(getAppDataDirectory());
        info += QString("Database Directory: %1\n").arg(getDefaultDatabaseDirectory());
        info += QString("Documents Location: %1\n").arg(QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation));
        info += QString("App Data Location: %1\n").arg(QStandardPaths::writableLocation(QStandardPaths::AppDataLocation));
        return info;
    }
}

#endif // PATHUTILS_H
