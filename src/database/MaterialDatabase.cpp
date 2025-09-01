#include "MaterialDatabase.h"
#include <QStandardPaths>
#include <QDir>
#include <QSqlRecord>
#include <QCoreApplication>
#include <QFileInfo>

MaterialDatabase* MaterialDatabase::s_instance = nullptr;

MaterialDatabase& MaterialDatabase::instance()
{
    if (!s_instance) {
        s_instance = new MaterialDatabase();
    }
    return *s_instance;
}

MaterialDatabase::MaterialDatabase(QObject* parent)
    : QObject(parent)
{
}

MaterialDatabase::~MaterialDatabase()
{
    close();
}

bool MaterialDatabase::initialize()
{
    // Setup SQLite database
    m_database = QSqlDatabase::addDatabase("QSQLITE", "MaterialConnection");
    
    // Set database path to project folder database/dewaruci.db
    QString appDirPath = QCoreApplication::applicationDirPath();
    QString projectRoot;
    
    // Navigate to project root from build directory
    QDir appDir(appDirPath);
    if (appDir.dirName().contains("build") || appDir.dirName().contains("Debug") || appDir.dirName().contains("Release")) {
        // We're in build directory, go up to project root
        appDir.cdUp(); // from Debug
        if (appDir.dirName().contains("Desktop_Qt")) {
            appDir.cdUp(); // from Desktop_Qt_6_9_1_MinGW_64_bit-Debug
        }
        if (appDir.dirName() == "build") {
            appDir.cdUp(); // from build
        }
        projectRoot = appDir.absolutePath();
    } else {
        // Assume we're already in project root
        projectRoot = appDirPath;
    }
    
    QString dbPath = QDir(projectRoot).absoluteFilePath("src/database/dewaruci.db");
    
    // Create database directory if it doesn't exist
    QDir dbDir = QFileInfo(dbPath).absoluteDir();
    if (!dbDir.exists()) {
        dbDir.mkpath(".");
    }
    
    m_database.setDatabaseName(dbPath);
    
    if (!m_database.open()) {
        m_lastError = QString("Failed to open database: %1").arg(m_database.lastError().text());
        qCritical() << "MaterialDatabase::initialize() -" << m_lastError;
        qCritical() << "  Attempted path:" << dbPath;
        qCritical() << "  Project root:" << projectRoot;
        qCritical() << "  App dir:" << appDirPath;
        return false;
    }
    
    qDebug() << "MaterialDatabase::initialize() - Database opened:" << dbPath;
    
    // Create table if it doesn't exist
    if (!createTable()) {
        return false;
    }
    
    qDebug() << "MaterialDatabase::initialize() - Successfully initialized";
    return true;
}

void MaterialDatabase::close()
{
    if (m_database.isOpen()) {
        m_database.close();
        qDebug() << "MaterialDatabase::close() - Database connection closed";
    }
}

bool MaterialDatabase::isConnected() const
{
    return m_database.isOpen() && m_database.isValid();
}

bool MaterialDatabase::createTable()
{
    QSqlQuery query(m_database);
    
    QString createTableSql = R"(
        CREATE TABLE IF NOT EXISTS structure_seagoing_ship_section0_linear_isotropic_materials (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            mat_no INTEGER,
            e_modulus INTEGER,
            g_modulus INTEGER,
            material_density INTEGER,
            yield_stress INTEGER,
            remark TEXT,
            created_at INTEGER DEFAULT (strftime('%s', 'now') * 1000),
            updated_at INTEGER DEFAULT (strftime('%s', 'now') * 1000),
            tensile_strength INTEGER
        )
    )";
    
    if (!query.exec(createTableSql)) {
        m_lastError = QString("Failed to create table: %1").arg(query.lastError().text());
        qCritical() << "MaterialDatabase::createTable() -" << m_lastError;
        return false;
    }
    
    // Create index for faster lookups
    QString createIndexSql = "CREATE INDEX IF NOT EXISTS idx_mat_no ON structure_seagoing_ship_section0_linear_isotropic_materials(mat_no)";
    if (!query.exec(createIndexSql)) {
        qWarning() << "MaterialDatabase::createTable() - Failed to create index:" << query.lastError().text();
    }
    
    qDebug() << "MaterialDatabase::createTable() - Table created successfully";
    return true;
}

