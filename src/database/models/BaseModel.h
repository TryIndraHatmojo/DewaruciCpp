#ifndef BASEMODEL_H
#define BASEMODEL_H

#include <QObject>
#include <QVariant>
#include <QDateTime>
#include <QSqlQuery>
#include <QSqlRecord>
#include <QJsonObject>
#include "../DatabaseManager.h"

class BaseModel : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int id READ id WRITE setId NOTIFY idChanged)
    Q_PROPERTY(QDateTime createdAt READ createdAt WRITE setCreatedAt NOTIFY createdAtChanged)
    Q_PROPERTY(QDateTime updatedAt READ updatedAt WRITE setUpdatedAt NOTIFY updatedAtChanged)

public:
    explicit BaseModel(QObject* parent = nullptr);
    virtual ~BaseModel() = default;
    
    // Primary properties
    int id() const { return m_id; }
    void setId(int id);
    
    QDateTime createdAt() const { return m_createdAt; }
    void setCreatedAt(const QDateTime& createdAt);
    
    QDateTime updatedAt() const { return m_updatedAt; }
    void setUpdatedAt(const QDateTime& updatedAt);
    
    // Virtual methods to be implemented by derived classes
    virtual QString tableName() const = 0;
    virtual QStringList fieldNames() const = 0;
    virtual QVariantMap toVariantMap() const = 0;
    virtual void fromVariantMap(const QVariantMap& map) = 0;
    
    // CRUD operations
    virtual bool save();
    virtual bool load(int id);
    virtual bool remove();
    virtual bool exists() const;
    
    // Utility methods
    QJsonObject toJson() const;
    void fromJson(const QJsonObject& json);
    bool isNew() const { return m_id <= 0; }
    
    // Static methods for queries
    static QSqlQuery findById(const QString& tableName, int id);
    static QSqlQuery findAll(const QString& tableName, const QString& orderBy = "");
    static QSqlQuery findWhere(const QString& tableName, const QString& whereClause, const QVariantList& bindValues = QVariantList());

signals:
    void idChanged();
    void createdAtChanged();
    void updatedAtChanged();
    void saved();
    void loaded();
    void deleted();

protected:
    virtual QVariantMap getFieldValues() const;
    virtual QString getInsertQuery() const;
    virtual QString getUpdateQuery() const;
    virtual QString getSelectQuery() const;
    virtual QString getDeleteQuery() const;
    
    void updateTimestamps();
    void bindValues(QSqlQuery& query, const QVariantMap& values) const;
    
    DatabaseManager* m_dbManager;

private:
    int m_id;
    QDateTime m_createdAt;
    QDateTime m_updatedAt;
};

#endif // BASEMODEL_H
