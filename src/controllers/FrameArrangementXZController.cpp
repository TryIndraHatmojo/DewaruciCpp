#include "FrameArrangementXZController.h"
#include "../database/models/FrameArrangementXZ.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDebug>

FrameArrangementXZController::FrameArrangementXZController(QObject *parent)
    : QObject(parent), m_model(nullptr)
{
}

void FrameArrangementXZController::setFrameXZList(const QJsonArray &list)
{
    if (m_frameXZList != list) {
        m_frameXZList = list;
        emit frameXZListChanged();
    }
}

void FrameArrangementXZController::setFoundFrameXZ(const QJsonArray &found)
{
    if (m_foundFrameXZ != found) {
        m_foundFrameXZ = found;
        emit foundFrameXZChanged();
    }
}

void FrameArrangementXZController::setSecondFrameXZ(const QJsonArray &second)
{
    if (m_secondFrameXZ != second) {
        m_secondFrameXZ = second;
        emit secondFrameXZChanged();
    }
}

void FrameArrangementXZController::setModel(FrameArrangementXZ* model)
{
    m_model = model;
}

void FrameArrangementXZController::insertFrameXZ(const QString &frameName, int frameNumber, double frameSpacing,
                                                const QString &ml, double xpCoor, double xl, double xllCoor, double xllLll)
{
    if (!m_model) {
        qCritical() << "FrameArrangementXZController::insertFrameXZ() - Model not set";
        emit errorOccurred("Model not set");
        return;
    }

    // Convert ml string to double (you might want to implement proper conversion logic)
    double mlValue = 0.0; // Default value, implement proper conversion based on your needs
    
    bool success = m_model->insertFrame(frameName, frameNumber, frameSpacing, 
                                       mlValue, xpCoor, xl, xllCoor, xllLll);
    
    if (success) {
        int lastId = getXZLastId();
        insertBody(frameName, "", lastId);
        getFrameXZList();
        checkIsFrameZero();
        
        qDebug() << "FrameArrangementXZController::insertFrameXZ() - Frame inserted successfully";
    } else {
        qCritical() << "FrameArrangementXZController::insertFrameXZ() - Failed to insert frame";
        emit errorOccurred("Failed to insert frame");
    }
}

void FrameArrangementXZController::getFrameXZList()
{
    if (!m_model) {
        qCritical() << "FrameArrangementXZController::getFrameXZList() - Model not set";
        emit errorOccurred("Model not set");
        return;
    }

    // Get data from model (assuming the model loads all data)
    QVariantList dataList;
    for (int i = 0; i < m_model->getRowCount(); ++i) {
        QVariantMap frameData = m_model->getFrameAtIndex(i);
        dataList.append(frameData);
    }

    // Sort data by frame number
    QVariantList sortedData = sortByFrameNumber(dataList);
    
    // Convert to JSON
    setFrameXZList(generateObjectJson(sortedData));
    
    qDebug() << "FrameArrangementXZController::getFrameXZList() - Loaded" << dataList.size() << "frames";
}

void FrameArrangementXZController::deleteFrameXZ(int id)
{
    if (!m_model) {
        qCritical() << "FrameArrangementXZController::deleteFrameXZ() - Model not set";
        emit errorOccurred("Model not set");
        return;
    }

    bool success = m_model->deleteFrame(id);
    if (success) {
        getFrameXZList();
        qDebug() << "FrameArrangementXZController::deleteFrameXZ() - Frame deleted successfully";
    } else {
        qCritical() << "FrameArrangementXZController::deleteFrameXZ() - Failed to delete frame";
        emit errorOccurred("Failed to delete frame");
    }
}

void FrameArrangementXZController::updateFrameXZ(int id, const QString &frameName, int frameNumber, double frameSpacing,
                                                const QString &ml, double xpCoor, double xl, double xllCoor, double xllLll)
{
    if (!m_model) {
        qCritical() << "FrameArrangementXZController::updateFrameXZ() - Model not set";
        emit errorOccurred("Model not set");
        return;
    }

    qDebug() << "FrameArrangementXZController::updateFrameXZ() - Updating frame:" << id << frameName << frameNumber << frameSpacing;

    // Check if all parameters are valid
    if (frameName.isEmpty() || frameSpacing <= 0) {
        qWarning() << "FrameArrangementXZController::updateFrameXZ() - One or more inputs are empty or invalid";
        emit errorOccurred("One or more inputs are empty or invalid");
        return;
    }

    // Convert ml string to double (you might want to implement proper conversion logic)
    double mlValue = 0.0; // Default value, implement proper conversion based on your needs

    bool success = m_model->updateFrame(id, frameName, frameNumber, frameSpacing, 
                                       mlValue, xpCoor, xl, xllCoor, xllLll);
    
    if (success) {
        getFrameXZList();
        
        if (frameNumber >= 0) {
            QVariantMap changedData;
            changedData["id"] = id;
            changedData["frameName"] = frameName;
            changedData["frameNumber"] = frameNumber;
            changedData["frameSpacing"] = frameSpacing;
            changedData["ml"] = ml;
            changedData["xpCoor"] = xpCoor;
            changedData["xl"] = xl;
            changedData["xllCoor"] = xllCoor;
            changedData["xllLll"] = xllLll;
            
            checkChangedFrameXZ(changedData, frameNumber);
        }
        
        checkIsFrameZero();
        qDebug() << "FrameArrangementXZController::updateFrameXZ() - Frame updated successfully";
    } else {
        qCritical() << "FrameArrangementXZController::updateFrameXZ() - Failed to update frame";
        emit errorOccurred("Failed to update frame");
    }
}

