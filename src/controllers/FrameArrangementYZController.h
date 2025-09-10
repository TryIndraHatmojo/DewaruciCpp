#ifndef FRAMEARRANGEMENTYZCONTROLLER_H
#define FRAMEARRANGEMENTYZCONTROLLER_H

#include <QObject>
#include <QJsonArray>
#include <QVariantList>
#include <QVariantMap>

class FrameArrangementYZ;

class FrameArrangementYZController : public QObject {
    Q_OBJECT
    Q_PROPERTY(QJsonArray frameYZList READ frameYZList WRITE setFrameYZList NOTIFY frameYZListChanged)
    Q_PROPERTY(QJsonArray selectedFrameYZ READ selectedFrameYZ WRITE setSelectedFrameYZ NOTIFY selectedFrameYZChanged)
    Q_PROPERTY(QJsonArray selectedFrameYZId READ selectedFrameYZId WRITE setSelectedFrameYZId NOTIFY selectedFrameYZIdChanged)
    Q_PROPERTY(QJsonArray selectedFrameYZName READ selectedFrameYZName WRITE setSelectedFrameYZName NOTIFY selectedFrameYZNameChanged)
    Q_PROPERTY(QJsonArray frameYZDrawing READ frameYZDrawing WRITE setFrameYZDrawing NOTIFY frameYZDrawingChanged)

public:
    explicit FrameArrangementYZController(QObject* parent = nullptr);

    // Properties
    QJsonArray frameYZList() const { return m_frameYZList; }
    QJsonArray selectedFrameYZ() const { return m_selectedFrameYZ; }
    QJsonArray selectedFrameYZId() const { return m_selectedFrameYZId; }
    QJsonArray selectedFrameYZName() const { return m_selectedFrameYZName; }
    QJsonArray frameYZDrawing() const { return m_frameYZDrawing; }

    void setFrameYZList(const QJsonArray &list);
    void setSelectedFrameYZ(const QJsonArray &list);
    void setSelectedFrameYZId(const QJsonArray &list);
    void setSelectedFrameYZName(const QJsonArray &list);
    void setFrameYZDrawing(const QJsonArray &list) { if (m_frameYZDrawing != list) { m_frameYZDrawing = list; emit frameYZDrawingChanged(); } }

    // Initialize with model
    void setModel(FrameArrangementYZ* model);

public slots:
    // CRUD & queries (mirroring the Python reference)
    Q_INVOKABLE int insertFrameYZ(const QString &name, int no, double spacing,
                                  double y, double z, int frameNo, const QString &fa, const QString &sym);
    Q_INVOKABLE void getFrameYZByFrameNo(int frameNumber);
    Q_INVOKABLE void deleteFrameYZ(int id);
    Q_INVOKABLE void updateFrameYZ(int id, const QString &name, int no, double spacing,
                                   double y, double z, int frameNo, const QString &fa, const QString &sym);
    Q_INVOKABLE void updateFrameYZFa(int id, const QString &fa);
    Q_INVOKABLE void updateFrameYZSym(int id, const QString &sym);
    Q_INVOKABLE void deleteFrameYZByFrameNumber(int frameNo);
    Q_INVOKABLE void getFrameYZAll();
    Q_INVOKABLE void getFrameYZById(int id);
    Q_INVOKABLE void getFrameYZByName(const QString &name);
    // Drawing table operations
    Q_INVOKABLE int insertFrameYZDrawing(int frameyzId, const QString &name, int no, double spacing,
                                         double y, double z, int frameNo, const QString &fa, const QString &sym);
    Q_INVOKABLE bool resetFrameYZDrawing();
    Q_INVOKABLE void getAllFrameYZDrawing();

signals:
    void frameYZListChanged();
    void selectedFrameYZChanged();
    void selectedFrameYZIdChanged();
    void selectedFrameYZNameChanged();
    void errorOccurred(const QString &error);
    void frameYZDrawingChanged();
    void frameArrangementYZDrawingChanged();

private:
    FrameArrangementYZ* m_model;
    QJsonArray m_frameYZList;
    QJsonArray m_selectedFrameYZ;
    QJsonArray m_selectedFrameYZId;
    QJsonArray m_selectedFrameYZName;
    QJsonArray m_frameYZDrawing;

    QJsonArray generateObjectJson(const QVariantList &data);
};

#endif // FRAMEARRANGEMENTYZCONTROLLER_H
