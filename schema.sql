-- ============================================================
--  Financial Reconciliation — Schema
-- ============================================================

CREATE TABLE source_transactions (
    transaction_id   VARCHAR(30) PRIMARY KEY,
    account_id       VARCHAR(20) NOT NULL,
    transaction_date DATE        NOT NULL,
    amount           NUMERIC(15,2) NOT NULL,
    currency         VARCHAR(5)  DEFAULT 'INR',
    transaction_type VARCHAR(20),   -- DEBIT / CREDIT
    status           VARCHAR(20),   -- SETTLED / PENDING
    loaded_at        TIMESTAMP   DEFAULT NOW()
);

CREATE TABLE target_transactions (
    transaction_id   VARCHAR(30) PRIMARY KEY,
    account_id       VARCHAR(20) NOT NULL,
    transaction_date DATE        NOT NULL,
    amount           NUMERIC(15,2) NOT NULL,
    currency         VARCHAR(5)  DEFAULT 'INR',
    transaction_type VARCHAR(20),
    status           VARCHAR(20),
    loaded_at        TIMESTAMP   DEFAULT NOW()
);

-- Load source data
COPY source_transactions(transaction_id, account_id, transaction_date,
                         amount, currency, transaction_type, status)
FROM 'data/source_transactions.csv' DELIMITER ',' CSV HEADER;

-- Load target data
COPY target_transactions(transaction_id, account_id, transaction_date,
                          amount, currency, transaction_type, status)
FROM 'data/target_transactions.csv' DELIMITER ',' CSV HEADER;
