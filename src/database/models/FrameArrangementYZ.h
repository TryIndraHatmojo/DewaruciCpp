#ifndef FRAMEARRANGEMENTYZ_H
#define FRAMEARRANGEMENTYZ_H

#include <QObject>
#include <QAbstractListModel>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QDebug>
#include <QVariant>
#include <string>

class FrameArrangementYZ : public QAbstractListModel
{
    Q_OBJECT

public:
    enum FrameRoles {
        IdRole = Qt::UserRole + 1,
        NameRole,
        NoRole,
        SpacingRole,
        YRole,
        ZRole,
        FrameNoRole,
    FaRole,
    SymRole,
    IsManualRole,
    CreatedAtRole,
    UpdatedAtRole
    };

    struct FrameYZData {
        int id;
        QString name;
        int no;
        double spacing;
    QVariant y; // allow empty string or number
    QVariant z; // allow empty string or number
        int frameNo;
    QString fa;   // TEXT in DB
    QString sym;  // TEXT in DB
    bool isManual{false};
    qint64 createdAt{0};
    qint64 updatedAt{0};
    };

    explicit FrameArrangementYZ(QObject *parent = nullptr);
    
    // QAbstractListModel interface
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    // Database operations
    Q_INVOKABLE bool createTable();
    Q_INVOKABLE bool loadData();
    Q_INVOKABLE bool loadDataByFrameNo(int frameNumber);
    Q_INVOKABLE int insertFrame(const QString &name, int no, double spacing, 
                               const QVariant &y, const QVariant &z, int frameNo, const QString &fa, const QString &sym);
    Q_INVOKABLE bool updateFrame(int id, const QString &name, int no, double spacing,
                                const QVariant &y, const QVariant &z, int frameNo, const QString &fa, const QString &sym);
    // Update only the name column; when reloadModel is false, does not call loadData()
    Q_INVOKABLE bool updateFrameName(int id, const QString &name, bool reloadModel = true);
    Q_INVOKABLE bool updateFrameFa(int id, const QString &fa);
    Q_INVOKABLE bool updateFrameSym(int id, const QString &sym);
    Q_INVOKABLE bool updateFrameIsManual(int id, bool isManual);
    Q_INVOKABLE bool deleteFrame(int id);
    Q_INVOKABLE bool deleteFramesByFrameNumber(int frameNumber);
    Q_INVOKABLE QVariantMap getFrameById(int id);
    Q_INVOKABLE QVariantList getFramesByName(const QString &name);
    Q_INVOKABLE QVariantList getFramesByFrameNo(int frameNumber);

    // YZ Drawing auxiliary table operations
    Q_INVOKABLE bool createDrawingTable();
    Q_INVOKABLE int insertFrameYZDrawing(int frameyzId, const QString &name, int no, double spacing,
                                         double y, double z, int frameNo, const QString &fa, const QString &sym);
    Q_INVOKABLE bool resetFrameYZDrawingTable();
    Q_INVOKABLE QVariantList getAllFrameYZDrawing();

    // Conflict and assignment APIs
    Q_INVOKABLE QVariantList checkSuffixConflict(const QString &prefix, int startSuffix, int count) const;
    Q_INVOKABLE int getLastSuffixForPrefix(const QString &prefix) const;
    Q_INVOKABLE bool assignManualNames(int id, const QString &prefix, int startSuffix, int count);
    Q_INVOKABLE bool assignAutoNamesFrom(int id, const QString &prefix, int continueFromSuffix, int count);

    // Optional in-memory storage for drawing rows matching required C++ types
    struct FrameYZDrawingData {
        int id{0};
        int frameyz_id{0};
        std::string name;
        int no{0};
        double spacing{0.0};
        double y{0.0};
        double z{0.0};
        int frame_no{0};
        std::string fa;
        std::string sym;
        int created_at{0}; // Note: DB stores milliseconds epoch (64-bit); truncated to int per spec
        int updated_at{0};
    };

    // Utility functions
    Q_INVOKABLE int getRowCount() const;
    Q_INVOKABLE QVariantMap getFrameAtIndex(int index) const;

signals:
    void dataChanged();
    void errorOccurred(const QString &error);

private:
    QList<FrameYZData> m_frameYZData;
    QList<FrameYZDrawingData> m_frameYZDrawingData; // mirrors drawing table
    QString m_lastError;
    
    void clearData();
    QSqlDatabase getDatabase() const;
};

#endif // FRAMEARRANGEMENTYZ_H
