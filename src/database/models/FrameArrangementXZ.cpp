#include "FrameArrangementXZ.h"
#include "../DatabaseShipConnection.h"
#include <QSqlQuery>
#include <QSqlError>
#include <QVariant>
#include <QDebug>

FrameArrangementXZ::FrameArrangementXZ(QObject *parent)
    : QAbstractListModel(parent)
{
}

int FrameArrangementXZ::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return m_frameData.size();
}

QVariant FrameArrangementXZ::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_frameData.size())
        return QVariant();

    const FrameData &frame = m_frameData.at(index.row());

    switch (role) {
    case IdRole:
        return frame.id;
    case FrameNameRole:
        return frame.frameName;
    case FrameNumberRole:
        return frame.frameNumber;
    case FrameSpacingRole:
        return frame.frameSpacing;
    case MlRole:
        return frame.ml;
    case XpCoorRole:
        return frame.xpCoor;
    case XlRole:
        return frame.xl;
    case XllCoorRole:
        return frame.xllCoor;
    case XllLllRole:
        return frame.xllLll;
    default:
        return QVariant();
    }
}

QHash<int, QByteArray> FrameArrangementXZ::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[IdRole] = "id";
    roles[FrameNameRole] = "frameName";
    roles[FrameNumberRole] = "frameNumber";
    roles[FrameSpacingRole] = "frameSpacing";
    roles[MlRole] = "ml";
    roles[XpCoorRole] = "xpCoor";
    roles[XlRole] = "xl";
    roles[XllCoorRole] = "xllCoor";
    roles[XllLllRole] = "xllLll";
    return roles;
}

bool FrameArrangementXZ::createTable()
{
    QSqlDatabase db = getDatabase();
    if (!db.isValid()) {
        m_lastError = "Ship database connection is not valid";
        qCritical() << "FrameArrangementXZ::createTable() -" << m_lastError;
        emit errorOccurred(m_lastError);
        return false;
    }

    QSqlQuery query(db);
    QString createTableSQL = R"(
        CREATE TABLE IF NOT EXISTS structure_seagoing_ship_section0_frame_arrangement_xz (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            frame_name TEXT NOT NULL,
            frame_number INTEGER NOT NULL,
            frame_spacing REAL NOT NULL,
            ml REAL NOT NULL,
            xp_coor REAL NOT NULL,
            x_l REAL NOT NULL,
            xll_coor REAL NOT NULL,
            xll_lll REAL NOT NULL
        )
    )";

    if (!query.exec(createTableSQL)) {
        m_lastError = QString("Failed to create frame arrangement XZ table: %1").arg(query.lastError().text());
        qCritical() << "FrameArrangementXZ::createTable() -" << m_lastError;
        emit errorOccurred(m_lastError);
        return false;
    }

    qDebug() << "FrameArrangementXZ::createTable() - Table created successfully";
    return true;
}

bool FrameArrangementXZ::loadData()
{
    QSqlDatabase db = getDatabase();
    if (!db.isValid()) {
        m_lastError = "Ship database connection is not valid";
        qCritical() << "FrameArrangementXZ::loadData() -" << m_lastError;
        emit errorOccurred(m_lastError);
        return false;
    }

    QSqlQuery query(db);
    query.prepare("SELECT id, frame_name, frame_number, frame_spacing, ml, xp_coor, x_l, xll_coor, xll_lll FROM structure_seagoing_ship_section0_frame_arrangement_xz ORDER BY id");

    if (!query.exec()) {
        m_lastError = QString("Failed to load frame arrangement XZ data: %1").arg(query.lastError().text());
        qCritical() << "FrameArrangementXZ::loadData() -" << m_lastError;
        emit errorOccurred(m_lastError);
        return false;
    }

    beginResetModel();
    clearData();

    while (query.next()) {
        FrameData frame;
        frame.id = query.value(0).toInt();
        frame.frameName = query.value(1).toString();
        frame.frameNumber = query.value(2).toInt();
        frame.frameSpacing = query.value(3).toDouble();
        frame.ml = query.value(4).toDouble();
        frame.xpCoor = query.value(5).toDouble();
        frame.xl = query.value(6).toDouble();
        frame.xllCoor = query.value(7).toDouble();
        frame.xllLll = query.value(8).toDouble();

        m_frameData.append(frame);
    }

    endResetModel();
    emit dataChanged();

    qDebug() << "FrameArrangementXZ::loadData() - Loaded" << m_frameData.size() << "frame records";
    return true;
}

