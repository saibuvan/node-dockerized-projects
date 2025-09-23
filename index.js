const express = require('express')
const app = express()
const port = 3000

app.get('/', (req, res) => {
  res.send('my devops buvanesh process!')
})

app.listen(port, () => {
  console.log(`Example app listening on port ${port}`)
})

