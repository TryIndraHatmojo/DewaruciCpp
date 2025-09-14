#include "FrameArrangementYZ.h"
#include "../DatabaseShipConnection.h"
#include <QSqlQuery>
#include <QSqlError>
#include <QVariant>
#include <QDebug>

FrameArrangementYZ::FrameArrangementYZ(QObject *parent)
    : QAbstractListModel(parent)
{
}

int FrameArrangementYZ::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return m_frameYZData.size();
}

QVariant FrameArrangementYZ::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_frameYZData.size())
        return QVariant();

    const FrameYZData &frame = m_frameYZData.at(index.row());

    switch (role) {
    case IdRole:
        return frame.id;
    case NameRole:
        return frame.name;
    case NoRole:
        return frame.no;
    case SpacingRole:
        return frame.spacing;
    case YRole:
        return frame.y;
    case ZRole:
        return frame.z;
    case FrameNoRole:
        return frame.frameNo;
    case FaRole:
        return frame.fa;
    case SymRole:
        return frame.sym;
    case CreatedAtRole:
        return frame.createdAt;
    case UpdatedAtRole:
        return frame.updatedAt;
    default:
        return QVariant();
    }
}

QHash<int, QByteArray> FrameArrangementYZ::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[IdRole] = "id";
    roles[NameRole] = "name";
    roles[NoRole] = "no";
    roles[SpacingRole] = "spacing";
    roles[YRole] = "y";
    roles[ZRole] = "z";
    roles[FrameNoRole] = "frameNo";
    roles[FaRole] = "fa";
    roles[SymRole] = "sym";
    roles[CreatedAtRole] = "createdAt";
    roles[UpdatedAtRole] = "updatedAt";
    return roles;
}

bool FrameArrangementYZ::createTable()
{
    QSqlDatabase db = getDatabase();
    if (!db.isValid()) {
        m_lastError = "Ship database connection is not valid";
        qCritical() << "FrameArrangementYZ::createTable() -" << m_lastError;
        emit errorOccurred(m_lastError);
        return false;
    }

    QSqlQuery query(db);
    QString createTableSQL = R"(
        CREATE TABLE IF NOT EXISTS structure_seagoing_ship_section0_frame_arrangement_yz (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            no INTEGER,
            spacing REAL,
            y REAL,
            z REAL,
            frame_no INTEGER,
            fa TEXT,
            sym TEXT,
            created_at INTEGER DEFAULT (strftime('%s','now') * 1000),
            updated_at INTEGER DEFAULT (strftime('%s','now') * 1000)
        )
    )";

    if (!query.exec(createTableSQL)) {
        m_lastError = QString("Failed to create frame arrangement YZ table: %1").arg(query.lastError().text());
        qCritical() << "FrameArrangementYZ::createTable() -" << m_lastError;
        emit errorOccurred(m_lastError);
        return false;
    }

    qDebug() << "FrameArrangementYZ::createTable() - Table created successfully";
    return true;
}

bool FrameArrangementYZ::loadData()
{
    QSqlDatabase db = getDatabase();
    if (!db.isValid()) {
        m_lastError = "Ship database connection is not valid";
        qCritical() << "FrameArrangementYZ::loadData() -" << m_lastError;
        emit errorOccurred(m_lastError);
        return false;
    }

    QSqlQuery query(db);
    query.prepare("SELECT id, name, no, spacing, y, z, frame_no, fa, sym, created_at, updated_at FROM structure_seagoing_ship_section0_frame_arrangement_yz ORDER BY id");

    if (!query.exec()) {
        m_lastError = QString("Failed to load frame arrangement YZ data: %1").arg(query.lastError().text());
        qCritical() << "FrameArrangementYZ::loadData() -" << m_lastError;
        emit errorOccurred(m_lastError);
        return false;
    }

    beginResetModel();
    clearData();

    while (query.next()) {
        FrameYZData frame;
        frame.id = query.value(0).toInt();
        frame.name = query.value(1).toString();
        frame.no = query.value(2).toInt();
        frame.spacing = query.value(3).toDouble();
        // Preserve original variant types for y/z so empty string can be shown
        frame.y = query.value(4);
        frame.z = query.value(5);
        frame.frameNo = query.value(6).toInt();
    frame.fa = query.value(7).toString();
    frame.sym = query.value(8).toString();
    frame.createdAt = query.value(9).toLongLong();
    frame.updatedAt = query.value(10).toLongLong();

        m_frameYZData.append(frame);
    }

    endResetModel();
    emit dataChanged();

    qDebug() << "FrameArrangementYZ::loadData() - Loaded" << m_frameYZData.size() << "frame YZ records";
    return true;
}

