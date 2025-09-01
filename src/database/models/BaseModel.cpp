#include "BaseModel.h"
#include <QSqlRecord>
#include <QSqlError>
#include <QJsonDocument>
#include <QDebug>

BaseModel::BaseModel(QObject* parent)
    : QObject(parent)
    , m_dbManager(&DatabaseManager::instance())
    , m_id(0)
{
}

void BaseModel::setId(int id)
{
    if (m_id != id) {
        m_id = id;
        emit idChanged();
    }
}

void BaseModel::setCreatedAt(const QDateTime& createdAt)
{
    if (m_createdAt != createdAt) {
        m_createdAt = createdAt;
        emit createdAtChanged();
    }
}

void BaseModel::setUpdatedAt(const QDateTime& updatedAt)
{
    if (m_updatedAt != updatedAt) {
        m_updatedAt = updatedAt;
        emit updatedAtChanged();
    }
}

bool BaseModel::save()
{
    if (!m_dbManager->isConnected()) {
        qWarning() << "Database is not connected";
        return false;
    }
    
    updateTimestamps();
    
    QString query;
    QVariantMap values = getFieldValues();
    
    if (isNew()) {
        // Insert new record
        query = getInsertQuery();
        values.remove("id"); // Remove ID for insert
    } else {
        // Update existing record
        query = getUpdateQuery();
        values["id"] = m_id;
    }
    
    QSqlQuery sqlQuery = m_dbManager->executeQuery(query);
    bindValues(sqlQuery, values);
    
    if (!sqlQuery.exec()) {
        qWarning() << "Failed to save model:" << sqlQuery.lastError().text();
        return false;
    }
    
    if (isNew()) {
        // Get the auto-generated ID
        QVariant lastId = sqlQuery.lastInsertId();
        if (lastId.isValid()) {
            setId(lastId.toInt());
        }
    }
    
    emit saved();
    return true;
}

bool BaseModel::load(int id)
{
    if (!m_dbManager->isConnected()) {
        qWarning() << "Database is not connected";
        return false;
    }
    
    QSqlQuery query = findById(tableName(), id);
    
    if (!query.exec() || !query.next()) {
        qWarning() << "Failed to load model with ID:" << id;
        return false;
    }
    
    QSqlRecord record = query.record();
    QVariantMap map;
    
    for (int i = 0; i < record.count(); ++i) {
        map[record.fieldName(i)] = record.value(i);
    }
    
    fromVariantMap(map);
    emit loaded();
    return true;
}

bool BaseModel::remove()
{
    if (isNew() || !m_dbManager->isConnected()) {
        return false;
    }
    
    QString query = getDeleteQuery();
    QSqlQuery sqlQuery = m_dbManager->executeQuery(query, {m_id});
    
    if (!sqlQuery.exec()) {
        qWarning() << "Failed to delete model:" << sqlQuery.lastError().text();
        return false;
    }
    
    emit deleted();
    setId(0); // Reset ID to indicate it's a new object
    return true;
}

bool BaseModel::exists() const
{
    if (isNew() || !m_dbManager->isConnected()) {
        return false;
    }
    
    QSqlQuery query = findById(tableName(), m_id);
    return query.exec() && query.next();
}

QJsonObject BaseModel::toJson() const
{
    QVariantMap map = toVariantMap();
    QJsonObject json;
    
    for (auto it = map.begin(); it != map.end(); ++it) {
        json[it.key()] = QJsonValue::fromVariant(it.value());
    }
    
    return json;
}

void BaseModel::fromJson(const QJsonObject& json)
{
    QVariantMap map;
    for (auto it = json.begin(); it != json.end(); ++it) {
        map[it.key()] = it.value().toVariant();
    }
    fromVariantMap(map);
}

QSqlQuery BaseModel::findById(const QString& tableName, int id)
{
    DatabaseManager& db = DatabaseManager::instance();
    QString queryString = QString("SELECT * FROM %1 WHERE id = ?").arg(tableName);
    return db.executeQuery(queryString, {id});
}

QSqlQuery BaseModel::findAll(const QString& tableName, const QString& orderBy)
{
    DatabaseManager& db = DatabaseManager::instance();
    QString queryString = QString("SELECT * FROM %1").arg(tableName);
    
    if (!orderBy.isEmpty()) {
        queryString += QString(" ORDER BY %1").arg(orderBy);
    }
    
    return db.executeQuery(queryString);
}

QSqlQuery BaseModel::findWhere(const QString& tableName, const QString& whereClause, const QVariantList& bindValues)
{
    DatabaseManager& db = DatabaseManager::instance();
    QString queryString = QString("SELECT * FROM %1 WHERE %2").arg(tableName, whereClause);
    return db.executeQuery(queryString, bindValues);
}

QVariantMap BaseModel::getFieldValues() const
{
    QVariantMap values = toVariantMap();
    
    // Add base model fields
    values["id"] = m_id;
    values["created_at"] = m_createdAt;
    values["updated_at"] = m_updatedAt;
    
    return values;
}

QString BaseModel::getInsertQuery() const
{
    QStringList fields = fieldNames();
    fields << "created_at" << "updated_at";
    
    QString placeholders = QString("?").repeated(fields.size());
    for (int i = 1; i < fields.size(); ++i) {
        placeholders.insert(i * 2 - 1, ", ");
    }
    
    return QString("INSERT INTO %1 (%2) VALUES (%3)")
           .arg(tableName())
           .arg(fields.join(", "))
           .arg(placeholders);
}

QString BaseModel::getUpdateQuery() const
{
    QStringList fields = fieldNames();
    fields << "updated_at";
    
    QStringList setClause;
    for (const QString& field : fields) {
        setClause << QString("%1 = ?").arg(field);
    }
    
    return QString("UPDATE %1 SET %2 WHERE id = ?")
           .arg(tableName())
           .arg(setClause.join(", "));
}

QString BaseModel::getSelectQuery() const
{
    return QString("SELECT * FROM %1 WHERE id = ?").arg(tableName());
}

QString BaseModel::getDeleteQuery() const
{
    return QString("DELETE FROM %1 WHERE id = ?").arg(tableName());
}

void BaseModel::updateTimestamps()
{
    QDateTime now = QDateTime::currentDateTime();
    
    if (isNew()) {
        setCreatedAt(now);
    }
    setUpdatedAt(now);
}

void BaseModel::bindValues(QSqlQuery& query, const QVariantMap& values) const
{
    QStringList fields = fieldNames();
    
    if (isNew()) {
        fields << "created_at" << "updated_at";
        for (const QString& field : fields) {
            query.addBindValue(values.value(field));
        }
    } else {
        fields << "updated_at";
        for (const QString& field : fields) {
            query.addBindValue(values.value(field));
        }
        query.addBindValue(values.value("id")); // For WHERE clause
    }
}
