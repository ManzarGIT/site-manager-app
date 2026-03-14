const prisma = require('../config/db');
const { encrypt, decrypt } = require('../utils/encryption');

exports.createTransaction = async (req, res) => {
    try {
        const { workerId, amount, type, notes } = req.body;

        let encryptedNotes = null;
        if (notes) {
            encryptedNotes = encrypt(notes);
        }

        const transaction = await prisma.transaction.create({
            data: {
                workerId,
                amount: parseFloat(amount),
                type, // ADVANCE, WAGE, PAYMENT
                encryptedNotes,
                createdBy: req.user.id
            }
        });

        res.status(201).json({
            ...transaction,
            notes: notes // Return decrypted to the creator for immediate display
        });
    } catch (error) {
        console.error('Create Transaction Error:', error);
        res.status(500).json({ message: 'Error creating transaction' });
    }
};

exports.getWorkerTransactions = async (req, res) => {
    try {
        const { workerId } = req.params;

        const transactions = await prisma.transaction.findMany({
            where: { workerId },
            orderBy: { date: 'desc' }
        });

        // Decrypt notes if user is ADMIN or the one who created it (or accountant)
        const canSeeNotes = ['ADMIN', 'ACCOUNTANT', 'MANAGER'].includes(req.user.role);

        const decryptedTransactions = transactions.map(t => {
            let notes = null;
            if (canSeeNotes && t.encryptedNotes) {
                try {
                    notes = decrypt(t.encryptedNotes);
                } catch (e) {
                    notes = '[Encrypted]';
                }
            } else if (t.encryptedNotes) {
                notes = '[Hidden - Insufficient Permissions]';
            }

            const { encryptedNotes, ...rest } = t;
            return { ...rest, notes };
        });

        res.json(decryptedTransactions);
    } catch (error) {
        console.error('Get Transactions Error:', error);
        res.status(500).json({ message: 'Error getting transactions' });
    }
};