bool FrameArrangementYZ::loadDataByFrameNo(int frameNumber)
{
    QSqlDatabase db = getDatabase();
    if (!db.isValid()) {
        m_lastError = "Ship database connection is not valid";
        qCritical() << "FrameArrangementYZ::loadDataByFrameNo() -" << m_lastError;
        emit errorOccurred(m_lastError);
        return false;
    }

    QSqlQuery query(db);
    query.prepare("SELECT id, name, no, spacing, y, z, frame_no, fa, sym, created_at, updated_at FROM structure_seagoing_ship_section0_frame_arrangement_yz WHERE frame_no = ? ORDER BY id");
    query.addBindValue(frameNumber);

    if (!query.exec()) {
        m_lastError = QString("Failed to load frame arrangement YZ data by frame number: %1").arg(query.lastError().text());
        qCritical() << "FrameArrangementYZ::loadDataByFrameNo() -" << m_lastError;
        emit errorOccurred(m_lastError);
        return false;
    }

    beginResetModel();
    clearData();

    while (query.next()) {
        FrameYZData frame;
        frame.id = query.value(0).toInt();
        frame.name = query.value(1).toString();
        frame.no = query.value(2).toInt();
        frame.spacing = query.value(3).toDouble();
        frame.y = query.value(4);
        frame.z = query.value(5);
        frame.frameNo = query.value(6).toInt();
    frame.fa = query.value(7).toString();
    frame.sym = query.value(8).toString();
    frame.createdAt = query.value(9).toLongLong();
    frame.updatedAt = query.value(10).toLongLong();

        m_frameYZData.append(frame);
    }

    endResetModel();
    emit dataChanged();

    qDebug() << "FrameArrangementYZ::loadDataByFrameNo() - Loaded" << m_frameYZData.size() << "frame YZ records for frame number" << frameNumber;
    return true;
}

