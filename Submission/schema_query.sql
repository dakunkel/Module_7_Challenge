DROP TABLE IF EXISTS merchant_category;
DROP TABLE IF EXISTS merchant;
DROP TABLE IF EXISTS card_holders;
DROP TABLE IF EXISTS credit_cards;
DROP TABLE IF EXISTS transactions;


CREATE TABLE merchant_category(
	id_merchant_category SERIAL PRIMARY KEY NOT NULL,
	merchant_category VARCHAR(50)
);

CREATE TABLE merchant(
	id_merchant SERIAL PRIMARY KEY NOT NULL,
	merchant_name VARCHAR(50),
	id_merchant_category INT,
	FOREIGN KEY (id_merchant_category) REFERENCES merchant_category(id_merchant_category)
);

CREATE TABLE card_holders(
	cardholder_id SERIAL PRIMARY KEY NOT NULL,
	cardholder_name VARCHAR(50)
);

CREATE TABLE credit_cards(
	card VARCHAR(20) PRIMARY KEY NOT NULL,
	cardholder_id INT,
	FOREIGN KEY (cardholder_id) REFERENCES card_holders(cardholder_id),
	CONSTRAINT unique_card UNIQUE (card)
);

CREATE TABLE transactions(
	transaction_id INT PRIMARY KEY NOT NULL,
	date TIMESTAMP,
	amount FLOAT,
	card VARCHAR(20),
	id_merchant INT,
	FOREIGN KEY (id_merchant) REFERENCES merchant(id_merchant),
	FOREIGN KEY (card) REFERENCES credit_cards(card)
);

-- Imported all data via CSV "Import/Export Data" tool with headers checked on and "," delimited