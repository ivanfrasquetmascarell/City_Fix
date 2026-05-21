const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const { authMiddleware, soloAdmin } = require('../middleware/auth');
const anunciosController = require('../controllers/anuncios.controller');

const storage = multer.memoryStorage();

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
