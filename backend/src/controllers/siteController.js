const prisma = require('../config/db');
const bcrypt = require('bcryptjs');

exports.createSite = async (req, res) => {
    try {
        const { name, location } = req.body;

        const site = await prisma.site.create({
            data: {
                name,
                location,
                managerId: req.user.id
            }
        });

        res.status(201).json(site);
    } catch (error) {
        console.error('Create Site Error:', error);
        res.status(500).json({ message: 'Error creating site' });
    }
};

exports.getSites = async (req, res) => {
    try {
        let sites;
        if (req.user.role === 'ADMIN') {
            sites = await prisma.site.findMany({
                include: { _count: { select: { workers: true } } }
            });
        } else {
            sites = await prisma.site.findMany({
                where: { managerId: req.user.id },
                include: { _count: { select: { workers: true } } }
            });
        }
        res.json(sites);
    } catch (error) {
        console.error('Get Sites Error:', error);
        res.status(500).json({ message: 'Error getting sites' });
    }
};

exports.getSiteById = async (req, res) => {
    try {
        const site = await prisma.site.findUnique({
            where: { id: req.params.id },
            include: { workers: true }
        });

        if (!site) return res.status(404).json({ message: 'Site not found' });

        if (req.user.role !== 'ADMIN' && site.managerId !== req.user.id) {
            return res.status(403).json({ message: 'Forbidden' });
        }

        res.json(site);
    } catch (error) {
        console.error('Get Site Error:', error);
        res.status(500).json({ message: 'Error getting site' });
    }
};

exports.updateSite = async (req, res) => {
    try {
        const { id } = req.params;
        const { name, location } = req.body;

        const site = await prisma.site.findUnique({ where: { id } });
        if (!site) return res.status(404).json({ message: 'Site not found' });

        if (req.user.role !== 'ADMIN' && site.managerId !== req.user.id) {
            return res.status(403).json({ message: 'Forbidden' });
        }

        const updated = await prisma.site.update({
            where: { id },
            data: { name, location }
        });

        res.json(updated);
    } catch (error) {
        console.error('Update Site Error:', error);
        res.status(500).json({ message: 'Error updating site' });
    }
};

exports.deleteSite = async (req, res) => {
    try {
        const { id } = req.params;
        const { adminPassword } = req.body;

        // Only ADMIN can delete sites
        if (req.user.role !== 'ADMIN') {
            return res.status(403).json({ message: 'Only admins can delete sites' });
        }

        // Verify admin password
        if (!adminPassword) {
            return res.status(400).json({ message: 'Admin password is required' });
        }

        const admin = await prisma.user.findUnique({ where: { id: req.user.id } });
        const passwordMatch = await bcrypt.compare(adminPassword, admin.password_hash);

        if (!passwordMatch) {
            return res.status(401).json({ message: 'Incorrect admin password' });
        }

        const site = await prisma.site.findUnique({ where: { id } });
        if (!site) return res.status(404).json({ message: 'Site not found' });

        // Delete related records first
        await prisma.attendance.deleteMany({ where: { siteId: id } });
        await prisma.transaction.deleteMany({
            where: { worker: { siteId: id } }
        });
        await prisma.worker.deleteMany({ where: { siteId: id } });
        await prisma.site.delete({ where: { id } });

        res.json({ message: 'Site deleted successfully' });
    } catch (error) {
        console.error('Delete Site Error:', error);
        res.status(500).json({ message: 'Error deleting site' });
    }
};