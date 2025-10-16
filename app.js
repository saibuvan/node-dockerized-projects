const express = require('express');
const app = express();
const port = 3001;

app.get('/', (req, res) => {
  res.send('Node.js Buvanesh service js guys');
  res.send('jenkins server apps service!');
});

app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});
