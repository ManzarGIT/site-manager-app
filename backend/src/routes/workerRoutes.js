const express = require('express');
const router = express.Router();
const workerController = require('../controllers/workerController');
const { requireAuth, requireRole } = require('../middlewares/auth');

router.use(requireAuth);

router.post('/', requireRole(['ADMIN', 'MANAGER', 'HANDLER']), workerController.createWorker);
router.get('/', workerController.getWorkers);
router.put('/:id', requireRole(['ADMIN', 'MANAGER', 'HANDLER']), workerController.updateWorker);

// Work progress (PIECE_RATE)
router.post('/progress', requireRole(['ADMIN', 'MANAGER', 'HANDLER']), workerController.addWorkProgress);
router.get('/progress/:workerId', workerController.getWorkProgress);

module.exports = router;