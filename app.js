const express = require('express');
const app = express();
const port = 3001;

// Basic route
app.get('/', (req, res) => {
  res.send('Node.js Buvanesh process!!!');
});

// Start server
app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});
