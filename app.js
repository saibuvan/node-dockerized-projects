const express = require('express');
const app = express();
const port = 3001;

// Basic route
app.get('/', (req, res) => {
  res.send('Hello, Express server is running!');
});

// Start server
app.listen(port, () => {
  console.log(`🚀 Server running at http://localhost:${port}`);
});

