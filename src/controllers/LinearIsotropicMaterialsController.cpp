#include "LinearIsotropicMaterialsController.h"
#include "src/database/models/LinearIsotropicMaterials.h"

LinearIsotropicMaterialsController::LinearIsotropicMaterialsController(QObject* parent)
    : QObject(parent) {}

void LinearIsotropicMaterialsController::setModel(LinearIsotropicMaterials* model) {
    if (m_model == model) return;
    if (m_model) {
        // disconnect old
        disconnect(m_model, nullptr, this, nullptr);
    }
    m_model = model;
    if (m_model) {
        // forward signals for QML
        connect(m_model, &LinearIsotropicMaterials::materialInserted,
                this, &LinearIsotropicMaterialsController::materialInserted);
        connect(m_model, &LinearIsotropicMaterials::materialUpdated,
                this, &LinearIsotropicMaterialsController::materialUpdated);
        connect(m_model, &LinearIsotropicMaterials::materialDeleted,
                this, &LinearIsotropicMaterialsController::materialDeleted);
    connect(m_model, &LinearIsotropicMaterials::error,
        this, [this](const QString &msg){
            emit error(msg);
            emit errorChanged();
        });
    }
}

QVariantList LinearIsotropicMaterialsController::getAllMaterialsForQML() const {
    if (!m_model) return {};
    return m_model->getAllMaterialsForQML();
}

bool LinearIsotropicMaterialsController::addMaterial(int eModulus, int gModulus, int materialDensity,
                                                     int yieldStress, int tensileStrength, const QString &remark) {
    if (!m_model) return false;
    return m_model->addMaterial(eModulus, gModulus, materialDensity, yieldStress, tensileStrength, remark);
}

bool LinearIsotropicMaterialsController::updateMaterial(int id, int eModulus, int gModulus, int materialDensity,
                                                        int yieldStress, int tensileStrength, const QString &remark) {
    if (!m_model) return false;
    return m_model->updateMaterial(id, eModulus, gModulus, materialDensity, yieldStress, tensileStrength, remark);
}

bool LinearIsotropicMaterialsController::removeMaterial(int id) {
    if (!m_model) return false;
    return m_model->removeMaterial(id);
}

QString LinearIsotropicMaterialsController::getLastError() const {
    if (!m_model) return QString();
    return m_model->getLastError();
}
