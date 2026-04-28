const express = require('express');
const router = express.Router();
const { listar, crear, actualizar, eliminar } = require('../controllers/categorias.controller');
const { authMiddleware } = require('../middleware/auth');

router.get('/', listar);
router.post('/', authMiddleware, crear);
router.put('/:id', authMiddleware, actualizar);
router.delete('/:id', authMiddleware, eliminar);

module.exports = router;
