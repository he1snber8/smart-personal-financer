CREATE TABLE users(id SERIAL PRIMARY KEY, name TEXT);
CREATE TABLE expenses(id SERIAL PRIMARY KEY, user_id INT, amount NUMERIC, category TEXT, occurred_at TIMESTAMP);
CREATE TABLE goals(id SERIAL PRIMARY KEY, user_id INT, name TEXT, target NUMERIC);
