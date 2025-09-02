#include "StructureProfileTable.h"
#include "../DatabaseConnection.h"
#include <QSqlRecord>
#include <QVariantMap>

StructureProfileTable::StructureProfileTable(QObject *parent)
    : QObject(parent)
{
}

bool StructureProfileTable::createTable()
{
    if (!DatabaseConnection::instance().isConnected()) {
        m_lastError = "Database is not connected";
        qCritical() << "StructureProfileTable::createTable() -" << m_lastError;
        return false;
    }

    QSqlQuery query(DatabaseConnection::instance().database());
    
    QString createTableSql = R"(
        CREATE TABLE IF NOT EXISTS structure_seagoing_ship_section0_profile_table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT,
            name TEXT,
            hw REAL,
            tw REAL,
            bf_profiles REAL,
            tf REAL,
            area REAL,
            e REAL,
            w REAL,
            upper_i REAL,
            lower_l REAL,
            tb REAL,
            bf_brackets REAL,
            tbf REAL,
            created_at INTEGER DEFAULT (strftime('%s', 'now') * 1000),
            updated_at INTEGER DEFAULT (strftime('%s', 'now') * 1000)
        )
    )";
    
    if (!query.exec(createTableSql)) {
        m_lastError = QString("Failed to create table: %1").arg(query.lastError().text());
        qCritical() << "StructureProfileTable::createTable() -" << m_lastError;
        return false;
    }
    
    // Create index for faster lookups
    QString createIndexSql = "CREATE INDEX IF NOT EXISTS idx_profile_name ON structure_seagoing_ship_section0_profile_table(name)";
    if (!query.exec(createIndexSql)) {
        qWarning() << "StructureProfileTable::createTable() - Failed to create index:" << query.lastError().text();
    }
    
    qDebug() << "StructureProfileTable::createTable() - Table created successfully";
    return true;
}

bool StructureProfileTable::insertProfile(const QString& type, const QString& name, double hw, double tw,
                                          double bfProfiles, double tf, double area, double e, double w,
                                          double upperI, double lowerL, double tb, double bfBrackets, double tbf)
{
    if (!DatabaseConnection::instance().isConnected()) {
        m_lastError = "Database is not connected";
        qCritical() << "StructureProfileTable::insertProfile() -" << m_lastError;
        return false;
    }
    
    QSqlQuery query(DatabaseConnection::instance().database());
    query.prepare(R"(
        INSERT INTO structure_seagoing_ship_section0_profile_table (type, name, hw, tw, bf_profiles, tf, area, e, w, upper_i, lower_l, tb, bf_brackets, tbf)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    )");
    
    query.addBindValue(type);
    query.addBindValue(name);
    query.addBindValue(hw);
    query.addBindValue(tw);
    query.addBindValue(bfProfiles);
    query.addBindValue(tf);
    query.addBindValue(area);
    query.addBindValue(e);
    query.addBindValue(w);
    query.addBindValue(upperI);
    query.addBindValue(lowerL);
    query.addBindValue(tb);
    query.addBindValue(bfBrackets);
    query.addBindValue(tbf);
    
    if (!executeQuery(query, "insertProfile")) {
        return false;
    }
    
    int newId = query.lastInsertId().toInt();
    qDebug() << "StructureProfileTable::insertProfile() - Profile inserted with ID:" << newId;
    emit profileInserted(newId);
    return true;
}

bool StructureProfileTable::updateProfile(int id, const QString& type, const QString& name, double hw, double tw,
                                          double bfProfiles, double tf, double area, double e, double w,
                                          double upperI, double lowerL, double tb, double bfBrackets, double tbf)
{
    if (!DatabaseConnection::instance().isConnected()) {
        m_lastError = "Database is not connected";
        qCritical() << "StructureProfileTable::updateProfile() -" << m_lastError;
        return false;
    }
    
    QSqlQuery query(DatabaseConnection::instance().database());
    query.prepare(R"(
        UPDATE structure_seagoing_ship_section0_profile_table 
        SET type = ?, name = ?, hw = ?, tw = ?, bf_profiles = ?, tf = ?, area = ?, e = ?, w = ?, upper_i = ?, lower_l = ?, tb = ?, bf_brackets = ?, tbf = ?,
            updated_at = strftime('%s', 'now') * 1000
        WHERE id = ?
    )");
    
    query.addBindValue(type);
    query.addBindValue(name);
    query.addBindValue(hw);
    query.addBindValue(tw);
    query.addBindValue(bfProfiles);
    query.addBindValue(tf);
    query.addBindValue(area);
    query.addBindValue(e);
    query.addBindValue(w);
    query.addBindValue(upperI);
    query.addBindValue(lowerL);
    query.addBindValue(tb);
    query.addBindValue(bfBrackets);
    query.addBindValue(tbf);
    query.addBindValue(id);
    
    if (!executeQuery(query, "updateProfile")) {
        return false;
    }
    
    qDebug() << "StructureProfileTable::updateProfile() - Profile updated, ID:" << id;
    emit profileUpdated(id);
    return true;
}