bool MaterialDatabase::insertMaterial(int matNo, int eModulus, int gModulus, 
                                     int materialDensity, int yieldStress, 
                                     int tensileStrength, const QString& remark)
{
    if (!isConnected()) {
        m_lastError = "Database is not connected";
        qCritical() << "MaterialDatabase::insertMaterial() -" << m_lastError;
        return false;
    }
    
    QSqlQuery query(m_database);
    query.prepare(R"(
        INSERT INTO structure_seagoing_ship_section0_linear_isotropic_materials (mat_no, e_modulus, g_modulus, material_density, 
                              yield_stress, tensile_strength, remark)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    )");
    
    query.addBindValue(matNo);
    query.addBindValue(eModulus);
    query.addBindValue(gModulus);
    query.addBindValue(materialDensity);
    query.addBindValue(yieldStress);
    query.addBindValue(tensileStrength);
    query.addBindValue(remark);
    
    if (!executeQuery(query, "insertMaterial")) {
        return false;
    }
    
    int newId = query.lastInsertId().toInt();
    qDebug() << "MaterialDatabase::insertMaterial() - Material inserted with ID:" << newId;
    emit materialInserted(newId);
    return true;
}

bool MaterialDatabase::updateMaterial(int id, int matNo, int eModulus, int gModulus, 
                                     int materialDensity, int yieldStress, 
                                     int tensileStrength, const QString& remark)
{
    if (!isConnected()) {
        m_lastError = "Database is not connected";
        qCritical() << "MaterialDatabase::updateMaterial() -" << m_lastError;
        return false;
    }
    
    QSqlQuery query(m_database);
    query.prepare(R"(
        UPDATE structure_seagoing_ship_section0_linear_isotropic_materials 
        SET mat_no = ?, e_modulus = ?, g_modulus = ?, material_density = ?,
            yield_stress = ?, tensile_strength = ?, remark = ?,
            updated_at = strftime('%s', 'now') * 1000
        WHERE id = ?
    )");
    
    query.addBindValue(matNo);
    query.addBindValue(eModulus);
    query.addBindValue(gModulus);
    query.addBindValue(materialDensity);
    query.addBindValue(yieldStress);
    query.addBindValue(tensileStrength);
    query.addBindValue(remark);
    query.addBindValue(id);
    
    if (!executeQuery(query, "updateMaterial")) {
        return false;
    }
    
    qDebug() << "MaterialDatabase::updateMaterial() - Material updated, ID:" << id;
    emit materialUpdated(id);
    return true;
}

MaterialData MaterialDatabase::findMaterialById(int id)
{
    MaterialData material = {};
    
    if (!isConnected()) {
        m_lastError = "Database is not connected";
        qCritical() << "MaterialDatabase::findMaterialById() -" << m_lastError;
        return material;
    }
    
    QSqlQuery query(m_database);
    query.prepare("SELECT * FROM structure_seagoing_ship_section0_linear_isotropic_materials WHERE id = ?");
    query.addBindValue(id);
    
    if (!executeQuery(query, "findMaterialById")) {
        return material;
    }
    
    if (query.next()) {
        material.id = query.value("id").toInt();
        material.matNo = query.value("mat_no").toInt();
        material.eModulus = query.value("e_modulus").toInt();
        material.gModulus = query.value("g_modulus").toInt();
        material.materialDensity = query.value("material_density").toInt();
        material.yieldStress = query.value("yield_stress").toInt();
        material.tensileStrength = query.value("tensile_strength").toInt();
        material.remark = query.value("remark").toString();
        
        qDebug() << "MaterialDatabase::findMaterialById() - Found material:" << material.matNo;
    } else {
        qDebug() << "MaterialDatabase::findMaterialById() - No material found with ID:" << id;
    }
    
    return material;
}

MaterialData MaterialDatabase::findMaterialByMatNo(int matNo)
{
    MaterialData material = {};
    
    if (!isConnected()) {
        m_lastError = "Database is not connected";
        qCritical() << "MaterialDatabase::findMaterialByMatNo() -" << m_lastError;
        return material;
    }
    
    QSqlQuery query(m_database);
    query.prepare("SELECT * FROM structure_seagoing_ship_section0_linear_isotropic_materials WHERE mat_no = ?");
    query.addBindValue(matNo);
    
    if (!executeQuery(query, "findMaterialByMatNo")) {
        return material;
    }
    
    if (query.next()) {
        material.id = query.value("id").toInt();
        material.matNo = query.value("mat_no").toInt();
        material.eModulus = query.value("e_modulus").toInt();
        material.gModulus = query.value("g_modulus").toInt();
        material.materialDensity = query.value("material_density").toInt();
        material.yieldStress = query.value("yield_stress").toInt();
        material.tensileStrength = query.value("tensile_strength").toInt();
        material.remark = query.value("remark").toString();
        
        qDebug() << "MaterialDatabase::findMaterialByMatNo() - Found material ID:" << material.id;
    } else {
        qDebug() << "MaterialDatabase::findMaterialByMatNo() - No material found with mat_no:" << matNo;
    }
    
    return material;
}

