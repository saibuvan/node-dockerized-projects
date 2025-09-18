const express = require('express')
const app = express()
const port = 3000

app.get('/', (req, res) => {
  res.send('my node js project Buvanesh DevOps yess boss!')
})

app.listen(3000, '0.0.0.0', () => {
  console.log('Server running on port 3000');
});

