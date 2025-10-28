-- name: CreateEntry :one
INSERT INTO entries (
    account_id,
    amount
) VALUES (
    $1,
    $2
) RETURNING *;

-- name: GetEntry :one
SELECT * FROM entries
WHERE id = $1 LIMIT 1;

-- name: ListEntries :many
SELECT * FROM entries
WHERE account_id = $1
ORDER BY id
LIMIT $2 OFFSET $3;

-- name: ListEntriesAll :many
SELECT * FROM entries
ORDER BY id
LIMIT $1 OFFSET $2;

-- name: UpdateEntry :one
UPDATE entries
SET amount = $2
WHERE id = $1
RETURNING *;

-- name: DeleteEntry :exec
DELETE FROM entries
WHERE id = $1;

-- name: GetEntriesByAccountId :many
SELECT * FROM entries
WHERE account_id = $1
ORDER BY created_at DESC;

-- name: GetEntriesByDateRange :many
SELECT * FROM entries
WHERE account_id = $1
AND created_at BETWEEN $2 AND $3
ORDER BY created_at DESC;