const prisma = require('../prisma');

// GET /incidencias
const listar = async (req, res) => {
  try {
    const { estado, categoriaId } = req.query;
    const where = {};

    // Ciudadano solo ve las suyas; admin ve todas
    if (req.usuario.rol === 'ciudadano') {
      where.usuarioId = req.usuario.id;
    }
    if (estado) where.estado = estado;
    if (categoriaId) where.categoriaId = parseInt(categoriaId);

    const incidencias = await prisma.incidencia.findMany({
      where,
      include: {
        categoria: true,
        usuario: { select: { id: true, nombre: true, email: true, rol: true } },
        multimedia: true,
      },
      orderBy: { createdAt: 'desc' },
    });

    res.json(incidencias);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
};

// GET /incidencias/:id
const obtener = async (req, res) => {
  try {
    const incidencia = await prisma.incidencia.findUnique({
      where: { id: parseInt(req.params.id) },
      include: {
        categoria: true,
        usuario: { select: { id: true, nombre: true, email: true, rol: true } },
        multimedia: true,
      },
    });

    if (!incidencia) return res.status(404).json({ error: 'Incidencia no encontrada' });

    // Ciudadano solo puede ver las suyas
    if (req.usuario.rol === 'ciudadano' && incidencia.usuarioId !== req.usuario.id) {
      return res.status(403).json({ error: 'Sin permisos' });
    }

    res.json(incidencia);
  } catch (err) {
    res.status(500).json({ error: 'Error interno del servidor' });
  }
};

// POST /incidencias
const crear = async (req, res) => {
  const { titulo, descripcion, latitud, longitud, categoriaId } = req.body;

  if (!titulo || !descripcion || !latitud || !longitud || !categoriaId) {
    return res.status(400).json({ error: 'Faltan campos obligatorios' });
  }

  try {
    // Procesar archivos
    const multimediaData = [];

    if (req.files) {
      if (req.files.imagenes) {
        req.files.imagenes.forEach((file) => {
          multimediaData.push({
            url: `/uploads/${file.filename}`,
            tipo: 'IMAGEN',
          });
        });
      }
      if (req.files.video) {
        req.files.video.forEach((file) => {
          multimediaData.push({
            url: `/uploads/${file.filename}`,
            tipo: 'VIDEO',
          });
        });
      }
    }

    const incidencia = await prisma.incidencia.create({
      data: {
        titulo,
        descripcion,
        latitud: parseFloat(latitud),
        longitud: parseFloat(longitud),
        categoriaId: parseInt(categoriaId),
        usuarioId: req.usuario.id,
        multimedia: {
          create: multimediaData,
        },
      },
      include: {
        categoria: true,
        multimedia: true,
      },
    });

    res.status(201).json(incidencia);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
};

// PUT /incidencias/:id  (solo admin)
const actualizar = async (req, res) => {
  const { estado, comentarioAdmin } = req.body;

  try {
    const incidencia = await prisma.incidencia.update({
      where: { id: parseInt(req.params.id) },
      data: {
        ...(estado && { estado }),
        ...(comentarioAdmin !== undefined && { comentarioAdmin }),
      },
      include: { categoria: true, usuario: { select: { id: true, nombre: true } } },
    });

    res.json(incidencia);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
};

// DELETE /incidencias/:id
const eliminar = async (req, res) => {
  try {
    const id = parseInt(req.params.id);
    const incidencia = await prisma.incidencia.findUnique({ where: { id } });

    if (!incidencia) {
      return res.status(404).json({ error: 'Incidencia no encontrada' });
    }

    // Lógica de permisos
    if (req.usuario.rol === 'ciudadano') {
      // 1. Verificar propiedad
      if (incidencia.usuarioId !== req.usuario.id) {
        return res.status(403).json({ error: 'No tienes permisos para borrar esta incidencia' });
      }
      // 2. Verificar estado (Solo se borra si está pendiente)
      if (incidencia.estado !== 'pendiente') {
        return res.status(400).json({ error: 'No puedes borrar una incidencia que ya está en curso o resuelta' });
      }
    }

    await prisma.incidencia.delete({ where: { id } });
    res.json({ mensaje: 'Incidencia eliminada con éxito' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
};

// GET /incidencias/stats  (solo admin)
const stats = async (req, res) => {
  try {
    const [total, pendientes, enCurso, resueltas] = await Promise.all([
      prisma.incidencia.count(),
      prisma.incidencia.count({ where: { estado: 'pendiente' } }),
      prisma.incidencia.count({ where: { estado: 'en_curso' } }),
      prisma.incidencia.count({ where: { estado: 'resuelto' } }),
    ]);

    const porCategoria = await prisma.incidencia.groupBy({
      by: ['categoriaId'],
      _count: { id: true },
    });

    res.json({ total, pendientes, enCurso, resueltas, porCategoria });
  } catch (err) {
    res.status(500).json({ error: 'Error interno del servidor' });
  }
};

module.exports = { listar, obtener, crear, actualizar, eliminar, stats };