bool FrameArrangementXZ::insertFrame(const QString &frameName, int frameNumber, double frameSpacing,
                                    double ml, double xpCoor, double xl, double xllCoor, double xllLll)
{
    QSqlDatabase db = getDatabase();
    if (!db.isValid()) {
        m_lastError = "Ship database connection is not valid";
        qCritical() << "FrameArrangementXZ::insertFrame() -" << m_lastError;
        emit errorOccurred(m_lastError);
        return false;
    }

    QSqlQuery query(db);
    query.prepare("INSERT INTO structure_seagoing_ship_section0_frame_arrangement_xz "
                  "(frame_name, frame_number, frame_spacing, ml, xp_coor, x_l, xll_coor, xll_lll) "
                  "VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
    
    query.addBindValue(frameName);
    query.addBindValue(frameNumber);
    query.addBindValue(frameSpacing);
    query.addBindValue(ml);
    query.addBindValue(xpCoor);
    query.addBindValue(xl);
    query.addBindValue(xllCoor);
    query.addBindValue(xllLll);

    if (!query.exec()) {
        m_lastError = QString("Failed to insert frame: %1").arg(query.lastError().text());
        qCritical() << "FrameArrangementXZ::insertFrame() -" << m_lastError;
        emit errorOccurred(m_lastError);
        return false;
    }

    qDebug() << "FrameArrangementXZ::insertFrame() - Frame inserted successfully";
    loadData(); // Reload data to update the model
    return true;
}

bool FrameArrangementXZ::updateFrame(int id, const QString &frameName, int frameNumber, double frameSpacing,
                                    double ml, double xpCoor, double xl, double xllCoor, double xllLll)
{
    QSqlDatabase db = getDatabase();
    if (!db.isValid()) {
        m_lastError = "Ship database connection is not valid";
        qCritical() << "FrameArrangementXZ::updateFrame() -" << m_lastError;
        emit errorOccurred(m_lastError);
        return false;
    }

    QSqlQuery query(db);
    query.prepare("UPDATE structure_seagoing_ship_section0_frame_arrangement_xz "
                  "SET frame_name=?, frame_number=?, frame_spacing=?, ml=?, xp_coor=?, x_l=?, xll_coor=?, xll_lll=? "
                  "WHERE id=?");
    
    query.addBindValue(frameName);
    query.addBindValue(frameNumber);
    query.addBindValue(frameSpacing);
    query.addBindValue(ml);
    query.addBindValue(xpCoor);
    query.addBindValue(xl);
    query.addBindValue(xllCoor);
    query.addBindValue(xllLll);
    query.addBindValue(id);

    if (!query.exec()) {
        m_lastError = QString("Failed to update frame: %1").arg(query.lastError().text());
        qCritical() << "FrameArrangementXZ::updateFrame() -" << m_lastError;
        emit errorOccurred(m_lastError);
        return false;
    }

    qDebug() << "FrameArrangementXZ::updateFrame() - Frame updated successfully";
    loadData(); // Reload data to update the model
    return true;
}

bool FrameArrangementXZ::updateFrameMl(int id, double ml)
{
    QSqlDatabase db = getDatabase();
    if (!db.isValid()) {
        m_lastError = "Ship database connection is not valid";
        qCritical() << "FrameArrangementXZ::updateFrameMl() -" << m_lastError;
        emit errorOccurred(m_lastError);
        return false;
    }

    QSqlQuery query(db);
    query.prepare("UPDATE structure_seagoing_ship_section0_frame_arrangement_xz SET ml=? WHERE id=?");
    query.addBindValue(ml);
    query.addBindValue(id);

    if (!query.exec()) {
        m_lastError = QString("Failed to update frame ML: %1").arg(query.lastError().text());
        qCritical() << "FrameArrangementXZ::updateFrameMl() -" << m_lastError;
        emit errorOccurred(m_lastError);
        return false;
    }

    qDebug() << "FrameArrangementXZ::updateFrameMl() - Frame ML updated successfully";
    loadData(); // Reload data to update the model
    return true;
}

bool FrameArrangementXZ::deleteFrame(int id)
{
    QSqlDatabase db = getDatabase();
    if (!db.isValid()) {
        m_lastError = "Ship database connection is not valid";
        qCritical() << "FrameArrangementXZ::deleteFrame() -" << m_lastError;
        emit errorOccurred(m_lastError);
        return false;
    }

    QSqlQuery query(db);
    query.prepare("DELETE FROM structure_seagoing_ship_section0_frame_arrangement_xz WHERE id=?");
    query.addBindValue(id);

    if (!query.exec()) {
        m_lastError = QString("Failed to delete frame: %1").arg(query.lastError().text());
        qCritical() << "FrameArrangementXZ::deleteFrame() -" << m_lastError;
        emit errorOccurred(m_lastError);
        return false;
    }

    qDebug() << "FrameArrangementXZ::deleteFrame() - Frame deleted successfully";
    loadData(); // Reload data to update the model
    return true;
}

int FrameArrangementXZ::getLastId()
{
    QSqlDatabase db = getDatabase();
    if (!db.isValid()) {
        m_lastError = "Ship database connection is not valid";
        qCritical() << "FrameArrangementXZ::getLastId() -" << m_lastError;
        emit errorOccurred(m_lastError);
        return -1;
    }

    QSqlQuery query(db);
    query.prepare("SELECT id FROM structure_seagoing_ship_section0_frame_arrangement_xz ORDER BY id DESC LIMIT 1");

    if (!query.exec()) {
        m_lastError = QString("Failed to get last ID: %1").arg(query.lastError().text());
        qCritical() << "FrameArrangementXZ::getLastId() -" << m_lastError;
        emit errorOccurred(m_lastError);
        return -1;
    }

    if (query.next()) {
        return query.value(0).toInt();
    }

    return -1; // No records found
}

QVariantMap FrameArrangementXZ::getFrameById(int id)
{
    QSqlDatabase db = getDatabase();
    QVariantMap result;
    
    if (!db.isValid()) {
        m_lastError = "Ship database connection is not valid";
        qCritical() << "FrameArrangementXZ::getFrameById() -" << m_lastError;
        emit errorOccurred(m_lastError);
        return result;
    }

    QSqlQuery query(db);
    query.prepare("SELECT id, frame_name, frame_number, frame_spacing, ml, xp_coor, x_l, xll_coor, xll_lll "
                  "FROM structure_seagoing_ship_section0_frame_arrangement_xz WHERE id=?");
    query.addBindValue(id);

    if (!query.exec()) {
        m_lastError = QString("Failed to get frame by ID: %1").arg(query.lastError().text());
        qCritical() << "FrameArrangementXZ::getFrameById() -" << m_lastError;
        emit errorOccurred(m_lastError);
        return result;
    }

    if (query.next()) {
        result["id"] = query.value(0).toInt();
        result["frameName"] = query.value(1).toString();
        result["frameNumber"] = query.value(2).toInt();
        result["frameSpacing"] = query.value(3).toDouble();
        result["ml"] = query.value(4).toDouble();
        result["xpCoor"] = query.value(5).toDouble();
        result["xl"] = query.value(6).toDouble();
        result["xllCoor"] = query.value(7).toDouble();
        result["xllLll"] = query.value(8).toDouble();
    }

    return result;
}

bool FrameArrangementXZ::resetDatabase()
{
    QSqlDatabase db = getDatabase();
    if (!db.isValid()) {
        m_lastError = "Ship database connection is not valid";
        qCritical() << "FrameArrangementXZ::resetDatabase() -" << m_lastError;
        emit errorOccurred(m_lastError);
        return false;
    }

    QSqlQuery query(db);
    query.prepare("DELETE FROM structure_seagoing_ship_section0_frame_arrangement_xz");

    if (!query.exec()) {
        m_lastError = QString("Failed to reset database: %1").arg(query.lastError().text());
        qCritical() << "FrameArrangementXZ::resetDatabase() -" << m_lastError;
        emit errorOccurred(m_lastError);
        return false;
    }

    qDebug() << "FrameArrangementXZ::resetDatabase() - Database reset successfully";
    loadData(); // Reload data to update the model
    return true;
}

int FrameArrangementXZ::getRowCount() const
{
    return m_frameData.size();
}

QVariantMap FrameArrangementXZ::getFrameAtIndex(int index) const
{
    QVariantMap result;
    
    if (index >= 0 && index < m_frameData.size()) {
        const FrameData &frame = m_frameData.at(index);
        result["id"] = frame.id;
        result["frameName"] = frame.frameName;
        result["frameNumber"] = frame.frameNumber;
        result["frameSpacing"] = frame.frameSpacing;
        result["ml"] = frame.ml;
        result["xpCoor"] = frame.xpCoor;
        result["xl"] = frame.xl;
        result["xllCoor"] = frame.xllCoor;
        result["xllLll"] = frame.xllLll;
    }
    
    return result;
}

void FrameArrangementXZ::clearData()
{
    m_frameData.clear();
}

QSqlDatabase FrameArrangementXZ::getDatabase() const
{
    return DatabaseShipConnection::instance().getDatabase();
}