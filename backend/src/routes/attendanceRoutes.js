const express = require('express');
const router = express.Router();
const attendanceController = require('../controllers/attendanceController');
const { requireAuth, requireRole } = require('../middlewares/auth');

router.use(requireAuth);

// QR scanner check-in/check-out
router.post('/', requireRole(['ADMIN', 'MANAGER', 'HANDLER']), attendanceController.markAttendance);

// Calendar-based attendance marking
router.post('/calendar', requireRole(['ADMIN', 'MANAGER', 'HANDLER']), attendanceController.markCalendarAttendance);

// Get attendance (by workerId or siteId query param)
router.get('/', (req, res) => {
    if (req.query.workerId) {
        return attendanceController.getAttendanceByWorker(req, res);
    }
    return attendanceController.getAttendanceBySite(req, res);
});

module.exports = router;