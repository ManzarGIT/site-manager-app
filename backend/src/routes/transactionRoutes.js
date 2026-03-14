const express = require('express');
const router = express.Router();
const transactionController = require('../controllers/transactionController');
const { requireAuth, requireRole } = require('../middlewares/auth');

router.use(requireAuth);

router.post('/', requireRole(['ADMIN', 'MANAGER', 'ACCOUNTANT']), transactionController.createTransaction);
router.get('/worker/:workerId', transactionController.getWorkerTransactions);

module.exports = router;