void FrameArrangementXZController::updateFrameXZMl(int id, const QString &ml)
{
    if (!m_model) {
        qCritical() << "FrameArrangementXZController::updateFrameXZMl() - Model not set";
        emit errorOccurred("Model not set");
        return;
    }

    // Get current frame data first
    QVariantMap currentFrame = m_model->getFrameById(id);
    if (currentFrame.isEmpty()) {
        qCritical() << "FrameArrangementXZController::updateFrameXZMl() - Frame not found";
        emit errorOccurred("Frame not found");
        return;
    }

    // Update with new ML value
    bool success = m_model->updateFrame(
        id,
        currentFrame["frameName"].toString(),
        currentFrame["frameNumber"].toInt(),
        currentFrame["frameSpacing"].toDouble(),
        currentFrame["ml"].toDouble(),
        currentFrame["xpCoor"].toDouble(),
        currentFrame["xl"].toDouble(),
        currentFrame["xllCoor"].toDouble(),
        currentFrame["xllLll"].toDouble()
    );

    if (success) {
        getFrameXZList();
        qDebug() << "FrameArrangementXZController::updateFrameXZMl() - Frame ML updated successfully";
    } else {
        qCritical() << "FrameArrangementXZController::updateFrameXZMl() - Failed to update frame ML";
        emit errorOccurred("Failed to update frame ML");
    }
}

int FrameArrangementXZController::getXZLastId()
{
    if (!m_model) {
        qCritical() << "FrameArrangementXZController::getXZLastId() - Model not set";
        emit errorOccurred("Model not set");
        return -1;
    }

    int lastId = m_model->getLastId();
    if (lastId != -1) {
        qDebug() << "FrameArrangementXZController::getXZLastId() - Last ID:" << lastId;
        return lastId;
    } else {
        qWarning() << "FrameArrangementXZController::getXZLastId() - Error getting last ID";
        return -1;
    }
}

void FrameArrangementXZController::getFrameXZById(int id)
{
    if (!m_model) {
        qCritical() << "FrameArrangementXZController::getFrameXZById() - Model not set";
        emit errorOccurred("Model not set");
        return;
    }

    QVariantMap frameData = m_model->getFrameById(id);
    if (!frameData.isEmpty()) {
        QVariantList dataList;
        dataList.append(frameData);
        setFoundFrameXZ(generateObjectJson(dataList));
        qDebug() << "FrameArrangementXZController::getFrameXZById() - Frame found";
    } else {
        setFoundFrameXZ(QJsonArray());
        qWarning() << "FrameArrangementXZController::getFrameXZById() - Frame not found";
    }
}

void FrameArrangementXZController::getSecondFrameXZList()
{
    // This function seems to be the same as getFrameXZList in the Python code
    getFrameXZList();
    setSecondFrameXZ(m_frameXZList);
}

void FrameArrangementXZController::resetFrameXZ()
{
    if (!m_model) {
        qCritical() << "FrameArrangementXZController::resetFrameXZ() - Model not set";
        emit errorOccurred("Model not set");
        return;
    }

    bool success = m_model->resetDatabase();
    if (success) {
        getFrameXZList();
        qDebug() << "FrameArrangementXZController::resetFrameXZ() - Database reset successfully";
    } else {
        qCritical() << "FrameArrangementXZController::resetFrameXZ() - Failed to reset database";
        emit errorOccurred("Failed to reset database");
    }
}

void FrameArrangementXZController::addSampleData()
{
    if (!m_model) {
        qCritical() << "FrameArrangementXZController::addSampleData() - Model not set";
        emit errorOccurred("Model not set");
        return;
    }

    // Add some sample frame data
    insertFrameXZ("Frame 0", 0, 1820.0, "FORWARD", 0.0, 0.0, 0.0, 0.0);
    insertFrameXZ("Frame 1", 1, 1820.0, "FORWARD", 1.82, 0.0182, 1.82, 0.0173);
    insertFrameXZ("Frame 2", 2, 1820.0, "FORWARD", 3.64, 0.0364, 3.64, 0.0347);
    insertFrameXZ("Frame 3", 3, 1820.0, "FORWARD", 5.46, 0.0546, 5.46, 0.0520);
    
    qDebug() << "FrameArrangementXZController::addSampleData() - Sample data added successfully";
}

