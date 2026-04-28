const express = require('express');
const router = express.Router();
const { registro, login, me, listarUsuarios, resetearPuntos, cambiarEstadoBloqueo } = require('../controllers/auth.controller');
const { authMiddleware } = require('../middleware/auth');

router.post('/registro', registro);
router.post('/login', login);
router.get('/me', authMiddleware, me);
router.get('/usuarios', authMiddleware, listarUsuarios);
router.put('/usuarios/:id/reset-puntos', authMiddleware, resetearPuntos);
router.put('/usuarios/:id/bloqueo', authMiddleware, cambiarEstadoBloqueo);

module.exports = router;
