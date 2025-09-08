#ifndef FRAMEARRANGEMENTYZ_H
#define FRAMEARRANGEMENTYZ_H

#include <QObject>
#include <QAbstractListModel>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QDebug>

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
        SymRole
    };

    struct FrameYZData {
        int id;
        QString name;
        int no;
        double spacing;
        double y;
        double z;
        int frameNo;
        double fa;
        double sym;
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
                               double y, double z, int frameNo, double fa, double sym);
    Q_INVOKABLE bool updateFrame(int id, const QString &name, int no, double spacing,
                                double y, double z, int frameNo, double fa, double sym);
    Q_INVOKABLE bool updateFrameFa(int id, double fa);
    Q_INVOKABLE bool updateFrameSym(int id, double sym);
    Q_INVOKABLE bool deleteFrame(int id);
    Q_INVOKABLE bool deleteFramesByFrameNumber(int frameNumber);
    Q_INVOKABLE QVariantMap getFrameById(int id);
    Q_INVOKABLE QVariantList getFramesByName(const QString &name);
    Q_INVOKABLE QVariantList getFramesByFrameNo(int frameNumber);

    // Utility functions
    Q_INVOKABLE int getRowCount() const;
    Q_INVOKABLE QVariantMap getFrameAtIndex(int index) const;

signals:
    void dataChanged();
    void errorOccurred(const QString &error);

private:
    QList<FrameYZData> m_frameYZData;
    QString m_lastError;
    
    void clearData();
    QSqlDatabase getDatabase() const;
};

#endif // FRAMEARRANGEMENTYZ_H
