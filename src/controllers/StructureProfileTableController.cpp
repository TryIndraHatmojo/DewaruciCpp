#include "StructureProfileTableController.h"
#include <QDebug>
#include <QRegularExpression>
#include <cmath>
#include <algorithm>

StructureProfileTableController::StructureProfileTableController(QObject *parent)
    : QObject(parent)
    , m_model(nullptr)
    , m_isLoading(false)
    , m_lastInsertedId(0)
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

int StructureProfileTableController::lastInsertedId() const
{
    return m_lastInsertedId;
}

// CRUD Operations
bool StructureProfileTableController::createProfile(const QString& type, const QString& name, 
                                     double hw, double tw, double bfProfiles, double tf,
                                     double area, double e, double w, double upperI,
                                     double lowerL, double tb, double bfBrackets, double tbf)
{
    setIsLoading(true);
    setLastError("");
    
    // Round all numeric values to 2 decimal places for consistency
    hw = std::round(hw * 100.0) / 100.0;
    tw = std::round(tw * 100.0) / 100.0;
    bfProfiles = std::round(bfProfiles * 100.0) / 100.0;
    tf = std::round(tf * 100.0) / 100.0;
    area = std::round(area * 100.0) / 100.0;
    e = std::round(e * 100.0) / 100.0;
    w = std::round(w * 100.0) / 100.0;
    upperI = std::round(upperI * 100.0) / 100.0;
    lowerL = std::round(lowerL * 100.0) / 100.0;
    tb = std::round(tb * 100.0) / 100.0;
    bfBrackets = std::round(bfBrackets * 100.0) / 100.0;
    tbf = std::round(tbf * 100.0) / 100.0;
    
    // Validate input data
    if (!validateProfile(type, name, hw, tw, bfProfiles, tf, area, e, w, upperI, lowerL, tb, bfBrackets, tbf)) {
        setIsLoading(false);
        return false;
    }
    
    // Check if profile with same name already exists
    // if (profileExists(name)) {
    //     setLastError(QString("Profile with name '%1' already exists").arg(name));
    //     setIsLoading(false);
    //     return false;
    // }
    
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
    
    // Round all numeric values to 2 decimal places for consistency
    hw = std::round(hw * 100.0) / 100.0;
    tw = std::round(tw * 100.0) / 100.0;
    bfProfiles = std::round(bfProfiles * 100.0) / 100.0;
    tf = std::round(tf * 100.0) / 100.0;
    area = std::round(area * 100.0) / 100.0;
    e = std::round(e * 100.0) / 100.0;
    w = std::round(w * 100.0) / 100.0;
    upperI = std::round(upperI * 100.0) / 100.0;
    lowerL = std::round(lowerL * 100.0) / 100.0;
    tb = std::round(tb * 100.0) / 100.0;
    bfBrackets = std::round(bfBrackets * 100.0) / 100.0;
    tbf = std::round(tbf * 100.0) / 100.0;
    
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
    // if (existing.name != name && profileExists(name)) {
    //     setLastError(QString("Profile with name '%1' already exists").arg(name));
    //     setIsLoading(false);
    //     return false;
    // }
    
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
    
    // Validate numeric values (should be non-negative for physical properties)
    // if (!isValidProfileData(type, name, hw, tw, bfProfiles, tf, area, e, w, upperI, lowerL, tb, bfBrackets, tbf)) {
    //     return false;
    // }
    
    // Validate name format (alphanumeric and common symbols)
    // QRegularExpression nameRegex("^[A-Za-z0-9_\\-\\.\\s]+$");
    // if (!nameRegex.match(name).hasMatch()) {
    //     setLastError("Profile name contains invalid characters. Only letters, numbers, spaces, hyphens, underscores, and dots are allowed");
    //     return false;
    // }
    
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
    qDebug() << "StructureProfileTableController::initialize() called";
    
    setIsLoading(true);
    
    // Create table if it doesn't exist
    qDebug() << "StructureProfileTableController::initialize() - Creating table";
    if (!m_model->createTable()) {
        qDebug() << "StructureProfileTableController::initialize() - Failed to create table:" << m_model->getLastError();
        setLastError(m_model->getLastError());
        setIsLoading(false);
        return;
    }
    
    qDebug() << "StructureProfileTableController::initialize() - Table created successfully";
    
    // Load initial data
    qDebug() << "StructureProfileTableController::initialize() - Loading initial data";
    loadProfilesFromModel();
    setIsLoading(false);
    
    qDebug() << "StructureProfileTableController::initialize() - Controller initialized with" << m_profiles.size() << "profiles";
}

