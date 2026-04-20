const express = require('express');
const router = express.Router();
const { authMiddleware } = require('../middleware/auth');
const { listar } = require('../controllers/categorias.controller');

router.get('/', authMiddleware, listar);

module.exports = router;
