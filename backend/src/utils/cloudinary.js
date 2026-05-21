const cloudinary = require('cloudinary').v2;
require('dotenv').config();

// Configuración con las variables del entorno
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

/**
 * Sube un buffer (archivo en memoria) directamente a Cloudinary.
 * @param {Buffer} buffer - El archivo en crudo.
 * @param {string} resourceType - 'image' o 'video'
 * @param {string} folder - Carpeta de destino en Cloudinary ('incidencias' o 'anuncios')
 * @returns {Promise<Object>} El resultado de la subida con la secure_url.
 */
const uploadStream = (buffer, resourceType = 'auto', folder = 'cityfix') => {
  return new Promise((resolve, reject) => {
    const uploadStream = cloudinary.uploader.upload_stream(
      {
        resource_type: resourceType,
        folder: folder,
      },
      (error, result) => {
        if (error) return reject(error);
        resolve(result);
      }
    );

    // Escribimos el buffer en el stream de Cloudinary
    uploadStream.end(buffer);
  });
};

module.exports = {
  cloudinary,
  uploadStream,
};
