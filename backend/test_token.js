const jwt = require('jsonwebtoken');
const https = require('https');

// Token para usuarioId 3 con el secreto local
const token = jwt.sign({ id: 3, rol: 'ciudadano' }, process.env.JWT_SECRET || 'cityfix_secret_super_seguro_2024', { expiresIn: '7d' });

const options = {
  hostname: 'cityfix-backend-13xy.onrender.com',
  port: 443,
  path: '/incidencias',
  method: 'GET',
  headers: {
    'Authorization': `Bearer ${token}`
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

req.end();
