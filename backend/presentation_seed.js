const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function main() {
  console.log('🚀 Iniciando script de preparación para la presentación...');

  // 1. Limpieza de Usuarios (excepto admins y Ivan)
  console.log('\n🧹 1. Limpiando usuarios antiguos...');
  const usersToDelete = await prisma.usuario.findMany({
    where: {
      rol: 'ciudadano',
      email: {
        notIn: ['Ivanfrasquetmascarell@gmail.com', 'admin@cityfix.com']
      }
    }
  });
  
  const userIds = usersToDelete.map(u => u.id);
  if (userIds.length > 0) {
    const incsToDelete = await prisma.incidencia.findMany({ where: { usuarioId: { in: userIds } } });
    const incIds = incsToDelete.map(i => i.id);
    if (incIds.length > 0) {
      await prisma.multimedia.deleteMany({ where: { incidenciaId: { in: incIds } } });
      await prisma.incidencia.deleteMany({ where: { usuarioId: { in: userIds } } });
    }
    await prisma.usuario.deleteMany({ where: { id: { in: userIds } } });
    console.log(`✅ Eliminados ${userIds.length} usuarios antiguos.`);
  }

  // 2. Crear 10 ciudadanos de prueba
  console.log('\n👥 2. Creando 10 ciudadanos de prueba...');
  const passwordHash = await bcrypt.hash('123', 10);
  for (let i = 1; i <= 10; i++) {
    await prisma.usuario.create({
      data: {
        nombre: `Ciudadano de Prueba ${i}`,
        email: `ciudadano${i}@cityfix.com`,
        password: passwordHash,
        puntos: Math.floor(Math.random() * 80) + 10,
      }
    });
  }
  console.log(`✅ Creados 10 usuarios nuevos.`);

  // 3. Limpieza de Incidencias de Ivan
  console.log('\n🗑️ 3. Limpiando incidencias rotas de Ivan...');
  const ivan = await prisma.usuario.findUnique({ where: { email: 'Ivanfrasquetmascarell@gmail.com' } });
  if (ivan) {
    const misIncs = await prisma.incidencia.findMany({ where: { usuarioId: ivan.id } });
    const misIncIds = misIncs.map(i => i.id);
    if (misIncIds.length > 0) {
      await prisma.multimedia.deleteMany({ where: { incidenciaId: { in: misIncIds } } });
      await prisma.incidencia.deleteMany({ where: { id: { in: misIncIds } } });
    }
    console.log(`✅ Eliminadas ${misIncIds.length} incidencias rotas.`);
  } else {
    console.log(`⚠️ Usuario Ivan no encontrado.`);
    return;
  }

  // 4. Crear 5 incidencias falsas para Ivan con Unsplash
  console.log('\n📝 4. Creando 5 incidencias HD de prueba...');
  const categorias = await prisma.categoria.findMany();
  
  const incidenciasData = [
    {
      titulo: 'Gran socavón en el asfalto',
      descripcion: 'Hay un bache enorme que daña los bajos de los coches.',
      direccion: 'Av. República Argentina, 45',
      latitud: 38.9666, longitud: -0.1833,
      estado: 'pendiente',
      categoriaId: categorias.find(c => c.nombre === 'Bache')?.id || 1,
      multimedia: ['https://images.unsplash.com/photo-1515162816999-a0c47dc192f7?w=800&q=80']
    },
    {
      titulo: 'Farola apagada o fundida',
      descripcion: 'Esta farola lleva 3 días apagada y la calle está a oscuras.',
      direccion: 'Carrer Major, 12',
      latitud: 38.9675, longitud: -0.1820,
      estado: 'en_curso',
      comentarioAdmin: 'Técnicos notificados, acudiremos mañana.',
      categoriaId: categorias.find(c => c.nombre === 'Farola rota')?.id || 2,
      multimedia: ['https://images.unsplash.com/photo-1588143245468-202c37dbdb30?w=800&q=80']
    },
    {
      titulo: 'Contenedores desbordados',
      descripcion: 'La basura está fuera de los contenedores oliendo muy mal.',
      direccion: 'Plaça del Prado, 2',
      latitud: 38.9680, longitud: -0.1810,
      estado: 'pendiente',
      categoriaId: categorias.find(c => c.nombre === 'Basura')?.id || 3,
      multimedia: ['https://images.unsplash.com/photo-1604187351574-c75ca79f5807?w=800&q=80']
    },
    {
      titulo: 'Pintadas en la fachada pública',
      descripcion: 'Han hecho un graffiti enorme esta noche en el polideportivo.',
      direccion: 'Polideportivo Municipal',
      latitud: 38.9650, longitud: -0.1850,
      estado: 'resuelto',
      comentarioAdmin: 'La brigada de limpieza ya lo ha borrado.',
      categoriaId: categorias.find(c => c.nombre === 'Vandalismo')?.id || 4,
      multimedia: ['https://images.unsplash.com/photo-1548696803-f36bc490d1f4?w=800&q=80']
    },
    {
      titulo: 'Banco roto en el parque',
      descripcion: 'Faltan varias tablas de madera en el asiento, es peligroso.',
      direccion: 'Parque de la Estación',
      latitud: 38.9640, longitud: -0.1860,
      estado: 'en_curso',
      comentarioAdmin: 'Madera encargada a la carpintería municipal.',
      categoriaId: categorias.find(c => c.nombre === 'Mobiliario urbano')?.id || 5,
      multimedia: ['https://images.unsplash.com/photo-1498064619985-5eb423cb118a?w=800&q=80']
    }
  ];

  for (const inc of incidenciasData) {
    await prisma.incidencia.create({
      data: {
        titulo: inc.titulo,
        descripcion: inc.descripcion,
        direccion: inc.direccion,
        latitud: inc.latitud,
        longitud: inc.longitud,
        estado: inc.estado,
        comentarioAdmin: inc.comentarioAdmin,
        usuarioId: ivan.id,
        categoriaId: inc.categoriaId,
        multimedia: {
          create: inc.multimedia.map(url => ({
            url,
            tipo: 'IMAGEN'
          }))
        }
      }
    });
  }
  console.log(`✅ Creadas 5 incidencias falsas.`);

  // 5. Limpieza y Creación de Anuncios
  console.log('\n📰 5. Limpiando y creando anuncios...');
  await prisma.multimedia.deleteMany({ where: { anuncioId: { not: null } } });
  await prisma.anuncio.deleteMany({});

  const anunciosData = [
    {
      titulo: 'Obras en la Plaza Mayor',
      descripcion: 'A partir del lunes, la Plaza Mayor permanecerá cerrada por reformas de alcantarillado.',
      imageUrl: 'https://images.unsplash.com/photo-1503387762-592deb58ef4e?w=800&q=80',
      links: JSON.stringify([{ titulo: 'Plano de desvíos', url: 'https://gandia.es/desvios' }])
    },
    {
      titulo: 'Fiestas Locales 2026',
      descripcion: 'Consulta toda la programación de nuestras fiestas patronales que arrancan este fin de semana.',
      imageUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=800&q=80',
      links: JSON.stringify([{ titulo: 'Ver programa completo', url: 'https://gandia.es/fiestas' }])
    },
    {
      titulo: 'Nueva línea de autobús',
      descripcion: 'Inauguramos una nueva ruta que conectará el centro con el polígono industrial.',
      imageUrl: 'https://images.unsplash.com/photo-1464219222984-216ebffaaf85?w=800&q=80',
      links: JSON.stringify([])
    },
    {
      titulo: 'Ayudas a emprendedores',
      descripcion: 'Abierto el plazo para solicitar las nuevas subvenciones municipales para nuevos negocios.',
      imageUrl: 'https://images.unsplash.com/photo-1554224155-6726b3ff858f?w=800&q=80',
      links: JSON.stringify([{ titulo: 'Sede Electrónica', url: 'https://sede.gandia.es' }])
    },
    {
      titulo: 'Campaña de reciclaje',
      descripcion: 'Recuerda que los envases de plástico van al contenedor amarillo. ¡Cuidemos nuestra ciudad!',
      imageUrl: 'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?w=800&q=80',
      links: JSON.stringify([])
    }
  ];

  for (const an of anunciosData) {
    await prisma.anuncio.create({
      data: {
        titulo: an.titulo,
        descripcion: an.descripcion,
        imageUrl: an.imageUrl,
        links: an.links
      }
    });
  }
  console.log(`✅ Creados 5 anuncios realistas.`);

  console.log('\n🎉 SCRIPT COMPLETADO CON ÉXITO.');
}

main()
  .catch((e) => {
    console.error('Error fatal:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
