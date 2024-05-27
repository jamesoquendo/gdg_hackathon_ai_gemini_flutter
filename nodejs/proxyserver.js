const express = require('express');
const request = require('request');
const cors = require('cors');
const app = express();

app.use(cors());

app.get('/proxy', (req, res) => {
  const url = 'https://videointelligence.googleapis.com/v1/your-operation-id?alt=json';
  request(url, (error, response, body) => {
    if (error) {
      res.status(500).send(error);
      return;
    }
    res.send(body);
  });
});

const PORT = 3000;
app.listen(PORT, () => {
  console.log(`Proxy server running at http://localhost:${PORT}`);
});
