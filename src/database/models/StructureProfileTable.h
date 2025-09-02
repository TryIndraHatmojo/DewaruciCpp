#ifndef STRUCTUREPROFILETABLE_H
#define STRUCTUREPROFILETABLE_H

#include <QObject>
#include <QSqlQuery>
#include <QSqlError>
#include <QSqlDatabase>
#include <QVariantList>
#include <QVariantMap>
#include <QDebug>

struct ProfileData {
    int id = 0;
    QString type;
    QString name;
    double hw = 0.0;
    double tw = 0.0;
    double bfProfiles = 0.0;
    double tf = 0.0;
    double area = 0.0;
    double e = 0.0;
    double w = 0.0;
    double upperI = 0.0;
    double lowerL = 0.0;
    double tb = 0.0;
    double bfBrackets = 0.0;
    double tbf = 0.0;
    qint64 createdAt = 0;
    qint64 updatedAt = 0;
};

class StructureProfileTable : public QObject
{
    Q_OBJECT

public:
    explicit StructureProfileTable(QObject *parent = nullptr);

    // Table management
    Q_INVOKABLE bool createTable();
    
    // CRUD operations
    bool insertProfile(const QString& type, const QString& name, double hw, double tw, 
                      double bfProfiles, double tf, double area, double e, double w,
                      double upperI, double lowerL, double tb, double bfBrackets, double tbf);
    
    bool updateProfile(int id, const QString& type, const QString& name, double hw, double tw,
                      double bfProfiles, double tf, double area, double e, double w,
                      double upperI, double lowerL, double tb, double bfBrackets, double tbf);
    
    bool deleteProfile(int id);
    bool deleteProfileByName(const QString& name);
    
    // Query operations
    ProfileData findProfileById(int id);
    ProfileData findProfileByName(const QString& name);
    QList<ProfileData> getAllProfiles();
    
    // Utility functions
    bool clearAllProfiles();
    bool insertSampleData();
    
    // QML accessible functions
    Q_INVOKABLE QVariantList getAllProfilesForQML();
    Q_INVOKABLE bool addProfile(const QString& type, const QString& name, double hw, double tw,
                               double bfProfiles, double tf, double area, double e, double w,
                               double upperI, double lowerL, double tb, double bfBrackets, double tbf);
    Q_INVOKABLE bool updateProfileQML(int id, const QString& type, const QString& name, double hw, double tw,
                                      double bfProfiles, double tf, double area, double e, double w,
                                      double upperI, double lowerL, double tb, double bfBrackets, double tbf);
    Q_INVOKABLE bool removeProfile(int id);
    Q_INVOKABLE QString getLastError() const;

signals:
    void profileInserted(int id);
    void profileUpdated(int id);
    void profileDeleted(int id);
    void error(const QString& message);

private:
    QString m_lastError;
    
    // Helper methods
    bool executeQuery(QSqlQuery& query, const QString& operation);
    ProfileData createProfileFromQuery(const QSqlQuery& query);
};

#endif // STRUCTUREPROFILETABLE_H
