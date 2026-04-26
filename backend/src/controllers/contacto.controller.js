const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

exports.obtenerContacto = async (req, res) => {
  try {
    // Intentamos obtener el primer registro de la tabla
    let contacto = await prisma.contacto.findFirst();

    // Si no hay ninguno creado todavía, devolvemos uno de prueba (Gandía)
    if (!contacto) {
      contacto = {
        telefono: '+34 962 95 94 00',
        email: 'ajuntament@gandia.org',
        direccion: 'Carrer de la Vila, 1, 46701 Gandia, Valencia',
        horario: 'Lunes a Viernes: 09:00 - 14:00',
        web: 'https://www.gandia.es'
      };
    }

    res.json(contacto);
  } catch (err) {
    console.error('Error al obtener contacto:', err);
    res.status(500).json({ error: 'Error interno del servidor' });
  }
};
