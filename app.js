const express = require('express');
const app = express();
const port = 3001;

// Basic route
app.get('/', (req, res) => {
<<<<<<< HEAD
  res.send('jenkins server apps service!');
=======
<<<<<<< HEAD
  res.send('Node.js Buvanesh service js guys');
=======
  res.send('jenkins server apps service!');
>>>>>>> a739e61fbbc1827be16338363a070d65533adcb9
>>>>>>> origin/release/1.0.0
});

// Start server
app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});
