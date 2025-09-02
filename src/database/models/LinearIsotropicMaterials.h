#ifndef LINEARISOTROPICMATERIALS_H
#define LINEARISOTROPICMATERIALS_H

#include <QObject>
#include <QSqlQuery>
#include <QSqlError>
#include <QVariantList>
#include <QDebug>

struct MaterialData {
    int id;
    int matNo;
    int eMod;
    int gMod;
    int density;
    int yieldStress;
    int tensileStrength;
    QString remark;
    qint64 createdAt;
    qint64 updatedAt;
};

Q_DECLARE_METATYPE(MaterialData)

class LinearIsotropicMaterials : public QObject
{
    Q_OBJECT

public:
    explicit LinearIsotropicMaterials(QObject *parent = nullptr);

    // Q_INVOKABLE methods untuk QML
    Q_INVOKABLE QVariantList getAllMaterialsForQML();
    Q_INVOKABLE bool addMaterial(int eModulus, int gModulus, int materialDensity, 
                                int yieldStress, int tensileStrength, const QString& remark);
    Q_INVOKABLE bool updateMaterial(int id, int eModulus, int gModulus, int materialDensity,
                                   int yieldStress, int tensileStrength, const QString& remark);
    Q_INVOKABLE bool removeMaterial(int id);
    Q_INVOKABLE QString getLastError() const;

    // C++ methods
    bool createTable();
    bool insertMaterial(int matNo, int eModulus, int gModulus, 
                       int materialDensity, int yieldStress, 
                       int tensileStrength, const QString& remark);
    bool updateMaterial(int id, int matNo, int eModulus, int gModulus, 
                       int materialDensity, int yieldStress, 
                       int tensileStrength, const QString& remark);
    bool deleteMaterial(int id);
    bool deleteMaterialByMatNo(int matNo);
    MaterialData findMaterialById(int id);
    MaterialData findMaterialByMatNo(int matNo);
    QList<MaterialData> getAllMaterials();
    bool clearAllMaterials();
    bool insertSampleData();

signals:
    void materialInserted(int id);
    void materialUpdated(int id);
    void materialDeleted(int id);
    void error(const QString& message);

private:
    bool executeQuery(QSqlQuery& query, const QString& operation);
    MaterialData createMaterialFromQuery(const QSqlQuery& query);
    int getNextMatNo();

    QString m_lastError;
};

#endif // LINEARISOTROPICMATERIALS_H
