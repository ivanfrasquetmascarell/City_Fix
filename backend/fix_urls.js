const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function fix() {
  // Update Farola
  await prisma.multimedia.updateMany({
    where: { url: 'https://images.unsplash.com/photo-1588143245468-202c37dbdb30?w=800&q=80' },
    data: { url: 'https://loremflickr.com/800/600/streetlight' }
  });
  
  // Update Vandalismo
  await prisma.multimedia.updateMany({
    where: { url: 'https://images.unsplash.com/photo-1548696803-f36bc490d1f4?w=800&q=80' },
    data: { url: 'https://loremflickr.com/800/600/graffiti' }
  });

  // Update Mobiliario
  await prisma.multimedia.updateMany({
    where: { url: 'https://images.unsplash.com/photo-1498064619985-5eb423cb118a?w=800&q=80' },
    data: { url: 'https://loremflickr.com/800/600/bench' }
  });

  console.log('✅ URLs actualizadas con éxito!');
}

fix()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
