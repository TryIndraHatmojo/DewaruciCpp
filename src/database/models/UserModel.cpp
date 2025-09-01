#include "UserModel.h"
#include <QRegularExpression>
#include <QSqlRecord>
#include <QDebug>

UserModel::UserModel(QObject* parent)
    : BaseModel(parent)
{
}

void UserModel::setUsername(const QString& username)
{
    if (m_username != username) {
        m_username = username;
        emit usernameChanged();
    }
}

void UserModel::setEmail(const QString& email)
{
    if (m_email != email) {
        m_email = email;
        emit emailChanged();
    }
}

void UserModel::setPasswordHash(const QString& passwordHash)
{
    if (m_passwordHash != passwordHash) {
        m_passwordHash = passwordHash;
        emit passwordHashChanged();
    }
}

QStringList UserModel::fieldNames() const
{
    return {"username", "email", "password_hash"};
}

QVariantMap UserModel::toVariantMap() const
{
    QVariantMap map;
    map["username"] = m_username;
    map["email"] = m_email;
    map["password_hash"] = m_passwordHash;
    return map;
}

void UserModel::fromVariantMap(const QVariantMap& map)
{
    setId(map.value("id", 0).toInt());
    setUsername(map.value("username").toString());
    setEmail(map.value("email").toString());
    setPasswordHash(map.value("password_hash").toString());
    setCreatedAt(map.value("created_at").toDateTime());
    setUpdatedAt(map.value("updated_at").toDateTime());
}

UserModel* UserModel::findByUsername(const QString& username)
{
    QSqlQuery query = findWhere("users", "username = ?", {username});
    
    if (!query.exec() || !query.next()) {
        return nullptr;
    }
    
    QSqlRecord record = query.record();
    QVariantMap map;
    
    for (int i = 0; i < record.count(); ++i) {
        map[record.fieldName(i)] = record.value(i);
    }
    
    UserModel* user = new UserModel();
    user->fromVariantMap(map);
    return user;
}

UserModel* UserModel::findByEmail(const QString& email)
{
    QSqlQuery query = findWhere("users", "email = ?", {email});
    
    if (!query.exec() || !query.next()) {
        return nullptr;
    }
    
    QSqlRecord record = query.record();
    QVariantMap map;
    
    for (int i = 0; i < record.count(); ++i) {
        map[record.fieldName(i)] = record.value(i);
    }
    
    UserModel* user = new UserModel();
    user->fromVariantMap(map);
    return user;
}

QList<UserModel*> UserModel::getAllUsers()
{
    QList<UserModel*> users;
    QSqlQuery query = findAll("users", "username ASC");
    
    if (!query.exec()) {
        qWarning() << "Failed to get all users:" << query.lastError().text();
        return users;
    }
    
    while (query.next()) {
        QSqlRecord record = query.record();
        QVariantMap map;
        
        for (int i = 0; i < record.count(); ++i) {
            map[record.fieldName(i)] = record.value(i);
        }
        
        UserModel* user = new UserModel();
        user->fromVariantMap(map);
        users.append(user);
    }
    
    return users;
}

bool UserModel::validateEmail() const
{
    QRegularExpression emailRegex(R"([a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})");
    return emailRegex.match(m_email).hasMatch();
}

bool UserModel::validateUsername() const
{
    // Username should be 3-20 characters, alphanumeric and underscore only
    QRegularExpression usernameRegex(R"(^[a-zA-Z0-9_]{3,20}$)");
    return usernameRegex.match(m_username).hasMatch();
}
