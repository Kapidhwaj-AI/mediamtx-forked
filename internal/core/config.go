package core

import (
	//"bank/config"

	"database/sql"
	"fmt"
	"log"

	_ "github.com/go-sql-driver/mysql"
)

var DB *sql.DB
var err error

func ConnectWithSql() (string, error) {

	log.Print("Connecting to MySQL database...")
	DB, err = sql.Open("mysql", fmt.Sprintf("clientdbuser:ClientDBUserKaPassword@tcp(%s:%s)/production", "35.232.220.60", "3306"))
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
