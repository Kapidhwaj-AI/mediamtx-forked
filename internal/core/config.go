package core

import (
	//"bank/config"

	"database/sql"
	"fmt"
	"log"
	_ "github.com/mattn/go-sqlite3" // SQLite driver
	_ "github.com/go-sql-driver/mysql"
)


var DB *sql.DB
var SQLiteDB *sql.DB 
var err error

func ConnectWithSql() (string, error) {

	log.Print("Connecting to MySQL database...")
	DB, err = sql.Open("mysql", fmt.Sprintf("clientdbuser:ClientDBUserKaPassword@tcp(%s:%s)/newClientDbTesting", "35.232.220.60", "3306"))
	if err != nil {
		// Logger.Fatal(err)
		return "", err
	}

	log.Print("After connecting to MySQL database...")
	DB.SetMaxOpenConns(10)
	DB.SetMaxIdleConns(10)
	err = DB.Ping()
	if err != nil {
		log.Fatal(err)
		return "", err
	}
	log.Println("Successfully connected to MySQL database")
	return "success", nil
}

// Connects to the SQLite database
func ConnectWithSqlite() (string, error) {
    log.Print("Connecting to SQLite database...")
    // The path to your SQLite database file.
    // Ensure this path is correct relative to where your Go application will be run.
    // If your Go app is in the same directory as your Hub code, then "./mydatabase.db" is fine.
    // Otherwise, you might need to specify an absolute path or a path relative to the Go executable.
    sqliteDBPath := "/home/vicharak/Downloads/edge/Onvif-Client-App/mydatabase.db"

    SQLiteDB, err = sql.Open("sqlite3", sqliteDBPath)
    if err != nil {
        log.Printf("Error opening SQLite database: %v", err)
        return "", err
    }
    SQLiteDB.SetMaxOpenConns(10)
    SQLiteDB.SetMaxIdleConns(10)

    // Ping the database to verify the connection
    err = SQLiteDB.Ping()
    if err != nil {
        log.Printf("Error pinging SQLite database: %v", err)
        return "", err
    }
    log.Println("Successfully connected to SQLite database")
    return "success", nil
}