QList<MaterialData> MaterialDatabase::getAllMaterials()
{
    QList<MaterialData> materials;
    
    if (!isConnected()) {
        m_lastError = "Database is not connected";
        qCritical() << "MaterialDatabase::getAllMaterials() -" << m_lastError;
        return materials;
    }
    
    QSqlQuery query(m_database);
    query.prepare("SELECT * FROM structure_seagoing_ship_section0_linear_isotropic_materials ORDER BY id ASC");
    
    if (!executeQuery(query, "getAllMaterials")) {
        return materials;
    }
    
    while (query.next()) {
        MaterialData material;
        material.id = query.value("id").toInt();
        material.matNo = query.value("mat_no").toInt();
        material.eModulus = query.value("e_modulus").toInt();
        material.gModulus = query.value("g_modulus").toInt();
        material.materialDensity = query.value("material_density").toInt();
        material.yieldStress = query.value("yield_stress").toInt();
        material.tensileStrength = query.value("tensile_strength").toInt();
        material.remark = query.value("remark").toString();
        
        materials.append(material);
    }
    
    qDebug() << "MaterialDatabase::getAllMaterials() - Retrieved" << materials.size() << "materials";
    return materials;
}

bool MaterialDatabase::deleteMaterial(int id)
{
    if (!isConnected()) {
        m_lastError = "Database is not connected";
        qCritical() << "MaterialDatabase::deleteMaterial() -" << m_lastError;
        return false;
    }
    
    QSqlQuery query(m_database);
    query.prepare("DELETE FROM structure_seagoing_ship_section0_linear_isotropic_materials WHERE id = ?");
    query.addBindValue(id);
    
    if (!executeQuery(query, "deleteMaterial")) {
        return false;
    }
    
    qDebug() << "MaterialDatabase::deleteMaterial() - Material deleted, ID:" << id;
    emit materialDeleted(id);
    return true;
}

bool MaterialDatabase::deleteMaterialByMatNo(int matNo)
{
    if (!isConnected()) {
        m_lastError = "Database is not connected";
        qCritical() << "MaterialDatabase::deleteMaterialByMatNo() -" << m_lastError;
        return false;
    }
    
    QSqlQuery query(m_database);
    query.prepare("DELETE FROM structure_seagoing_ship_section0_linear_isotropic_materials WHERE mat_no = ?");
    query.addBindValue(matNo);
    
    if (!executeQuery(query, "deleteMaterialByMatNo")) {
        return false;
    }
    
    qDebug() << "MaterialDatabase::deleteMaterialByMatNo() - Material deleted, mat_no:" << matNo;
    return true;
}

bool MaterialDatabase::insertSampleData()
{
    qDebug() << "MaterialDatabase::insertSampleData() - Inserting sample materials...";
    
    // Sample data based on the table shown in the image
    QList<QPair<QList<QVariant>, QString>> sampleData = {
        {{1, 206000000, 79230769, 8000, 235, 400}, "NT24"},
        {{2, 206000000, 79230769, 8000, 315, 440}, "HT32"},
        {{3, 206000000, 79230769, 8000, 355, 490}, "HT36"},
        {{4, 206000000, 79230769, 8000, 390, 510}, "HT40"},
        {{5, 205000000, 79230769, 8000, 390, 510}, "HT30"},
        {{6, 320500000, 79230769, 8000, 390, 510}, "HT30"},
        {{7, 300000000, 79230769, 8000, 390, 510}, "HT30"}
    };
    
    bool success = true;
    for (const auto& data : sampleData) {
        QList<QVariant> values = data.first;
        QString remark = data.second;
        
        // Check if material already exists
        MaterialData existing = findMaterialByMatNo(values[0].toInt());
        if (existing.id > 0) {
            qDebug() << "Material" << values[0].toInt() << "already exists, skipping...";
            continue;
        }
        
        if (!insertMaterial(values[0].toInt(), values[1].toInt(), values[2].toInt(),
                           values[3].toInt(), values[4].toInt(), values[5].toInt(), remark)) {
            qWarning() << "Failed to insert material" << values[0].toInt();
            success = false;
        } else {
            qDebug() << "Inserted material" << values[0].toInt() << "(" << remark << ")";
        }
    }
    
    qDebug() << "MaterialDatabase::insertSampleData() - Completed. Success:" << success;
    return success;
}

