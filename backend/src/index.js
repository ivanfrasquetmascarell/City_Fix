require('dotenv').config();
const express = require('express');
const cors = require('cors');
const path = require('path');

const authRoutes = require('./routes/auth.routes');
const incidenciasRoutes = require('./routes/incidencias.routes');
const categoriasRoutes = require('./routes/categorias.routes');

const app = express();
const PORT = process.env.PORT || 3000;

// Middlewares globales
app.use(cors());
app.use(express.json());

// Servir imágenes subidas de forma estática
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Rutas
app.use('/auth', authRoutes);
app.use('/incidencias', incidenciasRoutes);
app.use('/categorias', categoriasRoutes);

// Health check
app.get('/', (req, res) => {
  res.json({ mensaje: 'City Fix API funcionando ✅', version: '1.0.0' });
});

app.listen(PORT, () => {
  console.log(`🚀 Servidor corriendo en http://localhost:${PORT}`);
});
