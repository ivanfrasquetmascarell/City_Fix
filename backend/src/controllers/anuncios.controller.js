const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const { uploadStream } = require('../utils/cloudinary');

exports.listarAnuncios = async (req, res) => {
  try {
    const anuncios = await prisma.anuncio.findMany({
      include: { multimedia: true },
      orderBy: { createdAt: 'desc' },
    });
    res.json(anuncios);
  } catch (err) {
    console.error('ERROR listarAnuncios:', err);
    res.status(500).json({ error: 'Error interno' });
  }
};

exports.crearAnuncio = async (req, res) => {
  try {
    const { titulo, descripcion, links } = req.body;
    const portadaFile = req.files['portada'] ? req.files['portada'][0] : null;
    const extraFiles = req.files['multimedia'] || [];
    
    let imageUrl = null;
    if (portadaFile) {
      const result = await uploadStream(portadaFile.buffer, 'image', 'cityfix/anuncios');
      imageUrl = result.secure_url;
    }

    const multimediaData = [];
    for (const file of extraFiles) {
      const isVideo = file.mimetype.startsWith('video') || 
                      ['.mp4', '.mov', '.avi', '.webm'].some(ext => file.originalname.toLowerCase().endsWith(ext));
      
      const result = await uploadStream(file.buffer, isVideo ? 'video' : 'image', 'cityfix/anuncios');
      
      multimediaData.push({
        url: result.secure_url,
        tipo: isVideo ? 'VIDEO' : 'IMAGEN'
      });
    }

    let linksArray = [];
    if (links) {
      linksArray = typeof links === 'string' ? JSON.parse(links) : links;
    }

    const anuncio = await prisma.anuncio.create({
      data: {
        titulo,
        descripcion: descripcion || '',
        imageUrl,
        links: linksArray,
        multimedia: {
          create: multimediaData
        }
      },
      include: { multimedia: true }
    });

    res.status(201).json(anuncio);
  } catch (err) {
    console.error('ERROR crearAnuncio:', err);
    res.status(500).json({ error: 'Error al crear noticia' });
  }
};

exports.actualizarAnuncio = async (req, res) => {
  try {
    const { id } = req.params;
    const { titulo, descripcion, links, multimediaIdsToDelete } = req.body;
    const portadaFile = req.files['portada'] ? req.files['portada'][0] : null;
    const extraFiles = req.files['multimedia'] || [];

    if (multimediaIdsToDelete) {
      const ids = typeof multimediaIdsToDelete === 'string' ? JSON.parse(multimediaIdsToDelete) : multimediaIdsToDelete;
      if (ids.length > 0) {
        await prisma.multimedia.deleteMany({ where: { id: { in: ids.map(id => parseInt(id)) } } });
      }
    }

    let data = { titulo, descripcion };
    
    if (portadaFile) {
      const result = await uploadStream(portadaFile.buffer, 'image', 'cityfix/anuncios');
      data.imageUrl = result.secure_url;
    }
    
    if (links) data.links = typeof links === 'string' ? JSON.parse(links) : links;

    if (extraFiles.length > 0) {
      const multimediaData = [];
      for (const file of extraFiles) {
        const isVideo = file.mimetype.startsWith('video') || 
                        ['.mp4', '.mov', '.avi', '.webm'].some(ext => file.originalname.toLowerCase().endsWith(ext));
        const result = await uploadStream(file.buffer, isVideo ? 'video' : 'image', 'cityfix/anuncios');
        multimediaData.push({
          url: result.secure_url,
          tipo: isVideo ? 'VIDEO' : 'IMAGEN'
        });
      }
      
      data.multimedia = {
        create: multimediaData
      };
    }

    const anuncio = await prisma.anuncio.update({
      where: { id: parseInt(id) },
      data,
      include: { multimedia: true }
    });

    res.json(anuncio);
  } catch (err) {
    console.error('ERROR actualizarAnuncio:', err);
    res.status(500).json({ error: 'Error al actualizar' });
  }
};

exports.eliminarAnuncio = async (req, res) => {
  try {
    const { id } = req.params;
    await prisma.anuncio.delete({ where: { id: parseInt(id) } });
    res.json({ message: 'Anuncio eliminado' });
  } catch (err) {
    console.error('ERROR eliminarAnuncio:', err);
    res.status(500).json({ error: 'Error al eliminar' });
  }
};
