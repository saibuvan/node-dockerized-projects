const express = require('express');
const app = express();

const port = 3000;

app.get('/', (req, res) => {
<<<<<<< HEAD
  res.send('Hello World my Redington application!!!');
=======
  res.send('Hello World Redington my Service!!!');
>>>>>>> dd206c9ad4bdd9c7b6dfa80a50983688abc92ff4
});

// ✅ Health endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'UP', message: 'Service is healthy' });
});

app.listen(port, '0.0.0.0', () => {
  console.log(`🚀 Server running at http://localhost:${port}`);
});