bool MaterialDatabase::clearAllMaterials()
{
    if (!isConnected()) {
        m_lastError = "Database is not connected";
        qCritical() << "MaterialDatabase::clearAllMaterials() -" << m_lastError;
        return false;
    }
    
    QSqlQuery query(m_database);
    query.prepare("DELETE FROM structure_seagoing_ship_section0_linear_isotropic_materials");
    
    if (!executeQuery(query, "clearAllMaterials")) {
        return false;
    }
    
    qDebug() << "MaterialDatabase::clearAllMaterials() - All materials cleared";
    return true;
}

bool MaterialDatabase::executeQuery(QSqlQuery& query, const QString& operation)
{
    if (!query.exec()) {
        m_lastError = QString("%1 failed: %2").arg(operation, query.lastError().text());
        qCritical() << "MaterialDatabase::" << operation << "() - Error:" << m_lastError;
        qCritical() << "  SQL:" << query.lastQuery();
        emit error(m_lastError);
        return false;
    }
    return true;
}

// QML accessible functions
QVariantList MaterialDatabase::getAllMaterialsForQML()
{
    QVariantList result;
    QList<MaterialData> materials = getAllMaterials();
    
    int matNoCounter = 1; // Auto increment Mat No starting from 1
    
    for (const MaterialData& material : materials) {
        QVariantMap item;
        item["id"] = material.id;
        item["matNo"] = QString::number(matNoCounter++); // Auto increment Mat No
        item["eMod"] = QString::number(material.eModulus);
        item["gMod"] = QString::number(material.gModulus);
        item["density"] = QString::number(material.materialDensity);
        item["yieldStress"] = QString::number(material.yieldStress);
        item["tensileStrength"] = QString::number(material.tensileStrength);
        item["remark"] = material.remark;
        
        result.append(item);
    }
    
    qDebug() << "MaterialDatabase::getAllMaterialsForQML() - Returning" << result.size() << "materials for QML";
    return result;
}

bool MaterialDatabase::addMaterial(int eModulus, int gModulus, int materialDensity, 
                                  int yieldStress, int tensileStrength, const QString& remark)
{
    // Auto generate matNo by finding the highest existing matNo + 1
    QList<MaterialData> materials = getAllMaterials();
    int maxMatNo = 0;
    for (const MaterialData& material : materials) {
        if (material.matNo > maxMatNo) {
            maxMatNo = material.matNo;
        }
    }
    int newMatNo = maxMatNo + 1;
    
    bool success = insertMaterial(newMatNo, eModulus, gModulus, materialDensity, 
                                 yieldStress, tensileStrength, remark);
    
    if (success) {
        qDebug() << "MaterialDatabase::addMaterial() - Successfully added material with matNo:" << newMatNo;
    }
    
    return success;
}

bool MaterialDatabase::updateMaterial(int id, int eModulus, int gModulus, int materialDensity,
                                      int yieldStress, int tensileStrength, const QString& remark)
{
    if (!isConnected()) {
        m_lastError = "Database is not connected";
        qCritical() << "MaterialDatabase::updateMaterial(QML) -" << m_lastError;
        return false;
    }
    
    // Get existing material to preserve matNo
    MaterialData existing = findMaterialById(id);
    if (existing.id == 0) {
        m_lastError = QString("Material with ID %1 not found").arg(id);
        qWarning() << "MaterialDatabase::updateMaterial(QML) -" << m_lastError;
        return false;
    }
    
    // Use the original updateMaterial function with preserved matNo
    bool success = updateMaterial(id, existing.matNo, eModulus, gModulus, materialDensity,
                                 yieldStress, tensileStrength, remark);
    
    if (success) {
        qDebug() << "MaterialDatabase::updateMaterial(QML) - Successfully updated material ID:" << id;
    } else {
        qWarning() << "MaterialDatabase::updateMaterial(QML) - Failed to update material ID:" << id;
    }
    
    return success;
}

bool MaterialDatabase::removeMaterial(int id)
{
    bool success = deleteMaterial(id);
    
    if (success) {
        qDebug() << "MaterialDatabase::removeMaterial() - Successfully removed material with ID:" << id;
    }
    
    return success;
}

bool MaterialDatabase::isDBConnected() const
{
    return isConnected();
}

QString MaterialDatabase::getLastError() const
{
    return lastError();
}