// Private slots
void StructureProfileTableController::onProfileInserted(int id)
{
    setLastInsertedId(id);
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

void StructureProfileTableController::setLastInsertedId(int id)
{
    if (m_lastInsertedId != id) {
        m_lastInsertedId = id;
        emit lastInsertedIdChanged();
    }
}

void StructureProfileTableController::loadProfilesFromModel()
{
    qDebug() << "StructureProfileTableController::loadProfilesFromModel() called";
    
    QVariantList newProfiles = m_model->getAllProfilesForQML();
    
    qDebug() << "StructureProfileTableController::loadProfilesFromModel() - Got profiles from model, count:" << newProfiles.size();
    
    if (m_profiles != newProfiles) {
        qDebug() << "StructureProfileTableController::loadProfilesFromModel() - Profiles changed, updating";
        m_profiles = newProfiles;
        emit profilesChanged();
        emit profilesDataChanged();
    } else {
        qDebug() << "StructureProfileTableController::loadProfilesFromModel() - Profiles unchanged";
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

// Calculation functions
QVariantList StructureProfileTableController::countingFormula(double hw, double tw, double bf, double tf, const QString& type)
{
    double hw_cm = hw / 10.0;
    double tw_cm = tw / 10.0;
    double bf_cm = bf / 10.0;
    double tf_cm = tf / 10.0;
    double attch_plate_cm = tw / 10.0;
    double AttchX = 40.0 * attch_plate_cm;

    // Count area
    double FaceX = bf_cm;
    double WebX = tw_cm;
    
    double FaceY = tf_cm;
    double WebY = hw_cm - tf_cm;
    
    double AttchY = tw / 10.0;
    double FaceZ = (0.5 * FaceY) + WebY;
    double WebZ = 0.5 * WebY;
    double FaceZ2 = (0.5 * FaceY) + WebY + AttchY;
    double WebZ2 = 0.5 * WebY + AttchY;
    
    double AttchZ = 0.5 * AttchY;
    double FaceA = FaceX * FaceY;
    double FaceAZ = FaceA * FaceZ;
    double FaceAZ2 = FaceA * FaceZ2;
    double FaceAzZ = FaceAZ2 * FaceZ2;
    double FaceI = (FaceX * pow(FaceY, 3.0)) / 12.0;
    
    double WebA = WebX * WebY;
    double WebAZ = WebA * WebZ;
    double WebAZ2 = WebA * WebZ2;
    double WebAzZ = WebAZ2 * WebZ2;
    
    double WebI = (WebX * pow(WebY, 3.0)) / 12.0;
    double AttchA = AttchX * AttchY;
    double AttchAZ = AttchA * AttchZ;
    double AttchAzZ = AttchAZ * AttchZ;
    double AttchI = (AttchX * pow(AttchY, 3.0)) / 12.0;

    // Final area
    double area = FaceA + WebA;

    // Count e
    double z1 = 10.0 * (FaceAZ + WebAZ) / (FaceA + WebA);

    // Final e
    double e = z1;

    // Count upper_i
    double z12 = (FaceAZ2 + WebAZ2 + AttchAZ) / (FaceA + WebA + AttchA);
    double z2 = hw_cm + attch_plate_cm - z12;
    double sigmaAzz = FaceAzZ + WebAzZ + AttchAzZ;
    double sigmaUpperI = FaceI + WebI + AttchI;
    double sigmaA = FaceA + WebA + AttchA;
    double inertia_section = (sigmaAzz + sigmaUpperI) - (sigmaA * pow(z12, 2.0));

    // Final upper_i
    double upper_i = inertia_section;

    // Count moduli actual
    double moduli_actual;
    if (type == "HP") {
        moduli_actual = 2.1445 * std::min(inertia_section / z12, inertia_section / z2);
    } else {
        moduli_actual = std::min(inertia_section / z12, inertia_section / z2);
    }

    // Count moduli ksp
    double moduli_ksp;
    if (type == "Bar" || type == "T" || type == "FB") {
        moduli_ksp = moduli_actual / 1.0;
    } else if (type == "HP") {
        moduli_ksp = moduli_actual / 1.03;
    } else if (type == "L") {
        moduli_ksp = moduli_actual / 1.15;
    } else {
        moduli_ksp = 0.0;
    }

    // Final w
    double w = moduli_ksp;
    
    qDebug() << "counting_formula" << area << e << w << upper_i;
    
    // Round all results to 2 decimal places for consistency
    area = std::round(area * 100.0) / 100.0;
    e = std::round(e * 100.0) / 100.0;
    w = std::round(w * 100.0) / 100.0;
    upper_i = std::round(upper_i * 100.0) / 100.0;
    
    qDebug() << "counting_formula (rounded)" << area << e << w << upper_i;
    
    QVariantList result;
    result << area << e << w << upper_i;
    return result;
}

QVariantList StructureProfileTableController::countingFormulaEdit(double hw, double tw, double bf, double tf, 
                                                                 double area, double e, double w, double upperI, 
                                                                 const QString& type)
{
    double hw_cm = hw / 10.0;
    double tw_cm = tw / 10.0;
    double bf_cm = bf / 10.0;
    double tf_cm = tf / 10.0;
    double attch_plate_cm = tw / 10.0;
    double AttchX = 40.0 * attch_plate_cm;
    
    // Count area
    double FaceX = bf_cm;
    double WebX = tw_cm;
    
    double FaceY = tf_cm;
    double WebY = hw_cm - tf_cm;
    
    double AttchY = tw / 10.0;
    double FaceZ = (0.5 * FaceY) + WebY;
    double WebZ = 0.5 * WebY;
    double FaceZ2 = (0.5 * FaceY) + WebY + AttchY;
    double WebZ2 = 0.5 * WebY + AttchY;
    
    double AttchZ = 0.5 * AttchY;
    double FaceA = FaceX * FaceY;
    double FaceAZ = FaceA * FaceZ;
    double FaceAZ2 = FaceA * FaceZ2;
    double FaceAzZ = FaceAZ2 * FaceZ2;
    double FaceI = (FaceX * pow(FaceY, 3.0)) / 12.0;
    
    double WebA = WebX * WebY;
    double WebAZ = WebA * WebZ;
    double WebAZ2 = WebA * WebZ2;
    double WebAzZ = WebAZ2 * WebZ2;
    
    double WebI = (WebX * pow(WebY, 3.0)) / 12.0;
    double AttchA = AttchX * AttchY;
    double AttchAZ = AttchA * AttchZ;
    double AttchAzZ = AttchAZ * AttchZ;
    double AttchI = (AttchX * pow(AttchY, 3.0)) / 12.0;

    // Use existing area or calculate new one
    double final_area;
    if (area == 0.0) {
        final_area = FaceA + WebA;
    } else {
        final_area = area;
    }

    // Count e
    double z1 = 10.0 * (FaceAZ + WebAZ) / (FaceA + WebA);

    // Use existing e or calculate new one
    double final_e;
    if (e == 0.0) {
        final_e = z1;
    } else {
        final_e = e;
    }

    // Count upper_i
    double z12 = (FaceAZ2 + WebAZ2 + AttchAZ) / (FaceA + WebA + AttchA);
    double z2 = hw_cm + attch_plate_cm - z12;
    double sigmaAzz = FaceAzZ + WebAzZ + AttchAzZ;
    double sigmaUpperI = FaceI + WebI + AttchI;
    double sigmaA = FaceA + WebA + AttchA;
    double inertia_section = (sigmaAzz + sigmaUpperI) - (sigmaA * pow(z12, 2.0));

    // Use existing upper_i or calculate new one
    double final_upperI;
    if (upperI == 0.0) {
        final_upperI = inertia_section;
    } else {
        final_upperI = upperI;
    }

    // Count moduli actual
    double moduli_actual;
    if (type == "HP") {
        moduli_actual = 2.1445 * std::min(inertia_section / z12, inertia_section / z2);
    } else {
        moduli_actual = std::min(inertia_section / z12, inertia_section / z2);
    }

    // Count moduli ksp
    double moduli_ksp;
    if (type == "Bar" || type == "T" || type == "FB") {
        moduli_ksp = moduli_actual / 1.0;
    } else if (type == "HP") {
        moduli_ksp = moduli_actual / 1.03;
    } else if (type == "L") {
        moduli_ksp = moduli_actual / 1.15;
    } else {
        moduli_ksp = 0.0;
    }

    // Use existing w or calculate new one
    double final_w;
    if (w == 0.0) {
        final_w = moduli_ksp;
    } else {
        final_w = w;
    }
    
    qDebug() << "counting_formula_edit" << final_area << final_e << final_w << final_upperI;
    
    // Round all results to 2 decimal places for consistency
    final_area = std::round(final_area * 100.0) / 100.0;
    final_e = std::round(final_e * 100.0) / 100.0;
    final_w = std::round(final_w * 100.0) / 100.0;
    final_upperI = std::round(final_upperI * 100.0) / 100.0;
    
    qDebug() << "counting_formula_edit (rounded)" << final_area << final_e << final_w << final_upperI;
    
    QVariantList result;
    result << final_area << final_e << final_w << final_upperI;
    return result;
}

// Bracket calculation functions
QVariantList StructureProfileTableController::profileTableCountingFormulaBrackets(double tw, double W, double rehProfile, double rehBracket)
{
    // Convert inputs to double to match Python behavior
    double Reh_profile = static_cast<double>(rehProfile);
    double Reh_bracket = static_cast<double>(rehBracket);
    double W_val = static_cast<double>(W);
    double tw_val = static_cast<double>(tw);
    
    // Coefficients
    double k1 = 235.0 / Reh_profile;
    double k2 = 235.0 / Reh_bracket;
    double c = 1.2;
    double ct = 1.0;
    
    double tmax = tw_val;
    double bmin = 50.0;
    double bmax = 90.0;

    // t bracket, tb=tbf
    double tnet = c * pow(W_val / (double)k1, 1.0/3.0);
    
    // tk = Piecewise((1.5,tnet<10),((Min(3,0.1*tnet/sqrt(k1))),True))
    double tk;
    if (tnet < 10.0) {
        tk = 1.5;
    } else {
        tk = std::min(3.0, 0.1 * tnet / sqrt(k1));
    }
    
    double tmin = 5.0 + tk;
    double a = tnet + tk;
    double tfull = ceil(a * 10.0) / 10.0;

    // Output t yang diambil - t = Piecewise((tmin, tfull < tmin), (tmax, tfull > tmax), (tfull, True))
    double t;
    if (tfull < tmin) {
        t = tmin;
    } else if (tfull > tmax) {
        t = tmax;
    } else {
        t = tfull;
    }
    
    double tb = t;
    double tbf = t;

    // l bracket
    double lreq = 46.2 * pow(W_val / (double)k1, 1.0/3.0) * sqrt(k2) * ct;

    // Output l bracket yang diambil - l = ceiling(lreq)
    double l = ceil(lreq);

    // bf bracket
    double breq = 40.0 + W_val / 30.0;

    // Output bf yang diambil - bf = Piecewise((bmin,breq<bmin),(bmax,breq>bmax),(breq,True))
    double bf;
    if (breq < bmin) {
        bf = bmin;
    } else if (breq > bmax) {
        bf = bmax;
    } else {
        bf = breq;
    }
    
    // Convert to float to match Python behavior
    double l_result = static_cast<double>(l);
    double tb_result = static_cast<double>(tb);
    double bf_result = static_cast<double>(bf);
    double tbf_result = static_cast<double>(tbf);
    
    qDebug() << "profile_table_counting_formula_brackets" << l_result << tb_result << bf_result << tbf_result;
    
    // Round all results to 2 decimal places for consistency
    l_result = std::round(l_result * 100.0) / 100.0;
    tb_result = std::round(tb_result * 100.0) / 100.0;
    bf_result = std::round(bf_result * 100.0) / 100.0;
    tbf_result = std::round(tbf_result * 100.0) / 100.0;
    
    qDebug() << "profile_table_counting_formula_brackets (rounded)" << l_result << tb_result << bf_result << tbf_result;
    
    QVariantList result;
    result << l_result << tb_result << bf_result << tbf_result;
    return result;
}

QVariantList StructureProfileTableController::profileTableCountingFormulaBracketsEdit(double tw, double W, double rehProfile, double rehBracket,
                                                                                     double l, double tb, double bf, double tbf)
{
    // Convert inputs to double to match Python behavior
    double Reh_profile = static_cast<double>(rehProfile);
    double Reh_bracket = static_cast<double>(rehBracket);
    double W_val = static_cast<double>(W);
    double tw_val = static_cast<double>(tw);
    
    // Coefficients
    double k1 = 235.0 / Reh_profile;
    double k2 = 235.0 / Reh_bracket;
    double c = 1.2;
    double ct = 1.0;
    
    double tmax = tw_val;
    double bmin = 50.0;
    double bmax = 90.0;

    // t bracket, tb=tbf
    double tnet = c * pow(W_val / k1, 1.0/3.0);
    
    // tk = Piecewise((1.5,tnet<10),((Min(3,0.1*tnet/sqrt(k1))),True))
    double tk;
    if (tnet < 10.0) {
        tk = 1.5;
    } else {
        tk = std::min(3.0, 0.1 * tnet / sqrt(k1));
    }
    
    double tmin = 5.0 + tk;
    double a = tnet + tk;
    double tfull = ceil(a * 10.0) / 10.0;

    // Output t yang diambil - t = Piecewise((tmin, tfull < tmin), (tmax, tfull > tmax), (tfull, True))
    double t;
    if (tfull < tmin) {
        t = tmin;
    } else if (tfull > tmax) {
        t = tmax;
    } else {
        t = tfull;
    }
    
    // Use existing tb or calculated value
    double final_tb;
    if (tb == 0.0) {
        final_tb = t;
    } else {
        final_tb = tb;
    }
    
    // Use existing tbf or calculated value
    double final_tbf;
    if (tbf == 0.0) {
        final_tbf = t;
    } else {
        final_tbf = tbf;
    }

    // l bracket
    double lreq = 46.2 * pow(W_val / k1, 1.0/3.0) * sqrt(k2) * ct;

    // Output l bracket yang diambil - l = ceiling(lreq)
    double final_l;
    if (l == 0.0) {
        final_l = ceil(lreq);
    } else {
        final_l = l;
    }

    // bf bracket
    double breq = 40.0 + W_val / 30.0;

    // Output bf yang diambil - bf = Piecewise((bmin,breq<bmin),(bmax,breq>bmax),(breq,True))
    double final_bf;
    if (bf == 0.0) {
        if (breq < bmin) {
            final_bf = bmin;
        } else if (breq > bmax) {
            final_bf = bmax;
        } else {
            final_bf = breq;
        }
    } else {
        final_bf = bf;
    }
    
    qDebug() << "profile_table_counting_formula_brackets_edit" << final_l << final_tb << final_bf << final_tbf;
    
    // Round all results to 2 decimal places for consistency
    final_l = std::round(final_l * 100.0) / 100.0;
    final_tb = std::round(final_tb * 100.0) / 100.0;
    final_bf = std::round(final_bf * 100.0) / 100.0;
    final_tbf = std::round(final_tbf * 100.0) / 100.0;
    
    qDebug() << "profile_table_counting_formula_brackets_edit (rounded)" << final_l << final_tb << final_bf << final_tbf;
    
    QVariantList result;
    result << final_l << final_tb << final_bf << final_tbf;
    return result;
}

// Data management functions implementation
QVariantList StructureProfileTableController::getProfilesData() const
{
    return m_profiles;
}

QVariantList StructureProfileTableController::getAllProfilesData()
{
    qDebug() << "StructureProfileTableController::getAllProfilesData() called";
    
    if (!m_model) {
        qDebug() << "StructureProfileTableController::getAllProfilesData() - Model not initialized";
        setLastError("Model not initialized");
        return QVariantList();
    }

    qDebug() << "StructureProfileTableController::getAllProfilesData() - Model is available, calling loadProfilesFromModel";
    
    // Use the existing method that properly updates the internal state
    loadProfilesFromModel();
    
    qDebug() << "StructureProfileTableController::getAllProfilesData() - Returning profiles, count:" << m_profiles.size();
    return m_profiles;
}

bool StructureProfileTableController::addNewProfile(const QString& type, const QString& name, double hw, double tw, 
                                                   double bfProfiles, double tf, double area, double e, double w, 
                                                   double upperI, double lowerL, double tb, double bfBrackets, double tbf)
{
    return createProfile(type, name, hw, tw, bfProfiles, tf, area, e, w, upperI, lowerL, tb, bfBrackets, tbf);
}

bool StructureProfileTableController::updateProfileData(int id, const QString& type, const QString& name, double hw, double tw,
                                                       double bfProfiles, double tf, double area, double e, double w,
                                                       double upperI, double lowerL, double tb, double bfBrackets, double tbf)
{
    return updateProfile(id, type, name, hw, tw, bfProfiles, tf, area, e, w, upperI, lowerL, tb, bfBrackets, tbf);
}

bool StructureProfileTableController::removeProfileData(int id)
{
    return deleteProfile(id);
}

QString StructureProfileTableController::getLastError() const
{
    return lastError();
}
