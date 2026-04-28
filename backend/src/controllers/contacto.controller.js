const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

exports.obtenerContacto = async (req, res) => {
  try {
    const contacto = await prisma.contacto.findFirst();
    if (!contacto) {
      return res.json({
        telefono: '+34 962 95 94 00',
        email: 'ajuntament@gandia.org',
        direccion: 'Carrer de la Vila, 1, 46701 Gandia, Valencia',
        horario: 'Lunes a Viernes: 09:00 - 14:00',
        web: 'https://www.gandia.es'
      });
    }
    res.json(contacto);
  } catch (err) {
    res.status(500).json({ error: 'Error interno del servidor' });
  }
};

exports.actualizarContacto = async (req, res) => {
  try {
    const { telefono, email, direccion, horario, web } = req.body;
    
    // Buscamos si existe ya un registro
    const existe = await prisma.contacto.findFirst();

    let contacto;
    if (existe) {
      // Si existe, lo actualizamos
      contacto = await prisma.contacto.update({
        where: { id: existe.id },
        data: { telefono, email, direccion, horario, web }
      });
    } else {
      // Si no existe, lo creamos por primera vez
      contacto = await prisma.contacto.create({
        data: { telefono, email, direccion, horario, web }
      });
    }

    res.json(contacto);
  } catch (err) {
    res.status(500).json({ error: 'Error al actualizar contacto' });
  }
};
