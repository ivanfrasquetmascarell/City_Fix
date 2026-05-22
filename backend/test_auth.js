const http = require('http');
const https = require('https');

const data = JSON.stringify({
  email: 'Ivanfrasquetmascarell@gmail.com',
  password: '123'
});

const options = {
  hostname: 'cityfix-backend-13xy.onrender.com',
  port: 443,
  path: '/auth/login',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': data.length
  }
};

const req = https.request(options, res => {
  console.log(`statusCode: ${res.statusCode}`);
  let body = '';
  res.on('data', d => {
    body += d;
  });
  res.on('end', () => {
    console.log(body);
  });
});

req.on('error', error => {
  console.error(error);
});

req.write(data);
req.end();
