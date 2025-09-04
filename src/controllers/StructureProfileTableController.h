#ifndef STRUCTUREPROFILETABLECONTROLLER_H
#define STRUCTUREPROFILETABLECONTROLLER_H

#include <QObject>
#include <QVariantList>
#include <QVariantMap>
#include "../database/models/StructureProfileTable.h"

class StructureProfileTableController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList profiles READ profiles NOTIFY profilesChanged)
    Q_PROPERTY(QVariantList profilesData READ getProfilesData NOTIFY profilesDataChanged)
    Q_PROPERTY(QString lastError READ lastError NOTIFY lastErrorChanged)
    Q_PROPERTY(bool isLoading READ isLoading NOTIFY isLoadingChanged)
    Q_PROPERTY(int lastInsertedId READ lastInsertedId NOTIFY lastInsertedIdChanged)

public:
    explicit StructureProfileTableController(QObject *parent = nullptr);
    
    // Properties
    QVariantList profiles() const;
    QVariantList getProfilesData() const;
    QString lastError() const;
    bool isLoading() const;
    int lastInsertedId() const;
    
    // CRUD Operations accessible from QML
    Q_INVOKABLE bool createProfile(const QString& type, const QString& name, 
                                  double hw, double tw, double bfProfiles, double tf,
                                  double area, double e, double w, double upperI,
                                  double lowerL, double tb, double bfBrackets, double tbf);
    
    Q_INVOKABLE bool updateProfile(int id, const QString& type, const QString& name,
                                  double hw, double tw, double bfProfiles, double tf,
                                  double area, double e, double w, double upperI,
                                  double lowerL, double tb, double bfBrackets, double tbf);
    
    Q_INVOKABLE bool deleteProfile(int id);
    Q_INVOKABLE bool deleteProfileByName(const QString& name);
    
    // Query operations
    Q_INVOKABLE QVariantMap getProfileById(int id);
    Q_INVOKABLE QVariantMap getProfileByName(const QString& name);
    Q_INVOKABLE void refreshProfiles();
    
    // Batch operations
    Q_INVOKABLE bool clearAllProfiles();
    Q_INVOKABLE bool loadSampleData();
    
    // Validation
    Q_INVOKABLE bool validateProfile(const QString& type, const QString& name,
                                    double hw, double tw, double bfProfiles, double tf,
                                    double area, double e, double w, double upperI,
                                    double lowerL, double tb, double bfBrackets, double tbf);
    
    // Search and filter
    Q_INVOKABLE QVariantList searchProfiles(const QString& searchTerm);
    Q_INVOKABLE QVariantList filterProfilesByType(const QString& type);
    
    // Utility functions
    Q_INVOKABLE int getProfileCount();
    Q_INVOKABLE bool profileExists(const QString& name);
    Q_INVOKABLE QStringList getAvailableTypes();
    
    // Calculation functions
    Q_INVOKABLE QVariantList countingFormula(double hw, double tw, double bf, double tf, const QString& name);
    Q_INVOKABLE QVariantList countingFormulaEdit(double hw, double tw, double bf, double tf, 
                                                 double area, double e, double w, double upperI, 
                                                 const QString& name);
    
    // Bracket calculation functions
    Q_INVOKABLE QVariantList profileTableCountingFormulaBrackets(double tw, double W, double rehProfile, double rehBracket);
    Q_INVOKABLE QVariantList profileTableCountingFormulaBracketsEdit(double tw, double W, double rehProfile, double rehBracket,
                                                                     double l, double tb, double bf, double tbf);
    
    // Data management functions (similar to LinearIsotropicMaterials)
    Q_INVOKABLE QVariantList getAllProfilesData();
    Q_INVOKABLE bool addNewProfile(const QString& type, const QString& name, double hw, double tw, 
                                  double bfProfiles, double tf, double area, double e, double w, 
                                  double upperI, double lowerL, double tb, double bfBrackets, double tbf);
    Q_INVOKABLE bool updateProfileData(int id, const QString& type, const QString& name, double hw, double tw,
                                      double bfProfiles, double tf, double area, double e, double w,
                                      double upperI, double lowerL, double tb, double bfBrackets, double tbf);
    Q_INVOKABLE bool removeProfileData(int id);
    Q_INVOKABLE QString getLastError() const;

public slots:
    void initialize();

signals:
    void profilesChanged();
    void profilesDataChanged();
    void lastErrorChanged();
    void isLoadingChanged();
    void lastInsertedIdChanged();
    void profileCreated(int id);
    void profileUpdated(int id);
    void profileDeleted(int id);
    void operationCompleted(bool success, const QString& message);

private slots:
    void onProfileInserted(int id);
    void onProfileUpdated(int id);
    void onProfileDeleted(int id);
    void onModelError(const QString& error);

private:
    StructureProfileTable* m_model;
    QVariantList m_profiles;
    QString m_lastError;
    bool m_isLoading;
    int m_lastInsertedId;
    
    // Helper methods
    void setLastError(const QString& error);
    void setIsLoading(bool loading);
    void setLastInsertedId(int id);
    void loadProfilesFromModel();
    QVariantMap profileDataToVariantMap(const ProfileData& profile);
    bool isValidProfileData(const QString& type, const QString& name,
                           double hw, double tw, double bfProfiles, double tf,
                           double area, double e, double w, double upperI,
                           double lowerL, double tb, double bfBrackets, double tbf);
};

#endif // STRUCTUREPROFILETABLECONTROLLER_H
