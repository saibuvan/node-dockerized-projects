const express = require('express');
const app = express();
const port = 3005;

app.get('/', (req, res) => {
  res.send('hello redington!');
});

app.listen(port, '0.0.0.0', () => {
  console.log(`🚀 Server running at http://localhost:${port}`);
  res.send('Hello, Express server is running!');
});

app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});

