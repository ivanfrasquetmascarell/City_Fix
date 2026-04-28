const prisma = require('../prisma');

// GET /categorias
const listar = async (req, res) => {
  try {
    const categorias = await prisma.categoria.findMany({
      include: {
        _count: {
          select: { incidencias: true }
        }
      }
    });
    res.json(categorias);
  } catch (err) {
    res.status(500).json({ error: 'Error al obtener categorías' });
  }
};

// POST /categorias (solo admin)
const crear = async (req, res) => {
  try {
    const { nombre, icono } = req.body;
    const categoria = await prisma.categoria.create({
      data: { nombre, icono }
    });
    res.status(201).json(categoria);
  } catch (err) {
    res.status(500).json({ error: 'Error al crear categoría' });
  }
};

// PUT /categorias/:id (solo admin)
const actualizar = async (req, res) => {
  try {
    const { nombre, icono } = req.body;
    const categoria = await prisma.categoria.update({
      where: { id: parseInt(req.params.id) },
      data: { nombre, icono }
    });
    res.json(categoria);
  } catch (err) {
    res.status(500).json({ error: 'Error al actualizar categoría' });
  }
};

// DELETE /categorias/:id (solo admin)
const eliminar = async (req, res) => {
  try {
    const id = parseInt(req.params.id);
    
    // Verificar si tiene incidencias asociadas
    const count = await prisma.incidencia.count({ where: { categoriaId: id } });
    if (count > 0) {
      return res.status(400).json({ error: 'No se puede eliminar una categoría que tiene incidencias reportadas' });
    }

    await prisma.categoria.delete({ where: { id } });
    res.json({ mensaje: 'Categoría eliminada' });
  } catch (err) {
    res.status(500).json({ error: 'Error al eliminar categoría' });
  }
};

module.exports = { listar, crear, actualizar, eliminar };
