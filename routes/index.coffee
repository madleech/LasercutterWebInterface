express = require 'express'
jobs = require '../lib/jobs'
serial = require '../lib/serial'

router = express.Router()

# GET home page
router.get '/', (req, res, next) ->
  serial.ports (ports) ->
    res.render 'index',
      title: 'Express'
      jobs: jobs.list
      ports: ports

module.exports = router
