-- CREATE VIEW FOR COMBINED DATA SET
CREATE OR REPLACE VIEW combined_data_set AS 
SELECT 
    t.transaction_id,
    t.date,
    t.amount,
    ch.cardholder_id,
    ch.cardholder_name,
    cc.card,
    mc.merchant_category,
    m.merchant_name
FROM transactions t
INNER JOIN credit_cards cc ON t.card = cc.card
INNER JOIN card_holders ch ON cc.cardholder_id = ch.cardholder_id
INNER JOIN merchant m ON t.id_merchant = m.id_merchant
INNER JOIN merchant_category mc ON m.id_merchant_category = mc.id_merchant_category;

-- VIEW DATA FOR CARD HOLDER #1 WITH TRANSACTION LESS THAN $2.00
SELECT *
FROM combined_data_set
WHERE cardholder_id = '1' AND amount <2;

------------------------ DATA ANALYSIS ----------------------------
-- Some fraudsters hack a credit card by making several small transactions (less than $2.00), typically ignored by cardholders. 
-- How can you isolate (or group) the transactions of each cardholder?
CREATE OR REPLACE VIEW transactions_grouped_by_cardholder AS 
SELECT
    cardholder_id,
    cardholder_name,
    ROUND(CAST(SUM(amount) AS int),2) AS total_transaction_amount,
	CAST(COUNT(amount) AS int) AS total_transaction_count
FROM combined_data_set 
GROUP BY cardholder_id, cardholder_name
ORDER BY total_transaction_amount DESC;

SELECT *
FROM transactions_grouped_by_cardholder;

-- Count the transactions that are less than $2.00 per cardholder. 
CREATE OR REPLACE VIEW transactions_count_less_than_2 AS 
SELECT
    cardholder_id,
    cardholder_name,
    COUNT(CASE WHEN amount <2 THEN 1 END) AS total_transaction_count
FROM combined_data_set 
GROUP BY cardholder_id, cardholder_name
ORDER BY total_transaction_count DESC;

SELECT *
FROM transactions_count_less_than_2;

-- Create a view that combines the last two views (Total Transaction Amount and Count):
CREATE OR REPLACE VIEW transactions_grouped_by_cardholder_under_2 AS 
SELECT
    cardholder_id,
    cardholder_name,
    ROUND(CAST(SUM(amount) AS INT),2) AS total_transaction_amount,
	CAST(COUNT(amount) AS INT) AS total_transaction_count,
	COUNT(CASE WHEN amount <2 THEN 1 END) AS total_transaction_under_2_count
FROM combined_data_set
GROUP BY cardholder_id, cardholder_name
ORDER BY total_transaction_under_2_count DESC;

-- Create a view for ratios of $2 purchases to sum and count  of transactions
CREATE OR REPLACE VIEW transactions_under_2_ratios AS 
SELECT *,
       CONCAT(ROUND((total_transaction_under_2_count / CAST(total_transaction_count AS numeric) *100),2),'%') AS transaction_under_2_to_total_count_ratio,
       CONCAT(ROUND((total_transaction_under_2_count / total_transaction_amount *100),2),'%') AS transaction_under_2_to_sum_ratio
FROM transactions_grouped_by_cardholder_under_2
ORDER BY transaction_under_2_to_total_count_ratio DESC;

SELECT *
FROM transactions_under_2_ratios;

-- View to see transactions under $2 by date
CREATE OR REPLACE VIEW transactions_less_than_2_by_date AS 
SELECT
    cardholder_id,
    cardholder_name,
	transaction_id,
	amount,
	merchant_name,
	merchant_category,
	date
FROM combined_data_set
WHERE amount <2
GROUP BY transaction_id, cardholder_id, merchant_name,merchant_category,amount,cardholder_name, date
ORDER BY cardholder_id, date;

SELECT *
FROM transactions_less_than_2_by_date;

