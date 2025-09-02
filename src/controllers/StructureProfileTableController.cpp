#include "StructureProfileTableController.h"
#include <QDebug>
#include <QRegularExpression>

StructureProfileTableController::StructureProfileTableController(QObject *parent)
    : QObject(parent)
    , m_model(nullptr)
    , m_isLoading(false)
{
    m_model = new StructureProfileTable(this);
    
    // Connect model signals to controller slots
    connect(m_model, &StructureProfileTable::profileInserted,
            this, &StructureProfileTableController::onProfileInserted);
    connect(m_model, &StructureProfileTable::profileUpdated,
            this, &StructureProfileTableController::onProfileUpdated);
    connect(m_model, &StructureProfileTable::profileDeleted,
            this, &StructureProfileTableController::onProfileDeleted);
    connect(m_model, &StructureProfileTable::error,
            this, &StructureProfileTableController::onModelError);
}

// Properties
QVariantList StructureProfileTableController::profiles() const
{
    return m_profiles;
}

QString StructureProfileTableController::lastError() const
{
    return m_lastError;
}

bool StructureProfileTableController::isLoading() const
{
    return m_isLoading;
}

// CRUD Operations
bool StructureProfileTableController::createProfile(const QString& type, const QString& name, 
                                     double hw, double tw, double bfProfiles, double tf,
                                     double area, double e, double w, double upperI,
                                     double lowerL, double tb, double bfBrackets, double tbf)
{
    setIsLoading(true);
    setLastError("");
    
    // Validate input data
    if (!validateProfile(type, name, hw, tw, bfProfiles, tf, area, e, w, upperI, lowerL, tb, bfBrackets, tbf)) {
        setIsLoading(false);
        return false;
    }
    
    // Check if profile with same name already exists
    if (profileExists(name)) {
        setLastError(QString("Profile with name '%1' already exists").arg(name));
        setIsLoading(false);
        return false;
    }
    
    bool success = m_model->addProfile(type, name, hw, tw, bfProfiles, tf, area, e, w, upperI, lowerL, tb, bfBrackets, tbf);
    
    if (!success) {
        setLastError(m_model->getLastError());
    } else {
        refreshProfiles();
        emit operationCompleted(true, QString("Profile '%1' created successfully").arg(name));
    }
    
    setIsLoading(false);
    return success;
}

bool StructureProfileTableController::updateProfile(int id, const QString& type, const QString& name,
                                     double hw, double tw, double bfProfiles, double tf,
                                     double area, double e, double w, double upperI,
                                     double lowerL, double tb, double bfBrackets, double tbf)
{
    setIsLoading(true);
    setLastError("");
    
    // Validate input data
    if (!validateProfile(type, name, hw, tw, bfProfiles, tf, area, e, w, upperI, lowerL, tb, bfBrackets, tbf)) {
        setIsLoading(false);
        return false;
    }
    
    // Check if profile exists
    ProfileData existing = m_model->findProfileById(id);
    if (existing.id == 0) {
        setLastError(QString("Profile with ID %1 not found").arg(id));
        setIsLoading(false);
        return false;
    }
    
    // Check if new name conflicts with existing profile (except current one)
    if (existing.name != name && profileExists(name)) {
        setLastError(QString("Profile with name '%1' already exists").arg(name));
        setIsLoading(false);
        return false;
    }
    
    bool success = m_model->updateProfileQML(id, type, name, hw, tw, bfProfiles, tf, area, e, w, upperI, lowerL, tb, bfBrackets, tbf);
    
    if (!success) {
        setLastError(m_model->getLastError());
    } else {
        refreshProfiles();
        emit operationCompleted(true, QString("Profile '%1' updated successfully").arg(name));
    }
    
    setIsLoading(false);
    return success;
}

bool StructureProfileTableController::deleteProfile(int id)
{
    setIsLoading(true);
    setLastError("");
    
    // Check if profile exists
    ProfileData existing = m_model->findProfileById(id);
    if (existing.id == 0) {
        setLastError(QString("Profile with ID %1 not found").arg(id));
        setIsLoading(false);
        return false;
    }
    
    QString profileName = existing.name;
    bool success = m_model->removeProfile(id);
    
    if (!success) {
        setLastError(m_model->getLastError());
    } else {
        refreshProfiles();
        emit operationCompleted(true, QString("Profile '%1' deleted successfully").arg(profileName));
    }
    
    setIsLoading(false);
    return success;
}

