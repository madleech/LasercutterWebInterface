express = require 'express'
router = express.Router()
jobs = require '../lib/jobs'
printer = require '../lib/printer'
serial = require '../lib/serial'
radio = require '../lib/radio'
sensors = require '../lib/sensors'
debug = require('debug')('webcut:api')

progress = 0
status = null

radio.on 'progress', (value, state) ->
  progress = value
  status = state
radio.on 'finished', ->
  progress = 0
  status = 'finished'

printer.on 'error', (text) -> status = text
printer.on 'alarm', (text) -> status = text

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
  res.send {
    temperature:
      raw: sensors.temperature()
      formatted: (if sensors.temperature() then "#{Math.round sensors.temperature()}°C" else 'Unknown')
  }

router.post '/abort', (req, res) ->
  jobs.current_job()?.abort()
  res.send ok:true

router.post '/home', (req, res) ->
  home = -> printer.home()
  printer.once 'ready', home
  printer.once 'state', (state) ->
    if state is 'HOMED'
      printer.removeEventListener home
  
  printer.connect()
  res.send ok:true
  

module.exports = router