-- View to see transactions grouped by amount and cardholder
CREATE OR REPLACE VIEW transaction_count_grouped_by_amount AS 
SELECT
	cardholder_name,
	amount,
	COUNT(amount) AS count_amount
FROM combined_data_set 
WHERE amount <2
GROUP BY amount, cardholder_name
ORDER BY cardholder_name,amount;

SELECT *
FROM transaction_count_grouped_by_amount;

-- View to group transactions by Amount with no cardholder name
CREATE OR REPLACE VIEW transaction_count_grouped_by_amount_no_cardholder AS 
SELECT
	amount,
	COUNT(amount) AS count_amount
FROM combined_data_set 
WHERE amount <2
GROUP BY amount
ORDER BY count_amount DESC;

SELECT *
FROM transaction_count_grouped_by_amount_no_cardholder;

-- Take your investigation a step futher by considering the time period in which potentially fraudulent transactions are made. 
-- What are the top 100 highest transactions made between 7:00 am and 9:00 am?
CREATE OR REPLACE VIEW top_100_transactions_between_7_and_9 AS 
SELECT
    cardholder_id,
    cardholder_name,
	transaction_id,
	amount,
	merchant_name,
	merchant_category,
	date
FROM combined_data_set
WHERE EXTRACT(HOUR FROM date) >= 7 AND EXTRACT(HOUR FROM date) < 9
GROUP BY transaction_id, cardholder_id, merchant_name,merchant_category,amount,cardholder_name, date
ORDER BY amount DESC
LIMIT 100;

SELECT *
FROM top_100_transactions_between_7_and_9;

----- View to see all Transactions between 7-9
CREATE OR REPLACE VIEW transactions_between_7_and_9 AS 
SELECT
    cardholder_id,
    cardholder_name,
	transaction_id,
	amount,
	merchant_name,
	merchant_category,
	date
FROM combined_data_set
WHERE EXTRACT(HOUR FROM date) >= 7 AND EXTRACT(HOUR FROM date) < 9
GROUP BY transaction_id, cardholder_id, merchant_name,merchant_category,amount,cardholder_name, date
ORDER BY amount DESC;

SELECT *
FROM transactions_between_7_and_9;

-- Is there a higher number of fraudulent transactions made during this time frame versus the rest of the day?
-- View to see top 100 transactions outside of 7-9AM
CREATE OR REPLACE VIEW top_100_transactions_outside_7_and_9 AS 
SELECT
    cardholder_id,
    cardholder_name,
	transaction_id,
	amount,
	merchant_name,
	merchant_category,
	date
FROM combined_data_set
WHERE EXTRACT(HOUR FROM date) < 7 OR EXTRACT(HOUR FROM date) >= 9
GROUP BY transaction_id, cardholder_id, merchant_name,merchant_category,amount,cardholder_name, date
ORDER BY amount DESC
LIMIT 100;

SELECT *
FROM top_100_transactions_outside_7_and_9;

----- View to see all transactions outside of 7-9AM
CREATE OR REPLACE VIEW transactions_outside_7_and_9 AS 
SELECT
    cardholder_id,
    cardholder_name,
	transaction_id,
	amount,
	merchant_name,
	merchant_category,
	date
FROM combined_data_set
WHERE EXTRACT(HOUR FROM date) < 7 OR EXTRACT(HOUR FROM date) >= 9
GROUP BY transaction_id, cardholder_id, merchant_name,merchant_category,amount,cardholder_name, date
ORDER BY amount DESC;

SELECT *
FROM transactions_outside_7_and_9;

-- Transaction count grouped by hour over $1,000 to see highest time potentially fraudulent transactions occur
CREATE OR REPLACE VIEW transactions_by_hour AS 
SELECT
    EXTRACT(HOUR FROM date) AS transaction_hour,
	COUNT(CASE WHEN amount > 1000 THEN 1 END) AS count_amount_over_1000,
	COUNT(amount) AS count_total_transactions
FROM combined_data_set
GROUP BY transaction_hour
ORDER BY transaction_hour;

