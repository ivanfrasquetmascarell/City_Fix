const express = require('express');
const router = express.Router();
const { obtenerContacto, actualizarContacto } = require('../controllers/contacto.controller');
const { authMiddleware } = require('../middleware/auth');

router.get('/', obtenerContacto);
router.put('/', authMiddleware, actualizarContacto);

module.exports = router;
