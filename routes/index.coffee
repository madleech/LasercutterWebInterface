express = require 'express'
jobs = require '../lib/jobs'
serial = require '../lib/serial'

router = express.Router()

# GET home page
router.get '/', (req, res, next) ->
  serial.ports (ports) ->
    res.render 'index',
      title: 'WebCut'
      jobs: jobs.list
      ports: ports
      webcam_url: "http://#{req.hostname}:8080/?action=stream"

module.exports = router
