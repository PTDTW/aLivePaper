import Foundation
import SQLite3

class DatabaseManager {
    static let shared = DatabaseManager()
    private var db: OpaquePointer?
    
    private var databasePath: String {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupportDir = paths[0].appendingPathComponent("aLivePaper")
        return appSupportDir.path
    }
    
    private init() {
        createDirectoryIfNeeded()
        setupDatabase()
    }
    
    private func createDirectoryIfNeeded() {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: databasePath) {
            do {
                try fileManager.createDirectory(atPath: databasePath, withIntermediateDirectories: true)
            } catch {
                print("Error creating directory: \(error)")
            }
        }
    }
    
    private func setupDatabase() {
        let dbFilePath = (databasePath as NSString).appendingPathComponent("wallpapers.sqlite")
        print("Database path: \(dbFilePath)")
        
        // Create empty file if not exists
        if !FileManager.default.fileExists(atPath: dbFilePath) {
            FileManager.default.createFile(atPath: dbFilePath, contents: nil)
        }
        
        // Set file permissions
        try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: dbFilePath)
        
        if sqlite3_open(dbFilePath, &db) == SQLITE_OK {
            // Enable foreign keys and WAL mode for better performance
            executeSql("PRAGMA foreign_keys = ON;")
            executeSql("PRAGMA journal_mode = WAL;")
            
            // Create table if not exists
            let createTableQuery = """
                CREATE TABLE IF NOT EXISTS wallpapers (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    path TEXT UNIQUE,
                    fileName TEXT,
                    lastUsed DATETIME,
                    volume FLOAT
                );
            """
            executeSql(createTableQuery)
        }
    }
    
    private func executeSql(_ sql: String) {
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error executing SQL: \(String(cString: sqlite3_errmsg(db)))")
            }
        }
        sqlite3_finalize(statement)
    }
    
    func saveWallpaper(path: String, fileName: String, volume: Float) {
        let query = """
            INSERT OR REPLACE INTO wallpapers (path, fileName, lastUsed, volume)
            VALUES (?, ?, ?, ?);
        """
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            let timestamp = Date().timeIntervalSince1970
            
            sqlite3_bind_text(statement, 1, (path as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (fileName as NSString).utf8String, -1, nil)
            sqlite3_bind_double(statement, 3, timestamp)
            sqlite3_bind_double(statement, 4, Double(volume))
            
            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error saving wallpaper: \(String(cString: sqlite3_errmsg(db)))")
            }
        }
        sqlite3_finalize(statement)
    }
    
    func getWallpapers() -> [WallpaperRecord] {
        var records: [WallpaperRecord] = []
        let query = "SELECT * FROM wallpapers ORDER BY lastUsed DESC"
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = sqlite3_column_int64(statement, 0)
                let path = String(cString: sqlite3_column_text(statement, 1))
                let fileName = String(cString: sqlite3_column_text(statement, 2))
                let timestamp = sqlite3_column_double(statement, 3)
                let volume = Float(sqlite3_column_double(statement, 4))
                
                let record = WallpaperRecord(
                    id: id,
                    path: path,
                    fileName: fileName,
                    lastUsed: Date(timeIntervalSince1970: timestamp),
                    volume: volume
                )
                records.append(record)
            }
        }
        sqlite3_finalize(statement)
        return records
    }
}
