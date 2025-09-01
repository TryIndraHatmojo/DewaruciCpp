#ifndef MATERIALDATABASE_H
#define MATERIALDATABASE_H

#include <QObject>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QVariant>
#include <QDebug>

struct MaterialData {
    int id;
    int matNo;
    int eModulus;
    int gModulus;
    int materialDensity;
    int yieldStress;
    int tensileStrength;
    QString remark;
};

class MaterialDatabase : public QObject
{
    Q_OBJECT
    
public:
    static MaterialDatabase& instance();
    
    // Database operations
    bool initialize();
    void close();
    bool isConnected() const;
    
    // CRUD operations for materials
    bool insertMaterial(int matNo, int eModulus, int gModulus, 
                       int materialDensity, int yieldStress, 
                       int tensileStrength, const QString& remark);
    
    bool updateMaterial(int id, int matNo, int eModulus, int gModulus, 
                       int materialDensity, int yieldStress, 
                       int tensileStrength, const QString& remark);
    
    MaterialData findMaterialById(int id);
    MaterialData findMaterialByMatNo(int matNo);
    QList<MaterialData> getAllMaterials();
    
    bool deleteMaterial(int id);
    bool deleteMaterialByMatNo(int matNo);
    
    // Utility functions
    bool insertSampleData();
    bool clearAllMaterials();
    QString lastError() const { return m_lastError; }
    
    // QML accessible functions
    Q_INVOKABLE QVariantList getAllMaterialsForQML();
    Q_INVOKABLE bool addMaterial(int eModulus, int gModulus, int materialDensity, 
                                int yieldStress, int tensileStrength, const QString& remark);
    Q_INVOKABLE bool updateMaterial(int id, int eModulus, int gModulus, int materialDensity,
                                   int yieldStress, int tensileStrength, const QString& remark);
    Q_INVOKABLE bool removeMaterial(int id);
    Q_INVOKABLE bool isDBConnected() const;
    Q_INVOKABLE QString getLastError() const;

signals:
    void materialInserted(int id);
    void materialUpdated(int id);
    void materialDeleted(int id);
    void error(const QString& message);

private:
    explicit MaterialDatabase(QObject* parent = nullptr);
    ~MaterialDatabase();
    
    bool createTable();
    bool executeQuery(QSqlQuery& query, const QString& operation);
    
    QSqlDatabase m_database;
    QString m_lastError;
    static MaterialDatabase* s_instance;
};

#endif // MATERIALDATABASE_H
