printer = require './printer'
{EventEmitter} = require 'events'
radio = require './radio'
debug = require('debug')('webcut:jobs')

current_job = null

class Jobs extends EventEmitter
	constructor: ->
		@list = []
		radio.on 'finished', -> current_job = null
	
	add: (data) ->
		job = new Job(
			data.ip,
			data.name,
			data.gcode
		)
		# replace existing job with same name
		@list = (_job for _job,idx in @list when _job.name != job.name)
		@list.push job
		job
	
	get: (index) -> @list[index]
	
	command: (command) ->
		current_job.abort() if current_job
		# play /sd/<filename>
		if match = "#{command}".trim().match /play \/sd\/(.+)/
			for job in @list when job.name == match[1]
				job.start()
	
	current_job: -> current_job

class Job extends EventEmitter
	constructor: (@ip, @name, lines = "") ->
		@id = null
		@line = 0
		@lines = "#{lines}".split(/[\r\n]/)
	
	start: ->
		debug "starting job #{@name} with #{@line_count()} lines"
		current_job = @
		# once ready, send some first line
		printer.once 'ready', @send_next_line
		# each time an ok is received, send next line
		printer.on 'ok', @send_next_line
		printer.on 'error', (error) => radio.broadcast 'error', error
		printer.on 'alarm', (alarm) => radio.broadcast 'alarm', alarm
		printer.on 'progress', (text) => radio.broadcast 'progress', 0, text
		
		printer.connect()
	
	send_next_line: =>
		# send next line
		if @line < @lines.length
			printer.write @lines[@line]
			radio.broadcast 'progress', @line/@lines.length, 'cutting'
		
		# or if out of lines
		else
			debug "job finished"
			@finish()
		
		# track which line we're up to
		@line++
	
	line_count: -> @lines.length
	
	abort: ->
		debug "aborting unfinished job"
		printer.soft_reset()
		printer.removeListener 'ready', @send_next_line
		printer.removeListener 'ok', @send_next_line
		@finish()
	
	finish: ->
		printer.close()
		@emit 'finished'
		radio.broadcast 'finished'

module.exports = new Jobs
