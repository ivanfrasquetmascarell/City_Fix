const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const { authMiddleware, soloAdmin } = require('../middleware/auth');
const anunciosController = require('../controllers/anuncios.controller');

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, path.join(__dirname, '../uploads'));
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname);
    cb(null, `noticia-${Date.now()}-${Math.round(Math.random() * 1e9)}${ext}`);
  },
});

const upload = multer({ storage });

router.get('/', anunciosController.listarAnuncios);

router.post('/', 
  authMiddleware, 
  soloAdmin, 
  upload.fields([
    { name: 'portada', maxCount: 1 },
    { name: 'multimedia', maxCount: 10 }
  ]), 
  anunciosController.crearAnuncio
);

router.put('/:id',
  authMiddleware,
  soloAdmin,
  upload.fields([
    { name: 'portada', maxCount: 1 },
    { name: 'multimedia', maxCount: 10 }
  ]),
  anunciosController.actualizarAnuncio
);

router.delete('/:id',
  authMiddleware,
  soloAdmin,
  anunciosController.eliminarAnuncio
);

module.exports = router;
