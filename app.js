const express = require('express');
const app = express();

const port = 3000;

app.get('/', (req, res) => {
  res.send('Hello World my Redington services buddy forever yes nooo!!!');
});

// ✅ Health endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'UP', message: 'Service is healthy' });
});

app.listen(port, '0.0.0.0', () => {
  console.log(`🚀 Server running at http://localhost:${port}`);
});
