import express from "express";
import mysql from "mysql";
import cors from "cors";
import morgan from "morgan";
import dotenv from "dotenv";

const app = express();
dotenv.config();

app.use(cors());
app.use(express.json());
app.use(morgan("common"));

const db = mysql.createConnection({
  host: process.env.DB_HOST,
  user: process.env.DB_USERNAME,
  password: process.env.DB_PASSWORD,
  port: 3306,              // or process.env.DB_PORT if you created it
  database: "test",
});

// optional: check at startup
db.connect((err) => {
  if (err) {
    console.error("DB connect error:", err);
  } else {
    console.log("DB connected");
  }
});

app.get("/", (req, res) => {
  res.json("hello");
});

app.get("/dbcheck", (req, res) => {
  db.query("SELECT 1", (err) => {
    if (err) return res.status(500).json({ ok: false });
    return res.json({ ok: true });
  });
});

app.get("/books", (req, res) => {
  const q = "SELECT * FROM books";
  db.query(q, (err, data) => {
    if (err) return res.status(500).json(err);
    return res.json(data);
  });
});

app.post("/books", (req, res) => {
  const q =
    "INSERT INTO books(`title`, `desc`, `price`, `cover`) VALUES (?)";
  const values = [
    req.body.title,
    req.body.desc,
    req.body.price,
    req.body.cover,
  ];
  db.query(q, [values], (err, data) => {
    if (err) return res.status(500).send(err);
    return res.json(data);
  });
});

app.delete("/books/:id", (req, res) => {
  const bookId = req.params.id;
  const q = "DELETE FROM books WHERE id = ?";
  db.query(q, [bookId], (err, data) => {
    if (err) return res.status(500).send(err);
    return res.json(data);
  });
});

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
    if (err) return res.status(500).send(err);
    return res.json(data);
  });
});

app.listen(84, () => {
  console.log("Backend listening on 84");
});
