const bcrypt = require('bcryptjs');
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
    const hash = await bcrypt.hash('admin123', 10);

    const user = await prisma.user.upsert({
        where: { email: 'admin@sitemanager.com' },
        update: {},
        create: {
            name: 'Super Admin',
            email: 'admin@sitemanager.com',
            password_hash: hash,
            role: 'ADMIN',
        },
    });

    console.log('✅ Admin user ready:');
    console.log('Email: admin@sitemanager.com');
    console.log('Password: admin123');
}

main()
    .then(async () => {
        await prisma.$disconnect();
    })
    .catch(async (e) => {
        console.error(e);
        await prisma.$disconnect();
        process.exit(1);
    });
