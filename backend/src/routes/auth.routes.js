const express = require('express');
const router = express.Router();
const { registro, login, me } = require('../controllers/auth.controller');
const { authMiddleware } = require('../middleware/auth');

router.post('/registro', registro);
router.post('/login', login);
router.get('/me', authMiddleware, me);

module.exports = router;
