#ifndef FRAMEARRANGEMENTXZCONTROLLER_H
#define FRAMEARRANGEMENTXZCONTROLLER_H

#include <QObject>
#include <QJsonArray>
#include <QJsonObject>
#include <QVariantList>
#include <QVariantMap>
#include <QDebug>

class FrameArrangementXZ;

class FrameArrangementXZController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QJsonArray frameXZList READ frameXZList WRITE setFrameXZList NOTIFY frameXZListChanged)
    Q_PROPERTY(QJsonArray foundFrameXZ READ foundFrameXZ WRITE setFoundFrameXZ NOTIFY foundFrameXZChanged)
    Q_PROPERTY(QJsonArray secondFrameXZ READ secondFrameXZ WRITE setSecondFrameXZ NOTIFY secondFrameXZChanged)

public:
    explicit FrameArrangementXZController(QObject *parent = nullptr);

    // Property getters
    QJsonArray frameXZList() const { return m_frameXZList; }
    QJsonArray foundFrameXZ() const { return m_foundFrameXZ; }
    QJsonArray secondFrameXZ() const { return m_secondFrameXZ; }

    // Property setters
    void setFrameXZList(const QJsonArray &list);
    void setFoundFrameXZ(const QJsonArray &found);
    void setSecondFrameXZ(const QJsonArray &second);

    // Initialize with model
    void setModel(FrameArrangementXZ* model);

public slots:
    // Frame XZ operations
    void insertFrameXZ(const QString &frameName, int frameNumber, int frameSpacing, 
                      const QString &ml, double xpCoor, double xl, double xllCoor, double xllLll);
    void getFrameXZList();
    void deleteFrameXZ(int id);
    void updateFrameXZ(int id, const QString &frameName, int frameNumber, int frameSpacing,
                      const QString &ml, double xpCoor, double xl, double xllCoor, double xllLll);
    void updateFrameXZMl(int id, const QString &ml);
    int getXZLastId();
    void getFrameXZById(int id);
    void getSecondFrameXZList();
    void resetFrameXZ();
    
    // Sample data
    void addSampleData();

    // Utility functions
    void checkIsFrameZero();
    void checkChangedFrameXZ(const QVariantMap &changedData, int changedFrameNumber);
    
    // Ship properties (these should be implemented based on your ship data)
    double getShipLength() const;
    double getShipLengthL() const;

signals:
    void frameXZListChanged();
    void foundFrameXZChanged();
    void secondFrameXZChanged();
    void errorOccurred(const QString &error);

private:
    FrameArrangementXZ* m_model;
    QJsonArray m_frameXZList;
    QJsonArray m_foundFrameXZ;
    QJsonArray m_secondFrameXZ;

    // Helper functions
    QJsonArray generateObjectJson(const QVariantList &data);
    QVariantList sortByFrameNumber(const QVariantList &data);
    QVariantList qjsonArrayToList(const QJsonArray &jsonArray);
    void insertBody(const QString &frameName, const QString &description, int frameId);
};

#endif // FRAMEARRANGEMENTXZCONTROLLER_H
