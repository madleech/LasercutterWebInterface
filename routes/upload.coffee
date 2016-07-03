express = require 'express'
bodyParser = require 'body-parser'
router = express.Router()
debug = require('debug')('webcut:upload')

jobs = require '../lib/jobs'

router.post '/upload', (req, res, next) ->
	# X-Filename = filename
	# post body = gcode
	job = jobs.add
		ip: req.ip
		name: req.headers['x-filename']
		gcode: req.body
	debug "Job added, #{job.name}, #{job.line_count()}"
	res.send status: 'ok'

# run job
router.post '/command', (req, res, next) ->
	# play /sd/<filename>
	debug "Command: #{req.body}"
	job = jobs.command req.body
	res.send status: 'ok'

module.exports = router
