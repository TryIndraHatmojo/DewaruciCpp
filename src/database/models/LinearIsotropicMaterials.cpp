#include "LinearIsotropicMaterials.h"
#include "../DatabaseConnection.h"
#include <QSqlRecord>
#include <QVariantMap>

LinearIsotropicMaterials::LinearIsotropicMaterials(QObject *parent)
    : QObject(parent)
{
}

bool LinearIsotropicMaterials::createTable()
{
    if (!DatabaseConnection::instance().isConnected()) {
        m_lastError = "Database is not connected";
        qCritical() << "LinearIsotropicMaterials::createTable() -" << m_lastError;
        return false;
    }

    QSqlQuery query(DatabaseConnection::instance().database());
    
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
        qCritical() << "LinearIsotropicMaterials::createTable() -" << m_lastError;
        return false;
    }
    
    // Create index for faster lookups
    QString createIndexSql = "CREATE INDEX IF NOT EXISTS idx_mat_no ON structure_seagoing_ship_section0_linear_isotropic_materials(mat_no)";
    if (!query.exec(createIndexSql)) {
        qWarning() << "LinearIsotropicMaterials::createTable() - Failed to create index:" << query.lastError().text();
    }
    
    qDebug() << "LinearIsotropicMaterials::createTable() - Table created successfully";
    return true;
}

bool LinearIsotropicMaterials::insertMaterial(int matNo, int eModulus, int gModulus, 
                                            int materialDensity, int yieldStress, 
                                            int tensileStrength, const QString& remark)
{
    if (!DatabaseConnection::instance().isConnected()) {
        m_lastError = "Database is not connected";
        qCritical() << "LinearIsotropicMaterials::insertMaterial() -" << m_lastError;
        return false;
    }
    
    QSqlQuery query(DatabaseConnection::instance().database());
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
    qDebug() << "LinearIsotropicMaterials::insertMaterial() - Material inserted with ID:" << newId;
    emit materialInserted(newId);
    return true;
}

bool LinearIsotropicMaterials::updateMaterial(int id, int matNo, int eModulus, int gModulus, 
                                            int materialDensity, int yieldStress, 
                                            int tensileStrength, const QString& remark)
{
    if (!DatabaseConnection::instance().isConnected()) {
        m_lastError = "Database is not connected";
        qCritical() << "LinearIsotropicMaterials::updateMaterial() -" << m_lastError;
        return false;
    }
    
    QSqlQuery query(DatabaseConnection::instance().database());
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
    
    qDebug() << "LinearIsotropicMaterials::updateMaterial() - Material updated, ID:" << id;
    emit materialUpdated(id);
    return true;
}

bool LinearIsotropicMaterials::deleteMaterial(int id)
{
    if (!DatabaseConnection::instance().isConnected()) {
        m_lastError = "Database is not connected";
        qCritical() << "LinearIsotropicMaterials::deleteMaterial() -" << m_lastError;
        return false;
    }
    
    QSqlQuery query(DatabaseConnection::instance().database());
    query.prepare("DELETE FROM structure_seagoing_ship_section0_linear_isotropic_materials WHERE id = ?");
    query.addBindValue(id);
    
    if (!executeQuery(query, "deleteMaterial")) {
        return false;
    }
    
    qDebug() << "LinearIsotropicMaterials::deleteMaterial() - Material deleted, ID:" << id;
    emit materialDeleted(id);
    return true;
}

bool LinearIsotropicMaterials::deleteMaterialByMatNo(int matNo)
{
    if (!DatabaseConnection::instance().isConnected()) {
        m_lastError = "Database is not connected";
        qCritical() << "LinearIsotropicMaterials::deleteMaterialByMatNo() -" << m_lastError;
        return false;
    }
    
    QSqlQuery query(DatabaseConnection::instance().database());
    query.prepare("DELETE FROM structure_seagoing_ship_section0_linear_isotropic_materials WHERE mat_no = ?");
    query.addBindValue(matNo);
    
    if (!executeQuery(query, "deleteMaterialByMatNo")) {
        return false;
    }
    
    qDebug() << "LinearIsotropicMaterials::deleteMaterialByMatNo() - Material deleted, Mat No:" << matNo;
    return true;
}