bool StructureProfileTable::deleteProfile(int id)
{
    if (!DatabaseConnection::instance().isConnected()) {
        m_lastError = "Database is not connected";
        qCritical() << "StructureProfileTable::deleteProfile() -" << m_lastError;
        return false;
    }
    
    QSqlQuery query(DatabaseConnection::instance().database());
    query.prepare("DELETE FROM structure_seagoing_ship_section0_profile_table WHERE id = ?");
    query.addBindValue(id);
    
    if (!executeQuery(query, "deleteProfile")) {
        return false;
    }
    
    qDebug() << "StructureProfileTable::deleteProfile() - Profile deleted, ID:" << id;
    emit profileDeleted(id);
    return true;
}

bool StructureProfileTable::deleteProfileByName(const QString& name)
{
    if (!DatabaseConnection::instance().isConnected()) {
        m_lastError = "Database is not connected";
        qCritical() << "StructureProfileTable::deleteProfileByName() -" << m_lastError;
        return false;
    }
    
    QSqlQuery query(DatabaseConnection::instance().database());
    query.prepare("DELETE FROM structure_seagoing_ship_section0_profile_table WHERE name = ?");
    query.addBindValue(name);
    
    if (!executeQuery(query, "deleteProfileByName")) {
        return false;
    }
    
    qDebug() << "StructureProfileTable::deleteProfileByName() - Profile deleted, Name:" << name;
    return true;
}

ProfileData StructureProfileTable::findProfileById(int id)
{
    ProfileData profile = {};
    
    if (!DatabaseConnection::instance().isConnected()) {
        m_lastError = "Database is not connected";
        qCritical() << "StructureProfileTable::findProfileById() -" << m_lastError;
        return profile;
    }
    
    QSqlQuery query(DatabaseConnection::instance().database());
    query.prepare("SELECT * FROM structure_seagoing_ship_section0_profile_table WHERE id = ?");
    query.addBindValue(id);
    
    if (!executeQuery(query, "findProfileById")) {
        return profile;
    }
    
    if (query.next()) {
        profile = createProfileFromQuery(query);
        qDebug() << "StructureProfileTable::findProfileById() - Profile found, ID:" << id;
    } else {
        qDebug() << "StructureProfileTable::findProfileById() - Profile not found, ID:" << id;
    }
    
    return profile;
}

ProfileData StructureProfileTable::findProfileByName(const QString& name)
{
    ProfileData profile = {};
    
    if (!DatabaseConnection::instance().isConnected()) {
        m_lastError = "Database is not connected";
        qCritical() << "StructureProfileTable::findProfileByName() -" << m_lastError;
        return profile;
    }
    
    QSqlQuery query(DatabaseConnection::instance().database());
    query.prepare("SELECT * FROM structure_seagoing_ship_section0_profile_table WHERE name = ?");
    query.addBindValue(name);
    
    if (!executeQuery(query, "findProfileByName")) {
        return profile;
    }
    
    if (query.next()) {
        profile = createProfileFromQuery(query);
        qDebug() << "StructureProfileTable::findProfileByName() - Profile found, Name:" << name;
    } else {
        qDebug() << "StructureProfileTable::findProfileByName() - Profile not found, Name:" << name;
    }
    
    return profile;
}

QList<ProfileData> StructureProfileTable::getAllProfiles()
{
    QList<ProfileData> profiles;
    
    if (!DatabaseConnection::instance().isConnected()) {
        m_lastError = "Database is not connected";
        qCritical() << "StructureProfileTable::getAllProfiles() -" << m_lastError;
        return profiles;
    }
    
    QSqlQuery query(DatabaseConnection::instance().database());
    QString sql = "SELECT * FROM structure_seagoing_ship_section0_profile_table ORDER BY name";
    
    if (!query.exec(sql)) {
        m_lastError = QString("Failed to fetch profiles: %1").arg(query.lastError().text());
        qCritical() << "StructureProfileTable::getAllProfiles() -" << m_lastError;
        return profiles;
    }
    
    while (query.next()) {
        ProfileData profile = createProfileFromQuery(query);
        profiles.append(profile);
    }
    
    qDebug() << "StructureProfileTable::getAllProfiles() - Found" << profiles.size() << "profiles";
    return profiles;
}

bool StructureProfileTable::clearAllProfiles()
{
    if (!DatabaseConnection::instance().isConnected()) {
        m_lastError = "Database is not connected";
        qCritical() << "StructureProfileTable::clearAllProfiles() -" << m_lastError;
        return false;
    }
    
    QSqlQuery query(DatabaseConnection::instance().database());
    if (!query.exec("DELETE FROM structure_seagoing_ship_section0_profile_table")) {
        m_lastError = QString("Failed to clear profiles: %1").arg(query.lastError().text());
        qCritical() << "StructureProfileTable::clearAllProfiles() -" << m_lastError;
        return false;
    }
    
    qDebug() << "StructureProfileTable::clearAllProfiles() - All profiles cleared";
    return true;
}

