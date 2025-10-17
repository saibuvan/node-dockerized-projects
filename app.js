const express = require('express');
const app = express();
const port = 3002;

app.get('/', (req, res) => {
  res.send('Node.js service is running!!!');
});

app.listen(port, '0.0.0.0', () => {
  console.log(`🚀 Server running at http://localhost:${port}`);
});


