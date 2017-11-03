const express = require('express')
const app = express()
var env = require('node-env-file');
env('.env');

var message = process.env.MESSAGE;
var port = process.env.PORT;

app.get('/', function (req, res) {
  res.send(message)
})

app.listen(port, function () {
  console.log('Example app listening on port '+port+'!')
})