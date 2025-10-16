const express = require('express');
const app = express();
const port = 3002;

// Route
app.get('/', (req, res) => {
  res.send('Node.js Buvanesh service is running!');
});

// ✅ Listen only once
app.listen(port, '0.0.0.0', () => {
  console.log(`🚀 Server running at http://localhost:${port}`);
});


