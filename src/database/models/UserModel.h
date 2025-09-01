#ifndef USERMODEL_H
#define USERMODEL_H

#include "BaseModel.h"
#include <QString>

class UserModel : public BaseModel
{
    Q_OBJECT
    Q_PROPERTY(QString username READ username WRITE setUsername NOTIFY usernameChanged)
    Q_PROPERTY(QString email READ email WRITE setEmail NOTIFY emailChanged)
    Q_PROPERTY(QString passwordHash READ passwordHash WRITE setPasswordHash NOTIFY passwordHashChanged)

public:
    explicit UserModel(QObject* parent = nullptr);
    
    // Properties
    QString username() const { return m_username; }
    void setUsername(const QString& username);
    
    QString email() const { return m_email; }
    void setEmail(const QString& email);
    
    QString passwordHash() const { return m_passwordHash; }
    void setPasswordHash(const QString& passwordHash);
    
    // BaseModel interface implementation
    QString tableName() const override { return "usertbl"; }
    QStringList fieldNames() const override;
    QVariantMap toVariantMap() const override;
    void fromVariantMap(const QVariantMap& map) override;
    
    // Static methods for user-specific queries
    static UserModel* findByUsername(const QString& username);
    static UserModel* findByEmail(const QString& email);
    static QList<UserModel*> getAllUsers();
    
    // Utility methods
    bool validateEmail() const;
    bool validateUsername() const;

signals:
    void usernameChanged();
    void emailChanged();
    void passwordHashChanged();

private:
    QString m_username;
    QString m_email;
    QString m_passwordHash;
};

#endif // USERMODEL_H