MaterialData LinearIsotropicMaterials::findMaterialById(int id)
{
    MaterialData material = {};
    
    if (!DatabaseConnection::instance().isConnected()) {
        m_lastError = "Database is not connected";
        qCritical() << "LinearIsotropicMaterials::findMaterialById() -" << m_lastError;
        return material;
    }
    
    QSqlQuery query(DatabaseConnection::instance().database());
    query.prepare("SELECT * FROM structure_seagoing_ship_section0_linear_isotropic_materials WHERE id = ?");
    query.addBindValue(id);
    
    if (!executeQuery(query, "findMaterialById")) {
        return material;
    }
    
    if (query.next()) {
        material = createMaterialFromQuery(query);
        qDebug() << "LinearIsotropicMaterials::findMaterialById() - Material found, ID:" << id;
    } else {
        qDebug() << "LinearIsotropicMaterials::findMaterialById() - Material not found, ID:" << id;
    }
    
    return material;
}

MaterialData LinearIsotropicMaterials::findMaterialByMatNo(int matNo)
{
    MaterialData material = {};
    
    if (!DatabaseConnection::instance().isConnected()) {
        m_lastError = "Database is not connected";
        qCritical() << "LinearIsotropicMaterials::findMaterialByMatNo() -" << m_lastError;
        return material;
    }
    
    QSqlQuery query(DatabaseConnection::instance().database());
    query.prepare("SELECT * FROM structure_seagoing_ship_section0_linear_isotropic_materials WHERE mat_no = ?");
    query.addBindValue(matNo);
    
    if (!executeQuery(query, "findMaterialByMatNo")) {
        return material;
    }
    
    if (query.next()) {
        material = createMaterialFromQuery(query);
        qDebug() << "LinearIsotropicMaterials::findMaterialByMatNo() - Material found, Mat No:" << matNo;
    } else {
        qDebug() << "LinearIsotropicMaterials::findMaterialByMatNo() - Material not found, Mat No:" << matNo;
    }
    
    return material;
}

QList<MaterialData> LinearIsotropicMaterials::getAllMaterials()
{
    QList<MaterialData> materials;
    
    if (!DatabaseConnection::instance().isConnected()) {
        m_lastError = "Database is not connected";
        qCritical() << "LinearIsotropicMaterials::getAllMaterials() -" << m_lastError;
        return materials;
    }
    
    QSqlQuery query(DatabaseConnection::instance().database());
    QString sql = "SELECT * FROM structure_seagoing_ship_section0_linear_isotropic_materials ORDER BY mat_no";
    
    if (!query.exec(sql)) {
        m_lastError = QString("Failed to fetch materials: %1").arg(query.lastError().text());
        qCritical() << "LinearIsotropicMaterials::getAllMaterials() -" << m_lastError;
        return materials;
    }
    
    while (query.next()) {
        MaterialData material = createMaterialFromQuery(query);
        materials.append(material);
    }
    
    qDebug() << "LinearIsotropicMaterials::getAllMaterials() - Found" << materials.size() << "materials";
    return materials;
}

bool LinearIsotropicMaterials::clearAllMaterials()
{
    if (!DatabaseConnection::instance().isConnected()) {
        m_lastError = "Database is not connected";
        qCritical() << "LinearIsotropicMaterials::clearAllMaterials() -" << m_lastError;
        return false;
    }
    
    QSqlQuery query(DatabaseConnection::instance().database());
    if (!query.exec("DELETE FROM structure_seagoing_ship_section0_linear_isotropic_materials")) {
        m_lastError = QString("Failed to clear materials: %1").arg(query.lastError().text());
        qCritical() << "LinearIsotropicMaterials::clearAllMaterials() -" << m_lastError;
        return false;
    }
    
    qDebug() << "LinearIsotropicMaterials::clearAllMaterials() - All materials cleared";
    return true;
}