SELECT *
FROM transactions_by_hour;

-- Transaction count grouped by hour under $2 to see highest time potentially fraudulent transactions occur
CREATE OR REPLACE VIEW transactions_by_hour_under_2 AS 
SELECT
    EXTRACT(HOUR FROM date) AS transaction_hour,
	COUNT(CASE WHEN amount < 2 THEN 1 END) AS count_amount_under_2,
	COUNT(amount) AS count_total_transactions
FROM combined_data_set
GROUP BY transaction_hour
ORDER BY transaction_hour;

SELECT *
FROM transactions_by_hour_under_2;

-- What are the top 5 merchants prone to being hacked using small transactions?
CREATE OR REPLACE VIEW transactions_by_merchant_category AS 
SELECT
	merchant_category,
	COUNT(CASE WHEN amount > 1000 THEN 1 END) AS count_amount_over_1000,
	COUNT(CASE WHEN amount < 2 THEN 1 END) AS count_amount_under_2,
	COUNT(amount) AS count_total_transactions,
    ROUND((COUNT(CASE WHEN amount > 1000 THEN 1 END) / CAST(COUNT(amount) AS decimal) * 100),2) AS percent_amount_over_1000,
    ROUND((COUNT(CASE WHEN amount < 2 THEN 1 END) / CAST(COUNT(amount) AS decimal) * 100),2) AS percent_amount_under_2
FROM combined_data_set
GROUP BY merchant_category
ORDER BY count_amount_over_1000;

SELECT *
FROM transactions_by_merchant_category;


CREATE OR REPLACE VIEW transactions_by_merchant AS 
SELECT
	merchant_name,
	COUNT(CASE WHEN amount > 1000 THEN 1 END) AS count_amount_over_1000,
	COUNT(CASE WHEN amount < 2 THEN 1 END) AS count_amount_under_2,
	COUNT(amount) AS count_total_transactions,
    ROUND((COUNT(CASE WHEN amount > 1000 THEN 1 END) / CAST(COUNT(amount) AS decimal) * 100),2) AS percent_amount_over_1000,
    ROUND((COUNT(CASE WHEN amount < 2 THEN 1 END) / CAST(COUNT(amount) AS decimal) * 100),2) AS percent_amount_under_2
FROM combined_data_set
GROUP BY merchant_name
ORDER BY percent_amount_under_2 DESC;

SELECT *
FROM transactions_by_merchant
WHERE count_amount_over_1000 >0 and count_amount_under_2 >0 and percent_amount_over_1000 > 5;

SELECT *
FROM transactions_by_merchant
WHERE count_amount_under_2 >0
LIMIT 5;

SELECT *
FROM transactions_by_merchant
ORDER BY count_amount_under_2 DESC
LIMIT 5;

-- View for ID and name of cardholder when there is a transaction over $1,000, and multiple under $2
CREATE OR REPLACE VIEW cardholder_with_over_1000_and_under_2 AS 
SELECT
	cardholder_id,
	cardholder_name,
	COUNT(CASE WHEN amount > 1000 THEN 1 END) AS count_amount_over_1000,
	COUNT(CASE WHEN amount < 2 THEN 1 END) AS count_amount_under_2,
	COUNT(amount) AS count_total_transactions,
    ROUND((COUNT(CASE WHEN amount > 1000 THEN 1 END) / CAST(COUNT(amount) AS decimal) * 100),2) AS percent_amount_over_1000,
    ROUND((COUNT(CASE WHEN amount < 2 THEN 1 END) / CAST(COUNT(amount) AS decimal) * 100),2) AS percent_amount_under_2
FROM combined_data_set
GROUP BY cardholder_id, cardholder_name
ORDER BY count_amount_over_1000;

SELECT *
FROM cardholder_with_over_1000_and_under_2
WHERE count_amount_over_1000 >0 and count_amount_under_2 >1;

SELECT *
FROM combined_data_set
WHERE cardholder_id = '6' AND amount >1000;