require('dotenv').config();
const express = require('express');
const cors = require('cors');
const path = require('path');

const authRoutes = require('./routes/auth.routes');
const incidenciasRoutes = require('./routes/incidencias.routes');
const categoriasRoutes = require('./routes/categorias.routes');
const anunciosRoutes = require('./routes/anuncios.routes');
const contactoRoutes = require('./routes/contacto.routes');

const app = express();
const PORT = process.env.PORT || 3000;

// Middlewares globales
app.use(cors());
app.use(express.json());

// Servir imágenes subidas de forma estática con CORS explícito
app.use('/uploads', express.static(path.join(__dirname, 'uploads'), {
  setHeaders: (res) => {
    res.set('Access-Control-Allow-Origin', '*');
  }
}));

// Rutas
app.use('/auth', authRoutes);
app.use('/incidencias', incidenciasRoutes);
app.use('/categorias', categoriasRoutes);
app.use('/anuncios', anunciosRoutes);
app.use('/contacto', contactoRoutes);

// Health check
app.get('/', (req, res) => {
  res.json({ mensaje: 'City Fix API funcionando ✅', version: '1.0.0' });
});

app.listen(PORT, () => {
  console.log(`🚀 Servidor corriendo en http://localhost:${PORT}`);
});
