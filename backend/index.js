import express from "express";
import mysql from "mysql";
import cors from "cors";
import morgan from "morgan";
import dotenv from "dotenv";

dotenv.config();

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(morgan("common"));

// MySQL connection
const db = mysql.createConnection({
  host: process.env.DB_HOST,          // e.g. 10.0.0.5
  user: process.env.DB_USERNAME,      // e.g. book_user
  password: process.env.DB_PASSWORD,  // e.g. strong-pass
  port: process.env.DB_PORT || 3306,  // set DB_PORT=3306 in .env
  database: "test",                   // make sure this DB exists
});

// Connect once at startup
db.connect((err) => {
  if (err) {
    console.error("DB connection error:", err);
  } else {
    console.log("DB connected");
  }
});

// Simple health for LB
app.get("/", (req, res) => {
  res.status(200).json("hello");
});

// DB health check
app.get("/dbcheck", (req, res) => {
  db.query("SELECT 1", (err) => {
    if (err) {
      console.error("dbcheck error:", err);
      return res.status(500).json({ ok: false, error: err.code });
    }
    return res.json({ ok: true });
  });
});

// Get all books
app.get("/books", (req, res) => {
  const q = "SELECT * FROM books";
  db.query(q, (err, data) => {
    if (err) {
      console.error("GET /books error:", err);
      return res.status(500).json(err);
    }
    return res.json(data);
  });
});

// Create book
app.post("/books", (req, res) => {
  const q = "INSERT INTO books(`title`, `desc`, `price`, `cover`) VALUES (?)";
  const values = [
    req.body.title,
    req.body.desc,
    req.body.price,
    req.body.cover,
  ];
  db.query(q, [values], (err, data) => {
    if (err) {
      console.error("POST /books error:", err);
      return res.status(500).send(err);
    }
    return res.json(data);
  });
});

// Delete book
app.delete("/books/:id", (req, res) => {
  const bookId = req.params.id;
  const q = "DELETE FROM books WHERE id = ?";
  db.query(q, [bookId], (err, data) => {
    if (err) {
      console.error("DELETE /books error:", err);
      return res.status(500).send(err);
    }
    return res.json(data);
  });
});

// Update book
app.put("/books/:id", (req, res) => {
  const bookId = req.params.id;
  const q =
    "UPDATE books SET `title`= ?, `desc`= ?, `price`= ?, `cover`= ? WHERE id = ?";
  const values = [
    req.body.title,
    req.body.desc,
    req.body.price,
    req.body.cover,
  ];
  db.query(q, [...values, bookId], (err, data) => {
    if (err) {
      console.error("PUT /books error:", err);
      return res.status(500).send(err);
    }
    return res.json(data);
  });
});

// Listen on port 84, all interfaces (important for LB)
const PORT = 84;
app.listen(PORT, "0.0.0.0", () => {
  console.log(`Backend listening on port ${PORT}`);
});
