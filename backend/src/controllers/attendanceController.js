const prisma = require('../config/db');

// Original QR check-in/check-out (for scanner)
exports.markAttendance = async (req, res) => {
    try {
        const { workerId, siteId, action } = req.body;

        const today = new Date();
        today.setHours(0, 0, 0, 0);

        let attendance = await prisma.attendance.findFirst({
            where: {
                workerId,
                siteId,
                date: { gte: today }
            }
        });

        if (action === 'CHECK_IN') {
            if (attendance && attendance.checkIn) {
                return res.status(400).json({ message: 'Already checked in today' });
            }
            attendance = await prisma.attendance.create({
                data: {
                    workerId,
                    siteId,
                    checkIn: new Date(),
                    date: new Date()
                }
            });
        } else if (action === 'CHECK_OUT') {
            if (!attendance || !attendance.checkIn) {
                return res.status(400).json({ message: 'Must check in first' });
            }
            if (attendance.checkOut) {
                return res.status(400).json({ message: 'Already checked out today' });
            }
            attendance = await prisma.attendance.update({
                where: { id: attendance.id },
                data: { checkOut: new Date() }
            });
        } else {
            return res.status(400).json({ message: 'Invalid action' });
        }

        res.json(attendance);
    } catch (error) {
        console.error('Attendance Error:', error);
        res.status(500).json({ message: 'Error marking attendance' });
    }
};

// New: Calendar-based attendance marking (PRESENT, ABSENT, HALF_DAY)
exports.markCalendarAttendance = async (req, res) => {
    try {
        const { workerId, date, status } = req.body;

        if (!workerId || !date || !status) {
            return res.status(400).json({ message: 'workerId, date and status are required' });
        }

        const validStatuses = ['PRESENT', 'ABSENT', 'HALF_DAY'];
        if (!validStatuses.includes(status)) {
            return res.status(400).json({ message: 'Invalid status. Use PRESENT, ABSENT or HALF_DAY' });
        }

        // Get worker to find siteId
        const worker = await prisma.worker.findUnique({ where: { id: workerId } });
        if (!worker) return res.status(404).json({ message: 'Worker not found' });

        const attendanceDate = new Date(date);
        attendanceDate.setHours(0, 0, 0, 0);
        const nextDay = new Date(attendanceDate);
        nextDay.setDate(attendanceDate.getDate() + 1);

        // Check if record already exists for this date
        const existing = await prisma.attendance.findFirst({
            where: {
                workerId,
                date: {
                    gte: attendanceDate,
                    lt: nextDay
                }
            }
        });

        let attendance;
        if (existing) {
            // Update existing record
            attendance = await prisma.attendance.update({
                where: { id: existing.id },
                data: { status }
            });
        } else {
            // Create new record
            attendance = await prisma.attendance.create({
                data: {
                    workerId,
                    siteId: worker.siteId,
                    date: attendanceDate,
                    status
                }
            });
        }

        res.status(201).json(attendance);
    } catch (error) {
        console.error('Calendar Attendance Error:', error);
        res.status(500).json({ message: 'Error marking attendance' });
    }
};

// Get attendance by worker ID
exports.getAttendanceByWorker = async (req, res) => {
    try {
        const { workerId } = req.query;

        if (!workerId) {
            return res.status(400).json({ message: 'workerId is required' });
        }

        const attendances = await prisma.attendance.findMany({
            where: { workerId },
            orderBy: { date: 'desc' }
        });

        res.json(attendances);
    } catch (error) {
        console.error('Get Worker Attendance Error:', error);
        res.status(500).json({ message: 'Error getting attendance' });
    }
};

exports.getAttendanceBySite = async (req, res) => {
    try {
        const { siteId, date } = req.query;

        let queryDate = date ? new Date(date) : new Date();
        queryDate.setHours(0, 0, 0, 0);
        const nextDay = new Date(queryDate);
        nextDay.setDate(queryDate.getDate() + 1);

        const attendances = await prisma.attendance.findMany({
            where: {
                siteId,
                date: { gte: queryDate, lt: nextDay }
            },
            include: { worker: { select: { name: true, qrCode: true } } }
        });

        res.json(attendances);
    } catch (error) {
        console.error('Get Attendance Error:', error);
        res.status(500).json({ message: 'Error getting attendance logs' });
    }
};