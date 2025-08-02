const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');

const app = express();
app.use(cors());
app.use(express.json());

const pool = new Pool({
  host: process.env.PGHOST,
  user: process.env.PGUSER,
  password: process.env.PGPASSWORD,
  database: process.env.PGDATABASE,
});

app.post('/feedback', async (req, res) => {
  const { name, feedback } = req.body;
  try {
    await pool.query('INSERT INTO feedbacks (name, feedback) VALUES ($1, $2)', [name, feedback]);
    res.status(201).json({ message: 'Feedback received successfully' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error saving feedback' });
  }
});

app.get("/", (req, res) => {
  res.json({ message: "Backend is running" });
});

app.get('/feedback', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM feedbacks');
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Error retrieving feedbacks' });
  }
});

app.listen(5000, '0.0.0.0', () => console.log('Backend running on port 5000'));
