const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const path = require('path');
const fs = require('fs');
const ffmpegPath = require('@ffmpeg-installer/ffmpeg').path;
const ffmpeg = require('fluent-ffmpeg');
ffmpeg.setFfmpegPath(ffmpegPath);

// Función auxiliar para generar miniatura
const generarThumbnail = (videoPath, filename) => {
  return new Promise((resolve, reject) => {
    const thumbName = filename.replace(/\.[^/.]+$/, "") + "-thumb.jpg";
    const thumbPath = path.join(__dirname, '../uploads');
    
    ffmpeg(videoPath)
      .screenshots({
        timestamps: ['00:00:01'],
        filename: thumbName,
        folder: thumbPath,
        size: '320x?'
      })
      .on('end', () => {
        console.log('Thumbnail generado:', thumbName);
        resolve(thumbName);
      })
      .on('error', (err) => {
        console.error('Error generando thumbnail:', err);
        resolve(null); // No bloqueamos si falla
      });
  });
};

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
    const host = req.get('host');
    const imageUrl = portadaFile ? `${req.protocol}://${host}/uploads/${portadaFile.filename}` : null;

    // Generar thumbnails para vídeos
    for (const file of extraFiles) {
      const isVideo = file.mimetype.startsWith('video') || 
                      ['.mp4', '.mov', '.avi', '.webm'].some(ext => file.originalname.toLowerCase().endsWith(ext));
      if (isVideo) {
        await generarThumbnail(file.path, file.filename);
      }
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
          create: extraFiles.map(file => {
            const isVideo = file.mimetype.startsWith('video') || 
                            ['.mp4', '.mov', '.avi', '.webm'].some(ext => file.originalname.toLowerCase().endsWith(ext));
            return {
              url: `${req.protocol}://${host}/uploads/${file.filename}`,
              tipo: isVideo ? 'VIDEO' : 'IMAGEN'
            };
          })
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
    const host = req.get('host');

    if (multimediaIdsToDelete) {
      const ids = typeof multimediaIdsToDelete === 'string' ? JSON.parse(multimediaIdsToDelete) : multimediaIdsToDelete;
      if (ids.length > 0) {
        await prisma.multimedia.deleteMany({ where: { id: { in: ids.map(id => parseInt(id)) } } });
      }
    }

    // Generar thumbnails para nuevos vídeos
    for (const file of extraFiles) {
      const isVideo = file.mimetype.startsWith('video') || 
                      ['.mp4', '.mov', '.avi', '.webm'].some(ext => file.originalname.toLowerCase().endsWith(ext));
      if (isVideo) {
        await generarThumbnail(file.path, file.filename);
      }
    }

    let data = { titulo, descripcion };
    if (portadaFile) data.imageUrl = `${req.protocol}://${host}/uploads/${portadaFile.filename}`;
    if (links) data.links = typeof links === 'string' ? JSON.parse(links) : links;

    if (extraFiles.length > 0) {
      data.multimedia = {
        create: extraFiles.map(file => {
          const isVideo = file.mimetype.startsWith('video') || 
                          ['.mp4', '.mov', '.avi', '.webm'].some(ext => file.originalname.toLowerCase().endsWith(ext));
          return {
            url: `${req.protocol}://${host}/uploads/${file.filename}`,
            tipo: isVideo ? 'VIDEO' : 'IMAGEN'
          };
        })
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
