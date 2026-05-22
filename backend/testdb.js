const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
prisma.incidencia.findMany({ include: { multimedia: true, categoria: true, usuario: true } })
  .then(res => console.log(JSON.stringify(res, null, 2)))
  .catch(console.error)
  .finally(() => prisma.$disconnect());
