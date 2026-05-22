const https = require('https');

const urls = [
  'https://images.unsplash.com/photo-1515162816999-a0c47dc192f7?w=800&q=80',
  'https://images.unsplash.com/photo-1588143245468-202c37dbdb30?w=800&q=80',
  'https://images.unsplash.com/photo-1604187351574-c75ca79f5807?w=800&q=80',
  'https://images.unsplash.com/photo-1548696803-f36bc490d1f4?w=800&q=80',
  'https://images.unsplash.com/photo-1498064619985-5eb423cb118a?w=800&q=80'
];

urls.forEach(url => {
  https.get(url, res => {
    console.log(`${res.statusCode} -> ${url}`);
  }).on('error', e => {
    console.error(`Error: ${e.message}`);
  });
});
