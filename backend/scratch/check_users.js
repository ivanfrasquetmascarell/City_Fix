const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const users = await prisma.usuario.findMany();
  console.log('Usuarios en la base de datos:');
  users.forEach(u => {
    console.log(`- Email: ${u.email}, Nombre: ${u.nombre}, Rol: ${u.rol}`);
  });
}

main()
  .catch(e => console.error(e))
  .finally(async () => {
    await prisma.$disconnect();
  });
