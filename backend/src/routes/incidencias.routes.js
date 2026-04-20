const express = require('express');
const multer = require('multer');
const path = require('path');
const router = express.Router();
const { authMiddleware, soloAdmin } = require('../middleware/auth');
const {
  listar, obtener, crear, actualizar, eliminar, stats,
} = require('../controllers/incidencias.controller');

// Configuración de Multer para subida de imágenes
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, path.join(__dirname, '../uploads'));
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname);
    cb(null, `${Date.now()}-${Math.round(Math.random() * 1e9)}${ext}`);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 100 * 1024 * 1024 }, // 100MB
  fileFilter: (req, file, cb) => {
    const allowed = /jpeg|jpg|png|webp|mp4|mov/;
    const valid = allowed.test(path.extname(file.originalname).toLowerCase());
    cb(null, valid);
  },
});

router.get('/stats', authMiddleware, soloAdmin, stats);
router.get('/', authMiddleware, listar);
router.get('/:id', authMiddleware, obtener);
router.post('/', authMiddleware, upload.fields([
  { name: 'imagenes', maxCount: 3 },
  { name: 'video', maxCount: 1 }
]), crear);
router.put('/:id', authMiddleware, soloAdmin, actualizar);
router.delete('/:id', authMiddleware, eliminar);

module.exports = router;
