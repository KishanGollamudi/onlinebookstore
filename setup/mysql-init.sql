CREATE TABLE IF NOT EXISTS books (
  barcode VARCHAR(100) PRIMARY KEY,
  name VARCHAR(100),
  author VARCHAR(100),
  price INT,
  quantity INT
);

CREATE TABLE IF NOT EXISTS users (
  username VARCHAR(100) PRIMARY KEY,
  password VARCHAR(100) NOT NULL,
  firstname VARCHAR(100) NOT NULL,
  lastname VARCHAR(100) NOT NULL,
  address TEXT NOT NULL,
  phone VARCHAR(100) NOT NULL,
  mailid VARCHAR(100) NOT NULL,
  usertype INT
);

INSERT IGNORE INTO books VALUES
  ('9780134190500', 'Data Structures Through C', 'G.S. Baluja', 525, 20),
  ('9780134190563', 'The Go Programming Language', 'Alan A. A. Donovan and Brian Kernighan', 400, 8),
  ('9780133053036', 'C++ Primer', 'Stanley Lippman and Josée Lajoie and Barbara Moo', 976, 13),
  ('9781718500457', 'The Rust Programming Language', 'Steve Klabnik and Carol Nichols', 560, 12),
  ('9781491910740', 'Head First Java', 'Kathy Sierra and Bert Bates and Trisha Gee', 754, 23),
  ('9781492056300', 'Fluent Python', 'Luciano Ramalho', 1014, 5),
  ('9781720043997', 'The Road to Learn React', 'Robin Wieruch', 239, 18),
  ('9780132350884', 'Clean Code: A Handbook of Agile Software Craftsmanship', 'Robert C Martin', 288, 3),
  ('9780132181273', 'Domain-Driven Design', 'Eric Evans', 560, 28),
  ('9780132181785', 'Let us C', 'Yashavant Kanetkar', 329, 15),
  ('9781951204006', 'A Programmers Guide to Computer Science', 'William Springer', 188, 4),
  ('9780316204552', 'The Soul of a New Machine', 'Tracy Kidder', 293, 30),
  ('9780132778046', 'Effective Java', 'Joshua Bloch', 368, 21),
  ('9781484255995', 'Practical Rust Projects', 'Shing Lyu', 257, 15),
  ('9781484255996', 'Agni Veena', 'Kazi Nasrul Islam', 259, 25);

INSERT IGNORE INTO users VALUES
  ('demo', 'demo', 'Demo', 'User', 'Demo Home', '42502216225', 'demo@gmail.com', 2),
  ('Admin', 'Admin', 'Mr.', 'Admin', 'Haldia WB', '9584552224521', 'admin@gmail.com', 1),
  ('shashi', 'shashi', 'Shashi', 'Raj', 'Bihar', '1236547089', 'shashi@gmail.com', 2);
