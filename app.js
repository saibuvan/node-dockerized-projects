const express = require('express');
const app = express();
const port = 8081;

app.get('/', (req, res) => {
  res.send('Hello, Express server is running!');
});

app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});

