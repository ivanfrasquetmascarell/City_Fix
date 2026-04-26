const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');
const prisma = new PrismaClient();

async function main() {
  // Categorías base
  const categorias = [
    { nombre: 'Bache', icono: '🕳️' },
    { nombre: 'Farola rota', icono: '💡' },
    { nombre: 'Basura', icono: '🗑️' },
    { nombre: 'Vandalismo', icono: '🖌️' },
    { nombre: 'Mobiliario urbano', icono: '🪑' },
    { nombre: 'Inundación', icono: '💧' },
    { nombre: 'Otro', icono: '📌' },
  ];

  for (const cat of categorias) {
    await prisma.categoria.upsert({
      where: { nombre: cat.nombre },
      update: {},
      create: cat,
    });
  }
  console.log('✅ Categorías creadas');

  // Admin del ayuntamiento
  const hash = await bcrypt.hash('admin1234', 10);
  await prisma.usuario.upsert({
    where: { email: 'admin@ayuntamiento.es' },
    update: {},
    create: {
      nombre: 'Administrador',
      email: 'admin@ayuntamiento.es',
      password: hash,
      rol: 'admin',
    },
  });
  console.log('✅ Admin creado: admin@ayuntamiento.es / admin1234');

  // Usuario ciudadano de prueba
  const hashCiudadano = await bcrypt.hash('ciudadano1234', 10);
  await prisma.usuario.upsert({
    where: { email: 'ivan@cityfix.es' },
    update: {},
    create: {
      nombre: 'Ivan Frasquet',
      email: 'ivan@cityfix.es',
      password: hashCiudadano,
      rol: 'ciudadano',
    },
  });
  console.log('✅ Ciudadano de prueba creado: ivan@cityfix.es / ciudadano1234');
}

main()
  .catch((e) => { console.error(e); process.exit(1); })
  .finally(() => prisma.$disconnect());