bool LinearIsotropicMaterials::insertSampleData()
{
    struct SampleMaterial {
        int matNo;
        int eMod;
        int gMod;
        int density;
        int yieldStress;
        int tensileStrength;
        QString remark;
    };
    
    QList<SampleMaterial> samples = {
        {1, 210000, 80000, 7850, 250, 420, "Structural Steel"},
        {2, 200000, 77000, 7850, 355, 510, "High Strength Steel"},
        {3, 70000, 26000, 2700, 275, 310, "Aluminum Alloy"}
    };
    
    bool success = true;
    for (const auto& sample : samples) {
        if (!insertMaterial(sample.matNo, sample.eMod, sample.gMod, 
                           sample.density, sample.yieldStress, 
                           sample.tensileStrength, sample.remark)) {
            success = false;
            qWarning() << "Failed to insert sample material:" << sample.matNo;
        }
    }
    
    return success;
}

// QML accessible functions
QVariantList LinearIsotropicMaterials::getAllMaterialsForQML()
{
    QVariantList result;
    QList<MaterialData> materials = getAllMaterials();
    
    for (const MaterialData& material : materials) {
        QVariantMap materialMap;
        materialMap["id"] = material.id;
        materialMap["matNo"] = material.matNo;
        materialMap["eMod"] = material.eMod;
        materialMap["gMod"] = material.gMod;
        materialMap["density"] = material.density;
        materialMap["yieldStress"] = material.yieldStress;
        materialMap["tensileStrength"] = material.tensileStrength;
        materialMap["remark"] = material.remark;
        materialMap["createdAt"] = material.createdAt;
        materialMap["updatedAt"] = material.updatedAt;
        
        result.append(materialMap);
    }
    
    return result;
}

bool LinearIsotropicMaterials::addMaterial(int eModulus, int gModulus, int materialDensity, 
                                         int yieldStress, int tensileStrength, const QString& remark)
{
    int matNo = getNextMatNo();
    return insertMaterial(matNo, eModulus, gModulus, materialDensity, yieldStress, tensileStrength, remark);
}

bool LinearIsotropicMaterials::updateMaterial(int id, int eModulus, int gModulus, int materialDensity,
                                            int yieldStress, int tensileStrength, const QString& remark)
{
    // Get existing material to preserve mat_no
    MaterialData existing = findMaterialById(id);
    if (existing.id == 0) {
        m_lastError = "Material not found";
        return false;
    }
    
    return updateMaterial(id, existing.matNo, eModulus, gModulus, materialDensity, yieldStress, tensileStrength, remark);
}

bool LinearIsotropicMaterials::removeMaterial(int id)
{
    return deleteMaterial(id);
}

QString LinearIsotropicMaterials::getLastError() const
{
    return m_lastError;
}

// Private helper methods
bool LinearIsotropicMaterials::executeQuery(QSqlQuery& query, const QString& operation)
{
    if (!query.exec()) {
        m_lastError = QString("Failed to execute %1: %2").arg(operation, query.lastError().text());
        qCritical() << "LinearIsotropicMaterials::executeQuery() -" << m_lastError;
        emit error(m_lastError);
        return false;
    }
    return true;
}

MaterialData LinearIsotropicMaterials::createMaterialFromQuery(const QSqlQuery& query)
{
    MaterialData material;
    material.id = query.value("id").toInt();
    material.matNo = query.value("mat_no").toInt();
    material.eMod = query.value("e_modulus").toInt();
    material.gMod = query.value("g_modulus").toInt();
    material.density = query.value("material_density").toInt();
    material.yieldStress = query.value("yield_stress").toInt();
    material.tensileStrength = query.value("tensile_strength").toInt();
    material.remark = query.value("remark").toString();
    material.createdAt = query.value("created_at").toLongLong();
    material.updatedAt = query.value("updated_at").toLongLong();
    return material;
}

int LinearIsotropicMaterials::getNextMatNo()
{
    if (!DatabaseConnection::instance().isConnected()) {
        return 1;
    }
    
    QSqlQuery query(DatabaseConnection::instance().database());
    if (query.exec("SELECT MAX(mat_no) FROM structure_seagoing_ship_section0_linear_isotropic_materials")) {
        if (query.next()) {
            return query.value(0).toInt() + 1;
        }
    }
    
    return 1; // Start from 1 if no materials exist
}
