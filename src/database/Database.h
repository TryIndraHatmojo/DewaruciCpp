#ifndef DATABASE_H
#define DATABASE_H

// Main database headers
#include "DatabaseConfig.h"
#include "DatabaseManager.h"

// Model headers
#include "models/BaseModel.h"
#include "models/UserModel.h"

// Convenience function to initialize the database system
namespace Database {
    
    /**
     * Initialize the database system with default configuration
     * @return true if initialization was successful
     */
    inline bool initialize()
    {
        return DatabaseManager::instance().initialize();
    }
    
    /**
     * Initialize the database system with custom config path
     * @param configPath Path to the database configuration file
     * @return true if initialization was successful
     */
    inline bool initialize(const QString& configPath)
    {
        DatabaseConfig::instance().loadConfig(configPath);
        return DatabaseManager::instance().initialize();
    }
    
    /**
     * Create all required database tables
     * @return true if tables were created successfully
     */
    inline bool createTables()
    {
        return DatabaseManager::instance().createTables();
    }
    
    /**
     * Test the database connection
     * @return true if connection is working
     */
    inline bool testConnection()
    {
        return DatabaseManager::instance().testConnection();
    }
    
    /**
     * Close the database connection
     */
    inline void close()
    {
        DatabaseManager::instance().close();
    }
    
    /**
     * Get the database manager instance
     * @return Reference to DatabaseManager singleton
     */
    inline DatabaseManager& manager()
    {
        return DatabaseManager::instance();
    }
    
    /**
     * Get the database configuration instance
     * @return Reference to DatabaseConfig singleton
     */
    inline DatabaseConfig& config()
    {
        return DatabaseConfig::instance();
    }
}

#endif // DATABASE_H
