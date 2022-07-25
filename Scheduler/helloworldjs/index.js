const axios = require('axios');

exports.helloWorld = (req, res) => {
    //let message = req.query.message || req.body.message || 'Hello World!';
    //res.status(200).send(message);
    axios
  .get('http://34.70.44.232/')
  .then(res => {
    console.log(`statusCode: ${res.status}`);
    console.log(res);
  })
  .catch(error => {
    console.error(error);
  });
  };
  