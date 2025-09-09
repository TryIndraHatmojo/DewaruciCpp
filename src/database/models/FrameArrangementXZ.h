#ifndef FRAMEARRANGEMENTXZ_H
#define FRAMEARRANGEMENTXZ_H

#include <QObject>
#include <QAbstractListModel>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QDebug>

class FrameArrangementXZ : public QAbstractListModel
{
    Q_OBJECT

public:
    enum FrameRoles {
        IdRole = Qt::UserRole + 1,
        FrameNameRole,
        FrameNumberRole,
        FrameSpacingRole,
        MlRole,
        XpCoorRole,
        XlRole,
        XllCoorRole,
        XllLllRole
    };

    struct FrameData {
        int id;
        QString frameName;
        int frameNumber;
        int frameSpacing;        // Changed from double to int
        QString ml;              // Changed from double to QString
        double xpCoor;
        double xl;
        double xllCoor;
        double xllLll;
        qint64 createdAt;        // Added timestamp
        qint64 updatedAt;        // Added timestamp
    };

    explicit FrameArrangementXZ(QObject *parent = nullptr);
    
    // QAbstractListModel interface
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    // Database operations
    Q_INVOKABLE bool createTable();
    Q_INVOKABLE bool loadData();
    Q_INVOKABLE bool insertFrame(const QString &frameName, int frameNumber, int frameSpacing, 
                                const QString &ml, double xpCoor, double xl, double xllCoor, double xllLll);
    Q_INVOKABLE bool updateFrame(int id, const QString &frameName, int frameNumber, int frameSpacing,
                                const QString &ml, double xpCoor, double xl, double xllCoor, double xllLll);
    Q_INVOKABLE bool updateFrameMl(int id, const QString &ml);
    Q_INVOKABLE bool deleteFrame(int id);
    Q_INVOKABLE int getLastId();
    Q_INVOKABLE QVariantMap getFrameById(int id);
    Q_INVOKABLE bool resetDatabase();

    // Utility functions
    Q_INVOKABLE int getRowCount() const;
    Q_INVOKABLE QVariantMap getFrameAtIndex(int index) const;

signals:
    void dataChanged();
    void errorOccurred(const QString &error);

private:
    QList<FrameData> m_frameData;
    QString m_lastError;
    
    void clearData();
    QSqlDatabase getDatabase() const;
};

#endif // FRAMEARRANGEMENTXZ_H