bool StructureProfileTableController::deleteProfileByName(const QString& name)
{
    setIsLoading(true);
    setLastError("");
    
    if (name.isEmpty()) {
        setLastError("Profile name cannot be empty");
        setIsLoading(false);
        return false;
    }
    
    // Check if profile exists
    ProfileData existing = m_model->findProfileByName(name);
    if (existing.id == 0) {
        setLastError(QString("Profile with name '%1' not found").arg(name));
        setIsLoading(false);
        return false;
    }
    
    bool success = m_model->deleteProfileByName(name);
    
    if (!success) {
        setLastError(m_model->getLastError());
    } else {
        refreshProfiles();
        emit operationCompleted(true, QString("Profile '%1' deleted successfully").arg(name));
    }
    
    setIsLoading(false);
    return success;
}

// Query operations
QVariantMap StructureProfileTableController::getProfileById(int id)
{
    ProfileData profile = m_model->findProfileById(id);
    if (profile.id == 0) {
        setLastError(QString("Profile with ID %1 not found").arg(id));
        return QVariantMap();
    }
    
    return profileDataToVariantMap(profile);
}

QVariantMap StructureProfileTableController::getProfileByName(const QString& name)
{
    ProfileData profile = m_model->findProfileByName(name);
    if (profile.id == 0) {
        setLastError(QString("Profile with name '%1' not found").arg(name));
        return QVariantMap();
    }
    
    return profileDataToVariantMap(profile);
}

void StructureProfileTableController::refreshProfiles()
{
    setIsLoading(true);
    loadProfilesFromModel();
    setIsLoading(false);
}

// Batch operations
bool StructureProfileTableController::clearAllProfiles()
{
    setIsLoading(true);
    setLastError("");
    
    bool success = m_model->clearAllProfiles();
    
    if (!success) {
        setLastError(m_model->getLastError());
    } else {
        refreshProfiles();
        emit operationCompleted(true, "All profiles cleared successfully");
    }
    
    setIsLoading(false);
    return success;
}

bool StructureProfileTableController::loadSampleData()
{
    setIsLoading(true);
    setLastError("");
    
    bool success = m_model->insertSampleData();
    
    if (!success) {
        setLastError(m_model->getLastError());
    } else {
        refreshProfiles();
        emit operationCompleted(true, "Sample data loaded successfully");
    }
    
    setIsLoading(false);
    return success;
}

// Validation
bool StructureProfileTableController::validateProfile(const QString& type, const QString& name,
                                       double hw, double tw, double bfProfiles, double tf,
                                       double area, double e, double w, double upperI,
                                       double lowerL, double tb, double bfBrackets, double tbf)
{
    // Check required fields
    if (type.trimmed().isEmpty()) {
        setLastError("Profile type cannot be empty");
        return false;
    }
    
    if (name.trimmed().isEmpty()) {
        setLastError("Profile name cannot be empty");
        return false;
    }
    
    // Validate numeric values (should be non-negative for physical properties)
    if (!isValidProfileData(type, name, hw, tw, bfProfiles, tf, area, e, w, upperI, lowerL, tb, bfBrackets, tbf)) {
        return false;
    }
    
    // Validate name format (alphanumeric and common symbols)
    QRegularExpression nameRegex("^[A-Za-z0-9_\\-\\.\\s]+$");
    if (!nameRegex.match(name).hasMatch()) {
        setLastError("Profile name contains invalid characters. Only letters, numbers, spaces, hyphens, underscores, and dots are allowed");
        return false;
    }
    
    return true;
}

// Search and filter
QVariantList StructureProfileTableController::searchProfiles(const QString& searchTerm)
{
    QVariantList result;
    QString lowerSearchTerm = searchTerm.toLower();
    
    for (const QVariant& profileVariant : m_profiles) {
        QVariantMap profile = profileVariant.toMap();
        QString type = profile["type"].toString().toLower();
        QString name = profile["name"].toString().toLower();
        
        if (type.contains(lowerSearchTerm) || name.contains(lowerSearchTerm)) {
            result.append(profile);
        }
    }
    
    return result;
}

QVariantList StructureProfileTableController::filterProfilesByType(const QString& type)
{
    QVariantList result;
    QString lowerType = type.toLower();
    
    for (const QVariant& profileVariant : m_profiles) {
        QVariantMap profile = profileVariant.toMap();
        if (profile["type"].toString().toLower() == lowerType) {
            result.append(profile);
        }
    }
    
    return result;
}

// Utility functions
int StructureProfileTableController::getProfileCount()
{
    return m_profiles.size();
}

bool StructureProfileTableController::profileExists(const QString& name)
{
    ProfileData existing = m_model->findProfileByName(name);
    return existing.id != 0;
}

QStringList StructureProfileTableController::getAvailableTypes()
{
    QStringList types;
    QSet<QString> uniqueTypes;
    
    for (const QVariant& profileVariant : m_profiles) {
        QVariantMap profile = profileVariant.toMap();
        QString type = profile["type"].toString();
        if (!type.isEmpty()) {
            uniqueTypes.insert(type);
        }
    }
    
    types = uniqueTypes.values();
    types.sort();
    return types;
}

