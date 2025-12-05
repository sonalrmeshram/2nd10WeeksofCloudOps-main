import express from "express";
import mysql from "mysql2";
import cors from "cors";
import morgan from "morgan";
import dotenv from "dotenv";

dotenv.config();
const app = express();

app.use(cors());
app.use(express.json());
app.use(morgan("common"));

const db = mysql.createConnection({
  host: process.env.DB_HOST,
  user: process.env.DB_USERNAME,
  password: process.env.DB_PASSWORD,
  port: process.env.DB_PORT,
  database: process.env.DB_DATABASE,
  ssl: { rejectUnauthorized: false }
});

db.connect((err) => {
  if (err) console.error("DB Connection Error:", err);
  else console.log("Connected to Azure MySQL!");
});

app.get("/", (req, res) => {
  res.json("hello");
});

app.get("/books", (req, res) => {
  const q = "SELECT * FROM books";
  db.query(q, (err, data) => {
    if (err) return res.status(500).json(err);
    return res.json(data);
  });
});

app.post("/books", (req, res) => {
  const q = "INSERT INTO books(`title`, `desc`, `price`, `cover`) VALUES (?)";
  const values = [req.body.title, req.body.desc, req.body.price, req.body.cover];
  db.query(q, [values], (err, data) => {
    if (err) return res.status(500).json(err);
    return res.json(data);
  });
});

app.delete("/books/:id", (req, res) => {
  const q = "DELETE FROM books WHERE id = ?";
  db.query(q, [req.params.id], (err, data) => {
    if (err) return res.status(500).json(err);
    return res.json(data);
  });
});

app.put("/books/:id", (req, res) => {
  const q = "UPDATE books SET `title`=?, `desc`=?, `price`=?, `cover`=? WHERE id=?";
  const values = [req.body.title, req.body.desc, req.body.price, req.body.cover];
  db.query(q, [...values, req.params.id], (err, data) => {
    if (err) return res.status(500).json(err);
    return res.json(data);
  });
});

const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
  console.log("Backend running on port", PORT);
});