int FrameArrangementYZ::insertFrame(const QString &name, int no, double spacing,
                                   const QVariant &y, const QVariant &z, int frameNo, const QString &fa, const QString &sym)
{
    QSqlDatabase db = getDatabase();
    if (!db.isValid()) {
        m_lastError = "Ship database connection is not valid";
        qCritical() << "FrameArrangementYZ::insertFrame() -" << m_lastError;
        emit errorOccurred(m_lastError);
        return -1;
    }

    QSqlQuery query(db);
    query.prepare("INSERT INTO structure_seagoing_ship_section0_frame_arrangement_yz "
                  "(name, no, spacing, y, z, frame_no, fa, sym) "
                  "VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
    
    query.addBindValue(name);
    query.addBindValue(no);
    query.addBindValue(spacing);
    // Bind y/z as provided: empty string stays empty, number as double
    query.addBindValue(y);
    query.addBindValue(z);
    query.addBindValue(frameNo);
    query.addBindValue(fa);
    query.addBindValue(sym);

    if (!query.exec()) {
        m_lastError = QString("Failed to insert frame YZ: %1").arg(query.lastError().text());
        qCritical() << "FrameArrangementYZ::insertFrame() -" << m_lastError;
        emit errorOccurred(m_lastError);
        return -1;
    }

    int insertedId = query.lastInsertId().toInt();
    qDebug() << "FrameArrangementYZ::insertFrame() - Frame YZ inserted successfully with ID:" << insertedId;
    loadData(); // Reload data to update the model
    return insertedId;
}

bool FrameArrangementYZ::updateFrame(int id, const QString &name, int no, double spacing,
                                    const QVariant &y, const QVariant &z, int frameNo, const QString &fa, const QString &sym)
{
    QSqlDatabase db = getDatabase();
    if (!db.isValid()) {
        m_lastError = "Ship database connection is not valid";
        qCritical() << "FrameArrangementYZ::updateFrame() -" << m_lastError;
        emit errorOccurred(m_lastError);
        return false;
    }

    QSqlQuery query(db);
    query.prepare("UPDATE structure_seagoing_ship_section0_frame_arrangement_yz "
                  "SET name=?, no=?, spacing=?, y=?, z=?, frame_no=?, fa=?, sym=?, updated_at=(strftime('%s','now')*1000) "
                  "WHERE id=?");
    
    query.addBindValue(name);
    query.addBindValue(no);
    query.addBindValue(spacing);
    query.addBindValue(y);
    query.addBindValue(z);
    query.addBindValue(frameNo);
    query.addBindValue(fa);
    query.addBindValue(sym);
    query.addBindValue(id);

    if (!query.exec()) {
        m_lastError = QString("Failed to update frame YZ: %1").arg(query.lastError().text());
        qCritical() << "FrameArrangementYZ::updateFrame() -" << m_lastError;
        emit errorOccurred(m_lastError);
        return false;
    }

    qDebug() << "FrameArrangementYZ::updateFrame() - Frame YZ updated successfully";
    loadData(); // Reload data to update the model
    return true;
}

bool FrameArrangementYZ::updateFrameFa(int id, const QString &fa)
{
    QSqlDatabase db = getDatabase();
    if (!db.isValid()) {
        m_lastError = "Ship database connection is not valid";
        qCritical() << "FrameArrangementYZ::updateFrameFa() -" << m_lastError;
        emit errorOccurred(m_lastError);
        return false;
    }

    QSqlQuery query(db);
    query.prepare("UPDATE structure_seagoing_ship_section0_frame_arrangement_yz SET fa=?, updated_at=(strftime('%s','now')*1000) WHERE id=?");
    query.addBindValue(fa);
    query.addBindValue(id);

    if (!query.exec()) {
        m_lastError = QString("Failed to update frame YZ FA: %1").arg(query.lastError().text());
        qCritical() << "FrameArrangementYZ::updateFrameFa() -" << m_lastError;
        emit errorOccurred(m_lastError);
        return false;
    }

    qDebug() << "FrameArrangementYZ::updateFrameFa() - Frame YZ FA updated successfully";
    loadData(); // Reload data to update the model
    return true;
}

bool FrameArrangementYZ::updateFrameSym(int id, const QString &sym)
{
    QSqlDatabase db = getDatabase();
    if (!db.isValid()) {
        m_lastError = "Ship database connection is not valid";
        qCritical() << "FrameArrangementYZ::updateFrameSym() -" << m_lastError;
        emit errorOccurred(m_lastError);
        return false;
    }

    QSqlQuery query(db);
    query.prepare("UPDATE structure_seagoing_ship_section0_frame_arrangement_yz SET sym=?, updated_at=(strftime('%s','now')*1000) WHERE id=?");
    query.addBindValue(sym);
    query.addBindValue(id);

    if (!query.exec()) {
        m_lastError = QString("Failed to update frame YZ Sym: %1").arg(query.lastError().text());
        qCritical() << "FrameArrangementYZ::updateFrameSym() -" << m_lastError;
        emit errorOccurred(m_lastError);
        return false;
    }

    qDebug() << "FrameArrangementYZ::updateFrameSym() - Frame YZ Sym updated successfully";
    loadData(); // Reload data to update the model
    return true;
}

bool FrameArrangementYZ::deleteFrame(int id)
{
    QSqlDatabase db = getDatabase();
    if (!db.isValid()) {
        m_lastError = "Ship database connection is not valid";
        qCritical() << "FrameArrangementYZ::deleteFrame() -" << m_lastError;
        emit errorOccurred(m_lastError);
        return false;
    }

    QSqlQuery query(db);
    query.prepare("DELETE FROM structure_seagoing_ship_section0_frame_arrangement_yz WHERE id=?");
    query.addBindValue(id);

    if (!query.exec()) {
        m_lastError = QString("Failed to delete frame YZ: %1").arg(query.lastError().text());
        qCritical() << "FrameArrangementYZ::deleteFrame() -" << m_lastError;
        emit errorOccurred(m_lastError);
        return false;
    }

    qDebug() << "FrameArrangementYZ::deleteFrame() - Frame YZ deleted successfully";
    loadData(); // Reload data to update the model
    return true;
}

bool FrameArrangementYZ::deleteFramesByFrameNumber(int frameNumber)
{
    QSqlDatabase db = getDatabase();
    if (!db.isValid()) {
        m_lastError = "Ship database connection is not valid";
        qCritical() << "FrameArrangementYZ::deleteFramesByFrameNumber() -" << m_lastError;
        emit errorOccurred(m_lastError);
        return false;
    }

    QSqlQuery query(db);
    query.prepare("DELETE FROM structure_seagoing_ship_section0_frame_arrangement_yz WHERE frame_no=?");
    query.addBindValue(frameNumber);

    if (!query.exec()) {
        m_lastError = QString("Failed to delete frames YZ by frame number: %1").arg(query.lastError().text());
        qCritical() << "FrameArrangementYZ::deleteFramesByFrameNumber() -" << m_lastError;
        emit errorOccurred(m_lastError);
        return false;
    }

    qDebug() << "FrameArrangementYZ::deleteFramesByFrameNumber() - Frames YZ deleted successfully for frame number" << frameNumber;
    loadData(); // Reload data to update the model
    return true;
}

QVariantMap FrameArrangementYZ::getFrameById(int id)
{
    QSqlDatabase db = getDatabase();
    QVariantMap result;
    
    if (!db.isValid()) {
        m_lastError = "Ship database connection is not valid";
        qCritical() << "FrameArrangementYZ::getFrameById() -" << m_lastError;
        emit errorOccurred(m_lastError);
        return result;
    }

    QSqlQuery query(db);
    query.prepare("SELECT id, name, no, spacing, y, z, frame_no, fa, sym, created_at, updated_at "
                  "FROM structure_seagoing_ship_section0_frame_arrangement_yz WHERE id=?");
    query.addBindValue(id);

    if (!query.exec()) {
        m_lastError = QString("Failed to get frame YZ by ID: %1").arg(query.lastError().text());
        qCritical() << "FrameArrangementYZ::getFrameById() -" << m_lastError;
        emit errorOccurred(m_lastError);
        return result;
    }

    if (query.next()) {
        result["id"] = query.value(0).toInt();
        result["name"] = query.value(1).toString();
        result["no"] = query.value(2).toInt();
        result["spacing"] = query.value(3).toDouble();
        // Keep original variant for y/z
        result["y"] = query.value(4);
        result["z"] = query.value(5);
    result["frameNo"] = query.value(6).toInt();
    result["fa"] = query.value(7).toString();
    result["sym"] = query.value(8).toString();
    result["createdAt"] = query.value(9).toLongLong();
    result["updatedAt"] = query.value(10).toLongLong();
    }

    return result;
}

QVariantList FrameArrangementYZ::getFramesByName(const QString &name)
{
    QSqlDatabase db = getDatabase();
    QVariantList result;
    
    if (!db.isValid()) {
        m_lastError = "Ship database connection is not valid";
        qCritical() << "FrameArrangementYZ::getFramesByName() -" << m_lastError;
        emit errorOccurred(m_lastError);
        return result;
    }

    QSqlQuery query(db);
    query.prepare("SELECT id, name, no, spacing, y, z, frame_no, fa, sym, created_at, updated_at "
                  "FROM structure_seagoing_ship_section0_frame_arrangement_yz WHERE name=?");
    query.addBindValue(name);

    if (!query.exec()) {
        m_lastError = QString("Failed to get frames YZ by name: %1").arg(query.lastError().text());
        qCritical() << "FrameArrangementYZ::getFramesByName() -" << m_lastError;
        emit errorOccurred(m_lastError);
        return result;
    }

    while (query.next()) {
        QVariantMap frame;
        frame["id"] = query.value(0).toInt();
        frame["name"] = query.value(1).toString();
        frame["no"] = query.value(2).toInt();
    frame["spacing"] = query.value(3).toDouble();
    frame["y"] = query.value(4);
    frame["z"] = query.value(5);
    frame["frameNo"] = query.value(6).toInt();
    frame["fa"] = query.value(7).toString();
    frame["sym"] = query.value(8).toString();
    frame["createdAt"] = query.value(9).toLongLong();
    frame["updatedAt"] = query.value(10).toLongLong();
        result.append(frame);
    }

    return result;
}

QVariantList FrameArrangementYZ::getFramesByFrameNo(int frameNumber)
{
    QSqlDatabase db = getDatabase();
    QVariantList result;
    
    if (!db.isValid()) {
        m_lastError = "Ship database connection is not valid";
        qCritical() << "FrameArrangementYZ::getFramesByFrameNo() -" << m_lastError;
        emit errorOccurred(m_lastError);
        return result;
    }

    QSqlQuery query(db);
    query.prepare("SELECT id, name, no, spacing, y, z, frame_no, fa, sym, created_at, updated_at "
                  "FROM structure_seagoing_ship_section0_frame_arrangement_yz WHERE frame_no=?");
    query.addBindValue(frameNumber);

    if (!query.exec()) {
        m_lastError = QString("Failed to get frames YZ by frame number: %1").arg(query.lastError().text());
        qCritical() << "FrameArrangementYZ::getFramesByFrameNo() -" << m_lastError;
        emit errorOccurred(m_lastError);
        return result;
    }

    while (query.next()) {
        QVariantMap frame;
        frame["id"] = query.value(0).toInt();
        frame["name"] = query.value(1).toString();
        frame["no"] = query.value(2).toInt();
    frame["spacing"] = query.value(3).toDouble();
    frame["y"] = query.value(4);
    frame["z"] = query.value(5);
    frame["frameNo"] = query.value(6).toInt();
    frame["fa"] = query.value(7).toString();
    frame["sym"] = query.value(8).toString();
    frame["createdAt"] = query.value(9).toLongLong();
    frame["updatedAt"] = query.value(10).toLongLong();
        result.append(frame);
    }

    return result;
}

int FrameArrangementYZ::getRowCount() const
{
    return m_frameYZData.size();
}

QVariantMap FrameArrangementYZ::getFrameAtIndex(int index) const
{
    QVariantMap result;
    
    if (index >= 0 && index < m_frameYZData.size()) {
        const FrameYZData &frame = m_frameYZData.at(index);
        result["id"] = frame.id;
        result["name"] = frame.name;
        result["no"] = frame.no;
        result["spacing"] = frame.spacing;
        result["y"] = frame.y;
        result["z"] = frame.z;
        result["frameNo"] = frame.frameNo;
        result["fa"] = frame.fa;
        result["sym"] = frame.sym;
    }
    
    return result;
}

void FrameArrangementYZ::clearData()
{
    m_frameYZData.clear();
}

QSqlDatabase FrameArrangementYZ::getDatabase() const
{
    return DatabaseShipConnection::instance().getDatabase();
}

// ---------------- YZ Drawing Table Operations ----------------
// Mirrors the Python helper functions provided: create/insert/reset/fetch

bool FrameArrangementYZ::createDrawingTable()
{
    QSqlDatabase db = getDatabase();
    if (!db.isValid()) {
        m_lastError = "Ship database connection is not valid";
        qCritical() << "FrameArrangementYZ::createDrawingTable() -" << m_lastError;
        emit errorOccurred(m_lastError);
        return false;
    }

    QSqlQuery query(db);
    const QString sql = R"(
        CREATE TABLE IF NOT EXISTS structure_seagoing_ship_section0_frame_arrangement_yz_drawing (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            frameyz_id INTEGER,
            name TEXT,
            no INTEGER,
            spacing REAL,
            y REAL,
            z REAL,
            frame_no INTEGER,
            fa TEXT,
            sym TEXT,
            created_at INTEGER DEFAULT (strftime('%s','now') * 1000),
            updated_at INTEGER DEFAULT (strftime('%s','now') * 1000)
        )
    )";

    if (!query.exec(sql)) {
        m_lastError = QString("Failed to create YZ drawing table: %1").arg(query.lastError().text());
        qCritical() << "FrameArrangementYZ::createDrawingTable() -" << m_lastError;
        emit errorOccurred(m_lastError);
        return false;
    }
    qDebug() << "FrameArrangementYZ::createDrawingTable() - Table ensured";
    return true;
}

