CREATE TABLE articles(
id serial PRIMARY KEY,
title VARCHAR(255) NOT NULL,
url VARCHAR(2083) NOT NULL,
descriptions VARCHAR(5000) NOT NULL
);

CREATE TABLE comments(
id serial PRIMARY KEY,
username VARCHAR(50) NOT NULL,
comment VARCHAR(5000) NOT NULL,
article_id Int,
FOREIGN KEY (article_id) REFERENCES articles(id)
);
