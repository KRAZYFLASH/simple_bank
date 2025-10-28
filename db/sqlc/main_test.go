package db

import (
	"database/sql"
	"log"
	"os"
	"testing"

	_ "github.com/lib/pq" // penting: driver Postgres
)

const (
	dbDriver = "postgres"
	dbSource = "postgresql://root:secret@localhost:5432/simple_bank?sslmode=disable"
)

var (
	testDB      *sql.DB
	testQueries *Queries
)

func TestMain(m *testing.M) {
	var err error
	testDB, err = sql.Open(dbDriver, dbSource)
	if err != nil {
		log.Fatal("cannot connect to db:", err)
	}
	testQueries = New(testDB)
	os.Exit(m.Run())
}
