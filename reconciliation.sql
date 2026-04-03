-- ============================================================
--  Financial Transaction Reconciliation Queries
-- ============================================================

-- 1. Records in SOURCE but MISSING in TARGET
SELECT
    s.transaction_id,
    s.account_id,
    s.transaction_date,
    s.amount,
    'MISSING_IN_TARGET' AS issue_type
FROM source_transactions s
LEFT JOIN target_transactions t ON s.transaction_id = t.transaction_id
WHERE t.transaction_id IS NULL;


-- 2. Records in TARGET but MISSING in SOURCE (phantom records)
SELECT
    t.transaction_id,
    t.account_id,
    t.transaction_date,
    t.amount,
    'MISSING_IN_SOURCE' AS issue_type
FROM target_transactions t
LEFT JOIN source_transactions s ON t.transaction_id = s.transaction_id
WHERE s.transaction_id IS NULL;


-- 3. Amount Mismatches (same ID, different amount)
SELECT
    s.transaction_id,
    s.account_id,
    s.amount         AS source_amount,
    t.amount         AS target_amount,
    s.amount - t.amount AS variance,
    'AMOUNT_MISMATCH' AS issue_type
FROM source_transactions s
JOIN target_transactions t ON s.transaction_id = t.transaction_id
WHERE s.amount <> t.amount;


-- 4. Duplicate Transaction IDs in Source
SELECT
    transaction_id,
    COUNT(*) AS occurrences
FROM source_transactions
GROUP BY transaction_id
HAVING COUNT(*) > 1;


-- 5. Duplicate Transaction IDs in Target
SELECT
    transaction_id,
    COUNT(*) AS occurrences
FROM target_transactions
GROUP BY transaction_id
HAVING COUNT(*) > 1;


-- 6. Full Reconciliation Report (all issues in one view)
WITH recon AS (
    SELECT
        COALESCE(s.transaction_id, t.transaction_id) AS transaction_id,
        COALESCE(s.account_id,    t.account_id)      AS account_id,
        s.amount                                      AS source_amount,
        t.amount                                      AS target_amount,
        CASE
            WHEN t.transaction_id IS NULL           THEN 'MISSING_IN_TARGET'
            WHEN s.transaction_id IS NULL           THEN 'MISSING_IN_SOURCE'
            WHEN s.amount <> t.amount               THEN 'AMOUNT_MISMATCH'
            ELSE                                         'MATCHED'
        END AS recon_status
    FROM source_transactions s
    FULL OUTER JOIN target_transactions t
        ON s.transaction_id = t.transaction_id
)
SELECT * FROM recon
ORDER BY
    CASE recon_status
        WHEN 'MISSING_IN_TARGET' THEN 1
        WHEN 'MISSING_IN_SOURCE' THEN 2
        WHEN 'AMOUNT_MISMATCH'   THEN 3
        ELSE 4
    END;


-- 7. Summary — Reconciliation Stats by Account
WITH recon AS (
    SELECT
        COALESCE(s.account_id, t.account_id) AS account_id,
        CASE
            WHEN t.transaction_id IS NULL THEN 'MISSING_IN_TARGET'
            WHEN s.transaction_id IS NULL THEN 'MISSING_IN_SOURCE'
            WHEN s.amount <> t.amount     THEN 'AMOUNT_MISMATCH'
            ELSE                               'MATCHED'
        END AS recon_status
    FROM source_transactions s
    FULL OUTER JOIN target_transactions t
        ON s.transaction_id = t.transaction_id
)
SELECT
    account_id,
    COUNT(*) FILTER (WHERE recon_status = 'MATCHED')           AS matched,
    COUNT(*) FILTER (WHERE recon_status = 'MISSING_IN_TARGET') AS missing_in_target,
    COUNT(*) FILTER (WHERE recon_status = 'MISSING_IN_SOURCE') AS missing_in_source,
    COUNT(*) FILTER (WHERE recon_status = 'AMOUNT_MISMATCH')   AS amount_mismatches,
    COUNT(*)                                                    AS total_records
FROM recon
GROUP BY account_id
ORDER BY account_id;