int FrameArrangementYZ::insertFrameYZDrawing(int frameyzId, const QString &name, int no, double spacing,
                                             double y, double z, int frameNo, const QString &fa, const QString &sym)
{
    QSqlDatabase db = getDatabase();
    if (!db.isValid()) {
        m_lastError = "Ship database connection is not valid";
        qCritical() << "FrameArrangementYZ::insertFrameYZDrawing() -" << m_lastError;
        emit errorOccurred(m_lastError);
        return -1;
    }

    QSqlQuery query(db);
    query.prepare("INSERT INTO structure_seagoing_ship_section0_frame_arrangement_yz_drawing "
                  "(frameyz_id, name, no, spacing, y, z, frame_no, fa, sym) VALUES (?,?,?,?,?,?,?,?,?)");
    query.addBindValue(frameyzId);
    query.addBindValue(name);
    query.addBindValue(no);
    query.addBindValue(spacing);
    query.addBindValue(y);
    query.addBindValue(z);
    query.addBindValue(frameNo);
    query.addBindValue(fa);
    query.addBindValue(sym);

    if (!query.exec()) {
        m_lastError = QString("Failed to insert YZ drawing frame: %1").arg(query.lastError().text());
        qCritical() << "FrameArrangementYZ::insertFrameYZDrawing() -" << m_lastError;
        emit errorOccurred(m_lastError);
        return -1;
    }
    int insertedId = query.lastInsertId().toInt();
    qDebug() << "FrameArrangementYZ::insertFrameYZDrawing() - Inserted drawing row id" << insertedId;
    return insertedId;
}

