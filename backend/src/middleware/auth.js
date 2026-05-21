const jwt = require('jsonwebtoken');
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

const authMiddleware = async (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Token no proporcionado' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    const usuarioDB = await prisma.usuario.findUnique({
      where: { id: decoded.id }
    });

    if (!usuarioDB) {
      return res.status(401).json({ error: 'Usuario no encontrado' });
    }

    if (usuarioDB.bloqueado) {
      return res.status(403).json({ error: 'Tu cuenta ha sido bloqueada por el Ayuntamiento.' });
    }

    req.usuario = decoded;
    next();
  } catch (err) {
    return res.status(403).json({ error: 'Token inválido o expirado' });
  }
};

const soloAdmin = (req, res, next) => {
  if (!req.usuario || req.usuario.rol !== 'admin') {
    return res.status(403).json({ error: 'Acceso solo para administradores' });
  }
  next();
};

module.exports = { authMiddleware, soloAdmin };
