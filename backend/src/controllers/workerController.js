const prisma = require('../config/db');

exports.createWorker = async (req, res) => {
    try {
        const {
            name, phone, siteId, paymentType,
            // DAILY_WAGE
            wageRate,
            // CONTRACT
            contractDescription, contractAmount,
            // PIECE_RATE
            taskDescription, unitDescription, ratePerUnit
        } = req.body;

        const site = await prisma.site.findUnique({ where: { id: siteId } });
        if (!site) return res.status(404).json({ message: 'Site not found' });

        if (req.user.role !== 'ADMIN' && site.managerId !== req.user.id) {
            return res.status(403).json({ message: 'Forbidden' });
        }

        const worker = await prisma.worker.create({
            data: {
                name,
                phone,
                siteId,
                paymentType: paymentType || 'DAILY_WAGE',
                wageRate: paymentType === 'DAILY_WAGE' ? parseFloat(wageRate || 0) : 0,
                contractDescription: contractDescription || null,
                contractAmount: contractAmount ? parseFloat(contractAmount) : null,
                taskDescription: taskDescription || null,
                unitDescription: unitDescription || null,
                ratePerUnit: ratePerUnit ? parseFloat(ratePerUnit) : null,
            }
        });

        res.status(201).json(worker);
    } catch (error) {
        console.error('Create Worker Error:', error);
        res.status(500).json({ message: 'Error creating worker' });
    }
};

exports.getWorkers = async (req, res) => {
    try {
        const { siteId } = req.query;
        let whereCondition = { isActive: true };
        if (siteId) whereCondition.siteId = siteId;

        const workers = await prisma.worker.findMany({
            where: whereCondition,
            include: {
                _count: { select: { attendances: true, workProgress: true } }
            }
        });
        res.json(workers);
    } catch (error) {
        console.error('Get Workers Error:', error);
        res.status(500).json({ message: 'Error getting workers' });
    }
};

exports.updateWorker = async (req, res) => {
    try {
        const { id } = req.params;
        const {
            name, phone, paymentType,
            wageRate, contractDescription, contractAmount,
            taskDescription, unitDescription, ratePerUnit
        } = req.body;

        const worker = await prisma.worker.findUnique({ where: { id } });
        if (!worker) return res.status(404).json({ message: 'Worker not found' });

        const updated = await prisma.worker.update({
            where: { id },
            data: {
                name,
                phone,
                paymentType: paymentType || worker.paymentType,
                wageRate: paymentType === 'DAILY_WAGE' ? parseFloat(wageRate || 0) : 0,
                contractDescription: contractDescription || null,
                contractAmount: contractAmount ? parseFloat(contractAmount) : null,
                taskDescription: taskDescription || null,
                unitDescription: unitDescription || null,
                ratePerUnit: ratePerUnit ? parseFloat(ratePerUnit) : null,
            }
        });

        res.json(updated);
    } catch (error) {
        console.error('Update Worker Error:', error);
        res.status(500).json({ message: 'Error updating worker' });
    }
};

// Add work progress entry (for PIECE_RATE workers)
exports.addWorkProgress = async (req, res) => {
    try {
        const { workerId, quantity, description } = req.body;

        const worker = await prisma.worker.findUnique({ where: { id: workerId } });
        if (!worker) return res.status(404).json({ message: 'Worker not found' });
        if (worker.paymentType !== 'PIECE_RATE') {
            return res.status(400).json({ message: 'Work progress only for PIECE_RATE workers' });
        }

        const progress = await prisma.workProgress.create({
            data: {
                workerId,
                quantity: parseFloat(quantity),
                description: description || null,
                recordedBy: req.user.id
            }
        });

        res.status(201).json(progress);
    } catch (error) {
        console.error('Add Work Progress Error:', error);
        res.status(500).json({ message: 'Error adding work progress' });
    }
};

// Get work progress for a worker
exports.getWorkProgress = async (req, res) => {
    try {
        const { workerId } = req.params;
        const progress = await prisma.workProgress.findMany({
            where: { workerId },
            orderBy: { date: 'desc' }
        });
        res.json(progress);
    } catch (error) {
        console.error('Get Work Progress Error:', error);
        res.status(500).json({ message: 'Error getting work progress' });
    }
};