bool FrameArrangementYZ::resetFrameYZDrawingTable()
{
    QSqlDatabase db = getDatabase();
    if (!db.isValid()) {
        m_lastError = "Ship database connection is not valid";
        qCritical() << "FrameArrangementYZ::resetFrameYZDrawingTable() -" << m_lastError;
        emit errorOccurred(m_lastError);
        return false;
    }

    QSqlQuery query(db);
    if (!query.exec("DELETE FROM structure_seagoing_ship_section0_frame_arrangement_yz_drawing")) {
        m_lastError = QString("Failed to reset YZ drawing table: %1").arg(query.lastError().text());
        qCritical() << "FrameArrangementYZ::resetFrameYZDrawingTable() -" << m_lastError;
        emit errorOccurred(m_lastError);
        return false;
    }
    qDebug() << "FrameArrangementYZ::resetFrameYZDrawingTable() - All drawing rows deleted";
    return true;
}

QVariantList FrameArrangementYZ::getAllFrameYZDrawing()
{
    QVariantList result;
    m_frameYZDrawingData.clear();
    QSqlDatabase db = getDatabase();
    if (!db.isValid()) {
        m_lastError = "Ship database connection is not valid";
        qCritical() << "FrameArrangementYZ::getAllFrameYZDrawing() -" << m_lastError;
        emit errorOccurred(m_lastError);
        return result;
    }

    QSqlQuery query(db);
    if (!query.exec("SELECT id, frameyz_id, name, no, spacing, y, z, frame_no, fa, sym, created_at, updated_at FROM structure_seagoing_ship_section0_frame_arrangement_yz_drawing")) {
        m_lastError = QString("Failed to fetch YZ drawing rows: %1").arg(query.lastError().text());
        qCritical() << "FrameArrangementYZ::getAllFrameYZDrawing() -" << m_lastError;
        emit errorOccurred(m_lastError);
        return result;
    }

    while (query.next()) {
        FrameYZDrawingData d;
        d.id = query.value(0).toInt();
        d.frameyz_id = query.value(1).toInt();
        d.name = query.value(2).toString().toStdString();
        d.no = query.value(3).toInt();
        d.spacing = query.value(4).toDouble();
        d.y = query.value(5).toDouble();
        d.z = query.value(6).toDouble();
        d.frame_no = query.value(7).toInt();
        d.fa = query.value(8).toString().toStdString();
        d.sym = query.value(9).toString().toStdString();
        // Truncate 64-bit epoch ms to int as requested
        d.created_at = query.value(10).toLongLong();
        d.updated_at = query.value(11).toLongLong();
        m_frameYZDrawingData.append(d);

        QVariantMap row;
        row["id"] = d.id;
        row["frameyz_id"] = d.frameyz_id;
        row["name"] = QString::fromStdString(d.name);
        row["no"] = d.no;
        row["spacing"] = d.spacing;
        row["y"] = d.y;
        row["z"] = d.z;
        row["frame_no"] = d.frame_no;
        row["fa"] = QString::fromStdString(d.fa);
        row["sym"] = QString::fromStdString(d.sym);
        row["created_at"] = d.created_at;
        row["updated_at"] = d.updated_at;
        result.append(row);
    }

    return result;
}