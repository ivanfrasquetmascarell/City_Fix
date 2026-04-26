const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const incidencias = await prisma.incidencia.findMany({
    include: {
      categoria: true,
      usuario: { select: { id: true, nombre: true, email: true } },
    }
  });
  console.log('--- Listado de Incidencias en DB ---');
  console.log(JSON.stringify(incidencias, null, 2));
}

main()
  .catch(e => console.error(e))
  .finally(async () => {
    await prisma.$disconnect();
  });
