express = require 'express'
router = express.Router()
jobs = require '../lib/jobs'

router.get '/', (req, res, next) ->
  res.render 'jobs'

module.exports = router
