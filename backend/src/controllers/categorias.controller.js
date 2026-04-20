const prisma = require('../prisma');

// GET /categorias
const listar = async (req, res) => {
  try {
    const categorias = await prisma.categoria.findMany({ orderBy: { nombre: 'asc' } });
    res.json(categorias);
  } catch (err) {
    res.status(500).json({ error: 'Error interno del servidor' });
  }
};

module.exports = { listar };