void FrameArrangementXZController::checkIsFrameZero()
{
    try {
        QVariantList dataXZ = qjsonArrayToList(m_frameXZList);
        if (dataXZ.size() > 1) {
            bool isZero = false;
            for (const QVariant &item : dataXZ) {
                QVariantMap data = item.toMap();
                if (data["frameNumber"].toInt() == 0) {
                    isZero = true;
                    break;
                }
            }
            
            if (!isZero && !dataXZ.isEmpty()) {
                QString frameName = "Frame 0";
                int frameNumber = 0;
                QVariantMap firstFrame = dataXZ.first().toMap();
                double frameSpacing = firstFrame["frameSpacing"].toDouble();
                QString ml = "FORWARD";
                double xpCoor = 0;
                double xl = 0;
                double xllCoor = 0;
                double xllLll = 0;
                
                qDebug() << "FrameArrangementXZController::checkIsFrameZero() - Inserting Frame 0";
                insertFrameXZ(frameName, frameNumber, frameSpacing, ml, xpCoor, xl, xllCoor, xllLll);
            }
        }
    } catch (const std::exception &e) {
        qCritical() << "FrameArrangementXZController::checkIsFrameZero() - Error:" << e.what();
    }
}

void FrameArrangementXZController::checkChangedFrameXZ(const QVariantMap &changedData, int changedFrameNumber)
{
    QVariantMap defaultData = changedData;
    QVariantList listFrameXZ = qjsonArrayToList(m_frameXZList);
    
    // Filter data with frame numbers greater than the changed frame number
    QVariantList filteredData;
    for (const QVariant &item : listFrameXZ) {
        QVariantMap frameData = item.toMap();
        if (frameData["frameNumber"].toInt() > changedFrameNumber) {
            filteredData.append(frameData);
        }
    }
    
    if (!filteredData.isEmpty()) {
        for (const QVariant &item : filteredData) {
            QVariantMap frameData = item.toMap();
            
            // Define variables
            int id = frameData["id"].toInt();
            QString frameName = frameData["frameName"].toString();
            double frameSpacing = frameData["frameSpacing"].toDouble();
            int frameNumber = frameData["frameNumber"].toInt();
            QString ml = frameData["ml"].toString();
            
            // Convert ml to double value (implement proper conversion logic)
            double mlValue = 0.0;
            
            // Calculations
            int selisihFrame = frameNumber - defaultData["frameNumber"].toInt();
            double xpCoor = (selisihFrame * defaultData["frameSpacing"].toDouble() / 1000.0) + defaultData["xpCoor"].toDouble();
            
            double lpp = getShipLength();
            double xl = xpCoor / lpp;
            
            double xllCoor = xpCoor;
            
            double upperL = getShipLengthL();
            double xllLll = xllCoor / upperL;
            
            // Update frame
            bool success = m_model->updateFrame(id, frameName, frameNumber, frameSpacing,
                                               mlValue, xpCoor, xl, xllCoor, xllLll);
            
            if (success) {
                // Set default data for next iteration
                defaultData["frameNumber"] = frameNumber;
                defaultData["frameSpacing"] = frameSpacing;
                defaultData["xpCoor"] = xpCoor;
                defaultData["xl"] = xl;
                defaultData["xllCoor"] = xllCoor;
                defaultData["xllLll"] = xllLll;
            }
        }
        getFrameXZList();
    }
}

double FrameArrangementXZController::getShipLength() const
{
    // TODO: Implement this based on your ship data source
    // This should return the ship's LPP (Length between perpendiculars)
    return 100.0; // Placeholder value
}

double FrameArrangementXZController::getShipLengthL() const
{
    // TODO: Implement this based on your ship data source
    // This should return the ship's overall length
    return 105.0; // Placeholder value
}

QJsonArray FrameArrangementXZController::generateObjectJson(const QVariantList &data)
{
    QJsonArray jsonArray;
    for (const QVariant &item : data) {
        QVariantMap map = item.toMap();
        QJsonObject jsonObj = QJsonObject::fromVariantMap(map);
        jsonArray.append(jsonObj);
    }
    return jsonArray;
}

QVariantList FrameArrangementXZController::sortByFrameNumber(const QVariantList &data)
{
    QVariantList sortedData = data;
    std::sort(sortedData.begin(), sortedData.end(), [](const QVariant &a, const QVariant &b) {
        return a.toMap()["frameNumber"].toInt() < b.toMap()["frameNumber"].toInt();
    });
    return sortedData;
}

QVariantList FrameArrangementXZController::qjsonArrayToList(const QJsonArray &jsonArray)
{
    QVariantList list;
    for (const QJsonValue &value : jsonArray) {
        if (value.isObject()) {
            list.append(value.toObject().toVariantMap());
        }
    }
    return list;
}

void FrameArrangementXZController::insertBody(const QString &frameName, const QString &description, int frameId)
{
    // TODO: Implement this based on your body insertion logic
    // This function should handle inserting body data related to the frame
    qDebug() << "FrameArrangementXZController::insertBody() - Frame:" << frameName << "ID:" << frameId;
    Q_UNUSED(description)
}
