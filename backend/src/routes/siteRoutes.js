const express = require('express');
const router = express.Router();
const siteController = require('../controllers/siteController');
const { requireAuth, requireRole } = require('../middlewares/auth');

router.use(requireAuth);

router.post('/', requireRole(['ADMIN', 'MANAGER']), siteController.createSite);
router.get('/', siteController.getSites);
router.get('/:id', siteController.getSiteById);
router.put('/:id', requireRole(['ADMIN', 'MANAGER']), siteController.updateSite);
router.delete('/:id', requireRole(['ADMIN']), siteController.deleteSite);

module.exports = router;