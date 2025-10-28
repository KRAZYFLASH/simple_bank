package db

import (
	"context"
	"database/sql"
	"fmt"
)

type Store struct {
	*Queries
	db *sql.DB
}
// Membuat sebuah instance Store baru
func NewStore(db *sql.DB) *Store {
	return &Store{
		db:     db,
		Queries: New(db),
	}
}

// Mengksekusi fungsi dalam sebuah transaksi database
func (store *Store) execTx(ctx context.Context, fn func(*Queries) error) error {
	tx, err := store.db.BeginTx(ctx, nil)
	if err != nil {
		return err
	}

	q := New(tx)
	err = fn(q)
	if err != nil {
		if rbErr := tx.Rollback(); rbErr != nil {
			return fmt.Errorf("tx err: %v, rb err: %v", err, rbErr)
		}
		return err
	}

	return tx.Commit()
}

// Memproses transfer uang antar dua akun dalam sebuah transaksi
type TransferTxParams struct {
	FromAccountID int64 `json:"from_account_id"`
	ToAccountID   int64 `json:"to_account_id"`
	Amount        int64 `json:"amount"`
}

// Mengembalikan hasil dari proses transfer
type TransferTxResult struct {
	Transfer    Transfers `json:"transfer"`
	FromAccount Accounts   `json:"from_account"`
	ToAccount   Accounts   `json:"to_account"`
	FromEntry   Entries   `json:"from_entry"`
	ToEntry     Entries   `json:"to_entry"`
}

// var txKey = struct{}{}

// Melakukan transfer uang antar dua akun dalam sebuah transaksi, [fungsi ini membuat catatan transfer dan entri untuk kedua akun serta memperbarui saldo akun secara atomik.]
func (store *Store) TransferTx(ctx context.Context, arg TransferTxParams) (TransferTxResult, error) {
	var result TransferTxResult

	err := store.execTx(ctx, func(q *Queries) error {
		var err error

		// txName := ctx.Value(txKey)

		// fmt.Println(txName, "Create Transfer")

		result.Transfer, err = q.CreateTransfer(ctx, CreateTransferParams{
			FromAccountID: arg.FromAccountID,
			ToAccountID:   arg.ToAccountID,
			Amount:        arg.Amount,
		})
		
		if err != nil {
			return err
		}

		// fmt.Println(txName, "Create Entry done")
		result.FromEntry, err = q.CreateEntry(ctx, CreateEntryParams{
			AccountID: arg.FromAccountID,
			Amount:    -arg.Amount,
		})
		if err != nil {
			return err
		}

		// fmt.Println(txName, "Create To Entry done")
		result.ToEntry, err = q.CreateEntry(ctx, CreateEntryParams{
			AccountID: arg.ToAccountID,
			Amount:    arg.Amount,
		})

		if err != nil {
			return err
		}

		// TODO: get account's balance untuk update dari akun yang mengirim

		// fmt.Println(txName, "Get Account for Update 1")

		// SEBELUM ADA ADD BALANCE ACCOUNT
		// account1, err := q.GetAccountForUpdate(ctx, arg.FromAccountID)
		// if err != nil {
		// 	return err
		// }

		// fmt.Println(txName, "Update Account 1")
		result.FromAccount, err = q.AddAccountBalance(ctx, AddAccountBalanceParams{
			ID:      arg.FromAccountID,
			Amount: -arg.Amount,
		})
		if err != nil {
			return err
		}

		// TODO: get account's balance untuk update akun yang menerima

		// fmt.Println(txName, "Get Account for Update 2")

		// SEBELUM ADA ADD BALANCE ACCOUNT
		// account2, err := q.GetAccountForUpdate(ctx, arg.ToAccountID)
		// if err != nil {
		// 	return err
		// }

		// fmt.Println(txName, "Update Account 2")
		result.ToAccount, err = q.AddAccountBalance(ctx, AddAccountBalanceParams{
			ID:      arg.ToAccountID,
			Amount:  arg.Amount,
		})
		if err != nil {
			return err
		}

		return nil
	})
	return result, err
}
