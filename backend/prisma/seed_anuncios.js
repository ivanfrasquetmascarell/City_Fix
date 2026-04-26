const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Sembrando noticias de prueba...');

  const noticias = [
    {
      titulo: 'Nueva iluminación LED en el Paseo Germanias',
      descripcion: 'El ayuntamiento ha completado la sustitución de las antiguas farolas por un sistema LED de alta eficiencia, mejorando la visibilidad y reduciendo el consumo energético en un 40%.',
      imageUrl: 'https://images.unsplash.com/photo-1510444335241-9d58178a3fba?q=80&w=1772&auto=format&fit=crop',
    },
    {
      titulo: 'Finalizadas las obras de reasfaltado en Calle Mayor',
      descripcion: 'Tras dos semanas de intensos trabajos, la Calle Mayor vuelve a estar abierta al tráfico con un pavimento renovado y pasos de cebra inteligentes.',
      imageUrl: 'https://images.unsplash.com/photo-1515162816999-a0c47dc192f7?q=80&w=2070&auto=format&fit=crop',
    },
    {
      titulo: 'Gandía recibe el premio a Ciudad Sostenible 2026',
      descripcion: 'Gracias a vuestra colaboración a través de City Fix, hemos sido reconocidos como una de las ciudades que más rápido soluciona sus incidencias urbanas.',
      imageUrl: 'https://images.unsplash.com/photo-1449824913935-59a10b8d2000?q=80&w=2070&auto=format&fit=crop',
    }
  ];

  for (const n of noticias) {
    await prisma.anuncio.create({ data: n });
  }

  console.log('✅ ¡Noticias sembradas con éxito!');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
