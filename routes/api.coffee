express = require 'express'
router = express.Router()
jobs = require '../lib/jobs'
serial = require '../lib/serial'
radio = require '../lib/radio'
sensors = require '../lib/sensors'

progress = 0
status = null
radio.on 'progress', (value, state) ->
  progress = value
  status = state
radio.on 'finished', ->
  progress = 0
  status = 'finished'

router.get '/jobs', (req, res, next) ->
  res.send (for job in jobs.list
    {
  		name: job.name
  		ip: job.ip
  		lines: job.line_count()
    }
  )

router.get '/ports', (req, res, next) ->
  serial.ports (ports) ->
    res.send ports

router.all '/progress', (req, res) ->
  res.send {
    job: jobs.current_job()?.name || 'none'
    progress: progress*100 || 0
    status: status || 'Waiting for upload'
    timestamp: Date.now()
  }

router.all '/temperature', (req, res) ->
  res.send temperature: (if sensors.temperature() then "#{Math.round sensors.temperature()}°C" else 'Unknown')

module.exports = router