bool StructureProfileTable::insertSampleData()
{
    struct SampleProfile {
        QString type;
        QString name;
        double hw, tw, bfProfiles, tf, area, e, w, upperI, lowerL, tb, bfBrackets, tbf;
    };
    
    QList<SampleProfile> samples = {
        {"I-Beam", "IPE200", 200.0, 5.6, 100.0, 8.5, 28.5, 19.4, 22.4, 19.4, 10.0, 0.0, 0.0, 0.0},
        {"H-Beam", "HEA240", 230.0, 7.5, 240.0, 12.0, 76.8, 27.7, 60.3, 27.7, 12.0, 0.0, 0.0, 0.0},
        {"L-Angle", "L100x10", 100.0, 10.0, 100.0, 10.0, 19.2, 2.9, 15.1, 2.9, 7.0, 0.0, 0.0, 0.0}
    };
    
    bool success = true;
    for (const auto& sample : samples) {
        if (!insertProfile(sample.type, sample.name, sample.hw, sample.tw, sample.bfProfiles, 
                          sample.tf, sample.area, sample.e, sample.w, sample.upperI, 
                          sample.lowerL, sample.tb, sample.bfBrackets, sample.tbf)) {
            success = false;
            qWarning() << "Failed to insert sample profile:" << sample.name;
        }
    }
    
    return success;
}

// QML accessible functions
QVariantList StructureProfileTable::getAllProfilesForQML()
{
    QVariantList result;
    QList<ProfileData> profiles = getAllProfiles();
    
    for (const ProfileData& profile : profiles) {
        QVariantMap profileMap;
        profileMap["id"] = profile.id;
        profileMap["type"] = profile.type;
        profileMap["name"] = profile.name;
        profileMap["hw"] = profile.hw;
        profileMap["tw"] = profile.tw;
        profileMap["bfProfiles"] = profile.bfProfiles;
        profileMap["tf"] = profile.tf;
        profileMap["area"] = profile.area;
        profileMap["e"] = profile.e;
        profileMap["w"] = profile.w;
        profileMap["upperI"] = profile.upperI;
        profileMap["lowerL"] = profile.lowerL;
        profileMap["tb"] = profile.tb;
        profileMap["bfBrackets"] = profile.bfBrackets;
        profileMap["tbf"] = profile.tbf;
        profileMap["createdAt"] = profile.createdAt;
        profileMap["updatedAt"] = profile.updatedAt;
        
        result.append(profileMap);
    }
    
    return result;
}

bool StructureProfileTable::addProfile(const QString& type, const QString& name, double hw, double tw,
                                      double bfProfiles, double tf, double area, double e, double w,
                                      double upperI, double lowerL, double tb, double bfBrackets, double tbf)
{
    return insertProfile(type, name, hw, tw, bfProfiles, tf, area, e, w, upperI, lowerL, tb, bfBrackets, tbf);
}

bool StructureProfileTable::updateProfileQML(int id, const QString& type, const QString& name, double hw, double tw,
                                             double bfProfiles, double tf, double area, double e, double w,
                                             double upperI, double lowerL, double tb, double bfBrackets, double tbf)
{
    // Check if profile exists
    ProfileData existing = findProfileById(id);
    if (existing.id == 0) {
        m_lastError = "Profile not found";
        return false;
    }
    
    return updateProfile(id, type, name, hw, tw, bfProfiles, tf, area, e, w, upperI, lowerL, tb, bfBrackets, tbf);
}

bool StructureProfileTable::removeProfile(int id)
{
    return deleteProfile(id);
}

QString StructureProfileTable::getLastError() const
{
    return m_lastError;
}

// Private helper methods
bool StructureProfileTable::executeQuery(QSqlQuery& query, const QString& operation)
{
    if (!query.exec()) {
        m_lastError = QString("Failed to execute %1: %2").arg(operation, query.lastError().text());
        qCritical() << "StructureProfileTable::executeQuery() -" << m_lastError;
        emit error(m_lastError);
        return false;
    }
    return true;
}

ProfileData StructureProfileTable::createProfileFromQuery(const QSqlQuery& query)
{
    ProfileData profile;
    profile.id = query.value("id").toInt();
    profile.type = query.value("type").toString();
    profile.name = query.value("name").toString();
    profile.hw = query.value("hw").toDouble();
    profile.tw = query.value("tw").toDouble();
    profile.bfProfiles = query.value("bf_profiles").toDouble();
    profile.tf = query.value("tf").toDouble();
    profile.area = query.value("area").toDouble();
    profile.e = query.value("e").toDouble();
    profile.w = query.value("w").toDouble();
    profile.upperI = query.value("upper_i").toDouble();
    profile.lowerL = query.value("lower_l").toDouble();
    profile.tb = query.value("tb").toDouble();
    profile.bfBrackets = query.value("bf_brackets").toDouble();
    profile.tbf = query.value("tbf").toDouble();
    profile.createdAt = query.value("created_at").toLongLong();
    profile.updatedAt = query.value("updated_at").toLongLong();
    return profile;
}
