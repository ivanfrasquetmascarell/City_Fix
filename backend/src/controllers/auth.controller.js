const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const prisma = require('../prisma');

// POST /auth/registro
const registro = async (req, res) => {
  const { nombre, email, password } = req.body;

  if (!nombre || !email || !password) {
    return res.status(400).json({ error: 'Todos los campos son obligatorios' });
  }

  try {
    const existente = await prisma.usuario.findUnique({ where: { email } });
    if (existente) {
      return res.status(409).json({ error: 'El email ya está registrado' });
    }

    const hash = await bcrypt.hash(password, 10);
    const usuario = await prisma.usuario.create({
      data: { nombre, email, password: hash },
    });

    const token = jwt.sign(
      { id: usuario.id, rol: usuario.rol },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.status(201).json({
      token,
      usuario: { id: usuario.id, nombre: usuario.nombre, email: usuario.email, rol: usuario.rol, puntos: usuario.puntos },
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
};

// POST /auth/login
const login = async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: 'Email y contraseña son obligatorios' });
  }

  try {
    const usuario = await prisma.usuario.findUnique({ where: { email } });
    if (!usuario) {
      return res.status(401).json({ error: 'Credenciales incorrectas' });
    }

    const esValido = await bcrypt.compare(password, usuario.password);
    if (!esValido) return res.status(401).json({ error: 'Credenciales inválidas' });

    if (usuario.bloqueado) {
      return res.status(403).json({ error: 'Tu cuenta ha sido suspendida por el ayuntamiento.' });
    }

    const token = jwt.sign(
      { id: usuario.id, rol: usuario.rol },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({
      token,
      usuario: { id: usuario.id, nombre: usuario.nombre, email: usuario.email, rol: usuario.rol, puntos: usuario.puntos },
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
};

// GET /auth/me
const me = async (req, res) => {
  try {
    const usuario = await prisma.usuario.findUnique({
      where: { id: req.usuario.id },
      select: { id: true, nombre: true, email: true, rol: true, puntos: true, createdAt: true },
    });
    res.json(usuario);
  } catch (err) {
    res.status(500).json({ error: 'Error interno del servidor' });
  }
};

const listarUsuarios = async (req, res) => {
  try {
    const usuarios = await prisma.usuario.findMany({
      where: { rol: 'ciudadano' },
      orderBy: { puntos: 'desc' },
      select: {
        id: true,
        nombre: true,
        email: true,
        puntos: true,
        bloqueado: true,
        rol: true,
        createdAt: true,
        _count: {
          select: { incidencias: true }
        }
      }
    });
    res.json(usuarios);
  } catch (err) {
    res.status(500).json({ error: 'Error al obtener usuarios' });
  }
};

const resetearPuntos = async (req, res) => {
  try {
    await prisma.usuario.update({
      where: { id: parseInt(req.params.id) },
      data: { puntos: 0 }
    });
    res.json({ mensaje: 'Puntos reseteados' });
  } catch (err) {
    res.status(500).json({ error: 'Error al resetear puntos' });
  }
};

const cambiarEstadoBloqueo = async (req, res) => {
  try {
    const { bloqueado } = req.body;
    await prisma.usuario.update({
      where: { id: parseInt(req.params.id) },
      data: { bloqueado }
    });
    res.json({ mensaje: bloqueado ? 'Usuario bloqueado' : 'Usuario desbloqueado' });
  } catch (err) {
    res.status(500).json({ error: 'Error al cambiar estado de bloqueo' });
  }
};

module.exports = { registro, login, me, listarUsuarios, resetearPuntos, cambiarEstadoBloqueo };
