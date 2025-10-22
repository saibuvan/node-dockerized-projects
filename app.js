const express = require('express');
const app = express();

// Use env PORT if provided, fallback to 3005
const port =  3000;

app.get('/', (req, res) => {
  res.send('Hello Redington!');
});

app.listen(port, '0.0.0.0', () => {
  console.log(`🚀 Server running at http://localhost:${port}`);
});