// Public slots
void StructureProfileTableController::initialize()
{
    setIsLoading(true);
    
    // Create table if it doesn't exist
    if (!m_model->createTable()) {
        setLastError(m_model->getLastError());
        setIsLoading(false);
        return;
    }
    
    // Load initial data
    loadProfilesFromModel();
    setIsLoading(false);
    
    qDebug() << "StructureProfileTableController::initialize() - Controller initialized with" << m_profiles.size() << "profiles";
}

// Private slots
void StructureProfileTableController::onProfileInserted(int id)
{
    emit profileCreated(id);
    refreshProfiles();
}

void StructureProfileTableController::onProfileUpdated(int id)
{
    emit profileUpdated(id);
    refreshProfiles();
}

void StructureProfileTableController::onProfileDeleted(int id)
{
    emit profileDeleted(id);
    refreshProfiles();
}

void StructureProfileTableController::onModelError(const QString& error)
{
    setLastError(error);
}

// Private helper methods
void StructureProfileTableController::setLastError(const QString& error)
{
    if (m_lastError != error) {
        m_lastError = error;
        emit lastErrorChanged();
        
        if (!error.isEmpty()) {
            qWarning() << "ProfileController error:" << error;
        }
    }
}

void StructureProfileTableController::setIsLoading(bool loading)
{
    if (m_isLoading != loading) {
        m_isLoading = loading;
        emit isLoadingChanged();
    }
}

void StructureProfileTableController::loadProfilesFromModel()
{
    QVariantList newProfiles = m_model->getAllProfilesForQML();
    
    if (m_profiles != newProfiles) {
        m_profiles = newProfiles;
        emit profilesChanged();
    }
}

QVariantMap StructureProfileTableController::profileDataToVariantMap(const ProfileData& profile)
{
    QVariantMap map;
    map["id"] = profile.id;
    map["type"] = profile.type;
    map["name"] = profile.name;
    map["hw"] = profile.hw;
    map["tw"] = profile.tw;
    map["bfProfiles"] = profile.bfProfiles;
    map["tf"] = profile.tf;
    map["area"] = profile.area;
    map["e"] = profile.e;
    map["w"] = profile.w;
    map["upperI"] = profile.upperI;
    map["lowerL"] = profile.lowerL;
    map["tb"] = profile.tb;
    map["bfBrackets"] = profile.bfBrackets;
    map["tbf"] = profile.tbf;
    map["createdAt"] = profile.createdAt;
    map["updatedAt"] = profile.updatedAt;
    return map;
}

bool StructureProfileTableController::isValidProfileData(const QString& type, const QString& name,
                                          double hw, double tw, double bfProfiles, double tf,
                                          double area, double e, double w, double upperI,
                                          double lowerL, double tb, double bfBrackets, double tbf)
{
    // Check for negative values where they don't make sense
    QList<QPair<double, QString>> valuesToCheck = {
        {hw, "Height (hw)"},
        {tw, "Web thickness (tw)"},
        {bfProfiles, "Bottom flange profiles (bf_profiles)"},
        {tf, "Flange thickness (tf)"},
        {area, "Area"},
        {w, "Width (w)"},
        {upperI, "Upper inertia (upper_i)"},
        {lowerL, "Lower length (lower_l)"},
        {tb, "Bracket thickness (tb)"},
        {bfBrackets, "Bottom flange brackets (bf_brackets)"},
        {tbf, "Bracket flange thickness (tbf)"}
    };
    
    for (const auto& pair : valuesToCheck) {
        if (pair.first < 0) {
            setLastError(QString("%1 cannot be negative").arg(pair.second));
            return false;
        }
    }
    
    // Check for reasonable minimum values for critical dimensions
    if (hw > 0 && hw < 1.0) {
        setLastError("Height (hw) must be at least 1.0 mm if specified");
        return false;
    }
    
    if (tw > 0 && tw < 0.1) {
        setLastError("Web thickness (tw) must be at least 0.1 mm if specified");
        return false;
    }
    
    if (tf > 0 && tf < 0.1) {
        setLastError("Flange thickness (tf) must be at least 0.1 mm if specified");
        return false;
    }
    
    // Check for unreasonably large values
    QList<QPair<double, QString>> maxValueChecks = {
        {hw, "Height (hw)"},
        {tw, "Web thickness (tw)"},
        {bfProfiles, "Bottom flange profiles (bf_profiles)"},
        {tf, "Flange thickness (tf)"},
        {w, "Width (w)"}
    };
    
    for (const auto& pair : maxValueChecks) {
        if (pair.first > 10000.0) {
            setLastError(QString("%1 value seems unreasonably large (>10000)").arg(pair.second));
            return false;
        }
    }
    
    return true;
}
