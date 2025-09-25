#pragma once

#include <QObject>
#include <QVariantList>
#include <QString>

class LinearIsotropicMaterials;

class LinearIsotropicMaterialsController : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString lastError READ getLastError NOTIFY errorChanged)
public:
    explicit LinearIsotropicMaterialsController(QObject* parent = nullptr);
    ~LinearIsotropicMaterialsController() override = default;

    Q_INVOKABLE QVariantList getAllMaterialsForQML() const;
    Q_INVOKABLE bool addMaterial(int eModulus, int gModulus, int materialDensity,
                                 int yieldStress, int tensileStrength, const QString &remark);
    Q_INVOKABLE bool updateMaterial(int id, int eModulus, int gModulus, int materialDensity,
                                    int yieldStress, int tensileStrength, const QString &remark);
    Q_INVOKABLE bool removeMaterial(int id);
    Q_INVOKABLE QString getLastError() const;

    void setModel(LinearIsotropicMaterials* model);

signals:
    void materialInserted(int id);
    void materialUpdated(int id);
    void materialDeleted(int id);
    void error(const QString &message);
    void errorChanged();

private:
    LinearIsotropicMaterials* m_model { nullptr };
};
